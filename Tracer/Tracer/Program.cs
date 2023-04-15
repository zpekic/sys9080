﻿using System;
using System.Collections.Generic;
using System.Text;
using System.IO;
using System.IO.Ports;
using System.Globalization;
using System.Windows.Forms;

namespace Tracer
{
    class Program
    {
        const char LF = (char)10;
        static StringBuilder sbTraceRecord = new StringBuilder();
        static SerialPort comPort;
        static Dictionary<string, string> traceDictionary = new Dictionary<string, string>();
        static Dictionary<string, int> profilerDictionary = new Dictionary<string, int>();
        static StoreMap<StoreMapRow> memoryMap, ioMap;
        static InspectorForm inspector = null;

        // these track the "imagined" external memory space as updated and read by the CPU
        private Dictionary<int, byte> ioReadDictionary = new Dictionary<int, byte>();
        private Dictionary<int, byte> ioWriteDictionary = new Dictionary<int, byte>();
        private Dictionary<int, byte> ioDiffDictionary = new Dictionary<int, byte>();

        [STAThread]
        static int Main(string[] args)
        {
            System.IO.StreamReader sourceFile;
            string sourceFileName;
            string comPortName = "COM5";
            string rawLine;
            int dummy;
            
            PrintBanner();

            // args: <filename> COM<n>
            switch (args.Length)
            {
                case 0:
                    sourceFileName = GetInteractiveFile(@"C:\Users\zoltanp\Documents\HexCalc\sys9080\prog\zout");
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
                            if (keyValue.IndexOf(":") > 0)
                            {
                                profilerDictionary.Add(m1key, 0);
                            }
                            found = true;
                        }
                    }
                }
            }
            sourceFile.Close();

            Console.WriteLine($"{traceDictionary.Count} lines added from {sourceFileName}");

            comPort = new SerialPort(comPortName, 38400, Parity.None, 8, StopBits.One);
            if (comPort.IsOpen)
            {
                comPort.Close();
            }

            string comInfo = $"{comPort.PortName} ({comPort.BaudRate},{comPort.DataBits},{comPort.Parity},{comPort.StopBits})";
            Console.WriteLine($"Waiting for trace on {comInfo}");
            Console.WriteLine($"(Press 'x' to exit, 'i' to show inspector, <spacebar> to flip RTS pin)");
            comPort.DataReceived += Port_DataReceived;
            comPort.Handshake = Handshake.None;
            comPort.RtsEnable = true;
            comPort.Open();

            // create maps for memory and I/O
            memoryMap = new StoreMap<StoreMapRow>(1 << 16, true);
            ioMap = new StoreMap<StoreMapRow>(1 << 8, false);

            ConsoleKeyInfo key;
            bool exit = false;

            while (!exit)
            {
                key = Console.ReadKey();
                switch (key.KeyChar)
                {
                    // TODO: clear instruction counter on some key
                    case ' ':
                        comPort.RtsEnable = !comPort.RtsEnable;
                        break;
                    case 'i':
                    case 'I':
                        if (inspector == null)
                        {
                            inspector = new InspectorForm(sourceFileName, $"Tracer inspector window for {comInfo}", memoryMap, ioMap);

                            System.Threading.Thread formShower = new System.Threading.Thread(ShowForm);
                            formShower.Start(inspector);
                        }
                        else
                        {
                            inspector.BringToFront();
                        }
                        break;
                    case 'x':
                    case 'X':
                        // leave it in enabled state 
                        exit = true;
                        comPort.RtsEnable = true;
                        GenerateProfilerReport();
                        break;
                    default:
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

        static void Port_DataReceived(object sender, System.IO.Ports.SerialDataReceivedEventArgs e)
        {
            int address;
            byte data;
            string received = comPort.ReadExisting();

            foreach (char c in received)
            {
                if (c == LF)
                {
                    // leave out the previous CR (TODO - check assumption it was a CR...)
                    string traceRecord = sbTraceRecord.ToString(0, sbTraceRecord.Length - 1);
                    string[] traceValuePair = traceRecord.Split(',');
                    string recordType = traceValuePair[0].ToUpperInvariant();
                    string recordValue = traceValuePair[1].ToUpperInvariant();
                    switch (recordType)
                    {
                        // see https://github.com/zpekic/sys9080/blob/master/debugtracer.vhd
                        case "M1":  // instruction fetch
                            if (CheckRecipientAndRecord(memoryMap, recordValue.Split(' '), out address, out data))
                            {
                                memoryMap.UpdateFetch(address, data);
                            }
                            if (traceDictionary.ContainsKey(recordValue))
                            {
                                Console.WriteLine(traceDictionary[recordValue]);
                            }
                            else
                            { 
                                Console.ForegroundColor = ConsoleColor.Yellow;  // YELLOW for unmatched record
                                Console.WriteLine(traceRecord);
                            }
                            if (profilerDictionary.ContainsKey(recordValue))
                            {   
                                // increment hit count
                                profilerDictionary[recordValue]++;
                            }
                            break;
                        case "MR":  // read memory (except M1)
                            if (CheckRecipientAndRecord(memoryMap, recordValue.Split(' '), out address, out data))
                            {
                                memoryMap.UpdateRead(address, data);
                            }
                            Console.ForegroundColor = ConsoleColor.Blue;    // BLUE for not implemented trace record type
                            Console.WriteLine(traceRecord);
                            break;
                        case "MW":  // write memory
                            if (CheckRecipientAndRecord(memoryMap, recordValue.Split(' '), out address, out data))
                            {
                                memoryMap.UpdateWrite(address, data);
                            }
                            Console.ForegroundColor = ConsoleColor.Blue;    // BLUE for not implemented trace record type
                            Console.WriteLine(traceRecord);
                            break;
                        case "IR":  // read port
                            if (CheckRecipientAndRecord(ioMap, recordValue.Split(' '), out address, out data))
                            {
                                // TODO: coerce 16-bit address to 8-bit??
                                ioMap.UpdateRead(address, data);
                            }
                            Console.ForegroundColor = ConsoleColor.Blue;    // BLUE for not implemented trace record type
                            Console.WriteLine(traceRecord);
                            break;
                        case "IW":  // write port
                            if (CheckRecipientAndRecord(ioMap, recordValue.Split(' '), out address, out data))
                            {
                                // TODO: coerce 16-bit address to 8-bit??
                                ioMap.UpdateWrite(address, data);
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
                }
                else
                {
                    sbTraceRecord.Append(c);
                }
            }
        }


        private static bool CheckRecipientAndRecord(StoreMap<StoreMapRow> sm, string[] addressDataPair, out int address, out byte data)
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

                        if (int.TryParse(addressDataPair[1], NumberStyles.HexNumber, CultureInfo.InvariantCulture, out d) && (d >= 0) && (d < (1 << 8)))
                        {
                            data = (byte)d;
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
            List<string> topHitsList = new List<string>();

            // get total number of label hits
            foreach (string key in profilerDictionary.Keys)
            {
                totalHits += profilerDictionary[key];
            }

            if (totalHits > 0)
            {
                Console.WriteLine($"------------------------------------------------");
                //Console.WriteLine($"123 1234567890 123 -----------------------------");
                Console.WriteLine($"  # Hit  count   % Label");
                Console.WriteLine($"------------------------------------------------");

                // Find and print top ten hitters (TODO: make it command line parameter)
                for (int i = 1; i <= 10; i++)
                {
                    int topHits = 0;
                    string topKey = string.Empty;

                    foreach (string key in profilerDictionary.Keys)
                    {
                        if (!topHitsList.Contains(key) && (profilerDictionary[key] >= topHits))
                        {
                            topHits = profilerDictionary[key];
                            topKey = key;
                        }
                    }

                    topHitsList.Add(topKey);
                    Console.WriteLine($"{i,3} {topHits,10} {(100 * topHits) / totalHits,3}% {traceDictionary[topKey]}");
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
                openFileDialog.Filter = "LST files (*.lst)|*.lst|All files (*.*)|*.*";
                openFileDialog.FilterIndex = 0;
                openFileDialog.RestoreDirectory = true;

                if (openFileDialog.ShowDialog() == DialogResult.OK)
                {
                    //Get the path of specified file
                    return openFileDialog.FileName;
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
            Console.WriteLine($"----------------------------------------------------------------");
            Console.WriteLine($" i8080 compatible symbolic tracer utility (c) zpekic@hotmail.com");
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
                inspector.Dispose();
                inspector = null;
            }
        }

        private static void Assert(bool condition, string exceptionMessage)
        {
            if (!condition)
            {
                throw new ApplicationException(exceptionMessage, null);
            }
        }
    }
}
