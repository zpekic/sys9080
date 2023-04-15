using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;
using System.Windows.Forms;

namespace Tracer
{
    public partial class InspectorForm : Form
    {
        private StoreMap<StoreMapRow> memoryMap; 
        private StoreMap<StoreMapRow> ioMap;
        private string codeFile = string.Empty;
        private DataGridView dataGridView1 = new DataGridView();

        // Declare a Customer object to store data for a row being edited.
        private StoreMapRow smrInEdit;

        // Declare a variable to store the index of a row being edited.
        // A value of -1 indicates that there is no row currently in edit.
        private int rowInEdit = -1;

        // Declare a variable to indicate the commit scope.
        // Set this value to false to use cell-level commit scope.
        private bool rowScopeCommit = true;

        internal InspectorForm(string codeFile, string caption, StoreMap<StoreMapRow> memoryMap, StoreMap<StoreMapRow> ioMap)
        {
            InitializeComponent();

            this.dataGridView1.Dock = DockStyle.Fill;
            this.dataGridView1.ReadOnly = true;
            this.Load += new EventHandler(InspectorForm_Load);
            this.Text = caption;
            this.tabPageMem.Controls.Add(dataGridView1);
            this.codeFile = codeFile;
            this.memoryMap = memoryMap;
            this.ioMap = ioMap;
        }

        private void InspectorForm_Load(object sender, EventArgs e)
        {
            if (!string.IsNullOrEmpty(codeFile))
            {
                string fileNameAndExtension = codeFile.Substring(codeFile.LastIndexOf("\\") + 1);

                textBox1.Text = File.ReadAllText(codeFile);
                textBox1.Font = new Font(FontFamily.GenericMonospace, 12.0f, FontStyle.Regular);
                tabControl1.TabPages["tabPageCode"].Text = $"Code ({fileNameAndExtension})";
            }

            // Enable virtual mode.
            this.dataGridView1.VirtualMode = true;

            // Connect the virtual-mode events to event handlers.
            this.dataGridView1.CellValueNeeded += new
                DataGridViewCellValueEventHandler(dataGridView1_CellValueNeeded);
            this.dataGridView1.CellValuePushed += new
                DataGridViewCellValueEventHandler(dataGridView1_CellValuePushed);
            this.dataGridView1.NewRowNeeded += new
                DataGridViewRowEventHandler(dataGridView1_NewRowNeeded);
            this.dataGridView1.RowValidated += new
                DataGridViewCellEventHandler(dataGridView1_RowValidated);
            this.dataGridView1.RowDirtyStateNeeded += new
                QuestionEventHandler(dataGridView1_RowDirtyStateNeeded);
            this.dataGridView1.CancelRowEdit += new
                QuestionEventHandler(dataGridView1_CancelRowEdit);
            this.dataGridView1.UserDeletingRow += new
                DataGridViewRowCancelEventHandler(dataGridView1_UserDeletingRow);

            // Add columns to the DataGridView.
            foreach (StoreMapColumn smc in memoryMap.Columns)
            {
                DataGridViewTextBoxColumn tbc = new DataGridViewTextBoxColumn();
                tbc.HeaderText = smc.Text;
                tbc.Name = smc.Name;
                this.dataGridView1.Columns.Add(tbc);
            }
            this.dataGridView1.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.DisplayedCells;

            // Set the row count, including the row for new records.
            this.dataGridView1.RowCount = (memoryMap.Size >> 4);

            // subscribe to store map changes!
            this.memoryMap.StoreUpdatedEvent += MemoryMap_StoreUpdatedEvent;
        }

        private void MemoryMap_StoreUpdatedEvent(object sender, StoreUpdatedEventArgs e)
        {
            this.dataGridView1.InvalidateRow(e.Address >> 4);
        }

        private void dataGridView1_CellValueNeeded(object sender,
            System.Windows.Forms.DataGridViewCellValueEventArgs e)
        {
            // If this is the row for new records, no values are needed.
            if (e.RowIndex == this.dataGridView1.RowCount - 1) return;

            StoreMapRow smrTmp = new StoreMapRow(0);

            // Store a reference to the Customer object for the row being painted.
            if (e.RowIndex == rowInEdit)
            {
                smrTmp = this.smrInEdit;
            }
            else
            {
                smrTmp = memoryMap.GetStoreMapRow(e.RowIndex << 4);
            }

            // Set the cell value to paint using the Customer object retrieved.
            // get property name by reflection
            e.Value = (string)smrTmp[this.dataGridView1.Columns[e.ColumnIndex].Name];
            PaintCell(e.RowIndex, e.ColumnIndex, smrTmp.Descriptor[e.ColumnIndex]);
        }

