function Write-TypingColored {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Text,
        
        [int]$Delay = 50,  # milliseconds per character
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
        [string]$Prefix = ""   # e.g. "RAW :", "JPEG :", "Total files:"
    )

    $step = [Math]::Max([Math]::Ceiling($Target / 100), 1)

    for ($i = 0; $i -le $Target; $i += $step) {
        if ($i -gt $Target) { $i = $Target }

        # Always redraw the full line so the prefix + number stay aligned
        $line = "$Prefix $i"
        Write-Host -NoNewline "`r$line    " -ForegroundColor $Color

        Start-Sleep -Milliseconds $Delay
    }

    # Final print (ensures the last value + prefix are locked in, then moves to new line)
    Write-Host "$Prefix $Target" -ForegroundColor $Color
}

Write-Typing "Welcome to the Files Sorter" -delay 20 -color "Cyan"

function Get-FolderPath {
    param (
        [string]$prompt
    )
    do {
        Write-Typing $prompt -delay 40 -color "Yellow"
        $folderPath = Read-Host
        
        if (-not $folderPath -or -not (Test-Path $folderPath -PathType Container)) {
            Write-Typing "Invalid input. Please enter a valid folder path." -delay 20 -color "Red"
        } else {
            break
        }
    } while ($true)

    return $folderPath
}

function AskRunAgain {
    do {
        function Write-TypingColored {
            param (
                [string]$Text,
                [int]$Delay = 20,
                [string]$Color = "White"
            )
            foreach ($char in $Text.ToCharArray()) {
                Write-Host -NoNewline $char -ForegroundColor $Color
                Start-Sleep -Milliseconds $Delay
            }
        }

        Write-TypingColored "Do you want to run the script again? " -Delay 20 -Color "Yellow"
        Write-TypingColored "(Y/N)" -Delay 20 -Color "DarkGray"
        Write-Host

        $choice = Read-Host
        if ($choice -eq 'Y') {
            return $choice
        } elseif ($choice -eq 'N') {
            Write-TypingColored "Goodbye!" -Delay 20 -Color "Blue"
            Write-Host
            return $choice
        } else {
            Write-TypingColored "Invalid choice. Please enter Y or N." -Delay 20 -Color "Red"
            Write-Host
        }
    } while ($true)
}

function Get-DestinationFolders {
    $destinations = @()

    $firstDest = Get-FolderPath -prompt "Enter the destination folder path"
    $destinations += $firstDest

    do {
        function Write-TypingColored {
            param (
                [string]$Text,
                [int]$Delay = 20,
                [string]$Color = "White"
            )
            foreach ($char in $Text.ToCharArray()) {
                Write-Host -NoNewline $char -ForegroundColor $Color
                Start-Sleep -Milliseconds $Delay
            }
        }

        Write-TypingColored "Do you want to save the files in an additional folder? " -Delay 20 -Color "Yellow"
        Write-TypingColored "(Y/N)" -Delay 20 -Color "DarkGray"
        Write-Host

        $addAnother = Read-Host
        
        if ($addAnother -match '^(Y|y)$') {
            $nextDest = Get-FolderPath -prompt "Enter the additional destination folder path" -delay 20 -color "Yellow"
            $destinations += $nextDest
        } elseif ($addAnother -match '^(N|n)$') {
            break
        } else {
            Write-Typing "Invalid input. Please enter Y or N." -delay 20 -color "Red"
        }
    } while ($true)

    return $destinations
}

$fileCounts = @{}
$uniqueFilesProcessed = @()

