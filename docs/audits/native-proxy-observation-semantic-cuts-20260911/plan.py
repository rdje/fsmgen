"""Prospective semantic flows for every possible canonical reference ordering."""
from __future__ import annotations

import hashlib
import itertools
import json
from pathlib import Path
import struct

BASE = Path(__file__).resolve().parent
OWNER = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.3.2.2.2.2.2.2.2.2.1'
REVISION = 'c2bd1d2aa7e78a85571d34fc36cdcc02fe0485dd'


def image_keys() -> dict[str, str]:
    vector = json.loads((BASE.parent/'native-proxy-image-custody-20260910/vectors.json').read_bytes())
    c = bytes.fromhex(vector['generated_c_hex']); image = bytes.fromhex(vector['image_hex'])
    def key(value):
        return hashlib.sha256(b'fsmgen.rust_proxy_image.v1\0'+struct.pack('>Q', len(c))+c
                              +struct.pack('>Q', len(value))+value).hexdigest()
    assert key(image) == vector['key']
    return dict(primary=key(image), other=key(image+b'other'))


def flow(order: tuple[str, ...], closure_order: list[str]) -> list[dict]:
    assert set(order) == set(closure_order) == {'primary', 'other'}
    rows = []
    def add(event, effect=None): rows.append(dict(event=event, effect=effect))
    def image(part, role):
        prefix = 'image:'+part+':'+role
        add(prefix+':enter'); add(prefix+':directory:initial')
        for name in ('c', 'image'): add(prefix+':input:'+name+':read', dict(image=role, source=name))
        add(prefix+':reader:enter', dict(reader=role))
        add(prefix+':reader:return')
        for name in ('c', 'image'): add(prefix+':input:'+name+':check')
        add(prefix+':directory:final'); add(prefix+':return')
    add('inspect:enter')
    seen = set()
    for index, role in enumerate(order):
        prefix = 'reference:initial:'+str(index)
        add(prefix+':read', dict(reference=index))
        add(prefix+':decode'); add(prefix+':key')
        if role not in seen: image('initial', role); seen.add(role)
        add(prefix+':match'); add(prefix+':check'); add(prefix+':snapshot')
    add('closure:enter'); add('closure:names', dict(reference_directory=True))
    for index in range(len(order)):
        prefix = 'reference:closure:'+str(index)
        add(prefix+':original'); add(prefix+':read', dict(reference=index)); add(prefix+':fresh')
    for role in closure_order: image('closure', role)
    add('closure:return')
    assert len(rows) == len({row['event'] for row in rows})
    return rows


def build() -> dict:
    keys = image_keys(); closure_order = sorted(keys, key=keys.get)
    flows = {}; cases = []; mutants = []
    for route in ('fresh', 'reuse'):
        flows[route] = {}
        for phase in ('pre', 'post'):
            roles = ['primary', 'other', 'other']
            if route == 'reuse' or phase == 'post': roles.append('primary')
            orders = sorted(set(itertools.permutations(roles)))
            variants = {','.join(order): flow(order, closure_order) for order in orders}
            flows[route][phase] = variants
            selectors = [row['event'] for row in next(iter(variants.values()))]
            assert all({row['event'] for row in rows} == set(selectors) for rows in variants.values())
            prefix = route+':'+phase
            cases.append(dict(id=prefix+':complete', route=route, phase=phase, cut=None, hold='complete'))
            for event in selectors:
                cases.append(dict(id=prefix+':'+event, route=route, phase=phase, cut=event,
                                  hold='complete' if route == 'reuse' or phase == 'post' else 'absent'))
            for guard in ('omit_original_reference_close', 'omit_image_input_close', 'omit_fresh_reference_close'):
                mutants.append(dict(id=prefix+':'+guard, route=route, phase=phase, guard=guard, hold='complete'))
    return dict(schema='fsmgen.inactive_observation_semantic_cut_plan.v1', owner=OWNER,
        source_revision=REVISION, image_keys=keys, image_closure_order=closure_order,
        flows=flows, cases=cases, mutants=mutants,
        fixture='The qualified four-root context, two original inert runtime images and independent other observation hold. Reuse starts from its exact primary acquisition. Record every allocation immediately and reconcile complete per-case journals. No process, compiler, native query/helper, archive/release or retry.',
        ordering='Prospectively enumerate every possible primary/other image-role order for the three/four canonical reference names. Each case binds its order from independently validated records sorted by reference key; initial image reads occur only at first reference to that image, while image closure follows sorted content keys. Every variant has exactly the same unique cut selectors; only its executed ordering varies. No flow is derived from the observed event trace. Each selector runs once with its freshly allocated actual order; this is not the full selector-by-order Cartesian product.',
        checkpoints='Cut before selected reference/semantic/image helper calls, or after complete image readers/image helpers/reference closure return without transferring an open handle. Do not inject after a source read but before its caller can own the handle. Caller-sealed inspection/observation wrappers tail-goto originals. ImageCustody read_entry is an aggregate checked reader boundary; this slice does not enumerate its every internal instruction.',
        custody='Retain every returned source/writer/lock and actual directory handle from the full operation, even outside the selected semantic pass. Start from the independently qualified coordinator resource prefix before that pass, then add only completed semantic-call effects. An aggregate image reader adds C/executable/manifest sources and two directory enumerations. Every reference read adds one actual source. Readback/publication and target sources outside the selected pass retain their qualified exact counts. Verify byte/native identity, explicit close before recovery, lock inheritance, exact conservative hold state and every other owner.',
        mutants_contract='For each route/pass, deliberately omit exactly the first selected original-reference, initial-image C-input, or fresh-reference close while reporting success. Use actual retained handle identity, not reused descriptor numbers. The independent oracle derives its exact per-path occurrence from the prospective prefix; strict custody must expose one open descriptor and observer recovery closes it.',
        limits='Finite synchronous census call-boundary controls. Census/target/lock close reports, every aggregate-reader internal instruction or syscall error, asynchronous crashes, native ownership, archive/capture settlement, exact release, activation and historical startup repair remain separately owned or unqualified.')


if __name__ == '__main__':
    Path(__file__).with_name('plan.json').write_text(json.dumps(build(), sort_keys=True, indent=2)+'\n')
