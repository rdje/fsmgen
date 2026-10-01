use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Storable qw(dclone);
use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::DomainSource qw(_domain_actor_for_scheduled_artifact);
use FSM::Support::CheckDiagnostics qw(build_check_success_report build_check_failure_report);
use FSM::Support::NormalizedSemanticReport qw(build_normalized_semantic_success_report build_normalized_semantic_failure_report);
use FSM::Support::CapabilityManifest qw(build_capability_manifest);

my $json = JSON::PP->new->canonical;
my $root = abs_path('.');
my $work = tempdir(CLEANUP => 1);
my $parser = FSM::Adapter::ISF->new;
my $scheduler = FSM::Scheduler::ISF->new;
my $source = <<'ISF';
(actor port_report
  (types (type byte (bits 8)))
  (clock clk) (reset rst_n)
  (interface (output unused (width 2)) (input start)
             (input data (type byte)) (output done))
  (transaction main (on start) (complete done)))
ISF
my $expected = [
    {name => 'start', direction => 'input', width => 1},
    {name => 'data', direction => 'input', width => 8, type => 'byte', type_kind => 'bits'},
    {name => 'unused', direction => 'output', width => 2},
    {name => 'done', direction => 'output', width => 1},
];

subtest 'parser evidence, IR and schedule preserve declarations and detach owners' => sub {
    my $actor = $parser->parse_source($source, 'ports.isf');
    is_deeply($actor->{interface_port_metadata}, $expected, 'parser captures exact source-ordered declarations');
    $actor->{interface}{inputs}[1]{width} = 9;
    is($actor->{interface_port_metadata}[1]{width}, 8, 'evidence does not alias parser interface entries');
    $actor = $parser->parse_source($source, 'ports.isf');
    my $ir = $scheduler->{ir}->build_module($actor);
    is_deeply($ir->{interface_port_metadata}, $expected, 'IR carries original declarations including unused ports');
    my $report = $scheduler->{json_emitter}->report_hash($ir);
    is_deeply($report->{interface_ports}, $expected, 'schedule projects declared facts rather than inferred ports');
    $report->{interface_ports}[1]{type} = 'changed';
    is($ir->{interface_port_metadata}[1]{type}, 'byte', 'report mutation cannot alter IR');
    $ir->{interface_port_metadata}[1]{width} = 99;
    is($actor->{interface_port_metadata}[1]{width}, 8, 'IR mutation cannot alter source evidence');
    delete $actor->{interface_port_metadata};
    is($json->decode($scheduler->report($actor))->{interface_ports}, undef,
        'caller actor with no declaration evidence remains unknown');
    my $empty = $parser->parse_source('(actor empty)', 'empty.isf');
    is_deeply($json->decode($scheduler->report($empty))->{interface_ports}, [], 'known empty interface is an empty census');
};

subtest 'domain reports carry only authored owned declarations' => sub {
    my $actor = $parser->parse_file('docs/audits/domain-storage-report-20260930/domains.isf');
    my $expected = [
        {name => 'start', direction => 'input', width => 1, domain => 'core'},
        {name => 'ack', direction => 'input', width => 1, domain => 'core'},
        {name => 'aux_start', direction => 'input', width => 1, domain => 'aux'},
        {name => 'done', direction => 'output', width => 1, domain => 'core'},
        {name => 'aux_done', direction => 'output', width => 1, domain => 'aux'},
    ];
    my $ir = $scheduler->{ir}->build_module($actor);
    my $report = $json->decode($scheduler->report($actor));
    is_deeply($report->{interface_ports}, $expected, 'multi-domain top retains the complete authored interface');
    for my $domain (@{$report->{clock_domains}}) {
        my $owned = [grep { $_->{domain} eq $domain->{name} } @$expected];
        is_deeply($domain->{interface_ports}, $owned, 'domain has its exact owned declared ports');
        my ($partition) = grep { $_->{name} eq $domain->{name} } @{$ir->{domain_partition}{domains}};
        my $selected = _domain_actor_for_scheduled_artifact($actor, $partition, 'core');
        is_deeply($selected->{interface_port_metadata}, $owned, 'domain source evidence precedes private port injection');
        $selected->{interface_port_metadata}[0]{width} = 9;
        is_deeply($actor->{interface_port_metadata}, $expected, 'domain metadata does not alias original evidence');
    }
    delete $actor->{interface_port_metadata};
    my $unknown = $json->decode($scheduler->report($actor));
    is($unknown->{interface_ports}, undef, 'unknown top metadata remains null');
    is($_->{interface_ports}, undef, 'unknown domain metadata remains null') for @{$unknown->{clock_domains}};
    my $single = $parser->parse_source(
        '(actor single (clock-domains (domain only (clock clk)))'
        . ' (interface (input start) (output done)) (transaction main (on start) (complete done)))', 'single.isf');
    my $single_report = $json->decode($scheduler->report($single));
    is_deeply($single_report->{clock_domains}[0]{interface_ports}, [
        {name => 'start', direction => 'input', width => 1, domain => 'only'},
        {name => 'done', direction => 'output', width => 1, domain => 'only'},
    ], 'named single-domain module has concrete declaration metadata');
};

