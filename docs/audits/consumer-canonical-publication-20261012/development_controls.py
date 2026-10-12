"""Exercise the complete permanent suite against the pure proposed publication."""
import importlib.util
import unittest
from publication_common import *
import publish

spec = importlib.util.spec_from_file_location('publication_tests', 't/python/test_record_value_current_publication.py')
tests = importlib.util.module_from_spec(spec)
spec.loader.exec_module(tests)
current = tests.current
prior = current.historical()
sources = current.sources()
after, _ = publish.transformation({name: Path(name).read_bytes() for name in
    (TASK, BOOK, REGISTRY, 'MEMORY.md', 'docs/TASK_TREE.md', publish.fact.CARD)})
sources[publish.fact.CARD] = after[publish.fact.CARD]
record = current.current_input(prior, sources)
record['chapter'] = after[BOOK].decode()

def setup(cls):
    cls.prior, cls.declared, cls.canonical, cls.record = prior, current.authority(prior), sources, record

tests.CurrentPublicationTests.setUpClass = classmethod(setup)
result = unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromModule(tests))
need(result.wasSuccessful(), 'complete permanent suite against pure proposed publication')
print('PASS development-only complete permanent controls on the virtual publication; live production unchanged.')
