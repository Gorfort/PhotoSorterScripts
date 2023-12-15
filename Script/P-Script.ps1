# Change the color of "Welcome" to blue
Write-Host "Welcome" -ForegroundColor Blue
# Function to prompt the user for folder path and handle invalid input
function Get-FolderPath {
    param (
        [string]$prompt
    )
    do {
        $folderPath = Read-Host -Prompt $prompt
        if (-not (Test-Path $folderPath -PathType Container)) {
            Write-Host "Invalid folder path. Please try again." -ForegroundColor Red
        }
        else {
            break
        }
    } while ($true)
    return $folderPath
}
 
# Function to prompt the user for a non-empty folder name
function Get-FolderName {
    param (
        [string]$prompt
    )
    do {
        $folderName = Read-Host -Prompt $prompt
        if (-not $folderName) {
            Write-Host "Folder name cannot be empty. Please enter a name." -ForegroundColor Red
        }
        else {
            break
        }
    } while ($true)
    return $folderName
}
# Prompt the user for the source folder
$sourceFolder = Get-FolderPath -prompt "Enter the source folder path "
# Prompt the user for the folder name
$folderName = Get-FolderName -prompt "Enter folder name"
# Prompt the user for the destination folder
$destinationFolder = Get-FolderPath -prompt "Enter the destination folder path "
# Check if the destination folder exists, if not, create it
if (-not (Test-Path $destinationFolder -PathType Container)) {
    New-Item -ItemType Directory -Path $destinationFolder | Out-Null
}
# Create the destination folder with the specified folder name
$destinationFolder = Join-Path -Path $destinationFolder -ChildPath $folderName
New-Item -ItemType Directory -Path $destinationFolder | Out-Null
 
# Create RAW and JPEG folders inside the destination folder
$rawFolderPath = Join-Path -Path $destinationFolder -ChildPath "RAW"
$jpegFolderPath = Join-Path -Path $destinationFolder -ChildPath "JPEG"
 
New-Item -ItemType Directory -Path $rawFolderPath | Out-Null
New-Item -ItemType Directory -Path $jpegFolderPath | Out-Null
 
# Get all the photos from the source folder (excluding subdirectories)
$photos = Get-ChildItem -Path $sourceFolder
 
foreach ($photo in $photos) {
    if ($photo.Extension -eq ".CR3") {
        Copy-Item $photo.FullName $rawFolderPath
    }
    elseif ($photo.Extension -eq ".JPEG" -or $photo.Extension -eq ".JPG") {
        Copy-Item $photo.FullName $jpegFolderPath
    }
}
 
# Change the color of "Photos have been copied successfully" to green
Write-Host "Photos have been copied successfully." -ForegroundColor Green