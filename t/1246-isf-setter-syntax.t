#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::HDL::FlattenedDT;
use FSM::Pipeline::SourceFrontend;
use FSM::Scheduler::ISF;

sub parse_source {
    my ($source, $label) = @_;
    return FSM::Adapter::ISF->new()->parse_source($source, "$label.isf");
}

sub lower_source {
    my ($source, $label) = @_;
    my $actor = parse_source($source, $label);
    return FSM::Scheduler::ISF->new()->lower($actor);
}

sub assert_parse_rejected {
    my ($source, $label, $diagnostic_re) = @_;

    my $ok = eval {
        parse_source($source, $label);
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, "$label is rejected during parsing");
    ok(!ref($diagnostic), "$label diagnostic is scalar");
    like($diagnostic, $diagnostic_re, "$label diagnostic is targeted");
}

sub assert_lower_rejected {
    my ($source, $label, $diagnostic_re) = @_;

    my $ok = eval {
        lower_source($source, $label);
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, "$label is rejected during lowering");
    ok(!ref($diagnostic), "$label diagnostic is scalar");
    like($diagnostic, $diagnostic_re, "$label diagnostic is targeted");
}

subtest 'rule and transaction set forms preserve existing flopped timing' => sub {
    my $result = lower_source(<<'ISF', 'setter-syntax');
(actor setter_syntax
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (input ready)
    (input payload)
    (input cond)
    (input mode)
    (input keep)
    (input done_seen)
    (output rule_out)
    (output tx_out)
    (output done))
  (rule explicit_rule ready
    (set rule_out (+ payload 1)))
  (transaction main
    (on start)
    (set tx_out payload)
    (when cond
      (set tx_out (+ payload 1)))
    (switch mode
      (0 (set tx_out 0))
      (default (set tx_out 1)))
    (repeat 2
      (set tx_out payload))
    (while keep
      (set tx_out payload)
      (wait 1))
    (until done_seen
      (set tx_out payload))
    (complete done)))
ISF

    my $fsm = $result->{files}{'setter_syntax.fsm'};
    like($fsm, qr/\(-explicit_rule <ready\s+\(<- \(rule_out> \(\+ payload 1\)\)\)\s+\)/s,
        'rule set lowers as a flopped assignment inside the guarded rule DT');
    like($fsm, qr/\(main_set_\d+\s+\(<- \(tx_out> payload\)\)/,
        'top-level transaction set lowers as an ordered flopped transaction state');
    like($fsm, qr/\(main_set_\d+\s+\(<- \(tx_out> \(\+ payload 1\)\)/,
        'nested transaction set preserves expression RHS formatting');
    unlike($fsm, qr/\(<- \(set>/, 'set is not treated as an assignment target');

    assert_fsm_reaches_hdl($fsm, 'setter_syntax');
};

subtest 'malformed rule set actions fail before actor-shell return' => sub {
    assert_parse_rejected(<<'ISF', 'missing rule set rhs', qr/\AError: rule 'bad' set action requires '\(set port expr\)'/);
(actor bad_rule_set
  (clock clk)
  (interface (input ready) (output out))
  (rule bad ready
    (set out)))
ISF

    assert_parse_rejected(<<'ISF', 'nested rule set target', qr/\AError: rule 'bad' set action requires '\(set port expr\)'/);
(actor bad_rule_set
  (clock clk)
  (interface (input ready) (output out))
  (rule bad ready
    (set (out) 1)))
ISF

    assert_parse_rejected(<<'ISF', 'set expression as rule rhs', qr/\AError: rule 'bad' assignment RHS cannot use control-flow form 'set'/);
(actor bad_rule_set
  (clock clk)
  (interface (input ready) (output out))
  (rule bad ready
    (out (set out 1))))
ISF
};

subtest 'malformed transaction set clauses fail before scheduled emission' => sub {
    assert_lower_rejected(<<'ISF', 'missing transaction set rhs', qr/\ATransaction 'main': set requires '\(set var expr\)' in transaction body/);
(actor bad_transaction_set
  (clock clk)
  (interface (input start) (output out) (output done))
  (transaction main
    (on start)
    (set out)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'nested transaction set target', qr/\ATransaction 'main': set requires '\(set var expr\)' in transaction body/);
(actor bad_transaction_set
  (clock clk)
  (interface (input start) (output out) (output done))
  (transaction main
    (on start)
    (set (out) 1)
    (complete done)))
ISF

    assert_lower_rejected(<<'ISF', 'malformed nested transaction set', qr/\ATransaction 'main': set requires '\(set var expr\)' in when body/);
(actor bad_transaction_set
  (clock clk)
  (interface (input start) (input cond) (output out) (output done))
  (transaction main
    (on start)
    (when cond
      (set out))
    (complete done)))
ISF
};

done_testing();

sub assert_fsm_reaches_hdl {
    my ($fsm, $module_name) = @_;
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, "$module_name.fsm");
    write_file($fsm_path, $fsm);

    my $raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
        fsm_file    => $fsm_path,
        debug_level => 0,
    );
    my $fsm_module = FSM::Pipeline::SourceFrontend->create_fsm_module(
        raw_ast     => $raw_ast,
        debug_level => 0,
    );
    ok($fsm_module, 'setter scheduled .fsm parses through the normal .fsm frontend');

    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
    like($hdl, qr/\bmodule\s+\Q$module_name\E\b/, 'setter scheduled .fsm reaches SystemVerilog generation');
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
