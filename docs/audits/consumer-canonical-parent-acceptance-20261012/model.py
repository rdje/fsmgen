"""Complete unchanged canonical contracts, admitted meanings and fixed current facts."""
from parent_common import *
import interfaces

FAILURES = {
    'preparation-size': PLAN['preparation'] + '/size-actual.json',
    'publication-whitespace': PLAN['publication'] + '/whitespace-first.json',
    'publication-staging': PLAN['publication'] + '/size-repaired-actual.json'}


def inputs():
    public = interfaces.public()
    source = json.loads((BASE / 'source-proposal.json').read_bytes())['roles']
    need(source['publication']['revision'] == PLAN['revision'], 'exact fixed canonical-parent source role')
    namespaces = {role: interfaces.namespace(PLAN[role]) for role in ('preparation', 'publication', 'meaning')}
    canonical = canonical_sources()
    need(all(Path(name).read_bytes() == body for name, body in canonical.items()), 'every unchanged current canonical source byte')
    prior = public['historical']()
    record = public['current_input'](prior, canonical)
    record['chapter'] = fixed([BOOK])[BOOK].decode()
    public['check'](record, canonical, prior, public['authority'](prior))
    admission = public['consumer_fact'].admission()
    need(public['consumer_fact'].published(admission).encode() == canonical[PLAN['target']], 'whole current admitted canonical consumer meanings')
    failure_bytes = fixed(FAILURES.values())
    return dict(public=public, prior=prior, canonical=canonical, current=record,
                admission=admission, source=source, namespaces=namespaces,
                failures={role: json.loads(failure_bytes[name]) for role, name in FAILURES.items()},
                failure_identities={role: pin(failure_bytes[name]) for role, name in FAILURES.items()})


def header(data):
    return dict(schema_version=1, owner=PLAN['owner'], revision=PLAN['revision'],
        contracts=interfaces.contracts(), source=pin(canonical(data['source'])), namespaces=data['namespaces'],
        canonical={name: pin(body) for name, body in data['canonical'].items()},
        failure_identities=data['failure_identities'], boundary=PLAN['condition'],
        assumptions='Complete independently qualified original helper/remaining/join/meaning algorithms are shared fixed premises and independently reexecute. Qualified Storable primitive-kind witness and opaque synthetic trace retain; original native/private/provider/flags/encoding/hidden identities and later historical-programme currency remain unmeasured.')


def propose(data):
    path = PLAN['meaning'] + '/candidate.json.gz'
    meaning = json.loads(gzip.decompress(fixed([path])[path]))
    return dict(header(data), admission=data['admission'], meanings=meaning,
                current=data['current'], failures=data['failures'])
