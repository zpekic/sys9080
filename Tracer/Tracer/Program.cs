using System;
using System.Collections.Generic;
using System.Text;
using System.IO;
using System.IO.Ports;
using System.Globalization;
using System.Windows.Forms;
using System.Reflection;
using System.Linq;

namespace Tracer
{
    class Program : IDisposable
    {
        const char LF = (char)10;
        const char CR = (char)13;
        static StringBuilder sbTraceRecord = new StringBuilder();
        static SerialPort comPort;
        static System.IO.StreamReader sourceFile;
        static Dictionary<string, string> traceDictionary = new Dictionary<string, string>();
        static Dictionary<string, int> profilerDictionary = new Dictionary<string, int>();
        static StoreMap<StoreMapRow> memoryMap, ioMap;
        static CpuBroker cpuBroker; 
        static InspectorForm inspector = null;
        static int dataWidth = -1;  // uninitialized
        static string lastInstructionRecord = string.Empty;
        static string title;
        static bool stopAtNextInstruction = false;
        static bool stopAtNextReturn = false;
        static int stackLevel = 0;
        static int stackLevelChange = 0;

        // these track the "imagined" external memory space as updated and read by the CPU
        //private Dictionary<int, byte> ioReadDictionary = new Dictionary<int, byte>();
        //private Dictionary<int, byte> ioWriteDictionary = new Dictionary<int, byte>();
        //private Dictionary<int, byte> ioDiffDictionary = new Dictionary<int, byte>();

