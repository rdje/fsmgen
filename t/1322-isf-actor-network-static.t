#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::ISFPublicInterfaceContract qw(
    isf_public_interface_schedule_report_actor_network_association_schedule_keys
    isf_public_interface_schedule_report_actor_network_data_movement_keys
    isf_public_interface_schedule_report_actor_network_event_wait_keys
    isf_public_interface_schedule_report_actor_network_generated_top_keys
    isf_public_interface_schedule_report_actor_network_group_schedule_keys
    isf_public_interface_schedule_report_actor_network_group_keys
    isf_public_interface_schedule_report_actor_network_instance_keys
    isf_public_interface_schedule_report_actor_network_keys
    isf_public_interface_schedule_report_actor_network_resolved_instance_keys
    isf_public_interface_schedule_report_actor_network_transaction_trigger_keys
);

subtest 'actor-body static instance is parsed, lowered, and reported' => sub {
    my $source = actor_body_network_source('atl_static_network');
    my $actor = parse_source($source, 'atl-static-network.isf');

    is_deeply(
        $actor->{actor_network},
        {
            kind      => 'static_declaration',
            instances => [
                {
                    name        => 'reader',
                    actor_type  => 'packet_reader',
                    declaration => 'actor',
                },
            ],
            groups => [],
            association_schedules => [],
            group_schedules => [],
            data_movements => [],
            event_waits => [],
            transaction_triggers => [],
        },
        'parser preserves actor-body static actor-network instance identity',
    );

    my $scheduler = FSM::Scheduler::ISF->new();
    my $lowered = $scheduler->lower($actor);
    is_deeply(
        [sort keys %{$lowered->{files}}],
        ['atl_static_network.fsm'],
        'static actor-network declaration is report-only in this slice and emits no child artifacts',
    );

    my $report = decode_json($scheduler->report($actor));
    assert_actor_network_report(
        $report,
        {
            kind      => 'static_declaration',
            instances => [
                {
                    name        => 'reader',
                    actor_type  => 'packet_reader',
                    declaration => 'actor',
                },
            ],
            groups => [],
            group_schedules => [],
            data_movements => [],
            event_waits => [],
            transaction_triggers => [],
        },
        'actor-body network report',
    );

    my $path = write_temp_isf($source);
    my $cli_report = run_schedule_json($path, 'actor-body static actor network');
    is_deeply($cli_report, $report, 'CLI schedule JSON matches in-process report for actor-body static actor network');
};

subtest 'multiple top-level actor roots fail closed before ATL child type resolution' => sub {
    parse_fails_like(
        <<'ISF',
(actor atl_parent
  (clock clk)
  (interface (input start) (output done))
  (instance worker of packet_worker)
  (transaction run
    (on start)
    (trigger worker.process)
    (complete done)))

(actor packet_worker
  (clock clk)
  (interface (input process_start) (output done))
  (transaction process
    (on process_start)
    (complete done)))
ISF
        qr/multiple top-level \(actor \.\.\.\) roots: atl_parent, packet_worker.*sibling actor roots are not ATL child type definitions/s,
        'sibling actor roots are rejected before generated ATL child type resolution',
    );

    my $actor = parse_source(
        <<'ISF',
(actor one_actor_with_library_root
  (clock clk)
  (interface (input start) (output done))
  (transaction run
    (on start)
    (complete done)))

(library atl.helper
  (exports (actor helper))
  (actor helper
    (clock clk)
    (interface (input start) (output done))
    (transaction run
      (on start)
      (complete done))))
ISF
        'one-actor-plus-library-root.isf',
    );
    is($actor->{actor_name}, 'one_actor_with_library_root', 'one actor root plus library root remains accepted');
};

subtest 'library-qualified ATL actor type syntax emits child artifacts without an ATL top' => sub {
    parse_fails_like(
        <<'ISF',
(actor atl_parent
  (clock clk)
  (interface (input start) (output done))
  (instance worker of pkt_lib.packet_worker)
  (transaction run
    (on start)
    (complete done)))
ISF
        qr/ATL library-qualified static actor instance type 'pkt_lib\.packet_worker' requires an '\(imports \(library \.\.\. as alias\)\)' clause.*valid ATL actor type resolution is required before generated child emission/s,
        'library-qualified actor type without imports fails closed',
    );

    parse_fails_like(
        <<'ISF',
(actor atl_parent
  (clock clk)
  (interface (input start) (output done))
  (imports (library common.packet as pkt_lib))
  (instance worker of other_lib.packet_worker)
  (transaction run
    (on start)
    (complete done)))

(library common.packet
  (exports (actor packet_worker))
  (actor packet_worker
    (clock clk)
    (interface (input start) (output done))
    (transaction process
      (on start)
      (complete done))))
ISF
        qr/ATL static actor instance 'worker' type 'other_lib\.packet_worker' must use '\(instance worker of ALIAS\.EXPORT\)' where ALIAS is an imported library alias.*valid ATL actor type resolution is required before generated child emission/s,
        'unknown library-qualified actor type alias fails closed',
    );

    parse_fails_like(
        <<'ISF',
(actor atl_parent
  (clock clk)
  (interface (input start) (output done))
  (imports (library common.packet))
  (instance worker of common.packet.packet_worker)
  (transaction run
    (on start)
    (complete done)))

(library common.packet
  (exports (actor packet_worker))
  (actor packet_worker
    (clock clk)
    (interface (input start) (output done))
    (transaction process
      (on start)
      (complete done))))
ISF
        qr/ATL static actor instance 'worker' type 'common\.packet\.packet_worker' must use an explicit HDL identifier library alias from '\(imports \(library common\.packet as ALIAS\)\)'.*valid ATL actor type resolution is required before generated child emission/s,
        'library-qualified actor type requires explicit HDL import alias',
    );

    parse_fails_like(
        <<'ISF',
(actor atl_parent
  (clock clk)
  (interface (input start) (output done))
  (imports (library common.packet as pkt_lib))
  (instance worker of pkt_lib.packet_writer)
  (transaction run
    (on start)
    (complete done)))

(library common.packet
  (exports (actor packet_worker))
  (actor packet_worker
    (clock clk)
    (interface (input start) (output done))
    (transaction process
      (on start)
      (complete done))))
ISF
        qr/ATL static actor instance 'worker' type 'pkt_lib\.packet_writer' references missing actor export 'packet_writer' from library 'common\.packet'.*valid ATL actor type resolution is required before generated child emission/s,
        'unknown library actor export fails closed',
    );

    my $same_source = <<'ISF';
(actor atl_parent
  (clock clk)
  (interface (input start) (output done))
  (imports (library common.packet as pkt_lib))
  (instance worker of pkt_lib.packet_worker)
  (transaction run
    (on start)
    (complete done)))

(library common.packet
  (exports (actor packet_worker))
  (actor packet_worker
    (clock clk)
    (interface (input start) (output done))
    (transaction process
      (on start)
      (complete done))))
ISF
    assert_resolved_actor_type_metadata(
        parse_source($same_source, 'atl-type-resolution-same-source.isf'),
        'same-source library root',
    );

    my $dir = tempdir(CLEANUP => 1);
    write_packet_library($dir);
    my $top = File::Spec->catfile($dir, 'atl-type-resolution-external.isf');
    write_file($top, <<'ISF');
(actor external_atl_parent
  (clock clk)
  (interface (input start) (output done))
  (imports (library common.packet as pkt_lib))
  (instance worker of pkt_lib.packet_worker)
  (transaction run
    (on start)
    (complete done)))
ISF
    assert_resolved_actor_type_metadata(
        FSM::Adapter::ISF->new()->parse_file($top),
        'external library file',
        'external_atl_parent',
    );

    lower_fails_like(
        <<'ISF',
(actor atl_parent
  (clock clk)
  (interface (input start) (output done))
  (imports (library common.packet as pkt_lib))
  (instance worker of pkt_lib.packet_worker)
  (transaction atl_parent__worker
    (on start)
    (complete done))
  (transaction run
    (on start)
    (spawn atl_parent__worker as w0)
    (await_all done)
    (complete done)))

(library common.packet
  (exports (actor packet_worker))
  (actor packet_worker
    (clock clk)
    (interface (input start) (output done))
    (transaction process
      (on start)
      (complete done))))
ISF
        qr/ATL static actor instance 'worker' generated module 'atl_parent__worker' conflicts with another generated child/,
        'resolved ATL child artifact name conflicts with generated transaction child',
    );
};

