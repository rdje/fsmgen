"""Read the required selected Git launcher; issue no command or run authority."""
import json

from contract import ROOT
from installed_inputs import read_pin


def main():
    source = 'docs/audits/native-proxy-compiler-census-policy-admission-20260913/plan.json'
    prior = json.loads((ROOT / source).read_bytes())['git_policy']['pin']
    selected = dict(size_bytes=prior['identity']['size_bytes'], sha256=prior['sha256'])
    observed = read_pin('/usr/bin/git', selected)
    print(json.dumps(dict(schema='fsmgen.inactive_populated_selected_git_input.v1', selected=selected, observed=observed,
        prior_selected_source=source, actual_worker_execution=False, actual_fixture_allocation=False,
        locality_exception='Required installed read-only Git launcher; no project data is written outside the repository volume.',
        complete_loaded_git_dependency_closure=False), sort_keys=True, indent=2))


if __name__ == '__main__':
    main()
