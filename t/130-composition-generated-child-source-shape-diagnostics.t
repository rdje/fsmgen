#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

my $tempdir = tempdir(CLEANUP => 1);

my $pipeline = FSM::Pipeline::HDLGenerator->new(
    debug_level => 0,
    target_language => 'systemverilog',
    quiet => 1,
);

subtest 'missing ?fsmc source now says source count is blocked' => sub {
    expect_failure(
        name => 'missing_fsm_source_top',
        body => <<'FSM',
(?top:missing_fsm_source_top
  (?fsmc:child)
)
FSM
        pipeline_regex => qr/Composition top 'missing_fsm_source_top' contains '\?fsmc' child 'child' with 0 FSM source names, .*composition child source count is blocked because the active composition parser currently requires exactly one FSM source name per '\?fsmc'/s,
        cli_regex => qr/composition child source count is blocked because the active composition parser currently requires exactly one FSM source name per '\?fsmc'/s,
        cli_failure_name => 'missing ?fsmc source names',
    );
};

subtest 'nested ?fsmc source payloads now say source shape is blocked' => sub {
    expect_failure(
        name => 'nested_fsm_source_top',
        body => <<'FSM',
(?top:nested_fsm_source_top
  (?fsmc:child
    (opt foo)
  )
)
FSM
        pipeline_regex => qr/Composition top 'nested_fsm_source_top' contains '\?fsmc' child 'child', .*composition child source shape is blocked because the active composition parser currently requires exactly one flat FSM source name per '\?fsmc'/s,
        cli_regex => qr/composition child source shape is blocked because the active composition parser currently requires exactly one flat FSM source name per '\?fsmc'/s,
        cli_failure_name => 'nested ?fsmc source payloads',
    );
};

subtest 'missing ?dtc source now says source count is blocked' => sub {
    expect_failure(
        name => 'missing_dt_source_top',
        body => <<'FSM',
(?top:missing_dt_source_top
  (?dtc:child)
)
FSM
        pipeline_regex => qr/Composition top 'missing_dt_source_top' contains '\?dtc' child 'child' with 0 standalone-DT source names, .*composition child source count is blocked because the active composition parser currently requires exactly one standalone-DT source name per '\?dtc'/s,
        cli_regex => qr/composition child source count is blocked because the active composition parser currently requires exactly one standalone-DT source name per '\?dtc'/s,
        cli_failure_name => 'missing ?dtc source names',
    );
};

subtest 'nested ?dtc source payloads now say source shape is blocked' => sub {
    expect_failure(
        name => 'nested_dt_source_top',
        body => <<'FSM',
(?top:nested_dt_source_top
  (?dtc:child
    (opt foo)
  )
)
FSM
        pipeline_regex => qr/Composition top 'nested_dt_source_top' contains '\?dtc' child 'child', .*composition child source shape is blocked because the active composition parser currently requires exactly one flat standalone-DT source name per '\?dtc'/s,
        cli_regex => qr/composition child source shape is blocked because the active composition parser currently requires exactly one flat standalone-DT source name per '\?dtc'/s,
        cli_failure_name => 'nested ?dtc source payloads',
    );
};

done_testing();

sub expect_failure {
    my (%args) = @_;
    my $composition_path = File::Spec->catfile($tempdir, "$args{name}.fsm");
    my $output_path = File::Spec->catfile($tempdir, "$args{name}.sv");

    write_file($composition_path, $args{body});

    my $exception = eval {
        $pipeline->generate_hdl_from_file($composition_path);
        undef;
    };
    $exception = $@;

    like($exception, $args{pipeline_regex}, "pipeline now says $args{cli_failure_name} are blocked explicitly");
    like($exception, qr/docs\/COMPOSITION_SCOPE\.md/s, "pipeline diagnostic for $args{cli_failure_name} points to the scoped composition doc");
    like($exception, qr/docs\/COMPOSITION_LEGACY_MAPPING\.md/s, "pipeline diagnostic for $args{cli_failure_name} points to the legacy mapping note");

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '-o', $output_path, $composition_path],
    );

    ok(!$success, "CLI rejects $args{cli_failure_name}");
    ok(!-e $output_path, "CLI does not emit output for $args{cli_failure_name}");

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, $args{cli_regex}, "CLI surfaces the blocked diagnostic for $args{cli_failure_name}");
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
