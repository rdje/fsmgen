#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Storable qw(dclone);
use JSON::PP;
use lib 'perl';
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::FormalLowering;
use FSM::Scheduler::ISF::Emitter::FSM;
use FSM::Scheduler::ISF::PhysicalWriteDeclarations;
use FSM::Scheduler::ISF::PhysicalWriteTargets;

my $collector = 'FSM::Scheduler::ISF::PhysicalWriteDeclarations';
my $scheduler = FSM::Scheduler::ISF->new;
my $emitter = FSM::Scheduler::ISF::Emitter::FSM->new;
sub read_file {open my $fh, '<', $_[0] or die $!; local $/; return <$fh>}
sub lower {
    my $actor = FSM::Adapter::ISF->new->parse_source($_[0], 'physical_declarations.isf');
    my $context = FSM::Scheduler::ISF::FormalLowering->prepare($scheduler->{ir}, $actor);
    return $scheduler->{ir}->build_module($context ? $context->{actor} : $actor);
}
sub compare_emitted {
    my ($ir, $label) = @_;
    my $before = dclone($ir);
    my $result = $collector->collect($ir);
    my $fsm = $emitter->emit($ir);
    my ($size) = $fsm =~ /\(\+size\n(.*?)^  \)/ms;
    my %actual;
    for my $line (split /\n/, $size // '') {
        my ($name, $token) = $line =~ /^    \((\w+) (\w+)(?:\s|\))/;
        ok(defined($name), "$label size entry parsed") or diag($line);
        $actual{$name} = $token if defined $name;
    }
    is_deeply({map {$_ => $result->{declarations}{$_}{width_token}} keys %{$result->{declarations}}},
        \%actual, "$label exact emitted declaration/token set");
    is_deeply($ir, $before, "$label collection and emission leave IR unchanged");
    return $result;
}

subtest 'actual baseline declarations cover all admitted writer targets' => sub {
    my $cases = JSON::PP->new->decode(read_file('docs/audits/direct-writer-admission-20260927/cases.json'));
    for my $case (grep {$_->{expected_admission} eq 'admitted'} @$cases) {
        my $ir = lower($case->{source});
        my $result = compare_emitted($ir, $case->{case_id});
        is_deeply($result->{unresolved_targets}, [], "$case->{case_id} has explicit target contracts");
        my @targets = map {FSM::Scheduler::ISF::PhysicalWriteTargets->resolve(
            $result->{module}, $result->{declarations}, $_->{target})} @{$ir->{assignment_provenance}};
        is(scalar @targets, scalar @{$ir->{assignment_provenance}}, "$case->{case_id} resolves every actual assignment");
    }
};

subtest 'actual post-wiring parent and child declarations stay module-local' => sub {
    my $ir = lower(read_file('t/data/isf_schedule_generated_role_families.isf'));
    my @modules = ($ir, map {$ir->{children}{$_}} sort keys %{$ir->{children}});
    ok(@modules > 1, 'fixture contains actual generated modules');
    for my $module (@modules) {
        my $result = compare_emitted($module, $module->{actor_name});
        is_deeply($result->{unresolved_targets}, [], 'generated handoff/completion targets have explicit declarations');
    }
};

subtest 'typed private formals and aggregate layout preserve independent module contracts' => sub {
    my $ir = lower(<<'ISF');
(actor declarations (clock clk)
 (types (type signed_word (signed (bits 8))) (type frame_t (record (tag (bits 2)) (valid bit))))
 (interface (input start) (output result (type signed_word)))
 (storage (var frame (type frame_t)))
 (transaction main (ports (input payload (type signed_word)))
  (local count (width 4) (reset 7)) (on start) (set frame.tag 2) (set result payload)))
ISF
    my $result = compare_emitted($ir, 'typed');
    my $decl = $result->{declarations};
    is_deeply([@{$decl->{isf_port_main_payload}}{qw(width width_token origin)}],
        [8,'signed_word','counter'], 'private formal has resolved width and emitted type alias');
    is_deeply([@{$decl->{count}}{qw(width width_token origin)}], [4,4,'counter'], 'local width is explicitly emitted');
    my $range = FSM::Scheduler::ISF::PhysicalWriteTargets->resolve('declarations', $decl, 'frame.tag');
    is_deeply([@{$range}{qw(low high width)}], [1,2,2], 'storage retains canonical packed type layout');
    my $other_ir = dclone($ir); $other_ir->{actor_name} = 'other_module';
    my $other = $collector->collect($other_ir);
    my $other_range = FSM::Scheduler::ISF::PhysicalWriteTargets->resolve($other->{module}, $other->{declarations}, 'frame.tag');
    ok(!FSM::Scheduler::ISF::PhysicalWriteTargets->overlaps($range, $other_range), 'same spelling stays separate across modules');
    $decl->{frame}{type_spec}{width} = 100;
    is($other->{declarations}{frame}{type_spec}{width}, 3, 'independent collections do not share nested type records');
    is($ir->{declared_storage}[0]{signals}[0]{type_spec}{width}, 3, 'returned type mutation cannot edit source IR');
};

