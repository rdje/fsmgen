#!/usr/bin/env python3
"""Compatibility command; the original producer remains in the .3 Git boundary."""
import os
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[3]
os.execv(sys.executable, [sys.executable, '-B', str(root / 'scripts/check_pod_api_examples.py'), *sys.argv[1:]])