        [STAThread]
        static int Main(string[] args)
        {
            string sourceFileName;
            string comPortName = "COM6";
            int comPortBaudrate = 57600;
            int dummy;
            
            PrintBanner();

            // args: <filename> COM<n>
            switch (args.Length)
            {
                case 0:
                    sourceFileName = GetInteractiveFile(@"C:\Users\zoltanp\Documents\HexCalc\sys_sifp\prog");
                    break;
                case 1:
                    sourceFileName = args[0];
                    break;
                default:
                    sourceFileName = args[0];
                    comPortName = args[1].ToUpper();
                    break;
            }
            
            // simple check
            if (string.IsNullOrEmpty(sourceFileName))
            {
                Console.WriteLine($"Required argument not provided. Expected: tracer.exe lstFileName [COM<n>]");
                return 1;
            }
            else
            {
                if (!File.Exists(sourceFileName))
                {
                    Console.WriteLine($"{sourceFileName} not found.");
                    return 2;
                }
                if (!comPortName.StartsWith("COM") || !int.TryParse(comPortName.Substring(3), out dummy))
                {
                    Console.WriteLine($"{comPortName} is invalid (must be COM<n>).");
                    return 2;
                }
            }
            sourceFile = new System.IO.StreamReader(sourceFileName);
            // lame way to try to support both 8080 and SIFC
            if (sourceFileName.EndsWith(".vhd"))
            {
                dataWidth = 16;
                IngestMCCVhdFile();
            }
            else
            {
                dataWidth = 8;
                IngestZMACLstFile();
            }
            sourceFile.Close();

            Console.WriteLine($"{traceDictionary.Count} lines added from {sourceFileName}");

            comPort = new SerialPort(comPortName, comPortBaudrate, Parity.None, 8, StopBits.One);
            if (comPort.IsOpen)
            {
                comPort.Close();
            }

            string comInfo = $"{comPort.PortName} ({comPort.BaudRate},{comPort.DataBits},{comPort.Parity},{comPort.StopBits})";
            Console.WriteLine($"Waiting for trace on {comInfo}");
            Console.WriteLine($"(Press 'x' to exit, 'c|m|i' to show inspector, <spacebar> to flip RTS pin)");
            comPort.Open();
            comPort.Handshake = Handshake.None;
            comPort.RtsEnable = true;

            // create maps for memory and I/O
            //memoryMap = new StoreMap<StoreMapRow>(1 << 12, true);   // TODO: make it a parameter
            memoryMap = new StoreMap<StoreMapRow>(1 << 16, true); // TODO: limiting to 4k is a speed-up experiment 
            ioMap = new StoreMap<StoreMapRow>(1 << 8, false);
            cpuBroker = new CpuBroker(dataWidth);
            
            ConsoleKeyInfo key;
            bool exit = false;
            title = Console.Title;
            comPort.DataReceived += Port_DataReceived;

            while (!exit)
            {
                Console.Title = $"{title} stack level: {stackLevel}" + (comPort.RtsEnable ? " RtsEnable = 1" : " RtsEnable = 0") + (stopAtNextInstruction ? ", single step" : "") + (stopAtNextReturn ? ", run until RTS" : "");

                key = Console.ReadKey();

                switch (key.KeyChar)
                {
                    // TODO: clear instruction counter on some key
                    case ' ':
                        if (comPort.RtsEnable)
                        {
                            comPort.RtsEnable = false;
                            Console.WriteLine($"[stop at '{lastInstructionRecord}']");
                        }
                        else
                        {
                            comPort.RtsEnable = true;
                            Console.WriteLine("[continue]");
                        }
                        break;
                    case 'b':
                    case 'B':
                        Console.WriteLine("[reakpoints]");
                        // dump all breakpoints
                        Console.WriteLine("----------------------------");
                        Console.WriteLine("Instruction\tLine");
                        Console.WriteLine("----------------------------");
                        if (cpuBroker.breakpointDictionary.Count > 0)
                        {
                            foreach(string instruction in cpuBroker.breakpointDictionary.Keys)
                            {
                                int line = cpuBroker.breakpointDictionary[instruction];
                                Console.WriteLine($"{instruction}\t{line} {inspector.GetCodeLine(line)}");
                            }
                        }
                        else
                        {
                            Console.WriteLine("(None - use F9 in console or inspector window to set/remove)");
                        }
                        Console.WriteLine("----------------------------");
                        break;
                    case 'c':   // code
                    case 'C':
                    case 'm':   // memory
                    case 'M':
                    case 'i':   // i/o
                    case 'I':
                    case 'r':   // registers
                    case 'R':
                        comPort.RtsEnable = false;  // try to stop ongoing debugging
                        Console.WriteLine("[spector]");
                        EnsureInspector(true, sourceFileName, comInfo);
                        inspector.SelectTab(key.KeyChar);
                        break;
                    case 'x':
                    case 'X':
                        // leave it in enabled state 
                        Console.WriteLine("[it]");
                        exit = true;
                        comPort.RtsEnable = true;
                        GenerateProfilerReport();
                        break;
                    default:
                        switch (key.Key)
                        {
                            // run until next breakpoint
                            case ConsoleKey.F5:
                                stopAtNextInstruction = false;
                                stopAtNextReturn = false;
                                comPort.RtsEnable = true;
                                break;
                            // set or clear breakpoint at current instruction
                            case ConsoleKey.F9:
                                EnsureInspector(false, sourceFileName, comInfo);
                                if (!inspector.ToggleBreakpointByKey(lastInstructionRecord))
                                {
                                    MessageBox.Show($"Cannot find line with instruction '{lastInstructionRecord}'", "Breakpoint", MessageBoxButtons.OK);
                                }
                                break;
                            // run to next instruction
                            case ConsoleKey.F10:
                                stopAtNextInstruction = true;
                                stopAtNextReturn = false;
                                comPort.RtsEnable = true;
                                break;
                            // run until next breakpoint or RTS
                            case ConsoleKey.F12:
                                stopAtNextInstruction = false;
                                //stopAtNextReturn = !stopAtNextReturn;
                                stopAtNextReturn = true;
                                comPort.RtsEnable = true;
                                break;
                            default:
                                break;
                        }
                        break;
                }
            }
            comPort.Close();

            if (inspector != null)
            {
                inspector.Dispose();
                inspector = null;
            }

            return 0;
        }

        internal static void EnsureInspector(bool bringToFront, string sourceFileName, string comInfo)
        {
            if (inspector == null)
            {
                inspector = new InspectorForm(sourceFileName, $"Tracer inspector window for {comInfo}", memoryMap, ioMap, cpuBroker);

                // RTS low should stop the target CPU and allow putting breakpoints in the inspector window
                comPort.RtsEnable = false;
                System.Threading.Thread formShower = new System.Threading.Thread(ShowForm);
                formShower.Start(inspector);
            }
            else
            {
                if (bringToFront)
                {
                    inspector.BringToFront();
                }
            }
        }

