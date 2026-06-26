package FSM::IAL2::ProtocolIntent::ApbRequesterTransfer;

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
    confess "FSM::IAL2::ProtocolIntent::ApbRequesterTransfer->generate expects exactly one contract hash reference\n"
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
        kind  => 'protocol_intent.apb_requester_transfer',
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
    confess "FSM::IAL2::ProtocolIntent::ApbRequesterTransfer->new must be called with the FSM::IAL2::ProtocolIntent::ApbRequesterTransfer class invocant\n"
        unless defined($class) && !ref($class) && $class eq 'FSM::IAL2::ProtocolIntent::ApbRequesterTransfer';
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
    confess "FSM::IAL2::ProtocolIntent::ApbRequesterTransfer->$method must be called on an FSM::IAL2::ProtocolIntent::ApbRequesterTransfer object\n"
        unless blessed($self) && $self->isa('FSM::IAL2::ProtocolIntent::ApbRequesterTransfer');
}

sub _normalize_contract($raw) {
    my $kind = _required_scalar($raw, 'kind');
    confess "APB requester-transfer IAL2 contract kind must be apb_requester_transfer\n"
        unless $kind eq 'apb_requester_transfer';

    my $protocol = lc _required_scalar($raw, 'protocol');
    confess "APB requester-transfer IAL2 contract profile must be apb\n"
        unless $protocol eq 'apb';

    my $name = _required_identifier($raw, 'name');
    my $actor_name = exists($raw->{actor_name})
        ? _identifier_value($raw->{actor_name}, 'actor_name')
        : $name;
    my $role = lc _required_scalar($raw, 'role');
    confess "APB requester-transfer IAL2 contract role must be requester\n"
        unless $role eq 'requester';

    my $clock = _required_identifier($raw, 'clock');
    my $reset = _normalize_reset($raw->{reset});
    my $request = _normalize_request(_required_hash($raw, 'request'));
    my $response = _normalize_response(_required_hash($raw, 'response'));
    my $bus = _normalize_bus(_required_hash($raw, 'bus'));
    my $transfer = _normalize_transfer(_required_hash($raw, 'transfer'));

    _reject_duplicate_signal_names(
        $clock,
        $reset->{signal},
        $request->{start},
        $request->{write},
        $request->{address}{name},
        $request->{write_data}{name},
        $response->{done},
        $response->{read_data}{name},
        $response->{error},
        $bus->{address}{name},
        $bus->{write},
        $bus->{write_data}{name},
        $bus->{select},
        $bus->{enable},
        $bus->{ready},
        $bus->{read_data}{name},
        $bus->{error},
        qw(addr is_write wdata rdata slverr psel penable),
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
        request          => $request,
        response         => $response,
        bus              => $bus,
        transfer         => $transfer,
        intent_name      => $intent_name,
        source_object_id => $source_object_id,
        source_anchors   => $anchors,
    };
}

sub _normalize_request($raw) {
    return {
        start      => _required_identifier_field($raw, 'start', 'request.start'),
        write      => _required_identifier_field($raw, 'write', 'request.write'),
        address    => _normalize_width_binding($raw->{address}, 'request.address', 32),
        write_data => _normalize_width_binding($raw->{write_data}, 'request.write_data', 32),
    };
}

sub _normalize_response($raw) {
    return {
        done      => _required_identifier_field($raw, 'done', 'response.done'),
        read_data => _normalize_width_binding($raw->{read_data}, 'response.read_data', 32),
        error     => _required_identifier_field($raw, 'error', 'response.error'),
    };
}

sub _normalize_bus($raw) {
    return {
        address    => _normalize_width_binding($raw->{address}, 'bus.address', 32),
        write      => _required_identifier_field($raw, 'write', 'bus.write'),
        write_data => _normalize_width_binding($raw->{write_data}, 'bus.write_data', 32),
        select     => _required_identifier_field($raw, 'select', 'bus.select'),
        enable     => _required_identifier_field($raw, 'enable', 'bus.enable'),
        ready      => _required_identifier_field($raw, 'ready', 'bus.ready'),
        read_data  => _normalize_width_binding($raw->{read_data}, 'bus.read_data', 32),
        error      => _required_identifier_field($raw, 'error', 'bus.error'),
    };
}

