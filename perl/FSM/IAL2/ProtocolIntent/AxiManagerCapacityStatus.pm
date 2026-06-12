package FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus;

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
    confess "FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->generate expects exactly one contract hash reference\n"
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
        kind  => 'protocol_intent.axi_manager_capacity_status',
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
    confess "FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new must be called with the FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus class invocant\n"
        unless defined($class) && !ref($class) && $class eq 'FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus';
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
    confess "FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->$method must be called on an FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus object\n"
        unless blessed($self) && $self->isa('FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus');
}

sub _normalize_contract($raw) {
    _reject_unsupported_top_level_fields($raw);

    my $name = _required_identifier($raw, 'name');
    my $actor_name = exists($raw->{actor_name})
        ? _identifier_value($raw->{actor_name}, 'actor_name')
        : "${name}_capacity_status";

    my $protocol = lc _required_scalar($raw, 'protocol');
    confess "AXI manager capacity/status IAL2 contract protocol must be axi4 for this first slice\n"
        unless $protocol eq 'axi4';

    my $submit_policy = lc _required_scalar($raw, 'submit_policy');
    confess "AXI manager capacity/status IAL2 contract submit_policy must be try for this first slice\n"
        unless $submit_policy eq 'try';

    my $clock = _required_identifier($raw, 'clock');
    my $reset = _normalize_reset($raw->{reset});
    my $read_max_pending = _required_positive_integer($raw, 'read_max_pending');
    my $write_max_pending = _required_positive_integer($raw, 'write_max_pending');

    my %events = (
        read_submit    => _required_identifier($raw, 'read_submit'),
        read_complete  => _required_identifier($raw, 'read_complete'),
        write_submit   => _required_identifier($raw, 'write_submit'),
        write_complete => _required_identifier($raw, 'write_complete'),
    );

    my %storage = (
        pending_reads  => "${name}_pending_reads_q",
        pending_writes => "${name}_pending_writes_q",
    );

    my %widths = (
        pending_reads  => _counter_width($read_max_pending),
        pending_writes => _counter_width($write_max_pending),
    );

    my $status = _normalize_status_outputs($raw->{status}, $name);
    my $id_families = exists($raw->{id_families})
        ? _normalize_id_families($raw->{id_families})
        : undef;
    my $transactions = exists($raw->{transactions})
        ? _normalize_transactions(
            raw_transactions => $raw->{transactions},
            events           => \%events,
            id_families      => $id_families,
        )
        : undef;

    _reject_forbidden_or_duplicate_names(
        clock        => $clock,
        reset        => $reset->{signal},
        events       => \%events,
        status       => $status,
        storage      => \%storage,
        id_families  => $id_families,
        transactions => $transactions,
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
        name              => $name,
        actor_name        => $actor_name,
        protocol          => $protocol,
        submit_policy     => $submit_policy,
        clock             => $clock,
        reset             => $reset,
        read_max_pending  => $read_max_pending,
        write_max_pending => $write_max_pending,
        events            => \%events,
        status_outputs    => $status,
        id_families       => $id_families,
        transactions      => $transactions,
        storage           => \%storage,
        widths            => \%widths,
        intent_name       => $intent_name,
        source_object_id  => $source_object_id,
        source_anchors    => $anchors,
    };
}

sub _reject_unsupported_top_level_fields($raw) {
    my %allowed = map { $_ => 1 } qw(
        actor_name clock intent_name name protocol read_complete read_max_pending
        read_submit reset source source_object_id status submit_policy id_families
        transactions write_complete write_max_pending write_submit
    );

    for my $field (sort keys %$raw) {
        confess "AXI manager capacity/status IAL2 contract unsupported field '$field' in this first slice\n"
            unless $allowed{$field};
    }
}

sub _required_scalar($raw, $field) {
    confess "AXI manager capacity/status IAL2 contract is missing required scalar field '$field'\n"
        unless exists($raw->{$field});
    return _nonempty_scalar($raw->{$field}, $field);
}

sub _required_identifier($raw, $field) {
    return _identifier_value(_required_scalar($raw, $field), $field);
}

