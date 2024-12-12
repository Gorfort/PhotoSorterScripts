namespace FilesSorterV1
{
    partial class Form1
    {
        /// <summary>
        ///  Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        ///  Clean up any resources being used.
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
        ///  Required method for Designer support - do not modify
        ///  the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(Form1));
            btnSource = new Button();
            progressBar1 = new ProgressBar();
            textBoxSource = new TextBox();
            textBoxDestination = new TextBox();
            btnDestination = new Button();
            btnTransfer = new Button();
            textBoxAuthor = new TextBox();
            label1 = new Label();
            label2 = new Label();
            label3 = new Label();
            label4 = new Label();
            panel1 = new Panel();
            label5 = new Label();
            panel1.SuspendLayout();
            SuspendLayout();
            // 
            // btnSource
            // 
            btnSource.Location = new Point(445, 79);
            btnSource.Name = "btnSource";
            btnSource.Size = new Size(75, 23);
            btnSource.TabIndex = 0;
            btnSource.Text = "Source";
            btnSource.UseVisualStyleBackColor = true;
            btnSource.Click += btnSource_Click;
            // 
            // progressBar1
            // 
            progressBar1.Location = new Point(12, 288);
            progressBar1.Name = "progressBar1";
            progressBar1.Size = new Size(412, 23);
            progressBar1.TabIndex = 1;
            // 
            // textBoxSource
            // 
            textBoxSource.Location = new Point(12, 80);
            textBoxSource.Name = "textBoxSource";
            textBoxSource.Size = new Size(412, 23);
            textBoxSource.TabIndex = 2;
            // 
            // textBoxDestination
            // 
            textBoxDestination.Location = new Point(12, 155);
            textBoxDestination.Name = "textBoxDestination";
            textBoxDestination.Size = new Size(412, 23);
            textBoxDestination.TabIndex = 3;
            // 
            // btnDestination
            // 
            btnDestination.Location = new Point(445, 155);
            btnDestination.Name = "btnDestination";
            btnDestination.Size = new Size(75, 23);
            btnDestination.TabIndex = 4;
            btnDestination.Text = "Destination";
            btnDestination.UseVisualStyleBackColor = true;
            btnDestination.Click += btnDestination_Click;
            // 
            // btnTransfer
            // 
            btnTransfer.Location = new Point(451, 12);
            btnTransfer.Name = "btnTransfer";
            btnTransfer.Size = new Size(75, 23);
            btnTransfer.TabIndex = 5;
            btnTransfer.Text = "Transfer";
            btnTransfer.UseVisualStyleBackColor = true;
            btnTransfer.Click += btnTransfer_Click_1;
            // 
            // textBoxAuthor
            // 
            textBoxAuthor.Location = new Point(12, 230);
            textBoxAuthor.Name = "textBoxAuthor";
            textBoxAuthor.Size = new Size(143, 23);
            textBoxAuthor.TabIndex = 6;
            // 
            // label1
            // 
            label1.AutoSize = true;
            label1.Font = new Font("Segoe UI", 15.75F, FontStyle.Bold, GraphicsUnit.Point, 0);
            label1.Location = new Point(12, 9);
            label1.Name = "label1";
            label1.Size = new Size(140, 30);
            label1.TabIndex = 7;
            label1.Text = "Photo Sorter";
            // 
            // label2
            // 
            label2.AutoSize = true;
            label2.Font = new Font("Segoe UI Semibold", 9.75F, FontStyle.Bold, GraphicsUnit.Point, 0);
            label2.Location = new Point(12, 60);
            label2.Name = "label2";
            label2.Size = new Size(49, 17);
            label2.TabIndex = 8;
            label2.Text = "Source";
            // 
            // label3
            // 
            label3.AutoSize = true;
            label3.Font = new Font("Segoe UI Semibold", 9.75F, FontStyle.Bold, GraphicsUnit.Point, 0);
            label3.Location = new Point(12, 135);
            label3.Name = "label3";
            label3.Size = new Size(77, 17);
            label3.TabIndex = 9;
            label3.Text = "Destination";
            // 
            // label4
            // 
            label4.AutoSize = true;
            label4.Font = new Font("Segoe UI Semibold", 9.75F, FontStyle.Bold, GraphicsUnit.Point, 0);
            label4.Location = new Point(12, 210);
            label4.Name = "label4";
            label4.Size = new Size(51, 17);
            label4.TabIndex = 10;
            label4.Text = "Author";
            // 
            // panel1
            // 
            panel1.BackColor = Color.Gainsboro;
            panel1.Controls.Add(btnTransfer);
            panel1.Location = new Point(-6, 276);
            panel1.Name = "panel1";
            panel1.Size = new Size(544, 53);
            panel1.TabIndex = 11;
            // 
            // label5
            // 
            label5.AutoSize = true;
            label5.Font = new Font("Segoe UI", 8.25F, FontStyle.Regular, GraphicsUnit.Point, 0);
            label5.ForeColor = SystemColors.AppWorkspace;
            label5.Location = new Point(445, 260);
            label5.Name = "label5";
            label5.Size = new Size(80, 13);
            label5.TabIndex = 12;
            label5.Text = "T. Racine 2024";
            // 
            // Form1
            // 
            AutoScaleDimensions = new SizeF(7F, 15F);
            AutoScaleMode = AutoScaleMode.Font;
            ClientSize = new Size(532, 325);
            Controls.Add(label5);
            Controls.Add(label4);
            Controls.Add(label3);
            Controls.Add(label2);
            Controls.Add(label1);
            Controls.Add(textBoxAuthor);
            Controls.Add(btnDestination);
            Controls.Add(textBoxDestination);
            Controls.Add(textBoxSource);
            Controls.Add(progressBar1);
            Controls.Add(btnSource);
            Controls.Add(panel1);
            Icon = (Icon)resources.GetObject("$this.Icon");
            Name = "Form1";
            Text = "Photo Sorter";
            panel1.ResumeLayout(false);
            ResumeLayout(false);
            PerformLayout();
        }

        #endregion

        private Button btnSource;
        private ProgressBar progressBar1;
        private TextBox textBoxSource;
        private TextBox textBoxDestination;
        private Button btnDestination;
        private Button btnTransfer;
        private TextBox textBoxAuthor;
        private Label label1;
        private Label label2;
        private Label label3;
        private Label label4;
        private Panel panel1;
        private Label label5;
    }
}
