"""Real public examples plus successful-process/invalid-result adverse controls."""
import hashlib
import json
from pathlib import Path
import re
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'scripts'))
import check_pod_api_examples as examples


class PodExampleTest(unittest.TestCase):
    def fixture(self, module, program):
        temporary = ROOT / '.artifacts/tmp'
        temporary.mkdir(parents=True, exist_ok=True)
        work = tempfile.TemporaryDirectory(prefix='pod-example-control-', dir=temporary)
        self.addCleanup(work.cleanup)
        root = Path(work.name)
        path = root / 'docs/pod-api-entrypoints.json'
        path.parent.mkdir(parents=True)
        path.write_text(json.dumps({module: 'controlled fixture'}))
        path = root / ('perl/' + module.replace('::', '/') + '.pm')
        path.parent.mkdir(parents=True)
        path.write_text('package ' + module + ';\n1;\n__END__\n\n=head1 SYNOPSIS\n\n'
                        + '\n'.join('    ' + line for line in program.splitlines()) + '\n\n=cut\n')
        return root

    def test_actual_synopses_join_the_selected_book_guides(self):
        evidence = examples.check_examples()
        entries = json.loads((ROOT / 'docs/pod-api-entrypoints.json').read_bytes())
        guide = (ROOT / 'docs/book/src/11a-perl-api-reference.md').read_text()
        linked = {p.replace('/', '::') for p in re.findall(r'\]\(perl-api/(FSM/[\w/]+)\.html\)', guide)}
        self.assertEqual({r['module'] for r in evidence}, set(entries))
        self.assertEqual(set(entries), linked)
        for row in evidence:
            self.assertIs(type(row['exit_status']), int)
            self.assertEqual(row['exit_status'], 0)
            self.assertEqual(row['source_sha256'], hashlib.sha256((ROOT / row['source']).read_bytes()).hexdigest())

    def test_invalid_program_retains_exact_failure_evidence(self):
        root = self.fixture('FSM::Adapter::ISF', 'use FSM::Adapter::ISF;\nthis is invalid perl syntax !!!')
        with self.assertRaisesRegex(examples.ExampleError, 'example exited'):
            examples.check_examples(root)
        dirs = list((root / '.artifacts/tmp').glob('pod-api-examples-*'))
        self.assertEqual(len(dirs), 1)
        self.assertIn(b'syntax error', (dirs[0] / 'FSM-Adapter-ISF.stderr').read_bytes())
        self.assertIn(b'this is invalid', (dirs[0] / 'FSM-Adapter-ISF.pl').read_bytes())

    def test_successful_process_with_wrong_result_is_rejected(self):
        root = self.fixture('FSM::Adapter::ISF', 'use FSM::Adapter::ISF;\nprint "wrong_actor\\n";')
        with self.assertRaisesRegex(examples.ExampleError, 'expected the parsed i2c_master actor'):
            examples.check_examples(root)

    def test_boolean_schema_version_is_not_a_number(self):
        program = '''use FSM::Support::CapabilityManifest;
print '{"manifest_schema_version":true,"embedding":{"hdl_generator_facade":{"method_names":["new","generate_hdl_from_file"]}}}';'''
        root = self.fixture('FSM::Support::CapabilityManifest', program)
        with self.assertRaisesRegex(examples.ExampleError, 'expected numeric manifest schema version 1'):
            examples.check_examples(root)

    def test_integral_numeric_spelling_and_successful_workspace_cleanup(self):
        program = '''use FSM::Support::CapabilityManifest;
print '{"manifest_schema_version":1.0,"embedding":{"hdl_generator_facade":{"method_names":["new","generate_hdl_from_file"]}}}';'''
        root = self.fixture('FSM::Support::CapabilityManifest', program)
        evidence = examples.check_examples(root)
        self.assertEqual(evidence[0]['exit_status'], 0)
        self.assertEqual(list((root / '.artifacts/tmp').glob('pod-api-examples-*')), [])

    def test_unexpected_stderr_does_not_pass_with_a_correct_result(self):
        root = self.fixture('FSM::Adapter::ISF',
                            'use FSM::Adapter::ISF;\nwarn "controlled warning\\n";\nprint "i2c_master\\n";')
        with self.assertRaisesRegex(examples.ExampleError, 'unexpected stderr'):
            examples.check_examples(root)

    def test_hanging_example_times_out_and_retains_its_program(self):
        root = self.fixture('FSM::Adapter::ISF', 'use FSM::Adapter::ISF;\nsleep 5;')
        with self.assertRaisesRegex(examples.ExampleError, 'exceeded'):
            examples.check_examples(root, timeout=.1)
        dirs = list((root / '.artifacts/tmp').glob('pod-api-examples-*'))
        self.assertEqual(len(dirs), 1)
        self.assertIn(b'sleep 5;', (dirs[0] / 'FSM-Adapter-ISF.pl').read_bytes())


if __name__ == '__main__':
    unittest.main()