sub _normalize_transfer($raw) {
    my $name = _required_identifier_field($raw, 'name', 'transfer.name');
    my $setup = _normalize_phase(_required_hash_field($raw, 'setup', 'transfer.setup'), 'transfer.setup');
    my $access = _normalize_phase(_required_hash_field($raw, 'access', 'transfer.access'), 'transfer.access');
    my $complete_on = _required_scalar_field($raw, 'complete_on', 'transfer.complete_on');
    my $sample = _normalize_sample($raw->{sample});
    my $latency = _normalize_latency(_required_hash_field($raw, 'latency', 'transfer.latency'));

    _require_static_value($setup->{select}, 1, 'transfer.setup.select');
    _require_static_value($setup->{enable}, 0, 'transfer.setup.enable');
    _require_static_value($access->{select}, 1, 'transfer.access.select');
    _require_static_value($access->{enable}, 1, 'transfer.access.enable');
    confess "APB requester-transfer IAL2 contract transfer.complete_on must be ready\n"
        unless $complete_on eq 'ready';
    confess "APB requester-transfer IAL2 contract transfer.sample must be read-data followed by error\n"
        unless @$sample == 2 && $sample->[0] eq 'read-data' && $sample->[1] eq 'error';
    _require_static_value($latency->{min}, 2, 'transfer.latency.min');
    _require_static_value($latency->{max}, 16, 'transfer.latency.max');

    return {
        name        => $name,
        setup       => $setup,
        access      => $access,
        complete_on => $complete_on,
        sample      => $sample,
        latency     => $latency,
    };
}

sub _normalize_phase($raw, $field) {
    return {
        select => _integer_value($raw->{select}, "$field.select"),
        enable => _integer_value($raw->{enable}, "$field.enable"),
    };
}

sub _normalize_sample($raw) {
    confess "APB requester-transfer IAL2 contract transfer.sample must be an array reference\n"
        unless ref($raw) eq 'ARRAY';
    return [map { _nonempty_scalar($_, 'transfer.sample[]') } @$raw];
}

sub _normalize_latency($raw) {
    return {
        min => _integer_value($raw->{min}, 'transfer.latency.min'),
        max => _integer_value($raw->{max}, 'transfer.latency.max'),
    };
}

sub _normalize_width_binding($raw, $field, $expected_width) {
    confess "APB requester-transfer IAL2 contract $field must be a signal/width hash reference\n"
        unless ref($raw) eq 'HASH';
    my $name = _identifier_value($raw->{name}, "$field.name");
    my $width = _positive_integer($raw->{width}, "$field.width");
    confess "APB requester-transfer IAL2 contract $field.width must be $expected_width in this slice\n"
        unless $width == $expected_width;
    return {
        name  => $name,
        width => $width,
    };
}

sub _normalize_reset($raw_reset) {
    confess "APB requester-transfer IAL2 contract is missing required reset binding\n"
        unless defined $raw_reset && ref($raw_reset) eq 'HASH';

    my $reset = {
        signal     => _identifier_value($raw_reset->{signal}, 'reset.signal'),
        active_low => _bool_value($raw_reset->{active_low}, 'reset.active_low'),
        async      => _bool_value($raw_reset->{async}, 'reset.async'),
    };
    confess "APB requester-transfer IAL2 contract reset must be active_low async in this slice\n"
        unless $reset->{active_low} && $reset->{async};

    return $reset;
}

sub _required_hash($raw, $field) {
    confess "APB requester-transfer IAL2 contract is missing required hash field '$field'\n"
        unless exists $raw->{$field} && ref($raw->{$field}) eq 'HASH';
    return $raw->{$field};
}

sub _required_hash_field($raw, $key, $field) {
    confess "APB requester-transfer IAL2 contract is missing required hash field '$field'\n"
        unless exists $raw->{$key} && ref($raw->{$key}) eq 'HASH';
    return $raw->{$key};
}

sub _required_scalar($raw, $field) {
    confess "APB requester-transfer IAL2 contract is missing required scalar field '$field'\n"
        unless exists($raw->{$field});
    return _nonempty_scalar($raw->{$field}, $field);
}

