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

my $tempdir = tempdir(CLEANUP => 1);

subtest "compact ':=' directives register explicit reset metadata" => sub {
    my ($module, $adapter) = parse_success(<<'FSM');
(?fsm:init_directive_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (:= tester_reset=1)
  (idle
    (A = 1)
  )
)
FSM

    my @state_names = map { $_->name } @{$module->states};
    is_deeply(\@state_names, ['idle'], "':=' directive no longer creates a fake state");

    my $signal = $adapter->{signal_manager}->get_signal('tester_reset');
    ok($signal, "':=' directive registers the target signal");
    is($signal->get_attribute('reset_value'), '1', "':=' directive stores explicit reset metadata");
    is($signal->{initial_value}, '1', "':=' directive also preserves legacy initial_value metadata");
};

subtest 'single-token malformed DT actions no longer disappear silently' => sub {
    my $error = parse_failure(<<'FSM');
(?fsm:broken_single_token_action
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-dt
    (BROKEN)
    (A = 1)
  )
)
FSM

    like($error, qr/Unsupported action form '\(BROKEN\)'/, 'single-token malformed action gets a targeted diagnostic');
};

subtest 'empty guarded blocks no longer disappear silently' => sub {
    my $error = parse_failure(<<'FSM');
(?fsm:broken_empty_guard
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-dt
    (<req)
    (A = 1)
  )
)
FSM

    like($error, qr/Malformed guarded block '<req'/, 'empty guarded block gets a targeted diagnostic');
};

subtest "malformed ':=' directives fail explicitly" => sub {
    my $error = parse_failure(<<'FSM');
(?fsm:broken_init_directive
  (+system
    (clock clk)
    (sreset rstn)
  )
  (:= BROKEN)
  (idle
    (A = 1)
  )
)
FSM

    like($error, qr/Unsupported ':=' directive 'BROKEN'/, "malformed ':=' directive gets a targeted diagnostic");
};

done_testing();

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

sub parse_success {
    my ($fsm_text) = @_;
    my $result = parse_fsm_with_adapter($fsm_text);
    ok($result->{module}, 'parse succeeded as expected');
    return @{$result}{qw(module adapter)};
}

sub parse_fsm_with_adapter {
    my ($fsm_text) = @_;
    my $fsm_path = File::Spec->catfile($tempdir, "malformed_" . int(rand(1_000_000)) . ".fsm");
    write_file($fsm_path, $fsm_text);

    my $raw_ast = Lispish::multi($fsm_path);
    my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
    my $module = $adapter->parse_fsm($raw_ast);
    return {
        module => $module,
        adapter => $adapter,
    };
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
