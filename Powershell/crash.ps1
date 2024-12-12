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