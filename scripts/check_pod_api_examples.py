#!/usr/bin/env python3
"""Execute selected repository POD synopses and check their public results."""

import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

from generate_pod_reference import ROOT, ReferenceError, local_path


class ExampleError(RuntimeError):
    pass


def require(condition, message):
    if not condition:
        raise ExampleError(message)


def number_is(value, expected):
    # Integral JSON numeric spellings are equivalent; Booleans are not numbers.
    return type(value) in (int, float) and value == expected


def parse_json(module, text):
    def invalid_constant(value):
        raise ExampleError(f'{module}: invalid JSON constant {value}')
    try:
        result = json.loads(text, parse_constant=invalid_constant)
    except ValueError as error:
        raise ExampleError(f'{module}: example did not emit one JSON object: {error}') from error
    require(isinstance(result, dict), f'{module}: expected a JSON object')
    return result


def observe(module, raw, root):
    text = raw.decode('utf-8')
    if module == 'FSM::Adapter::ISF':
        require(text.strip() == 'i2c_master', f'{module}: expected the parsed i2c_master actor')
    elif module == 'FSM::Pipeline::HDLGenerator':
        require(re.search(r'\bmodule\s+ahb_lite_subordinate\b', text) and 'endmodule' in text,
                f'{module}: expected generated AHB module HDL')
    elif module == 'FSM::Scheduler::ISF':
        report = parse_json(module, text)
        require(report.get('scheduled_fsm') == 'i2c_master.fsm'
                and number_is(report.get('schema_version'), 1),
                f'{module}: expected the version-1 i2c_master schedule report')
    elif module == 'FSM::Support::CapabilityManifest':
        manifest = parse_json(module, text)
        require(number_is(manifest.get('manifest_schema_version'), 1),
                f'{module}: expected numeric manifest schema version 1')
        embedding = manifest.get('embedding')
        require(isinstance(embedding, dict), f'{module}: expected embedding contracts')
        facade = embedding.get('hdl_generator_facade')
        require(isinstance(facade, dict), f'{module}: expected the HDL facade contract')
        methods = facade.get('method_names')
        require(isinstance(methods, list) and len(methods) == 2
                and all(isinstance(name, str) for name in methods)
                and set(methods) == {'new', 'generate_hdl_from_file'},
                f'{module}: expected the bounded HDL facade methods')
    elif module == 'FSM::Support::SemanticIntrospectionMCPAdapter':
        response = parse_json(module, text)
        require(response.get('jsonrpc') == '2.0' and number_is(response.get('id'), 1),
                f'{module}: expected the matching JSON-RPC response')
        result = response.get('result')
        require(isinstance(result, dict) and isinstance(result.get('tools'), list),
                f'{module}: expected a tool-list result')
        require(any(isinstance(tool, dict) and tool.get('name') == 'fsmgen_vial_inspect'
                    for tool in result['tools']), f'{module}: missing the typed VIAL inspection tool')
    elif module == 'FSM::VIAL::Tool':
        inspection = parse_json(module, text)
        require(inspection.get('schema') == 'fsmgen.vial_source_semantics.v1'
                and number_is(inspection.get('schema_version'), 1)
                and inspection.get('language') == 'vial'
                and number_is(inspection.get('language_version'), 1),
                f'{module}: expected version-1 typed VIAL source semantics')
        identity = inspection.get('root_source')
        source_id = 'vial/ahb_subordinate_base_output_arbitration.vial'
        require(isinstance(identity, dict) and identity.get('source_name') == source_id,
                f'{module}: expected the inspected AHB source identity')
        expected = hashlib.sha256(local_path(root, source_id).read_bytes()).hexdigest()
        require(identity.get('content_sha256') == expected, f'{module}: source bytes do not match inspection')
    else:
        raise ExampleError(f'No result oracle for selected entry point: {module}')


