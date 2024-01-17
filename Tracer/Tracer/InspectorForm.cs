using System;
using System.Drawing;
using System.Linq;
using System.IO;
using System.Windows.Forms;
using System.Collections.Generic;
using System.Threading;

namespace Tracer
{
    public partial class InspectorForm : Form
    {
        public delegate void HighlightCode(string instructionKey, bool fetch);
        public HighlightCode codeHighlightDelegate;
        public delegate void RegisterValue(string registerValue, bool dummy);
        public RegisterValue registerValueDelegate;

        private StoreMap<StoreMapRow> memoryMap; 
        private StoreMap<StoreMapRow> ioMap;
        private CpuBroker cpuBroker;
        private string codeFile = string.Empty;
        private DataGridView dataGridView1 = new DataGridView();
        private DataGridView dataGridView2 = new DataGridView();
        private List<int> breakPointLineList = new List<int>();
        private string previousMatch = string.Empty;
        private List<string> labelList = new List<string>();

        // Declare store map rows to store data for a row being edited (not used!)
        private StoreMapRow memSMRInEdit, ioSMRInEdit;

        // Declare a variable to store the index of a row being edited.
        // A value of -1 indicates that there is no row currently in edit.
        private int memRowInEdit = -1;
        private int ioRowInEdit = -1;

        // Declare a variable to indicate the commit scope.
        // Set this value to false to use cell-level commit scope.
        private bool rowScopeCommit = true;
        private int stepCount = 0;
        //private FileSystemWatcher fsw = null;

        internal InspectorForm(string codeFile, string caption, StoreMap<StoreMapRow> memoryMap, StoreMap<StoreMapRow> ioMap, CpuBroker cpuBroker, List<string> labelList)
        {
            InitializeComponent();

            this.Load += new EventHandler(InspectorForm_Load);
            this.Text = caption;
            this.tabPageMem.Controls.Add(dataGridView1);
            this.tabPageIO.Controls.Add(dataGridView2);
            this.codeFile = codeFile;
            this.memoryMap = memoryMap;
            this.ioMap = ioMap;
            this.cpuBroker = cpuBroker;
            this.labelList = labelList;
            this.codeHighlightDelegate = new HighlightCode(HighlightCodeMethod);
            this.registerValueDelegate = new RegisterValue(RegisterValueMethod);
        }

        //private void CpuBroker_CodeSearchEvent(object sender, CodeSearchEventArgs e)
        //{
        //    this.Invoke(new MethodInvoker(delegate (string) {
        //        HighlightCode(e.InstructionKey);
        //    }));
        //}

        public void RegisterValueMethod(string registerValue, bool dummy)
        {
            this.Text = registerValue;
        }

        public void HighlightCodeMethod(string matchKey, bool fetch)
        {
            if (this.textBoxCode != null)
            {
                if (!string.IsNullOrEmpty(previousMatch))
                {
                    textBoxCode.Find(previousMatch, 0, RichTextBoxFinds.MatchCase | RichTextBoxFinds.WholeWord);
                    this.textBoxCode.SelectionColor = this.textBoxCode.ForeColor;
                    this.textBoxCode.SelectionBackColor = this.textBoxCode.BackColor;
                }
                int foundIndex = this.textBoxCode.Find(matchKey, 0, RichTextBoxFinds.MatchCase | RichTextBoxFinds.WholeWord);
                if (foundIndex < 0)
                {
                    // only warn for code, for memory read assume it was not in code memory
                    if (fetch)
                    {
                        Console.Beep();
                        previousMatch = string.Empty;
                    }
                }
                else
                {

                    //int line = this.textBox1.GetLineFromCharIndex(foundIndex);
                    //int startSelect = this.textBox1.GetFirstCharIndexFromLine(line);
                    //int endSelect = foundIndex + 8;
                    this.textBoxCode.SelectionColor = fetch ? Color.Yellow : Color.White;
                    this.textBoxCode.SelectionBackColor = fetch ? Color.Blue : Color.LightBlue;
                    //this.textBox1.Select(startSelect, endSelect);
                    //this.textBox1.ScrollToCaret();
                    stepCount++;
                    previousMatch = matchKey;
                    //this.textBox1.Refresh();
                }
            }
        }
        
        public void SelectTab(char tabSel)
        {
            for(int i = 0; i < this.tabControl1.TabCount; i++)
            {
                if (this.tabControl1.TabPages[i].Tag.ToString().Contains(tabSel))
                {
                    this.tabControl1.SelectTab(i);
                    return;
                }
            }
        }

