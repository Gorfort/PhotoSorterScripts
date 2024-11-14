<#

.NOTES
File Name            : P-Script.ps1
Requirements         : PowerShell 7.4.0
Script version       : 1.0.5
Author               : Thibaud Racine
Creation date        : 13.12.23
Location             : ETML Lausanne, Switzerland

.SYNOPSIS
This script is designed to organize and copy photos from a source folder to a
to a destination folder. It classifies photos according to their file extension
(CR3, JPEG, JPG, MP4, MOV, CMR, MXF and others) and places them in subfolders (RAW, JPEG, PNG, Video, Others)
in the destination folder.
 
.DESCRIPTION
The script prompts the user to enter a path to the source folder,
and the path to the destination folders. It then copies the photos from the source to the destination 
organizing them into sub-folders according to file type and metadata time.
 
.PARAMETER Extension
.ps1
 
.INPUTS
The script takes into account paths entered by the user.
 
.OUTPUTS
The script organizes and copies photos according to specified criteria. 
It provides information on the copying process and folder organization.
 
.EXAMPLE
First enter into the directory where the script is located.
- cd Script
- .\FilesSorter.ps1
This example shows how to run the script.
 
.LINK
GitHub : https://github.com/Gorfort/PhotoSorter-PowerShell

#>
# Function to simulate typing effect
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

Write-Typing "Welcome to the Files Sorter" -delay 20 -color "Cyan"

# Function to get folder path from user
function Get-FolderPath {
    param (
        [string]$prompt
    )
    do {
        Write-Typing $prompt -delay 40 -color "Yellow"
        $folderPath = Read-Host
        
        # Check if the input is empty or the folder path does not exist
        if (-not $folderPath -or -not (Test-Path $folderPath -PathType Container)) {
            Write-Typing "Invalid input. Please enter a valid folder path." -delay 20 -color "Red"
        } else {
            break
        }
    } while ($true)

    return $folderPath
}

# Function to ask the user if they want to run the script again
function AskRunAgain {
    do {
        Write-Typing "Do you want to run the script again? (Y/N)" -delay 20 -color "Yellow"
        $choice = Read-Host
        if ($choice -eq 'Y' -or $choice -eq 'N') {
            return $choice
        } else {
            Write-Typing "Invalid choice. Please enter Y or N." -delay 20 -color "Red"
        }
    } while ($true)
}