SUPPORTED = {
    'FSM::Adapter::ISF', 'FSM::Pipeline::HDLGenerator', 'FSM::Scheduler::ISF',
    'FSM::Support::CapabilityManifest', 'FSM::Support::SemanticIntrospectionMCPAdapter',
    'FSM::VIAL::Tool',
}


def synopsis(module, raw):
    match = re.search(r'^=head1 SYNOPSIS\s*\n(.*?)(?=^=head1\b|^=cut\b|\Z)',
                      raw.decode('utf-8'), flags=re.MULTILINE | re.DOTALL)
    require(match is not None, f'{module}: missing SYNOPSIS')
    snippet = '\n'.join(line[4:] for line in match[1].splitlines() if line.startswith('    ')) + '\n'
    require('use FSM::' in snippet, f'{module}: SYNOPSIS must contain a standalone Perl API program')
    return snippet.encode('utf-8')


def check_examples(root=ROOT, *, timeout=120):
    root = Path(root).resolve()
    require(timeout > 0, 'Example timeout must be positive')
    entries = json.loads(local_path(root, 'docs/pod-api-entrypoints.json').read_bytes())
    require(isinstance(entries, dict) and entries and set(entries) <= SUPPORTED,
            'Selected entry points require explicit result oracles')
    inputs = {module: local_path(root, 'perl/' + module.replace('::', '/') + '.pm').read_bytes()
              for module in sorted(entries)}
    temporary = local_path(root, '.artifacts/tmp')
    temporary.mkdir(parents=True, exist_ok=True)
    work = Path(tempfile.mkdtemp(prefix='pod-api-examples-', dir=temporary))
    evidence = []
    try:
        for module, raw in inputs.items():
            stem = module.replace('::', '-')
            (work / (stem + '.pm.source')).write_bytes(raw)
            program = synopsis(module, raw)
            script = work / (stem + '.pl')
            script.write_bytes(program)
            stdout, stderr = work / (stem + '.stdout'), work / (stem + '.stderr')
            with stdout.open('wb') as out, stderr.open('wb') as err:
                try:
                    result = subprocess.run(['perl', '-Iperl', str(script.relative_to(root))],
                                            cwd=root, stdout=out, stderr=err, timeout=timeout)
                except subprocess.TimeoutExpired as error:
                    raise ExampleError(f'{module}: example exceeded {timeout:g} seconds') from error
            errors = stderr.read_bytes()
            require(result.returncode == 0,
                    f'{module}: example exited {result.returncode}\n' + errors.decode('utf-8', errors='replace'))
            require(not errors, f'{module}: unexpected stderr\n' + errors.decode('utf-8', errors='replace'))
            observe(module, stdout.read_bytes(), root)
            evidence.append({'module': module, 'source': 'perl/' + module.replace('::', '/') + '.pm',
                             'source_sha256': hashlib.sha256(raw).hexdigest(),
                             'snippet_sha256': hashlib.sha256(program).hexdigest(),
                             'exit_status': result.returncode, 'observation': 'expected public result accepted'})
        require(all(local_path(root, 'perl/' + module.replace('::', '/') + '.pm').read_bytes() == raw
                    for module, raw in inputs.items()), 'Selected POD source changed during example checks')
    except (ExampleError, ReferenceError, OSError, UnicodeError, ValueError) as error:
        (work / 'completed-examples.json').write_text(json.dumps(evidence, indent=2, sort_keys=True) + '\n')
        raise ExampleError(f'{error}\nEvidence retained: {work.relative_to(root)}') from error
    shutil.rmtree(work)  # Only the exact checker-created successful workspace.
    return evidence


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--timeout', type=int, default=120, metavar='SECONDS',
                        help='time limit for each standalone example (default: 120)')
    args = parser.parse_args()
    print(json.dumps(check_examples(timeout=args.timeout), indent=2, sort_keys=True))


if __name__ == '__main__':
    try:
        main()
    except (ExampleError, ReferenceError, OSError, UnicodeError, ValueError) as error:
        print(f'pod-api-examples: ERROR: {error}', file=sys.stderr)
        sys.exit(1)
