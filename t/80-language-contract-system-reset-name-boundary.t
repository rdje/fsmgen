#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::Pipeline::HDLGenerator;

my $tempdir = tempdir(CLEANUP => 1);

subtest 'canonical +system reset names are accepted with explicit reset policy metadata' => sub {
    my $sync_module = parse_success(<<'FSM');
(?fsm:good_sync_reset_name
  (+system
    (clock clk)
    (sreset reset)
  )
  (-dt
    (A <= 1)
  )
)
FSM

    my $sync_contract = $sync_module->effective_system_contract;
    is($sync_contract->{reset}, 'reset', 'sreset accepts an active-high-looking reset name');
    is($sync_contract->{reset_kind}, 'sync', 'sreset records synchronous reset kind');
    is($sync_contract->{reset_active_level}, 1, 'sreset records active-high reset polarity');

    my $async_module = parse_success(<<'FSM');
(?fsm:good_async_reset_name
  (+system
    (clock clk)
    (areset rst_n)
  )
  (-dt
    (A <= 1)
  )
)
FSM

    my $async_contract = $async_module->effective_system_contract;
    is($async_contract->{reset}, 'rst_n', 'areset accepts an active-low-looking reset name');
    is($async_contract->{reset_kind}, 'async', 'areset records asynchronous reset kind');
    is($async_contract->{reset_active_level}, 0, 'areset records active-low reset polarity');
};

subtest 'pipeline and CLI honor canonical reset policy in emitted HDL' => sub {
    assert_pipeline_and_cli_accept(
        'good_sync_reset_name_cli.fsm',
        <<'FSM',
(?fsm:good_sync_reset_name_cli
  (+system
    (clock clk)
    (sreset reset)
  )
  (-dt
    (A <= 1)
  )
)
FSM
        qr/always_ff\s*@\(posedge\s+clk\).*if\s*\(reset\)/s,
        'canonical synchronous active-high reset',
    );

    assert_pipeline_and_cli_accept(
        'good_async_reset_name_cli.fsm',
        <<'FSM',
(?fsm:good_async_reset_name_cli
  (+system
    (clock clk)
    (areset rst_n)
  )
  (-dt
    (A <= 1)
  )
)
FSM
        qr/always_ff\s*@\(posedge\s+clk\s+or\s+negedge\s+rst_n\).*if\s*\(!rst_n\)/s,
        'canonical asynchronous active-low reset',
    );
};

subtest 'malformed +system reset names are still rejected explicitly' => sub {
    my $sync_error = parse_failure(<<'FSM');
(?fsm:bad_sync_reset_identifier
  (+system
    (clock clk)
    (sreset reset-name)
  )
  (-dt
    (A <= 1)
  )
)
FSM

    like($sync_error, qr/Unsupported '\+system' reset name 'reset-name'/, 'bad sreset identifier gets a targeted diagnostic');

    my $async_error = parse_failure(<<'FSM');
(?fsm:bad_async_reset_identifier
  (+system
    (clock clk)
    (areset rst-n)
  )
  (-dt
    (A <= 1)
  )
)
FSM

    like($async_error, qr/Unsupported '\+system' reset name 'rst-n'/, 'bad areset identifier gets a targeted diagnostic');
};

done_testing();

sub parse_success {
    my ($fsm_text) = @_;
    my $fsm_path = write_fsm('parse_success_' . int(rand(1_000_000)) . '.fsm', $fsm_text);
    my $raw_ast = Lispish::multi($fsm_path);
    my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
    return $adapter->parse_fsm($raw_ast);
}

sub parse_failure {
    my ($fsm_text) = @_;
    my $fsm_path = write_fsm('parse_failure_' . int(rand(1_000_000)) . '.fsm', $fsm_text);
    my $raw_ast = Lispish::multi($fsm_path);
    my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);

    my $error = eval {
        $adapter->parse_fsm($raw_ast);
        undef;
    };
    $error = $@ if !$error;
    ok($error, 'parse failed as expected');
    return $error;
}

sub assert_pipeline_and_cli_accept {
    my ($filename, $fsm_text, $hdl_re, $label) = @_;

    my $fsm_path = write_fsm($filename, $fsm_text);
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug => 0,
    );

    my $result = $pipeline->generate_hdl_from_file($fsm_path);
    like($result->{hdl_code}, $hdl_re, "pipeline emits $label behavior");

    my $out_path = File::Spec->catfile($tempdir, $filename . '.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $out_path, '--quiet', $fsm_path],
    );

    ok($success, "CLI accepts $label");
    ok(-e $out_path, "CLI emits output for $label");
    like(slurp($out_path), $hdl_re, "CLI output emits $label behavior");
}

sub write_fsm {
    my ($filename, $content) = @_;
    my $path = File::Spec->catfile($tempdir, $filename);
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
    return $path;
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot open $path for read: $!";
    local $/;
    my $content = <$fh>;
    close $fh or die "Cannot close $path: $!";
    return $content;
}
