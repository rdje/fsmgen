#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw/ tempdir /;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;

my $tempdir = tempdir(CLEANUP => 1);

subtest 'conventional +system section with sreset is now regression-backed explicitly' => sub {
    my ($adapter, $fsm_module) = parse_fsm_with_adapter(<<'FSM');
(?fsm:system_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (A 1)
    (B 1)
  )
  (-dt
    (A = B)
  )
)
FSM

    is($fsm_module->attributes->{system_contract}{clock}, 'clk', '+system stores the conventional clock name');
    is($fsm_module->attributes->{system_contract}{reset}, 'rstn', '+system stores the conventional reset name');
    is($fsm_module->attributes->{system_contract}{reset_keyword}, 'sreset', '+system stores the accepted reset keyword');
    is($fsm_module->clock_domains->{default}, 'clk', '+system seeds the default clock domain');
    is($fsm_module->reset_domains->{default}, 'rstn', '+system seeds the default reset domain');

    my $clock_signal = $adapter->{signal_manager}->get_signal('clk');
    my $reset_signal = $adapter->{signal_manager}->get_signal('rstn');
    ok($clock_signal, 'clk is registered as a system signal');
    ok($reset_signal, 'rstn is registered as a system signal');
    ok($clock_signal && $clock_signal->is_clock, 'clk is typed as a clock signal');
    ok($reset_signal && $reset_signal->is_reset, 'rstn is typed as a reset signal');

    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
    like($hdl, qr/module\s+system_contract\b/s, 'system-contract FSM still generates HDL through the active backend');
};

subtest 'conventional +system section also accepts the legacy asreset spelling' => sub {
    my ($adapter, $fsm_module) = parse_fsm_with_adapter(<<'FSM');
(?fsm:system_contract_async_keyword
  (+system
    (clock clk)
    (asreset rstn)
  )
  (-dt
    (A = 1)
  )
)
FSM

    is($fsm_module->attributes->{system_contract}{clock}, 'clk', 'asreset form keeps the conventional clock name');
    is($fsm_module->attributes->{system_contract}{reset}, 'rstn', 'asreset form keeps the conventional reset name');
    is($fsm_module->attributes->{system_contract}{reset_keyword}, 'asreset', 'asreset form records the accepted reset keyword');
    ok($adapter->{signal_manager}->get_signal('clk')->is_clock, 'asreset form still registers clk as a clock signal');
    ok($adapter->{signal_manager}->get_signal('rstn')->is_reset, 'asreset form still registers rstn as a reset signal');
};

subtest 'non-canonical +system clock names are accepted as identifiers' => sub {
    my ($adapter, $fsm_module) = parse_fsm_with_adapter(<<'FSM');
(?fsm:custom_clock_name
  (+system
    (clock core_clk)
    (sreset rstn)
  )
  (-dt
    (A = 1)
  )
)
FSM

    is($fsm_module->attributes->{system_contract}{clock}, 'core_clk', '+system stores the authored clock name');
    is($fsm_module->clock_domains->{default}, 'core_clk', '+system seeds the default clock domain from the authored clock name');
    ok($adapter->{signal_manager}->get_signal('core_clk')->is_clock, 'authored clock name is registered as a clock signal');
};

subtest 'malformed +system clock names are rejected explicitly' => sub {
    my $error = parse_failure(<<'FSM');
(?fsm:bad_clock_identifier
  (+system
    (clock core-clk)
    (sreset rstn)
  )
  (-dt
    (A = 1)
  )
)
FSM

    like($error, qr/Unsupported '\+system' clock name 'core-clk'/, 'bad clock identifier gets a targeted diagnostic');
};

subtest 'conventional +system section also accepts the canonical areset spelling' => sub {
    my ($adapter, $fsm_module) = parse_fsm_with_adapter(<<'FSM');
(?fsm:system_contract_areset_keyword
  (+system
    (clock clk)
    (areset rst_n)
  )
  (-dt
    (A = 1)
  )
)
FSM

    is($fsm_module->attributes->{system_contract}{clock}, 'clk', 'areset form keeps the conventional clock name');
    is($fsm_module->attributes->{system_contract}{reset}, 'rst_n', 'areset form keeps the canonical active-low reset name');
    is($fsm_module->attributes->{system_contract}{reset_keyword}, 'areset', 'areset form records the canonical reset keyword');
    is($fsm_module->attributes->{system_contract}{reset_kind}, 'async', 'areset form records asynchronous reset semantics');
    is($fsm_module->attributes->{system_contract}{reset_active_level}, 0, 'areset form records active-low reset semantics');
    ok($adapter->{signal_manager}->get_signal('clk')->is_clock, 'areset form still registers clk as a clock signal');
    ok($adapter->{signal_manager}->get_signal('rst_n')->is_reset, 'areset form still registers rst_n as a reset signal');
};

subtest 'incomplete +system sections are rejected explicitly' => sub {
    my $error = parse_failure(<<'FSM');
(?fsm:incomplete_system
  (+system
    (clock clk)
  )
  (-dt
    (A = 1)
  )
)
FSM

    like($error, qr/Incomplete '\+system' section/, 'incomplete +system section gets a targeted diagnostic');
};

done_testing();

sub parse_fsm_with_adapter {
    my ($fsm_text) = @_;
    my $fsm_path = File::Spec->catfile($tempdir, "system_" . int(rand(1_000_000)) . ".fsm");
    write_file($fsm_path, $fsm_text);

    my $raw_ast = Lispish::multi($fsm_path);
    my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
    my $fsm_module = $adapter->parse_fsm($raw_ast);
    return ($adapter, $fsm_module);
}

sub parse_failure {
    my ($fsm_text) = @_;
    my $error;
    eval {
        parse_fsm_with_adapter($fsm_text);
        1;
    } or do {
        $error = $@;
    };
    ok($error, 'parse failed as expected');
    return $error;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
