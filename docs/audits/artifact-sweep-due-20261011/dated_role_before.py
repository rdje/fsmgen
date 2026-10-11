"""Reproduce the original saved/current documentation conflation."""
import importlib.util
import sys
from importlib.machinery import SourceFileLoader
sys.path.insert(0, 'docs/audits/artifact-sweep-due-20261011')
loader = SourceFileLoader('original_cleanup_reader', 'docs/audits/artifact-sweep-due-20261011/verify-before-dated-role.py.txt')
spec = importlib.util.spec_from_loader(loader.name, loader)
module = importlib.util.module_from_spec(spec)
loader.exec_module(module)
module.publication()
