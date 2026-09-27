#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Storable qw(dclone);
use JSON::PP;
use File::Temp qw(tempdir);
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::FormalLowering;

my $scheduler = FSM::Scheduler::ISF->new;
my $json = JSON::PP->new->canonical;
my $work = tempdir(CLEANUP => 1);
sub parse {FSM::Adapter::ISF->new->parse_source($_[0], 'formal_families.isf')}
sub strict_carriers {
    my ($actor, $label) = @_;
    my $files = $scheduler->lower($actor)->{files};
    for my $name (sort keys %$files) {
        open my $fh, '>', "$work/$name" or die $!; print {$fh} $files->{$name}; close $fh or die $!;
    }
    my $top = exists($files->{"$actor->{actor_name}_top.fsm"}) ? "$actor->{actor_name}_top" : $actor->{actor_name};
    my $r = FSM::Test::SourceQueryRunner::_capture([$^X,'bin/fsmgen','--strict','--check','--json',"$work/$top.fsm"], '');
    is($r->{exit_code}, 0, "$label strict carrier") or diag($r->{stdout}, $r->{stderr});
    return $files;
}

subtest 'source reports and physical loop/bank operands have separate views' => sub {
    my $actor = parse(<<'ISF');
(actor source_operands (clock clk) (reset (rst_n async active_low))
 (interface (input start) (input ack) (input ready) (output valid) (output done))
 (storage (bank ram (width 8) (depth 4)))
 (transaction main
  (ports (input index (width 2)) (input payload (width 8)) (input keep) (output result (width 8)))
  (on start) (store ram index payload) (load ram index as result)
  (while keep (exit-when (== payload 0)) (continue-when (! keep)) (wait 1))
  (assert (monitor (within ack 3)))
  (stage accept (input ready) (output valid)) (complete done)))
ISF
    my $context = FSM::Scheduler::ISF::FormalLowering->prepare($scheduler->{ir}, $actor);
    my $ir = $scheduler->{ir}->build_module($context->{actor});
    my $before = dclone($ir);
    my $view = FSM::Scheduler::ISF::FormalLowering->report_ir($context, $ir);
    is_deeply($ir, $before, 'report restoration never edits executable IR');
    my $report = $json->decode($scheduler->report($actor));
    is($report->{transaction_loops}[0]{condition}, 'keep', 'loop report names authored condition');
    is_deeply([map {$_->{condition}} @{$report->{loop_early_exits}}],
        ['(== payload 0)', '(! keep)'], 'early-exit and continue reports retain authored operands');
    is_deeply([map {[$_->{kind}, $_->{index}, $_->{value}, $_->{target}]} @{$report->{bank_accesses}}],
        [['store','index','payload',undef], ['load','index',undef,'result']], 'bank provenance retains authored scalar operands');
    is_deeply($report->{temporal_contracts}, [], 'removed contract syntax is not fabricated by monitor lowering');
    my $monitor = join(' ', map {$json->encode($_)} grep {$_->{kind} eq 'temporal_contract_monitor'} @{$ir->{dt_blocks}});
    like($monitor, qr/\back\b/, 'monitor still observes actor-owned ack');
    is($report->{transaction_stages}[0]{ready}, 'ready', 'stage ready endpoint stays actor-owned');
    is($report->{transaction_stages}[0]{valid}, 'valid', 'stage valid endpoint stays actor-owned');
    my $private = $context->{plan}{formals}{main};
    my ($loop) = grep {$_->{loop_entry}} @{$ir->{states}};
    is($loop->{loop_condition}, $private->{keep}{physical_name}, 'executable loop still reads private condition');
    is($ir->{bank_accesses}[0]{index}, $private->{index}{physical_name}, 'executable bank index remains physical');
    is($ir->{bank_accesses}[0]{value}, $private->{payload}{physical_name}, 'executable store value remains physical');
    is($ir->{bank_accesses}[1]{target}, $private->{result}{physical_name}, 'executable load destination remains physical');
    $view->{bank_accesses}[0]{index} = 'mutated';
    is_deeply($ir, $before, 'nested report mutation cannot change executable bank data');
    my $bad = dclone($ir); $bad->{bank_accesses}[0]{bank} = 'different_owner';
    eval {FSM::Scheduler::ISF::FormalLowering->report_ir($context, $bad)};
    like($@, qr/mismatched bank access identity/, 'report projection refuses mismatched source ownership');
    strict_carriers($actor, 'loops/banks/monitor/stage');
};

