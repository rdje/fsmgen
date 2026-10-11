"""Reconstruct a missing ignored checkpoint from committed Git, then qualify it."""
import json
import sys
from capture import BASE
import checkpoint

expected = json.loads((BASE / 'source-v3.json').read_bytes())
actual = checkpoint.derive(install=not checkpoint.boundary.local(checkpoint.VIEW).exists())
checkpoint.need(actual == expected, 'complete committed checkpoint reconstruction')
sys.argv = [str(BASE / 'checkpoint.py')]
checkpoint.main()
