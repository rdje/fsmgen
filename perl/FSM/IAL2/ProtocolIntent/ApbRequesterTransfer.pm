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

    _add_response_idle_clears($contract, $lowered->{files})
        if defined($contract->{response}{busy}) || defined($contract->{response}{status});
    _add_back_to_back_requester_behavior($contract, $lowered->{files})
        if _requester_has_back_to_back_policy($contract);

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
    _validate_sideband_bundle($request, $bus);
    _validate_width_policy($request, $response, $bus);
    my $transfer = _normalize_transfer(_required_hash($raw, 'transfer'));
    _validate_timing_policy_contract($request, $response, $bus, $transfer);

    _reject_duplicate_signal_names(
        $clock,
        $reset->{signal},
        $request->{start},
        $request->{write},
        $request->{address}{name},
        $request->{write_data}{name},
        (defined($request->{protection}) ? ($request->{protection}{name}) : ()),
        (defined($request->{write_strobe}) ? ($request->{write_strobe}{name}) : ()),
        (defined($response->{accepted}) ? ($response->{accepted}) : ()),
        (defined($response->{busy}) ? ($response->{busy}) : ()),
        (defined($response->{status}) ? ($response->{status}{name}) : ()),
        $response->{done},
        $response->{read_data}{name},
        $response->{error},
        $bus->{address}{name},
        $bus->{write},
        $bus->{write_data}{name},
        (defined($bus->{protection}) ? ($bus->{protection}{name}) : ()),
        (defined($bus->{strobe}) ? ($bus->{strobe}{name}) : ()),
        $bus->{select},
        $bus->{enable},
        $bus->{ready},
        $bus->{read_data}{name},
        $bus->{error},
        qw(addr is_write wdata prot wstrb rdata slverr psel penable queued_valid queued_addr queued_write queued_wdata queued_prot queued_wstrb),
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
    my %request = (
        start      => _required_identifier_field($raw, 'start', 'request.start'),
        write      => _required_identifier_field($raw, 'write', 'request.write'),
        address    => _normalize_width_binding($raw->{address}, 'request.address', 32),
        write_data => _normalize_width_binding_one_of($raw->{write_data}, 'request.write_data', [16, 32]),
    );
    $request{protection} = _normalize_width_binding($raw->{protection}, 'request.protection', 3)
        if exists $raw->{protection};
    $request{write_strobe} = _normalize_width_binding_one_of($raw->{write_strobe}, 'request.write_strobe', [2, 4])
        if exists $raw->{write_strobe};
    return \%request;
}

sub _normalize_response($raw) {
    my $response = {
        done      => _required_identifier_field($raw, 'done', 'response.done'),
        read_data => _normalize_width_binding_one_of($raw->{read_data}, 'response.read_data', [16, 32]),
        error     => _required_identifier_field($raw, 'error', 'response.error'),
    };
    $response->{busy} = _identifier_value($raw->{busy}, 'response.busy')
        if exists $raw->{busy};
    $response->{accepted} = _identifier_value($raw->{accepted}, 'response.accepted')
        if exists $raw->{accepted};
    if (exists $raw->{status}) {
        confess "APB requester-transfer IAL2 contract response.status requires response.busy in this slice\n"
            unless exists $response->{busy};
        $response->{status} = _normalize_width_binding($raw->{status}, 'response.status', 2);
    }
    return $response;
}