sub _required_positive_integer($raw, $field) {
    confess "AXI manager capacity/status IAL2 contract is missing required positive integer field '$field'\n"
        unless exists($raw->{$field});
    return _positive_integer($raw->{$field}, $field);
}

sub _nonempty_scalar($value, $field) {
    confess "AXI manager capacity/status IAL2 contract field '$field' must be a non-empty scalar\n"
        if !defined($value) || ref($value) || $value eq '';
    return $value;
}

sub _identifier_value($value, $field) {
    confess "AXI manager capacity/status IAL2 contract field '$field' must be an ISF identifier\n"
        unless defined($value) && !ref($value) && $value =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
    return $value;
}

sub _positive_integer($value, $field) {
    confess "AXI manager capacity/status IAL2 contract field '$field' must be a positive integer\n"
        if ref($value) || !defined($value) || $value !~ /\A[1-9][0-9]*\z/;
    return int($value);
}

sub _normalize_reset($raw_reset) {
    confess "AXI manager capacity/status IAL2 contract is missing required reset binding\n"
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
    confess "AXI manager capacity/status IAL2 contract field '$field' must be boolean 0 or 1\n"
        if ref($value) || !defined($value) || ($value ne '0' && $value ne '1');
    return $value ? 1 : 0;
}

sub _normalize_status_outputs($raw_status, $name) {
    my %status = (
        read_can_accept      => "${name}_read_can_accept",
        write_can_accept     => "${name}_write_can_accept",
        read_full            => "${name}_read_full",
        write_full           => "${name}_write_full",
        pending_reads        => "${name}_pending_reads",
        pending_writes       => "${name}_pending_writes",
        read_slots_available => "${name}_read_slots_available",
        write_slots_available => "${name}_write_slots_available",
    );

    if (defined $raw_status) {
        confess "AXI manager capacity/status IAL2 contract field 'status' must be a hash reference\n"
            unless ref($raw_status) eq 'HASH';
        my %allowed = map { $_ => 1 } keys %status;
        for my $field (sort keys %$raw_status) {
            confess "AXI manager capacity/status IAL2 contract status output '$field' is unsupported in this first slice\n"
                unless $allowed{$field};
            $status{$field} = _identifier_value($raw_status->{$field}, "status.$field");
        }
    }

    return \%status;
}

sub _normalize_id_families($raw_id_families) {
    confess "AXI manager capacity/status IAL2 contract field 'id_families' must be a hash reference\n"
        unless ref($raw_id_families) eq 'HASH';

    my %allowed = map { $_ => 1 } qw(read write);
    for my $family (sort keys %$raw_id_families) {
        confess "AXI manager capacity/status IAL2 contract id_families has unsupported family '$family'; supported families: read, write\n"
            unless $allowed{$family};
    }
    for my $required (qw(read write)) {
        confess "AXI manager capacity/status IAL2 contract id_families is missing required '$required' family\n"
            unless exists $raw_id_families->{$required};
    }

    return {
        read  => _normalize_id_family($raw_id_families->{read},  'read'),
        write => _normalize_id_family($raw_id_families->{write}, 'write'),
    };
}

sub _normalize_id_family($raw_family, $family) {
    confess "AXI manager capacity/status IAL2 contract id_families.$family must be a hash reference\n"
        unless ref($raw_family) eq 'HASH';

    my %allowed = map { $_ => 1 } qw(width request_id_signal response_id_signal);
    for my $field (sort keys %$raw_family) {
        confess "AXI manager capacity/status IAL2 contract id_families.$family unsupported field '$field'\n"
            unless $allowed{$field};
    }
    confess "AXI manager capacity/status IAL2 contract id_families.$family is missing required field 'width'\n"
        unless exists $raw_family->{width};

    my $width = _integer_0_to_32($raw_family->{width}, "id_families.$family.width");
    my %family_entry = (
        width   => $width,
        present => $width > 0 ? 1 : 0,
    );

    if ($width > 0) {
        for my $field (qw(request_id_signal response_id_signal)) {
            confess "AXI manager capacity/status IAL2 contract id_families.$family positive width requires field '$field'\n"
                unless exists $raw_family->{$field};
            $family_entry{$field} = _identifier_value($raw_family->{$field}, "id_families.$family.$field");
        }
    } else {
        for my $field (qw(request_id_signal response_id_signal)) {
            confess "AXI manager capacity/status IAL2 contract id_families.$family zero width must not include field '$field'\n"
                if exists $raw_family->{$field};
        }
    }

    return \%family_entry;
}

