use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::FormalLowering;
use FSM::Scheduler::ISF::DomainSource qw(_domain_actor_for_scheduled_artifact);

my $json = JSON::PP->new->canonical;
my $sources = 'docs/audits/record-output-generated-ingress-20261002/sources';
my $spec = {kind => 'record', width => 5, signed => 0, member_order => [qw(tag payload)], members => {
    tag => {kind => 'bits', width => 2, signed => 0},
    payload => {kind => 'bits', width => 3, signed => 1, state_model => 'four_state'},
}};
my $fields = [
    {path => 'tag', width => 2, msb => 4, lsb => 3, signed => 0},
    {path => 'payload', width => 3, msb => 2, lsb => 0, signed => 1, state_model => 'four_state'},
];
# Literal scope membership is independent of the capture recipe/compiler.
my @cases = qw(direct local_do spawn_writer blocking_writer spawn_readers storage_then_output
    unused_with_child competing_children formal_shadow imported_writer scalar_control scalar_writer
    scalar_reader input_control domain_direct domain_writer domain_readers imported_domain_blocking);
my %direct = map {($_, 1)} qw(direct local_do domain_direct);
my %without_record_output = map {($_, 1)} qw(scalar_control scalar_writer scalar_reader input_control);
my %writers = map {($_, 1)} qw(spawn_writer blocking_writer competing_children imported_writer
    domain_writer imported_domain_blocking);
my %readers = map {($_, 1)} qw(spawn_readers domain_readers);

