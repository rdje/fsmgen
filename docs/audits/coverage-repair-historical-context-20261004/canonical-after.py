import subprocess
subprocess.run([
    'python3', '-B', 'docs/audits/coverage-repair-historical-context-20261004/run_context.py',
    '--binding', 'docs/audits/coverage-repair-historical-context-20261004/binding.json',
    '--output', '.artifacts/coverage-repair-canonical-reverify-20261004',
], check=True)
subprocess.run([
    'python3', '-B', 'docs/audits/reservation-coverage-historical-context-20261003/run_context.py',
    '--binding', 'docs/audits/reservation-coverage-historical-context-20261003/bindings.json',
    '--output', '.artifacts/reservation-coverage-copy-repair-reverify-20261003',
], check=True)
print('PASS exact repaired coverage proof and original full cause/copy qualification replay at separate pinned revisions; later hot-source changes require their own validation; sealed evidence preserved.')
