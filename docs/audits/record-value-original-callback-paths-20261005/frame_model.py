"""Original compiled callback/eval/refusal/helper-wrapper source roles."""
CONTRACTS = {
    'helper_parameters': 'my ($run, $pattern, $name) = @_;',
    'callback_eval': 'my $ok = eval { $run->(); 1 };',
    'helper_lookup': "my $helper = main->can('refuses');",
    'helper_wrapper': 'local *main::refuses = sub {',
    'wrapper_parameters': 'my ($operation, $pattern, $label) = @_;',
    'helper_delegate': 'my $returned = $helper->(@_);',
    'callback_body_delegate': 'return $body->(@_);',
}


def derive(helper, phases):
    pattern = helper['pattern']
    # Every independently authored pattern in this exact corpus uses a plain
    # unmodified qr literal. Its source catalog preserves the whole default
    # stringification. Header display is a separate finite projection.
    if not (pattern.startswith('(?^:') and pattern.endswith(')')):
        raise ValueError('finite source callback regex declaration')
    body = pattern[4:-1]
    if '(' in body or ')' in body:
        raise ValueError('finite source callback regex body profile')
    arguments = [
        {'role': 'original_compiled_parameterless_callback', 'kind': 'reference', 'reference_kind': 'CODE'},
        {'role': 'source_refusal_pattern', 'kind': 'regex_source', 'source_pattern': pattern, 'display_body': body},
        {'role': 'source_helper_label', 'kind': 'scalar', 'value': helper['label']},
    ]
    path = [
        {'function': 'main::__ANON__', 'call_site': 'compiled_original_parameterless_callback', 'arguments': []},
        {'function': 'eval {...}', 'call_site': 'original_refuses_callback_eval', 'arguments': []},
        {'function': 'main::refuses', 'call_site': 'compiled_original_helper', 'arguments': arguments},
        {'function': 'main::__ANON__', 'call_site': 'installed_observer_helper_wrapper', 'arguments': arguments},
    ]
    return {'phases': phases, 'paths': [path for _ in range(phases)]}