subtest 'static concurrent group metadata is parsed, lowered, and reported' => sub {
    my $source = <<'ISF';
(actor atl_static_group
  (clock clk)
  (interface (input start) (output done))
  (instance reader of packet_reader)
  (instance writer of packet_writer)
  (group pipeline
    (members reader writer)
    (mode concurrent))
  (transaction run
    (on start)
    (complete done)))
ISF
    my $actor = parse_source($source, 'atl-static-group.isf');
    my $expected_group = {
        name        => 'pipeline',
        members     => [qw(reader writer)],
        mode        => 'concurrent',
        declaration => 'group',
        source      => 'actor_body',
        scheduling  => 'metadata_only',
    };

    is_deeply(
        $actor->{actor_network}{groups},
        [ $expected_group ],
        'parser records the selected static concurrent group metadata',
    );

    my $scheduler = FSM::Scheduler::ISF->new();
    my $lowered = $scheduler->lower($actor);
    is_deeply(
        [sort keys %{$lowered->{files}}],
        ['atl_static_group.fsm'],
        'static group metadata is report-only and emits no child artifacts or ATL top',
    );

    my $report = decode_json($scheduler->report($actor));
    assert_actor_network_report(
        $report,
        {
            kind      => 'static_declaration',
            instances => [
                {
                    name        => 'reader',
                    actor_type  => 'packet_reader',
                    declaration => 'actor',
                },
                {
                    name        => 'writer',
                    actor_type  => 'packet_writer',
                    declaration => 'actor',
                },
            ],
            groups => [ $expected_group ],
            group_schedules => [],
            data_movements => [],
            event_waits => [],
            transaction_triggers => [],
        },
        'static concurrent group report',
    );
};

subtest 'selected concurrent group trigger batch lowers to one parent state' => sub {
    my $source = <<'ISF';
(actor atl_group_trigger_batch
  (clock clk)
  (interface (input start) (output done))
  (instance reader of packet_reader)
  (instance writer of packet_writer)
  (group pipeline
    (members reader writer)
    (mode concurrent))
  (transaction run
    (on start)
    (trigger reader.capture)
    (trigger writer.emit)
    (complete done)))
ISF
    my $actor = parse_source($source, 'atl-group-trigger-batch.isf');
    my $expected_group = {
        name        => 'pipeline',
        members     => [qw(reader writer)],
        mode        => 'concurrent',
        declaration => 'group',
        source      => 'actor_body',
        scheduling  => 'metadata_only',
    };
    my $expected_triggers = [
        {
            owner_transaction  => 'run',
            context            => 'transaction_body',
            instance           => 'reader',
            target_transaction => 'capture',
            signal             => 'reader_capture_start',
            sink               => 'external_handoff',
        },
        {
            owner_transaction  => 'run',
            context            => 'transaction_body',
            instance           => 'writer',
            target_transaction => 'emit',
            signal             => 'writer_emit_start',
            sink               => 'external_handoff',
        },
    ];
    my $expected_group_schedule = {
        group               => 'pipeline',
        owner_transaction   => 'run',
        context             => 'transaction_body',
        members             => [qw(reader writer)],
        target_transactions => [qw(capture emit)],
        signals             => [qw(reader_capture_start writer_emit_start)],
        schedule            => 'same_cycle_external_trigger_batch',
        dependency_policy   => 'declared_group_distinct_members',
        storage             => 'none',
        source              => 'parent_trigger_state',
        sink                => 'external_handoff',
    };
    my $expected_association_schedule = {
        association         => 'run_trigger_batch',
        kind                => 'temporary_trigger_batch',
        lifetime            => 'task_scoped',
        owner_transaction   => 'run',
        context             => 'transaction_body',
        members             => [qw(reader writer)],
        target_transactions => [qw(capture emit)],
        signals             => [qw(reader_capture_start writer_emit_start)],
        schedule            => 'same_cycle_external_trigger_batch',
        dependency_policy   => 'declared_group_distinct_members',
        storage             => 'none',
        source              => 'parent_trigger_state',
        sink                => 'external_handoff',
    };

    is_deeply(
        $actor->{actor_network}{transaction_triggers},
        $expected_triggers,
        'parser preserves per-target actor transaction trigger metadata for the group batch',
    );
    is_deeply(
        $actor->{actor_network}{group_schedules},
        [ $expected_group_schedule ],
        'parser records the selected same-cycle group trigger schedule metadata',
    );
    is_deeply(
        $actor->{actor_network}{association_schedules},
        [ $expected_association_schedule ],
        'parser records canonical temporary association schedule metadata',
    );

    my $scheduler = FSM::Scheduler::ISF->new();
    my $lowered = $scheduler->lower($actor);
    my $fsm = $lowered->{files}{'atl_group_trigger_batch.fsm'};
    ok($fsm, 'group trigger batch emits the parent scheduled .fsm');
    is_deeply(
        [sort keys %{$lowered->{files}}],
        ['atl_group_trigger_batch.fsm'],
        'group trigger batch does not emit ATL child artifacts or a generated top',
    );
    like($fsm, qr/run_atl_trigger_batch_/, 'scheduled .fsm contains one grouped trigger state');
    unlike($fsm, qr/run_atl_trigger_[0-9]/, 'scheduled .fsm does not split the grouped trigger batch into per-trigger states');
    like($fsm, qr/\(<1 \(reader_capture_start> 1\)\)/, 'scheduled .fsm pulses the reader trigger handoff');
    like($fsm, qr/\(<1 \(writer_emit_start> 1\)\)/, 'scheduled .fsm pulses the writer trigger handoff');

    my $report = decode_json($scheduler->report($actor));
    assert_actor_network_report(
        $report,
        {
            kind      => 'static_declaration',
            instances => [
                {
                    name        => 'reader',
                    actor_type  => 'packet_reader',
                    declaration => 'actor',
                },
                {
                    name        => 'writer',
                    actor_type  => 'packet_writer',
                    declaration => 'actor',
                },
            ],
            groups => [ $expected_group ],
            association_schedules => [ $expected_association_schedule ],
            group_schedules => [ $expected_group_schedule ],
            data_movements => [],
            event_waits => [],
            transaction_triggers => $expected_triggers,
        },
        'group trigger batch report',
    , 'group-transaction-trigger.isf');
};