        internal static void Assert(bool condition, string exceptionMessage)
        {
            if (!condition)
            {
                Console.ResetColor();
                throw new ApplicationException(exceptionMessage, null);
            }
        }

        static void Port_DataReceived(object sender, System.IO.Ports.SerialDataReceivedEventArgs e)
        {
            int address;
            object data;
            string received = comPort.ReadExisting();
            bool pause;

            foreach (char c in received)
            {
                if (c == LF)
                {
                    // leave out the previous CR (TODO - check assumption it was a CR...)
                    string traceRecord = sbTraceRecord.ToString();// 0, sbTraceRecord.Length - 1);
                    string[] traceValuePair = traceRecord.Split(',');
                    if (traceValuePair.Length != 2)
                    {
                        Console.ForegroundColor = ConsoleColor.Red;
                        Console.WriteLine($"{traceRecord} - BAD RECORD, IGNORED!");
                        return;
                    }
                    string recordType = traceValuePair[0].Trim().ToUpperInvariant();
                    string recordValue = traceValuePair[1].Trim().ToUpperInvariant();
                    pause = false;
                    switch (recordType)
                    {
                        // see https://github.com/zpekic/sys9080/blob/master/debugtracer.vhd
                        case "M1":  // instruction fetch
                        case "IF":
                            // need to mark it in case breakpoint set / clear is attempted
                            lastInstructionRecord = recordValue;
                            if (stackLevelChange != 0)
                            {
                                stackLevel = stackLevel + stackLevelChange;
                                stackLevelChange = 0;
                                Console.Title = $"{title} stack level: {stackLevel}" + (comPort.RtsEnable ? " RtsEnable = 1" : " RtsEnable = 0") + (stopAtNextInstruction ? ", single step" : "") + (stopAtNextReturn ? ", run until RTS" : "");
                            }
                            if (cpuBroker.callDictionary.ContainsKey(recordValue))
                            {
                                stackLevelChange = 1;
                            }
                            if (cpuBroker.returnDictionary.ContainsKey(recordValue))
                            {
                                stackLevelChange = -1;
                            }
                            // if found in breakpoint list, first try to stop the target CPU, then do anything else
                            if (cpuBroker.breakpointDictionary.ContainsKey(recordValue) || 
                                stopAtNextInstruction ||
                                (stopAtNextReturn && cpuBroker.returnDictionary.ContainsKey(recordValue)))
                            {
                                comPort.RtsEnable = false;
                                Console.Title = $"{title} stack level: {stackLevel}" + (comPort.RtsEnable ? " RtsEnable = 1" : " RtsEnable = 0") + (stopAtNextInstruction ? ", single step" : "") + (stopAtNextReturn ? ", run until RTS" : "");
                            }
                            if (CheckRecipientAndRecord(memoryMap, recordValue.Split(' '), out address, out data, dataWidth))
                            {
                                CheckLimit(memoryMap.UpdateFetch(address, data, ref pause), traceRecord);
                            }
                            // track hits for "profiling"
                            if (profilerDictionary.ContainsKey(recordValue))
                            {
                                // increment hit count
                                profilerDictionary[recordValue]++;
                            }
                            else
                            {
                                // mark first hit
                                profilerDictionary.Add(recordValue, 1);
                            }
                            // display on console
                            if (traceDictionary.ContainsKey(recordValue))
                            {
                                Console.WriteLine(traceDictionary[recordValue]);
                                if (inspector != null && cpuBroker.InspectorReady)
                                {
                                    //cpuBroker.InstructionFetch(recordValue);
                                    inspector.Invoke(inspector.codeHighlightDelegate, new Object[] { recordValue, true });
                                }
                            }
                            else
                            { 
                                Console.ForegroundColor = ConsoleColor.Yellow;  // YELLOW for unmatched record
                                Console.WriteLine(traceRecord);
                            }
                            break;
                        case "RV":  // register value
                            if (cpuBroker.UpdateRegister(recordValue))
                            {
                                Console.ForegroundColor = ConsoleColor.Green;     // GREEN for register values
                            }
                            else
                            {
                                Console.ForegroundColor = ConsoleColor.Red;     // RED for unrecognized trace record type
                            }
                            Console.WriteLine(traceRecord);
                            if (inspector != null && cpuBroker.InspectorReady)
                            {
                                inspector.Invoke(inspector.registerValueDelegate, new Object[] { cpuBroker.GetRegisterState(), false });
                            }
                            break;
                        case "MR":  // read memory (except M1)
                            if (CheckRecipientAndRecord(memoryMap, recordValue.Split(' '), out address, out data, dataWidth))
                            {
                                CheckLimit(memoryMap.UpdateRead(address, data, ref pause), traceRecord);
                            }
                            if (inspector != null)
                            {
                                //inspector.Invoke(inspector.codeHighlightDelegate, new Object[] { recordValue, false });
                            }
                            Console.ForegroundColor = ConsoleColor.Blue;    // BLUE for not implemented trace record type
                            Console.WriteLine(traceRecord);
                            break;
                        case "MW":  // write memory
                            if (CheckRecipientAndRecord(memoryMap, recordValue.Split(' '), out address, out data, dataWidth))
                            {
                                CheckLimit(memoryMap.UpdateWrite(address, data, ref pause), traceRecord);
                            }
                            Console.ForegroundColor = ConsoleColor.Blue;    // BLUE for not implemented trace record type
                            Console.WriteLine(traceRecord);
                            break;
                        case "IR":  // read port
                            if (CheckRecipientAndRecord(ioMap, recordValue.Split(' '), out address, out data, dataWidth))
                            {
                                // TODO: coerce 16-bit address to 8-bit??
                                CheckLimit(ioMap.UpdateRead(address & 0xFF, data, ref pause), traceRecord);
                            }
                            Console.ForegroundColor = ConsoleColor.Blue;    // BLUE for not implemented trace record type
                            Console.WriteLine(traceRecord);
                            break;
                        case "IW":  // write port
                            if (CheckRecipientAndRecord(ioMap, recordValue.Split(' '), out address, out data, dataWidth))
                            {
                                // TODO: coerce 16-bit address to 8-bit??
                                CheckLimit(ioMap.UpdateWrite(address & 0xFF, data, ref pause), traceRecord);
                            }
                            Console.ForegroundColor = ConsoleColor.Blue;    // BLUE for not implemented trace record type
                            Console.WriteLine(traceRecord);
                            break;
                        default:    
                            Console.ForegroundColor = ConsoleColor.Red;     // RED for unrecognized trace record type
                            Console.WriteLine(traceRecord);
                            break;
                    }
                    Console.ResetColor();
                    sbTraceRecord.Clear();
                    // pause code execution to inspect memory!
                    if (pause)
                    {
                        SendKeys.SendWait(" ");
                    }
                }
                else
                {
                    if (c != CR)
                    {
                        sbTraceRecord.Append(c);
                    }
                }
            }
        }

