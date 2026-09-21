"""Build the collection using the user's original wrapper design."""
import runpy
from pathlib import Path

runpy.run_path(str(Path(__file__).with_name("restore_original_wrappers.py")), run_name="__main__")
