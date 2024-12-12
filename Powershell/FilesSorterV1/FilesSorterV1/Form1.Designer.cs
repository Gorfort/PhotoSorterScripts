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
            btnSource = new Button();
            progressBar1 = new ProgressBar();
            textBoxSource = new TextBox();
            textBoxDestination = new TextBox();
            btnDestination = new Button();
            btnTransfer = new Button();
            textBoxAuthor = new TextBox();
            SuspendLayout();
            // 
            // btnSource
            // 
            btnSource.Location = new Point(25, 60);
            btnSource.Name = "btnSource";
            btnSource.Size = new Size(75, 23);
            btnSource.TabIndex = 0;
            btnSource.Text = "Source";
            btnSource.UseVisualStyleBackColor = true;
            btnSource.Click += btnSource_Click;
            // 
            // progressBar1
            // 
            progressBar1.Location = new Point(283, 350);
            progressBar1.Name = "progressBar1";
            progressBar1.Size = new Size(257, 23);
            progressBar1.TabIndex = 1;
            // 
            // textBoxSource
            // 
            textBoxSource.Location = new Point(25, 31);
            textBoxSource.Name = "textBoxSource";
            textBoxSource.Size = new Size(381, 23);
            textBoxSource.TabIndex = 2;
            // 
            // textBoxDestination
            // 
            textBoxDestination.Location = new Point(25, 146);
            textBoxDestination.Name = "textBoxDestination";
            textBoxDestination.Size = new Size(381, 23);
            textBoxDestination.TabIndex = 3;
            // 
            // btnDestination
            // 
            btnDestination.Location = new Point(25, 206);
            btnDestination.Name = "btnDestination";
            btnDestination.Size = new Size(75, 23);
            btnDestination.TabIndex = 4;
            btnDestination.Text = "Destination";
            btnDestination.UseVisualStyleBackColor = true;
            btnDestination.Click += btnDestination_Click;
            // 
            // btnTransfer
            // 
            btnTransfer.Location = new Point(382, 388);
            btnTransfer.Name = "btnTransfer";
            btnTransfer.Size = new Size(75, 23);
            btnTransfer.TabIndex = 5;
            btnTransfer.Text = "Transfer";
            btnTransfer.UseVisualStyleBackColor = true;
            btnTransfer.Click += btnTransfer_Click_1;
            // 
            // textBoxAuthor
            // 
            textBoxAuthor.Location = new Point(592, 84);
            textBoxAuthor.Name = "textBoxAuthor";
            textBoxAuthor.Size = new Size(143, 23);
            textBoxAuthor.TabIndex = 6;
            // 
            // Form1
            // 
            AutoScaleDimensions = new SizeF(7F, 15F);
            AutoScaleMode = AutoScaleMode.Font;
            ClientSize = new Size(800, 450);
            Controls.Add(textBoxAuthor);
            Controls.Add(btnTransfer);
            Controls.Add(btnDestination);
            Controls.Add(textBoxDestination);
            Controls.Add(textBoxSource);
            Controls.Add(progressBar1);
            Controls.Add(btnSource);
            Name = "Form1";
            Text = "Form1";
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
    }
}
