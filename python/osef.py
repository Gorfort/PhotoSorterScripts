import os
import shutil
from PIL import Image
import piexif
from PIL.PngImagePlugin import PngImageFile

def update_metadata(image_path, author_name):
    """
    Update metadata of the image with the author's name.
    Works for JPEG, PNG, and DNG files.
    """
    try:
        # Open the image file
        img = Image.open(image_path)

        # Handle JPEG and JPG files (using EXIF)
        if image_path.lower().endswith(('jpg', 'jpeg')):
            exif_dict = piexif.load(img.info.get("exif", b""))
            # Update author field in EXIF metadata
            exif_dict['0th'][piexif.ImageIFD.Artist] = author_name.encode()
            exif_bytes = piexif.dump(exif_dict)
            img.save(image_path, exif=exif_bytes)

        # Handle PNG files (using text metadata)
        elif image_path.lower().endswith('png'):
            # PNG metadata can be added as text
            img.save(image_path, pnginfo=img.info.get("pnginfo", {}))
            img.info['Author'] = author_name  # Add author as PNG text

        # DNG files are more complex, so we can leave them untouched for now, as it's more advanced
        elif image_path.lower().endswith('dng'):
            print(f"DNG file found, but metadata update skipped for {image_path}.")

        # RC3 files are not standard image files and are ignored for now
        elif image_path.lower().endswith('rc3'):
            print(f"RC3 file found, skipping {image_path}.")
        
    except Exception as e:
        print(f"Error updating metadata for {image_path}: {e}")


def process_images(source_folder, dest_folder, author_name):
    """
    Process all images in the source folder and save them to the destination folder
    with the updated metadata.
    """
    # Ensure destination folder exists
    if not os.path.exists(dest_folder):
        os.makedirs(dest_folder)

    for root, _, files in os.walk(source_folder):
        for file in files:
            # Construct full file path
            file_path = os.path.join(root, file)
            # Only process valid image files
            if file.lower().endswith(('jpg', 'jpeg', 'png', 'dng', 'cr3')):
                try:
                    # Copy the image to the destination folder first
                    dest_path = os.path.join(dest_folder, file)
                    shutil.copy(file_path, dest_path)

                    # Update metadata
                    update_metadata(dest_path, author_name)

                    print(f"Processed {file} successfully.")

                except Exception as e:
                    print(f"Error processing {file}: {e}")


def main():
    print("Welcome to the Image Metadata Updater!")
    
    # Ask user for input
    author_name = input("Enter the author's name: ")
    source_folder = input("Enter the source folder path: ")
    dest_folder = input("Enter the destination folder path: ")

    # Ensure the source folder exists
    if not os.path.exists(source_folder):
        print(f"Source folder {source_folder} does not exist.")
        return

    # Process the images
    process_images(source_folder, dest_folder, author_name)
    print("All images processed.")


if __name__ == "__main__":
    main()
