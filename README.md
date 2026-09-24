# Photo Organizer Script 📷
![PowerShell](https://img.shields.io/badge/PowerShell-%235391FE.svg?style=for-the-badge&logo=powershell&logoColor=white)  ![Visual Studio Code](https://img.shields.io/badge/Visual%20Studio%20Code-0078d7.svg?style=for-the-badge&logo=visual-studio-code&logoColor=white) ![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54) ![macOS](https://img.shields.io/badge/mac%20os-000000?style=for-the-badge&logo=macos&logoColor=F0F0F0) ![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black) ![Windows 11](https://img.shields.io/badge/Windows%2011-%230079d5.svg?style=for-the-badge&logo=Windows%2011&logoColor=white)
## Overview
These scripts automate the organization and copying of files from a source folder to one or more destination folders. They classify files based on their extensions (CR3, RAW, DNG, JPEG, JPG, PNG, MP4, MOV, CRM, MXF) and organize them into year and month folders with subfolders for each file type: RAW, JPEG, PNG, Video, and Others. Files are grouped under a user folder named after the current user, and the scripts summarize the processed files when they finish.

## Features
- **User-Friendly**: Prompts for the source folder, one destination folder, and optional additional destinations.
- **Organized Structure**: Sorts files into year and month folders, then into RAW, JPEG, PNG, Video, or Others.
- **Multi Destination**: Copies the same files into multiple destination folders in one run.
- **Progress Tracking**: Displays live copy progress and estimated time remaining.
- **Summary**: Prints a year-by-year and month-by-month summary, along with total time and total size transferred.
- **Cleanup**: Removes empty type folders after processing.

## Requirements
- PowerShell 7.4.0 or later for `FilesSorter.ps1` and `FilesGatherer.ps1`.
- Python 3 for `FilesSorter.py` and `FilesGatherer.py`.
- The Python scripts install `Pillow` automatically on first run.

## How to use the scripts with PowerShell
1. Download or clone this repository.
2. Open a terminal and navigate to the script directory.
3. Run the script using:
   ```powershell
   .\FilesSorter.ps1
   ```
   ```powershell
   .\FilesGatherer.ps1
   ```

## How to use the scripts with Python
1. Download or clone this repository.
2. Open a terminal and navigate to the script directory.
3. Run the script using:
   ```python
   python3 FilesSorter.py
   ```
   ```python
   python3 FilesGatherer.py
   ```

## What the sorter asks for
When you run `FilesSorter.ps1` or `FilesSorter.py`, the script will prompt you for:
- The source folder path.
- A destination folder path.
- An optional additional destination folder path.
- Whether you want to run the script again when the first pass finishes.

## Output structure
The sorter creates a structure like this in each destination folder:

```text
<destination>\
   <year>\
      <month> <year>\
         <username>\
            RAW\
            JPEG\
            PNG\
            Video\
            Others\
```
