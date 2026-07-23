package FSM::IAL2::ProtocolIntent::AxiWriteTransactionComposition;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use JSON::PP ();
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings qw(experimental::signatures experimental::postderef);

use FSM::Adapter::ISF;
use FSM::IAL2::ProtocolIntent::AxiBResponseAcceptor;
use FSM::IAL2::ProtocolIntent::AxiWriteRequestComposition;
use FSM::Scheduler::ISF;

my @COMMAND_WIDTH_FIELDS = (
    [address => 32],
    [id      => 4],
    [data    => 32],
    [strobe  => 4],
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

my @B_WIDTH_FIELDS = (
    [id                => 4],
    [response          => 2],
    [captured_id       => 4],
    [captured_response => 2],
);

my @PRIVATE_SIGNAL_NAMES = qw(
    request_cmd_valid_i request_awaddr_i request_awid_i
    request_wdata_i request_wstrb_i request_busy_i request_done_i
    b_arm_i b_busy_i b_done_i captured_bid_i
    active_q response_armed_q expected_awid_q
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
    confess "FSM::IAL2::ProtocolIntent::AxiWriteTransactionComposition->generate expects exactly one contract hash reference\n"
        unless @args == 1 && ref($args[0]) eq 'HASH';

    my $contract = _normalize_contract($args[0]);
    my $request_result = FSM::IAL2::ProtocolIntent::AxiWriteRequestComposition
        ->new(debug => $self->{debug})
        ->generate(_request_composition_contract($contract));
    my $b_result = FSM::IAL2::ProtocolIntent::AxiBResponseAcceptor
        ->new(debug => $self->{debug})
        ->generate(_b_acceptor_contract($contract));
    my $coordinator_result = _generate_transaction_coordinator($self, $contract);

    my (@ial1_items, @ial0_items, @schedule_reports);
    my %fsm_files;
    _add_request_children(
        result           => $request_result,
        ial1_items       => \@ial1_items,
        ial0_items       => \@ial0_items,
        schedule_reports => \@schedule_reports,
        fsm_files        => \%fsm_files,
    );
    _add_single_child(
        result           => $b_result,
        object_name      => 'axi_b_response_acceptor',
        role             => 'b-acceptor',
        instance_name    => 'b_acceptor',
        ial1_items       => \@ial1_items,
        ial0_items       => \@ial0_items,
        schedule_reports => \@schedule_reports,
        fsm_files        => \%fsm_files,
    );
    _add_single_child(
        result           => $coordinator_result,
        object_name      => 'axi_write_transaction_coordinator',
        role             => 'transaction-coordinator',
        instance_name    => 'transaction_coordinator',
        ial1_items       => \@ial1_items,
        ial0_items       => \@ial0_items,
        schedule_reports => \@schedule_reports,
        fsm_files        => \%fsm_files,
    );

    confess "Error: AXI write transaction composition expected five generated IAL1 children\n"
        unless @ial1_items == 5;
    confess "Error: AXI write transaction composition expected five generated schedule reports\n"
        unless @schedule_reports == 5;
    confess "Error: AXI write transaction composition expected five generated leaf .fsm artifacts\n"
        unless keys(%fsm_files) == 5;

    my $top = _build_structural_top($contract, \%fsm_files);
    confess "Error: AXI write transaction composition generated duplicate .fsm artifact '$top->{entry_artifact}'\n"
        if exists $fsm_files{$top->{entry_artifact}};
    $fsm_files{$top->{entry_artifact}} = $top->{text};
    push @ial0_items, $top->{ial0_item};

    confess "Error: AXI write transaction composition expected six generated IAL0 artifacts\n"
        unless @ial0_items == 6 && keys(%fsm_files) == 6;

    my $report = _build_report(
        contract           => $contract,
        request_result     => $request_result,
        b_result           => $b_result,
        coordinator_result => $coordinator_result,
        ial1_items         => \@ial1_items,
        ial0_items         => \@ial0_items,
        schedule_reports   => \@schedule_reports,
        fsm_files          => \%fsm_files,
        hdl_entry          => $top->{report_entry},
    );

    return {
        layer => 'IAL2',
        kind  => 'protocol_intent.axi_write_transaction_composition',
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
    confess "FSM::IAL2::ProtocolIntent::AxiWriteTransactionComposition->new must be called with the FSM::IAL2::ProtocolIntent::AxiWriteTransactionComposition class invocant\n"
        unless defined($class) && !ref($class)
            && $class eq 'FSM::IAL2::ProtocolIntent::AxiWriteTransactionComposition';
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
    confess "FSM::IAL2::ProtocolIntent::AxiWriteTransactionComposition->$method must be called on an FSM::IAL2::ProtocolIntent::AxiWriteTransactionComposition object\n"
        unless blessed($self)
            && $self->isa('FSM::IAL2::ProtocolIntent::AxiWriteTransactionComposition');
}

sub _normalize_contract($raw) {
    my $kind = _required_scalar($raw, 'kind');
    confess "AXI write transaction composition IAL2 contract kind must be axi_write_transaction_composition\n"
        unless $kind eq 'axi_write_transaction_composition';

    my $protocol = lc _required_scalar($raw, 'protocol');
    confess "AXI write transaction composition IAL2 contract profile must be axi4 in this slice\n"
        unless $protocol eq 'axi4';

    my $name = _required_identifier($raw, 'name');
    my $actor_name = exists($raw->{actor_name})
        ? _identifier_value($raw->{actor_name}, 'actor_name')
        : $name;
    my $role = lc _required_scalar($raw, 'role');
    confess "AXI write transaction composition IAL2 contract role must be manager\n"
        unless $role eq 'manager';

    my $clock = _required_identifier($raw, 'clock');
    my $reset = _normalize_reset($raw->{reset});
    confess "AXI write transaction composition reset must be asynchronous active-low in this slice\n"
        unless $reset->{async} && $reset->{active_low};

    my $command = _normalize_command(_required_hash($raw, 'command'));
    my $aw_channel = _normalize_aw_channel(_required_hash($raw, 'aw_channel'));
    my $w_channel = _normalize_w_channel(_required_hash($raw, 'w_channel'));
    my $b_channel = _normalize_b_channel(_required_hash($raw, 'b_channel'));
    my $status = _normalize_status(_required_hash($raw, 'status'));

    _reject_duplicate_signal_names(
        $clock,
        $reset->{signal},
        _binding_names($command),
        _binding_names($aw_channel),
        _binding_names($w_channel),
        _binding_names($b_channel),
        _binding_names($status),
        @PRIVATE_SIGNAL_NAMES,
        qw(
            aw_busy aw_done w_busy w_done
            aw_cmd_valid aw_cmd_awaddr aw_cmd_awid
            w_cmd_valid w_cmd_wdata w_cmd_wstrb
            aw_driver w_driver request_coordinator
            b_acceptor transaction_coordinator
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
        b_channel        => $b_channel,
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

sub _normalize_b_channel($raw) {
    my %channel = (
        valid => _required_identifier_field($raw, 'valid', 'b_channel.valid'),
        ready => _required_identifier_field($raw, 'ready', 'b_channel.ready'),
    );
    for my $field (@B_WIDTH_FIELDS) {
        my ($key, $width) = @$field;
        $channel{$key} = _normalize_width_binding($raw->{$key}, "b_channel.$key", $width);
    }
    return \%channel;
}

sub _normalize_status($raw) {
    return {
        busy              => _required_identifier_field($raw, 'busy', 'status.busy'),
        request_done      => _required_identifier_field($raw, 'request_done', 'status.request_done'),
        transaction_done  => _required_identifier_field($raw, 'transaction_done', 'status.transaction_done'),
        response_id_match => _required_identifier_field($raw, 'response_id_match', 'status.response_id_match'),
    };
}

sub _request_composition_contract($contract) {
    return {
        kind       => 'axi_write_request_composition',
        protocol   => 'axi4',
        name       => 'axi_write_request_private',
        actor_name => 'axi_write_request_private',
        role       => 'manager-to-subordinate',
        clock      => $contract->{clock},
        reset      => _clone_jsonish($contract->{reset}),
        command => {
            start   => 'request_cmd_valid_i',
            address => { name => 'request_awaddr_i', width => 32 },
            id      => { name => 'request_awid_i', width => 4 },
            data    => { name => 'request_wdata_i', width => 32 },
            strobe  => { name => 'request_wstrb_i', width => 4 },
        },
        aw_channel => _clone_jsonish($contract->{aw_channel}),
        w_channel  => _clone_jsonish($contract->{w_channel}),
        status => {
            busy => 'request_busy_i',
            done => 'request_done_i',
        },
        intent_name      => 'axi_write_request_private',
        source_object_id => 'axi-write-request-composition',
        source            => { anchors => _request_source_anchors($contract) },
    };
}

sub _b_acceptor_contract($contract) {
    my $b = $contract->{b_channel};
    return {
        kind       => 'axi_b_response_acceptor',
        protocol   => 'axi4',
        name       => 'axi_b_response_acceptor',
        actor_name => 'axi_b_response_acceptor',
        role       => 'subordinate-to-manager',
        clock      => $contract->{clock},
        reset      => _clone_jsonish($contract->{reset}),
        command => {
            arm => 'b_arm_i',
        },
        channel => {
            valid             => $b->{valid},
            ready             => $b->{ready},
            id                => _clone_jsonish($b->{id}),
            response          => _clone_jsonish($b->{response}),
            captured_id       => _clone_jsonish($b->{captured_id}),
            captured_response => _clone_jsonish($b->{captured_response}),
            busy              => 'b_busy_i',
            done              => 'b_done_i',
        },
        intent_name      => $contract->{intent_name},
        source_object_id => 'axi-b-response-acceptor',
        source            => { anchors => _b_source_anchors($contract) },
    };
}

sub _request_source_anchors($contract) {
    return [] unless @{$contract->{source_anchors}} >= 6;
    return [map { _clone_jsonish($_) } @{$contract->{source_anchors}}[0 .. 5]];
}

sub _b_source_anchors($contract) {
    return [] unless @{$contract->{source_anchors}} >= 9;
    return [map { _clone_jsonish($_) } @{$contract->{source_anchors}}[1, 2, 3, 6, 7, 8]];
}

sub _generate_transaction_coordinator($self, $contract) {
    my $isf_name = 'axi_write_transaction_coordinator.isf';
    my $isf_text = _transaction_coordinator_isf($contract);
    my $adapter = FSM::Adapter::ISF->new(debug => $self->{debug});
    my $actor = $adapter->parse_source($isf_text, $isf_name);
    my $scheduler = FSM::Scheduler::ISF->new(debug => $self->{debug});
    my $lowered = $scheduler->lower($actor);
    my $schedule_report = JSON::PP->new->decode($scheduler->report($actor));

    return {
        layer => 'IAL1',
        kind  => 'protocol_intent.axi_write_transaction_coordinator',
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
            schema => 'fsmgen.ial2.protocol_intent.axi_write_transaction_coordinator.v1',
            mode   => 'coordinator',
            generated_artifacts => {
                ial1 => { name => $isf_name, format => 'isf' },
                ial0 => { files => [sort keys %{$lowered->{files} || {}}], format => 'fsm' },
                hdl_entry => {
                    selected       => JSON::PP::false,
                    kind           => 'generated_coordinator_fsm',
                    module         => 'axi_write_transaction_coordinator',
                    entry_artifact => 'axi_write_transaction_coordinator.fsm',
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
        '(actor axi_write_transaction_coordinator',
        "  (clock $contract->{clock})",
        "  $reset",
        '  (interface',
        _interface_line('input', $cmd->{start}),
        _interface_line('input', $cmd->{address}),
        _interface_line('input', $cmd->{id}),
        _interface_line('input', $cmd->{data}),
        _interface_line('input', $cmd->{strobe}),
        '    (input request_busy_i)',
        '    (input request_done_i)',
        '    (input b_busy_i)',
        '    (input b_done_i)',
        '    (input captured_bid_i (width 4))',
        '    (output request_cmd_valid_i)',
        '    (output request_awaddr_i (width 32))',
        '    (output request_awid_i (width 4))',
        '    (output request_wdata_i (width 32))',
        '    (output request_wstrb_i (width 4))',
        '    (output b_arm_i)',
        _interface_line('output', $status->{busy}),
        _interface_line('output', $status->{request_done}),
        _interface_line('output', $status->{transaction_done}),
        _interface_line('output', $status->{response_id_match}) . ')',
        '',
        '  (priority finish_response over admit)',
        '  (priority finish_response over arm_response)',
        '  (priority finish_response over clear_transaction_done)',
        '  (priority arm_response over clear_b_arm)',
        '  (priority arm_response over clear_request_done)',
        '  (priority admit over clear_request_start)',
        '',
        "  (rule admit (& (! active_q) (! request_busy_i) (! b_busy_i) $cmd->{start} (! ${address}[0]) (! ${address}[1]))",
        '    (set active_q 1)',
        '    (set request_cmd_valid_i 1)',
        "    (set request_awaddr_i $cmd->{address}{name})",
        "    (set request_awid_i $cmd->{id}{name})",
        "    (set request_wdata_i $cmd->{data}{name})",
        "    (set request_wstrb_i $cmd->{strobe}{name})",
        "    (set expected_awid_q $cmd->{id}{name})",
        "    (set $status->{busy} 1))",
        '',
        '  (rule clear_request_start request_cmd_valid_i',
        '    (set request_cmd_valid_i 0))',
        '',
        '  (rule arm_response (& active_q (! response_armed_q) request_done_i (! b_busy_i))',
        '    (set response_armed_q 1)',
        '    (set b_arm_i 1)',
        "    (set $status->{request_done} 1))",
        '',
        '  (rule clear_b_arm b_arm_i',
        '    (set b_arm_i 0))',
        '',
        "  (rule clear_request_done $status->{request_done}",
        "    (set $status->{request_done} 0))",
        '',
        '  (rule finish_response (& active_q response_armed_q b_done_i)',
        '    (set active_q 0)',
        '    (set response_armed_q 0)',
        "    (set $status->{busy} 0)",
        "    (set $status->{transaction_done} 1)",
        "    (set $status->{response_id_match} (== captured_bid_i expected_awid_q)))",
        '',
        "  (rule clear_transaction_done $status->{transaction_done}",
        "    (set $status->{transaction_done} 0))",
        '',
        '  (transaction aligned_command_check',
        '    (assert',
        "      (=> (& (! active_q) (! request_busy_i) (! b_busy_i) $cmd->{start})",
        "          (& (! ${address}[0]) (! ${address}[1])))",
        '      "single-beat AXI write transaction address must be four-byte aligned"))',
        '',
        '  (transaction response_id_check',
        '    (assert',
        '      (=> (& active_q response_armed_q b_done_i)',
        '          (== captured_bid_i expected_awid_q))',
        '      "accepted AXI BID must match admitted AWID")))',
        '',
    );
}

sub _add_request_children(%args) {
    my $result = $args{result};
    my @expected_ial1 = qw(
        axi_aw_driver.isf
        axi_w_driver.isf
        axi_write_request_coordinator.isf
    );
    my @expected_fsm = qw(
        axi_aw_driver.fsm
        axi_w_driver.fsm
        axi_write_request_coordinator.fsm
    );
    my $nested_top = 'axi_write_request_private.fsm';

    my @ial1 = @{$result->{generated_ial1}{items} || []};
    confess "Error: AXI write transaction composition is missing generated request child IAL1 items\n"
        unless @ial1 == 3;
    confess "Error: AXI write transaction composition generated unexpected request child IAL1 artifacts\n"
        unless join("\0", map { $_->{name} // '' } @ial1) eq join("\0", @expected_ial1);
    for my $item (@ial1) {
        my $copy = _clone_jsonish($item);
        if (($copy->{object_name} // '') eq 'axi_write_request_coordinator') {
            $copy->{role} = 'request-coordinator';
            $copy->{instance_name} = 'request_coordinator';
        }
        push @{$args{ial1_items}}, $copy;
    }

    my @schedule = @{$result->{generated_ial1_schedule_reports} || []};
    confess "Error: AXI write transaction composition is missing generated request child schedules\n"
        unless @schedule == 3;
    for my $item (@schedule) {
        my $copy = _clone_jsonish($item);
        if (($copy->{object_name} // '') eq 'axi_write_request_coordinator') {
            $copy->{role} = 'request-coordinator';
            $copy->{instance_name} = 'request_coordinator';
        }
        push @{$args{schedule_reports}}, $copy;
    }

    my $files = $result->{generated_ial0}{files} || {};
    confess "Error: AXI write transaction composition is missing generated request child nested top '$nested_top'\n"
        unless exists $files->{$nested_top};
    for my $artifact (@expected_fsm) {
        confess "Error: AXI write transaction composition is missing generated request child '$artifact'\n"
            unless exists $files->{$artifact};
        confess "Error: AXI write transaction composition generated duplicate .fsm artifact '$artifact'\n"
            if exists $args{fsm_files}{$artifact};
        $args{fsm_files}{$artifact} = $files->{$artifact};
    }

    my @ial0 = grep { ($_->{kind} // '') eq 'generated_endpoint' }
        @{$result->{generated_ial0}{items} || []};
    confess "Error: AXI write transaction composition expected three generated request child IAL0 endpoints\n"
        unless @ial0 == 3;
    for my $item (@ial0) {
        my $copy = _clone_jsonish($item);
        if (($copy->{object_name} // '') eq 'axi_write_request_coordinator') {
            $copy->{role} = 'request-coordinator';
            $copy->{instance_name} = 'request_coordinator';
        }
        push @{$args{ial0_items}}, $copy;
    }
    confess "Error: AXI write transaction composition must not retain nested request composition top '$nested_top'\n"
        if exists $args{fsm_files}{$nested_top};
}

sub _add_single_child(%args) {
    my $result = $args{result};
    my @fsm_names = sort keys %{$result->{generated_ial0}{files} || {}};
    confess "Error: AXI write transaction composition expected one generated child .fsm for '$args{object_name}'\n"
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
        confess "Error: AXI write transaction composition generated duplicate .fsm artifact '$fsm_name'\n"
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
        axi_w_driver.fsm
        axi_write_request_coordinator.fsm
        axi_b_response_acceptor.fsm
        axi_write_transaction_coordinator.fsm
    );
    for my $artifact (@child_artifacts) {
        confess "Error: AXI write transaction composition is missing generated child .fsm artifact '$artifact'\n"
            unless exists $fsm_files->{$artifact};
    }

    my @lines = (
        "(?top:$contract->{actor_name}",
        '  (?ports:public_io',
        (map { '    ' . _top_port_token($_) } _top_port_specs($contract)),
        '  )',
        '  (?fsmc:aw_driver axi_aw_driver)',
        '  (?fsmc:w_driver axi_w_driver)',
        '  (?fsmc:request_coordinator axi_write_request_coordinator)',
        '  (?fsmc:b_acceptor axi_b_response_acceptor)',
        '  (?fsmc:transaction_coordinator axi_write_transaction_coordinator)',
        '  (?wiring:axi_write_transaction_wiring',
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
                axi_wiring => 'explicit_flat_single_beat_aw_w_b_transaction',
            },
        },
    };
}

sub _top_port_specs($contract) {
    my $cmd = $contract->{command};
    my $aw = $contract->{aw_channel};
    my $w = $contract->{w_channel};
    my $b = $contract->{b_channel};
    my $status = $contract->{status};

    return (
        { name => $contract->{clock}, direction => 'system', width => 1, system => 1 },
        { name => $contract->{reset}{signal}, direction => 'system', width => 1, system => 1 },
        _input_port($cmd->{start}, 1),
        _input_port($cmd->{address}{name}, $cmd->{address}{width}),
        _input_port($cmd->{id}{name}, $cmd->{id}{width}),
        _input_port($cmd->{data}{name}, $cmd->{data}{width}),
        _input_port($cmd->{strobe}{name}, $cmd->{strobe}{width}),
        _input_port($aw->{ready}, 1),
        _input_port($w->{ready}, 1),
        _input_port($b->{valid}, 1),
        _input_port($b->{id}{name}, $b->{id}{width}),
        _input_port($b->{response}{name}, $b->{response}{width}),
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
        _output_port($b->{ready}, 1),
        _output_port($b->{captured_id}{name}, $b->{captured_id}{width}),
        _output_port($b->{captured_response}{name}, $b->{captured_response}{width}),
        _output_port($status->{busy}, 1),
        _output_port($status->{request_done}, 1),
        _output_port($status->{transaction_done}, 1),
        _output_port($status->{response_id_match}, 1),
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
        '(aw_driver.aw_busy request_coordinator.aw_busy)',
        '(aw_driver.aw_done request_coordinator.aw_done)',
        '(w_driver.w_busy request_coordinator.w_busy)',
        '(w_driver.w_done request_coordinator.w_done)',
        '(request_coordinator.aw_cmd_valid aw_driver.aw_cmd_valid)',
        '(request_coordinator.aw_cmd_awaddr aw_driver.aw_cmd_awaddr)',
        '(request_coordinator.aw_cmd_awid aw_driver.aw_cmd_awid)',
        "(=8'd0 aw_driver.cmd_awlen)",
        "(=3'd2 aw_driver.cmd_awsize)",
        "(=2'b01 aw_driver.cmd_awburst)",
        '(request_coordinator.w_cmd_valid w_driver.w_cmd_valid)',
        '(request_coordinator.w_cmd_wdata w_driver.w_cmd_wdata)',
        '(request_coordinator.w_cmd_wstrb w_driver.w_cmd_wstrb)',
        '(transaction_coordinator.request_cmd_valid_i request_coordinator.request_cmd_valid_i)',
        '(transaction_coordinator.request_awaddr_i request_coordinator.request_awaddr_i)',
        '(transaction_coordinator.request_awid_i request_coordinator.request_awid_i)',
        '(transaction_coordinator.request_wdata_i request_coordinator.request_wdata_i)',
        '(transaction_coordinator.request_wstrb_i request_coordinator.request_wstrb_i)',
        '(request_coordinator.request_busy_i transaction_coordinator.request_busy_i)',
        '(request_coordinator.request_done_i transaction_coordinator.request_done_i)',
        '(transaction_coordinator.b_arm_i b_acceptor.b_arm_i)',
        '(b_acceptor.b_busy_i transaction_coordinator.b_busy_i)',
        '(b_acceptor.b_done_i transaction_coordinator.b_done_i)',
        '(b_acceptor.response_bid transaction_coordinator.captured_bid_i)',
    );
}

sub _build_report(%args) {
    my $contract = $args{contract};
    my @ial1_items = @{$args{ial1_items}};
    my @ial0_items = @{$args{ial0_items}};
    my @schedule_reports = @{$args{schedule_reports}};
    my @fsm_files = sort keys %{$args{fsm_files}};

    return {
        schema => 'fsmgen.ial2.protocol_intent.axi_write_transaction_composition.v1',
        mode   => 'write-transaction-composition',
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
            object  => 'axi-write-transaction-composition',
            role    => $contract->{role},
        },
        composition => {
            name                 => $contract->{name},
            actor_name           => $contract->{actor_name},
            topology             => 'flat_single_beat_aw_w_b_transaction',
            child_instance_count => 5,
            children => [
                { role => 'aw-driver', instance_name => 'aw_driver', object_name => 'axi_aw_driver' },
                { role => 'w-driver', instance_name => 'w_driver', object_name => 'axi_w_driver' },
                { role => 'request-coordinator', instance_name => 'request_coordinator', object_name => 'axi_write_request_coordinator' },
                { role => 'b-acceptor', instance_name => 'b_acceptor', object_name => 'axi_b_response_acceptor' },
                { role => 'transaction-coordinator', instance_name => 'transaction_coordinator', object_name => 'axi_write_transaction_coordinator' },
            ],
            wiring_policy => 'explicit_flat_single_beat_aw_w_b_transaction',
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
            b_channel  => _clone_jsonish($contract->{b_channel}),
            status     => _clone_jsonish($contract->{status}),
        },
        single_beat_policy => {
            address_width           => 32,
            address_alignment_bytes => 4,
            id_width                => 4,
            data_width              => 32,
            strobe_width            => 4,
            all_zero_strobe_allowed => JSON::PP::true,
            awlen                   => 0,
            awsize                  => 2,
            awburst                 => 1,
            awburst_name            => 'INCR',
            wlast                   => 1,
            beat_count              => 1,
            request_completion      => 'both_aw_and_w_accepted',
            response_completion     => 'b_response_accepted_and_captured',
        },
        request_composition_reuse => {
            generator             => 'FSM::IAL2::ProtocolIntent::AxiWriteRequestComposition',
            nested_top_selected   => JSON::PP::false,
            omitted_top_artifact  => 'axi_write_request_private.fsm',
            retained_leaf_count   => 3,
            retained_leaf_objects => [qw(axi_aw_driver axi_w_driver axi_write_request_coordinator)],
            private_bindings      => {
                command => [qw(request_cmd_valid_i request_awaddr_i request_awid_i request_wdata_i request_wstrb_i)],
                status  => [qw(request_busy_i request_done_i)],
            },
        },
        transaction_coordinator => {
            actor_name              => 'axi_write_transaction_coordinator',
            admission_policy        => 'idle_level_sampled',
            queue_depth             => 0,
            payload_capture         => 'atomic_on_admission',
            alignment_guard         => $contract->{command}{address}{name} . "[1:0] == 2'b00",
            b_arm_policy            => 'arm_after_request_completion',
            busy_policy             => 'admission_through_b_response_retirement',
            request_done_policy     => 'one_pulse_when_request_completion_arms_b',
            transaction_done_policy => 'one_pulse_after_b_response_retirement',
            response_id_policy      => 'captured_bid_matches_retained_admitted_awid',
            mismatch_policy         => 'terminal_completion_with_match_zero_and_assertion',
            response_status_policy  => 'raw_bresp_capture_not_success_interpretation',
        },
        children => [
            _request_child_report('aw-driver', 'aw_driver', $args{request_result}),
            _request_child_report('w-driver', 'w_driver', $args{request_result}),
            _request_child_report('coordinator', 'request_coordinator', $args{request_result}),
            _single_child_report('b-acceptor', 'b_acceptor', $args{b_result}),
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

sub _request_child_report($role, $instance_name, $request_result) {
    my ($child) = grep { ($_->{role} // '') eq $role }
        @{$request_result->{report}{children} || []};
    confess "Error: AXI write transaction composition is missing generated request child report '$role'\n"
        unless $child;
    my $copy = _clone_jsonish($child);
    $copy->{instance_name} = $instance_name;
    $copy->{role} = $role eq 'coordinator' ? 'request-coordinator' : $role;
    return $copy;
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
        'profile must be axi4, object must be axi-write-transaction-composition, and role must be manager',
        'clock and asynchronous active-low reset are shared by all five generated children',
        'one idle admission atomically captures aligned address width 32, ID width 4, data width 32, and strobe width 4',
        'AW metadata is fixed to AWLEN 0, AWSIZE 2, and AWBURST INCR while W is one final beat and zero strobe is legal',
        'flat C4 topology reuses unchanged generated AW, W, request coordinator, and B acceptor actors plus one transaction coordinator',
        'private request and B status bindings isolate child-to-child links and the nested request top is omitted',
        'B is armed only after both request channels accept',
        'aggregate busy spans admission through B retirement and request/transaction done are distinct one-cycle pulses',
        'captured BID is matched against retained admitted AWID and mismatch terminally completes with match zero plus assertion',
        'captured two-bit BRESP remains raw transaction status and is not interpreted as success',
        'all public bindings, generated internal signals, instance names, and artifact names are distinct',
        'lowering is IAL2 through five generated IAL1 and five generated leaf IAL0 actors into one structural IAL0 top, never direct IAL2-to-IAL0',
    ];
}

sub _unsupported_residue {
    return [
        { id => 'axi_write_transaction_composition_capacity_core_integration_deferred', detail => 'Capacity/status submit/completion and response-demux integration remain future work.' },
        { id => 'axi_write_transaction_composition_outstanding_queueing_deferred', detail => 'Multiple outstanding writes, queues, adjacent back-to-back admission, and response buffering remain future work.' },
        { id => 'axi_write_transaction_composition_id_allocation_ordering_deferred', detail => 'Dynamic ID allocation plus same-ID and different-ID ordering remain future work.' },
        { id => 'axi_write_transaction_composition_multi_beat_deferred', detail => 'Multi-beat W, dynamic WLAST/AW metadata, and burst address generation remain future work.' },
        { id => 'axi_write_transaction_composition_narrow_unaligned_deferred', detail => 'Narrow transfers, unaligned lane placement, and extended AXI attributes remain future work.' },
        { id => 'axi_write_transaction_composition_response_status_mapping_deferred', detail => 'Raw BRESP is captured; protocol-neutral or higher-level response status mapping remains future work.' },
        { id => 'axi_write_transaction_composition_extended_b_sidebands_deferred', detail => 'Extended Issue L B response signals and sidebands remain future work.' },
        { id => 'axi_write_transaction_composition_ar_r_channels_deferred', detail => 'Read-address and read-data/response behavior remain outside this write composition.' },
        { id => 'axi_write_transaction_composition_transaction_interface_deferred', detail => 'Decision 0020 protocol-neutral transaction interfaces remain director-gated future work.' },
        { id => 'axi_write_transaction_composition_profile_alias_deferred', detail => '.axi profile-alias surfacing remains unsupported; this source uses generic .ppif only.' },
        { id => 'axi_write_transaction_composition_verification_output_deferred', detail => 'Direct verification-output generation from this IAL2 source remains future work.' },
        { id => 'axi_write_transaction_composition_backend_variants_deferred', detail => 'Direct backend lowering, backend-language variants, and VHDL behavior remain future work.' },
        { id => 'axi_write_transaction_composition_other_protocols_unchanged', detail => 'AHB and APB behavior remain unchanged.' },
    ];
}

sub _required_scalar($raw, $field) {
    confess "AXI write transaction composition IAL2 contract is missing required scalar field '$field'\n"
        unless exists($raw->{$field}) && !ref($raw->{$field});
    return _nonempty_scalar($raw->{$field}, $field);
}

sub _required_hash($raw, $field) {
    confess "AXI write transaction composition IAL2 contract field '$field' must be a hash reference\n"
        unless ref($raw->{$field}) eq 'HASH';
    return $raw->{$field};
}

sub _required_identifier($raw, $field) {
    return _identifier_value(_required_scalar($raw, $field), $field);
}

sub _required_identifier_field($raw, $field, $label) {
    confess "AXI write transaction composition IAL2 contract is missing required field '$label'\n"
        unless exists($raw->{$field}) && !ref($raw->{$field});
    return _identifier_value($raw->{$field}, $label);
}

sub _normalize_width_binding($raw, $field, $expected_width) {
    confess "AXI write transaction composition IAL2 contract field '$field' must be a hash reference\n"
        unless ref($raw) eq 'HASH';
    my $name = _required_identifier_field($raw, 'name', "$field.name");
    my $width = _positive_integer($raw->{width}, "$field.width");
    confess "AXI write transaction composition IAL2 contract $field.width must be $expected_width in this slice\n"
        unless $width == $expected_width;
    return { name => $name, width => $width };
}

sub _normalize_reset($raw_reset) {
    confess "AXI write transaction composition IAL2 contract is missing required reset binding\n"
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
    confess "AXI write transaction composition IAL2 contract source.anchors must be an array reference\n"
        unless ref($anchors) eq 'ARRAY';
    my @normalized;
    for my $index (0 .. $#$anchors) {
        my $anchor = $anchors->[$index];
        confess "AXI write transaction composition IAL2 contract source.anchors[$index] must be a hash reference\n"
            unless ref($anchor) eq 'HASH';
        for my $required (qw(document section page)) {
            confess "AXI write transaction composition IAL2 contract source.anchors[$index] is missing '$required'\n"
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
        confess "AXI write transaction composition IAL2 contract duplicates signal '$name'\n"
            if $seen{$name}++;
    }
}

sub _nonempty_scalar($value, $field) {
    confess "AXI write transaction composition IAL2 contract field '$field' must be a non-empty scalar\n"
        unless defined($value) && !ref($value) && length($value);
    return "$value";
}

sub _identifier_value($value, $field) {
    my $identifier = _nonempty_scalar($value, $field);
    confess "AXI write transaction composition IAL2 contract field '$field' must be an ISF identifier\n"
        unless $identifier =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
    return $identifier;
}

sub _positive_integer($value, $field) {
    confess "AXI write transaction composition IAL2 contract field '$field' must be a positive integer\n"
        unless defined($value) && !ref($value) && "$value" =~ /\A[0-9]+\z/ && $value > 0;
    return 0 + $value;
}

sub _bool_value($value, $field) {
    confess "AXI write transaction composition IAL2 contract field '$field' must be boolean 0 or 1\n"
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
