import os
import urllib.request
import zipfile
import tempfile
import shutil

# Target directories
BASE_DIR = os.path.join("scripts", "app", "data", "databases", "parts")
DIRS = {
    "motors": os.path.join(BASE_DIR, "motors"),
    "nose_cones": os.path.join(BASE_DIR, "nose_cones"),
    "fins": os.path.join(BASE_DIR, "fins"),
    "body_tubes": os.path.join(BASE_DIR, "body_tubes"),
    "raw_xml": os.path.join(BASE_DIR, "raw_xml") # For the unsorted manufacturer XMLs
}

# URLs
MOTOR_DB_URL = "https://github.com/openrocket/motor-database/archive/refs/heads/master.zip"
PARTS_DB_URL = "https://github.com/openrocket/openrocket-database/archive/refs/heads/master.zip"

def setup_directories():
    for d in DIRS.values():
        os.makedirs(d, exist_ok=True)
    print("Created directory structure.")

def download_and_extract(url, target_dir, ext_filter):
    print(f"Downloading from {url}...")
    
    with tempfile.TemporaryDirectory() as tmpdirname:
        zip_path = os.path.join(tmpdirname, "repo.zip")
        urllib.request.urlretrieve(url, zip_path)
        
        print("Extracting files...")
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(tmpdirname)
            
            # Find all files with matching extensions and move them to target_dir
            extracted_count = 0
            for root, _, files in os.walk(tmpdirname):
                for file in files:
                    if file.endswith(ext_filter):
                        src = os.path.join(root, file)
                        dst = os.path.join(target_dir, file)
                        # Handle duplicates by renaming if necessary, but usually files are uniquely named
                        if not os.path.exists(dst):
                            shutil.copy2(src, dst)
                            extracted_count += 1
            print(f"Successfully extracted {extracted_count} files into {target_dir}")

def main():
    setup_directories()
    
    # Download motors (.eng and .rse)
    print("\n--- Processing Motors ---")
    download_and_extract(MOTOR_DB_URL, DIRS["motors"], (".eng", ".rse"))
    
    # Download component databases (.xml)
    # Note: OpenRocket XMLs often group nose cones and body tubes together by manufacturer (e.g. Estes.xml)
    # We will dump them into raw_xml for now. We can write a parser to split them later if needed.
    print("\n--- Processing Parts ---")
    download_and_extract(PARTS_DB_URL, DIRS["raw_xml"], (".xml", ".orc"))
    
    print("\nDownload complete! Data is ready in scripts/app/data/databases/parts/")

if __name__ == "__main__":
    main()
