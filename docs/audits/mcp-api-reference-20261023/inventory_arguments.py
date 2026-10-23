#!/usr/bin/env python3
"""Capture typed argument admission through the actual API and persistent pipe."""
import gzip
import hashlib
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[3]
assert Path.cwd().resolve() == ROOT
sys.path.insert(0, str(ROOT / 'scripts'))
sys.path.insert(0, str(ROOT / 't/python'))
from generate_pod_reference import local_path
from test_fixture_mcp_stdio import Session

VIAL = 'vial/ahb_subordinate_base_output_arbitration_lifecycle_v2.vial'
CODE = 'FSMGEN_COMPOSITION_CHILD_ITEM_LIST_SHAPE'
BASE = {
    'fsmgen_capability_query': {'section': 'semantic_introspection'},
    'fsmgen_discover_sources': {'query': 'axi', 'limit': 1},
    'fsmgen_find_examples': {'query': 'axi', 'limit': 1},
    'fsmgen_explain_diagnostic': {'code': CODE, 'limit_examples': 1},
    'fsmgen_support_summary': {'limit_examples': 1},
    'fsmgen_check': {'source_id': VIAL, 'language_version': 2},
    'fsmgen_semantic_introspect': {'source_id': VIAL, 'language_version': 2},
    'fsmgen_vial_inspect': {'source_id': VIAL, 'language_version': 2},
    'fsmgen_schedule_preview': {'source_id': 'ppif/axi_aw_valid_ready.ppif'},
}
SCALARS = [('null', None), ('false', False), ('true', True), ('zero', 0), ('one', 1),
           ('fraction', 1.5), ('array', []), ('object', {}), ('empty_string', ''),
           ('numeric_string', '1'), ('unicode_string', 'é')]
NUMERIC = [('integral_decimal', '1.0'), ('integral_exponent', '1e0'),
           ('large_integer', '1e30'), ('negative_integer', '-1')]


def cases_for(tools):
    assert set(BASE) == {t['name'] for t in tools}
    rows = []

    def add(name, label, params, literal=None, omit_params=False):
        request = {'jsonrpc': '2.0', 'id': len(rows) + 2, 'method': 'tools/call'}
        if not omit_params:
            request['params'] = params
        raw = json.dumps(request, ensure_ascii=False)
        if literal is not None:
            assert raw.count('"__FSMGEN_AUDIT_NUMBER__"') == 1
            raw = raw.replace('"__FSMGEN_AUDIT_NUMBER__"', literal)
        rows.append({'tool': name, 'label': name + ':' + label, 'request_utf8': raw})

    for tool in tools:
        name = tool['name']
        base = BASE[name]
        add(name, 'valid_base', {'name': name, 'arguments': base})
        add(name, 'arguments_omitted', {'name': name})
        add(name, 'unknown_field', {'name': name, 'arguments': dict(base, unpublished_argument=True)})
        for label, value in SCALARS:
            add(name, 'root_' + label, {'name': name, 'arguments': value})
        for label, value in SCALARS:
            add(name, 'name_' + label, {'name': value, 'arguments': {}})
        for field, definition in tool['inputSchema']['properties'].items():
            for label, value in SCALARS:
                arguments = dict(base, **{field: value})
                add(name, field + ':' + label, {'name': name, 'arguments': arguments})
            if definition['type'] == 'integer':
                for label, literal in NUMERIC:
                    arguments = dict(base, **{field: '__FSMGEN_AUDIT_NUMBER__'})
                    add(name, field + ':' + label, {'name': name, 'arguments': arguments}, literal)
            if 'enum' in definition:
                for value in definition['enum']:
                    add(name, field + ':enum_' + str(value), {'name': name, 'arguments': dict(base, **{field: value})})
                # A numeric string spelling of the valid VIAL version isolates
                # type admission from the selected source's version semantics.
                if definition['type'] == 'integer':
                    add(name, field + ':version_string', {'name': name, 'arguments': dict(base, **{field: '2'})})
        add(name, 'params_omitted', None, omit_params=True)
        for label, value in SCALARS:
            add(name, 'params_' + label, value)
    return rows