sub _integer_0_to_32($value, $field) {
    confess "AXI manager capacity/status IAL2 contract field '$field' must be an integer in 0..32\n"
        if ref($value) || !defined($value) || $value !~ /\A(?:0|[1-9][0-9]*)\z/ || $value > 32;
    return int($value);
}

sub _normalize_transactions(%args) {
    my $raw_transactions = $args{raw_transactions};
    confess "AXI manager capacity/status IAL2 contract field 'transactions' must be an array reference\n"
        unless ref($raw_transactions) eq 'ARRAY';
    confess "AXI manager capacity/status IAL2 contract field 'transactions' requires at least one transaction\n"
        unless @$raw_transactions;

    my @normalized;
    my (%seen_names, %seen_tags);
    for my $index (0 .. $#$raw_transactions) {
        my $transaction = _normalize_transaction(
            raw_transaction => $raw_transactions->[$index],
            index           => $index,
            events          => $args{events},
            id_families     => $args{id_families},
        );
        confess "AXI manager capacity/status IAL2 contract transactions[$index] duplicates transaction name '$transaction->{name}'\n"
            if $seen_names{$transaction->{name}}++;
        confess "AXI manager capacity/status IAL2 contract transactions[$index] duplicates transaction tag '$transaction->{tag}'\n"
            if $seen_tags{$transaction->{tag}}++;
        push @normalized, $transaction;
    }

    return \@normalized;
}

sub _normalize_transaction(%args) {
    my $raw = $args{raw_transaction};
    my $index = $args{index};
    confess "AXI manager capacity/status IAL2 contract transactions[$index] must be a hash reference\n"
        unless ref($raw) eq 'HASH';

    my %allowed = map { $_ => 1 } qw(kind name tag request_event completion_event id);
    for my $field (sort keys %$raw) {
        confess "AXI manager capacity/status IAL2 contract transactions[$index] unsupported field '$field'\n"
            unless $allowed{$field};
    }

    for my $field (qw(kind name tag request_event completion_event id)) {
        confess "AXI manager capacity/status IAL2 contract transactions[$index] is missing required field '$field'\n"
            unless exists $raw->{$field};
    }

    my $kind = lc _nonempty_scalar($raw->{kind}, "transactions[$index].kind");
    confess "AXI manager capacity/status IAL2 contract transactions[$index].kind must be read or write\n"
        unless $kind =~ /\A(?:read|write)\z/;

    my $name = _identifier_value($raw->{name}, "transactions[$index].name");
    my $tag = _identifier_value($raw->{tag}, "transactions[$index].tag");
    my $request_event = _identifier_value($raw->{request_event}, "transactions[$index].request_event");
    my $completion_event = _identifier_value($raw->{completion_event}, "transactions[$index].completion_event");

    my $expected_request = $kind eq 'read' ? $args{events}{read_submit} : $args{events}{write_submit};
    my $expected_completion = $kind eq 'read' ? $args{events}{read_complete} : $args{events}{write_complete};
    confess "AXI manager capacity/status IAL2 contract transactions[$index] $kind request_event must reference existing direction-level event '$expected_request'\n"
        unless $request_event eq $expected_request;
    confess "AXI manager capacity/status IAL2 contract transactions[$index] $kind completion_event must reference existing direction-level event '$expected_completion'\n"
        unless $completion_event eq $expected_completion;

    return {
        kind             => $kind,
        name             => $name,
        tag              => $tag,
        request_event    => $request_event,
        completion_event => $completion_event,
        id               => _normalize_transaction_id($raw->{id}, $kind, $index, $args{id_families}),
    };
}