        private void PaintCell(int row, int col, char descriptor)
        { 
            switch (descriptor)
            {
                case 'F':
                    this.dataGridView1.Rows[row].Cells[col].Style.BackColor = Color.Aqua;
                    break;
                case 'R':
                    this.dataGridView1.Rows[row].Cells[col].Style.BackColor = Color.Blue;
                    break;
                case 'W':
                    this.dataGridView1.Rows[row].Cells[col].Style.BackColor = Color.Bisque;
                    break;
                case 'A':
                    this.dataGridView1.Rows[row].Cells[col].Style.BackColor = Color.Pink;
                    break;
                case 'H':
                    this.dataGridView1.Rows[row].Cells[col].Style.BackColor = Color.CornflowerBlue;
                    break;
                default:
                    break;
            }
        }

        private void dataGridView1_CellValuePushed(object sender,
            System.Windows.Forms.DataGridViewCellValueEventArgs e)
        {
            StoreMapRow smrTmp = new StoreMapRow(0);

            //// Store a reference to the Customer object for the row being edited.
            //if (e.RowIndex < this.customers.Count)
            //{
            //    // If the user is editing a new row, create a new Customer object.
            //    this.smrInEdit = new StoreMapRow(0);
            //    smrTmp = this.smrInEdit;
            //    this.rowInEdit = e.RowIndex;
            //}
            //else
            //{
            //    smrTmp = this.smrInEdit;
            //}

            //// Set the appropriate Customer property to the cell value entered.
            //String newValue = e.Value as String;
            //// set property name by reflection
            //smrTmp[this.dataGridView1.Columns[e.ColumnIndex].Name] = newValue;
        }

        private void dataGridView1_NewRowNeeded(object sender,
            System.Windows.Forms.DataGridViewRowEventArgs e)
        {
            // Create a new Customer object when the user edits
            // the row for new records.
            this.smrInEdit = new StoreMapRow(0);
            this.rowInEdit = this.dataGridView1.Rows.Count - 1;
        }

        private void dataGridView1_RowValidated(object sender,
            System.Windows.Forms.DataGridViewCellEventArgs e)
        {
            // Save row changes if any were made and release the edited
            // Customer object if there is one.
            //if (e.RowIndex >= this.customers.Count &&
            //    e.RowIndex != this.dataGridView1.Rows.Count - 1)
            //{
            //    // Add the new Customer object to the data store.
            //    this.customers.Add(this.customerInEdit);
            //    this.customerInEdit = null;
            //    this.rowInEdit = -1;
            //}
            //else if (this.customerInEdit != null &&
            //    e.RowIndex < this.customers.Count)
            //{
            //    // Save the modified Customer object in the data store.
            //    this.customers[e.RowIndex] = this.customerInEdit;
            //    this.customerInEdit = null;
            //    this.rowInEdit = -1;
            //}
            //else if (this.dataGridView1.ContainsFocus)
            //{
            //    this.customerInEdit = null;
            //    this.rowInEdit = -1;
            //}
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

        private void dataGridView1_CancelRowEdit(object sender,
            System.Windows.Forms.QuestionEventArgs e)
        {
            //if (this.rowInEdit == this.dataGridView1.Rows.Count - 2 &&
            //    this.rowInEdit == this.customers.Count)
            //{
            //    // If the user has canceled the edit of a newly created row,
            //    // replace the corresponding Customer object with a new, empty one.
            //    this.smrInEdit = new StoreMapRow(0);
            //}
            //else
            //{
            //    // If the user has canceled the edit of an existing row,
            //    // release the corresponding Customer object.
            //    this.smrInEdit = new StoreMapRow(0);
            //    this.rowInEdit = -1;
            //}
        }

        private void dataGridView1_UserDeletingRow(object sender,
            System.Windows.Forms.DataGridViewRowCancelEventArgs e)
        {
            //if (e.Row.Index < this.customers.Count)
            //{
            //    // If the user has deleted an existing row, remove the
            //    // corresponding Customer object from the data store.
            //    this.customers.RemoveAt(e.Row.Index);
            //}

            //if (e.Row.Index == this.rowInEdit)
            //{
            //    // If the user has deleted a newly created row, release
            //    // the corresponding Customer object.
            //    this.rowInEdit = -1;
            //    this.smrInEdit = new StoreMapRow(0);
            //}
        }
    }
}

