package FSM::IAL2::ProtocolIntent::AxiArDriver;

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

# Bounded AXI manager AR read-address-channel driver (initiator, bus-driving side).
# Public contract selected by IAL2-AXI-MANAGER-INITIATOR-FRONTIER.25.
# See docs/IAL2_AXI_MANAGER_INITIATOR_AR_DRIVER_CONTRACT_SELECTION.md.
#
# It issues one AR read-address transfer: on a one-shot command trigger it samples
# the command payload, asserts ARVALID and drives the AR payload held stable
# until ARREADY, then completes with a one-cycle done pulse. It complements the
# capacity/status response core; it drives no R channel in this slice and its
# done pulse means only that the AR request was accepted.

my @COMMAND_WIDTH_FIELDS = (
    [address => 'araddr', 32],
    [id      => 'arid',   4],
    [length  => 'arlen',  8],
    [size    => 'arsize', 3],
    [burst   => 'arburst', 2],
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
    confess "FSM::IAL2::ProtocolIntent::AxiArDriver->generate expects exactly one contract hash reference\n"
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
        kind  => 'protocol_intent.axi_ar_driver',
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
    confess "FSM::IAL2::ProtocolIntent::AxiArDriver->new must be called with the FSM::IAL2::ProtocolIntent::AxiArDriver class invocant\n"
        unless defined($class) && !ref($class) && $class eq 'FSM::IAL2::ProtocolIntent::AxiArDriver';
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
    confess "FSM::IAL2::ProtocolIntent::AxiArDriver->$method must be called on an FSM::IAL2::ProtocolIntent::AxiArDriver object\n"
        unless blessed($self) && $self->isa('FSM::IAL2::ProtocolIntent::AxiArDriver');
}

sub _normalize_contract($raw) {
    my $kind = _required_scalar($raw, 'kind');
    confess "AXI AR driver IAL2 contract kind must be axi_ar_driver\n"
        unless $kind eq 'axi_ar_driver';

    my $protocol = lc _required_scalar($raw, 'protocol');
    confess "AXI AR driver IAL2 contract profile must be axi4 in this slice\n"
        unless $protocol eq 'axi4';

    my $name = _required_identifier($raw, 'name');
    my $actor_name = exists($raw->{actor_name})
        ? _identifier_value($raw->{actor_name}, 'actor_name')
        : $name;

    my $role = lc _required_scalar($raw, 'role');
    confess "AXI AR driver IAL2 contract role must be manager-to-subordinate\n"
        unless $role eq 'manager-to-subordinate';

    my $clock = _required_identifier($raw, 'clock');
    my $reset = _normalize_reset($raw->{reset});
    my $command = _normalize_command(_required_hash($raw, 'command'));
    my $channel = _normalize_channel(_required_hash($raw, 'channel'));

    _reject_duplicate_signal_names(
        $clock,
        $reset->{signal},
        _binding_names($command),
        _binding_names($channel),
        qw(addr_q id_q len_q size_q burst_q active_q),
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
        channel          => $channel,
        intent_name      => $intent_name,
        source_object_id => $source_object_id,
        source_anchors   => $anchors,
    };
}

sub _normalize_command($raw) {
    my %command = (
        start => _required_identifier_field($raw, 'start', 'command.start'),
        ready => _required_identifier_field($raw, 'ready', 'command.ready'),
    );
    for my $field (@COMMAND_WIDTH_FIELDS) {
        my ($key, undef, $width) = @$field;
        $command{$key} = _normalize_width_binding($raw->{$key}, "command.$key", $width);
    }
    return \%command;
}

sub _normalize_channel($raw) {
    my %channel = (
        valid => _required_identifier_field($raw, 'valid', 'channel.valid'),
        busy  => _required_identifier_field($raw, 'busy', 'channel.busy'),
        done  => _required_identifier_field($raw, 'done', 'channel.done'),
    );
    for my $field (@COMMAND_WIDTH_FIELDS) {
        my ($key, undef, $width) = @$field;
        $channel{$key} = _normalize_width_binding($raw->{$key}, "channel.$key", $width);
    }
    return \%channel;
}