subtest 'unsupported static graph shapes fail closed' => sub {
    parse_fails_like(
        <<'ISF',
(actor two_instances
  (clock clk)
  (interface (input start) (output done))
  (instance reader of packet_reader)
  (instance writer of packet_writer)
  (transaction run (on start) (complete done)))
ISF
        qr/currently accepts exactly one actor instance/,
        'multiple static instances are rejected until multi-instance scheduling ships',
    );

    parse_fails_like(
        <<'ISF',
(actor group_single_member
  (clock clk)
  (interface (input start) (output done))
  (group pipeline (members reader) (mode concurrent))
  (transaction run (on start) (complete done)))
ISF
        qr/ATL concurrent group 'pipeline' requires at least two members/,
        'static concurrent groups require at least two members',
    );

    parse_fails_like(
        <<'ISF',
(actor group_event_wait
  (clock clk)
  (interface (input start) (output done))
  (instance reader of packet_reader)
  (instance writer of packet_writer)
  (group pipeline (members reader writer) (mode concurrent))
  (transaction run
    (on start)
    (await reader.done)
    (complete done)))
ISF
        qr/ATL concurrent group metadata cannot be combined with actor event waits/,
        'static concurrent group metadata does not combine with actor event waits',
    );

    my $single_trigger_with_group = parse_source(<<'ISF', 'group-transaction-trigger.isf');
(actor group_transaction_trigger
  (clock clk)
  (interface (input start) (output done))
  (instance reader of packet_reader)
  (instance writer of packet_writer)
  (group pipeline (members reader writer) (mode concurrent))
  (transaction run
    (on start)
    (trigger writer.capture)
    (complete done)))
ISF
    is_deeply(
        $single_trigger_with_group->{actor_network}{group_schedules},
        [],
        'a static group declaration does not force a temporary association for one trigger',
    );
    is_deeply(
        $single_trigger_with_group->{actor_network}{association_schedules},
        [],
        'a static group declaration does not force canonical association metadata for one trigger',
    );

    parse_fails_like(
        <<'ISF',
(actor unsupported_concurrent_alias
  (clock clk)
  (interface (input start) (output done))
  (concurrent pipeline reader writer)
  (transaction run (on start) (complete done)))
ISF
        qr/ATL compact concurrent group alias '\(concurrent \.\.\.\)' is reserved but not supported yet/,
        'unsupported compact concurrent group alias fails closed with ATL diagnostic',
    );

    parse_fails_like(
        <<'ISF',
(actor dynamic_instance
  (clock clk)
  (interface (input start) (output done))
  (instance (select reader writer) of packet_reader)
  (transaction run (on start) (complete done)))
ISF
        qr/static actor instance name must be a scalar HDL identifier/,
        'dynamic or non-scalar instance names fail closed',
    );

    parse_fails_like(
        <<'ISF',
(actor recursive_network
  (clock clk)
  (interface (input start) (output done))
  (instance self of recursive_network)
  (transaction run (on start) (complete done)))
ISF
        qr/cannot instantiate its own enclosing actor type/,
        'direct recursive static actor instance fails closed',
    );

    parse_fails_like(
        <<'ISF',
(actor scoped_network_rejected
  (clock clk)
  (interface (input start) (output done))
  (network
    (instance reader of packet_reader))
  (transaction run (on start) (complete done)))
ISF
        qr/direct '\(instance name of actor_type\)' actor clauses; '\(network \.\.\.\)' is not supported/,
        'scoped network wrapper is rejected',
    );
};

