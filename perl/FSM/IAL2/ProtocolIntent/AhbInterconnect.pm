package FSM::IAL2::ProtocolIntent::AhbInterconnect;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use JSON::PP ();
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::IAL2::ProtocolIntent::AhbRequester;
use FSM::IAL2::ProtocolIntent::AhbSubordinate;

sub new($class, @constructor_args) {
    _validate_constructor_receiver($class);
    my %args = _validate_constructor_args($class, @constructor_args);

    return bless {
        debug => $args{debug} // 0,
    }, $class;
}

sub generate($self, @args) {
    _validate_object_receiver($self, 'generate');
    confess "FSM::IAL2::ProtocolIntent::AhbInterconnect->generate expects exactly one contract hash reference\n"
        unless @args == 1 && ref($args[0]) eq 'HASH';

    my $contract = _normalize_contract($args[0]);
    my $requester_contract = _endpoint_contract($contract, 'requester');
    my @subordinate_contracts = map {
        _endpoint_contract_from_hash($contract, $_)
    } @{$contract->{subordinates}};

    my $requester_result = FSM::IAL2::ProtocolIntent::AhbRequester
        ->new(debug => $self->{debug})
        ->generate($requester_contract);
    my @subordinate_results = map {
        FSM::IAL2::ProtocolIntent::AhbSubordinate
            ->new(debug => $self->{debug})
            ->generate($_)
    } @subordinate_contracts;

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
    for my $index (0 .. $#subordinate_results) {
        _add_endpoint_result(
            result           => $subordinate_results[$index],
            role             => 'subordinate',
            object_name      => $contract->{subordinates}[$index]{name},
            ial1_items       => \@ial1_items,
            ial0_items       => \@ial0_items,
            schedule_reports => \@schedule_reports,
            fsm_files        => \%all_fsm_files,
        );
    }

    my $interconnect = _build_ahb_interconnect_artifacts($contract);
    push @ial1_items, $interconnect->{ial1_item};
    confess "Error: AHB interconnect generated duplicate .fsm artifact '$interconnect->{entry_artifact}'\n"
        if exists $all_fsm_files{$interconnect->{entry_artifact}};
    $all_fsm_files{$interconnect->{entry_artifact}} = $interconnect->{fsm_text};
    push @ial0_items, $interconnect->{ial0_item};

    my $top = _build_composition_top(
        contract           => $contract,
        requester_result   => $requester_result,
        subordinate_results => \@subordinate_results,
        interconnect       => $interconnect,
        fsm_files          => \%all_fsm_files,
    );
    confess "Error: AHB interconnect generated duplicate .fsm artifact '$top->{entry_artifact}'\n"
        if exists $all_fsm_files{$top->{entry_artifact}};
    $all_fsm_files{$top->{entry_artifact}} = $top->{text};
    push @ial0_items, $top->{ial0_item};

    my $report = _build_report(
        contract           => $contract,
        requester_result   => $requester_result,
        subordinate_results => \@subordinate_results,
        interconnect       => $interconnect,
        ial1_items         => \@ial1_items,
        ial0_items         => \@ial0_items,
        hdl_entry          => $top->{report_entry},
        fsm_files          => \%all_fsm_files,
    );

    return {
        layer => 'IAL2',
        kind  => 'protocol_intent.ahb_interconnect',
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
    confess "FSM::IAL2::ProtocolIntent::AhbInterconnect->new must be called with the FSM::IAL2::ProtocolIntent::AhbInterconnect class invocant\n"
        unless defined($class) && !ref($class) && $class eq 'FSM::IAL2::ProtocolIntent::AhbInterconnect';
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
    confess "FSM::IAL2::ProtocolIntent::AhbInterconnect->$method must be called on an FSM::IAL2::ProtocolIntent::AhbInterconnect object\n"
        unless blessed($self) && $self->isa('FSM::IAL2::ProtocolIntent::AhbInterconnect');
}

sub _normalize_contract($raw) {
    my $kind = _required_scalar($raw, 'kind');
    confess "AHB interconnect IAL2 contract kind must be ahb_interconnect\n"
        unless $kind eq 'ahb_interconnect';

    my $protocol = lc _required_scalar($raw, 'protocol');
    confess "AHB interconnect IAL2 contract profile must be ahb\n"
        unless $protocol eq 'ahb';

    my $intent_name = _nonempty_scalar($raw->{intent_name}, 'intent_name');
    my $source = _required_hash($raw, 'source');
    my $interconnect = _required_hash($raw, 'interconnect');
    my $requester = _required_hash($raw, 'requester');
    my @subordinates = _raw_subordinate_contracts($raw);

    my $name = _required_identifier($interconnect, 'name');
    my $role = lc _required_scalar($interconnect, 'role');
    confess "AHB interconnect IAL2 contract role must be interconnect\n"
        unless $role eq 'interconnect';
    my $clock = _required_identifier($interconnect, 'clock');
    my $reset = _normalize_reset($interconnect->{reset}, 'interconnect.reset');
    my $children = _normalize_children(_required_hash($interconnect, 'children'));
    my $decode = _normalize_decode(_required_hash($interconnect, 'decode'));
    my $wiring = _normalize_wiring(_required_hash($interconnect, 'wiring'));
    my $address_map = _normalize_address_map(
        _required_hash($interconnect, 'address_map'),
        $children->{subordinates},
    );

    _validate_endpoint_role($requester, 'requester', 'ahb_requester');
    for my $subordinate (@subordinates) {
        _validate_endpoint_role($subordinate, 'subordinate', 'ahb_subordinate');
    }
    _validate_shared_system_ports($clock, $reset, $requester, \@subordinates);
    _validate_child_references($children, $requester, \@subordinates);
    _validate_bus_compatibility($wiring->{bus}, $requester->{bus}, \@subordinates);
    _validate_aggregate_seq_policy_family(\@subordinates);

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
        interconnect     => {
            name        => $name,
            role        => $role,
            clock       => $clock,
            reset       => $reset,
            children    => $children,
            address_map => $address_map,
            decode      => $decode,
            wiring      => $wiring,
        },
        requester        => _clone_jsonish($requester),
        subordinate      => _clone_jsonish($subordinates[0]),
        subordinates     => [map { _clone_jsonish($_) } @subordinates],
    };
    _assign_generated_instance_names($contract);
    return $contract;
}

sub _endpoint_contract($contract, $role) {
    my %endpoint = %{$contract->{$role}};
    $endpoint{protocol} = $contract->{protocol};
    $endpoint{intent_name} = $contract->{intent_name};
    $endpoint{source} = _clone_jsonish($contract->{source});
    return \%endpoint;
}

sub _endpoint_contract_from_hash($contract, $endpoint) {
    my %copy = %$endpoint;
    $copy{protocol} = $contract->{protocol};
    $copy{intent_name} = $contract->{intent_name};
    $copy{source} = _clone_jsonish($contract->{source});
    return \%copy;
}

sub _raw_subordinate_contracts($raw) {
    my @subordinates;
    if (exists $raw->{subordinates}) {
        confess "AHB interconnect IAL2 contract subordinates must be an array reference\n"
            unless ref($raw->{subordinates}) eq 'ARRAY';
        @subordinates = @{$raw->{subordinates}};
    } elsif (exists $raw->{subordinate}) {
        @subordinates = ($raw->{subordinate});
    } else {
        confess "AHB interconnect IAL2 contract is missing required hash field 'subordinate'\n";
    }

    confess "AHB interconnect IAL2 contract supports one or two subordinate endpoints in this slice\n"
        unless @subordinates == 1 || @subordinates == 2;
    for my $index (0 .. $#subordinates) {
        confess "AHB interconnect IAL2 contract subordinates[$index] must be a hash reference\n"
            unless ref($subordinates[$index]) eq 'HASH';
    }
    return @subordinates;
}

