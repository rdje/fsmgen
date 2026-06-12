package FSM::Adapter::IAL2::PPIF;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use Lispish;
use FSM::Adapter::ISF::LispishAdapter;
use FSM::IAL2::ProtocolIntent::ValidReadyChannel;

sub new($class, @constructor_args) {
    _validate_constructor_receiver($class);
    my %args = _validate_constructor_args($class, @constructor_args);
    my $debug = $args{debug} // 0;

    return bless {
        debug   => $debug,
        adapter => FSM::Adapter::ISF::LispishAdapter->new(debug => $debug),
    }, $class;
}

sub parse_file($self, @args) {
    _validate_object_receiver($self, 'parse_file');
    my ($ppif_path) = _validate_scalar_args('parse_file', 1, @args);
    confess "FSM::Adapter::IAL2::PPIF->parse_file argument 1 must name a readable .ppif file\n"
        unless $ppif_path =~ /\.ppif\z/i && -f $ppif_path && -r $ppif_path;

    open my $fh, '<', $ppif_path or confess "Cannot read .ppif file '$ppif_path': $!\n";
    my $source_text = do { local $/; <$fh> };
    close $fh or confess "Cannot close .ppif file '$ppif_path': $!\n";
    return $self->parse_source($source_text, $ppif_path);
}