for my $name (@cases) {
    subtest $name => sub {
        my $actor = FSM::Adapter::ISF->new->parse_file("$sources/$name.isf");
        my $before = $json->encode($actor);
        my $domains = $name =~ /domain/;
        my $type = $name =~ /imported/ ? 'shared.frame' : 'frame';
        my @ports = (port('start', 'input', 1),
            $without_record_output{$name} && $name ne 'input_control'
                ? port('incoming', 'input', 5) : record_port('incoming', 'input', $type),
            $name eq 'input_control' ? record_port('packet', 'input', $type) : (),
            $domains ? port('unused', 'input', 1) : (),
            $name eq 'input_control' ? () : $without_record_output{$name}
                ? port('packet', 'output', $name eq 'scalar_reader' ? 3 : 5)
                : record_port('packet', 'output', $type),
            port('seen', 'output', 3), port('again', 'output', 3), port('done', 'output', 1));
        if ($domains) {$_->{domain} = $_->{name} eq 'unused' ? 'idle' : 'io' for @ports}
        same($actor->{interface_port_metadata}, \@ports, 'complete literal declaration roles/order/type/layout');
        same($actor->{storage}[0]{type_spec}, $spec, 'entire independently authored packed storage type');
        unless ($without_record_output{$name}) {
            my ($output) = grep {$_->{name} eq 'packet'} @{$actor->{interface}{outputs}};
            same($output->{type_spec}, $spec, 'complete record output recursive type');
        }
        my $scheduler = FSM::Scheduler::ISF->new;
        my $formal = FSM::Scheduler::ISF::FormalLowering->prepare($scheduler->{ir}, $actor);
        my $effective = $formal ? $formal->{actor} : $actor;
        my $ir = $scheduler->{ir}->build_module($effective);
        if ($domains) {
            same([map {$_->{name}} @{$ir->{domain_partition}{domains}}], [qw(idle io)],
                'complete actual partition keeps both explicit domains');
            my ($domain) = grep {$_->{name} eq 'io'} @{$ir->{domain_partition}{domains}};
            my $selected = _domain_actor_for_scheduled_artifact($effective, $domain, 'idle');
            same($selected->{interface_port_metadata}, [grep {$_->{domain} eq 'io'} @ports],
                'actual canonical selected source keeps only owning declarations');
            $ir = $scheduler->{ir}->build_module($selected);
        }
        same([sort keys %{$ir->{children}}], $direct{$name} ? [] : ['worker'],
            'complete generated definition membership');
        if (!$direct{$name}) {
            my $child = $ir->{children}{worker};
            my @instances = $name =~ /blocking/ ? ('main_worker_do_0')
                : $readers{$name} || $name eq 'competing_children' ? qw(left right) : ('one');
            same([map {$_->{instance}} @{$ir->{spawn_instances}}], \@instances,
                'all actual bound instances are independently named');
            if ($writers{$name}) {
                same($child->{ports}, [port('start', 'input', 1), port('done', 'output', 1),
                    port('packet', 'output', 5), {name => 'held', direction => 'input', width => 5, isf_handoff => 1}],
                    'actual writer exposes packet but only has the existing storage read handoff');
                same(assignments($child, 'packet'), [{lhs => 'packet', rhs => 'held', op => '<-', source_kind => 'set'}],
                    'original child whole-output write exists at its original state');
                same(assignments($ir, 'packet'), [], 'owner has no generated packet update yet');
                ok(!(grep {exists $_->{actor_output_writes}} @{$ir->{spawn_instances}}),
                    'no output mapping is invented from storage mappings');
            } elsif ($readers{$name}) {
                same($child->{ports}, [port('start', 'input', 1), port('done', 'output', 1), port('result', 'output', 3)],
                    'actual reader has no packet input before owner-view repair');
                same(assignments($child, 'result'), [{lhs => 'result', rhs => 'packet.payload', op => '<-', source_kind => 'set'}],
                    'actual child operand still requires the missing live owner view');
            } elsif ($name eq 'formal_shadow') {
                same($child->{ports}, [port('start', 'input', 1), port('done', 'output', 1), port('packet', 'output', 3)],
                    'nearest scalar formal remains three bits, not the actor record');
                same(assignments($child, 'packet'), [{lhs => 'packet', rhs => '3', op => '<-', source_kind => 'set'}],
                    'scalar formal write retains its distinct local identity');
            } elsif ($name eq 'storage_then_output') {
                same($child->{actor_storage_writes}, [{name => 'held', width => 5, type => 'frame', type_spec => $spec,
                    data_port => 'isf_write_held_data', enable_port => 'isf_write_held_enable'}],
                    'existing generated storage write has the complete separate typed handoff');
                same(assignments($ir, 'packet'), [{lhs => 'packet', rhs => 'held', op => '<-', source_kind => 'set'}],
                    'later owner output copy remains a direct write');
            } elsif ($name eq 'input_control') {
                same($child->{ports}, [port('start', 'input', 1), port('packet', 'input', 5),
                    port('done', 'output', 1), port('result', 'output', 3)],
                    'accepted record input control has a real inherited reader input');
            } elsif ($name eq 'unused_with_child') {
                same($child->{ports}, [port('start', 'input', 1), port('done', 'output', 1)],
                    'unused output never becomes a child declaration');
            }
        }
        for my $method (qw(lower report)) {
            my $ok = eval {$scheduler->$method($actor); 1};
            my $error = $@;
            if ($direct{$name} || $without_record_output{$name}) {
                ok($ok, "$method scheduler control passes (not a strict realization claim)") or diag($error);
            } else {
                ok(!$ok, "$method never publishes an unqualified generated record mapping");
                like($error, qr/\AInvalid record-output writer inventory: generated record-output mappings require separate qualification/,
                    "$method exact mandatory gate, including unused output and scalar shadow controls");
            }
        }
        is($json->encode($actor), $before, 'complete first-touch caller JSON kinds/data remain unchanged');
    };
}
done_testing;

sub assignments {
    my ($ir, $target) = @_;
    return [grep {$_->{lhs} eq $target} map {@{$_->{assignments}}}
        @{$ir->{states}}, @{$ir->{dt_blocks}}];
}
sub port {return {name => $_[0], direction => $_[1], width => $_[2]}}
sub record_port {return {name => $_[0], direction => $_[1], width => 5, type => $_[2], type_kind => 'record', fields => $fields}}
sub same {is($json->encode($_[0]), $json->encode($_[1]), $_[2])}
