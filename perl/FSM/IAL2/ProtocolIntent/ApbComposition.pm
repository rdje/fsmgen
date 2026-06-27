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

    my $source_object_id = exists($source->{object_id})
        ? _nonempty_scalar($source->{object_id}, 'source.object_id')
        : $intent_name;
    my $anchors = exists($source->{anchors})
        ? _normalize_source_anchors($source->{anchors})
        : [];

    return {
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

sub _endpoint_contract($contract, $role) {
    my %endpoint = %{$contract->{$role}};
    $endpoint{protocol} = $contract->{protocol};
    $endpoint{intent_name} = $contract->{intent_name};
    $endpoint{source} = _clone_jsonish($contract->{source});
    return \%endpoint;
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
        _input_port($completer->{control}{wait_cycles}{name}, $completer->{control}{wait_cycles}{width}),
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
        "($completer.$bus->{ready} $requester.$bus->{ready})",
        "($completer.$bus->{read_data}{name} $requester.$bus->{read_data}{name})",
        "($completer.$bus->{error} $requester.$bus->{error})",
    );
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
            'APB composition is exposed through .ppif and bounded .apb profile-alias sources; direct IAL2-to-IAL0 lowering remains forbidden',
        ],
        unsupported_residue => _apb_composition_unsupported_residue($contract),
    };

    $report->{requester_status_field} = _clone_jsonish($requester_result->{report}{response_status_field})
        if defined $requester_result->{report}{response_status_field};

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
        {
            id     => 'apb_protection_and_strobes_deferred',
            detail => 'PPROT, PSTRB, byte-enable policy, and APB4/APB5 sideband behavior remain future APB work.',
        },
        {
            id     => 'apb_alternate_widths_deferred',
            detail => 'The first APB composition fixes address, write-data, and read-data widths to 32 bits and wait_cycles to 4 bits.',
        },
        {
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
    $report->{response_status_field} = _clone_jsonish($result->{report}{response_status_field})
        if defined $result->{report}{response_status_field};

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
