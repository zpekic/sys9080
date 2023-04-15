using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

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
            Descriptor = "????????????????";
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

    class StoreMap<T>
    {
        public readonly int Size = -1;
        public readonly bool ShowAscii = false;
        private List<StoreMapColumn> columns = new List<StoreMapColumn>();
        // these track the "imagined" external memory / IO space as seen by the CPU
        private Dictionary<int, byte> readDictionary = new Dictionary<int, byte>();
        private Dictionary<int, byte> writeDictionary = new Dictionary<int, byte>();
        private Dictionary<int, byte> fetchDictionary = new Dictionary<int, byte>();

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
            string bytePropName, bytePropValue;
            char asciiChar;
            char descriptorChar;
            StringBuilder sbAscii = new StringBuilder();
            StringBuilder sbDescriptor = new StringBuilder();

            for (int i = 0; i < 16; i++)
            {
                //bytePropName = "x" + "0123456789ABCDEF"[i];

                if (!GetDataFromDictionary(fetchDictionary, address + i, 'F', out bytePropValue, out asciiChar, out descriptorChar))
                {
                    if (!GetDataFromDictionary(readDictionary, address + i, 'R', out bytePropValue, out asciiChar, out descriptorChar))
                    {
                        GetDataFromDictionary(writeDictionary, address + i, 'W', out bytePropValue, out asciiChar, out descriptorChar);
                    }
                }
                sbAscii.Append(asciiChar);
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

            smr.Ascii = sbAscii.ToString();
            smr.Descriptor = sbDescriptor.ToString();

            return smr;
        }

        public void UpdateFetch(int address, byte data)
        {
            if (readDictionary.ContainsKey(address))
            {
                // TODO: are we executing data?
                readDictionary.Remove(address);
            }
            if (writeDictionary.ContainsKey(address))
            {
                // TODO: are we executing self-modified code?
                writeDictionary.Remove(address);
            }
            AddOrUpdateEntry(fetchDictionary, address, data);
        }

        public void UpdateRead(int address, byte data)
        {
            if (fetchDictionary.ContainsKey(address))
            {
                // TODO: are we reading code?
                fetchDictionary.Remove(address);
            }
            if (writeDictionary.ContainsKey(address))
            {
                // TODO: check if same, warning otherwise
                writeDictionary.Remove(address);
            }
            AddOrUpdateEntry(readDictionary, address, data);
        }

        public void UpdateWrite(int address, byte data)
        {
            if (readDictionary.ContainsKey(address))
            {
                readDictionary.Remove(address);
            }
            if (fetchDictionary.ContainsKey(address))
            {
                // TODO: are we updating code?
                fetchDictionary.Remove(address);
            }
            AddOrUpdateEntry(writeDictionary, address, data);
        }

        private static void AddOrUpdateEntry(Dictionary<int, byte> dict, int address, byte data)
        {
            if (dict.ContainsKey(address))
            {
                if (dict[address] != data)
                {
                    dict[address] = data;
                    // TODO: raise event
                }
            }
            else
            {
                dict.Add(address, data);
                // TODO: raise event
            }
        }

        private bool GetDataFromDictionary(Dictionary<int, byte> dict, int address, char descriptor, out string byteValue, out char asciiChar, out char descriptorChar)
        {
            byteValue = "??";
            asciiChar = '?';
            descriptorChar = '?';

            if (dict.ContainsKey(address))
            {
                descriptorChar = descriptor;
                byte data = dict[address];
                if ((data < 32) || (data > 126))
                {
                    asciiChar = '.';
                }
                else
                {
                    asciiChar = Convert.ToChar(data);
                }
                byteValue = data.ToString("X2");
                return true;
            }
            return false;
        }

    }
}