sub _normalize_transaction_id($raw_id, $kind, $index, $id_families) {
    confess "AXI manager capacity/status IAL2 contract transactions[$index].id must be a hash reference\n"
        unless ref($raw_id) eq 'HASH';

    my %allowed = map { $_ => 1 } qw(policy value);
    for my $field (sort keys %$raw_id) {
        confess "AXI manager capacity/status IAL2 contract transactions[$index].id unsupported field '$field'\n"
            unless $allowed{$field};
    }

    if (exists $raw_id->{policy}) {
        confess "AXI manager capacity/status IAL2 contract transactions[$index].id policy must be auto\n"
            unless !ref($raw_id->{policy}) && $raw_id->{policy} eq 'auto';
        confess "AXI manager capacity/status IAL2 contract transactions[$index].id auto policy must not include value\n"
            if exists $raw_id->{value};
        return { policy => 'auto' };
    }

    confess "AXI manager capacity/status IAL2 contract transactions[$index].id requires policy auto or concrete value\n"
        unless exists $raw_id->{value};

    my $value = _unsigned_integer($raw_id->{value}, "transactions[$index].id.value");
    confess "AXI manager capacity/status IAL2 contract transactions[$index] concrete ID requires id_families metadata\n"
        unless ref($id_families) eq 'HASH';

    my $family = $id_families->{$kind};
    confess "AXI manager capacity/status IAL2 contract transactions[$index] concrete $kind ID requires a declared $kind ID family\n"
        unless ref($family) eq 'HASH';
    confess "AXI manager capacity/status IAL2 contract transactions[$index] concrete $kind ID is not allowed when $kind ID-family width is 0\n"
        unless $family->{present};

    my $width = $family->{width};
    my $limit = 2 ** $width;
    confess "AXI manager capacity/status IAL2 contract transactions[$index] concrete $kind ID value $value does not fit width $width\n"
        if $value >= $limit;

    return {
        policy       => 'concrete',
        value        => $value,
        family       => $kind,
        family_width => $width,
        fits         => 1,
    };
}

sub _unsigned_integer($value, $field) {
    confess "AXI manager capacity/status IAL2 contract field '$field' must be an unsigned integer\n"
        if ref($value) || !defined($value) || $value !~ /\A(?:0|[1-9][0-9]*)\z/;
    return int($value);
}

sub _reject_forbidden_or_duplicate_names(%args) {
    my %seen;
    my @groups = (
        [clock   => [$args{clock}]],
        [reset   => [$args{reset}]],
        [events  => [values %{$args{events}}]],
        [status  => [values %{$args{status}}]],
        [storage => [values %{$args{storage}}]],
    );
    push @groups, [id_families => _id_family_signal_names($args{id_families})]
        if defined $args{id_families};
    push @groups, [transactions => _transaction_names_and_tags($args{transactions})]
        if defined $args{transactions};

    for my $group (@groups) {
        my ($kind, $names) = @$group;
        for my $name (@$names) {
            confess "AXI manager capacity/status IAL2 contract generated signal '$name' collides with reserved scheduler signal 'can_accept'\n"
                if $name eq 'can_accept';
            confess "AXI manager capacity/status IAL2 contract duplicates signal '$name'\n"
                if $seen{$name}++;
        }
    }
}

sub _transaction_names_and_tags($transactions) {
    my @names;
    return \@names unless ref($transactions) eq 'ARRAY';

    for my $transaction (@$transactions) {
        push @names, $transaction->{name}, $transaction->{tag};
    }

    return \@names;
}

sub _id_family_signal_names($id_families) {
    my @names;
    return \@names unless ref($id_families) eq 'HASH';

    for my $family (qw(read write)) {
        my $entry = $id_families->{$family} || {};
        next unless $entry->{present};
        push @names, $entry->{request_id_signal}, $entry->{response_id_signal};
    }

    return \@names;
}