# Function to ask the user if they want to add another folder
function Get-DestinationFolders {
    $destinations = @()

    # Prompt for the first destination folder
    $firstDest = Get-FolderPath -prompt "Enter the primary destination folder path"
    $destinations += $firstDest

    # Ask if the user wants to add more folders
    do {
        Write-Typing "Do you want to save the files in an additional folder? (Y/N)" -delay 20 -color "Yellow"
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

# Main script execution (rest of your script continues here...)


# Initialize a hash table to track files by month and category
$fileCounts = @{}
# Create an array to track unique file names that have been processed
$uniqueFilesProcessed = @()

# Main script execution loop
do {
    $sourceFolder = Get-FolderPath -prompt "Enter the source folder path"
    $destinationFolders = Get-DestinationFolders

    # Start timer
    $startTime = Get-Date

# Get all the photos from the source folder (excluding subdirectories)
$photos = Get-ChildItem -Path $sourceFolder -File
$totalFiles = $photos.Count
$processedFiles = 0
$startTime = Get-Date
$previousTime = $startTime

foreach ($photo in $photos) {
    try {
        # Check if the file has already been processed
        if ($uniqueFilesProcessed -contains $photo.Name) {
            continue  # Skip processing if already counted
        }

        # Get the Date Taken from metadata or use LastWriteTime as a fallback
        $dateTaken = (Get-ItemProperty -Path $photo.FullName -Name DateTaken -ErrorAction SilentlyContinue).DateTaken
        if ($null -eq $dateTaken) {
            $dateTaken = $photo.LastWriteTime
        }

        $currentMonth = $dateTaken.ToString("MMMM")
        $currentYear = $dateTaken.ToString("yyyy")

        # Process each destination folder
        foreach ($destinationFolder in $destinationFolders) {
            if (-not (Test-Path $destinationFolder -PathType Container)) {
                New-Item -ItemType Directory -Path $destinationFolder | Out-Null
            }

            # Create year and month folders within each destination
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

            # Create subfolders for different file types within the user-named folder
            $rawFolderPath = Join-Path -Path $userFolder -ChildPath "RAW"
            $pngFolderPath = Join-Path -Path $userFolder -ChildPath "PNG"
            $jpegFolderPath = Join-Path -Path $userFolder -ChildPath "JPEG"
            $videoFolderPath = Join-Path -Path $userFolder -ChildPath "Video"
            $othersFolderPath = Join-Path -Path $userFolder -ChildPath "Others"

            # Create folders only if they don't exist
            New-Item -ItemType Directory -Path $rawFolderPath -ErrorAction SilentlyContinue | Out-Null
            New-Item -ItemType Directory -Path $pngFolderPath -ErrorAction SilentlyContinue | Out-Null
            New-Item -ItemType Directory -Path $jpegFolderPath -ErrorAction SilentlyContinue | Out-Null
            New-Item -ItemType Directory -Path $videoFolderPath -ErrorAction SilentlyContinue | Out-Null
            New-Item -ItemType Directory -Path $othersFolderPath -ErrorAction SilentlyContinue | Out-Null

            # Determine the destination path based on file extension
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

            # Copy the file if it does not already exist at the destination
            if (-not (Test-Path -Path $destinationPath)) {
                Copy-Item -Path $photo.FullName -Destination $destinationPath
                $processedFiles++
            }
        }

        # Update processed files list and percentage
        $uniqueFilesProcessed += $photo.Name
        $percentComplete = [math]::floor(($processedFiles / $totalFiles) * 100)
        
        # Track file counts
        $monthKey = "$currentMonth $currentYear"
        if (-not $fileCounts.ContainsKey($monthKey)) {
            $fileCounts[$monthKey] = @{
                "RAW" = 0; "JPEG" = 0; "PNG" = 0; "Video" = 0; "Others" = 0
            }
        }
        $fileCounts[$monthKey][$fileType]++

        # Calculate the time taken for the current file
        $currentTime = Get-Date
        $timeElapsed = $currentTime - $previousTime
        $previousTime = $currentTime

        # Calculate the average time per file
        $averageTimePerFile = ($currentTime - $startTime).TotalSeconds / $processedFiles

        # Estimate the remaining time
        $remainingFiles = $totalFiles - $processedFiles
        $estimatedRemainingTime = $remainingFiles * $averageTimePerFile
        $estimatedRemainingTimeFormatted = [TimeSpan]::FromSeconds($estimatedRemainingTime).ToString("hh\:mm\:ss")

        # Update the progress bar and include the estimated remaining time in the Status message
        Write-Progress -Activity "Copying Files" -PercentComplete $percentComplete -Status "$processedFiles/$totalFiles files copied - $percentComplete% complete. Estimated Time Remaining: $estimatedRemainingTimeFormatted"
        
    } catch {
        Write-Host "Error processing $($photo.Name): $_" -ForegroundColor Red
    }
}


    # Clear the progress bar after copying is complete
    Write-Progress -Activity " " -Status " " -Completed

    # Display file summary after processing
    Write-Typing "Processing complete. Files summary:" -delay 20 -color "Cyan"
    $fileCounts.GetEnumerator() | ForEach-Object {
        $monthKey = $_.Key
        $counts = $_.Value
        $output = "$monthKey -"

        # Build the output by including only counts greater than 0
        $output += ($counts.Keys | Where-Object { $counts[$_] -gt 0 } | ForEach-Object { "$_ : $($counts[$_])" }) -join ", "

        Write-Typing $output -delay 40 -color "Green"
    }

    # Calculate the time taken and display
    $endTime = Get-Date
    $duration = $endTime - $startTime
    Write-Typing "Time taken: $($duration.Hours)h $($duration.Minutes)m $($duration.Seconds)s" -delay 20 -color "Magenta"

    # Cleanup: Remove empty subfolders
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

    $runAgainChoice = AskRunAgain
} while ($runAgainChoice -eq 'Y')
