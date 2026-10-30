"""Retain bounded native producer observations with calibrated call hooks."""
import gzip
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
BASE = 'docs/audits/concat-guard-capture-20261030/probe.pl'
OBSERVER = str((HERE/'probe.pl').relative_to(ROOT))


def run(arguments):
    result = subprocess.run(arguments, cwd=ROOT, capture_output=True)
    return dict(command=arguments, status=result.returncode,
                stdout=result.stdout.decode(), stderr=result.stderr.decode())


def normalize(value):
    if isinstance(value, str):
        return re.sub(r'^// Date:.*\n', '// Date: <normalized>\n', value, flags=re.M)
    if isinstance(value, list):
        return [normalize(item) for item in value]
    if isinstance(value, dict):
        return {key: normalize(item) for key, item in value.items()}
    return value


def main():
    baseline = run(['perl','-Iperl',BASE])
    observed = run(['perl','-Iperl',OBSERVER])
    assert baseline['status'] == observed['status'] == 0, (baseline,observed)
    original = json.loads(baseline['stdout'])
    result = json.loads(observed['stdout'])
    assert normalize(original) == normalize(result['native']), 'observer changed complete native products'
    assert result['native_calls']['typed_concat'] == result['native_calls']['definition_reads'] == 0
    assert result['control']['calls']['typed_concat'] == result['control']['calls']['definition_reads'] == 1
    assert result['control']['definition_width'] == 16
    assert len(result['collections']) == sum(len(case['backends']) for case in original['cases'])
    assert any(row['concats'] for row in result['collections'])

    def check_operand(node):
        if node[0] == 'concat':
            for child in node[1:]:
                check_operand(child)
        else:
            assert node[0] == 'signal' and node[1]['actual_module_member'] is True
            assert node[1]['requirements'] is not None

    for row in result['collections']:
        assert row['named_owner_class'] == 'FSM::ExpressionNamer'
        for entry in row['concats']:
            assert entry['source'] == 'ast_factorization'
            assert entry['birth']['kind'] == 'concatenation_sum_candidate'
            check_operand(entry['operands'])
    # Scope the caller census explicitly; arbitrary external API consumers and
    # dynamic client code are outside this observation and are never excluded.
    census = run(['rg','-n','get_signal_definitions|name_ast_expression|name_concatenation_ast|expr_namer','bin','perl'])
    assert census['status'] == 0
    membership = subprocess.check_output(['git','ls-files','--','bin','perl'],cwd=ROOT).decode().splitlines()
    sources = {path: hashlib.sha256((ROOT/path).read_bytes()).hexdigest()
               for path in membership if (ROOT/path).is_file()}
    for path in [BASE,OBSERVER,str(Path(__file__).relative_to(ROOT))]:
        sources[path] = hashlib.sha256((ROOT/path).read_bytes()).hexdigest()
    record = dict(schema_version=1, revision=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT).decode().strip(),
                  source_sha256=sources, baseline=baseline, observed=observed, scoped_caller_census=census,
                  rederive='Actual retained fixed/mutable guard/RHS native producer and ordered collected Core source contracts.',
                  falsify='Both typed hooks observed in an explicit positive control; complete instrumented/uninstrumented products agree except Date banners; static caller census distinguishes string naming from typed publication.',
                  durability='Tracked producer/observer/replay, complete historical observations and source identities; replay after relevant source changes.',
                  conclusion='The selected native concatenation rows come from actual factorizer candidates and Core module operands. Do not require an unconsumed typed-namer definition protocol for these cases.',
                  limits='Finite retained producer only. No claim about arbitrary external API clients, all expression families, generic override execution or full qualification.')
    with gzip.GzipFile(filename=str(HERE/'evidence.json.gz'),mode='wb',mtime=0) as stream:
        stream.write((json.dumps(record,sort_keys=True,indent=2)+'\n').encode())
    print('Bounded native source selection, positive observation controls and complete product preservation pass.')


if __name__ == '__main__':
    main()
