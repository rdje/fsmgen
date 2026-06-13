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

sub _contract_from_root($root, $source_label) {
    my (undef, $intent_name, @clauses) = @$root;
    _require_scalar($intent_name, "protocol-platform-intent name", $source_label);

    my ($profile, $source);
    my @channels;
    my @managers;
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
        } elsif ($head eq 'manager-capacity-status') {
            push @managers, _parse_manager_capacity_status(\@body, $source_label);
        } else {
            confess "Error: .ppif source '$source_label' has unsupported top-level clause '($head ...)'\n";
        }
    }

    confess "Error: .ppif source '$source_label' is missing required (profile ...) clause\n"
        unless defined $profile;
    confess "Error: .ppif source '$source_label' is missing required (source ...) clause\n"
        unless defined $source;
    confess "Error: .ppif source '$source_label' is missing required intent object clause, expected (valid-ready-channel ...) or (manager-capacity-status ...)\n"
        unless @channels || @managers;
    confess "Error: .ppif source '$source_label' cannot mix (valid-ready-channel ...) and (manager-capacity-status ...) objects in this slice\n"
        if @channels && @managers;
    confess "Error: .ppif source '$source_label' supports exactly one (manager-capacity-status ...) object in this slice\n"
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
    confess "Error: .ppif (manager-capacity-status $name (transactions ($kind $transaction_name (id ...)))) requires (id auto) or (id (value N))\n"
        unless @$items == 1;

    my $id = $items->[0];
    return { policy => 'auto' }
        if !ref($id) && $id eq 'auto';

    confess "Error: .ppif (manager-capacity-status $name (transactions ($kind $transaction_name (id ...)))) requires (id auto) or (id (value N))\n"
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
        'transaction-completion' => 'transaction_completion',
    );
    my %entry;

    for my $clause (@$items) {
        my ($head, @body) = _clause_parts($clause, $source_label);
        confess "Error: .ppif (manager-capacity-status $name (response-demux (read ...))) has unsupported clause '($head ...)'\n"
            unless exists $allowed{$head};
        confess "Error: .ppif (manager-capacity-status $name (response-demux (read ...))) has duplicate ($head ...) clause\n"
            if exists $entry{$allowed{$head}};
        confess "Error: .ppif (manager-capacity-status $name (response-demux (read ($head ...)))) requires exactly one scalar value\n"
            unless @body == 1 && !ref($body[0]);
        $entry{$allowed{$head}} = $body[0];
    }

    confess "Error: .ppif (manager-capacity-status $name (response-demux (read ...))) is missing required (response-event ...) clause\n"
        unless exists $entry{response_event};
    confess "Error: .ppif (manager-capacity-status $name (response-demux (read ...))) is missing required (response-scope ...) clause\n"
        unless exists $entry{response_scope};
    confess "Error: .ppif (manager-capacity-status $name (response-demux (read ...))) is missing required (transaction-completion ...) clause\n"
        unless exists $entry{transaction_completion};
    confess "Error: .ppif (manager-capacity-status $name (response-demux (read (response-scope ...)))) supports only single-beat in this slice\n"
        unless $entry{response_scope} eq 'single-beat';
    confess "Error: .ppif (manager-capacity-status $name (response-demux (read (transaction-completion ...)))) supports only generated in this slice\n"
        unless $entry{transaction_completion} eq 'generated';

    return \%entry;
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
        'interleaving'      => 'interleaving',
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

        if ($head =~ /\A(?:capture-scope|completion-source|interleaving)\z/) {
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
    confess "Error: .ppif (manager-capacity-status $name (read-data (read (capture-scope ...)))) supports only single-beat in this slice\n"
        unless $entry{capture_scope} eq 'single-beat';
    confess "Error: .ppif (manager-capacity-status $name (read-data (read (completion-source ...)))) supports only response-demux in this slice\n"
        unless $entry{completion_source} eq 'response-demux';
    confess "Error: .ppif (manager-capacity-status $name (read-data (read (interleaving ...)))) supports only single-beat-by-rid in this slice\n"
        unless $entry{interleaving} eq 'single-beat-by-rid';

    $entry{transactions} = \@transactions;
    return \%entry;
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
        'data-output'   => 'data_output',
        'status-output' => 'status_output',
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

    for my $required (qw(data_output status_output)) {
        my $clause = $required;
        $clause =~ s/_/-/g;
        confess "Error: .ppif (manager-capacity-status $name (read-data (read (transaction $transaction_name ...)))) is missing required ($clause ...) clause\n"
            unless exists $transaction{$required};
    }

    return \%transaction;
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
        unsupported_residue => [
            {
                id     => 'axi_manager_concurrency',
                detail => 'Transaction IDs, outstanding windows, bursts, response matching, and channel dependency rules remain outside this monitor-only bundle slice.',
            },
        ],
    };
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
