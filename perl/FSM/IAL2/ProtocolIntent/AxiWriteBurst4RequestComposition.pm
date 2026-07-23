package FSM::IAL2::ProtocolIntent::AxiWriteBurst4RequestComposition;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use JSON::PP ();
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::Adapter::ISF;
use FSM::IAL2::ProtocolIntent::AxiAwDriver;
use FSM::IAL2::ProtocolIntent::AxiWBurst4Driver;
use FSM::Scheduler::ISF;

# Bounded AXI manager fixed-four AW+W request composition.
# Public contract selected by IAL2-AXI-MANAGER-INITIATOR-FRONTIER.45.
# See docs/IAL2_AXI_MANAGER_INITIATOR_BURST4_WRITE_REQUEST_COMPOSITION_CONTRACT_SELECTION.md.
#
# The composition reuses the shipped AW and W drivers unchanged. A distinct
# generated coordinator atomically captures one aligned aggregate command,
# starts both children, remembers their independent completion pulses, and
# completes only after both request channels have transferred. B response
# handling and full write-transaction completion remain explicit residue.

my @COMMAND_WIDTH_FIELDS = (
    [address => 32],
    [id      => 4],
    [data0   => 32],
    [data1   => 32],
    [data2   => 32],
    [data3   => 32],
    [strobe0 => 4],
    [strobe1 => 4],
    [strobe2 => 4],
    [strobe3 => 4],
);

my @AW_WIDTH_FIELDS = (
    [address => 32],
    [id      => 4],
    [length  => 8],
    [size    => 3],
    [burst   => 2],
);

my @W_WIDTH_FIELDS = (
    [data   => 32],
    [strobe => 4],
);

sub new($class, @constructor_args) {
    _validate_constructor_receiver($class);
    my %args = _validate_constructor_args($class, @constructor_args);

    return bless {
        debug => $args{debug} // 0,
    }, $class;
}

sub generate($self, @args) {
    _validate_object_receiver($self, 'generate');
    confess "FSM::IAL2::ProtocolIntent::AxiWriteBurst4RequestComposition->generate expects exactly one contract hash reference\n"
        unless @args == 1 && ref($args[0]) eq 'HASH';

    my $contract = _normalize_contract($args[0]);
    my $aw_result = FSM::IAL2::ProtocolIntent::AxiAwDriver
        ->new(debug => $self->{debug})
        ->generate(_aw_child_contract($contract));
    my $w_result = FSM::IAL2::ProtocolIntent::AxiWBurst4Driver
        ->new(debug => $self->{debug})
        ->generate(_w_child_contract($contract));
    my $coordinator_result = _generate_coordinator($self, $contract);

    my (@ial1_items, @ial0_items, @schedule_reports);
    my %fsm_files;
    _add_generated_child(
        result           => $aw_result,
        object_name      => 'axi_aw_driver',
        role             => 'aw-driver',
        instance_name    => 'aw_driver',
        ial1_items       => \@ial1_items,
        ial0_items       => \@ial0_items,
        schedule_reports => \@schedule_reports,
        fsm_files        => \%fsm_files,
    );
    _add_generated_child(
        result           => $w_result,
        object_name      => 'axi_w_burst4_driver',
        role             => 'w-driver',
        instance_name    => 'w_driver',
        ial1_items       => \@ial1_items,
        ial0_items       => \@ial0_items,
        schedule_reports => \@schedule_reports,
        fsm_files        => \%fsm_files,
    );
    _add_generated_child(
        result           => $coordinator_result,
        object_name      => 'axi_write_burst4_request_coordinator',
        role             => 'coordinator',
        instance_name    => 'coordinator',
        ial1_items       => \@ial1_items,
        ial0_items       => \@ial0_items,
        schedule_reports => \@schedule_reports,
        fsm_files        => \%fsm_files,
    );

    my $top = _build_structural_top($contract, \%fsm_files);
    confess "Error: AXI write burst4 request composition generated duplicate .fsm artifact '$top->{entry_artifact}'\n"
        if exists $fsm_files{$top->{entry_artifact}};
    $fsm_files{$top->{entry_artifact}} = $top->{text};
    push @ial0_items, $top->{ial0_item};

    my $report = _build_report(
        contract           => $contract,
        aw_result          => $aw_result,
        w_result           => $w_result,
        coordinator_result => $coordinator_result,
        ial1_items         => \@ial1_items,
        ial0_items         => \@ial0_items,
        schedule_reports   => \@schedule_reports,
        fsm_files          => \%fsm_files,
        hdl_entry          => $top->{report_entry},
    );

    return {
        layer => 'IAL2',
        kind  => 'protocol_intent.axi_write_burst4_request_composition',
        mode  => $report->{mode},
        generated_ial1 => {
            format => 'isf',
            items  => \@ial1_items,
        },
        generated_ial0 => {
            format => 'fsm',
            items  => \@ial0_items,
            files  => \%fsm_files,
        },
        generated_ial1_schedule_reports => \@schedule_reports,
        report => $report,
    };
}

