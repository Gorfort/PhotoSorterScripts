import os
import shutil
import time 
from datetime import datetime
from pathlib import Path
from PIL import Image
from PIL.ExifTags import TAGS

def typing_effect(text, delay=0.02, color=None):
    """Simulate typing effect."""
    for char in text:
        print(char, end='', flush=True)
        time.sleep(delay) 
    print()

def get_folder_path(prompt):
    """Prompt user for a valid folder path."""
    while True:
        typing_effect(prompt, delay=0.04)
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
    first_dest = get_folder_path("Enter the primary destination folder path:")
    destinations.append(first_dest)

    while True:
        typing_effect("Do you want to save the files in an additional folder? (Y/N)", delay=0.02)
        add_another = input().strip().upper()
        if add_another == 'Y':
            next_dest = get_folder_path("Enter the additional destination folder path:")
            destinations.append(next_dest)
        elif add_another == 'N':
            break
        else:
            typing_effect("Invalid input. Please enter Y or N.", color="red")

    return destinations

def remove_empty_folders(folder_path):
    """Remove empty folders without printing messages."""
    for dirpath, dirnames, filenames in os.walk(folder_path, topdown=False):
        for dirname in dirnames:
            dir_to_check = os.path.join(dirpath, dirname)
            try:
                # Tente de supprimer le dossier s'il est vide
                os.rmdir(dir_to_check)
            except OSError:
                pass  # Ignore les erreurs si le dossier n'est pas vide

def organize_photos(source_folder, destination_folders):
    """Organize and copy photos."""
    file_counts = {}
    unique_files_processed = set()

    photos = [f for f in os.scandir(source_folder) if f.is_file()]
    total_files = len(photos)
    processed_files = 0

    start_time = datetime.now()

    for photo in photos:
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
                    "Video": ['.mp4', '.mov', '.crm', '.mxf']
                }

                # Assign to the correct category (ignores "Others" folder)
                file_moved = False
                extension = photo.name.split('.')[-1].lower()
                for category, extensions in subfolders.items():
                    if f".{extension}" in extensions:
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

                # If the file was not moved to any category, it's ignored (not moved to "Others")
                if not file_moved:
                    continue

            unique_files_processed.add(photo.name)

        except Exception as e:
            typing_effect(f"Error processing {photo.name}: {e}", color="red")

    duration = datetime.now() - start_time
    typing_effect(f"Time taken: {duration}", color="magenta")

    # Remove empty folders after processing
    remove_empty_folders(source_folder)
    for destination_folder in destination_folders:
        remove_empty_folders(destination_folder)

    return file_counts

# Main execution
if __name__ == "__main__":
    run_again = 'Y'
    while run_again == 'Y':
        source_folder = get_folder_path("Enter the source folder path:")
        destination_folders = get_destination_folders()
        file_counts = organize_photos(source_folder, destination_folders)

        typing_effect("Processing complete. Files summary:", color="cyan")
        for month, counts in file_counts.items():
            details = ", ".join([f"{key}: {value}" for key, value in counts.items() if value > 0])
            typing_effect(f"{month} - {details}", color="green")

        run_again = ask_run_again()
