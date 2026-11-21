import os
from pathlib import Path

from android.storage import app_storage_path

# SDL extracts the game code and mods together. Keep saves outside that tree.
os.chdir(Path(__file__).resolve().parent)
os.environ["HOME"] = app_storage_path()
from run_tuxemon import launch_game

launch_game([])
