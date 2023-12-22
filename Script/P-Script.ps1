<#
.SYNOPSIS
Ce script est conçu pour organiser et copier des photos d'un dossier source vers un
vers un dossier de destination. Il classe les photos en fonction de leur extension de fichier
(.CR3, .JPEG, .JPG, .mp4, .MOV) et les place dans des sous-dossiers (RAW, JPEG, Vidéo)
dans le dossier de destination. 
 
.DESCRIPTION
Le script invite l'utilisateur à saisir un nom de dossier, un chemin d'accès au dossier source,
et le chemin du dossier de destination. Il copie ensuite les photos de la source vers la destination 
en les organisant dans des sous-dossiers en fonction de leur type de fichier.
 
.PARAMETER Nom
Spécifie le nom du dossier saisi par l'utilisateur.
 
.PARAMETER Extension
.ps1
 
.INPUTS
Le script prend en compte les noms de dossiers et les chemins d'accès saisis par l'utilisateur.
 
.OUTPUTS
Le script organise et copie les photos en fonction des critères spécifiés. 
Il fournit des informations sur le processus de copie et l'organisation des dossiers.
 
.EXAMPLE
PS> .\P-Script.ps1
Cet exemple montre comment exécuter le script, demander à l'utilisateur
des noms de dossiers et des chemins d'accès, et organiser et copier les photos.
 
.LINK
Pas de lien sur ce script
#>

# Change the color of "Welcome" to blue
Write-Host "Welcome" -ForegroundColor Blue
 
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
 
 
# Function to ask the user if they want to run the script again
function AskRunAgain {
    do {
        $choice = Read-Host "Do you want to run the script again? (Y/N)"
        if ($choice -eq 'Y' -or $choice -eq 'N') {
            return $choice
        }
        else {
            Write-Host "Invalid choice. Please enter Y or N." -ForegroundColor Red
        }
    } while ($true)
}
 
do {

    # Prompt the user for the folder name
    $folderName = Get-FolderName -prompt "Enter folder name"

    # Prompt the user for the source folder
    $sourceFolder = Get-FolderPath -prompt "Enter the source folder path "
 
    # Prompt the user for the destination folder
    $destinationFolder = Get-FolderPath -prompt "Enter the destination folder path "
 
    # Check if the destination folder exists, if not, create it
    if (-not (Test-Path $destinationFolder -PathType Container)) {
        New-Item -ItemType Directory -Path $destinationFolder | Out-Null
    }
 
    # Create the destination folder with the specified folder name
    $destinationFolder = Join-Path -Path $destinationFolder -ChildPath $folderName
 
    # Check if the folder already exists in the destination folder
    if (Test-Path $destinationFolder -PathType Container) {
        Write-Host "Folder '$folderName' already exists in the destination. Adding photos to the existing folders." -ForegroundColor Yellow
    }
    else {
        New-Item -ItemType Directory -Path $destinationFolder | Out-Null
    }
 
    # Create RAW, JPEG, and Video folders inside the destination folder
    $rawFolderPath = Join-Path -Path $destinationFolder -ChildPath "RAW"
    $jpegFolderPath = Join-Path -Path $destinationFolder -ChildPath "JPEG"
    $videoFolderPath = Join-Path -Path $destinationFolder -ChildPath "Video"
 
    New-Item -ItemType Directory -Path $rawFolderPath -ErrorAction SilentlyContinue | Out-Null
    New-Item -ItemType Directory -Path $jpegFolderPath -ErrorAction SilentlyContinue | Out-Null
    New-Item -ItemType Directory -Path $videoFolderPath -ErrorAction SilentlyContinue | Out-Null
 
    # Get all the photos from the source folder (excluding subdirectories)
    $photos = Get-ChildItem -Path $sourceFolder
 
    # Initialize variables for the progress bar
    $totalFiles = $photos.Count
    $processedFiles = 0
 
    foreach ($photo in $photos) {
        if ($photo.Extension -eq ".CR3") {
            $destinationPath = Join-Path -Path $rawFolderPath -ChildPath $photo.Name
        }
        elseif ($photo.Extension -eq ".JPEG" -or $photo.Extension -eq ".JPG") {
            $destinationPath = Join-Path -Path $jpegFolderPath -ChildPath $photo.Name
        }
        elseif ($photo.Extension -eq ".mp4" -or $photo.Extension -eq ".MOV") {
            $destinationPath = Join-Path -Path $videoFolderPath -ChildPath $photo.Name
        }
     
        # Check if the file already exists in the destination
        if (Test-Path $destinationPath) {
            Write-Host "File '$photo.Name' already exists in the destination. Skipping." -ForegroundColor Yellow
        }
        else {
            # File doesn't exist, proceed with the copy
            Copy-Item $photo.FullName $destinationPath -ErrorAction SilentlyContinue
     
            # Update the progress bar
            $processedFiles++
            $percentComplete = [math]::floor(($processedFiles / $totalFiles) * 100)
            Write-Progress -Activity "Copying Files" -PercentComplete $percentComplete -Status "$processedFiles/$totalFiles files copied - $percentComplete% complete"
        }
    }
 
    Clear-Host
    # Change the color of "Photos have been copied successfully" to green
    Write-Host "Photos have been copied successfully." -ForegroundColor Green
 
    # Check if folders are empty and delete them
    if ((Get-ChildItem $rawFolderPath | Measure-Object).Count -eq 0) {
        Remove-Item $rawFolderPath
    }
 
    if ((Get-ChildItem $jpegFolderPath | Measure-Object).Count -eq 0) {
        Remove-Item $jpegFolderPath
    }
 
    if ((Get-ChildItem $videoFolderPath | Measure-Object).Count -eq 0) {
        Remove-Item $videoFolderPath
    }
 
    # Ask the user if they want to run the script again
    $runAgain = AskRunAgain
} while ($runAgain -eq 'Y')