subtest 'selected qualified event wait lowers to parent handoff input' => sub {
    my $actor = parse_source(<<'ISF', 'atl-event-wait.isf');
(actor atl_event_wait
  (clock clk)
  (interface (input start) (output done))
  (instance reader of packet_reader)
  (transaction run
    (on start)
    (await reader.done)
    (complete done)))
ISF

    is_deeply(
        $actor->{actor_network}{event_waits},
        [
            {
                transaction => 'run',
                context     => 'transaction_body',
                instance    => 'reader',
                event       => 'done',
                signal      => 'reader_done',
                source      => 'external_handoff',
            },
        ],
        'parser records the selected actor-event wait handoff metadata',
    );

    my $scheduler = FSM::Scheduler::ISF->new();
    my $lowered = $scheduler->lower($actor);
    my $fsm = $lowered->{files}{'atl_event_wait.fsm'};
    ok($fsm, 'selected actor-event wait still emits the parent scheduled .fsm only');
    is_deeply(
        [sort keys %{$lowered->{files}}],
        ['atl_event_wait.fsm'],
        'selected actor-event wait does not emit ATL child artifacts or a generated top',
    );
    like($fsm, qr/\(reader_done 1\)/, 'scheduled .fsm exposes generated event handoff input');
    like($fsm, qr/<reader_done\s+\(\-> run_done_2\)/, 'scheduled .fsm awaits the generated event handoff input');

    my $report = decode_json($scheduler->report($actor));
    assert_actor_network_report(
        $report,
        {
            kind      => 'static_declaration',
            instances => [
                {
                    name        => 'reader',
                    actor_type  => 'packet_reader',
                    declaration => 'actor',
                },
            ],
            groups => [],
            group_schedules => [],
            data_movements => [],
            event_waits => [
                {
                    transaction => 'run',
                    context     => 'transaction_body',
                    instance    => 'reader',
                    event       => 'done',
                    signal      => 'reader_done',
                    source      => 'external_handoff',
                },
            ],
            transaction_triggers => [],
        },
        'actor-event wait report',
    );
};

subtest 'selected qualified transaction trigger lowers to parent handoff output' => sub {
    my $actor = parse_source(<<'ISF', 'atl-transaction-trigger.isf');
(actor atl_transaction_trigger
  (clock clk)
  (interface (input start) (output done))
  (instance reader of packet_reader)
  (transaction run
    (on start)
    (trigger reader.capture)
    (complete done)))
ISF

    is_deeply(
        $actor->{actor_network}{transaction_triggers},
        [
            {
                owner_transaction  => 'run',
                context            => 'transaction_body',
                instance           => 'reader',
                target_transaction => 'capture',
                signal             => 'reader_capture_start',
                sink               => 'external_handoff',
            },
        ],
        'parser records the selected actor-transaction trigger handoff metadata',
    );

    my $scheduler = FSM::Scheduler::ISF->new();
    my $lowered = $scheduler->lower($actor);
    my $fsm = $lowered->{files}{'atl_transaction_trigger.fsm'};
    ok($fsm, 'selected actor-transaction trigger still emits the parent scheduled .fsm only');
    is_deeply(
        [sort keys %{$lowered->{files}}],
        ['atl_transaction_trigger.fsm'],
        'selected actor-transaction trigger does not emit ATL child artifacts or a generated top',
    );
    like($fsm, qr/\(reader_capture_start 1\)/, 'scheduled .fsm exposes generated trigger handoff output');
    like($fsm, qr/\(<1 \(reader_capture_start> 1\)\)/, 'scheduled .fsm pulses the generated trigger handoff output');

    my $report = decode_json($scheduler->report($actor));
    assert_actor_network_report(
        $report,
        {
            kind      => 'static_declaration',
            instances => [
                {
                    name        => 'reader',
                    actor_type  => 'packet_reader',
                    declaration => 'actor',
                },
            ],
            groups => [],
            group_schedules => [],
            data_movements => [],
            event_waits => [],
            transaction_triggers => [
                {
                    owner_transaction  => 'run',
                    context            => 'transaction_body',
                    instance           => 'reader',
                    target_transaction => 'capture',
                    signal             => 'reader_capture_start',
                    sink               => 'external_handoff',
                },
            ],
        },
        'actor-transaction trigger report',
    );
};

subtest 'selected scalar actor-to-actor data movement lowers to parent handoff ports' => sub {
    my $source = <<'ISF';
(actor atl_scalar_data_movement
  (clock clk)
  (interface (input start) (output done))
  (instance producer of packet_reader)
  (instance consumer of packet_writer)
  (drive feed_consumer
    (consumer.payload producer.payload))
  (transaction run
    (on start)
    (drive feed_consumer)
    (complete done)))
ISF
    my $actor = parse_source($source, 'atl-scalar-data-movement.isf');

    my $expected_movement = {
        kind            => 'scalar_actor_handoff',
        transaction     => 'run',
        context         => 'transaction_body',
        drive           => 'feed_consumer',
        source_instance => 'producer',
        source_endpoint => 'payload',
        source_signal   => 'producer_payload',
        sink_instance   => 'consumer',
        sink_endpoint   => 'payload',
        sink_signal     => 'consumer_payload',
        width           => 1,
        width_source    => 'scalar_one_bit',
        route_lifetime  => 'drive_call_cycle',
        storage         => 'none',
        source          => 'external_handoff',
        sink            => 'external_handoff',
    };

    is_deeply(
        $actor->{drives}{feed_consumer}{body},
        [
            [ 'consumer_payload', 'producer_payload' ],
        ],
        'parser rewrites the selected ATL endpoint pair to generated parent handoff signals',
    );
    is_deeply(
        $actor->{actor_network}{data_movements},
        [ $expected_movement ],
        'parser records the selected scalar actor-to-actor data movement metadata',
    );

    my $scheduler = FSM::Scheduler::ISF->new();
    my $lowered = $scheduler->lower($actor);
    my $fsm = $lowered->{files}{'atl_scalar_data_movement.fsm'};
    ok($fsm, 'selected scalar data movement still emits the parent scheduled .fsm only');
    is_deeply(
        [sort keys %{$lowered->{files}}],
        ['atl_scalar_data_movement.fsm'],
        'selected scalar data movement does not emit ATL child artifacts or a generated top',
    );
    like($fsm, qr/\(producer_payload 1\)/, 'scheduled .fsm exposes generated source handoff input');
    like($fsm, qr/\(consumer_payload 1\)/, 'scheduled .fsm exposes generated sink handoff output');
    like($fsm, qr/\(<- \(consumer_payload>?\s+producer_payload\) <feed_consumer_start\)/,
        'drive body lowers the selected scalar handoff through the named drive request');

    my $report = decode_json($scheduler->report($actor));
    assert_actor_network_report(
        $report,
        {
            kind      => 'static_declaration',
            instances => [
                {
                    name        => 'producer',
                    actor_type  => 'packet_reader',
                    declaration => 'actor',
                },
                {
                    name        => 'consumer',
                    actor_type  => 'packet_writer',
                    declaration => 'actor',
                },
            ],
            groups => [],
            group_schedules => [],
            data_movements => [ $expected_movement ],
            event_waits => [],
            transaction_triggers => [],
        },
        'actor scalar data movement report',
    );

    my $path = write_temp_isf($source);
    my $cli_report = run_schedule_json($path, 'actor scalar data movement');
    is_deeply($cli_report, $report, 'CLI schedule JSON matches in-process report for scalar data movement');
};

