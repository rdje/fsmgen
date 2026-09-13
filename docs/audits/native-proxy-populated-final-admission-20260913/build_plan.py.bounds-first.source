"""Build reviewable inactive admission data; never issue or execute a permit."""
import json

from contract import BASE, SCOPE, OWNER, EXECUTION_OWNER, OUTPUT, bounds, cases, roots, worker_sources, driver_sources
from review_run import expected_files


def build():
    installed = json.loads((BASE / 'installed-first.json').read_bytes())['result']
    modules = json.loads((BASE / 'compile-inventory-first.json').read_bytes())['inventory']['installed_modules']
    git = json.loads((BASE / 'git-first.json').read_bytes())['result']
    return dict(schema='fsmgen.inactive_populated_final_admission_plan.v1', owner=OWNER, execution_owner=EXECUTION_OWNER,
        selected_prior_revision=SCOPE['source_revision'], output=OUTPUT, cases=cases(), roots=roots(), bounds=bounds(),
        worker_sources=worker_sources(), driver_sources=driver_sources(), toolchains=installed['toolchains'],
        git_launcher=git['selected'], installed_modules=modules, uname=installed['uname'],
        expected_run_files=sorted(expected_files()), expected_reviewed_files=sorted(expected_files(True)),
        execution_authorized=False, reusable=False, compiler_execution=False, proxy_execution=False, live_collector_execution=False,
        source_qualification_required=True, synthetic_retirement_and_work_records=True,
        locality_exception=installed['locality_exception'], complete_native_dependency_closure=False,
        git_policy=dict(executable='/usr/bin/git', configuration={'core.excludesFile': '.gitignore'},
            closed_environment=dict(PATH='/usr/bin:/bin', LC_ALL='C', LANG='C', TMPDIR_root_relative='.artifacts/tmp')))


if __name__ == '__main__':
    with (BASE / 'plan.json').open('x') as stream:
        json.dump(build(), stream, sort_keys=True, indent=2)
        stream.write('\n')
