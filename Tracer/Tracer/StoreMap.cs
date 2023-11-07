using System;
using System.Collections.Generic;
using System.Text;

namespace Tracer
{
    struct StoreMapColumn
    {
        public string Text;
        public string Name;

        public StoreMapColumn(string t, string n)
        {
            Text = t;
            Name = n;
        }
    }

    struct StoreMapRow
    {
        public string Address;
        public string Ascii;
        public string Descriptor;
        public string x0;
        public string x1;
        public string x2;
        public string x3;
        public string x4;
        public string x5;
        public string x6;
        public string x7;
        public string x8;
        public string x9;
        public string xA;
        public string xB;
        public string xC;
        public string xD;
        public string xE;
        public string xF;

        public object this[string propertyName]
        {
            get { return this.GetType().GetField(propertyName).GetValue(this); }
            set { this.GetType().GetField(propertyName).SetValue(this, value); }
        }

        public StoreMapRow(int i)
        {
            Address = i.ToString("X4");
            Ascii = "????????????????";
            Descriptor = "A????????????????H";
            x0 = "??";
            x1 = "??";
            x2 = "??";
            x3 = "??";
            x4 = "??";
            x5 = "??";
            x6 = "??";
            x7 = "??";
            x8 = "??";
            x9 = "??";
            xA = "??";
            xB = "??";
            xC = "??";
            xD = "??";
            xE = "??";
            xF = "??";
        }
    }

    public class StoreUpdatedEventArgs : EventArgs
    {
        public int Address;
        public object Data;
        public char Descriptor;

        public StoreUpdatedEventArgs(int address, object data, char descriptor)
        {
            this.Address = address;
            this.Data = data;
            this.Descriptor = descriptor;
        }
    }

    class StoreMap<T>
    {
        public readonly int Size = -1;
        public readonly bool ShowAscii = false;

        public event EventHandler<StoreUpdatedEventArgs> StoreUpdatedEvent;

        private List<StoreMapColumn> columns = new List<StoreMapColumn>();
        // these track the "imagined" external memory / IO space as seen by the CPU
        private Dictionary<int, object> readDictionary = new Dictionary<int, object>();
        private Dictionary<int, object> writeDictionary = new Dictionary<int, object>();
        private Dictionary<int, object> fetchDictionary = new Dictionary<int, object>();
        private Dictionary<int, object> registerDictionary = new Dictionary<int, object>();

        // Declare an array to store the data elements.
        private Dictionary<int, StoreMapRow> rowDictionary = new Dictionary<int, StoreMapRow>();

        // Define the indexer to allow client code to use [] notation.
        public StoreMapRow this[int i]
        {
            get {
                if (!rowDictionary.ContainsKey(i))
                {
                    StoreMapRow smr = new StoreMapRow(i * 16);
                    rowDictionary.Add(i, smr);
                    // TODO populate by going through existing byte dictionaries                  
                }

                return rowDictionary[i];
            }
            //set { arr[i] = value; }
        }

        public List<StoreMapColumn> Columns
        {
            get { return this.columns; }
        }

        public StoreMap(int size, bool showAscii)
        {
            this.Size = size;
            this.ShowAscii = showAscii;

            columns.Add(new StoreMapColumn("ADDRESS", "Address"));
            for (int i = 0; i < 16; i++)
            {
                string tn = "x" + "0123456789ABCDEF"[i];
                columns.Add(new StoreMapColumn(tn, tn));
            }
            if (showAscii)
            {
                columns.Add(new StoreMapColumn("ASCII", "Ascii"));
            }
        }

        public StoreMapRow GetStoreMapRow(int address)
        {
            StoreMapRow smr = new StoreMapRow(address);
            string bytePropValue;
            string ascii;
            char descriptorChar;
            StringBuilder sbAscii = new StringBuilder();
            StringBuilder sbDescriptor = new StringBuilder("A");    // have a description for address column too

            for (int i = 0; i < 16; i++)
            {
                //bytePropName = "x" + "0123456789ABCDEF"[i];

                if (!GetDataFromDictionary(fetchDictionary, address + i, 'F', out bytePropValue, out ascii, out descriptorChar))
                {
                    if (!GetDataFromDictionary(readDictionary, address + i, 'R', out bytePropValue, out ascii, out descriptorChar))
                    {
                        GetDataFromDictionary(writeDictionary, address + i, 'W', out bytePropValue, out ascii, out descriptorChar);
                    }
                }
                sbAscii.Append(ascii);
                sbDescriptor.Append(descriptorChar);
                //smr[bytePropName] = bytePropValue;
                switch (i)
                {
                    case 0:
                        smr.x0 = bytePropValue;
                        break;
                    case 1:
                        smr.x1 = bytePropValue;
                        break;
                    case 2:
                        smr.x2 = bytePropValue;
                        break;
                    case 3:
                        smr.x3 = bytePropValue;
                        break;
                    case 4:
                        smr.x4 = bytePropValue;
                        break;
                    case 5:
                        smr.x5 = bytePropValue;
                        break;
                    case 6:
                        smr.x6 = bytePropValue;
                        break;
                    case 7:
                        smr.x7 = bytePropValue;
                        break;
                    case 8:
                        smr.x8 = bytePropValue;
                        break;
                    case 9:
                        smr.x9 = bytePropValue;
                        break;
                    case 10:
                        smr.xA = bytePropValue;
                        break;
                    case 11:
                        smr.xB = bytePropValue;
                        break;
                    case 12:
                        smr.xC = bytePropValue;
                        break;
                    case 13:
                        smr.xD = bytePropValue;
                        break;
                    case 14:
                        smr.xE = bytePropValue;
                        break;
                    case 15:
                        smr.xF = bytePropValue;
                        break;
                    default:
                        break;
                }
            }

            sbDescriptor.Append('H');   // ASCII column is for 'H'umans :-)

            smr.Ascii = sbAscii.ToString();
            smr.Descriptor = sbDescriptor.ToString();

            return smr;
        }

