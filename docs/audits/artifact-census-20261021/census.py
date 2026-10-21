"""Repeat the published safe artifact census in a new exclusive dated slot."""
import importlib.util
from pathlib import Path
import subprocess

if not __debug__:
    raise SystemExit('Census assertions must be enabled.')

ROOT = Path(__file__).resolve().parents[3]
BASE = '7e1f42a97e76160408dff4c6bdc825837ee3d5df'
SOURCE = 'docs/audits/artifact-census-20261020/census.py'

# Execute only the installed, authenticated census implementation. Native Git
# bytes are a comparison input; no historical body is compiled or executed.
path = ROOT / SOURCE
assert not path.is_symlink() and path.is_file() and path.stat().st_dev == ROOT.stat().st_dev
assert path.read_bytes() == subprocess.check_output(
    ['git', '--no-replace-objects', 'show', BASE + ':' + SOURCE], cwd=ROOT)
spec = importlib.util.spec_from_file_location('artifact_census_contract', path)
contract = importlib.util.module_from_spec(spec)
spec.loader.exec_module(contract)

# The fixed collector/reviewer/control functions remain byte-exact. Only this
# observation's native boundary, owner, producer identity and output slot differ.
contract.BASE = BASE
contract.OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.89'
contract.SELF = Path(__file__).resolve().relative_to(ROOT).as_posix()
contract.OUTPUT = Path(__file__).with_name('census.json.gz')

if __name__ == '__main__':
    contract.main()