sub _assign_generated_instance_names($contract) {
    my $interconnect = $contract->{interconnect};
    my %reserved = map { $_->{name} => 1 } _top_port_specs($contract);

    my $requester_child = $interconnect->{children}{requester};
    $requester_child->{generated_instance_name} = _unique_generated_instance_name(
        $requester_child->{instance_name},
        'requester',
        \%reserved,
    );

    for my $child (@{$interconnect->{children}{subordinates}}) {
        $child->{generated_instance_name} = _unique_generated_instance_name(
            $child->{instance_name},
            'subordinate',
            \%reserved,
        );
    }

    $interconnect->{generated_interconnect_instance_name} = _unique_generated_instance_name(
        'interconnect',
        'interconnect',
        \%reserved,
    );
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
        confess "Error: AHB interconnect generated duplicate endpoint .fsm artifact '$fsm_name'\n"
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

sub _build_ahb_interconnect_artifacts($contract) {
    my $entry_artifact = 'ahb_interconnect.fsm';
    my $isf_name = 'ahb_interconnect.isf';
    my $isf_text = _build_ahb_interconnect_isf($contract);
    my $fsm_text = _build_ahb_interconnect_fsm($contract);

    return {
        object_name    => 'ahb_interconnect',
        instance_name  => $contract->{interconnect}{generated_interconnect_instance_name} // 'interconnect',
        role           => 'interconnect',
        ial1_name      => $isf_name,
        ial1_text      => $isf_text,
        entry_artifact => $entry_artifact,
        fsm_text       => $fsm_text,
        ial1_item      => {
            object_name => 'ahb_interconnect',
            role        => 'interconnect',
            format      => 'isf',
            name        => $isf_name,
            text        => $isf_text,
        },
        ial0_item      => {
            object_name    => 'ahb_interconnect',
            role           => 'interconnect',
            kind           => 'generated_ahb_interconnect',
            format         => 'fsm',
            files          => [$entry_artifact],
            entry_artifact => $entry_artifact,
        },
    };
}

sub _build_ahb_interconnect_isf($contract) {
    my $interconnect = $contract->{interconnect};
    my $reset = _reset_clause($interconnect->{reset});
    my $bus = $interconnect->{wiring}{bus};
    my @subordinates = _subordinate_binding_entries($contract);

    return join("\n",
        "(actor ahb_interconnect",
        "  (clock $interconnect->{clock})",
        "  $reset",
        "  (watchdog 65536)",
        "",
        "  (interface",
        _interface_line('input', $bus->{request}),
        _interface_line('input', $bus->{lock}),
        _interface_line('input', $bus->{address}),
        _interface_line('input', $bus->{transfer}),
        _interface_line('input', $bus->{write}),
        _interface_line('input', $bus->{size}),
        _interface_line('input', $bus->{burst}),
        _interface_line('input', $bus->{protection}),
        _interface_line('input', $bus->{write_data}),
        (map {
            my $sub_bus = $_->{endpoint}{bus};
            (
                _interface_line('input', $sub_bus->{ready_out}),
                _interface_line('input', $sub_bus->{response}),
                _interface_line('input', $sub_bus->{read_data}),
            )
        } @subordinates),
        _output_interface_line($bus->{grant}, 1, 1),
        _output_interface_line($bus->{ready}, 1, 1),
        _output_interface_line($bus->{response}, 0, 0),
        _output_interface_line($bus->{read_data}, 0, 0),
        (map {
            my $sub_bus = $_->{endpoint}{bus};
            (
                _output_interface_line($sub_bus->{select}, 0, 0),
                _output_interface_line($sub_bus->{address}, 0, 0),
            )
        } @subordinates),
        "  )",
        "",
        "  (address-map $interconnect->{address_map}{name}",
        (map {
            my $window = $_->{window};
            (
                "    (window $window->{name}",
                "      (base $window->{base}{name} width $window->{base}{width} default $window->{base}{default})",
                "      (size $window->{size}{name} width $window->{size}{width} default $window->{size}{default}))",
            )
        } @subordinates),
        "  )",
        "",
        "  (decode",
        "    (overlap $interconnect->{decode}{overlap})",
        "    (priority $interconnect->{decode}{priority})",
        "    (unmapped-address $interconnect->{decode}{unmapped_address}))",
        "",
        "  (behavior",
        "    (grant fixed-one)",
        "    (request-decode active-transfer-static-window)",
        "    (response-mux selected-subordinate-one-bit-hresp-to-requester-two-bit-hresp)",
        "    (unmapped-address-error two-cycle)))",
        "",
    );
}

sub _build_ahb_interconnect_fsm($contract) {
    my $interconnect = $contract->{interconnect};
    my $bus = $interconnect->{wiring}{bus};
    my @subordinates = _subordinate_binding_entries($contract);
    my $address = $bus->{address}{name};
    my $transfer = $bus->{transfer}{name};
    my $active_transfer = "(! (== $transfer 2'b00))";
    my @window_matches = map {
        "(& (>= $address $_->{window}{base}{default}) (< $address $_->{window}{limit}))"
    } @subordinates;
    my $any_window_match = @window_matches == 1
        ? $window_matches[0]
        : "(| " . join(' ', @window_matches) . ")";
    my $unmapped = "(& $active_transfer (! $any_window_match))";
    my $input_visibility_guard = "(& "
        . join(
            ' ',
            "(== $bus->{request} $bus->{request})",
            "(== $bus->{lock} $bus->{lock})",
            "(== $bus->{write} $bus->{write})",
            "(== $bus->{size}{name} $bus->{size}{name})",
            "(== $bus->{burst}{name} $bus->{burst}{name})",
            "(== $bus->{protection}{name} $bus->{protection}{name})",
            "(== $bus->{write_data}{name} $bus->{write_data}{name})",
        )
        . ")";
    my @subordinate_size_lines;
    my @subordinate_idle_lines;
    my @subordinate_hit_blocks;
    my @subordinate_unmapped_lines;
    for my $index (0 .. $#subordinates) {
        my $entry = $subordinates[$index];
        my $sub_bus = $entry->{endpoint}{bus};
        my $window = $entry->{window};
        my $hit = "(& $active_transfer $window_matches[$index])";
        my $local_address = _local_address_expr($address, $window);

        push @subordinate_size_lines,
            _size_line($sub_bus->{ready_out}, 1),
            _size_line($sub_bus->{response}{name}, $sub_bus->{response}{width}),
            _size_line($sub_bus->{read_data}{name}, $sub_bus->{read_data}{width}),
            _size_line($sub_bus->{select}, 1, 0),
            _size_line($sub_bus->{address}{name}, $sub_bus->{address}{width}, 0);
        push @subordinate_idle_lines,
            "    (= ($sub_bus->{select}> 0))",
            "    (= ($sub_bus->{address}{name}> 0))";
        push @subordinate_hit_blocks,
            "",
            "    (<$hit",
            "      (= ($bus->{ready}> $sub_bus->{ready_out}))",
            "      (= ($bus->{read_data}{name}> $sub_bus->{read_data}{name}))",
            "      (= ($sub_bus->{select}> 1))",
            "      (= ($sub_bus->{address}{name}> $local_address))",
            "      (<$sub_bus->{response}{name}",
            "        (= ($bus->{response}{name}> 2'b01))",
            "      )",
            "      (<!$sub_bus->{response}{name}",
            "        (= ($bus->{response}{name}> 2'b00))",
            "      )",
            "    )";
        push @subordinate_unmapped_lines,
            "      (= ($sub_bus->{select}> 0))",
            "      (= ($sub_bus->{address}{name}> 0))";
    }

    return join("\n",
        "(?fsm:ahb_interconnect",
        "",
        "  (+system",
        "    (clock $interconnect->{clock})",
        "    (areset $interconnect->{reset}{signal})",
        "  )",
        "",
        "  (+size",
        _size_line($bus->{request}, 1),
        _size_line($bus->{lock}, 1),
        _size_line($bus->{address}{name}, $bus->{address}{width}),
        _size_line($bus->{transfer}{name}, $bus->{transfer}{width}),
        _size_line($bus->{write}, 1),
        _size_line($bus->{size}{name}, $bus->{size}{width}),
        _size_line($bus->{burst}{name}, $bus->{burst}{width}),
        _size_line($bus->{protection}{name}, $bus->{protection}{width}),
        _size_line($bus->{write_data}{name}, $bus->{write_data}{width}),
        @subordinate_size_lines,
        _size_line($bus->{grant}, 1, 1),
        _size_line($bus->{ready}, 1, 1),
        _size_line($bus->{response}{name}, $bus->{response}{width}, 0),
        _size_line($bus->{read_data}{name}, $bus->{read_data}{width}, 0),
        "  )",
        "",
        "  (idle",
        "    (= ($bus->{grant}> 1))",
        "    (= ($bus->{ready}> 1))",
        "    (= ($bus->{response}{name}> 2'b00))",
        "    (= ($bus->{read_data}{name}> 0))",
        @subordinate_idle_lines,
        "    (<$input_visibility_guard",
        "      (= ($bus->{grant}> 1))",
        "    )",
        @subordinate_hit_blocks,
        "",
        "    (<$unmapped",
        "      (= ($bus->{ready}> 0))",
        "      (= ($bus->{response}{name}> 2'b01))",
        "      (= ($bus->{read_data}{name}> 0))",
        @subordinate_unmapped_lines,
        "      (-> unmapped_error_complete)",
        "    )",
        "  )",
        "",
        "  (unmapped_error_complete",
        "    (= ($bus->{grant}> 1))",
        "    (= ($bus->{ready}> 1))",
        "    (= ($bus->{response}{name}> 2'b01))",
        "    (= ($bus->{read_data}{name}> 0))",
        @subordinate_idle_lines,
        "    (-> idle)",
        "  )",
        ")",
        "",
    );
}

sub _build_composition_top(%args) {
    my $contract = $args{contract};
    my $requester_result = $args{requester_result};
    my @subordinate_results = @{$args{subordinate_results} || []};
    my $interconnect = $args{interconnect};
    my $fsm_files = $args{fsm_files};

    my $ic = $contract->{interconnect};
    my $top_name = $ic->{name};
    my $entry_artifact = "$top_name.fsm";
    my $requester_child = $ic->{children}{requester};
    my @subordinate_children = @{$ic->{children}{subordinates}};
    my $requester_instance = _generated_instance_name($requester_child);
    my $requester_entry = $requester_result->{report}{generated_artifacts}{hdl_entry}{entry_artifact};
    my @subordinate_entries = map {
        $_->{report}{generated_artifacts}{hdl_entry}{entry_artifact}
    } @subordinate_results;
    my @child_artifacts = ($requester_entry, $interconnect->{entry_artifact}, @subordinate_entries);

    my @port_specs = _top_port_specs($contract);
    my @lines = (
        "(?top:$top_name",
        "  (?ports:public_io",
        (map { "    " . _composition_port_token($_) } @port_specs),
        "  )",
        "  (?fsmc:$requester_instance $requester_child->{object_name})",
        "  (?fsmc:$interconnect->{instance_name} $interconnect->{object_name})",
        (map {
            "  (?fsmc:" . _generated_instance_name($_) . " $_->{object_name})"
        } @subordinate_children),
        "  (?wiring:$ic->{wiring}{name}",
        (map { "    $_" } _wiring_lines($contract, $interconnect)),
        "  )",
        ")",
        "",
    );

    for my $artifact (@child_artifacts) {
        confess "Error: AHB interconnect composition is missing generated child .fsm artifact '$artifact'\n"
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
            kind            => 'generated_ahb_composition_top',
            format          => 'fsm',
            files           => [$entry_artifact],
            entry_artifact  => $entry_artifact,
            child_artifacts => \@child_artifacts,
        },
        report_entry   => {
            selected        => JSON::PP::true,
            kind            => 'generated_ahb_composition_top',
            format          => 'fsm',
            module          => $top_name,
            entry_artifact  => $entry_artifact,
            child_artifacts => \@child_artifacts,
            port_policy     => {
                shared_system_ports => {
                    clock => $ic->{clock},
                    reset => _clone_jsonish($ic->{reset}),
                },
                ahb_bus_wiring => _topology_name($contract),
            },
        },
    };
}

