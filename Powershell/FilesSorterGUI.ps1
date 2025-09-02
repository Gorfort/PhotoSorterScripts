Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ------------------------------------------------------------
# GLOBALS
# ------------------------------------------------------------
$Global:folderName = $env:USERNAME  # used for the "user" subfolder level
[System.Windows.Forms.Application]::EnableVisualStyles()

# ------------------------------------------------------------
# GUI-SAFE HELPERS (RichTextBox typing + color + counting)
# ------------------------------------------------------------

function Get-WinColor {
    param([string]$Name = "White")
    $c = [System.Drawing.Color]::FromName($Name)
    if (-not $c.IsKnownColor) { return [System.Drawing.Color]::White }
    return $c
}

function Add-RtbTyping {
    param(
        [Parameter(Mandatory=$true)][System.Windows.Forms.RichTextBox]$Rtb,
        [Parameter(Mandatory=$true)][string]$Text,
        [int]$Delay = 20,
        [string]$Color = "White",
        [switch]$NewLine
    )
    $col = Get-WinColor $Color
    foreach ($ch in $Text.ToCharArray()) {
        $Rtb.SelectionColor = $col
        $Rtb.AppendText($ch)
        $Rtb.ScrollToCaret()
        Start-Sleep -Milliseconds $Delay
        [System.Windows.Forms.Application]::DoEvents()
    }
    if ($NewLine) {
        $Rtb.SelectionColor = $col
        $Rtb.AppendText([Environment]::NewLine)
        $Rtb.ScrollToCaret()
        [System.Windows.Forms.Application]::DoEvents()
    }
}

# -------------------------------
# Reduce flicker in RichTextBox updates
# -------------------------------
function Suspend-RtbDrawing {
    param([System.Windows.Forms.RichTextBox]$Rtb)
    $WM_SETREDRAW = 0x0B
    $signature = @"
    [DllImport("user32.dll")]
    public static extern int SendMessage(IntPtr hWnd, int wMsg, bool wParam, int lParam);
"@
    Add-Type -MemberDefinition $signature -Name "Win32SendMessage" -Namespace Win32 -PassThru | Out-Null
    [Win32.Win32SendMessage]::SendMessage($Rtb.Handle, $WM_SETREDRAW, $false, 0) | Out-Null
}

function Resume-RtbDrawing {
    param([System.Windows.Forms.RichTextBox]$Rtb)
    $WM_SETREDRAW = 0x0B
    [Win32.Win32SendMessage]::SendMessage($Rtb.Handle, $WM_SETREDRAW, $true, 0) | Out-Null
    $Rtb.Refresh()
}



function Add-RtbLine {
    param(
        [System.Windows.Forms.RichTextBox]$Rtb,
        [string]$Text,
        [string]$Color = "White"
    )

    if ([string]::IsNullOrWhiteSpace($Text)) { return }  # skip empty lines

    $Rtb.SelectionColor = [System.Drawing.Color]::FromName($Color)
    $Rtb.AppendText($Text + "`r`n")
    $Rtb.ScrollToCaret()
}


