"""Inherited preload recipe; persisted include/capture paths remain relative."""
import os
import subprocess
from pathlib import Path

base = Path(__file__).parent
env = dict(os.environ)
env['PERL5LIB'] = ':'.join(str(Path(name).resolve()) for name in (
    'perl', 't/lib', str(base / 'red-lib')))
env['PERL5OPT'] = '-MNoFileSourceComparison'
env['FSMGEN_FILE_ORIGIN_AUTHORITY_CLASS'] = 'NoFileSourceComparison'
env['FSMGEN_FILE_ORIGIN_CAPTURE'] = str(base / 'bypass-red')
result = subprocess.run([
    'scripts/run_with_ram_guard.sh', '--', 'prove', '-Iperl', '-It/lib',
    't/2048-isf-file-document-origin-authority.t'], env=env)
raise SystemExit(result.returncode)