sub _emit_isf($contract) {
    my $cmd = $contract->{command};
    my $chan = $contract->{channel};
    my $reset = _reset_clause($contract->{reset});

    # Exactly-once Valid-Ready schedule selected and executably proved in
    # IAL2-AXI-MANAGER-INITIATOR-FRONTIER.25:
    #   - the inline launch drive is a one-state combinational handoff;
    #   - `launch_ar` registers ARVALID, busy, and the sampled payload;
    #   - `accept_ar` clears ARVALID/busy/active_q on the same edge that sees
    #     ARVALID && ARREADY, preventing a second acceptance under held READY;
    #   - explicit accept-over-launch priority resolves every shared rule write;
    #   - the transaction waits on latched active_q, so a one-cycle READY pulse
    #     cannot be lost while scheduled control advances;
    #   - `(complete <done>)` still emits the one-cycle done pulse.
    return join("\n",
        "(actor $contract->{actor_name}",
        "  (clock $contract->{clock})",
        "  $reset",
        "",
        "  (interface",
        _interface_line('input', $cmd->{start}),
        _interface_line('input', $cmd->{address}),
        _interface_line('input', $cmd->{id}),
        _interface_line('input', $cmd->{length}),
        _interface_line('input', $cmd->{size}),
        _interface_line('input', $cmd->{burst}),
        _interface_line('input', $cmd->{ready}),
        _interface_line('output', $chan->{valid}),
        _interface_line('output', $chan->{address}),
        _interface_line('output', $chan->{id}),
        _interface_line('output', $chan->{length}),
        _interface_line('output', $chan->{size}),
        _interface_line('output', $chan->{burst}),
        _interface_line('output', $chan->{busy}),
        _interface_line('output', $chan->{done}) . ")",
        "",
        "  (priority accept_ar over launch_ar)",
        "",
        "  (rule launch_ar launch_ar_start",
        "    (set active_q 1)",
        "    (set $chan->{busy} 1)",
        "    (set $chan->{valid} 1)",
        "    (set $chan->{address}{name} addr_q)",
        "    (set $chan->{id}{name} id_q)",
        "    (set $chan->{length}{name} len_q)",
        "    (set $chan->{size}{name} size_q)",
        "    (set $chan->{burst}{name} burst_q))",
        "",
        "  (rule accept_ar (& $chan->{valid} $cmd->{ready})",
        "    (set active_q 0)",
        "    (set $chan->{busy} 0)",
        "    (set $chan->{valid} 0))",
        "",
        "  (transaction ar_issue",
        "    (on $cmd->{start}",
        "      (sample $cmd->{address}{name} as addr_q)",
        "      (sample $cmd->{id}{name} as id_q)",
        "      (sample $cmd->{length}{name} as len_q)",
        "      (sample $cmd->{size}{name} as size_q)",
        "      (sample $cmd->{burst}{name} as burst_q))",
        "    (drive",
        "      (launch_ar_start 1))",
        "    (while active_q",
        "      (wait 1))",
        "    (complete $chan->{done})))",
        "",
    );
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
        schema => 'fsmgen.ial2.protocol_intent.axi_ar_driver.v1',
        mode   => 'driver',
        layering => {
            source_layer          => 'IAL2',
            generated_ial1_format => 'isf',
            generated_ial0_format => 'fsm',
            direct_ial2_to_ial0   => JSON::PP::false,
        },
        source_object => \%source_object,
        target_protocol => {
            profile => $contract->{protocol},
            object  => 'axi-ar-driver',
            role    => $contract->{role},
        },
        driver => {
            name       => $contract->{name},
            actor_name => $contract->{actor_name},
        },
        bindings => {
            clock   => $contract->{clock},
            reset   => _clone_jsonish($contract->{reset}),
            command => _clone_jsonish($contract->{command}),
            channel => _clone_jsonish($contract->{channel}),
        },
        request_scope => {
            address_width          => 32,
            id_width               => 4,
            length_width           => 8,
            size_width             => 3,
            burst_width            => 2,
            done_event             => 'ar_request_accepted',
            includes_read_response => JSON::PP::false,
        },
        generated_artifacts => {
            ial1 => {
                name   => $args{isf_name},
                format => 'isf',
            },
            ial0 => {
                files  => \@fsm_files,
                format => 'fsm',
            },
            hdl_entry => {
                selected       => JSON::PP::true,
                kind           => 'generated_driver_fsm',
                entry_artifact => "$contract->{actor_name}.fsm",
            },
        },
        enforced_static_rules => [
            'profile must be axi4 and the object must be axi-ar-driver',
            'role must be manager-to-subordinate',
            'AR address width is 32 and AR id width is 4 in this slice',
            'AR length width is 8, size width is 3, and burst width is 2 in this slice',
            'the first slice drives the complete core AR request payload (address, id, length, size, burst)',
            'ARVALID launches independently of ARREADY and accepts exactly once per admitted command',
            'ar_done means accepted AR request, not read response or transaction completion',
            'command inputs and driven channel/status outputs are distinct',
            'direct IAL2-to-IAL0 lowering is forbidden',
        ],
        unsupported_residue => _unsupported_residue(),
    };
}

