using System;
using System.Collections.Generic;
using System.Text;

namespace Tracer
{
    public class CodeSearchEventArgs : EventArgs
    {
        public string InstructionKey;
        public char Descriptor;

        public CodeSearchEventArgs(string instructionKey, char descriptor)
        {
            this.InstructionKey = instructionKey;
            this.Descriptor = descriptor;
        }
    }

    class CpuBroker
    {
        // TODO: don't be lazy, make it private and access through helper methods
        public Dictionary<string, int> breakpointDictionary = new Dictionary<string, int>();
        public bool InspectorReady = false;

        // HACKHACK - this should go to a separate CodeMap class but too lazy
        public event EventHandler<CodeSearchEventArgs> CodeSearchEvent;
        private Dictionary<string, string> RegValDictionary = new Dictionary<string, string>();
        private static Dictionary<char, string> Hex2Bin = new Dictionary<char, string> 
        {
            {'0', "0000"},
            {'1', "0001"},
            {'2', "0010"},
            {'3', "0011"},
            {'4', "0100"},
            {'5', "0101"},
            {'6', "0110"},
            {'7', "0111"},
            {'8', "1000"},
            {'9', "1001"},
            {'A', "1010"},
            {'B', "1011"},
            {'C', "1100"},
            {'D', "1101"},
            {'E', "1110"},
            {'F', "1111"}
        };

        public CpuBroker(int dataWidth)
        {
            switch (dataWidth)
            {
                case 8:
                    RegValDictionary.Add("AF", "????");
                    RegValDictionary.Add("BC", "????");
                    RegValDictionary.Add("DE", "????");
                    RegValDictionary.Add("HL", "????");
                    RegValDictionary.Add("PC", "????");
                    RegValDictionary.Add("SP", "????");
                    break;
                case 16:
                    RegValDictionary.Add("P", "????");
                    RegValDictionary.Add("A", "????");
                    RegValDictionary.Add("X", "????");
                    RegValDictionary.Add("Y", "????");
                    RegValDictionary.Add("S", "????");
                    RegValDictionary.Add("F", "????????????????");
                    break;
                default:
                    break;
            }
        }

        public bool UpdateRegister(string recordValue)
        {
            string[] nameValuePair = recordValue.Split('=');
            if (nameValuePair.Length == 2)
            {
                string name = nameValuePair[0].Trim().ToUpper();
                string value = nameValuePair[1].Trim().ToUpper();

                if (name.Equals("F"))
                {
                    value = Hex2Bin[value[0]] + Hex2Bin[value[1]] + Hex2Bin[value[2]] + Hex2Bin[value[3]];
                }

                if (RegValDictionary.ContainsKey(name))
                {
                    RegValDictionary[name] = value;
                }
                else
                {
                    throw new InvalidOperationException($"Register key {name} is unknown");
                }

                return true;
            }
            return false;
        }

        public string GetRegisterState()
        {
            StringBuilder sb = new StringBuilder();
            foreach (string key in RegValDictionary.Keys)
            {
                sb.Append(key);
                sb.Append("=");
                sb.Append(RegValDictionary[key]);
                sb.Append(" ");
            }

            return sb.ToString();
        }

        public bool IsMatchingCodeLine(string selectedLine, string line, out string breakpointKey)
        {
            //--L0048@001B 000A.CPY, M[POP];
            //--r_p = 0000, r_a = 000, r_x = 000, r_y = 001, r_s = 010;
            //27 => X"0" & O"0" & O"0" & O"1" & O"2",

            breakpointKey = string.Empty;
            if (line.StartsWith("-- L") && (line[18] == '.'))
            {
                if (selectedLine.Equals(line))
                {
                    breakpointKey = line.Substring(9, 9); // TODO: make this less rigid?
                    return true;
                }
            }

            return false;
        }

        public void InstructionFetch(string instructionKey)
        {
            EventHandler<CodeSearchEventArgs> raiseEvent = CodeSearchEvent;
            CodeSearchEventArgs eventArgs = null;

            eventArgs = new CodeSearchEventArgs(instructionKey, 'F');

            // raise event if something changed and we have a subscriber
            if ((raiseEvent != null) & (eventArgs != null))
            {
                raiseEvent(this, eventArgs);
            }
        }

    }
}
