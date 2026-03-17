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

subtest 'wrong-kind external ?fsmc child now says child-source realization is blocked and points to ?dtc' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'wrong_fsmc_kind_top.fsm');
    my $child_path = File::Spec->catfile($tempdir, 'route_src.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'wrong_fsmc_kind_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:wrong_fsmc_kind_top
  (?ports:public_io
    data_in<8
    route_data>8
  )
  (?fsmc:router route_src)
)
FSM
    );

    write_file(
        $child_path,
        <<'FSM'
(?dt:route_src
  (-route
    (route_data> = data_in)
  )
  (+size
    (data_in 8)
    (route_data 8)
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $exception = eval {
        $pipeline->generate_hdl_from_file($composition_path);
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/resolves '\?fsmc' child 'route_src' to '.*route_src\.fsm', .*child-source realization is blocked because that resolved file is not an active FSM child source \(detected root '\?dt:route_src'\).*Use '\?dtc' for standalone-DT children instead/s,
        'pipeline now says wrong-kind external ?fsmc child realization is blocked and points to ?dtc',
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI rejects wrong-kind external ?fsmc child sources');
    ok(!-e $output_path, 'CLI does not emit output for wrong-kind external ?fsmc child sources');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like(
        $combined_output,
        qr/child-source realization is blocked because that resolved file is not an active FSM child source .*Use '\?dtc' for standalone-DT children instead/s,
        'CLI surfaces the blocked wrong-kind ?fsmc child diagnostic',
    );
};

subtest 'wrong-kind external ?dtc child now says child-source realization is blocked and points to ?fsmc' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'wrong_dtc_kind_top.fsm');
    my $child_path = File::Spec->catfile($tempdir, 'child_src.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:wrong_dtc_kind_top
  (?ports:public_io
    clk
    rst_n
    output_data>8
  )
  (?dtc:child child_src)
)
FSM
    );

    write_file(
        $child_path,
        <<'FSM'
(?fsm:child_src
  (-state0
    (output_data> <= 8'1)
  )
  (+size
    (output_data 8)
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $exception = eval {
        $pipeline->generate_hdl_from_file($composition_path);
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/resolves '\?dtc' child 'child_src' to '.*child_src\.fsm', .*child-source realization is blocked because that resolved file is not an active standalone-DT child source \(detected root '\?fsm:child_src'\).*Use '\?fsmc' for FSM children instead/s,
        'pipeline now says wrong-kind external ?dtc child realization is blocked and points to ?fsmc',
    );
};

subtest 'missing external generated child now says child-source resolution is blocked' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'missing_child_top.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'missing_child_top.sv');

    write_file(
        $composition_path,
        <<'FSM'
(?top:missing_child_top
  (?ports:public_io
    clk
    rst_n
    output_data>8
  )
  (?fsmc:child missing_src)
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $exception = eval {
        $pipeline->generate_hdl_from_file($composition_path);
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/declares '\?fsmc' child 'missing_src', .*child-source resolution is blocked because no active child FSM source was found either embedded in the same file or in an external '\.fsm' file.*Search roots: .*Searched locations: /s,
        'pipeline now says missing external generated child resolution is blocked',
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '-o', $output_path, $composition_path],
    );

    ok(!$success, 'CLI rejects missing external generated child sources');
    ok(!-e $output_path, 'CLI does not emit output for missing external generated child sources');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like(
        $combined_output,
        qr/child-source resolution is blocked because no active child FSM source was found either embedded in the same file or in an external '\.fsm' file/s,
        'CLI surfaces the blocked missing-child resolution diagnostic',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