sub _unsupported_residue {
    return [
        {
            id     => 'axi_ar_driver_id_width_fixed',
            detail => 'ARID width is pinned to 4 in this slice; configurable ID width remains deferred.',
        },
        {
            id     => 'axi_ar_driver_attributes_deferred',
            detail => 'Extended AR attributes and optional sidebands including ARREGION/ARLOCK/ARCACHE/ARPROT/ARQOS/ARUSER are not driven in this slice.',
        },
        {
            id     => 'axi_ar_driver_request_legality_deferred',
            detail => 'The driver transports authored AR metadata but does not validate 4KB crossing, reserved encodings, WRAP constraints, alignment, size/data-width coupling, or other address/length/size/burst combinations.',
        },
        {
            id     => 'axi_ar_driver_r_channel_deferred',
            detail => 'RREADY, RID/RDATA/RRESP/RLAST capture, beat accounting, and ARID/RID matching remain deferred; a complete manager must accept every returned beat described by the issued request.',
        },
        {
            id     => 'axi_ar_driver_request_only_completion',
            detail => 'ar_done reports only accepted AR request issue; read response and full transaction completion require a later composition.',
        },
        {
            id     => 'axi_ar_driver_capacity_core_integration_deferred',
            detail => 'Integration with the AXI manager capacity/status response core remains future work.',
        },
        {
            id     => 'axi_ar_driver_outstanding_deferred',
            detail => 'The driver admits one request while idle and has no queue or multiple-outstanding-read policy.',
        },
        {
            id     => 'axi_ar_driver_transaction_interface_deferred',
            detail => 'Decision 0020 protocol-neutral transaction-interface composition remains director-gated.',
        },
        {
            id     => 'axi_ar_driver_profile_alias_deferred',
            detail => '.axi profile-alias surfacing of the AR driver remains an unsupported candidate; this slice supports only generic .ppif.',
        },
        {
            id     => 'axi_ar_driver_verification_output_deferred',
            detail => 'Verification-output generation remains deferred.',
        },
        {
            id     => 'axi_ar_driver_backend_variants_deferred',
            detail => 'Direct backend lowering, backend-language variants, and VHDL behavior remain deferred.',
        },
    ];
}

sub _required_scalar($raw, $field) {
    confess "AXI AR driver IAL2 contract is missing required scalar field '$field'\n"
        unless exists($raw->{$field});
    return _nonempty_scalar($raw->{$field}, $field);
}

sub _required_hash($raw, $field) {
    confess "AXI AR driver IAL2 contract field '$field' must be a hash reference\n"
        unless ref($raw->{$field}) eq 'HASH';
    return $raw->{$field};
}

sub _required_identifier($raw, $field) {
    return _identifier_value(_required_scalar($raw, $field), $field);
}

sub _required_identifier_field($raw, $field, $label) {
    confess "AXI AR driver IAL2 contract is missing required field '$label'\n"
        unless exists($raw->{$field});
    return _identifier_value($raw->{$field}, $label);
}

sub _normalize_width_binding($raw, $field, $expected_width) {
    confess "AXI AR driver IAL2 contract field '$field' must be a hash reference\n"
        unless ref($raw) eq 'HASH';
    my $name = _identifier_value($raw->{name}, "$field.name");
    my $width = _positive_integer($raw->{width}, "$field.width");
    confess "AXI AR driver IAL2 contract $field.width must be $expected_width in this slice\n"
        unless $width == $expected_width;
    return {
        name  => $name,
        width => $width,
    };
}

sub _normalize_reset($raw_reset) {
    confess "AXI AR driver IAL2 contract is missing required reset binding\n"
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
    confess "AXI AR driver IAL2 contract source.anchors must be an array reference\n"
        unless ref($anchors) eq 'ARRAY';

    my @normalized;
    for my $index (0 .. $#$anchors) {
        my $anchor = $anchors->[$index];
        if (ref($anchor) eq 'HASH') {
            for my $required (qw(document section page)) {
                confess "AXI AR driver IAL2 contract source.anchors[$index] is missing '$required'\n"
                    unless defined($anchor->{$required}) && !ref($anchor->{$required}) && length($anchor->{$required});
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
        confess "AXI AR driver IAL2 contract duplicates interface/internal signal '$name'\n"
            if $seen{$name}++;
    }
}

sub _nonempty_scalar($value, $field) {
    confess "AXI AR driver IAL2 contract field '$field' must be a non-empty scalar\n"
        if !defined($value) || ref($value) || $value eq '';
    return $value;
}

sub _identifier_value($value, $field) {
    confess "AXI AR driver IAL2 contract field '$field' must be an ISF identifier\n"
        unless defined($value) && !ref($value) && $value =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
    return $value;
}

sub _positive_integer($value, $field) {
    confess "AXI AR driver IAL2 contract field '$field' must be a positive integer\n"
        unless defined($value) && !ref($value) && $value =~ /\A[1-9][0-9]*\z/;
    return int($value);
}

sub _bool_value($value, $field) {
    confess "AXI AR driver IAL2 contract field '$field' must be boolean 0 or 1\n"
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
    return "(reset (" . join(' ', @parts) . "))";
}

sub _clone_jsonish($value) {
    return $value unless ref($value);
    return [map { _clone_jsonish($_) } @$value] if ref($value) eq 'ARRAY';
    return { map { $_ => _clone_jsonish($value->{$_}) } keys %$value } if ref($value) eq 'HASH';
    return $value;
}

1;
