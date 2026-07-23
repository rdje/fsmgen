package FSM::IAL2::ProtocolIntent::AxiBResponseAcceptor;

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

# Bounded manager-side AXI B write-response acceptor. Public contract selected
# by IAL2-AXI-MANAGER-INITIATOR-FRONTIER.13; see
# docs/IAL2_AXI_MANAGER_INITIATOR_B_RESPONSE_ACCEPTOR_CONTRACT_SELECTION.md.
#
# One idle-time arm raises BREADY without waiting for BVALID. One response
# handshake captures fixed-width BID/BRESP, clears ready/busy, holds the
# captured response, and later emits one completion pulse. Cross-channel
# composition, outstanding responses, and capacity-core integration remain
# explicit residue.

my @CHANNEL_WIDTH_FIELDS = (
    [id                => 4],
    [response          => 2],
    [captured_id       => 4],
    [captured_response => 2],
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
    confess "FSM::IAL2::ProtocolIntent::AxiBResponseAcceptor->generate expects exactly one contract hash reference\n"
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
        kind  => 'protocol_intent.axi_b_response_acceptor',
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
    confess "FSM::IAL2::ProtocolIntent::AxiBResponseAcceptor->new must be called with the FSM::IAL2::ProtocolIntent::AxiBResponseAcceptor class invocant\n"
        unless defined($class) && !ref($class) && $class eq 'FSM::IAL2::ProtocolIntent::AxiBResponseAcceptor';
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
    confess "FSM::IAL2::ProtocolIntent::AxiBResponseAcceptor->$method must be called on an FSM::IAL2::ProtocolIntent::AxiBResponseAcceptor object\n"
        unless blessed($self) && $self->isa('FSM::IAL2::ProtocolIntent::AxiBResponseAcceptor');
}

