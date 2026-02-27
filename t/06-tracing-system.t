#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw/tempdir/;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Debug qw(
    fsm_debug
    fsm_trace_enter
    fsm_trace_exit
    fsm_trace_decision
    set_fsm_trace_verbosity
    get_fsm_trace_verbosity
    set_fsm_trace_output_file
    clear_fsm_trace_output_file
    set_fsm_trace_emojis
    debug_enabled
);

my $tmpdir = tempdir(CLEANUP => 1);
my $trace_file = File::Spec->catfile($tmpdir, 'trace.log');

set_fsm_trace_verbosity('debug');
set_fsm_trace_emojis(0);
set_fsm_trace_output_file($trace_file);

emit_sample_trace();

clear_fsm_trace_output_file();

open my $fh, '<', $trace_file or die "Cannot open trace file '$trace_file': $!";
my $trace_text = do { local $/; <$fh> };
close $fh;

ok(length($trace_text) > 0, 'trace file captured output');
like($trace_text, qr/\[TRACE\]\[[A-Z]+\]\[[^:\]]+:[^:\]]+\(\):\d+\]\[ENTER\]/, 'trace line includes file/function/line metadata for ENTER');
like($trace_text, qr/\[TRACE\]\[[A-Z]+\]\[[^:\]]+:[^:\]]+\(\):\d+\]\[INFO\]/, 'trace line includes file/function/line metadata for INFO');
like($trace_text, qr/\[TRACE\]\[[A-Z]+\]\[[^:\]]+:[^:\]]+\(\):\d+\]\[DECISION\]\s+decision=TRUE/, 'trace decision line is emitted');
like($trace_text, qr/\[TRACE\]\[[A-Z]+\]\[[^:\]]+:[^:\]]+\(\):\d+\]\[EXIT\]/, 'trace line includes file/function/line metadata for EXIT');

is(get_fsm_trace_verbosity(), 'debug', 'named verbosity getter returns debug');
ok(debug_enabled(), 'debug/tracing enabled at debug verbosity');

set_fsm_trace_verbosity('none');
ok(!debug_enabled(), 'debug/tracing disabled at none verbosity');

done_testing();

sub emit_sample_trace {
    fsm_trace_enter('sample trace scope', 2);
    fsm_debug('sample trace body', 2);
    fsm_trace_decision(1, 'sample decision path', 2);
    fsm_trace_exit('sample trace scope', 2);
}
