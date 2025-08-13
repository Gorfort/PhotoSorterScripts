Add-Type -AssemblyName System.Windows.Forms

# Function to create and show the GUI
function Show-GUI {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Files Sorter"
    $form.Size = New-Object System.Drawing.Size(450,400)
    
    $sourceLabel = New-Object System.Windows.Forms.Label
    $sourceLabel.Text = "Source Folder:"
    $sourceLabel.Location = New-Object System.Drawing.Point(10,20)
    $form.Controls.Add($sourceLabel)
    
    $sourceTextBox = New-Object System.Windows.Forms.TextBox
    $sourceTextBox.Location = New-Object System.Drawing.Point(120,20)
    $sourceTextBox.Size = New-Object System.Drawing.Size(200,20)
    $form.Controls.Add($sourceTextBox)
    
    $sourceButton = New-Object System.Windows.Forms.Button
    $sourceButton.Text = "Browse"
    $sourceButton.Location = New-Object System.Drawing.Point(330,20)
    $sourceButton.Add_Click({
        $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
        if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $sourceTextBox.Text = $folderBrowser.SelectedPath
        }
    })
    $form.Controls.Add($sourceButton)
    
    $destLabel = New-Object System.Windows.Forms.Label
    $destLabel.Text = "Destination Folder:"
    $destLabel.Location = New-Object System.Drawing.Point(10,60)
    $form.Controls.Add($destLabel)
    
    $destTextBox = New-Object System.Windows.Forms.TextBox
    $destTextBox.Location = New-Object System.Drawing.Point(120,60)
    $destTextBox.Size = New-Object System.Drawing.Size(200,20)
    $form.Controls.Add($destTextBox)
    
    $destButton = New-Object System.Windows.Forms.Button
    $destButton.Text = "Browse"
    $destButton.Location = New-Object System.Drawing.Point(330,60)
    $destButton.Add_Click({
        $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
        if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $destTextBox.Text = $folderBrowser.SelectedPath
        }
    })
    $form.Controls.Add($destButton)
    
    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $progressBar.Location = New-Object System.Drawing.Point(10,140)
    $progressBar.Size = New-Object System.Drawing.Size(400,20)
    $form.Controls.Add($progressBar)
    
    $summaryLabel = New-Object System.Windows.Forms.Label
    $summaryLabel.Text = "Summary:"
    $summaryLabel.Location = New-Object System.Drawing.Point(10,170)
    $form.Controls.Add($summaryLabel)
    
    $summaryTextBox = New-Object System.Windows.Forms.TextBox
    $summaryTextBox.Multiline = $true
    $summaryTextBox.Location = New-Object System.Drawing.Point(10,190)
    $summaryTextBox.Size = New-Object System.Drawing.Size(400,120)
    $summaryTextBox.ScrollBars = 'Vertical'
    $form.Controls.Add($summaryTextBox)
    
    $startButton = New-Object System.Windows.Forms.Button
    $startButton.Text = "Start Sorting"
    $startButton.Location = New-Object System.Drawing.Point(150,320)
    $startButton.Add_Click({
        $sourceFolder = $sourceTextBox.Text
        $destinationFolder = $destTextBox.Text
        if ($sourceFolder -and (Test-Path $sourceFolder -PathType Container) -and
            $destinationFolder -and (Test-Path $destinationFolder -PathType Container)) {
            Sort-Files -sourceFolder $sourceFolder -destinationFolders @($destinationFolder) -progressBar $progressBar -summaryTextBox $summaryTextBox
        } else {
            [System.Windows.Forms.MessageBox]::Show("Please select valid source and destination folders.", "Error", "OK", "Error")
        }
    })
    $form.Controls.Add($startButton)
    
    $form.ShowDialog()
}

# Function to sort files with progress bar and metadata sorting
function Sort-Files {
    param (
        [string]$sourceFolder,
        [string[]]$destinationFolders,
        [System.Windows.Forms.ProgressBar]$progressBar,
        [System.Windows.Forms.TextBox]$summaryTextBox
    )
    
    $photos = Get-ChildItem -Path $sourceFolder -File
    $totalFiles = $photos.Count
    $processedFiles = 0
    $fileCounts = @{}
    
    foreach ($photo in $photos) {
        $dateTaken = (Get-ItemProperty -Path $photo.FullName -Name DateTaken -ErrorAction SilentlyContinue).DateTaken
        if ($null -eq $dateTaken) {
            $dateTaken = $photo.LastWriteTime
        }
        $currentMonth = $dateTaken.ToString("MMMM")
        $currentYear = $dateTaken.ToString("yyyy")
        
        foreach ($destinationFolder in $destinationFolders) {
            $monthFolder = Join-Path -Path (Join-Path -Path $destinationFolder -ChildPath $currentYear) -ChildPath "$currentMonth $currentYear"
            $fileType = "Others"
            if ($photo.Extension -match "\.CR3|\.RAW|\.DNG") {
                $fileType = "RAW"
            } elseif ($photo.Extension -match "\.JPEG|\.JPG") {
                $fileType = "JPEG"
            } elseif ($photo.Extension -match "\.PNG") {
                $fileType = "PNG"
            } elseif ($photo.Extension -match "\.MP4|\.MOV|\.CRM|\.MXF") {
                $fileType = "Video"
            }
            $typeFolder = Join-Path -Path $monthFolder -ChildPath $fileType
            
            if (-not (Test-Path -Path $typeFolder)) {
                New-Item -Path $typeFolder -ItemType Directory -Force | Out-Null
            }
            
            $destinationPath = Join-Path -Path $typeFolder -ChildPath $photo.Name
            if (-not (Test-Path -Path $destinationPath)) {
                Copy-Item -Path $photo.FullName -Destination $destinationPath
                $processedFiles++
                $progressBar.Value = ($processedFiles / $totalFiles) * 100
            }
            
            if (-not $fileCounts.ContainsKey($currentYear)) {
                $fileCounts[$currentYear] = @{}
            }
            if (-not $fileCounts[$currentYear].ContainsKey($currentMonth)) {
                $fileCounts[$currentYear][$currentMonth] = @{}
            }
            if (-not $fileCounts[$currentYear][$currentMonth].ContainsKey($fileType)) {
                $fileCounts[$currentYear][$currentMonth][$fileType] = 0
            }
            $fileCounts[$currentYear][$currentMonth][$fileType]++
        }
    }
    
    $summaryTextBox.Text = "Processing complete.`r`n" + ($fileCounts.GetEnumerator() | ForEach-Object { $_.Key + "`r`n" + ($_.Value.GetEnumerator() | ForEach-Object { "  " + $_.Key + "`r`n    " + ($_.Value.GetEnumerator() | ForEach-Object { $_.Key + ": " + $_.Value }) -join "`r`n" }) -join "`r`n" }) -join "`r`n"
}

# Show the GUI
Show-GUI