import getpass
import os
import shutil
import subprocess
import sys
import time
from datetime import datetime

from PIL import Image
from PIL.ExifTags import TAGS


def write_typing_colored(text, delay=50, color="White", newline=True):
    color_codes = {
        "Black": "\033[30m",
        "DarkGray": "\033[90m",
        "Red": "\033[31m",
        "Green": "\033[32m",
        "Yellow": "\033[33m",
        "Blue": "\033[34m",
        "Magenta": "\033[35m",
        "Cyan": "\033[36m",
        "White": "\033[37m",
        "Reset": "\033[0m",
    }

    prefix = color_codes.get(color, color_codes["White"])
    suffix = color_codes["Reset"]

    print(prefix, end="")
    for char in text:
        print(char, end="", flush=True)
        time.sleep(delay / 1000)
    print(suffix, end="")
    if newline:
        print()


def write_typing(text, delay=20, color="White", newline=True):
    write_typing_colored(text, delay=delay, color=color, newline=newline)


def write_counting(target, delay=5):
    step = max((target + 99) // 100, 1)

    for value in range(0, target + 1, step):
        if value > target:
            value = target
        print(f"\r{value}   ", end="", flush=True)
        time.sleep(delay / 1000)

    print(f"{target}", flush=True)


def install_packages():
    required_packages = ["Pillow"]
    try:
        write_typing("Updating packages...", delay=40, color="Blue")

        for package in required_packages:
            subprocess.check_call(
                [sys.executable, "-m", "pip", "install", package],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )

        print("\r" + " " * 20 + "\r", end="", flush=True)
    except Exception as exc:
        print(f"\nFailed to install packages: {exc}")
        sys.exit(1)


def get_folder_path(prompt):
    while True:
        write_typing(prompt, delay=40, color="Yellow")
        folder_path = input().strip()

        if folder_path and os.path.isdir(folder_path):
            return folder_path

        write_typing("Invalid input. Please enter a valid folder path.", delay=20, color="Red")


def ask_run_again():
    while True:
        write_typing_colored("Do you want to run the script again? ", delay=20, color="Yellow", newline=False)
        write_typing_colored("(Y/N)", delay=20, color="DarkGray")

        choice = input().strip().upper()
        if choice in {"Y", "N"}:
            if choice == "N":
                write_typing_colored("Goodbye!", delay=20, color="Blue")
                print()
            return choice

        write_typing("Invalid choice. Please enter Y or N.", delay=20, color="Red")


def get_destination_folders():
    destinations = []
    first_destination = get_folder_path("Enter the destination folder path")
    destinations.append(first_destination)

    while True:
        write_typing_colored(
            "Do you want to save the files in an additional folder? ",
            delay=20,
            color="Yellow",
            newline=False,
        )
        write_typing_colored("(Y/N)", delay=20, color="DarkGray")

        add_another = input().strip().upper()
        if add_another == "Y":
            next_destination = get_folder_path("Enter the additional destination folder path")
            destinations.append(next_destination)
        elif add_another == "N":
            break
        else:
            write_typing("Invalid input. Please enter Y or N.", delay=20, color="Red")

    return destinations


def get_date_taken(file_path):
    try:
        image = Image.open(file_path)
        try:
            exif_data = image.getexif()
            if exif_data:
                for tag, value in exif_data.items():
                    if TAGS.get(tag, tag) == "DateTimeOriginal":
                        return datetime.strptime(value, "%Y:%m:%d %H:%M:%S")
        finally:
            image.close()
    except Exception:
        pass

    return datetime.fromtimestamp(os.path.getmtime(file_path))


def remove_empty_folders(folder_path):
    for dirpath, dirnames, filenames in os.walk(folder_path, topdown=False):
        for dirname in dirnames:
            dir_to_check = os.path.join(dirpath, dirname)
            try:
                os.rmdir(dir_to_check)
            except OSError:
                pass


def organize_files(source_folder, destination_folders, folder_name):
    file_counts = {}
    unique_files_processed = set()

    photos = [entry for entry in os.scandir(source_folder) if entry.is_file()]
    total_files = len(photos)
    processed_files = 0

    start_time = datetime.now()
    previous_time = start_time

    for photo in photos:
        try:
            if photo.name in unique_files_processed:
                continue

            date_taken = get_date_taken(photo.path)
            current_month = date_taken.strftime("%B")
            current_year = date_taken.strftime("%Y")
            month_key = f"{current_month} {current_year}"
            file_type = None

            extension = os.path.splitext(photo.name)[1].lower()
            if extension in {".cr3", ".raw", ".dng"}:
                file_type = "RAW"
            elif extension in {".jpeg", ".jpg"}:
                file_type = "JPEG"
            elif extension in {".mp4", ".mov", ".crm", ".mxf"}:
                file_type = "Video"
            elif extension == ".png":
                file_type = "PNG"
            else:
                file_type = "Others"

            for destination_folder in destination_folders:
                if not os.path.isdir(destination_folder):
                    os.makedirs(destination_folder, exist_ok=True)

                year_folder = os.path.join(destination_folder, current_year)
                if not os.path.isdir(year_folder):
                    os.makedirs(year_folder, exist_ok=True)

                month_folder = os.path.join(year_folder, month_key)
                if not os.path.isdir(month_folder):
                    os.makedirs(month_folder, exist_ok=True)

                user_folder = os.path.join(month_folder, folder_name)
                if not os.path.isdir(user_folder):
                    os.makedirs(user_folder, exist_ok=True)

                raw_folder = os.path.join(user_folder, "RAW")
                png_folder = os.path.join(user_folder, "PNG")
                jpeg_folder = os.path.join(user_folder, "JPEG")
                video_folder = os.path.join(user_folder, "Video")
                others_folder = os.path.join(user_folder, "Others")

                os.makedirs(raw_folder, exist_ok=True)
                os.makedirs(png_folder, exist_ok=True)
                os.makedirs(jpeg_folder, exist_ok=True)
                os.makedirs(video_folder, exist_ok=True)
                os.makedirs(others_folder, exist_ok=True)

                if file_type == "RAW":
                    destination_path = os.path.join(raw_folder, photo.name)
                elif file_type == "JPEG":
                    destination_path = os.path.join(jpeg_folder, photo.name)
                elif file_type == "Video":
                    destination_path = os.path.join(video_folder, photo.name)
                elif file_type == "PNG":
                    destination_path = os.path.join(png_folder, photo.name)
                else:
                    destination_path = os.path.join(others_folder, photo.name)

                if not os.path.exists(destination_path):
                    shutil.copy2(photo.path, destination_path)
                    processed_files += 1

            if month_key not in file_counts:
                file_counts[month_key] = {
                    "RAW": 0,
                    "JPEG": 0,
                    "PNG": 0,
                    "Video": 0,
                    "Others": 0,
                }
            file_counts[month_key][file_type] += 1

            unique_files_processed.add(photo.name)

            current_time = datetime.now()
            time_elapsed = current_time - previous_time
            previous_time = current_time

            if processed_files > 0:
                average_time_per_file = (current_time - start_time).total_seconds() / processed_files
                remaining_files = total_files - processed_files
                estimated_remaining_time = remaining_files * average_time_per_file
                estimated_remaining_time_formatted = time.strftime(
                    "%H:%M:%S",
                    time.gmtime(max(estimated_remaining_time, 0)),
                )
            else:
                estimated_remaining_time_formatted = "Calculating..."

            percent_complete = 0 if total_files == 0 else int((processed_files / total_files) * 100)
            print(
                f"\rCopying Files - {processed_files}/{total_files} files copied - "
                f"{percent_complete}% complete. Estimated Time Remaining: {estimated_remaining_time_formatted}    ",
                end="",
                flush=True,
            )
        except Exception as exc:
            print(f"\nError processing {photo.name}: {exc}")

    print()
    print()
    write_typing_colored("Processing complete. Files summary:", delay=20, color="Cyan")
    print()

    grouped_by_year = {}
    for month_key in file_counts:
        month_date = datetime.strptime(month_key, "%B %Y")
        year = month_date.year
        grouped_by_year.setdefault(year, {})[month_key] = file_counts[month_key]

    for year in sorted(grouped_by_year):
        write_typing_colored(f"Year {year}:", delay=20, color="Cyan")
        print()

        sorted_months = sorted(
            grouped_by_year[year].keys(),
            key=lambda month_key: datetime.strptime(month_key, "%B %Y"),
        )

        for month_key in sorted_months:
            counts = grouped_by_year[year][month_key]
            write_typing_colored(f"  {month_key} :", delay=20, color="Green")
            print()

            for file_type in [key for key, value in counts.items() if value > 0]:
                print(f"    {file_type} files: ", end="", flush=True)
                write_counting(counts[file_type], delay=5)

            print()

    end_time = datetime.now()
    duration = end_time - start_time

    write_typing_colored("Time taken: ", delay=20, color="Magenta")
    write_typing_colored(
        f"{duration.seconds // 3600}h {(duration.seconds // 60) % 60}m {duration.seconds % 60}s",
        delay=20,
        color="White",
    )
    print()

    write_typing_colored("Total files: ", delay=20, color="Magenta")
    write_counting(total_files, delay=5)

    total_size_bytes = sum(entry.stat().st_size for entry in photos)
    total_size_gb = round(total_size_bytes / (1024 ** 3), 2)

    write_typing_colored("Total size transferred: ", delay=20, color="Magenta")
    write_typing_colored(f"{total_size_gb} GB", delay=20, color="White")
    print()

    for destination_folder in destination_folders:
        if not os.path.isdir(destination_folder):
            continue

        year_folders = [
            os.path.join(destination_folder, name)
            for name in os.listdir(destination_folder)
            if os.path.isdir(os.path.join(destination_folder, name))
        ]

        for year_folder in year_folders:
            month_folders = [
                os.path.join(year_folder, name)
                for name in os.listdir(year_folder)
                if os.path.isdir(os.path.join(year_folder, name))
            ]

            for month_folder in month_folders:
                user_folder_path = os.path.join(month_folder, folder_name)
                if os.path.isdir(user_folder_path):
                    for subfolder in ["RAW", "JPEG", "Video", "Others", "PNG"]:
                        subfolder_path = os.path.join(user_folder_path, subfolder)
                        if os.path.isdir(subfolder_path):
                            has_files = False
                            for _, _, filenames in os.walk(subfolder_path):
                                if filenames:
                                    has_files = True
                                    break

                            if not has_files:
                                shutil.rmtree(subfolder_path, ignore_errors=True)

    return file_counts


def main():
    install_packages()
    write_typing("Welcome to the Files Sorter", delay=20, color="Cyan")

    folder_name = os.getenv("USERNAME") or os.getenv("USER") or getpass.getuser()
    run_again_choice = "Y"

    while run_again_choice == "Y":
        source_folder = get_folder_path("Enter the source folder path")
        destination_folders = get_destination_folders()
        organize_files(source_folder, destination_folders, folder_name)
        run_again_choice = ask_run_again()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        write_typing("\nScript interrupted by user. Goodbye!", delay=20, color="Red")