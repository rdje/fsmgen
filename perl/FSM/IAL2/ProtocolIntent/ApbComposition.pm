package FSM::IAL2::ProtocolIntent::ApbComposition;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::IAL2::ProtocolIntent::ApbCompleter;
use FSM::IAL2::ProtocolIntent::ApbRequesterTransfer;

sub new($class, @constructor_args) {
    _validate_constructor_receiver($class);
    my %args = _validate_constructor_args($class, @constructor_args);

    return bless {
        debug => $args{debug} // 0,
    }, $class;
}

sub generate($self, @args) {
    _validate_object_receiver($self, 'generate');
    confess "FSM::IAL2::ProtocolIntent::ApbComposition->generate expects exactly one contract hash reference\n"
        unless @args == 1 && ref($args[0]) eq 'HASH';

    my $contract = _normalize_contract($args[0]);
    return _generate_multi_peripheral_composition($self, $contract)
        if _is_multi_peripheral_contract($contract);

    my $requester_contract = _endpoint_contract($contract, 'requester');
    my $completer_contract = _endpoint_contract($contract, 'completer');

    my $requester_result = FSM::IAL2::ProtocolIntent::ApbRequesterTransfer
        ->new(debug => $self->{debug})
        ->generate($requester_contract);
    my $completer_result = FSM::IAL2::ProtocolIntent::ApbCompleter
        ->new(debug => $self->{debug})
        ->generate($completer_contract);

    my (@ial1_items, @ial0_items, @schedule_reports);
    my %all_fsm_files;

    _add_endpoint_result(
        result          => $requester_result,
        role            => 'requester',
        object_name     => $contract->{requester}{name},
        ial1_items      => \@ial1_items,
        ial0_items      => \@ial0_items,
        schedule_reports => \@schedule_reports,
        fsm_files       => \%all_fsm_files,
    );
    _add_endpoint_result(
        result          => $completer_result,
        role            => 'completer',
        object_name     => $contract->{completer}{name},
        ial1_items      => \@ial1_items,
        ial0_items      => \@ial0_items,
        schedule_reports => \@schedule_reports,
        fsm_files       => \%all_fsm_files,
    );

    my $top = _build_composition_top(
        contract         => $contract,
        requester_result => $requester_result,
        completer_result => $completer_result,
        fsm_files        => \%all_fsm_files,
    );
    confess "Error: APB composition generated duplicate .fsm artifact '$top->{entry_artifact}'\n"
        if exists $all_fsm_files{$top->{entry_artifact}};
    $all_fsm_files{$top->{entry_artifact}} = $top->{text};
    push @ial0_items, $top->{ial0_item};

    my $report = _build_report(
        contract         => $contract,
        requester_result => $requester_result,
        completer_result => $completer_result,
        ial1_items       => \@ial1_items,
        ial0_items       => \@ial0_items,
        hdl_entry        => $top->{report_entry},
        fsm_files        => \%all_fsm_files,
    );

    return {
        layer => 'IAL2',
        kind  => 'protocol_intent.apb_composition',
        mode  => $report->{mode},
        generated_ial1 => {
            format => 'isf',
            items  => \@ial1_items,
        },
        generated_ial0 => {
            format => 'fsm',
            items  => \@ial0_items,
            files  => \%all_fsm_files,
        },
        generated_ial1_schedule_reports => \@schedule_reports,
        report => $report,
    };
}

sub _generate_multi_peripheral_composition($self, $contract) {
    my $requester_contract = _endpoint_contract($contract, 'requester');
    my $requester_result = FSM::IAL2::ProtocolIntent::ApbRequesterTransfer
        ->new(debug => $self->{debug})
        ->generate($requester_contract);

    my @peripheral_results;
    for my $peripheral (@{$contract->{composition}{children}{peripherals}}) {
        my $completer_contract = _endpoint_contract_for_object(
            $contract,
            _completer_for_child($contract, $peripheral),
        );
        my $result = FSM::IAL2::ProtocolIntent::ApbCompleter
            ->new(debug => $self->{debug})
            ->generate($completer_contract);
        push @peripheral_results, {
            child  => $peripheral,
            result => $result,
        };
    }

    my (@ial1_items, @ial0_items, @schedule_reports);
    my %all_fsm_files;

    _add_endpoint_result(
        result           => $requester_result,
        role             => 'requester',
        object_name      => $contract->{requester}{name},
        ial1_items       => \@ial1_items,
        ial0_items       => \@ial0_items,
        schedule_reports => \@schedule_reports,
        fsm_files        => \%all_fsm_files,
    );
    for my $entry (@peripheral_results) {
        _add_endpoint_result(
            result           => $entry->{result},
            role             => 'peripheral',
            object_name      => $entry->{child}{object_name},
            ial1_items       => \@ial1_items,
            ial0_items       => \@ial0_items,
            schedule_reports => \@schedule_reports,
            fsm_files        => \%all_fsm_files,
        );
    }

    my $interconnect = _build_apb_interconnect_artifacts($contract);
    push @ial1_items, $interconnect->{ial1_item};
    confess "Error: APB composition generated duplicate .fsm artifact '$interconnect->{entry_artifact}'\n"
        if exists $all_fsm_files{$interconnect->{entry_artifact}};
    $all_fsm_files{$interconnect->{entry_artifact}} = $interconnect->{fsm_text};
    push @ial0_items, $interconnect->{ial0_item};

    my $top = _build_multi_peripheral_composition_top(
        contract           => $contract,
        requester_result   => $requester_result,
        peripheral_results => \@peripheral_results,
        interconnect       => $interconnect,
        fsm_files          => \%all_fsm_files,
    );
    confess "Error: APB composition generated duplicate .fsm artifact '$top->{entry_artifact}'\n"
        if exists $all_fsm_files{$top->{entry_artifact}};
    $all_fsm_files{$top->{entry_artifact}} = $top->{text};
    push @ial0_items, $top->{ial0_item};

    my $report = _build_multi_peripheral_report(
        contract           => $contract,
        requester_result   => $requester_result,
        peripheral_results => \@peripheral_results,
        interconnect       => $interconnect,
        ial1_items         => \@ial1_items,
        ial0_items         => \@ial0_items,
        hdl_entry          => $top->{report_entry},
        fsm_files          => \%all_fsm_files,
    );

    return {
        layer => 'IAL2',
        kind  => 'protocol_intent.apb_composition',
        mode  => $report->{mode},
        generated_ial1 => {
            format => 'isf',
            items  => \@ial1_items,
        },
        generated_ial0 => {
            format => 'fsm',
            items  => \@ial0_items,
            files  => \%all_fsm_files,
        },
        generated_ial1_schedule_reports => \@schedule_reports,
        report => $report,
    };
}

sub _validate_constructor_receiver($class) {
    confess "FSM::IAL2::ProtocolIntent::ApbComposition->new must be called with the FSM::IAL2::ProtocolIntent::ApbComposition class invocant\n"
        unless defined($class) && !ref($class) && $class eq 'FSM::IAL2::ProtocolIntent::ApbComposition';
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
    confess "FSM::IAL2::ProtocolIntent::ApbComposition->$method must be called on an FSM::IAL2::ProtocolIntent::ApbComposition object\n"
        unless blessed($self) && $self->isa('FSM::IAL2::ProtocolIntent::ApbComposition');
}

sub _normalize_contract($raw) {
    my $kind = _required_scalar($raw, 'kind');
    confess "APB composition IAL2 contract kind must be apb_composition\n"
        unless $kind eq 'apb_composition';

    my $protocol = lc _required_scalar($raw, 'protocol');
    confess "APB composition IAL2 contract profile must be apb\n"
        unless $protocol eq 'apb';

    my $intent_name = _nonempty_scalar($raw->{intent_name}, 'intent_name');
    my $source = _required_hash($raw, 'source');
    my $composition = _required_hash($raw, 'composition');
    my $requester = _required_hash($raw, 'requester');
    return _normalize_multi_peripheral_contract($raw, $kind, $protocol, $intent_name, $source, $composition, $requester)
        if ref($raw->{completers}) eq 'ARRAY'
            || (ref($composition->{children}) eq 'HASH' && ref($composition->{children}{peripherals}) eq 'ARRAY');
    my $completer = _required_hash($raw, 'completer');

    my $name = _required_identifier($composition, 'name');
    my $role = lc _required_scalar($composition, 'role');
    confess "APB composition IAL2 contract role must be composition\n"
        unless $role eq 'composition';
    my $clock = _required_identifier($composition, 'clock');
    my $reset = _normalize_reset($composition->{reset}, 'composition.reset');
    my $children = _normalize_children(_required_hash($composition, 'children'));
    my $wiring = _normalize_wiring(_required_hash($composition, 'wiring'));

    _validate_endpoint_role($requester, 'requester', 'apb_requester_transfer');
    _validate_endpoint_role($completer, 'completer', 'apb_completer');
    _validate_shared_system_ports($clock, $reset, $requester, $completer);
    _validate_child_references($children, $requester, $completer);
    _validate_bus_compatibility($wiring->{bus}, $requester->{bus}, $completer->{bus});
    _validate_fixed_timing_policy_compatibility($wiring->{bus}, $requester, $completer);

    my $source_object_id = exists($source->{object_id})
        ? _nonempty_scalar($source->{object_id}, 'source.object_id')
        : $intent_name;
    my $anchors = exists($source->{anchors})
        ? _normalize_source_anchors($source->{anchors})
        : [];

    my $contract = {
        kind             => $kind,
        protocol         => $protocol,
        intent_name      => $intent_name,
        source           => $source,
        source_object_id => $source_object_id,
        source_anchors   => $anchors,
        composition      => {
            name     => $name,
            role     => $role,
            clock    => $clock,
            reset    => $reset,
            children => $children,
            wiring   => $wiring,
        },
        requester => _clone_jsonish($requester),
        completer => _clone_jsonish($completer),
    };
}

sub _normalize_multi_peripheral_contract($raw, $kind, $protocol, $intent_name, $source, $raw_composition, $requester) {
    my $raw_completers = $raw->{completers};
    confess "APB multi-peripheral composition IAL2 contract completers must be a non-empty array reference\n"
        unless ref($raw_completers) eq 'ARRAY' && @$raw_completers;

    my $name = _required_identifier($raw_composition, 'name');
    my $role = lc _required_scalar($raw_composition, 'role');
    confess "APB composition IAL2 contract role must be composition\n"
        unless $role eq 'composition';
    my $clock = _required_identifier($raw_composition, 'clock');
    my $reset = _normalize_reset($raw_composition->{reset}, 'composition.reset');
    my $children = _normalize_multi_peripheral_children(_required_hash($raw_composition, 'children'));
    my $decode = _normalize_decode(_required_hash($raw_composition, 'decode'));
    my $wiring = _normalize_wiring(_required_hash($raw_composition, 'wiring'));
    my $address_map = _normalize_address_map(
        _required_hash($raw_composition, 'address_map'),
        $children->{peripherals},
        _apb_bus_data_bytes($wiring->{bus}),
    );

    _validate_endpoint_role($requester, 'requester', 'apb_requester_transfer');
    _validate_multi_peripheral_completers($raw_completers);
    _validate_multi_shared_system_ports($clock, $reset, $requester, $raw_completers);
    _validate_multi_child_references($children, $requester, $raw_completers);
    _validate_multi_bus_compatibility($wiring->{bus}, $requester->{bus}, $raw_completers);
    _validate_multi_signal_uniqueness($clock, $reset, $requester, $raw_completers);
    _validate_multi_peripheral_timing_policy_compatibility($wiring->{bus}, $children, $requester, $raw_completers);

    my $source_object_id = exists($source->{object_id})
        ? _nonempty_scalar($source->{object_id}, 'source.object_id')
        : $intent_name;
    my $anchors = exists($source->{anchors})
        ? _normalize_source_anchors($source->{anchors})
        : [];

    my $contract = {
        kind             => $kind,
        protocol         => $protocol,
        intent_name      => $intent_name,
        source           => $source,
        source_object_id => $source_object_id,
        source_anchors   => $anchors,
        topology         => 'multi_peripheral_interconnect',
        composition      => {
            name        => $name,
            role        => $role,
            clock       => $clock,
            reset       => $reset,
            children    => $children,
            address_map => $address_map,
            decode      => $decode,
            wiring      => $wiring,
        },
        requester  => _clone_jsonish($requester),
        completers => [map { _clone_jsonish($_) } @$raw_completers],
    };
    _assign_multi_generated_instance_names($contract);
    return $contract;
}

sub _endpoint_contract($contract, $role) {
    my %endpoint = %{$contract->{$role}};
    $endpoint{protocol} = $contract->{protocol};
    $endpoint{intent_name} = $contract->{intent_name};
    $endpoint{source} = _clone_jsonish($contract->{source});
    return \%endpoint;
}

sub _endpoint_contract_for_object($contract, $endpoint) {
    my %copy = %$endpoint;
    $copy{protocol} = $contract->{protocol};
    $copy{intent_name} = $contract->{intent_name};
    $copy{source} = _clone_jsonish($contract->{source});
    return \%copy;
}

