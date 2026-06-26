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
    my $storage = _normalize_storage(_required_hash($raw, 'storage'));
    my $transfer = _normalize_transfer(_required_hash($raw, 'transfer'), $control, $storage);

    _reject_duplicate_signal_names(
        $clock,
        $reset->{signal},
        $control->{wait_cycles}{name},
        $bus->{select},
        $bus->{enable},
        $bus->{write},
        $bus->{address}{name},
        $bus->{write_data}{name},
        $bus->{ready},
        $bus->{read_data}{name},
        $bus->{error},
        $storage->{register}{data}{name},
        qw(addr write_q wdata_q wait_n apb_complete_done_q),
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
    return {
        select     => _required_identifier_field($raw, 'select', 'bus.select'),
        enable     => _required_identifier_field($raw, 'enable', 'bus.enable'),
        write      => _required_identifier_field($raw, 'write', 'bus.write'),
        address    => _normalize_width_binding($raw->{address}, 'bus.address', 32),
        write_data => _normalize_width_binding($raw->{write_data}, 'bus.write_data', 32),
        ready      => _required_identifier_field($raw, 'ready', 'bus.ready'),
        read_data  => _normalize_width_binding($raw->{read_data}, 'bus.read_data', 32),
        error      => _required_identifier_field($raw, 'error', 'bus.error'),
    };
}

sub _normalize_storage($raw) {
    confess "APB completer IAL2 contract storage.register must be a hash reference\n"
        unless ref($raw->{register}) eq 'HASH';
    my $register = $raw->{register};
    my $name = _required_identifier_field($register, 'name', 'storage.register.name');
    my $address = _normalize_address_binding($register->{address}, 'storage.register.address', 0, 32);
    my $data = _normalize_storage_data($register->{data}, 'storage.register.data', 32, 0);

    return {
        register => {
            name    => $name,
            address => $address,
            data    => $data,
        },
    };
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

sub _normalize_transfer($raw, $control, $storage) {
    my $name = _required_identifier_field($raw, 'name', 'transfer.name');
    my $setup_detect = _normalize_phase(_required_hash_field($raw, 'setup_detect', 'transfer.setup_detect'), 'transfer.setup_detect');
    my $wait_cycles = _required_identifier_field($raw, 'wait_cycles', 'transfer.wait_cycles');
    my $read = _required_scalar_field($raw, 'read', 'transfer.read');
    my $write = _required_scalar_field($raw, 'write', 'transfer.write');
    my $unmapped_address = _required_scalar_field($raw, 'unmapped_address', 'transfer.unmapped_address');

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

    return {
        name             => $name,
        setup_detect     => $setup_detect,
        wait_cycles      => $wait_cycles,
        read             => $read,
        write            => $write,
        unmapped_address => $unmapped_address,
        register         => $storage->{register}{name},
    };
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
        "      (sample $control->{wait_cycles}{name} as wait_n))",
        "    (drive enter_access)",
        "    (wait wait_n)",
        "    (when (& write_q (== addr $storage->{address}{value}))",
        "      (set $reg_data wdata_q)",
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

    my %source_object = (
        id      => $contract->{source_object_id},
        anchors => _clone_jsonish($contract->{source_anchors}),
    );
    $source_object{intent_name} = $contract->{intent_name}
        if defined($contract->{intent_name}) && length($contract->{intent_name});

    return {
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
        transfer => {
            name             => $contract->{transfer}{name},
            setup_detect     => _clone_jsonish($contract->{transfer}{setup_detect}),
            wait_cycles      => $contract->{transfer}{wait_cycles},
            read             => $contract->{transfer}{read},
            write            => $contract->{transfer}{write},
            unmapped_address => $contract->{transfer}{unmapped_address},
            register         => $contract->{transfer}{register},
        },
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
        generated_scheduler_or_completer_rules => [
            {
                id     => 'apb_setup_detect',
                detail => 'Generated IAL1 samples PADDR, PWRITE, PWDATA, and wait_cycles only when PSEL is asserted and PENABLE is low.',
            },
            {
                id     => 'apb_access_wait',
                detail => 'Generated IAL1 drives PREADY low, waits for the sampled runtime wait count, and then completes the APB access.',
            },
            {
                id     => 'apb_register_or_error_response',
                detail => 'Generated IAL1 updates or reads the address-0 register and drives PSLVERR for unmapped addresses.',
            },
        ],
        assumptions => [
            {
                id     => 'single_register_map',
                detail => 'This first APB completer PPIF slice models one 32-bit address-0 register and one transfer at a time.',
            },
            {
                id     => 'generated_ial1_review_artifact',
                detail => 'The source lowers through generated IAL1 before generated IAL0; direct IAL2-to-IAL0 lowering remains forbidden.',
            },
            {
                id     => 'internal_completion_pulse',
                detail => 'The generated IAL1 uses an internal completion storage bit to make the APB transaction terminal without adding a public done port.',
            },
        ],
        enforced_static_rules => [
            'contract object must be a hash reference',
            'profile must be apb and the object must be apb-completer',
            'role must be completer',
            'clock, reset, control, bus, storage, and generated local names must be unique ISF identifiers',
            'address, write-data, read-data, and register data widths are fixed at 32 bits for this slice',
            'wait-cycles width is fixed at 4 bits for this slice',
            'setup detection must require select 1 and enable 0',
            'the only implemented register address is 0 and reset value is 0',
            'read and write behavior must target the selected register and unmapped addresses must assert error',
            'APB completer is exposed through .ppif only; .apb remains bounded to requester-transfer in this slice',
        ],
        unsupported_residue => [
            {
                id     => 'apb_interconnect_multi_peripheral_decode_deferred',
                detail => 'The one-requester/one-completer APB composition is support-accounted through generic .ppif; multi-peripheral address decode and routing remain future APB interconnect work.',
            },
            {
                id     => 'apb_profile_alias_completer_deferred',
                detail => '.apb remains the bounded requester-transfer profile alias and does not accept APB completer sources in this slice.',
            },
            {
                id     => 'apb_profile_alias_composition_deferred',
                detail => 'The generated APB composition is supported through generic .ppif only; .apb composition alias exposure remains future work.',
            },
            {
                id     => 'apb_multi_register_decode_deferred',
                detail => 'Additional register locations, range decode, byte lanes, and side effects remain future APB completer work.',
            },
            {
                id     => 'apb_protection_and_strobes_deferred',
                detail => 'PPROT, PSTRB, byte-enable policy, and APB4/APB5 sideband behavior remain future APB work.',
            },
            {
                id     => 'apb_alternate_widths_deferred',
                detail => 'The public APB PPIF completer source fixes address, write-data, read-data, register data, and wait-count widths.',
            },
            {
                id     => 'apb_back_to_back_policy_deferred',
                detail => 'Back-to-back setup admission and queued transfer policy remain future exact-owner work.',
            },
        ],
    };
}

sub _clone_jsonish($value) {
    return undef unless defined $value;
    return [map { _clone_jsonish($_) } @$value] if ref($value) eq 'ARRAY';
    return { map { $_ => _clone_jsonish($value->{$_}) } sort keys %$value } if ref($value) eq 'HASH';
    return $value;
}

1;