        private static void IngestMCCVhdFile()
        {
            string rawLine;

            while ((rawLine = sourceFile.ReadLine()) != null)
            {
                string trimmedLine = rawLine.Trim();

                if ((trimmedLine.Length > 18) && trimmedLine.StartsWith("-- L") && (trimmedLine[18] == '.'))
                {
                    // extract source line number and memory hex address
                    string[] decHex = trimmedLine.Split('@');
                    if (decHex.Length > 1)
                    {
                        string sourceLineNumber = decHex[0].Substring(4);
                        string m1key = decHex[1].Substring(0, decHex[1].IndexOf('.'));
                        string m1Value = decHex[1].Substring(decHex[1].IndexOf('.') + 1);
                        traceDictionary.Add(m1key, $"[{sourceLineNumber}]{m1Value}");
                    }
                }
            }
        }

        private static void IngestZMACLstFile()
        {
            string rawLine;

            while ((rawLine = sourceFile.ReadLine()) != null)
            {
                string trimmedLine = rawLine.Trim();
                bool found = false;

                if (!found && (trimmedLine.Length > 5))
                {
                    char[] hexChar = new char[8];

                    for (int i = 0; i < trimmedLine.Length; i++)
                    {
                        char c = trimmedLine[i];

                        hexChar[0] = hexChar[1];
                        hexChar[1] = hexChar[2];
                        hexChar[2] = hexChar[3];
                        hexChar[3] = hexChar[4];
                        hexChar[4] = hexChar[5];
                        hexChar[5] = hexChar[6];
                        hexChar[6] = hexChar[7];
                        hexChar[7] = c;
                        if (IsM1Cycle(hexChar))
                        {
                            StringBuilder sb = new StringBuilder();
                            sb.Append(hexChar);

                            string m1key = sb.ToString();
                            int keyIndex = rawLine.IndexOf(m1key);
                            m1key = m1key.Substring(0, 4) + " " + m1key.Substring(6, 2);
                            // only add text from the found instruction record onwards
                            string keyValue = rawLine.Substring(keyIndex);
                            traceDictionary.Add(m1key, keyValue);
                            // if this is a label, also add to the "profiler"
                            //if (keyValue.IndexOf(":") > 0)
                            //{
                            //    profilerDictionary.Add(m1key, 0);
                            //}
                            found = true;
                        }
                    }
                }
            }
        }