do {
    $sourceFolder = Get-FolderPath -prompt "Enter the source folder path"
    $destinationFolders = Get-DestinationFolders

    $startTime = Get-Date

    $photos = Get-ChildItem -Path $sourceFolder -File
    $totalFiles = $photos.Count
    $processedFiles = 0
    $startTime = Get-Date
    $previousTime = $startTime

    function Get-DateTaken {
        param([string]$FilePath)
        try {
            $img = [System.Drawing.Image]::FromFile($FilePath)
            $propItem = $img.GetPropertyItem(36867)
            $dateTakenString = ([System.Text.Encoding]::ASCII.GetString($propItem.Value)).Trim([char]0)
            $img.Dispose()
            return [datetime]::ParseExact($dateTakenString, "yyyy:MM:dd HH:mm:ss", $null)
        } catch {
            return (Get-Item $FilePath).LastWriteTime
        }
    }

    foreach ($photo in $photos) {
        try {
            if ($uniqueFilesProcessed -contains $photo.Name) { continue }

            $dateTaken = Get-DateTaken -FilePath $photo.FullName
            if ($null -eq $dateTaken) { $dateTaken = $photo.LastWriteTime }

            $currentMonth = $dateTaken.ToString("MMMM")
            $currentYear = $dateTaken.ToString("yyyy")

            foreach ($destinationFolder in $destinationFolders) {
                if (-not (Test-Path $destinationFolder -PathType Container)) {
                    New-Item -ItemType Directory -Path $destinationFolder | Out-Null
                }

                $yearFolder = Join-Path -Path $destinationFolder -ChildPath $currentYear
                if (-not (Test-Path $yearFolder -PathType Container)) {
                    New-Item -ItemType Directory -Path $yearFolder | Out-Null
                }

                $monthFolder = Join-Path -Path $yearFolder -ChildPath "$currentMonth $currentYear"
                if (-not (Test-Path $monthFolder -PathType Container)) {
                    New-Item -ItemType Directory -Path $monthFolder | Out-Null
                }

                $userFolder = Join-Path -Path $monthFolder -ChildPath $folderName
                if (-not (Test-Path $userFolder -PathType Container)) {
                    New-Item -ItemType Directory -Path $userFolder | Out-Null
                }

                $rawFolderPath = Join-Path -Path $userFolder -ChildPath "RAW"
                $pngFolderPath = Join-Path -Path $userFolder -ChildPath "PNG"
                $jpegFolderPath = Join-Path -Path $userFolder -ChildPath "JPEG"
                $videoFolderPath = Join-Path -Path $userFolder -ChildPath "Video"
                $othersFolderPath = Join-Path -Path $userFolder -ChildPath "Others"

                New-Item -ItemType Directory -Path $rawFolderPath -ErrorAction SilentlyContinue | Out-Null
                New-Item -ItemType Directory -Path $pngFolderPath -ErrorAction SilentlyContinue | Out-Null
                New-Item -ItemType Directory -Path $jpegFolderPath -ErrorAction SilentlyContinue | Out-Null
                New-Item -ItemType Directory -Path $videoFolderPath -ErrorAction SilentlyContinue | Out-Null
                New-Item -ItemType Directory -Path $othersFolderPath -ErrorAction SilentlyContinue | Out-Null

                if ($photo.Extension -eq ".CR3" -or $photo.Extension -eq ".RAW" -or $photo.Extension -eq ".DNG") {
                    $destinationPath = Join-Path -Path $rawFolderPath -ChildPath $photo.Name
                    $fileType = "RAW"
                } elseif ($photo.Extension -eq ".JPEG" -or $photo.Extension -eq ".JPG") {
                    $destinationPath = Join-Path -Path $jpegFolderPath -ChildPath $photo.Name
                    $fileType = "JPEG"
                } elseif ($photo.Extension -eq ".mp4" -or $photo.Extension -eq ".MOV" -or $photo.Extension -eq ".CRM" -or $photo.Extension -eq ".MXF") {
                    $destinationPath = Join-Path -Path $videoFolderPath -ChildPath $photo.Name
                    $fileType = "Video"
                } elseif ($photo.Extension -eq ".png") {
                    $destinationPath = Join-Path -Path $pngFolderPath -ChildPath $photo.Name
                    $fileType = "PNG"
                } else {
                    $destinationPath = Join-Path -Path $othersFolderPath -ChildPath $photo.Name
                    $fileType = "Others"
                }

                if (-not (Test-Path -Path $destinationPath)) {
                    Copy-Item -Path $photo.FullName -Destination $destinationPath
                    $processedFiles++
                }
            }

            $uniqueFilesProcessed += $photo.Name
            $percentComplete = [math]::floor(($processedFiles / $totalFiles) * 100)

            $monthKey = "$currentMonth $currentYear"
            if (-not $fileCounts.ContainsKey($monthKey)) {
                $fileCounts[$monthKey] = @{
                    "RAW" = 0; "JPEG" = 0; "PNG" = 0; "Video" = 0; "Others" = 0
                }
            }
            $fileCounts[$monthKey][$fileType]++

            $currentTime = Get-Date
            $timeElapsed = $currentTime - $previousTime
            $previousTime = $currentTime

            if ($processedFiles -gt 0) {
                $averageTimePerFile = ($currentTime - $startTime).TotalSeconds / $processedFiles
                $remainingFiles = $totalFiles - $processedFiles
                $estimatedRemainingTime = $remainingFiles * $averageTimePerFile
                $estimatedRemainingTimeFormatted = [TimeSpan]::FromSeconds($estimatedRemainingTime).ToString("hh\:mm\:ss")
            } else {
                $estimatedRemainingTimeFormatted = "Calculating..."
            }

            Write-Progress -Activity "Copying Files" -PercentComplete $percentComplete -Status "$processedFiles/$totalFiles files copied - $percentComplete% complete. Estimated Time Remaining: $estimatedRemainingTimeFormatted"
        } catch {
            Write-Host "Error processing $($photo.Name): $_" -ForegroundColor Red
        }
    }

    Write-Progress -Activity " " -Status " " -Completed

    Write-TypingColored "Processing complete. Files summary:" -Delay 20 -Color "Cyan"
    Write-Host

    $groupedByYear = @{}
    foreach ($monthKey in $fileCounts.Keys) {
        $date = [datetime]::ParseExact($monthKey, "MMMM yyyy", $null)
        $year = $date.Year

        if (-not $groupedByYear.ContainsKey($year)) {
            $groupedByYear[$year] = @{}
        }
        $groupedByYear[$year][$monthKey] = $fileCounts[$monthKey]
    }

    foreach ($year in ($groupedByYear.Keys | Sort-Object)) {
        Write-TypingColored "Year ${year}:" -Delay 20 -Color "Cyan"
        Write-Host

        $sortedMonths = $groupedByYear[$year].Keys | ForEach-Object {
            [PSCustomObject]@{
                Key = $_
                Date = [datetime]::ParseExact($_, "MMMM yyyy", $null)
            }
        } | Sort-Object Date

        foreach ($monthEntry in $sortedMonths) {
            $monthKey = $monthEntry.Key
            $counts = $groupedByYear[$year][$monthKey]

            # Print the month header
            Write-TypingColored "  $monthKey :" -Delay 20 -Color "Green"
            Write-Host

            foreach ($type in $counts.Keys | Where-Object { $counts[$_] -gt 0 }) {
                # Print the label in Green
                Write-Host -NoNewline "    $type files: " -ForegroundColor Green

                # Animate the number in White
                for ($i = 0; $i -le $counts[$type]; $i += [Math]::Max([Math]::Ceiling($counts[$type] / 100),1)) {
                    if ($i -gt $counts[$type]) { $i = $counts[$type] }

                    # Move cursor to the position after the label
                    $cursorLeft = ("    $type files: ").Length
                    $cursorTop = [Console]::CursorTop
                    [Console]::SetCursorPosition($cursorLeft, $cursorTop)

                    # Write the number in White
                    Write-Host ("{0}   " -f $i) -NoNewline -ForegroundColor White

                    Start-Sleep -Milliseconds 5
                }
                Write-Host ""  # move to next line
            }
            Write-Host
        }
    }

$endTime = Get-Date
$duration = $endTime - $startTime

# Display the time taken
Write-TypingColored "Time taken: " -Delay 20 -Color "Magenta"
Write-TypingColored ("{0}h {1}m {2}s" -f $duration.Hours, $duration.Minutes, $duration.Seconds) -Delay 20 -Color "White"
Write-Host

# Print the label in Magenta and animate total files
Write-Host -NoNewline "Total files: " -ForegroundColor Magenta
for ($i = 0; $i -le $totalFiles; $i += [Math]::Max([Math]::Ceiling($totalFiles / 100),1)) {
    if ($i -gt $totalFiles) { $i = $totalFiles }

    $cursorLeft = ("Total files: ").Length
    $cursorTop = [Console]::CursorTop
    [Console]::SetCursorPosition($cursorLeft, $cursorTop)

    Write-Host ("{0}   " -f $i) -NoNewline -ForegroundColor White
    Start-Sleep -Milliseconds 5
}
Write-Host ""  # finish the line

# Calculate total size in GB
$totalSizeBytes = ($photos | Measure-Object -Property Length -Sum).Sum
$totalSizeGB = [Math]::Round($totalSizeBytes / 1GB, 2)

# Display total size transferred
Write-TypingColored "Total size transferred: " -Delay 20 -Color "Magenta"
Write-TypingColored "$totalSizeGB GB" -Delay 20 -Color "White"
Write-Host

# Cleanup empty subfolders
foreach ($destinationFolder in $destinationFolders) {
    $yearFolders = Get-ChildItem -Path $destinationFolder -Directory

    foreach ($yearFolder in $yearFolders) {
        $monthFolders = Get-ChildItem -Path $yearFolder.FullName -Directory
        foreach ($monthFolder in $monthFolders) {
            $userFolderPath = Join-Path -Path $monthFolder.FullName -ChildPath $folderName
            if (Test-Path -Path $userFolderPath -PathType Container) {
                $subFoldersToCheck = @("RAW", "JPEG", "Video", "Others", "PNG")
                foreach ($subFolder in $subFoldersToCheck) {
                    $subFolderPath = Join-Path -Path $userFolderPath -ChildPath $subFolder
                    if (Test-Path -Path $subFolderPath -PathType Container) {
                        if ((Get-ChildItem -Path $subFolderPath -File -Recurse -Force | Measure-Object).Count -eq 0) {
                            Remove-Item -Path $subFolderPath -Recurse -Force
                        }
                    }
                }
            }
        }
    }
}

# Ask user if they want to run the script again
$runAgainChoice = AskRunAgain
} while ($runAgainChoice -eq 'Y')