subtest 'selected scalar top-level pin to actor data movement lowers to parent handoff output' => sub {
    my $source = <<'ISF';
(actor atl_pin_to_actor_movement
  (clock clk)
  (interface (input start) (input in_bit) (output done))
  (instance consumer of packet_writer)
  (drive feed_consumer
    (consumer.payload pins.in_bit))
  (transaction run
    (on start)
    (drive feed_consumer)
    (complete done)))
ISF
    my $actor = parse_source($source, 'atl-pin-to-actor-movement.isf');

    my $expected_movement = {
        kind            => 'scalar_pin_to_actor_handoff',
        transaction     => 'run',
        context         => 'transaction_body',
        drive           => 'feed_consumer',
        source_instance => 'pins',
        source_endpoint => 'in_bit',
        source_signal   => 'in_bit',
        sink_instance   => 'consumer',
        sink_endpoint   => 'payload',
        sink_signal     => 'consumer_payload',
        width           => 1,
        width_source    => 'top_level_pin_scalar_one_bit',
        route_lifetime  => 'drive_call_cycle',
        storage         => 'none',
        source          => 'top_level_pin',
        sink            => 'external_handoff',
    };

    is_deeply(
        $actor->{drives}{feed_consumer}{body},
        [
            [ 'consumer_payload', 'in_bit' ],
        ],
        'parser rewrites the selected pin-to-actor pair to generated sink handoff and existing input pin',
    );
    is_deeply(
        $actor->{actor_network}{data_movements},
        [ $expected_movement ],
        'parser records the selected scalar pin-to-actor movement metadata',
    );

    my $scheduler = FSM::Scheduler::ISF->new();
    my $lowered = $scheduler->lower($actor);
    my $fsm = $lowered->{files}{'atl_pin_to_actor_movement.fsm'};
    ok($fsm, 'selected pin-to-actor movement still emits the parent scheduled .fsm only');
    is_deeply(
        [sort keys %{$lowered->{files}}],
        ['atl_pin_to_actor_movement.fsm'],
        'selected pin-to-actor movement does not emit ATL child artifacts or a generated top',
    );
    like($fsm, qr/\(in_bit 1\)/, 'scheduled .fsm keeps the top-level input pin');
    like($fsm, qr/\(consumer_payload 1\)/, 'scheduled .fsm exposes generated actor sink handoff output');
    like($fsm, qr/\(<- \(consumer_payload>?\s+in_bit\) <feed_consumer_start\)/,
        'drive body lowers the selected pin-to-actor handoff through the named drive request');

    my $report = decode_json($scheduler->report($actor));
    assert_actor_network_report(
        $report,
        {
            kind      => 'static_declaration',
            instances => [
                {
                    name        => 'consumer',
                    actor_type  => 'packet_writer',
                    declaration => 'actor',
                },
            ],
            groups => [],
            group_schedules => [],
            data_movements => [ $expected_movement ],
            event_waits => [],
            transaction_triggers => [],
        },
        'pin-to-actor scalar data movement report',
    );
};

subtest 'selected scalar actor to top-level pin data movement lowers to parent handoff input' => sub {
    my $source = <<'ISF';
(actor atl_actor_to_pin_movement
  (clock clk)
  (interface (input start) (output out_bit) (output done))
  (instance producer of packet_reader)
  (drive publish_result
    (pins.out_bit producer.payload))
  (transaction run
    (on start)
    (drive publish_result)
    (complete done)))
ISF
    my $actor = parse_source($source, 'atl-actor-to-pin-movement.isf');

    my $expected_movement = {
        kind            => 'scalar_actor_to_pin_handoff',
        transaction     => 'run',
        context         => 'transaction_body',
        drive           => 'publish_result',
        source_instance => 'producer',
        source_endpoint => 'payload',
        source_signal   => 'producer_payload',
        sink_instance   => 'pins',
        sink_endpoint   => 'out_bit',
        sink_signal     => 'out_bit',
        width           => 1,
        width_source    => 'top_level_output_pin_scalar_one_bit',
        route_lifetime  => 'drive_call_cycle',
        storage         => 'none',
        source          => 'external_handoff',
        sink            => 'top_level_pin',
    };

    is_deeply(
        $actor->{drives}{publish_result}{body},
        [
            [ 'out_bit', 'producer_payload' ],
        ],
        'parser rewrites the selected actor-to-pin pair to existing output pin and generated source handoff',
    );
    is_deeply(
        $actor->{actor_network}{data_movements},
        [ $expected_movement ],
        'parser records the selected scalar actor-to-pin movement metadata',
    );

    my $scheduler = FSM::Scheduler::ISF->new();
    my $lowered = $scheduler->lower($actor);
    my $fsm = $lowered->{files}{'atl_actor_to_pin_movement.fsm'};
    ok($fsm, 'selected actor-to-pin movement still emits the parent scheduled .fsm only');
    is_deeply(
        [sort keys %{$lowered->{files}}],
        ['atl_actor_to_pin_movement.fsm'],
        'selected actor-to-pin movement does not emit ATL child artifacts or a generated top',
    );
    like($fsm, qr/\(producer_payload 1\)/, 'scheduled .fsm exposes generated actor source handoff input');
    like($fsm, qr/\(out_bit 1\)/, 'scheduled .fsm keeps the top-level output pin');
    like($fsm, qr/\(<- \(out_bit>?\s+producer_payload\) <publish_result_start\)/,
        'drive body lowers the selected actor-to-pin handoff through the named drive request');

    my $report = decode_json($scheduler->report($actor));
    assert_actor_network_report(
        $report,
        {
            kind      => 'static_declaration',
            instances => [
                {
                    name        => 'producer',
                    actor_type  => 'packet_reader',
                    declaration => 'actor',
                },
            ],
            groups => [],
            group_schedules => [],
            data_movements => [ $expected_movement ],
            event_waits => [],
            transaction_triggers => [],
        },
        'actor-to-pin scalar data movement report',
    );
};

