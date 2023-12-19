﻿using System;
using System.Drawing;
using System.Linq;
using System.IO;
using System.Windows.Forms;
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
        private FileSystemWatcher fsw = null;

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
            if (this.textBox1 != null)
            {
                this.textBox1.Undo();
                this.textBox1.DeselectAll();
                this.textBox1.Refresh();
                //this.textBox1.ShowSelectionMargin = true;
                int foundIndex = this.textBox1.Find(matchKey, 0, RichTextBoxFinds.MatchCase | RichTextBoxFinds.WholeWord);
                if (foundIndex < 0)
                {
                    // only warn for code, for memory read assume it was not in code memory
                    if (fetch)
                    {
                        Console.Beep();
                    }
                }
                else
                {

                    int line = this.textBox1.GetLineFromCharIndex(foundIndex);
                    int startSelect = this.textBox1.GetFirstCharIndexFromLine(line);
                    int endSelect = foundIndex + 8;
                    this.textBox1.SelectionColor = fetch ? Color.Yellow : Color.White;
                    this.textBox1.SelectionBackColor = fetch ? Color.Blue : Color.LightBlue;
                    this.textBox1.Select(startSelect, endSelect);
                    if ((stepCount % 4) == 0)
                    {
                        this.textBox1.ScrollToCaret();
                    }
                    stepCount++;
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

                textBox1.Text = File.ReadAllText(codeFile, System.Text.Encoding.UTF8);
                textBox1.Font = new Font(FontFamily.GenericMonospace, 12.0f, FontStyle.Regular);
                tabControl1.TabPages["tabPageCode"].Text = $"Code ({fileNameAndExtension})";
                //fsw = new FileSystemWatcher(codeFile);
            }

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

