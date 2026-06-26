package FSM::IAL2::ProtocolIntent::ValidReadyChannel;

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
    confess "FSM::IAL2::ProtocolIntent::ValidReadyChannel->generate expects exactly one contract hash reference\n"
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
        kind  => 'protocol_intent.valid_ready_channel',
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
    confess "FSM::IAL2::ProtocolIntent::ValidReadyChannel->new must be called with the FSM::IAL2::ProtocolIntent::ValidReadyChannel class invocant\n"
        unless defined($class) && !ref($class) && $class eq 'FSM::IAL2::ProtocolIntent::ValidReadyChannel';
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
    confess "FSM::IAL2::ProtocolIntent::ValidReadyChannel->$method must be called on an FSM::IAL2::ProtocolIntent::ValidReadyChannel object\n"
        unless blessed($self) && $self->isa('FSM::IAL2::ProtocolIntent::ValidReadyChannel');
}

sub _normalize_contract($raw) {
    my $name = _required_identifier($raw, 'name');
    my $actor_name = exists($raw->{actor_name})
        ? _identifier_value($raw->{actor_name}, 'actor_name')
        : "${name}_valid_ready_monitor";

    my ($protocol, $channel, $role, $profile_kind) = _normalize_profile_channel_role($raw);

    my $clock = _required_identifier($raw, 'clock');
    my $reset = _normalize_reset($raw->{reset});
    my $valid = _required_identifier($raw, 'valid');
    my $ready = _required_identifier($raw, 'ready');
    my $payload = _normalize_payload($raw->{payload});

    _reject_duplicate_interface_names($valid, $ready, $payload, "${actor_name}_done");

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
        name             => $name,
        actor_name       => $actor_name,
        done             => "${actor_name}_done",
        protocol         => $protocol,
        profile_kind     => $profile_kind,
        channel          => $channel,
        role             => $role,
        clock            => $clock,
        reset            => $reset,
        valid            => $valid,
        ready            => $ready,
        payload          => $payload,
        intent_name      => $intent_name,
        source_object_id => $source_object_id,
        source_anchors   => $anchors,
    };
}

sub _normalize_profile_channel_role($raw) {
    my $protocol = lc _required_scalar($raw, 'protocol');

    if (_is_axi_profile($protocol)) {
        my $channel = uc _required_scalar($raw, 'channel');
        my %axi_channels = map { $_ => 1 } qw(AW W B AR R);
        confess "AXI Valid-Ready IAL2 contract channel must be one of AW, W, B, AR, or R\n"
            unless $axi_channels{$channel};

        my $role = lc _required_scalar($raw, 'role');
        my %roles = map { $_ => 1 } qw(manager-to-subordinate subordinate-to-manager);
        confess "AXI Valid-Ready IAL2 contract role must be manager-to-subordinate or subordinate-to-manager\n"
            unless $roles{$role};

        return ($protocol, $channel, $role, 'axi');
    }

    if ($protocol eq 'valid-ready') {
        my $channel = _identifier_value(_required_scalar($raw, 'channel'), 'channel');
        my $role = lc _required_scalar($raw, 'role');
        my %roles = map { $_ => 1 } qw(producer-to-consumer consumer-to-producer);
        confess "Valid-Ready IAL2 contract valid-ready profile role must be producer-to-consumer or consumer-to-producer\n"
            unless $roles{$role};

        return ($protocol, $channel, $role, 'valid-ready');
    }

    confess "Valid-Ready IAL2 contract profile must be valid-ready, axi, axi3, axi4, or axi5\n";
}

sub _is_axi_profile($protocol) {
    return defined($protocol) && $protocol =~ /\Aaxi(?:3|4|5)?\z/;
}

sub _required_scalar($raw, $field) {
    confess "Valid-Ready IAL2 contract is missing required scalar field '$field'\n"
        unless exists($raw->{$field});
    return _nonempty_scalar($raw->{$field}, $field);
}

sub _required_identifier($raw, $field) {
    return _identifier_value(_required_scalar($raw, $field), $field);
}

sub _nonempty_scalar($value, $field) {
    confess "Valid-Ready IAL2 contract field '$field' must be a non-empty scalar\n"
        if !defined($value) || ref($value) || $value eq '';
    return $value;
}

sub _identifier_value($value, $field) {
    confess "Valid-Ready IAL2 contract field '$field' must be an ISF identifier\n"
        unless defined($value) && !ref($value) && $value =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
    return $value;
}