subtest 'reserved endpoint-aware drive movement forms fail closed with ATL diagnostics' => sub {
    parse_fails_like(
        <<'ISF',
(actor qualified_drive_sink
  (clock clk)
  (interface (input start) (input payload) (output done))
  (instance reader of packet_reader)
  (drive feed_reader
    (reader.payload payload))
  (transaction run
    (on start)
    (drive feed_reader)
    (complete done)))
ISF
        qr/drive 'feed_reader' body ATL scalar actor-to-actor data movement source 'payload' must be a qualified static actor endpoint or selected 'pins\.input_pin' source/,
        'named drive body qualified actor sink fails closed before local dotted-name diagnostics',
    );

    parse_fails_like(
        <<'ISF',
(actor qualified_drive_source
  (clock clk)
  (interface (input start) (output payload) (output done))
  (instance reader of packet_reader)
  (drive read_payload
    (payload reader.payload))
  (transaction run
    (on start)
    (drive read_payload)
    (complete done)))
ISF
        qr/drive 'read_payload' body ATL scalar actor-to-actor data movement sink 'payload' must be a qualified static actor endpoint or selected 'pins\.output_pin' sink/,
        'named drive body qualified actor source fails closed before local dotted-name diagnostics',
    );

    parse_fails_like(
        <<'ISF',
(actor qualified_inline_drive_source
  (clock clk)
  (interface (input start) (output payload) (output done))
  (instance reader of packet_reader)
  (transaction run
    (on start)
    (drive inline_payload (payload reader.payload))
    (complete done)))
ISF
        qr/transaction 'run' inline drive source ATL actor data movement source 'reader\.payload' is reserved but not supported yet/,
        'inline drive qualified actor source fails closed before local dotted-name diagnostics',
    );

    parse_fails_like(
        <<'ISF',
(actor qualified_drive_without_call
  (clock clk)
  (interface (input start) (output done))
  (instance producer of packet_reader)
  (instance consumer of packet_writer)
  (drive feed_consumer
    (consumer.payload producer.payload))
  (transaction run
    (on start)
    (complete done)))
ISF
        qr/drive 'feed_consumer' ATL scalar actor-to-actor data movement requires exactly one top-level transaction drive call/,
        'selected data movement drive requires one top-level drive call',
    );

    parse_fails_like(
        <<'ISF',
(actor qualified_drive_nested_call
  (clock clk)
  (interface (input start) (output done))
  (instance producer of packet_reader)
  (instance consumer of packet_writer)
  (drive feed_consumer
    (consumer.payload producer.payload))
  (transaction run
    (on start)
    (when start
      (drive feed_consumer))
    (complete done)))
ISF
        qr/transaction 'run' when body ATL scalar actor-to-actor data movement drive '\(drive feed_consumer\)' is reserved for top-level transaction bodies only/,
        'selected data movement drive call remains top-level only',
    );

    parse_fails_like(
        <<'ISF',
(actor qualified_drive_multiple_pairs
  (clock clk)
  (interface (input start) (output done))
  (instance producer of packet_reader)
  (instance consumer of packet_writer)
  (drive feed_consumer
    (consumer.payload producer.payload)
    (consumer.valid producer.valid))
  (transaction run
    (on start)
    (drive feed_consumer)
    (complete done)))
ISF
        qr/drive 'feed_consumer' body ATL scalar actor-to-actor data movement requires exactly one drive-body pair/,
        'selected data movement drive body remains one scalar pair only',
    );

    parse_fails_like(
        <<'ISF',
(actor pin_to_actor_wide_source
  (clock clk)
  (interface (input start) (input in_data (width 8)) (output done))
  (instance consumer of packet_writer)
  (drive feed_consumer
    (consumer.payload pins.in_data))
  (transaction run
    (on start)
    (drive feed_consumer)
    (complete done)))
ISF
        qr/source pin 'pins\.in_data' must be one bit/,
        'pin-to-actor movement rejects wider top-level pins in the first subset',
    );

    parse_fails_like(
        <<'ISF',
(actor actor_to_pin_wide_sink
  (clock clk)
  (interface (input start) (output out_data (width 8)) (output done))
  (instance producer of packet_reader)
  (drive publish
    (pins.out_data producer.payload))
  (transaction run
    (on start)
    (drive publish)
    (complete done)))
ISF
        qr/sink pin 'pins\.out_data' must be one bit/,
        'actor-to-pin movement rejects wider top-level output pins in the first subset',
    );

    parse_fails_like(
        <<'ISF',
(actor actor_to_pin_missing_pin
  (clock clk)
  (interface (input start) (output done))
  (instance producer of packet_reader)
  (drive publish
    (pins.out_bit producer.payload))
  (transaction run
    (on start)
    (drive publish)
    (complete done)))
ISF
        qr/sink pin 'pins\.out_bit' is not a declared top-level output pin/,
        'actor-to-pin movement requires an existing output pin',
    );

    parse_fails_like(
        <<'ISF',
(actor actor_to_input_pin_rejected
  (clock clk)
  (interface (input start) (input out_bit) (output done))
  (instance producer of packet_reader)
  (drive publish
    (pins.out_bit producer.payload))
  (transaction run
    (on start)
    (drive publish)
    (complete done)))
ISF
        qr/sink pin 'pins\.out_bit' is not a declared top-level output pin/,
        'actor-to-pin movement does not treat input pins as output sinks',
    );

    parse_fails_like(
        <<'ISF',
(actor pin_to_actor_missing_pin
  (clock clk)
  (interface (input start) (output done))
  (instance consumer of packet_writer)
  (drive feed_consumer
    (consumer.payload pins.in_bit))
  (transaction run
    (on start)
    (drive feed_consumer)
    (complete done)))
ISF
        qr/source pin 'pins\.in_bit' is not a declared top-level input pin/,
        'pin-to-actor movement requires an existing input pin',
    );
};

