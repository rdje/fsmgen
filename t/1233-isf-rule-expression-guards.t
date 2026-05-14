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

subtest 'rule guards accept scalar-or-list expressions and lower into DT DTEs' => sub {
    my $source = <<'ISF';
(actor rule_expression_guards
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input push)
    (input pop)
    (input full)
    (input empty)
    (output write_fire)
    (output read_fire))
  (rule push_only (& push (! pop) (! full))
    (write_fire 1))
  (rule pop_only
    (when (& pop (! push) (! empty)))
    (read_fire 1)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'rule-expression-guards.isf');
    my %rule_by_name = map { $_->{name} => $_ } @{$actor->{rules}};

    is_deeply(
        $rule_by_name{push_only}{when},
        ['when', ['&', 'push', ['!', 'pop'], ['!', 'full']]],
        'shorthand expression guard normalizes into the public when field',
    );
    is_deeply(
        $rule_by_name{pop_only}{when},
        ['when', ['&', 'pop', ['!', 'push'], ['!', 'empty']]],
        'long-form expression guard normalizes into the public when field',
    );

    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    my $fsm = $lowered->{files}{'rule_expression_guards.fsm'};

    like(
        $fsm,
        qr/\(-push_only\s+<\(& push \(! pop\) \(! full\)\)\s+\(<- \(write_fire> 1\)\)\s+\)/s,
        'shorthand expression guard is emitted once as the rule DT DTE',
    );
    like(
        $fsm,
        qr/\(-pop_only\s+<\(& pop \(! push\) \(! empty\)\)\s+\(<- \(read_fire> 1\)\)\s+\)/s,
        'long-form expression guard is emitted once as the rule DT DTE',
    );

    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'rule_expression_guards.fsm');
    write_file($fsm_path, $fsm);

    my $raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
        fsm_file => $fsm_path,
        debug_level => 0,
    );
    my $fsm_module = FSM::Pipeline::SourceFrontend->create_fsm_module(
        raw_ast => $raw_ast,
        debug_level => 0,
    );
    ok($fsm_module, 'expression-guard scheduled .fsm parses through the normal .fsm frontend');

    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
    like($hdl, qr/\bmodule\s+rule_expression_guards\b/, 'expression-guard rules reach HDL generation');
};

subtest 'rule expression guards keep targeted parser boundaries' => sub {
    assert_parse_rejected(<<'ISF', qr/rule 'duplicate' accepts only one guard condition/, 'mixed shorthand and long-form expression guards are rejected');
(actor duplicate_expression_guard
  (clock clk)
  (interface
    (input push)
    (input pop)
    (output write_fire))
  (rule duplicate (& push (! pop))
    (when pop)
    (write_fire 1)))
ISF

    assert_parse_rejected(<<'ISF', qr/rule 'bad_guard' guard expression cannot use control-flow form 'when'/, 'control-flow form is rejected inside a rule guard expression');
(actor bad_expression_guard
  (clock clk)
  (interface
    (input push)
    (output write_fire))
  (rule bad_guard
    (when (when push))
    (write_fire 1)))
ISF
};

done_testing();

sub assert_parse_rejected {
    my ($source, $diagnostic_re, $label) = @_;
    my $ok = eval {
        FSM::Adapter::ISF->new()->parse_source($source, "$label.isf");
        1;
    };
    my $diagnostic = $@;

    ok(!$ok, $label);
    like($diagnostic, $diagnostic_re, "$label diagnostic");
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
