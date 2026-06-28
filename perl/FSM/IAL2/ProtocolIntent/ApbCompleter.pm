package FSM::IAL2::ProtocolIntent::ApbCompleter;

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

sub new($class, @constructor_args) {
    _validate_constructor_receiver($class);
    my %args = _validate_constructor_args($class, @constructor_args);

    return bless {
        debug => $args{debug} // 0,
    }, $class;
}

sub generate($self, @args) {
    _validate_object_receiver($self, 'generate');
    confess "FSM::IAL2::ProtocolIntent::ApbCompleter->generate expects exactly one contract hash reference\n"
        unless @args == 1 && ref($args[0]) eq 'HASH';

    my $contract = _normalize_contract($args[0]);
    my $isf_text = _emit_isf($contract);
    my $isf_name = "$contract->{actor_name}.isf";

    my $adapter = FSM::Adapter::ISF->new(debug => $self->{debug});
    my $actor = $adapter->parse_source($isf_text, $isf_name);

    my $scheduler = FSM::Scheduler::ISF->new(debug => $self->{debug});
    my $lowered = $scheduler->lower($actor);
    my $schedule_report_json = $scheduler->report($actor);
    my $schedule_report = JSON::PP->new->decode($schedule_report_json);

    my $report = _build_report(
        contract => $contract,
        isf_name => $isf_name,
        fsm_files => [sort keys %{$lowered->{files} || {}}],
    );

    return {
        layer => 'IAL2',
        kind  => 'protocol_intent.apb_completer',
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
    confess "FSM::IAL2::ProtocolIntent::ApbCompleter->new must be called with the FSM::IAL2::ProtocolIntent::ApbCompleter class invocant\n"
        unless defined($class) && !ref($class) && $class eq 'FSM::IAL2::ProtocolIntent::ApbCompleter';
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
    confess "FSM::IAL2::ProtocolIntent::ApbCompleter->$method must be called on an FSM::IAL2::ProtocolIntent::ApbCompleter object\n"
        unless blessed($self) && $self->isa('FSM::IAL2::ProtocolIntent::ApbCompleter');
}

sub _normalize_contract($raw) {
    my $kind = _required_scalar($raw, 'kind');
    confess "APB completer IAL2 contract kind must be apb_completer\n"
        unless $kind eq 'apb_completer';

    my $protocol = lc _required_scalar($raw, 'protocol');
    confess "APB completer IAL2 contract profile must be apb\n"
        unless $protocol eq 'apb';

    my $name = _required_identifier($raw, 'name');
    my $actor_name = exists($raw->{actor_name})
        ? _identifier_value($raw->{actor_name}, 'actor_name')
        : $name;
    my $role = lc _required_scalar($raw, 'role');
    confess "APB completer IAL2 contract role must be completer\n"
        unless $role eq 'completer';

    my $clock = _required_identifier($raw, 'clock');
    my $reset = _normalize_reset($raw->{reset});
    my $control = _normalize_control(_required_hash($raw, 'control'));
    my $bus = _normalize_bus(_required_hash($raw, 'bus'));
    _validate_sideband_bundle($bus);
    _validate_width_policy($bus);
    my $storage = _normalize_storage(_required_hash($raw, 'storage'), $bus);
    _validate_access_policy_contract($storage, $bus);
    my $transfer = _normalize_transfer(_required_hash($raw, 'transfer'), $control, $storage);
    _validate_timing_policy_contract($bus, $storage, $transfer);

    _reject_duplicate_signal_names(
        $clock,
        $reset->{signal},
        $control->{wait_cycles}{name},
        $bus->{select},
        $bus->{enable},
        $bus->{write},
        $bus->{address}{name},
        $bus->{write_data}{name},
        (defined($bus->{protection}) ? ($bus->{protection}{name}) : ()),
        (defined($bus->{strobe}) ? ($bus->{strobe}{name}) : ()),
        $bus->{ready},
        $bus->{read_data}{name},
        $bus->{error},
        (map { $_->{data}{name} } _storage_registers($storage)),
        qw(addr write_q wdata_q prot_q strb_q wait_n apb_complete_done_q),
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
        control          => $control,
        bus              => $bus,
        storage          => $storage,
        transfer         => $transfer,
        intent_name      => $intent_name,
        source_object_id => $source_object_id,
        source_anchors   => $anchors,
    };
}

sub _normalize_control($raw) {
    return {
        wait_cycles => _normalize_width_binding($raw->{wait_cycles}, 'control.wait_cycles', 4),
    };
}

sub _normalize_bus($raw) {
    my %bus = (
        select     => _required_identifier_field($raw, 'select', 'bus.select'),
        enable     => _required_identifier_field($raw, 'enable', 'bus.enable'),
        write      => _required_identifier_field($raw, 'write', 'bus.write'),
        address    => _normalize_width_binding($raw->{address}, 'bus.address', 32),
        write_data => _normalize_width_binding_one_of($raw->{write_data}, 'bus.write_data', [16, 32]),
        ready      => _required_identifier_field($raw, 'ready', 'bus.ready'),
        read_data  => _normalize_width_binding_one_of($raw->{read_data}, 'bus.read_data', [16, 32]),
        error      => _required_identifier_field($raw, 'error', 'bus.error'),
    );
    $bus{protection} = _normalize_width_binding($raw->{protection}, 'bus.protection', 3)
        if exists $raw->{protection};
    $bus{strobe} = _normalize_width_binding_one_of($raw->{strobe}, 'bus.strobe', [2, 4])
        if exists $raw->{strobe};
    return \%bus;
}

sub _validate_sideband_bundle($bus) {
    my @present = grep { defined } ($bus->{protection}, $bus->{strobe});
    return unless @present;

    confess "APB completer IAL2 sideband contract requires bus.protection and bus.strobe together in this slice\n"
        unless @present == 2;
}

sub _validate_width_policy($bus) {
    my $data_width = $bus->{write_data}{width};
    confess "APB completer IAL2 contract bus.read_data.width must match selected APB data width $data_width in this slice\n"
        unless $bus->{read_data}{width} == $data_width;
    confess "APB completer IAL2 contract data width must be 16 or 32 in this slice\n"
        unless $data_width == 16 || $data_width == 32;

    my $sidebands = defined($bus->{protection}) && defined($bus->{strobe});
    confess "APB completer IAL2 contract 16-bit APB data width requires sideband-aware PPROT/PSTRB bindings in this slice\n"
        if $data_width == 16 && !$sidebands;
    return unless $sidebands;

    my $expected_strobe_width = _apb_strobe_width_for_data_width($data_width);
    confess "APB completer IAL2 contract bus.strobe.width must be $expected_strobe_width for selected APB data width $data_width in this slice\n"
        unless $bus->{strobe}{width} == $expected_strobe_width;
}

sub _normalize_storage($raw, $bus) {
    confess "APB completer IAL2 contract storage must not provide both register and registers fields\n"
        if exists($raw->{register}) && exists($raw->{registers});
    my $data_width = $bus->{write_data}{width};
    my $address_alignment = _apb_strobe_width_for_data_width($data_width);
    if (exists $raw->{registers}) {
        confess "APB completer IAL2 contract storage.registers must be a non-empty array reference\n"
            unless ref($raw->{registers}) eq 'ARRAY' && @{$raw->{registers}};
        return _normalize_multi_register_storage($raw->{registers}, $data_width, $address_alignment);
    }

    confess "APB completer IAL2 contract storage.register must be a hash reference\n"
        unless ref($raw->{register}) eq 'HASH';
    my $register = $raw->{register};
    my $name = _required_identifier_field($register, 'name', 'storage.register.name');
    my $address = _normalize_address_binding($register->{address}, 'storage.register.address', 0, 32);
    my $data = _normalize_storage_data($register->{data}, 'storage.register.data', $data_width, 0);
    my @access_policy = exists($register->{access_policy})
        ? (access_policy => _normalize_access_policy($register->{access_policy}, 'storage.register.access_policy'))
        : ();

    return {
        register => {
            name          => $name,
            address       => $address,
            data          => $data,
            @access_policy,
        },
    };
}

sub _normalize_multi_register_storage($registers, $data_width, $address_alignment) {
    my (@normalized, %register_names, %data_names, %address_values);
    for my $index (0 .. $#$registers) {
        my $register = $registers->[$index];
        confess "APB completer IAL2 contract storage.registers[$index] must be a hash reference\n"
            unless ref($register) eq 'HASH';
        my $name = _required_identifier_field($register, 'name', "storage.registers[$index].name");
        confess "APB completer IAL2 contract duplicate storage register name '$name'\n"
            if $register_names{$name}++;
        my $address = _normalize_decoded_address_binding($register->{address}, "storage.registers[$index].address", $address_alignment);
        confess "APB completer IAL2 contract duplicate storage register address '$address->{value}'\n"
            if $address_values{$address->{value}}++;
        my $data = _normalize_storage_data($register->{data}, "storage.registers[$index].data", $data_width, 0);
        confess "APB completer IAL2 contract duplicate storage register data signal '$data->{name}'\n"
            if $data_names{$data->{name}}++;
        my @access_policy = exists($register->{access_policy})
            ? (access_policy => _normalize_access_policy($register->{access_policy}, "storage.registers[$index].access_policy"))
            : ();
        push @normalized, {
            name          => $name,
            address       => $address,
            data          => $data,
            @access_policy,
        };
    }

    return @normalized == 1
        ? { register => $normalized[0] }
        : { registers => \@normalized };
}

sub _normalize_storage_data($raw, $field, $expected_width, $expected_reset) {
    confess "APB completer IAL2 contract $field must be a signal/width/reset hash reference\n"
        unless ref($raw) eq 'HASH';
    my $binding = _normalize_width_binding($raw, $field, $expected_width);
    my $reset = _integer_value($raw->{reset}, "$field.reset");
    confess "APB completer IAL2 contract $field.reset must be $expected_reset in this slice\n"
        unless $reset == $expected_reset;
    return {
        %$binding,
        reset => $reset,
    };
}

sub _normalize_access_policy($raw, $field) {
    confess "APB completer IAL2 contract $field must be an access-policy hash reference\n"
        unless ref($raw) eq 'HASH';

    my %policy;
    for my $operation (qw(read write)) {
        confess "APB completer IAL2 contract $field.$operation is required in this slice\n"
            unless exists $raw->{$operation};
        $policy{$operation} = _normalize_access_policy_action($raw->{$operation}, "$field.$operation");
    }

    for my $key (sort keys %$raw) {
        confess "APB completer IAL2 contract $field has unsupported operation '$key'\n"
            unless $key eq 'read' || $key eq 'write';
    }

    return \%policy;
}

sub _normalize_access_policy_action($raw, $field) {
    confess "APB completer IAL2 contract $field must be an access-policy action hash reference\n"
        unless ref($raw) eq 'HASH';
    my $action = _required_scalar_field($raw, 'action', "$field.action");
    if ($action eq 'allow') {
        confess "APB completer IAL2 contract $field action allow must not provide a predicate\n"
            if exists $raw->{predicate};
        return { action => 'allow' };
    }

    confess "APB completer IAL2 contract $field action must be allow or require in this slice\n"
        unless $action eq 'require';
    my $predicate = _normalize_access_policy_predicate(_required_hash_field($raw, 'predicate', "$field.predicate"), "$field.predicate");

    for my $key (sort keys %$raw) {
        confess "APB completer IAL2 contract $field has unsupported key '$key'\n"
            unless $key eq 'action' || $key eq 'predicate';
    }

    return {
        action    => 'require',
        predicate => $predicate,
    };
}

sub _normalize_access_policy_predicate($raw, $field) {
    my $kind = _required_scalar_field($raw, 'kind', "$field.kind");
    confess "APB completer IAL2 contract $field.kind must be privileged in this slice\n"
        unless $kind eq 'privileged';
    my $value = _bool_value($raw->{value}, "$field.value");

    for my $key (sort keys %$raw) {
        confess "APB completer IAL2 contract $field has unsupported key '$key'\n"
            unless $key eq 'kind' || $key eq 'value';
    }

    return {
        kind  => $kind,
        value => $value,
    };
}

sub _validate_access_policy_contract($storage, $bus) {
    return unless _storage_has_access_policy($storage);
    confess "APB completer IAL2 contract access-policy requires multi-register storage in this slice\n"
        unless _storage_is_multi_register($storage);
    confess "APB completer IAL2 contract access-policy requires bus.protection and bus.strobe sideband bindings in this slice\n"
        unless defined($bus->{protection}) && defined($bus->{strobe});
    confess "APB completer IAL2 contract access-policy requires selected 16-bit or 32-bit APB data width in this slice\n"
        unless $bus->{write_data}{width} == 16 || $bus->{write_data}{width} == 32;
}

sub _normalize_address_binding($raw, $field, $expected_value, $expected_width) {
    confess "APB completer IAL2 contract $field must be an address/width hash reference\n"
        unless ref($raw) eq 'HASH';
    my $value = _integer_value($raw->{value}, "$field.value");
    my $width = _positive_integer($raw->{width}, "$field.width");
    confess "APB completer IAL2 contract $field.value must be $expected_value in this slice\n"
        unless $value == $expected_value;
    confess "APB completer IAL2 contract $field.width must be $expected_width in this slice\n"
        unless $width == $expected_width;
    return {
        value => $value,
        width => $width,
    };
}

sub _normalize_decoded_address_binding($raw, $field, $address_alignment) {
    confess "APB completer IAL2 contract $field must be an address/width hash reference\n"
        unless ref($raw) eq 'HASH';
    my $value = _integer_value($raw->{value}, "$field.value");
    my $width = _positive_integer($raw->{width}, "$field.width");
    confess "APB completer IAL2 contract $field.width must be 32 in this slice\n"
        unless $width == 32;
    confess "APB completer IAL2 contract $field.value must fit in 32 bits in this slice\n"
        if $value > 0xffffffff;
    confess "APB completer IAL2 contract $field.value must be $address_alignment-byte aligned in this slice\n"
        unless $value % $address_alignment == 0;
    return {
        value => $value,
        width => $width,
    };
}

sub _normalize_transfer($raw, $control, $storage) {
    my $name = _required_identifier_field($raw, 'name', 'transfer.name');
    my $setup_detect = _normalize_phase(_required_hash_field($raw, 'setup_detect', 'transfer.setup_detect'), 'transfer.setup_detect');
    my $wait_cycles = _required_identifier_field($raw, 'wait_cycles', 'transfer.wait_cycles');
    my $read = _required_scalar_field($raw, 'read', 'transfer.read');
    my $write = _required_scalar_field($raw, 'write', 'transfer.write');
    my $unmapped_address = _required_scalar_field($raw, 'unmapped_address', 'transfer.unmapped_address');
    my $timing_policy = exists($raw->{timing_policy})
        ? _normalize_timing_policy(_required_hash_field($raw, 'timing_policy', 'transfer.timing_policy'))
        : undef;

    _require_static_value($setup_detect->{select}, 1, 'transfer.setup_detect.select');
    _require_static_value($setup_detect->{enable}, 0, 'transfer.setup_detect.enable');
    confess "APB completer IAL2 contract transfer.wait_cycles must name the control.wait_cycles signal\n"
        unless $wait_cycles eq $control->{wait_cycles}{name};
    confess "APB completer IAL2 contract transfer.read must be register in this slice\n"
        unless $read eq 'register';
    confess "APB completer IAL2 contract transfer.write must be register in this slice\n"
        unless $write eq 'register';
    confess "APB completer IAL2 contract transfer.unmapped_address must be error in this slice\n"
        unless $unmapped_address eq 'error';

    my %transfer = (
        name             => $name,
        setup_detect     => $setup_detect,
        wait_cycles      => $wait_cycles,
        read             => $read,
        write            => $write,
        unmapped_address => $unmapped_address,
        (defined($timing_policy) ? (timing_policy => $timing_policy) : ()),
    );
    if (_storage_is_multi_register($storage)) {
        $transfer{registers} = [map { $_->{name} } _storage_registers($storage)];
    } else {
        my ($register) = _storage_registers($storage);
        $transfer{register} = $register->{name};
    }

    return \%transfer;
}

sub _normalize_timing_policy($raw) {
    my $setup_admission = _required_scalar_field($raw, 'setup_admission', 'transfer.timing_policy.setup_admission');
    confess "APB completer IAL2 contract transfer.timing_policy.setup_admission must be adjacent in this slice\n"
        unless $setup_admission eq 'adjacent';

    for my $key (sort keys %$raw) {
        confess "APB completer IAL2 contract transfer.timing_policy has unsupported key '$key'\n"
            unless $key eq 'setup_admission';
    }

    return {
        setup_admission => $setup_admission,
    };
}

sub _validate_timing_policy_contract($bus, $storage, $transfer) {
    return unless exists $transfer->{timing_policy};

    my $is_no_sideband_family = $bus->{write_data}{width} == 32
        && $bus->{read_data}{width} == 32
        && !defined($bus->{protection})
        && !defined($bus->{strobe});
    my $is_sideband_family = $bus->{write_data}{width} == 32
        && $bus->{read_data}{width} == 32
        && defined($bus->{protection})
        && defined($bus->{strobe})
        && $bus->{protection}{width} == 3
        && $bus->{strobe}{width} == 4;
    my $is_sideband_data16_family = $bus->{write_data}{width} == 16
        && $bus->{read_data}{width} == 16
        && defined($bus->{protection})
        && defined($bus->{strobe})
        && $bus->{protection}{width} == 3
        && $bus->{strobe}{width} == 2;
    my $is_one_register = !_storage_is_multi_register($storage);
    my $is_selected_sideband_multi_register = $is_sideband_family
        && _storage_is_selected_sideband_multi_register_timing_shape($storage);
    my $is_selected_sideband_generalized_no_policy_register_set = $is_sideband_family
        && _storage_is_selected_sideband_generalized_no_policy_register_set_timing_shape($storage);
    my $is_selected_sideband_protection_generalized_register_set = $is_sideband_family
        && _storage_is_selected_sideband_protection_generalized_register_set_timing_shape($storage);
    my $is_selected_sideband_protection_multi_register = $is_sideband_family
        && _storage_is_selected_sideband_protection_multi_register_timing_shape($storage);
    my $is_selected_sideband_protection_multi_peripheral_register = $is_sideband_family
        && (
            _storage_is_selected_sideband_protection_multi_peripheral_status_timing_shape($storage)
            || _storage_is_selected_sideband_protection_multi_peripheral_control_timing_shape($storage)
        );
    my $is_selected_sideband_data16_multi_register = $is_sideband_data16_family
        && _storage_is_selected_sideband_data16_multi_register_timing_shape($storage);
    my $is_selected_sideband_data16_generalized_no_policy_register_set = $is_sideband_data16_family
        && _storage_is_selected_sideband_data16_generalized_no_policy_register_set_timing_shape($storage);
    my $is_selected_sideband_data16_protection_generalized_register_set = $is_sideband_data16_family
        && _storage_is_selected_sideband_data16_protection_generalized_register_set_timing_shape($storage);
    my $is_selected_sideband_data16_protection_multi_register = $is_sideband_data16_family
        && _storage_is_selected_sideband_data16_protection_multi_register_timing_shape($storage);
    my $is_selected_sideband_data16_protection_multi_peripheral_register = $is_sideband_data16_family
        && (
            _storage_is_selected_sideband_data16_protection_multi_peripheral_status_timing_shape($storage)
            || _storage_is_selected_sideband_data16_protection_multi_peripheral_control_timing_shape($storage)
        );
    confess "APB completer IAL2 contract selected setup-admission adjacent policy supports only the selected 32-bit no-sideband one-register, selected 32-bit sideband-aware one-register, selected 32-bit sideband-aware two-register no-policy, selected 32-bit sideband-aware generalized no-policy reg0..regN register-set, selected 32-bit sideband-aware two-register protection, selected 32-bit sideband-aware protected generalized reg0..regN register-set, selected 32-bit sideband-aware protection status/control peripheral, selected sideband-aware data16 two-register no-policy, selected sideband-aware data16 generalized no-policy reg0..regN register-set, selected sideband-aware data16 two-register protection, selected sideband-aware data16 protected generalized reg0..regN register-set, or selected sideband-aware data16 protection status/control peripheral completer families in this slice\n"
        unless ($is_one_register && ($is_no_sideband_family || $is_sideband_family))
            || $is_selected_sideband_multi_register
            || $is_selected_sideband_generalized_no_policy_register_set
            || $is_selected_sideband_protection_generalized_register_set
            || $is_selected_sideband_protection_multi_register
            || $is_selected_sideband_protection_multi_peripheral_register
            || $is_selected_sideband_data16_multi_register
            || $is_selected_sideband_data16_generalized_no_policy_register_set
            || $is_selected_sideband_data16_protection_generalized_register_set
            || $is_selected_sideband_data16_protection_multi_register
            || $is_selected_sideband_data16_protection_multi_peripheral_register;
}

sub _normalize_phase($raw, $field) {
    return {
        select => _integer_value($raw->{select}, "$field.select"),
        enable => _integer_value($raw->{enable}, "$field.enable"),
    };
}

sub _normalize_width_binding($raw, $field, $expected_width) {
    confess "APB completer IAL2 contract $field must be a signal/width hash reference\n"
        unless ref($raw) eq 'HASH';
    my $name = _identifier_value($raw->{name}, "$field.name");
    my $width = _positive_integer($raw->{width}, "$field.width");
    confess "APB completer IAL2 contract $field.width must be $expected_width in this slice\n"
        unless $width == $expected_width;
    return {
        name  => $name,
        width => $width,
    };
}

sub _normalize_width_binding_one_of($raw, $field, $allowed_widths) {
    confess "APB completer IAL2 contract $field must be a signal/width hash reference\n"
        unless ref($raw) eq 'HASH';
    my $name = _identifier_value($raw->{name}, "$field.name");
    my $width = _positive_integer($raw->{width}, "$field.width");
    my %allowed = map { $_ => 1 } @$allowed_widths;
    confess "APB completer IAL2 contract $field.width must be one of " . join(', ', @$allowed_widths) . " in this slice\n"
        unless $allowed{$width};
    return {
        name  => $name,
        width => $width,
    };
}

sub _normalize_reset($raw_reset) {
    confess "APB completer IAL2 contract is missing required reset binding\n"
        unless defined $raw_reset && ref($raw_reset) eq 'HASH';

    my $reset = {
        signal     => _identifier_value($raw_reset->{signal}, 'reset.signal'),
        active_low => _bool_value($raw_reset->{active_low}, 'reset.active_low'),
        async      => _bool_value($raw_reset->{async}, 'reset.async'),
    };
    confess "APB completer IAL2 contract reset must be active_low async in this slice\n"
        unless $reset->{active_low} && $reset->{async};

    return $reset;
}

sub _required_hash($raw, $field) {
    confess "APB completer IAL2 contract is missing required hash field '$field'\n"
        unless exists $raw->{$field} && ref($raw->{$field}) eq 'HASH';
    return $raw->{$field};
}

sub _required_hash_field($raw, $key, $field) {
    confess "APB completer IAL2 contract is missing required hash field '$field'\n"
        unless exists $raw->{$key} && ref($raw->{$key}) eq 'HASH';
    return $raw->{$key};
}

sub _required_scalar($raw, $field) {
    confess "APB completer IAL2 contract is missing required scalar field '$field'\n"
        unless exists($raw->{$field});
    return _nonempty_scalar($raw->{$field}, $field);
}

sub _required_scalar_field($raw, $key, $field) {
    confess "APB completer IAL2 contract is missing required scalar field '$field'\n"
        unless exists($raw->{$key});
    return _nonempty_scalar($raw->{$key}, $field);
}

sub _required_identifier($raw, $field) {
    return _identifier_value(_required_scalar($raw, $field), $field);
}

sub _required_identifier_field($raw, $key, $field) {
    return _identifier_value(_required_scalar_field($raw, $key, $field), $field);
}

sub _nonempty_scalar($value, $field) {
    confess "APB completer IAL2 contract field '$field' must be a non-empty scalar\n"
        if !defined($value) || ref($value) || $value eq '';
    return $value;
}

sub _identifier_value($value, $field) {
    confess "APB completer IAL2 contract field '$field' must be an ISF identifier\n"
        unless defined($value) && !ref($value) && $value =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
    return $value;
}

sub _positive_integer($value, $field) {
    confess "APB completer IAL2 contract field '$field' must be a positive integer\n"
        if ref($value) || !defined($value) || $value !~ /\A[1-9][0-9]*\z/;
    return int($value);
}

sub _integer_value($value, $field) {
    confess "APB completer IAL2 contract field '$field' must be an integer\n"
        if ref($value) || !defined($value) || $value !~ /\A(?:0|[1-9][0-9]*)\z/;
    return int($value);
}

sub _bool_value($value, $field) {
    confess "APB completer IAL2 contract field '$field' must be boolean 0 or 1\n"
        if ref($value) || !defined($value) || ($value ne '0' && $value ne '1');
    return $value ? 1 : 0;
}

sub _require_static_value($actual, $expected, $field) {
    confess "APB completer IAL2 contract $field must be $expected in this slice\n"
        unless defined($actual) && $actual == $expected;
}

sub _reject_duplicate_signal_names(@names) {
    my %seen;
    for my $name (@names) {
        confess "APB completer IAL2 contract duplicates signal or generated local name '$name'\n"
            if $seen{$name}++;
    }
}

sub _storage_registers($storage) {
    return @{$storage->{registers}} if ref($storage->{registers}) eq 'ARRAY';
    return ($storage->{register}) if ref($storage->{register}) eq 'HASH';
    return ();
}

sub _storage_is_multi_register($storage) {
    return ref($storage->{registers}) eq 'ARRAY' && @{$storage->{registers}} > 1;
}

sub _storage_is_selected_sideband_multi_register_timing_shape($storage) {
    return _storage_is_selected_multi_register_timing_shape($storage, 4, 32);
}

sub _storage_is_selected_sideband_generalized_no_policy_register_set_timing_shape($storage) {
    return _storage_is_selected_generalized_no_policy_register_set_timing_shape($storage, 2, 5, 4, 32);
}

sub _storage_is_selected_sideband_protection_generalized_register_set_timing_shape($storage) {
    return _storage_is_selected_generalized_protection_register_set_timing_shape($storage, 2, 4, 4, 32);
}

sub _storage_is_selected_sideband_protection_multi_register_timing_shape($storage) {
    return 0 unless ref($storage->{registers}) eq 'ARRAY';
    my @registers = @{$storage->{registers}};
    return 0 unless @registers == 2;
    return 0 unless _storage_register_matches_selected_timing_shape($registers[0], 'reg0', 0, 32)
        && _storage_register_matches_selected_timing_shape($registers[1], 'reg1', 4, 32);
    return _access_policy_is_selected_reg0_protection($registers[0])
        && _access_policy_is_selected_reg1_protection($registers[1]);
}

sub _storage_is_selected_sideband_protection_multi_peripheral_status_timing_shape($storage) {
    return 0 unless ref($storage->{registers}) eq 'ARRAY';
    my @registers = @{$storage->{registers}};
    return 0 unless @registers == 2;
    return 0 unless _storage_register_matches_selected_timing_shape($registers[0], 'status_reg', 0, 32)
        && _storage_register_matches_selected_timing_shape($registers[1], 'status_shadow_reg', 4, 32);
    return _access_policy_is_selected_reg0_protection($registers[0])
        && _access_policy_is_selected_reg0_protection($registers[1]);
}

sub _storage_is_selected_sideband_protection_multi_peripheral_control_timing_shape($storage) {
    return 0 unless ref($storage->{registers}) eq 'ARRAY';
    my @registers = @{$storage->{registers}};
    return 0 unless @registers == 2;
    return 0 unless _storage_register_matches_selected_timing_shape($registers[0], 'control_reg', 0, 32)
        && _storage_register_matches_selected_timing_shape($registers[1], 'control_shadow_reg', 4, 32);
    return _access_policy_is_selected_reg1_protection($registers[0])
        && _access_policy_is_selected_reg1_protection($registers[1]);
}

sub _storage_is_selected_sideband_data16_multi_register_timing_shape($storage) {
    return _storage_is_selected_multi_register_timing_shape($storage, 2, 16);
}

sub _storage_is_selected_sideband_data16_generalized_no_policy_register_set_timing_shape($storage) {
    return _storage_is_selected_generalized_no_policy_register_set_timing_shape($storage, 2, 5, 2, 16);
}

sub _storage_is_selected_sideband_data16_protection_generalized_register_set_timing_shape($storage) {
    return _storage_is_selected_generalized_protection_register_set_timing_shape($storage, 2, 4, 2, 16);
}

sub _storage_is_selected_sideband_data16_protection_multi_register_timing_shape($storage) {
    return 0 unless ref($storage->{registers}) eq 'ARRAY';
    my @registers = @{$storage->{registers}};
    return 0 unless @registers == 2;
    return 0 unless _storage_register_matches_selected_timing_shape($registers[0], 'reg0', 0, 16)
        && _storage_register_matches_selected_timing_shape($registers[1], 'reg1', 2, 16);
    return _access_policy_is_selected_reg0_protection($registers[0])
        && _access_policy_is_selected_reg1_protection($registers[1]);
}

sub _storage_is_selected_sideband_data16_protection_multi_peripheral_status_timing_shape($storage) {
    return 0 unless ref($storage->{registers}) eq 'ARRAY';
    my @registers = @{$storage->{registers}};
    return 0 unless @registers == 2;
    return 0 unless _storage_register_matches_selected_timing_shape($registers[0], 'status_reg', 0, 16)
        && _storage_register_matches_selected_timing_shape($registers[1], 'status_shadow_reg', 2, 16);
    return _access_policy_is_selected_reg0_protection($registers[0])
        && _access_policy_is_selected_reg0_protection($registers[1]);
}

sub _storage_is_selected_sideband_data16_protection_multi_peripheral_control_timing_shape($storage) {
    return 0 unless ref($storage->{registers}) eq 'ARRAY';
    my @registers = @{$storage->{registers}};
    return 0 unless @registers == 2;
    return 0 unless _storage_register_matches_selected_timing_shape($registers[0], 'control_reg', 0, 16)
        && _storage_register_matches_selected_timing_shape($registers[1], 'control_shadow_reg', 2, 16);
    return _access_policy_is_selected_reg1_protection($registers[0])
        && _access_policy_is_selected_reg1_protection($registers[1]);
}

sub _storage_is_selected_multi_register_timing_shape($storage, $reg1_address, $data_width) {
    return 0 unless ref($storage->{registers}) eq 'ARRAY';
    my @registers = @{$storage->{registers}};
    return 0 unless @registers == 2;
    return 0 if grep { ref($_) ne 'HASH' || exists $_->{access_policy} } @registers;
    return _storage_register_matches_selected_timing_shape($registers[0], 'reg0', 0, $data_width)
        && _storage_register_matches_selected_timing_shape($registers[1], 'reg1', $reg1_address, $data_width);
}

sub _storage_is_selected_generalized_no_policy_register_set_timing_shape($storage, $minimum_count, $maximum_count, $address_stride, $data_width) {
    return 0 unless ref($storage->{registers}) eq 'ARRAY';
    my @registers = @{$storage->{registers}};
    return 0 unless @registers >= $minimum_count && @registers <= $maximum_count;
    return 0 if grep { ref($_) ne 'HASH' || exists $_->{access_policy} } @registers;
    for my $index (0 .. $#registers) {
        return 0 unless _storage_register_matches_selected_timing_shape(
            $registers[$index],
            "reg$index",
            $index * $address_stride,
            $data_width,
        );
    }
    return 1;
}

sub _storage_is_selected_generalized_protection_register_set_timing_shape($storage, $minimum_count, $maximum_count, $address_stride, $data_width) {
    return 0 unless ref($storage->{registers}) eq 'ARRAY';
    my @registers = @{$storage->{registers}};
    return 0 unless @registers >= $minimum_count && @registers <= $maximum_count;
    for my $index (0 .. $#registers) {
        return 0 unless _storage_register_matches_selected_timing_shape(
            $registers[$index],
            "reg$index",
            $index * $address_stride,
            $data_width,
        );
        return 0 unless $index == 0
            ? _access_policy_is_selected_reg0_protection($registers[$index])
            : _access_policy_is_selected_reg1_protection($registers[$index]);
    }
    return 1;
}

sub _storage_register_matches_selected_timing_shape($register, $name, $address_value, $data_width) {
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

sub _access_policy_is_selected_reg0_protection($register) {
    my $policy = $register->{access_policy};
    return 0 unless ref($policy) eq 'HASH';
    return _access_policy_operation_is_allow($policy->{read})
        && _access_policy_operation_is_privileged($policy->{write}, 1);
}

sub _access_policy_is_selected_reg1_protection($register) {
    my $policy = $register->{access_policy};
    return 0 unless ref($policy) eq 'HASH';
    return _access_policy_operation_is_privileged($policy->{read}, 1)
        && _access_policy_operation_is_privileged($policy->{write}, 1);
}

sub _access_policy_operation_is_allow($operation) {
    return ref($operation) eq 'HASH'
        && ($operation->{action} // '') eq 'allow'
        && !exists($operation->{predicate});
}

sub _access_policy_operation_is_privileged($operation, $value) {
    return ref($operation) eq 'HASH'
        && ($operation->{action} // '') eq 'require'
        && ref($operation->{predicate}) eq 'HASH'
        && ($operation->{predicate}{kind} // '') eq 'privileged'
        && defined($operation->{predicate}{value})
        && !ref($operation->{predicate}{value})
        && $operation->{predicate}{value} == $value;
}

sub _storage_has_access_policy($storage) {
    for my $register (_storage_registers($storage)) {
        return 1 if ref($register->{access_policy}) eq 'HASH';
    }
    return 0;
}

sub _normalize_source_anchors($anchors) {
    confess "APB completer IAL2 contract source.anchors must be an array reference\n"
        unless ref($anchors) eq 'ARRAY';

    my @normalized;
    for my $index (0 .. $#$anchors) {
        my $anchor = $anchors->[$index];
        if (ref($anchor) eq 'HASH') {
            my %copy;
            for my $key (sort keys %$anchor) {
                my $value = $anchor->{$key};
                confess "APB completer IAL2 contract source.anchors[$index].$key must be a scalar\n"
                    if ref($value);
                $copy{$key} = $value;
            }
            push @normalized, \%copy;
        } else {
            push @normalized, _nonempty_scalar($anchor, "source.anchors[$index]");
        }
    }

    return \@normalized;
}

sub _emit_isf($contract) {
    return _emit_multi_register_isf($contract)
        if _storage_is_multi_register($contract->{storage});
    return _emit_single_register_isf($contract);
}

sub _emit_single_register_isf($contract) {
    my $control = $contract->{control};
    my $bus = $contract->{bus};
    my $storage = $contract->{storage}{register};
    my $transfer = $contract->{transfer};
    my $reset = _reset_clause($contract->{reset});
    my $ready = $bus->{ready};
    my $read_data = $bus->{read_data}{name};
    my $error = $bus->{error};
    my $reg_data = $storage->{data}{name};
    my $internal_done = 'apb_complete_done_q';
    my $sidebands = _contract_has_sidebands($contract);
    my $data_width = $bus->{write_data}{width};
    my $strobe_width = _apb_strobe_width_for_data_width($data_width);

    return join("\n",
        "(actor $contract->{actor_name}",
        "  (clock $contract->{clock})",
        "  $reset",
        "  (watchdog 65536)",
        "",
        "  (interface",
        _interface_line('input', $bus->{select}),
        _interface_line('input', $bus->{enable}),
        _interface_line('input', $bus->{write}),
        _interface_line('input', $bus->{address}),
        _interface_line('input', $bus->{write_data}),
        ($sidebands ? (
            _interface_line('input', $bus->{protection}),
            _interface_line('input', $bus->{strobe}),
        ) : ()),
        _interface_line('input', $control->{wait_cycles}),
        _interface_line('output', $bus->{ready}),
        _interface_line('output', $bus->{read_data}),
        _interface_line('output', $bus->{error}) . ")",
        "",
        "  (storage",
        "    (var $reg_data (width $storage->{data}{width}) (reset $storage->{data}{reset}))",
        "    (var $internal_done (width 1) (reset 0)))",
        "",
        "  (drive enter_access",
        "    ($ready 0)",
        "    ($read_data 0)",
        "    ($error 0))",
        "",
        "  (drive read_hit",
        "    ($ready 1)",
        "    ($read_data $reg_data)",
        "    ($error 0))",
        "",
        "  (drive write_hit",
        "    ($ready 1)",
        "    ($read_data 0)",
        "    ($error 0))",
        "",
        "  (drive error_complete",
        "    ($ready 1)",
        "    ($read_data 0)",
        "    ($error 1))",
        "",
        "  (transaction $transfer->{name}",
        "    (when (& $bus->{select} (! $bus->{enable}))",
        "      (sample $bus->{address}{name} as addr)",
        "      (sample $bus->{write} as write_q)",
        "      (sample $bus->{write_data}{name} as wdata_q)",
        ($sidebands ? (
            "      (sample $bus->{protection}{name} as prot_q)",
            "      (sample $bus->{strobe}{name} as strb_q)",
        ) : ()),
        "      (sample $control->{wait_cycles}{name} as wait_n))",
        _sideband_local_lines($sidebands, $strobe_width),
        "    (drive enter_access)",
        "    (wait wait_n)",
        "    (when (& write_q (== addr $storage->{address}{value}))",
        _write_storage_lines($reg_data, $sidebands, $data_width),
        "      (drive write_hit))",
        "    (when (& write_q (! (== addr $storage->{address}{value})))",
        "      (drive error_complete))",
        "    (when (& (! write_q) (== addr $storage->{address}{value}))",
        "      (drive read_hit))",
        "    (when (& (! write_q) (! (== addr $storage->{address}{value})))",
        "      (drive error_complete))",
        "    (complete $internal_done)))",
        "",
    );
}

sub _emit_multi_register_isf($contract) {
    my $control = $contract->{control};
    my $bus = $contract->{bus};
    my $transfer = $contract->{transfer};
    my $reset = _reset_clause($contract->{reset});
    my $ready = $bus->{ready};
    my $read_data = $bus->{read_data}{name};
    my $error = $bus->{error};
    my $internal_done = 'apb_complete_done_q';
    my @registers = _storage_registers($contract->{storage});
    my $sidebands = _contract_has_sidebands($contract);
    my $data_width = $bus->{write_data}{width};
    my $strobe_width = _apb_strobe_width_for_data_width($data_width);

    my @storage_lines = map {
        "    (var $_->{data}{name} (width $_->{data}{width}) (reset $_->{data}{reset}))"
    } @registers;
    push @storage_lines, "    (var $internal_done (width 1) (reset 0)))";

    my @read_drive_lines;
    for my $register (@registers) {
        push @read_drive_lines,
            "  (drive " . _read_drive_name($register),
            "    ($ready 1)",
            "    ($read_data $register->{data}{name})",
            "    ($error 0))",
            "";
    }

    my $any_address_hit = _any_register_match_expr(@registers);
    my @transaction_register_lines;
    for my $register (@registers) {
        my $match = _register_match_expr($register);
        push @transaction_register_lines, _write_access_lines($register, $match, $sidebands, $data_width);
    }
    push @transaction_register_lines,
        "    (when (& write_q (! $any_address_hit))",
        "      (drive error_complete))";
    for my $register (@registers) {
        my $match = _register_match_expr($register);
        push @transaction_register_lines, _read_access_lines($register, $match);
    }
    push @transaction_register_lines,
        "    (when (& (! write_q) (! $any_address_hit))",
        "      (drive error_complete))";

    return join("\n",
        "(actor $contract->{actor_name}",
        "  (clock $contract->{clock})",
        "  $reset",
        "  (watchdog 65536)",
        "",
        "  (interface",
        _interface_line('input', $bus->{select}),
        _interface_line('input', $bus->{enable}),
        _interface_line('input', $bus->{write}),
        _interface_line('input', $bus->{address}),
        _interface_line('input', $bus->{write_data}),
        ($sidebands ? (
            _interface_line('input', $bus->{protection}),
            _interface_line('input', $bus->{strobe}),
        ) : ()),
        _interface_line('input', $control->{wait_cycles}),
        _interface_line('output', $bus->{ready}),
        _interface_line('output', $bus->{read_data}),
        _interface_line('output', $bus->{error}) . ")",
        "",
        "  (storage",
        @storage_lines,
        "",
        "  (drive enter_access",
        "    ($ready 0)",
        "    ($read_data 0)",
        "    ($error 0))",
        "",
        @read_drive_lines,
        "  (drive write_hit",
        "    ($ready 1)",
        "    ($read_data 0)",
        "    ($error 0))",
        "",
        "  (drive error_complete",
        "    ($ready 1)",
        "    ($read_data 0)",
        "    ($error 1))",
        "",
        "  (transaction $transfer->{name}",
        "    (when (& $bus->{select} (! $bus->{enable}))",
        "      (sample $bus->{address}{name} as addr)",
        "      (sample $bus->{write} as write_q)",
        "      (sample $bus->{write_data}{name} as wdata_q)",
        ($sidebands ? (
            "      (sample $bus->{protection}{name} as prot_q)",
            "      (sample $bus->{strobe}{name} as strb_q)",
        ) : ()),
        "      (sample $control->{wait_cycles}{name} as wait_n))",
        _sideband_local_lines($sidebands, $strobe_width),
        "    (drive enter_access)",
        "    (wait wait_n)",
        @transaction_register_lines,
        "    (complete $internal_done)))",
        "",
    );
}

sub _write_access_lines($register, $match, $sidebands, $data_width) {
    my $allowed = _register_access_allowed_expr($register, 'write');
    return (
        "    (when (& write_q $match)",
        _write_storage_lines($register->{data}{name}, $sidebands, $data_width),
        "      (drive write_hit))",
    ) unless defined $allowed;

    return (
        "    (when (& write_q $match $allowed)",
        _write_storage_lines($register->{data}{name}, $sidebands, $data_width),
        "      (drive write_hit))",
        "    (when (& write_q $match (! $allowed))",
        "      (drive error_complete))",
    );
}

sub _read_access_lines($register, $match) {
    my $read_drive = _read_drive_name($register);
    my $allowed = _register_access_allowed_expr($register, 'read');
    return (
        "    (when (& (! write_q) $match)",
        "      (drive $read_drive))",
    ) unless defined $allowed;

    return (
        "    (when (& (! write_q) $match $allowed)",
        "      (drive $read_drive))",
        "    (when (& (! write_q) $match (! $allowed))",
        "      (drive error_complete))",
    );
}

sub _register_access_allowed_expr($register, $operation) {
    my $policy = $register->{access_policy};
    return undef unless ref($policy) eq 'HASH';
    my $operation_policy = $policy->{$operation};
    return undef unless ref($operation_policy) eq 'HASH';
    return undef if ($operation_policy->{action} // '') eq 'allow';
    return _privileged_access_expr($operation_policy->{predicate}{value});
}

sub _privileged_access_expr($required_value) {
    return $required_value
        ? "(!= (& prot_q 3'd1) 3'd0)"
        : "(== (& prot_q 3'd1) 3'd0)";
}

sub _contract_has_sidebands($contract) {
    return defined($contract->{bus}{protection}) && defined($contract->{bus}{strobe});
}

sub _sideband_local_lines($sidebands, $strobe_width) {
    return () unless $sidebands;
    return (
        "    (local prot_q (width 3))",
        "    (local strb_q (width $strobe_width))",
    );
}

sub _write_storage_lines($data_signal, $sidebands, $data_width) {
    return "      (set $data_signal wdata_q)" unless $sidebands;

    my $lanes = _apb_strobe_width_for_data_width($data_width);
    my $all_bits = (1 << $data_width) - 1;
    my @lines;
    for my $lane (0 .. $lanes - 1) {
        my $write_mask = 0xff << ($lane * 8);
        my $preserve_mask = $all_bits ^ $write_mask;
        push @lines,
            "      (when-bit strb_q $lane",
            "        (set $data_signal (| (& $data_signal " . _hex_literal($data_width, $preserve_mask) . ") (& wdata_q " . _hex_literal($data_width, $write_mask) . "))))";
    }
    return @lines;
}

sub _apb_strobe_width_for_data_width($data_width) {
    confess "APB completer IAL2 contract data width must be byte-addressable in this slice\n"
        unless $data_width % 8 == 0;
    return int($data_width / 8);
}

sub _hex_literal($width, $value) {
    return sprintf("%d'h%0*x", $width, int($width / 4), $value);
}

sub _read_drive_name($register) {
    return "read_$register->{name}_hit";
}

sub _register_match_expr($register) {
    return "(== addr $register->{address}{value})";
}

sub _any_register_match_expr(@registers) {
    return _register_match_expr($registers[0]) if @registers == 1;
    return "(| " . join(' ', map { _register_match_expr($_) } @registers) . ")";
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

sub _build_report(%args) {
    my $contract = $args{contract};
    my @fsm_files = @{$args{fsm_files} || []};
    my $multi_register = _storage_is_multi_register($contract->{storage});
    my $has_access_policy = _storage_has_access_policy($contract->{storage});

    my %source_object = (
        id      => $contract->{source_object_id},
        anchors => _clone_jsonish($contract->{source_anchors}),
    );
    $source_object{intent_name} = $contract->{intent_name}
        if defined($contract->{intent_name}) && length($contract->{intent_name});

    my %transfer_report = (
        name             => $contract->{transfer}{name},
        setup_detect     => _clone_jsonish($contract->{transfer}{setup_detect}),
        wait_cycles      => $contract->{transfer}{wait_cycles},
        read             => $contract->{transfer}{read},
        write            => $contract->{transfer}{write},
        unmapped_address => $contract->{transfer}{unmapped_address},
        (_completer_has_adjacent_setup_policy($contract) ? (
            timing_policy => _apb_completer_timing_policy_report($contract),
        ) : ()),
    );
    if ($multi_register) {
        $transfer_report{registers} = _clone_jsonish($contract->{transfer}{registers});
    } else {
        $transfer_report{register} = $contract->{transfer}{register};
    }

    my $report = {
        schema => 'fsmgen.ial2.protocol_intent.apb_completer.v1',
        mode   => 'completer',
        layering => {
            source_layer          => 'IAL2',
            generated_ial1_format => 'isf',
            generated_ial0_format => 'fsm',
            direct_ial2_to_ial0   => 0,
        },
        source_object => \%source_object,
        target_protocol => {
            profile  => $contract->{protocol},
            object   => 'apb-completer',
            role     => $contract->{role},
            transfer => $contract->{transfer}{name},
        },
        completer => {
            name       => $contract->{name},
            actor_name => $contract->{actor_name},
        },
        bindings => {
            clock   => $contract->{clock},
            reset   => _clone_jsonish($contract->{reset}),
            control => _clone_jsonish($contract->{control}),
            bus     => _clone_jsonish($contract->{bus}),
            storage => _clone_jsonish($contract->{storage}),
        },
        width_policy => _apb_completer_width_policy($contract),
        transfer => \%transfer_report,
        generated_artifacts => {
            ial1 => {
                name   => $args{isf_name},
                format => 'isf',
            },
            ial0 => {
                format => 'fsm',
                files  => \@fsm_files,
            },
            hdl_entry => {
                selected       => 1,
                kind           => 'single_generated_fsm',
                entry_artifact => "$contract->{actor_name}.fsm",
                module         => $contract->{actor_name},
            },
        },
        generated_scheduler_or_completer_rules => _report_generated_rules($multi_register, _contract_has_sidebands($contract), $has_access_policy, $contract),
        assumptions => _report_assumptions($multi_register, $contract),
        enforced_static_rules => _report_enforced_static_rules($multi_register, $contract),
        unsupported_residue => _report_unsupported_residue($multi_register, $contract),
    };

    $report->{protection_policy} = _protection_policy_report($contract)
        if $has_access_policy;

    return $report;
}

sub _report_generated_rules($multi_register, $sidebands, $has_access_policy, $contract = undef) {
    return [
        {
            id     => 'apb_setup_detect',
            detail => $sidebands
                ? 'Generated IAL1 samples PADDR, PWRITE, PWDATA, PPROT, PSTRB, and wait_cycles only when PSEL is asserted and PENABLE is low.'
                : 'Generated IAL1 samples PADDR, PWRITE, PWDATA, and wait_cycles only when PSEL is asserted and PENABLE is low.',
        },
        {
            id     => 'apb_access_wait',
            detail => 'Generated IAL1 drives PREADY low, waits for the sampled runtime wait count, and then completes the APB access.',
        },
        {
            id     => 'apb_register_or_error_response',
            detail => $has_access_policy
                ? 'Generated IAL1 applies register-local PPROT access policies before mapped reads and writes, returns PSLVERR for denied or unmapped accesses, and keeps denied writes side-effect-free.'
                : $multi_register
                ? ($sidebands
                    ? 'Generated IAL1 applies PSTRB byte enables to selected decoded-register writes, reads selected registers, and drives PSLVERR for unmapped addresses.'
                    : 'Generated IAL1 updates or reads the selected decoded register and drives PSLVERR for unmapped addresses.')
                : ($sidebands
                    ? 'Generated IAL1 applies PSTRB byte enables to address-0 writes, reads the address-0 register, and drives PSLVERR for unmapped addresses.'
                    : 'Generated IAL1 updates or reads the address-0 register and drives PSLVERR for unmapped addresses.'),
        },
        (defined($contract) && _completer_has_adjacent_setup_policy($contract) ? ({
            id     => 'apb_adjacent_setup_admission',
            detail => 'The selected timing policy explicitly owns setup admission on every PSEL && !PENABLE cycle, including the cycle immediately after the prior access response.',
        }) : ()),
    ];
}

sub _report_assumptions($multi_register, $contract) {
    my $data_width = _apb_data_width($contract);
    my $alignment = _apb_strobe_width_for_data_width($data_width);
    my $map_assumption = $multi_register
        ? {
            id     => 'bounded_register_map',
            detail => "This APB completer PPIF slice models source-ordered $data_width-bit $alignment-byte-aligned registers and one transfer at a time.",
        }
        : {
            id     => 'single_register_map',
            detail => "This first APB completer PPIF slice models one $data_width-bit address-0 register and one transfer at a time.",
        };

    return [
        $map_assumption,
        {
            id     => 'generated_ial1_review_artifact',
            detail => 'The source lowers through generated IAL1 before generated IAL0; direct IAL2-to-IAL0 lowering remains forbidden.',
        },
        (_completer_has_adjacent_setup_policy($contract) ? ({
            id     => 'adjacent_setup_admission',
            detail => 'The selected completer accepts the next APB setup when PSEL is high and PENABLE is low; it does not require an inter-transfer idle cycle.',
        }) : ()),
        {
            id     => 'internal_completion_pulse',
            detail => 'The generated IAL1 uses an internal completion storage bit to make the APB transaction terminal without adding a public done port.',
        },
    ];
}

sub _report_enforced_static_rules($multi_register, $contract) {
    my $sidebands = _contract_has_sidebands($contract);
    my $data_width = _apb_data_width($contract);
    my $strobe_width = _apb_strobe_width_for_data_width($data_width);
    my $alignment = $strobe_width;
    my @rules = (
        'contract object must be a hash reference',
        'profile must be apb and the object must be apb-completer',
        'role must be completer',
        'clock, reset, control, bus, storage, and generated local names must be unique ISF identifiers',
        "address width is fixed at 32 bits; write-data, read-data, and register data widths are fixed at the selected $data_width-bit APB data width for this slice",
        ($sidebands ? ("sideband-aware completer contracts require PPROT width 3 and data-derived PSTRB width $strobe_width") : ()),
        (_storage_has_access_policy($contract->{storage}) ? ('access-policy is register-local, requires sideband-aware 16-bit or 32-bit multi-register completers, and supports allow or privileged PPROT[0] equality predicates only') : ()),
        'wait-cycles width is fixed at 4 bits for this slice',
        'setup detection must require select 1 and enable 0',
    );
    push @rules, $multi_register
        ? "register names, register data signals, and register addresses must be unique; register addresses must be 32-bit $alignment-byte-aligned decimal values and reset values must be 0"
        : 'the only implemented register address is 0 and reset value is 0';
    push @rules,
        'read and write behavior must target the selected register and unmapped addresses must assert error',
        (_completer_has_adjacent_setup_policy($contract) ? ('selected timing-policy is setup-admission adjacent and remains bounded to the selected 32-bit no-sideband one-register, selected 32-bit sideband-aware one-register, selected 32-bit sideband-aware two-register no-policy, selected 32-bit sideband-aware generalized no-policy reg0..regN register-set, selected 32-bit sideband-aware two-register protection, selected 32-bit sideband-aware protected generalized reg0..regN register-set, selected 32-bit sideband-aware protection status/control peripheral, selected sideband-aware data16 two-register no-policy, selected sideband-aware data16 generalized no-policy reg0..regN register-set, selected sideband-aware data16 two-register protection, selected sideband-aware data16 protected generalized reg0..regN register-set, or selected sideband-aware data16 protection status/control peripheral completer families') : ()),
        'APB completer is exposed through .ppif and bounded .apb profile-alias sources; direct IAL2-to-IAL0 lowering remains forbidden';
    return \@rules;
}

sub _report_unsupported_residue($multi_register, $contract) {
    my $sidebands = _contract_has_sidebands($contract);
    my @residue = (
        {
            id     => 'apb_interconnect_multi_peripheral_decode_deferred',
            detail => 'The one-requester/one-completer APB composition is support-accounted through generic .ppif; multi-peripheral address decode and routing remain future APB interconnect work.',
        },
    );
    push @residue, {
        id     => 'apb_multi_register_decode_deferred',
        detail => 'Additional register locations, range decode, byte lanes, and side effects remain future APB completer work.',
    } unless $multi_register;
    push @residue, _apb_protection_residue($contract);
    push @residue,
        _apb_completer_width_residue($contract),
        _completer_has_adjacent_setup_policy($contract)
            ? _apb_additional_back_to_back_policies_residue()
            : {
                id     => 'apb_back_to_back_policy_deferred',
                detail => 'Back-to-back setup admission and queued transfer policy remain future exact-owner work.',
            };
    return \@residue;
}

sub _completer_has_adjacent_setup_policy($contract) {
    return ref($contract->{transfer}{timing_policy}) eq 'HASH'
        && ($contract->{transfer}{timing_policy}{setup_admission} // '') eq 'adjacent';
}

sub _apb_completer_timing_policy_report($contract) {
    return {
        setup_admission => $contract->{transfer}{timing_policy}{setup_admission},
    };
}

sub _apb_additional_back_to_back_policies_residue() {
    return {
        id     => 'apb_additional_back_to_back_policies_deferred',
        detail => 'Adjacent setup admission is implemented for the selected 32-bit no-sideband one-register completer, selected 32-bit sideband-aware one-register completer, selected 32-bit sideband-aware two-register no-policy completer, selected 32-bit sideband-aware generalized no-policy reg0..regN register-set completer, selected 32-bit sideband-aware two-register protection completer, selected 32-bit sideband-aware protected generalized reg0..regN register-set completer, selected sideband-aware data16 two-register no-policy completer, selected sideband-aware data16 generalized no-policy reg0..regN register-set completer, selected sideband-aware data16 two-register protection completer, selected sideband-aware data16 protected generalized reg0..regN register-set completer, and selected sideband-aware data16 protection status/control peripheral completers; queued requester policy beyond selected composition propagation, broader generalized cardinality multi-peripheral multi-register propagation, direct backend lowering, verification-output, backend-language variants, AXI, AHB, and VHDL remain future work.',
    };
}

sub _protection_policy_report($contract) {
    my @register_reports = map {
        {
            name  => $_->{name},
            read  => _protection_policy_operation_report($_->{access_policy}{read}),
            write => _protection_policy_operation_report($_->{access_policy}{write}),
        }
    } grep { ref($_->{access_policy}) eq 'HASH' } _storage_registers($contract->{storage});

    return {
        scope               => 'register',
        predicate_namespace => 'fsmgen_apb_pprot_v1',
        predicate_source    => {
            bus_signal     => $contract->{bus}{protection}{name},
            sampled_signal => 'prot_q',
            bit            => 0,
        },
        denied_read_behavior => {
            ready     => 1,
            read_data => 0,
            error     => 1,
        },
        denied_write_behavior => {
            ready          => 1,
            read_data      => 0,
            error          => 1,
            storage_update => 'side_effect_free',
        },
        zero_strobe_write_policy => {
            allowed => 'successful_no_byte_write',
            denied  => 'error_side_effect_free',
        },
        registers => \@register_reports,
    };
}

sub _protection_policy_operation_report($operation) {
    return { action => 'allow' }
        if ($operation->{action} // '') eq 'allow';
    return {
        action    => 'require',
        predicate => {
            kind        => 'privileged',
            source_bit  => 'PPROT[0]',
            value       => $operation->{predicate}{value},
            expression  => $operation->{predicate}{value} ? 'PPROT[0] == 1' : 'PPROT[0] == 0',
        },
    };
}

sub _apb_protection_residue($contract) {
    return _apb_sideband_residue()
        unless _contract_has_sidebands($contract);
    return _apb_additional_protection_policies_residue()
        if _storage_has_access_policy($contract->{storage});
    return _apb_protection_policy_effects_residue();
}

sub _apb_data_width($contract) {
    return $contract->{bus}{write_data}{width};
}

sub _is_sideband_data16_contract($contract) {
    return _contract_has_sidebands($contract) && _apb_data_width($contract) == 16;
}

sub _apb_completer_width_policy($contract) {
    my $data_width = _apb_data_width($contract);
    my $strobe_width = _apb_strobe_width_for_data_width($data_width);
    my @byte_lanes = map {
        {
            strobe_bit => $_,
            data_range => '[' . (($_ * 8) + 7) . ':' . ($_ * 8) . ']',
        }
    } 0 .. $strobe_width - 1;

    my %policy = (
        address_width            => 32,
        data_width               => $data_width,
        register_data_width      => $data_width,
        wait_cycles_width        => $contract->{control}{wait_cycles}{width},
        register_alignment_bytes => $strobe_width,
        supported_data_widths    => [16, 32],
        selected_contract        => _is_sideband_data16_contract($contract) ? 'sideband_data16' : 'fixed_data32',
    );
    if (_contract_has_sidebands($contract)) {
        $policy{protection_width} = $contract->{bus}{protection}{width};
        $policy{strobe_width} = $contract->{bus}{strobe}{width};
        $policy{byte_lanes} = \@byte_lanes;
        $policy{zero_strobe_write_policy} = 'successful_no_byte_write';
    }
    return \%policy;
}

sub _apb_completer_width_residue($contract) {
    return {
        id     => 'apb_remaining_widths_deferred',
        detail => 'Address widths other than 32 bits, wait-count widths other than 4 bits, and APB data widths beyond the selected sideband-aware 16/32-bit boundary remain future APB completer work.',
    } if _is_sideband_data16_contract($contract);

    return {
        id     => 'apb_alternate_widths_deferred',
        detail => 'The public APB PPIF completer source fixes address, write-data, read-data, register data, and wait-count widths.',
    };
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
        detail => 'PPROT is sampled by the generated APB completer, but protection access-control policy remains future APB work.',
    };
}

sub _apb_additional_protection_policies_residue() {
    return {
        id     => 'apb_additional_protection_policies_deferred',
        detail => 'Register-local privileged PPROT[0] access policy is implemented for sideband-aware 16-bit and 32-bit multi-register APB completers; global, window-level, programmable, boolean, multi-predicate, and non-privileged policy families remain future APB work.',
    };
}

sub _clone_jsonish($value) {
    return undef unless defined $value;
    return [map { _clone_jsonish($_) } @$value] if ref($value) eq 'ARRAY';
    return { map { $_ => _clone_jsonish($value->{$_}) } sort keys %$value } if ref($value) eq 'HASH';
    return $value;
}

1;
