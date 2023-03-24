using System;
using System.Collections.Generic;
using System.Text;
using System.IO;
using System.IO.Ports;
using System.Windows.Forms;

namespace Tracer
{
    class Program
    {
        const char LF = (char)10;
        static StringBuilder sbTraceRecord = new StringBuilder();
        static SerialPort comPort;
        static Dictionary<string, string> traceDictionary = new Dictionary<string, string>();

        [STAThread]
        static int Main(string[] args)
        {
            System.IO.StreamReader sourceFile;
            string sourceFileName;
            string comPortName = "COM5";
            string rawLine;
            int dummy;

            // args: <filename> COM<n>
            switch (args.Length)
            {
                case 0:
                    sourceFileName = GetInteractiveFile(string.Empty);
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
                            traceDictionary.Add(m1key, rawLine.Substring(keyIndex));

                            found = true;
                        }
                    }
                }
            }

            Console.WriteLine($"{traceDictionary.Count} lines added from {sourceFileName}");

            comPort = new SerialPort(comPortName, 38400, Parity.None, 8, StopBits.One);
            if (comPort.IsOpen)
            {
                comPort.Close();
            }
            Console.WriteLine($"Waiting for trace on {comPort.PortName} ({comPort.BaudRate},{comPort.DataBits},{comPort.Parity},{comPort.StopBits})");
            Console.WriteLine($"(Press 'x' to exit, <spacebar> to flip RTS pin)");
            comPort.DataReceived += Port_DataReceived;
            comPort.Handshake = Handshake.None;
            comPort.RtsEnable = true;
            comPort.Open();

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
                    case 'x':
                    case 'X':
                        exit = true;
                    break;
                    default:
                        break;
                }
            }
            comPort.Close();

            return 0;
        }

        static void Port_DataReceived(object sender, System.IO.Ports.SerialDataReceivedEventArgs e)
        {
            string received = comPort.ReadExisting();

            foreach (char c in received)
            {
                if (c == LF)
                {
                    // leave out the previous CR (TODO - check assumption it was a CR...)
                    string traceRecord = sbTraceRecord.ToString(0, sbTraceRecord.Length - 1);
                    string[] traceValuePair = traceRecord.Split(',');
                    string recordType = traceValuePair[0].ToUpperInvariant();
                    switch (recordType)
                    {
                        // see https://github.com/zpekic/sys9080/blob/master/debugtracer.vhd
                        case "M1":  // instruction fetch
                            if (traceDictionary.ContainsKey(traceValuePair[1]))
                            {
                                Console.WriteLine(traceDictionary[traceValuePair[1]]);
                            }
                            else
                            { 
                                Console.ForegroundColor = ConsoleColor.Yellow;  // YELLOW for unmatched record
                                Console.WriteLine(traceRecord);
                            }
                            break;
                        case "MR":  // read memory (except M1)
                        case "MW":  // write memory
                        case "IR":  // read port
                        case "IW":  // write port
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

        private static string GetInteractiveFile(string fileName)
        {
            using (OpenFileDialog openFileDialog = new OpenFileDialog())
            {
                openFileDialog.InitialDirectory = Directory.GetCurrentDirectory();
                openFileDialog.Title = "Select assembly listing file for trace matching";
                openFileDialog.FileName = fileName;
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
    }
}
