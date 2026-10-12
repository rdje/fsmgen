"""Complete unchanged original consumer contracts, whole source meanings and canonical custody."""
from parent_common import *
import interfaces

FAILURES = {
    'preparation-size': PLAN['preparation'] + '/size-actual.json',
    'publication-whitespace': PLAN['publication'] + '/whitespace-first.json',
    'publication-staging': PLAN['publication'] + '/size-repaired-actual.json',
    'canonical-development-preflight': PLAN['canonical_parent'] + '/development-publication-actual.json'}


def inputs():
    public = interfaces.public()
    source = json.loads((BASE / 'source-proposal.json').read_bytes())['roles']
    need(source['publication']['revision'] == PLAN['revision'], 'exact fixed canonical-parent source role')
    namespaces = {role: interfaces.namespace(PLAN[role]) for role in ('source_contract', 'meaning', 'preparation', 'publication', 'canonical_parent')}
    canonical = canonical_sources()
    need(all(Path(name).read_bytes() == body for name, body in canonical.items()), 'every unchanged current canonical source byte')
    prior = public['historical']()
    record = public['current_input'](prior, canonical)
    record['chapter'] = fixed([BOOK])[BOOK].decode()
    public['check'](record, canonical, prior, public['authority'](prior))
    admission = public['consumer_fact'].admission()
    need(public['consumer_fact'].published(admission).encode() == canonical[PLAN['target']], 'whole current admitted canonical consumer meanings')
    checkpoint_names = [PLAN['canonical_parent'] + '/' + name for name in ('proof.json', 'manifest.json', 'qualification.json')] + [PLAN['final_index']]
    checkpoint = {name: pin(body) for name, body in fixed(checkpoint_names).items()}
    failure_bytes = fixed(FAILURES.values())
    return dict(public=public, prior=prior, canonical=canonical, current=record,
                admission=admission, source=source, namespaces=namespaces,
                checkpoint=checkpoint, failures={role: json.loads(failure_bytes[name]) for role, name in FAILURES.items()},
                failure_identities={role: pin(failure_bytes[name]) for role, name in FAILURES.items()})


def header(data):
    return dict(schema_version=1, owner=PLAN['owner'], revision=PLAN['revision'],
        contracts=interfaces.contracts(), source=pin(canonical(data['source'])), namespaces=data['namespaces'],
        canonical={name: pin(body) for name, body in data['canonical'].items()},
        failure_identities=data['failure_identities'], canonical_checkpoint=data['checkpoint'], boundary=PLAN['condition'],
        assumptions='Complete independently qualified original source-contract/helper/remaining/join/meaning algorithms are shared fixed premises and independently reexecute. Qualified Storable primitive-kind witness and opaque synthetic trace retain; original native/private/provider/flags/encoding/hidden identities and later historical-programme currency remain unmeasured.')


def propose(data):
    paths = {role: PLAN[role] + '/candidate.json.gz' for role in ('source_contract', 'meaning')}
    bodies = fixed(paths.values())
    source = json.loads(gzip.decompress(bodies[paths['source_contract']]))
    meaning = json.loads(gzip.decompress(bodies[paths['meaning']]))
    links = []
    for mode in meaning['children']['join']['modes']:
        for row in mode['consumers']:
            assertion = source['assertions'][row['index']]
            value = row['meaning']
            links.append(dict(mode=mode['mode'], index=row['index'], role=row['role'],
                context=assertion['context'], source=pin(canonical(assertion)), native=pin(canonical(row['native'])),
                meaning=pin(canonical(value)), basis=pin(canonical({name: part for name, part in value.items() if name not in ('operand', 'outcome', 'source_assertion')})),
                operand=value['operand'], outcome=value['outcome']))
    return dict(header(data), admission=data['admission'], source_contracts=source, meanings=meaning, links=links,
                current=data['current'], failures=data['failures'])