subtest 'unsupported qualified event and trigger forms fail closed with ATL diagnostics' => sub {
    parse_fails_like(
        <<'ISF',
(actor nested_qualified_event_wait
  (clock clk)
  (interface (input start) (output done))
  (instance reader of packet_reader)
  (transaction run
    (on start)
    (when start
      (await reader.done))
    (complete done)))
ISF
        qr/ATL actor event wait '\(await reader\.done\)' is reserved for top-level transaction bodies only/,
        'nested qualified actor event wait fails closed before generic enum diagnostics',
    );

    parse_fails_like(
        <<'ISF',
(actor multiple_qualified_event_waits
  (clock clk)
  (interface (input start) (output done))
  (instance reader of packet_reader)
  (transaction run
    (on start)
    (await reader.done)
    (await reader.ready)
    (complete done)))
ISF
        qr/exceeds the current one-event-wait subset/,
        'multiple qualified actor event waits fail closed until fan-in/fan-out policy ships',
    );

    parse_fails_like(
        <<'ISF',
(actor trigger_batch_multiple_event_waits
  (clock clk)
  (interface (input start) (output done))
  (instance reader of packet_reader)
  (instance filter of packet_filter)
  (instance writer of packet_writer)
  (transaction run
    (on start)
    (trigger reader.capture)
    (trigger filter.process)
    (trigger writer.emit)
    (await reader.done)
    (await writer.done)
    (complete done)))
ISF
        qr/ATL actor event wait '\(await writer\.done\)' exceeds the current one-event-wait subset/,
        'temporary trigger batch plus multiple event waits fails closed before scheduled emission',
    );

    parse_fails_like(
        <<'ISF',
(actor qualified_event_wait_signal_conflict
  (clock clk)
  (interface
    (input start)
    (input reader_done)
    (output done))
  (instance reader of packet_reader)
  (transaction run
    (on start)
    (await reader.done)
    (complete done)))
ISF
        qr/generated handoff signal 'reader_done' conflicts with a declared actor signal/,
        'generated actor event handoff names fail closed on actor signal conflicts',
    );

    parse_fails_like(
        <<'ISF',
(actor qualified_event_wait_multi_domain
  (clock-domains
    (domain core (clock clk_a) :default)
    (domain io (clock clk_b)))
  (interface
    (input start (domain core))
    (output done (domain core)))
  (instance reader of packet_reader)
  (transaction run
    (domain core)
    (on start)
    (await reader.done)
    (complete done)))
ISF
        qr/ATL actor event waits require a single-clock actor in the current subset/,
        'actor event waits fail closed for multi-domain actors until cross-clock ATL events ship',
    );

    parse_fails_like(
        <<'ISF',
(actor nested_qualified_transaction_trigger
  (clock clk)
  (interface (input start) (output done))
  (instance reader of packet_reader)
  (transaction run
    (on start)
    (when start
      (trigger reader.capture))
    (complete done)))
ISF
        qr/ATL actor transaction trigger '\(trigger reader\.capture\)' is reserved for top-level transaction bodies only/,
        'nested qualified actor trigger fails closed before generic unsupported-clause diagnostics',
    );

    parse_fails_like(
        <<'ISF',
(actor multiple_qualified_transaction_triggers
  (clock clk)
  (interface (input start) (output done))
  (instance reader of packet_reader)
  (transaction run
    (on start)
    (trigger reader.capture)
    (trigger reader.flush)
    (complete done)))
ISF
        qr/ATL temporary trigger batch requires each trigger to target a distinct actor instance/,
        'multiple qualified actor triggers to the same instance fail closed until fan-in/fan-out policy ships',
    );

    parse_fails_like(
        <<'ISF',
(actor qualified_transaction_trigger_signal_conflict
  (clock clk)
  (interface
    (input start)
    (output done)
    (output reader_capture_start))
  (instance reader of packet_reader)
  (transaction run
    (on start)
    (trigger reader.capture)
    (complete done)))
ISF
        qr/generated handoff signal 'reader_capture_start' conflicts with a declared actor signal/,
        'generated actor trigger handoff names fail closed on actor signal conflicts',
    );

    parse_fails_like(
        <<'ISF',
(actor qualified_handoff_signal_conflict
  (clock clk)
  (interface (input start) (output done))
  (instance reader of packet_reader)
  (transaction run
    (on start)
    (await reader.capture_start)
    (trigger reader.capture)
    (complete done)))
ISF
        qr/generated handoff signal 'reader_capture_start' is used by both actor event wait 'reader\.capture_start' and actor transaction trigger 'reader\.capture'/,
        'event and trigger generated handoff name collisions fail closed',
    );

    parse_fails_like(
        <<'ISF',
(actor qualified_transaction_trigger_multi_domain
  (clock-domains
    (domain core (clock clk_a) :default)
    (domain io (clock clk_b)))
  (interface
    (input start (domain core))
    (output done (domain core)))
  (instance reader of packet_reader)
  (transaction run
    (domain core)
    (on start)
    (trigger reader.capture)
    (complete done)))
ISF
        qr/ATL actor transaction triggers require a single-clock actor in the current subset/,
        'actor transaction triggers fail closed for multi-domain actors until cross-clock ATL triggers ship',
    );

    parse_fails_like(
        <<'ISF',
(actor qualified_rule_trigger
  (clock clk)
  (interface (input start) (output done))
  (instance reader of packet_reader)
  (transaction local
    (complete done))
  (rule kick start
    (trigger reader.capture)))
ISF
        qr/ATL actor transaction trigger '\(trigger reader\.capture\)' is reserved but not supported yet/,
        'rule-level qualified actor trigger fails closed before unknown-transaction diagnostics',
    );

    my $actor = parse_source(<<'ISF', 'local-await-trigger.isf');
(actor local_await_trigger
  (clock clk)
  (interface
    (input start)
    (input ack)
    (output done))
  (instance reader of packet_reader)
  (transaction child
    (complete done))
  (transaction run
    (on start)
    (await ack)
    (complete done))
  (rule kick start
    (trigger child)))
ISF
    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    ok($lowered->{files}{'local_await_trigger.fsm'}, 'unqualified local await and rule trigger still lower');
};

done_testing();

