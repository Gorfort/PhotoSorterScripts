import subprocess
import sys
import os
import shutil
import time

# Function to install missing packages
def install_package(package):
    subprocess.check_call([sys.executable, "-m", "pip", "install", package])

# Try importing tqdm, and install it if not found
try:
    from tqdm import tqdm
except ImportError:
    print("tqdm module not found. Installing it now...")
    install_package('tqdm')
    from tqdm import tqdm

# Function to simulate typing effect with color
def write_typing(text, delay=0.05, color="white"):
    """Simulate typing effect with color."""
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
    if color in color_codes:
        text = color_codes[color] + text + color_codes["reset"]

    for char in text:
        print(char, end="", flush=True)
        time.sleep(delay)
    print()

# Function to prompt the user for a valid folder path
def get_folder_path(prompt):
    """Prompt the user for a valid folder path."""
    while True:
        write_typing(prompt, delay=0.04, color="yellow")
        folder_path = input()
        if os.path.isdir(folder_path):
            return folder_path
        else:
            write_typing("Invalid folder path. Please try again.", delay=0.04, color="red")

# Function to ask the user if they want to run the script again
def ask_run_again():
    """Ask the user if they want to run the script again."""
    while True:
        write_typing("Do you want to run the script again? (Y/N)", delay=0.04, color="yellow")
        choice = input().strip().upper()
        if choice in ['Y', 'N']:
            return choice
        else:
            write_typing("Invalid choice. Please enter Y or N.", delay=0.04, color="red")

def main():
    """Main function to gather files from source and move them to destination."""
    while True:
        try:
            write_typing("Welcome to the Files Gatherer !", delay=0.04, color="green")
            
            # Get source and destination folders
            source_folder = get_folder_path("Enter the source folder path:")
            destination_folder = get_folder_path("Enter the destination folder path:")

            # Get all files from source folder (including subdirectories)
            files = []
            for root, dirs, filenames in os.walk(source_folder):
                for filename in filenames:
                    files.append(os.path.join(root, filename))

            total_files = len(files)
            processed_files = 0
            unique_source_folders = set()

            # Record start time
            start_time = time.time()

            # Iterate over all files
            for file in tqdm(files, desc="Copying files", unit="file"):
                try:
                    # Define the destination path
                    destination_path = os.path.join(destination_folder, os.path.basename(file))

                    # Copy file if it doesn't exist in the destination
                    if not os.path.exists(destination_path):
                        shutil.copy(file, destination_path)
                        processed_files += 1
                        unique_source_folders.add(os.path.dirname(file))
                    else:
                        write_typing(f"File {os.path.basename(file)} already exists in the destination. Skipping.", delay=0.04, color="yellow")
                except Exception as e:
                    write_typing(f"Error processing {os.path.basename(file)}: {str(e)}", delay=0.04, color="red")

            # Record end time and calculate duration
            end_time = time.time()
            duration = end_time - start_time
            hours, remainder = divmod(duration, 3600)
            minutes, seconds = divmod(remainder, 60)

            # Final message
            write_typing(f"All files have been copied successfully.", delay=0.04, color="green")
            write_typing(f"{processed_files} files have been moved from {len(unique_source_folders)} folder(s).", delay=0.04, color="cyan")
            write_typing(f"Time taken: {int(hours)}h {int(minutes)}m {int(seconds)}s", delay=0.04, color="magenta")

            # Ask if the user wants to run again
            if ask_run_again() == 'N':
                write_typing("Goodbye!", delay=0.04, color="green")
                break
        
        except KeyboardInterrupt:
            write_typing("\nScript interrupted by user. Goodbye!", color="red")
            break

if __name__ == "__main__":
    main()
