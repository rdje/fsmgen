use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use Storable qw(dclone);
use JSON::PP;
use File::Temp qw(tempdir);
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner qw(normalize_repository_paths);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::FormalLowering;
use FSM::Scheduler::ISF::DomainSource qw(_domain_actor_for_scheduled_artifact);
use FSM::Scheduler::ISF::ChildOutputReads;
use FSM::Scheduler::ISF::Emitter::FSM;

my $json = JSON::PP->new->canonical;
my $work = tempdir(CLEANUP => 1);
my ($active_source, $active_packages);
my $spec = {kind => 'record', width => 5, signed => 0, member_order => [qw(tag payload)], members => {
    tag => {kind => 'bits', width => '2', signed => 0},
    payload => {kind => 'bits', width => '3', signed => 1, state_model => 'four_state'},
}};
my @ingress = qw(direct local_do spawn_writer blocking_writer spawn_readers storage_then_output
    unused_with_child competing_children formal_shadow imported_writer scalar_control scalar_writer
    scalar_reader input_control domain_direct domain_writer domain_readers imported_domain_blocking);
my $sources = 'docs/audits/record-output-generated-ingress-20261002/sources';
for my $case (@ingress) {
    subtest "actual ingress $case" => sub {
        my ($actor, $builder, $ir) = actual("$sources/$case.isf", $case =~ /domain/);
        is_deeply([sort keys %{$ir->{children}}], $case =~ /\A(?:direct|local_do|domain_direct)\z/ ? [] : ['worker'],
            'complete actual child definition membership');
        return unless $ir->{children}{worker};
        my ($tx) = grep {$_->{name} eq 'worker'} @{$actor->{transactions}};
        my $child = $ir->{children}{worker};
        my $read = $case =~ /\A(?:spawn_readers|domain_readers|scalar_reader)\z/;
        my $expected = expected($child, $read ? 'packet' : undef, $case eq 'scalar_reader' ? undef : $spec,
            $case eq 'scalar_reader' ? '3' : 5, $case =~ /imported/ ? 'shared.frame' : 'frame');
        if (!$read && $case !~ /\A(?:spawn_writer|blocking_writer|competing_children|imported_writer|domain_writer|imported_domain_blocking|formal_shadow|input_control)\z/) {
            delete $expected->{$_}{packet} for qw(signal_type_refs reset_values storage_roles);
        }
        if ($read) {
            for my $s (@{$expected->{states}}) {
                for my $a (@{$s->{assignments}}) {
                    $a->{rhs} = $case eq 'scalar_reader' ? 'isf_output_read_packet' : 'isf_output_read_packet.payload'
                        if $a->{lhs} eq 'result';
                }
            }
        }
        qualify($case, $builder, $actor, $tx, $child, $expected);
    };
}