sub _validate_constructor_receiver($class) {
    confess "FSM::IAL2::ProtocolIntent::AxiWriteBurst4RequestComposition->new must be called with the FSM::IAL2::ProtocolIntent::AxiWriteBurst4RequestComposition class invocant\n"
        unless defined($class) && !ref($class)
            && $class eq 'FSM::IAL2::ProtocolIntent::AxiWriteBurst4RequestComposition';
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
    confess "FSM::IAL2::ProtocolIntent::AxiWriteBurst4RequestComposition->$method must be called on an FSM::IAL2::ProtocolIntent::AxiWriteBurst4RequestComposition object\n"
        unless blessed($self)
            && $self->isa('FSM::IAL2::ProtocolIntent::AxiWriteBurst4RequestComposition');
}

sub _normalize_contract($raw) {
    my $kind = _required_scalar($raw, 'kind');
    confess "AXI write burst4 request composition IAL2 contract kind must be axi_write_burst4_request_composition\n"
        unless $kind eq 'axi_write_burst4_request_composition';

    my $protocol = lc _required_scalar($raw, 'protocol');
    confess "AXI write burst4 request composition IAL2 contract profile must be axi4 in this slice\n"
        unless $protocol eq 'axi4';

    my $name = _required_identifier($raw, 'name');
    my $actor_name = exists($raw->{actor_name})
        ? _identifier_value($raw->{actor_name}, 'actor_name')
        : $name;
    my $role = lc _required_scalar($raw, 'role');
    confess "AXI write burst4 request composition IAL2 contract role must be manager-to-subordinate\n"
        unless $role eq 'manager-to-subordinate';

    my $clock = _required_identifier($raw, 'clock');
    my $reset = _normalize_reset($raw->{reset});
    confess "AXI write burst4 request composition reset must be asynchronous active-low in this slice\n"
        unless $reset->{async} && $reset->{active_low};

    my $command = _normalize_command(_required_hash($raw, 'command'));
    my $aw_channel = _normalize_aw_channel(_required_hash($raw, 'aw_channel'));
    my $w_channel = _normalize_w_channel(_required_hash($raw, 'w_channel'));
    my $status = _normalize_status(_required_hash($raw, 'status'));

    _reject_duplicate_signal_names(
        $clock,
        $reset->{signal},
        _binding_names($command),
        _binding_names($aw_channel),
        _binding_names($w_channel),
        _binding_names($status),
        qw(
            active_q aw_seen_q w_seen_q can_accept
            aw_done_i w_done_i aw_busy_i w_busy_i
            aw_cmd_valid_i aw_cmd_addr_i aw_cmd_id_i
            w_cmd_valid_i
            w_cmd_data0_i w_cmd_data1_i w_cmd_data2_i w_cmd_data3_i
            w_cmd_strb0_i w_cmd_strb1_i w_cmd_strb2_i w_cmd_strb3_i
            aw_driver w_driver coordinator
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
        aw_channel       => $aw_channel,
        w_channel        => $w_channel,
        status           => $status,
        intent_name      => $intent_name,
        source_object_id => $source_object_id,
        source_anchors   => $anchors,
    };
}

sub _normalize_command($raw) {
    my %command = (
        start => _required_identifier_field($raw, 'start', 'command.start'),
    );
    for my $field (@COMMAND_WIDTH_FIELDS) {
        my ($key, $width) = @$field;
        $command{$key} = _normalize_width_binding($raw->{$key}, "command.$key", $width);
    }
    return \%command;
}

sub _normalize_aw_channel($raw) {
    my %channel = (
        ready => _required_identifier_field($raw, 'ready', 'aw_channel.ready'),
        valid => _required_identifier_field($raw, 'valid', 'aw_channel.valid'),
    );
    for my $field (@AW_WIDTH_FIELDS) {
        my ($key, $width) = @$field;
        $channel{$key} = _normalize_width_binding($raw->{$key}, "aw_channel.$key", $width);
    }
    return \%channel;
}

sub _normalize_w_channel($raw) {
    my %channel = (
        ready => _required_identifier_field($raw, 'ready', 'w_channel.ready'),
        valid => _required_identifier_field($raw, 'valid', 'w_channel.valid'),
        last  => _required_identifier_field($raw, 'last', 'w_channel.last'),
    );
    for my $field (@W_WIDTH_FIELDS) {
        my ($key, $width) = @$field;
        $channel{$key} = _normalize_width_binding($raw->{$key}, "w_channel.$key", $width);
    }
    return \%channel;
}

sub _normalize_status($raw) {
    return {
        busy       => _required_identifier_field($raw, 'busy', 'status.busy'),
        beat_done  => _required_identifier_field($raw, 'beat_done', 'status.beat_done'),
        done       => _required_identifier_field($raw, 'done', 'status.done'),
        beat_index => _normalize_width_binding(
            $raw->{beat_index},
            'status.beat_index',
            2,
        ),
    };
}

sub _aw_child_contract($contract) {
    return {
        kind       => 'axi_aw_driver',
        protocol   => 'axi4',
        name       => 'axi_aw_driver',
        actor_name => 'axi_aw_driver',
        role       => 'manager-to-subordinate',
        clock      => $contract->{clock},
        reset      => _clone_jsonish($contract->{reset}),
        command => {
            start   => 'aw_cmd_valid_i',
            address => { name => 'aw_cmd_addr_i', width => 32 },
            id      => { name => 'aw_cmd_id_i', width => 4 },
            length  => { name => 'cmd_awlen', width => 8 },
            size    => { name => 'cmd_awsize', width => 3 },
            burst   => { name => 'cmd_awburst', width => 2 },
            ready   => $contract->{aw_channel}{ready},
        },
        channel => {
            valid   => $contract->{aw_channel}{valid},
            address => _clone_jsonish($contract->{aw_channel}{address}),
            id      => _clone_jsonish($contract->{aw_channel}{id}),
            length  => _clone_jsonish($contract->{aw_channel}{length}),
            size    => _clone_jsonish($contract->{aw_channel}{size}),
            burst   => _clone_jsonish($contract->{aw_channel}{burst}),
            busy    => 'aw_busy_i',
            done    => 'aw_done_i',
        },
        intent_name      => $contract->{intent_name},
        source_object_id => 'axi-aw-driver',
        source            => { anchors => [] },
    };
}

sub _w_child_contract($contract) {
    return {
        kind       => 'axi_w_burst4_driver',
        protocol   => 'axi4',
        name       => 'axi_w_burst4_driver',
        actor_name => 'axi_w_burst4_driver',
        role       => 'manager-to-subordinate',
        clock      => $contract->{clock},
        reset      => _clone_jsonish($contract->{reset}),
        command => {
            start   => 'w_cmd_valid_i',
            data0   => { name => 'w_cmd_data0_i', width => 32 },
            data1   => { name => 'w_cmd_data1_i', width => 32 },
            data2   => { name => 'w_cmd_data2_i', width => 32 },
            data3   => { name => 'w_cmd_data3_i', width => 32 },
            strobe0 => { name => 'w_cmd_strb0_i', width => 4 },
            strobe1 => { name => 'w_cmd_strb1_i', width => 4 },
            strobe2 => { name => 'w_cmd_strb2_i', width => 4 },
            strobe3 => { name => 'w_cmd_strb3_i', width => 4 },
            ready   => $contract->{w_channel}{ready},
        },
        channel => {
            valid  => $contract->{w_channel}{valid},
            data   => _clone_jsonish($contract->{w_channel}{data}),
            strobe => _clone_jsonish($contract->{w_channel}{strobe}),
            last   => $contract->{w_channel}{last},
            busy       => 'w_busy_i',
            beat_done  => $contract->{status}{beat_done},
            done       => 'w_done_i',
            beat_index => _clone_jsonish($contract->{status}{beat_index}),
        },
        intent_name      => $contract->{intent_name},
        source_object_id => 'axi-w-driver',
        source            => { anchors => [] },
    };
}

sub _generate_coordinator($self, $contract) {
    my $isf_name = 'axi_write_burst4_request_coordinator.isf';
    my $isf_text = _coordinator_isf($contract);
    my $adapter = FSM::Adapter::ISF->new(debug => $self->{debug});
    my $actor = $adapter->parse_source($isf_text, $isf_name);
    my $scheduler = FSM::Scheduler::ISF->new(debug => $self->{debug});
    my $lowered = $scheduler->lower($actor);
    my $schedule_report = JSON::PP->new->decode($scheduler->report($actor));

    return {
        layer => 'IAL1',
        kind  => 'generated_axi_write_burst4_request_coordinator',
        mode  => 'coordinator',
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
        report => {
            schema     => 'fsmgen.ial2.protocol_intent.axi_write_burst4_request_coordinator.v1',
            mode       => 'coordinator',
            actor_name => 'axi_write_burst4_request_coordinator',
            generated_artifacts => {
                ial1 => { name => $isf_name, format => 'isf' },
                ial0 => {
                    files  => [sort keys %{$lowered->{files} || {}}],
                    format => 'fsm',
                },
                hdl_entry => {
                    selected       => JSON::PP::false,
                    kind           => 'generated_coordinator_fsm',
                    entry_artifact => 'axi_write_burst4_request_coordinator.fsm',
                    module         => 'axi_write_burst4_request_coordinator',
                },
            },
        },
    };
}

sub _coordinator_isf($contract) {
    my $cmd = $contract->{command};
    my $status = $contract->{status};
    my $reset = _reset_clause($contract->{reset});
    my $address_name = $cmd->{address}{name};

    return join("\n",
        '(actor axi_write_burst4_request_coordinator',
        "  (clock $contract->{clock})",
        "  $reset",
        '  (interface',
        _interface_line('input', $cmd->{start}),
        _interface_line('input', $cmd->{address}),
        _interface_line('input', $cmd->{id}),
        (map { _interface_line('input', $cmd->{"data$_"}) } 0 .. 3),
        (map { _interface_line('input', $cmd->{"strobe$_"}) } 0 .. 3),
        '    (input aw_busy_i)',
        '    (input aw_done_i)',
        '    (input w_busy_i)',
        '    (input w_done_i)',
        '    (output aw_cmd_valid_i)',
        '    (output aw_cmd_addr_i (width 32))',
        '    (output aw_cmd_id_i (width 4))',
        '    (output w_cmd_valid_i)',
        '    (output w_cmd_data0_i (width 32))',
        '    (output w_cmd_data1_i (width 32))',
        '    (output w_cmd_data2_i (width 32))',
        '    (output w_cmd_data3_i (width 32))',
        '    (output w_cmd_strb0_i (width 4))',
        '    (output w_cmd_strb1_i (width 4))',
        '    (output w_cmd_strb2_i (width 4))',
        '    (output w_cmd_strb3_i (width 4))',
        _interface_line('output', $status->{busy}),
        _interface_line('output', $status->{done}) . ')',
        '',
        '  (priority finish_join over latch_aw)',
        '  (priority finish_join over latch_w)',
        '  (priority finish_join over admit)',
        '  (priority finish_join over clear_done)',
        '  (priority admit over latch_aw)',
        '  (priority admit over latch_w)',
        '  (priority admit over clear_child_starts)',
        '',
        '  (rule admit',
        "    (& (! active_q) (! aw_busy_i) (! w_busy_i) $cmd->{start}",
        "       (! ${address_name}[0]) (! ${address_name}[1])",
        "       (! (& ${address_name}[11] ${address_name}[10] ${address_name}[9]",
        "             ${address_name}[8] ${address_name}[7] ${address_name}[6]",
        "             ${address_name}[5] ${address_name}[4] ${address_name}[3]))",
        "       (! (& ${address_name}[11] ${address_name}[10] ${address_name}[9]",
        "             ${address_name}[8] ${address_name}[7] ${address_name}[6]",
        "             ${address_name}[5] ${address_name}[4] ${address_name}[2])))",
        '    (set active_q 1)',
        '    (set aw_seen_q 0)',
        '    (set w_seen_q 0)',
        '    (set aw_cmd_valid_i 1)',
        "    (set aw_cmd_addr_i $cmd->{address}{name})",
        "    (set aw_cmd_id_i $cmd->{id}{name})",
        '    (set w_cmd_valid_i 1)',
        (map { "    (set w_cmd_data${_}_i $cmd->{\"data$_\"}{name})" } 0 .. 3),
        (map { "    (set w_cmd_strb${_}_i $cmd->{\"strobe$_\"}{name})" } 0 .. 3),
        "    (set $status->{busy} 1))",
        '',
        '  (rule clear_child_starts (| aw_cmd_valid_i w_cmd_valid_i)',
        '    (set aw_cmd_valid_i 0)',
        '    (set w_cmd_valid_i 0))',
        '',
        '  (rule latch_aw (& active_q aw_done_i)',
        '    (set aw_seen_q 1))',
        '',
        '  (rule latch_w (& active_q w_done_i)',
        '    (set w_seen_q 1))',
        '',
        '  (rule finish_join',
        '    (& active_q (| aw_seen_q aw_done_i) (| w_seen_q w_done_i))',
        '    (set active_q 0)',
        '    (set aw_seen_q 0)',
        '    (set w_seen_q 0)',
        "    (set $status->{busy} 0)",
        "    (set $status->{done} 1))",
        '',
        "  (rule clear_done $status->{done}",
        "    (set $status->{done} 0))",
        '',
        '  (transaction aligned_boundary_command_check',
        '    (assert',
        "      (=> (& (! active_q) (! aw_busy_i) (! w_busy_i) $cmd->{start})",
        "          (& (! ${address_name}[0]) (! ${address_name}[1])",
        "             (! (& ${address_name}[11] ${address_name}[10] ${address_name}[9]",
        "                   ${address_name}[8] ${address_name}[7] ${address_name}[6]",
        "                   ${address_name}[5] ${address_name}[4] ${address_name}[3]))",
        "             (! (& ${address_name}[11] ${address_name}[10] ${address_name}[9]",
        "                   ${address_name}[8] ${address_name}[7] ${address_name}[6]",
        "                   ${address_name}[5] ${address_name}[4] ${address_name}[2]))))",
        '      "fixed-four AXI INCR write request must be four-byte aligned and remain within 4 KiB"))',
        ')',
        '',
    );
}

sub _add_generated_child(%args) {
    my $result = $args{result};
    my @fsm_names = sort keys %{$result->{generated_ial0}{files} || {}};

    push @{$args{ial1_items}}, {
        object_name   => $args{object_name},
        role          => $args{role},
        instance_name => $args{instance_name},
        format        => $result->{generated_ial1}{format},
        name          => $result->{generated_ial1}{name},
        text          => $result->{generated_ial1}{text},
    };
    for my $fsm_name (@fsm_names) {
        confess "Error: AXI write burst4 request composition generated duplicate child .fsm artifact '$fsm_name'\n"
            if exists $args{fsm_files}{$fsm_name};
        $args{fsm_files}{$fsm_name} = $result->{generated_ial0}{files}{$fsm_name};
    }
    my $entry_artifact = $result->{report}{generated_artifacts}{hdl_entry}{entry_artifact};
    push @{$args{ial0_items}}, {
        object_name    => $args{object_name},
        role           => $args{role},
        instance_name  => $args{instance_name},
        kind           => 'generated_endpoint',
        format         => 'fsm',
        files          => \@fsm_names,
        entry_artifact => $entry_artifact,
    };
    push @{$args{schedule_reports}}, {
        object_name   => $args{object_name},
        role          => $args{role},
        instance_name => $args{instance_name},
        report        => _clone_jsonish($result->{generated_ial1_schedule_report}),
    };
}

sub _build_structural_top($contract, $fsm_files) {
    my $entry_artifact = "$contract->{actor_name}.fsm";
    my @child_artifacts = qw(
        axi_aw_driver.fsm
        axi_w_burst4_driver.fsm
        axi_write_burst4_request_coordinator.fsm
    );
    for my $artifact (@child_artifacts) {
        confess "Error: AXI write burst4 request composition is missing generated child .fsm artifact '$artifact'\n"
            unless exists $fsm_files->{$artifact};
    }

    my @lines = (
        "(?top:$contract->{actor_name}",
        '  (?ports:public_io',
        (map { '    ' . _top_port_token($_) } _top_port_specs($contract)),
        '  )',
        '  (?fsmc:aw_driver axi_aw_driver)',
        '  (?fsmc:w_driver axi_w_burst4_driver)',
        '  (?fsmc:coordinator axi_write_burst4_request_coordinator)',
        '  (?wiring:axi_write_burst4_request_wiring',
        (map { "    $_" } _wiring_lines($contract)),
        '  )',
        ')',
        '',
    );
    for my $artifact (@child_artifacts) {
        push @lines, $fsm_files->{$artifact}, '';
    }

    return {
        entry_artifact => $entry_artifact,
        text           => join("\n", @lines),
        ial0_item      => {
            object_name     => $contract->{name},
            role            => 'composition',
            kind            => 'generated_composition_top',
            format          => 'fsm',
            files           => [$entry_artifact],
            entry_artifact  => $entry_artifact,
            child_artifacts => \@child_artifacts,
        },
        report_entry => {
            selected        => JSON::PP::true,
            kind            => 'generated_composition_top',
            format          => 'fsm',
            module          => $contract->{actor_name},
            entry_artifact  => $entry_artifact,
            child_artifacts => \@child_artifacts,
            port_policy     => {
                shared_system_ports => {
                    clock => $contract->{clock},
                    reset => _clone_jsonish($contract->{reset}),
                },
                axi_wiring => 'explicit_parallel_aw_w_burst4_request_join',
            },
        },
    };
}

sub _top_port_specs($contract) {
    my $cmd = $contract->{command};
    my $aw = $contract->{aw_channel};
    my $w = $contract->{w_channel};
    my $status = $contract->{status};

    return (
        { name => $contract->{clock}, direction => 'system', width => 1, system => 1 },
        { name => $contract->{reset}{signal}, direction => 'system', width => 1, system => 1 },
        _input_port($cmd->{start}, 1),
        _input_port($cmd->{address}{name}, $cmd->{address}{width}),
        _input_port($cmd->{id}{name}, $cmd->{id}{width}),
        (map { _input_port($cmd->{"data$_"}{name}, $cmd->{"data$_"}{width}) } 0 .. 3),
        (map { _input_port($cmd->{"strobe$_"}{name}, $cmd->{"strobe$_"}{width}) } 0 .. 3),
        _input_port($aw->{ready}, 1),
        _input_port($w->{ready}, 1),
        _output_port($aw->{valid}, 1),
        _output_port($aw->{address}{name}, $aw->{address}{width}),
        _output_port($aw->{id}{name}, $aw->{id}{width}),
        _output_port($aw->{length}{name}, $aw->{length}{width}),
        _output_port($aw->{size}{name}, $aw->{size}{width}),
        _output_port($aw->{burst}{name}, $aw->{burst}{width}),
        _output_port($w->{valid}, 1),
        _output_port($w->{data}{name}, $w->{data}{width}),
        _output_port($w->{strobe}{name}, $w->{strobe}{width}),
        _output_port($w->{last}, 1),
        _output_port($status->{busy}, 1),
        _output_port($status->{beat_done}, 1),
        _output_port($status->{done}, 1),
        _output_port($status->{beat_index}{name}, $status->{beat_index}{width}),
    );
}

sub _input_port($binding, $width) {
    my $name = ref($binding) eq 'HASH' ? $binding->{name} : $binding;
    return { name => $name, direction => 'input', width => $width };
}

sub _output_port($binding, $width) {
    my $name = ref($binding) eq 'HASH' ? $binding->{name} : $binding;
    return { name => $name, direction => 'output', width => $width };
}

sub _top_port_token($spec) {
    return $spec->{width} == 1 ? $spec->{name} : "$spec->{name}<$spec->{width}"
        if $spec->{system};
    return $spec->{width} == 1 ? "=$spec->{name}" : "=$spec->{name}<$spec->{width}"
        if $spec->{direction} eq 'input';
    return $spec->{width} == 1 ? "=$spec->{name}>" : "=$spec->{name}>$spec->{width}";
}

sub _wiring_lines($contract) {
    return (
        '(aw_driver.aw_busy_i coordinator.aw_busy_i)',
        '(aw_driver.aw_done_i coordinator.aw_done_i)',
        '(w_driver.w_busy_i coordinator.w_busy_i)',
        '(w_driver.w_done_i coordinator.w_done_i)',
        '(coordinator.aw_cmd_valid_i aw_driver.aw_cmd_valid_i)',
        '(coordinator.aw_cmd_addr_i aw_driver.aw_cmd_addr_i)',
        '(coordinator.aw_cmd_id_i aw_driver.aw_cmd_id_i)',
        "(=8'd3 aw_driver.cmd_awlen)",
        "(=3'd2 aw_driver.cmd_awsize)",
        "(=2'b01 aw_driver.cmd_awburst)",
        '(coordinator.w_cmd_valid_i w_driver.w_cmd_valid_i)',
        (map { "(coordinator.w_cmd_data${_}_i w_driver.w_cmd_data${_}_i)" } 0 .. 3),
        (map { "(coordinator.w_cmd_strb${_}_i w_driver.w_cmd_strb${_}_i)" } 0 .. 3),
    );
}

sub _build_report(%args) {
    my $contract = $args{contract};
    my @ial1_items = @{$args{ial1_items}};
    my @ial0_items = @{$args{ial0_items}};
    my @schedule_reports = @{$args{schedule_reports}};
    my @fsm_files = sort keys %{$args{fsm_files}};

    my $report = {
        schema => 'fsmgen.ial2.protocol_intent.axi_write_burst4_request_composition.v1',
        mode   => 'write-burst4-request-composition',
        layering => {
            source_layer          => 'IAL2',
            generated_ial1_format => 'isf',
            generated_ial0_format => 'fsm',
            direct_ial2_to_ial0   => JSON::PP::false,
        },
        source_object => {
            id          => $contract->{source_object_id},
            intent_name => $contract->{intent_name},
            anchors     => _clone_jsonish($contract->{source_anchors}),
        },
        target_protocol => {
            profile => $contract->{protocol},
            object  => 'axi-write-burst4-request-composition',
            role    => $contract->{role},
        },
        composition => {
            name                 => $contract->{name},
            actor_name           => $contract->{actor_name},
            topology             => 'parallel_aw_w_burst4_request_join',
            child_instance_count => 3,
            children => [
                { role => 'aw-driver', instance_name => 'aw_driver', object_name => 'axi_aw_driver' },
                { role => 'w-driver', instance_name => 'w_driver', object_name => 'axi_w_burst4_driver' },
                { role => 'coordinator', instance_name => 'coordinator', object_name => 'axi_write_burst4_request_coordinator' },
            ],
            wiring_policy => 'explicit_parallel_aw_w_burst4_request_join',
            shared_system_ports => {
                clock => $contract->{clock},
                reset => _clone_jsonish($contract->{reset}),
            },
            top_ports => [map { _clone_jsonish($_) } _top_port_specs($contract)],
        },
        bindings => {
            clock      => $contract->{clock},
            reset      => _clone_jsonish($contract->{reset}),
            command    => _clone_jsonish($contract->{command}),
            aw_channel => _clone_jsonish($contract->{aw_channel}),
            w_channel  => _clone_jsonish($contract->{w_channel}),
            status     => _clone_jsonish($contract->{status}),
        },
        fixed_four_request_policy => {
            address_width           => 32,
            address_alignment_bytes => 4,
            address_span_bytes      => 16,
            four_kib_contained      => JSON::PP::true,
            id_width                => 4,
            data_width              => 32,
            strobe_width            => 4,
            all_zero_strobe_allowed => JSON::PP::true,
            awlen                   => 3,
            awsize                  => 2,
            awburst                 => 1,
            awburst_name            => 'INCR',
            beat_count              => 4,
            beat_index_width        => 2,
            last_sequence           => [0, 0, 0, 1],
            payload_authoring       => 'explicit_four_tuple_fields',
            payload_capture         => 'atomic_on_idle_command',
            beat_event              => 'direct_w_child_accepted_transfer',
            request_completion      => 'both_aw_and_final_w_accepted',
        },
        coordinator => {
            actor_name          => 'axi_write_burst4_request_coordinator',
            admission_policy    => 'idle_level_sampled',
            queue_depth         => 0,
            payload_capture     => 'atomic_on_admission',
            alignment_guard     => 'four_byte_aligned_and_16_byte_span_within_4kib',
            alignment_assertion => 'admissible_idle_attempt_implies_fixed_four_boundary_legal',
            child_start_policy  => 'one_registered_pulse_each',
            completion_history  => 'remember_aw_done_and_w_done_independently',
            completion_policy   => 'one_pulse_after_aw_and_final_w_accept',
            beat_status_policy  => 'direct_from_unchanged_w_burst4_child',
            response_completion => JSON::PP::false,
        },
        children => [
            _child_report('aw-driver', 'aw_driver', $args{aw_result}),
            _child_report('w-driver', 'w_driver', $args{w_result}),
            _child_report('coordinator', 'coordinator', $args{coordinator_result}),
        ],
        generated_schedules => {
            count => scalar(@schedule_reports),
            items => _clone_jsonish(\@schedule_reports),
        },
        generated_artifacts => {
            ial1 => {
                format => 'isf',
                items  => [map {
                    {
                        object_name   => $_->{object_name},
                        role          => $_->{role},
                        instance_name => $_->{instance_name},
                        name          => $_->{name},
                        format        => $_->{format},
                    }
                } @ial1_items],
            },
            ial0 => {
                format => 'fsm',
                files  => \@fsm_files,
                items  => _clone_jsonish(\@ial0_items),
            },
            hdl_entry => _clone_jsonish($args{hdl_entry}),
        },
        enforced_static_rules => _enforced_static_rules(),
        unsupported_residue   => _unsupported_residue(),
    };
    return $report;
}

sub _child_report($role, $instance_name, $result) {
    return {
        role                => $role,
        instance_name       => $instance_name,
        target_protocol     => _clone_jsonish($result->{report}{target_protocol}),
        bindings            => _clone_jsonish($result->{report}{bindings}),
        generated_artifacts => _clone_jsonish($result->{report}{generated_artifacts}),
        unsupported_residue => _clone_jsonish($result->{report}{unsupported_residue} || []),
    };
}

sub _enforced_static_rules {
    return [
        'AXI4 manager-to-subordinate fixed-four AW+W request composition',
        'shared clock and asynchronous active-low reset across all three children',
        'idle command atomically captures address32 ID4 and four explicit data32 strobe4 tuples',
        'admission requires four-byte alignment and a 16-byte span contained within one 4-KiB region',
        'AW metadata is fixed to LEN3 SIZE2 INCR',
        'flat C4 reuses unchanged AW and W-burst4 actors plus one join coordinator',
        'one admitted command emits one one-cycle start to each child',
        'AW and final-W completions are independently remembered and joined',
        'one active request ignores busy commands and has no queue',
        'W beat event and index are direct unchanged-child outputs',
        'request done excludes B response acceptance and transaction success',
        'arbitrary per-beat WSTRB including zero remains legal',
        'reset aborts without phantom beat or request completion and recovery restarts',
        'selected top is the exact 29-signal 3-child 66-net 46-declared-link 52-resolved-link C4 composition',
        'lowering uses three generated IAL1 and leaf IAL0 actors plus one structural top never direct IAL2-to-IAL0',
    ];
}

sub _unsupported_residue {
    return [
        { id => 'axi_write_burst4_request_composition_b_response_full_transaction_deferred', detail => 'B arming BID BRESP and full write-transaction completion remain separate' },
        { id => 'axi_write_burst4_request_composition_dynamic_burst_deferred', detail => 'authored or dynamic length and variable payload cardinality remain unsupported' },
        { id => 'axi_write_burst4_request_composition_narrow_unaligned_wrap_attributes_deferred', detail => 'narrow unaligned FIXED WRAP and extended AW attributes remain unsupported' },
        { id => 'axi_write_burst4_request_composition_packed_streaming_payload_deferred', detail => 'packed banks and streaming producer handshakes remain unsupported' },
        { id => 'axi_write_burst4_request_composition_capacity_core_integration_deferred', detail => 'capacity submit completion and storage integration remain separate' },
        { id => 'axi_write_burst4_request_composition_outstanding_queueing_deferred', detail => 'back-to-back buffering queues and multiple outstanding requests remain unsupported' },
        { id => 'axi_write_burst4_request_composition_id_allocation_ordering_demux_deferred', detail => 'ID allocation reuse ordering response demux and interleaving remain separate' },
        { id => 'axi_write_burst4_request_composition_malformed_subordinate_recovery_deferred', detail => 'timeout abort retry and bus resynchronization policy remain unsupported' },
        { id => 'axi_write_burst4_request_composition_response_aggregation_output_banks_deferred', detail => 'response aggregation and output banks are not request-composition responsibilities' },
        { id => 'axi_write_burst4_request_composition_transaction_interface_deferred', detail => 'decision 0020 protocol-neutral transaction interface remains director-gated' },
        { id => 'axi_write_burst4_request_composition_profile_alias_deferred', detail => 'the .axi alias remains unsupported for this object' },
        { id => 'axi_write_burst4_request_composition_verification_output_deferred', detail => 'direct verification-output generation remains unsupported' },
        { id => 'axi_write_burst4_request_composition_backend_variants_deferred', detail => 'direct backend VHDL and backend-language variants remain unchanged' },
        { id => 'axi_write_burst4_request_composition_other_protocols_unchanged', detail => 'AHB and APB parsing lowering artifacts and behavior remain unchanged' },
    ];
}

sub _required_scalar($raw, $field) {
    confess "AXI write burst4 request composition IAL2 contract is missing required scalar field '$field'\n"
        unless exists($raw->{$field});
    return _nonempty_scalar($raw->{$field}, $field);
}

sub _required_hash($raw, $field) {
    confess "AXI write burst4 request composition IAL2 contract field '$field' must be a hash reference\n"
        unless ref($raw->{$field}) eq 'HASH';
    return $raw->{$field};
}

sub _required_identifier($raw, $field) {
    return _identifier_value(_required_scalar($raw, $field), $field);
}

sub _required_identifier_field($raw, $field, $label) {
    confess "AXI write burst4 request composition IAL2 contract is missing required field '$label'\n"
        unless exists($raw->{$field});
    return _identifier_value($raw->{$field}, $label);
}

sub _normalize_width_binding($raw, $field, $expected_width) {
    confess "AXI write burst4 request composition IAL2 contract field '$field' must be a hash reference\n"
        unless ref($raw) eq 'HASH';
    my $name = _identifier_value($raw->{name}, "$field.name");
    my $width = _positive_integer($raw->{width}, "$field.width");
    confess "AXI write burst4 request composition IAL2 contract $field.width must be $expected_width in this slice\n"
        unless $width == $expected_width;
    return { name => $name, width => $width };
}

sub _normalize_reset($raw_reset) {
    confess "AXI write burst4 request composition IAL2 contract is missing required reset binding\n"
        unless defined $raw_reset;

    my %reset;
    if (ref($raw_reset) eq 'HASH') {
        $reset{signal} = _identifier_value($raw_reset->{signal}, 'reset.signal');
        $reset{active_low} = exists($raw_reset->{active_low})
            ? _bool_value($raw_reset->{active_low}, 'reset.active_low')
            : ($reset{signal} =~ /_n\z/i ? 1 : 0);
        $reset{polarity_source} = exists($raw_reset->{active_low}) ? 'explicit' : 'signal_name_convention';
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
    confess "AXI write burst4 request composition IAL2 contract source.anchors must be an array reference\n"
        unless ref($anchors) eq 'ARRAY';

    my @normalized;
    for my $index (0 .. $#$anchors) {
        my $anchor = $anchors->[$index];
        if (ref($anchor) eq 'HASH') {
            for my $required (qw(document section page)) {
                confess "AXI write burst4 request composition IAL2 contract source.anchors[$index] is missing '$required'\n"
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
        confess "AXI write burst4 request composition IAL2 contract duplicates signal '$name'\n"
            if $seen{$name}++;
    }
}

sub _nonempty_scalar($value, $field) {
    confess "AXI write burst4 request composition IAL2 contract field '$field' must be a non-empty scalar\n"
        if !defined($value) || ref($value) || $value eq '';
    return $value;
}

sub _identifier_value($value, $field) {
    confess "AXI write burst4 request composition IAL2 contract field '$field' must be an ISF identifier\n"
        unless defined($value) && !ref($value)
            && $value =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
    return $value;
}

sub _positive_integer($value, $field) {
    confess "AXI write burst4 request composition IAL2 contract field '$field' must be a positive integer\n"
        unless defined($value) && !ref($value) && $value =~ /\A[1-9][0-9]*\z/;
    return int($value);
}

sub _bool_value($value, $field) {
    confess "AXI write burst4 request composition IAL2 contract field '$field' must be boolean 0 or 1\n"
        if ref($value) || !defined($value) || ($value ne '0' && $value ne '1');
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
    return '(reset (' . join(' ', @parts) . '))';
}

sub _clone_jsonish($value) {
    return $value unless ref($value);
    return [map { _clone_jsonish($_) } @$value] if ref($value) eq 'ARRAY';
    return { map { $_ => _clone_jsonish($value->{$_}) } keys %$value }
        if ref($value) eq 'HASH';
    return $value;
}

1;
