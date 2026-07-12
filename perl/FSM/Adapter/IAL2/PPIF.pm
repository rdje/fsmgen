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
use FSM::IAL2::ProtocolIntent::AhbInterconnect;
use FSM::IAL2::ProtocolIntent::AhbRequester;
use FSM::IAL2::ProtocolIntent::AhbSubordinate;
use FSM::IAL2::ProtocolIntent::ApbComposition;
use FSM::IAL2::ProtocolIntent::ApbCompleter;
use FSM::IAL2::ProtocolIntent::ApbRequesterTransfer;
use FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus;
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
    my ($source_path) = _validate_scalar_args('parse_file', 1, @args);
    confess "FSM::Adapter::IAL2::PPIF->parse_file argument 1 must name a readable .ppif file or supported IAL2 profile-alias file\n"
        unless $source_path =~ /\.(?:ppif|axi|apb|ahb)\z/i && -f $source_path && -r $source_path;

    open my $fh, '<', $source_path or confess "Cannot read IAL2 PPIF/profile-alias file '$source_path': $!\n";
    my $source_text = do { local $/; <$fh> };
    close $fh or confess "Cannot close IAL2 PPIF/profile-alias file '$source_path': $!\n";
    return $self->parse_source($source_text, $source_path);
}

sub parse_source($self, @args) {
    _validate_object_receiver($self, 'parse_source');
    my ($source_text, $source_label) = _validate_scalar_args('parse_source', 2, @args);

    my $surface = _source_surface_name($source_label);
    my $raw = Lispish::multi(\$source_text);
    confess "Error: failed to parse $surface source '$source_label' with Lispish\n"
        unless defined $raw && ref($raw) eq 'ARRAY';

    my $forms = $self->{adapter}->normalize_multi($raw);
    confess "Error: $surface source '$source_label' must contain exactly one top-level (protocol-platform-intent ...) form\n"
        unless ref($forms) eq 'ARRAY' && @$forms == 1;

    my $root = $forms->[0];
    confess "Error: $surface source '$source_label' must start with (protocol-platform-intent ...)\n"
        unless ref($root) eq 'ARRAY' && ($root->[0] // '') eq 'protocol-platform-intent';

    my $contract = _contract_from_root($root, $source_label);
    _validate_profile_alias_contract($source_label, $contract);
    my $generator = FSM::IAL2::ProtocolIntent::ValidReadyChannel->new(debug => $self->{debug});
    return _generate_bundle($generator, $contract)
        if _is_bundle_contract($contract);
    return FSM::IAL2::ProtocolIntent::ApbComposition->new(debug => $self->{debug})->generate($contract)
        if _is_apb_composition_contract($contract);
    return FSM::IAL2::ProtocolIntent::ApbCompleter->new(debug => $self->{debug})->generate($contract)
        if _is_apb_completer_contract($contract);
    return FSM::IAL2::ProtocolIntent::ApbRequesterTransfer->new(debug => $self->{debug})->generate($contract)
        if _is_apb_requester_transfer_contract($contract);
    if (_is_ahb_interconnect_contract($contract)) {
        my $result = FSM::IAL2::ProtocolIntent::AhbInterconnect->new(debug => $self->{debug})->generate($contract);
        if (_is_ahb_profile_alias_source($source_label)) {
            _remove_unsupported_residue_id($result, 'ahb_aggregate_profile_alias_deferred');
            _remove_unsupported_residue_id($result, 'ahb_profile_alias_deferred');
            _remove_unsupported_residue_id($result, 'ahb_subordinate_profile_alias_deferred');
            _remove_ahb_seq_alias_exposure_from_residue($result);
        }
        return $result;
    }
    if (_is_ahb_requester_contract($contract)) {
        my $result = FSM::IAL2::ProtocolIntent::AhbRequester->new(debug => $self->{debug})->generate($contract);
        _remove_unsupported_residue_id($result, 'ahb_profile_alias_deferred')
            if _is_ahb_profile_alias_source($source_label);
        return $result;
    }
    if (_is_ahb_subordinate_contract($contract)) {
        my $result = FSM::IAL2::ProtocolIntent::AhbSubordinate->new(debug => $self->{debug})->generate($contract);
        if (_is_ahb_profile_alias_source($source_label)) {
            _remove_unsupported_residue_id($result, 'ahb_subordinate_profile_alias_deferred');
            _remove_ahb_seq_alias_exposure_from_residue($result);
        }
        return $result;
    }
    return FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new(debug => $self->{debug})->generate($contract)
        if _is_manager_capacity_status_contract($contract);
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

sub _source_surface_name($source_label) {
    return '.ahb' if defined($source_label) && $source_label =~ /\.ahb\z/i;
    return '.apb' if defined($source_label) && $source_label =~ /\.apb\z/i;
    return '.axi' if defined($source_label) && $source_label =~ /\.axi\z/i;
    return '.ppif';
}

sub _is_ahb_profile_alias_source($source_label) {
    return defined($source_label) && $source_label =~ /\.ahb\z/i;
}

sub _is_axi_profile_alias_source($source_label) {
    return defined($source_label) && $source_label =~ /\.axi\z/i;
}

sub _is_apb_profile_alias_source($source_label) {
    return defined($source_label) && $source_label =~ /\.apb\z/i;
}

sub _is_axi_family_profile($profile) {
    return defined($profile) && !ref($profile) && $profile =~ /\Aaxi(?:3|4|5)?\z/;
}

sub _remove_unsupported_residue_id($result, $residue_id) {
    return unless ref($result) eq 'HASH' && ref($result->{report}) eq 'HASH';
    _remove_unsupported_residue_id_from_node($result->{report}, $residue_id);
}

sub _remove_ahb_seq_alias_exposure_from_residue($result) {
    return unless ref($result) eq 'HASH' && ref($result->{report}) eq 'HASH';
    _rewrite_unsupported_residue_detail(
        $result->{report},
        'ahb_burst_seq_support_deferred',
        sub {
            my ($detail) = @_;
            $detail =~ s/, \.ahb alias exposure//;
            return $detail;
        },
    );
}

sub _rewrite_unsupported_residue_detail($node, $residue_id, $rewrite) {
    return unless ref($node);

    if (ref($node) eq 'HASH') {
        if (ref($node->{unsupported_residue}) eq 'ARRAY') {
            for my $entry (@{$node->{unsupported_residue}}) {
                next unless ref($entry) eq 'HASH';
                next unless defined($entry->{id}) && $entry->{id} eq $residue_id;
                next unless defined($entry->{detail}) && !ref($entry->{detail});
                $entry->{detail} = $rewrite->($entry->{detail});
            }
        }
        _rewrite_unsupported_residue_detail($_, $residue_id, $rewrite)
            for values %$node;
        return;
    }

    if (ref($node) eq 'ARRAY') {
        _rewrite_unsupported_residue_detail($_, $residue_id, $rewrite)
            for @$node;
    }
}

sub _remove_unsupported_residue_id_from_node($node, $residue_id) {
    return unless ref($node);

    if (ref($node) eq 'HASH') {
        if (ref($node->{unsupported_residue}) eq 'ARRAY') {
            my @kept = grep {
                !(ref($_) eq 'HASH' && defined($_->{id}) && $_->{id} eq $residue_id)
            } @{$node->{unsupported_residue}};
            $node->{unsupported_residue} = \@kept;
        }
        _remove_unsupported_residue_id_from_node($_, $residue_id)
            for values %$node;
        return;
    }

    if (ref($node) eq 'ARRAY') {
        _remove_unsupported_residue_id_from_node($_, $residue_id)
            for @$node;
    }
}

sub _validate_profile_alias_contract($source_label, $contract) {
    if (_is_ahb_profile_alias_source($source_label)) {
        my $profile = $contract->{protocol};
        confess "Error: .ahb source '$source_label' profile '$profile' does not match .ahb profile alias; expected ahb\n"
            unless defined($profile) && !ref($profile) && $profile eq 'ahb';

        confess "Error: .ahb source '$source_label' profile ahb requires exactly one (ahb-requester ...) object, exactly one (ahb-subordinate ...) object, the selected aggregate one-requester/one-subordinate (ahb-interconnect ...) shape, or the selected aggregate one-requester/two-subordinate (ahb-interconnect ...) shape in this slice\n"
            unless _is_ahb_requester_contract($contract)
                || _is_ahb_subordinate_contract($contract)
                || _is_selected_ahb_profile_alias_interconnect_contract($contract);
        return;
    }

    if (_is_apb_profile_alias_source($source_label)) {
        my $profile = $contract->{protocol};
        confess "Error: .apb source '$source_label' profile '$profile' does not match .apb profile alias; expected apb\n"
            unless defined($profile) && !ref($profile) && $profile eq 'apb';

        confess "Error: .apb source '$source_label' profile apb requires exactly one (apb-requester ...), one (apb-completer ...), the explicit one-requester/one-completer/one-composition shape, or the selected one-requester/multi-peripheral APB composition shape in this slice\n"
            unless _is_apb_requester_transfer_contract($contract)
                || _is_apb_completer_contract($contract)
                || _is_apb_composition_contract($contract);
        return;
    }

    return unless _is_axi_profile_alias_source($source_label);

    my $profile = $contract->{protocol};
    confess "Error: .axi source '$source_label' profile '$profile' does not match .axi profile alias; expected axi, axi3, axi4, or axi5\n"
        unless _is_axi_family_profile($profile);

    confess "Error: .axi source '$source_label' supports only one AXI-family valid-ready-channel object in this slice; requested AXI bundle or manager behavior remains unsupported for the first profile-alias implementation\n"
        if _is_bundle_contract($contract) || _is_manager_capacity_status_contract($contract);
}

sub _contract_from_root($root, $source_label) {
    my $surface = _source_surface_name($source_label);
    my (undef, $intent_name, @clauses) = @$root;
    _require_scalar($intent_name, "protocol-platform-intent name", $source_label);

    my ($profile, $source);
    my @channels;
    my @managers;
    my @apb_requesters;
    my @apb_completers;
    my @apb_compositions;
    my @ahb_requesters;
    my @ahb_subordinates;
    my @ahb_interconnects;
    for my $clause (@clauses) {
        my ($head, @body) = _clause_parts($clause, $source_label);
        if ($head eq 'profile') {
            confess "Error: $surface source '$source_label' has duplicate (profile ...) clauses\n"
                if defined $profile;
            confess "Error: .ppif (profile ...) requires exactly one scalar profile name\n"
                unless @body == 1 && !ref($body[0]);
            $profile = $body[0];
        } elsif ($head eq 'source') {
            confess "Error: $surface source '$source_label' has duplicate (source ...) clauses\n"
                if defined $source;
            $source = _parse_source_clause(\@body, $source_label);
        } elsif ($head eq 'valid-ready-channel') {
            push @channels, _parse_valid_ready_channel(\@body, $source_label);
        } elsif ($head eq 'manager-capacity-status') {
            push @managers, _parse_manager_capacity_status(\@body, $source_label);
        } elsif ($head eq 'apb-requester') {
            push @apb_requesters, _parse_apb_requester(\@body, $source_label);
        } elsif ($head eq 'apb-completer') {
            push @apb_completers, _parse_apb_completer(\@body, $source_label);
        } elsif ($head eq 'apb-composition') {
            push @apb_compositions, _parse_apb_composition(\@body, $source_label);
        } elsif ($head eq 'ahb-requester') {
            push @ahb_requesters, _parse_ahb_requester(\@body, $source_label);
        } elsif ($head eq 'ahb-subordinate') {
            push @ahb_subordinates, _parse_ahb_subordinate(\@body, $source_label);
        } elsif ($head eq 'ahb-interconnect') {
            push @ahb_interconnects, _parse_ahb_interconnect(\@body, $source_label);
        } else {
            confess "Error: $surface source '$source_label' has unsupported top-level clause '($head ...)'\n";
        }
    }

    confess "Error: $surface source '$source_label' is missing required (profile ...) clause\n"
        unless defined $profile;
    confess "Error: $surface source '$source_label' is missing required (source ...) clause\n"
        unless defined $source;
    confess "Error: $surface source '$source_label' is missing required intent object clause, expected (valid-ready-channel ...), (manager-capacity-status ...), (apb-requester ...), (apb-completer ...), (apb-composition ...), (ahb-requester ...), (ahb-subordinate ...), or (ahb-interconnect ...)\n"
        unless @channels || @managers || @apb_requesters || @apb_completers || @apb_compositions || @ahb_requesters || @ahb_subordinates || @ahb_interconnects;
    if (@ahb_interconnects) {
        confess "Error: $surface source '$source_label' profile '$profile' does not match (ahb-interconnect ...); expected ahb\n"
            unless $profile eq 'ahb';
        my $cardinality_message =
            "Error: $surface source '$source_label' AHB interconnect requires exactly one (ahb-requester ...), one or two (ahb-subordinate ...) objects, and one (ahb-interconnect ...) object in this slice\n";
        confess $cardinality_message
            unless @ahb_requesters == 1
                && (@ahb_subordinates == 1 || @ahb_subordinates == 2)
                && @ahb_interconnects == 1
                && !@channels
                && !@managers
                && !@apb_requesters
                && !@apb_completers
                && !@apb_compositions;

        return {
            kind         => 'ahb_interconnect',
            intent_name  => $intent_name,
            protocol     => $profile,
            source       => $source,
            requester    => $ahb_requesters[0],
            subordinate  => $ahb_subordinates[0],
            subordinates => [@ahb_subordinates],
            interconnect => $ahb_interconnects[0],
        };
    }
    if (@ahb_requesters) {
        confess "Error: $surface source '$source_label' profile '$profile' does not match (ahb-requester ...); expected ahb\n"
            unless $profile eq 'ahb';
        confess "Error: $surface source '$source_label' cannot mix (ahb-requester ...) with (ahb-subordinate ...), (ahb-interconnect ...), (valid-ready-channel ...), (manager-capacity-status ...), (apb-requester ...), (apb-completer ...), or (apb-composition ...) objects outside the selected AHB interconnect shape in this slice\n"
            if @ahb_subordinates || @ahb_interconnects || @channels || @managers || @apb_requesters || @apb_completers || @apb_compositions;
        confess "Error: $surface source '$source_label' supports exactly one (ahb-requester ...) object in this slice\n"
            if @ahb_requesters > 1;

        return {
            %{$ahb_requesters[0]},
            intent_name => $intent_name,
            protocol    => $profile,
            source      => $source,
        };
    }
    if (@ahb_subordinates) {
        confess "Error: $surface source '$source_label' profile '$profile' does not match (ahb-subordinate ...); expected ahb\n"
            unless $profile eq 'ahb';
        confess "Error: $surface source '$source_label' cannot mix (ahb-subordinate ...) with (ahb-requester ...), (ahb-interconnect ...), (valid-ready-channel ...), (manager-capacity-status ...), (apb-requester ...), (apb-completer ...), or (apb-composition ...) objects outside the selected AHB interconnect shape in this slice\n"
            if @ahb_requesters || @ahb_interconnects || @channels || @managers || @apb_requesters || @apb_completers || @apb_compositions;
        confess "Error: $surface source '$source_label' supports exactly one (ahb-subordinate ...) object in this slice\n"
            if @ahb_subordinates > 1;

        return {
            %{$ahb_subordinates[0]},
            intent_name => $intent_name,
            protocol    => $profile,
            source      => $source,
        };
    }
    if (@apb_compositions) {
        confess "Error: $surface source '$source_label' profile '$profile' does not match (apb-composition ...); expected apb\n"
            unless $profile eq 'apb';
        confess "Error: $surface source '$source_label' APB composition requires exactly one (apb-requester ...) and one (apb-composition ...) object in this slice\n"
            unless @apb_requesters == 1 && @apb_compositions == 1 && !@channels && !@managers;

        my $composition = $apb_compositions[0];
        my $children = ref($composition->{children}) eq 'HASH' ? $composition->{children} : {};
        my $has_peripherals = ref($children->{peripherals}) eq 'ARRAY' && @{$children->{peripherals}};
        if ($has_peripherals) {
            confess "Error: $surface source '$source_label' APB multi-peripheral composition requires two or more (apb-completer ...) objects\n"
                unless @apb_completers >= 2;
            confess "Error: $surface source '$source_label' APB multi-peripheral composition requires (address-map ...) and (decode ...) clauses\n"
                unless ref($composition->{address_map}) eq 'HASH' && ref($composition->{decode}) eq 'HASH';
            return {
                kind        => 'apb_composition',
                intent_name => $intent_name,
                protocol    => $profile,
                source      => $source,
                requester   => $apb_requesters[0],
                completers  => [@apb_completers],
                composition => $composition,
            };
        }

        confess "Error: $surface source '$source_label' APB fixed composition requires exactly one (apb-completer ...) object and one (completer INSTANCE OBJECT) child in this slice\n"
            unless @apb_completers == 1 && exists $children->{completer};
        confess "Error: $surface source '$source_label' APB fixed composition does not support (address-map ...) or (decode ...) clauses\n"
            if exists($composition->{address_map}) || exists($composition->{decode});

        return {
            kind        => 'apb_composition',
            intent_name => $intent_name,
            protocol    => $profile,
            source      => $source,
            requester   => $apb_requesters[0],
            completer   => $apb_completers[0],
            composition => $apb_compositions[0],
        };
    }
    if (@apb_requesters) {
        confess "Error: $surface source '$source_label' profile '$profile' does not match (apb-requester ...); expected apb\n"
            unless $profile eq 'apb';
        confess "Error: $surface source '$source_label' cannot mix (apb-requester ...) with (valid-ready-channel ...), (manager-capacity-status ...), (apb-completer ...), or (apb-composition ...) objects outside the explicit APB composition shape in this slice\n"
            if @channels || @managers || @apb_completers || @apb_compositions;
        confess "Error: $surface source '$source_label' supports exactly one (apb-requester ...) object in this slice\n"
            if @apb_requesters > 1;

        return {
            %{$apb_requesters[0]},
            intent_name => $intent_name,
            protocol    => $profile,
            source      => $source,
        };
    }
    if (@apb_completers) {
        confess "Error: $surface source '$source_label' profile '$profile' does not match (apb-completer ...); expected apb\n"
            unless $profile eq 'apb';
        confess "Error: $surface source '$source_label' cannot mix (apb-completer ...) with (valid-ready-channel ...), (manager-capacity-status ...), (apb-requester ...), or (apb-composition ...) objects outside the explicit APB composition shape in this slice\n"
            if @channels || @managers || @apb_requesters || @apb_compositions;
        confess "Error: $surface source '$source_label' supports exactly one (apb-completer ...) object in this slice\n"
            if @apb_completers > 1;

        return {
            %{$apb_completers[0]},
            intent_name => $intent_name,
            protocol    => $profile,
            source      => $source,
        };
    }
    confess "Error: $surface source '$source_label' profile apb requires exactly one (apb-requester ...), one (apb-completer ...), the explicit one-requester/one-completer/one-composition shape, or the selected one-requester/multi-peripheral APB composition shape in this slice\n"
        if $profile eq 'apb';
    confess "Error: $surface source '$source_label' cannot mix (valid-ready-channel ...) and (manager-capacity-status ...) objects in this slice\n"
        if @channels && @managers;
    confess "Error: $surface source '$source_label' supports exactly one (manager-capacity-status ...) object in this slice\n"
        if @managers > 1;

    if (@managers == 1) {
        return {
            %{$managers[0]},
            intent_name => $intent_name,
            protocol    => $profile,
            source      => $source,
        };
    }

    my %seen_channel_names;
    for my $channel (@channels) {
        confess "Error: $surface source '$source_label' has duplicate valid-ready-channel object name '$channel->{name}'\n"
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

sub _parse_apb_requester($body, $source_label) {
    confess "Error: .ppif (apb-requester ...) requires a scalar object name\n"
        unless @$body >= 1 && !ref($body->[0]) && length($body->[0]);

    my $name = $body->[0];
    my %contract = (
        kind => 'apb_requester_transfer',
        name => $name,
    );
    my %seen;
    for my $clause (@{$body}[1 .. $#$body]) {
        my ($head, @items) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (apb-requester $name ...) has duplicate ($head ...) clause\n"
            if $seen{$head}++;

        if ($head =~ /\A(?:role|clock)\z/) {
            confess "Error: .ppif (apb-requester $name ($head ...)) requires exactly one scalar value\n"
                unless @items == 1 && !ref($items[0]);
            $contract{$head} = $items[0];
        } elsif ($head eq 'reset') {
            $contract{reset} = _parse_reset(\@items, $source_label);
        } elsif ($head eq 'request') {
            $contract{request} = _parse_apb_request_block(\@items, $source_label, $name);
        } elsif ($head eq 'response') {
            $contract{response} = _parse_apb_response_block(\@items, $source_label, $name);
        } elsif ($head eq 'bus') {
            $contract{bus} = _parse_apb_bus_block(\@items, $source_label, $name);
        } elsif ($head eq 'transfer') {
            $contract{transfer} = _parse_apb_transfer_block(\@items, $source_label, $name);
        } else {
            confess "Error: .ppif (apb-requester $name ...) has unsupported clause '($head ...)'\n";
        }
    }

    for my $required (qw(role clock reset request response bus transfer)) {
        confess "Error: .ppif (apb-requester $name ...) is missing required ($required ...) clause\n"
            unless exists $contract{$required};
    }

    return \%contract;
}

sub _parse_apb_request_block($items, $source_label, $name) {
    my %allowed = (
        start        => 'start',
        write        => 'write',
        address      => 'address',
        'write-data' => 'write_data',
        protection   => 'protection',
        'write-strobe' => 'write_strobe',
    );
    my %request;

    for my $clause (@$items) {
        my ($head, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (apb-requester $name (request ...)) has unsupported clause '($head ...)'\n"
            unless exists $allowed{$head};
        confess "Error: .ppif (apb-requester $name (request ...)) has duplicate ($head ...) clause\n"
            if exists $request{$allowed{$head}};
        $request{$allowed{$head}} = $head =~ /\A(?:address|write-data|protection|write-strobe)\z/
            ? _parse_apb_width_binding(\@body, $source_label, "apb-requester $name request $head")
            : _parse_apb_scalar_binding(\@body, $source_label, "apb-requester $name request $head");
    }

    for my $required (qw(start write address write_data)) {
        my $clause = $required;
        $clause =~ s/_/-/g;
        confess "Error: .ppif (apb-requester $name (request ...)) is missing required ($clause ...) clause\n"
            unless exists $request{$required};
    }

    return \%request;
}

sub _parse_apb_response_block($items, $source_label, $name) {
    my %allowed = (
        accepted   => 'accepted',
        busy       => 'busy',
        status     => 'status',
        done        => 'done',
        'read-data' => 'read_data',
        error       => 'error',
    );
    my %response;

    for my $clause (@$items) {
        my ($head, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (apb-requester $name (response ...)) has unsupported clause '($head ...)'\n"
            unless exists $allowed{$head};
        confess "Error: .ppif (apb-requester $name (response ...)) has duplicate ($head ...) clause\n"
            if exists $response{$allowed{$head}};
        $response{$allowed{$head}} = $head =~ /\A(?:read-data|status)\z/
            ? _parse_apb_width_binding(\@body, $source_label, "apb-requester $name response $head")
            : _parse_apb_scalar_binding(\@body, $source_label, "apb-requester $name response $head");
    }

    for my $required (qw(done read_data error)) {
        my $clause = $required;
        $clause =~ s/_/-/g;
        confess "Error: .ppif (apb-requester $name (response ...)) is missing required ($clause ...) clause\n"
            unless exists $response{$required};
    }

    if (exists $response{status}) {
        confess "Error: .ppif (apb-requester $name (response ...)) status field requires (busy NAME) in this slice\n"
            unless exists $response{busy};
        confess "Error: .ppif (apb-requester $name (response ...)) status width must be 2 in this slice\n"
            unless $response{status}{width} == 2;
    }

    return \%response;
}

sub _parse_apb_bus_block($items, $source_label, $name) {
    my %allowed = (
        address      => 'address',
        write        => 'write',
        'write-data' => 'write_data',
        protection   => 'protection',
        strobe       => 'strobe',
        select       => 'select',
        enable       => 'enable',
        ready        => 'ready',
        'read-data'  => 'read_data',
        error        => 'error',
    );
    my %bus;

    for my $clause (@$items) {
        my ($head, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (apb-requester $name (bus ...)) has unsupported clause '($head ...)'\n"
            unless exists $allowed{$head};
        confess "Error: .ppif (apb-requester $name (bus ...)) has duplicate ($head ...) clause\n"
            if exists $bus{$allowed{$head}};
        $bus{$allowed{$head}} = $head =~ /\A(?:address|write-data|read-data|protection|strobe)\z/
            ? _parse_apb_width_binding(\@body, $source_label, "apb-requester $name bus $head")
            : _parse_apb_scalar_binding(\@body, $source_label, "apb-requester $name bus $head");
    }

    for my $required (qw(address write write_data select enable ready read_data error)) {
        my $clause = $required;
        $clause =~ s/_/-/g;
        confess "Error: .ppif (apb-requester $name (bus ...)) is missing required ($clause ...) clause\n"
            unless exists $bus{$required};
    }

    return \%bus;
}

sub _parse_apb_transfer_block($items, $source_label, $name) {
    confess "Error: .ppif (apb-requester $name (transfer ...)) requires a scalar transfer name\n"
        unless @$items >= 1 && !ref($items->[0]) && length($items->[0]);

    my $transfer_name = $items->[0];
    my %transfer = (name => $transfer_name);
    my %seen;
    for my $clause (@{$items}[1 .. $#$items]) {
        my ($head, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (apb-requester $name (transfer $transfer_name ...)) has duplicate ($head ...) clause\n"
            if $seen{$head}++;
        if ($head =~ /\A(?:setup|access)\z/) {
            $transfer{$head} = _parse_apb_phase_binding(\@body, $source_label, "apb-requester $name transfer $transfer_name $head");
        } elsif ($head eq 'complete-on') {
            $transfer{complete_on} = _parse_apb_scalar_binding(\@body, $source_label, "apb-requester $name transfer $transfer_name complete-on");
        } elsif ($head eq 'sample') {
            $transfer{sample} = _parse_apb_sample_binding(\@body, $source_label, "apb-requester $name transfer $transfer_name sample");
        } elsif ($head eq 'latency') {
            $transfer{latency} = _parse_apb_latency_binding(\@body, $source_label, "apb-requester $name transfer $transfer_name latency");
        } elsif ($head eq 'timing-policy') {
            $transfer{timing_policy} = _parse_apb_requester_timing_policy(\@body, $source_label, $name, $transfer_name);
        } else {
            confess "Error: .ppif (apb-requester $name (transfer $transfer_name ...)) has unsupported clause '($head ...)'\n";
        }
    }

    for my $required (qw(setup access complete_on sample latency)) {
        my $clause = $required;
        $clause =~ s/_/-/g;
        confess "Error: .ppif (apb-requester $name (transfer $transfer_name ...)) is missing required ($clause ...) clause\n"
            unless exists $transfer{$required};
    }

    return \%transfer;
}

sub _parse_apb_requester_timing_policy($items, $source_label, $name, $transfer_name) {
    my %policy;
    for my $clause (@$items) {
        my ($head, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (apb-requester $name (transfer $transfer_name (timing-policy ...))) has duplicate ($head ...) clause\n"
            if exists $policy{$head};
        if ($head eq 'back-to-back') {
            confess "Error: .ppif (apb-requester $name (transfer $transfer_name (timing-policy (back-to-back ...)))) requires exactly one scalar policy value\n"
                unless @body == 1 && !ref($body[0]);
            confess "Error: .ppif (apb-requester $name (transfer $transfer_name ...)) timing-policy supports only (back-to-back queued) in this slice\n"
                unless $body[0] eq 'queued';
            $policy{back_to_back} = $body[0];
        } elsif ($head eq 'queue-depth') {
            confess "Error: .ppif (apb-requester $name (transfer $transfer_name (timing-policy (queue-depth ...)))) requires exactly one scalar value\n"
                unless @body == 1 && !ref($body[0]);
            confess "Error: .ppif (apb-requester $name (transfer $transfer_name ...)) timing-policy supports only (queue-depth 1) in this slice\n"
                unless $body[0] eq '1';
            $policy{queue_depth} = int($body[0]);
        } elsif ($head eq 'overflow') {
            confess "Error: .ppif (apb-requester $name (transfer $transfer_name (timing-policy (overflow ...)))) requires exactly one scalar policy value\n"
                unless @body == 1 && !ref($body[0]);
            confess "Error: .ppif (apb-requester $name (transfer $transfer_name ...)) timing-policy supports only (overflow reject) in this slice\n"
                unless $body[0] eq 'reject';
            $policy{overflow} = $body[0];
        } else {
            confess "Error: .ppif (apb-requester $name (transfer $transfer_name (timing-policy ...))) has unsupported clause '($head ...)'\n";
        }
    }

    for my $required (qw(back_to_back queue_depth overflow)) {
        my $clause = $required;
        $clause =~ s/_/-/g;
        confess "Error: .ppif (apb-requester $name (transfer $transfer_name (timing-policy ...))) is missing required ($clause ...) clause\n"
            unless exists $policy{$required};
    }

    return \%policy;
}

sub _parse_ahb_requester($body, $source_label) {
    confess "Error: .ppif (ahb-requester ...) requires a scalar object name\n"
        unless @$body >= 1 && !ref($body->[0]) && length($body->[0]);

    my $name = $body->[0];
    my %contract = (
        kind => 'ahb_requester',
        name => $name,
    );
    my %seen;
    for my $clause (@{$body}[1 .. $#$body]) {
        my ($head, @items) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (ahb-requester $name ...) has duplicate ($head ...) clause\n"
            if $seen{$head}++;

        if ($head =~ /\A(?:role|clock)\z/) {
            confess "Error: .ppif (ahb-requester $name ($head ...)) requires exactly one scalar value\n"
                unless @items == 1 && !ref($items[0]);
            $contract{$head} = $items[0];
        } elsif ($head eq 'reset') {
            $contract{reset} = _parse_reset(\@items, $source_label);
        } elsif ($head eq 'local-command') {
            $contract{local_command} = _parse_ahb_local_command_block(\@items, $source_label, $name);
        } elsif ($head eq 'local-status') {
            $contract{local_status} = _parse_ahb_local_status_block(\@items, $source_label, $name);
        } elsif ($head eq 'bus') {
            $contract{bus} = _parse_ahb_bus_block(\@items, $source_label, $name);
        } elsif ($head eq 'burst') {
            $contract{burst} = _parse_ahb_literal_block(
                \@items,
                $source_label,
                "ahb-requester $name burst",
                [qw(single incr wrap4 incr4 wrap8 incr8 wrap16 incr16 length-zero-means-one max-beats)],
            );
        } elsif ($head eq 'transfer') {
            $contract{transfer} = _parse_ahb_literal_block(
                \@items,
                $source_label,
                "ahb-requester $name transfer",
                [qw(idle nonseq seq first-beat later-beats advance-on)],
            );
        } elsif ($head eq 'response') {
            $contract{response} = _parse_ahb_literal_block(
                \@items,
                $source_label,
                "ahb-requester $name response",
                [qw(okay error retry split error-action retry-action split-action read-sample)],
            );
        } else {
            confess "Error: .ppif (ahb-requester $name ...) has unsupported clause '($head ...)'\n";
        }
    }

    for my $required (qw(role clock reset local_command local_status bus burst transfer response)) {
        my $clause = $required;
        $clause =~ s/_/-/g;
        confess "Error: .ppif (ahb-requester $name ...) is missing required ($clause ...) clause\n"
            unless exists $contract{$required};
    }

    return \%contract;
}

sub _parse_ahb_local_command_block($items, $source_label, $name) {
    return _parse_ahb_binding_block(
        $items,
        $source_label,
        "ahb-requester $name local-command",
        {
            valid             => 'scalar',
            ready             => 'scalar',
            write             => 'scalar',
            address           => 'width',
            'write-data'      => 'width',
            'write-data-step' => 'width',
            size              => 'width',
            protection        => 'width',
            lock              => 'scalar',
            burst             => 'width',
            length            => 'width',
        },
        [qw(valid ready write address write-data write-data-step size protection lock burst length)],
    );
}

sub _parse_ahb_local_status_block($items, $source_label, $name) {
    return _parse_ahb_binding_block(
        $items,
        $source_label,
        "ahb-requester $name local-status",
        {
            busy              => 'scalar',
            'beat-done'       => 'scalar',
            done              => 'scalar',
            'burst-active'    => 'scalar',
            'wrap-active'     => 'scalar',
            'beat-index'      => 'width',
            'beats-remaining' => 'width',
            'active-address'  => 'width',
            'active-burst'    => 'width',
            'last-error'      => 'scalar',
            'last-retry'      => 'scalar',
            'last-split'      => 'scalar',
            'last-response'   => 'width',
            'last-read-data'  => 'width',
        },
        [qw(busy beat-done done burst-active wrap-active beat-index beats-remaining active-address active-burst last-error last-retry last-split last-response last-read-data)],
    );
}

sub _parse_ahb_bus_block($items, $source_label, $name) {
    return _parse_ahb_binding_block(
        $items,
        $source_label,
        "ahb-requester $name bus",
        {
            grant       => 'scalar',
            ready       => 'scalar',
            response    => 'width',
            'read-data' => 'width',
            request     => 'scalar',
            lock        => 'scalar',
            address     => 'width',
            transfer    => 'width',
            write       => 'scalar',
            size        => 'width',
            burst       => 'width',
            protection  => 'width',
            'write-data' => 'width',
        },
        [qw(grant ready response read-data request lock address transfer write size burst protection write-data)],
    );
}

sub _parse_ahb_binding_block($items, $source_label, $context, $shape, $required) {
    my %parsed;
    for my $clause (@$items) {
        my ($head, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif ($context ...) has unsupported clause '($head ...)'\n"
            unless exists $shape->{$head};
        my $key = $head;
        $key =~ s/-/_/g;
        confess "Error: .ppif ($context ...) has duplicate ($head ...) clause\n"
            if exists $parsed{$key};
        $parsed{$key} = $shape->{$head} eq 'width'
            ? _parse_apb_width_binding(\@body, $source_label, "$context $head")
            : _parse_apb_scalar_binding(\@body, $source_label, "$context $head");
    }

    for my $field (@$required) {
        my $key = $field;
        $key =~ s/-/_/g;
        confess "Error: .ppif ($context ...) is missing required ($field ...) clause\n"
            unless exists $parsed{$key};
    }

    return \%parsed;
}

sub _parse_ahb_literal_block($items, $source_label, $context, $required) {
    my %parsed;
    my %required = map { $_ => 1 } @$required;
    for my $clause (@$items) {
        my ($head, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif ($context ...) has unsupported clause '($head ...)'\n"
            unless $required{$head};
        my $key = $head;
        $key =~ s/-/_/g;
        confess "Error: .ppif ($context ...) has duplicate ($head ...) clause\n"
            if exists $parsed{$key};
        confess "Error: .ppif ($context ($head ...)) requires exactly one scalar value\n"
            unless @body == 1 && !ref($body[0]);
        $parsed{$key} = $body[0];
    }

    for my $field (@$required) {
        my $key = $field;
        $key =~ s/-/_/g;
        confess "Error: .ppif ($context ...) is missing required ($field ...) clause\n"
            unless exists $parsed{$key};
    }

    return \%parsed;
}

sub _parse_ahb_subordinate($body, $source_label) {
    confess "Error: .ppif (ahb-subordinate ...) requires a scalar object name\n"
        unless @$body >= 1 && !ref($body->[0]) && length($body->[0]);

    my $name = $body->[0];
    my %contract = (
        kind => 'ahb_subordinate',
        name => $name,
    );
    my %seen;
    for my $clause (@{$body}[1 .. $#$body]) {
        my ($head, @items) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (ahb-subordinate $name ...) has duplicate ($head ...) clause\n"
            if $seen{$head}++;

        if ($head =~ /\A(?:role|clock)\z/) {
            confess "Error: .ppif (ahb-subordinate $name ($head ...)) requires exactly one scalar value\n"
                unless @items == 1 && !ref($items[0]);
            $contract{$head} = $items[0];
        } elsif ($head eq 'reset') {
            $contract{reset} = _parse_reset(\@items, $source_label);
        } elsif ($head eq 'control') {
            $contract{control} = _parse_ahb_subordinate_control_block(\@items, $source_label, $name);
        } elsif ($head eq 'bus') {
            $contract{bus} = _parse_ahb_subordinate_bus_block(\@items, $source_label, $name);
        } elsif ($head eq 'storage') {
            $contract{storage} = _parse_ahb_subordinate_storage_block(\@items, $source_label, $name);
        } elsif ($head eq 'transfer') {
            $contract{transfer} = _parse_ahb_subordinate_transfer_block(\@items, $source_label, $name);
        } else {
            confess "Error: .ppif (ahb-subordinate $name ...) has unsupported clause '($head ...)'\n";
        }
    }

    for my $required (qw(role clock reset control bus storage transfer)) {
        my $clause = $required;
        $clause =~ s/_/-/g;
        confess "Error: .ppif (ahb-subordinate $name ...) is missing required ($clause ...) clause\n"
            unless exists $contract{$required};
    }

    return \%contract;
}

sub _parse_ahb_subordinate_control_block($items, $source_label, $name) {
    return _parse_ahb_binding_block(
        $items,
        $source_label,
        "ahb-subordinate $name control",
        {
            'wait-cycles' => 'width',
        },
        [qw(wait-cycles)],
    );
}

sub _parse_ahb_subordinate_bus_block($items, $source_label, $name) {
    return _parse_ahb_binding_block(
        $items,
        $source_label,
        "ahb-subordinate $name bus",
        {
            select       => 'scalar',
            'ready-in'   => 'scalar',
            address      => 'width',
            transfer     => 'width',
            burst        => 'width',
            write        => 'scalar',
            size         => 'width',
            'write-data' => 'width',
            'ready-out'  => 'scalar',
            response     => 'width',
            'read-data'  => 'width',
        },
        [qw(select ready-in address transfer write size write-data ready-out response read-data)],
    );
}

sub _parse_ahb_subordinate_storage_block($items, $source_label, $name) {
    my @registers;

    for my $clause (@$items) {
        my ($head, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (ahb-subordinate $name (storage ...)) has unsupported clause '($head ...)'\n"
            unless $head eq 'register';
        push @registers, _parse_ahb_subordinate_storage_register(\@body, $source_label, $name);
    }

    confess "Error: .ppif (ahb-subordinate $name (storage ...)) requires exactly one (register ...) clause in this slice\n"
        unless @registers == 1;

    return { register => $registers[0] };
}

sub _parse_ahb_subordinate_storage_register($items, $source_label, $name) {
    confess "Error: .ppif (ahb-subordinate $name (storage (register ...))) requires a scalar register name\n"
        unless @$items >= 1 && !ref($items->[0]) && length($items->[0]);

    my $register_name = $items->[0];
    my %register = (name => $register_name);
    my %seen;
    for my $clause (@{$items}[1 .. $#$items]) {
        my ($head, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (ahb-subordinate $name (storage (register $register_name ...))) has duplicate ($head ...) clause\n"
            if $seen{$head}++;
        if ($head eq 'address') {
            $register{address} = _parse_apb_address_binding(\@body, $source_label, "ahb-subordinate $name storage register $register_name address");
        } elsif ($head eq 'data') {
            $register{data} = _parse_apb_storage_data_binding(\@body, $source_label, "ahb-subordinate $name storage register $register_name data");
        } else {
            confess "Error: .ppif (ahb-subordinate $name (storage (register $register_name ...))) has unsupported clause '($head ...)'\n";
        }
    }

    for my $required (qw(address data)) {
        confess "Error: .ppif (ahb-subordinate $name (storage (register $register_name ...))) is missing required ($required ...) clause\n"
            unless exists $register{$required};
    }

    return \%register;
}

sub _parse_ahb_subordinate_transfer_block($items, $source_label, $name) {
    confess "Error: .ppif (ahb-subordinate $name (transfer ...)) requires a scalar transfer name\n"
        unless @$items >= 1 && !ref($items->[0]) && length($items->[0]);

    my $transfer_name = $items->[0];
    my %transfer = (name => $transfer_name);
    my %seen_single;
    my @ignored;
    my @parked;
    my @supported_sizes;
    for my $clause (@{$items}[1 .. $#$items]) {
        my ($head, @body) = _clause_parts($clause, $source_label);
        if ($head eq 'ignored-transfer') {
            push @ignored, _parse_apb_scalar_binding(\@body, $source_label, "ahb-subordinate $name transfer $transfer_name ignored-transfer");
            next;
        }
        if ($head eq 'parked-transfer') {
            push @parked, _parse_apb_scalar_binding(\@body, $source_label, "ahb-subordinate $name transfer $transfer_name parked-transfer");
            next;
        }
        if ($head eq 'supported-size') {
            push @supported_sizes, _parse_apb_scalar_binding(\@body, $source_label, "ahb-subordinate $name transfer $transfer_name supported-size");
            next;
        }

        confess "Error: .ppif (ahb-subordinate $name (transfer $transfer_name ...)) has duplicate ($head ...) clause\n"
            if $seen_single{$head}++;
        if ($head eq 'accept-when') {
            $transfer{accept_when} = _parse_ahb_subordinate_accept_when(\@body, $source_label, $name, $transfer_name);
        } elsif ($head =~ /\A(?:idle|busy|nonseq|seq|supported-transfer|wait-cycles|read|write|unmapped-address|unsupported-size|unsupported-transfer|lane-order|narrow-write|narrow-read|unaligned-access|crossing-access|seq-policy|error-completion)\z/) {
            my $key = $head;
            $key =~ s/-/_/g;
            $transfer{$key} = _parse_apb_scalar_binding(\@body, $source_label, "ahb-subordinate $name transfer $transfer_name $head");
        } elsif ($head eq 'response') {
            $transfer{response} = _parse_ahb_subordinate_response_block(\@body, $source_label, $name, $transfer_name);
        } else {
            confess "Error: .ppif (ahb-subordinate $name (transfer $transfer_name ...)) has unsupported clause '($head ...)'\n";
        }
    }
    $transfer{ignored_transfer} = \@ignored if @ignored;
    $transfer{parked_transfer} = \@parked if @parked;
    $transfer{supported_size} = \@supported_sizes if @supported_sizes;

    for my $required (qw(accept_when idle busy nonseq seq supported_transfer ignored_transfer wait_cycles read write unmapped_address unsupported_size unsupported_transfer response error_completion)) {
        my $clause = $required;
        $clause =~ s/_/-/g;
        confess "Error: .ppif (ahb-subordinate $name (transfer $transfer_name ...)) is missing required ($clause ...) clause\n"
            unless exists $transfer{$required};
    }

    return \%transfer;
}

sub _parse_ahb_subordinate_accept_when($items, $source_label, $name, $transfer_name) {
    my %parsed;
    for my $clause (@$items) {
        my ($head, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (ahb-subordinate $name (transfer $transfer_name (accept-when ...))) supports only (select ...) and (ready-in ...) clauses\n"
            unless $head eq 'select' || $head eq 'ready-in';
        my $key = $head;
        $key =~ s/-/_/g;
        confess "Error: .ppif (ahb-subordinate $name (transfer $transfer_name (accept-when ...))) has duplicate ($head ...) clause\n"
            if exists $parsed{$key};
        $parsed{$key} = _parse_apb_scalar_binding(\@body, $source_label, "ahb-subordinate $name transfer $transfer_name accept-when $head");
    }

    for my $required (qw(select ready_in)) {
        my $clause = $required;
        $clause =~ s/_/-/g;
        confess "Error: .ppif (ahb-subordinate $name (transfer $transfer_name (accept-when ...))) is missing required ($clause ...) clause\n"
            unless exists $parsed{$required};
    }

    return \%parsed;
}

sub _parse_ahb_subordinate_response_block($items, $source_label, $name, $transfer_name) {
    my %parsed;
    for my $clause (@$items) {
        my ($head, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (ahb-subordinate $name (transfer $transfer_name (response ...))) supports only (okay ...) and (error ...) clauses\n"
            unless $head eq 'okay' || $head eq 'error';
        confess "Error: .ppif (ahb-subordinate $name (transfer $transfer_name (response ...))) has duplicate ($head ...) clause\n"
            if exists $parsed{$head};
        $parsed{$head} = _parse_apb_scalar_binding(\@body, $source_label, "ahb-subordinate $name transfer $transfer_name response $head");
    }

    for my $required (qw(okay error)) {
        confess "Error: .ppif (ahb-subordinate $name (transfer $transfer_name (response ...))) is missing required ($required ...) clause\n"
            unless exists $parsed{$required};
    }

    return \%parsed;
}

sub _parse_ahb_interconnect($body, $source_label) {
    confess "Error: .ppif (ahb-interconnect ...) requires a scalar object name\n"
        unless @$body >= 1 && !ref($body->[0]) && length($body->[0]);

    my $name = $body->[0];
    my %contract = (
        kind => 'ahb_interconnect',
        name => $name,
    );
    my %seen;
    for my $clause (@{$body}[1 .. $#$body]) {
        my ($head, @items) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (ahb-interconnect $name ...) has duplicate ($head ...) clause\n"
            if $seen{$head}++;

        if ($head =~ /\A(?:role|clock)\z/) {
            confess "Error: .ppif (ahb-interconnect $name ($head ...)) requires exactly one scalar value\n"
                unless @items == 1 && !ref($items[0]);
            $contract{$head} = $items[0];
        } elsif ($head eq 'reset') {
            $contract{reset} = _parse_reset(\@items, $source_label);
        } elsif ($head eq 'children') {
            $contract{children} = _parse_ahb_interconnect_children_block(\@items, $source_label, $name);
        } elsif ($head eq 'address-map') {
            $contract{address_map} = _parse_ahb_interconnect_address_map_block(\@items, $source_label, $name);
        } elsif ($head eq 'decode') {
            $contract{decode} = _parse_ahb_interconnect_decode_block(\@items, $source_label, $name);
        } elsif ($head eq 'wiring') {
            $contract{wiring} = _parse_ahb_interconnect_wiring_block(\@items, $source_label, $name);
        } else {
            confess "Error: .ppif (ahb-interconnect $name ...) has unsupported clause '($head ...)'\n";
        }
    }

    for my $required (qw(role clock reset children address_map decode wiring)) {
        my $clause = $required;
        $clause =~ s/_/-/g;
        confess "Error: .ppif (ahb-interconnect $name ...) is missing required ($clause ...) clause\n"
            unless exists $contract{$required};
    }

    return \%contract;
}

sub _parse_ahb_interconnect_children_block($items, $source_label, $name) {
    my %children;
    my @subordinates;

    for my $clause (@$items) {
        my ($head, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (ahb-interconnect $name (children ...)) supports only (requester INSTANCE OBJECT) and (subordinate INSTANCE OBJECT)\n"
            unless $head =~ /\A(?:requester|subordinate)\z/;
        confess "Error: .ppif (ahb-interconnect $name (children ...)) has duplicate (requester ...) clause\n"
            if $head eq 'requester' && exists $children{$head};
        confess "Error: .ppif (ahb-interconnect $name (children ($head ...))) requires exactly instance and object scalar names\n"
            unless @body == 2 && !ref($body[0]) && length($body[0]) && !ref($body[1]) && length($body[1]);
        my $child = {
            instance_name => $body[0],
            object_name   => $body[1],
        };
        if ($head eq 'subordinate') {
            push @subordinates, $child;
            next;
        }
        $children{$head} = $child;
    }

    confess "Error: .ppif (ahb-interconnect $name (children ...)) is missing required (requester ...) clause\n"
        unless exists $children{requester};
    confess "Error: .ppif (ahb-interconnect $name (children ...)) is missing required (subordinate ...) clause\n"
        unless @subordinates;
    confess "Error: .ppif (ahb-interconnect $name (children ...)) supports one or two (subordinate ...) clauses in this slice\n"
        unless @subordinates == 1 || @subordinates == 2;

    $children{subordinate} = $subordinates[0];
    $children{subordinates} = \@subordinates;
    return \%children;
}

sub _parse_ahb_interconnect_address_map_block($items, $source_label, $name) {
    confess "Error: .ppif (ahb-interconnect $name (address-map ...)) requires a scalar address-map name\n"
        unless @$items >= 1 && !ref($items->[0]) && length($items->[0]);

    my $map_name = $items->[0];
    my @windows;
    for my $clause (@{$items}[1 .. $#$items]) {
        my ($head, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (ahb-interconnect $name (address-map $map_name ...)) supports only (window INSTANCE ...)\n"
            unless $head eq 'window';
        push @windows, _parse_ahb_interconnect_address_window(\@body, $source_label, $name, $map_name);
    }

    confess "Error: .ppif (ahb-interconnect $name (address-map $map_name ...)) requires one or two (window ...) clauses in this slice\n"
        unless @windows == 1 || @windows == 2;

    return {
        name    => $map_name,
        windows => \@windows,
    };
}

sub _parse_ahb_interconnect_address_window($items, $source_label, $name, $map_name) {
    confess "Error: .ppif (ahb-interconnect $name (address-map $map_name (window ...))) requires a scalar subordinate instance name\n"
        unless @$items >= 1 && !ref($items->[0]) && length($items->[0]);

    my $window_name = $items->[0];
    my %window = (name => $window_name);
    my %seen;
    for my $clause (@{$items}[1 .. $#$items]) {
        my ($head, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (ahb-interconnect $name (address-map $map_name (window $window_name ...))) supports only (base NAME width N default V) and (size NAME width N default V)\n"
            unless $head =~ /\A(?:base|size)\z/;
        confess "Error: .ppif (ahb-interconnect $name (address-map $map_name (window $window_name ...))) has duplicate ($head ...) clause\n"
            if $seen{$head}++;
        $window{$head} = _parse_apb_parameter_default_binding(
            \@body,
            $source_label,
            "ahb-interconnect $name address-map $map_name window $window_name $head",
        );
    }

    for my $required (qw(base size)) {
        confess "Error: .ppif (ahb-interconnect $name (address-map $map_name (window $window_name ...))) is missing required ($required ...) clause\n"
            unless exists $window{$required};
    }

    return \%window;
}

sub _parse_ahb_interconnect_decode_block($items, $source_label, $name) {
    my %allowed = (
        overlap            => 'overlap',
        priority           => 'priority',
        'unmapped-address' => 'unmapped_address',
    );
    my %decode;

    for my $clause (@$items) {
        my ($head, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (ahb-interconnect $name (decode ...)) has unsupported clause '($head ...)'\n"
            unless exists $allowed{$head};
        confess "Error: .ppif (ahb-interconnect $name (decode ...)) has duplicate ($head ...) clause\n"
            if exists $decode{$allowed{$head}};
        $decode{$allowed{$head}} = _parse_apb_scalar_binding(
            \@body,
            $source_label,
            "ahb-interconnect $name decode $head",
        );
    }

    for my $required (qw(overlap priority unmapped_address)) {
        my $clause = $required;
        $clause =~ s/_/-/g;
        confess "Error: .ppif (ahb-interconnect $name (decode ...)) is missing required ($clause ...) clause\n"
            unless exists $decode{$required};
    }

    return \%decode;
}

sub _parse_ahb_interconnect_wiring_block($items, $source_label, $name) {
    confess "Error: .ppif (ahb-interconnect $name (wiring ...)) requires a scalar wiring name\n"
        unless @$items >= 1 && !ref($items->[0]) && length($items->[0]);

    my $wiring_name = $items->[0];
    my %allowed = (
        grant                   => 'grant',
        request                 => 'request',
        ready                   => 'ready',
        response                => 'response',
        'read-data'             => 'read_data',
        address                 => 'address',
        transfer                => 'transfer',
        write                   => 'write',
        size                    => 'size',
        burst                   => 'burst',
        protection              => 'protection',
        lock                    => 'lock',
        'write-data'            => 'write_data',
        'subordinate-select'    => 'subordinate_select',
        'subordinate-ready-out' => 'subordinate_ready_out',
        'subordinate-response'  => 'subordinate_response',
        'subordinate-read-data' => 'subordinate_read_data',
    );
    my %bus;

    for my $clause (@{$items}[1 .. $#$items]) {
        my ($head, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (ahb-interconnect $name (wiring $wiring_name ...)) has unsupported clause '($head ...)'\n"
            unless exists $allowed{$head};
        confess "Error: .ppif (ahb-interconnect $name (wiring $wiring_name ...)) has duplicate ($head ...) clause\n"
            if exists $bus{$allowed{$head}};
        $bus{$allowed{$head}} = $head =~ /\A(?:response|read-data|address|transfer|size|burst|protection|write-data|subordinate-response|subordinate-read-data)\z/
            ? _parse_apb_width_binding(\@body, $source_label, "ahb-interconnect $name wiring $wiring_name $head")
            : _parse_apb_scalar_binding(\@body, $source_label, "ahb-interconnect $name wiring $wiring_name $head");
    }

    for my $required (qw(grant request ready response read_data address transfer write size burst protection lock write_data)) {
        my $clause = $required;
        $clause =~ s/_/-/g;
        confess "Error: .ppif (ahb-interconnect $name (wiring $wiring_name ...)) is missing required ($clause ...) clause\n"
            unless exists $bus{$required};
    }

    return {
        name => $wiring_name,
        bus  => \%bus,
    };
}

sub _parse_apb_scalar_binding($body, $source_label, $context) {
    confess "Error: .ppif ($context ...) requires exactly one scalar value\n"
        unless @$body == 1 && !ref($body->[0]) && length($body->[0]);
    return $body->[0];
}

sub _parse_apb_width_binding($body, $source_label, $context) {
    confess "Error: .ppif ($context ...) requires '(signal width N)'\n"
        unless @$body == 3 && !ref($body->[0]) && !ref($body->[1]) && !ref($body->[2]) && $body->[1] eq 'width';
    return {
        name  => $body->[0],
        width => $body->[2],
    };
}

sub _parse_apb_phase_binding($body, $source_label, $context) {
    my %phase;
    for my $clause (@$body) {
        my ($head, @items) = _clause_parts($clause, $source_label);
        confess "Error: .ppif ($context ...) supports only (select N) and (enable N)\n"
            unless $head =~ /\A(?:select|enable)\z/;
        confess "Error: .ppif ($context ...) has duplicate ($head ...) clause\n"
            if exists $phase{$head};
        confess "Error: .ppif ($context ($head ...)) requires exactly one scalar value\n"
            unless @items == 1 && !ref($items[0]);
        $phase{$head} = $items[0];
    }

    for my $required (qw(select enable)) {
        confess "Error: .ppif ($context ...) is missing required ($required ...) clause\n"
            unless exists $phase{$required};
    }

    return \%phase;
}

sub _parse_apb_sample_binding($body, $source_label, $context) {
    confess "Error: .ppif ($context ...) requires at least one scalar sample name\n"
        unless @$body;
    for my $item (@$body) {
        confess "Error: .ppif ($context ...) sample entries must be scalar names\n"
            if ref($item) || !length($item);
    }
    return [@$body];
}

sub _parse_apb_latency_binding($body, $source_label, $context) {
    my %latency;
    for my $clause (@$body) {
        my ($head, @items) = _clause_parts($clause, $source_label);
        confess "Error: .ppif ($context ...) supports only (min N) and (max N)\n"
            unless $head =~ /\A(?:min|max)\z/;
        confess "Error: .ppif ($context ...) has duplicate ($head ...) clause\n"
            if exists $latency{$head};
        confess "Error: .ppif ($context ($head ...)) requires exactly one scalar value\n"
            unless @items == 1 && !ref($items[0]);
        $latency{$head} = $items[0];
    }

    for my $required (qw(min max)) {
        confess "Error: .ppif ($context ...) is missing required ($required ...) clause\n"
            unless exists $latency{$required};
    }

    return \%latency;
}

sub _parse_apb_completer($body, $source_label) {
    confess "Error: .ppif (apb-completer ...) requires a scalar object name\n"
        unless @$body >= 1 && !ref($body->[0]) && length($body->[0]);

    my $name = $body->[0];
    my %contract = (
        kind => 'apb_completer',
        name => $name,
    );
    my %seen;
    for my $clause (@{$body}[1 .. $#$body]) {
        my ($head, @items) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (apb-completer $name ...) has duplicate ($head ...) clause\n"
            if $seen{$head}++;

        if ($head =~ /\A(?:role|clock)\z/) {
            confess "Error: .ppif (apb-completer $name ($head ...)) requires exactly one scalar value\n"
                unless @items == 1 && !ref($items[0]);
            $contract{$head} = $items[0];
        } elsif ($head eq 'reset') {
            $contract{reset} = _parse_reset(\@items, $source_label);
        } elsif ($head eq 'control') {
            $contract{control} = _parse_apb_completer_control_block(\@items, $source_label, $name);
        } elsif ($head eq 'bus') {
            $contract{bus} = _parse_apb_completer_bus_block(\@items, $source_label, $name);
        } elsif ($head eq 'storage') {
            $contract{storage} = _parse_apb_completer_storage_block(\@items, $source_label, $name);
        } elsif ($head eq 'transfer') {
            $contract{transfer} = _parse_apb_completer_transfer_block(\@items, $source_label, $name);
        } else {
            confess "Error: .ppif (apb-completer $name ...) has unsupported clause '($head ...)'\n";
        }
    }

    for my $required (qw(role clock reset control bus storage transfer)) {
        confess "Error: .ppif (apb-completer $name ...) is missing required ($required ...) clause\n"
            unless exists $contract{$required};
    }

    return \%contract;
}

sub _parse_apb_completer_control_block($items, $source_label, $name) {
    my %control;

    for my $clause (@$items) {
        my ($head, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (apb-completer $name (control ...)) has unsupported clause '($head ...)'\n"
            unless $head eq 'wait-cycles';
        confess "Error: .ppif (apb-completer $name (control ...)) has duplicate ($head ...) clause\n"
            if exists $control{wait_cycles};
        $control{wait_cycles} = _parse_apb_width_binding(\@body, $source_label, "apb-completer $name control $head");
    }

    confess "Error: .ppif (apb-completer $name (control ...)) is missing required (wait-cycles ...) clause\n"
        unless exists $control{wait_cycles};

    return \%control;
}

sub _parse_apb_completer_bus_block($items, $source_label, $name) {
    my %allowed = (
        select       => 'select',
        enable       => 'enable',
        write        => 'write',
        address      => 'address',
        'write-data' => 'write_data',
        protection   => 'protection',
        strobe       => 'strobe',
        ready        => 'ready',
        'read-data'  => 'read_data',
        error        => 'error',
    );
    my %bus;

    for my $clause (@$items) {
        my ($head, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (apb-completer $name (bus ...)) has unsupported clause '($head ...)'\n"
            unless exists $allowed{$head};
        confess "Error: .ppif (apb-completer $name (bus ...)) has duplicate ($head ...) clause\n"
            if exists $bus{$allowed{$head}};
        $bus{$allowed{$head}} = $head =~ /\A(?:address|write-data|read-data|protection|strobe)\z/
            ? _parse_apb_width_binding(\@body, $source_label, "apb-completer $name bus $head")
            : _parse_apb_scalar_binding(\@body, $source_label, "apb-completer $name bus $head");
    }

    for my $required (qw(select enable write address write_data ready read_data error)) {
        my $clause = $required;
        $clause =~ s/_/-/g;
        confess "Error: .ppif (apb-completer $name (bus ...)) is missing required ($clause ...) clause\n"
            unless exists $bus{$required};
    }

    return \%bus;
}

sub _parse_apb_completer_storage_block($items, $source_label, $name) {
    my @registers;

    for my $clause (@$items) {
        next unless defined $clause;
        my ($head, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (apb-completer $name (storage ...)) has unsupported clause '($head ...)'\n"
            unless $head eq 'register';
        push @registers, _parse_apb_completer_storage_register(\@body, $source_label, $name);
    }

    confess "Error: .ppif (apb-completer $name (storage ...)) requires at least one (register ...) clause\n"
        unless @registers;

    return @registers == 1
        ? { register => $registers[0] }
        : { registers => \@registers };
}

sub _parse_apb_completer_storage_register($items, $source_label, $name) {
    confess "Error: .ppif (apb-completer $name (storage (register ...))) requires a scalar register name\n"
        unless @$items >= 1 && !ref($items->[0]) && length($items->[0]);

    my $register_name = $items->[0];
    my %register = (name => $register_name);
    my %seen;
    for my $clause (@{$items}[1 .. $#$items]) {
        my ($head, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (apb-completer $name (storage (register $register_name ...))) has duplicate ($head ...) clause\n"
            if $seen{$head}++;
        if ($head eq 'address') {
            $register{address} = _parse_apb_address_binding(\@body, $source_label, "apb-completer $name storage register $register_name address");
        } elsif ($head eq 'data') {
            $register{data} = _parse_apb_storage_data_binding(\@body, $source_label, "apb-completer $name storage register $register_name data");
        } elsif ($head eq 'access-policy') {
            $register{access_policy} = _parse_apb_completer_access_policy(\@body, $source_label, $name, $register_name);
        } else {
            confess "Error: .ppif (apb-completer $name (storage (register $register_name ...))) has unsupported clause '($head ...)'\n";
        }
    }

    for my $required (qw(address data)) {
        confess "Error: .ppif (apb-completer $name (storage (register $register_name ...))) is missing required ($required ...) clause\n"
            unless exists $register{$required};
    }

    return \%register;
}

sub _parse_apb_completer_access_policy($items, $source_label, $name, $register_name) {
    my %policy;
    for my $clause (@$items) {
        my ($head, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (apb-completer $name (storage (register $register_name (access-policy ...)))) supports only (read ...) and (write ...) clauses\n"
            unless $head eq 'read' || $head eq 'write';
        confess "Error: .ppif (apb-completer $name (storage (register $register_name (access-policy ...)))) has duplicate ($head ...) clause\n"
            if exists $policy{$head};
        $policy{$head} = _parse_apb_completer_access_policy_action(
            \@body,
            $source_label,
            "apb-completer $name storage register $register_name access-policy $head",
        );
    }

    for my $required (qw(read write)) {
        confess "Error: .ppif (apb-completer $name (storage (register $register_name (access-policy ...)))) is missing required ($required ...) clause\n"
            unless exists $policy{$required};
    }

    return \%policy;
}

sub _parse_apb_completer_access_policy_action($items, $source_label, $context) {
    confess "Error: .ppif ($context ...) requires action allow or require\n"
        unless @$items >= 1 && !ref($items->[0]) && length($items->[0]);

    my $action = $items->[0];
    return { action => 'allow' }
        if $action eq 'allow' && @$items == 1;

    confess "Error: .ppif ($context allow ...) does not accept predicates\n"
        if $action eq 'allow';
    confess "Error: .ppif ($context ...) supports only action allow or require\n"
        unless $action eq 'require';
    confess "Error: .ppif ($context require ...) requires exactly one predicate clause\n"
        unless @$items == 2 && ref($items->[1]) eq 'ARRAY';

    return {
        action    => 'require',
        predicate => _parse_apb_completer_access_policy_predicate($items->[1], $source_label, $context),
    };
}

sub _parse_apb_completer_access_policy_predicate($clause, $source_label, $context) {
    my ($head, @body) = _clause_parts($clause, $source_label);
    confess "Error: .ppif ($context require ...) supports only (privileged 0) or (privileged 1)\n"
        unless $head eq 'privileged';
    confess "Error: .ppif ($context require (privileged ...)) requires exactly one scalar value 0 or 1\n"
        unless @body == 1 && !ref($body[0]) && ($body[0] eq '0' || $body[0] eq '1');
    return {
        kind  => 'privileged',
        value => int($body[0]),
    };
}

sub _parse_apb_address_binding($body, $source_label, $context) {
    confess "Error: .ppif ($context ...) requires '(address width N)'\n"
        unless @$body == 3 && !ref($body->[0]) && !ref($body->[1]) && !ref($body->[2]) && $body->[1] eq 'width';
    return {
        value => $body->[0],
        width => $body->[2],
    };
}

sub _parse_apb_storage_data_binding($body, $source_label, $context) {
    confess "Error: .ppif ($context ...) requires '(signal width N reset V)'\n"
        unless @$body == 5
            && !ref($body->[0])
            && !ref($body->[1])
            && !ref($body->[2])
            && !ref($body->[3])
            && !ref($body->[4])
            && $body->[1] eq 'width'
            && $body->[3] eq 'reset';
    return {
        name  => $body->[0],
        width => $body->[2],
        reset => $body->[4],
    };
}

sub _parse_apb_completer_transfer_block($items, $source_label, $name) {
    confess "Error: .ppif (apb-completer $name (transfer ...)) requires a scalar transfer name\n"
        unless @$items >= 1 && !ref($items->[0]) && length($items->[0]);

    my $transfer_name = $items->[0];
    my %transfer = (name => $transfer_name);
    my %seen;
    for my $clause (@{$items}[1 .. $#$items]) {
        my ($head, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (apb-completer $name (transfer $transfer_name ...)) has duplicate ($head ...) clause\n"
            if $seen{$head}++;
        if ($head eq 'setup-detect') {
            $transfer{setup_detect} = _parse_apb_phase_binding(\@body, $source_label, "apb-completer $name transfer $transfer_name $head");
        } elsif ($head eq 'wait-cycles') {
            $transfer{wait_cycles} = _parse_apb_scalar_binding(\@body, $source_label, "apb-completer $name transfer $transfer_name $head");
        } elsif ($head eq 'read') {
            $transfer{read} = _parse_apb_scalar_binding(\@body, $source_label, "apb-completer $name transfer $transfer_name $head");
        } elsif ($head eq 'write') {
            $transfer{write} = _parse_apb_scalar_binding(\@body, $source_label, "apb-completer $name transfer $transfer_name $head");
        } elsif ($head eq 'unmapped-address') {
            $transfer{unmapped_address} = _parse_apb_scalar_binding(\@body, $source_label, "apb-completer $name transfer $transfer_name $head");
        } elsif ($head eq 'timing-policy') {
            $transfer{timing_policy} = _parse_apb_completer_timing_policy(\@body, $source_label, $name, $transfer_name);
        } else {
            confess "Error: .ppif (apb-completer $name (transfer $transfer_name ...)) has unsupported clause '($head ...)'\n";
        }
    }

    for my $required (qw(setup_detect wait_cycles read write unmapped_address)) {
        my $clause = $required;
        $clause =~ s/_/-/g;
        confess "Error: .ppif (apb-completer $name (transfer $transfer_name ...)) is missing required ($clause ...) clause\n"
            unless exists $transfer{$required};
    }

    return \%transfer;
}

sub _parse_apb_completer_timing_policy($items, $source_label, $name, $transfer_name) {
    my %policy;
    for my $clause (@$items) {
        my ($head, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (apb-completer $name (transfer $transfer_name (timing-policy ...))) has duplicate ($head ...) clause\n"
            if exists $policy{$head};
        if ($head eq 'setup-admission') {
            confess "Error: .ppif (apb-completer $name (transfer $transfer_name (timing-policy (setup-admission ...)))) requires exactly one scalar policy value\n"
                unless @body == 1 && !ref($body[0]);
            confess "Error: .ppif (apb-completer $name (transfer $transfer_name ...)) timing-policy supports only (setup-admission adjacent) in this slice\n"
                unless $body[0] eq 'adjacent';
            $policy{setup_admission} = $body[0];
        } else {
            confess "Error: .ppif (apb-completer $name (transfer $transfer_name (timing-policy ...))) has unsupported clause '($head ...)'\n";
        }
    }

    confess "Error: .ppif (apb-completer $name (transfer $transfer_name (timing-policy ...))) is missing required (setup-admission ...) clause\n"
        unless exists $policy{setup_admission};

    return \%policy;
}

sub _parse_apb_composition($body, $source_label) {
    confess "Error: .ppif (apb-composition ...) requires a scalar object name\n"
        unless @$body >= 1 && !ref($body->[0]) && length($body->[0]);

    my $name = $body->[0];
    my %contract = (
        kind => 'apb_composition',
        name => $name,
    );
    my %seen;
    for my $clause (@{$body}[1 .. $#$body]) {
        my ($head, @items) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (apb-composition $name ...) has duplicate ($head ...) clause\n"
            if $seen{$head}++;

        if ($head =~ /\A(?:role|clock)\z/) {
            confess "Error: .ppif (apb-composition $name ($head ...)) requires exactly one scalar value\n"
                unless @items == 1 && !ref($items[0]);
            $contract{$head} = $items[0];
        } elsif ($head eq 'reset') {
            $contract{reset} = _parse_reset(\@items, $source_label);
        } elsif ($head eq 'children') {
            $contract{children} = _parse_apb_composition_children_block(\@items, $source_label, $name);
        } elsif ($head eq 'address-map') {
            $contract{address_map} = _parse_apb_composition_address_map_block(\@items, $source_label, $name);
        } elsif ($head eq 'decode') {
            $contract{decode} = _parse_apb_composition_decode_block(\@items, $source_label, $name);
        } elsif ($head eq 'wiring') {
            $contract{wiring} = _parse_apb_composition_wiring_block(\@items, $source_label, $name);
        } else {
            confess "Error: .ppif (apb-composition $name ...) has unsupported clause '($head ...)'\n";
        }
    }

    for my $required (qw(role clock reset children wiring)) {
        confess "Error: .ppif (apb-composition $name ...) is missing required ($required ...) clause\n"
            unless exists $contract{$required};
    }

    return \%contract;
}

sub _parse_apb_composition_children_block($items, $source_label, $name) {
    my %children;
    my @peripherals;

    for my $clause (@$items) {
        my ($head, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (apb-composition $name (children ...)) supports only (requester INSTANCE OBJECT), (completer INSTANCE OBJECT), and (peripheral INSTANCE OBJECT)\n"
            unless $head =~ /\A(?:requester|completer|peripheral)\z/;
        confess "Error: .ppif (apb-composition $name (children ...)) has duplicate ($head ...) clause\n"
            if $head ne 'peripheral' && exists $children{$head};
        confess "Error: .ppif (apb-composition $name (children ($head ...))) requires exactly instance and object scalar names\n"
            unless @body == 2 && !ref($body[0]) && length($body[0]) && !ref($body[1]) && length($body[1]);
        my $child = {
            instance_name => $body[0],
            object_name   => $body[1],
        };
        if ($head eq 'peripheral') {
            push @peripherals, $child;
        } else {
            $children{$head} = $child;
        }
    }

    confess "Error: .ppif (apb-composition $name (children ...)) cannot mix fixed (completer ...) with multi-peripheral (peripheral ...) entries\n"
        if exists($children{completer}) && @peripherals;
    $children{peripherals} = \@peripherals
        if @peripherals;

    for my $required (qw(requester)) {
        confess "Error: .ppif (apb-composition $name (children ...)) is missing required ($required ...) clause\n"
            unless exists $children{$required};
    }
    confess "Error: .ppif (apb-composition $name (children ...)) is missing required (completer ...) clause or selected multi-peripheral (peripheral ...) entries\n"
        unless exists($children{completer}) || @peripherals;

    return \%children;
}

sub _parse_apb_composition_address_map_block($items, $source_label, $name) {
    confess "Error: .ppif (apb-composition $name (address-map ...)) requires a scalar address-map name\n"
        unless @$items >= 1 && !ref($items->[0]) && length($items->[0]);

    my $map_name = $items->[0];
    my @windows;
    for my $clause (@{$items}[1 .. $#$items]) {
        my ($head, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (apb-composition $name (address-map $map_name ...)) supports only (window INSTANCE ...)\n"
            unless $head eq 'window';
        push @windows, _parse_apb_composition_address_window(\@body, $source_label, $name, $map_name);
    }

    confess "Error: .ppif (apb-composition $name (address-map $map_name ...)) requires at least one (window ...) clause\n"
        unless @windows;

    return {
        name    => $map_name,
        windows => \@windows,
    };
}

sub _parse_apb_composition_address_window($items, $source_label, $name, $map_name) {
    confess "Error: .ppif (apb-composition $name (address-map $map_name (window ...))) requires a scalar peripheral instance name\n"
        unless @$items >= 1 && !ref($items->[0]) && length($items->[0]);

    my $window_name = $items->[0];
    my %window = (name => $window_name);
    my %seen;
    for my $clause (@{$items}[1 .. $#$items]) {
        my ($head, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (apb-composition $name (address-map $map_name (window $window_name ...))) supports only (base NAME width N default V) and (size NAME width N default V)\n"
            unless $head =~ /\A(?:base|size)\z/;
        confess "Error: .ppif (apb-composition $name (address-map $map_name (window $window_name ...))) has duplicate ($head ...) clause\n"
            if $seen{$head}++;
        $window{$head} = _parse_apb_parameter_default_binding(
            \@body,
            $source_label,
            "apb-composition $name address-map $map_name window $window_name $head",
        );
    }

    for my $required (qw(base size)) {
        confess "Error: .ppif (apb-composition $name (address-map $map_name (window $window_name ...))) is missing required ($required ...) clause\n"
            unless exists $window{$required};
    }

    return \%window;
}

sub _parse_apb_parameter_default_binding($body, $source_label, $context) {
    confess "Error: .ppif ($context ...) requires '(NAME width N default V)'\n"
        unless @$body == 5
            && !ref($body->[0])
            && !ref($body->[1])
            && !ref($body->[2])
            && !ref($body->[3])
            && !ref($body->[4])
            && $body->[1] eq 'width'
            && $body->[3] eq 'default';
    return {
        name    => $body->[0],
        width   => $body->[2],
        default => $body->[4],
    };
}

sub _parse_apb_composition_decode_block($items, $source_label, $name) {
    my %allowed = (
        overlap           => 'overlap',
        priority          => 'priority',
        'unmapped-address' => 'unmapped_address',
    );
    my %decode;

    for my $clause (@$items) {
        my ($head, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (apb-composition $name (decode ...)) has unsupported clause '($head ...)'\n"
            unless exists $allowed{$head};
        confess "Error: .ppif (apb-composition $name (decode ...)) has duplicate ($head ...) clause\n"
            if exists $decode{$allowed{$head}};
        $decode{$allowed{$head}} = _parse_apb_scalar_binding(
            \@body,
            $source_label,
            "apb-composition $name decode $head",
        );
    }

    for my $required (qw(overlap priority unmapped_address)) {
        my $clause = $required;
        $clause =~ s/_/-/g;
        confess "Error: .ppif (apb-composition $name (decode ...)) is missing required ($clause ...) clause\n"
            unless exists $decode{$required};
    }

    return \%decode;
}

sub _parse_apb_composition_wiring_block($items, $source_label, $name) {
    confess "Error: .ppif (apb-composition $name (wiring ...)) requires a scalar wiring name\n"
        unless @$items >= 1 && !ref($items->[0]) && length($items->[0]);

    my $wiring_name = $items->[0];
    my %allowed = (
        select       => 'select',
        enable       => 'enable',
        write        => 'write',
        address      => 'address',
        'write-data' => 'write_data',
        protection   => 'protection',
        strobe       => 'strobe',
        ready        => 'ready',
        'read-data'  => 'read_data',
        error        => 'error',
    );
    my %bus;

    for my $clause (@{$items}[1 .. $#$items]) {
        my ($head, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (apb-composition $name (wiring $wiring_name ...)) has unsupported clause '($head ...)'\n"
            unless exists $allowed{$head};
        confess "Error: .ppif (apb-composition $name (wiring $wiring_name ...)) has duplicate ($head ...) clause\n"
            if exists $bus{$allowed{$head}};
        $bus{$allowed{$head}} = $head =~ /\A(?:address|write-data|read-data|protection|strobe)\z/
            ? _parse_apb_width_binding(\@body, $source_label, "apb-composition $name wiring $wiring_name $head")
            : _parse_apb_scalar_binding(\@body, $source_label, "apb-composition $name wiring $wiring_name $head");
    }

    for my $required (qw(select enable write address write_data ready read_data error)) {
        my $clause = $required;
        $clause =~ s/_/-/g;
        confess "Error: .ppif (apb-composition $name (wiring $wiring_name ...)) is missing required ($clause ...) clause\n"
            unless exists $bus{$required};
    }

    return {
        name => $wiring_name,
        bus  => \%bus,
    };
}

sub _parse_manager_capacity_status($body, $source_label) {
    confess "Error: .ppif (manager-capacity-status ...) requires a scalar object name\n"
        unless @$body >= 1 && !ref($body->[0]) && length($body->[0]);

    my $name = $body->[0];
    my %contract = (name => $name);
    my %seen;
    for my $clause (@{$body}[1 .. $#$body]) {
        my ($head, @items) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (manager-capacity-status $name ...) has duplicate ($head ...) clause\n"
            if $seen{$head}++;

        if ($head =~ /\A(?:clock|read-submit|read-complete|write-submit|write-complete|submit-policy|read-max-pending|write-max-pending)\z/) {
            confess "Error: .ppif (manager-capacity-status $name ($head ...)) requires exactly one scalar value\n"
                unless @items == 1 && !ref($items[0]);
            $contract{_manager_capacity_contract_key($head)} = $items[0];
        } elsif ($head eq 'reset') {
            $contract{reset} = _parse_reset(\@items, $source_label);
        } elsif ($head eq 'status') {
            $contract{status} = _parse_manager_capacity_status_outputs(\@items, $source_label, $name);
        } elsif ($head eq 'id-families') {
            $contract{id_families} = _parse_manager_capacity_id_families(\@items, $source_label, $name);
        } elsif ($head eq 'transactions') {
            $contract{transactions} = _parse_manager_capacity_transactions(\@items, $source_label, $name);
        } elsif ($head eq 'auto-id-lifecycle') {
            $contract{auto_id_lifecycle} = _parse_manager_capacity_auto_id_lifecycle(\@items, $source_label, $name);
        } elsif ($head eq 'response-demux') {
            $contract{response_demux} = _parse_manager_capacity_response_demux(\@items, $source_label, $name);
        } elsif ($head eq 'same-id-ordering') {
            $contract{same_id_ordering_policy} = _parse_manager_capacity_same_id_ordering(\@items, $source_label, $name);
        } elsif ($head eq 'read-data') {
            $contract{read_data} = _parse_manager_capacity_read_data(\@items, $source_label, $name);
        } else {
            confess "Error: .ppif (manager-capacity-status $name ...) has unsupported clause '($head ...)'\n";
        }
    }

    for my $required (qw(clock reset read_max_pending write_max_pending submit_policy read_submit read_complete write_submit write_complete)) {
        my $clause = $required;
        $clause =~ s/_/-/g;
        confess "Error: .ppif (manager-capacity-status $name ...) is missing required ($clause ...) clause\n"
            unless exists $contract{$required};
    }

    return \%contract;
}

sub _manager_capacity_contract_key($clause_name) {
    my %map = (
        'clock'             => 'clock',
        'read-submit'       => 'read_submit',
        'read-complete'     => 'read_complete',
        'write-submit'      => 'write_submit',
        'write-complete'    => 'write_complete',
        'submit-policy'     => 'submit_policy',
        'read-max-pending'  => 'read_max_pending',
        'write-max-pending' => 'write_max_pending',
    );
    return $map{$clause_name} if exists $map{$clause_name};
    confess "Internal error: unknown manager capacity/status PPIF clause '$clause_name'\n";
}

sub _parse_manager_capacity_status_outputs($items, $source_label, $name) {
    my %allowed = (
        'read-can-accept'       => 'read_can_accept',
        'write-can-accept'      => 'write_can_accept',
        'read-full'             => 'read_full',
        'write-full'            => 'write_full',
        'pending-reads'         => 'pending_reads',
        'pending-writes'        => 'pending_writes',
        'read-slots-available'  => 'read_slots_available',
        'write-slots-available' => 'write_slots_available',
    );
    my %status;

    for my $clause (@$items) {
        my ($head, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (manager-capacity-status $name (status ...)) has unsupported status clause '($head ...)'\n"
            unless exists $allowed{$head};
        confess "Error: .ppif (manager-capacity-status $name (status ...)) has duplicate ($head ...) clause\n"
            if exists $status{$allowed{$head}};
        confess "Error: .ppif (manager-capacity-status $name (status ($head ...))) requires exactly one scalar value\n"
            unless @body == 1 && !ref($body[0]);
        $status{$allowed{$head}} = $body[0];
    }

    return \%status;
}

sub _parse_manager_capacity_id_families($items, $source_label, $name) {
    confess "Error: .ppif (manager-capacity-status $name (id-families ...)) requires read/write family clauses\n"
        unless @$items;

    my %families;
    for my $clause (@$items) {
        my ($family, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (manager-capacity-status $name (id-families ...)) has unsupported family clause '($family ...)'\n"
            unless $family =~ /\A(?:read|write)\z/;
        confess "Error: .ppif (manager-capacity-status $name (id-families ...)) has duplicate ($family ...) family clause\n"
            if exists $families{$family};
        $families{$family} = _parse_manager_capacity_id_family(\@body, $source_label, $name, $family);
    }

    for my $required (qw(read write)) {
        confess "Error: .ppif (manager-capacity-status $name (id-families ...)) is missing required ($required ...) family clause\n"
            unless exists $families{$required};
    }

    return \%families;
}

sub _parse_manager_capacity_id_family($items, $source_label, $name, $family) {
    my %allowed = (
        'width'       => 'width',
        'request-id'  => 'request_id_signal',
        'response-id' => 'response_id_signal',
    );
    my %entry;

    for my $clause (@$items) {
        my ($head, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (manager-capacity-status $name (id-families ($family ...))) has unsupported clause '($head ...)'\n"
            unless exists $allowed{$head};
        confess "Error: .ppif (manager-capacity-status $name (id-families ($family ...))) has duplicate ($head ...) clause\n"
            if exists $entry{$allowed{$head}};
        confess "Error: .ppif (manager-capacity-status $name (id-families ($family ($head ...)))) requires exactly one scalar value\n"
            unless @body == 1 && !ref($body[0]);
        $entry{$allowed{$head}} = $body[0];
    }

    confess "Error: .ppif (manager-capacity-status $name (id-families ($family ...))) is missing required (width ...) clause\n"
        unless exists $entry{width};
    my $width = _manager_capacity_id_width($entry{width}, $source_label, $name, $family);

    if ($width > 0) {
        for my $required (qw(request_id_signal response_id_signal)) {
            my $clause_name = $required;
            $clause_name =~ s/_signal\z//;
            $clause_name =~ s/_/-/g;
            confess "Error: .ppif (manager-capacity-status $name (id-families ($family ...))) positive width requires ($clause_name ...)\n"
                unless exists $entry{$required};
        }
    } else {
        for my $forbidden (qw(request_id_signal response_id_signal)) {
            my $clause_name = $forbidden;
            $clause_name =~ s/_signal\z//;
            $clause_name =~ s/_/-/g;
            confess "Error: .ppif (manager-capacity-status $name (id-families ($family ...))) zero width must not include ($clause_name ...)\n"
                if exists $entry{$forbidden};
        }
    }

    $entry{width} = $width;
    return \%entry;
}

sub _manager_capacity_id_width($value, $source_label, $name, $family) {
    confess "Error: .ppif (manager-capacity-status $name (id-families ($family (width ...)))) width must be an integer in 0..32\n"
        if ref($value) || !defined($value) || $value !~ /\A(?:0|[1-9][0-9]*)\z/ || $value > 32;
    return int($value);
}

sub _parse_manager_capacity_transactions($items, $source_label, $name) {
    confess "Error: .ppif (manager-capacity-status $name (transactions ...)) requires at least one transaction clause\n"
        unless @$items;

    my @transactions;
    my (%seen_names, %seen_tags);
    for my $clause (@$items) {
        my ($kind, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (manager-capacity-status $name (transactions ...)) has unsupported transaction kind '($kind ...)'\n"
            unless $kind =~ /\A(?:read|write)\z/;
        my $transaction = _parse_manager_capacity_transaction($kind, \@body, $source_label, $name);
        confess "Error: .ppif (manager-capacity-status $name (transactions ...)) has duplicate transaction name '$transaction->{name}'\n"
            if $seen_names{$transaction->{name}}++;
        confess "Error: .ppif (manager-capacity-status $name (transactions ...)) has duplicate transaction tag '$transaction->{tag}'\n"
            if $seen_tags{$transaction->{tag}}++;
        push @transactions, $transaction;
    }

    return \@transactions;
}

sub _parse_manager_capacity_transaction($kind, $items, $source_label, $name) {
    confess "Error: .ppif (manager-capacity-status $name (transactions ($kind ...))) requires a scalar transaction name\n"
        unless @$items >= 1 && !ref($items->[0]) && length($items->[0]);

    my $transaction_name = $items->[0];
    my %transaction = (
        kind => $kind,
        name => $transaction_name,
    );
    my %seen;
    for my $clause (@{$items}[1 .. $#$items]) {
        my ($head, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (manager-capacity-status $name (transactions ($kind $transaction_name ...))) has duplicate ($head ...) clause\n"
            if $seen{$head}++;

        if ($head =~ /\A(?:tag|request|completion)\z/) {
            confess "Error: .ppif (manager-capacity-status $name (transactions ($kind $transaction_name ($head ...)))) requires exactly one scalar value\n"
                unless @body == 1 && !ref($body[0]);
            $transaction{_manager_capacity_transaction_key($head)} = $body[0];
        } elsif ($head eq 'id') {
            $transaction{id} = _parse_manager_capacity_transaction_id(\@body, $source_label, $name, $kind, $transaction_name);
        } else {
            confess "Error: .ppif (manager-capacity-status $name (transactions ($kind $transaction_name ...))) has unsupported clause '($head ...)'\n";
        }
    }

    for my $required (qw(tag request_event completion_event id)) {
        my $clause = $required;
        $clause =~ s/_event\z//;
        confess "Error: .ppif (manager-capacity-status $name (transactions ($kind $transaction_name ...))) is missing required ($clause ...) clause\n"
            unless exists $transaction{$required};
    }

    return \%transaction;
}

sub _manager_capacity_transaction_key($clause_name) {
    my %map = (
        'tag'        => 'tag',
        'request'    => 'request_event',
        'completion' => 'completion_event',
    );
    return $map{$clause_name} if exists $map{$clause_name};
    confess "Internal error: unknown manager capacity/status transaction PPIF clause '$clause_name'\n";
}

sub _parse_manager_capacity_transaction_id($items, $source_label, $name, $kind, $transaction_name) {
    confess "Error: .ppif (manager-capacity-status $name (transactions ($kind $transaction_name (id ...)))) requires (id auto), (id dynamic), or (id (value N))\n"
        unless @$items == 1;

    my $id = $items->[0];
    return { policy => 'auto' }
        if !ref($id) && $id eq 'auto';
    return { policy => 'dynamic' }
        if !ref($id) && $id eq 'dynamic';

    confess "Error: .ppif (manager-capacity-status $name (transactions ($kind $transaction_name (id ...)))) requires (id auto), (id dynamic), or (id (value N))\n"
        unless ref($id) eq 'ARRAY' && @$id == 2 && ($id->[0] // '') eq 'value' && !ref($id->[1]);

    my $value = $id->[1];
    confess "Error: .ppif (manager-capacity-status $name (transactions ($kind $transaction_name (id (value ...))))) value must be an unsigned integer\n"
        unless defined($value) && $value =~ /\A(?:0|[1-9][0-9]*)\z/;

    return { value => int($value) };
}

sub _parse_manager_capacity_auto_id_lifecycle($items, $source_label, $name) {
    confess "Error: .ppif (manager-capacity-status $name (auto-id-lifecycle ...)) requires read/write family clauses\n"
        unless @$items;

    my %families;
    for my $clause (@$items) {
        my ($family, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (manager-capacity-status $name (auto-id-lifecycle ...)) has unsupported family clause '($family ...)'\n"
            unless $family =~ /\A(?:read|write)\z/;
        confess "Error: .ppif (manager-capacity-status $name (auto-id-lifecycle ...)) has duplicate ($family ...) family clause\n"
            if exists $families{$family};
        $families{$family} = _parse_manager_capacity_auto_id_lifecycle_family(\@body, $source_label, $name, $family);
    }

    return \%families;
}

sub _parse_manager_capacity_auto_id_lifecycle_family($items, $source_label, $name, $family) {
    my %entry;
    for my $clause (@$items) {
        next unless defined $clause;
        my ($head, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (manager-capacity-status $name (auto-id-lifecycle ($family ...))) has unsupported clause '($head ...)'\n"
            unless $head eq 'pool';
        confess "Error: .ppif (manager-capacity-status $name (auto-id-lifecycle ($family ...))) has duplicate (pool ...) clause\n"
            if exists $entry{pool};
        $entry{pool} = _parse_manager_capacity_auto_id_pool(\@body, $name, $family);
    }

    confess "Error: .ppif (manager-capacity-status $name (auto-id-lifecycle ($family ...))) is missing required (pool ...) clause\n"
        unless exists $entry{pool};

    return \%entry;
}

sub _parse_manager_capacity_auto_id_pool($items, $name, $family) {
    confess "Error: .ppif (manager-capacity-status $name (auto-id-lifecycle ($family (pool ...)))) pool supports 1..4 unsigned integer values\n"
        unless @$items >= 1 && @$items <= 4;

    my (%seen, @pool);
    for my $value (@$items) {
        confess "Error: .ppif (manager-capacity-status $name (auto-id-lifecycle ($family (pool ...)))) pool value must be an unsigned integer\n"
            if ref($value) || !defined($value) || $value !~ /\A(?:0|[1-9][0-9]*)\z/;
        my $id = int($value);
        confess "Error: .ppif (manager-capacity-status $name (auto-id-lifecycle ($family (pool ...)))) pool duplicates ID value $id\n"
            if $seen{$id}++;
        push @pool, $id;
    }

    return \@pool;
}

sub _parse_manager_capacity_same_id_ordering($items, $source_label, $name) {
    confess "Error: .ppif (manager-capacity-status $name (same-id-ordering ...)) requires at least one read/write family clause\n"
        unless @$items;

    my %families;
    for my $clause (@$items) {
        my ($family, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (manager-capacity-status $name (same-id-ordering ...)) has unsupported family clause '($family ...)'; this slice supports (read ...) and (write ...)\n"
            unless $family =~ /\A(?:read|write)\z/;
        confess "Error: .ppif (manager-capacity-status $name (same-id-ordering ...)) has duplicate ($family ...) family clause\n"
            if exists $families{$family};
        $families{$family} = _parse_manager_capacity_same_id_ordering_family(\@body, $source_label, $name, $family);
    }

    return \%families;
}

sub _parse_manager_capacity_same_id_ordering_family($items, $source_label, $name, $family) {
    my %entry;
    for my $clause (@$items) {
        next unless defined $clause;
        my ($head, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (manager-capacity-status $name (same-id-ordering ($family ...))) has unsupported clause '($head ...)'\n"
            unless $head =~ /\A(?:concrete-id-reuse|dynamic-id-reuse)\z/;

        if ($head eq 'concrete-id-reuse') {
            confess "Error: .ppif (manager-capacity-status $name (same-id-ordering ($family ...))) has duplicate (concrete-id-reuse ...) clause\n"
                if exists $entry{concrete_id_reuse};
            confess "Error: .ppif (manager-capacity-status $name (same-id-ordering ($family (concrete-id-reuse ...)))) requires exactly one scalar value\n"
                unless @body == 1 && !ref($body[0]);
            confess "Error: .ppif (manager-capacity-status $name (same-id-ordering ($family (concrete-id-reuse ...)))) supports only reject or issue-order-queue in this slice\n"
                unless $body[0] =~ /\A(?:reject|issue-order-queue)\z/;
            $entry{concrete_id_reuse} = $body[0];
            next;
        }

        confess "Error: .ppif (manager-capacity-status $name (same-id-ordering ($family ...))) has duplicate (dynamic-id-reuse ...) clause\n"
            if exists $entry{dynamic_id_reuse};
        confess "Error: .ppif (manager-capacity-status $name (same-id-ordering ($family (dynamic-id-reuse ...)))) requires exactly one scalar value\n"
            unless @body == 1 && !ref($body[0]);
        confess "Error: .ppif (manager-capacity-status $name (same-id-ordering ($family (dynamic-id-reuse ...)))) supports only reject or issue-order-queue in this slice\n"
            unless $body[0] =~ /\A(?:reject|issue-order-queue)\z/;
        $entry{dynamic_id_reuse} = $body[0];
    }

    confess "Error: .ppif (manager-capacity-status $name (same-id-ordering ($family ...))) requires at least one (concrete-id-reuse ...) or (dynamic-id-reuse ...) clause\n"
        unless exists($entry{concrete_id_reuse}) || exists($entry{dynamic_id_reuse});

    return \%entry;
}

sub _parse_manager_capacity_response_demux($items, $source_label, $name) {
    confess "Error: .ppif (manager-capacity-status $name (response-demux ...)) requires at least one read/write family clause\n"
        unless @$items;

    my %families;
    for my $clause (@$items) {
        my ($family, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (manager-capacity-status $name (response-demux ...)) has unsupported family clause '($family ...)'; this slice supports (read ...) and (write ...)\n"
            unless $family =~ /\A(?:read|write)\z/;
        confess "Error: .ppif (manager-capacity-status $name (response-demux ...)) has duplicate ($family ...) family clause\n"
            if exists $families{$family};
        $families{$family} = $family eq 'write'
            ? _parse_manager_capacity_response_demux_write(\@body, $source_label, $name)
            : _parse_manager_capacity_response_demux_read(\@body, $source_label, $name);
    }

    return \%families;
}

sub _parse_manager_capacity_response_demux_write($items, $source_label, $name) {
    my %allowed = (
        'response-event'         => 'response_event',
        'transaction-completion' => 'transaction_completion',
    );
    my %entry;

    for my $clause (@$items) {
        my ($head, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (manager-capacity-status $name (response-demux (write ...))) has unsupported clause '($head ...)'\n"
            unless exists $allowed{$head};
        confess "Error: .ppif (manager-capacity-status $name (response-demux (write ...))) has duplicate ($head ...) clause\n"
            if exists $entry{$allowed{$head}};
        confess "Error: .ppif (manager-capacity-status $name (response-demux (write ($head ...)))) requires exactly one scalar value\n"
            unless @body == 1 && !ref($body[0]);
        $entry{$allowed{$head}} = $body[0];
    }

    confess "Error: .ppif (manager-capacity-status $name (response-demux (write ...))) is missing required (response-event ...) clause\n"
        unless exists $entry{response_event};
    confess "Error: .ppif (manager-capacity-status $name (response-demux (write ...))) is missing required (transaction-completion ...) clause\n"
        unless exists $entry{transaction_completion};
    confess "Error: .ppif (manager-capacity-status $name (response-demux (write (transaction-completion ...)))) supports only generated in this slice\n"
        unless $entry{transaction_completion} eq 'generated';

    return \%entry;
}

sub _parse_manager_capacity_response_demux_read($items, $source_label, $name) {
    my %allowed = (
        'response-event'         => 'response_event',
        'response-scope'         => 'response_scope',
        'last-signal'            => 'last_signal',
        'transaction-completion' => 'transaction_completion',
    );
    my %entry;

    for my $clause (@$items) {
        my ($head, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (manager-capacity-status $name (response-demux (read ...))) has unsupported clause '($head ...)'\n"
            unless exists $allowed{$head};
        confess "Error: .ppif (manager-capacity-status $name (response-demux (read ...))) has duplicate ($head ...) clause\n"
            if exists $entry{$allowed{$head}};
        if ($head eq 'last-signal') {
            my ($signal, $width) = _parse_manager_capacity_response_demux_last_signal(\@body, $source_label, $name);
            $entry{last_signal} = $signal;
            $entry{last_signal_width} = $width;
        } else {
            confess "Error: .ppif (manager-capacity-status $name (response-demux (read ($head ...)))) requires exactly one scalar value\n"
                unless @body == 1 && !ref($body[0]);
            $entry{$allowed{$head}} = $body[0];
        }
    }

    confess "Error: .ppif (manager-capacity-status $name (response-demux (read ...))) is missing required (response-event ...) clause\n"
        unless exists $entry{response_event};
    confess "Error: .ppif (manager-capacity-status $name (response-demux (read ...))) is missing required (response-scope ...) clause\n"
        unless exists $entry{response_scope};
    confess "Error: .ppif (manager-capacity-status $name (response-demux (read ...))) is missing required (transaction-completion ...) clause\n"
        unless exists $entry{transaction_completion};
    confess "Error: .ppif (manager-capacity-status $name (response-demux (read (response-scope ...)))) supports only single-beat or burst-last in this slice\n"
        unless $entry{response_scope} =~ /\A(?:single-beat|burst-last)\z/;
    confess "Error: .ppif (manager-capacity-status $name (response-demux (read ...))) single-beat response-scope must not include (last-signal ...)\n"
        if $entry{response_scope} eq 'single-beat' && exists $entry{last_signal};
    confess "Error: .ppif (manager-capacity-status $name (response-demux (read ...))) burst-last response-scope requires exactly one (last-signal NAME (width 1)) clause\n"
        if $entry{response_scope} eq 'burst-last' && !exists $entry{last_signal};
    confess "Error: .ppif (manager-capacity-status $name (response-demux (read (transaction-completion ...)))) supports only generated in this slice\n"
        unless $entry{transaction_completion} eq 'generated';

    return \%entry;
}

sub _parse_manager_capacity_response_demux_last_signal($items, $source_label, $name) {
    confess "Error: .ppif (manager-capacity-status $name (response-demux (read (last-signal ...)))) requires (NAME (width 1))\n"
        unless @$items == 2 && !ref($items->[0]) && length($items->[0]) && ref($items->[1]) eq 'ARRAY';

    my $signal = $items->[0];
    my ($width_head, @width_body) = _clause_parts($items->[1], $source_label);
    confess "Error: .ppif (manager-capacity-status $name (response-demux (read (last-signal ...)))) requires (NAME (width 1))\n"
        unless $width_head eq 'width' && @width_body == 1 && !ref($width_body[0]);
    my $width = $width_body[0];
    confess "Error: .ppif (manager-capacity-status $name (response-demux (read (last-signal ...)))) width must be 1 in this slice\n"
        unless defined($width) && $width =~ /\A[1-9][0-9]*\z/ && int($width) == 1;

    return ($signal, int($width));
}

sub _parse_manager_capacity_read_data($items, $source_label, $name) {
    confess "Error: .ppif (manager-capacity-status $name (read-data ...)) requires one read family clause\n"
        unless @$items;

    my %families;
    for my $clause (@$items) {
        my ($family, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (manager-capacity-status $name (read-data ...)) has unsupported family clause '($family ...)'; this slice supports (read ...)\n"
            unless $family eq 'read';
        confess "Error: .ppif (manager-capacity-status $name (read-data ...)) has duplicate (read ...) family clause\n"
            if exists $families{read};
        $families{read} = _parse_manager_capacity_read_data_read(\@body, $source_label, $name);
    }

    confess "Error: .ppif (manager-capacity-status $name (read-data ...)) is missing required (read ...) family clause\n"
        unless exists $families{read};

    return \%families;
}

sub _parse_manager_capacity_read_data_read($items, $source_label, $name) {
    my %allowed = (
        'capture-scope'     => 'capture_scope',
        'completion-source' => 'completion_source',
        'data-signal'       => 'data_signal',
        'status-signal'     => 'status_signal',
        'status-policy'     => 'status_policy',
        'status-aggregation' => 'status_aggregation',
        'interleaving'      => 'interleaving',
        'burst-length'      => 'burst_length',
    );
    my %entry;
    my @transactions;
    my (%seen, %seen_transactions);

    for my $clause (@$items) {
        my ($head, @body) = _clause_parts($clause, $source_label);
        if ($head eq 'transaction') {
            my $transaction = _parse_manager_capacity_read_data_transaction(\@body, $source_label, $name);
            confess "Error: .ppif (manager-capacity-status $name (read-data (read ...))) has duplicate transaction '$transaction->{transaction}'\n"
                if $seen_transactions{$transaction->{transaction}}++;
            push @transactions, $transaction;
            next;
        }

        confess "Error: .ppif (manager-capacity-status $name (read-data (read ...))) has unsupported clause '($head ...)'\n"
            unless exists $allowed{$head};
        confess "Error: .ppif (manager-capacity-status $name (read-data (read ...))) has duplicate ($head ...) clause\n"
            if $seen{$head}++;

        if ($head =~ /\A(?:capture-scope|completion-source|status-policy|interleaving)\z/) {
            confess "Error: .ppif (manager-capacity-status $name (read-data (read ($head ...)))) requires exactly one scalar value\n"
                unless @body == 1 && !ref($body[0]);
            $entry{$allowed{$head}} = $body[0];
        } elsif ($head eq 'data-signal') {
            my ($signal, $width) = _parse_manager_capacity_read_data_signal_width(
                $head,
                \@body,
                $source_label,
                $name,
            );
            $entry{data_signal} = $signal;
            $entry{data_width} = $width;
        } elsif ($head eq 'status-signal') {
            my ($signal, $width) = _parse_manager_capacity_read_data_signal_width(
                $head,
                \@body,
                $source_label,
                $name,
            );
            confess "Error: .ppif (manager-capacity-status $name (read-data (read (status-signal ...)))) status width must be 2 in this slice\n"
                unless $width == 2;
            $entry{status_signal} = $signal;
            $entry{status_width} = $width;
        } elsif ($head eq 'status-aggregation') {
            $entry{status_aggregation} = _parse_manager_capacity_read_data_status_aggregation(\@body, $source_label, $name);
        } elsif ($head eq 'burst-length') {
            $entry{burst_length} = _parse_manager_capacity_read_data_burst_length(\@body, $source_label, $name);
        }
    }

    for my $required (qw(capture_scope completion_source data_signal status_signal interleaving)) {
        my $clause = $required;
        $clause =~ s/_/-/g;
        confess "Error: .ppif (manager-capacity-status $name (read-data (read ...))) is missing required ($clause ...) clause\n"
            unless exists $entry{$required};
    }
    confess "Error: .ppif (manager-capacity-status $name (read-data (read ...))) requires at least one transaction clause\n"
        unless @transactions;
    confess "Error: .ppif (manager-capacity-status $name (read-data (read (capture-scope ...)))) supports only single-beat, last-beat, or multi-beat in this slice\n"
        unless $entry{capture_scope} =~ /\A(?:single-beat|last-beat|multi-beat)\z/;
    confess "Error: .ppif (manager-capacity-status $name (read-data (read (completion-source ...)))) supports only response-demux in this slice\n"
        unless $entry{completion_source} eq 'response-demux';
    if ($entry{capture_scope} eq 'single-beat') {
        confess "Error: .ppif (manager-capacity-status $name (read-data (read (status-policy ...)))) is only supported with capture-scope last-beat in this slice\n"
            if exists $entry{status_policy};
        confess "Error: .ppif (manager-capacity-status $name (read-data (read (burst-length ...)))) is only supported with capture-scope last-beat in this slice\n"
            if exists $entry{burst_length};
        confess "Error: .ppif (manager-capacity-status $name (read-data (read (status-aggregation ...)))) is only supported with capture-scope multi-beat in this slice\n"
            if exists $entry{status_aggregation};
        confess "Error: .ppif (manager-capacity-status $name (read-data (read (interleaving ...)))) supports only single-beat-by-rid with capture-scope single-beat in this slice\n"
            unless $entry{interleaving} eq 'single-beat-by-rid';
        _validate_manager_capacity_read_data_legacy_transactions(\@transactions, $source_label, $name, 'single-beat');
    } elsif ($entry{capture_scope} eq 'last-beat') {
        confess "Error: .ppif (manager-capacity-status $name (read-data (read (status-policy ...)))) capture-scope last-beat requires status-policy last-beat in this slice\n"
            unless exists($entry{status_policy}) && $entry{status_policy} eq 'last-beat';
        confess "Error: .ppif (manager-capacity-status $name (read-data (read (status-aggregation ...)))) is only supported with capture-scope multi-beat in this slice\n"
            if exists $entry{status_aggregation};
        confess "Error: .ppif (manager-capacity-status $name (read-data (read (interleaving ...)))) supports only last-beat-by-rid with capture-scope last-beat in this slice\n"
            unless $entry{interleaving} eq 'last-beat-by-rid';
        _validate_manager_capacity_read_data_legacy_transactions(\@transactions, $source_label, $name, 'last-beat');
    } else {
        confess "Error: .ppif (manager-capacity-status $name (read-data (read (status-policy ...)))) capture-scope multi-beat requires status-policy per-beat in this slice\n"
            unless exists($entry{status_policy}) && $entry{status_policy} eq 'per-beat';
        confess "Error: .ppif (manager-capacity-status $name (read-data (read (interleaving ...)))) supports only multi-beat-by-rid with capture-scope multi-beat in this slice\n"
            unless $entry{interleaving} eq 'multi-beat-by-rid';
        confess "Error: .ppif (manager-capacity-status $name (read-data (read (burst-length ...)))) capture-scope multi-beat requires burst-length metadata in this slice\n"
            unless exists $entry{burst_length};
        confess "Error: .ppif (manager-capacity-status $name (read-data (read (burst-length (validation ...))))) capture-scope multi-beat requires validation runtime-assertion in this slice\n"
            unless $entry{burst_length}{validation} eq 'runtime-assertion';
        _validate_manager_capacity_read_data_multi_beat_transactions(
            \@transactions,
            $source_label,
            $name,
            exists $entry{status_aggregation},
        );
    }

    $entry{transactions} = \@transactions;
    return \%entry;
}

sub _parse_manager_capacity_read_data_status_aggregation($items, $source_label, $name) {
    my %allowed = (
        policy => 'policy',
    );
    my %entry;
    my %seen;

    confess "Error: .ppif (manager-capacity-status $name (read-data (read (status-aggregation ...)))) requires a (policy worst-observed) clause\n"
        unless @$items;

    for my $clause (@$items) {
        my ($head, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (manager-capacity-status $name (read-data (read (status-aggregation ...)))) has unsupported clause '($head ...)'\n"
            unless exists $allowed{$head};
        confess "Error: .ppif (manager-capacity-status $name (read-data (read (status-aggregation ...)))) has duplicate ($head ...) clause\n"
            if $seen{$head}++;
        confess "Error: .ppif (manager-capacity-status $name (read-data (read (status-aggregation ($head ...))))) requires exactly one scalar value\n"
            unless @body == 1 && !ref($body[0]);
        $entry{$allowed{$head}} = $body[0];
    }

    confess "Error: .ppif (manager-capacity-status $name (read-data (read (status-aggregation ...)))) is missing required (policy ...) clause\n"
        unless exists $entry{policy};
    confess "Error: .ppif (manager-capacity-status $name (read-data (read (status-aggregation (policy ...))))) supports only worst-observed in this slice\n"
        unless $entry{policy} eq 'worst-observed';

    return \%entry;
}

sub _parse_manager_capacity_read_data_burst_length($items, $source_label, $name) {
    my %allowed = (
        'source'     => 'source',
        'signal'     => 'signal',
        'encoding'   => 'encoding',
        'capture'    => 'capture',
        'max-beats'  => 'max_beats',
        'validation' => 'validation',
    );
    my %entry;
    my %seen;

    for my $clause (@$items) {
        my ($head, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (manager-capacity-status $name (read-data (read (burst-length ...)))) has unsupported clause '($head ...)'\n"
            unless exists $allowed{$head};
        confess "Error: .ppif (manager-capacity-status $name (read-data (read (burst-length ...)))) has duplicate ($head ...) clause\n"
            if $seen{$head}++;

        if ($head eq 'signal') {
            my ($signal, $width) = _parse_manager_capacity_read_data_burst_length_signal(\@body, $source_label, $name);
            $entry{signal} = $signal;
            $entry{signal_width} = $width;
        } else {
            confess "Error: .ppif (manager-capacity-status $name (read-data (read (burst-length ($head ...))))) requires exactly one scalar value\n"
                unless @body == 1 && !ref($body[0]);
            $entry{$allowed{$head}} = $body[0];
        }
    }

    for my $required (qw(source signal encoding capture max_beats validation)) {
        my $clause = $required;
        $clause =~ s/_/-/g;
        confess "Error: .ppif (manager-capacity-status $name (read-data (read (burst-length ...)))) is missing required ($clause ...) clause\n"
            unless exists $entry{$required};
    }

    confess "Error: .ppif (manager-capacity-status $name (read-data (read (burst-length (source ...))))) supports only arlen in this slice\n"
        unless $entry{source} eq 'arlen';
    confess "Error: .ppif (manager-capacity-status $name (read-data (read (burst-length (signal ...))))) width must be 8 for source arlen in this slice\n"
        unless $entry{signal_width} == 8;
    confess "Error: .ppif (manager-capacity-status $name (read-data (read (burst-length (encoding ...))))) supports only axlen-plus-one in this slice\n"
        unless $entry{encoding} eq 'axlen-plus-one';
    confess "Error: .ppif (manager-capacity-status $name (read-data (read (burst-length (capture ...))))) supports only request in this slice\n"
        unless $entry{capture} eq 'request';
    confess "Error: .ppif (manager-capacity-status $name (read-data (read (burst-length (max-beats ...))))) max-beats must be an integer in 1..256\n"
        unless defined($entry{max_beats}) && $entry{max_beats} =~ /\A[1-9][0-9]*\z/ && int($entry{max_beats}) <= 256;
    $entry{max_beats} = int($entry{max_beats});
    confess "Error: .ppif (manager-capacity-status $name (read-data (read (burst-length (validation ...))))) supports only report-only or runtime-assertion in this slice\n"
        unless $entry{validation} eq 'report-only' || $entry{validation} eq 'runtime-assertion';

    return \%entry;
}

sub _parse_manager_capacity_read_data_burst_length_signal($items, $source_label, $name) {
    confess "Error: .ppif (manager-capacity-status $name (read-data (read (burst-length (signal ...))))) requires (NAME (width 8))\n"
        unless @$items == 2 && !ref($items->[0]) && length($items->[0]) && ref($items->[1]) eq 'ARRAY';

    my $signal = $items->[0];
    my ($width_head, @width_body) = _clause_parts($items->[1], $source_label);
    confess "Error: .ppif (manager-capacity-status $name (read-data (read (burst-length (signal ...))))) requires (NAME (width 8))\n"
        unless $width_head eq 'width' && @width_body == 1 && !ref($width_body[0]);
    my $width = $width_body[0];
    confess "Error: .ppif (manager-capacity-status $name (read-data (read (burst-length (signal ...))))) width must be a positive integer\n"
        unless defined($width) && $width =~ /\A[1-9][0-9]*\z/;

    return ($signal, int($width));
}

sub _parse_manager_capacity_read_data_signal_width($head, $items, $source_label, $name) {
    confess "Error: .ppif (manager-capacity-status $name (read-data (read ($head ...)))) requires (NAME (width N))\n"
        unless @$items == 2 && !ref($items->[0]) && ref($items->[1]) eq 'ARRAY';

    my $signal = $items->[0];
    my ($width_head, @width_body) = _clause_parts($items->[1], $source_label);
    confess "Error: .ppif (manager-capacity-status $name (read-data (read ($head ...)))) requires (NAME (width N))\n"
        unless $width_head eq 'width' && @width_body == 1 && !ref($width_body[0]);
    my $width = $width_body[0];
    confess "Error: .ppif (manager-capacity-status $name (read-data (read ($head ...)))) width must be a positive integer\n"
        unless defined($width) && $width =~ /\A[1-9][0-9]*\z/;

    return ($signal, int($width));
}

sub _parse_manager_capacity_read_data_transaction($items, $source_label, $name) {
    confess "Error: .ppif (manager-capacity-status $name (read-data (read (transaction ...)))) requires a scalar transaction name\n"
        unless @$items >= 1 && !ref($items->[0]) && length($items->[0]);

    my $transaction_name = $items->[0];
    my %allowed = (
        'data-output'             => 'data_output',
        'status-output'           => 'status_output',
        'data-output-prefix'      => 'data_output_prefix',
        'status-output-prefix'    => 'status_output_prefix',
        'status-aggregate-output' => 'status_aggregate_output',
        'valid-mask-output'       => 'valid_mask_output',
        'length-output'           => 'length_output',
    );
    my %transaction = (transaction => $transaction_name);
    my %seen;
    for my $clause (@{$items}[1 .. $#$items]) {
        my ($head, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (manager-capacity-status $name (read-data (read (transaction $transaction_name ...)))) has unsupported clause '($head ...)'\n"
            unless exists $allowed{$head};
        confess "Error: .ppif (manager-capacity-status $name (read-data (read (transaction $transaction_name ...)))) has duplicate ($head ...) clause\n"
            if $seen{$head}++;
        confess "Error: .ppif (manager-capacity-status $name (read-data (read (transaction $transaction_name ($head ...))))) requires exactly one scalar value\n"
            unless @body == 1 && !ref($body[0]);
        $transaction{$allowed{$head}} = $body[0];
    }

    return \%transaction;
}

sub _validate_manager_capacity_read_data_legacy_transactions($transactions, $source_label, $name, $capture_scope) {
    for my $transaction (@$transactions) {
        for my $field (qw(data_output status_output)) {
            my $clause = $field;
            $clause =~ s/_/-/g;
            confess "Error: .ppif (manager-capacity-status $name (read-data (read (transaction $transaction->{transaction} ...)))) capture-scope $capture_scope is missing required ($clause ...) clause\n"
                unless exists $transaction->{$field};
        }
        for my $field (qw(data_output_prefix status_output_prefix status_aggregate_output valid_mask_output length_output)) {
            next unless exists $transaction->{$field};
            my $clause = $field;
            $clause =~ s/_/-/g;
            confess "Error: .ppif (manager-capacity-status $name (read-data (read (transaction $transaction->{transaction} ...)))) capture-scope $capture_scope does not support ($clause ...) clauses\n";
        }
    }
}

sub _validate_manager_capacity_read_data_multi_beat_transactions($transactions, $source_label, $name, $has_status_aggregation) {
    for my $transaction (@$transactions) {
        for my $field (qw(data_output status_output)) {
            next unless exists $transaction->{$field};
            my $clause = $field;
            $clause =~ s/_/-/g;
            confess "Error: .ppif (manager-capacity-status $name (read-data (read (transaction $transaction->{transaction} ...)))) capture-scope multi-beat does not support legacy ($clause ...) clauses\n";
        }
        if (!$has_status_aggregation && exists $transaction->{status_aggregate_output}) {
            confess "Error: .ppif (manager-capacity-status $name (read-data (read (transaction $transaction->{transaction} (status-aggregate-output ...))))) requires a read-level (status-aggregation ...) clause\n";
        }
        my @required = qw(data_output_prefix status_output_prefix valid_mask_output length_output);
        push @required, 'status_aggregate_output'
            if $has_status_aggregation;
        for my $required (@required) {
            my $clause = $required;
            $clause =~ s/_/-/g;
            confess "Error: .ppif (manager-capacity-status $name (read-data (read (transaction $transaction->{transaction} ...)))) capture-scope multi-beat is missing required ($clause ...) clause\n"
                unless exists $transaction->{$required};
        }
    }
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

sub _is_manager_capacity_status_contract($contract) {
    return ref($contract) eq 'HASH'
        && exists($contract->{read_max_pending})
        && exists($contract->{write_max_pending})
        && exists($contract->{read_submit})
        && exists($contract->{write_submit});
}

sub _is_apb_requester_transfer_contract($contract) {
    return ref($contract) eq 'HASH'
        && ($contract->{kind} // '') eq 'apb_requester_transfer';
}

sub _is_apb_completer_contract($contract) {
    return ref($contract) eq 'HASH'
        && ($contract->{kind} // '') eq 'apb_completer';
}

sub _is_apb_composition_contract($contract) {
    return ref($contract) eq 'HASH'
        && ($contract->{kind} // '') eq 'apb_composition';
}

sub _is_ahb_requester_contract($contract) {
    return ref($contract) eq 'HASH'
        && ($contract->{kind} // '') eq 'ahb_requester';
}

sub _is_ahb_interconnect_contract($contract) {
    return ref($contract) eq 'HASH'
        && ($contract->{kind} // '') eq 'ahb_interconnect';
}

sub _is_selected_ahb_profile_alias_interconnect_contract($contract) {
    return 0 unless _is_ahb_interconnect_contract($contract);
    my $subordinate_count = _ahb_interconnect_subordinate_count($contract);
    return $subordinate_count == 1 || $subordinate_count == 2;
}

sub _ahb_interconnect_subordinate_count($contract) {
    return 0 unless _is_ahb_interconnect_contract($contract);
    return scalar @{$contract->{subordinates}}
        if ref($contract->{subordinates}) eq 'ARRAY';
    return ref($contract->{subordinate}) eq 'HASH' ? 1 : 0;
}

sub _is_ahb_subordinate_contract($contract) {
    return ref($contract) eq 'HASH'
        && ($contract->{kind} // '') eq 'ahb_subordinate';
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

    my $hdl_entry = _build_bundle_hdl_entry(
        bundle          => $bundle,
        ial0_items      => \@ial0_items,
        channel_reports => \@channel_reports,
        fsm_files       => \%all_fsm_files,
    );
    $all_fsm_files{$hdl_entry->{entry_artifact}} = $hdl_entry->{text};
    push @ial0_items, $hdl_entry->{ial0_item};

    my $report = _build_bundle_report(
        bundle          => $bundle,
        ial1_items      => \@ial1_items,
        ial0_items      => \@ial0_items,
        channel_reports => \@channel_reports,
        hdl_entry       => $hdl_entry->{report_entry},
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
    my $hdl_entry = $args{hdl_entry};

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
                defined($hdl_entry)
                    ? %$hdl_entry
                    : (
                        selected => 0,
                        reason   => 'multi-channel PPIF bundle has no wrapper/top actor or explicit HDL entry selection in this slice',
                    ),
            },
        },
        unsupported_residue => _bundle_unsupported_residue($bundle),
    };
}

sub _bundle_unsupported_residue($bundle) {
    my $protocol = lc($bundle->{protocol} // '');
    return [
        {
            id     => 'valid_ready_profile_bundle_behavior_outside_monitor',
            detail => 'The generic valid-ready bundle is monitor-only; producer/consumer drive policy, backpressure policy, coordination, and protocol-specific ordering remain outside this bundle.',
        },
    ] if $protocol eq 'valid-ready';

    return [
        {
            id     => 'axi_manager_concurrency',
            detail => 'Transaction IDs, outstanding windows, bursts, response matching, and channel dependency rules remain outside this monitor-only bundle slice.',
        },
    ];
}

sub _build_bundle_hdl_entry(%args) {
    my $bundle = $args{bundle};
    my @ial0_items = @{$args{ial0_items} || []};
    my @channel_reports = @{$args{channel_reports} || []};
    my $fsm_files = $args{fsm_files} || {};

    my $module_name = _sanitized_hdl_identifier($bundle->{intent_name}, 'protocol-platform-intent name');
    my $entry_artifact = "$module_name.fsm";
    confess "Error: .ppif Valid-Ready bundle generated duplicate aggregate .fsm artifact '$entry_artifact'\n"
        if exists $fsm_files->{$entry_artifact};

    my ($clock, $reset) = _shared_bundle_system_ports(\@channel_reports);
    my @port_specs = _bundle_wrapper_port_specs($clock, $reset, \@channel_reports);
    my @channel_entry_artifacts = map { $_->{entry_artifact} } @ial0_items;

    my @lines = (
        "(?top:$module_name",
        "  (?ports:public_io",
        (map { "    " . _composition_port_token($_) } @port_specs),
        "  )",
        (map {
            my $child = $_;
            $child =~ s/\.fsm\z//;
            "  (?fsmc:$child)"
        } @channel_entry_artifacts),
        ")",
        "",
    );

    for my $artifact (@channel_entry_artifacts) {
        confess "Error: .ppif Valid-Ready bundle is missing generated child .fsm artifact '$artifact'\n"
            unless exists $fsm_files->{$artifact};
        push @lines, $fsm_files->{$artifact};
        push @lines, "";
    }

    return {
        entry_artifact => $entry_artifact,
        text           => join("\n", @lines),
        ial0_item      => {
            object_name     => $bundle->{intent_name},
            channel         => 'bundle',
            kind            => 'aggregate_wrapper_top',
            format          => 'fsm',
            files           => [$entry_artifact],
            entry_artifact  => $entry_artifact,
            child_artifacts => \@channel_entry_artifacts,
        },
        report_entry   => {
            selected        => 1,
            kind            => 'aggregate_wrapper_top',
            format          => 'fsm',
            module_name     => $module_name,
            entry_artifact  => $entry_artifact,
            child_artifacts => \@channel_entry_artifacts,
            port_policy     => {
                shared_system_ports => {
                    clock => $clock,
                    reset => _clone_jsonish($reset),
                },
                data_binding => 'composition_c4_declared_connect_by_name',
            },
        },
    };
}

sub _shared_bundle_system_ports($channel_reports) {
    confess "Error: .ppif Valid-Ready bundle requires at least two channel reports before wrapper generation\n"
        unless ref($channel_reports) eq 'ARRAY' && @$channel_reports >= 2;

    my $first_bindings = $channel_reports->[0]{valid_ready_channel_report}{bindings} || {};
    my $clock = $first_bindings->{clock};
    my $reset = $first_bindings->{reset};
    confess "Error: .ppif Valid-Ready bundle wrapper requires channel clock metadata\n"
        unless defined($clock) && !ref($clock) && length($clock);
    confess "Error: .ppif Valid-Ready bundle wrapper requires channel reset metadata\n"
        unless ref($reset) eq 'HASH';

    for my $entry (@$channel_reports) {
        my $bindings = $entry->{valid_ready_channel_report}{bindings} || {};
        my $object_name = $entry->{object_name} // '<unknown>';
        confess "Error: .ppif Valid-Ready bundle wrapper requires shared clock '$clock'; channel '$object_name' uses '$bindings->{clock}'\n"
            unless defined($bindings->{clock}) && !ref($bindings->{clock}) && $bindings->{clock} eq $clock;
        confess "Error: .ppif Valid-Ready bundle wrapper requires shared reset '$reset->{signal}'; channel '$object_name' has incompatible reset policy\n"
            unless _same_reset_policy($reset, $bindings->{reset});
    }

    return ($clock, _clone_jsonish($reset));
}

sub _same_reset_policy($left, $right) {
    return 0 unless ref($left) eq 'HASH' && ref($right) eq 'HASH';
    for my $field (qw(signal active_low async)) {
        return 0 unless defined($left->{$field}) && defined($right->{$field});
        return 0 unless $left->{$field} eq $right->{$field};
    }
    return 1;
}

sub _bundle_wrapper_port_specs($clock, $reset, $channel_reports) {
    my @ports;
    my %seen;
    _push_bundle_wrapper_port(\@ports, \%seen, {
        name      => $clock,
        direction => 'input',
        width     => 1,
        system    => 'clock',
    });
    _push_bundle_wrapper_port(\@ports, \%seen, {
        name      => $reset->{signal},
        direction => 'input',
        width     => 1,
        system    => 'reset',
    });

    for my $entry (@$channel_reports) {
        my $object_name = $entry->{object_name} // '<unknown>';
        my $report = $entry->{valid_ready_channel_report} || {};
        my $bindings = $report->{bindings} || {};
        my $entry_artifact = $report->{generated_artifacts}{ial0}{files}[0];
        confess "Error: .ppif Valid-Ready bundle channel '$object_name' is missing its generated .fsm entry artifact\n"
            unless defined($entry_artifact) && !ref($entry_artifact) && $entry_artifact =~ /\.fsm\z/;
        my $child_module = $entry_artifact;
        $child_module =~ s/\.fsm\z//;

        _push_bundle_wrapper_port(\@ports, \%seen, {
            name      => $bindings->{valid},
            direction => 'input',
            width     => 1,
            source    => "$object_name valid",
        });
        _push_bundle_wrapper_port(\@ports, \%seen, {
            name      => $bindings->{ready},
            direction => 'input',
            width     => 1,
            source    => "$object_name ready",
        });
        for my $payload (@{$bindings->{payload} || []}) {
            _push_bundle_wrapper_port(\@ports, \%seen, {
                name      => $payload->{name},
                direction => 'input',
                width     => $payload->{width},
                source    => "$object_name payload",
            });
        }
        _push_bundle_wrapper_port(\@ports, \%seen, {
            name      => "${child_module}_done",
            direction => 'output',
            width     => 1,
            source    => "$object_name generated done",
        });
    }

    return @ports;
}

sub _push_bundle_wrapper_port($ports, $seen, $spec) {
    my $name = $spec->{name};
    confess "Error: .ppif Valid-Ready bundle wrapper encountered a missing port name\n"
        unless defined($name) && !ref($name) && length($name);
    confess "Error: .ppif Valid-Ready bundle wrapper port '$name' is not an HDL identifier\n"
        unless $name =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;

    my $width = $spec->{width};
    confess "Error: .ppif Valid-Ready bundle wrapper port '$name' has invalid width '$width'\n"
        unless defined($width) && !ref($width) && $width =~ /\A[1-9][0-9]*\z/;
    $spec->{width} = int($width);

    if (exists $seen->{$name}) {
        my $prior = $seen->{$name};
        confess "Error: .ppif Valid-Ready bundle wrapper port '$name' conflicts between $prior->{source} and $spec->{source}\n"
            unless ($prior->{system} // '') && ($spec->{system} // '') && $prior->{system} eq $spec->{system};
        return;
    }

    $spec->{source} //= $spec->{system} // 'unknown source';
    $seen->{$name} = $spec;
    push @$ports, $spec;
}

sub _composition_port_token($spec) {
    my $name = $spec->{name};
    my $width = $spec->{width};
    if ($spec->{system}) {
        return $width == 1 ? $name : "$name<$width";
    }

    my $direction = $spec->{direction};
    confess "Error: .ppif Valid-Ready bundle wrapper port '$name' has unsupported direction '$direction'\n"
        unless $direction eq 'input' || $direction eq 'output';
    my $arrow = $direction eq 'output' ? '>' : '<';
    return $width == 1 ? "=$name$arrow" : "=$name$arrow$width";
}

sub _sanitized_hdl_identifier($value, $label) {
    confess "Error: .ppif Valid-Ready bundle wrapper requires scalar $label\n"
        unless defined($value) && !ref($value) && length($value);
    my $identifier = $value;
    $identifier =~ s/[^A-Za-z0-9_]+/_/g;
    $identifier =~ s/\A_+//;
    $identifier =~ s/_+\z//;
    $identifier = "ppif_$identifier" unless $identifier =~ /\A[A-Za-z_]/;
    confess "Error: .ppif Valid-Ready bundle wrapper could not derive an HDL identifier from $label '$value'\n"
        unless $identifier =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
    return $identifier;
}

sub _clone_jsonish($value) {
    return undef unless defined $value;
    return [map { _clone_jsonish($_) } @$value] if ref($value) eq 'ARRAY';
    return { map { $_ => _clone_jsonish($value->{$_}) } sort keys %$value } if ref($value) eq 'HASH';
    return $value;
}

1;
