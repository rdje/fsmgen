"""Select the exact Rust-parity wrapper, never the first generic PROBE block."""
from pathlib import Path

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
SCOPE = b"subtest 'Rust parity rejects unresolved and misleading tool identities before building' => sub {\n"
CALL = (b"        my $probe = File::Spec->catfile($mode_workspace, 'rust-tool-resolution');\n"
        b"        write_executable($probe, <<'PROBE');\n")
EXPECTED = (b'use strict;\nuse warnings;\nuse JSON::PP qw(encode_json);\n'
            b'$ENV{PATH} = shift @ARGV;\nrequire FSM::Test::RustParityRuntime;\n'
            b'print encode_json(FSM::Test::RustParityRuntime::run_rust_parity());\n')


def wrapper(source):
    if source.count(SCOPE) != 1:
        raise ValueError('Rust parity source scope must be unique')
    scope = source.split(SCOPE, 1)[1].split(b'\nsubtest ', 1)[0]
    if scope.count(CALL) != 1:
        raise ValueError('exact generated-wrapper call must be unique in its scope')
    tail = scope.split(CALL, 1)[1]
    if tail.count(b'\nPROBE\n') != 1:
        raise ValueError('exact Rust-parity heredoc terminator required')
    body = tail.split(b'\nPROBE\n', 1)[0] + b'\n'
    if body != EXPECTED:
        raise ValueError('Rust-parity wrapper bytes differ from the reviewed program')
    return body


def qualify(source):
    assert wrapper(source) == EXPECTED
    # Changing an earlier unrelated PROBE must not affect the selected wrapper.
    generic = b"write_executable($probe, <<'PROBE');"
    assert source.count(generic) == 5
    changed = source.replace(generic, b'earlier unrelated fixture changed', 1)
    assert wrapper(changed) == EXPECTED
    rejected = []
    for name, changed in [
        ('duplicate_scope', source + SCOPE),
        ('missing_scope', source.replace(SCOPE, b'')),
        ('wrong_basename', source.replace(CALL, CALL.replace(b'rust-tool-resolution', b'other'))),
        ('changed_wrapper', source.replace(EXPECTED, EXPECTED + b'changed\n')),
        ('first_generic_wrapper', source.replace(EXPECTED, b'invalid first-block substitution\n')),
    ]:
        try:
            wrapper(changed)
        except ValueError:
            rejected.append(name)
        else:
            raise AssertionError('accepted altered source scope: ' + name)
    return dict(wrapper_bytes=len(EXPECTED), generic_probe_blocks=5,
                earlier_unrelated_block_independent=True, rejected_controls=rejected)
