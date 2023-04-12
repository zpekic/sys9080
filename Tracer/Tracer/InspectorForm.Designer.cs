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
            this.tabPageMem = new System.Windows.Forms.TabPage();
            this.tabPageIO = new System.Windows.Forms.TabPage();
            this.tabPageCode = new System.Windows.Forms.TabPage();
            this.textBox1 = new System.Windows.Forms.TextBox();
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
            this.tabControl1.Name = "tabControl1";
            this.tabControl1.SelectedIndex = 0;
            this.tabControl1.Size = new System.Drawing.Size(800, 450);
            this.tabControl1.TabIndex = 0;
            // 
            // tabPageMem
            // 
            this.tabPageMem.Location = new System.Drawing.Point(4, 22);
            this.tabPageMem.Name = "tabPageMem";
            this.tabPageMem.Padding = new System.Windows.Forms.Padding(3);
            this.tabPageMem.Size = new System.Drawing.Size(792, 424);
            this.tabPageMem.TabIndex = 0;
            this.tabPageMem.Text = "Memory";
            this.tabPageMem.ToolTipText = "Display traced memory locations";
            this.tabPageMem.UseVisualStyleBackColor = true;
            // 
            // tabPageIO
            // 
            this.tabPageIO.Location = new System.Drawing.Point(4, 22);
            this.tabPageIO.Name = "tabPageIO";
            this.tabPageIO.Padding = new System.Windows.Forms.Padding(3);
            this.tabPageIO.Size = new System.Drawing.Size(792, 424);
            this.tabPageIO.TabIndex = 1;
            this.tabPageIO.Text = "I/O";
            this.tabPageIO.ToolTipText = "Display traced I/O locations";
            this.tabPageIO.UseVisualStyleBackColor = true;
            // 
            // tabPageCode
            // 
            this.tabPageCode.Controls.Add(this.textBox1);
            this.tabPageCode.Location = new System.Drawing.Point(4, 22);
            this.tabPageCode.Name = "tabPageCode";
            this.tabPageCode.Size = new System.Drawing.Size(792, 424);
            this.tabPageCode.TabIndex = 2;
            this.tabPageCode.Text = "Code";
            this.tabPageCode.ToolTipText = "Assembler listing file for execution tracing";
            this.tabPageCode.UseVisualStyleBackColor = true;
            // 
            // textBox1
            // 
            this.textBox1.Dock = System.Windows.Forms.DockStyle.Fill;
            this.textBox1.Location = new System.Drawing.Point(0, 0);
            this.textBox1.Name = "textBox1";
            this.textBox1.ReadOnly = true;
            this.textBox1.Size = new System.Drawing.Size(792, 20);
            this.textBox1.TabIndex = 0;
            this.textBox1.Multiline = true;
            this.textBox1.ScrollBars = System.Windows.Forms.ScrollBars.Both;
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
        private System.Windows.Forms.TextBox textBox1;
    }
}