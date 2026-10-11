"""Complete recovered finite parent acceptance while preserving the first failure."""
import argparse
import stat
from parent_common import *
import book_native
import intake
import publish
import recover
import recovery_book_native
import recovery_source
import verify as initial

SUCCESS = initial.SUCCESS
EXCLUDED = {'proof.json', 'manifest.json'} | {label + suffix for label in ('seal', 'default', 'staged-doctrines')
    for suffix in ('-started.json', '-actual.json')}


def read(name):
    return json.loads((BASE / name).read_bytes())


def original_epoch():
    # The entire unchanged first verifier still qualifies its original core.
    # Its failed inventory delivery is authenticated separately, never promoted.
    result = initial.core(current=False)
    publication = publish.qualify(current=False)
    first = read('inventory-write-actual.json')
    finding = read('inventory-finding.json')
    started = read('inventory-write-started.json')
    need(all(same(first[key], value) for key, value in started.items())
         and type(first['status']) is int and first['status'] == 1
         and type(first['expected_status']) is int and first['expected_status'] == 0
         and first['command'] == ['scripts/run_with_ram_guard.sh', '--', 'scripts/check_claim_verification_inventory.pl', '--write']
         and same(first['programmes'], first['programmes_after']),
         'first failed inventory actual native1 and declared0 remain distinct')
    for entry in first['programmes'].values():
        raw = entry['body'].encode() if 'body' in entry else bytes.fromhex(entry['body_hex'])
        need(pin(raw) == entry['identity'], 'whole first failed inventory programme/input epoch')
    need(re.match(r'ram-guard: PID [0-9]+; host [0-9]+\.[0-9]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', first['stderr'])
         and 'ram-guard: terminating PID tree' not in first['stderr'], 'unchanged first failed inventory guard')
    need(first['stdout'] == '' and first['stderr'].endswith(
         'claim-inventory: disposition registry names stale candidate_id ' + finding['candidate_id'] + '\n'),
         'whole first unexpected stale-disposition failure retains')
    after = read('source-published.json')
    before = read('source-before.json')
    need(after == dict(before, overlays={name: pin(body) for name, body in intake.overlays(True).items()}),
         'whole original pre-recovery published source epoch retains')
    for label, command in {
        'publication': ['python3', '-B', str(BASE / 'publish.py')],
        'current-after': ['python3', '-B', str(BASE / 'current_snapshot.py'), 'after'],
        'focused': publish.COMMANDS['focused'], 'book': publish.COMMANDS['book'],
        'book-native': ['python3', '-B', str(BASE / 'book_native.py')],
        'source-published': ['python3', '-B', str(BASE / 'intake.py'), '--published'],
        'size': publish.COMMANDS['size'], 'claims': publish.COMMANDS['claims'],
    }.items():
        initial.gate(label, command)
    first_native = book_native.qualify(gzip.decompress((BASE / 'native-chapter.html.gz').read_bytes()).decode())
    need(same(first_native, read('book-native.json')), 'whole original first native chapter and scope retains')
    sources = load_product('canonical-after.json.gz')
    need(same(sources, load_product('canonical-before.json.gz')), 'whole original canonical source epoch retains')
    public = original_public()
    prior = public['historical']()
    record = load_product('current-after.json.gz')
    public['check'](record, {name: body.encode() for name, body in sources.items()}, prior, public['authority'](prior))
    return dict(core=result, publication=publication, source_published=after, native=first_native,
                first_inventory=pin(canonical(first)), finding=pin(canonical(finding)),
                condition='Initial finite source/cause/control scope and successful partial delivery retain their exact epochs. Initial inventory native1/declared0 remains a failed required delivery gate; only the separately qualified correction can complete acceptance.')


