import os
import shutil
import subprocess
import sys
import ensurepip
import piexif
from PIL import Image

def ensure_pip_installed():
    """Ensure that pip is installed on the system."""
    try:
        subprocess.check_call([sys.executable, "-m", "pip", "--version"])
    except FileNotFoundError:
        print("pip not found. Installing pip...")
        try:
            ensurepip.bootstrap()
            subprocess.check_call([sys.executable, "-m", "pip", "install", "--upgrade", "pip"])
        except Exception as e:
            print(f"Failed to install pip: {e}")
            sys.exit(1)

def install_package(package_name):
    """Install a package using pip."""
    try:
        subprocess.check_call([sys.executable, "-m", "pip", "install", package_name])
    except subprocess.CalledProcessError as e:
        print(f"Error installing package {package_name}: {e}")
        sys.exit(1)

def add_metadata(file_path, destination_path, author_name):
    """Add Author name to EXIF and preserve IPTC metadata."""
    try:
        img = Image.open(file_path)
        edited_file_path = os.path.join(destination_path, os.path.basename(file_path))
        
        # Load the original EXIF data
        exif_data = img.info.get("exif")
        
        # Load existing EXIF data using piexif
        exif_dict = piexif.load(exif_data or b"")
        
        # Add Author Name to EXIF (ImageIFD.Artist)
        exif_dict["0th"][piexif.ImageIFD.Artist] = author_name.encode("utf-8")
        
        # Reapply the EXIF data to the image
        exif_bytes = piexif.dump(exif_dict)

        # Save the image with the EXIF data, but avoid JFIF creation (do not use JFIF-compliant encoding)
        img.save(edited_file_path, "JPEG", exif=exif_bytes, quality=95, optimize=True)

        print(f"Processed and saved with metadata: {edited_file_path}")
    except Exception as e:
        print(f"Error processing file {file_path}: {e}")

def main():
    # Ensure pip is installed
    ensure_pip_installed()

    # Install Pillow and piexif if not already installed
    print("Checking and installing required packages...")
    install_package("pillow")
    install_package("piexif")
    
    # Ask user for source path
    source_path = input("Enter the source folder path: ").strip()
    
    # Ask user for destination path
    destination_path = input("Enter the destination folder path: ").strip()
    
    # Check if source path exists
    if not os.path.exists(source_path):
        print("Error: Source path does not exist. Exiting program.")
        return
    
    # Create destination folder if it does not exist
    if not os.path.exists(destination_path):
        os.makedirs(destination_path)
    
    # Ask user for the author's name
    author_name = input("Enter the author's name: ").strip()

    # Process images in the source path
    for file_name in os.listdir(source_path):
        file_path = os.path.join(source_path, file_name)
        
        # Check if it's an image file (jpg/jpeg)
        if file_name.lower().endswith(('.jpg', '.jpeg')):
            add_metadata(file_path, destination_path, author_name)
        else:
            # Copy non-image files directly to the destination folder
            shutil.copy(file_path, destination_path)
            print(f"Copied: {file_path} to {destination_path}")

    print("All files processed successfully!")

if __name__ == "__main__":
    main()
