package FSM::IAL2::ProtocolIntent::AxiWDriver;

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

# Bounded AXI manager W write-data-channel driver (initiator, bus-driving side).
# Public contract selected by IAL2-AXI-MANAGER-INITIATOR-FRONTIER.9.
# See docs/IAL2_AXI_MANAGER_INITIATOR_W_DRIVER_CONTRACT_SELECTION.md.
#
# It issues one W transfer: on a one-shot command trigger it samples 32-bit
# data and four byte strobes, asserts WVALID with WLAST=1, holds the W payload
# stable until WREADY, accepts exactly once, and emits one done pulse. AW/W
# coordination, B completion, and multi-beat sequencing remain explicit
# residue rather than hidden behavior in this channel primitive.

my @WIDTH_FIELDS = (
    [data   => 32],
    [strobe => 4],
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
    confess "FSM::IAL2::ProtocolIntent::AxiWDriver->generate expects exactly one contract hash reference\n"
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
        contract  => $contract,
        isf_name  => $isf_name,
        fsm_files => [sort keys %{$lowered->{files} || {}}],
    );

    return {
        layer => 'IAL2',
        kind  => 'protocol_intent.axi_w_driver',
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
    confess "FSM::IAL2::ProtocolIntent::AxiWDriver->new must be called with the FSM::IAL2::ProtocolIntent::AxiWDriver class invocant\n"
        unless defined($class) && !ref($class) && $class eq 'FSM::IAL2::ProtocolIntent::AxiWDriver';
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
    confess "FSM::IAL2::ProtocolIntent::AxiWDriver->$method must be called on an FSM::IAL2::ProtocolIntent::AxiWDriver object\n"
        unless blessed($self) && $self->isa('FSM::IAL2::ProtocolIntent::AxiWDriver');
}

sub _normalize_contract($raw) {
    my $kind = _required_scalar($raw, 'kind');
    confess "AXI W driver IAL2 contract kind must be axi_w_driver\n"
        unless $kind eq 'axi_w_driver';

    my $protocol = lc _required_scalar($raw, 'protocol');
    confess "AXI W driver IAL2 contract profile must be axi4 in this slice\n"
        unless $protocol eq 'axi4';

    my $name = _required_identifier($raw, 'name');
    my $actor_name = exists($raw->{actor_name})
        ? _identifier_value($raw->{actor_name}, 'actor_name')
        : $name;

    my $role = lc _required_scalar($raw, 'role');
    confess "AXI W driver IAL2 contract role must be manager-to-subordinate\n"
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
        qw(data_q strb_q active_q),
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
    for my $field (@WIDTH_FIELDS) {
        my ($key, $width) = @$field;
        $command{$key} = _normalize_width_binding($raw->{$key}, "command.$key", $width);
    }
    return \%command;
}

sub _normalize_channel($raw) {
    my %channel = (
        valid => _required_identifier_field($raw, 'valid', 'channel.valid'),
        last  => _required_identifier_field($raw, 'last', 'channel.last'),
        busy  => _required_identifier_field($raw, 'busy', 'channel.busy'),
        done  => _required_identifier_field($raw, 'done', 'channel.done'),
    );
    for my $field (@WIDTH_FIELDS) {
        my ($key, $width) = @$field;
        $channel{$key} = _normalize_width_binding($raw->{$key}, "channel.$key", $width);
    }
    return \%channel;
}

sub _emit_isf($contract) {
    my $cmd = $contract->{command};
    my $chan = $contract->{channel};
    my $reset = _reset_clause($contract->{reset});

    # Exactly-once Valid-Ready schedule selected in .9 from the AW correction:
    #   - launch registers activity, busy, WVALID, WDATA, WSTRB, and WLAST=1;
    #   - acceptance clears activity/busy/WVALID on the WVALID && WREADY edge;
    #   - accept-over-launch priority prevents a second beat under held READY;
    #   - the transaction waits on latched active_q, preserving one-cycle READY;
    #   - `(complete <done>)` emits the one-cycle completion pulse.
    return join("\n",
        "(actor $contract->{actor_name}",
        "  (clock $contract->{clock})",
        "  $reset",
        "",
        "  (interface",
        _interface_line('input', $cmd->{start}),
        _interface_line('input', $cmd->{data}),
        _interface_line('input', $cmd->{strobe}),
        _interface_line('input', $cmd->{ready}),
        _interface_line('output', $chan->{valid}),
        _interface_line('output', $chan->{data}),
        _interface_line('output', $chan->{strobe}),
        _interface_line('output', $chan->{last}),
        _interface_line('output', $chan->{busy}),
        _interface_line('output', $chan->{done}) . ")",
        "",
        "  (priority accept_w over launch_w)",
        "",
        "  (rule launch_w launch_w_start",
        "    (set active_q 1)",
        "    (set $chan->{busy} 1)",
        "    (set $chan->{valid} 1)",
        "    (set $chan->{data}{name} data_q)",
        "    (set $chan->{strobe}{name} strb_q)",
        "    (set $chan->{last} 1))",
        "",
        "  (rule accept_w (& $chan->{valid} $cmd->{ready})",
        "    (set active_q 0)",
        "    (set $chan->{busy} 0)",
        "    (set $chan->{valid} 0))",
        "",
        "  (transaction w_issue",
        "    (on $cmd->{start}",
        "      (sample $cmd->{data}{name} as data_q)",
        "      (sample $cmd->{strobe}{name} as strb_q))",
        "    (drive",
        "      (launch_w_start 1))",
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
        schema => 'fsmgen.ial2.protocol_intent.axi_w_driver.v1',
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
            object  => 'axi-w-driver',
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
        single_beat => {
            data_width             => 32,
            strobe_width           => 4,
            last_value             => 1,
            all_zero_strobe_allowed => JSON::PP::true,
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
            'profile must be axi4 and the object must be axi-w-driver',
            'role must be manager-to-subordinate',
            'W data width is 32 in this slice',
            'W strobe width is 4 and equals the data width divided by eight',
            'the first slice emits one beat with scalar WLAST fixed high while valid',
            'all-zero WSTRB is legal',
            'command inputs and driven channel/status outputs are distinct',
            'direct IAL2-to-IAL0 lowering is forbidden',
        ],
        unsupported_residue => _unsupported_residue(),
    };
}