sub _normalize_contract($raw) {
    my $kind = _required_scalar($raw, 'kind');
    confess "AXI B response acceptor IAL2 contract kind must be axi_b_response_acceptor\n"
        unless $kind eq 'axi_b_response_acceptor';

    my $protocol = lc _required_scalar($raw, 'protocol');
    confess "AXI B response acceptor IAL2 contract profile must be axi4 in this slice\n"
        unless $protocol eq 'axi4';

    my $name = _required_identifier($raw, 'name');
    my $actor_name = exists($raw->{actor_name})
        ? _identifier_value($raw->{actor_name}, 'actor_name')
        : $name;

    my $role = lc _required_scalar($raw, 'role');
    confess "AXI B response acceptor IAL2 contract role must be subordinate-to-manager\n"
        unless $role eq 'subordinate-to-manager';

    my $clock = _required_identifier($raw, 'clock');
    my $reset = _normalize_reset($raw->{reset});
    my $command = _normalize_command(_required_hash($raw, 'command'));
    my $channel = _normalize_channel(_required_hash($raw, 'channel'));

    _reject_duplicate_signal_names(
        $clock,
        $reset->{signal},
        _binding_names($command),
        _binding_names($channel),
        qw(active_q arm_b_start),
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
    return {
        arm => _required_identifier_field($raw, 'arm', 'command.arm'),
    };
}

sub _normalize_channel($raw) {
    my %channel = (
        valid => _required_identifier_field($raw, 'valid', 'channel.valid'),
        ready => _required_identifier_field($raw, 'ready', 'channel.ready'),
        busy  => _required_identifier_field($raw, 'busy', 'channel.busy'),
        done  => _required_identifier_field($raw, 'done', 'channel.done'),
    );
    for my $field (@CHANNEL_WIDTH_FIELDS) {
        my ($key, $width) = @$field;
        $channel{$key} = _normalize_width_binding($raw->{$key}, "channel.$key", $width);
    }
    return \%channel;
}

sub _emit_isf($contract) {
    my $cmd = $contract->{command};
    my $chan = $contract->{channel};
    my $reset = _reset_clause($contract->{reset});

    return join("\n",
        "(actor $contract->{actor_name}",
        "  (clock $contract->{clock})",
        "  $reset",
        "",
        "  (interface",
        _interface_line('input', $cmd->{arm}),
        _interface_line('input', $chan->{valid}),
        _interface_line('input', $chan->{id}),
        _interface_line('input', $chan->{response}),
        _interface_line('output', $chan->{ready}),
        _interface_line('output', $chan->{captured_id}),
        _interface_line('output', $chan->{captured_response}),
        _interface_line('output', $chan->{busy}),
        _interface_line('output', $chan->{done}) . ")",
        "",
        "  (priority accept_b over arm_b)",
        "",
        "  (rule arm_b arm_b_start",
        "    (set active_q 1)",
        "    (set $chan->{busy} 1)",
        "    (set $chan->{ready} 1))",
        "",
        "  (rule accept_b (& active_q $chan->{valid} $chan->{ready})",
        "    (set $chan->{captured_id}{name} $chan->{id}{name})",
        "    (set $chan->{captured_response}{name} $chan->{response}{name})",
        "    (set active_q 0)",
        "    (set $chan->{busy} 0)",
        "    (set $chan->{ready} 0))",
        "",
        "  (transaction b_receive",
        "    (on $cmd->{arm})",
        "    (drive",
        "      (arm_b_start 1))",
        "    (while active_q",
        "      (wait 1))",
        "    (complete $chan->{done})))",
        "",
    );
}

sub _build_report(%args) {
    my $contract = $args{contract};
    my $chan = $contract->{channel};
    my @fsm_files = @{$args{fsm_files} || []};

    my %source_object = (
        id      => $contract->{source_object_id},
        anchors => _clone_jsonish($contract->{source_anchors}),
    );
    $source_object{intent_name} = $contract->{intent_name}
        if defined($contract->{intent_name}) && length($contract->{intent_name});

    return {
        schema => 'fsmgen.ial2.protocol_intent.axi_b_response_acceptor.v1',
        mode   => 'acceptor',
        layering => {
            source_layer          => 'IAL2',
            generated_ial1_format => 'isf',
            generated_ial0_format => 'fsm',
            direct_ial2_to_ial0   => JSON::PP::false,
        },
        source_object => \%source_object,
        target_protocol => {
            profile => $contract->{protocol},
            object  => 'axi-b-response-acceptor',
            role    => $contract->{role},
        },
        acceptor => {
            name       => $contract->{name},
            actor_name => $contract->{actor_name},
        },
        bindings => {
            clock   => $contract->{clock},
            reset   => _clone_jsonish($contract->{reset}),
            command => _clone_jsonish($contract->{command}),
            channel => _clone_jsonish($contract->{channel}),
        },
        bounded_response => {
            arming_policy            => 'explicit_one_response',
            ready_policy             => 'assert_after_arm_without_waiting_for_valid',
            accept_condition         => "$chan->{valid} && $chan->{ready}",
            id_width                 => 4,
            response_width           => 2,
            capture_policy           => 'on_accept_and_hold_until_next_accept',
            done_policy              => 'one_pulse_per_accepted_arm_after_transaction_retirement',
            back_to_back_supported   => JSON::PP::false,
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
                kind           => 'generated_acceptor_fsm',
                entry_artifact => "$contract->{actor_name}.fsm",
            },
        },
        enforced_static_rules => [
            'profile must be axi4 and the object must be axi-b-response-acceptor',
            'role must be subordinate-to-manager',
            'one explicit arm owns one response acceptance',
            'BREADY is manager-driven and asserts after arm without waiting for BVALID',
            'B ID width and captured ID width are 4',
            'B response width and captured response width are 2',
            'capture occurs only on BVALID && BREADY and is held until the next accepted response',
            'busy and ready clear on acceptance and done is one later pulse',
            'all bindings and reserved internal names are distinct',
            'direct IAL2-to-IAL0 lowering is forbidden',
        ],
        unsupported_residue => _unsupported_residue(),
    };
}

