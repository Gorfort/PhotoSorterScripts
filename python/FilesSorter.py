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
import piexif

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
    required_packages = ['Pillow', 'tqdm', 'piexif']
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

def update_metadata(image_path, author_name):
    """Update metadata of the image with the author's name."""
    try:
        # Ensure the path is a string before checking its extension
        image_path_str = str(image_path).lower()

        # Open the image file
        img = Image.open(image_path)

        # Handle JPEG and JPG files (using EXIF)
        if image_path_str.endswith(('jpg', 'jpeg')):
            exif_dict = piexif.load(img.info.get("exif", b""))
            # Update author field in EXIF metadata
            exif_dict['0th'][piexif.ImageIFD.Artist] = author_name.encode()
            exif_bytes = piexif.dump(exif_dict)
            img.save(image_path, exif=exif_bytes)

        # Handle PNG files (using text metadata)
        elif image_path_str.endswith('png'):
            # PNG metadata can be added as text
            img.info['Author'] = author_name  # Add author as PNG text
            img.save(image_path, pnginfo=img.info.get("pnginfo", {}))

        # Handle CR3 files - Currently not updating metadata, but you can process them similarly
        elif image_path_str.endswith('cr3'):
            print(f"Processing CR3 file: {image_path}.")
            # CR3 files typically don't support EXIF metadata modification easily, 
            # but you can add functionality to copy or organize them without skipping.
            # For now, just copying them or handling them as a RAW file.
        
        # DNG files are more complex, so we can leave them untouched for now
        elif image_path_str.endswith('dng'):
            print(f"DNG file found, but metadata update skipped for {image_path}.")
        
    except Exception as e:
        print(f"Error updating metadata for {image_path}: {e}")

def remove_empty_folders(folder_path):
    """Remove empty folders."""
    for dirpath, dirnames, filenames in os.walk(folder_path, topdown=False):
        for dirname in dirnames:
            dir_to_check = os.path.join(dirpath, dirname)
            try:
                os.rmdir(dir_to_check)
            except OSError:
                pass  

def organize_photos(source_folder, destination_folders, author_name):
    """Organize and copy photos with progress bar, and update metadata."""
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
                                # Update metadata with author's name after copying
                                update_metadata(dest_path, author_name)
                                processed_files += 1
                                file_moved = True

                            if f"{current_month} {current_year}" not in file_counts:
                                file_counts[f"{current_month} {current_year}"] = {cat: 0 for cat in subfolders}
                            file_counts[f"{current_month} {current_year}"][category] += 1

                    if not file_moved:
                        continue

                unique_files_processed.add(photo.name)

            except Exception as e:
                typing_effect(f"Error processing {photo.name}: {e}", color="red")

            # Update progress bar color based on progress
            progress_percentage = (idx + 1) / total_files * 100
            if progress_percentage < 33:
                pbar.set_postfix_str("\033[31mProcessing...\033[0m")
            elif progress_percentage < 66:
                pbar.set_postfix_str("\033[33mIn Progress...\033[0m")
            else:
                pbar.set_postfix_str("\033[32mAlmost done...\033[0m")

            pbar.update(1)

    elapsed_time = datetime.now() - start_time
    typing_effect(f"\nProcessing completed in {elapsed_time}", color="green")
    typing_effect(f"Total files processed: {processed_files}", color="green")

    # Remove empty folders
    for folder in destination_folders:
        remove_empty_folders(folder)

    # Ask if user wants to run the script again
    if ask_run_again() == 'Y':
        main()

def main():
    """Main function to run the script."""
    source_folder = get_folder_path("Enter the source folder path:", color="yellow")
    author_name = input("Enter the author's name: ").strip()
    destination_folders = get_destination_folders()
    organize_photos(source_folder, destination_folders, author_name)

# Call the main function to start the script
if __name__ == "__main__":
    main()
