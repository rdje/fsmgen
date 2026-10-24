#!/usr/bin/env python3
"""Retain/replay actual canonical native pages and isolated refusal controls."""
import argparse
import copy
import gzip
import json
from pathlib import Path
import tempfile

from verify_shared_closure import rendered, require, sha

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
PAGES = ('11a-perl-api-reference.html', '11-extensions-and-embedding.html',
         'perl-api/FSM/Support/CapabilityManifest.html')


def exercise(pages):
    require(set(pages) == set(PAGES), 'complete actual native pages')
    scratch = ROOT / '.artifacts/shared-closure'
    scratch.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=scratch) as name:
        fixture = Path(name)

        def write(view):
            for path in PAGES:
                target = fixture / path
                if path in view:
                    target.parent.mkdir(parents=True, exist_ok=True)
                    target.write_text(view[path])
                elif target.exists():
                    target.unlink()

        write(pages)
        result = {'original': rendered(fixture), 'refusals': {}}
        for label in ('missing_canonical', 'candidate_cell', 'drive_cell',
                      'aggregate_cell', 'grouped_cell', 'compatibility_route', 'pod_guide'):
            view = copy.deepcopy(pages)
            if label == 'missing_canonical':
                view.pop(PAGES[0])
            elif label == 'compatibility_route':
                old = '11a-perl-api-reference.html#normalized-shared-datapath-candidate-and-contributor-subjects'
                require(old in view[PAGES[1]], 'native route control intervention')
                view[PAGES[1]] = view[PAGES[1]].replace(old, 'missing.html#wrong', 1)
            elif label == 'pod_guide':
                old = 'Normalized shared-datapath grouped lookups'
                require(old in view[PAGES[2]], 'native POD control intervention')
                view[PAGES[2]] = view[PAGES[2]].replace(old, 'Removed shared grouped guide')
            else:
                section, token = {
                    'candidate_cell': ('candidate-and-contributor-subjects', 'signal_name'),
                    'drive_cell': ('binding-and-drive-intent-subjects', 'signal_ref_variant'),
                    'aggregate_cell': ('aggregate-and-assertion-subjects', 'input_enable_signals'),
                    'grouped_cell': ('grouped-lookups', 'forward_ir_lowered_rtl_ir_composition_shared_datapath_assertion_keys')}[label]
                text = view[PAGES[0]]
                head, tail = text.split('<h3 id="normalized-shared-datapath-' + section + '"', 1)
                require(token in tail, 'native table control intervention')
                view[PAGES[0]] = head + '<h3 id="normalized-shared-datapath-' + section + '"' + tail.replace(token, 'invented_cell', 1)
            write(view)
            try:
                rendered(fixture)
            except (ValueError, FileNotFoundError) as error:
                result['refusals'][label] = ('missing canonical page' if isinstance(error, FileNotFoundError) else str(error))
            else:
                raise ValueError('Accepted native counterfeit: ' + label)
        return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('packet', type=Path)
    parser.add_argument('--capture-build', type=Path)
    parser.add_argument('--current-build', type=Path)
    args = parser.parse_args()
    if args.capture_build:
        require(args.packet.resolve().parent == BASE and not args.packet.exists(), 'new owned native packet')
        pages = {path: (args.capture_build / path).read_text() for path in PAGES}
        packet = {'schema': 'fsmgen.shared_closure_native.v1', 'pages': pages,
            'closure_sha256': sha((BASE / 'shared-closure-qualified.json.gz').read_bytes()),
            'instrument': {'text': Path(__file__).read_text(), 'sha256': sha(Path(__file__).read_bytes())},
            'reader_sha256': sha((BASE / 'verify_shared_closure.py').read_bytes()),
            'result': exercise(pages)}
        require(pages == {path: (args.capture_build / path).read_text() for path in PAGES}, 'production native pages conserved')
        args.packet.write_bytes(gzip.compress((json.dumps(packet, sort_keys=True, indent=2) + '\n').encode(), mtime=0))
    packet = json.loads(gzip.decompress(args.packet.read_bytes()))
    require(packet['schema'] == 'fsmgen.shared_closure_native.v1', 'native packet identity')
    require(packet['instrument'] == {'text': Path(__file__).read_text(), 'sha256': sha(Path(__file__).read_bytes())}, 'native instrument identity')
    require(packet['reader_sha256'] == sha((BASE / 'verify_shared_closure.py').read_bytes()), 'native reader identity')
    require(packet['closure_sha256'] == sha((BASE / 'shared-closure-qualified.json.gz').read_bytes()), 'native closure input identity')
    require(exercise(packet['pages']) == packet['result'], 'complete native result replay')
    if args.current_build:
        require(packet['pages'] == {path: (args.current_build / path).read_text() for path in PAGES}, 'current native pages stale')
    print(json.dumps({'canonical_sha256': sha(packet['pages'][PAGES[0]].encode()),
        'rejected_controls': packet['result']['refusals'], 'production_pages_unchanged': True}, sort_keys=True))


if __name__ == '__main__':
    main()
