package FSM::IAL2::ProtocolIntent::AxiWBurst4Driver;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use JSON::PP ();
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

# Bounded fixed-four AXI manager W write-data-channel driver.
# Public contract selected by IAL2-AXI-MANAGER-INITIATOR-FRONTIER.41.
# See docs/IAL2_AXI_MANAGER_INITIATOR_W_BURST4_DRIVER_CONTRACT_SELECTION.md.
#
# One idle command atomically captures four data32/strobe4 tuples. The actor
# presents them with continuous WVALID, holds each tuple under backpressure,
# drives WLAST 0/0/0/1, publishes every accepted beat with a two-bit index,
# and retires once with the fourth transfer. It is additive to AxiWDriver;
# AW/address coordination and B response completion remain explicit residue.

sub new($class, @constructor_args) {
    _validate_constructor_receiver($class);
    my %args = _validate_constructor_args($class, @constructor_args);

    return bless {
        debug => $args{debug} // 0,
    }, $class;
}

sub generate($self, @args) {
    _validate_object_receiver($self, 'generate');
    confess "FSM::IAL2::ProtocolIntent::AxiWBurst4Driver->generate expects exactly one contract hash reference\n"
        unless @args == 1 && ref($args[0]) eq 'HASH';

    my $contract = _normalize_contract($args[0]);
    my $isf_text = _emit_isf($contract);
    my $isf_name = "$contract->{actor_name}.isf";

    my $adapter = FSM::Adapter::ISF->new(debug => $self->{debug});
    my $actor = $adapter->parse_source($isf_text, $isf_name);

    my $scheduler = FSM::Scheduler::ISF->new(debug => $self->{debug});
    my $lowered = $scheduler->lower($actor);
    my $schedule_report = JSON::PP->new->decode($scheduler->report($actor));

    my $report = _build_report(
        contract  => $contract,
        isf_name  => $isf_name,
        fsm_files => [sort keys %{$lowered->{files} || {}}],
    );

    return {
        layer => 'IAL2',
        kind  => 'protocol_intent.axi_w_burst4_driver',
        mode  => $report->{mode},
        generated_ial1 => {
            format => 'isf',
            name   => $isf_name,
            text   => $isf_text,
        },
        generated_ial0 => {
            format => 'fsm',
            files  => _clone_jsonish($lowered->{files}),
        },
        generated_ial1_schedule_report => $schedule_report,
        report => $report,
    };
}

sub _validate_constructor_receiver($class) {
    confess "FSM::IAL2::ProtocolIntent::AxiWBurst4Driver->new must be called with the FSM::IAL2::ProtocolIntent::AxiWBurst4Driver class invocant\n"
        unless defined($class)
            && !ref($class)
            && $class eq 'FSM::IAL2::ProtocolIntent::AxiWBurst4Driver';
}

sub _validate_constructor_args($class, @args) {
    confess "$class->new expects an even-length option/value list\n"
        if @args % 2;

    my %options = @args;
    my %allowed = map { $_ => 1 } qw(debug);
    for my $name (sort keys %options) {
        confess "$class->new unsupported option '$name'; supported option: debug\n"
            unless $allowed{$name};
    }

    return %options;
}

sub _validate_object_receiver($self, $method) {
    confess "FSM::IAL2::ProtocolIntent::AxiWBurst4Driver->$method must be called on an FSM::IAL2::ProtocolIntent::AxiWBurst4Driver object\n"
        unless blessed($self)
            && $self->isa('FSM::IAL2::ProtocolIntent::AxiWBurst4Driver');
}