subtest 'assembly widths are declarations but other known widths stay implicit' => sub {
    my $ir = lower(<<'ISF');
(actor assembly (clock clk)
 (interface (input start) (input source (width 8)) (output done))
 (transaction main (on start) (sample source as captured)
  (assemble header payload as packet (widths 4 8))
  (set scratch 3) (complete done)))
ISF
    my $result = compare_emitted($ir, 'assembly');
    is_deeply([map {$result->{declarations}{$_}{width}} qw(header payload packet)], [4,8,12], 'assembly declarations match independent widths');
    is($ir->{signal_widths}{captured}, 8, 'sample target has known lowering width');
    ok(!exists $result->{declarations}{captured}, 'known sample width does not claim an explicit declaration');
    is_deeply($result->{unresolved_targets}, [{root=>'captured',target=>'captured'}, {root=>'scratch',target=>'scratch'}],
        'implicit assignment roots remain explicit obligations in deterministic order');
    $ir->{signal_widths}{unrelated} = 37;
    is_deeply($collector->collect($ir), $result, 'unrelated known expression widths cannot fabricate declarations');
};

subtest 'emitter precedence and static assembly exclusions are retained' => sub {
    my $ir = {actor_name=>'precedence', ports=>[{name=>'value',width=>8}],
        declared_storage=>[{signals=>[{name=>'value',width=>7}]}],
        counters=>{value=>6, held=>3}, signal_widths=>{value=>5, held=>4, field=>2, CONST=>7, PARAM=>9},
        constants=>[{name=>'CONST'}], params=>[{name=>'PARAM'}],
        states=>[{assembly_signals=>[qw(value held field CONST PARAM)], assignments=>[]}], dt_blocks=>[]};
    my $result = $collector->collect($ir);
    is_deeply({map {$_=>$result->{declarations}{$_}{width}} keys %{$result->{declarations}}},
        {value=>8, held=>3, field=>2}, 'first emitted declaration wins and static operands stay excluded');
    my $size = $emitter->_emit_size($ir);
    like($size, qr/\(value 8\)/, 'independent emitter agrees on selected port width');
    unlike($size, qr/\((?:CONST|PARAM) /, 'independent emitter excludes static operands');
    $ir->{states}[0]{assembly_signals} = [reverse @{$ir->{states}[0]{assembly_signals}}];
    is_deeply($collector->collect($ir), $result, 'assembly traversal permutations keep identical detached contracts');
};

subtest 'missing and malformed declarations cannot silently resolve writers' => sub {
    my $ir = lower('(actor missing (storage (var value (width 8))) (transaction main (set value 3)))');
    my $bad = dclone($ir); $bad->{declared_storage}=[];
    my $result = $collector->collect($bad);
    is_deeply($result->{unresolved_targets}, [{root=>'value',target=>'value'}], 'removed declaration remains unresolved despite signal_widths copy');
    for my $case (
        [sub {delete $_[0]{actor_name}}, qr/require a module IR/],
        [sub {$_[0]{ports}={}}, qr/require 'ports' records/],
        [sub {$_[0]{counters}=[]}, qr/require a 'counters' map/],
        [sub {$_[0]{declared_storage}[0]{signals}[0]{width}=0}, qr/invalid width token/],
        [sub {$_[0]{declared_storage}[0]{signals}[0]{type_spec}={width=>4}}, qr/inconsistent resolved type width/],
        [sub {$_[0]{states}[0]{assignments}[0]{lhs}=[]}, qr/scalar assignment targets/],
        [sub {$_[0]{states}[0]{assignments}[0]{lhs}='value.no_such_member'}, qr/unresolved aggregate path/],
    ) {
        my $mutated = dclone($ir); $case->[0]->($mutated);
        eval {$collector->collect($mutated)};
        like($@, $case->[1], 'malformed contract is refused with a focused diagnostic');
    }
};
done_testing();
