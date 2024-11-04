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
and the path to the destination folder. It then copies the photos from the source to the destination 
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
GitHub : https://github.com/Gorfort/P-Script-PowerShell

#>

Write-Host "Welcome" -ForegroundColor Blue

# Specify the folder name directly
$folderName = "Photos"

# Function to prompt the user for a folder path and handle invalid input
function Get-FolderPath {
    param (
        [string]$prompt
    )
    do {
        $folderPath = Read-Host -Prompt $prompt
        if (-not (Test-Path $folderPath -PathType Container)) {
            Write-Host "Invalid folder path. Please try again." -ForegroundColor Red
        } else {
            break
        }
    } while ($true)

    return $folderPath
}

# Function to ask the user if they want to run the script again
function AskRunAgain {
    do {
        $choice = Read-Host "Do you want to run the script again? (Y/N)"
        if ($choice -eq 'Y' -or $choice -eq 'N') {
            return $choice
        } else {
            Write-Host "Invalid choice. Please enter Y or N." -ForegroundColor Red
        }
    } while ($true)
}

# Function to prompt the user for multiple destination folders
function Get-DestinationFolders {
    $destinations = @()

    # Prompt for the first destination folder
    $firstDest = Get-FolderPath -prompt "Enter the primary destination folder path"
    $destinations += $firstDest

    # Ask if the user wants to add more folders
    do {
        $addAnother = Read-Host "Do you want to save the files in an additional folder? (Y/N)"
        
        if ($addAnother -match '^(Y|y)$') {
            $nextDest = Get-FolderPath -prompt "Enter the additional destination folder path"
            $destinations += $nextDest
        } elseif ($addAnother -match '^(N|n)$') {
            break  # Exit the loop if "N" or "n" is entered
        } else {
            Write-Host "Invalid input. Please enter Y or N." -ForegroundColor Red
        }
    } while ($true)

    return $destinations
}

# Initialize a hash table to track files by month and category
$fileCounts = @{}

# Main script execution loop
do {
    $sourceFolder = Get-FolderPath -prompt "Enter the source folder path"
    $destinationFolders = Get-DestinationFolders

    # Get all the photos from the source folder (excluding subdirectories)
    $photos = Get-ChildItem -Path $sourceFolder -File
    $totalFiles = $photos.Count
    $processedFiles = 0

    foreach ($photo in $photos) {
        try {
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

                # Copy the file if it doesn't already exist in the destination
                if (-not (Test-Path $destinationPath)) {
                    Copy-Item $photo.FullName $destinationPath -ErrorAction SilentlyContinue
                }
            }

            # Increment the unique file count after processing all destination folders
            $processedFiles++
            $percentComplete = [math]::floor(($processedFiles / $totalFiles) * 100)
            Write-Progress -Activity "Copying Files" -PercentComplete $percentComplete -Status "$processedFiles/$totalFiles files copied - $percentComplete% complete"

            # Track file counts
            $monthKey = "$currentMonth $currentYear"
            if (-not $fileCounts.ContainsKey($monthKey)) {
                $fileCounts[$monthKey] = @{
                    "RAW" = 0; "JPEG" = 0; "PNG" = 0; "Video" = 0; "Others" = 0
                }
            }
            $fileCounts[$monthKey][$fileType]++

        } catch {
            Write-Host "Error processing $($photo.Name): $_" -ForegroundColor Yellow
        }
    }

    # Final message for completion
    Write-Host "All photos have been copied successfully." -ForegroundColor Green

    # Display summary of file counts per month
    Write-Host "`nSummary of files moved:" -ForegroundColor Cyan
    foreach ($month in $fileCounts.Keys) {
        $counts = $fileCounts[$month]
        $output = "$month :"

        # Build the output string by including only non-zero file types
        foreach ($fileType in $counts.Keys) {
            if ($counts[$fileType] -gt 0) {
                $output += " $($counts[$fileType]) $fileType files,"
            }
        }

        # Remove trailing comma and display the result if there’s any file type to show
        if ($output -ne "$month :") {
            Write-Host ($output.TrimEnd(',')) -ForegroundColor Green
        }
    }

    # Cleanup: Remove empty subfolders
    foreach ($destinationFolder in $destinationFolders) {
        # Get all year folders in the destination folder
        $yearFolders = Get-ChildItem -Path $destinationFolder -Directory

        # Loop through each year folder
        foreach ($yearFolder in $yearFolders) {
            # Loop through each month folder in the year folder
            $monthFolders = Get-ChildItem -Path $yearFolder.FullName -Directory
            foreach ($monthFolder in $monthFolders) {
                # Construct the user folder path based on the folder name
                $userFolderPath = Join-Path -Path $monthFolder.FullName -ChildPath $folderName

                if (Test-Path -Path $userFolderPath -PathType Container) {
                    # List of subfolders to check
                    $subFoldersToCheck = @("RAW", "JPEG", "Video", "Others", "PNG")

                    # Loop through each subfolder and delete if empty
                    foreach ($subFolder in $subFoldersToCheck) {
                        $subFolderPath = Join-Path -Path $userFolderPath -ChildPath $subFolder
                        if (Test-Path -Path $subFolderPath -PathType Container) {
                            # Check if the subfolder is empty
                            if ((Get-ChildItem -Path $subFolderPath -File -Recurse -Force | Measure-Object).Count -eq 0) {
                                Remove-Item -Path $subFolderPath -Recurse -Force
                            }
                        }
                    }
                }
            }
        }
    }

    $runAgain = AskRunAgain

} while ($runAgain -eq 'Y')
