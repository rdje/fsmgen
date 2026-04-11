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

subtest 'nested ?rtl payloads now keep parameter override syntax blocked' => sub {
    expect_failure(
        name => 'nested_rtl_payload_top',
        body => <<'FSM',
(?top:nested_rtl_payload_top
  (?rtl:u_uart
    (module uart_tx)
    (params
      (WIDTH 8)
    )
  )
)
FSM
        pipeline_regex => qr/Composition top 'nested_rtl_payload_top' contains '\?rtl' child 'u_uart', .*composition external-RTL child source shape is blocked because the active composition parser currently accepts either '\(\?rtl:module\)' or '\(\?rtl:instance module\)' as the flat RTL child declaration form\. Parameter\/generic override blocks are planned as a separate semantic instantiation contract and are not accepted in '\?rtl' child payloads yet/s,
        cli_regex => qr/Parameter\/generic override blocks are planned as a separate semantic instantiation contract and are not accepted in '\?rtl' child payloads yet/s,
        cli_failure_name => 'nested ?rtl parameter override payloads',
    );
};

subtest 'multi-token ?rtl aliases now say source count is blocked' => sub {
    expect_failure(
        name => 'multi_token_rtl_alias_top',
        body => <<'FSM',
(?top:multi_token_rtl_alias_top
  (?rtl:u_uart uart_tx uart_rx)
)
FSM
        pipeline_regex => qr/Composition top 'multi_token_rtl_alias_top' contains '\?rtl' child 'u_uart' with 2 RTL module references, .*composition external-RTL child source count is blocked because the active composition parser currently accepts exactly one flat RTL module name after '\?rtl:instance' when an explicit instance name is needed/s,
        cli_regex => qr/composition external-RTL child source count is blocked because the active composition parser currently accepts exactly one flat RTL module name after '\?rtl:instance' when an explicit instance name is needed/s,
        cli_failure_name => 'multi-token ?rtl aliases',
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
