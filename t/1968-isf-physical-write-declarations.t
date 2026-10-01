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
        my ($name, $token) = $line =~ /^    \((\w+) ([^()\s]+)(?:\s|\))/;
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

subtest 'actual imported type tokens match direct, generated and domain carriers' => sub {
    my $work = tempdir(CLEANUP => 1);
    my $json = JSON::PP->new->canonical;
    my $write = sub {
        my ($name, $text) = @_;
        my $path = "$work/$name";
        open my $fh, '>:raw', $path or die $!;
        print {$fh} $text or die $!;
        close $fh or die $!;
        return $path;
    };
    $write->('shared.fsm', '(?pkg:shared (+types '
        . '(type frame (record (tag (bits 2)) (payload (bits 3)))) '
        . '(type word (signed (bits 5)))))');
    for my $case (
        ['direct', 'shared.frame', 0, 0],
        ['local_alias', 'alias', 0, 0],
        ['generated', 'shared.frame', 1, 0],
        ['domain', 'shared.frame', 0, 1],
        ['generated_domain', 'shared.frame', 1, 1],
    ) {
        my ($name, $type, $generated, $domain) = @$case;
        my $timing = $domain
            ? '(clock-domains (domain core (clock clk) :default) (domain io (clock io_clk)))'
            : '(clock clk)';
        my $owned = $domain ? '(domain io)' : '';
        my $types = $type eq 'alias' ? '(types (type alias shared.frame))' : '';
        my $body = $generated
            ? "(transaction worker $owned (ports (output result (width 3)))"
                . ' (set held packet) (set result packet.payload) (complete done))'
                . " (transaction main $owned (on start)"
                . ' (spawn worker as job (bind (output result seen))) (await_all done) (complete done))'
            : "(transaction main $owned (on start) (set held packet) (set seen packet.payload) (complete done))";
        my $source = "(actor $name $timing (imports (package shared)) $types"
            . " (interface (input start $owned) (input packet (type $type) $owned)"
            . " (output seen (width 3) $owned) (output done $owned))"
            . " (storage (var held (type $type) $owned)) $body)";
        my $path = $write->("$name.isf", $source);
        my $actor = FSM::Adapter::ISF->new->parse_file($path);
        my $actor_before = $json->encode($actor);
        my $formal = FSM::Scheduler::ISF::FormalLowering->prepare($scheduler->{ir}, $actor);
        my $physical = $formal ? $formal->{actor} : $actor;
        my $ir = $scheduler->{ir}->build_module($physical);
        my @parents = $domain
            ? map { $_->{ir} } @{$scheduler->_multi_domain_realizations($physical, $ir->{domain_partition})}
            : ($ir);
        for my $parent (@parents) {
            for my $module ($parent, map { $parent->{children}{$_} } sort keys %{$parent->{children} || {}}) {
                my ($result, $error);
                eval { $result = compare_emitted($module, "$name $module->{actor_name}"); 1 }
                    or $error = $@;
                ok($result, "$name actual realized module declarations collect")
                    or diag((split /\n/, $error // '')[0]);
                next unless $result;
                if (exists $result->{declarations}{held}) {
                    my $range = FSM::Scheduler::ISF::PhysicalWriteTargets->resolve(
                        $result->{module}, $result->{declarations}, 'held.tag');
                    is_deeply([@{$range}{qw(low high width)}], [3,4,2],
                        "$name storage leaf retains independently expected packed range");
                }
                for my $token (qw(shared. .frame shared..frame shared.frame.extra shared/frame)) {
                    my $bad = dclone($module);
                    next unless @{$bad->{ports}};
                    $bad->{ports}[0]{type} = $token;
                    my $ok = eval { $collector->collect($bad); 1 };
                    my ($first) = split /\n/, $@;
                    ok(!$ok, "$name malformed type token refuses");
                    like($first // '', qr/^Physical write declaration '.*' has an invalid width token/,
                        "$name malformed token has the primary declaration reason");
                }
            }
        }
        is($json->encode($actor), $actor_before, "$name complete parsed caller JSON is unchanged");
        my $files = $scheduler->lower($actor)->{files};
        for my $filename (sort keys %$files) {
            my $carrier = $write->($filename, $files->{$filename});
            my $native = FSM::Test::SourceQueryRunner::_capture(
                [$^X, 'bin/fsmgen', '--quiet', '--strict', '--check', '--json', $carrier], '');
            is($native->{exit_code}, 0, "$name actual $filename strictly replays")
                or diag($native->{stdout}, $native->{stderr});
            is($native->{signal}, 0, "$name carrier has no signal failure");
            ok($json->decode($native->{stdout})->{success}, "$name actual carrier reports success");
        }
    }
    my $scalar = $write->('scalar.isf', '(actor scalar (clock clk) (imports (package shared))'
        . ' (interface (input value (type shared.word)) (output result (type shared.word)))'
        . ' (transaction main (set result value)))');
    my $actor = FSM::Adapter::ISF->new->parse_file($scalar);
    my $ir = $scheduler->{ir}->build_module($actor);
    my $result = eval { compare_emitted($ir, 'imported scalar') };
    my $error = $@;
    ok($result, 'imported signed scalar input/output aliases also collect')
        or diag((split /\n/, $error // '')[0]);
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