sub _wiring_lines($contract, $interconnect) {
    my $ic = $contract->{interconnect};
    my $requester = _generated_instance_name($ic->{children}{requester});
    my $fabric = $interconnect->{instance_name};
    my $bus = $ic->{wiring}{bus};

    return (
        "($requester.$bus->{request} $fabric.$bus->{request})",
        "($requester.$bus->{lock} $fabric.$bus->{lock})",
        "($requester.$bus->{address}{name} $fabric.$bus->{address}{name})",
        "($requester.$bus->{transfer}{name} $fabric.$bus->{transfer}{name})",
        "($requester.$bus->{write} $fabric.$bus->{write})",
        "($requester.$bus->{size}{name} $fabric.$bus->{size}{name})",
        "($requester.$bus->{burst}{name} $fabric.$bus->{burst}{name})",
        "($requester.$bus->{protection}{name} $fabric.$bus->{protection}{name})",
        "($requester.$bus->{write_data}{name} $fabric.$bus->{write_data}{name})",
        "($fabric.$bus->{grant} $requester.$bus->{grant})",
        "($fabric.$bus->{ready} $requester.$bus->{ready})",
        "($fabric.$bus->{response}{name} $requester.$bus->{response}{name})",
        "($fabric.$bus->{read_data}{name} $requester.$bus->{read_data}{name})",
        (map {
            my $subordinate = _generated_instance_name($_->{child});
            my $sub_bus = $_->{endpoint}{bus};
            my @lines = (
                "($fabric.$bus->{ready} $subordinate.$sub_bus->{ready_in})",
                "($fabric.$sub_bus->{select} $subordinate.$sub_bus->{select})",
                "($fabric.$sub_bus->{address}{name} $subordinate.$sub_bus->{address}{name})",
                "($requester.$bus->{transfer}{name} $subordinate.$sub_bus->{transfer}{name})",
                "($requester.$bus->{write} $subordinate.$sub_bus->{write})",
                "($requester.$bus->{size}{name} $subordinate.$sub_bus->{size}{name})",
            );
            push @lines, "($requester.$bus->{burst}{name} $subordinate.$sub_bus->{burst}{name})"
                if ref($sub_bus->{burst}) eq 'HASH';
            push @lines, (
                "($requester.$bus->{write_data}{name} $subordinate.$sub_bus->{write_data}{name})",
                "($subordinate.$sub_bus->{ready_out} $fabric.$sub_bus->{ready_out})",
                "($subordinate.$sub_bus->{response}{name} $fabric.$sub_bus->{response}{name})",
                "($subordinate.$sub_bus->{read_data}{name} $fabric.$sub_bus->{read_data}{name})",
            );
            @lines
        } _subordinate_binding_entries($contract)),
    );
}

