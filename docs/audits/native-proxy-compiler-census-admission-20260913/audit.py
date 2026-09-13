"""Repeatable source/data admission review. Never emits or consumes a permit."""
import argparse
import ast
import hashlib
import json
from pathlib import Path

import admission
import qualify_profile
import source_contract

BASE, ROOT, PLAN = admission.BASE, admission.ROOT, admission.PLAN


def pin(path):
    raw=path.read_bytes()
    return dict(path=str(path.relative_to(ROOT)),size_bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest())


def verify():
    pins=json.loads((BASE/'implementation-pins.json').read_bytes())
    for row in PLAN['inputs']+pins:
        assert pin(ROOT/row['path'])==row
    assert PLAN['compiler']['invocations']==2 and PLAN['compiler']['concurrency']==1
    assert PLAN['compiler']['timeout_seconds']==10 and PLAN['compiler']['capture_limit_bytes']==4096
    assert PLAN['workspace_policy']['nodes']==256 and PLAN['workspace_policy']['depth']==8
    assert PLAN['workspace_policy']['file_bytes']==65536 and PLAN['workspace_policy']['total_file_bytes']==4194304
    limits=PLAN['evidence_limits']; d=limits['journal_derivation']
    required=2*(6*limits['total_file_bytes']+limits['nodes']*(6*d['symlink_target_bytes']+
        limits['root_relative_path_bytes']+d['metadata_allowance_per_node']))+d['global_allowance_bytes']
    assert required==d['conservative_required_bytes']<=limits['journal_bytes']==67108864
    source=(ROOT/'t/fixtures/rust-tool-proxy.c').read_bytes()
    for case,flag in zip(PLAN['cases'],[1,0]):
        raw=('#define PROXY_NONZERO '+str(flag)+'\n').encode()+source
        assert case['generated_c']==dict(bytes_hex=raw.hex(),size_bytes=len(raw),sha256=admission.digest(raw))
    wrapper=source_contract.wrapper((ROOT/'t/1669-task-acceptance-fixture-runtime.t').read_bytes())
    assert wrapper==bytes.fromhex(PLAN['wrapper']['bytes_hex']) and PLAN['wrapper']['mode']==0o755
    assert PLAN['wrapper']['sha256']==admission.digest(wrapper) and PLAN['wrapper']['size_bytes']==len(wrapper)
    assert PLAN['cargo_role']['relative_target']=='rustup'
    for path in BASE.glob('*.py'):ast.parse(path.read_bytes(),filename=str(path.relative_to(ROOT)))
    qualification=json.loads((BASE/'qualification.json').read_bytes())
    for stage,result in qualification['outputs'].items():
        assert result['exit']=='0\n',stage
    assert json.loads(qualification['outputs']['profile-final']['stdout'])==qualify_profile.qualify()
    tap=qualification['outputs']['compiler-final']['stdout']
    assert tap.endswith('1..29\n') and '\nnot ok ' not in '\n'+tap
    assert 'compile_profile.pl syntax OK' in qualification['outputs']['runner-final']['stderr']
    for row in qualification['sources']:assert pin(ROOT/row['path'])==row
    first=json.loads((BASE/'profile-model-first.json').read_bytes())
    assert first['outcome']['exit']=='0\n'
    for row in first['sources']:
        raw=bytes.fromhex(row['bytes_hex'])
        assert len(raw)==row['size_bytes'] and admission.digest(raw)==row['sha256']
    assert not (ROOT/PLAN['output']).exists()
    assert all(not (ROOT/c['workspace']).exists() for c in PLAN['cases'])
    # This check applies to the pre-execution admission epoch. After sole
    # execution use its saved source epoch and execution evidence, not a replay.
    result=qualify_profile.qualify()
    return dict(source_inputs=len(PLAN['inputs']),implementation_inputs=len(pins),
        compiler_model_checks=29,profile_rejected_controls=len(result['rejected_controls']),
        wrapper_source_rejected_controls=len(result['wrapper_source']['rejected_controls']),
        source_admission_only=True,compiler_invocations=0,fixture_allocations=0,
        current_epoch_revalidation_required=True,authentic_profiles_pending=True)


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--verify-saved',required=True,action='store_true')
    parser.parse_args()
    print(json.dumps(verify(),sort_keys=True))
