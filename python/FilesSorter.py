import os
import shutil
from datetime import datetime
from pathlib import Path
import subprocess
import sys
import time
from tqdm import tqdm
from PIL import Image
from PIL.ExifTags import TAGS

# Typing effect function to display text with delay
def typing_effect(text, delay=0.02, color=None):
    """Simulate typing effect with optional colors."""
    # Define ANSI color codes
    color_codes = {
        "black": "\033[30m",
        "red": "\033[31m",
        "green": "\033[32m",
        "yellow": "\033[33m",
        "blue": "\033[34m",
        "magenta": "\033[35m",
        "cyan": "\033[36m",
        "white": "\033[37m",
        "reset": "\033[0m"
    }

    # Apply color if specified
    if color and color in color_codes:
        text = color_codes[color] + text + color_codes["reset"]

    for char in text:
        print(char, end='', flush=True)
        time.sleep(delay)
    print()

# Automatically install required modules
def install_packages():
    required_packages = ['Pillow', 'tqdm']
    try:
        typing_effect("Updating packages...", delay=0.04, color="blue")
        
        for package in required_packages:
            subprocess.check_call(
                [sys.executable, "-m", "pip", "install", package],
                stdout=subprocess.DEVNULL,  # Suppress standard output
                stderr=subprocess.DEVNULL   # Suppress error output
            )

        # Make the "Updating packages..." message disappear
        print('\r' + ' ' * 20 + '\r', end='', flush=True)  # Clear the line
    except Exception as e:
        print(f"\nFailed to install packages: {e}")
        sys.exit(1)

# Call install_packages at the start
install_packages()

def get_folder_path(prompt, color="yellow"):
    """Prompt user for a valid folder path."""
    while True:
        typing_effect(prompt, delay=0.04, color=color)
        folder_path = input()
        if folder_path and os.path.isdir(folder_path):
            return folder_path
        else:
            typing_effect("Invalid input. Please enter a valid folder path.", color="red")

def ask_run_again():
    """Prompt user to decide if the script should run again."""
    while True:
        typing_effect("Do you want to run the script again? (Y/N)", delay=0.02)
        choice = input().strip().upper()
        if choice in ['Y', 'N']:
            return choice
        else:
            typing_effect("Invalid choice. Please enter Y or N.", color="red")

def get_destination_folders():
    """Prompt user for destination folders."""
    destinations = []
    first_dest = get_folder_path("Enter the primary destination folder path:", color="yellow")
    destinations.append(first_dest)

    while True:
        typing_effect("Do you want to save the files in an additional folder? (Y/N)", delay=0.02, color="yellow")
        add_another = input().strip().upper()
        if add_another == 'Y':
            next_dest = get_folder_path("Enter the additional destination folder path:", color="yellow")
            destinations.append(next_dest)
        elif add_another == 'N':
            break
        else:
            typing_effect("Invalid input. Please enter Y or N.", color="red")

    return destinations

def remove_empty_folders(folder_path):
    """Remove empty folders."""
    for dirpath, dirnames, filenames in os.walk(folder_path, topdown=False):
        for dirname in dirnames:
            dir_to_check = os.path.join(dirpath, dirname)
            try:
                os.rmdir(dir_to_check)
            except OSError:
                pass