subtest 'generated transaction child handoffs are not actor declarations' => sub {
    my $actor = $parser->parse_source(
        '(actor generated (interface (input start) (output done))'
        . ' (transaction main (on start) (spawn worker as w0) (await_all done) (complete done))'
        . ' (transaction worker (wait 1)))', 'generated.isf');
    my $ir = $scheduler->{ir}->build_module($actor);
    ok(keys(%{$ir->{children}}), 'actual generated child exists');
    for my $child (values %{$ir->{children}}) {
        ok(@{$child->{ports}}, 'child has generated hardware ports');
        is($scheduler->{json_emitter}->report_hash($child)->{interface_ports}, undef,
            'private child ports do not become declared actor interface facts');
    }
    is_deeply($scheduler->{json_emitter}->report_hash($ir)->{interface_ports}, [
        {name => 'start', direction => 'input', width => 1},
        {name => 'done', direction => 'output', width => 1},
    ], 'parent metadata excludes generated handoffs');
    my $crossing = $parser->parse_file('isf/clock_domain_event_crossing.isf');
    my $crossed_ir = $scheduler->{ir}->build_module($crossing);
    my $crossed_report = $json->decode($scheduler->report($crossing));
    my %owned = (
        source => [{name => 'bus_start', direction => 'input', width => 1, domain => 'source'}],
        core => [{name => 'core_seen', direction => 'output', width => 1, domain => 'core'}],
    );
    for my $domain (@{$crossed_ir->{domain_partition}{domains}}) {
        my $selected = _domain_actor_for_scheduled_artifact($crossing, $domain, 'source');
        my $hardware_count = @{$selected->{interface}{inputs}} + @{$selected->{interface}{outputs}};
        cmp_ok($hardware_count, '>', scalar(@{$owned{$domain->{name}}}), 'event domain has actual injected private ports');
        is_deeply($selected->{interface_port_metadata}, $owned{$domain->{name}}, 'injected handshake ports are excluded from declarations');
        my ($published) = grep { $_->{name} eq $domain->{name} } @{$crossed_report->{clock_domains}};
        is_deeply($published->{interface_ports}, $owned{$domain->{name}}, 'actual crossing schedule excludes private endpoints');
    }
};

subtest 'shared source success projections distinguish supplied null and absent evidence' => sub {
    for my $build (\&build_check_success_report, \&build_normalized_semantic_success_report) {
        my $report = $build->(input => 'ports.isf', source_file => 'ports.isf', interface_ports => $expected);
        is_deeply($report->{source}{interface_ports}, $expected, 'success receives complete declared metadata');
        $report->{source}{interface_ports}[0]{width} = 7;
        is($expected->[0]{width}, 1, 'success snapshot detached');
        is_deeply($build->(interface_ports => [])->{source}{interface_ports}, [], 'known empty remains empty');
        my $unknown = $build->(interface_ports => undef);
        ok(exists($unknown->{source}{interface_ports}), 'explicit unknown has a slot');
        is($unknown->{source}{interface_ports}, undef, 'explicit unknown is null');
        ok(!exists($build->()->{source}{interface_ports}), 'absent source argument does not invent ISF metadata');
    }
    for my $build (\&build_check_failure_report, \&build_normalized_semantic_failure_report) {
        ok(!exists($build->(message => 'Error: bad source', interface_ports => {})
            ->{source}{interface_ports}), 'failure ignores even malformed successful-source evidence');
    }
};

