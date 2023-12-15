# Prompt the user for the folder name
$folderName = Read-Host -Prompt "Enter folder name"
 
# Create the destination folder
$destinationFolder = Join-Path -Path "C:\Users\EtmlPowershell\Desktop\photos" -ChildPath $folderName
New-Item -ItemType Directory -Path $destinationFolder
 
# Create RAW and JPEG folders inside the destination folder
$rawFolderPath = Join-Path -Path $destinationFolder -ChildPath "RAW"
$jpegFolderPath = Join-Path -Path $destinationFolder -ChildPath "JPEG"
 
New-Item -ItemType Directory -Path $rawFolderPath
New-Item -ItemType Directory -Path $jpegFolderPath
 
# Get all the photos from the SD card (excluding subdirectories)
$photos = Get-ChildItem -Path "C:\Users\EtmlPowershell\Desktop\SD" 
 
foreach ($photo in $photos) {
    
    if ($photo.Extension -eq ".CR3")
    {
        Copy-Item $photo $rawFolderPath
    }
    if ($photo.Extension -eq ".JPEG")
    {
        Copy-Item $photo $jpegFolderPath
    }
}
 
Write-Host "Photos have been copied successfully."