sub _is_multi_peripheral_contract($contract) {
    return ($contract->{topology} // '') eq 'multi_peripheral_interconnect';
}

sub _assign_multi_generated_instance_names($contract) {
    my $composition = $contract->{composition};
    my %reserved = map { $_->{name} => 1 } _multi_top_port_specs($contract);

    my $requester_child = $composition->{children}{requester};
    $requester_child->{generated_instance_name} = _unique_generated_instance_name(
        $requester_child->{instance_name},
        'requester',
        \%reserved,
    );

    $composition->{generated_interconnect_instance_name} = _unique_generated_instance_name(
        'interconnect',
        'interconnect',
        \%reserved,
    );

    for my $peripheral (@{$composition->{children}{peripherals}}) {
        $peripheral->{generated_instance_name} = _unique_generated_instance_name(
            $peripheral->{instance_name},
            'peripheral',
            \%reserved,
        );
    }
}

sub _unique_generated_instance_name($desired, $role, $reserved) {
    my $candidate = $desired;
    if (!$reserved->{$candidate}) {
        $reserved->{$candidate} = 1;
        return $candidate;
    }

    my $base = "${desired}_$role";
    $candidate = $base;
    my $suffix = 2;
    while ($reserved->{$candidate}) {
        $candidate = "${base}_$suffix";
        ++$suffix;
    }

    $reserved->{$candidate} = 1;
    return $candidate;
}

sub _generated_instance_name($child) {
    return $child->{generated_instance_name} // $child->{instance_name};
}

sub _completer_for_child($contract, $child) {
    for my $completer (@{$contract->{completers} || []}) {
        return $completer if ($completer->{name} // '') eq ($child->{object_name} // '');
    }
    confess "APB multi-peripheral composition child '$child->{instance_name}' references unknown APB completer object '$child->{object_name}'\n";
}

sub _add_endpoint_result(%args) {
    my $result = $args{result};
    my $role = $args{role};
    my $object_name = $args{object_name};
    my $ial1_items = $args{ial1_items};
    my $ial0_items = $args{ial0_items};
    my $schedule_reports = $args{schedule_reports};
    my $fsm_files = $args{fsm_files};

    push @$ial1_items, {
        object_name => $object_name,
        role        => $role,
        format      => $result->{generated_ial1}{format},
        name        => $result->{generated_ial1}{name},
        text        => $result->{generated_ial1}{text},
    };

    my @fsm_names = sort keys %{$result->{generated_ial0}{files} || {}};
    for my $fsm_name (@fsm_names) {
        confess "Error: APB composition generated duplicate endpoint .fsm artifact '$fsm_name'\n"
            if exists $fsm_files->{$fsm_name};
        $fsm_files->{$fsm_name} = $result->{generated_ial0}{files}{$fsm_name};
    }

    my $entry_artifact = $result->{report}{generated_artifacts}{hdl_entry}{entry_artifact};
    push @$ial0_items, {
        object_name    => $object_name,
        role           => $role,
        kind           => 'generated_endpoint',
        format         => 'fsm',
        files          => \@fsm_names,
        entry_artifact => $entry_artifact,
    };

    push @$schedule_reports, {
        object_name => $object_name,
        role        => $role,
        report      => _clone_jsonish($result->{generated_ial1_schedule_report}),
    };
}

sub _build_composition_top(%args) {
    my $contract = $args{contract};
    my $requester_result = $args{requester_result};
    my $completer_result = $args{completer_result};
    my $fsm_files = $args{fsm_files};

    my $composition = $contract->{composition};
    my $top_name = $composition->{name};
    my $entry_artifact = "$top_name.fsm";
    my $requester_child = $composition->{children}{requester};
    my $completer_child = $composition->{children}{completer};
    my $requester_entry = $requester_result->{report}{generated_artifacts}{hdl_entry}{entry_artifact};
    my $completer_entry = $completer_result->{report}{generated_artifacts}{hdl_entry}{entry_artifact};

    my @port_specs = _top_port_specs($contract);
    my @lines = (
        "(?top:$top_name",
        "  (?ports:public_io",
        (map { "    " . _composition_port_token($_) } @port_specs),
        "  )",
        "  (?fsmc:$requester_child->{instance_name} $requester_child->{object_name})",
        "  (?fsmc:$completer_child->{instance_name} $completer_child->{object_name})",
        "  (?wiring:$composition->{wiring}{name}",
        (map { "    $_" } _wiring_lines($composition)),
        "  )",
        ")",
        "",
    );

    for my $artifact ($requester_entry, $completer_entry) {
        confess "Error: APB composition is missing generated child .fsm artifact '$artifact'\n"
            unless defined($artifact) && exists $fsm_files->{$artifact};
        push @lines, $fsm_files->{$artifact};
        push @lines, "";
    }

    return {
        entry_artifact => $entry_artifact,
        text           => join("\n", @lines),
        ial0_item      => {
            object_name     => $top_name,
            role            => 'composition',
            kind            => 'generated_composition_top',
            format          => 'fsm',
            files           => [$entry_artifact],
            entry_artifact  => $entry_artifact,
            child_artifacts => [$requester_entry, $completer_entry],
        },
        report_entry   => {
            selected        => 1,
            kind            => 'generated_composition_top',
            format          => 'fsm',
            module          => $top_name,
            entry_artifact  => $entry_artifact,
            child_artifacts => [$requester_entry, $completer_entry],
            port_policy     => {
                shared_system_ports => {
                    clock => $composition->{clock},
                    reset => _clone_jsonish($composition->{reset}),
                },
                apb_bus_wiring => 'explicit_requester_completer_point_to_point',
            },
        },
    };
}

sub _build_apb_interconnect_artifacts($contract) {
    my $entry_artifact = 'apb_interconnect.fsm';
    my $isf_name = 'apb_interconnect.isf';
    my $isf_text = _build_apb_interconnect_isf($contract);
    my $fsm_text = _build_apb_interconnect_fsm($contract);

    return {
        object_name    => 'apb_interconnect',
        instance_name  => $contract->{composition}{generated_interconnect_instance_name} // 'interconnect',
        role           => 'interconnect',
        ial1_name      => $isf_name,
        ial1_text      => $isf_text,
        entry_artifact => $entry_artifact,
        fsm_text       => $fsm_text,
        ial1_item      => {
            object_name => 'apb_interconnect',
            role        => 'interconnect',
            format      => 'isf',
            name        => $isf_name,
            text        => $isf_text,
        },
        ial0_item      => {
            object_name    => 'apb_interconnect',
            role           => 'interconnect',
            kind           => 'generated_apb_interconnect',
            format         => 'fsm',
            files          => [$entry_artifact],
            entry_artifact => $entry_artifact,
        },
    };
}

sub _build_apb_interconnect_isf($contract) {
    my $composition = $contract->{composition};
    my $reset = _reset_clause($composition->{reset});
    my $request_bus = $composition->{wiring}{bus};
    my @interface_lines = (
        _interface_line('input', $request_bus->{select}),
        _interface_line('input', $request_bus->{enable}),
        _interface_line('input', $request_bus->{write}),
        _interface_line('input', $request_bus->{address}),
        _interface_line('input', $request_bus->{write_data}),
        (_bus_has_sidebands($request_bus) ? (
            _interface_line('input', $request_bus->{protection}),
            _interface_line('input', $request_bus->{strobe}),
        ) : ()),
        _interface_line('output', $request_bus->{ready}),
        _interface_line('output', $request_bus->{read_data}),
        _interface_line('output', $request_bus->{error}),
    );
    for my $peripheral (@{$composition->{children}{peripherals}}) {
        my $completer = _completer_for_child($contract, $peripheral);
        my $bus = $completer->{bus};
        push @interface_lines,
            _interface_line('output', $bus->{select}),
            _interface_line('output', $bus->{enable}),
            _interface_line('output', $bus->{write}),
            _interface_line('output', $bus->{address}),
            _interface_line('output', $bus->{write_data}),
            (_bus_has_sidebands($bus) ? (
                _interface_line('output', $bus->{protection}),
                _interface_line('output', $bus->{strobe}),
            ) : ()),
            _interface_line('input', $bus->{ready}),
            _interface_line('input', $bus->{read_data}),
            _interface_line('input', $bus->{error});
    }

    my @window_lines;
    for my $window (@{$composition->{address_map}{windows}}) {
        push @window_lines,
            "    (window $window->{name}",
            "      (base $window->{base}{name} width $window->{base}{width} default $window->{base}{default})",
            "      (size $window->{size}{name} width $window->{size}{width} default $window->{size}{default}))";
    }

    return join("\n",
        "(actor apb_interconnect",
        "  (clock $composition->{clock})",
        "  $reset",
        "  (watchdog 65536)",
        "",
        "  (interface",
        @interface_lines,
        "  )",
        "",
        "  (address-map $composition->{address_map}{name}",
        @window_lines,
        "  )",
        "",
        "  (decode",
        "    (overlap $composition->{decode}{overlap})",
        "    (priority $composition->{decode}{priority})",
        "    (unmapped-address $composition->{decode}{unmapped_address}))",
        "",
        "  (behavior",
        "    (request-fanout decoded-psel local-address)",
        "    (response-mux selected-peripheral unmapped-address-error)))",
        "",
    );
}

sub _build_apb_interconnect_fsm($contract) {
    my $composition = $contract->{composition};
    my $request_bus = $composition->{wiring}{bus};
    my @size_lines = (
        _size_line($request_bus->{select}, 1),
        _size_line($request_bus->{enable}, 1),
        _size_line($request_bus->{write}, 1),
        _size_line($request_bus->{address}{name}, $request_bus->{address}{width}),
        _size_line($request_bus->{write_data}{name}, $request_bus->{write_data}{width}),
        (_bus_has_sidebands($request_bus) ? (
            _size_line($request_bus->{protection}{name}, $request_bus->{protection}{width}),
            _size_line($request_bus->{strobe}{name}, $request_bus->{strobe}{width}),
        ) : ()),
        _size_line($request_bus->{ready}, 1),
        _size_line($request_bus->{read_data}{name}, $request_bus->{read_data}{width}),
        _size_line($request_bus->{error}, 1),
    );
    for my $peripheral (@{$composition->{children}{peripherals}}) {
        my $bus = _completer_for_child($contract, $peripheral)->{bus};
        push @size_lines,
            _size_line($bus->{select}, 1),
            _size_line($bus->{enable}, 1),
            _size_line($bus->{write}, 1),
            _size_line($bus->{address}{name}, $bus->{address}{width}),
            _size_line($bus->{write_data}{name}, $bus->{write_data}{width}),
            (_bus_has_sidebands($bus) ? (
                _size_line($bus->{protection}{name}, $bus->{protection}{width}),
                _size_line($bus->{strobe}{name}, $bus->{strobe}{width}),
            ) : ()),
            _size_line($bus->{ready}, 1),
            _size_line($bus->{read_data}{name}, $bus->{read_data}{width}),
            _size_line($bus->{error}, 1);
    }

    my @fanout_lines;
    my @hit_exprs;
    for my $peripheral (@{$composition->{children}{peripherals}}) {
        my $window = _window_for_peripheral($composition, $peripheral->{instance_name});
        my $hit = _window_hit_expr($request_bus, $window);
        push @hit_exprs, $hit;
        my $bus = _completer_for_child($contract, $peripheral)->{bus};
        push @fanout_lines,
            "    (<- ($bus->{enable}> $request_bus->{enable}))",
            "    (<- ($bus->{write}> $request_bus->{write}))",
            "    (<- ($bus->{write_data}{name}> $request_bus->{write_data}{name}))",
            (_bus_has_sidebands($request_bus) ? (
                "    (<- ($bus->{protection}{name}> $request_bus->{protection}{name}))",
                "    (<- ($bus->{strobe}{name}> $request_bus->{strobe}{name}))",
            ) : ()),
            "    (<- ($bus->{select}> $request_bus->{select}) <$hit)",
            "    (<- ($bus->{select}> 0) <(! $hit))",
            "    (<- ($bus->{address}{name}> " . _local_address_expr($request_bus, $window) . ") <$hit)",
            "    (<- ($bus->{address}{name}> 0) <(! $hit))";
    }

    my $any_hit = _any_hit_expr(@hit_exprs);
    my $unmapped_access = "(& $request_bus->{select} $request_bus->{enable} (! $any_hit))";
    my $default_response = "(! (| $any_hit $unmapped_access))";
    my @response_lines;
    for my $peripheral (@{$composition->{children}{peripherals}}) {
        my $window = _window_for_peripheral($composition, $peripheral->{instance_name});
        my $hit = _window_hit_expr($request_bus, $window);
        my $bus = _completer_for_child($contract, $peripheral)->{bus};
        push @response_lines,
            "    (<- ($request_bus->{ready}> $bus->{ready}) <$hit)",
            "    (<- ($request_bus->{read_data}{name}> $bus->{read_data}{name}) <$hit)",
            "    (<- ($request_bus->{error}> $bus->{error}) <$hit)";
    }
    push @response_lines,
        "    (<- ($request_bus->{ready}> 1) <$unmapped_access)",
        "    (<- ($request_bus->{read_data}{name}> 0) <$unmapped_access)",
        "    (<- ($request_bus->{error}> 1) <$unmapped_access)",
        "    (<- ($request_bus->{ready}> 0) <$default_response)",
        "    (<- ($request_bus->{read_data}{name}> 0) <$default_response)",
        "    (<- ($request_bus->{error}> 0) <$default_response)";

    return join("\n",
        "(?fsm:apb_interconnect",
        "",
        "  (+system",
        "    (clock $composition->{clock})",
        "    (areset $composition->{reset}{signal})",
        "  )",
        "",
        "  (+size",
        @size_lines,
        "  )",
        "",
        "  (idle",
        "    (-> idle)",
        "  )",
        "",
        "  (-request_fanout",
        @fanout_lines,
        "  )",
        "",
        "  (-response_mux",
        @response_lines,
        "  )",
        "",
        ")",
        "",
    );
}

sub _build_multi_peripheral_composition_top(%args) {
    my $contract = $args{contract};
    my $requester_result = $args{requester_result};
    my $peripheral_results = $args{peripheral_results};
    my $interconnect = $args{interconnect};
    my $fsm_files = $args{fsm_files};

    my $composition = $contract->{composition};
    my $top_name = $composition->{name};
    my $entry_artifact = "$top_name.fsm";
    my $requester_child = $composition->{children}{requester};
    my $requester_instance = _generated_instance_name($requester_child);
    my $requester_entry = $requester_result->{report}{generated_artifacts}{hdl_entry}{entry_artifact};
    my @peripheral_entries = map {
        $_->{result}{report}{generated_artifacts}{hdl_entry}{entry_artifact}
    } @$peripheral_results;
    my @child_artifacts = ($requester_entry, $interconnect->{entry_artifact}, @peripheral_entries);

    my @port_specs = _multi_top_port_specs($contract);
    my @lines = (
        "(?top:$top_name",
        "  (?ports:public_io",
        (map { "    " . _composition_port_token($_) } @port_specs),
        "  )",
        "  (?fsmc:$requester_instance $requester_child->{object_name})",
        "  (?fsmc:$interconnect->{instance_name} $interconnect->{object_name})",
        (map { "  (?fsmc:" . _generated_instance_name($_) . " $_->{object_name})" } @{$composition->{children}{peripherals}}),
        "  (?wiring:$composition->{wiring}{name}",
        (map { "    $_" } _multi_wiring_lines($contract, $interconnect)),
        "  )",
        ")",
        "",
    );

    for my $artifact (@child_artifacts) {
        confess "Error: APB multi-peripheral composition is missing generated child .fsm artifact '$artifact'\n"
            unless defined($artifact) && exists $fsm_files->{$artifact};
        push @lines, $fsm_files->{$artifact};
        push @lines, "";
    }

    return {
        entry_artifact => $entry_artifact,
        text           => join("\n", @lines),
        ial0_item      => {
            object_name     => $top_name,
            role            => 'composition',
            kind            => 'generated_composition_top',
            format          => 'fsm',
            files           => [$entry_artifact],
            entry_artifact  => $entry_artifact,
            child_artifacts => \@child_artifacts,
        },
        report_entry   => {
            selected        => 1,
            kind            => 'generated_composition_top',
            format          => 'fsm',
            module          => $top_name,
            entry_artifact  => $entry_artifact,
            child_artifacts => \@child_artifacts,
            port_policy     => {
                shared_system_ports => {
                    clock => $composition->{clock},
                    reset => _clone_jsonish($composition->{reset}),
                },
                apb_bus_wiring => 'decoded_multi_peripheral_interconnect',
            },
        },
    };
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

sub _size_line($name, $width) {
    return "    ($name $width)";
}

sub _window_for_peripheral($composition, $peripheral_name) {
    for my $window (@{$composition->{address_map}{windows}}) {
        return $window if $window->{name} eq $peripheral_name;
    }
    confess "APB multi-peripheral composition has no address-map window for peripheral '$peripheral_name'\n";
}

sub _window_hit_expr($request_bus, $window) {
    return "(& $request_bus->{select} (>= $request_bus->{address}{name} $window->{base}{default}) (< $request_bus->{address}{name} $window->{limit}))";
}

sub _local_address_expr($request_bus, $window) {
    return $request_bus->{address}{name}
        if $window->{base}{default} == 0;
    return "(- $request_bus->{address}{name} $window->{base}{default})";
}

sub _any_hit_expr(@hit_exprs) {
    confess "APB multi-peripheral composition requires at least one decoded hit expression\n"
        unless @hit_exprs;
    return $hit_exprs[0] if @hit_exprs == 1;
    return "(| " . join(' ', @hit_exprs) . ")";
}

sub _request_has_sidebands($requester) {
    return defined($requester->{request}{protection})
        && defined($requester->{request}{write_strobe});
}

sub _bus_has_sidebands($bus) {
    return defined($bus->{protection}) && defined($bus->{strobe});
}

sub _multi_top_port_specs($contract) {
    my $composition = $contract->{composition};
    my $requester = $contract->{requester};

    return (
        {
            name      => $composition->{clock},
            direction => 'input',
            width     => 1,
            system    => 'clock',
        },
        {
            name      => $composition->{reset}{signal},
            direction => 'input',
            width     => 1,
            system    => 'reset',
        },
        _input_port($requester->{request}{start}, 1),
        _input_port($requester->{request}{write}, 1),
        _input_port($requester->{request}{address}{name}, $requester->{request}{address}{width}),
        _input_port($requester->{request}{write_data}{name}, $requester->{request}{write_data}{width}),
        (_request_has_sidebands($requester) ? (
            _input_port($requester->{request}{protection}{name}, $requester->{request}{protection}{width}),
            _input_port($requester->{request}{write_strobe}{name}, $requester->{request}{write_strobe}{width}),
        ) : ()),
        (map {
            my $completer = _completer_for_child($contract, $_);
            _input_port($completer->{control}{wait_cycles}{name}, $completer->{control}{wait_cycles}{width});
        } @{$composition->{children}{peripherals}}),
        (defined($requester->{response}{accepted}) ? (_output_port($requester->{response}{accepted}, 1)) : ()),
        (defined($requester->{response}{busy}) ? (_output_port($requester->{response}{busy}, 1)) : ()),
        (defined($requester->{response}{status}) ? (_output_port($requester->{response}{status}{name}, $requester->{response}{status}{width})) : ()),
        _output_port($requester->{response}{done}, 1),
        _output_port($requester->{response}{error}, 1),
        _output_port($requester->{response}{read_data}{name}, $requester->{response}{read_data}{width}),
    );
}

sub _multi_wiring_lines($contract, $interconnect) {
    my $composition = $contract->{composition};
    my $requester = _generated_instance_name($composition->{children}{requester});
    my $interconnect_instance = $interconnect->{instance_name};
    my $bus = $composition->{wiring}{bus};

    my @lines = (
        "($requester.$bus->{select} $interconnect_instance.$bus->{select})",
        "($requester.$bus->{enable} $interconnect_instance.$bus->{enable})",
        "($requester.$bus->{write} $interconnect_instance.$bus->{write})",
        "($requester.$bus->{address}{name} $interconnect_instance.$bus->{address}{name})",
        "($requester.$bus->{write_data}{name} $interconnect_instance.$bus->{write_data}{name})",
        (_bus_has_sidebands($bus) ? (
            "($requester.$bus->{protection}{name} $interconnect_instance.$bus->{protection}{name})",
            "($requester.$bus->{strobe}{name} $interconnect_instance.$bus->{strobe}{name})",
        ) : ()),
        "($interconnect_instance.$bus->{ready} $requester.$bus->{ready})",
        "($interconnect_instance.$bus->{read_data}{name} $requester.$bus->{read_data}{name})",
        "($interconnect_instance.$bus->{error} $requester.$bus->{error})",
    );

    for my $peripheral (@{$composition->{children}{peripherals}}) {
        my $instance = _generated_instance_name($peripheral);
        my $peripheral_bus = _completer_for_child($contract, $peripheral)->{bus};
        push @lines,
            "($interconnect_instance.$peripheral_bus->{select} $instance.$peripheral_bus->{select})",
            "($interconnect_instance.$peripheral_bus->{enable} $instance.$peripheral_bus->{enable})",
            "($interconnect_instance.$peripheral_bus->{write} $instance.$peripheral_bus->{write})",
            "($interconnect_instance.$peripheral_bus->{address}{name} $instance.$peripheral_bus->{address}{name})",
            "($interconnect_instance.$peripheral_bus->{write_data}{name} $instance.$peripheral_bus->{write_data}{name})",
            (_bus_has_sidebands($peripheral_bus) ? (
                "($interconnect_instance.$peripheral_bus->{protection}{name} $instance.$peripheral_bus->{protection}{name})",
                "($interconnect_instance.$peripheral_bus->{strobe}{name} $instance.$peripheral_bus->{strobe}{name})",
            ) : ()),
            "($instance.$peripheral_bus->{ready} $interconnect_instance.$peripheral_bus->{ready})",
            "($instance.$peripheral_bus->{read_data}{name} $interconnect_instance.$peripheral_bus->{read_data}{name})",
            "($instance.$peripheral_bus->{error} $interconnect_instance.$peripheral_bus->{error})";
    }

    return @lines;
}

sub _top_port_specs($contract) {
    my $composition = $contract->{composition};
    my $requester = $contract->{requester};
    my $completer = $contract->{completer};

    return (
        {
            name      => $composition->{clock},
            direction => 'input',
            width     => 1,
            system    => 'clock',
        },
        {
            name      => $composition->{reset}{signal},
            direction => 'input',
            width     => 1,
            system    => 'reset',
        },
        _input_port($requester->{request}{start}, 1),
        _input_port($requester->{request}{write}, 1),
        _input_port($requester->{request}{address}{name}, $requester->{request}{address}{width}),
        _input_port($requester->{request}{write_data}{name}, $requester->{request}{write_data}{width}),
        (_request_has_sidebands($requester) ? (
            _input_port($requester->{request}{protection}{name}, $requester->{request}{protection}{width}),
            _input_port($requester->{request}{write_strobe}{name}, $requester->{request}{write_strobe}{width}),
        ) : ()),
        _input_port($completer->{control}{wait_cycles}{name}, $completer->{control}{wait_cycles}{width}),
        (defined($requester->{response}{accepted}) ? (_output_port($requester->{response}{accepted}, 1)) : ()),
        (defined($requester->{response}{busy}) ? (_output_port($requester->{response}{busy}, 1)) : ()),
        (defined($requester->{response}{status}) ? (_output_port($requester->{response}{status}{name}, $requester->{response}{status}{width})) : ()),
        _output_port($requester->{response}{done}, 1),
        _output_port($requester->{response}{error}, 1),
        _output_port($requester->{response}{read_data}{name}, $requester->{response}{read_data}{width}),
    );
}

sub _input_port($name, $width) {
    return {
        name      => $name,
        direction => 'input',
        width     => $width,
    };
}

sub _output_port($name, $width) {
    return {
        name      => $name,
        direction => 'output',
        width     => $width,
    };
}

sub _composition_port_token($spec) {
    my $name = _identifier_value($spec->{name}, 'top port name');
    my $width = _positive_integer($spec->{width}, "top port $name width");
    return $width == 1 ? $name : "$name<$width"
        if $spec->{system};

    my $direction = _nonempty_scalar($spec->{direction}, "top port $name direction");
    confess "APB composition top port '$name' has unsupported direction '$direction'\n"
        unless $direction eq 'input' || $direction eq 'output';
    return $width == 1 ? "=$name" : "=$name<$width"
        if $direction eq 'input';
    return $width == 1 ? "=$name>" : "=$name>$width";
}

sub _wiring_lines($composition) {
    my $requester = $composition->{children}{requester}{instance_name};
    my $completer = $composition->{children}{completer}{instance_name};
    my $bus = $composition->{wiring}{bus};

    return (
        "($requester.$bus->{select} $completer.$bus->{select})",
        "($requester.$bus->{enable} $completer.$bus->{enable})",
        "($requester.$bus->{write} $completer.$bus->{write})",
        "($requester.$bus->{address}{name} $completer.$bus->{address}{name})",
        "($requester.$bus->{write_data}{name} $completer.$bus->{write_data}{name})",
        (_bus_has_sidebands($bus) ? (
            "($requester.$bus->{protection}{name} $completer.$bus->{protection}{name})",
            "($requester.$bus->{strobe}{name} $completer.$bus->{strobe}{name})",
        ) : ()),
        "($completer.$bus->{ready} $requester.$bus->{ready})",
        "($completer.$bus->{read_data}{name} $requester.$bus->{read_data}{name})",
        "($completer.$bus->{error} $requester.$bus->{error})",
    );
}

sub _build_multi_peripheral_report(%args) {
    my $contract = $args{contract};
    my $requester_result = $args{requester_result};
    my $peripheral_results = $args{peripheral_results};
    my $interconnect = $args{interconnect};
    my @ial1_items = @{$args{ial1_items} || []};
    my @ial0_items = @{$args{ial0_items} || []};
    my $hdl_entry = $args{hdl_entry};
    my @fsm_files = sort keys %{$args{fsm_files} || {}};
    my $composition = $contract->{composition};
    my @peripherals = @{$composition->{children}{peripherals}};

    my $report = {
        schema => 'fsmgen.ial2.protocol_intent.apb_composition.v1',
        mode   => 'requester-multi-peripheral-composition',
        layering => {
            source_layer          => 'IAL2',
            generated_ial1_format => 'isf',
            generated_ial0_format => 'fsm',
            direct_ial2_to_ial0   => 0,
        },
        source_object => {
            id          => $contract->{source_object_id},
            intent_name => $contract->{intent_name},
            anchors     => _clone_jsonish($contract->{source_anchors}),
        },
        target_protocol => {
            profile => $contract->{protocol},
            object  => 'apb-composition',
            role    => $composition->{role},
        },
        composition => {
            name                          => $composition->{name},
            topology                      => 'multi_peripheral_interconnect',
            child_instance_count          => 2 + scalar(@peripherals),
            endpoint_child_instance_count => 1 + scalar(@peripherals),
            requester                     => _clone_jsonish($composition->{children}{requester}),
            peripherals                   => _multi_peripheral_report_entries($contract),
            address_map                   => _multi_address_map_report($contract),
            decode                        => _clone_jsonish($composition->{decode}),
            response_mux                  => _multi_response_mux_report($contract),
            generated_interconnect        => {
                object_name   => $interconnect->{object_name},
                instance_name => $interconnect->{instance_name},
                ial1_artifact => $interconnect->{ial1_name},
                ial0_artifact => $interconnect->{entry_artifact},
            },
            wiring                        => _clone_jsonish($composition->{wiring}),
            width_policy                  => _composition_width_policy($contract),
            top_ports                     => [map { _clone_jsonish($_) } _multi_top_port_specs($contract)],
        },
        children => [
            _child_report('requester', $composition->{children}{requester}, $requester_result),
            _interconnect_child_report($contract, $interconnect),
            map {
                _child_report('peripheral', $_->{child}, $_->{result})
            } @$peripheral_results,
        ],
        generated_artifacts => {
            ial1 => {
                format => 'isf',
                items  => [
                    map {
                        {
                            object_name => $_->{object_name},
                            role        => $_->{role},
                            name        => $_->{name},
                            format      => $_->{format},
                        }
                    } @ial1_items
                ],
            },
            ial0 => {
                format => 'fsm',
                files  => \@fsm_files,
                items  => _clone_jsonish(\@ial0_items),
            },
            hdl_entry => _clone_jsonish($hdl_entry),
        },
        enforced_static_rules => [
            'profile must be apb and the aggregate object must be apb-composition',
            'multi-peripheral composition requires one requester, two or more APB completer peripherals, and one generated APB interconnect',
            'peripheral instances, peripheral object names, address-map windows, and generated signal names must be unique',
            'generated top instance names are deterministic and avoid collisions with declared top ports while reports preserve authored peripheral names',
            'address-map base and size defaults must be static 32-bit non-overlapping ' . _composition_data_bytes($contract) . '-byte-aligned decimal values',
            'decode policy is overlap reject, priority source-order, and unmapped-address error',
            'the generated APB interconnect fans out decoded PSEL, forwards control/data, translates local PADDR, muxes selected responses, and returns PSLVERR for unmapped active accesses',
            (_multi_peripheral_has_back_to_back_policy($contract) ? ('selected multi-peripheral back-to-back policy requires requester back-to-back queued queue-depth 1 overflow reject, every peripheral setup-admission adjacent, and propagation-only interconnect decode without idle-cycle insertion') : ()),
            (_composition_has_sidebands($contract) ? ('sideband-aware multi-peripheral composition propagates PPROT width 3 and data-derived PSTRB width ' . _composition_strobe_width($contract) . ' through the generated APB interconnect') : ()),
            (_composition_has_access_policy($contract) ? ('register-local PPROT access-policy enforcement is owned by the selected APB completer/peripheral; the generated composition and interconnect only propagate PPROT/PSTRB and mux selected responses') : ()),
            'APB composition is exposed through .ppif and bounded .apb profile-alias sources; direct IAL2-to-IAL0 lowering remains forbidden',
        ],
        unsupported_residue => _apb_multi_peripheral_unsupported_residue($contract),
    };

    $report->{requester_status_field} = _clone_jsonish($requester_result->{report}{response_status_field})
        if defined $requester_result->{report}{response_status_field};
    $report->{requester_accepted_field} = _clone_jsonish($requester_result->{report}{response_accepted_field})
        if defined $requester_result->{report}{response_accepted_field};
    $report->{back_to_back_policy} = _multi_peripheral_back_to_back_policy_report($contract, $requester_result, $peripheral_results, $interconnect)
        if _multi_peripheral_has_back_to_back_policy($contract);
    $report->{protection_policy} = _multi_peripheral_protection_policy_report($peripheral_results)
        if _composition_has_access_policy($contract);

    return $report;
}

sub _multi_peripheral_report_entries($contract) {
    my $composition = $contract->{composition};
    return [
        map {
            my $window = _window_for_peripheral($composition, $_->{instance_name});
            my $completer = _completer_for_child($contract, $_);
            {
                instance_name         => $_->{instance_name},
                generated_instance_name => _generated_instance_name($_),
                object_name           => $_->{object_name},
                role                  => 'peripheral',
                address_window        => _clone_jsonish($window),
                local_address_policy  => 'subtract_window_base',
                decoded_select_signal => $completer->{bus}{select},
            }
        } @{$composition->{children}{peripherals}}
    ];
}

sub _multi_address_map_report($contract) {
    my $composition = $contract->{composition};
    return {
        name             => $composition->{address_map}{name},
        address_width    => $composition->{address_map}{address_width},
        alignment_bytes  => $composition->{address_map}{alignment_bytes},
        windows          => _clone_jsonish($composition->{address_map}{windows}),
        overlap_policy   => $composition->{decode}{overlap},
        priority         => $composition->{decode}{priority},
        unmapped_address => $composition->{decode}{unmapped_address},
    };
}

sub _multi_response_mux_report($contract) {
    my $bus = $contract->{composition}{wiring}{bus};
    return {
        ready           => $bus->{ready},
        read_data       => _clone_jsonish($bus->{read_data}),
        error           => $bus->{error},
        selected_policy => 'selected_peripheral_response',
        unmapped_policy => {
            active_access => 'PSEL && PENABLE with no matching address window',
            ready         => 1,
            read_data     => 0,
            error         => 1,
        },
        idle_policy => {
            ready     => 0,
            read_data => 0,
            error     => 0,
        },
    };
}

sub _interconnect_child_report($contract, $interconnect) {
    my $report = {
        role                => 'interconnect',
        instance_name       => $interconnect->{instance_name},
        object_name         => $interconnect->{object_name},
        target_protocol     => {
            profile  => $contract->{protocol},
            object   => 'apb-interconnect',
            role     => 'interconnect',
            topology => 'multi_peripheral_interconnect',
        },
        address_map         => _multi_address_map_report($contract),
        response_mux        => _multi_response_mux_report($contract),
        generated_artifacts => {
            ial1 => {
                name   => $interconnect->{ial1_name},
                format => 'isf',
            },
            ial0 => {
                format => 'fsm',
                files  => [$interconnect->{entry_artifact}],
            },
            hdl_entry => {
                selected       => 0,
                kind           => 'generated_apb_interconnect',
                entry_artifact => $interconnect->{entry_artifact},
                module         => $interconnect->{object_name},
            },
        },
        unsupported_residue => _clone_jsonish(_apb_multi_peripheral_interconnect_unsupported_residue($contract)),
    };
    $report->{protection_policy} = {
        enforcement_owner => 'peripheral_completers',
        interconnect_role => 'propagate_pprot_pstrb_and_mux_selected_response_only',
    } if _composition_has_access_policy($contract);
    $report->{back_to_back_policy} = {
        interconnect_role => 'propagate_queued_setup_without_idle_cycle',
        setup_decode      => 'current_psel_paddr_with_penable_low',
        response_mux      => 'selected_peripheral_response',
        unmapped_policy   => 'active_access_only',
    } if _multi_peripheral_has_back_to_back_policy($contract);
    return $report;
}

sub _composition_has_sidebands($contract) {
    return _bus_has_sidebands($contract->{composition}{wiring}{bus});
}

sub _composition_data_width($contract) {
    return int($contract->{composition}{wiring}{bus}{write_data}{width});
}

sub _composition_data_bytes($contract) {
    return _apb_bus_data_bytes($contract->{composition}{wiring}{bus});
}

sub _composition_strobe_width($contract) {
    return int($contract->{composition}{wiring}{bus}{strobe}{width})
        if _composition_has_sidebands($contract);
    return undef;
}

sub _is_sideband_data16_contract($contract) {
    return _composition_has_sidebands($contract) && _composition_data_width($contract) == 16;
}

sub _composition_width_policy($contract) {
    my $data_width = _composition_data_width($contract);
    my %policy = (
        address_width            => 32,
        data_width               => $data_width,
        wait_cycles_width        => 4,
        address_map_width        => 32,
        address_map_alignment_bytes => _composition_data_bytes($contract),
        supported_data_widths    => [16, 32],
        selected_contract        => _is_sideband_data16_contract($contract) ? 'sideband_data16' : 'fixed_data32',
    );
    if (_composition_has_sidebands($contract)) {
        $policy{protection_width} = $contract->{composition}{wiring}{bus}{protection}{width};
        $policy{strobe_width} = _composition_strobe_width($contract);
    }
    return \%policy;
}

sub _apb_bus_data_bytes($bus) {
    my $data_width = _positive_integer($bus->{write_data}{width}, 'composition.wiring.bus.write_data.width');
    confess "APB composition IAL2 contract bus.write_data.width must match bus.read_data.width in this slice\n"
        unless $data_width == $bus->{read_data}{width};
    confess "APB composition IAL2 contract bus data width must be byte-addressable in this slice\n"
        unless $data_width % 8 == 0;
    return int($data_width / 8);
}

sub _apb_multi_peripheral_unsupported_residue($contract) {
    return [
        _apb_composition_protection_residue($contract),
        _apb_alternate_widths_residue($contract),
        _multi_peripheral_has_back_to_back_policy($contract)
            ? _apb_additional_back_to_back_policies_residue()
            : _apb_back_to_back_residue(),
    ];
}

sub _apb_multi_peripheral_interconnect_unsupported_residue($contract) {
    return [
        _apb_composition_protection_residue($contract),
        _apb_alternate_widths_residue($contract),
        _multi_peripheral_has_back_to_back_policy($contract)
            ? _apb_additional_back_to_back_policies_residue()
            : _apb_back_to_back_residue(),
    ];
}

sub _apb_sideband_residue() {
    return {
        id     => 'apb_protection_and_strobes_deferred',
        detail => 'PPROT, PSTRB, byte-enable policy, and APB4/APB5 sideband behavior remain future APB work.',
    };
}

sub _apb_protection_policy_effects_residue() {
    return {
        id     => 'apb_protection_policy_effects_deferred',
        detail => 'PPROT is propagated through the generated APB composition and interconnect, but protection access-control policy remains future APB work.',
    };
}

sub _apb_additional_protection_policies_residue() {
    return {
        id     => 'apb_additional_protection_policies_deferred',
        detail => 'Register-local privileged PPROT[0] access policy is implemented by selected 16-bit and 32-bit APB completer endpoints; global, window-level, interconnect-owned, programmable, boolean, multi-predicate, and non-privileged policy families remain future APB work.',
    };
}

sub _apb_composition_protection_residue($contract) {
    return _apb_sideband_residue()
        unless _composition_has_sidebands($contract);
    return _apb_additional_protection_policies_residue()
        if _composition_has_access_policy($contract);
    return _apb_protection_policy_effects_residue();
}

sub _apb_alternate_widths_residue($contract) {
    return {
        id     => 'apb_remaining_widths_deferred',
        detail => 'Address widths other than 32 bits, wait-count widths other than 4 bits, and APB data widths beyond the selected sideband-aware 16/32-bit boundary remain future APB composition work.',
    } if _is_sideband_data16_contract($contract);

    return {
        id     => 'apb_alternate_widths_deferred',
        detail => 'This APB composition fixes address, write-data, and read-data widths to 32 bits and wait-cycle controls to 4 bits.',
    };
}

sub _apb_back_to_back_residue() {
    return {
        id     => 'apb_back_to_back_policy_deferred',
        detail => 'Back-to-back transfer policy and queued requester admission remain future exact-owner work.',
    };
}

sub _build_report(%args) {
    my $contract = $args{contract};
    my $requester_result = $args{requester_result};
    my $completer_result = $args{completer_result};
    my @ial1_items = @{$args{ial1_items} || []};
    my @ial0_items = @{$args{ial0_items} || []};
    my $hdl_entry = $args{hdl_entry};
    my @fsm_files = sort keys %{$args{fsm_files} || {}};
    my $composition = $contract->{composition};

    my $report = {
        schema => 'fsmgen.ial2.protocol_intent.apb_composition.v1',
        mode   => 'requester-completer-composition',
        layering => {
            source_layer          => 'IAL2',
            generated_ial1_format => 'isf',
            generated_ial0_format => 'fsm',
            direct_ial2_to_ial0   => 0,
        },
        source_object => {
            id          => $contract->{source_object_id},
            intent_name => $contract->{intent_name},
            anchors     => _clone_jsonish($contract->{source_anchors}),
        },
        target_protocol => {
            profile => $contract->{protocol},
            object  => 'apb-composition',
            role    => $composition->{role},
        },
        composition => {
            name              => $composition->{name},
            child_instance_count => 2,
            requester         => _clone_jsonish($composition->{children}{requester}),
            completer         => _clone_jsonish($composition->{children}{completer}),
            wiring            => _clone_jsonish($composition->{wiring}),
            width_policy      => _composition_width_policy($contract),
            top_ports         => [map { _clone_jsonish($_) } _top_port_specs($contract)],
        },
        children => [
            _child_report('requester', $composition->{children}{requester}, $requester_result),
            _child_report('completer', $composition->{children}{completer}, $completer_result),
        ],
        generated_artifacts => {
            ial1 => {
                format => 'isf',
                items  => [
                    map {
                        {
                            object_name => $_->{object_name},
                            role        => $_->{role},
                            name        => $_->{name},
                            format      => $_->{format},
                        }
                    } @ial1_items
                ],
            },
            ial0 => {
                format => 'fsm',
                files  => \@fsm_files,
                items  => _clone_jsonish(\@ial0_items),
            },
            hdl_entry => _clone_jsonish($hdl_entry),
        },
        enforced_static_rules => [
            'profile must be apb and the aggregate object must be apb-composition',
            'source must contain exactly one APB requester, one APB completer, and one APB composition object',
            'requester, completer, and composition must share clock and reset policy',
            'composition children must reference the embedded requester and completer objects by name',
            'composition bus wiring must match requester and completer APB signal names and widths',
            (_fixed_composition_has_back_to_back_policy($contract) ? ('selected fixed-composition back-to-back policy requires requester back-to-back queued queue-depth 1 overflow reject and completer setup-admission adjacent') : ()),
            (_composition_has_sidebands($contract) ? ('sideband-aware composition wiring requires PPROT width 3 and data-derived PSTRB width ' . _composition_strobe_width($contract) . ' across requester, completer, and composition bus bindings') : ()),
            (_composition_has_access_policy($contract) ? ('register-local PPROT access-policy enforcement is owned by the completer child; the fixed composition only propagates PPROT/PSTRB and selected endpoint responses') : ()),
            'APB composition is exposed through .ppif and bounded .apb profile-alias sources; direct IAL2-to-IAL0 lowering remains forbidden',
        ],
        unsupported_residue => _apb_composition_unsupported_residue($contract),
    };

    $report->{requester_status_field} = _clone_jsonish($requester_result->{report}{response_status_field})
        if defined $requester_result->{report}{response_status_field};
    $report->{requester_accepted_field} = _clone_jsonish($requester_result->{report}{response_accepted_field})
        if defined $requester_result->{report}{response_accepted_field};
    $report->{back_to_back_policy} = _fixed_composition_back_to_back_policy_report($contract, $requester_result, $completer_result)
        if _fixed_composition_has_back_to_back_policy($contract);
    $report->{protection_policy} = _fixed_composition_protection_policy_report($contract, $completer_result)
        if _composition_has_access_policy($contract);

    return $report;
}

sub _apb_composition_unsupported_residue($contract) {
    my @residue = (
        {
            id     => 'apb_interconnect_multi_peripheral_decode_deferred',
            detail => 'The first APB composition wires one requester to one completer; multi-peripheral address decode and routing remain future APB interconnect work.',
        },
    );

    if (defined($contract->{requester}{response}{status})) {
        # The selected busy+status requester response is surfaced through the top.
    } elsif (defined($contract->{requester}{response}{busy})) {
        push @residue, {
            id     => 'apb_requester_status_field_deferred',
            detail => 'The generated APB composition exposes requester busy, done, read-data, and error; named requester status fields remain future endpoint contract widening.',
        };
    } else {
        push @residue, {
            id     => 'apb_requester_busy_status_deferred',
            detail => 'The generated APB composition exposes the shipped requester response keys done, read-data, and error; requester busy/status output remains a future endpoint contract widening.',
        };
    }

    push @residue, {
        id     => 'apb_multi_register_decode_deferred',
        detail => 'The generated completer endpoint still models one address-0 register and leaves broader register decode to future APB work.',
    } unless _apb_completer_has_multi_registers($contract);

    push @residue, (
        _apb_composition_protection_residue($contract),
        _apb_alternate_widths_residue($contract),
        _fixed_composition_has_back_to_back_policy($contract)
            ? _apb_additional_back_to_back_policies_residue()
            : {
                id     => 'apb_back_to_back_policy_deferred',
                detail => 'Back-to-back transfer policy and queued requester admission remain future exact-owner work.',
            },
    );

    return \@residue;
}

sub _apb_completer_has_multi_registers($contract) {
    return ref($contract->{completer}{storage}{registers}) eq 'ARRAY'
        && @{$contract->{completer}{storage}{registers}} > 1;
}

sub _endpoint_storage_is_selected_sideband_multi_register_timing_shape($storage) {
    return _endpoint_storage_is_selected_multi_register_timing_shape($storage, 4, 32);
}

sub _endpoint_storage_is_selected_sideband_generalized_no_policy_register_set_timing_shape($storage) {
    return _endpoint_storage_is_selected_generalized_no_policy_register_set_timing_shape($storage, 2, 5, 4, 32);
}

sub _endpoint_storage_is_selected_sideband_protection_generalized_register_set_timing_shape($storage) {
    return _endpoint_storage_is_selected_generalized_protection_register_set_timing_shape($storage, 2, 4, 4, 32);
}

sub _endpoint_storage_is_selected_sideband_protection_multi_register_timing_shape($storage) {
    my @registers = _endpoint_storage_registers($storage);
    return 0 unless @registers == 2;
    return 0 unless _endpoint_storage_register_matches_selected_timing_shape($registers[0], 'reg0', 0, 32)
        && _endpoint_storage_register_matches_selected_timing_shape($registers[1], 'reg1', 4, 32);
    return _endpoint_access_policy_is_selected_reg0_protection($registers[0])
        && _endpoint_access_policy_is_selected_reg1_protection($registers[1]);
}

sub _endpoint_storage_is_selected_sideband_protection_multi_peripheral_status_timing_shape($storage) {
    my @registers = _endpoint_storage_registers($storage);
    return 0 unless @registers == 2;
    return 0 unless _endpoint_storage_register_matches_selected_timing_shape($registers[0], 'status_reg', 0, 32)
        && _endpoint_storage_register_matches_selected_timing_shape($registers[1], 'status_shadow_reg', 4, 32);
    return _endpoint_access_policy_is_selected_reg0_protection($registers[0])
        && _endpoint_access_policy_is_selected_reg0_protection($registers[1]);
}

sub _endpoint_storage_is_selected_sideband_protection_multi_peripheral_control_timing_shape($storage) {
    my @registers = _endpoint_storage_registers($storage);
    return 0 unless @registers == 2;
    return 0 unless _endpoint_storage_register_matches_selected_timing_shape($registers[0], 'control_reg', 0, 32)
        && _endpoint_storage_register_matches_selected_timing_shape($registers[1], 'control_shadow_reg', 4, 32);
    return _endpoint_access_policy_is_selected_reg1_protection($registers[0])
        && _endpoint_access_policy_is_selected_reg1_protection($registers[1]);
}

sub _endpoint_storage_is_selected_sideband_data16_multi_register_timing_shape($storage) {
    return _endpoint_storage_is_selected_multi_register_timing_shape($storage, 2, 16);
}

sub _endpoint_storage_is_selected_sideband_data16_generalized_no_policy_register_set_timing_shape($storage) {
    return _endpoint_storage_is_selected_generalized_no_policy_register_set_timing_shape($storage, 2, 5, 2, 16);
}

sub _endpoint_storage_is_selected_sideband_data16_protection_generalized_register_set_timing_shape($storage) {
    return _endpoint_storage_is_selected_generalized_protection_register_set_timing_shape($storage, 2, 4, 2, 16);
}

sub _endpoint_storage_is_selected_sideband_data16_protection_multi_register_timing_shape($storage) {
    my @registers = _endpoint_storage_registers($storage);
    return 0 unless @registers == 2;
    return 0 unless _endpoint_storage_register_matches_selected_timing_shape($registers[0], 'reg0', 0, 16)
        && _endpoint_storage_register_matches_selected_timing_shape($registers[1], 'reg1', 2, 16);
    return _endpoint_access_policy_is_selected_reg0_protection($registers[0])
        && _endpoint_access_policy_is_selected_reg1_protection($registers[1]);
}

sub _endpoint_storage_is_selected_sideband_data16_protection_multi_peripheral_status_timing_shape($storage) {
    my @registers = _endpoint_storage_registers($storage);
    return 0 unless @registers == 2;
    return 0 unless _endpoint_storage_register_matches_selected_timing_shape($registers[0], 'status_reg', 0, 16)
        && _endpoint_storage_register_matches_selected_timing_shape($registers[1], 'status_shadow_reg', 2, 16);
    return _endpoint_access_policy_is_selected_reg0_protection($registers[0])
        && _endpoint_access_policy_is_selected_reg0_protection($registers[1]);
}

sub _endpoint_storage_is_selected_sideband_data16_protection_multi_peripheral_control_timing_shape($storage) {
    my @registers = _endpoint_storage_registers($storage);
    return 0 unless @registers == 2;
    return 0 unless _endpoint_storage_register_matches_selected_timing_shape($registers[0], 'control_reg', 0, 16)
        && _endpoint_storage_register_matches_selected_timing_shape($registers[1], 'control_shadow_reg', 2, 16);
    return _endpoint_access_policy_is_selected_reg1_protection($registers[0])
        && _endpoint_access_policy_is_selected_reg1_protection($registers[1]);
}

sub _multi_peripheral_completers_are_selected_sideband_data16_protection_timing_shape($completers) {
    return 0 unless ref($completers) eq 'ARRAY' && @$completers == 2;
    my $status_count = 0;
    my $control_count = 0;
    for my $completer (@$completers) {
        $status_count++
            if _endpoint_storage_is_selected_sideband_data16_protection_multi_peripheral_status_timing_shape($completer->{storage});
        $control_count++
            if _endpoint_storage_is_selected_sideband_data16_protection_multi_peripheral_control_timing_shape($completer->{storage});
    }
    return $status_count == 1 && $control_count == 1;
}

sub _multi_peripheral_completers_are_selected_sideband_data16_protection_multi_register_timing_shape($completers) {
    return 0 unless ref($completers) eq 'ARRAY' && @$completers == 2;
    return !(grep { !_endpoint_storage_is_selected_sideband_data16_protection_multi_register_timing_shape($_->{storage}) } @$completers);
}

sub _multi_peripheral_completers_are_selected_sideband_protection_multi_register_timing_shape($completers) {
    return 0 unless ref($completers) eq 'ARRAY' && @$completers == 2;
    return !(grep { !_endpoint_storage_is_selected_sideband_protection_multi_register_timing_shape($_->{storage}) } @$completers);
}

sub _multi_peripheral_completers_are_selected_sideband_protection_timing_shape($completers) {
    return 0 unless ref($completers) eq 'ARRAY' && @$completers == 2;
    my $status_count = 0;
    my $control_count = 0;
    for my $completer (@$completers) {
        $status_count++
            if _endpoint_storage_is_selected_sideband_protection_multi_peripheral_status_timing_shape($completer->{storage});
        $control_count++
            if _endpoint_storage_is_selected_sideband_protection_multi_peripheral_control_timing_shape($completer->{storage});
    }
    return $status_count == 1 && $control_count == 1;
}

sub _multi_peripheral_completers_are_selected_sideband_no_policy_multi_register_timing_shape($completers) {
    return 0 unless ref($completers) eq 'ARRAY' && @$completers == 2;
    return !(grep { !_endpoint_storage_is_selected_sideband_multi_register_timing_shape($_->{storage}) } @$completers);
}

sub _multi_peripheral_completers_are_selected_sideband_generalized_no_policy_register_set_timing_shape($completers) {
    return 0 unless ref($completers) eq 'ARRAY' && @$completers == 2;
    return !(grep { !_endpoint_storage_is_selected_sideband_generalized_no_policy_register_set_timing_shape($_->{storage}) } @$completers);
}

sub _multi_peripheral_completers_are_selected_sideband_protection_generalized_register_set_timing_shape($completers) {
    return 0 unless ref($completers) eq 'ARRAY' && @$completers == 2;
    my $expected_count;
    for my $completer (@$completers) {
        return 0 unless _endpoint_storage_is_selected_sideband_protection_generalized_register_set_timing_shape($completer->{storage});
        my @registers = _endpoint_storage_registers($completer->{storage});
        $expected_count //= scalar @registers;
        return 0 unless @registers == $expected_count;
    }
    return 1;
}

sub _multi_peripheral_completers_are_selected_sideband_data16_no_policy_multi_register_timing_shape($completers) {
    return 0 unless ref($completers) eq 'ARRAY' && @$completers == 2;
    return !(grep { !_endpoint_storage_is_selected_sideband_data16_multi_register_timing_shape($_->{storage}) } @$completers);
}

sub _multi_peripheral_completers_are_selected_sideband_data16_generalized_no_policy_register_set_timing_shape($completers) {
    return 0 unless ref($completers) eq 'ARRAY' && @$completers == 2;
    my $expected_count;
    for my $completer (@$completers) {
        return 0 unless _endpoint_storage_is_selected_sideband_data16_generalized_no_policy_register_set_timing_shape($completer->{storage});
        my @registers = _endpoint_storage_registers($completer->{storage});
        $expected_count //= scalar @registers;
        return 0 unless @registers == $expected_count;
    }
    return 1;
}

sub _multi_peripheral_completers_are_selected_sideband_data16_protection_generalized_register_set_timing_shape($completers) {
    return 0 unless ref($completers) eq 'ARRAY' && @$completers == 2;
    my $expected_count;
    for my $completer (@$completers) {
        return 0 unless _endpoint_storage_is_selected_sideband_data16_protection_generalized_register_set_timing_shape($completer->{storage});
        my @registers = _endpoint_storage_registers($completer->{storage});
        $expected_count //= scalar @registers;
        return 0 unless @registers == $expected_count;
    }
    return 1;
}

sub _endpoint_storage_is_selected_multi_register_timing_shape($storage, $reg1_address, $data_width) {
    my @registers = _endpoint_storage_registers($storage);
    return 0 unless @registers == 2;
    return 0 if grep { ref($_) ne 'HASH' || exists $_->{access_policy} } @registers;
    return _endpoint_storage_register_matches_selected_timing_shape($registers[0], 'reg0', 0, $data_width)
        && _endpoint_storage_register_matches_selected_timing_shape($registers[1], 'reg1', $reg1_address, $data_width);
}

sub _endpoint_storage_is_selected_generalized_no_policy_register_set_timing_shape($storage, $minimum_count, $maximum_count, $address_stride, $data_width) {
    my @registers = _endpoint_storage_registers($storage);
    return 0 unless @registers >= $minimum_count && @registers <= $maximum_count;
    return 0 if grep { ref($_) ne 'HASH' || exists $_->{access_policy} } @registers;
    for my $index (0 .. $#registers) {
        return 0 unless _endpoint_storage_register_matches_selected_timing_shape(
            $registers[$index],
            "reg$index",
            $index * $address_stride,
            $data_width,
        );
    }
    return 1;
}

sub _endpoint_storage_is_selected_generalized_protection_register_set_timing_shape($storage, $minimum_count, $maximum_count, $address_stride, $data_width) {
    my @registers = _endpoint_storage_registers($storage);
    return 0 unless @registers >= $minimum_count && @registers <= $maximum_count;
    for my $index (0 .. $#registers) {
        return 0 unless _endpoint_storage_register_matches_selected_timing_shape(
            $registers[$index],
            "reg$index",
            $index * $address_stride,
            $data_width,
        );
        return 0 unless $index == 0
            ? _endpoint_access_policy_is_selected_reg0_protection($registers[$index])
            : _endpoint_access_policy_is_selected_reg1_protection($registers[$index]);
    }
    return 1;
}

sub _endpoint_storage_register_matches_selected_timing_shape($register, $name, $address_value, $data_width) {
    return 0 unless ref($register) eq 'HASH';
    my $address = $register->{address};
    my $data = $register->{data};
    return 0 unless ref($address) eq 'HASH' && ref($data) eq 'HASH';
    return defined($register->{name})
        && !ref($register->{name})
        && $register->{name} eq $name
        && defined($address->{value})
        && !ref($address->{value})
        && $address->{value} == $address_value
        && defined($address->{width})
        && !ref($address->{width})
        && $address->{width} == 32
        && defined($data->{width})
        && !ref($data->{width})
        && $data->{width} == $data_width
        && defined($data->{reset})
        && !ref($data->{reset})
        && $data->{reset} == 0;
}

sub _endpoint_access_policy_is_selected_reg0_protection($register) {
    my $policy = $register->{access_policy};
    return 0 unless ref($policy) eq 'HASH';
    return _endpoint_access_policy_operation_is_allow($policy->{read})
        && _endpoint_access_policy_operation_is_privileged($policy->{write}, 1);
}

sub _endpoint_access_policy_is_selected_reg1_protection($register) {
    my $policy = $register->{access_policy};
    return 0 unless ref($policy) eq 'HASH';
    return _endpoint_access_policy_operation_is_privileged($policy->{read}, 1)
        && _endpoint_access_policy_operation_is_privileged($policy->{write}, 1);
}

sub _endpoint_access_policy_operation_is_allow($operation) {
    return ref($operation) eq 'HASH'
        && ($operation->{action} // '') eq 'allow'
        && !exists($operation->{predicate});
}

sub _endpoint_access_policy_operation_is_privileged($operation, $value) {
    return ref($operation) eq 'HASH'
        && ($operation->{action} // '') eq 'require'
        && ref($operation->{predicate}) eq 'HASH'
        && ($operation->{predicate}{kind} // '') eq 'privileged'
        && defined($operation->{predicate}{value})
        && !ref($operation->{predicate}{value})
        && $operation->{predicate}{value} == $value;
}

sub _composition_has_access_policy($contract) {
    if (_is_multi_peripheral_contract($contract)) {
        for my $completer (@{$contract->{completers} || []}) {
            return 1 if _endpoint_has_access_policy($completer);
        }
        return 0;
    }
    return _endpoint_has_access_policy($contract->{completer});
}

sub _endpoint_has_access_policy($endpoint) {
    my $storage = $endpoint->{storage};
    return 0 unless ref($storage) eq 'HASH';
    for my $register (_endpoint_storage_registers($storage)) {
        return 1 if ref($register->{access_policy}) eq 'HASH';
    }
    return 0;
}

sub _endpoint_storage_registers($storage) {
    return @{$storage->{registers}} if ref($storage->{registers}) eq 'ARRAY';
    return ($storage->{register}) if ref($storage->{register}) eq 'HASH';
    return ();
}

sub _fixed_composition_protection_policy_report($contract, $completer_result) {
    return undef unless ref($completer_result->{report}{protection_policy}) eq 'HASH';
    my $child = $contract->{composition}{children}{completer};
    return {
        enforcement_owner => 'completer',
        composition_role  => 'propagate_pprot_pstrb_and_selected_response_only',
        completer         => {
            instance_name => $child->{instance_name},
            object_name   => $child->{object_name},
        },
        child_policy      => _clone_jsonish($completer_result->{report}{protection_policy}),
    };
}

sub _fixed_composition_has_back_to_back_policy($contract) {
    return _requester_endpoint_has_selected_back_to_back($contract->{requester})
        && _completer_endpoint_has_selected_adjacent_setup($contract->{completer});
}

sub _fixed_composition_back_to_back_policy_report($contract, $requester_result, $completer_result) {
    my $requester_child = $contract->{composition}{children}{requester};
    my $completer_child = $contract->{composition}{children}{completer};
    return {
        composition_role => 'propagate_endpoint_policy',
        requester        => {
            instance_name => $requester_child->{instance_name},
            object_name   => $requester_child->{object_name},
            timing_policy => _clone_jsonish($requester_result->{report}{transfer}{timing_policy}),
        },
        completer        => {
            instance_name => $completer_child->{instance_name},
            object_name   => $completer_child->{object_name},
            timing_policy => _clone_jsonish($completer_result->{report}{transfer}{timing_policy}),
        },
    };
}

sub _apb_additional_back_to_back_policies_residue() {
    return {
        id     => 'apb_additional_back_to_back_policies_deferred',
        detail => join(' ',
            'Selected 32-bit no-sideband depth-1 queued requester and adjacent completer policy propagation is implemented for fixed composition and the bounded two-peripheral interconnect/decode family;',
            'selected 32-bit sideband-aware requester and adjacent completer policy propagation is implemented for fixed composition, selected sideband-aware fixed multi-register composition, selected sideband-aware protected fixed multi-register composition, the bounded two-peripheral interconnect/decode family, and the bounded sideband-aware no-policy two-register two-peripheral composition;',
            'selected bounded 32-bit sideband-aware generalized no-policy reg0..regN register-set requester/completer propagation is implemented for the bounded two-peripheral composition;',
            'selected bounded 32-bit sideband-aware protected generalized reg0..regN register-set requester/completer propagation is implemented for the bounded two-peripheral composition;',
            'selected sideband-aware protection requester and adjacent protected status/control or protected reg0/reg1 two-register peripheral propagation is implemented for bounded two-peripheral composition;',
            'selected sideband-aware data16 requester and adjacent data16 two-register no-policy or protected completer propagation is implemented for fixed composition;',
            'selected sideband-aware data16 requester and adjacent data16 two-register no-policy peripheral propagation is implemented for bounded two-peripheral composition;',
            'selected bounded sideband-aware data16 generalized no-policy reg0..regN register-set requester/completer propagation is implemented for the bounded two-peripheral composition;',
            'selected sideband-aware data16-protection requester and adjacent protected status/control or protected reg0/reg1 two-register peripheral propagation is implemented for bounded two-peripheral composition;',
            'selected sideband-aware data16 protected generalized requester and adjacent protected reg0..regN peripheral propagation is implemented for bounded two-peripheral composition;',
            'selected status/control protected storage is complete for the bounded 32-bit and data16 two-peripheral families;',
            'broader cardinality multi-peripheral multi-register timing beyond the selected bounded families, deeper queues, alternate overflow policies, accepted-less requester timing, multiple active APB transfers, bus matrices, scoreboards, direct backend lowering, verification-output, backend-language variants, AXI, AHB, and VHDL remain future work.',
        ),
    };
}

sub _multi_peripheral_has_back_to_back_policy($contract) {
    return 0 unless _is_multi_peripheral_contract($contract);
    return 0 unless _requester_endpoint_has_selected_back_to_back($contract->{requester});
    my $completers = $contract->{completers} || [];
    return 0 unless @$completers;
    return !(grep { !_completer_endpoint_has_selected_adjacent_setup($_) } @$completers);
}

sub _multi_peripheral_back_to_back_policy_report($contract, $requester_result, $peripheral_results, $interconnect) {
    my $requester_child = $contract->{composition}{children}{requester};
    return {
        composition_role => 'propagate_endpoint_policy_through_interconnect',
        requester        => {
            instance_name => $requester_child->{instance_name},
            object_name   => $requester_child->{object_name},
            timing_policy => _clone_jsonish($requester_result->{report}{transfer}{timing_policy}),
        },
        interconnect     => {
            instance_name => $interconnect->{instance_name},
            object_name   => $interconnect->{object_name},
            timing_role   => 'propagate_queued_setup_without_idle_cycle',
            setup_decode  => 'current_psel_paddr_with_penable_low',
            response_mux  => 'selected_peripheral_response',
            unmapped_policy  => 'active_access_only',
        },
        peripherals      => [
            map {
                {
                    instance_name           => $_->{child}{instance_name},
                    generated_instance_name => _generated_instance_name($_->{child}),
                    object_name             => $_->{child}{object_name},
                    timing_policy           => _clone_jsonish($_->{result}{report}{transfer}{timing_policy}),
                }
            } @$peripheral_results
        ],
    };
}

sub _multi_peripheral_protection_policy_report($peripheral_results) {
    my @peripherals;
    for my $entry (@$peripheral_results) {
        my $policy = $entry->{result}{report}{protection_policy};
        next unless ref($policy) eq 'HASH';
        push @peripherals, {
            instance_name           => $entry->{child}{instance_name},
            generated_instance_name => _generated_instance_name($entry->{child}),
            object_name             => $entry->{child}{object_name},
            child_policy            => _clone_jsonish($policy),
        };
    }
    return undef unless @peripherals;
    return {
        enforcement_owner => 'peripheral_completers',
        interconnect_role => 'propagate_pprot_pstrb_and_mux_selected_response_only',
        peripherals       => \@peripherals,
    };
}

sub _child_report($role, $child, $result) {
    my $report = {
        role                => $role,
        instance_name       => $child->{instance_name},
        object_name         => $child->{object_name},
        source_object       => _clone_jsonish($result->{report}{source_object}),
        target_protocol     => _clone_jsonish($result->{report}{target_protocol}),
        bindings            => _clone_jsonish($result->{report}{bindings}),
        transfer            => _clone_jsonish($result->{report}{transfer}),
        generated_artifacts => _clone_jsonish($result->{report}{generated_artifacts}),
        unsupported_residue => _clone_jsonish($result->{report}{unsupported_residue}),
    };
    $report->{generated_instance_name} = _generated_instance_name($child)
        if defined $child->{generated_instance_name};
    $report->{response_status_field} = _clone_jsonish($result->{report}{response_status_field})
        if defined $result->{report}{response_status_field};
    $report->{response_accepted_field} = _clone_jsonish($result->{report}{response_accepted_field})
        if defined $result->{report}{response_accepted_field};
    $report->{protection_policy} = _clone_jsonish($result->{report}{protection_policy})
        if defined $result->{report}{protection_policy};

    return $report;
}

sub _normalize_children($raw) {
    my $requester = _required_hash($raw, 'requester');
    my $completer = _required_hash($raw, 'completer');
    return {
        requester => _normalize_child($requester, 'requester'),
        completer => _normalize_child($completer, 'completer'),
    };
}

sub _normalize_multi_peripheral_children($raw) {
    confess "APB multi-peripheral composition cannot mix fixed completer and peripheral children\n"
        if exists $raw->{completer};

    my $requester = _required_hash($raw, 'requester');
    my $peripherals = $raw->{peripherals};
    confess "APB multi-peripheral composition requires two or more peripheral children\n"
        unless ref($peripherals) eq 'ARRAY' && @$peripherals >= 2;

    my (@normalized, %instance_names, %object_names);
    for my $index (0 .. $#$peripherals) {
        my $child = $peripherals->[$index];
        confess "APB multi-peripheral composition peripheral[$index] must be a child hash reference\n"
            unless ref($child) eq 'HASH';
        my $normalized = _normalize_child($child, 'peripheral');
        confess "APB multi-peripheral composition duplicate peripheral instance '$normalized->{instance_name}'\n"
            if $instance_names{$normalized->{instance_name}}++;
        confess "APB multi-peripheral composition duplicate peripheral object '$normalized->{object_name}'\n"
            if $object_names{$normalized->{object_name}}++;
        push @normalized, $normalized;
    }

    my $requester_child = _normalize_child($requester, 'requester');
    confess "APB multi-peripheral composition child instance aliases must be unique\n"
        if $instance_names{$requester_child->{instance_name}};

    return {
        requester   => $requester_child,
        peripherals => \@normalized,
    };
}

sub _normalize_child($raw, $role) {
    return {
        instance_name => _required_identifier($raw, 'instance_name'),
        object_name   => _required_identifier($raw, 'object_name'),
        role          => $role,
    };
}

sub _normalize_wiring($raw) {
    my $name = _required_identifier($raw, 'name');
    my $bus = _required_hash($raw, 'bus');
    return {
        name => $name,
        bus  => _clone_jsonish($bus),
    };
}

sub _normalize_address_map($raw, $peripherals, $alignment_bytes) {
    my $name = _required_identifier($raw, 'name');
    my $windows = $raw->{windows};
    confess "APB multi-peripheral composition address_map.windows must be a non-empty array reference\n"
        unless ref($windows) eq 'ARRAY' && @$windows;

    my %peripheral_instances = map { $_->{instance_name} => 1 } @$peripherals;
    my (@normalized, %window_names, %parameter_names);
    for my $index (0 .. $#$windows) {
        my $window = $windows->[$index];
        confess "APB multi-peripheral composition address_map.windows[$index] must be a hash reference\n"
            unless ref($window) eq 'HASH';
        my $window_name = _required_identifier($window, 'name');
        confess "APB multi-peripheral composition duplicate address-map window '$window_name'\n"
            if $window_names{$window_name}++;
        confess "APB multi-peripheral composition address-map window '$window_name' does not match a peripheral child instance\n"
            unless $peripheral_instances{$window_name};
        my $base = _normalize_address_parameter($window->{base}, "address_map.windows[$index].base", 1);
        my $size = _normalize_address_parameter($window->{size}, "address_map.windows[$index].size", 0);
        for my $parameter ($base, $size) {
            confess "APB multi-peripheral composition duplicate address-map parameter '$parameter->{name}'\n"
                if $parameter_names{$parameter->{name}}++;
        }
        confess "APB multi-peripheral composition address-map base '$base->{default}' must be $alignment_bytes-byte aligned\n"
            unless $base->{default} % $alignment_bytes == 0;
        confess "APB multi-peripheral composition address-map size '$size->{default}' must be positive and $alignment_bytes-byte-sized\n"
            unless $size->{default} > 0 && $size->{default} % $alignment_bytes == 0;
        confess "APB multi-peripheral composition address-map window '$window_name' overflows 32-bit address space\n"
            if $base->{default} + $size->{default} > 4_294_967_296;
        push @normalized, {
            name  => $window_name,
            base  => $base,
            size  => $size,
            limit => $base->{default} + $size->{default},
        };
    }

    for my $peripheral (@$peripherals) {
        confess "APB multi-peripheral composition address-map is missing a window for peripheral '$peripheral->{instance_name}'\n"
            unless $window_names{$peripheral->{instance_name}};
    }
    _validate_nonoverlapping_windows(@normalized);

    return {
        name          => $name,
        address_width => 32,
        alignment_bytes => $alignment_bytes,
        windows       => \@normalized,
    };
}

sub _normalize_address_parameter($raw, $field, $allow_zero) {
    confess "APB multi-peripheral composition $field must be a parameter/width/default hash reference\n"
        unless ref($raw) eq 'HASH';
    my $name = _identifier_value($raw->{name}, "$field.name");
    my $width = _positive_integer($raw->{width}, "$field.width");
    confess "APB multi-peripheral composition $field.width must be 32 in this slice\n"
        unless $width == 32;
    my $default = _nonnegative_integer($raw->{default}, "$field.default");
    confess "APB multi-peripheral composition $field.default must be positive in this slice\n"
        if !$allow_zero && $default == 0;
    confess "APB multi-peripheral composition $field.default must fit in 32 bits in this slice\n"
        if $default > 0xffffffff;
    return {
        name    => $name,
        width   => $width,
        default => $default,
    };
}

sub _validate_nonoverlapping_windows(@windows) {
    for my $left_index (0 .. $#windows) {
        my $left = $windows[$left_index];
        for my $right_index ($left_index + 1 .. $#windows) {
            my $right = $windows[$right_index];
            my $overlaps = $left->{base}{default} < $right->{limit}
                && $right->{base}{default} < $left->{limit};
            confess "APB multi-peripheral composition address-map windows '$left->{name}' and '$right->{name}' overlap\n"
                if $overlaps;
        }
    }
}

sub _normalize_decode($raw) {
    my $overlap = _nonempty_scalar($raw->{overlap}, 'decode.overlap');
    my $priority = _nonempty_scalar($raw->{priority}, 'decode.priority');
    my $unmapped_address = _nonempty_scalar($raw->{unmapped_address}, 'decode.unmapped_address');
    confess "APB multi-peripheral composition decode.overlap must be reject in this slice\n"
        unless $overlap eq 'reject';
    confess "APB multi-peripheral composition decode.priority must be source-order in this slice\n"
        unless $priority eq 'source-order';
    confess "APB multi-peripheral composition decode.unmapped_address must be error in this slice\n"
        unless $unmapped_address eq 'error';
    return {
        overlap          => $overlap,
        priority         => $priority,
        unmapped_address => $unmapped_address,
    };
}

sub _validate_endpoint_role($endpoint, $role, $kind) {
    confess "APB composition IAL2 contract requires $role endpoint kind $kind\n"
        unless ($endpoint->{kind} // '') eq $kind;
    confess "APB composition IAL2 contract requires endpoint '$endpoint->{name}' role $role\n"
        unless lc($endpoint->{role} // '') eq $role;
}

sub _validate_shared_system_ports($clock, $reset, $requester, $completer) {
    for my $entry (
        ['requester', $requester],
        ['completer', $completer],
    ) {
        my ($role, $endpoint) = @$entry;
        confess "APB composition IAL2 contract requires shared clock '$clock'; $role uses '$endpoint->{clock}'\n"
            unless ($endpoint->{clock} // '') eq $clock;
        confess "APB composition IAL2 contract requires shared reset '$reset->{signal}'; $role has incompatible reset policy\n"
            unless _same_reset_policy($reset, $endpoint->{reset});
    }
}

sub _same_reset_policy($left, $right) {
    return 0 unless ref($left) eq 'HASH' && ref($right) eq 'HASH';
    for my $field (qw(signal active_low async)) {
        return 0 unless defined($left->{$field}) && defined($right->{$field});
        return 0 unless $left->{$field} eq $right->{$field};
    }
    return 1;
}

sub _validate_child_references($children, $requester, $completer) {
    confess "APB composition requester child references '$children->{requester}{object_name}', expected '$requester->{name}'\n"
        unless $children->{requester}{object_name} eq $requester->{name};
    confess "APB composition completer child references '$children->{completer}{object_name}', expected '$completer->{name}'\n"
        unless $children->{completer}{object_name} eq $completer->{name};
    confess "APB composition child instance aliases must be unique\n"
        if $children->{requester}{instance_name} eq $children->{completer}{instance_name};
}

sub _validate_bus_compatibility($wiring, $requester_bus, $completer_bus) {
    for my $field (qw(select enable write ready error)) {
        _require_matching_scalar_bus_field($field, $wiring, $requester_bus, $completer_bus);
    }
    for my $field (qw(address write_data read_data)) {
        _require_matching_width_bus_field($field, $wiring, $requester_bus, $completer_bus);
    }
    _validate_fixed_sideband_compatibility($wiring, $requester_bus, $completer_bus);
}

sub _validate_fixed_timing_policy_compatibility($wiring, $requester, $completer) {
    my $requester_policy = _endpoint_has_timing_policy($requester);
    my $completer_policy = _endpoint_has_timing_policy($completer);
    return unless $requester_policy || $completer_policy;

    confess "APB fixed composition selected back-to-back timing-policy requires requester back-to-back queued queue-depth 1 overflow reject and completer setup-admission adjacent in this slice\n"
        unless _requester_endpoint_has_selected_back_to_back($requester)
            && _completer_endpoint_has_selected_adjacent_setup($completer);

    my $is_no_sideband_family = _is_selected_no_sideband_timing_bus($wiring)
        && _is_selected_no_sideband_timing_bus($requester->{bus})
        && _is_selected_no_sideband_timing_bus($completer->{bus});
    my $is_sideband_family = _is_selected_sideband_timing_bus($wiring)
        && _is_selected_sideband_timing_bus($requester->{bus})
        && _is_selected_sideband_timing_bus($completer->{bus});
    my $is_sideband_data16_family = _is_selected_sideband_data16_timing_bus($wiring)
        && _is_selected_sideband_data16_timing_bus($requester->{bus})
        && _is_selected_sideband_data16_timing_bus($completer->{bus});
    confess "APB fixed composition selected back-to-back timing-policy supports only 32-bit no-sideband, selected 32-bit sideband-aware, or selected sideband-aware data16 APB wiring in this slice\n"
        unless $is_no_sideband_family || $is_sideband_family || $is_sideband_data16_family;

    confess "APB fixed composition selected back-to-back timing-policy supports only one-register completer storage, selected 32-bit sideband-aware two-register no-policy completer storage, selected 32-bit sideband-aware two-register protection completer storage, selected sideband-aware data16 two-register no-policy completer storage, or selected sideband-aware data16 two-register protection completer storage in this slice\n"
        if ref($completer->{storage}{registers}) eq 'ARRAY'
            && !($is_sideband_family && _endpoint_storage_is_selected_sideband_multi_register_timing_shape($completer->{storage}))
            && !($is_sideband_family && _endpoint_storage_is_selected_sideband_protection_multi_register_timing_shape($completer->{storage}))
            && !($is_sideband_data16_family && _endpoint_storage_is_selected_sideband_data16_multi_register_timing_shape($completer->{storage}))
            && !($is_sideband_data16_family && _endpoint_storage_is_selected_sideband_data16_protection_multi_register_timing_shape($completer->{storage}));
}

sub _is_selected_no_sideband_timing_bus($bus) {
    return $bus->{write_data}{width} == 32
        && $bus->{read_data}{width} == 32
        && !_bus_has_sidebands($bus);
}

sub _is_selected_sideband_timing_bus($bus) {
    return $bus->{write_data}{width} == 32
        && $bus->{read_data}{width} == 32
        && _bus_has_sidebands($bus)
        && $bus->{protection}{width} == 3
        && $bus->{strobe}{width} == 4;
}

sub _is_selected_sideband_data16_timing_bus($bus) {
    return $bus->{write_data}{width} == 16
        && $bus->{read_data}{width} == 16
        && _bus_has_sidebands($bus)
        && $bus->{protection}{width} == 3
        && $bus->{strobe}{width} == 2;
}

sub _request_has_selected_sideband_timing_fields($requester) {
    return _request_has_selected_sideband_timing_fields_with_strobe($requester, 4);
}

sub _request_has_selected_sideband_data16_timing_fields($requester) {
    return _request_has_selected_sideband_timing_fields_with_strobe($requester, 2);
}

sub _request_has_selected_sideband_timing_fields_with_strobe($requester, $strobe_width) {
    return ref($requester->{request}{protection}) eq 'HASH'
        && ref($requester->{request}{write_strobe}) eq 'HASH'
        && ($requester->{request}{protection}{width} // '') eq '3'
        && ($requester->{request}{write_strobe}{width} // '') eq "$strobe_width";
}

sub _validate_multi_peripheral_timing_policy_compatibility($wiring, $children, $requester, $completers) {
    my $has_policy = _endpoint_has_timing_policy($requester)
        || grep { _endpoint_has_timing_policy($_) } @$completers;
    return unless $has_policy;

    confess "APB multi-peripheral selected back-to-back timing-policy requires requester back-to-back queued queue-depth 1 overflow reject and every peripheral completer setup-admission adjacent in this slice\n"
        unless _requester_endpoint_has_selected_back_to_back($requester)
            && !(grep { !_completer_endpoint_has_selected_adjacent_setup($_) } @$completers);

    confess "APB multi-peripheral selected back-to-back timing-policy supports only two peripheral completers in this slice\n"
        unless @$completers == 2
            && @{$children->{peripherals}} == 2;

    my $is_no_sideband_family = _is_selected_no_sideband_timing_bus($wiring)
        && _is_selected_no_sideband_timing_bus($requester->{bus})
        && !_request_has_sidebands($requester)
        && !(grep { !_is_selected_no_sideband_timing_bus($_->{bus}) } @$completers);
    my $is_sideband_family = _is_selected_sideband_timing_bus($wiring)
        && _is_selected_sideband_timing_bus($requester->{bus})
        && _request_has_selected_sideband_timing_fields($requester)
        && !(grep { !_is_selected_sideband_timing_bus($_->{bus}) } @$completers);
    my $is_sideband_data16_family = _is_selected_sideband_data16_timing_bus($wiring)
        && _is_selected_sideband_data16_timing_bus($requester->{bus})
        && _request_has_selected_sideband_data16_timing_fields($requester)
        && !(grep { !_is_selected_sideband_data16_timing_bus($_->{bus}) } @$completers);
    confess "APB multi-peripheral selected back-to-back timing-policy supports only 32-bit no-sideband, selected 32-bit sideband-aware, or selected sideband-aware data16 APB wiring in this slice\n"
        unless $is_no_sideband_family || $is_sideband_family || $is_sideband_data16_family;

    if ($is_sideband_family && _multi_peripheral_completers_are_selected_sideband_no_policy_multi_register_timing_shape($completers)) {
        return;
    } elsif ($is_sideband_family && _multi_peripheral_completers_are_selected_sideband_generalized_no_policy_register_set_timing_shape($completers)) {
        return;
    } elsif ($is_sideband_family && _multi_peripheral_completers_are_selected_sideband_protection_generalized_register_set_timing_shape($completers)) {
        return;
    } elsif ($is_sideband_family && _multi_peripheral_completers_are_selected_sideband_protection_multi_register_timing_shape($completers)) {
        return;
    } elsif ($is_sideband_family && _multi_peripheral_completers_are_selected_sideband_protection_timing_shape($completers)) {
        return;
    } elsif ($is_sideband_data16_family) {
        return
            if _multi_peripheral_completers_are_selected_sideband_data16_no_policy_multi_register_timing_shape($completers);
        return
            if _multi_peripheral_completers_are_selected_sideband_data16_generalized_no_policy_register_set_timing_shape($completers);
        return
            if _multi_peripheral_completers_are_selected_sideband_data16_protection_generalized_register_set_timing_shape($completers);
        return
            if _multi_peripheral_completers_are_selected_sideband_data16_protection_multi_register_timing_shape($completers);
        return
            if _multi_peripheral_completers_are_selected_sideband_data16_protection_timing_shape($completers);
        confess "APB multi-peripheral selected back-to-back timing-policy supports only the selected two-peripheral sideband data16 no-policy reg0/reg1 storage shape, the selected bounded two-peripheral sideband data16 generalized no-policy reg0..regN register-set storage shape, the selected two-peripheral sideband data16 protection reg0/reg1 storage shape, the selected bounded two-peripheral sideband data16 protected generalized reg0..regN register-set storage shape, or the selected two-peripheral sideband data16 protection status/control storage shape in this slice\n";
    } else {
        confess "APB multi-peripheral selected back-to-back timing-policy supports only one-register peripheral completer storage, the selected two-peripheral sideband no-policy reg0/reg1 storage shape, the selected bounded two-peripheral sideband generalized no-policy reg0..regN register-set storage shape, the selected bounded two-peripheral sideband protected generalized reg0..regN register-set storage shape, the selected two-peripheral sideband protection reg0/reg1 storage shape, or the selected two-peripheral sideband protection status/control storage shape in this slice\n"
            if grep {
                my @registers = _endpoint_storage_registers($_->{storage});
                @registers != 1;
            } @$completers;
    }
}

sub _endpoint_has_timing_policy($endpoint) {
    return ref($endpoint->{transfer}) eq 'HASH'
        && ref($endpoint->{transfer}{timing_policy}) eq 'HASH';
}

sub _requester_endpoint_has_selected_back_to_back($requester) {
    my $policy = ref($requester->{transfer}) eq 'HASH' ? $requester->{transfer}{timing_policy} : undef;
    return 0 unless ref($policy) eq 'HASH';
    return ($policy->{back_to_back} // '') eq 'queued'
        && ($policy->{queue_depth} // '') eq '1'
        && ($policy->{overflow} // '') eq 'reject'
        && defined($requester->{response}{accepted})
        && defined($requester->{response}{busy})
        && ref($requester->{response}{status}) eq 'HASH'
        && ($requester->{response}{status}{width} // '') eq '2';
}

sub _completer_endpoint_has_selected_adjacent_setup($completer) {
    my $policy = ref($completer->{transfer}) eq 'HASH' ? $completer->{transfer}{timing_policy} : undef;
    return 0 unless ref($policy) eq 'HASH';
    return ($policy->{setup_admission} // '') eq 'adjacent';
}

sub _validate_multi_peripheral_completers($completers) {
    my %names;
    for my $index (0 .. $#$completers) {
        my $completer = $completers->[$index];
        confess "APB multi-peripheral composition completers[$index] must be a hash reference\n"
            unless ref($completer) eq 'HASH';
        _validate_endpoint_role($completer, 'completer', 'apb_completer');
        my $name = _required_identifier($completer, 'name');
        confess "APB multi-peripheral composition duplicate APB completer object '$name'\n"
            if $names{$name}++;
    }
}

sub _validate_multi_shared_system_ports($clock, $reset, $requester, $completers) {
    _validate_endpoint_shared_system_port($clock, $reset, 'requester', $requester);
    for my $completer (@$completers) {
        _validate_endpoint_shared_system_port($clock, $reset, "peripheral '$completer->{name}'", $completer);
    }
}

sub _validate_endpoint_shared_system_port($clock, $reset, $role, $endpoint) {
    confess "APB composition IAL2 contract requires shared clock '$clock'; $role uses '$endpoint->{clock}'\n"
        unless ($endpoint->{clock} // '') eq $clock;
    confess "APB composition IAL2 contract requires shared reset '$reset->{signal}'; $role has incompatible reset policy\n"
        unless _same_reset_policy($reset, $endpoint->{reset});
}

sub _validate_multi_child_references($children, $requester, $completers) {
    confess "APB composition requester child references '$children->{requester}{object_name}', expected '$requester->{name}'\n"
        unless $children->{requester}{object_name} eq $requester->{name};

    my %completer_by_name = map { $_->{name} => $_ } @$completers;
    my %referenced;
    for my $peripheral (@{$children->{peripherals}}) {
        confess "APB multi-peripheral composition peripheral child '$peripheral->{instance_name}' references unknown APB completer object '$peripheral->{object_name}'\n"
            unless exists $completer_by_name{$peripheral->{object_name}};
        $referenced{$peripheral->{object_name}}++;
    }
    for my $completer (@$completers) {
        confess "APB multi-peripheral composition APB completer object '$completer->{name}' is not referenced by a peripheral child\n"
            unless $referenced{$completer->{name}};
    }
}

sub _validate_multi_bus_compatibility($wiring, $requester_bus, $completers) {
    for my $field (qw(select enable write ready error)) {
        _require_matching_scalar_bus_field($field, $wiring, $requester_bus);
    }
    for my $field (qw(address write_data read_data)) {
        _require_matching_width_bus_field($field, $wiring, $requester_bus);
    }
    _validate_multi_sideband_compatibility($wiring, $requester_bus, $completers);
    for my $completer (@$completers) {
        for my $field (qw(address write_data read_data)) {
            my $expected_width = $wiring->{$field}{width};
            confess "APB multi-peripheral composition peripheral '$completer->{name}' bus.$field width must be $expected_width\n"
                unless ref($completer->{bus}{$field}) eq 'HASH'
                    && ($completer->{bus}{$field}{width} // '') eq $expected_width;
        }
    }
}

sub _validate_multi_signal_uniqueness($clock, $reset, $requester, $completers) {
    my %seen;
    for my $name (
        $requester->{request}{start},
        $requester->{request}{write},
        $requester->{request}{address}{name},
        $requester->{request}{write_data}{name},
        (defined($requester->{request}{protection}) ? ($requester->{request}{protection}{name}) : ()),
        (defined($requester->{request}{write_strobe}) ? ($requester->{request}{write_strobe}{name}) : ()),
        (defined($requester->{response}{accepted}) ? ($requester->{response}{accepted}) : ()),
        (defined($requester->{response}{busy}) ? ($requester->{response}{busy}) : ()),
        (defined($requester->{response}{status}) ? ($requester->{response}{status}{name}) : ()),
        $requester->{response}{done},
        $requester->{response}{read_data}{name},
        $requester->{response}{error},
        $requester->{bus}{select},
        $requester->{bus}{enable},
        $requester->{bus}{write},
        $requester->{bus}{address}{name},
        $requester->{bus}{write_data}{name},
        (defined($requester->{bus}{protection}) ? ($requester->{bus}{protection}{name}) : ()),
        (defined($requester->{bus}{strobe}) ? ($requester->{bus}{strobe}{name}) : ()),
        $requester->{bus}{ready},
        $requester->{bus}{read_data}{name},
        $requester->{bus}{error},
        map {
            (
                $_->{control}{wait_cycles}{name},
                $_->{bus}{select},
                $_->{bus}{enable},
                $_->{bus}{write},
                $_->{bus}{address}{name},
                $_->{bus}{write_data}{name},
                (defined($_->{bus}{protection}) ? ($_->{bus}{protection}{name}) : ()),
                (defined($_->{bus}{strobe}) ? ($_->{bus}{strobe}{name}) : ()),
                $_->{bus}{ready},
                $_->{bus}{read_data}{name},
                $_->{bus}{error},
            )
        } @$completers,
    ) {
        next if !defined($name) || $name eq $clock || $name eq $reset->{signal};
        confess "APB multi-peripheral composition duplicates top, APB bus, or peripheral signal '$name'\n"
            if $seen{$name}++;
    }
}

sub _validate_fixed_sideband_compatibility($wiring, $requester_bus, $completer_bus) {
    my $sideband_present = grep { _bus_declares_any_sideband($_) } ($wiring, $requester_bus, $completer_bus);
    return unless $sideband_present;

    for my $bus_name (
        ['composition wiring', $wiring],
        ['requester', $requester_bus],
        ['completer', $completer_bus],
    ) {
        my ($label, $bus) = @$bus_name;
        confess "APB composition IAL2 contract $label bus must declare protection and strobe together in this slice\n"
            unless _bus_has_sidebands($bus);
    }

    for my $field (qw(protection strobe)) {
        _require_matching_width_bus_field($field, $wiring, $requester_bus, $completer_bus);
    }
}

sub _validate_multi_sideband_compatibility($wiring, $requester_bus, $completers) {
    my $sideband_present = _bus_declares_any_sideband($wiring)
        || _bus_declares_any_sideband($requester_bus)
        || grep { _bus_declares_any_sideband($_->{bus}) } @$completers;
    return unless $sideband_present;

    for my $bus_name (
        ['composition wiring', $wiring],
        ['requester', $requester_bus],
    ) {
        my ($label, $bus) = @$bus_name;
        confess "APB multi-peripheral composition IAL2 contract $label bus must declare protection and strobe together in this slice\n"
            unless _bus_has_sidebands($bus);
    }
    for my $field (qw(protection strobe)) {
        _require_matching_width_bus_field($field, $wiring, $requester_bus);
    }

    for my $completer (@$completers) {
        confess "APB multi-peripheral composition peripheral '$completer->{name}' bus must declare protection and strobe together in this slice\n"
            unless _bus_has_sidebands($completer->{bus});
        for my $field (qw(protection strobe)) {
            my $expected_width = $wiring->{$field}{width};
            confess "APB multi-peripheral composition peripheral '$completer->{name}' bus.$field width must be $expected_width\n"
                unless ref($completer->{bus}{$field}) eq 'HASH'
                    && ($completer->{bus}{$field}{width} // '') eq $expected_width;
        }
    }
}

sub _bus_declares_any_sideband($bus) {
    return defined($bus->{protection}) || defined($bus->{strobe});
}

sub _require_matching_scalar_bus_field($field, @buses) {
    my $expected = $buses[0]->{$field};
    for my $bus (@buses) {
        confess "APB composition IAL2 contract bus.$field must be scalar signal '$expected'\n"
            unless defined($bus->{$field}) && !ref($bus->{$field}) && $bus->{$field} eq $expected;
    }
}

sub _require_matching_width_bus_field($field, @buses) {
    my $expected = $buses[0]->{$field};
    confess "APB composition IAL2 contract bus.$field must be a signal/width binding\n"
        unless ref($expected) eq 'HASH';
    for my $bus (@buses) {
        confess "APB composition IAL2 contract bus.$field must match signal '$expected->{name}' width '$expected->{width}'\n"
            unless ref($bus->{$field}) eq 'HASH'
                && ($bus->{$field}{name} // '') eq $expected->{name}
                && ($bus->{$field}{width} // '') eq $expected->{width};
    }
}

sub _normalize_reset($raw_reset, $field) {
    confess "APB composition IAL2 contract is missing required $field binding\n"
        unless defined $raw_reset && ref($raw_reset) eq 'HASH';

    my $reset = {
        signal     => _identifier_value($raw_reset->{signal}, "$field.signal"),
        active_low => _bool_value($raw_reset->{active_low}, "$field.active_low"),
        async      => _bool_value($raw_reset->{async}, "$field.async"),
    };
    confess "APB composition IAL2 contract $field must be active_low async in this slice\n"
        unless $reset->{active_low} && $reset->{async};

    return $reset;
}

sub _normalize_source_anchors($anchors) {
    confess "APB composition IAL2 contract source.anchors must be an array reference\n"
        unless ref($anchors) eq 'ARRAY';

    my @normalized;
    for my $index (0 .. $#$anchors) {
        my $anchor = $anchors->[$index];
        confess "APB composition IAL2 contract source.anchors[$index] must be a hash reference\n"
            unless ref($anchor) eq 'HASH';
        my %copy;
        for my $key (sort keys %$anchor) {
            $copy{$key} = _nonempty_scalar($anchor->{$key}, "source.anchors[$index].$key");
        }
        push @normalized, \%copy;
    }

    return \@normalized;
}

sub _required_hash($raw, $field) {
    confess "APB composition IAL2 contract is missing required hash field '$field'\n"
        unless exists $raw->{$field} && ref($raw->{$field}) eq 'HASH';
    return $raw->{$field};
}

sub _required_scalar($raw, $field) {
    confess "APB composition IAL2 contract is missing required scalar field '$field'\n"
        unless exists($raw->{$field});
    return _nonempty_scalar($raw->{$field}, $field);
}

sub _required_identifier($raw, $field) {
    return _identifier_value($raw->{$field}, $field);
}

sub _identifier_value($value, $field) {
    my $text = _nonempty_scalar($value, $field);
    confess "APB composition IAL2 contract $field must be an HDL identifier\n"
        unless $text =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
    return $text;
}

sub _nonempty_scalar($value, $field) {
    confess "APB composition IAL2 contract $field must be a non-empty scalar\n"
        if !defined($value) || ref($value) || $value eq '';
    return $value;
}

sub _positive_integer($value, $field) {
    confess "APB composition IAL2 contract $field must be a positive integer\n"
        if !defined($value) || ref($value) || $value !~ /\A[1-9][0-9]*\z/;
    return int($value);
}

sub _nonnegative_integer($value, $field) {
    confess "APB composition IAL2 contract $field must be a non-negative integer\n"
        if !defined($value) || ref($value) || $value !~ /\A(?:0|[1-9][0-9]*)\z/;
    return int($value);
}

sub _bool_value($value, $field) {
    confess "APB composition IAL2 contract $field must be boolean 0 or 1\n"
        if !defined($value) || ref($value) || $value !~ /\A[01]\z/;
    return $value ? 1 : 0;
}

sub _clone_jsonish($value) {
    return undef unless defined $value;
    return [map { _clone_jsonish($_) } @$value] if ref($value) eq 'ARRAY';
    return { map { $_ => _clone_jsonish($value->{$_}) } sort keys %$value } if ref($value) eq 'HASH';
    return $value;
}

1;