subtest 'ordinary compilation preserves typed sibling identities under declaration permutations' => sub {
    my $actor = parse(<<'ISF');
(actor typed_siblings (clock clk) (reset rst_n)
 (types (type narrow (signed (bits 4))) (type wide (signed (bits 8))))
 (interface (input start) (input other) (input ISF_PORT_FIRST_PAYLOAD) (output done))
 (storage (var payload (width 12) (reset 19)))
 (transaction first (ports (input payload (type narrow))) (on start) (set payload 3) (complete done))
 (transaction second (ports (output payload (type wide))) (on other) (set payload 5) (complete done)))
ISF
    my @names;
    for my $reverse (0, 1) {
        my $source = dclone($actor);
        @{$source->{transactions}} = reverse @{$source->{transactions}} if $reverse;
        my $context = FSM::Scheduler::ISF::FormalLowering->prepare($scheduler->{ir}, $source);
        my $ir = $scheduler->{ir}->build_module($context->{actor});
        my @allocated;
        for my $case (['first',4,'narrow'], ['second',8,'wide']) {
            my ($owner,$width,$type) = @$case;
            my $name = $context->{plan}{formals}{$owner}{payload}{physical_name};
            push @allocated, $name;
            is($ir->{signal_widths}{$name}, $width, "$owner keeps its width");
            is($ir->{signal_type_refs}{$name}, $type, "$owner keeps its signed type");
            is($ir->{storage_roles}{$name}, 'transaction_port', "$owner keeps private ownership");
            ok(!exists $ir->{reset_values}{$name}, "$owner does not inherit actor reset");
            isnt(lc($name), 'isf_port_first_payload', "$owner avoids case-folded actor pin");
        }
        isnt($allocated[0], $allocated[1], 'sibling physical storage identities differ');
        is($ir->{reset_values}{payload}, 19, 'actor storage reset stays with its owner');
        push @names, \@allocated;
        strict_carriers($source, "declaration permutation $reverse");
    }
    is_deeply($names[0], $names[1], 'allocation is stable under sibling declaration reversal');
};

subtest 'unassigned and unused direct formals stay internal across public backends' => sub {
    my $actor = parse(<<'ISF');
(actor private_boundary (clock clk) (reset rst_n)
 (interface (input start) (output observed (width 8)) (output done))
 (transaction main (ports (input payload (width 8)) (output unused (width 4)))
  (on start) (set observed payload) (complete done)))
ISF
    my $context = FSM::Scheduler::ISF::FormalLowering->prepare($scheduler->{ir}, $actor);
    my $ir = $scheduler->{ir}->build_module($context->{actor});
    my @private = map {$context->{plan}{formals}{main}{$_}{physical_name}} qw(payload unused);
    my %internal = map {$_ => 1} @{$ir->{explicit_internal_signals}};
    ok($internal{$_}, "$_ explicitly internal") for @private;
    my $bad = dclone($ir); $bad->{explicit_internal_signals} = [];
    eval {FSM::Scheduler::ISF::FormalLowering->verify($context, {$bad->{actor_name} => $bad})};
    like($@, qr/wrong width or ownership/, 'final guard rejects omitted private classification');
    strict_carriers($actor, 'unassigned and unused formals');
    my $source = "$work/private_boundary.fsm";
    my $semantic = FSM::Test::SourceQueryRunner::_capture([$^X,'bin/fsmgen','--strict','--emit-semantic-json',$source], '');
    is($semantic->{exit_code}, 0, 'semantic query succeeds');
    my $report = $json->decode($semantic->{stdout});
    is_deeply([sort map {$_->{name}} @{$report->{semantic}{forward_ir}{structural_rtl_ir}{ports}}],
        [sort qw(clk rst_n start observed done)], 'exact public ports exclude private formals');
    for my $language (qw(systemverilog verilog vhdl)) {
        my $output = "$work/private_boundary.$language";
        my $r = FSM::Test::SourceQueryRunner::_capture([$^X,'bin/fsmgen','--strict','--quiet','--language',$language,'--output',$output,$source], '');
        is($r->{exit_code}, 0, "$language generates private declarations") or diag($r->{stdout}, $r->{stderr});
        next if $r->{exit_code};
        open my $fh, '<', $output or die $!; my $hdl = do {local $/; <$fh>}; close $fh;
        my ($ports) = $language eq 'vhdl' ? ($hdl =~ /port\s*\((.*?)\);/s) : ($hdl =~ /module\s+private_boundary\s*\((.*?)\);/s);
        ok(defined $ports, "$language public port list found");
        unlike($ports, qr/isf_port_/, "$language public interface has no private formal");
        like($hdl, $language eq 'vhdl' ? qr/signal isf_port_main_payload : std_logic_vector\(7 downto 0\)/
            : qr/\breg\s+\[7:0\]\s+isf_port_main_payload\b/, "$language read-only private width retained");
    }
};

subtest 'normal compilation reserves a real rule payload with the candidate formal name' => sub {
    my $actor = parse(<<'ISF');
(actor helper_collision (clock clk) (reset rst_n)
 (interface (input fire) (input din (width 4)) (output observed (width 4)) (output done))
 (transaction main (ports (input payload (width 4)))
  (on main_start) (set observed payload) (complete done))
 (rule isf_port fire (trigger main (bind (input payload din)))))
ISF
    my $report = $json->decode($scheduler->report($actor));
    my @private = grep {($_->{role} // '') eq 'transaction_port'} @{$report->{inferred_storage}};
    is(scalar @private, 1, 'one private formal declared');
    isnt($private[0]{name}, 'isf_port_main_payload', 'private name avoids actual rule payload');
    is($report->{transaction_port_bindings}[0]{port}, 'payload', 'binding still names the authored callee formal');
    my $files = strict_carriers($actor, 'rule helper collision');
    like($files->{'helper_collision.fsm'}, qr/\(isf_port_main_payload 4\)/, 'rule helper keeps its source-derived name');
};

done_testing();