sub _required_scalar_field($raw, $key, $field) {
    confess "APB requester-transfer IAL2 contract is missing required scalar field '$field'\n"
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
    confess "APB requester-transfer IAL2 contract field '$field' must be a non-empty scalar\n"
        if !defined($value) || ref($value) || $value eq '';
    return $value;
}

sub _identifier_value($value, $field) {
    confess "APB requester-transfer IAL2 contract field '$field' must be an ISF identifier\n"
        unless defined($value) && !ref($value) && $value =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
    return $value;
}

sub _positive_integer($value, $field) {
    confess "APB requester-transfer IAL2 contract field '$field' must be a positive integer\n"
        if ref($value) || !defined($value) || $value !~ /\A[1-9][0-9]*\z/;
    return int($value);
}

sub _integer_value($value, $field) {
    confess "APB requester-transfer IAL2 contract field '$field' must be an integer\n"
        if ref($value) || !defined($value) || $value !~ /\A(?:0|[1-9][0-9]*)\z/;
    return int($value);
}

sub _bool_value($value, $field) {
    confess "APB requester-transfer IAL2 contract field '$field' must be boolean 0 or 1\n"
        if ref($value) || !defined($value) || ($value ne '0' && $value ne '1');
    return $value ? 1 : 0;
}

sub _require_static_value($actual, $expected, $field) {
    confess "APB requester-transfer IAL2 contract $field must be $expected in this slice\n"
        unless defined($actual) && $actual == $expected;
}

sub _reject_duplicate_signal_names(@names) {
    my %seen;
    for my $name (@names) {
        confess "APB requester-transfer IAL2 contract duplicates signal or generated local name '$name'\n"
            if $seen{$name}++;
    }
}