for my $name (qw(packet start done isf_child_start_seen)) {
    subtest "actual handshake collision $name" => sub {
        my $path = "$work/$name.isf";
        write_file($path, collision_source($name));
        my ($actor, $builder, $ir) = actual($path);
        my ($tx) = grep {$_->{name} eq 'worker'} @{$actor->{transactions}};
        my $child = $ir->{children}{worker};
        is($child->{signal_type_refs}{$name}, 'frame', 'actual baseline inherited actor type');
        my $expected = expected($child, $name, $spec, 5, 'frame');
        for my $s (@{$expected->{states}}) {
            $_->{rhs} = "isf_output_read_$name.payload" for grep {$_->{lhs} eq 'result'} @{$s->{assignments}};
        }
        my $plan = qualify("collision_$name", $builder, $actor, $tx, $child, $expected);
        my $fsm = FSM::Scheduler::ISF::Emitter::FSM->new->emit($plan);
        like($fsm, qr/\($name /, 'source owner name is retained where actually declared') if $name eq 'done';
        like($fsm, qr/\(start 1\)/, 'start handshake remains one bit');
        like($fsm, qr/\(done 1\)/, 'done handshake remains one bit');
        like($fsm, qr/\(isf_output_read_\Q$name\E frame\)/, 'private data view retains its record alias');
        for my $mutation (qw(history port entry path prepared type)) {
            my $bad = dclone($child);
            my ($entry) = grep {$_->{kind} eq 'entry'} @{$bad->{states}};
            my ($history) = grep {$_->{kind} eq 'child_activation'} @{$bad->{dt_blocks}};
            if ($mutation eq 'history') {$bad->{storage_roles}{$history->{name}} = 'sample_alias'}
            elsif ($mutation eq 'port') {$_->{width} = 5 for grep {$_->{name} eq 'start'} @{$bad->{ports}}}
            elsif ($mutation eq 'entry') {$entry->{transitions}[0]{condition}{expr} = $name}
            elsif ($mutation eq 'prepared') {$bad->{actor_output_reads} = []}
            elsif ($mutation eq 'type') {$bad->{signal_type_refs}{$name} = 'wrong_frame'}
            else {
                for my $s (@{$bad->{states}}) {$_->{rhs} = "$name.missing" for grep {$_->{lhs} eq 'result'} @{$s->{assignments}}}
            }
            my $before = $json->encode($bad);
            my $ok = eval {FSM::Scheduler::ISF::ChildOutputReads->plan(lowering => $builder,
                actor => $actor, transaction => $tx, ir => $bad); 1};
            ok(!$ok, "$mutation hostile input refuses");
            like($@, qr/Invalid child output-read preparation:/, 'precise bounded preparation refusal');
            is($json->encode($bad), $before, 'failed preparation leaves complete caller untouched');
        }
    };
}

my $scalar_source = read_file("$sources/scalar_reader.isf");
for my $case (qw(slice guard_assert alias_collision parameter_shadow local_shadow formal_shadow self_read sample record_self_read)) {
    subtest "actual data role $case" => sub {
        my $text = $case eq 'sample' || $case eq 'record_self_read' ? collision_source('packet') : $scalar_source;
        my $alias = $case eq 'alias_collision' ? 'isf_output_read_packet_output_read' : 'isf_output_read_packet';
        my %rhs;
        if ($case eq 'slice') {
            $text =~ s/\(set result packet\)/(set result packet[2:0])/;
            %rhs = ('packet[2:0]' => "$alias\[2:0\]");
        } elsif ($case eq 'guard_assert') {
            $text =~ s/\(set result packet\)/(wait 1) (when (> packet 0) (set result (+ packet 1))) (assert (== packet packet) "packet")/;
            %rhs = ('(+ packet 1)' => "(+ $alias 1)", '(> packet 0)' => "(> $alias 0)",
                '(== packet packet)' => "(== $alias $alias)");
        } elsif ($case eq 'alias_collision') {
            $text =~ s/\(transaction worker /\(transaction worker (local isf_output_read_packet (width 3) (reset 0)) /;
            %rhs = (packet => $alias);
        } elsif ($case eq 'parameter_shadow') {
            $text =~ s/\(transaction worker /\(transaction worker (params (packet 2)) /;
        } elsif ($case eq 'local_shadow') {
            $text =~ s/\(transaction worker /\(transaction worker (local packet (width 3) (reset 1)) /;
        } elsif ($case eq 'formal_shadow') {
            $text =~ s/\(ports \(output result/\(ports (input packet (width 3)) (output result/;
            $text =~ s/\(input incoming \(width 5\)\)/\(input incoming (width 3))/;
            $text =~ s/\(bind \(output result seen\)\)/\(bind (input packet incoming) (output result seen))/;
        } elsif ($case eq 'self_read') {
            $text =~ s/\(input incoming \(width 5\)\)/\(input incoming (width 3))/;
            $text =~ s/\(set result packet\)/\(set packet incoming) (set result packet)/;
            %rhs = (packet => $alias);
        } elsif ($case eq 'sample') {
            $text =~ s/\(set result packet.payload\)/\(sample packet.payload as saved) (set result saved)/;
            %rhs = ('packet.payload' => "$alias.payload");
        } else {
            $text =~ s/\(set result packet.payload\)/\(set packet packet) (set result packet.payload)/;
            %rhs = (packet => $alias, 'packet.payload' => "$alias.payload");
        }
        my $path = "$work/$case.isf";
        write_file($path, $text);
        if ($case eq 'local_shadow') {
            my $ok = eval {actual($path); 1};
            ok(!$ok, 'actual local cannot shadow an actor interface name');
            like($@, qr/\Q(local packet ...)\E.*collides with interface port 'packet'/, 'existing precise local declaration refusal');
            return;
        }
        my ($actor, $builder, $ir) = actual($path);
        my ($tx) = grep {$_->{name} eq 'worker'} @{$actor->{transactions}};
        my $child = $ir->{children}{worker};
        my $record = $case eq 'sample' || $case eq 'record_self_read';
        my $expected = expected($child, keys(%rhs) ? 'packet' : undef, $record ? $spec : undef,
            $record ? 5 : '3', 'frame', $alias);
        if ($case eq 'record_self_read') {$expected->{signal_type_refs}{packet} = 'frame'}
        my $hits = 0;
        # Literal source expressions, independently prescribed for these authored
        # cases, establish complete expected products without calling the visitor.
        for my $s (@{$expected->{states}}) {
            for my $a (@{$s->{assignments}}) {
                if (exists $rhs{$a->{rhs}}) {$a->{rhs} = $rhs{$a->{rhs}}; ++$hits}
                literal_guard($a->{guard}, \%rhs);
            }
            for my $t (@{$s->{transitions}}) {literal_guard($t->{condition}, \%rhs)}
            $s->{condition}[1] = $alias if $case eq 'guard_assert' && $s->{kind} eq 'branch';
        }
        for my $a (@{$expected->{immediate_assertions}}) {
            $a->{condition} = $rhs{$a->{condition}} if exists $rhs{$a->{condition}};
        }
        ok($hits, 'actual emitted source data operand exists') if keys %rhs;
        my $plan = qualify("role_$case", $builder, $actor, $tx, $child, $expected);
        if ($case eq 'sample') {
            is($plan->{storage_roles}{saved}, 'sample_alias', 'sample remains a distinct captured scalar');
            is($plan->{signal_type_refs}{saved}, $child->{signal_type_refs}{saved}, 'sample exact signed/four-state type stays intact');
        }
    };
}

for my $case (qw(enum_mask package_mask constant_mask literal unused_handshake)) {
    subtest "actual static or unused role $case" => sub {
        my $text = $case eq 'unused_handshake' ? collision_source('start') : $scalar_source;
        if ($case eq 'enum_mask') {
            $text =~ s/\(interface /\(enums (packet (ONE 1))) (interface /;
            $text =~ s/\(set result packet\)/\(set result packet.ONE)/;
        } elsif ($case eq 'package_mask') {
            write_file("$work/shared.fsm", '(?pkg:shared (+enums (mode (ONE 1))) (+constants (MAX 3)))');
            $text =~ s/\(interface /\(imports (package shared)) (interface /;
            $text =~ s/\(output packet \(width 3\)\)/\(output shared (width 3))/;
            $text =~ s/\(transaction worker /\(transaction worker (params (MODE shared.MAX)) /;
            $text =~ s/\(set result packet\)/\(set result shared.mode.ONE)/;
        } elsif ($case eq 'constant_mask') {
            $text =~ s/\(interface /\(constants (packet 2)) (interface /;
        } elsif ($case eq 'literal') {
            $text =~ s/\(set result packet\)/\(set result 3'bx01)/;
        } else {
            $text =~ s/\(set result start.payload\)/\(set result 1)/;
        }
        my $path = "$work/$case.isf";
        write_file($path, $text);
        my ($actor, $builder, $ir) = actual($path);
        my ($tx) = grep {$_->{name} eq 'worker'} @{$actor->{transactions}};
        my $child = $ir->{children}{worker};
        my $expected = expected($child, undef);
        if ($case eq 'unused_handshake') {delete $expected->{$_}{start} for qw(signal_type_refs reset_values storage_roles)}
        qualify("static_$case", $builder, $actor, $tx, $child, $expected);
        my $scope = $builder->child_output_read_scope($actor, $tx);
        ok($scope->{static_symbols}{'packet.ONE'}, 'canonical local enum member is static') if $case eq 'enum_mask';
        if ($case eq 'package_mask') {
            ok($scope->{static_symbols}{'shared.MAX'}, 'canonical imported parameter constant is static');
            ok($scope->{static_symbols}{'shared.mode.ONE'}, 'canonical imported enum operand is static');
        }
        ok($scope->{static_symbols}{packet}, 'canonical actor constant is static') if $case eq 'constant_mask';
    };
}

subtest 'emitter precedence and opaque identities' => sub {
    my ($actor, $builder, $ir) = actual("$sources/scalar_reader.isf");
    my ($tx) = grep {$_->{name} eq 'worker'} @{$actor->{transactions}};
    my $child = dclone($ir->{children}{worker});
    # Each fixture lists its own expected consumed fields. Losing fields carry
    # the same output spelling, making an indiscriminate walk visibly wrong.
    my @fixtures = (
        [{kind => 'branch', condition => 'packet', transitions => [{target => 'target'}]}, [['condition']]],
        [{kind => 'branch', condition => 'packet', transitions => [{target => 'target', condition => {port => 'start', expr => 'packet'}}]}, []],
        [{kind => 'switch', signal => 'packet', branches => [{value => 'packet', body_start => 'packet'}, {value => '_', body_start => 'packet'}], transitions => []}, [['signal'], ['branches',0,'value']]],
        [{kind => 'switch', signal => 'packet', switch_transitions_materialized => 1, transitions => [{target => 'packet', condition => {expr => 'packet'}}]}, [['transitions',0,'condition','expr']]],
        [{kind => 'loop_while', condition => ['&','packet',['state_active','packet']], transitions => [{target => 'packet', condition => {loop_branch => 1, expr => 'packet'}}]}, [['condition',1]]],
        [{kind => 'loop_until', condition => 'packet', loop_transitions_materialized => 1, transitions => [{target => 'packet', condition => {signal => 'start', op => '=', value => 'packet'}}]}, [['transitions',0,'condition','value']]],
        [{kind => 'loop_exit_when', condition => 'packet', transitions => []}, [['condition']]],
        [{kind => 'sync_all', done_ports => ['packet'], completion_ports => ['start'], transitions => [{target => 'packet'}]}, []],
        [{kind => 'sync_any', done_ports => ['packet'], transitions => [{target => 'packet'}]}, [['done_ports',0]]],
        [{kind => 'sync_all', done_ports => ['packet'], transitions => [{target => 'packet', condition => {signal => 'packet', op => '=', value => 'packet'}}]}, [['transitions',0,'condition','signal'],['transitions',0,'condition','value']]],
        [{kind => 'await', transitions => [{target => 'packet', condition => {port => 'start', expr => 'packet'}}]}, []],
        [{kind => 'await', transitions => [{target => 'packet', condition => {port => '0', expr => 'packet'}}]}, []],
        [{kind => 'await', transitions => [{target => 'packet', condition => {signal => 'packet', value => 'packet'}}]}, [['transitions',0,'condition','signal']]],
        [{kind => 'repeat_check', counter => 'can_accept', transitions => [{target => 'packet', condition => {signal => 'can_accept', op => '!=', value => 'packet'}}, {target => 'packet', condition => {expr => 'packet'}}]}, [['transitions',1,'condition','expr']]],
        [{kind => 'sequential', word => 'packet', assignments => [{lhs => 'packet', rhs => 'packet', op => '--', guard => {port => 'packet'}}], transitions => []}, []],
        [{kind => 'sequential', word => 'packet', fields => ['packet'], transitions => []}, [['word']]],
        [{kind => 'sequential', assignments => [{lhs => 'packet', rhs => '(state_active packet)', op => '<-', guard => {port => '1', expr => 'packet'}}, {lhs => 'packet', rhs => "3'hx", op => '=', guard => {signal => 'start', op => '=', value => 'packet', expr => 'packet'}}], transitions => []}, [['assignments',1,'guard','value']]],
    );
    for my $i (0 .. $#fixtures) {
        my ($state, $paths) = @{$fixtures[$i]};
        $state = {name => 'packet', transaction => 'worker', assignments => [], transitions => [], %$state};
        my $test_ir = dclone($child);
        push @{$test_ir->{states}}, $state;
        my $expected = expected($test_ir, 'packet', undef, '3', undef);
        # Preserve data-writer metadata as part of the separately gated writer
        # prerequisite; packet is scalar and has no inherited alias here.
        $_->{rhs} = 'isf_output_read_packet' for map {grep {$_->{lhs} eq 'result'} @{$_->{assignments}}} @{$expected->{states}};
        for my $path (@$paths) {
            my $node = $expected->{states}[-1];
            for my $j (0 .. $#$path - 1) {$node = ref($node) eq 'ARRAY' ? $node->[$path->[$j]] : $node->{$path->[$j]}}
            my $key = $path->[-1];
            if (ref($node) eq 'ARRAY') {$node->[$key] = 'isf_output_read_packet'} else {$node->{$key} = 'isf_output_read_packet'}
        }
        qualify("precedence_$i", $builder, $actor, $tx, $test_ir, $expected);
    }
};
done_testing;

sub actual {
    my ($path, $domain) = @_;
    $active_source = read_file($path);
    $active_packages = $active_source =~ /\(package shared\)/ ? {shared => read_file(dirname($path) . '/shared.fsm')} : {};
    my $actor = FSM::Adapter::ISF->new->parse_file($path);
    my $scheduler = FSM::Scheduler::ISF->new;
    my $formal = FSM::Scheduler::ISF::FormalLowering->prepare($scheduler->{ir}, $actor);
    $actor = $formal->{actor} if $formal;
    my $ir = $scheduler->{ir}->build_module($actor);
    if ($domain) {
        my ($io) = grep {$_->{name} eq 'io'} @{$ir->{domain_partition}{domains}};
        $actor = _domain_actor_for_scheduled_artifact($actor, $io, 'idle');
        $ir = $scheduler->{ir}->build_module($actor);
    }
    return ($actor, $scheduler->{ir}, $ir);
}
sub expected {
    my ($child, $name, $type, $width, $alias_type, $private) = @_;
    my $expected = dclone($child);
    $expected->{actor_output_reads} = [];
    if (defined $name) {
        my $alias = $private // "isf_output_read_$name";
        my $read = {name => $name, input_port => $alias, width => $width};
        if ($type) {$read->{type} = $alias_type; $read->{type_spec} = dclone($type)}
        push @{$expected->{actor_output_reads}}, $read;
        push @{$expected->{ports}}, {name => $alias, direction => 'input', width => $width, isf_handoff => 1};
        $expected->{signal_widths}{$alias} = $width;
        $expected->{signal_type_refs}{$alias} = $alias_type if $type;
        delete $expected->{$_}{$name} for qw(signal_type_refs reset_values storage_roles);
    }
    $expected->{explicit_interface_ports} = [map {{%$_}} @{$expected->{ports}}];
    return $expected;
}
sub qualify {
    my ($name, $builder, $actor, $tx, $child, $expected) = @_;
    my $before = $json->encode([$actor, $child]);
    my $plan = FSM::Scheduler::ISF::ChildOutputReads->plan(lowering => $builder, actor => $actor,
        transaction => $tx, ir => $child);
    is($json->encode($plan), $json->encode($expected), 'complete independent expected IR, including every absence/unchanged field');
    is($json->encode([$actor, $child]), $before, 'complete source/IR JSON kinds/data unchanged');
    if (my $dir = $ENV{FSMGEN_OUTPUT_READ_CAPTURE}) {
        write_file("$dir/$name.json", $json->encode(normalize_repository_paths({actor => $actor, transaction => $tx,
            child => $child, prepared => $plan, expected => $expected,
            source => $active_source, packages => $active_packages,
            emitted => FSM::Scheduler::ISF::Emitter::FSM->new->emit($plan)}, abs_path('.'))) . "\n");
    }
    return $plan;
}
sub collision_source {
    my ($name) = @_;
    return '(actor view_'.$name.' (clock clk) (reset (rst_n sync active_low))'
        .' (types (type frame (record (tag (bits 2)) (payload (signed (four_state (bits 3)))))))'
        .' (interface (input request) (output '.$name.' (type frame)) (output seen (width 3)) (output ack))'
        .' (storage (var held (type frame) (reset 5)))'
        .' (transaction worker (params (MODE 0)) (ports (output result (width 3)))'
        .' (set result '.$name.'.payload) (complete ack))'
        .' (transaction main (on request) (set '.$name.' held)'
        .' (do worker (params (MODE 1)) (bind (output result seen))) (complete ack)))';
}
sub write_file {open my $fh, '>:raw', $_[0] or die $!; print {$fh} $_[1] or die $!; close $fh or die $!}
sub read_file {open my $fh, '<:raw', $_[0] or die $!; local $/; return <$fh>}
sub literal_guard {
    my ($guard, $replacements) = @_;
    return unless $guard;
    for my $key (qw(port expr signal value)) {
        $guard->{$key} = $replacements->{$guard->{$key}} if defined($guard->{$key}) && !ref($guard->{$key})
            && exists $replacements->{$guard->{$key}};
    }
}
