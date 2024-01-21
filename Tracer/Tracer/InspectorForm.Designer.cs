namespace Tracer
{
    partial class InspectorForm
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.tabControl1 = new System.Windows.Forms.TabControl();
            this.tabPageCode = new System.Windows.Forms.TabPage();
            this.label1 = new System.Windows.Forms.Label();
            this.comboBoxLabel = new System.Windows.Forms.ComboBox();
            this.textBoxCode = new System.Windows.Forms.RichTextBox();
            this.tabPageMem = new System.Windows.Forms.TabPage();
            this.tabPageIO = new System.Windows.Forms.TabPage();
            this.label2 = new System.Windows.Forms.Label();
            this.comboBoxBreakpoint = new System.Windows.Forms.ComboBox();
            this.btnAddBP = new System.Windows.Forms.Button();
            this.btnDelBP = new System.Windows.Forms.Button();
            this.tabControl1.SuspendLayout();
            this.tabPageCode.SuspendLayout();
            this.SuspendLayout();
            // 
            // tabControl1
            // 
            this.tabControl1.Controls.Add(this.tabPageCode);
            this.tabControl1.Controls.Add(this.tabPageMem);
            this.tabControl1.Controls.Add(this.tabPageIO);
            this.tabControl1.Dock = System.Windows.Forms.DockStyle.Fill;
            this.tabControl1.Location = new System.Drawing.Point(0, 0);
            this.tabControl1.Margin = new System.Windows.Forms.Padding(3, 3, 3, 30);
            this.tabControl1.Name = "tabControl1";
            this.tabControl1.SelectedIndex = 0;
            this.tabControl1.Size = new System.Drawing.Size(800, 450);
            this.tabControl1.TabIndex = 0;
            // 
            // tabPageCode
            // 
            this.tabPageCode.Controls.Add(this.btnDelBP);
            this.tabPageCode.Controls.Add(this.btnAddBP);
            this.tabPageCode.Controls.Add(this.comboBoxBreakpoint);
            this.tabPageCode.Controls.Add(this.label2);
            this.tabPageCode.Controls.Add(this.label1);
            this.tabPageCode.Controls.Add(this.comboBoxLabel);
            this.tabPageCode.Controls.Add(this.textBoxCode);
            this.tabPageCode.Font = new System.Drawing.Font("Lucida Console", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.tabPageCode.Location = new System.Drawing.Point(4, 22);
            this.tabPageCode.Name = "tabPageCode";
            this.tabPageCode.Size = new System.Drawing.Size(792, 424);
            this.tabPageCode.TabIndex = 2;
            this.tabPageCode.Tag = "cC";
            this.tabPageCode.Text = "Code";
            this.tabPageCode.ToolTipText = "Assembler listing file for execution tracing";
            this.tabPageCode.UseVisualStyleBackColor = true;
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Font = new System.Drawing.Font("Lucida Console", 12F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label1.Location = new System.Drawing.Point(8, 6);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(68, 16);
            this.label1.TabIndex = 1;
            this.label1.Text = "Label:";
            // 
            // comboBoxLabel
            // 
            this.comboBoxLabel.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this.comboBoxLabel.Font = new System.Drawing.Font("Lucida Console", 12F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.comboBoxLabel.ItemHeight = 16;
            this.comboBoxLabel.Location = new System.Drawing.Point(95, 3);
            this.comboBoxLabel.Name = "comboBoxLabel";
            this.comboBoxLabel.Size = new System.Drawing.Size(190, 24);
            this.comboBoxLabel.Sorted = true;
            this.comboBoxLabel.TabIndex = 0;
            // 
            // textBoxCode
            // 
            this.textBoxCode.Dock = System.Windows.Forms.DockStyle.Bottom;
            this.textBoxCode.Location = new System.Drawing.Point(0, 33);
            this.textBoxCode.Name = "textBoxCode";
            this.textBoxCode.ReadOnly = true;
            this.textBoxCode.Size = new System.Drawing.Size(792, 391);
            this.textBoxCode.TabIndex = 0;
            this.textBoxCode.Text = "";
            // 
            // tabPageMem
            // 
            this.tabPageMem.Font = new System.Drawing.Font("Lucida Console", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.tabPageMem.Location = new System.Drawing.Point(4, 22);
            this.tabPageMem.Name = "tabPageMem";
            this.tabPageMem.Padding = new System.Windows.Forms.Padding(3);
            this.tabPageMem.Size = new System.Drawing.Size(792, 424);
            this.tabPageMem.TabIndex = 0;
            this.tabPageMem.Tag = "mM";
            this.tabPageMem.Text = "Memory";
            this.tabPageMem.ToolTipText = "Display traced memory locations";
            this.tabPageMem.UseVisualStyleBackColor = true;
            // 
            // tabPageIO
            // 
            this.tabPageIO.Font = new System.Drawing.Font("Lucida Console", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.tabPageIO.Location = new System.Drawing.Point(4, 22);
            this.tabPageIO.Name = "tabPageIO";
            this.tabPageIO.Padding = new System.Windows.Forms.Padding(3);
            this.tabPageIO.Size = new System.Drawing.Size(792, 424);
            this.tabPageIO.TabIndex = 1;
            this.tabPageIO.Tag = "iI";
            this.tabPageIO.Text = "I/O";
            this.tabPageIO.ToolTipText = "Display traced I/O locations";
            this.tabPageIO.UseVisualStyleBackColor = true;
            // 
            // label2
            // 
            this.label2.AutoSize = true;
            this.label2.Font = new System.Drawing.Font("Lucida Console", 12F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label2.Location = new System.Drawing.Point(385, 6);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(118, 16);
            this.label2.TabIndex = 2;
            this.label2.Text = "Breakpoint:";
            // 
            // comboBoxBreakpoint
            // 
            this.comboBoxBreakpoint.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this.comboBoxBreakpoint.Font = new System.Drawing.Font("Lucida Console", 12F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.comboBoxBreakpoint.ItemHeight = 16;
            this.comboBoxBreakpoint.Location = new System.Drawing.Point(509, 3);
            this.comboBoxBreakpoint.Name = "comboBoxBreakpoint";
            this.comboBoxBreakpoint.Size = new System.Drawing.Size(194, 24);
            this.comboBoxBreakpoint.Sorted = true;
            this.comboBoxBreakpoint.TabIndex = 3;
            // 
            // btnAddBP
            // 
            this.btnAddBP.Location = new System.Drawing.Point(291, 4);
            this.btnAddBP.Name = "btnAddBP";
            this.btnAddBP.Size = new System.Drawing.Size(43, 23);
            this.btnAddBP.TabIndex = 4;
            this.btnAddBP.Text = "+";
            this.btnAddBP.UseVisualStyleBackColor = true;
            // 
            // btnDelBP
            // 
            this.btnDelBP.Location = new System.Drawing.Point(709, 4);
            this.btnDelBP.Name = "btnDelBP";
            this.btnDelBP.Size = new System.Drawing.Size(43, 23);
            this.btnDelBP.TabIndex = 5;
            this.btnDelBP.Text = "-";
            this.btnDelBP.UseVisualStyleBackColor = true;
            // 
            // InspectorForm
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(800, 450);
            this.Controls.Add(this.tabControl1);
            this.Name = "InspectorForm";
            this.Text = "InspectorForm";
            this.tabControl1.ResumeLayout(false);
            this.tabPageCode.ResumeLayout(false);
            this.tabPageCode.PerformLayout();
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.TabControl tabControl1;
        private System.Windows.Forms.TabPage tabPageMem;
        private System.Windows.Forms.TabPage tabPageIO;
        private System.Windows.Forms.TabPage tabPageCode;
        private System.Windows.Forms.RichTextBox textBoxCode;
        private System.Windows.Forms.ComboBox comboBoxLabel;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.ComboBox comboBoxBreakpoint;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.Button btnDelBP;
        private System.Windows.Forms.Button btnAddBP;
    }
}