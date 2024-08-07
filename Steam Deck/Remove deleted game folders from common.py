# The following was written entirely by ChatGPT and should be used with extreme caution. Or reckless abandon. Dealer's choice.
import os
import shutil

def get_steam_library_folders():
    # Path to Steam configuration file
    config_file = os.path.expanduser('~/.steam/steam/steamapps/libraryfolders.vdf')
    if not os.path.isfile(config_file):
        print("Library configuration file not found.")
        return []

    with open(config_file, 'r') as file:
        lines = file.readlines()

    # Extract library folder paths
    paths = []
    for line in lines:
        if '"path"' in line:
            path = line.split('"')[3]
            paths.append(path)

    return paths

def get_installed_games(library_paths):
    installed_game_dirs = set()
    for path in library_paths:
        app_manifest_path = os.path.join(path, 'steamapps')
        if not os.path.isdir(app_manifest_path):
            continue

        common_path = os.path.join(path, 'steamapps', 'common')
        if not os.path.isdir(common_path):
            continue

        for root, _, files in os.walk(app_manifest_path):
            for file in files:
                if file.endswith('.acf'):
                    acf_path = os.path.join(root, file)
                    try:
                        with open(acf_path, 'r', errors='ignore') as f:
                            lines = f.readlines()
                            for line in lines:
                                if 'installdir' in line:
                                    install_dir = line.split('"')[3]
                                    installed_game_dirs.add(install_dir)
                    except Exception as e:
                        print(f"Error reading {acf_path}: {e}")

    return installed_game_dirs

def find_uninstalled_folders(library_paths, installed_game_dirs):
    uninstalled_folders = []
    for path in library_paths:
        common_path = os.path.join(path, 'steamapps', 'common')
        if not os.path.isdir(common_path):
            continue

        for folder in os.listdir(common_path):
            folder_path = os.path.join(common_path, folder)
            if os.path.isdir(folder_path) and folder not in installed_game_dirs:
                uninstalled_folders.append(folder_path)

    return uninstalled_folders

def delete_folders(folders):
    for folder in folders:
        try:
            shutil.rmtree(folder)
            print(f"Deleted folder: {folder}")
        except Exception as e:
            print(f"Error deleting {folder}: {e}")

def main():
    library_paths = get_steam_library_folders()
    if not library_paths:
        print("No Steam library folders found.")
        return

    installed_game_dirs = get_installed_games(library_paths)
    uninstalled_folders = find_uninstalled_folders(library_paths, installed_game_dirs)

    if not uninstalled_folders:
        print("No uninstalled folders found.")
    else:
        print("Uninstalled Steam Game Folders:")
        for folder in uninstalled_folders:
            print(folder)

        # Confirm and delete uninstalled folders
        confirm = input("Do you want to delete these folders? (y/n): ")
        if confirm.lower() == 'y':
            delete_folders(uninstalled_folders)
        else:
            print("No folders were deleted.")

if __name__ == "__main__":
    main()
