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
    set_fsm_trace_verbosity
    get_fsm_debug_level
    set_fsm_trace_output_file
    clear_fsm_trace_output_file
    get_fsm_trace_output_file
    set_fsm_trace_emojis
    trace_emojis_enabled
    capture_fsm_debug_state
    restore_fsm_debug_state
);
use FSM::Pipeline::HDLGenerator;

my $tmpdir = tempdir(CLEANUP => 1);
my $outer_trace = File::Spec->catfile($tmpdir, 'outer-trace.log');
my $inner_trace = File::Spec->catfile($tmpdir, 'inner-trace.log');

sub slurp_file {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot open '$path': $!";
    my $text = do { local $/; <$fh> };
    close $fh;
    return $text;
}

set_fsm_trace_verbosity('debug');
set_fsm_trace_emojis(0);
set_fsm_trace_output_file($outer_trace);
fsm_debug('outer before snapshot', 1);

my $saved_state = capture_fsm_debug_state();
set_fsm_trace_output_file($inner_trace);
fsm_debug('inner while rebound', 1);
restore_fsm_debug_state($saved_state);
fsm_debug('outer after restore', 1);
clear_fsm_trace_output_file();

my $outer_text = slurp_file($outer_trace);
my $inner_text = slurp_file($inner_trace);

like($outer_text, qr/outer before snapshot/, 'outer trace keeps the pre-snapshot line');
like($outer_text, qr/outer after restore/, 'outer trace keeps the post-restore line');
unlike($outer_text, qr/inner while rebound/, 'outer trace excludes the temporary rebound line');
like($inner_text, qr/inner while rebound/, 'inner trace captures the temporary rebound line');
is(get_fsm_trace_output_file(), undef, 'trace output file is cleared after cleanup');

set_fsm_trace_verbosity('none');
set_fsm_trace_emojis(0);
set_fsm_trace_output_file($outer_trace);

my $pipeline = FSM::Pipeline::HDLGenerator->new(
    debug_level => 2,
    target_language => 'systemverilog',
);

is(get_fsm_debug_level(), 0, 'HDLGenerator->new does not leak debug level globally');
is(get_fsm_trace_output_file(), $outer_trace, 'HDLGenerator->new preserves the caller trace sink');
ok(!trace_emojis_enabled(), 'HDLGenerator->new preserves the caller emoji setting');

my $pre_generate_text = slurp_file($outer_trace);
my $pre_generate_len = length($pre_generate_text);

my $result = $pipeline->generate_hdl_from_file('fsm/trial_0.fsm');
ok($result->{hdl_code}, 'generation succeeds under scoped debug state');
is(get_fsm_debug_level(), 0, 'generate_hdl_from_file restores the caller debug level');
is(get_fsm_trace_output_file(), $outer_trace, 'generate_hdl_from_file restores the caller trace sink');
ok(!trace_emojis_enabled(), 'generate_hdl_from_file restores the caller emoji setting');

my $post_generate_text = slurp_file($outer_trace);
ok(length($post_generate_text) > $pre_generate_len, 'scoped pipeline debug emits trace into the caller sink');

my $post_generate_len = length($post_generate_text);
fsm_debug('outer quiet after generate', 1);
my $after_quiet_text = slurp_file($outer_trace);
is(length($after_quiet_text), $post_generate_len, 'outer quiet state stays in effect after generation');

clear_fsm_trace_output_file();
set_fsm_trace_verbosity('none');
set_fsm_trace_emojis(1);

done_testing();