        private static void CheckLimit(bool ok, string traceRecord)
        {
            if (!ok)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.BackgroundColor = ConsoleColor.Yellow;
                Console.WriteLine($"{traceRecord} - IGNORED, OUT OF BOUNDS!");
            }
        }

        private static bool CheckRecipientAndRecord(StoreMap<StoreMapRow> sm, string[] addressDataPair, out int address, out object data, int dataWidth)
        {
            address = 0;
            data = 0;

            if (sm == null)
            {
                return false;
            }
            else
            { 
                if (addressDataPair != null && addressDataPair.Length == 2)
                {
                    if (int.TryParse(addressDataPair[0], System.Globalization.NumberStyles.HexNumber, CultureInfo.InvariantCulture, out address) && (address >=0) && (address < (1 << 16)))
                    {
                        int d;

                        if (int.TryParse(addressDataPair[1], NumberStyles.HexNumber, CultureInfo.InvariantCulture, out d) && (d >= 0) && (d < (1 << dataWidth)))
                        {
                            switch(dataWidth)
                            {
                                case 8:
                                    data = (byte)d;
                                    break;
                                case 16:
                                    data = (UInt16)d;
                                    break;
                                case 32:
                                    data = (UInt32)d;
                                    break;
                                default:
                                    throw new InvalidDataException($"Data Width value of {dataWidth} is not supported.");
                            }
                            return true;
                        }
                        else
                        {
                            Console.ForegroundColor = ConsoleColor.Yellow;     // YELLOW for recoverable mess
                            Console.WriteLine("Bad data in trace record from target device");
                        }
                    }
                    else
                    {
                        Console.ForegroundColor = ConsoleColor.Yellow;     // YELLOW for recoverable mess
                        Console.WriteLine("Bad address in trace record from target device");
                    }
                }
                else
                {
                    Console.ForegroundColor = ConsoleColor.Yellow;     // YELLOW for recoverable mess
                    Console.WriteLine("Malformed trace record from target device");
                }
            }

            return false;
        }


        private static void GenerateProfilerReport()
        {
            int totalHits = 0;
            List<KeyValuePair<string, int>> orderedProfilerList = new List<KeyValuePair<string, int>>();

            // get total number of label hits
            foreach (string key in profilerDictionary.Keys)
            {
                totalHits += profilerDictionary[key];
            }
            orderedProfilerList = profilerDictionary.ToList();
            orderedProfilerList.Sort((pair1, pair2) => pair2.Value.CompareTo(pair1.Value));

            if (totalHits > 0)
            {
                Console.WriteLine($"------------------------------------------------");
                //Console.WriteLine($"123 1234567890 123 -----------------------------");
                Console.WriteLine($"Hits\tHit%\tCumulative%\tInstruction");
                Console.WriteLine($"------------------------------------------------");

                // Find and print top 80% of hitters (TODO: make it command line parameter)
                float cumulativePercentage = 0.0F;
                foreach(var kvp in orderedProfilerList)
                {
                    float hit = (100.0F * kvp.Value) / totalHits;
                    cumulativePercentage += hit;
                    if (cumulativePercentage <= 80.0F)
                    {
                        Console.WriteLine($"{kvp.Value}\t{hit:N2}\t{cumulativePercentage:N2}\t{kvp.Key}\t{traceDictionary[kvp.Key]}");
                    }
                }

                Console.WriteLine($"---Total hits: {totalHits} --------------------------------------");
            }
            else
            {
                Console.WriteLine($"---No hits in profiler dictionary -------------------------------");
            }
        }

