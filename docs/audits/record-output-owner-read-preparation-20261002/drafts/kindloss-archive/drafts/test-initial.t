use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use Storable qw(dclone);
use JSON::PP;
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::FormalLowering;
use FSM::Scheduler::ISF::DomainSource qw(_domain_actor_for_scheduled_artifact);
use FSM::Scheduler::ISF::ChildOutputReads;
use FSM::Scheduler::ISF::Emitter::FSM;

my $json = JSON::PP->new->canonical;
my $work = tempdir(CLEANUP => 1);
my $spec = {kind => 'record', width => 5, signed => 0, member_order => [qw(tag payload)], members => {
    tag => {kind => 'bits', width => 2, signed => 0},
    payload => {kind => 'bits', width => 3, signed => 1, state_model => 'four_state'},
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
            $case eq 'scalar_reader' ? 3 : 5, $case =~ /imported/ ? 'shared.frame' : 'frame');
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
        for my $mutation (qw(history port entry path prepared)) {
            my $bad = dclone($child);
            my ($entry) = grep {$_->{kind} eq 'entry'} @{$bad->{states}};
            my ($history) = grep {$_->{kind} eq 'child_activation'} @{$bad->{dt_blocks}};
            if ($mutation eq 'history') {$bad->{storage_roles}{$history->{name}} = 'sample_alias'}
            elsif ($mutation eq 'port') {$_->{width} = 5 for grep {$_->{name} eq 'start'} @{$bad->{ports}}}
            elsif ($mutation eq 'entry') {$entry->{transitions}[0]{condition}{expr} = $name}
            elsif ($mutation eq 'prepared') {$bad->{actor_output_reads} = []}
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
done_testing;

sub actual {
    my ($path, $domain) = @_;
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
    my ($child, $name, $type, $width, $alias_type) = @_;
    my $expected = dclone($child);
    $expected->{actor_output_reads} = [];
    if (defined $name) {
        my $alias = "isf_output_read_$name";
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
        write_file("$dir/$name.json", $json->encode({actor => $actor, transaction => $tx,
            child => $child, prepared => $plan, expected => $expected,
            emitted => FSM::Scheduler::ISF::Emitter::FSM->new->emit($plan)}) . "\n");
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
