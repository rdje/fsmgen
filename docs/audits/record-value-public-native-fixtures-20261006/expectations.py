"""Source-selected public boundaries, fixed before any native observations."""
ROLES = {
    'more-empty': dict(body='more_empty', arguments=[], prefix=['PublicFixture::frames', 'PublicFixture::leaf', 'PublicFixture::more_empty']),
    'more-extra': dict(body='more_extra', arguments=['public-argument-A', 'public-argument-B'], prefix=['PublicFixture::frames', 'PublicFixture::leaf', 'PublicFixture::more_extra']),
    'builder-extra': dict(body='builder_extra', arguments=['public-builder-A'], prefix=['PublicFixture::frames', 'PublicFixture::leaf', 'PublicFixture::builder_extra']),
    'eval-success': dict(value='public-eval-result', error='', prefix=['PublicFixture::frames', 'PublicFixture::leaf', '(eval)', 'PublicFixture::eval_success']),
    'eval-failure': dict(value=None, error='public-eval-failure\n', prefix=['PublicFixture::frames', 'PublicFixture::leaf', '(eval)', 'PublicFixture::eval_failure']),
    'do-load': dict(body='public-load-body', error='', prefix=['PublicFixture::frames', 'PublicFixture::leaf'], enclosing='PublicFixture::do_load'),
    'require-load': dict(body='public-load-body', error='', prefix=['PublicFixture::frames', 'PublicFixture::leaf'], enclosing='PublicFixture::require_load'),
    'trace-full': dict(body='public-trace-message', frames=['PublicFixture::trace_outer'], visible=['public-trace-A', 'public-trace-B']),
    'trace-suppressed': dict(body='public-trace-message', frames=['PublicFixture::trace_outer'], absent=['public-trace-A', 'public-trace-B']),
}
EXTRA_CLAUSES = {
    'public_builder_accessor': ('Test::More', 'my $test_builder = Test::More->builder;'),
    'public_output_handle': ('Test::Builder', 'They take either an open $filehandle, a $filename to open and write to or a $scalar reference to append to.'),
    'trace_full_arguments': ('Carp', 'Use a false value to show all arguments to a function call.'),
    'trace_suppress_arguments': ('Carp', "To suppress all arguments, use -1 or '0 but true'."),
    'trace_full_argument_length': ('Carp', 'Use a value of 0 to show the full length of the argument.'),
}


def check_clauses(profile, require):
    docs = {k: ' '.join(v['stdout'].split()) for k, v in profile['commands'].items()}
    for role, (document, clause) in EXTRA_CLAUSES.items():
        require(clause in docs[document], 'selected additional public fixture clause: ' + role)
    return EXTRA_CLAUSES
