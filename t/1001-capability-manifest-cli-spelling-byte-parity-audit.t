#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use IPC::Cmd qw(run);

subtest 'capability manifest CLI spellings emit identical bytes' => sub {
    my ($primary_success, $primary_error, $primary_full, $primary_stdout, $primary_stderr) = run(
        command => ['./bin/fsmgen', '--capability-manifest'],
    );
    my ($alias_success, $alias_error, $alias_full, $alias_stdout, $alias_stderr) = run(
        command => ['./bin/fsmgen', '--emit-capability-manifest'],
    );

    ok($primary_success, 'primary capability manifest command succeeds')
        or diag($primary_error || join('', @{$primary_full || []}));
    ok($alias_success, 'alias capability manifest command succeeds')
        or diag($alias_error || join('', @{$alias_full || []}));
    is(join('', @{$primary_stderr || []}), '', 'primary command emits no stderr');
    is(join('', @{$alias_stderr || []}), '', 'alias command emits no stderr');
    is(join('', @{$alias_stdout || []}), join('', @{$primary_stdout || []}), 'manifest CLI spellings emit identical stdout bytes');
};

done_testing();