sub _normalize_source_anchors($anchors) {
    confess "AXI manager capacity/status IAL2 contract source.anchors must be an array reference\n"
        unless ref($anchors) eq 'ARRAY';

    my @normalized;
    for my $index (0 .. $#$anchors) {
        my $anchor = $anchors->[$index];
        if (ref($anchor) eq 'HASH') {
            my %copy;
            for my $key (sort keys %$anchor) {
                my $value = $anchor->{$key};
                confess "AXI manager capacity/status IAL2 contract source.anchors[$index].$key must be a scalar\n"
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

sub _counter_width($max_value) {
    my $width = 1;
    my $limit = 2;
    while ($limit <= $max_value) {
        ++$width;
        $limit *= 2;
    }
    return $width;
}

sub _emit_isf($contract) {
    my $read_width = $contract->{widths}{pending_reads};
    my $write_width = $contract->{widths}{pending_writes};
    my $reset = _reset_clause($contract->{reset});
    my @read_rules = _direction_rules(
        direction => 'read',
        submit => $contract->{events}{read_submit},
        complete => $contract->{events}{read_complete},
        max_pending => $contract->{read_max_pending},
        storage => $contract->{storage}{pending_reads},
        pending_output => $contract->{status_outputs}{pending_reads},
        slots_output => $contract->{status_outputs}{read_slots_available},
        full_output => $contract->{status_outputs}{read_full},
        can_accept_output => $contract->{status_outputs}{read_can_accept},
    );
    my @write_rules = _direction_rules(
        direction => 'write',
        submit => $contract->{events}{write_submit},
        complete => $contract->{events}{write_complete},
        max_pending => $contract->{write_max_pending},
        storage => $contract->{storage}{pending_writes},
        pending_output => $contract->{status_outputs}{pending_writes},
        slots_output => $contract->{status_outputs}{write_slots_available},
        full_output => $contract->{status_outputs}{write_full},
        can_accept_output => $contract->{status_outputs}{write_can_accept},
    );

    return join("\n",
        "(actor $contract->{actor_name}",
        "  (clock $contract->{clock})",
        "  $reset",
        "  (interface",
        "    (input $contract->{events}{read_submit})",
        "    (input $contract->{events}{read_complete})",
        "    (input $contract->{events}{write_submit})",
        "    (input $contract->{events}{write_complete})",
        "    (output $contract->{status_outputs}{read_can_accept})",
        "    (output $contract->{status_outputs}{write_can_accept})",
        "    (output $contract->{status_outputs}{read_full})",
        "    (output $contract->{status_outputs}{write_full})",
        _width_output_line($contract->{status_outputs}{pending_reads}, $read_width),
        _width_output_line($contract->{status_outputs}{pending_writes}, $write_width),
        _width_output_line($contract->{status_outputs}{read_slots_available}, $read_width),
        _width_output_line($contract->{status_outputs}{write_slots_available}, $write_width),
        "  )",
        "  (storage",
        "    (var $contract->{storage}{pending_reads} (width $read_width))",
        "    (var $contract->{storage}{pending_writes} (width $write_width)))",
        "",
        @read_rules,
        "",
        @write_rules,
        ")",
        "",
    );
}

sub _reset_clause($reset) {
    my @parts = ($reset->{signal});
    push @parts, $reset->{async} ? 'async' : 'sync';
    push @parts, $reset->{active_low} ? 'active_low' : 'active_high';
    return "(reset (" . join(' ', @parts) . "))";
}

sub _width_output_line($name, $width) {
    return "    (output $name)" if $width == 1;
    return "    (output $name (width $width))";
}

sub _direction_rules(%args) {
    my @rules;
    for my $occupancy (0 .. $args{max_pending}) {
        push @rules, _rule_lines(%args, kind => 'idle', occupancy => $occupancy);
    }
    for my $occupancy (0 .. $args{max_pending}) {
        push @rules, _rule_lines(%args, kind => 'submit_only', occupancy => $occupancy);
    }
    for my $occupancy (0 .. $args{max_pending}) {
        push @rules, _rule_lines(%args, kind => 'complete_only', occupancy => $occupancy);
    }
    for my $occupancy (0 .. $args{max_pending}) {
        push @rules, _rule_lines(%args, kind => 'submit_complete', occupancy => $occupancy);
    }
    return @rules;
}

sub _rule_lines(%args) {
    my $occupancy = $args{occupancy};
    my ($submit_guard, $complete_guard) = _event_guards($args{kind}, $args{submit}, $args{complete});
    my $condition = "(& $submit_guard $complete_guard (== $args{storage} $occupancy))";
    my $next = _next_pending($args{kind}, $occupancy, $args{max_pending});
    my $full = $next == $args{max_pending} ? 1 : 0;
    my $can_accept = _can_accept($args{kind}, $occupancy, $args{max_pending});
    my $slots = $args{max_pending} - $next;
    my $rule = "$args{direction}_$args{kind}_occ$occupancy";

    return (
        "  (rule $rule $condition",
        "    ($args{storage} $next)",
        "    ($args{pending_output} $next)",
        "    ($args{slots_output} $slots)",
        "    ($args{full_output} $full)",
        "    ($args{can_accept_output} $can_accept))",
    );
}

sub _event_guards($kind, $submit, $complete) {
    return ("(! $submit)", "(! $complete)") if $kind eq 'idle';
    return ($submit, "(! $complete)") if $kind eq 'submit_only';
    return ("(! $submit)", $complete) if $kind eq 'complete_only';
    return ($submit, $complete) if $kind eq 'submit_complete';
    confess "Internal error: unknown capacity/status rule kind '$kind'\n";
}

sub _next_pending($kind, $occupancy, $max_pending) {
    return $occupancy if $kind eq 'idle';
    return $occupancy < $max_pending ? $occupancy + 1 : $occupancy
        if $kind eq 'submit_only';
    return $occupancy > 0 ? $occupancy - 1 : 0
        if $kind eq 'complete_only';
    return $occupancy == 0 ? 1 : $occupancy
        if $kind eq 'submit_complete';
    confess "Internal error: unknown capacity/status rule kind '$kind'\n";
}

sub _can_accept($kind, $occupancy, $max_pending) {
    return 1 if $kind eq 'submit_complete' || $kind eq 'complete_only';
    return $occupancy < $max_pending ? 1 : 0;
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
        schema => 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1',
        mode   => 'capacity-status-shell',
        layering => {
            source_layer          => 'IAL2',
            generated_ial1_format => 'isf',
            generated_ial0_format => 'fsm',
            direct_ial2_to_ial0   => 0,
        },
        source_object => \%source_object,
        manager => {
            name       => $contract->{name},
            actor_name => $contract->{actor_name},
            protocol   => $contract->{protocol},
        },
        capacity => {
            read => {
                max_pending => $contract->{read_max_pending},
                counter_width => $contract->{widths}{pending_reads},
                storage => $contract->{storage}{pending_reads},
            },
            write => {
                max_pending => $contract->{write_max_pending},
                counter_width => $contract->{widths}{pending_writes},
                storage => $contract->{storage}{pending_writes},
            },
        },
        status_outputs => _clone_jsonish($contract->{status_outputs}),
        (defined $contract->{id_families}
            ? (id_families => _report_id_families($contract))
            : ()),
        (defined $contract->{transactions}
            ? (transactions => _report_transactions($contract))
            : ()),
        abstract_events => _clone_jsonish($contract->{events}),
        submit_policy => $contract->{submit_policy},
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
        generated_scheduler_or_status_rules => [
            {
                id => 'read_capacity_matrix',
                direction => 'read',
                rule_count => 4 * ($contract->{read_max_pending} + 1),
                storage => $contract->{storage}{pending_reads},
                status_outputs => [
                    $contract->{status_outputs}{read_can_accept},
                    $contract->{status_outputs}{read_full},
                    $contract->{status_outputs}{pending_reads},
                    $contract->{status_outputs}{read_slots_available},
                ],
            },
            {
                id => 'write_capacity_matrix',
                direction => 'write',
                rule_count => 4 * ($contract->{write_max_pending} + 1),
                storage => $contract->{storage}{pending_writes},
                status_outputs => [
                    $contract->{status_outputs}{write_can_accept},
                    $contract->{status_outputs}{write_full},
                    $contract->{status_outputs}{pending_writes},
                    $contract->{status_outputs}{write_slots_available},
                ],
            },
        ],
        blocked_reason_vocabulary => [
            'none',
            'max_pending_reached',
            'unsupported_transaction_kind',
        ],
        assumptions => [
            {
                id     => 'abstract_submit_complete_events',
                detail => 'The first slice models abstract read/write submit and completion events; AXI channel expansion and response matching remain residue.',
            },
            {
                id     => 'try_policy_status',
                detail => 'can_accept reports whether a submit is accepted under the bounded try policy, including same-cycle completion freeing capacity.',
            },
        ],
        enforced_static_rules => [
            'contract object must be a hash reference',
            'protocol must be axi4',
            'submit_policy must be try',
            'read_max_pending and write_max_pending must be explicit positive integers',
            'clock, reset, submit events, complete events, status outputs, and generated storage names must be unique ISF identifiers',
            'generated names must not collide with the scheduler-generated can_accept signal',
            'if supplied, id_families must explicitly declare read and write families',
            'id_families read/write widths must be integers in 0..32',
            'positive-width ID families require request and response ID signal names; zero-width ID families reject ID signal names',
            'ID-family signal names must be unique and must not collide with clock, reset, submit events, complete events, status outputs, or generated storage names',
            'if supplied, transactions must declare unique names and tags, read/write kind, direction-level request/completion event bindings, and id policy/value',
            'concrete transaction ID values require a present matching ID family and must fit its declared width',
        ],
        unsupported_residue => [
            {
                id     => 'blocking_or_queued_policy',
                detail => 'The first slice implements only try-style acceptance/status feedback.',
            },
            {
                id     => 'axi_id_ordering_and_response_matching',
                detail => 'ID allocation, dynamic user-ID validation while issuing work, same-ID ordering, different-ID interleaving, BID/RID response matching, and burst/last-beat tracking remain outside this capacity/status shell.',
            },
            {
                id     => 'profile_aliases_and_full_manager_behavior',
                detail => 'Profile alias suffixes, transaction classes, unique-in-flight behavior, and the full AXI manager remain future exact-owner work.',
            },
            {
                id     => 'vhdl_backend_or_reroute',
                detail => 'VHDL backend and reroute behavior remains deferred until the SystemVerilog-backed IAL path is feature complete.',
            },
        ],
    };
}

sub _report_transactions($contract) {
    my $source_anchors = $contract->{source_anchors};
    return [
        map {
            {
                name             => $_->{name},
                kind             => $_->{kind},
                tag              => $_->{tag},
                request_event    => $_->{request_event},
                completion_event => $_->{completion_event},
                id               => _report_transaction_id($_->{id}),
                source_anchors   => _clone_jsonish($source_anchors),
            }
        } @{$contract->{transactions} || []}
    ];
}

sub _report_transaction_id($id) {
    return { policy => 'auto' } if ($id->{policy} // '') eq 'auto';

    return {
        policy       => 'concrete',
        value        => $id->{value},
        family       => $id->{family},
        family_width => $id->{family_width},
        fits         => $id->{fits} ? JSON::PP::true : JSON::PP::false,
    };
}

sub _report_id_families($contract) {
    my %report;
    my $source_anchors = $contract->{source_anchors};
    for my $family (qw(write read)) {
        my $entry = $contract->{id_families}{$family};
        my %family_report = (
            width          => $entry->{width},
            present        => $entry->{present} ? JSON::PP::true : JSON::PP::false,
            source_anchors => _clone_jsonish($source_anchors),
        );
        if ($entry->{present}) {
            $family_report{request_id_signal} = $entry->{request_id_signal};
            $family_report{response_id_signal} = $entry->{response_id_signal};
        }
        $report{$family} = \%family_report;
    }

    return \%report;
}

sub _clone_jsonish($value) {
    return undef unless defined $value;
    return [map { _clone_jsonish($_) } @$value] if ref($value) eq 'ARRAY';
    return { map { $_ => _clone_jsonish($value->{$_}) } sort keys %$value } if ref($value) eq 'HASH';
    return $value;
}

1;
