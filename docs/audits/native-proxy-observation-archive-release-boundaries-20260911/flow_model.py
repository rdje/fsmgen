"""Derive the selected healthy call forest from source loops and physical inputs.

No observed call, event, count or success verdict participates in construction.
Source aliases distinguish successive descriptors for the same physical file.
"""
from contextlib import contextmanager
import json

RELEASE = 'NativeProxyObservationRelease'
COORD = 'NativeProxyImageCoordination'
CUSTODY = 'NativeProxyImageCustody'
ARCHIVE = 'NativeProxyObservationArchive'
CENSUS = 'NativeProxyReferenceCensus'
PRIVATE = 'NativeProxyPrivateWorkspace'


def derive(context, before, spec):
    calls, stack, source_paths = [], [], {}
    store = context['store']['path']; evidence = context['evidence']['path']
    archive = evidence + '/retained-sources'
    hold = context['acquired']['observation_reference']['source']['identity']['path']
    selected_key = context['acquired']['observation_reference']['record']['image_key']
    references = {path.split('/')[-1]: json.loads(bytes.fromhex(node['bytes_hex']))
                  for path, node in before['store'].items() if path.startswith('references/')}
    available = sorted(path.split('/')[1] for path, node in before['store'].items()
                       if path.startswith('images/') and path.count('/') == 1 and node['kind'] == 'directory')
    archive_sources, live_sources = [], []

    @contextmanager
    def call(package, symbol, caller=None, **metadata):
        parent = stack[-1] if stack else None
        if caller is None:
            caller = calls[parent]['name'].rsplit('::', 1)[0] if parent is not None else COORD
        row = dict(id=len(calls), name=package + '::' + symbol, parent=parent, caller=caller, **metadata)
        calls.append(row); stack.append(row['id'])
        yield row
        assert stack.pop() == row['id']

    def leaf(package, symbol, **metadata):
        with call(package, symbol, **metadata): pass

    def directory(path, **metadata): leaf(CUSTODY, '_directory', path=path, **metadata)
    def names(path): leaf(COORD, '_names', path=path)

    def source(path, mode=0o400, limit=65536):
        alias = 'source:' + str(len(source_paths)); source_paths[alias] = path
        leaf(CUSTODY, '_source', path=path, mode=mode, limit=limit, opens=alias)
        return alias

    def recheck(alias): leaf(CUSTODY, '_recheck_source', path=source_paths[alias], source_handle=alias)

    def archive_members():
        with call(ARCHIVE, '_members'): names(archive)

    def archive_directories():
        with call(ARCHIVE, '_directory_closure'):
            directory(evidence); directory(archive)

    def archive_closure():
        with call(RELEASE, '_archive_closure'):
            archive_members(); archive_directories()
            with call(ARCHIVE, '_source_closure'):
                for alias in archive_sources:
                    recheck(alias); recheck(source(source_paths[alias]))
                for alias in archive_sources: recheck(alias)
            leaf(ARCHIVE, '_receipt'); archive_members(); archive_directories()
            for alias in archive_sources: recheck(alias)

    def read_entry(key):
        entry = store + '/images/' + key
        with call(CUSTODY, 'read_entry'):
            for path in (store, store + '/images', entry): directory(path)
            leaf(CUSTODY, '_members', path=entry)
            sources = [source(entry + '/rustup.c'), source(entry + '/rustup', 0o500),
                       source(entry + '/image.json', limit=4096)]
            leaf(CUSTODY, '_members', path=entry)
            for path in (store, store + '/images', entry): directory(path)
            for alias in sources: recheck(alias)

    def image(key):
        entry = store + '/images/' + key
        with call(CENSUS, '_image', image_key=key):
            directory(entry)
            sources = [source(entry + '/rustup.c'), source(entry + '/rustup', 0o500)]
            read_entry(key)
            for alias in sources: recheck(alias)
            directory(entry)

    def structure():
        with call(COORD, '_structure'):
            names(store); directory(store + '/images'); directory(store + '/references'); names(store)

    def census(records):
        with call(COORD, '_census'):
            names(store + '/images'); names(store + '/references')
            for key in available: directory(store + '/images/' + key)
            for name in sorted(records): recheck(source(store + '/references/' + name, limit=4096))

    def inspect(records):
        with call(CENSUS, '_inspect_locked', reference_names=sorted(records)):
            held, images = [], set()
            for name, record in sorted(records.items()):
                alias = source(store + '/references/' + name, limit=4096); held.append(alias)
                leaf(CENSUS, '_decode_record'); leaf(CENSUS, '_filename_key')
                key = record['image_key']
                if key not in images: image(key); images.add(key)
                leaf(CENSUS, '_matches_image'); recheck(alias)
            with call(CENSUS, '_closure'):
                names(store + '/references')
                for alias in held:
                    recheck(alias); recheck(source(source_paths[alias], limit=4096))
                for key in sorted(images): image(key)

    def retain_live():
        entry = store + '/images/' + selected_key
        with call(RELEASE, '_retain_live_sources'):
            for path, mode, limit in [(entry + '/rustup.c', 0o400, 65536),
                                      (entry + '/rustup', 0o500, 65536), (hold, 0o400, 4096)]:
                alias = source(path, mode, limit); live_sources.append(alias); recheck(alias)

    def absence(phase):
        with call(RELEASE, '_assert_absent', phase=phase): leaf(PRIVATE, '_absent', path=hold)

    with call(RELEASE, '_prepare', caller=RELEASE):
        leaf(ARCHIVE, '_limits')
        directory(evidence, caller='NativeProxyObservationAcquisition'); directory(archive); archive_members()
        for file in spec['files']:
            alias = source(file['path']); archive_sources.append(alias); recheck(alias)
        archive_closure()
    leaf(RELEASE, '_coordinator_request'); directory(store)
    leaf(COORD, '_lock_identity'); leaf(COORD, '_lock_identity'); directory(store)
    structure(); directory(store + '/images'); directory(store + '/references'); census(references)
    inspect(references)
    with call(RELEASE, '_admit_locked'):
        leaf(RELEASE, '_current_image'); archive_closure(); retain_live()
    census(references); inspect(references)
    with call(RELEASE, '_release_locked'):
        archive_closure(); image(selected_key); retain_live()
        for alias in archive_sources + live_sources: recheck(alias)
        leaf(RELEASE, '_unlink_exact'); absence('after_unlink')
    remaining = {name: record for name, record in references.items() if store + '/references/' + name != hold}
    census(remaining); inspect(remaining)
    with call(RELEASE, '_finish_locked'):
        image(selected_key); archive_closure(); absence('finish')
    structure(); directory(store + '/images'); directory(store + '/references'); directory(store)
    leaf(COORD, '_lock_identity')
    assert not stack
    return calls
