package FSM::IAL2::ProtocolIntent::AxiReadBurst4TransactionComposition;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use JSON::PP ();
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings qw(experimental::signatures experimental::postderef);

use FSM::Adapter::ISF;
use FSM::IAL2::ProtocolIntent::AxiArDriver;
use FSM::IAL2::ProtocolIntent::AxiRBeatAcceptor;
use FSM::Scheduler::ISF;

my @COMMAND_WIDTH_FIELDS = (
    [address => 32],
    [id      => 4],
);

my @AR_WIDTH_FIELDS = (
    [address => 32],
    [id      => 4],
    [length  => 8],
    [size    => 3],
    [burst   => 2],
);

my @R_WIDTH_FIELDS = (
    [id                => 4],
    [data              => 32],
    [response          => 2],
    [captured_id       => 4],
    [captured_data     => 32],
    [captured_response => 2],
);

my @PRIVATE_SIGNAL_NAMES = qw(
    ar_cmd_valid_i ar_cmd_addr_i ar_cmd_id_i ar_busy_i ar_done_i
    r_arm_i r_busy_i r_done_i captured_rid_i captured_rlast_i
    active_q expected_arid_q response_armed_q beat_index_q
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
    confess "FSM::IAL2::ProtocolIntent::AxiReadBurst4TransactionComposition->generate expects exactly one contract hash reference\n"
        unless @args == 1 && ref($args[0]) eq 'HASH';

    my $contract = _normalize_contract($args[0]);
    my $ar_result = FSM::IAL2::ProtocolIntent::AxiArDriver
        ->new(debug => $self->{debug})
        ->generate(_ar_driver_contract($contract));
    my $r_result = FSM::IAL2::ProtocolIntent::AxiRBeatAcceptor
        ->new(debug => $self->{debug})
        ->generate(_r_acceptor_contract($contract));
    my $coordinator_result = _generate_transaction_coordinator($self, $contract);

    my (@ial1_items, @ial0_items, @schedule_reports);
    my %fsm_files;
    _add_single_child(
        result           => $ar_result,
        object_name      => 'axi_ar_driver',
        role             => 'ar-driver',
        instance_name    => 'ar_driver',
        ial1_items       => \@ial1_items,
        ial0_items       => \@ial0_items,
        schedule_reports => \@schedule_reports,
        fsm_files        => \%fsm_files,
    );
    _add_single_child(
        result           => $r_result,
        object_name      => 'axi_r_beat_acceptor',
        role             => 'r-acceptor',
        instance_name    => 'r_acceptor',
        ial1_items       => \@ial1_items,
        ial0_items       => \@ial0_items,
        schedule_reports => \@schedule_reports,
        fsm_files        => \%fsm_files,
    );
    _add_single_child(
        result           => $coordinator_result,
        object_name      => 'axi_read_burst4_transaction_coordinator',
        role             => 'transaction-coordinator',
        instance_name    => 'transaction_coordinator',
        ial1_items       => \@ial1_items,
        ial0_items       => \@ial0_items,
        schedule_reports => \@schedule_reports,
        fsm_files        => \%fsm_files,
    );

    confess "Error: AXI read burst4 transaction composition expected three generated IAL1 children\n"
        unless @ial1_items == 3;
    confess "Error: AXI read burst4 transaction composition expected three generated schedule reports\n"
        unless @schedule_reports == 3;
    confess "Error: AXI read burst4 transaction composition expected three generated leaf .fsm artifacts\n"
        unless keys(%fsm_files) == 3;

    my $top = _build_structural_top($contract, \%fsm_files);
    confess "Error: AXI read burst4 transaction composition generated duplicate .fsm artifact '$top->{entry_artifact}'\n"
        if exists $fsm_files{$top->{entry_artifact}};
    $fsm_files{$top->{entry_artifact}} = $top->{text};
    push @ial0_items, $top->{ial0_item};

    confess "Error: AXI read burst4 transaction composition expected four generated IAL0 artifacts\n"
        unless @ial0_items == 4 && keys(%fsm_files) == 4;

    my $report = _build_report(
        contract           => $contract,
        ar_result          => $ar_result,
        r_result           => $r_result,
        coordinator_result => $coordinator_result,
        ial1_items         => \@ial1_items,
        ial0_items         => \@ial0_items,
        schedule_reports   => \@schedule_reports,
        fsm_files          => \%fsm_files,
        hdl_entry          => $top->{report_entry},
    );

    return {
        layer => 'IAL2',
        kind  => 'protocol_intent.axi_read_burst4_transaction_composition',
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
    confess "FSM::IAL2::ProtocolIntent::AxiReadBurst4TransactionComposition->new must be called with the FSM::IAL2::ProtocolIntent::AxiReadBurst4TransactionComposition class invocant\n"
        unless defined($class) && !ref($class)
            && $class eq 'FSM::IAL2::ProtocolIntent::AxiReadBurst4TransactionComposition';
}

sub _validate_constructor_args($class, @args) {
    confess "$class->new expects named options\n" if @args % 2;
    my %options = @args;
    my %allowed = map { $_ => 1 } qw(debug);
    for my $name (sort keys %options) {
        confess "$class->new unsupported option '$name'; supported option: debug\n"
            unless $allowed{$name};
    }
    return %options;
}

sub _validate_object_receiver($self, $method) {
    confess "FSM::IAL2::ProtocolIntent::AxiReadBurst4TransactionComposition->$method must be called on an FSM::IAL2::ProtocolIntent::AxiReadBurst4TransactionComposition object\n"
        unless blessed($self)
            && $self->isa('FSM::IAL2::ProtocolIntent::AxiReadBurst4TransactionComposition');
}

sub _normalize_contract($raw) {
    my $kind = _required_scalar($raw, 'kind');
    confess "AXI read burst4 transaction composition IAL2 contract kind must be axi_read_burst4_transaction_composition\n"
        unless $kind eq 'axi_read_burst4_transaction_composition';

    my $protocol = lc _required_scalar($raw, 'protocol');
    confess "AXI read burst4 transaction composition IAL2 contract profile must be axi4 in this slice\n"
        unless $protocol eq 'axi4';

    my $name = _required_identifier($raw, 'name');
    my $actor_name = exists($raw->{actor_name})
        ? _identifier_value($raw->{actor_name}, 'actor_name')
        : $name;
    my $role = lc _required_scalar($raw, 'role');
    confess "AXI read burst4 transaction composition IAL2 contract role must be manager\n"
        unless $role eq 'manager';

    my $clock = _required_identifier($raw, 'clock');
    my $reset = _normalize_reset($raw->{reset});
    confess "AXI read burst4 transaction composition reset must be asynchronous active-low in this slice\n"
        unless $reset->{async} && $reset->{active_low};

    my $command = _normalize_command(_required_hash($raw, 'command'));
    my $ar_channel = _normalize_ar_channel(_required_hash($raw, 'ar_channel'));
    my $r_channel = _normalize_r_channel(_required_hash($raw, 'r_channel'));
    my $status = _normalize_status(_required_hash($raw, 'status'));

    _reject_duplicate_signal_names(
        $clock,
        $reset->{signal},
        _binding_names($command),
        _binding_names($ar_channel),
        _binding_names($r_channel),
        _binding_names($status),
        @PRIVATE_SIGNAL_NAMES,
        qw(
            ar_cmd_valid cmd_araddr cmd_arid cmd_arlen cmd_arsize cmd_arburst
            ar_busy ar_done r_accept_cmd_valid r_busy r_beat_done
            ar_driver r_acceptor transaction_coordinator
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
        ar_channel       => $ar_channel,
        r_channel        => $r_channel,
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

sub _normalize_ar_channel($raw) {
    my %channel = (
        ready => _required_identifier_field($raw, 'ready', 'ar_channel.ready'),
        valid => _required_identifier_field($raw, 'valid', 'ar_channel.valid'),
    );
    for my $field (@AR_WIDTH_FIELDS) {
        my ($key, $width) = @$field;
        $channel{$key} = _normalize_width_binding($raw->{$key}, "ar_channel.$key", $width);
    }
    return \%channel;
}

sub _normalize_r_channel($raw) {
    my %channel = (
        valid         => _required_identifier_field($raw, 'valid', 'r_channel.valid'),
        ready         => _required_identifier_field($raw, 'ready', 'r_channel.ready'),
        last          => _required_identifier_field($raw, 'last', 'r_channel.last'),
        captured_last => _required_identifier_field($raw, 'captured_last', 'r_channel.captured_last'),
    );
    for my $field (@R_WIDTH_FIELDS) {
        my ($key, $width) = @$field;
        $channel{$key} = _normalize_width_binding($raw->{$key}, "r_channel.$key", $width);
    }
    return \%channel;
}

sub _normalize_status($raw) {
    return {
        busy              => _required_identifier_field($raw, 'busy', 'status.busy'),
        request_done      => _required_identifier_field($raw, 'request_done', 'status.request_done'),
        beat_done         => _required_identifier_field($raw, 'beat_done', 'status.beat_done'),
        transaction_done  => _required_identifier_field($raw, 'transaction_done', 'status.transaction_done'),
        response_beat_index => _normalize_width_binding(
            $raw->{response_beat_index},
            'status.response_beat_index',
            2,
        ),
        response_id_match => _required_identifier_field($raw, 'response_id_match', 'status.response_id_match'),
        response_last_match => _required_identifier_field($raw, 'response_last_match', 'status.response_last_match'),
    };
}

sub _ar_driver_contract($contract) {
    my $ar = $contract->{ar_channel};
    return {
        kind       => 'axi_ar_driver',
        protocol   => 'axi4',
        name       => 'axi_ar_driver',
        actor_name => 'axi_ar_driver',
        role       => 'manager-to-subordinate',
        clock      => $contract->{clock},
        reset      => _clone_jsonish($contract->{reset}),
        command => {
            start   => 'ar_cmd_valid',
            address => { name => 'cmd_araddr', width => 32 },
            id      => { name => 'cmd_arid', width => 4 },
            length  => { name => 'cmd_arlen', width => 8 },
            size    => { name => 'cmd_arsize', width => 3 },
            burst   => { name => 'cmd_arburst', width => 2 },
            ready   => $ar->{ready},
        },
        channel => {
            valid   => $ar->{valid},
            address => _clone_jsonish($ar->{address}),
            id      => _clone_jsonish($ar->{id}),
            length  => _clone_jsonish($ar->{length}),
            size    => _clone_jsonish($ar->{size}),
            burst   => _clone_jsonish($ar->{burst}),
            busy    => 'ar_busy',
            done    => 'ar_done',
        },
        intent_name      => $contract->{intent_name},
        source_object_id => 'axi-ar-driver',
        source            => { anchors => _ar_source_anchors($contract) },
    };
}

sub _r_acceptor_contract($contract) {
    my $r = $contract->{r_channel};
    return {
        kind       => 'axi_r_beat_acceptor',
        protocol   => 'axi4',
        name       => 'axi_r_beat_acceptor',
        actor_name => 'axi_r_beat_acceptor',
        role       => 'subordinate-to-manager',
        clock      => $contract->{clock},
        reset      => _clone_jsonish($contract->{reset}),
        command => {
            arm => 'r_accept_cmd_valid',
        },
        channel => {
            valid             => $r->{valid},
            ready             => $r->{ready},
            id                => _clone_jsonish($r->{id}),
            data              => _clone_jsonish($r->{data}),
            response          => _clone_jsonish($r->{response}),
            last              => $r->{last},
            captured_id       => _clone_jsonish($r->{captured_id}),
            captured_data     => _clone_jsonish($r->{captured_data}),
            captured_response => _clone_jsonish($r->{captured_response}),
            captured_last     => $r->{captured_last},
            busy              => 'r_busy',
            done              => 'r_beat_done',
        },
        intent_name      => $contract->{intent_name},
        source_object_id => 'axi-r-beat-acceptor',
        source            => { anchors => _r_source_anchors($contract) },
    };
}

sub _ar_source_anchors($contract) {
    return [] unless @{$contract->{source_anchors}} >= 13;
    return [map { _clone_jsonish($_) } @{$contract->{source_anchors}}[0 .. 7, 11]];
}

sub _r_source_anchors($contract) {
    return [] unless @{$contract->{source_anchors}} >= 13;
    return [map { _clone_jsonish($_) } @{$contract->{source_anchors}}[0, 1, 2, 3, 8, 9, 10, 12]];
}

sub _generate_transaction_coordinator($self, $contract) {
    my $isf_name = 'axi_read_burst4_transaction_coordinator.isf';
    my $isf_text = _transaction_coordinator_isf($contract);
    my $adapter = FSM::Adapter::ISF->new(debug => $self->{debug});
    my $actor = $adapter->parse_source($isf_text, $isf_name);
    my $scheduler = FSM::Scheduler::ISF->new(debug => $self->{debug});
    my $lowered = $scheduler->lower($actor);
    my $schedule_report = JSON::PP->new->decode($scheduler->report($actor));

    return {
        layer => 'IAL1',
        kind  => 'protocol_intent.axi_read_burst4_transaction_coordinator',
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
            schema => 'fsmgen.ial2.protocol_intent.axi_read_burst4_transaction_coordinator.v1',
            mode   => 'coordinator',
            generated_artifacts => {
                ial1 => { name => $isf_name, format => 'isf' },
                ial0 => { files => [sort keys %{$lowered->{files} || {}}], format => 'fsm' },
                hdl_entry => {
                    selected       => JSON::PP::false,
                    kind           => 'generated_coordinator_fsm',
                    module         => 'axi_read_burst4_transaction_coordinator',
                    entry_artifact => 'axi_read_burst4_transaction_coordinator.fsm',
                },
            },
            enforced_static_rules => [],
            unsupported_residue   => [],
        },
    };
}

sub _transaction_coordinator_isf($contract) {
    my $cmd = $contract->{command};
    my $status = $contract->{status};
    my $reset = _reset_clause($contract->{reset});
    my $address = $cmd->{address}{name};

    return join("\n",
        '(actor axi_read_burst4_transaction_coordinator',
        "  (clock $contract->{clock})",
        "  $reset",
        '  (interface',
        _interface_line('input', $cmd->{start}),
        _interface_line('input', $cmd->{address}),
        _interface_line('input', $cmd->{id}),
        '    (input ar_busy_i)',
        '    (input ar_done_i)',
        '    (input r_busy_i)',
        '    (input r_done_i)',
        '    (input captured_rid_i (width 4))',
        '    (input captured_rlast_i)',
        '    (output ar_cmd_valid_i)',
        '    (output ar_cmd_addr_i (width 32))',
        '    (output ar_cmd_id_i (width 4))',
        '    (output r_arm_i)',
        _interface_line('output', $status->{busy}),
        _interface_line('output', $status->{request_done}),
        _interface_line('output', $status->{beat_done}),
        _interface_line('output', $status->{transaction_done}),
        _interface_line('output', $status->{response_beat_index}),
        _interface_line('output', $status->{response_id_match}),
        _interface_line('output', $status->{response_last_match}) . ')',
        '',
        '  (storage',
        '    (var beat_index_q (width 2) (reset 0)))',
        '',
        '  (priority finish_burst over advance_beat)',
        '  (priority finish_burst over arm_next_response)',
        '  (priority finish_burst over clear_beat_done)',
        '  (priority finish_burst over clear_transaction_done)',
        '  (priority advance_beat over arm_next_response)',
        '  (priority advance_beat over clear_beat_done)',
        '  (priority arm_first_response over clear_r_arm)',
        '  (priority arm_first_response over clear_request_done)',
        '  (priority arm_next_response over clear_r_arm)',
        '  (priority admit over clear_ar_start)',
        '',
        "  (rule admit (& (! active_q) (! ar_busy_i) (! r_busy_i) $cmd->{start}",
        "                 (! ${address}[0]) (! ${address}[1])",
        "                 (! (& ${address}[11] ${address}[10] ${address}[9]",
        "                       ${address}[8] ${address}[7] ${address}[6]",
        "                       ${address}[5] ${address}[4]",
        "                       (| ${address}[3] ${address}[2]))))",
        '    (set active_q 1)',
        '    (set ar_cmd_valid_i 1)',
        "    (set ar_cmd_addr_i $cmd->{address}{name})",
        "    (set ar_cmd_id_i $cmd->{id}{name})",
        "    (set expected_arid_q $cmd->{id}{name})",
        '    (set beat_index_q 0)',
        '    (set response_armed_q 0)',
        "    (set $status->{busy} 1)",
        "    (set $status->{response_id_match} 1)",
        "    (set $status->{response_last_match} 1))",
        '',
        '  (rule clear_ar_start ar_cmd_valid_i',
        '    (set ar_cmd_valid_i 0))',
        '',
        '  (rule arm_first_response (& active_q (! response_armed_q) (== beat_index_q 0)',
        '                              ar_done_i (! r_busy_i))',
        '    (set response_armed_q 1)',
        '    (set r_arm_i 1)',
        "    (set $status->{request_done} 1))",
        '',
        '  (rule arm_next_response (& active_q (! response_armed_q) (! (== beat_index_q 0))',
        '                             (! r_busy_i))',
        '    (set response_armed_q 1)',
        '    (set r_arm_i 1))',
        '',
        '  (rule clear_r_arm r_arm_i',
        '    (set r_arm_i 0))',
        '',
        "  (rule clear_request_done $status->{request_done}",
        "    (set $status->{request_done} 0))",
        '',
        '  (rule advance_beat (& active_q response_armed_q r_done_i (! (== beat_index_q 3)))',
        "    (set $status->{beat_done} 1)",
        "    (set $status->{response_beat_index}{name} beat_index_q)",
        "    (set $status->{response_id_match} (& $status->{response_id_match} (== captured_rid_i expected_arid_q)))",
        "    (set $status->{response_last_match}",
        "      (& $status->{response_last_match}",
        '         (== captured_rlast_i (== beat_index_q 3))))',
        '    (set beat_index_q (+ beat_index_q 1))',
        '    (set response_armed_q 0))',
        '',
        '  (rule finish_burst (& active_q response_armed_q r_done_i (== beat_index_q 3))',
        "    (set $status->{beat_done} 1)",
        "    (set $status->{response_beat_index}{name} beat_index_q)",
        "    (set $status->{response_id_match} (& $status->{response_id_match} (== captured_rid_i expected_arid_q)))",
        "    (set $status->{response_last_match} (& $status->{response_last_match} captured_rlast_i))",
        '    (set active_q 0)',
        '    (set response_armed_q 0)',
        "    (set $status->{busy} 0)",
        "    (set $status->{transaction_done} 1))",
        '',
        "  (rule clear_beat_done $status->{beat_done}",
        "    (set $status->{beat_done} 0))",
        '',
        "  (rule clear_transaction_done $status->{transaction_done}",
        "    (set $status->{transaction_done} 0))",
        '',
        '  (transaction aligned_boundary_command_check',
        '    (assert',
        "      (=> (& (! active_q) (! ar_busy_i) (! r_busy_i) $cmd->{start})",
        "          (& (! ${address}[0]) (! ${address}[1])",
        "             (! (& ${address}[11] ${address}[10] ${address}[9]",
        "                   ${address}[8] ${address}[7] ${address}[6]",
        "                   ${address}[5] ${address}[4]",
        "                   (| ${address}[3] ${address}[2])))))",
        '      "fixed-four AXI INCR read must be four-byte aligned and remain within 4 KiB"))',
        '',
        '  (transaction response_id_check',
        '    (assert',
        '      (=> (& active_q response_armed_q r_done_i)',
        '          (== captured_rid_i expected_arid_q))',
        '      "each accepted AXI RID must match the admitted ARID"))',
        '',
        '  (transaction response_last_check',
        '    (assert',
        '      (=> (& active_q response_armed_q r_done_i)',
        '          (== captured_rlast_i (== beat_index_q 3)))',
        '      "AXI RLAST must be low before and high on fixed-four beat index 3")))',
        '',
    );
}

sub _add_single_child(%args) {
    my $result = $args{result};
    my @fsm_names = sort keys %{$result->{generated_ial0}{files} || {}};
    confess "Error: AXI read burst4 transaction composition expected one generated child .fsm for '$args{object_name}'\n"
        unless @fsm_names == 1;

    push @{$args{ial1_items}}, {
        object_name   => $args{object_name},
        role          => $args{role},
        instance_name => $args{instance_name},
        format        => $result->{generated_ial1}{format},
        name          => $result->{generated_ial1}{name},
        text          => $result->{generated_ial1}{text},
    };
    for my $fsm_name (@fsm_names) {
        confess "Error: AXI read burst4 transaction composition generated duplicate .fsm artifact '$fsm_name'\n"
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
        axi_ar_driver.fsm
        axi_r_beat_acceptor.fsm
        axi_read_burst4_transaction_coordinator.fsm
    );
    for my $artifact (@child_artifacts) {
        confess "Error: AXI read burst4 transaction composition is missing generated child .fsm artifact '$artifact'\n"
            unless exists $fsm_files->{$artifact};
    }

    my @lines = (
        "(?top:$contract->{actor_name}",
        '  (?ports:public_io',
        (map { '    ' . _top_port_token($_) } _top_port_specs($contract)),
        '  )',
        '  (?fsmc:ar_driver axi_ar_driver)',
        '  (?fsmc:r_acceptor axi_r_beat_acceptor)',
        '  (?fsmc:transaction_coordinator axi_read_burst4_transaction_coordinator)',
        '  (?wiring:axi_read_burst4_transaction_wiring',
        (map { "    $_" } _wiring_lines()),
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
                axi_wiring => 'explicit_flat_fixed_four_beat_ar_r_transaction',
            },
        },
    };
}

sub _top_port_specs($contract) {
    my $cmd = $contract->{command};
    my $ar = $contract->{ar_channel};
    my $r = $contract->{r_channel};
    my $status = $contract->{status};

    return (
        { name => $contract->{clock}, direction => 'system', width => 1, system => 1 },
        { name => $contract->{reset}{signal}, direction => 'system', width => 1, system => 1 },
        _input_port($cmd->{start}, 1),
        _input_port($cmd->{address}{name}, $cmd->{address}{width}),
        _input_port($cmd->{id}{name}, $cmd->{id}{width}),
        _input_port($ar->{ready}, 1),
        _input_port($r->{valid}, 1),
        _input_port($r->{id}{name}, $r->{id}{width}),
        _input_port($r->{data}{name}, $r->{data}{width}),
        _input_port($r->{response}{name}, $r->{response}{width}),
        _input_port($r->{last}, 1),
        _output_port($ar->{valid}, 1),
        _output_port($ar->{address}{name}, $ar->{address}{width}),
        _output_port($ar->{id}{name}, $ar->{id}{width}),
        _output_port($ar->{length}{name}, $ar->{length}{width}),
        _output_port($ar->{size}{name}, $ar->{size}{width}),
        _output_port($ar->{burst}{name}, $ar->{burst}{width}),
        _output_port($r->{ready}, 1),
        _output_port($r->{captured_id}{name}, $r->{captured_id}{width}),
        _output_port($r->{captured_data}{name}, $r->{captured_data}{width}),
        _output_port($r->{captured_response}{name}, $r->{captured_response}{width}),
        _output_port($r->{captured_last}, 1),
        _output_port($status->{busy}, 1),
        _output_port($status->{request_done}, 1),
        _output_port($status->{beat_done}, 1),
        _output_port($status->{transaction_done}, 1),
        _output_port($status->{response_beat_index}{name}, $status->{response_beat_index}{width}),
        _output_port($status->{response_id_match}, 1),
        _output_port($status->{response_last_match}, 1),
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

sub _wiring_lines {
    return (
        '(ar_driver.ar_busy transaction_coordinator.ar_busy_i)',
        '(ar_driver.ar_done transaction_coordinator.ar_done_i)',
        '(transaction_coordinator.ar_cmd_valid_i ar_driver.ar_cmd_valid)',
        '(transaction_coordinator.ar_cmd_addr_i ar_driver.cmd_araddr)',
        '(transaction_coordinator.ar_cmd_id_i ar_driver.cmd_arid)',
        "(=8'd3 ar_driver.cmd_arlen)",
        "(=3'd2 ar_driver.cmd_arsize)",
        "(=2'b01 ar_driver.cmd_arburst)",
        '(transaction_coordinator.r_arm_i r_acceptor.r_accept_cmd_valid)',
        '(r_acceptor.r_busy transaction_coordinator.r_busy_i)',
        '(r_acceptor.r_beat_done transaction_coordinator.r_done_i)',
        '(r_acceptor.response_rid transaction_coordinator.captured_rid_i)',
        '(r_acceptor.response_rlast transaction_coordinator.captured_rlast_i)',
    );
}

sub _build_report(%args) {
    my $contract = $args{contract};
    my @ial1_items = @{$args{ial1_items}};
    my @ial0_items = @{$args{ial0_items}};
    my @schedule_reports = @{$args{schedule_reports}};
    my @fsm_files = sort keys %{$args{fsm_files}};

    return {
        schema => 'fsmgen.ial2.protocol_intent.axi_read_burst4_transaction_composition.v1',
        mode   => 'read-burst4-transaction-composition',
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
            object  => 'axi-read-burst4-transaction-composition',
            role    => $contract->{role},
        },
        composition => {
            name                 => $contract->{name},
            actor_name           => $contract->{actor_name},
            topology             => 'flat_fixed_four_beat_ar_r_transaction',
            child_instance_count => 3,
            net_count             => 48,
            resolved_link_count   => 46,
            children => [
                { role => 'ar-driver', instance_name => 'ar_driver', object_name => 'axi_ar_driver' },
                { role => 'r-acceptor', instance_name => 'r_acceptor', object_name => 'axi_r_beat_acceptor' },
                { role => 'transaction-coordinator', instance_name => 'transaction_coordinator', object_name => 'axi_read_burst4_transaction_coordinator' },
            ],
            wiring_policy => 'explicit_flat_fixed_four_beat_ar_r_transaction',
            fanout_policy  => 'captured_rid_and_rlast_single_source_public_and_coordinator',
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
            ar_channel => _clone_jsonish($contract->{ar_channel}),
            r_channel  => _clone_jsonish($contract->{r_channel}),
            status     => _clone_jsonish($contract->{status}),
        },
        fixed_burst_policy => {
            address_width           => 32,
            address_alignment_bytes => 4,
            span_bytes              => 16,
            four_kib_contained      => JSON::PP::true,
            id_width                => 4,
            data_width              => 32,
            arlen                   => 3,
            arsize                  => 2,
            arburst                 => 1,
            arburst_name            => 'INCR',
            beat_count              => 4,
            request_completion      => 'ar_request_accepted',
            beat_completion         => 'r_beat_accepted_and_captured',
            transaction_completion  => 'fourth_r_beat_accepted_and_captured',
        },
        ar_driver_reuse => {
            generator           => 'FSM::IAL2::ProtocolIntent::AxiArDriver',
            behavior_unchanged  => JSON::PP::true,
            retained_leaf_count => 1,
            retained_leaf       => 'axi_ar_driver',
            fixed_metadata      => { arlen => 3, arsize => 2, arburst => 1, arburst_name => 'INCR' },
        },
        r_acceptor_reuse => {
            generator           => 'FSM::IAL2::ProtocolIntent::AxiRBeatAcceptor',
            behavior_unchanged  => JSON::PP::true,
            retained_leaf_count => 1,
            retained_leaf       => 'axi_r_beat_acceptor',
            arm_binding         => 'r_accept_cmd_valid',
            capture_policy      => 'raw_rid_rdata_rresp_rlast',
        },
        transaction_coordinator => {
            actor_name              => 'axi_read_burst4_transaction_coordinator',
            admission_policy        => 'idle_level_sampled',
            queue_depth             => 0,
            payload_capture         => 'atomic_on_admission',
            legality_guard          => 'four_byte_aligned_16_byte_span_within_one_4kib_region',
            r_arm_policy            => 'first_after_ar_completion_then_once_after_each_nonfinal_beat',
            beat_index_width        => 2,
            expected_beat_count     => 4,
            busy_policy             => 'admission_through_fourth_r_beat_retirement',
            request_done_policy     => 'one_pulse_when_ar_completion_arms_first_r_beat',
            beat_done_policy        => 'one_pulse_after_each_raw_r_beat_capture',
            transaction_done_policy => 'one_pulse_with_fourth_beat_retirement',
            response_id_policy      => 'sticky_all_captured_rid_match_retained_admitted_arid',
            response_last_policy    => 'sticky_rlast_low_on_indices_0_to_2_and_high_on_index_3',
            mismatch_policy         => 'assert_and_drain_to_authoritative_fourth_accepted_beat',
            response_status_policy  => 'raw_per_beat_rresp_not_success_and_not_aggregated',
        },
        children => [
            _single_child_report('ar-driver', 'ar_driver', $args{ar_result}),
            _single_child_report('r-acceptor', 'r_acceptor', $args{r_result}),
            _single_child_report('transaction-coordinator', 'transaction_coordinator', $args{coordinator_result}),
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
}

sub _single_child_report($role, $instance_name, $result) {
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
        'profile must be axi4, object must be axi-read-burst4-transaction-composition, and role must be manager',
        'clock and asynchronous active-low reset are shared by all three generated children',
        'one idle admission atomically captures address width 32 and ID width 4',
        'admission requires four-byte alignment and the complete 16-byte span to remain within one 4-KiB region',
        'AR metadata is fixed to ARLEN 3, ARSIZE 2, and ARBURST INCR for four four-byte beats',
        'flat C4 topology reuses unchanged generated AR driver and one explicitly re-armed R beat acceptor plus one transaction coordinator',
        'R is first armed only after the owned AR request accepts',
        'the unchanged R beat acceptor is re-armed once for each of four expected beats',
        'one outstanding ownership interval rejects busy commands and provides no queue',
        'request, beat, and transaction completion are distinct one-cycle events',
        'response beat index 0 through 3 identifies the raw captured tuple during each beat event',
        'RID match and the expected count/RLAST sequence match are sticky across all four beats',
        'RID mismatch, early RLAST, missing final RLAST, and non-OKAY RRESP drain or retire at the authoritative fourth accepted beat',
        'RRESP remains raw per beat and is not interpreted as success or aggregated',
        'lowering is IAL2 through three generated IAL1 and three generated leaf IAL0 actors into one structural IAL0 top, never direct IAL2-to-IAL0',
    ];
}

sub _unsupported_residue {
    return [
        { id => 'axi_read_burst4_transaction_composition_dynamic_burst_deferred', detail => 'Authored or dynamic ARLEN, variable beat counts, variable ARSIZE, FIXED/WRAP bursts, and general burst progression remain future work.' },
        { id => 'axi_read_burst4_transaction_composition_narrow_unaligned_wrap_attributes_deferred', detail => 'Narrow, unaligned, or wrapping transfers and extended AR attributes remain future work.' },
        { id => 'axi_read_burst4_transaction_composition_multi_beat_write_deferred', detail => 'Multi-beat WDATA/WSTRB supply, WLAST sequencing, and write transaction composition remain future work.' },
        { id => 'axi_read_burst4_transaction_composition_response_aggregation_output_banks_deferred', detail => 'Sticky or worst RRESP aggregation, result mapping, error-RDATA usability policy, and four-entry output banks remain future work.' },
        { id => 'axi_read_burst4_transaction_composition_capacity_core_integration_deferred', detail => 'Capacity/status submit/completion, ID authority, read-data storage, and response-demux integration remain future work.' },
        { id => 'axi_read_burst4_transaction_composition_outstanding_queueing_deferred', detail => 'Adjacent back-to-back admission, multiple outstanding reads, buffering, and queues remain future work.' },
        { id => 'axi_read_burst4_transaction_composition_id_allocation_ordering_demux_deferred', detail => 'Dynamic ID allocation/reuse, same-ID ordering, RID demux, and read-data interleaving remain future work.' },
        { id => 'axi_read_burst4_transaction_composition_malformed_subordinate_recovery_deferred', detail => 'Timeout, abort, retry, or resynchronization when a malformed subordinate stops before the ARLEN-selected count remain future work.' },
        { id => 'axi_read_burst4_transaction_composition_extended_r_monitoring_deferred', detail => 'Extended Issue L R sidebands and generated subordinate stall/payload-stability monitoring remain future work.' },
        { id => 'axi_read_burst4_transaction_composition_transaction_interface_deferred', detail => 'Decision 0020 protocol-neutral transaction interfaces remain director-gated future work.' },
        { id => 'axi_read_burst4_transaction_composition_profile_alias_deferred', detail => '.axi profile-alias surfacing remains unsupported; this source uses generic .ppif only.' },
        { id => 'axi_read_burst4_transaction_composition_verification_output_deferred', detail => 'Direct verification-output generation from this IAL2 source remains future work.' },
        { id => 'axi_read_burst4_transaction_composition_backend_variants_deferred', detail => 'Direct backend lowering, backend-language variants, and VHDL behavior remain future work.' },
        { id => 'axi_read_burst4_transaction_composition_other_protocols_unchanged', detail => 'AHB and APB behavior remain unchanged.' },
    ];
}

sub _required_scalar($raw, $field) {
    confess "AXI read burst4 transaction composition IAL2 contract is missing required scalar field '$field'\n"
        unless exists($raw->{$field}) && !ref($raw->{$field});
    return _nonempty_scalar($raw->{$field}, $field);
}

sub _required_hash($raw, $field) {
    confess "AXI read burst4 transaction composition IAL2 contract field '$field' must be a hash reference\n"
        unless ref($raw->{$field}) eq 'HASH';
    return $raw->{$field};
}

sub _required_identifier($raw, $field) {
    return _identifier_value(_required_scalar($raw, $field), $field);
}

sub _required_identifier_field($raw, $field, $label) {
    confess "AXI read burst4 transaction composition IAL2 contract is missing required field '$label'\n"
        unless exists($raw->{$field}) && !ref($raw->{$field});
    return _identifier_value($raw->{$field}, $label);
}

sub _normalize_width_binding($raw, $field, $expected_width) {
    confess "AXI read burst4 transaction composition IAL2 contract field '$field' must be a hash reference\n"
        unless ref($raw) eq 'HASH';
    my $name = _required_identifier_field($raw, 'name', "$field.name");
    my $width = _positive_integer($raw->{width}, "$field.width");
    confess "AXI read burst4 transaction composition IAL2 contract $field.width must be $expected_width in this slice\n"
        unless $width == $expected_width;
    return { name => $name, width => $width };
}

sub _normalize_reset($raw_reset) {
    confess "AXI read burst4 transaction composition IAL2 contract is missing required reset binding\n"
        unless ref($raw_reset) eq 'HASH';
    my $signal = _identifier_value($raw_reset->{signal}, 'reset.signal');
    my $async = _bool_value($raw_reset->{async}, 'reset.async');
    my $active_low = _bool_value($raw_reset->{active_low}, 'reset.active_low');
    return {
        signal          => $signal,
        async           => $async,
        active_low      => $active_low,
        polarity_source => $raw_reset->{polarity_source} // 'explicit',
    };
}

sub _normalize_source_anchors($anchors) {
    confess "AXI read burst4 transaction composition IAL2 contract source.anchors must be an array reference\n"
        unless ref($anchors) eq 'ARRAY';
    my @normalized;
    for my $index (0 .. $#$anchors) {
        my $anchor = $anchors->[$index];
        confess "AXI read burst4 transaction composition IAL2 contract source.anchors[$index] must be a hash reference\n"
            unless ref($anchor) eq 'HASH';
        for my $required (qw(document section page)) {
            confess "AXI read burst4 transaction composition IAL2 contract source.anchors[$index] is missing '$required'\n"
                unless exists($anchor->{$required}) && !ref($anchor->{$required})
                    && length($anchor->{$required});
        }
        push @normalized, {
            document => "$anchor->{document}",
            section  => "$anchor->{section}",
            page     => "$anchor->{page}",
        };
    }
    return \@normalized;
}

sub _binding_names(@values) {
    my @names;
    for my $value (@values) {
        if (ref($value) eq 'HASH') {
            for my $key (sort keys %$value) {
                my $item = $value->{$key};
                push @names, ref($item) eq 'HASH' ? $item->{name} : $item;
            }
        }
        elsif (defined $value) {
            push @names, $value;
        }
    }
    return @names;
}

sub _reject_duplicate_signal_names(@names) {
    my %seen;
    for my $name (@names) {
        next unless defined($name) && length($name);
        confess "AXI read burst4 transaction composition IAL2 contract duplicates signal '$name'\n"
            if $seen{$name}++;
    }
}

sub _nonempty_scalar($value, $field) {
    confess "AXI read burst4 transaction composition IAL2 contract field '$field' must be a non-empty scalar\n"
        unless defined($value) && !ref($value) && length($value);
    return "$value";
}

sub _identifier_value($value, $field) {
    my $identifier = _nonempty_scalar($value, $field);
    confess "AXI read burst4 transaction composition IAL2 contract field '$field' must be an ISF identifier\n"
        unless $identifier =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
    return $identifier;
}

sub _positive_integer($value, $field) {
    confess "AXI read burst4 transaction composition IAL2 contract field '$field' must be a positive integer\n"
        unless defined($value) && !ref($value) && "$value" =~ /\A[0-9]+\z/ && $value > 0;
    return 0 + $value;
}

sub _bool_value($value, $field) {
    confess "AXI read burst4 transaction composition IAL2 contract field '$field' must be boolean 0 or 1\n"
        unless defined($value) && !ref($value) && ("$value" eq '0' || "$value" eq '1');
    return $value ? 1 : 0;
}

sub _interface_line($direction, $binding) {
    if (ref($binding) eq 'HASH') {
        return "    ($direction $binding->{name} (width $binding->{width}))";
    }
    return "    ($direction $binding)";
}

sub _reset_clause($reset) {
    my $kind = $reset->{async} ? 'async' : 'sync';
    my $polarity = $reset->{active_low} ? 'active_low' : 'active_high';
    return "(reset ($reset->{signal} $kind $polarity))";
}

sub _clone_jsonish($value) {
    return $value unless ref($value);
    return [map { _clone_jsonish($_) } @$value] if ref($value) eq 'ARRAY';
    if (ref($value) eq 'HASH') {
        return { map { $_ => _clone_jsonish($value->{$_}) } keys %$value };
    }
    return $value;
}

1;
