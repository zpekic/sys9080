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

        private Dictionary<int, string> lineLabelDictionary = new Dictionary<int, string>();
        private Dictionary<string, int> labelLineDictionary = new Dictionary<string, int>();
        private Dictionary<int, string> lineKeyDictionary = new Dictionary<int, string>();
        private Dictionary<string, int> keyLineDictionary = new Dictionary<string, int>();

        internal InspectorForm(string codeFile, string caption, StoreMap<StoreMapRow> memoryMap, StoreMap<StoreMapRow> ioMap, CpuBroker cpuBroker)
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
                    //this.textBoxCode.ScrollToCaret();
                    stepCount++;
                    previousMatch = matchKey;
                    this.textBoxCode.Refresh();
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
            List<string> labelList = new List<string>();

            // 1st tab contains code text
            if (!string.IsNullOrEmpty(codeFile))
            {
                string fileNameAndExtension = codeFile.Substring(codeFile.LastIndexOf("\\") + 1);
                string lineNumber, instructionKey, label, code;
                bool isReturn, isCall;

                textBoxCode.Text = File.ReadAllText(codeFile, System.Text.Encoding.UTF8);
                textBoxCode.Font = new Font(FontFamily.GenericMonospace, 12.0f, FontStyle.Regular);
                tabControl1.TabPages["tabPageCode"].Text = $"Code ({fileNameAndExtension})";

                textBoxCode.KeyDown += TextBox1_KeyDown;
                this.textBoxCode.ShowSelectionMargin = true;

                // populate all dictionaries which will speed up breakpoint handling later
                for (int line = 0; line < textBoxCode.Lines.Length; line++)
                {
                    if (cpuBroker.DecomposeInstructionLine(textBoxCode.Lines[line], out lineNumber, out instructionKey, out label, out code, out isReturn, out isCall))
                    {
                        if (!string.IsNullOrEmpty(label))
                        {
                            lineLabelDictionary.Add(line, label);
                            labelLineDictionary.Add(label, line);
                            labelList.Add(label + ":");
                        }
                        if (!string.IsNullOrEmpty(instructionKey))
                        {
                            lineKeyDictionary.Add(line, instructionKey);
                            keyLineDictionary.Add(instructionKey, line);
                            if (isReturn)
                            {
                                cpuBroker.returnDictionary.Add(instructionKey, line);
                            }
                            if (isCall)
                            {
                                cpuBroker.callDictionary.Add(instructionKey, line);
                            }
                        }
                    }
                }
                labelList.Sort();
                //fsw = new FileSystemWatcher(codeFile);
            }

            // label combobox and button to add them to breakpoint list
            comboBoxLabel.Font = new Font(FontFamily.GenericMonospace, 12.0f, FontStyle.Regular);
            if (labelList.Count > 0)
            {
                foreach (string label in labelList)
                {
                    this.comboBoxLabel.Items.Add(label);
                }
                comboBoxLabel.SelectedValueChanged += ComboBoxLabel_SelectedValueChanged;
                comboBoxLabel.Enabled = true;
                btnAddBP.Enabled = true;
                btnAddBP.Click += BtnAddBP_Click;
            }
            else
            {
                comboBoxLabel.Enabled = false;
                btnAddBP.Enabled = false;
            }

            // breakpoint combobox and button to remove them
            comboBoxBreakpoint.Font = new Font(FontFamily.GenericMonospace, 12.0f, FontStyle.Regular);
            comboBoxBreakpoint.SelectedValueChanged += ComboBoxBreakpoint_SelectedValueChanged;
            comboBoxBreakpoint.Enabled = false;
            btnDelBP.Enabled = false;
            btnDelBP.Click += BtnDelBP_Click;

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

        private void BtnDelBP_Click(object sender, EventArgs e)
        {
            string selectedBreakpoint = $"{this.comboBoxBreakpoint.SelectedItem}";

            if (string.IsNullOrEmpty(selectedBreakpoint))
            {
                MessageBox.Show(this, "Select breakpoint from the dropdown to remove it", "Tracer - breakpoints", MessageBoxButtons.OK);
            }
            else
            {
                ToggleBreakpointBySelectedText(selectedBreakpoint);
            }
        }

        private void BtnAddBP_Click(object sender, EventArgs e)
        {
            string selectedLabel = $"{this.comboBoxLabel.SelectedItem}";

            if (string.IsNullOrEmpty(selectedLabel))
            {
                MessageBox.Show(this, "Select label from the dropdown to add to breakpoint list", "Tracer - breakpoints", MessageBoxButtons.OK);
            }
            else
            {
                int line = labelLineDictionary[selectedLabel.TrimEnd(new char[] { ':' })];
                ToggleBreakpointBySelectedText(textBoxCode.Lines[line]);
            }
        }

        private void ComboBoxBreakpoint_SelectedValueChanged(object sender, EventArgs e)
        {
            this.textBoxCode.Find($"{this.comboBoxBreakpoint.SelectedItem}");
            this.textBoxCode.ScrollToCaret();
        }

        private void ComboBoxLabel_SelectedValueChanged(object sender, EventArgs e)
        {
            this.textBoxCode.Find($"{this.comboBoxLabel.SelectedItem}");
            this.textBoxCode.ScrollToCaret();
        }

        public string GetCodeLine(int line)
        {
            EnsureInspectorIsReady();

            return this.textBoxCode.Lines[line];
        }

        private void EnsureInspectorIsReady()
        {
            while (!cpuBroker.InspectorReady)
            {
                Thread.Sleep(100);
            }
        }

        public bool ToggleBreakpointByKey(string breakpointKey)
        {
            int line = keyLineDictionary[breakpointKey];
            return ToggleBreakpointBySelectedText(textBoxCode.Lines[line]);
        }

        private bool ToggleBreakpointBySelectedText(string selectedLine)
        {
            if (string.IsNullOrEmpty(selectedLine))
            {
                MessageBox.Show(this, "Error setting or clearing breakpoint.\nSelect line in code window by clicking to the left margin space", "Tracer", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            else
            {
                selectedLine = selectedLine.TrimEnd(new char[] { '\r', '\n' });
                int ficl = this.textBoxCode.Find(selectedLine);
                //int li = this.textBox1.GetLineFromCharIndex(ficl);
                if (ficl >= 0)
                {
                    foreach(int li in lineKeyDictionary.Keys)
                    {
                        string line = this.textBoxCode.Lines[li];
                        string breakpointKey = lineKeyDictionary[li];

                        if (selectedLine.Equals(line, StringComparison.InvariantCultureIgnoreCase))
                        {
                            this.textBoxCode.Enabled = true;

                            if (cpuBroker.breakpointDictionary.ContainsValue(li))
                            {
                                cpuBroker.breakpointDictionary.Remove(breakpointKey);
                                this.textBoxCode.SelectionColor = this.textBoxCode.ForeColor;
                                this.textBoxCode.SelectionBackColor = this.textBoxCode.BackColor;

                                comboBoxBreakpoint.Items.Remove(line);
                            }
                            else
                            {
                                cpuBroker.breakpointDictionary.Add(breakpointKey, li);

                                this.textBoxCode.Find(line);
                                this.textBoxCode.SelectionColor = Color.White;
                                this.textBoxCode.SelectionBackColor = Color.Red;

                                comboBoxBreakpoint.Items.Add(line);
                        }

                        comboBoxBreakpoint.Enabled = (comboBoxBreakpoint.Items.Count > 0);
                        btnDelBP.Enabled = (comboBoxBreakpoint.Items.Count > 0);
                         // bail because breakpoint has been set or removed
                        return true;
                        }
                    }
                }
                else
                {
                    Console.Beep();
                }
            }
            return false;
        }

        private void TextBox1_KeyDown(object sender, KeyEventArgs e)
        {
            if (e.KeyCode == Keys.F9)
            {
                ToggleBreakpointBySelectedText(this.textBoxCode.SelectedText);
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

