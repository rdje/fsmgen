"""Public contract clauses selected before any native frame interpretation."""
CLAUSES = {
    'caller_call_target': ('caller', '$subroutine is the function that the caller called (rather than the function containing the caller).'),
    'caller_block_eval': ('caller', 'for an "eval BLOCK" statement, $subroutine is "(eval)", but $evaltext is undefined.'),
    'caller_require_use': ('caller', '$is_require is true if the frame is created by a "require" or "use" statement'),
    'caller_visible_frames': ('caller', 'the only types of call frames that are visible are subroutine calls and "eval".'),
    'caller_argument_limit': ('caller', 'Be aware that setting @DB::args is *best effort*, intended for debugging or generating backtraces, and should not be relied upon.'),
    'caller_alias_limit': ('caller', 'Perl does not take a copy of @_, so @DB::args will contain modifications the subroutine makes to @_ or its contents, not the original values at call time.'),
    'eval_failure': ('eval', '"eval" returns "undef" in scalar context, or an empty list in list context, and $@ is set to the error message.'),
    'eval_success': ('eval', 'If there was no error, $@ is set to the empty string.'),
    'carp_long_trace': ('Carp', 'In the case of "cluck()" and "confess()", that context is a summary of every call in the call-stack; "longmess()" returns the contents of the error message.'),
    'carp_controls': ('Carp', 'You can also alter the way the output and logic of "Carp" works, by changing some global variables in the "Carp" namespace.'),
    'more_subtest': ('Test::More', 'subtest $name => \\&code, @args;'),
    'more_arguments': ('Test::More', 'Extra arguments given to "subtest" are passed to the callback.'),
    'builder_subtest': ('Test::Builder', '$builder->subtest($name, \\&subtests, @args);'),
    'builder_arguments': ('Test::Builder', '"subtest" also, and optionally, accepts arguments which will be passed to the subtests reference.'),
}


def derive(record, require):
    docs = {name: ' '.join(row['stdout'].split()) for name, row in record['commands'].items()}
    result = {}
    for role, (document, clause) in CLAUSES.items():
        require(clause in docs[document], 'complete selected public contract clause: ' + role)
        result[role] = dict(document=document, clause=clause,
            qualification='dated public-interface contract only; original native/historical interpretation remains separate')
    return result