sub _normalize_contract($raw) {
    my $kind = _required_scalar($raw, 'kind');
    confess "AXI W burst4 driver IAL2 contract kind must be axi_w_burst4_driver\n"
        unless $kind eq 'axi_w_burst4_driver';

    my $protocol = lc _required_scalar($raw, 'protocol');
    confess "AXI W burst4 driver IAL2 contract profile must be axi4 in this slice\n"
        unless $protocol eq 'axi4';

    my $name = _required_identifier($raw, 'name');
    my $actor_name = exists($raw->{actor_name})
        ? _identifier_value($raw->{actor_name}, 'actor_name')
        : $name;

    my $role = lc _required_scalar($raw, 'role');
    confess "AXI W burst4 driver IAL2 contract role must be manager-to-subordinate\n"
        unless $role eq 'manager-to-subordinate';

    my $clock = _required_identifier($raw, 'clock');
    my $reset = _normalize_reset($raw->{reset});
    confess "AXI W burst4 driver reset must be asynchronous active-low in this slice\n"
        unless $reset->{async} && $reset->{active_low};
    my $command = _normalize_command(_required_hash($raw, 'command'));
    my $channel = _normalize_channel(_required_hash($raw, 'channel'));

    _reject_duplicate_signal_names(
        $clock,
        $reset->{signal},
        _binding_names($command),
        _binding_names($channel),
        qw(
            active_q beat_index_q
            data1_q data2_q data3_q
            strb1_q strb2_q strb3_q
            can_accept
        ),
    );

    my $source = ref($raw->{source}) eq 'HASH' ? $raw->{source} : {};
    my $intent_name = exists($raw->{intent_name})
        ? _nonempty_scalar($raw->{intent_name}, 'intent_name')
        : undef;
    my $source_object_id = exists($raw->{source_object_id})
        ? _nonempty_scalar($raw->{source_object_id}, 'source_object_id')
        : exists($source->{object_id})
            ? _nonempty_scalar($source->{object_id}, 'source.object_id')
            : $name;
    my $anchors = exists($source->{anchors})
        ? _normalize_source_anchors($source->{anchors})
        : [];

    return {
        kind             => $kind,
        name             => $name,
        actor_name       => $actor_name,
        protocol         => $protocol,
        role             => $role,
        clock            => $clock,
        reset            => $reset,
        command          => $command,
        channel          => $channel,
        intent_name      => $intent_name,
        source_object_id => $source_object_id,
        source_anchors   => $anchors,
    };
}

sub _normalize_command($raw) {
    my %command = (
        start => _required_identifier_field($raw, 'start', 'command.start'),
        ready => _required_identifier_field($raw, 'ready', 'command.ready'),
    );
    for my $index (0 .. 3) {
        $command{"data$index"} = _normalize_width_binding(
            $raw->{"data$index"},
            "command.data$index",
            32,
        );
        $command{"strobe$index"} = _normalize_width_binding(
            $raw->{"strobe$index"},
            "command.strobe$index",
            4,
        );
    }
    return \%command;
}

sub _normalize_channel($raw) {
    return {
        valid      => _required_identifier_field($raw, 'valid', 'channel.valid'),
        data       => _normalize_width_binding($raw->{data}, 'channel.data', 32),
        strobe     => _normalize_width_binding($raw->{strobe}, 'channel.strobe', 4),
        last       => _required_identifier_field($raw, 'last', 'channel.last'),
        busy       => _required_identifier_field($raw, 'busy', 'channel.busy'),
        beat_done  => _required_identifier_field($raw, 'beat_done', 'channel.beat_done'),
        done       => _required_identifier_field($raw, 'done', 'channel.done'),
        beat_index => _normalize_width_binding($raw->{beat_index}, 'channel.beat_index', 2),
    };
}

