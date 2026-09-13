"""Load only original pure readers with their exact isolated dependencies."""
from pathlib import Path
import importlib.util
import sys

sys.dont_write_bytecode = True
BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
A = ROOT/'docs/audits/native-proxy-lifetime-files-admission-20260913'


def load(name, path):
    spec=importlib.util.spec_from_file_location(name,path)
    module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module);return module


SUPPORT=load('controls_original_support',A/'support.py')
missing=object();previous={name:sys.modules.get(name,missing) for name in ('support','oracle')}
try:
    sys.modules['support']=SUPPORT
    ORACLE=load('controls_original_oracle',A/'oracle.py');sys.modules['oracle']=ORACLE
    CONSUME=load('controls_original_consume',A/'consume.py')
finally:
    for name,value in previous.items():
        if value is missing:sys.modules.pop(name,None)
        else:sys.modules[name]=value
MODEL=SUPPORT.OLD_MODEL
COMMON=SUPPORT.OLD_COMMON
canonical=SUPPORT.canonical
digest=SUPPORT.digest
stable=ORACLE.stable
