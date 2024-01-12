<#

.NOTES
Nom du fichier 		: P-Script.ps1
Prérequis 			: PowerShell 7.4.0
Version du script 	: 1.0
Auteur 				: Thibaud Racine
Date de creation 	: 13.12.23
Lieu 				: ETML, Sébeillion
Changement 			: Aucun

.SYNOPSIS
Ce script est conçu pour organiser et copier des photos d'un dossier source vers un
vers un dossier de destination. Il classe les photos en fonction de leur extension de fichier
(.CR3, .JPEG, .JPG, .mp4, .MOV et autres) et les place dans des sous-dossiers (RAW, JPEG, Vidéo)
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
GitHub : https://github.com/Gorfort/P-Script-PowerShell

#>

Write-Host "Welcome" -ForegroundColor Blue

# Function to prompt the user for a non-empty folder name
function Get-FolderName {
    param (
        [string]$prompt
    )
    do {
        $folderName = Read-Host -Prompt $prompt
        if (-not $folderName) {
            # In case the user didn't entered a name
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
            # If the folder path is invalid
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
        # If the imput is invalid
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

    # Get the current month and year
    $currentMonth = Get-Date -Format "MMMM"
    $currentYear = Get-Date -Format "yyyy"

    # Create a folder with the current month and year inside the destination folder
    $monthFolder = Join-Path -Path $destinationFolder -ChildPath "$currentMonth $currentYear"
    if (-not (Test-Path $monthFolder -PathType Container)) {
        New-Item -ItemType Directory -Path $monthFolder | Out-Null
    }

    # Create the user-named folder inside the month folder
    $userFolder = Join-Path -Path $monthFolder -ChildPath $folderName
    if (-not (Test-Path $userFolder -PathType Container)) {
        New-Item -ItemType Directory -Path $userFolder | Out-Null
    }

    # Create RAW, JPEG, and Video folders inside the user-named folder
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

    # Get all the photos from the source folder (excluding subdirectories)
    $photos = Get-ChildItem -Path $sourceFolder

    # Initialize variables for the progress bar
    $totalFiles = $photos.Count
    $processedFiles = 0

    # Copy files into the respective folders
    foreach ($photo in $photos) {
        # Put files with the "CR3" and "RAW" extensions into the "RAW" Folder.
        if ($photo.Extension -eq ".CR3" -or $photo.Extension -eq ".RAW") {
            $destinationPath = Join-Path -Path $rawFolderPath -ChildPath $photo.Name
        }
        # Put files with the "JPEG" and "JPG" extensions into the "JPEG" Folder.
        elseif ($photo.Extension -eq ".JPEG" -or $photo.Extension -eq ".JPG") {
            $destinationPath = Join-Path -Path $jpegFolderPath -ChildPath $photo.Name
        }
        # Put files with the "MP4", "MOV", "CMR", and "MXF" extensions into the "Video" Folder.
        elseif ($photo.Extension -eq ".mp4" -or $photo.Extension -eq ".MOV" -or $photo.Extension -eq ".CRM" -or $photo.Extension -eq ".MXF") {
            $destinationPath = Join-Path -Path $videoFolderPath -ChildPath $photo.Name
        }
        # Put files with the "PNG" extension into the "PNG" Folder.
        elseif ($photo.Extension -eq ".png") {
            $destinationPath = Join-Path -Path $pngFolderPath -ChildPath $photo.Name
        }
        #Put all the other extensions into the "Other" Folders
        else {
            $destinationPath = Join-Path -Path $othersFolderPath -ChildPath $photo.Name
        }
 
        # Check if the file already exists in the destination
        if (-not (Test-Path $destinationPath)) {
            # Copy the file to the destination
            Copy-Item $photo.FullName $destinationPath -ErrorAction SilentlyContinue
 
            # Update the progress bar
            $processedFiles++
            $percentComplete = [math]::floor(($processedFiles / $totalFiles) * 100)
            Write-Progress -Activity "Copying Files" -PercentComplete $percentComplete -Status "$processedFiles/$totalFiles files copied - $percentComplete% complete"
        }
    }

    # Change the color of the text to green
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
    if ((Get-ChildItem $othersFolderPath | Measure-Object).Count -eq 0) {
        Remove-Item $othersFolderPath
    }
    if ((Get-ChildItem $pngFolderPath | Measure-Object).Count -eq 0) {
        Remove-Item $pngFolderPath
    }

    # Ask the user if they want to run the script again
    $runAgain = AskRunAgain
} while ($runAgain -eq 'Y')