"""Read applicable source/data legs of the now-historical prospective admissions.

The original prospective full auditors require an absent execution journal.
Their immutable reports are authenticated by the closure. Here only their
source/first-epoch and data helpers run; no original producer main runs.
"""
import argparse
import importlib.util
import json
from pathlib import Path
import sys

BASE=Path(__file__).resolve().parent
ROOT=BASE.parents[2]
FINAL=ROOT/'docs/audits/native-proxy-lifetime-controls-final-admission-20260913'
sys.path.insert(0,str(FINAL))
from support_final_corrected import H,read
import audit_integration_corrected
import qualify_permit


def verify():
    spec=importlib.util.spec_from_file_location('lifetime_harness_source_parts',H/'audit.py')
    harness=importlib.util.module_from_spec(spec);spec.loader.exec_module(harness)
    saved=read(H/'harness-review.json')
    sources=harness.source_join();epochs=harness.retained_epochs()
    assert sources==saved['source_join'] and epochs==saved['original_epochs']
    data=harness.audit_data.verify();assert data==read(H/'data-review.json')
    integration=audit_integration_corrected.verify();assert integration==read(FINAL/'integration-review.json')
    permit=qualify_permit.verify();assert permit==read(FINAL/'permit-review.json')
    return dict(schema='fsmgen.lifetime_admission_source_data_reverification.v1',source_join=sources,
        original_epochs=epochs,control_data_cases=len(data['cases']),corrected_perl_checks=data['corrected_perl_checks'],
        harness_reader_countermodels=len(data['rejected_countermodels']),
        retained_healthy_stages=integration['retained_healthy_stages'],
        integration_countermodels=len(integration['rejected_countermodels']),permit_countermodels=len(permit['rejected_states']),
        actual_fixture_operations=0,actual_permits_written=0,prospective_report_states_preserved_as_original_epochs=True)


def main():
    parser=argparse.ArgumentParser();group=parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--retain',action='store_true');group.add_argument('--verify-saved',action='store_true');args=parser.parse_args()
    value=verify()
    if args.retain:
        with (BASE/'admission-review.json').open('x') as stream:json.dump(value,stream,sort_keys=True,indent=2);stream.write('\n')
    else:assert read(BASE/'admission-review.json')==value
    print('Historical admission source/data legs: OK; no producer or permit execution.')


if __name__=='__main__':main()