sub _unsupported_residue {
    return [
        {
            id     => 'axi_w_driver_aw_coordination_deferred',
            detail => 'Coordinated AW+W transaction launch and completion remain future work.',
        },
        {
            id     => 'axi_w_driver_b_response_completion_deferred',
            detail => 'B-channel observation, response handling, and write-transaction completion remain future work.',
        },
        {
            id     => 'axi_w_driver_multi_beat_deferred',
            detail => 'Beat counters, data sequences, and dynamic WLAST remain future work; this slice emits exactly one beat.',
        },
        {
            id     => 'axi_w_driver_outstanding_transactions_deferred',
            detail => 'This slice supports one active command with no queue or multiple outstanding writes.',
        },
        {
            id     => 'axi_w_driver_burst_address_coupling_deferred',
            detail => 'AWLEN/AWSIZE/address coupling to write data remains future work.',
        },
        {
            id     => 'axi_w_driver_ar_r_channels_deferred',
            detail => 'Read-address and read-data behavior remain outside this write-data primitive.',
        },
        {
            id     => 'axi_w_driver_capacity_core_integration_deferred',
            detail => 'Integration with the AXI manager capacity/status response core remains future work.',
        },
        {
            id     => 'axi_w_driver_transaction_interface_deferred',
            detail => 'The protocol-neutral transaction interface and role composition from decision 0020 remain future work.',
        },
        {
            id     => 'axi_w_driver_profile_alias_deferred',
            detail => '.axi profile-alias surfacing remains unsupported; this slice supports only generic .ppif.',
        },
        {
            id     => 'axi_w_driver_verification_output_deferred',
            detail => 'Direct verification-output generation from this IAL2 source remains future work.',
        },
        {
            id     => 'axi_w_driver_backend_variants_deferred',
            detail => 'Backend-language variants and VHDL behavior remain future work.',
        },
    ];
}

sub _required_scalar($raw, $field) {
    confess "AXI W driver IAL2 contract is missing required scalar field '$field'\n"
        unless exists($raw->{$field});
    return _nonempty_scalar($raw->{$field}, $field);
}

sub _required_hash($raw, $field) {
    confess "AXI W driver IAL2 contract field '$field' must be a hash reference\n"
        unless ref($raw->{$field}) eq 'HASH';
    return $raw->{$field};
}

sub _required_identifier($raw, $field) {
    return _identifier_value(_required_scalar($raw, $field), $field);
}

sub _required_identifier_field($raw, $field, $label) {
    confess "AXI W driver IAL2 contract is missing required field '$label'\n"
        unless exists($raw->{$field});
    return _identifier_value($raw->{$field}, $label);
}

sub _normalize_width_binding($raw, $field, $expected_width) {
    confess "AXI W driver IAL2 contract field '$field' must be a hash reference\n"
        unless ref($raw) eq 'HASH';
    my $name = _identifier_value($raw->{name}, "$field.name");
    my $width = _positive_integer($raw->{width}, "$field.width");
    confess "AXI W driver IAL2 contract $field.width must be $expected_width in this slice\n"
        unless $width == $expected_width;
    return {
        name  => $name,
        width => $width,
    };
}

sub _normalize_reset($raw_reset) {
    confess "AXI W driver IAL2 contract is missing required reset binding\n"
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
    confess "AXI W driver IAL2 contract source.anchors must be an array reference\n"
        unless ref($anchors) eq 'ARRAY';

    my @normalized;
    for my $index (0 .. $#$anchors) {
        my $anchor = $anchors->[$index];
        if (ref($anchor) eq 'HASH') {
            for my $required (qw(document section page)) {
                confess "AXI W driver IAL2 contract source.anchors[$index] is missing '$required'\n"
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
        confess "AXI W driver IAL2 contract duplicates signal '$name'\n"
            if $seen{$name}++;
    }
}

sub _nonempty_scalar($value, $field) {
    confess "AXI W driver IAL2 contract field '$field' must be a non-empty scalar\n"
        if !defined($value) || ref($value) || $value eq '';
    return $value;
}

sub _identifier_value($value, $field) {
    confess "AXI W driver IAL2 contract field '$field' must be an ISF identifier\n"
        unless defined($value) && !ref($value) && $value =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
    return $value;
}

sub _positive_integer($value, $field) {
    confess "AXI W driver IAL2 contract field '$field' must be a positive integer\n"
        unless defined($value) && !ref($value) && $value =~ /\A[1-9][0-9]*\z/;
    return int($value);
}

sub _bool_value($value, $field) {
    confess "AXI W driver IAL2 contract field '$field' must be boolean 0 or 1\n"
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