sub _emit_isf($contract) {
    my $cmd = $contract->{command};
    my $chan = $contract->{channel};
    my $reset = _reset_clause($contract->{reset});

    return join("\n",
        "(actor $contract->{actor_name}",
        "  (clock $contract->{clock})",
        "  $reset",
        "  (interface",
        _interface_line('input', $cmd->{start}),
        _interface_line('input', $cmd->{data0}),
        _interface_line('input', $cmd->{data1}),
        _interface_line('input', $cmd->{data2}),
        _interface_line('input', $cmd->{data3}),
        _interface_line('input', $cmd->{strobe0}),
        _interface_line('input', $cmd->{strobe1}),
        _interface_line('input', $cmd->{strobe2}),
        _interface_line('input', $cmd->{strobe3}),
        _interface_line('input', $cmd->{ready}),
        _interface_line('output', $chan->{valid}),
        _interface_line('output', $chan->{data}),
        _interface_line('output', $chan->{strobe}),
        _interface_line('output', $chan->{last}),
        _interface_line('output', $chan->{busy}),
        _interface_line('output', $chan->{beat_done}),
        _interface_line('output', $chan->{done}),
        _interface_line('output', $chan->{beat_index}) . ")",
        "",
        "  (storage",
        "    (var beat_index_q (width 2) (reset 0))",
        "    (var data1_q (width 32) (reset 0))",
        "    (var data2_q (width 32) (reset 0))",
        "    (var data3_q (width 32) (reset 0))",
        "    (var strb1_q (width 4) (reset 0))",
        "    (var strb2_q (width 4) (reset 0))",
        "    (var strb3_q (width 4) (reset 0)))",
        "",
        "  (priority accept_beat0 over clear_beat_done)",
        "  (priority accept_beat1 over clear_beat_done)",
        "  (priority accept_beat2 over clear_beat_done)",
        "  (priority accept_final over clear_beat_done)",
        "  (priority accept_final over clear_done)",
        "",
        "  (rule admit (& (! active_q) $cmd->{start})",
        "    (set active_q 1)",
        "    (set $chan->{busy} 1)",
        "    (set beat_index_q 0)",
        "    (set data1_q $cmd->{data1}{name})",
        "    (set data2_q $cmd->{data2}{name})",
        "    (set data3_q $cmd->{data3}{name})",
        "    (set strb1_q $cmd->{strobe1}{name})",
        "    (set strb2_q $cmd->{strobe2}{name})",
        "    (set strb3_q $cmd->{strobe3}{name})",
        "    (set $chan->{valid} 1)",
        "    (set $chan->{data}{name} $cmd->{data0}{name})",
        "    (set $chan->{strobe}{name} $cmd->{strobe0}{name})",
        "    (set $chan->{last} 0))",
        "",
        "  (rule accept_beat0 (& active_q $chan->{valid} $cmd->{ready} (== beat_index_q 0))",
        "    (set $chan->{beat_done} 1)",
        "    (set $chan->{beat_index}{name} 0)",
        "    (set beat_index_q 1)",
        "    (set $chan->{data}{name} data1_q)",
        "    (set $chan->{strobe}{name} strb1_q)",
        "    (set $chan->{last} 0))",
        "",
        "  (rule accept_beat1 (& active_q $chan->{valid} $cmd->{ready} (== beat_index_q 1))",
        "    (set $chan->{beat_done} 1)",
        "    (set $chan->{beat_index}{name} 1)",
        "    (set beat_index_q 2)",
        "    (set $chan->{data}{name} data2_q)",
        "    (set $chan->{strobe}{name} strb2_q)",
        "    (set $chan->{last} 0))",
        "",
        "  (rule accept_beat2 (& active_q $chan->{valid} $cmd->{ready} (== beat_index_q 2))",
        "    (set $chan->{beat_done} 1)",
        "    (set $chan->{beat_index}{name} 2)",
        "    (set beat_index_q 3)",
        "    (set $chan->{data}{name} data3_q)",
        "    (set $chan->{strobe}{name} strb3_q)",
        "    (set $chan->{last} 1))",
        "",
        "  (rule accept_final (& active_q $chan->{valid} $cmd->{ready} (== beat_index_q 3))",
        "    (set $chan->{beat_done} 1)",
        "    (set $chan->{beat_index}{name} 3)",
        "    (set active_q 0)",
        "    (set $chan->{busy} 0)",
        "    (set $chan->{valid} 0)",
        "    (set $chan->{done} 1))",
        "",
        "  (rule clear_beat_done $chan->{beat_done}",
        "    (set $chan->{beat_done} 0))",
        "",
        "  (rule clear_done $chan->{done}",
        "    (set $chan->{done} 0))",
        "",
        "  (transaction wlast_sequence_check",
        "    (assert",
        "      (=> (& $chan->{valid} active_q)",
        "          (== $chan->{last} (== beat_index_q 3)))",
        "      \"WLAST must be high only on fixed-four beat index 3\")))",
        "",
    );
}