        private void InspectorForm_Load(object sender, EventArgs e)
        {
            // 1st tab contains code text
            if (!string.IsNullOrEmpty(codeFile))
            {
                string fileNameAndExtension = codeFile.Substring(codeFile.LastIndexOf("\\") + 1);

                textBoxCode.Text = File.ReadAllText(codeFile, System.Text.Encoding.UTF8);
                textBoxCode.Font = new Font(FontFamily.GenericMonospace, 12.0f, FontStyle.Regular);
                tabControl1.TabPages["tabPageCode"].Text = $"Code ({fileNameAndExtension})";

                textBoxCode.KeyDown += TextBox1_KeyDown;
                this.textBoxCode.ShowSelectionMargin = true;

                //fsw = new FileSystemWatcher(codeFile);
            }

            // label combobox
            comboBoxLabel.Font = new Font(FontFamily.GenericMonospace, 12.0f, FontStyle.Regular);
            if (labelList.Count > 0)
            {
                foreach (string label in labelList)
                {
                    this.comboBoxLabel.Items.Add(label);
                }
                comboBoxLabel.SelectedValueChanged += ComboBoxLabel_SelectedValueChanged;
                comboBoxLabel.Enabled = true;
            }
            else
            {
                comboBoxLabel.Enabled = false;
            }

            // breakpoint combobox
            comboBoxBreakpoint.Font = new Font(FontFamily.GenericMonospace, 12.0f, FontStyle.Regular);
            comboBoxBreakpoint.SelectedValueChanged += ComboBoxBreakpoint_SelectedValueChanged;
            comboBoxBreakpoint.Enabled = false;

            // 2nd tab contains Memory data grid
            InitGridView(this.dataGridView1, memoryMap);
            // Connect the virtual-mode events to event handlers.
            this.dataGridView1.CellValueNeeded += new DataGridViewCellValueEventHandler(dataGridView1_CellValueNeeded);
            this.dataGridView1.NewRowNeeded += new DataGridViewRowEventHandler(dataGridView1_NewRowNeeded);
            this.dataGridView1.RowDirtyStateNeeded += new QuestionEventHandler(dataGridView1_RowDirtyStateNeeded);
            // subscribe to store map changes!
            this.memoryMap.StoreUpdatedEvent += MemoryMap_StoreUpdatedEvent;

            // 3rd tab contains IO data grid
            InitGridView(this.dataGridView2, ioMap);
            // Connect the virtual-mode events to event handlers.
            this.dataGridView2.CellValueNeeded += new DataGridViewCellValueEventHandler(dataGridView2_CellValueNeeded);
            this.dataGridView2.NewRowNeeded += new DataGridViewRowEventHandler(dataGridView2_NewRowNeeded);
            this.dataGridView2.RowDirtyStateNeeded += new QuestionEventHandler(dataGridView2_RowDirtyStateNeeded);
            // subscribe to store map changes!
            this.ioMap.StoreUpdatedEvent += IoMap_StoreUpdatedEvent;

            // subscribe to CPU broker changes!
            //this.cpuBroker.CodeSearchEvent += CpuBroker_CodeSearchEvent;
            cpuBroker.InspectorReady = true;
        }

        private void ComboBoxBreakpoint_SelectedValueChanged(object sender, EventArgs e)
        {
            this.textBoxCode.Find($"{this.comboBoxBreakpoint.SelectedItem}");
            this.textBoxCode.ScrollToCaret();
        }

        private void ComboBoxLabel_SelectedValueChanged(object sender, EventArgs e)
        {
            this.textBoxCode.Find($"{this.comboBoxLabel.SelectedItem}:");
            this.textBoxCode.ScrollToCaret();
        }

        public string GetCodeLine(int line)
        {
            EnsureInspectorIsReady();

            return this.textBoxCode.Lines[line];
        }

        private void UpdateBreakpointComboBox(string line, bool add)
        {
            string lineNumber;
            string key;
            string label;
            string code;

            if (cpuBroker.DecomposeInstructionLine(line, out lineNumber, out key, out label, out code))
            {
                string item = string.IsNullOrEmpty(label) ? (key + ".") : (label + ":");

                if (add)
                {
                    // add
                    comboBoxBreakpoint.Items.Add(item);
                }
                else
                {
                    // remove
                    comboBoxBreakpoint.Items.Remove(item);
                }
            }
            comboBoxBreakpoint.Enabled = (comboBoxBreakpoint.Items.Count > 0);
        }

