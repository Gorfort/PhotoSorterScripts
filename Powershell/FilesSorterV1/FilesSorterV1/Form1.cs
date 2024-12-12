using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.Serialization;
using System.Windows.Forms;

namespace FilesSorterV1
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();

            // Load previously saved settings if available
            textBoxSource.Text = Properties.Settings.Default.SourcePath;
            textBoxDestination.Text = Properties.Settings.Default.DestinationPath;
            textBoxAuthor.Text = Properties.Settings.Default.AuthorName;
        }

        private void btnSource_Click(object sender, EventArgs e)
        {
            using (FolderBrowserDialog folderDialog = new FolderBrowserDialog())
            {
                folderDialog.Description = "Select the source folder";
                if (folderDialog.ShowDialog() == DialogResult.OK)
                {
                    textBoxSource.Text = folderDialog.SelectedPath;
                }
            }
        }

        private void btnDestination_Click(object sender, EventArgs e)
        {
            using (FolderBrowserDialog folderDialog = new FolderBrowserDialog())
            {
                folderDialog.Description = "Select the destination folder";
                if (folderDialog.ShowDialog() == DialogResult.OK)
                {
                    textBoxDestination.Text = folderDialog.SelectedPath;
                }
            }
        }

        private void btnTransfer_Click_1(object sender, EventArgs e)
        {
            string sourcePath = textBoxSource.Text;
            string destinationPath = textBoxDestination.Text;
            string authorName = textBoxAuthor.Text;

            // Validate inputs
            if (string.IsNullOrEmpty(sourcePath) || string.IsNullOrEmpty(destinationPath) || string.IsNullOrEmpty(authorName))
            {
                MessageBox.Show("Please provide all inputs: Source folder, Destination folder, and Author name.",
                                "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }

            try
            {
                // Save settings for the next time the app is run
                Properties.Settings.Default.SourcePath = sourcePath;
                Properties.Settings.Default.DestinationPath = destinationPath;
                Properties.Settings.Default.AuthorName = authorName;
                Properties.Settings.Default.Save();

                // Get all image files from the source folder
                string[] imageFiles = Directory.GetFiles(sourcePath, "*.jpg");

                if (imageFiles.Length == 0)
                {
                    MessageBox.Show("No image files found in the source folder.", "Info", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    return;
                }

                // Initialize progress bar
                progressBar1.Value = 0;
                progressBar1.Maximum = imageFiles.Length;

                foreach (string file in imageFiles)
                {
                    // Load the image
                    using (Image image = Image.FromFile(file))
                    {
                        // Set metadata (Author name)
                        PropertyItem propItem = (PropertyItem)FormatterServices.GetUninitializedObject(typeof(PropertyItem));
                        propItem.Id = 0x013B; // ID for Artist/Author in EXIF
                        propItem.Type = 2; // ASCII
                        propItem.Value = System.Text.Encoding.ASCII.GetBytes(authorName + '\0'); // Null-terminated
                        propItem.Len = propItem.Value.Length;

                        image.SetPropertyItem(propItem);

                        // Save the image to the destination folder
                        string fileName = Path.GetFileName(file);
                        string destinationFile = Path.Combine(destinationPath, fileName);
                        image.Save(destinationFile, ImageFormat.Jpeg);
                    }

                    // Update progress bar
                    progressBar1.Value += 1;
                }

                MessageBox.Show("Transfer completed successfully.", "Success", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"An error occurred: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
    }
}