def main():
    output = local_path(ROOT, sys.argv[1])
    assert output.suffix == '.gz' and not output.exists()
    assert not (ROOT / '0').exists() and not (ROOT / '1').exists()
    work = local_path(ROOT, '.artifacts/mcp-api-reference')
    inputs = work / 'argument-cases.json'
    api_output = work / 'argument-api.json'
    api_errors = work / 'argument-api.stderr'
    assert not any(p.exists() for p in (inputs, api_output, api_errors))
    native = [p for p in subprocess.check_output(['git', 'ls-files', '-z', 'perl/FSM']).decode().split('\0') if p.endswith('.pm')]
    selected = native + ['bin/fsmgen-mcp', 't/python/test_fixture_mcp_stdio.py',
                         'scripts/generate_pod_reference.py',
                         'docs/audits/mcp-api-reference-20261023/inventory_arguments.py',
                         'docs/audits/mcp-api-reference-20261023/probe_argument_api.pl']
    identities = {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in selected}
    head = subprocess.check_output(['git', 'rev-parse', 'HEAD']).decode().strip()
    record = {'head': head, 'source_sha256': identities,
              'observer_sources': {p: (ROOT / p).read_text() for p in selected if p not in native},
              'python_version': sys.version}
    # Repair captures can precede their commit. Retain every changed native
    # byte as an explicit overlay over the exact HEAD, never label it that HEAD.
    record['native_source_overrides'] = {
        p: (ROOT / p).read_text() for p in native
        if hashlib.sha256(subprocess.check_output(['git', 'show', head + ':' + p])).hexdigest() != identities[p]}
    with Session(['perl', 'bin/fsmgen-mcp', '--workspace-root', '.']) as server:
        for request in ({'jsonrpc': '2.0', 'id': 0, 'method': 'initialize',
                         'params': {'protocolVersion': '2025-06-18', 'capabilities': {},
                                    'clientInfo': {'name': 'argument-kind-audit', 'version': '1'}}},
                        {'jsonrpc': '2.0', 'id': 1, 'method': 'tools/list'}):
            server.send(request)
            response = server.receive()
            if request['method'] == 'initialize':
                server.send({'jsonrpc': '2.0', 'method': 'notifications/initialized'})
            if request['method'] == 'tools/list':
                record['tools'] = response['result']['tools']
        rows = cases_for(record['tools'])
        inputs.write_text(json.dumps(rows, ensure_ascii=False, indent=2) + '\n')
        record['cases'] = rows
        replies = []
        for row in rows:
            # Preserve explicit numeric spellings; Session.send would reserialize
            # them after a Python float parse. Keep the original UTF-8 frames.
            raw = (row['request_utf8'] + '\n').encode('utf-8')
            server.sent.extend(raw)
            server.process.stdin.write(raw)
            server.process.stdin.flush()
            replies.append(server.receive(timeout=120))
        record['wire_replies'] = replies
        record['sent_utf8'] = server.sent.decode('utf-8')
        record['received_utf8'] = server.received.decode('utf-8')
    record['exit_status'] = server.process.returncode
    record['orderly_eof'] = True
    with api_output.open('wb') as out, api_errors.open('wb') as err:
        completed = subprocess.run(['perl', '-Iperl', 'docs/audits/mcp-api-reference-20261023/probe_argument_api.pl',
                                    inputs.relative_to(ROOT).as_posix()], cwd=ROOT, stdout=out, stderr=err, timeout=600)
    assert completed.returncode == 0 and not api_errors.read_bytes(), 'API audit failed; raw evidence retained'
    record['api'] = json.loads(api_output.read_bytes())
    assert identities == {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in selected}
    assert subprocess.check_output(['git', 'rev-parse', 'HEAD']).decode().strip() == head
    with gzip.GzipFile(filename=str(output), mode='wb', mtime=0) as out:
        out.write((json.dumps(record, ensure_ascii=False, indent=2) + '\n').encode('utf-8'))
    print('Complete API/pipe argument matrix retained: ' + output.relative_to(ROOT).as_posix())


if __name__ == '__main__':
    main()