sub _build_report(%args) {
    my $contract = $args{contract};
    my @fsm_files = @{$args{fsm_files} || []};

    my %source_object = (
        id      => $contract->{source_object_id},
        anchors => _clone_jsonish($contract->{source_anchors}),
    );
    $source_object{intent_name} = $contract->{intent_name}
        if defined($contract->{intent_name}) && length($contract->{intent_name});

    return {
        schema => 'fsmgen.ial2.protocol_intent.axi_w_burst4_driver.v1',
        mode   => 'burst4-driver',
        layering => {
            source_layer          => 'IAL2',
            generated_ial1_format => 'isf',
            generated_ial0_format => 'fsm',
            direct_ial2_to_ial0   => JSON::PP::false,
        },
        source_object => \%source_object,
        target_protocol => {
            profile => $contract->{protocol},
            object  => 'axi-w-burst4-driver',
            role    => $contract->{role},
        },
        driver => {
            name       => $contract->{name},
            actor_name => $contract->{actor_name},
        },
        bindings => {
            clock   => $contract->{clock},
            reset   => _clone_jsonish($contract->{reset}),
            command => _clone_jsonish($contract->{command}),
            channel => _clone_jsonish($contract->{channel}),
        },
        fixed_burst_policy => {
            data_width              => 32,
            strobe_width            => 4,
            beat_count              => 4,
            beat_index_width        => 2,
            last_beat_index         => 3,
            last_sequence           => [0, 0, 0, 1],
            payload_authoring       => 'explicit_four_tuple_fields',
            capture_policy          => 'atomic_on_idle_command',
            beat_zero_storage       => 'driven_wdata_wstrb_registers',
            trailing_payload_storage => 'private_per_beat_registers',
            valid_policy            => 'assert_independent_of_ready_and_hold_through_fourth_acceptance',
            stall_policy            => 'hold_valid_data_strobe_last_and_index',
            beat_completion         => 'w_transfer_accepted',
            burst_completion        => 'fourth_w_transfer_accepted',
            all_zero_strobe_allowed => JSON::PP::true,
        },
        driver_policy => {
            queue_depth  => 0,
            busy_command => 'ignored_not_queued',
            beat_event   => 'level_high_each_accepted_cycle_with_index',
            final_event  => 'coincident_with_accepted_index_three',
            reset        => 'asynchronous_abort_without_events',
        },
        generated_ial1_schedule => {
            port_count     => 18,
            input_count    => 10,
            output_count   => 8,
            signal_count   => 30,
            state_count    => 0,
            compile_issues => [],
            decision_tree_blocks => [
                { name => 'admit',           assignments => 13 },
                { name => 'accept_beat0',    assignments => 6 },
                { name => 'accept_beat1',    assignments => 6 },
                { name => 'accept_beat2',    assignments => 6 },
                { name => 'accept_final',    assignments => 6 },
                { name => 'clear_beat_done', assignments => 1 },
                { name => 'clear_done',      assignments => 1 },
            ],
            declared_storage => [
                { name => 'beat_index_q', width => 2 },
                { name => 'data1_q',      width => 32 },
                { name => 'data2_q',      width => 32 },
                { name => 'data3_q',      width => 32 },
                { name => 'strb1_q',      width => 4 },
                { name => 'strb2_q',      width => 4 },
                { name => 'strb3_q',      width => 4 },
            ],
            priority_resolutions => [
                { winner => 'accept_beat0', loser => 'clear_beat_done', target => $contract->{channel}{beat_done} },
                { winner => 'accept_beat1', loser => 'clear_beat_done', target => $contract->{channel}{beat_done} },
                { winner => 'accept_beat2', loser => 'clear_beat_done', target => $contract->{channel}{beat_done} },
                { winner => 'accept_final', loser => 'clear_beat_done', target => $contract->{channel}{beat_done} },
                { winner => 'accept_final', loser => 'clear_done',      target => $contract->{channel}{done} },
            ],
            assertion => 'WLAST must be high only on fixed-four beat index 3',
        },
        generated_artifacts => {
            ial1 => {
                name   => $args{isf_name},
                format => 'isf',
            },
            ial0 => {
                files  => \@fsm_files,
                format => 'fsm',
            },
            hdl_entry => {
                selected       => JSON::PP::true,
                kind           => 'generated_driver_fsm',
                entry_artifact => "$contract->{actor_name}.fsm",
            },
        },
        enforced_static_rules => _enforced_static_rules(),
        unsupported_residue   => _unsupported_residue(),
    };
}

sub _enforced_static_rules {
    return [
        'profile must be axi4, object must be axi-w-burst4-driver, and role must be manager-to-subordinate',
        'clock and reset are shared with one asynchronous active-low generated actor',
        'one idle command atomically captures four explicit data width 32 and strobe width 4 tuples',
        'WVALID asserts independently of WREADY and remains high through all four presented beats',
        'WDATA, WSTRB, WLAST, and the current beat index remain stable during every WREADY-low stall',
        'WLAST is low on beat indices 0 through 2 and high only on beat index 3',
        'exactly four WVALID and WREADY acceptances retire one admitted command',
        'all-zero and partial WSTRB values are legal on every beat',
        'beat done and beat index identify every accepted tuple including consecutive WREADY-high transfers',
        'final done coincides with accepted beat index 3 and clears busy and WVALID',
        'a one-cycle command while busy is ignored and no command queue is provided',
        'asynchronous reset aborts without fabricated beat or final events and recovery restarts at beat index 0',
        'lowering is IAL2 through one generated IAL1 actor into one generated IAL0 FSM, never direct IAL2-to-IAL0',
    ];
}