def update_metadata(image_path, author_name):
    """Update metadata of the image with the author's name using ExifTool."""
    try:
        # Convert path to string and ensure it's wrapped in quotes (to handle spaces in paths)
        image_path_str = str(image_path)
        image_path_str = f'"{image_path_str}"'  # Wrap the path in double quotes

        # Exclude non-image files like .DS_Store
        if not image_path_str.lower().endswith(('.jpg', '.jpeg', '.png', '.tiff', '.cr3', '.raw', '.dng')):
            return

        # Provide the full path to ExifTool on Windows
        exiftool_path = r"C:\path\to\exiftool.exe"  # Update this path if ExifTool isn't in PATH
        
        # Ensure the ExifTool path is correctly specified
        if not os.path.exists(exiftool_path):
            print(f"ExifTool not found at {exiftool_path}. Please verify the path.")
            return

        # Build the command for ExifTool
        command = [exiftool_path, '-overwrite_original', f'-Artist={author_name}', image_path_str]
        
        # Run the ExifTool command to update the metadata
        subprocess.run(command, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        print(f"Metadata updated for {image_path_str}")

    except Exception as e:
        print(f"Error updating metadata for {image_path}: {e}")

def organize_photos(source_folder, destination_folders, author_name):
    """Organize and copy photos with progress bar."""
    file_counts = {}
    unique_files_processed = set()

    photos = [f for f in os.scandir(source_folder) if f.is_file()]
    total_files = len(photos)
    processed_files = 0

    start_time = datetime.now()

    # Use tqdm to show progress
    with tqdm(total=total_files, desc="Processing photos", unit="file") as pbar:
        for idx, photo in enumerate(photos):
            try:
                if photo.name in unique_files_processed:
                    continue

                # Get the date taken
                date_taken = None
                if photo.name.lower().endswith(('.jpg', '.jpeg')):
                    try:
                        image = Image.open(photo.path)
                        exif_data = image._getexif()
                        if exif_data:
                            for tag, value in exif_data.items():
                                if TAGS.get(tag, tag) == 'DateTimeOriginal':
                                    date_taken = datetime.strptime(value, '%Y:%m:%d %H:%M:%S')
                                    break
                    except:
                        pass

                if not date_taken:
                    date_taken = datetime.fromtimestamp(photo.stat().st_mtime)

                current_month = date_taken.strftime("%B")
                current_year = date_taken.strftime("%Y")

                # Organize by destination folders
                for destination_folder in destination_folders:
                    year_folder = Path(destination_folder) / current_year
                    month_folder = year_folder / f"{current_month} {current_year}"

                    if not month_folder.exists():
                        month_folder.mkdir(parents=True, exist_ok=True)

                    # Subfolders for file types
                    subfolders = {
                        "RAW": ['.cr3', '.raw', '.dng'],
                        "JPEG": ['.jpg', '.jpeg'],
                        "PNG": ['.png'],
                        "Video": ['.mp4', '.mov', '.crm', '.mxf'],
                        "Others": []  # For unsupported files
                    }

                    # Assign to the correct category
                    file_moved = False
                    extension = photo.name.split('.')[-1].lower()
                    for category, extensions in subfolders.items():
                        if f".{extension}" in extensions or (category == "Others" and f".{extension}" not in sum(list(subfolders.values()), [])):
                            category_folder = month_folder / category
                            if not category_folder.exists():
                                category_folder.mkdir(parents=True, exist_ok=True)

                            dest_path = category_folder / photo.name
                            if not dest_path.exists():
                                shutil.copy2(photo.path, dest_path)
                                processed_files += 1
                                file_moved = True

                            if f"{current_month} {current_year}" not in file_counts:
                                file_counts[f"{current_month} {current_year}"] = {cat: 0 for cat in subfolders}
                            file_counts[f"{current_month} {current_year}"][category] += 1

                            # Update metadata after moving the file
                            update_metadata(dest_path, author_name)

                    if not file_moved:
                        continue

                unique_files_processed.add(photo.name)

            except Exception as e:
                typing_effect(f"Error processing {photo.name}: {e}", color="red")

            # Update progress bar color based on progress
            progress_percentage = (idx + 1) / total_files * 100
            if progress_percentage < 33:
                pbar.set_postfix_str("\033[31mProcessing...\033[0m")  # Red
            elif progress_percentage < 66:
                pbar.set_postfix_str("\033[33mProcessing...\033[0m")  # Yellow
            else:
                pbar.set_postfix_str("\033[32mProcessing...\033[0m")  # Green

            pbar.update(1)

    # Time taken
    duration = datetime.now() - start_time
    formatted_duration = str(duration).split('.')[0]
    hours, minutes, seconds = map(int, formatted_duration.split(':'))
    formatted_time = f"{hours:01}:{minutes:02}:{seconds:02}"

    typing_effect(f"Time taken: {formatted_time}", color="magenta")

    remove_empty_folders(source_folder)
    for destination_folder in destination_folders:
        remove_empty_folders(destination_folder)

    return file_counts

if __name__ == "__main__":
    try:
        typing_effect("Welcome to the Files Sorter !", color="green")
        run_again = 'Y'
        while run_again == 'Y':
            source_folder = get_folder_path("Enter the source folder path:")
            author_name = input("Enter the author's name for metadata update: ")
            destination_folders = get_destination_folders()
            file_counts = organize_photos(source_folder, destination_folders, author_name)

            typing_effect("Processing complete. Files summary:", color="cyan")
            for month, counts in file_counts.items():
                output = f"\033[33m{month} - "
                for idx, (key, value) in enumerate(counts.items()):
                    if value > 0:
                        output += f"\033[32m{key}: \033[37m{value}"
                        if idx < len(counts) - 1:
                            output += ", "
                typing_effect(output, color="white", delay=0.04)
            run_again = ask_run_again()

        typing_effect("Goodbye !", color="cyan")

    except KeyboardInterrupt:
        typing_effect("\nScript interrupted by user. Goodbye!", color="red")