# Animated "counting" that updates numbers in-place on the same line
function Add-RtbCounting {
    param(
        [Parameter(Mandatory=$true)][System.Windows.Forms.RichTextBox]$Rtb,
        [int]$Target,
        [int]$Delay = 5,
        [string]$Color = "White",
        [string]$Prefix = ""
    )
    # Write the label first
    $labelColor = Get-WinColor "Yellow"
    $numColor   = Get-WinColor $Color
    $Rtb.SelectionColor = $labelColor
    $Rtb.AppendText($Prefix)
    $Rtb.ScrollToCaret()

    # Remember where the number begins
    $numStart = $Rtb.TextLength
    # Write an initial "0   " (no newline yet)
    $Rtb.SelectionColor = $numColor
    $Rtb.AppendText("0   ")
    $Rtb.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()

    $step = [Math]::Max([Math]::Ceiling($Target / 100), 1)
    for ($i = 0; $i -le $Target; $i += $step) {
        if ($i -gt $Target) { $i = $Target }
        # Replace the number from $numStart to current end of line
        $Rtb.SelectionStart  = $numStart
        $Rtb.SelectionLength = ($Rtb.TextLength - $numStart)
        $Rtb.SelectionColor  = $numColor
        $Rtb.SelectedText    = ("{0}   " -f $i)
        $Rtb.ScrollToCaret()
        Start-Sleep -Milliseconds $Delay
        [System.Windows.Forms.Application]::DoEvents()
    }

    # Finally, end the line
    $Rtb.SelectionColor = $numColor
    $Rtb.AppendText([Environment]::NewLine)
    $Rtb.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

# GUI-versions of your original typing helpers (names preserved in spirit)
function Write-TypingColoredGUI {
    param(
        [Parameter(Mandatory=$true)][System.Windows.Forms.RichTextBox]$SummaryBox,
        [Parameter(Mandatory=$true)][string]$Text,
        [int]$Delay = 20,
        [string]$Color = "White",
        [switch]$NewLine
    )
    Add-RtbTyping -Rtb $SummaryBox -Text $Text -Delay $Delay -Color $Color -NewLine:$NewLine
}

function Write-TypingGUI {
    param(
        [Parameter(Mandatory=$true)][System.Windows.Forms.RichTextBox]$SummaryBox,
        [string]$Text,
        [int]$Delay = 20,
        [string]$Color = "White",
        [switch]$NewLine
    )
    Add-RtbTyping -Rtb $SummaryBox -Text $Text -Delay $Delay -Color $Color -NewLine:$NewLine
}

function Write-CountingGUI {
    param(
        [Parameter(Mandatory=$true)][System.Windows.Forms.RichTextBox]$SummaryBox,
        [int]$Target,
        [int]$Delay = 5,
        [string]$Color = "White",
        [string]$Prefix = ""
    )
    Add-RtbCounting -Rtb $SummaryBox -Target $Target -Delay $Delay -Color $Color -Prefix $Prefix
}

# ------------------------------------------------------------
# EXIF helper (same behavior as your original Get-DateTaken)
# ------------------------------------------------------------
function Get-DateTaken {
    param([Parameter(Mandatory=$true)][string]$FilePath)
    try {
        $img = [System.Drawing.Image]::FromFile($FilePath)
        try {
            $propItem = $img.GetPropertyItem(36867)
            $dateTakenString = ([System.Text.Encoding]::ASCII.GetString($propItem.Value)).Trim([char]0)
            $img.Dispose()
            return [datetime]::ParseExact($dateTakenString, "yyyy:MM:dd HH:mm:ss", $null)
        } catch {
            $img.Dispose()
            return (Get-Item $FilePath).LastWriteTime
        }
    } catch {
        return (Get-Item $FilePath).LastWriteTime
    }
}

# ------------------------------------------------------------
# THE CORE SORT FUNCTION (GUI version of your long loop)
# ------------------------------------------------------------
function Sort-Files {
    param(
        [Parameter(Mandatory=$true)][string]$sourceFolder,
        [Parameter(Mandatory=$true)][string[]]$destinationFolders,
        [Parameter(Mandatory=$true)][System.Windows.Forms.ProgressBar]$progressBar,
        [Parameter(Mandatory=$true)][System.Windows.Forms.RichTextBox]$summaryBox
    )

    $summaryBox.Clear()
    Write-TypingColoredGUI -SummaryBox $summaryBox -Text "Welcome to the Files Sorter" -Delay 12 -Color "Cyan" -NewLine

    $photos = Get-ChildItem -Path $sourceFolder -File -ErrorAction SilentlyContinue
    $totalFiles = $photos.Count
    if ($totalFiles -le 0) {
        Add-RtbLine -Rtb $summaryBox -Text "No files found in $sourceFolder." -Color "Red"
        return
    }

    $progressBar.Minimum = 0
    $progressBar.Maximum = $totalFiles
    $progressBar.Value = 0

    $fileCounts = @{}
    $processedFiles = 0
    $uniqueFilesProcessed = @()
    $startTime = Get-Date

    # Single line placeholder for progress
    Add-RtbLine -Rtb $summaryBox -Text ("Copying: 0/{0}  (~Calculating...)" -f $totalFiles) -Color "Gray"

    foreach ($photo in $photos) {
        try {
            if ($uniqueFilesProcessed -contains $photo.Name) { continue }

            $dateTaken = Get-DateTaken -FilePath $photo.FullName
            if ($null -eq $dateTaken) { $dateTaken = $photo.LastWriteTime }

            $currentMonth = $dateTaken.ToString("MMMM")
            $currentYear  = $dateTaken.ToString("yyyy")

            foreach ($destinationFolder in $destinationFolders) {
                if (-not (Test-Path $destinationFolder)) { New-Item -ItemType Directory -Path $destinationFolder | Out-Null }

                $yearFolder = Join-Path $destinationFolder $currentYear
                if (-not (Test-Path $yearFolder)) { New-Item -ItemType Directory -Path $yearFolder | Out-Null }

                $monthFolder = Join-Path $yearFolder "$currentMonth $currentYear"
                if (-not (Test-Path $monthFolder)) { New-Item -ItemType Directory -Path $monthFolder | Out-Null }

                $userFolder = Join-Path $monthFolder $Global:folderName
                if (-not (Test-Path $userFolder)) { New-Item -ItemType Directory -Path $userFolder | Out-Null }

                # Subfolders
                $subFolders = @{
                    RAW    = Join-Path $userFolder "RAW"
                    JPEG   = Join-Path $userFolder "JPEG"
                    PNG    = Join-Path $userFolder "PNG"
                    Video  = Join-Path $userFolder "Video"
                    Others = Join-Path $userFolder "Others"
                }

                foreach ($sf in $subFolders.Values) { if (-not (Test-Path $sf)) { New-Item -ItemType Directory -Path $sf | Out-Null } }

                # Determine file type
                $fileType = "Others"
                switch -Regex ($photo.Extension.ToLower()) {
                    '^\.cr3|^\.raw|^\.dng' { $destinationPath = Join-Path $subFolders.RAW $photo.Name; $fileType = "RAW"; break }
                    '^\.jpe?g'             { $destinationPath = Join-Path $subFolders.JPEG $photo.Name; $fileType = "JPEG"; break }
                    '^\.png'               { $destinationPath = Join-Path $subFolders.PNG $photo.Name; $fileType = "PNG"; break }
                    '^\.mp4|^\.mov|^\.crm|^\.mxf' { $destinationPath = Join-Path $subFolders.Video $photo.Name; $fileType = "Video"; break }
                    default                { $destinationPath = Join-Path $subFolders.Others $photo.Name }
                }

                if (-not (Test-Path $destinationPath)) {
                    Copy-Item -Path $photo.FullName -Destination $destinationPath -ErrorAction SilentlyContinue
                }
            }

            $processedFiles++
            $uniqueFilesProcessed += $photo.Name

            # Update counts
            $monthKey = "$currentMonth $currentYear"
            if (-not $fileCounts.ContainsKey($monthKey)) { $fileCounts[$monthKey] = @{"RAW"=0;"JPEG"=0;"PNG"=0;"Video"=0;"Others"=0} }
            $fileCounts[$monthKey][$fileType]++

            # Update progress bar
            $progressBar.Value = [Math]::Min($processedFiles, $totalFiles)

            # ETA
            $elapsed = (Get-Date) - $startTime
            $avg = $elapsed.TotalSeconds / $processedFiles
            $remaining = [Math]::Max(($totalFiles - $processedFiles) * $avg,0)
            $eta = [TimeSpan]::FromSeconds($remaining).ToString("hh\:mm\:ss")

            # Update only the last line in RichTextBox in WHITE without adding new lines
            $lineIndex = $summaryBox.Lines.Count - 1

            # Protect against empty RichTextBox
            if ($lineIndex -lt 0) {
                $summaryBox.AppendText(("Copying: {0}/{1}  (~{2})" -f $processedFiles, $totalFiles, $eta))
            } else {
                $summaryBox.SelectionStart  = $summaryBox.GetFirstCharIndexFromLine($lineIndex)
                $summaryBox.SelectionLength = $summaryBox.Lines[$lineIndex].Length
                $summaryBox.SelectionColor  = [System.Drawing.Color]::White
                $summaryBox.SelectedText    = ("Copying: {0}/{1}  (~{2})" -f $processedFiles, $totalFiles, $eta)
            }

            $summaryBox.ScrollToCaret()
            [System.Windows.Forms.Application]::DoEvents()

        } catch {
            Add-RtbLine -Rtb $summaryBox -Text ("Error processing {0}: {1}" -f $photo.Name, $_) -Color "Red"
        }
    }

    # Add final summary
    $summaryBox.AppendText([Environment]::NewLine)
    Write-TypingColoredGUI -SummaryBox $summaryBox -Text "Processing complete. Files summary:" -Delay 12 -Color "Cyan" -NewLine
    $summaryBox.AppendText([Environment]::NewLine)
    
    # Group & print summary
    $groupedByYear = @{}
    foreach ($monthKey in $fileCounts.Keys) {
        $date = [datetime]::ParseExact($monthKey, "MMMM yyyy", $null)
        $year = $date.Year
        if (-not $groupedByYear.ContainsKey($year)) { $groupedByYear[$year] = @{} }
        $groupedByYear[$year][$monthKey] = $fileCounts[$monthKey]
    }

    foreach ($year in ($groupedByYear.Keys | Sort-Object)) {
        Write-TypingColoredGUI -SummaryBox $summaryBox -Text ("Year {0}:" -f $year) -Delay 12 -Color "Cyan" -NewLine
        $sortedMonths = $groupedByYear[$year].Keys | ForEach-Object {
            [PSCustomObject]@{ Key=$_; Date=[datetime]::ParseExact($_,"MMMM yyyy",$null) }
        } | Sort-Object Date

        foreach ($monthEntry in $sortedMonths) {
            $monthKey = $monthEntry.Key
            $counts = $groupedByYear[$year][$monthKey]
            Write-TypingColoredGUI -SummaryBox $summaryBox -Text ("  {0} :" -f $monthKey) -Delay 10 -Color "LightGreen" -NewLine
            foreach ($type in $counts.Keys | Where-Object { $counts[$_] -gt 0 }) {
                $prefix = "    {0} files: " -f $type
                Write-CountingGUI -SummaryBox $summaryBox -Target $counts[$type] -Delay 5 -Color "White" -Prefix $prefix
            }
            $summaryBox.AppendText([Environment]::NewLine)
        }
    }

    # Totals
    $duration = (Get-Date) - $startTime
    Write-TypingColoredGUI -SummaryBox $summaryBox -Text ("Time taken: {0}h {1}m {2}s" -f $duration.Hours, $duration.Minutes, $duration.Seconds) -Delay 10 -Color "Magenta" -NewLine
    Add-RtbCounting -Rtb $summaryBox -Target $totalFiles -Delay 5 -Color "White" -Prefix "Total files: "

    $totalSizeGB = [Math]::Round(($photos | Measure-Object Length -Sum).Sum / 1GB, 2)
    Write-TypingColoredGUI -SummaryBox $summaryBox -Text ("Total size transferred: {0} GB" -f $totalSizeGB) -Delay 10 -Color "White" -NewLine
}


# ------------------------------------------------------------
# GUI (your Show-GUI, upgraded to use RichTextBox + multi-destination)
# ------------------------------------------------------------
function Show-GUI {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Files Sorter"
    $form.Size = New-Object System.Drawing.Size(520,520)
    $form.StartPosition = "CenterScreen"

    # Source
    $sourceLabel = New-Object System.Windows.Forms.Label
    $sourceLabel.Text = "Source Folder:"
    $sourceLabel.Location = New-Object System.Drawing.Point(10,20)
    $form.Controls.Add($sourceLabel)

    $sourceTextBox = New-Object System.Windows.Forms.TextBox
    $sourceTextBox.Location = New-Object System.Drawing.Point(120,18)
    $sourceTextBox.Size = New-Object System.Drawing.Size(280,20)
    $form.Controls.Add($sourceTextBox)

    $sourceButton = New-Object System.Windows.Forms.Button
    $sourceButton.Text = "Browse"
    $sourceButton.Location = New-Object System.Drawing.Point(410,16)
    $sourceButton.Add_Click({
        $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
        if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $sourceTextBox.Text = $dlg.SelectedPath
        }
    })
    $form.Controls.Add($sourceButton)

    # Destinations (support multiple)
    $destLabel = New-Object System.Windows.Forms.Label
    $destLabel.Text = "Destination Folders:"
    $destLabel.Location = New-Object System.Drawing.Point(10,55)
    $form.Controls.Add($destLabel)

    $destTextBox = New-Object System.Windows.Forms.TextBox
    $destTextBox.Location = New-Object System.Drawing.Point(120,53)
    $destTextBox.Size = New-Object System.Drawing.Size(280,20)
    $form.Controls.Add($destTextBox)

    $destButton = New-Object System.Windows.Forms.Button
    $destButton.Text = "Add"
    $destButton.Location = New-Object System.Drawing.Point(410,51)
    $form.Controls.Add($destButton)

    $destListBox = New-Object System.Windows.Forms.ListBox
    $destListBox.Location = New-Object System.Drawing.Point(120,80)
    $destListBox.Size = New-Object System.Drawing.Size(280,60)
    $form.Controls.Add($destListBox)

    $removeDestBtn = New-Object System.Windows.Forms.Button
    $removeDestBtn.Text = "Remove Selected"
    $removeDestBtn.Location = New-Object System.Drawing.Point(410,80)
    $form.Controls.Add($removeDestBtn)

    $destButton.Add_Click({
        # pick via dialog; the entered text box is optional
        $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
        if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $destTextBox.Text = $dlg.SelectedPath
            if (-not [string]::IsNullOrWhiteSpace($destTextBox.Text)) {
                if (-not ($destListBox.Items -contains $destTextBox.Text)) {
                    [void]$destListBox.Items.Add($destTextBox.Text)
                }
            }
        } elseif (-not [string]::IsNullOrWhiteSpace($destTextBox.Text)) {
            if (-not ($destListBox.Items -contains $destTextBox.Text)) {
                [void]$destListBox.Items.Add($destTextBox.Text)
            }
        }
    })

    $removeDestBtn.Add_Click({
        while ($destListBox.SelectedItems.Count -gt 0) {
            $destListBox.Items.Remove($destListBox.SelectedItem)
        }
    })

    # Progress bar
    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $progressBar.Location = New-Object System.Drawing.Point(10,155)
    $progressBar.Size = New-Object System.Drawing.Size(480,20)
    $form.Controls.Add($progressBar)

    # Summary (RichTextBox for colors and animations)
    $summaryLabel = New-Object System.Windows.Forms.Label
    $summaryLabel.Text = "Summary:"
    $summaryLabel.Location = New-Object System.Drawing.Point(10,185)
    $form.Controls.Add($summaryLabel)

    $summaryBox = New-Object System.Windows.Forms.RichTextBox
    $summaryBox.Location = New-Object System.Drawing.Point(10,205)
    $summaryBox.Size = New-Object System.Drawing.Size(480,240)
    $summaryBox.ReadOnly = $true
    $summaryBox.BackColor = [System.Drawing.Color]::Black  
    $summaryBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    $form.Controls.Add($summaryBox)

    # Start
    $startButton = New-Object System.Windows.Forms.Button
    $startButton.Text = "Start Sorting"
    $startButton.Location = New-Object System.Drawing.Point(190,455)
    $form.Controls.Add($startButton)

    $startButton.Add_Click({
        $sourceFolder = $sourceTextBox.Text
        $destinationFolders = @()
        foreach ($item in $destListBox.Items) { $destinationFolders += [string]$item }

        if (-not $sourceFolder -or -not (Test-Path $sourceFolder -PathType Container)) {
            [System.Windows.Forms.MessageBox]::Show("Please select a valid source folder.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
            return
        }
        if ($destinationFolders.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("Please add at least one destination folder.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
            return
        }

        Sort-Files -sourceFolder $sourceFolder -destinationFolders $destinationFolders -progressBar $progressBar -summaryBox $summaryBox
    })

    $form.Add_Shown({ $form.Activate() })
    [void]$form.ShowDialog()
}

# ------------------------------------------------------------
# (Optional) Retain your original console helpers for completeness
# (They won't be used in GUI run, but included so no parts are "lost")
# ------------------------------------------------------------
function Write-TypingColored {
    param(
        [Parameter(Mandatory=$true)][string]$Text,
        [int]$Delay = 50,
        [ConsoleColor]$Color = [ConsoleColor]::White
    )
    $oldColor = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $Color
    foreach ($char in $Text.ToCharArray()) {
        Write-Host -NoNewline $char
        Start-Sleep -Milliseconds $Delay
    }
    $Host.UI.RawUI.ForegroundColor = $oldColor
}

function Write-Typing {
    param (
        [string]$text,
        [int]$delay = 20,
        [string]$color = "White"
    )
    foreach ($char in $text.ToCharArray()) {
        Write-Host -NoNewline -ForegroundColor $color $char
        Start-Sleep -Milliseconds $delay
    }
    Write-Host
}

function Write-Counting {
    param (
        [int]$Target,
        [int]$Delay = 5,
        [string]$Color = "White",
        [string]$Prefix = ""
    )
    $step = [Math]::Max([Math]::Ceiling($Target / 100), 1)
    for ($i = 0; $i -le $Target; $i += $step) {
        if ($i -gt $Target) { $i = $Target }
        $line = "$Prefix $i"
        Write-Host -NoNewline "`r$line    " -ForegroundColor $Color
        Start-Sleep -Milliseconds $Delay
    }
    Write-Host "$Prefix $Target" -ForegroundColor $Color
}

# ------------------------------------------------------------
# RUN GUI
# ------------------------------------------------------------
Show-GUI