        public bool ToggleBreakpoint(string instructionKey)
        {
            string line = string.Empty;
            int lineIndex = FindLineByKey(instructionKey, out line);

            if (lineIndex >= 0)
            {
                if (cpuBroker.breakpointDictionary.ContainsKey(instructionKey))
                {
                    cpuBroker.breakpointDictionary.Remove(instructionKey);
                    UpdateBreakpointComboBox(line, false);

                    this.textBoxCode.Find(line);
                    this.textBoxCode.SelectionColor = this.textBoxCode.ForeColor;
                    this.textBoxCode.SelectionBackColor = this.textBoxCode.BackColor;
                    //MessageBox.Show(this, $"Removed from '{line}'", "Breakpoint", MessageBoxButtons.OK);
                }
                else
                {
                    cpuBroker.breakpointDictionary.Add(instructionKey, lineIndex);
                    UpdateBreakpointComboBox(line, true);

                    this.textBoxCode.Find(line);
                    this.textBoxCode.SelectionColor = Color.White;
                    this.textBoxCode.SelectionBackColor = Color.Red;
                    //MessageBox.Show(this, $"Added at '{line}'", "Breakpoint", MessageBoxButtons.OK);
                }

                return true;
            }
            else
            {
                //MessageBox.Show(this, $"Cannot find line with instruction '{instructionKey}'", "Breakpoint", MessageBoxButtons.OK );
            }
            return false;
        }

        private void EnsureInspectorIsReady()
        {
            while (!cpuBroker.InspectorReady)
            {
                Thread.Sleep(100);
            }
        }

        private int FindLineByKey(string key, out string line)
        {
            line = string.Empty;

            EnsureInspectorIsReady();
            for (int li = 0; li < this.textBoxCode.Lines.Length; li++)
            {
                line = this.textBoxCode.Lines[li];
                if (line.Contains(key))
                {
                    return li;
                }
            }

            return -1; // not found
        }