sub _top_port_specs($contract) {
    my $ic = $contract->{interconnect};
    my $requester = $contract->{requester};
    my @subordinates = @{$contract->{subordinates}};

    return (
        {
            name      => $ic->{clock},
            direction => 'input',
            width     => 1,
            system    => 'clock',
        },
        {
            name      => $ic->{reset}{signal},
            direction => 'input',
            width     => 1,
            system    => 'reset',
        },
        _input_port($requester->{local_command}{valid}, 1),
        _input_port($requester->{local_command}{write}, 1),
        _input_port($requester->{local_command}{address}{name}, $requester->{local_command}{address}{width}),
        _input_port($requester->{local_command}{write_data}{name}, $requester->{local_command}{write_data}{width}),
        _input_port($requester->{local_command}{write_data_step}{name}, $requester->{local_command}{write_data_step}{width}),
        _input_port($requester->{local_command}{size}{name}, $requester->{local_command}{size}{width}),
        _input_port($requester->{local_command}{protection}{name}, $requester->{local_command}{protection}{width}),
        _input_port($requester->{local_command}{lock}, 1),
        _input_port($requester->{local_command}{burst}{name}, $requester->{local_command}{burst}{width}),
        _input_port($requester->{local_command}{length}{name}, $requester->{local_command}{length}{width}),
        (map {
            _input_port($_->{control}{wait_cycles}{name}, $_->{control}{wait_cycles}{width})
        } @subordinates),
        _output_port($requester->{local_command}{ready}, 1),
        _output_port($requester->{local_status}{busy}, 1),
        _output_port($requester->{local_status}{beat_done}, 1),
        _output_port($requester->{local_status}{done}, 1),
        _output_port($requester->{local_status}{burst_active}, 1),
        _output_port($requester->{local_status}{wrap_active}, 1),
        _output_port($requester->{local_status}{beat_index}{name}, $requester->{local_status}{beat_index}{width}),
        _output_port($requester->{local_status}{beats_remaining}{name}, $requester->{local_status}{beats_remaining}{width}),
        _output_port($requester->{local_status}{active_address}{name}, $requester->{local_status}{active_address}{width}),
        _output_port($requester->{local_status}{active_burst}{name}, $requester->{local_status}{active_burst}{width}),
        _output_port($requester->{local_status}{last_error}, 1),
        _output_port($requester->{local_status}{last_retry}, 1),
        _output_port($requester->{local_status}{last_split}, 1),
        _output_port($requester->{local_status}{last_response}{name}, $requester->{local_status}{last_response}{width}),
        _output_port($requester->{local_status}{last_read_data}{name}, $requester->{local_status}{last_read_data}{width}),
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
    confess "AHB interconnect top port '$name' has unsupported direction '$direction'\n"
        unless $direction eq 'input' || $direction eq 'output';
    return $width == 1 ? "=$name" : "=$name<$width"
        if $direction eq 'input';
    return $width == 1 ? "=$name>" : "=$name>$width";
}

sub _build_report(%args) {
    my $contract = $args{contract};
    my $requester_result = $args{requester_result};
    my @subordinate_results = @{$args{subordinate_results} || []};
    my $interconnect = $args{interconnect};
    my @ial1_items = @{$args{ial1_items} || []};
    my @ial0_items = @{$args{ial0_items} || []};
    my $hdl_entry = $args{hdl_entry};
    my @fsm_files = sort keys %{$args{fsm_files} || {}};
    my $ic = $contract->{interconnect};
    my $composition = {
        name                          => $ic->{name},
        topology                      => _topology_name($contract),
        child_instance_count          => 2 + scalar(@{$contract->{subordinates}}),
        endpoint_child_instance_count => 1 + scalar(@{$contract->{subordinates}}),
        requester                     => _clone_jsonish($ic->{children}{requester}),
        subordinate                   => _subordinate_report_entry($contract),
        subordinates                  => _subordinate_report_entries($contract),
        address_map                   => _address_map_report($contract),
        decode                        => _clone_jsonish($ic->{decode}),
        response_mux                  => _response_mux_report($contract),
        generated_interconnect        => {
            object_name   => $interconnect->{object_name},
            instance_name => $interconnect->{instance_name},
            ial1_artifact => $interconnect->{ial1_name},
            ial0_artifact => $interconnect->{entry_artifact},
        },
        wiring                        => _clone_jsonish($ic->{wiring}),
        width_policy                  => _width_policy($contract),
        top_ports                     => [map { _clone_jsonish($_) } _top_port_specs($contract)],
    };
    if (my $byte_lane_propagation = _byte_lane_propagation_report($contract, \@subordinate_results)) {
        $composition->{byte_lane_propagation} = $byte_lane_propagation;
    }
    if (my $seq_policy_propagation = _seq_policy_propagation_report($contract, \@subordinate_results)) {
        $composition->{seq_policy_propagation} = $seq_policy_propagation;
    }

    return {
        schema => 'fsmgen.ial2.protocol_intent.ahb_interconnect.v1',
        mode   => 'requester-subordinate-interconnect',
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
            object  => 'ahb-interconnect',
            role    => $ic->{role},
        },
        composition => $composition,
        children => [
            _child_report('requester', $ic->{children}{requester}, $requester_result),
            _interconnect_child_report($contract, $interconnect),
            (map {
                _child_report('subordinate', $ic->{children}{subordinates}[$_], $subordinate_results[$_], $contract)
            } 0 .. $#subordinate_results),
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
            'profile must be ahb and the aggregate object must be ahb-interconnect',
            _static_cardinality_rule($contract),
            'requester, subordinate endpoints, and interconnect must share clock and reset policy',
            'interconnect children must reference the embedded requester and subordinate objects by name',
            _static_address_map_rule($contract),
            'decode policy is overlap reject, priority source-order, and unmapped-address error',
            'the generated AHB interconnect asserts HGRANT permanently, decodes HTRANS != IDLE against the static window, emits local subordinate HADDR, and muxes subordinate response/data',
            'the generated AHB interconnect maps one-bit subordinate OKAY/ERROR HRESP to requester two-bit OKAY/ERROR HRESP',
            'unmapped active transfers complete with a two-cycle interconnect-owned ERROR response',
            _static_source_surface_rule($contract),
        ],
        unsupported_residue => _unsupported_residue($contract),
    };
}

sub _subordinate_report_entry($contract) {
    return _subordinate_report_entries($contract)->[0];
}

sub _subordinate_report_entries($contract) {
    return [
        map {
            my $child = $_->{child};
            my $endpoint = $_->{endpoint};
            my $window = $_->{window};
            +{
                %{$child},
                address_window        => _clone_jsonish($window),
                local_address_policy  => 'subtract_window_base',
                decoded_select_signal => $endpoint->{bus}{select},
                local_address_signal  => _clone_jsonish($endpoint->{bus}{address}),
            }
        } _subordinate_binding_entries($contract)
    ];
}

sub _topology_name($contract) {
    my $count = scalar @{$contract->{subordinates} || []};
    return 'one_requester_one_subordinate_static_window_interconnect'
        if $count == 1;
    return 'one_requester_two_subordinate_static_window_interconnect'
        if $count == 2;
    confess "AHB interconnect unsupported subordinate count '$count'\n";
}

sub _static_cardinality_rule($contract) {
    return scalar(@{$contract->{subordinates}}) == 1
        ? 'source must contain exactly one AHB requester, one AHB subordinate, and one AHB interconnect object'
        : 'source must contain exactly one AHB requester, two AHB subordinates, and one AHB interconnect object';
}

sub _static_address_map_rule($contract) {
    return scalar(@{$contract->{subordinates}}) == 1
        ? 'address-map must contain exactly one static 32-bit word-aligned window matching the subordinate child instance'
        : 'address-map must contain exactly two static 32-bit word-aligned non-overlapping windows matching the subordinate child instances';
}

sub _subordinate_binding_entries($contract) {
    my @children = @{$contract->{interconnect}{children}{subordinates} || []};
    my @endpoints = @{$contract->{subordinates} || []};
    my %endpoint_by_name = map { $_->{name} => $_ } @endpoints;
    my %window_by_name = map { $_->{name} => $_ } @{$contract->{interconnect}{address_map}{windows} || []};
    my @entries;
    for my $child (@children) {
        my $endpoint = $endpoint_by_name{$child->{object_name}}
            or confess "AHB interconnect internal error: no subordinate endpoint for '$child->{object_name}'\n";
        my $window = $window_by_name{$child->{instance_name}}
            or confess "AHB interconnect internal error: no address window for '$child->{instance_name}'\n";
        push @entries, {
            child    => $child,
            endpoint => $endpoint,
            window   => $window,
        };
    }
    return @entries;
}

sub _selected_window($contract) {
    return $contract->{interconnect}{address_map}{windows}[0];
}

sub _legacy_subordinate_bus($contract) {
    return $contract->{subordinates}[0]{bus};
}

sub _legacy_subordinate_child($contract) {
    return $contract->{interconnect}{children}{subordinates}[0];
}

sub _legacy_subordinate_report_entry($contract) {
    my $child = _legacy_subordinate_child($contract);
    my $window = _selected_window($contract);
    return {
        %{$child},
        address_window        => _clone_jsonish($window),
        local_address_policy  => 'subtract_window_base',
        decoded_select_signal => _legacy_subordinate_bus($contract)->{select},
        local_address_signal  => _clone_jsonish(_legacy_subordinate_bus($contract)->{address}),
    };
}

sub _address_map_report($contract) {
    my $ic = $contract->{interconnect};
    return {
        name             => $ic->{address_map}{name},
        address_width    => $ic->{address_map}{address_width},
        alignment_bytes  => $ic->{address_map}{alignment_bytes},
        windows          => _clone_jsonish($ic->{address_map}{windows}),
        overlap_policy   => $ic->{decode}{overlap},
        priority         => $ic->{decode}{priority},
        unmapped_address => $ic->{decode}{unmapped_address},
    };
}

sub _response_mux_report($contract) {
    my $bus = $contract->{interconnect}{wiring}{bus};
    my @subordinates = _subordinate_binding_entries($contract);
    return {
        grant           => $bus->{grant},
        ready           => $bus->{ready},
        response        => _clone_jsonish($bus->{response}),
        read_data       => _clone_jsonish($bus->{read_data}),
        selected_policy => 'selected_subordinate_response',
        subordinate_sources => [
            map {
                {
                    instance_name => $_->{child}{instance_name},
                    ready_out     => $_->{endpoint}{bus}{ready_out},
                    response      => _clone_jsonish($_->{endpoint}{bus}{response}),
                    read_data     => _clone_jsonish($_->{endpoint}{bus}{read_data}),
                }
            } @subordinates
        ],
        hresp_mapping   => {
            subordinate_width => 1,
            requester_width   => $bus->{response}{width},
            okay              => {
                subordinate => "1'b0",
                requester   => "2'b00",
            },
            error             => {
                subordinate => "1'b1",
                requester   => "2'b01",
            },
        },
        hit_policy      => {
            active_transfer => 'HTRANS != IDLE',
            ready           => 'selected_subordinate_ready_out',
            read_data       => 'selected_subordinate_read_data',
            response        => 'selected_subordinate_hresp_mapped_to_two_bits',
        },
        unmapped_policy => {
            active_transfer => 'HTRANS != IDLE with no matching address window',
            cycles          => 2,
            first_cycle     => {
                ready     => 0,
                response  => "2'b01",
                read_data => 0,
            },
            complete_cycle  => {
                ready     => 1,
                response  => "2'b01",
                read_data => 0,
            },
        },
        idle_policy     => {
            grant     => 1,
            ready     => 1,
            response  => "2'b00",
            read_data => 0,
        },
    };
}

sub _interconnect_child_report($contract, $interconnect) {
    return {
        role                => 'interconnect',
        instance_name       => $interconnect->{instance_name},
        object_name         => $interconnect->{object_name},
        target_protocol     => {
            profile  => $contract->{protocol},
            object   => 'ahb-interconnect',
            role     => 'interconnect',
            topology => _topology_name($contract),
        },
        address_map         => _address_map_report($contract),
        response_mux        => _response_mux_report($contract),
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
                selected       => JSON::PP::false,
                kind           => 'generated_ahb_interconnect',
                entry_artifact => $interconnect->{entry_artifact},
                module         => $interconnect->{object_name},
            },
        },
        unsupported_residue => _clone_jsonish(_unsupported_residue($contract)),
    };
}

sub _static_source_surface_rule($contract) {
    return 'AHB interconnect HBURST-aware aggregate propagation is exposed through generic .ppif in this slice; matching aggregate .ahb profile aliases and broader aggregate AHB interconnect/decode shapes remain deferred'
        if _all_subordinates_have_hburst_seq_policy($contract);
    return 'AHB interconnect is exposed through generic .ppif and the selected aggregate .ahb profile alias; broader aggregate AHB interconnect/decode shapes remain deferred';
}