sub parse_source($self, @args) {
    _validate_object_receiver($self, 'parse_source');
    my ($source_text, $source_label) = _validate_scalar_args('parse_source', 2, @args);

    my $raw = Lispish::multi(\$source_text);
    confess "Error: failed to parse .ppif source '$source_label' with Lispish\n"
        unless defined $raw && ref($raw) eq 'ARRAY';

    my $forms = $self->{adapter}->normalize_multi($raw);
    confess "Error: .ppif source '$source_label' must contain exactly one top-level (protocol-platform-intent ...) form\n"
        unless ref($forms) eq 'ARRAY' && @$forms == 1;

    my $root = $forms->[0];
    confess "Error: .ppif source '$source_label' must start with (protocol-platform-intent ...)\n"
        unless ref($root) eq 'ARRAY' && ($root->[0] // '') eq 'protocol-platform-intent';

    my $contract = _contract_from_root($root, $source_label);
    my $generator = FSM::IAL2::ProtocolIntent::ValidReadyChannel->new(debug => $self->{debug});
    return _generate_bundle($generator, $contract)
        if _is_bundle_contract($contract);
    return $generator->generate($contract);
}

sub _validate_constructor_receiver($class) {
    confess "FSM::Adapter::IAL2::PPIF->new must be called with the FSM::Adapter::IAL2::PPIF class invocant\n"
        unless defined($class) && !ref($class) && $class eq 'FSM::Adapter::IAL2::PPIF';
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
    confess "FSM::Adapter::IAL2::PPIF->$method must be called on an FSM::Adapter::IAL2::PPIF object\n"
        unless blessed($self) && $self->isa('FSM::Adapter::IAL2::PPIF');
}

sub _validate_scalar_args($method, $expected, @args) {
    confess "FSM::Adapter::IAL2::PPIF->$method expects exactly $expected scalar argument(s)\n"
        unless @args == $expected;

    for my $index (0 .. $#args) {
        my $arg = $args[$index];
        confess "FSM::Adapter::IAL2::PPIF->$method argument " . ($index + 1) . " must be a defined scalar\n"
            if !defined($arg) || ref($arg);
    }

    return @args;
}

sub _contract_from_root($root, $source_label) {
    my (undef, $intent_name, @clauses) = @$root;
    _require_scalar($intent_name, "protocol-platform-intent name", $source_label);

    my ($profile, $source);
    my @channels;
    for my $clause (@clauses) {
        my ($head, @body) = _clause_parts($clause, $source_label);
        if ($head eq 'profile') {
            confess "Error: .ppif source '$source_label' has duplicate (profile ...) clauses\n"
                if defined $profile;
            confess "Error: .ppif (profile ...) requires exactly one scalar profile name\n"
                unless @body == 1 && !ref($body[0]);
            $profile = $body[0];
        } elsif ($head eq 'source') {
            confess "Error: .ppif source '$source_label' has duplicate (source ...) clauses\n"
                if defined $source;
            $source = _parse_source_clause(\@body, $source_label);
        } elsif ($head eq 'valid-ready-channel') {
            push @channels, _parse_valid_ready_channel(\@body, $source_label);
        } else {
            confess "Error: .ppif source '$source_label' has unsupported top-level clause '($head ...)'\n";
        }
    }

    confess "Error: .ppif source '$source_label' is missing required (profile ...) clause\n"
        unless defined $profile;
    confess "Error: .ppif source '$source_label' is missing required (source ...) clause\n"
        unless defined $source;
    confess "Error: .ppif source '$source_label' is missing required (valid-ready-channel ...) clause\n"
        unless @channels;

    my %seen_channel_names;
    for my $channel (@channels) {
        confess "Error: .ppif source '$source_label' has duplicate valid-ready-channel object name '$channel->{name}'\n"
            if $seen_channel_names{$channel->{name}}++;
    }

    if (@channels == 1) {
        my %channel = %{$channels[0]};
        my $channel_source = delete($channel{source}) // $source;
        return {
            %channel,
            intent_name => $intent_name,
            protocol    => $profile,
            source      => $channel_source,
        };
    }

    my @bundle_channels;
    for my $channel (@channels) {
        my %channel = %$channel;
        my $channel_source = exists($channel{source}) ? delete($channel{source}) : undef;
        push @bundle_channels, {
            %channel,
            protocol           => $profile,
            source             => $channel_source // $source,
            source_attribution => defined($channel_source) ? 'channel' : 'inherited',
        };
    }

    return {
        kind        => 'valid_ready_bundle',
        intent_name => $intent_name,
        protocol    => $profile,
        source      => $source,
        channels    => \@bundle_channels,
    };
}

sub _clause_parts($clause, $source_label) {
    confess "Error: .ppif source '$source_label' contains a malformed list clause\n"
        unless ref($clause) eq 'ARRAY' && @$clause >= 1 && !ref($clause->[0]);
    return @$clause;
}

sub _parse_source_clause($body, $source_label) {
    my ($object_id, @anchors);

    for my $clause (@$body) {
        my ($head, @items) = _clause_parts($clause, $source_label);
        if ($head eq 'object') {
            confess "Error: .ppif (source ...) has duplicate (object ...) clauses\n"
                if defined $object_id;
            confess "Error: .ppif (source (object ...)) requires exactly one scalar object id\n"
                unless @items == 1 && !ref($items[0]) && length($items[0]);
            $object_id = $items[0];
        } elsif ($head eq 'anchor') {
            push @anchors, _parse_anchor(\@items, $source_label);
        } else {
            confess "Error: .ppif (source ...) has unsupported clause '($head ...)'\n";
        }
    }

    confess "Error: .ppif (source ...) requires one (object ...) clause\n"
        unless defined $object_id;
    confess "Error: .ppif (source ...) requires at least one (anchor ...) clause\n"
        unless @anchors;

    return {
        object_id => $object_id,
        anchors   => \@anchors,
    };
}

sub _parse_anchor($items, $source_label) {
    my %anchor;
    for my $clause (@$items) {
        my ($head, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (anchor ...) has duplicate ($head ...) field\n"
            if exists $anchor{$head};
        confess "Error: .ppif (anchor ...) field '$head' requires exactly one scalar value\n"
            unless @body == 1 && !ref($body[0]);
        $anchor{$head} = $body[0];
    }

    for my $required (qw(document section page)) {
        confess "Error: .ppif (anchor ...) requires ($required ...)\n"
            unless defined($anchor{$required}) && length($anchor{$required});
    }

    return \%anchor;
}

sub _parse_valid_ready_channel($body, $source_label) {
    confess "Error: .ppif (valid-ready-channel ...) requires a scalar object name\n"
        unless @$body >= 1 && !ref($body->[0]) && length($body->[0]);

    my $name = $body->[0];
    my %contract = (name => $name);
    my %seen;
    for my $clause (@{$body}[1 .. $#$body]) {
        my ($head, @items) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (valid-ready-channel $name ...) has duplicate ($head ...) clause\n"
            if $seen{$head}++;

        if ($head =~ /\A(?:channel|role|clock|valid|ready)\z/) {
            confess "Error: .ppif ($head ...) requires exactly one scalar value\n"
                unless @items == 1 && !ref($items[0]);
            $contract{$head} = $items[0];
        } elsif ($head eq 'source') {
            $contract{source} = _parse_source_clause(\@items, $source_label);
        } elsif ($head eq 'reset') {
            $contract{reset} = _parse_reset(\@items, $source_label);
        } elsif ($head eq 'payload') {
            $contract{payload} = _parse_payload(\@items, $source_label);
        } else {
            confess "Error: .ppif (valid-ready-channel $name ...) has unsupported clause '($head ...)'\n";
        }
    }

    for my $required (qw(channel role clock reset valid ready payload)) {
        confess "Error: .ppif (valid-ready-channel $name ...) is missing required ($required ...) clause\n"
            unless exists $contract{$required};
    }

    return \%contract;
}

sub _parse_reset($items, $source_label) {
    confess "Error: .ppif (reset ...) requires exactly one reset tuple\n"
        unless @$items == 1 && ref($items->[0]) eq 'ARRAY';

    my ($signal, @attrs) = @{$items->[0]};
    _require_scalar($signal, 'reset signal', $source_label);
    my %attr;
    for my $value (@attrs) {
        confess "Error: .ppif reset attribute '$value' must be active_low, active_high, async, or sync\n"
            unless !ref($value) && $value =~ /\A(?:active_low|active_high|async|sync)\z/;
        confess "Error: .ppif reset tuple has duplicate '$value' attribute\n"
            if $attr{$value}++;
    }
    confess "Error: .ppif reset tuple must include exactly one of active_low or active_high\n"
        if ($attr{active_low} ? 1 : 0) + ($attr{active_high} ? 1 : 0) != 1;
    confess "Error: .ppif reset tuple must include exactly one of async or sync\n"
        if ($attr{async} ? 1 : 0) + ($attr{sync} ? 1 : 0) != 1;

    return {
        signal     => $signal,
        active_low => $attr{active_low} ? 1 : 0,
        async      => $attr{async} ? 1 : 0,
    };
}

sub _parse_payload($items, $source_label) {
    confess "Error: .ppif (payload ...) requires at least one payload entry\n"
        unless @$items;

    my @payload;
    for my $entry (@$items) {
        confess "Error: .ppif payload entries must be lists such as (awaddr width 32)\n"
            unless ref($entry) eq 'ARRAY' && @$entry >= 1 && !ref($entry->[0]);
        my ($name, @attrs) = @$entry;
        my %field = (name => $name);
        if (@attrs) {
            confess "Error: .ppif payload entry '$name' supports only '(width N)'\n"
                unless @attrs == 2 && $attrs[0] eq 'width' && !ref($attrs[1]);
            $field{width} = $attrs[1];
        }
        push @payload, \%field;
    }

    return \@payload;
}

sub _require_scalar($value, $label, $source_label) {
    confess "Error: .ppif source '$source_label' requires scalar $label\n"
        unless defined($value) && !ref($value) && length($value);
}

sub _is_bundle_contract($contract) {
    return ref($contract) eq 'HASH'
        && ($contract->{kind} // '') eq 'valid_ready_bundle';
}

sub _generate_bundle($generator, $bundle) {
    my @channels = @{$bundle->{channels} || []};
    confess "Error: .ppif Valid-Ready bundle requires at least two channels\n"
        unless @channels >= 2;

    my (@ial1_items, @ial0_items, @schedule_reports, @channel_reports);
    my %all_fsm_files;

    for my $channel (@channels) {
        my %contract = %$channel;
        $contract{intent_name} = $bundle->{intent_name};
        my $result = $generator->generate(\%contract);
        my $report = $result->{report};
        my $object_name = $channel->{name};
        my $family = $report->{target_channel}{family};

        push @ial1_items, {
            object_name => $object_name,
            channel     => $family,
            format      => $result->{generated_ial1}{format},
            name        => $result->{generated_ial1}{name},
            text        => $result->{generated_ial1}{text},
        };

        my @fsm_names = sort keys %{$result->{generated_ial0}{files} || {}};
        for my $fsm_name (@fsm_names) {
            confess "Error: .ppif Valid-Ready bundle generated duplicate .fsm artifact '$fsm_name'\n"
                if exists $all_fsm_files{$fsm_name};
            $all_fsm_files{$fsm_name} = $result->{generated_ial0}{files}{$fsm_name};
        }

        my $entry_artifact = $report->{generated_artifacts}{ial0}{files}[0];
        push @ial0_items, {
            object_name    => $object_name,
            channel        => $family,
            format         => 'fsm',
            files          => \@fsm_names,
            entry_artifact => $entry_artifact,
        };

        push @schedule_reports, {
            object_name => $object_name,
            channel     => $family,
            report      => _clone_jsonish($result->{generated_ial1_schedule_report}),
        };

        push @channel_reports, {
            object_name             => $object_name,
            source_attribution      => $channel->{source_attribution},
            valid_ready_channel_report => _clone_jsonish($report),
        };
    }

    my $report = _build_bundle_report(
        bundle          => $bundle,
        ial1_items      => \@ial1_items,
        ial0_items      => \@ial0_items,
        channel_reports => \@channel_reports,
    );

    return {
        layer => 'IAL2',
        kind  => 'protocol_intent.valid_ready_bundle',
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

sub _build_bundle_report(%args) {
    my $bundle = $args{bundle};
    my @ial1_items = @{$args{ial1_items} || []};
    my @ial0_items = @{$args{ial0_items} || []};
    my @channel_reports = @{$args{channel_reports} || []};

    my @channels;
    my $inherited_source_count = 0;
    for my $entry (@channel_reports) {
        my $channel_report = $entry->{valid_ready_channel_report};
        my $source_scope = $entry->{source_attribution} eq 'channel' ? 'channel' : 'inherited';
        ++$inherited_source_count if $source_scope eq 'inherited';

        push @channels, {
            object_name => $entry->{object_name},
            source_object => _clone_jsonish($channel_report->{source_object}),
            source_attribution => {
                scope => $source_scope,
                ($source_scope eq 'inherited'
                    ? (inherited_from => $bundle->{source}{object_id})
                    : ()),
            },
            target_channel => _clone_jsonish($channel_report->{target_channel}),
            bindings => _clone_jsonish($channel_report->{bindings}),
            generated_artifacts => _clone_jsonish($channel_report->{generated_artifacts}),
            transfer_fire_condition => $channel_report->{transfer_fire_condition},
            generated_runtime_assertions => _clone_jsonish($channel_report->{generated_runtime_assertions}),
            unsupported_residue => _clone_jsonish($channel_report->{unsupported_residue}),
        };
    }

    my %source_object = (
        id      => $bundle->{source}{object_id},
        anchors => _clone_jsonish($bundle->{source}{anchors}),
    );
    $source_object{intent_name} = $bundle->{intent_name}
        if defined($bundle->{intent_name}) && length($bundle->{intent_name});

    return {
        schema => 'fsmgen.ial2.protocol_intent.valid_ready_bundle.v1',
        mode   => 'monitor-only-bundle',
        layering => {
            source_layer          => 'IAL2',
            generated_ial1_format => 'isf',
            generated_ial0_format => 'fsm',
            direct_ial2_to_ial0   => 0,
        },
        source_object => \%source_object,
        bundle => {
            protocol               => $bundle->{protocol},
            channel_count          => scalar(@channels),
            channel_object_names   => [map { $_->{object_name} } @channels],
            inherited_source_count => $inherited_source_count,
        },
        channels => \@channels,
        generated_artifacts => {
            ial1 => {
                format => 'isf',
                items  => [
                    map {
                        {
                            object_name => $_->{object_name},
                            channel     => $_->{channel},
                            name        => $_->{name},
                            format      => $_->{format},
                        }
                    } @ial1_items
                ],
            },
            ial0 => {
                format => 'fsm',
                items  => _clone_jsonish(\@ial0_items),
            },
            hdl_entry => {
                selected => 0,
                reason   => 'multi-channel PPIF bundle has no wrapper/top actor or explicit HDL entry selection in this slice',
            },
        },
        unsupported_residue => [
            {
                id     => 'bundle_hdl_entry',
                detail => 'Default HDL generation remains fail-closed until a wrapper/top actor or explicit entry-selection owner lands.',
            },
            {
                id     => 'axi_manager_concurrency',
                detail => 'Transaction IDs, outstanding windows, bursts, response matching, and channel dependency rules remain outside this monitor-only bundle slice.',
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