sub _normalize_bus($raw) {
    my %bus = (
        address    => _normalize_width_binding($raw->{address}, 'bus.address', 32),
        write      => _required_identifier_field($raw, 'write', 'bus.write'),
        write_data => _normalize_width_binding_one_of($raw->{write_data}, 'bus.write_data', [16, 32]),
        select     => _required_identifier_field($raw, 'select', 'bus.select'),
        enable     => _required_identifier_field($raw, 'enable', 'bus.enable'),
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

sub _validate_sideband_bundle($request, $bus) {
    my @present = grep { defined } (
        $request->{protection},
        $request->{write_strobe},
        $bus->{protection},
        $bus->{strobe},
    );
    return unless @present;

    confess "APB requester-transfer IAL2 sideband contract requires request.protection, request.write_strobe, bus.protection, and bus.strobe together in this slice\n"
        unless @present == 4;
}

sub _validate_width_policy($request, $response, $bus) {
    my $data_width = $request->{write_data}{width};
    for my $binding (
        ['response.read_data', $response->{read_data}],
        ['bus.write_data',    $bus->{write_data}],
        ['bus.read_data',     $bus->{read_data}],
    ) {
        my ($field, $width_binding) = @$binding;
        confess "APB requester-transfer IAL2 contract $field.width must match selected APB data width $data_width in this slice\n"
            unless $width_binding->{width} == $data_width;
    }

    my $sidebands = defined($request->{protection})
        && defined($request->{write_strobe})
        && defined($bus->{protection})
        && defined($bus->{strobe});
    confess "APB requester-transfer IAL2 contract 16-bit APB data width requires sideband-aware PPROT/PSTRB bindings in this slice\n"
        if $data_width == 16 && !$sidebands;
    confess "APB requester-transfer IAL2 contract data width must be 16 or 32 in this slice\n"
        unless $data_width == 16 || $data_width == 32;
    return unless $sidebands;

    my $expected_strobe_width = _apb_strobe_width_for_data_width($data_width);
    confess "APB requester-transfer IAL2 contract request.write_strobe.width must be $expected_strobe_width for selected APB data width $data_width in this slice\n"
        unless $request->{write_strobe}{width} == $expected_strobe_width;
    confess "APB requester-transfer IAL2 contract bus.strobe.width must be $expected_strobe_width for selected APB data width $data_width in this slice\n"
        unless $bus->{strobe}{width} == $expected_strobe_width;
}

sub _normalize_transfer($raw) {
    my $name = _required_identifier_field($raw, 'name', 'transfer.name');
    my $setup = _normalize_phase(_required_hash_field($raw, 'setup', 'transfer.setup'), 'transfer.setup');
    my $access = _normalize_phase(_required_hash_field($raw, 'access', 'transfer.access'), 'transfer.access');
    my $complete_on = _required_scalar_field($raw, 'complete_on', 'transfer.complete_on');
    my $sample = _normalize_sample($raw->{sample});
    my $latency = _normalize_latency(_required_hash_field($raw, 'latency', 'transfer.latency'));
    my $timing_policy = exists($raw->{timing_policy})
        ? _normalize_timing_policy(_required_hash_field($raw, 'timing_policy', 'transfer.timing_policy'))
        : undef;

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
        (defined($timing_policy) ? (timing_policy => $timing_policy) : ()),
    };
}

sub _normalize_timing_policy($raw) {
    my $back_to_back = _required_scalar_field($raw, 'back_to_back', 'transfer.timing_policy.back_to_back');
    confess "APB requester-transfer IAL2 contract transfer.timing_policy.back_to_back must be queued in this slice\n"
        unless $back_to_back eq 'queued';
    my $queue_depth = _positive_integer($raw->{queue_depth}, 'transfer.timing_policy.queue_depth');
    confess "APB requester-transfer IAL2 contract transfer.timing_policy.queue_depth must be 1 in this slice\n"
        unless $queue_depth == 1;
    my $overflow = _required_scalar_field($raw, 'overflow', 'transfer.timing_policy.overflow');
    confess "APB requester-transfer IAL2 contract transfer.timing_policy.overflow must be reject in this slice\n"
        unless $overflow eq 'reject';

    for my $key (sort keys %$raw) {
        confess "APB requester-transfer IAL2 contract transfer.timing_policy has unsupported key '$key'\n"
            unless $key eq 'back_to_back' || $key eq 'queue_depth' || $key eq 'overflow';
    }

    return {
        back_to_back => $back_to_back,
        queue_depth  => $queue_depth,
        overflow     => $overflow,
    };
}

sub _validate_timing_policy_contract($request, $response, $bus, $transfer) {
    if (exists $response->{accepted} && !exists $transfer->{timing_policy}) {
        confess "APB requester-transfer IAL2 contract response.accepted requires selected transfer.timing_policy in this slice\n";
    }
    return unless exists $transfer->{timing_policy};

    for my $field (qw(accepted busy status)) {
        confess "APB requester-transfer IAL2 contract selected back-to-back timing-policy requires response.$field in this slice\n"
            unless exists $response->{$field};
    }
    confess "APB requester-transfer IAL2 contract selected back-to-back timing-policy requires response.status width 2 in this slice\n"
        unless $response->{status}{width} == 2;
    my $has_sidebands = defined($request->{protection})
        || defined($request->{write_strobe})
        || defined($bus->{protection})
        || defined($bus->{strobe});
    confess "APB requester-transfer IAL2 contract selected back-to-back timing-policy supports only the 32-bit no-sideband or 32-bit sideband-aware requester families in this slice\n"
        unless $request->{write_data}{width} == 32
            && $response->{read_data}{width} == 32
            && $bus->{write_data}{width} == 32
            && $bus->{read_data}{width} == 32
            && (
                !$has_sidebands
                || (
                    defined($request->{protection})
                    && defined($request->{write_strobe})
                    && defined($bus->{protection})
                    && defined($bus->{strobe})
                    && $request->{protection}{width} == 3
                    && $request->{write_strobe}{width} == 4
                    && $bus->{protection}{width} == 3
                    && $bus->{strobe}{width} == 4
                )
            );
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

sub _normalize_width_binding_one_of($raw, $field, $allowed_widths) {
    confess "APB requester-transfer IAL2 contract $field must be a signal/width hash reference\n"
        unless ref($raw) eq 'HASH';
    my $name = _identifier_value($raw->{name}, "$field.name");
    my $width = _positive_integer($raw->{width}, "$field.width");
    my %allowed = map { $_ => 1 } @$allowed_widths;
    confess "APB requester-transfer IAL2 contract $field.width must be one of " . join(', ', @$allowed_widths) . " in this slice\n"
        unless $allowed{$width};
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
    my $sidebands = _contract_has_sidebands($contract);

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
        ($sidebands ? (
            _interface_line('input', $request->{protection}),
            _interface_line('input', $request->{write_strobe}),
        ) : ()),
        (defined($response->{busy}) ? (_interface_line('output', $response->{busy})) : ()),
        (defined($response->{accepted}) ? (_interface_line('output', $response->{accepted})) : ()),
        (defined($response->{status}) ? (_interface_line('output', $response->{status})) : ()),
        _interface_line('output', $response->{done}),
        _interface_line('output', $response->{read_data}),
        _interface_line('output', $response->{error}),
        _interface_line('output', $bus->{address}),
        _interface_line('output', $bus->{write}),
        _interface_line('output', $bus->{write_data}),
        ($sidebands ? (
            _interface_line('output', $bus->{protection}),
            _interface_line('output', $bus->{strobe}),
        ) : ()),
        _interface_line('output', $bus->{select}),
        _interface_line('output', $bus->{enable}),
        _interface_line('input', $bus->{ready}),
        _interface_line('input', $bus->{read_data}),
        _interface_line('input', $bus->{error}) . ")",
        "",
        "  (drive setup_phase",
        "    ($bus->{address}{name} addr)",
        "    ($bus->{write} is_write)",
        "    ($bus->{write_data}{name} wdata)",
        ($sidebands ? (
            "    ($bus->{protection}{name} prot)",
            "    ($bus->{strobe}{name} (& wstrb " . _write_strobe_enable_expr($bus->{strobe}{width}) . "))",
        ) : ()),
        "    ($bus->{select} $transfer->{setup}{select})",
        (defined($response->{busy}) ? ("    ($response->{busy} 1)") : ()),
        (defined($response->{status}) ? ("    ($response->{status}{name} 1)") : ()),
        "    ($bus->{enable} $transfer->{setup}{enable}))",
        "",
        "  (drive access_phase",
        (defined($response->{busy}) ? ("    ($response->{busy} 1)") : ()),
        (defined($response->{status}) ? ("    ($response->{status}{name} 1)") : ()),
        "    ($bus->{enable} $transfer->{access}{enable}))",
        "",
        _done_drive_lines($bus, $response),
        "",
        "  (transaction $transfer->{name}",
        "    (on $request->{start}",
        "      (sample $request->{address}{name} as addr)",
        "      (sample $request->{write} as is_write)",
        "      (sample $request->{write_data}{name} as wdata" . ($sidebands ? ")" : "))"),
        ($sidebands ? (
            "      (sample $request->{protection}{name} as prot)",
            "      (sample $request->{write_strobe}{name} as wstrb))",
        ) : ()),
        (defined($response->{status}) ? ("    (local slverr (width 1))") : ()),
        "    (drive setup_phase)",
        "    (drive access_phase)",
        "    (await $bus->{ready})",
        "    (sample $bus->{read_data}{name} as rdata)",
        "    (sample $bus->{error} as slverr)",
        _completion_drive_lines($response),
        "    (complete $response->{done})",
        "    (latency (min $transfer->{latency}{min}) (max $transfer->{latency}{max}))))",
        "",
    );
}

sub _contract_has_sidebands($contract) {
    return defined($contract->{bus}{protection}) && defined($contract->{bus}{strobe});
}

sub _apb_data_width($contract) {
    return $contract->{bus}{write_data}{width};
}

sub _apb_strobe_width_for_data_width($data_width) {
    confess "APB requester-transfer IAL2 contract data width must be byte-addressable in this slice\n"
        unless $data_width % 8 == 0;
    return int($data_width / 8);
}

sub _write_strobe_enable_expr($strobe_width, $write_signal = undef) {
    $write_signal //= 'is_write';
    return $write_signal if $strobe_width == 1;
    return '(concat ' . join(' ', ($write_signal) x $strobe_width) . ')';
}

sub _is_sideband_data16_contract($contract) {
    return _contract_has_sidebands($contract) && _apb_data_width($contract) == 16;
}

sub _done_drive_lines($bus, $response) {
    return (
        "  (drive done_phase",
        "    ($bus->{select} 0)",
        "    ($bus->{enable} 0)",
        (defined($bus->{protection}) ? ("    ($bus->{protection}{name} 0)") : ()),
        (defined($bus->{strobe}) ? ("    ($bus->{strobe}{name} 0)") : ()),
        "    ($response->{read_data}{name} rdata)",
        "    ($response->{error} slverr))",
    ) unless defined $response->{status};

    my $status = $response->{status}{name};
    return (
        "  (drive done_phase",
        "    ($bus->{select} 0)",
        "    ($bus->{enable} 0)",
        (defined($bus->{protection}) ? ("    ($bus->{protection}{name} 0)") : ()),
        (defined($bus->{strobe}) ? ("    ($bus->{strobe}{name} 0)") : ()),
        "    ($response->{read_data}{name} rdata)",
        "    ($response->{error} slverr)",
        "    ($status (concat 1'b1 slverr)))",
    );
}

sub _completion_drive_lines($response) {
    return ("    (drive done_phase)");
}

sub _add_response_idle_clears($contract, $fsm_files) {
    confess "APB requester-transfer response-status generation requires generated .fsm files\n"
        unless ref($fsm_files) eq 'HASH';

    my $fsm_name = "$contract->{actor_name}.fsm";
    confess "APB requester-transfer response-status generation is missing generated artifact '$fsm_name'\n"
        unless exists $fsm_files->{$fsm_name};

    my @assignments;
    push @assignments, "    (<- ($contract->{response}{busy}> 0))"
        if defined $contract->{response}{busy};
    push @assignments, "    (<- ($contract->{response}{status}{name}> 0))"
        if defined $contract->{response}{status};

    @assignments = grep { $fsm_files->{$fsm_name} !~ /^\Q$_\E$/m } @assignments;
    return unless @assignments;

    my $idle_state = "$contract->{transfer}{name}_idle_0";
    my $assignment_block = join("\n", @assignments) . "\n";

    my $count = ($fsm_files->{$fsm_name} =~ s/^(\s*\(\Q$idle_state\E\s*\n)/$1$assignment_block/m);
    confess "APB requester-transfer response-status generation could not find generated idle state '$idle_state' in '$fsm_name'\n"
        unless $count == 1;
}

sub _add_back_to_back_requester_behavior($contract, $fsm_files) {
    confess "APB requester-transfer back-to-back generation requires generated .fsm files\n"
        unless ref($fsm_files) eq 'HASH';

    my $fsm_name = "$contract->{actor_name}.fsm";
    confess "APB requester-transfer back-to-back generation is missing generated artifact '$fsm_name'\n"
        unless exists $fsm_files->{$fsm_name};

    my $text = $fsm_files->{$fsm_name};
    _add_back_to_back_queue_sizes(\$text, $contract, $fsm_name);
    _patch_back_to_back_idle_state(\$text, $contract, $fsm_name);
    for my $state_index (1 .. 4) {
        _patch_back_to_back_queue_capture_state(\$text, $contract, $fsm_name, "$contract->{transfer}{name}_drive_$state_index")
            if $state_index == 1 || $state_index == 2 || $state_index == 4;
    }
    _patch_back_to_back_queue_capture_state(\$text, $contract, $fsm_name, "$contract->{transfer}{name}_await_3");
    _patch_back_to_back_done_state(\$text, $contract, $fsm_name);
    _patch_back_to_back_timeout_state(\$text, $contract, $fsm_name);
    $fsm_files->{$fsm_name} = $text;
}

sub _add_back_to_back_queue_sizes($text_ref, $contract, $fsm_name) {
    my $address_width = $contract->{request}{address}{width};
    my $data_width = $contract->{request}{write_data}{width};
    my $sidebands = _contract_has_sidebands($contract);
    my @lines = (
        "    (queued_valid 1)",
        "    (queued_addr $address_width)",
        "    (queued_write 1)",
        "    (queued_wdata $data_width)",
        ($sidebands ? (
            "    (queued_prot $contract->{request}{protection}{width})",
            "    (queued_wstrb $contract->{request}{write_strobe}{width})",
        ) : ()),
    );
    @lines = grep { $$text_ref !~ /^\Q$_\E$/m } @lines;
    return unless @lines;

    my $block = join("\n", @lines) . "\n";
    my $count = ($$text_ref =~ s/^(\s*\(slverr 1\)\n)/$1$block/m);
    confess "APB requester-transfer back-to-back generation could not add queue locals to '$fsm_name'\n"
        unless $count == 1;
}

sub _patch_back_to_back_idle_state($text_ref, $contract, $fsm_name) {
    my $state = "$contract->{transfer}{name}_idle_0";
    my $accepted = $contract->{response}{accepted};
    _insert_unique_state_lines($text_ref, $fsm_name, $state, [
        "    (<- ($accepted> 0))",
        "    (<- (queued_valid 0))",
    ]);

    my $old = join("\n",
        "    (<$contract->{request}{start}",
        "      (-> $contract->{transfer}{name}_drive_1)",
        "    )",
    );
    my $new = join("\n",
        "    (<$contract->{request}{start}",
        "      (<- ($accepted> 1))",
        "      (-> $contract->{transfer}{name}_drive_1)",
        "    )",
    );
    my $count = ($$text_ref =~ s/\Q$old\E/$new/);
    confess "APB requester-transfer back-to-back generation could not patch idle admission in '$fsm_name'\n"
        unless $count == 1 || $$text_ref =~ /\Q$new\E/;
}

sub _patch_back_to_back_queue_capture_state($text_ref, $contract, $fsm_name, $state) {
    my $request = $contract->{request};
    my $accepted = $contract->{response}{accepted};
    my $sidebands = _contract_has_sidebands($contract);
    my @lines = (
        "    (<- ($accepted> 0))",
        "    (?(& $request->{start} (! queued_valid))",
        "      (>0",
        "        (<- ($accepted> 1))",
        "        (<= (queued_addr $request->{address}{name}))",
        "        (<= (queued_write $request->{write}))",
        "        (<= (queued_wdata $request->{write_data}{name}))",
        ($sidebands ? (
            "        (<= (queued_prot $request->{protection}{name}))",
            "        (<= (queued_wstrb $request->{write_strobe}{name}))",
        ) : ()),
        "        (<- (queued_valid 1))))",
    );
    _insert_unique_state_lines($text_ref, $fsm_name, $state, \@lines);
}

sub _patch_back_to_back_done_state($text_ref, $contract, $fsm_name) {
    my $transfer_name = $contract->{transfer}{name};
    my $state = "${transfer_name}_done_5";
    my $accepted = $contract->{response}{accepted};
    my $request = $contract->{request};
    my $bus = $contract->{bus};
    my $response = $contract->{response};
    my $sidebands = _contract_has_sidebands($contract);
    my @queued_sideband_state_lines = $sidebands ? (
        "        (<= (prot queued_prot))",
        "        (<= (wstrb queued_wstrb))",
    ) : ();
    my @queued_sideband_bus_lines = $sidebands ? (
        "        (<- ($bus->{protection}{name}> queued_prot))",
        "        (<- ($bus->{strobe}{name}> (& queued_wstrb " . _write_strobe_enable_expr($bus->{strobe}{width}, 'queued_write') . ")))",
    ) : ();
    my @direct_sideband_state_lines = $sidebands ? (
        "            (<= (prot $request->{protection}{name}))",
        "            (<= (wstrb $request->{write_strobe}{name}))",
    ) : ();
    my @direct_sideband_bus_lines = $sidebands ? (
        "            (<- ($bus->{protection}{name}> $request->{protection}{name}))",
        "            (<- ($bus->{strobe}{name}> (& $request->{write_strobe}{name} " . _write_strobe_enable_expr($bus->{strobe}{width}, $request->{write}) . ")))",
    ) : ();
    my $old = join("\n",
        "  ($state",
        "    (<1 ($response->{done}> 1))",
        "    (= (${transfer_name}_lerr 1) <${transfer_name}_cc<2)",
        "    (-> ${transfer_name}_idle_0)",
        "  )",
    );
    my $new = join("\n",
        "  ($state",
        "    (<- ($accepted> 0))",
        "    (<1 ($response->{done}> 1))",
        "    (= (${transfer_name}_lerr 1) <${transfer_name}_cc<2)",
        "    (?queued_valid",
        "      (>0",
        "        (<= (addr queued_addr))",
        "        (<= (is_write queued_write))",
        "        (<= (wdata queued_wdata))",
        @queued_sideband_state_lines,
        "        (<- (queued_valid 0))",
        "        (<- ($bus->{address}{name}> queued_addr))",
        "        (<- ($bus->{write}> queued_write))",
        "        (<- ($bus->{write_data}{name}> queued_wdata))",
        @queued_sideband_bus_lines,
        "        (<- ($bus->{select}> 1))",
        "        (<- ($bus->{enable}> 0))",
        "        (<- ($response->{busy}> 1))",
        "        (<- ($response->{status}{name}> 1))",
        "        (-> ${transfer_name}_drive_2))",
        "      (=0",
        "        (?$request->{start}",
        "          (>0",
        "            (<- ($accepted> 1))",
        "            (<= (addr $request->{address}{name}))",
        "            (<= (is_write $request->{write}))",
        "            (<= (wdata $request->{write_data}{name}))",
        @direct_sideband_state_lines,
        "            (<- ($bus->{address}{name}> $request->{address}{name}))",
        "            (<- ($bus->{write}> $request->{write}))",
        "            (<- ($bus->{write_data}{name}> $request->{write_data}{name}))",
        @direct_sideband_bus_lines,
        "            (<- ($bus->{select}> 1))",
        "            (<- ($bus->{enable}> 0))",
        "            (<- ($response->{busy}> 1))",
        "            (<- ($response->{status}{name}> 1))",
        "            (-> ${transfer_name}_drive_2))",
        "          (=0",
        "            (-> ${transfer_name}_idle_0)))))",
        "  )",
    );
    my $count = ($$text_ref =~ s/\Q$old\E/$new/);
    confess "APB requester-transfer back-to-back generation could not patch terminal state '$state' in '$fsm_name'\n"
        unless $count == 1 || $$text_ref =~ /^\s*\(\Q$state\E\s*\n\s*\Q(<- ($accepted> 0))\E/m;
}

sub _patch_back_to_back_timeout_state($text_ref, $contract, $fsm_name) {
    my $state = "$contract->{transfer}{name}_timeout";
    _insert_unique_state_lines($text_ref, $fsm_name, $state, [
        "    (<- ($contract->{response}{accepted}> 0))",
        "    (<- (queued_valid 0))",
    ]);
}

sub _insert_unique_state_lines($text_ref, $fsm_name, $state, $lines) {
    my $block = join("\n", @$lines) . "\n";
    my $count = ($$text_ref =~ s/^(\s*\(\Q$state\E\s*\n)/$1$block/m);
    confess "APB requester-transfer back-to-back generation could not find generated state '$state' in '$fsm_name'\n"
        unless $count == 1;
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

    my $report = {
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
        width_policy => _apb_requester_width_policy($contract),
        transfer => {
            name        => $contract->{transfer}{name},
            setup       => _clone_jsonish($contract->{transfer}{setup}),
            access      => _clone_jsonish($contract->{transfer}{access}),
            complete_on => $contract->{transfer}{complete_on},
            sample      => _clone_jsonish($contract->{transfer}{sample}),
            latency     => _clone_jsonish($contract->{transfer}{latency}),
            (_requester_has_back_to_back_policy($contract) ? (
                timing_policy => _apb_requester_timing_policy_report($contract),
            ) : ()),
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
            (_requester_has_back_to_back_policy($contract) ? ({
                id     => 'apb_back_to_back_queue_depth_1',
                detail => 'Generated IAL0 accepts one active APB transfer plus one queued transfer, rejects overflow without overwriting the queued request, and can launch the next setup without an inserted idle cycle.',
            }) : ()),
            (defined($contract->{response}{status}) ? ({
                id     => 'apb_status_field_encoding',
                detail => 'Generated IAL1 drives the selected 2-bit response status encoding: 0 idle, 1 busy, 2 done_ok, 3 done_error.',
            }) : ()),
        ],
        assumptions => [
            {
                id     => 'single_outstanding_transfer',
                detail => _requester_has_back_to_back_policy($contract)
                    ? 'The selected APB requester still drives at most one active APB bus transfer while holding at most one queued next transfer.'
                    : 'This first APB PPIF slice models one requester transfer at a time and delegates scheduling to the existing IAL1 lowering path.',
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
            _apb_requester_data_width_rule($contract),
            (_contract_has_sidebands($contract) ? (_apb_requester_sideband_width_rule($contract)) : ()),
            'setup phase must drive select 1 and enable 0',
            'access phase must drive select 1 and enable 1',
            'completion waits on ready, samples read-data and error, and reports latency min 2 max 16',
            'APB requester-transfer is exposed through .ppif and bounded .apb profile-alias sources; APB completer and fixed composition aliases are exposed through sibling .apb samples; direct IAL2-to-IAL0 lowering remains forbidden',
        ],
        unsupported_residue => _apb_requester_unsupported_residue($contract),
    };

    $report->{response_status_field} = {
        name     => $contract->{response}{status}{name},
        width    => $contract->{response}{status}{width},
        encoding => _apb_requester_status_encoding(),
    } if defined $contract->{response}{status};
    $report->{response_accepted_field} = {
        name   => $contract->{response}{accepted},
        width  => 1,
        policy => 'pulses when start is sampled into the active slot or the empty depth-1 queued slot',
    } if defined $contract->{response}{accepted};

    return $report;
}

sub _apb_requester_unsupported_residue($contract) {
    my @residue = (
        {
            id     => 'apb_multi_peripheral_decode_deferred',
            detail => 'Address decode, peripheral selection beyond one PSEL, and multi-peripheral routing remain future APB work.',
        },
    );
    push @residue, _contract_has_sidebands($contract)
        ? _apb_protection_policy_effects_residue()
        : _apb_sideband_residue();

    if (defined($contract->{response}{status})) {
        # The selected busy+status response contract is fully represented here.
    } elsif (defined($contract->{response}{busy})) {
        push @residue, {
            id     => 'apb_requester_status_field_deferred',
            detail => 'The APB requester-transfer public response contract exposes busy, done, read-data, and error; named status fields remain future APB contract widening.',
        };
    } else {
        push @residue, {
            id     => 'apb_requester_busy_status_deferred',
            detail => 'The APB requester-transfer public response contract exposes done, read-data, and error; requester busy/status output remains future contract widening.',
        };
    }

    push @residue, (
        _apb_requester_width_residue($contract),
        _requester_has_back_to_back_policy($contract)
            ? _apb_additional_back_to_back_policies_residue()
            : {
                id     => 'apb_back_to_back_policy_deferred',
                detail => 'Back-to-back transfer policy and queued transfer admission remain future exact-owner work.',
            },
    );

    return \@residue;
}

sub _requester_has_back_to_back_policy($contract) {
    return ref($contract->{transfer}{timing_policy}) eq 'HASH'
        && ($contract->{transfer}{timing_policy}{back_to_back} // '') eq 'queued';
}

sub _apb_requester_timing_policy_report($contract) {
    return {
        back_to_back => $contract->{transfer}{timing_policy}{back_to_back},
        queue_depth  => $contract->{transfer}{timing_policy}{queue_depth},
        overflow     => $contract->{transfer}{timing_policy}{overflow},
        accepted     => $contract->{response}{accepted},
    };
}

sub _apb_additional_back_to_back_policies_residue() {
    return {
        id     => 'apb_additional_back_to_back_policies_deferred',
        detail => 'Depth-1 queued requester admission with overflow reject is implemented for the selected 32-bit no-sideband status requester and selected 32-bit sideband-aware status requester, including selected fixed-composition and two-peripheral interconnect/decode propagation; deeper queues, alternate overflow policies, accepted-less surfaces, data16/protection variants, multiple active APB transfers, broader interconnect propagation, direct backend lowering, verification-output, backend-language variants, AXI, AHB, and VHDL remain future work.',
    };
}

sub _apb_requester_width_policy($contract) {
    my $data_width = _apb_data_width($contract);
    my %policy = (
        address_width          => 32,
        data_width             => $data_width,
        requester_status_width => defined($contract->{response}{status}) ? $contract->{response}{status}{width} : undef,
        supported_data_widths  => [16, 32],
        selected_contract      => _is_sideband_data16_contract($contract) ? 'sideband_data16' : 'fixed_data32',
    );
    if (_contract_has_sidebands($contract)) {
        $policy{protection_width} = $contract->{bus}{protection}{width};
        $policy{strobe_width} = $contract->{bus}{strobe}{width};
        $policy{write_strobe_width} = $contract->{request}{write_strobe}{width};
    }
    return \%policy;
}

sub _apb_requester_data_width_rule($contract) {
    my $data_width = _apb_data_width($contract);
    return "address width is fixed at 32 bits; write-data and read-data widths are fixed at the selected $data_width-bit APB data width for this slice";
}

sub _apb_requester_sideband_width_rule($contract) {
    my $strobe_width = $contract->{bus}{strobe}{width};
    return "sideband-aware requester-transfer contracts require PPROT width 3 and data-derived PSTRB/write-strobe width $strobe_width";
}

sub _apb_requester_width_residue($contract) {
    return {
        id     => 'apb_remaining_widths_deferred',
        detail => 'Address widths other than 32 bits and APB data widths beyond the selected sideband-aware 16/32-bit boundary remain future APB requester-transfer work.',
    } if _is_sideband_data16_contract($contract);

    return {
        id     => 'apb_alternate_widths_deferred',
        detail => 'The public APB PPIF requester-transfer source fixes address, write-data, and read-data widths to 32 bits.',
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
        detail => 'PPROT is propagated by the generated APB requester, but protection access-control policy remains future APB work.',
    };
}

sub _apb_requester_status_encoding() {
    return [
        {
            name   => 'idle',
            code   => 0,
            detail => 'No active transfer is being driven by the requester.',
        },
        {
            name   => 'busy',
            code   => 1,
            detail => 'The requester is in setup or access phase for an active transfer.',
        },
        {
            name   => 'done_ok',
            code   => 2,
            detail => 'The transfer completed after PREADY with PSLVERR low.',
        },
        {
            name   => 'done_error',
            code   => 3,
            detail => 'The transfer completed after PREADY with PSLVERR high.',
        },
    ];
}

sub _clone_jsonish($value) {
    return undef unless defined $value;
    return [map { _clone_jsonish($_) } @$value] if ref($value) eq 'ARRAY';
    return { map { $_ => _clone_jsonish($value->{$_}) } sort keys %$value } if ref($value) eq 'HASH';
    return $value;
}

1;