sub _child_report($role, $child, $result, $parent_contract = undef) {
    my $report = {
        role                => $role,
        instance_name       => $child->{instance_name},
        object_name         => $child->{object_name},
        source_object       => _clone_jsonish($result->{report}{source_object}),
        target_protocol     => _clone_jsonish($result->{report}{target_protocol}),
        bindings            => _clone_jsonish($result->{report}{bindings}),
        transfer            => _clone_jsonish($result->{report}{transfer}),
        generated_artifacts => _clone_jsonish($result->{report}{generated_artifacts}),
        unsupported_residue => _child_unsupported_residue($role, $result, $parent_contract),
    };
    $report->{generated_instance_name} = _generated_instance_name($child)
        if defined $child->{generated_instance_name};
    $report->{narrow_transfer_policy} = _clone_jsonish($result->{report}{narrow_transfer_policy})
        if defined $result->{report}{narrow_transfer_policy};
    $report->{burst} = _clone_jsonish($result->{report}{burst})
        if defined $result->{report}{burst};
    $report->{response} = _clone_jsonish($result->{report}{response})
        if defined $result->{report}{response};
    $report->{output_defaults} = _clone_jsonish($result->{report}{output_defaults})
        if defined $result->{report}{output_defaults};
    return $report;
}

sub _child_unsupported_residue($role, $result, $parent_contract) {
    my $residue = _clone_jsonish($result->{report}{unsupported_residue});
    return $residue unless $role eq 'subordinate' && _all_subordinates_have_seq_policy($parent_contract);
    for my $item (@$residue) {
        next unless ref($item) eq 'HASH'
            && ($item->{id} // '') eq 'ahb_burst_seq_support_deferred'
            && defined $item->{detail};
        $item->{detail} =~ s/,\s*aggregate propagation//;
        $item->{detail} =~ s/aggregate propagation,\s*//;
    }
    return $residue;
}

sub _width_policy($contract) {
    my $subordinate_count = scalar @{$contract->{subordinates}};
    return {
        address_width                   => 32,
        data_width                      => 32,
        requester_response_width        => 2,
        subordinate_response_width      => 1,
        transfer_width                  => 2,
        size_width                      => 3,
        burst_width                     => 3,
        protection_width                => 4,
        wait_cycles_width               => 4,
        local_address_policy            => 'subtract_window_base',
        supported_subordinate_cardinality => $subordinate_count,
        supported_requester_cardinality => 1,
    };
}

sub _byte_lane_propagation_report($contract, $subordinate_results) {
    return undef unless _all_subordinates_have_byte_lane_policy($contract);
    my @bindings = _subordinate_binding_entries($contract);
    return undef unless @$subordinate_results == @bindings;

    my $bus = $contract->{interconnect}{wiring}{bus};
    my @subordinates;
    for my $index (0 .. $#bindings) {
        my $child_report = $subordinate_results->[$index]{report};
        return undef unless ref($child_report->{narrow_transfer_policy}) eq 'HASH';
        my $binding = $bindings[$index];
        my $endpoint = $binding->{endpoint};
        my $sub_bus = $endpoint->{bus};
        push @subordinates, {
            instance_name          => $binding->{child}{instance_name},
            object_name            => $binding->{child}{object_name},
            address_window         => _clone_jsonish($binding->{window}),
            transfer               => $endpoint->{transfer}{name},
            supported_size         => _clone_jsonish($endpoint->{transfer}{supported_size}),
            narrow_transfer_policy => _clone_jsonish($child_report->{narrow_transfer_policy}),
            local_address_policy   => 'subtract_window_base_before_subordinate_lane_policy',
            select_signal          => $sub_bus->{select},
            local_address_signal   => _clone_jsonish($sub_bus->{address}),
            ready_out_signal       => $sub_bus->{ready_out},
            response_signal        => _clone_jsonish($sub_bus->{response}),
            read_data_signal       => _clone_jsonish($sub_bus->{read_data}),
        };
    }

    return {
        selected             => JSON::PP::true,
        mode                 => 'subordinate_owned_narrow_transfer_policy',
        local_address_policy => 'subtract_window_base_before_subordinate_lane_policy',
        mapped_hit_owner     => 'selected_subordinate',
        unmapped_error_owner => 'interconnect',
        request_forwarding   => {
            address    => _clone_jsonish($bus->{address}),
            transfer   => _clone_jsonish($bus->{transfer}),
            write      => $bus->{write},
            size       => _clone_jsonish($bus->{size}),
            write_data => _clone_jsonish($bus->{write_data}),
            ready      => $bus->{ready},
        },
        response_forwarding  => {
            ready     => $bus->{ready},
            response  => _clone_jsonish($bus->{response}),
            read_data => _clone_jsonish($bus->{read_data}),
            hresp_mapping => {
                subordinate_width => 1,
                requester_width   => $bus->{response}{width},
                okay              => {
                    subordinate => "1'b0",
                    requester   => "2'b00",
                },
                error             => {
                    subordinate => "1'b1",
                    requester   => "2'b01",
                },
            },
        },
        subordinates         => \@subordinates,
    };
}

sub _seq_policy_propagation_report($contract, $subordinate_results) {
    return undef unless _all_subordinates_have_seq_policy($contract);
    my @bindings = _subordinate_binding_entries($contract);
    return undef unless @$subordinate_results == @bindings;

    my $bus = $contract->{interconnect}{wiring}{bus};
    my $hburst_selected = _all_subordinates_have_hburst_seq_policy($contract);
    my $mode = $hburst_selected
        ? 'subordinate_owned_hburst_in_word_seq_policy'
        : 'subordinate_owned_in_word_seq_policy';
    my $local_address_policy = $hburst_selected
        ? 'subtract_window_base_before_subordinate_hburst_seq_policy'
        : 'subtract_window_base_before_subordinate_seq_policy';
    my @subordinates;
    my @child_burst_names;
    for my $index (0 .. $#bindings) {
        my $child_report = $subordinate_results->[$index]{report};
        return undef unless ref($child_report->{transfer}) eq 'HASH'
            && ref($child_report->{transfer}{seq_policy}) eq 'HASH';
        my $seq_policy = $child_report->{transfer}{seq_policy};
        my $binding = $bindings[$index];
        my $endpoint = $binding->{endpoint};
        my $sub_bus = $endpoint->{bus};
        my %entry = (
            instance_name        => $binding->{child}{instance_name},
            object_name          => $binding->{child}{object_name},
            address_window       => _clone_jsonish($binding->{window}),
            transfer             => $endpoint->{transfer}{name},
            supported_size       => _clone_jsonish($endpoint->{transfer}{supported_size}),
            supported_seq_size   => _clone_jsonish($seq_policy->{supported_sizes}),
            seq_policy           => _clone_jsonish($seq_policy),
            local_address_policy => $local_address_policy,
            select_signal        => $sub_bus->{select},
            local_address_signal => _clone_jsonish($sub_bus->{address}),
            ready_out_signal     => $sub_bus->{ready_out},
            response_signal      => _clone_jsonish($sub_bus->{response}),
            read_data_signal     => _clone_jsonish($sub_bus->{read_data}),
        );
        if ($hburst_selected) {
            $entry{burst_signal} = _clone_jsonish($sub_bus->{burst});
            $entry{supported_hburst_modes} = _clone_jsonish($seq_policy->{supported_hburst_modes});
            $entry{fail_closed_hburst_modes} = _clone_jsonish($seq_policy->{fail_closed_hburst_modes});
            push @child_burst_names, $sub_bus->{burst}{name};
        }
        push @subordinates, \%entry;
    }

    my %request_forwarding = (
        address    => _clone_jsonish($bus->{address}),
        transfer   => _clone_jsonish($bus->{transfer}),
        write      => $bus->{write},
        size       => _clone_jsonish($bus->{size}),
        write_data => _clone_jsonish($bus->{write_data}),
        ready      => $bus->{ready},
    );
    $request_forwarding{burst} = {
        global_name => $bus->{burst}{name},
        width       => $bus->{burst}{width},
        child_names => \@child_burst_names,
    } if $hburst_selected;

    my %report = (
        selected             => JSON::PP::true,
        mode                 => $mode,
        local_address_policy => $local_address_policy,
        mapped_hit_owner     => 'selected_subordinate',
        unmapped_error_owner => 'interconnect',
        request_forwarding   => \%request_forwarding,
        response_forwarding  => {
            ready     => $bus->{ready},
            response  => _clone_jsonish($bus->{response}),
            read_data => _clone_jsonish($bus->{read_data}),
            hresp_mapping => {
                subordinate_width => 1,
                requester_width   => $bus->{response}{width},
                okay              => {
                    subordinate => "1'b0",
                    requester   => "2'b00",
                },
                error             => {
                    subordinate => "1'b1",
                    requester   => "2'b01",
                },
            },
        },
        subordinates         => \@subordinates,
    );
    if ($hburst_selected) {
        $report{policy} = 'hburst_in_word_progressive';
        $report{base_policy} = 'in_word_progressive';
        $report{length_source} = $bus->{burst}{name};
    }
    return \%report;
}

sub _all_subordinates_have_byte_lane_policy($contract) {
    return 0 unless ref($contract) eq 'HASH';
    my @subordinates = @{$contract->{subordinates} || []};
    return 0 unless @subordinates;
    for my $subordinate (@subordinates) {
        return 0 unless _subordinate_has_byte_lane_policy($subordinate);
    }
    return 1;
}

sub _subordinate_has_byte_lane_policy($subordinate) {
    return 0 unless ref($subordinate) eq 'HASH' && ref($subordinate->{transfer}) eq 'HASH';
    my $transfer = $subordinate->{transfer};
    return 0 unless _is_byte_lane_transfer_name($transfer->{name});

    my @sizes = @{$transfer->{supported_size} || []};
    my %sizes = map { $_ => 1 } @sizes;
    return 0 unless @sizes == 3 && $sizes{byte} && $sizes{halfword} && $sizes{word};
    return 0 unless ($transfer->{lane_order} // '') eq 'little-endian';
    return 0 unless ($transfer->{narrow_write} // '') eq 'preserve-inactive-lanes';
    return 0 unless ($transfer->{narrow_read} // '') eq 'zero-fill-inactive-lanes';
    return 0 unless ($transfer->{unaligned_access} // '') eq 'error';
    return 0 unless ($transfer->{crossing_access} // '') eq 'error';
    return 1;
}

sub _all_subordinates_have_seq_policy($contract) {
    return 0 unless ref($contract) eq 'HASH';
    my @subordinates = @{$contract->{subordinates} || []};
    return 0 unless @subordinates;
    for my $subordinate (@subordinates) {
        return 0 unless _subordinate_has_seq_policy($subordinate);
    }
    return 1;
}

sub _all_subordinates_have_hburst_seq_policy($contract) {
    return 0 unless ref($contract) eq 'HASH';
    my @subordinates = @{$contract->{subordinates} || []};
    return 0 unless @subordinates;
    for my $subordinate (@subordinates) {
        return 0 unless _subordinate_has_hburst_seq_policy($subordinate);
    }
    return 1;
}

sub _all_subordinates_park_busy($contract) {
    return 0 unless ref($contract) eq 'HASH';
    my @subordinates = @{$contract->{subordinates} || []};
    return 0 unless @subordinates;
    for my $subordinate (@subordinates) {
        return 0 unless _subordinate_parks_busy($subordinate);
    }
    return 1;
}

sub _subordinate_parks_busy($subordinate) {
    return 0 unless ref($subordinate) eq 'HASH' && ref($subordinate->{transfer}) eq 'HASH';
    my $parked = $subordinate->{transfer}{parked_transfer};
    return 0 unless ref($parked) eq 'ARRAY';
    return scalar(grep { $_ eq 'busy' } @$parked) ? 1 : 0;
}

sub _subordinate_has_seq_policy($subordinate) {
    return _subordinate_has_in_word_seq_policy($subordinate)
        || _subordinate_has_hburst_seq_policy($subordinate);
}

sub _subordinate_has_in_word_seq_policy($subordinate) {
    return 0 unless _subordinate_has_byte_lane_policy($subordinate);
    my $transfer = $subordinate->{transfer};
    return 0 unless ($transfer->{name} // '') eq 'ahb_lite_byte_lane_seq_access';
    my $seq_policy = $transfer->{seq_policy};
    return 0 unless defined $seq_policy;
    return 1 if !ref($seq_policy) && $seq_policy eq 'in-word-progressive';
    return 0 unless ref($seq_policy) eq 'HASH';
    return 0 unless $seq_policy->{selected};
    return 0 unless ($seq_policy->{mode} // '') eq 'in_word_progressive';
    my @sizes = @{$seq_policy->{supported_sizes} || []};
    my %sizes = map { $_ => 1 } @sizes;
    return 0 unless @sizes == 2 && $sizes{byte} && $sizes{halfword};
    return 1;
}

sub _subordinate_has_hburst_seq_policy($subordinate) {
    return 0 unless _subordinate_has_byte_lane_policy($subordinate);
    my $transfer = $subordinate->{transfer};
    return 0 unless ($transfer->{name} // '') eq 'ahb_lite_byte_lane_hburst_seq_access';
    my $seq_policy = $transfer->{seq_policy};
    return 0 unless defined $seq_policy;
    my $mode = ref($seq_policy) eq 'HASH' ? ($seq_policy->{mode} // '') : $seq_policy;
    return 0 unless $mode eq 'hburst_in_word_progressive'
        || $mode eq 'hburst-in-word-progressive';
    return 0 unless ref($subordinate->{bus}{burst}) eq 'HASH'
        && ($subordinate->{bus}{burst}{width} // '') eq '3';
    return 1;
}

sub _subordinate_requests_hburst_seq_policy($subordinate) {
    return 0 unless ref($subordinate) eq 'HASH' && ref($subordinate->{transfer}) eq 'HASH';
    my $seq_policy = $subordinate->{transfer}{seq_policy};
    return 0 unless defined $seq_policy;
    my $mode = ref($seq_policy) eq 'HASH' ? ($seq_policy->{mode} // '') : $seq_policy;
    return $mode eq 'hburst_in_word_progressive'
        || $mode eq 'hburst-in-word-progressive';
}

sub _is_byte_lane_transfer_name($name) {
    return ($name // '') eq 'ahb_lite_byte_lane_access'
        || ($name // '') eq 'ahb_lite_byte_lane_seq_access'
        || ($name // '') eq 'ahb_lite_byte_lane_hburst_seq_access';
}

sub _unsupported_residue($contract = undef) {
    my $subordinate_count = ref($contract) eq 'HASH' ? scalar @{$contract->{subordinates} || []} : 1;
    my $byte_lane_selected = _all_subordinates_have_byte_lane_policy($contract);
    my $seq_policy_selected = _all_subordinates_have_seq_policy($contract);
    my $hburst_seq_policy_selected = _all_subordinates_have_hburst_seq_policy($contract);
    my $hburst_busy_park_selected = $hburst_seq_policy_selected && _all_subordinates_park_busy($contract);
    my $interconnect_residue = $subordinate_count == 2
        ? {
            id     => 'ahb_broader_interconnect_decode_deferred',
            detail => $hburst_seq_policy_selected
                ? 'The first one-requester/two-subordinate static-window AHB interconnect/decode source ships with subordinate-owned byte/halfword/word narrow transfers and byte-only HBURST WRAP4/INCR4 in-word SEQ propagation; broader subordinate cardinality, multiple requesters, arbitration, bus matrices, programmable or dynamic windows, optional AHB signals, BUSY-in-burst continuation, halfword/word burst SEQ, wider bursts, direct backend, verification-output, backend-language variants, AXI/APB behavior, and VHDL remain future work.'
                : $byte_lane_selected
                ? 'The first one-requester/two-subordinate static-window AHB interconnect/decode source ships with subordinate-owned byte/halfword/word narrow transfers; broader subordinate cardinality, multiple requesters, arbitration, bus matrices, programmable or dynamic windows, optional AHB signals, burst continuation, direct backend, verification-output, backend-language variants, AXI/APB behavior, and VHDL remain future work.'
                : 'The first one-requester/two-subordinate static-window AHB interconnect/decode source ships; broader subordinate cardinality, multiple requesters, arbitration, bus matrices, programmable or dynamic windows, optional AHB signals, burst continuation, byte lanes, direct backend, verification-output, backend-language variants, AXI/APB behavior, and VHDL remain future work.',
        }
        : {
            id     => 'ahb_multi_subordinate_decode_deferred',
            detail => 'Only one requester, one subordinate, and one static address window are implemented for this source; multi-subordinate decode, arbitration, and bus matrices remain future AHB work.',
        };
    return [
        {
            id     => 'ahb_aggregate_profile_alias_deferred',
            detail => 'Generic .ppif reports retain the aggregate profile-alias distinction; use ppif/ahb_interconnect.ahb for the selected one-subordinate .ahb alias surface or ppif/ahb_interconnect_two_subordinate.ahb for the selected two-subordinate .ahb alias surface, while broader aggregate AHB alias shapes remain future work.',
        },
        $interconnect_residue,
        {
            id     => 'ahb_optional_signal_residue',
            detail => $byte_lane_selected
                ? 'Optional AHB and AHB5 property-gated signals, exclusive access, protection policy effects, and legacy two-bit subordinate HRESP compatibility remain deferred.'
                : 'Optional AHB and AHB5 property-gated signals, byte lanes, exclusive access, protection policy effects, and legacy two-bit subordinate HRESP compatibility remain deferred.',
        },
        {
            id     => 'ahb_burst_seq_support_deferred',
            detail => $hburst_busy_park_selected
                ? 'The interconnect decodes active transfers by HTRANS != IDLE and ships subordinate-owned byte-only HBURST WRAP4/INCR4 in-word SEQ propagation with BUSY-in-burst parking for selected aggregate HBURST byte-lane sources; indefinite INCR, WRAP8/INCR8/WRAP16/INCR16, halfword/word burst SEQ, multi-word/register-bank SEQ progression, and broader manager/subordinate behavior remain future work.'
                : $hburst_seq_policy_selected
                ? 'The interconnect decodes active transfers by HTRANS != IDLE and ships subordinate-owned byte-only HBURST WRAP4/INCR4 in-word SEQ propagation for selected aggregate HBURST byte-lane sources; indefinite INCR, WRAP8/INCR8/WRAP16/INCR16, halfword/word burst SEQ, BUSY-in-burst handling, multi-word/register-bank SEQ progression, and broader manager/subordinate behavior remain future work.'
                : $seq_policy_selected
                ? 'The interconnect decodes active transfers by HTRANS != IDLE and ships subordinate-owned byte/halfword in-word SEQ continuation for selected aggregate byte-lane sources; HBURST-driven length/wrap semantics, BUSY-in-burst handling, multi-word/register-bank SEQ progression, wrapping/incrementing burst address progression beyond requester generation, and broader manager/subordinate behavior remain future work.'
                : 'The interconnect decodes active transfers by HTRANS != IDLE and leaves burst SEQ continuation policy, wrapping/incrementing burst address progression beyond requester generation, and broader manager/subordinate behavior to future work.',
        },
        {
            id     => 'ahb_direct_backend_deferred',
            detail => 'Direct IAL2-to-backend lowering remains forbidden; this slice emits reviewable IAL1 and IAL0 artifacts.',
        },
        {
            id     => 'ahb_verification_output_deferred',
            detail => 'Verification-output generation, backend-language variants, AXI, APB, and VHDL remain deferred.',
        },
    ];
}

sub _normalize_children($raw) {
    my $requester = _required_hash($raw, 'requester');
    my @subordinates;
    if (ref($raw->{subordinates}) eq 'ARRAY') {
        @subordinates = @{$raw->{subordinates}};
    } elsif (ref($raw->{subordinate}) eq 'HASH') {
        @subordinates = ($raw->{subordinate});
    } else {
        confess "AHB interconnect children must contain one or two subordinate child bindings\n";
    }
    confess "AHB interconnect children must contain one or two subordinate child bindings\n"
        unless @subordinates == 1 || @subordinates == 2;
    my $requester_child = _normalize_child($requester, 'requester');
    my @subordinate_children = map { _normalize_child($_, 'subordinate') } @subordinates;
    my %seen_instances = ($requester_child->{instance_name} => 1);
    for my $child (@subordinate_children) {
        confess "AHB interconnect child instance aliases must be unique\n"
            if $seen_instances{$child->{instance_name}}++;
    }
    return {
        requester    => $requester_child,
        subordinate  => $subordinate_children[0],
        subordinates => \@subordinate_children,
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

sub _normalize_address_map($raw, $subordinate_children) {
    my $name = _required_identifier($raw, 'name');
    my $windows = $raw->{windows};
    confess "AHB interconnect address_map.windows must contain one window per subordinate child in this slice\n"
        unless ref($windows) eq 'ARRAY'
            && (@$windows == 1 || @$windows == 2)
            && @$windows == @$subordinate_children;

    my %child_instances = map { $_->{instance_name} => 1 } @$subordinate_children;
    my %seen_windows;
    my %seen_parameters;
    my @normalized_windows;
    for my $index (0 .. $#$windows) {
        my $window = $windows->[$index];
        confess "AHB interconnect address_map.windows[$index] must be a hash reference\n"
            unless ref($window) eq 'HASH';
        my $window_name = _required_identifier($window, 'name');
        confess "AHB interconnect duplicate address-map window '$window_name'\n"
            if $seen_windows{$window_name}++;
        confess "AHB interconnect address-map window '$window_name' must match subordinate child instance '$subordinate_children->[0]{instance_name}'\n"
            if @$subordinate_children == 1 && !$child_instances{$window_name};
        confess "AHB interconnect address-map window '$window_name' does not match a subordinate child instance\n"
            unless $child_instances{$window_name};
        my $base = _normalize_address_parameter($window->{base}, "address_map.windows[$index].base", 1);
        my $size = _normalize_address_parameter($window->{size}, "address_map.windows[$index].size", 0);
        for my $parameter ($base, $size) {
            confess "AHB interconnect duplicate address-map parameter '$parameter->{name}'\n"
                if $seen_parameters{$parameter->{name}}++;
        }
        confess "AHB interconnect address-map base '$base->{default}' must be 4-byte aligned\n"
            unless $base->{default} % 4 == 0;
        confess "AHB interconnect address-map size '$size->{default}' must be positive and 4-byte aligned\n"
            unless $size->{default} > 0 && $size->{default} % 4 == 0;
        confess "AHB interconnect address-map window '$window_name' overflows 32-bit address space\n"
            if $base->{default} + $size->{default} > 4_294_967_296;
        push @normalized_windows, {
            name  => $window_name,
            base  => $base,
            size  => $size,
            limit => $base->{default} + $size->{default},
        };
    }
    for my $child (@$subordinate_children) {
        confess "AHB interconnect address-map is missing a window for subordinate '$child->{instance_name}'\n"
            unless $seen_windows{$child->{instance_name}};
    }
    for my $left_index (0 .. $#normalized_windows) {
        for my $right_index ($left_index + 1 .. $#normalized_windows) {
            my $left = $normalized_windows[$left_index];
            my $right = $normalized_windows[$right_index];
            next if $left->{limit} <= $right->{base}{default}
                || $right->{limit} <= $left->{base}{default};
            confess "AHB interconnect address-map windows '$left->{name}' and '$right->{name}' overlap\n";
        }
    }

    return {
        name            => $name,
        address_width   => 32,
        alignment_bytes => 4,
        windows         => \@normalized_windows,
    };
}

sub _normalize_address_parameter($raw, $field, $allow_zero) {
    confess "AHB interconnect $field must be a parameter/width/default hash reference\n"
        unless ref($raw) eq 'HASH';
    my $name = _identifier_value($raw->{name}, "$field.name");
    my $width = _positive_integer($raw->{width}, "$field.width");
    confess "AHB interconnect $field.width must be 32 in this slice\n"
        unless $width == 32;
    my $default = _nonnegative_integer($raw->{default}, "$field.default");
    confess "AHB interconnect $field.default must be positive in this slice\n"
        if !$allow_zero && $default == 0;
    confess "AHB interconnect $field.default must fit in 32 bits in this slice\n"
        if $default > 0xffffffff;
    return {
        name    => $name,
        width   => $width,
        default => $default,
    };
}

sub _normalize_decode($raw) {
    my $overlap = _nonempty_scalar($raw->{overlap}, 'decode.overlap');
    my $priority = _nonempty_scalar($raw->{priority}, 'decode.priority');
    my $unmapped_address = _nonempty_scalar($raw->{unmapped_address}, 'decode.unmapped_address');
    confess "AHB interconnect decode.overlap must be reject in this slice\n"
        unless $overlap eq 'reject';
    confess "AHB interconnect decode.priority must be source-order in this slice\n"
        unless $priority eq 'source-order';
    confess "AHB interconnect decode.unmapped_address must be error in this slice\n"
        unless $unmapped_address eq 'error';
    return {
        overlap          => $overlap,
        priority         => $priority,
        unmapped_address => $unmapped_address,
    };
}

sub _validate_endpoint_role($endpoint, $role, $kind) {
    confess "AHB interconnect IAL2 contract requires $role endpoint kind $kind\n"
        unless ($endpoint->{kind} // '') eq $kind;
    confess "AHB interconnect IAL2 contract requires endpoint '$endpoint->{name}' role $role\n"
        unless lc($endpoint->{role} // '') eq $role;
}

sub _validate_shared_system_ports($clock, $reset, $requester, $subordinates) {
    for my $entry (
        ['requester', $requester],
        (map { ['subordinate', $_] } @$subordinates),
    ) {
        my ($role, $endpoint) = @$entry;
        confess "AHB interconnect IAL2 contract requires shared clock '$clock'; $role uses '$endpoint->{clock}'\n"
            unless ($endpoint->{clock} // '') eq $clock;
        confess "AHB interconnect IAL2 contract requires shared reset '$reset->{signal}'; $role has incompatible reset policy\n"
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

sub _validate_child_references($children, $requester, $subordinates) {
    confess "AHB interconnect requester child references '$children->{requester}{object_name}', expected '$requester->{name}'\n"
        unless $children->{requester}{object_name} eq $requester->{name};
    my %subordinate_by_name;
    for my $subordinate (@$subordinates) {
        confess "AHB interconnect duplicate subordinate object '$subordinate->{name}'\n"
            if $subordinate_by_name{$subordinate->{name}}++;
    }

    my %seen_instances = ($children->{requester}{instance_name} => 1);
    my %referenced_objects;
    for my $child (@{$children->{subordinates}}) {
        confess "AHB interconnect child instance aliases must be unique\n"
            if $seen_instances{$child->{instance_name}}++;
        confess "AHB interconnect subordinate child references unknown object '$child->{object_name}'\n"
            unless $subordinate_by_name{$child->{object_name}};
        confess "AHB interconnect duplicate subordinate child object reference '$child->{object_name}'\n"
            if $referenced_objects{$child->{object_name}}++;
    }
    for my $subordinate (@$subordinates) {
        confess "AHB interconnect subordinate object '$subordinate->{name}' is not referenced by a child\n"
            unless $referenced_objects{$subordinate->{name}};
    }
}

sub _validate_bus_compatibility($wiring, $requester_bus, $subordinates) {
    _require_matching_scalar_bus_field('grant', $wiring, $requester_bus);
    _require_matching_scalar_bus_field('request', $wiring, $requester_bus);
    _require_matching_scalar_bus_field('lock', $wiring, $requester_bus);
    _require_matching_scalar_bus_field('ready', $wiring, $requester_bus);
    _require_matching_scalar_bus_field('write', $wiring, $requester_bus);

    for my $field (qw(response read_data address transfer size write_data)) {
        _require_matching_width_bus_field($field, $wiring, $requester_bus);
    }
    for my $field (qw(burst protection)) {
        _require_matching_width_bus_field($field, $wiring, $requester_bus);
    }

    my %local_names;
    for my $subordinate (@$subordinates) {
        my $subordinate_bus = $subordinate->{bus};
        _require_matching_scalar_bus_field('ready', $wiring, { ready => $subordinate_bus->{ready_in} });
        _require_matching_scalar_bus_field('write', $wiring, $subordinate_bus);
        for my $field (qw(transfer size write_data)) {
            _require_matching_width_bus_field($field, $wiring, $subordinate_bus);
        }
        _require_width_binding($subordinate_bus->{burst}, 'subordinate.bus.burst', 3)
            if ref($subordinate_bus->{burst}) eq 'HASH';
        _require_width_binding($subordinate_bus->{address}, 'subordinate.bus.address', 32);
        _require_width_binding($subordinate_bus->{response}, 'subordinate.bus.response', 1);
        _require_width_binding($subordinate_bus->{read_data}, 'subordinate.bus.read_data', 32);
        for my $signal (
            $subordinate_bus->{select},
            $subordinate_bus->{address}{name},
            (ref($subordinate_bus->{burst}) eq 'HASH' ? $subordinate_bus->{burst}{name} : ()),
            $subordinate_bus->{ready_out},
            $subordinate_bus->{response}{name},
            $subordinate_bus->{read_data}{name},
        ) {
            confess "AHB interconnect duplicate subordinate local signal '$signal'\n"
                if $local_names{$signal}++;
        }
    }

    if (@$subordinates == 1) {
        my $subordinate_bus = $subordinates->[0]{bus};
        _require_matching_scalar_bus_field('subordinate_select', $wiring, { subordinate_select => $subordinate_bus->{select} });
        _require_matching_scalar_bus_field('subordinate_ready_out', $wiring, { subordinate_ready_out => $subordinate_bus->{ready_out} });
        _require_matching_width_bus_field('subordinate_response', $wiring, { subordinate_response => $subordinate_bus->{response} });
        _require_matching_width_bus_field('subordinate_read_data', $wiring, { subordinate_read_data => $subordinate_bus->{read_data} });
    } else {
        for my $field (qw(subordinate_select subordinate_ready_out subordinate_response subordinate_read_data)) {
            confess "AHB interconnect two-subordinate wiring must omit scalar bus.$field; use each subordinate bus block for per-subordinate signals\n"
                if exists $wiring->{$field};
        }
    }
}

sub _validate_aggregate_seq_policy_family($subordinates) {
    my @hburst_requested = grep { _subordinate_requests_hburst_seq_policy($_) } @$subordinates;
    return unless @hburst_requested;

    for my $subordinate (@$subordinates) {
        confess "AHB interconnect aggregate hburst-in-word-progressive sources require every subordinate child to use transfer ahb_lite_byte_lane_hburst_seq_access with bus.burst width 3\n"
            unless _subordinate_has_hburst_seq_policy($subordinate);
    }
}

sub _require_matching_scalar_bus_field($field, @buses) {
    my $expected = $buses[0]->{$field};
    for my $bus (@buses) {
        confess "AHB interconnect IAL2 contract bus.$field must be scalar signal '$expected'\n"
            unless defined($bus->{$field}) && !ref($bus->{$field}) && $bus->{$field} eq $expected;
    }
}

sub _require_matching_width_bus_field($field, @buses) {
    my $expected = $buses[0]->{$field};
    confess "AHB interconnect IAL2 contract bus.$field must be a signal/width binding\n"
        unless ref($expected) eq 'HASH';
    for my $bus (@buses) {
        confess "AHB interconnect IAL2 contract bus.$field must match signal '$expected->{name}' width '$expected->{width}'\n"
            unless ref($bus->{$field}) eq 'HASH'
                && ($bus->{$field}{name} // '') eq $expected->{name}
                && ($bus->{$field}{width} // '') eq $expected->{width};
    }
}

sub _require_width_binding($binding, $field, $width) {
    confess "AHB interconnect IAL2 contract $field must be a signal/width binding\n"
        unless ref($binding) eq 'HASH';
    confess "AHB interconnect IAL2 contract $field.width must be $width in this slice\n"
        unless ($binding->{width} // '') eq "$width";
}

sub _normalize_reset($raw_reset, $field) {
    confess "AHB interconnect IAL2 contract is missing required $field binding\n"
        unless defined $raw_reset && ref($raw_reset) eq 'HASH';

    my $reset = {
        signal     => _identifier_value($raw_reset->{signal}, "$field.signal"),
        active_low => _bool_value($raw_reset->{active_low}, "$field.active_low"),
        async      => _bool_value($raw_reset->{async}, "$field.async"),
    };
    confess "AHB interconnect IAL2 contract $field must be active_low async in this slice\n"
        unless $reset->{active_low} && $reset->{async};

    return $reset;
}

sub _normalize_source_anchors($anchors) {
    confess "AHB interconnect IAL2 contract source.anchors must be an array reference\n"
        unless ref($anchors) eq 'ARRAY';

    my @normalized;
    for my $index (0 .. $#$anchors) {
        my $anchor = $anchors->[$index];
        confess "AHB interconnect IAL2 contract source.anchors[$index] must be a hash reference\n"
            unless ref($anchor) eq 'HASH';
        my %copy;
        for my $key (sort keys %$anchor) {
            $copy{$key} = _nonempty_scalar($anchor->{$key}, "source.anchors[$index].$key");
        }
        push @normalized, \%copy;
    }

    return \@normalized;
}

sub _local_address_expr($address, $window) {
    return $address
        if $window->{base}{default} == 0;
    return "(- $address $window->{base}{default})";
}

sub _interface_line($direction, $binding) {
    return "    ($direction $binding)"
        unless ref($binding) eq 'HASH';
    return $binding->{width} == 1
        ? "    ($direction $binding->{name})"
        : "    ($direction $binding->{name} (width $binding->{width}))";
}

sub _output_interface_line($binding, $reset, $default) {
    my $name = ref($binding) eq 'HASH' ? $binding->{name} : $binding;
    my $width = ref($binding) eq 'HASH' ? $binding->{width} : 1;
    my $width_clause = $width == 1 ? '' : " (width $width)";
    return "    (output $name$width_clause (reset $reset) (default $default))";
}

sub _reset_clause($reset) {
    my @parts = ($reset->{signal});
    push @parts, $reset->{async} ? 'async' : 'sync';
    push @parts, $reset->{active_low} ? 'active_low' : 'active_high';
    return "(reset (" . join(' ', @parts) . "))";
}

sub _size_line($name, $width, $reset = undef) {
    return defined($reset)
        ? "    ($name $width (reset $reset))"
        : "    ($name $width)";
}

sub _required_hash($raw, $field) {
    confess "AHB interconnect IAL2 contract is missing required hash field '$field'\n"
        unless exists $raw->{$field} && ref($raw->{$field}) eq 'HASH';
    return $raw->{$field};
}

sub _required_scalar($raw, $field) {
    confess "AHB interconnect IAL2 contract is missing required scalar field '$field'\n"
        unless exists($raw->{$field});
    return _nonempty_scalar($raw->{$field}, $field);
}

sub _required_identifier($raw, $field) {
    return _identifier_value(_required_scalar($raw, $field), $field);
}

sub _identifier_value($value, $field) {
    my $text = _nonempty_scalar($value, $field);
    confess "AHB interconnect IAL2 contract $field must be an HDL identifier\n"
        unless $text =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
    return $text;
}

sub _nonempty_scalar($value, $field) {
    confess "AHB interconnect IAL2 contract $field must be a non-empty scalar\n"
        if !defined($value) || ref($value) || $value eq '';
    return $value;
}

sub _positive_integer($value, $field) {
    confess "AHB interconnect IAL2 contract $field must be a positive integer\n"
        if !defined($value) || ref($value) || $value !~ /\A[1-9][0-9]*\z/;
    return int($value);
}

sub _nonnegative_integer($value, $field) {
    confess "AHB interconnect IAL2 contract $field must be a non-negative integer\n"
        if !defined($value) || ref($value) || $value !~ /\A(?:0|[1-9][0-9]*)\z/;
    return int($value);
}

sub _bool_value($value, $field) {
    confess "AHB interconnect IAL2 contract $field must be boolean 0 or 1\n"
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
