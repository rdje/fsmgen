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

subtest 'bare symbolic test selectors are rejected explicitly' => sub {
    my $error = parse_failure(<<'FSM');
(?fsm:bad_test_selector_symbol
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (MODE 2)
    (A 1)
  )
  (s0
    (?MODE
      (BUSY
        (A = 1)
      )
    )
  )
)
FSM

    like($error, qr/Malformed test selector 'BUSY'/, 'bare symbolic selector gets a targeted diagnostic');
};

subtest 'bare numeric test selectors are rejected explicitly' => sub {
    my $error = parse_failure(<<'FSM');
(?fsm:bad_test_selector_numeric
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (MODE 2)
    (A 1)
  )
  (s0
    (?MODE
      (0
        (A = 1)
      )
    )
  )
)
FSM

    like($error, qr/Malformed test selector '0'/, 'bare numeric selector gets a targeted diagnostic');
};

subtest 'operator-prefixed equality selectors remain supported' => sub {
    my $fsm_path = write_fsm('good_test_selector_symbol.fsm', <<'FSM');
(?fsm:good_test_selector_symbol
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (MODE 2)
    (OTHER 2)
    (A 1)
  )
  (s0
    (?MODE
      (=OTHER
        (A = 1)
      )
    )
  )
)
FSM

    my $raw_ast = Lispish::multi($fsm_path);
    my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
    my $fsm_module = $adapter->parse_fsm($raw_ast);
    ok($fsm_module, 'operator-prefixed symbolic equality selector parses successfully');

    my $phase1_gen = FSM::HDL::FlattenedDT->new(debug => 0);
    $phase1_gen->{enable_graph}->set_fsm_module_reference($fsm_module);
    $phase1_gen->{orchestrator}->flatten_all_decision_trees($fsm_module);

    my ($assignment) = grep { $_->{dt} eq 's0' && $_->{rhs} eq '1' } @{$phase1_gen->{lhs_assignments}->{A} || []};
    ok($assignment, 'captured assignments include the =OTHER selector branch');
    is(
        $assignment->{conditions_ast}->to_systemverilog,
        'MODE == OTHER',
        '=OTHER selector lowers to equality against the named token'
    );

    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
    like($hdl, qr/\bMODE\s*==\s*OTHER\b/, 'generated HDL contains the =OTHER selector comparison');
};

done_testing();

sub parse_failure {
    my ($fsm_text) = @_;
    my $error = eval {
        my $path = write_fsm('parse_failure_case.fsm', $fsm_text);
        my $raw_ast = Lispish::multi($path);
        my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
        $adapter->parse_fsm($raw_ast);
        undef;
    };
    $error = $@;
    ok($error, 'parse failed as expected');
    return $error;
}

sub write_fsm {
    my ($filename, $content) = @_;
    my $path = File::Spec->catfile($tempdir, $filename);
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
    return $path;
}
