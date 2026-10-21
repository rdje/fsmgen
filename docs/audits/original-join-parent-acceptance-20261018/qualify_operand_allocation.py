"""Exercise the actual allocation reader against rehashed, changed model data."""
import argparse
import contextlib
import copy
import gzip
import io
import json
import runpy
import sys

import operand_allocation as allocation
import saved_reader_sources as source

PATH = allocation.execute.AUDIT / 'operand-allocation-data-control-qualified.json.gz'
SOURCE = allocation.execute.AUDIT / 'qualify_operand_allocation.py'
SELF = 'qualify_operand_allocation.py'
PREMISES = (SELF, 'operand_allocation.py')


def source_metadata(*, current=False):
    return {str(allocation.execute.AUDIT / name):
            allocation.prepare.blob(source.body(name, current=current)) for name in PREMISES}


def qualify():
    original = allocation.execute.read(allocation.PATH)
    product = json.loads(gzip.decompress(original))
    bad = copy.deepcopy(product)
    entry = bad['inputs'][str(allocation.AST_INPUT)]
    model = json.loads(gzip.decompress(allocation.prepare.unblob(entry['body'])))
    namespace = model['result']['bindings'][0]['recipe']['namespace']
    assert namespace['__name__'] != '__main__'
    namespace['__name__'] = '__main__'
    changed_model = gzip.compress(allocation.prepare.encoded(model), mtime=0)
    entry['body'] = allocation.prepare.blob(changed_model)
    # A fresh hash alone must not admit different data under the old native pin.
    allocation.bounded.strict_equal(entry['reference'], product['inputs'][str(allocation.AST_INPUT)]['reference'])
    assert changed_model != allocation.prepare.unblob(product['inputs'][str(allocation.AST_INPUT)]['body'])
    candidate = gzip.compress(allocation.prepare.encoded(bad), mtime=0)
    prior_read, prior_argv = allocation.execute.read, sys.argv
    positive, output = io.StringIO(), io.StringIO()

    def controlled_read(path):
        return candidate if str(path) == str(allocation.PATH) else prior_read(path)

    try:
        sys.argv = [str(allocation.execute.AUDIT / 'operand_allocation.py')]
        with contextlib.redirect_stdout(positive):
            runpy.run_path(sys.argv[0], run_name='__main__')
        assert positive.getvalue().startswith('Complete prior input models join'), 'unmodified actual reader passes first'
        allocation.execute.read = controlled_read
        with contextlib.redirect_stdout(output):
            try:
                runpy.run_path(sys.argv[0], run_name='__main__')
            except AssertionError as error:
                refusal = str(error)
            else:
                raise RuntimeError('actual default reader admitted changed model data with a fresh hash')
    finally:
        allocation.execute.read, sys.argv = prior_read, prior_argv
    assert refusal and not output.getvalue(), 'reader refuses before printing success'
    assert allocation.execute.read(allocation.PATH) == original, 'published proof remains untouched'
    return dict(owner=allocation.OWNER,
        scope='Actual current default allocation reader with only its stored-proof read substituted; no original programme or model executes and no published input/proof changes.',
        original=allocation.prepare.identity(original), candidate=allocation.prepare.blob(candidate),
        changed_model=allocation.prepare.identity(changed_model), refusal=refusal,
        positive_stdout=positive.getvalue(), stdout=output.getvalue(), original_programme_execution=False,
        programmes=source_metadata())


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    parser.add_argument('--current', action='store_true', help='compare installed qualifier/allocation source metadata')
    args = parser.parse_args()
    product = qualify()
    if args.write or args.current:
        product['programmes'] = source_metadata(current=True)
    if args.write:
        allocation.execute.save(PATH, product)
    else:
        allocation.bounded.strict_equal(json.loads(gzip.decompress(allocation.execute.read(PATH))), product)
    print('Actual default allocation reader rejects changed namespace data with a fresh payload hash under its unchanged native model reference; original proof and programmes remain untouched.')