def corrected(*, current=False):
    row = recover.qualify(current=current)
    public = original_public()
    prior = public['historical']()
    sources = load_product('canonical-recovered.json.gz')
    need(same(sources, load_product('canonical-before.json.gz'))
         and sources == {name: body.decode() for name, body in canonical_sources().items()},
         'every canonical fact question probe and byte retains through encoding-line recovery')
    record = load_product('current-recovered.json.gz')
    public['check'](record, {name: body.encode() for name, body in sources.items()}, prior, public['authority'](prior))
    need(record['chapter'].encode() == recover.overlays()[BOOK], 'whole actual recovered current book source')
    native = recovery_book_native.qualify(gzip.decompress((BASE / 'native-chapter-recovered.html.gz').read_bytes()).decode())
    need(same(native, read('book-native-recovered.json')), 'whole actual recovered native guidance and original limits')
    source = read('source-recovered.json')
    before = read('source-before.json')
    need(source == dict(before, overlays={name: pin(body) for name, body in recover.overlays().items()}),
         'whole recovered source census with only exact owned metadata changes')
    if current:
        need(public['sources']() == {name: body.encode() for name, body in sources.items()}, 'whole explicit current recovered canonical source')
        need(same(recovery_source.live(intake.derive()), source), 'whole explicit current recovered source graph')
    commands = {
        'recovery-publication': ['python3', '-B', str(BASE / 'recover.py')],
        'current-recovered': ['python3', '-B', str(BASE / 'recovery_current.py')],
        'book-native-recovered': ['python3', '-B', str(BASE / 'recovery_book_native.py')],
        'source-recovered': ['python3', '-B', str(BASE / 'recovery_source.py')],
        'focused-corrected': publish.COMMANDS['focused'] + ['t/1638-claim-verification-dispositions.t'],
        'book-corrected': publish.COMMANDS['book'], 'native-corrected': publish.COMMANDS['native'],
        'size-corrected': publish.COMMANDS['size'], 'claims-corrected': publish.COMMANDS['claims'],
        'inventory-write-corrected': publish.COMMANDS['inventory-write'],
        'inventory-corrected': publish.COMMANDS['inventory'],
        'dispositions-corrected': ['scripts/check_claim_verification_dispositions.pl'],
    }
    gates = {label: initial.gate(label, command, current=current) for label, command in commands.items()}
    need('All tests successful' in read('focused-corrected-actual.json')['stdout'], 'actual complete corrected focused regression')
    return dict(publication=row, source=source, current=pin(canonical(record)), native=native, gates=gates,
                condition='Exact reviewed UTF-8 line and original disposition identity restore. Original meaning, classification, verifier, source/control epochs and authority retain; complete corrected current/native/source/claim/disposition delivery qualifies separately.')


def catalogue():
    result = {}
    for path in sorted(BASE.iterdir()):
        need(not path.is_symlink() and stat.S_ISREG(path.lstat().st_mode)
             and path.stat().st_dev == Path.cwd().stat().st_dev, 'whole ordinary flat same-volume recovered parent archive')
        if path.name not in EXCLUDED:
            result[path.name] = dict(**pin(path.read_bytes()), executable=bool(path.stat().st_mode & 0o111))
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--core', action='store_true')
    parser.add_argument('--seal', action='store_true')
    parser.add_argument('--current', action='store_true')
    args = parser.parse_args()
    need(not (args.core and args.seal), 'one complete corrected parent acceptance role')
    original = original_epoch()
    recovered = corrected(current=args.current or args.seal)
    result = dict(owner=PLAN['owner'], revision=PLAN['revision'], original=original, recovered=recovered,
        condition=PLAN['condition'], legs=dict(
            rederive='Complete unchanged original finite parent core and source/cause/native/control/canonical obligations, exact normalized encoding-line/disposition identity and whole corrected current source/query/capacity/native delivery.',
            falsify='All complete original native parent and child controls retain; the first actual stale-ID native refusal stays failed, while restored whole reviewed source text produces successful independent census/disposition qualification.',
            durability='Complete committed original and corrected source/programme/command/terminal/product/HTML/snapshot epochs, every first failure and scope limit, fixed source custody and normal receipts; saved recovery uses no ignored checkpoint.'))
    need(json.loads(canonical(result)) == result, 'whole recovered parent JSON-native proof round trip')
    if args.core:
        print('PASS complete unchanged original finite parent core and separately corrected delivery; first failure retains.')
    else:
        if args.seal:
            save('proof.json', result)
            save('manifest.json', catalogue())
        else:
            need(same(read('proof.json'), result) and same(read('manifest.json'), catalogue()), 'whole immutable complete recovered finite cause-parent acceptance')
        print(SUCCESS, end='')