sub _unsupported_residue {
    return [
        {
            id     => 'axi_w_burst4_driver_aw_coordination_deferred',
            detail => 'AW launch, address ownership, AWLEN/AWSIZE/AWBURST coupling, alignment, 4-KiB legality, AW/W joining, and request completion remain future work.',
        },
        {
            id     => 'axi_w_burst4_driver_b_response_completion_deferred',
            detail => 'B arming, BID/BRESP handling, and full write-transaction completion remain future work.',
        },
        {
            id     => 'axi_w_burst4_driver_address_attribute_coupling_deferred',
            detail => 'This channel primitive does not establish address, transfer-size, burst-kind, or transaction-container legality.',
        },
        {
            id     => 'axi_w_burst4_driver_dynamic_general_bursts_deferred',
            detail => 'Authored or dynamic beat counts, lengths other than four, and general burst progression remain future work.',
        },
        {
            id     => 'axi_w_burst4_driver_narrow_unaligned_wrap_deferred',
            detail => 'Narrow, unaligned, FIXED, WRAP, and extended W-side behavior remain future work.',
        },
        {
            id     => 'axi_w_burst4_driver_streaming_packed_payload_deferred',
            detail => 'Packed payload banks, streaming producer supply, producer backpressure, and underflow buffering remain future work.',
        },
        {
            id     => 'axi_w_burst4_driver_capacity_core_integration_deferred',
            detail => 'Capacity/status submit/completion, ID authority, response bookkeeping, and storage integration remain future work.',
        },
        {
            id     => 'axi_w_burst4_driver_outstanding_queueing_deferred',
            detail => 'Adjacent back-to-back admission, multiple outstanding writes, buffering, queues, ordering, demux, and interleaving remain future work.',
        },
        {
            id     => 'axi_w_burst4_driver_transaction_interface_deferred',
            detail => 'Decision 0020 protocol-neutral transaction interfaces and role composition remain director-gated future work.',
        },
        {
            id     => 'axi_w_burst4_driver_profile_alias_deferred',
            detail => '.axi profile-alias surfacing remains unsupported; this source uses generic .ppif only.',
        },
        {
            id     => 'axi_w_burst4_driver_verification_output_deferred',
            detail => 'Direct verification-output generation from this IAL2 source remains future work.',
        },
        {
            id     => 'axi_w_burst4_driver_backend_variants_deferred',
            detail => 'Direct backend lowering, backend-language variants, and VHDL behavior remain future work.',
        },
        {
            id     => 'axi_w_burst4_driver_other_protocols_unchanged',
            detail => 'AHB and APB behavior remain unchanged.',
        },
    ];
}

sub _required_scalar($raw, $field) {
    confess "AXI W burst4 driver IAL2 contract is missing required scalar field '$field'\n"
        unless exists($raw->{$field});
    return _nonempty_scalar($raw->{$field}, $field);
}

sub _required_hash($raw, $field) {
    confess "AXI W burst4 driver IAL2 contract field '$field' must be a hash reference\n"
        unless ref($raw->{$field}) eq 'HASH';
    return $raw->{$field};
}

sub _required_identifier($raw, $field) {
    return _identifier_value(_required_scalar($raw, $field), $field);
}

sub _required_identifier_field($raw, $field, $label) {
    confess "AXI W burst4 driver IAL2 contract is missing required field '$label'\n"
        unless exists($raw->{$field});
    return _identifier_value($raw->{$field}, $label);
}

sub _normalize_width_binding($raw, $field, $expected_width) {
    confess "AXI W burst4 driver IAL2 contract field '$field' must be a hash reference\n"
        unless ref($raw) eq 'HASH';
    my $name = _identifier_value($raw->{name}, "$field.name");
    my $width = _positive_integer($raw->{width}, "$field.width");
    confess "AXI W burst4 driver IAL2 contract $field.width must be $expected_width in this slice\n"
        unless $width == $expected_width;
    return {
        name  => $name,
        width => $width,
    };
}

