"""Exercise original prerequisite imports before resolving the owned publisher."""
from pathlib import Path
import runpy

from capture import BASE

# Reproduce the final-reader import order without rerunning original native readers.
runpy.run_path(str(BASE / 'verify.py'))
import publish
import verify

if Path(verify.__file__).resolve() != (BASE / 'verify.py').resolve():
    raise ValueError('publisher imported a foreign verifier')
if publish.gate is not verify.gate or publish.TASK != verify.TASK:
    raise ValueError('publisher did not bind the complete owned verifier interface')
print('PASS actual original prerequisite imports resolve the owned publisher/verifier interface.')