sub _unsupported_residue {
    return [
        {
            id     => 'axi_b_response_acceptor_aw_w_coordination_deferred',
            detail => 'AW/W launch, completion coordination, and a complete write transactor remain future composition work.',
        },
        {
            id     => 'axi_b_response_acceptor_capacity_core_integration_deferred',
            detail => 'Wiring captured BID and the done event into the AXI manager capacity/status response core remains future work.',
        },
        {
            id     => 'axi_b_response_acceptor_outstanding_back_to_back_deferred',
            detail => 'This slice owns one explicitly armed response with no queue, same-cycle re-arm, or back-to-back response throughput.',
        },
        {
            id     => 'axi_b_response_acceptor_id_width_fixed',
            detail => 'BID and captured response ID widths are fixed at 4; configurable write ID width remains deferred.',
        },
        {
            id     => 'axi_b_response_acceptor_response_width_variants_deferred',
            detail => 'BRESP and captured response widths are fixed at 2; absent or three-bit Issue L response variants remain deferred.',
        },
        {
            id     => 'axi_b_response_acceptor_extended_response_signals_deferred',
            detail => 'BCOMP, persistence, atomic/deferrable/MTE response signals, credits, BIDUNQ, BUSER, and other B sidebands remain deferred.',
        },
        {
            id     => 'axi_b_response_acceptor_status_interpretation_deferred',
            detail => 'This primitive captures raw BRESP but does not map response encodings into a higher-level transaction status.',
        },
        {
            id     => 'axi_b_response_acceptor_subordinate_stall_assertions_deferred',
            detail => 'Generated assertions for subordinate BVALID and payload stability remain in the independent Valid-Ready monitor surface.',
        },
        {
            id     => 'axi_b_response_acceptor_burst_coupling_deferred',
            detail => 'Burst address/data sequencing and response ownership coupling remain future transaction-level work.',
        },
        {
            id     => 'axi_b_response_acceptor_ar_r_channels_deferred',
            detail => 'Read-address and read-data/response behavior remain outside this write-response primitive.',
        },
        {
            id     => 'axi_b_response_acceptor_transaction_interface_deferred',
            detail => 'The protocol-neutral transaction interface and role composition from decision 0020 remain future work.',
        },
        {
            id     => 'axi_b_response_acceptor_profile_alias_deferred',
            detail => '.axi profile-alias surfacing remains unsupported; this slice supports only generic .ppif.',
        },
        {
            id     => 'axi_b_response_acceptor_verification_output_deferred',
            detail => 'Direct verification-output generation from this IAL2 source remains future work.',
        },
        {
            id     => 'axi_b_response_acceptor_backend_variants_deferred',
            detail => 'Direct backend lowering, backend-language variants, and VHDL behavior remain future work.',
        },
    ];
}

sub _required_scalar($raw, $field) {
    confess "AXI B response acceptor IAL2 contract is missing required scalar field '$field'\n"
        unless exists($raw->{$field});
    return _nonempty_scalar($raw->{$field}, $field);
}

sub _required_hash($raw, $field) {
    confess "AXI B response acceptor IAL2 contract field '$field' must be a hash reference\n"
        unless ref($raw->{$field}) eq 'HASH';
    return $raw->{$field};
}

sub _required_identifier($raw, $field) {
    return _identifier_value(_required_scalar($raw, $field), $field);
}

sub _required_identifier_field($raw, $field, $label) {
    confess "AXI B response acceptor IAL2 contract is missing required field '$label'\n"
        unless exists($raw->{$field});
    return _identifier_value($raw->{$field}, $label);
}

sub _normalize_width_binding($raw, $field, $expected_width) {
    confess "AXI B response acceptor IAL2 contract field '$field' must be a hash reference\n"
        unless ref($raw) eq 'HASH';
    my $name = _identifier_value($raw->{name}, "$field.name");
    my $width = _positive_integer($raw->{width}, "$field.width");
    confess "AXI B response acceptor IAL2 contract $field.width must be $expected_width in this slice\n"
        unless $width == $expected_width;
    return {
        name  => $name,
        width => $width,
    };
}

sub _normalize_reset($raw_reset) {
    confess "AXI B response acceptor IAL2 contract is missing required reset binding\n"
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
    confess "AXI B response acceptor IAL2 contract source.anchors must be an array reference\n"
        unless ref($anchors) eq 'ARRAY';

    my @normalized;
    for my $index (0 .. $#$anchors) {
        my $anchor = $anchors->[$index];
        if (ref($anchor) eq 'HASH') {
            for my $required (qw(document section page)) {
                confess "AXI B response acceptor IAL2 contract source.anchors[$index] is missing '$required'\n"
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
        confess "AXI B response acceptor IAL2 contract duplicates signal '$name'\n"
            if $seen{$name}++;
    }
}

sub _nonempty_scalar($value, $field) {
    confess "AXI B response acceptor IAL2 contract field '$field' must be a non-empty scalar\n"
        if !defined($value) || ref($value) || $value eq '';
    return $value;
}

sub _identifier_value($value, $field) {
    confess "AXI B response acceptor IAL2 contract field '$field' must be an ISF identifier\n"
        unless defined($value) && !ref($value) && $value =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
    return $value;
}

sub _positive_integer($value, $field) {
    confess "AXI B response acceptor IAL2 contract field '$field' must be a positive integer\n"
        unless defined($value) && !ref($value) && $value =~ /\A[1-9][0-9]*\z/;
    return int($value);
}

sub _bool_value($value, $field) {
    confess "AXI B response acceptor IAL2 contract field '$field' must be boolean 0 or 1\n"
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