sub _normalize_source_anchors($anchors) {
    confess "APB requester-transfer IAL2 contract source.anchors must be an array reference\n"
        unless ref($anchors) eq 'ARRAY';

    my @normalized;
    for my $index (0 .. $#$anchors) {
        my $anchor = $anchors->[$index];
        if (ref($anchor) eq 'HASH') {
            my %copy;
            for my $key (sort keys %$anchor) {
                my $value = $anchor->{$key};
                confess "APB requester-transfer IAL2 contract source.anchors[$index].$key must be a scalar\n"
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
    my $request = $contract->{request};
    my $response = $contract->{response};
    my $bus = $contract->{bus};
    my $transfer = $contract->{transfer};
    my $reset = _reset_clause($contract->{reset});

    return join("\n",
        "(actor $contract->{actor_name}",
        "  (clock $contract->{clock})",
        "  $reset",
        "  (watchdog 65536)",
        "",
        "  (interface",
        _interface_line('input', $request->{start}),
        _interface_line('input', $request->{write}),
        _interface_line('input', $request->{address}),
        _interface_line('input', $request->{write_data}),
        _interface_line('output', $response->{done}),
        _interface_line('output', $response->{read_data}),
        _interface_line('output', $response->{error}),
        _interface_line('output', $bus->{address}),
        _interface_line('output', $bus->{write}),
        _interface_line('output', $bus->{write_data}),
        _interface_line('output', $bus->{select}),
        _interface_line('output', $bus->{enable}),
        _interface_line('input', $bus->{ready}),
        _interface_line('input', $bus->{read_data}),
        _interface_line('input', $bus->{error}) . ")",
        "",
        "  (drive (psel val) ($bus->{select} val))",
        "  (drive (penable val) ($bus->{enable} val))",
        "",
        "  (drive setup_phase",
        "    ($bus->{address}{name} addr)",
        "    ($bus->{write} is_write)",
        "    ($bus->{write_data}{name} wdata)",
        "    ($bus->{select} $transfer->{setup}{select})",
        "    ($bus->{enable} $transfer->{setup}{enable}))",
        "",
        "  (drive access_phase",
        "    ($bus->{enable} $transfer->{access}{enable}))",
        "",
        "  (drive done_phase",
        "    (psel 0)",
        "    (penable 0)",
        "    ($response->{read_data}{name} rdata)",
        "    ($response->{error} slverr))",
        "",
        "  (transaction $transfer->{name}",
        "    (on $request->{start}",
        "      (sample $request->{address}{name} as addr)",
        "      (sample $request->{write} as is_write)",
        "      (sample $request->{write_data}{name} as wdata))",
        "    (drive setup_phase)",
        "    (drive access_phase)",
        "    (await $bus->{ready})",
        "    (sample $bus->{read_data}{name} as rdata)",
        "    (sample $bus->{error} as slverr)",
        "    (drive done_phase)",
        "    (complete $response->{done})",
        "    (latency (min $transfer->{latency}{min}) (max $transfer->{latency}{max}))))",
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
        schema => 'fsmgen.ial2.protocol_intent.apb_requester_transfer.v1',
        mode   => 'requester-transfer',
        layering => {
            source_layer          => 'IAL2',
            generated_ial1_format => 'isf',
            generated_ial0_format => 'fsm',
            direct_ial2_to_ial0   => 0,
        },
        source_object => \%source_object,
        target_protocol => {
            profile  => $contract->{protocol},
            object   => 'apb-requester',
            role     => $contract->{role},
            transfer => $contract->{transfer}{name},
        },
        requester => {
            name       => $contract->{name},
            actor_name => $contract->{actor_name},
        },
        bindings => {
            clock    => $contract->{clock},
            reset    => _clone_jsonish($contract->{reset}),
            request  => _clone_jsonish($contract->{request}),
            response => _clone_jsonish($contract->{response}),
            bus      => _clone_jsonish($contract->{bus}),
        },
        transfer => {
            name        => $contract->{transfer}{name},
            setup       => _clone_jsonish($contract->{transfer}{setup}),
            access      => _clone_jsonish($contract->{transfer}{access}),
            complete_on => $contract->{transfer}{complete_on},
            sample      => _clone_jsonish($contract->{transfer}{sample}),
            latency     => _clone_jsonish($contract->{transfer}{latency}),
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
        generated_scheduler_or_requester_rules => [
            {
                id     => 'apb_setup_phase',
                detail => 'Generated IAL1 drives PSEL asserted with PENABLE low after start samples request fields.',
            },
            {
                id     => 'apb_access_phase',
                detail => 'Generated IAL1 asserts PENABLE and awaits PREADY before sampling PRDATA and PSLVERR.',
            },
            {
                id     => 'apb_done_pulse',
                detail => 'Generated IAL1 deasserts PSEL/PENABLE, publishes read data and error status, and completes through done.',
            },
        ],
        assumptions => [
            {
                id     => 'single_outstanding_transfer',
                detail => 'This first APB PPIF slice models one requester transfer at a time and delegates scheduling to the existing IAL1 lowering path.',
            },
            {
                id     => 'environment_drives_apb_response',
                detail => 'The environment or APB peripheral drives PREADY, PRDATA, and PSLVERR.',
            },
        ],
        enforced_static_rules => [
            'contract object must be a hash reference',
            'profile must be apb and the object must be apb-requester',
            'role must be requester',
            'clock, reset, request, response, bus, and generated local names must be unique ISF identifiers',
            'address, write-data, and read-data widths are fixed at 32 bits for this slice',
            'setup phase must drive select 1 and enable 0',
            'access phase must drive select 1 and enable 1',
            'completion waits on ready, samples read-data and error, and reports latency min 2 max 16',
            'APB requester-transfer is exposed through .ppif and bounded .apb profile-alias sources; direct IAL2-to-IAL0 lowering remains forbidden',
        ],
        unsupported_residue => [
            {
                id     => 'apb_multi_peripheral_decode_deferred',
                detail => 'Address decode, peripheral selection beyond one PSEL, and multi-peripheral routing remain future APB work.',
            },
            {
                id     => 'apb_protection_and_strobes_deferred',
                detail => 'PPROT, PSTRB, byte-enable policy, and APB4/APB5 sideband behavior remain future APB work.',
            },
            {
                id     => 'apb_completer_and_interconnect_generation_deferred',
                detail => 'The slice generates only the requester-transfer path; APB completer and interconnect generation remain owned by lower-layer fixtures or future PPIF slices.',
            },
            {
                id     => 'apb_alternate_widths_deferred',
                detail => 'The public APB PPIF requester-transfer source fixes address, write-data, and read-data widths to 32 bits.',
            },
            {
                id     => 'apb_back_to_back_policy_deferred',
                detail => 'Back-to-back transfer policy and queued transfer admission remain future exact-owner work.',
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
