# Photo Organizer Script 📷

## Overview
This PowerShell script automates the organization and copying of photos from a source folder to a destination folder. It classifies files based on their extensions (e.g., CR3, JPEG, JPG, MP4, MOV, etc.) and organizes them into subfolders such as **RAW**, **JPEG**, **PNG**, **Video**, and **Others**.

## Features
- **User-Friendly**: Prompts for source and destination folder paths.
- **Organized Structure**: Sorts files into year and month folders, with user-defined subfolders for each file type.
- **Error Handling**: Catches and displays errors during the copying process.
- **Progress Tracking**: Displays the progress of file copying in real-time.

## Requirements
- PowerShell 7.4.0 or later.

## Installation
1. Download or clone this repository.
2. Open PowerShell and navigate to the script directory.
3. Run the script using:
   ```powershell
   .\FilesSorter.ps1