        private void TextBox1_KeyDown(object sender, KeyEventArgs e)
        {
            if (e.KeyCode == Keys.F9)
            {
                string selectedLine = this.textBoxCode.SelectedText;
                string breakpointKey;

                if (string.IsNullOrEmpty(selectedLine))
                {
                    MessageBox.Show(this, "Error setting or clearing breakpoint.\nSelect line in code window by clicking to the left margin space", "Tracer", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
                else
                {
                    selectedLine = selectedLine.TrimEnd(new char[] { '\r', '\n'});
                    int ficl = this.textBoxCode.Find(selectedLine);
                    //int li = this.textBox1.GetLineFromCharIndex(ficl);
                    if (ficl >= 0)
                    {
                        for (int li = 0; li < this.textBoxCode.Lines.Length; li++)
                        {
                            string line = this.textBoxCode.Lines[li];

                            if (cpuBroker.IsMatchingCodeLine(selectedLine, line, out breakpointKey))
                            { 
                                this.textBoxCode.Enabled = true;

                                if (cpuBroker.breakpointDictionary.ContainsValue(li))
                                {
                                    cpuBroker.breakpointDictionary.Remove(breakpointKey);
                                    UpdateBreakpointComboBox(line, false);

                                    this.textBoxCode.Find(line);
                                    this.textBoxCode.SelectionColor = this.textBoxCode.ForeColor;
                                    this.textBoxCode.SelectionBackColor = this.textBoxCode.BackColor;
                                }
                                else
                                {
                                    cpuBroker.breakpointDictionary.Add(breakpointKey, li);
                                    UpdateBreakpointComboBox(line, true);

                                    this.textBoxCode.Find(line);
                                    this.textBoxCode.SelectionColor = Color.White;
                                    this.textBoxCode.SelectionBackColor = Color.Red;
                                }

                                // bail because breakpoint has been set or removed
                                return;
                            }
                        }
                    }
                    else
                    {
                        Console.Beep();
                    }
                }
            }
        }

        private void InitGridView(DataGridView dgv, StoreMap<StoreMapRow> sm)
        {
            // Enable virtual mode.
            dgv.VirtualMode = true;

            // styling
            dgv.RowsDefaultCellStyle.Font = new Font(FontFamily.GenericMonospace, 8);

            // Add columns to the DataGridView.
            foreach (StoreMapColumn smc in sm.Columns)
            {
                DataGridViewTextBoxColumn tbc = new DataGridViewTextBoxColumn();
                tbc.HeaderText = smc.Text;
                tbc.Name = smc.Name;
                dgv.Columns.Add(tbc);
            }
            dgv.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.DisplayedCells;
            dgv.Dock = DockStyle.Fill;
 
            // Set the row count, no new records will be added
            dgv.RowCount = (sm.Size >> 4) + 1;
            dgv.ReadOnly = true;
        }

        private void IoMap_StoreUpdatedEvent(object sender, StoreUpdatedEventArgs e)
        {
            this.dataGridView2.InvalidateRow(e.Address >> 4);
        }

        private void MemoryMap_StoreUpdatedEvent(object sender, StoreUpdatedEventArgs e)
        {
            this.dataGridView1.InvalidateRow(e.Address >> 4);
        }


        private void PaintCell(DataGridView dgv, int row, int col, char descriptor)
        { 
            switch (descriptor)
            {
                case 'F':
                    dgv.Rows[row].Cells[col].Style.BackColor = Color.Blue;
                    break;
                case 'R':
                    dgv.Rows[row].Cells[col].Style.BackColor = Color.Aqua;
                    break;
                case 'W':
                    dgv.Rows[row].Cells[col].Style.BackColor = Color.Bisque;
                    break;
                case 'A':
                    dgv.Rows[row].Cells[col].Style.BackColor = Color.Pink;
                    break;
                case 'H':
                    dgv.Rows[row].Cells[col].Style.BackColor = Color.CornflowerBlue;
                    break;
                default:
                    break;
            }
        }

        #region Mem grid event handlers
        private void dataGridView1_CellValueNeeded(object sender,
            System.Windows.Forms.DataGridViewCellValueEventArgs e)
        {
            // If this is the row for new records, no values are needed.
            if (e.RowIndex == this.dataGridView1.RowCount - 1) return;

            StoreMapRow smrTmp = new StoreMapRow(0);

            // Store a reference to the Customer object for the row being painted.
            if (e.RowIndex == memRowInEdit)
            {
                smrTmp = this.memSMRInEdit;
            }
            else
            {
                smrTmp = memoryMap.GetStoreMapRow(e.RowIndex << 4);
            }

            // Set the cell value to paint using the Customer object retrieved.
            // get property name by reflection
            e.Value = (string)smrTmp[this.dataGridView1.Columns[e.ColumnIndex].Name];
            PaintCell((DataGridView)sender, e.RowIndex, e.ColumnIndex, smrTmp.Descriptor[e.ColumnIndex]);
        }

        private void dataGridView1_NewRowNeeded(object sender,
            System.Windows.Forms.DataGridViewRowEventArgs e)
        {
            // Create a new Customer object when the user edits
            // the row for new records.
            this.memSMRInEdit = new StoreMapRow(0);
            this.memRowInEdit = this.dataGridView1.Rows.Count - 1;
        }

        private void dataGridView1_RowDirtyStateNeeded(object sender,
            System.Windows.Forms.QuestionEventArgs e)
        {
            if (!rowScopeCommit)
            {
                // In cell-level commit scope, indicate whether the value
                // of the current cell has been modified.
                e.Response = this.dataGridView1.IsCurrentCellDirty;
            }
        }
#endregion

        #region IO grid event handlers
        private void dataGridView2_CellValueNeeded(object sender,
            System.Windows.Forms.DataGridViewCellValueEventArgs e)
        {
            // If this is the row for new records, no values are needed.
            if (e.RowIndex == this.dataGridView2.RowCount - 1) return;

            StoreMapRow smrTmp = new StoreMapRow(0);

            // Store a reference to the Customer object for the row being painted.
            if (e.RowIndex == ioRowInEdit)
            {
                smrTmp = this.ioSMRInEdit;
            }
            else
            {
                smrTmp = ioMap.GetStoreMapRow(e.RowIndex << 4);
            }

            // Set the cell value to paint using the Customer object retrieved.
            // get property name by reflection
            e.Value = (string)smrTmp[this.dataGridView2.Columns[e.ColumnIndex].Name];
            PaintCell((DataGridView)sender, e.RowIndex, e.ColumnIndex, smrTmp.Descriptor[e.ColumnIndex]);
        }

        private void dataGridView2_NewRowNeeded(object sender,
            System.Windows.Forms.DataGridViewRowEventArgs e)
        {
            // Create a new Customer object when the user edits
            // the row for new records.
            this.ioSMRInEdit = new StoreMapRow(0);
            this.ioRowInEdit = this.dataGridView2.Rows.Count - 1;
        }

        private void dataGridView2_RowDirtyStateNeeded(object sender,
            System.Windows.Forms.QuestionEventArgs e)
        {
            if (!rowScopeCommit)
            {
                // In cell-level commit scope, indicate whether the value
                // of the current cell has been modified.
                e.Response = this.dataGridView2.IsCurrentCellDirty;
            }
        }
        #endregion

    }
}