sub _normalize_reset($raw_reset) {
    confess "AXI W burst4 driver IAL2 contract is missing required reset binding\n"
        unless defined $raw_reset;

    my %reset;
    if (ref($raw_reset) eq 'HASH') {
        $reset{signal} = _identifier_value($raw_reset->{signal}, 'reset.signal');
        $reset{active_low} = exists($raw_reset->{active_low})
            ? _bool_value($raw_reset->{active_low}, 'reset.active_low')
            : ($reset{signal} =~ /_n\z/i ? 1 : 0);
        $reset{polarity_source} = exists($raw_reset->{active_low})
            ? 'explicit'
            : 'signal_name_convention';
        $reset{async} = exists($raw_reset->{async})
            ? _bool_value($raw_reset->{async}, 'reset.async')
            : 1;
    } else {
        $reset{signal} = _identifier_value($raw_reset, 'reset');
        $reset{active_low} = $reset{signal} =~ /_n\z/i ? 1 : 0;
        $reset{polarity_source} = 'signal_name_convention';
        $reset{async} = 1;
    }

    return \%reset;
}

sub _normalize_source_anchors($anchors) {
    confess "AXI W burst4 driver IAL2 contract source.anchors must be an array reference\n"
        unless ref($anchors) eq 'ARRAY';

    my @normalized;
    for my $index (0 .. $#$anchors) {
        my $anchor = $anchors->[$index];
        if (ref($anchor) eq 'HASH') {
            for my $required (qw(document section page)) {
                confess "AXI W burst4 driver IAL2 contract source.anchors[$index] is missing '$required'\n"
                    unless defined($anchor->{$required})
                        && !ref($anchor->{$required})
                        && length($anchor->{$required});
            }
            push @normalized, {
                document => $anchor->{document},
                section  => $anchor->{section},
                page     => $anchor->{page},
            };
        } else {
            push @normalized, _nonempty_scalar($anchor, "source.anchors[$index]");
        }
    }

    return \@normalized;
}

sub _binding_names(@values) {
    my @names;
    for my $value (@values) {
        if (ref($value) eq 'HASH') {
            if (exists $value->{name}) {
                push @names, $value->{name};
            } else {
                push @names, _binding_names(values %$value);
            }
        } elsif (defined($value) && !ref($value)) {
            push @names, $value;
        }
    }
    return @names;
}

sub _reject_duplicate_signal_names(@names) {
    my %seen;
    for my $name (@names) {
        next unless defined($name) && !ref($name) && length($name);
        confess "AXI W burst4 driver IAL2 contract duplicates signal '$name'\n"
            if $seen{$name}++;
    }
}

sub _nonempty_scalar($value, $field) {
    confess "AXI W burst4 driver IAL2 contract field '$field' must be a non-empty scalar\n"
        if !defined($value) || ref($value) || $value eq '';
    return $value;
}

sub _identifier_value($value, $field) {
    confess "AXI W burst4 driver IAL2 contract field '$field' must be an ISF identifier\n"
        unless defined($value)
            && !ref($value)
            && $value =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
    return $value;
}

sub _positive_integer($value, $field) {
    confess "AXI W burst4 driver IAL2 contract field '$field' must be a positive integer\n"
        unless defined($value)
            && !ref($value)
            && $value =~ /\A[1-9][0-9]*\z/;
    return int($value);
}

sub _bool_value($value, $field) {
    confess "AXI W burst4 driver IAL2 contract field '$field' must be boolean 0 or 1\n"
        if ref($value)
            || !defined($value)
            || ($value ne '0' && $value ne '1');
    return $value ? 1 : 0;
}

sub _interface_line($direction, $binding) {
    return "    ($direction $binding)"
        unless ref($binding) eq 'HASH';
    return $binding->{width} == 1
        ? "    ($direction $binding->{name})"
        : "    ($direction $binding->{name} (width $binding->{width}))";
}

sub _reset_clause($reset) {
    my @parts = ($reset->{signal});
    push @parts, $reset->{async} ? 'async' : 'sync';
    push @parts, $reset->{active_low} ? 'active_low' : 'active_high';
    return "(reset (" . join(' ', @parts) . "))";
}

sub _clone_jsonish($value) {
    return $value unless ref($value);
    return [map { _clone_jsonish($_) } @$value]
        if ref($value) eq 'ARRAY';
    return { map { $_ => _clone_jsonish($value->{$_}) } keys %$value }
        if ref($value) eq 'HASH';
    return $value;
}

1;
