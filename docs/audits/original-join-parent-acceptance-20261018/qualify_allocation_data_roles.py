"""Closed adapter for the data qualifier's original two-source metadata contract."""
import gzip
import json

import qualify_operand_allocation as reader
import saved_source_roles as shared

SELF = 'qualify_allocation_data_roles.py'
LINE = ('Actual default allocation reader rejects changed namespace data with a fresh '
        'payload hash under its unchanged native model reference; original proof '
        'and programmes remain untouched.\n')
SCOPE = ('Dependent qualifier saved source metadata and its complete original '
         'candidate/data/native binding, positive/negative current audit-reader '
         'outputs, scope and execution flag only. The original proof names exactly '
         'qualifier/allocation sources using full relative path keys; no prepare '
         'source is invented. Nested current allocation audit readers retain their '
         'saved mode. Current/write selection affects the qualifier metadata only. '
         'Historical images remain metadata and never execute. Source/model/Python/'
         'gzip/Git semantics remain shared premises. Complete source/default/effect/'
         'runtime/custody/private/HIAL/full-CI, native admission and whole-helper '
         'success remain separately owned.')


class Qualification(shared.Qualification):
    """Keep the shared collector/reviewer; declare this different original schema."""

    def __init__(self):
        # The common constructor requires a prepare.py premise. This original
        # contract has exactly two different keys, so declare them explicitly.
        assert reader.PREMISES == ('qualify_operand_allocation.py', 'operand_allocation.py')
        self.reader = reader
        self.sources = (reader.SELF, 'saved_reader_sources.py', 'saved_source_roles.py', SELF)
        assert len(set(self.sources)) == len(self.sources)
        for name in self.sources:
            shared.source.source_name(name)
        self.output = shared.AUDIT / 'allocation-data-source-roles-qualified.json.gz'
        self.line, self.scope = LINE, SCOPE

    def reference(self):
        original = {name: shared.source.original(name) for name in reader.PREMISES}
        raw = shared.execute.read(reader.PATH)
        shared.equal(raw, shared.epoch.read(shared.source.REVISION, str(reader.PATH)))
        metadata = {str(shared.AUDIT / name): row['body'] for name, row in original.items()}
        shared.equal(json.loads(gzip.decompress(raw))['programmes'], metadata)
        shared.equal(reader.source_metadata(), metadata)
        return dict(original=original, metadata=metadata,
                    proof=dict(revision=shared.source.REVISION, path=str(reader.PATH),
                               identity=shared.prepare.identity(raw), retention_contract='fsmgen_required_history'))

    def controls(self, fixed):
        images = {name: shared.unblob(row['body']) for name, row in fixed['original'].items()}
        changed = dict(images)
        changed[reader.SELF] = b'x' + changed[reader.SELF][1:]
        rows = []
        for label, supplied, denied in (('historical-image', images, False),
                                        ('changed-image', changed, False),
                                        ('denied-image', images, True)):
            for current in (False, True):
                with self.supplied_images(supplied, denied) as attempted:
                    result = shared.outcome(lambda: shared.equal(reader.source_metadata(current=current), fixed['metadata']))
                assert result['accepted'] is (not current or label == 'historical-image')
                assert bool(attempted) is current
                rows.append(dict(label=label, current=current, reads=attempted, result=result))
        key = str(shared.AUDIT / reader.SELF)
        other = str(shared.AUDIT / 'operand_allocation.py')
        for label in ('float-bytes', 'boolean-bytes', 'missing-member', 'rehashed-body', 'borrowed-reader'):
            candidate = dict(fixed['metadata'])
            candidate[key] = dict(candidate[key])
            if label == 'float-bytes':
                candidate[key]['bytes'] = float(candidate[key]['bytes'])
            elif label == 'boolean-bytes':
                candidate[key]['bytes'] = True
            elif label == 'missing-member':
                del candidate[key]
            elif label == 'rehashed-body':
                candidate[key] = shared.prepare.blob(changed[reader.SELF])
            else:
                candidate[key] = candidate[other]
            result = shared.outcome(lambda: shared.equal(candidate, reader.source_metadata()))
            assert not result['accepted']
            rows.append(dict(label=label, candidate=candidate, result=result))
        for name in ('../qualify_operand_allocation.py', 'inventory.json.gz', 'missing-source-control.py'):
            result = shared.outcome(lambda: shared.source.original(name))
            assert not result['accepted']
            rows.append(dict(label='closed-native-member', name=name, result=result))
        command = shared.source.execute.command
        try:
            def changed_show(argv):
                raw = command(argv)
                return b'x' + raw[1:] if argv[2] == 'show' else raw
            shared.source.execute.command = changed_show
            result = shared.outcome(lambda: shared.source.original(reader.SELF))
            assert not result['accepted']
            rows.append(dict(label='changed-native-show', result=result))
        finally:
            shared.source.execute.command = command
        return rows


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    Qualification().main()
