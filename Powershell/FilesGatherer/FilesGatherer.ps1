<#

.NOTES
File Name            : FilesGatherer.ps1
Requirements         : PowerShell 7.4.0
Script version       : 1.0.0
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

Write-Host "Welcome to the Files Gatherer" -ForegroundColor Blue

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

# Main script execution loop
do {
    $sourceFolder = Get-FolderPath -prompt "Enter the source folder path"
    $destinationFolder = Get-FolderPath -prompt "Enter the destination folder path"

    # Get all files from the source folder (including subdirectories)
    $files = Get-ChildItem -Path $sourceFolder -File -Recurse
    $totalFiles = $files.Count
    $processedFiles = 0
    $uniqueSourceFolders = @{}

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
                Write-Host "File $($file.Name) already exists in the destination. Skipping." -ForegroundColor Yellow
            }

            # Update progress
            $percentComplete = [math]::floor(($processedFiles / $totalFiles) * 100)
            Write-Progress -Activity "Copying Files" -PercentComplete $percentComplete -Status "$processedFiles/$totalFiles files copied - $percentComplete% complete"

        } catch {
            Write-Host "Error processing $($file.Name): $_" -ForegroundColor Red
        }
    }

    # Final message for completion
    Write-Host "All files have been copied successfully." -ForegroundColor Green
    
    # Summary of moved files and source folders
    $sourceFolderCount = $uniqueSourceFolders.Keys.Count
    Write-Host "$processedFiles files have been moved from $sourceFolderCount folder(s)." -ForegroundColor Cyan

    $runAgain = AskRunAgain

} while ($runAgain -eq 'Y')

if ($runAgain -eq 'N') {
    Write-Host "Goodbye!" -ForegroundColor Green
}