        private static string GetInteractiveFile(string initialDirectory)
        {
            using (OpenFileDialog openFileDialog = new OpenFileDialog())
            {
                openFileDialog.InitialDirectory = string.IsNullOrEmpty(initialDirectory) ? Directory.GetCurrentDirectory() : initialDirectory;
                openFileDialog.Title = "Select assembly listing file for trace matching";
                //openFileDialog.FileName = fileName;
                openFileDialog.Filter = "VHD files (*.vhd)|*.vhd|LST files (*.lst)|*.lst|All files (*.*)|*.*";
                openFileDialog.FilterIndex = 0;
                openFileDialog.RestoreDirectory = true;

                if (openFileDialog.ShowDialog() == DialogResult.OK)
                {
                    //Get the path of specified file
                    return openFileDialog.FileName.ToLowerInvariant();
                }
            }

            return null; // no file selected
        }

        static bool IsM1Cycle(char[] hexChar)
        {
            string ValidHexChars = "0123456789ABCDEF";

            for (int i = 0; i < hexChar.Length; i++)
            {
                switch (i)
                {
                    case 4:
                    case 5:
                        if (!Char.IsWhiteSpace(hexChar[i]))
                        {
                            return false;
                        }
                        break;
                    default:
                        if (ValidHexChars.IndexOf(hexChar[i]) < 0)
                        {
                            return false;
                        }
                        break;
                }
            }
            return true;
        }

        static void PrintBanner()
        {
            Version version = Assembly.GetEntryAssembly().GetName().Version;
            Console.WriteLine($"----------------------------------------------------------------");
            Console.WriteLine($" Symbolic tracer utility V{version.ToString()} (c) zpekic@hotmail.com supports:");
            Console.WriteLine($" SIFC-16: load *.vhd file for SIFC-16 (mcc microcode compiler)");
            Console.WriteLine($" i8080  : load *.lst file i8080 (ZMAC assembler)");
            Console.WriteLine($"----------------------------------------------------------------");
            Console.WriteLine($" https://hackaday.io/project/190239-from-bit-slice-to-basic-and-symbolic-tracing");
            Console.WriteLine($" Sources: https://github.com/zpekic/sys9080");
            Console.WriteLine($"----------------------------------------------------------------");
        }

        private static void ShowForm(object form)
        {
            Application.ApplicationExit += Application_ApplicationExit;
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run((InspectorForm) form);
        }

        private static void Application_ApplicationExit(object sender, EventArgs e)
        {
            if (inspector != null)
            {
                inspector = null;
            }
        }


        #region IDisposable Support
        private bool disposedValue = false; // To detect redundant calls

        protected virtual void Dispose(bool disposing)
        {
            if (!disposedValue)
            {
                if (disposing)
                {
                    if (comPort != null)
                    {
                        comPort.Close();
                        comPort = null;
                    }
                    if (sourceFile != null)
                    {
                        sourceFile.Close();
                        sourceFile = null;
                    }
                }

                // TODO: free unmanaged resources (unmanaged objects) and override a finalizer below.
                // TODO: set large fields to null.

                disposedValue = true;
            }
        }

        // TODO: override a finalizer only if Dispose(bool disposing) above has code to free unmanaged resources.
        // ~Program() {
        //   // Do not change this code. Put cleanup code in Dispose(bool disposing) above.
        //   Dispose(false);
        // }

        // This code added to correctly implement the disposable pattern.
        public void Dispose()
        {
            // Do not change this code. Put cleanup code in Dispose(bool disposing) above.
            Dispose(true);
            // TODO: uncomment the following line if the finalizer is overridden above.
            // GC.SuppressFinalize(this);
        }
        #endregion
    }
}