subtest 'native source reports publish scalar/imported declarations and preserve failure boundaries' => sub {
    write_file("$work/shared.fsm", '(?pkg:shared (+types (type byte (bits 8))))');
    my $imported = $source;
    $imported =~ s/\(types \(type byte \(bits 8\)\)\)/(imports (package shared))/;
    $imported =~ s/\(type byte\)/(type shared.byte)/;
    for my $case (['local.isf', $source, $expected], ['imported.isf', $imported,
        [map { my %p = %$_; $p{type} = 'shared.byte' if exists $p{type}; \%p } @$expected]],
        ['empty.isf', '(actor empty)', []],
        ['bad.isf', '(actor bad (interface (input data (width 0))))', undef],
        ['record.isf', '(actor refused (types (type frame (record (flag bit))))'
            . ' (interface (output packet (type frame))) (transaction main (set packet.flag 1)))', undef],
        ['direct.fsm', '(?fsm:direct (+system (clock clk) (areset rst_n)) (idle (-> idle)))', undef]) {
        my $path = "$work/$case->[0]"; write_file($path, $case->[1]); $path =~ s/^\Q$root\E\///;
        for my $flags ([qw(--strict --check --json)], [qw(--strict --emit-semantic-json)]) {
            my $result = capture([$^X, 'bin/fsmgen', @$flags, $path]);
            my $failure = $case->[0] eq 'bad.isf' || $case->[0] eq 'record.isf';
            is($result->{exit_code}, $failure ? 1 : 0, 'native admission unchanged');
            is($result->{stderr}, '', 'machine-report stderr clean');
            my $report = $json->decode($result->{stdout});
            if (defined($case->[2])) {
                is_deeply($report->{source}{interface_ports}, $case->[2], 'exact independently expected native declarations');
            } else {
                ok(!exists($report->{source}{interface_ports}), 'failure/unrelated source has no ISF declarations');
            }
            like($json->encode($report->{diagnostics}), qr/record output field writes are not yet admitted/,
                'record output field writer retains contextual refusal') if $case->[0] eq 'record.isf';
        }
    }
};

subtest 'capabilities expose the same closed declaration schema at source and schedule' => sub {
    my $manifest = build_capability_manifest();
    my $schedule = $manifest->{embedding}{isf_public_interface};
    my $contract = $schedule->{schedule_report_interface_ports};
    is_deeply($contract->{entry_keys}, [qw(name direction width)], 'required port key family');
    is_deeply($contract->{optional_entry_keys}, [qw(type type_kind domain fields)], 'optional port key family');
    is_deeply($contract->{field_keys}, [qw(path width lsb msb signed)], 'record scalar-leaf family prepared');
    is_deeply($contract->{optional_field_keys}, ['state_model'], 'state-model presence is optional');
    is_deeply($contract->{direction_values}, [qw(input output)], 'closed direction values');
    is_deeply($contract->{type_kind_values}, [qw(bit bits record)], 'closed resolved root kinds');
    is_deeply($contract->{field_signed_values}, [0, 1], 'closed scalar signed values');
    is_deeply($contract->{field_state_model_values}, [qw(two_state four_state)], 'closed scalar state models');
    is_deeply($manifest->{diagnostics}{check_json}{source_optional_fields}{interface_ports}, $contract, 'shared check contract');
    is_deeply($manifest->{semantic_exports}{normalized_semantic_json}{source_optional_fields}{interface_ports}, $contract,
        'shared semantic contract');
    ok(grep($_ eq 'interface_ports', @{$schedule->{schedule_report_top_level_keys}}), 'schedule discovery includes new field');
    ok(grep($_ eq 'interface_ports', @{$schedule->{schedule_report_clock_domain_keys}}), 'domain discovery includes new field');
    for my $path ('docs/isf-spec/12-downstream-rules-artifacts-reports.md',
                  'docs/isf-spec/22-public-interface-reports-evolution.md') {
        my $text = read_file($path);
        my ($list) = $text =~ /```text\n(schema_version\n.*?)```/s;
        ok(defined($list), 'maintained report key list exists');
        my @keys = split /\s+/, $list // '';
        is_deeply([sort @keys], [sort @{$schedule->{schedule_report_top_level_keys}}],
            'maintained report key list includes every advertised field exactly once');
    }
};

subtest 'mdBook declaration example produces exactly its documented array' => sub {
    my ($section) = read_file('docs/book/src/13a-actor-interface.md')
        =~ /### Declared interface metadata\n(.*?)## Actor-Owned Storage/s;
    my ($source) = ($section // '') =~ /```lisp\n(.*?)```/s;
    my ($array) = ($section // '') =~ /```json\n(.*?)```/s;
    ok(defined($source) && defined($array), 'runnable example and independent expected JSON exist');
    my $path = "$work/book-example.isf"; write_file($path, $source // '');
    my $expected = $json->decode($array // 'null');
    for my $flags ([qw(--strict --check --json)], [qw(--strict --emit-semantic-json)], ['--emit-schedule-json']) {
        my $result = capture([$^X, 'bin/fsmgen', @$flags, $path]);
        is($result->{exit_code}, 0, 'book example native query succeeds');
        is($result->{stderr}, '', 'book query stderr clean');
        my $report = $json->decode($result->{stdout});
        my $ports = $flags->[0] eq '--emit-schedule-json' ? $report->{interface_ports} : $report->{source}{interface_ports};
        is_deeply($ports, $expected, 'book example complete declarations equal documented JSON');
    }
};

done_testing();
sub capture { FSM::Test::SourceQueryRunner::_capture($_[0], $_[1] // '') }
sub read_file { open my $fh, '<', $_[0] or die $!; local $/; return <$fh>; }
sub write_file { open my $fh, '>', $_[0] or die $!; print {$fh} $_[1] or die $!; close $fh or die $!; }