sub _normalize_reset($raw_reset) {
    confess "Valid-Ready IAL2 contract is missing required reset binding\n"
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

sub _bool_value($value, $field) {
    confess "Valid-Ready IAL2 contract field '$field' must be boolean 0 or 1\n"
        if ref($value) || !defined($value) || ($value ne '0' && $value ne '1');
    return $value ? 1 : 0;
}

sub _normalize_payload($payload) {
    confess "Valid-Ready IAL2 contract field 'payload' must be a non-empty array reference\n"
        unless ref($payload) eq 'ARRAY' && @$payload;

    my @normalized;
    for my $index (0 .. $#$payload) {
        my $item = $payload->[$index];
        my ($name, $width);
        if (ref($item) eq 'HASH') {
            $name = _identifier_value($item->{name}, "payload[$index].name");
            $width = exists($item->{width}) ? _positive_integer($item->{width}, "payload[$index].width") : 1;
        } else {
            $name = _identifier_value($item, "payload[$index]");
            $width = 1;
        }
        push @normalized, {
            name  => $name,
            width => $width,
        };
    }

    return \@normalized;
}

sub _positive_integer($value, $field) {
    confess "Valid-Ready IAL2 contract field '$field' must be a positive integer\n"
        if ref($value) || !defined($value) || $value !~ /\A[1-9][0-9]*\z/;
    return int($value);
}

sub _reject_duplicate_interface_names($valid, $ready, $payload, $done) {
    my %seen;
    for my $name ($valid, $ready, map({ $_->{name} } @$payload), $done) {
        confess "Valid-Ready IAL2 contract duplicates interface signal '$name'\n"
            if $seen{$name}++;
    }
}

sub _normalize_source_anchors($anchors) {
    confess "Valid-Ready IAL2 contract source.anchors must be an array reference\n"
        unless ref($anchors) eq 'ARRAY';

    my @normalized;
    for my $index (0 .. $#$anchors) {
        my $anchor = $anchors->[$index];
        if (ref($anchor) eq 'HASH') {
            my %copy;
            for my $key (sort keys %$anchor) {
                my $value = $anchor->{$key};
                confess "Valid-Ready IAL2 contract source.anchors[$index].$key must be a scalar\n"
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
    my @interface = (
        "    (input $contract->{valid})",
        "    (input $contract->{ready})",
        map(
            {
                $_->{width} == 1
                    ? "    (input $_->{name})"
                    : "    (input $_->{name} (width $_->{width}))"
            }
            @{$contract->{payload}}
        ),
        "    (output $contract->{done})",
    );

    my @checks = _assertion_isf_lines($contract);
    my $reset = _reset_clause($contract->{reset});

    return join("\n",
        "(actor $contract->{actor_name}",
        "  (clock $contract->{clock})",
        "  $reset",
        "  (interface",
        @interface,
        "  )",
        "  (transaction monitor",
        "    (on $contract->{valid})",
        @checks,
        "    (complete $contract->{done})))",
        "",
    );
}

sub _reset_clause($reset) {
    my @parts = ($reset->{signal});
    push @parts, $reset->{async} ? 'async' : 'sync';
    push @parts, $reset->{active_low} ? 'active_low' : 'active_high';
    return "(reset (" . join(' ', @parts) . "))";
}

sub _assertion_isf_lines($contract) {
    my $valid = $contract->{valid};
    my $ready = $contract->{ready};
    my $stall = "(& (past $valid) (! (past $ready)))";

    my @lines = (
        '    (assert (=> ' . $stall . " $valid) "
            . _quote_isf_string("$valid must remain asserted while $ready is low") . ')',
    );

    for my $payload (@{$contract->{payload}}) {
        my $name = $payload->{name};
        push @lines,
            '    (assert (=> ' . $stall . " (== $name (past $name))) "
            . _quote_isf_string("$name must remain stable while $valid is stalled by $ready") . ')';
    }

    push @lines, "    (cover (& $valid $ready))";
    return @lines;
}

sub _quote_isf_string($value) {
    $value =~ s/\\/\\\\/g;
    $value =~ s/"/\\"/g;
    return qq{"$value"};
}

sub _build_report(%args) {
    my $contract = $args{contract};
    my @fsm_files = @{$args{fsm_files} || []};
    my $valid = $contract->{valid};
    my $ready = $contract->{ready};

    my @assertions = (
        {
            id                 => 'valid_hold_while_stalled',
            kind               => 'assert',
            transaction        => 'monitor',
            generated_name     => 'monitor_assert_0',
            property           => "(=> (& (past $valid) (! (past $ready))) $valid)",
            obligation         => 'If the previous cycle presented VALID without READY, VALID must remain asserted in the current cycle.',
            source_object_id   => $contract->{source_object_id},
        },
    );

    my $ordinal = 1;
    for my $payload (@{$contract->{payload}}) {
        my $name = $payload->{name};
        push @assertions, {
            id               => "payload_${name}_stable_while_stalled",
            kind             => 'assert',
            transaction      => 'monitor',
            generated_name   => "monitor_assert_$ordinal",
            property         => "(=> (& (past $valid) (! (past $ready))) (== $name (past $name)))",
            obligation       => "If the previous cycle presented VALID without READY, $name must equal its previous sampled value.",
            source_object_id => $contract->{source_object_id},
        };
        ++$ordinal;
    }

    my %source_object = (
        id      => $contract->{source_object_id},
        anchors => _clone_jsonish($contract->{source_anchors}),
    );
    $source_object{intent_name} = $contract->{intent_name}
        if defined($contract->{intent_name}) && length($contract->{intent_name});

    my @profile_static_rules = $contract->{profile_kind} eq 'axi'
        ? (
            'AXI profile protocol must be axi, axi3, axi4, or axi5',
            'AXI profile channel must be one of AW, W, B, AR, or R',
            'AXI profile role must be manager-to-subordinate or subordinate-to-manager',
        )
        : (
            'valid-ready profile protocol must be valid-ready',
            'valid-ready profile channel must be an ISF identifier',
            'valid-ready profile role must be producer-to-consumer or consumer-to-producer',
        );

    my @unsupported_residue = (
        {
            id     => 'reset_low_valid_during_reset',
            detail => 'The first slice reports reset-valid obligations as residue because the current assertion emitter disables generated assertions during reset.',
        },
        {
            id     => 'ready_independence',
            detail => 'The first slice does not prove that VALID generation is independent from READY; that requires source behavior or a manager model.',
        },
    );
    if ($contract->{profile_kind} eq 'axi') {
        push @unsupported_residue, {
            id     => 'axi_manager_concurrency',
            detail => 'Transaction IDs, outstanding windows, bursts, response matching, and channel dependency rules remain outside this monitor-only slice.',
        };
    } else {
        push @unsupported_residue, {
            id     => 'valid_ready_profile_behavior_outside_monitor',
            detail => 'The generic valid-ready profile is monitor-only; producer/consumer generation policy, backpressure policy, and protocol-specific ordering remain outside this sample.',
        };
    }

    return {
        schema => 'fsmgen.ial2.protocol_intent.valid_ready_channel.v1',
        mode   => 'monitor-only',
        layering => {
            source_layer          => 'IAL2',
            generated_ial1_format => 'isf',
            generated_ial0_format => 'fsm',
            direct_ial2_to_ial0   => 0,
        },
        source_object => \%source_object,
        generated_artifacts => {
            ial1 => {
                name   => $args{isf_name},
                format => 'isf',
            },
            ial0 => {
                format => 'fsm',
                files  => \@fsm_files,
            },
        },
        target_channel => {
            protocol => $contract->{protocol},
            family   => $contract->{channel},
            role     => $contract->{role},
        },
        bindings => {
            clock   => $contract->{clock},
            reset   => _clone_jsonish($contract->{reset}),
            valid   => $valid,
            ready   => $ready,
            payload => _clone_jsonish($contract->{payload}),
        },
        transfer_fire_condition => "$valid && $ready",
        generated_scheduler_or_monitor_rules => [
            {
                id          => 'monitor_transaction_trigger',
                transaction => 'monitor',
                trigger     => $valid,
                reason      => 'IAL1 transactions need an entry trigger; generated assertions remain module-level checks after lowering.',
            },
            {
                id         => 'transfer_fire_cover',
                kind       => 'cover',
                expression => "(& $valid $ready)",
                name       => 'monitor_cover_0',
            },
        ],
        generated_runtime_assertions => \@assertions,
        assumptions => [
            {
                id     => 'single_clock_sampling',
                detail => "All generated checks sample on clock '$contract->{clock}' through the existing IAL1 assertion path.",
            },
            {
                id     => 'environment_drives_valid_ready_payload',
                detail => 'The generated actor is monitor-only; the environment drives VALID, READY, and payload signals.',
            },
        ],
        enforced_static_rules => [
            'contract object must be a hash reference',
            'name, protocol, channel, role, clock, reset, valid, ready, and payload are required',
            @profile_static_rules,
            'ISF-entering signal names must be identifiers',
            'payload must be non-empty and payload widths must be positive integers',
            'valid, ready, payload, and generated done endpoint names must be unique',
        ],
        unsupported_residue => \@unsupported_residue,
    };
}

sub _clone_jsonish($value) {
    return undef unless defined $value;
    return [map { _clone_jsonish($_) } @$value] if ref($value) eq 'ARRAY';
    return { map { $_ => _clone_jsonish($value->{$_}) } sort keys %$value } if ref($value) eq 'HASH';
    return $value;
}

1;
