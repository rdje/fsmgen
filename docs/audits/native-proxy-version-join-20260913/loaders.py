"""Load pinned data helpers in isolated local module namespaces, never mains."""
import importlib.util
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[3]
UNITS = {
    "layout": "native-proxy-version-contracts-20260913",
    "preparation": "native-proxy-preparation-records-20260913",
    "capture": "native-proxy-capture-dispatch-20260913",
    "retained": "native-proxy-retained-formats-20260913",
}
LOCAL_NAMES = ("prepare", "qualify", "source_contracts", "dispatch", "capture_contract", "retained_contract", "audit", "review")


def load(unit, filename):
    directory = ROOT / "docs/audits" / UNITS[unit]
    original_path = list(sys.path)
    original_modules = {name: sys.modules[name] for name in LOCAL_NAMES if name in sys.modules}
    try:
        for name in LOCAL_NAMES:
            sys.modules.pop(name, None)
        sys.path.insert(0, str(directory))
        specification = importlib.util.spec_from_file_location("version_join_" + unit + "_" + Path(filename).stem, directory / filename)
        module = importlib.util.module_from_spec(specification)
        specification.loader.exec_module(module)
        return module
    finally:
        sys.path[:] = original_path
        for name in LOCAL_NAMES:
            sys.modules.pop(name, None)
        sys.modules.update(original_modules)