        private void ReportMemoryIssue(bool fatal, string message)
        {
            //Program.Assert(!fatal, message);

            Console.Beep();
            Console.ForegroundColor = ConsoleColor.Yellow;
            Console.BackgroundColor = ConsoleColor.Red;
            Console.WriteLine($"MEMORY ISSUE: {message}");
            Console.ResetColor();
        }

        public bool UpdateFetch(int address, object data, ref bool pause)
        {
            if (address < this.Size)
            {
                if (readDictionary.ContainsKey(address))
                {
                    ReportMemoryIssue(false, $"Executing data at {address:X4}");
                    readDictionary.Remove(address);
                }
                if (writeDictionary.ContainsKey(address))
                {
                    ReportMemoryIssue(false, $"Executing self-modifying at {address:X4}");
                    writeDictionary.Remove(address);
                }
                AddOrUpdateEntry(fetchDictionary, address, data, 'F');
                return true;
            }
            return false;
        }

        public bool UpdateRead(int address, object data, ref bool pause)
        {
            if (address < this.Size)
            {
                if (fetchDictionary.ContainsKey(address))
                {
                    ReportMemoryIssue(false, $"Reading (not executing) code at {address:X4}");
                    fetchDictionary.Remove(address);
                }
                if (writeDictionary.ContainsKey(address))
                {
                    string readData = data.ToString();
                    string writeData = writeDictionary[address].ToString();
                    if (!readData.Equals(writeData, StringComparison.InvariantCultureIgnoreCase))
                    {
                        if (data is Byte)
                        {
                            ReportMemoryIssue(false, $"Reading {data:X2} from {address:X4}, expected {writeDictionary[address]:X2}");
                        }
                        else
                        {
                            if (data is UInt16)
                            {
                                ReportMemoryIssue(false, $"Reading {data:X4} from {address:X4}, expected {writeDictionary[address]:X4}");
                            }
                            else
                            {
                                ReportMemoryIssue(false, $"Reading {readData} from {address:X4}, expected {writeData}");
                            }
                        }
                        pause = true;
                    }
                    writeDictionary.Remove(address);
                }
                AddOrUpdateEntry(readDictionary, address, data, 'R');
                return true;
            }
            return false;
        }

        public bool UpdateWrite(int address, object data, ref bool pause)
        {
            if (address < this.Size)
            {
                if (readDictionary.ContainsKey(address))
                {
                    readDictionary.Remove(address);
                }
                if (fetchDictionary.ContainsKey(address))
                {
                    ReportMemoryIssue(false, $"Writing code at {address:X4}");
                    fetchDictionary.Remove(address);
                }
                AddOrUpdateEntry(writeDictionary, address, data, 'W');
                return true;
            }
            return false;
        }

        private void AddOrUpdateEntry(Dictionary<int, object> dict, int address, object data, char descriptor)
        {
            EventHandler<StoreUpdatedEventArgs> raiseEvent = StoreUpdatedEvent;
            StoreUpdatedEventArgs eventArgs = null;

            if (dict.ContainsKey(address))
            {
                if (dict[address] != data)
                {
                    dict[address] = data;
                    eventArgs = new StoreUpdatedEventArgs(address, data, descriptor);
                }
            }
            else
            {
                dict.Add(address, data);
                eventArgs = new StoreUpdatedEventArgs(address, data, descriptor);
            }

            // raise event if something changed and we have a subscriber
            if ((raiseEvent != null) & (eventArgs != null))
            {
                raiseEvent(this, eventArgs);
            }
        }

        private char GetPrintableChar(byte b, char placeholder)
        {
            if ((b > 31) && (b < 127))
            {
                return Convert.ToChar(b);
            }
            return placeholder;
        }

        private bool GetDataFromDictionary(Dictionary<int, object> dict, int address, char descriptor, out string dataValue, out string ascii, out char descriptorChar)
        {
            dataValue = "??";
            ascii = "?";
            descriptorChar = '?';

            if (dict.ContainsKey(address))
            {
                descriptorChar = descriptor;
                object data = dict[address];
                if (data is byte)
                {
                    byte b = (byte)data;
                    ascii = GetPrintableChar(b, '.').ToString();
                    dataValue = b.ToString("X2");
                    return true;
                }
                if (data is UInt16)
                {
                    UInt16 w = (UInt16)data;
                    ascii = GetPrintableChar((byte) (w >> 8), '.').ToString() + GetPrintableChar((byte) (w & 255), '.').ToString();
                    dataValue = w.ToString("X4");
                    return true;
                }
            }
            return false;
        }

    }
}
