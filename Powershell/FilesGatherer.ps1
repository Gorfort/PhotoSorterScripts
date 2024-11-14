<#

.NOTES
File Name            : FilesGatherer.ps1
Requirements         : PowerShell 7.4.0
Script version       : 1.0.3
Author               : Thibaud Racine
Creation date        : 04.11.24
Location             : ETML Lausanne, Switzerland

.SYNOPSIS
This script is designed to gather files from a source folder and copy them to a 
destination folder without sorting them into subfolders. It simply transfers files 
from the source to the destination.

.DESCRIPTION
The script prompts the user to enter a path to the source folder,
and the path to the destination folder. It then copies all files from the source 
to the destination folder without any organization by type or metadata.

.PARAMETER Extension
.ps1

.INPUTS
The script takes into account paths entered by the user.

.OUTPUTS
The script copies files from the source folder to the destination folder directly. 
It provides information on the copying process.

.EXAMPLE
First enter into the directory where the script is located.
- cd Script
- .\FilesGatherer.ps1
This example shows how to run the script.

.LINK
GitHub : https://github.com/Gorfort/PhotoSorter-PowerShell

#>

# Helper function to simulate typing effect with color
function Write-TypingEffect {
    param (
        [string]$text,
        [int]$delay = 50,            # Adjust delay (milliseconds) for typing speed
        [ConsoleColor]$color = "White" # Default color set to White
    )
    foreach ($char in $text.ToCharArray()) {
        Write-Host -NoNewline $char -ForegroundColor $color
        Start-Sleep -Milliseconds $delay
    }
    Write-Host ""
}

# Intro message with blue color
Write-TypingEffect "Welcome to the Files Gatherer" -delay 40 -color "Cyan"

# Function to prompt the user for a folder path and handle invalid input
function Get-FolderPath {
    param (
        [string]$prompt
    )
    do {
        Write-TypingEffect $prompt -delay 40 -color "Yellow"
        $folderPath = Read-Host
        if (-not (Test-Path $folderPath -PathType Container)) {
            Write-TypingEffect "Invalid folder path. Please try again." -delay 40 -color "Red"
        } else {
            break
        }
    } while ($true)

    return $folderPath
}

# Function to ask the user if they want to run the script again
function AskRunAgain {
    do {
        Write-TypingEffect "Do you want to run the script again? (Y/N)" -delay 40 -color "Yellow"
        $choice = Read-Host
        if ($choice -eq 'Y' -or $choice -eq 'N') {
            return $choice
        } else {
            Write-TypingEffect "Invalid choice. Please enter Y or N." -delay 40 -color "Red"
        }
    } while ($true)
}

# Main script execution loop
do {
    $sourceFolder = Get-FolderPath -prompt "Enter the source folder path :"
    $destinationFolder = Get-FolderPath -prompt "Enter the destination folder path :"

    # Get all files from the source folder (including subdirectories)
    $files = Get-ChildItem -Path $sourceFolder -File -Recurse
    $totalFiles = $files.Count
    $processedFiles = 0
    $uniqueSourceFolders = @{}

    # Record the start time
    $startTime = Get-Date

    foreach ($file in $files) {
        try {
            # Define the destination path
            $destinationPath = Join-Path -Path $destinationFolder -ChildPath $file.Name

            # Copy the file if it doesn't already exist in the destination
            if (-not (Test-Path $destinationPath)) {
                Copy-Item -Path $file.FullName -Destination $destinationPath -ErrorAction SilentlyContinue
                $processedFiles++
                
                # Track the unique source folder
                $uniqueSourceFolders[$file.DirectoryName] = $true
            } else {
                Write-TypingEffect "File $($file.Name) already exists in the destination. Skipping." -delay 30 -color "Yellow"
            }

            # Update progress
            $percentComplete = [math]::floor(($processedFiles / $totalFiles) * 100)
            Write-Progress -Activity "Copying Files" -PercentComplete $percentComplete -Status "$processedFiles/$totalFiles files copied - $percentComplete% complete"

        } catch {
            Write-TypingEffect "Error processing $($file.Name): $_" -delay 30 -color "Red"
        }
    }

    # Record the end time and calculate the duration
    $endTime = Get-Date
    $duration = $endTime - $startTime

    # Clear the progress bar after copying is complete
    Write-Progress -Activity " " -Status " " -Completed

    # Final message for completion in green
    Write-TypingEffect "All files have been copied successfully." -delay 40 -color "Green"
    
    # Summary of moved files and source folders in cyan, and display the duration
    $sourceFolderCount = $uniqueSourceFolders.Keys.Count
    Write-TypingEffect "$processedFiles files have been moved from $sourceFolderCount folder(s)." -delay 40 -color "Cyan"
    Write-TypingEffect "Time taken: $($duration.Hours)h $($duration.Minutes)m $($duration.Seconds)s" -delay 40 -color "Magenta"

    $runAgain = AskRunAgain

} while ($runAgain -eq 'Y')

if ($runAgain -eq 'N') {
    Write-TypingEffect "Goodbye!" -delay 40 -color "Green"
}
