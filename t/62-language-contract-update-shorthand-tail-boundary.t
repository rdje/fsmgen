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
use FSM::Pipeline::HDLGenerator;

my $tempdir = tempdir(CLEANUP => 1);

subtest 'guard-suffixed separated update shorthand remains supported' => sub {
    my $module = parse_success(<<'FSM');
(?fsm:update_tail_guard_ok
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (counter 8)
    (start 1)
  )
  (-dt
    (+= counter 4 <start)
  )
)
FSM

    my ($state) = grep { $_->name eq '-dt' } @{ $module->states || [] };
    ok($state, 'found standalone DT');
    my @elements = map { @{ $_->elements || [] } } @{ $state->decision_trees || [] };
    is(scalar(@elements), 1, 'guarded update shorthand still produces one top-level element');
    ok($elements[0]->isa('FSM::CoreAST::ConditionalBranch'), 'guard-suffixed separated update shorthand remains a guarded action');
};

subtest 'malformed extra update-shorthand tails are rejected explicitly' => sub {
    my $single_tail_error = parse_failure(<<'FSM');
(?fsm:bad_update_tail_single
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-dt
    (+= counter 4 3)
  )
)
FSM

    like(
        $single_tail_error,
        qr/Malformed update shorthand tail '3' in '\(\+= counter 4 3\)'/,
        'single stray positional tail gets a targeted update-shorthand-tail diagnostic',
    );

    my $multi_tail_error = parse_failure(<<'FSM');
(?fsm:bad_update_tail_multi
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-dt
    (+= counter 4 3 2)
  )
)
FSM

    like(
        $multi_tail_error,
        qr/Malformed update shorthand tail '3, 2' in '\(\+= counter 4 3 2\)'/,
        'multiple stray positional tails get a targeted update-shorthand-tail diagnostic',
    );
};

subtest 'pipeline and CLI do not emit HDL for malformed update-shorthand tails' => sub {
    my $fsm_path = write_fsm('bad_update_tail_cli.fsm', <<'FSM');
(?fsm:bad_update_tail_cli
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-dt
    (+= counter 4 3)
  )
)
FSM

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug => 0,
    );
    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($fsm_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;
    ok($pipeline_error, 'pipeline rejects malformed update-shorthand tail');
    like(
        $pipeline_error,
        qr/Malformed update shorthand tail '3' in '\(\+= counter 4 3\)'/,
        'pipeline surfaces the update-shorthand-tail boundary clearly',
    );

    my $out_path = File::Spec->catfile($tempdir, 'bad_update_tail_cli.sv');
    my $success = system($^X, '-I', 'perl', 'bin/fsmgen', '--output', $out_path, $fsm_path) == 0;
    ok(!$success, 'CLI rejects malformed update-shorthand tail');
    ok(!-e $out_path, 'CLI does not emit output for malformed update-shorthand tail');
};

done_testing();

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

sub parse_success {
    my ($fsm_text) = @_;
    my $fsm_path = write_fsm('parse_success_' . int(rand(1_000_000)) . '.fsm', $fsm_text);
    my $raw_ast = Lispish::multi($fsm_path);
    my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
    my $module = $adapter->parse_fsm($raw_ast);
    ok($module, 'parse succeeded as expected');
    return $module;
}

sub write_fsm {
    my ($filename, $content) = @_;
    my $path = File::Spec->catfile($tempdir, $filename);
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
    return $path;
}