sub assert_actor_network_report {
    my ($report, $expected, $label) = @_;

    is_deeply(
        [sort keys %{$report->{actor_network}}],
        [sort @{isf_public_interface_schedule_report_actor_network_keys()}],
        "$label exposes advertised actor_network keys",
    );
    is_deeply(
        [sort keys %{$report->{actor_network}{instances}[0]}],
        [sort @{_expected_actor_network_instance_keys($report->{actor_network}{instances}[0])}],
        "$label exposes advertised actor_network instance keys",
    );
    if (@{$report->{actor_network}{groups} || []}) {
        is_deeply(
            [sort keys %{$report->{actor_network}{groups}[0]}],
            [sort @{isf_public_interface_schedule_report_actor_network_group_keys()}],
            "$label exposes advertised actor_network group keys",
        );
    }
    if (@{$report->{actor_network}{group_schedules} || []}) {
        is_deeply(
            [sort keys %{$report->{actor_network}{group_schedules}[0]}],
            [sort @{isf_public_interface_schedule_report_actor_network_group_schedule_keys()}],
            "$label exposes advertised actor_network group_schedule keys",
        );
    }
    if (@{$report->{actor_network}{generated_tops} || []}) {
        is_deeply(
            [sort keys %{$report->{actor_network}{generated_tops}[0]}],
            [sort @{isf_public_interface_schedule_report_actor_network_generated_top_keys()}],
            "$label exposes advertised actor_network generated_top keys",
        );
    }
    if (@{$report->{actor_network}{association_schedules} || []}) {
        is_deeply(
            [sort keys %{$report->{actor_network}{association_schedules}[0]}],
            [sort @{isf_public_interface_schedule_report_actor_network_association_schedule_keys()}],
            "$label exposes advertised actor_network association_schedule keys",
        );
    }
    if (@{$report->{actor_network}{event_waits} || []}) {
        is_deeply(
            [sort keys %{$report->{actor_network}{event_waits}[0]}],
            [sort @{isf_public_interface_schedule_report_actor_network_event_wait_keys()}],
            "$label exposes advertised actor_network event_wait keys",
        );
    }
    if (@{$report->{actor_network}{data_movements} || []}) {
        is_deeply(
            [sort keys %{$report->{actor_network}{data_movements}[0]}],
            [sort @{isf_public_interface_schedule_report_actor_network_data_movement_keys()}],
            "$label exposes advertised actor_network data_movement keys",
        );
    }
    if (@{$report->{actor_network}{transaction_triggers} || []}) {
        is_deeply(
            [sort keys %{$report->{actor_network}{transaction_triggers}[0]}],
            [sort @{isf_public_interface_schedule_report_actor_network_transaction_trigger_keys()}],
            "$label exposes advertised actor_network transaction_trigger keys",
        );
    }
    $expected->{association_schedules} = []
        unless exists $expected->{association_schedules};
    $expected->{generated_tops} = []
        unless exists $expected->{generated_tops};
    is_deeply($report->{actor_network}, $expected, "$label preserves actor-network identity");
}

sub assert_resolved_actor_type_metadata {
    my ($actor, $label, $actor_name) = @_;
    $actor_name //= 'atl_parent';

    my $expected_instance = {
        name            => 'worker',
        actor_type      => 'pkt_lib.packet_worker',
        declaration     => 'actor',
        type_resolution => 'library_actor_export',
        library         => 'common.packet',
        alias           => 'pkt_lib',
        export          => 'packet_worker',
        module          => "${actor_name}__worker",
        scheduled_fsm   => "${actor_name}__worker.fsm",
    };
    is_deeply(
        $actor->{actor_network}{instances}[0],
        $expected_instance,
        "$label parser records resolved ATL actor type metadata",
    );

    my $scheduler = FSM::Scheduler::ISF->new();
    my $lowered = $scheduler->lower($actor);
    is_deeply(
        [sort keys %{$lowered->{files}}],
        ["$actor_name.fsm", "${actor_name}__worker.fsm"],
        "$label emits parent and resolved ATL child scheduled .fsm artifacts",
    );
    like(
        $lowered->{files}{"${actor_name}__worker.fsm"},
        qr/\A\(\?fsm:${actor_name}__worker\b/,
        "$label emitted ATL child .fsm uses the reserved module name",
    );
    ok(!exists $lowered->{files}{"${actor_name}_top.fsm"}, "$label emits no generated ATL top");

    my $report = decode_json($scheduler->report($actor));
    assert_actor_network_report(
        $report,
        {
            kind      => 'static_declaration',
            instances => [ $expected_instance ],
            groups => [],
            association_schedules => [],
            group_schedules => [],
            data_movements => [],
            event_waits => [],
            transaction_triggers => [],
        },
        "$label resolved actor type report",
    );
    is_deeply($report->{library_uses}, [], "$label does not report a reusable-library use");
}

sub _expected_actor_network_instance_keys {
    my ($entry) = @_;
    return isf_public_interface_schedule_report_actor_network_resolved_instance_keys()
        if exists $entry->{type_resolution};
    return isf_public_interface_schedule_report_actor_network_instance_keys();
}

sub parse_source {
    my ($source, $label) = @_;
    return FSM::Adapter::ISF->new()->parse_source($source, $label);
}

sub parse_fails_like {
    my ($source, $pattern, $label) = @_;
    my $ok = eval {
        parse_source($source, 'actor-network-negative.isf');
        1;
    };
    ok(!$ok, "$label rejects source");
    like($@, $pattern, "$label reports the bounded diagnostic");
}

sub lower_fails_like {
    my ($source, $pattern, $label) = @_;
    my $ok = eval {
        my $actor = parse_source($source, 'actor-network-lower-negative.isf');
        FSM::Scheduler::ISF->new()->lower($actor);
        1;
    };
    ok(!$ok, "$label rejects during lowering");
    like($@, $pattern, "$label reports the bounded diagnostic");
}

sub run_schedule_json {
    my ($path, $label) = @_;
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $path],
    );

    ok($success, "$label CLI schedule JSON succeeds");
    is(join('', @{$stderr_buf || []}), '', "$label CLI schedule JSON keeps stderr clean");
    return decode_json(join('', @{$stdout_buf || []}));
}

sub write_temp_isf {
    my ($source) = @_;
    my $dir = tempdir(CLEANUP => 1);
    my $path = File::Spec->catfile($dir, 'atl-static-network.isf');
    write_file($path, $source);
    return $path;
}

sub write_packet_library {
    my ($dir) = @_;
    my $lib_dir = File::Spec->catdir($dir, 'common');
    make_path($lib_dir);
    my $path = File::Spec->catfile($lib_dir, 'packet.isf');
    write_file($path, <<'ISF');
(library common.packet
  (exports (actor packet_worker))
  (actor packet_worker
    (clock clk)
    (interface (input start) (output done))
    (transaction process
      (on start)
      (complete done))))
ISF
    return $path;
}

sub write_file {
    my ($path, $source) = @_;
    open my $fh, '>', $path or die "cannot write $path: $!";
    print {$fh} $source or die "cannot write $path: $!";
    close $fh or die "cannot close $path: $!";
}

sub actor_body_network_source {
    my ($actor_name) = @_;
    return <<"ISF";
(actor $actor_name
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input start)
    (output done))
  (instance reader of packet_reader)
  (transaction run
    (on start)
    (complete done)))
ISF
}
