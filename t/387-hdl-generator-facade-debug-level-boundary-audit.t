#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Debug qw(
    clear_fsm_trace_output_file
    get_fsm_debug_level
    get_fsm_trace_output_file
    set_fsm_trace_emojis
    set_fsm_trace_output_file
    set_fsm_trace_verbosity
);
use FSM::Pipeline::HDLGenerator;
use FSM::Support::HDLGeneratorFacadeContract qw(
    build_hdl_generator_facade_contract
    hdl_generator_facade_public_constructor_option_names
);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');

subtest 'facade contract advertises debug_level as a public constructor option' => sub {
    my $contract = build_hdl_generator_facade_contract();

    ok(
        contains_value(
            $contract->{public_constructor_option_names},
            'debug_level',
        ),
        'emitted facade contract includes debug_level in public constructor options',
    );
    ok(
        contains_value(
            hdl_generator_facade_public_constructor_option_names(),
            'debug_level',
        ),
        'builder-owned public constructor list includes debug_level',
    );
    ok(
        contains_value(
            $contract->{constructor_option_family_map}{core_constructor_option_names},
            'debug_level',
        ),
        'grouped core constructor family includes debug_level',
    );
};

subtest 'facade debug_level option controls scoped trace emission thresholds' => sub {
    my $direct_path = repo_file('t/corpus/direct_sreset_active_high.fsm');

    my ($quiet_result, $quiet_trace) = run_facade_with_trace(
        debug_level => 0,
        source_path => $direct_path,
    );
    like(
        $quiet_result->{hdl_code},
        qr/\bmodule\s+direct_sreset_active_high\b/s,
        'debug_level 0 still generates the expected direct module',
    );
    is($quiet_trace, '', 'debug_level 0 emits no trace even when a caller trace sink is bound');

    my ($medium_result, $medium_trace) = run_facade_with_trace(
        debug_level => 2,
        source_path => $direct_path,
    );
    like(
        $medium_result->{hdl_code},
        qr/\bmodule\s+direct_sreset_active_high\b/s,
        'debug_level 2 still generates the expected direct module',
    );
    like($medium_trace, qr/\[TRACE\]\[LOW\]/, 'debug_level 2 emits low-detail trace lines');
    like($medium_trace, qr/\[TRACE\]\[MEDIUM\]/, 'debug_level 2 emits medium-detail trace lines');
    unlike($medium_trace, qr/\[TRACE\]\[HIGH\]/, 'debug_level 2 does not emit high-detail trace lines');
    unlike($medium_trace, qr/Full raw AST dump/, 'debug_level 2 does not emit the high-detail raw AST dump');

    my ($debug_result, $debug_trace) = run_facade_with_trace(
        debug_level => 4,
        source_path => $direct_path,
    );
    like(
        $debug_result->{hdl_code},
        qr/\bmodule\s+direct_sreset_active_high\b/s,
        'debug_level 4 still generates the expected direct module',
    );
    like($debug_trace, qr/\[TRACE\]\[HIGH\]/, 'debug_level 4 emits high-detail trace lines');
    like($debug_trace, qr/Full raw AST dump/, 'debug_level 4 emits the high-detail raw AST dump');
};

subtest 'facade debug_level trace scope restores caller debug state after generation' => sub {
    my $direct_path = repo_file('t/corpus/direct_sreset_active_high.fsm');
    my ($result) = run_facade_with_trace(
        debug_level => 4,
        source_path => $direct_path,
    );

    ok($result->{hdl_code}, 'generation succeeds under scoped debug level');
    is(get_fsm_debug_level(), 0, 'facade debug_level scope restores global debug level');
    is(get_fsm_trace_output_file(), undef, 'facade debug_level audit cleanup clears the caller trace sink');
};

done_testing();

sub repo_file {
    my ($relpath) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relpath);
}

sub contains_value {
    my ($values, $wanted) = @_;
    return 0 unless ref($values) eq 'ARRAY';

    for my $value (@{$values}) {
        return 1 if defined($value) && $value eq $wanted;
    }

    return 0;
}

sub run_facade_with_trace {
    my (%args) = @_;
    my $debug_level = $args{debug_level};
    my $source_path = $args{source_path};
    my $tempdir = tempdir(CLEANUP => 1);
    my $trace_path = File::Spec->catfile($tempdir, "debug-level-$debug_level.trace");

    set_fsm_trace_verbosity('none');
    set_fsm_trace_emojis(0);
    set_fsm_trace_output_file($trace_path);

    my $result;
    my $ok = eval {
        my $pipeline = FSM::Pipeline::HDLGenerator->new(
            debug_level => $debug_level,
            target_language => 'systemverilog',
            quiet => 1,
        );
        $result = $pipeline->generate_hdl_from_file($source_path);
        1;
    };
    my $error = $@ unless $ok;

    clear_fsm_trace_output_file();
    set_fsm_trace_verbosity('none');
    set_fsm_trace_emojis(1);

    die $error if !$ok;
    return ($result, slurp_file($trace_path));
}

sub slurp_file {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot open $path: $!";
    my $text = do { local $/; <$fh> };
    close $fh or die "Cannot close $path: $!";
    return $text;
}
