# Photo Organizer Script 📷
![PowerShell](https://img.shields.io/badge/PowerShell-%235391FE.svg?style=for-the-badge&logo=powershell&logoColor=white) ![Windows 11](https://img.shields.io/badge/Windows%2011-%230079d5.svg?style=for-the-badge&logo=Windows%2011&logoColor=white) ![Visual Studio Code](https://img.shields.io/badge/Visual%20Studio%20Code-0078d7.svg?style=for-the-badge&logo=visual-studio-code&logoColor=white)
## Overview
This PowerShell script automates the organization and copying of photos from a source folder to a destination folder. It classifies files based on their extensions (e.g., CR3, JPEG, JPG, MP4, MOV, etc.) and organizes them into subfolders such as **RAW**, **JPEG**, **PNG**, **Video**, and **Others**.

## Features
- **User-Friendly**: Prompts for source and destination folder paths.
- **Organized Structure**: Sorts files into year and month folders, with user-defined subfolders for each file type.
- **Multi Destination**: You can copy your files into different folders at the same time.
- **Progress Tracking**: Displays the progress of file copying in real-time.
- **Summary**: When the script is done you get a summary of the moved files.

## Requirements
- PowerShell 7.4.0 or later.

## Installation
1. Download or clone this repository.
2. Open PowerShell and navigate to the script directory.
3. Run the script using:
   ```powershell
   .\FilesSorter.ps1
