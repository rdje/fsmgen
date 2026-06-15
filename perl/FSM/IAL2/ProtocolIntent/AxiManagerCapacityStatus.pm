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
    my $auto_id_lifecycle = exists($raw->{auto_id_lifecycle})
        ? _normalize_auto_id_lifecycle(
            raw_lifecycle => $raw->{auto_id_lifecycle},
            manager_name   => $name,
            id_families   => $id_families,
            transactions  => $transactions,
        )
        : undef;
    my $same_id_ordering_policy = exists($raw->{same_id_ordering_policy})
        ? _normalize_same_id_ordering_policy($raw->{same_id_ordering_policy})
        : undef;
    my $response_demux = exists($raw->{response_demux})
        ? _normalize_response_demux(
            raw_response_demux => $raw->{response_demux},
            events             => \%events,
            id_families        => $id_families,
            transactions       => $transactions,
            auto_id_lifecycle  => $auto_id_lifecycle,
            same_id_ordering_policy => $same_id_ordering_policy,
            read_max_pending   => $read_max_pending,
            write_max_pending  => $write_max_pending,
        )
        : undef;
    my $transaction_event_dispatch = _build_transaction_event_dispatch(
        events       => \%events,
        transactions => $transactions,
    );
    my $same_id_admitted_request_boundary = _build_same_id_admitted_request_boundary(
        manager_name             => $name,
        id_families              => $id_families,
        transactions             => $transactions,
        same_id_ordering_policy  => $same_id_ordering_policy,
        transaction_event_dispatch => $transaction_event_dispatch,
        storage                  => \%storage,
        read_max_pending         => $read_max_pending,
        write_max_pending        => $write_max_pending,
    );
    my $same_id_issue_order_queue_behavior = _build_same_id_issue_order_queue_behavior(
        manager_name             => $name,
        id_families              => $id_families,
        transactions             => $transactions,
        response_demux           => $response_demux,
        same_id_ordering_policy  => $same_id_ordering_policy,
        same_id_admitted_request_boundary => $same_id_admitted_request_boundary,
    );
    $response_demux = _response_demux_with_same_id_issue_order_queue_behavior(
        response_demux => $response_demux,
        behavior       => $same_id_issue_order_queue_behavior,
    );
    my $read_data = exists($raw->{read_data})
        ? _normalize_read_data(
            raw_read_data  => $raw->{read_data},
            manager_name   => $name,
            transactions   => $transactions,
            response_demux => $response_demux,
        )
        : undef;
    my $id_response_rule_engine = _build_id_response_rule_engine(
        id_families             => $id_families,
        transactions            => $transactions,
        same_id_ordering_policy => $same_id_ordering_policy,
        response_demux          => $response_demux,
    );
    my $event_inputs = _effective_event_inputs(
        events                     => \%events,
        transaction_event_dispatch => $transaction_event_dispatch,
        response_demux             => $response_demux,
    );

    _reject_forbidden_or_duplicate_names(
        clock        => $clock,
        reset        => $reset->{signal},
        events       => \%events,
        event_inputs => $event_inputs,
        status       => $status,
        storage      => \%storage,
        id_families  => $id_families,
        transactions => $transactions,
        auto_id_lifecycle => $auto_id_lifecycle,
        response_demux => $response_demux,
        read_data => $read_data,
        same_id_admitted_request_boundary => $same_id_admitted_request_boundary,
        same_id_issue_order_queue_behavior => $same_id_issue_order_queue_behavior,
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
    my $same_id_ordering = _build_same_id_ordering(
        manager_name             => $name,
        source_anchors            => $anchors,
        auto_id_lifecycle         => $auto_id_lifecycle,
        response_demux            => $response_demux,
        same_id_ordering_policy   => $same_id_ordering_policy,
        same_id_admitted_request_boundary => $same_id_admitted_request_boundary,
        same_id_issue_order_queue_behavior => $same_id_issue_order_queue_behavior,
    );

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
        event_inputs      => $event_inputs,
        status_outputs    => $status,
        id_families       => $id_families,
        transactions      => $transactions,
        auto_id_lifecycle => $auto_id_lifecycle,
        response_demux    => $response_demux,
        read_data         => $read_data,
        same_id_ordering_policy => $same_id_ordering_policy,
        same_id_ordering  => $same_id_ordering,
        same_id_admitted_request_boundary => $same_id_admitted_request_boundary,
        same_id_issue_order_queue_behavior => $same_id_issue_order_queue_behavior,
        transaction_event_dispatch => $transaction_event_dispatch,
        id_response_rule_engine => $id_response_rule_engine,
        storage           => \%storage,
        widths            => \%widths,
        intent_name       => $intent_name,
        source_object_id  => $source_object_id,
        source_anchors    => $anchors,
    };
}

sub _reject_unsupported_top_level_fields($raw) {
    my %allowed = map { $_ => 1 } qw(
        actor_name auto_id_lifecycle clock intent_name name protocol read_complete
        read_data read_max_pending read_submit reset response_demux source source_object_id status
        same_id_ordering_policy submit_policy id_families transactions write_complete write_max_pending
        write_submit
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

    my $opposite_kind = $kind eq 'read' ? 'write' : 'read';
    my $opposite_request = $kind eq 'read' ? $args{events}{write_submit} : $args{events}{read_submit};
    my $opposite_completion = $kind eq 'read' ? $args{events}{write_complete} : $args{events}{read_complete};
    confess "AXI manager capacity/status IAL2 contract transactions[$index] $kind request_event must not reference $opposite_kind direction-level event '$opposite_request'\n"
        if $request_event eq $opposite_request;
    confess "AXI manager capacity/status IAL2 contract transactions[$index] $kind completion_event must not reference $opposite_kind direction-level event '$opposite_completion'\n"
        if $completion_event eq $opposite_completion;

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

sub _normalize_auto_id_lifecycle(%args) {
    my $raw = $args{raw_lifecycle};
    confess "AXI manager capacity/status IAL2 contract field 'auto_id_lifecycle' must be a hash reference\n"
        unless ref($raw) eq 'HASH';
    confess "AXI manager capacity/status IAL2 contract auto_id_lifecycle requires id_families metadata\n"
        unless ref($args{id_families}) eq 'HASH';
    confess "AXI manager capacity/status IAL2 contract auto_id_lifecycle requires transactions metadata\n"
        unless ref($args{transactions}) eq 'ARRAY';

    my %allowed = map { $_ => 1 } qw(read write);
    for my $family (sort keys %$raw) {
        confess "AXI manager capacity/status IAL2 contract auto_id_lifecycle has unsupported family '$family'; supported families: read, write\n"
            unless $allowed{$family};
    }

    my $auto_transactions_by_family = _auto_transactions_by_family($args{transactions});
    my @families;
    for my $family (qw(write read)) {
        next unless exists $raw->{$family};
        push @families, _normalize_auto_id_lifecycle_family(
            raw_family => $raw->{$family},
            family => $family,
            manager_name => $args{manager_name},
            id_families => $args{id_families},
            transactions => $args{transactions},
            auto_transactions_by_family => $auto_transactions_by_family,
        );
    }

    confess "AXI manager capacity/status IAL2 contract auto_id_lifecycle requires at least one read/write family\n"
        unless @families;

    return {
        mode                         => 'bounded_pool_contract',
        generated_behavior           => 1,
        max_pool_entries_per_family  => 4,
        families                     => \@families,
        residue                      => [
            'same_id_ordering',
            'response_demux',
        ],
    };
}

sub _normalize_auto_id_lifecycle_family(%args) {
    my $family = $args{family};
    my $raw = $args{raw_family};
    confess "AXI manager capacity/status IAL2 contract auto_id_lifecycle.$family must be a hash reference\n"
        unless ref($raw) eq 'HASH';

    my %allowed = map { $_ => 1 } qw(pool);
    for my $field (sort keys %$raw) {
        confess "AXI manager capacity/status IAL2 contract auto_id_lifecycle.$family unsupported field '$field'\n"
            unless $allowed{$field};
    }
    confess "AXI manager capacity/status IAL2 contract auto_id_lifecycle.$family is missing required field 'pool'\n"
        unless exists $raw->{pool};

    my $id_family = $args{id_families}{$family};
    confess "AXI manager capacity/status IAL2 contract auto_id_lifecycle.$family requires a declared $family ID family\n"
        unless ref($id_family) eq 'HASH';
    confess "AXI manager capacity/status IAL2 contract auto_id_lifecycle.$family requires positive ID-family width\n"
        unless $id_family->{present};

    my $auto_transactions = $args{auto_transactions_by_family}{$family} || [];
    confess "AXI manager capacity/status IAL2 contract auto_id_lifecycle.$family requires at least one auto-ID transaction in the $family family\n"
        unless @$auto_transactions;

    my $pool = _normalize_auto_id_pool($raw->{pool}, $family, $id_family->{width});
    my $transaction_state = _auto_id_lifecycle_transaction_state(
        manager_name  => $args{manager_name},
        family        => $family,
        transactions  => $args{transactions},
        auto_transactions => $auto_transactions,
        pool          => $pool,
    );
    return {
        family                    => $family,
        request_id_signal         => $id_family->{request_id_signal},
        request_id_direction      => 'generated_output',
        response_id_signal        => $id_family->{response_id_signal},
        response_id_direction     => 'generated_input',
        pool                      => $pool,
        allocator                 => 'first_free_pool_order',
        transaction_lifetime      => 'single_active',
        release                   => 'transaction_completion_event',
        no_id_available           => 'runtime_assertion',
        auto_transactions         => _clone_jsonish($auto_transactions),
        transaction_state         => $transaction_state,
    };
}

sub _auto_id_lifecycle_transaction_state(%args) {
    my %transaction_by_name = map { $_->{name} => $_ } @{$args{transactions}};
    return [
        map {
            my $transaction = $transaction_by_name{$_};
            confess "Internal error: auto-ID lifecycle transaction '$_' is missing from normalized transactions\n"
                unless ref($transaction) eq 'HASH';
            my $prefix = "$args{manager_name}_$_";
            +{
                transaction        => $_,
                request_event      => $transaction->{request_event},
                completion_event   => $transaction->{completion_event},
                selected_id_signal => "${prefix}_auto_id_q",
                busy_signal        => "${prefix}_auto_id_busy_q",
                allocation_rules   => [
                    map { "${prefix}_auto_id_alloc_$_" } @{$args{pool}},
                ],
                release_rule       => "${prefix}_auto_id_release",
                no_id_assertion    => "${prefix}_auto_id_available",
                completion_assertion => "${prefix}_auto_id_completion_active",
            }
        } @{$args{auto_transactions}}
    ];
}

sub _auto_transactions_by_family($transactions) {
    my %by_family = (
        read  => [],
        write => [],
    );

    for my $transaction (@$transactions) {
        my $id = $transaction->{id};
        next unless ref($id) eq 'HASH' && ($id->{policy} // '') eq 'auto';
        push @{$by_family{$transaction->{kind}}}, $transaction->{name};
    }

    return \%by_family;
}

sub _normalize_auto_id_pool($raw_pool, $family, $width) {
    confess "AXI manager capacity/status IAL2 contract auto_id_lifecycle.$family.pool must be an array reference\n"
        unless ref($raw_pool) eq 'ARRAY';
    confess "AXI manager capacity/status IAL2 contract auto_id_lifecycle.$family.pool supports 1..4 ID values in this slice\n"
        unless @$raw_pool >= 1 && @$raw_pool <= 4;

    my $limit = 2 ** $width;
    my (%seen, @pool);
    for my $index (0 .. $#$raw_pool) {
        my $value = _unsigned_integer($raw_pool->[$index], "auto_id_lifecycle.$family.pool[$index]");
        confess "AXI manager capacity/status IAL2 contract auto_id_lifecycle.$family.pool duplicates ID value $value\n"
            if $seen{$value}++;
        confess "AXI manager capacity/status IAL2 contract auto_id_lifecycle.$family.pool value $value does not fit width $width\n"
            if $value >= $limit;
        push @pool, $value;
    }

    return \@pool;
}

sub _normalize_response_demux(%args) {
    my $raw = $args{raw_response_demux};
    confess "AXI manager capacity/status IAL2 contract field 'response_demux' must be a hash reference\n"
        unless ref($raw) eq 'HASH';

    for my $family (sort keys %$raw) {
        confess "AXI manager capacity/status IAL2 contract response_demux has unsupported family '$family'; supported families: read, write\n"
            unless $family =~ /\A(?:read|write)\z/;
    }
    confess "AXI manager capacity/status IAL2 contract response_demux requires at least one read/write family\n"
        unless exists($raw->{read}) || exists($raw->{write});
    confess "AXI manager capacity/status IAL2 contract response_demux requires id_families metadata\n"
        unless ref($args{id_families}) eq 'HASH';
    confess "AXI manager capacity/status IAL2 contract response_demux requires transactions metadata\n"
        unless ref($args{transactions}) eq 'ARRAY';

    my %normalized;
    if (exists $raw->{write}) {
        my $write_family = $args{id_families}{write};
        confess "AXI manager capacity/status IAL2 contract response_demux.write requires a declared write ID family\n"
            unless ref($write_family) eq 'HASH';
        confess "AXI manager capacity/status IAL2 contract response_demux.write requires positive write ID-family width\n"
            unless $write_family->{present};

        my $write_lifecycle = _auto_id_lifecycle_family_by_name($args{auto_id_lifecycle}, 'write');
        my $queue_head_plan = _response_demux_queue_head_plan_for_family(
            family_name             => 'write',
            transactions            => $args{transactions},
            same_id_ordering_policy => $args{same_id_ordering_policy},
            max_pending             => $args{write_max_pending},
            lifecycle               => $write_lifecycle,
        );

        $normalized{write} = _normalize_response_demux_write(
            raw_write       => $raw->{write},
            events          => $args{events},
            write_family    => $write_family,
            write_lifecycle => $write_lifecycle,
            queue_head_plan => $queue_head_plan,
        );
    }

    if (exists $raw->{read}) {
        my $read_family = $args{id_families}{read};
        confess "AXI manager capacity/status IAL2 contract response_demux.read requires a declared read ID family\n"
            unless ref($read_family) eq 'HASH';
        confess "AXI manager capacity/status IAL2 contract response_demux.read requires positive read ID-family width\n"
            unless $read_family->{present};

        my $read_lifecycle = _auto_id_lifecycle_family_by_name($args{auto_id_lifecycle}, 'read');
        my $queue_head_plan = _response_demux_queue_head_plan_for_family(
            family_name             => 'read',
            transactions            => $args{transactions},
            same_id_ordering_policy => $args{same_id_ordering_policy},
            max_pending             => $args{read_max_pending},
            lifecycle               => $read_lifecycle,
        );

        $normalized{read} = _normalize_response_demux_read(
            raw_read       => $raw->{read},
            events         => $args{events},
            read_family    => $read_family,
            read_lifecycle => $read_lifecycle,
            queue_head_plan => $queue_head_plan,
        );
    }

    my $generated_behavior = grep {
        ref($normalized{$_}) eq 'HASH' && $normalized{$_}{generated_behavior}
    } qw(write read);
    my $mode = exists($normalized{read})
        ? 'bounded_response_demux_contract'
        : 'bounded_write_bid_demux_contract';
    my @residue = _response_demux_residue(\%normalized);

    return {
        mode               => $mode,
        generated_behavior => $generated_behavior ? 1 : 0,
        %normalized,
        residue => \@residue,
    };
}

sub _response_demux_residue($normalized) {
    if (_response_demux_has_queue_head_contract($normalized)) {
        my @residue;
        push @residue, 'read_response_demux'
            unless exists $normalized->{read};
        push @residue, qw(generated_same_id_queue_head_demux read_data_interleaving bursts);
        return @residue;
    }

    return qw(read_response_demux same_id_ordering read_data_interleaving bursts)
        unless exists $normalized->{read};

    my $read = $normalized->{read};
    return qw(read_data_interleaving bursts)
        if ref($read) eq 'HASH' && $read->{generated_behavior};

    return qw(generated_burst_last_read_demux read_data_interleaving bursts);
}

sub _response_demux_has_queue_head_contract($response_demux) {
    return 0 unless ref($response_demux) eq 'HASH';
    for my $family (qw(write read)) {
        my $entry = $response_demux->{$family};
        return 1 if ref($entry) eq 'HASH'
            && ($entry->{transaction_completion_source} // '') eq 'generated_queue_head_demux';
    }
    return 0;
}

sub _response_demux_family_has_queue_head_contract($response_demux, $family) {
    return 0 unless ref($response_demux) eq 'HASH';
    my $entry = $response_demux->{$family};
    return ref($entry) eq 'HASH'
        && ($entry->{transaction_completion_source} // '') eq 'generated_queue_head_demux';
}

sub _response_demux_queue_head_plan_for_family(%args) {
    my $family_name = $args{family_name};
    my $policy = _same_id_ordering_policy_for_family($args{same_id_ordering_policy}, $family_name);
    my $queue_policy_selected = ref($policy) eq 'HASH'
        && ($policy->{policy} // '') eq 'issue_order_queue';
    my $lifecycle = $args{lifecycle};
    my $has_auto_lifecycle = ref($lifecycle) eq 'HASH'
        && @{$lifecycle->{auto_transactions} || []};

    my $groups = _same_id_duplicate_concrete_groups(
        transactions => $args{transactions},
        family_name  => $family_name,
        max_pending  => $args{max_pending},
    );
    my $has_duplicate_group = @$groups ? 1 : 0;

    if ($queue_policy_selected && $has_duplicate_group) {
        confess "AXI manager capacity/status IAL2 contract response_demux.$family_name does not support same-family auto_id_lifecycle plus concrete same-ID queue-head demux in this slice\n"
            if $has_auto_lifecycle;
        my @completion_signals;
        my %wanted = map {
            map { $_ => 1 } @{$_->{transactions} || []}
        } @$groups;
        for my $transaction (@{$args{transactions} || []}) {
            next unless $wanted{$transaction->{name}};
            push @completion_signals, $transaction->{completion_event};
        }
        return {
            mode               => 'queue_head',
            groups             => $groups,
            completion_signals => \@completion_signals,
        };
    }

    if ($has_auto_lifecycle) {
        return {
            mode      => 'auto_id',
            lifecycle => $lifecycle,
        };
    }

    if ($queue_policy_selected) {
        confess "AXI manager capacity/status IAL2 contract response_demux.$family_name concrete same-ID queue-head demux requires at least one duplicate concrete $family_name ID group\n";
    }

    confess "AXI manager capacity/status IAL2 contract response_demux.$family_name requires $family_name auto_id_lifecycle metadata or selected same-id-ordering.$family_name concrete-id-reuse issue-order-queue with a duplicate concrete-ID group\n";
}

sub _same_id_duplicate_concrete_groups(%args) {
    my @transactions = grep {
        ($_->{kind} // '') eq $args{family_name}
            && ref($_->{id}) eq 'HASH'
            && ($_->{id}{policy} // '') eq 'concrete'
    } @{$args{transactions} || []};

    my (%by_id, @order);
    for my $transaction (@transactions) {
        my $id = $transaction->{id}{value};
        push @order, $id unless exists $by_id{$id};
        push @{$by_id{$id}}, $transaction;
    }

    my @groups;
    for my $id (@order) {
        my $group = $by_id{$id};
        next unless @$group > 1;
        my $depth = @$group < $args{max_pending} ? scalar(@$group) : $args{max_pending};
        push @groups, {
            concrete_id          => $id,
            transactions         => [map { $_->{name} } @$group],
            depth                => $depth,
            dequeue_event_source => 'queue_head_response_demux',
        };
    }
    return \@groups;
}

sub _normalize_response_demux_write(%args) {
    my $raw = $args{raw_write};
    confess "AXI manager capacity/status IAL2 contract response_demux.write must be a hash reference\n"
        unless ref($raw) eq 'HASH';

    my %allowed = map { $_ => 1 } qw(response_event transaction_completion);
    for my $field (sort keys %$raw) {
        confess "AXI manager capacity/status IAL2 contract response_demux.write unsupported field '$field'\n"
            unless $allowed{$field};
    }
    confess "AXI manager capacity/status IAL2 contract response_demux.write is missing required field 'response_event'\n"
        unless exists $raw->{response_event};
    confess "AXI manager capacity/status IAL2 contract response_demux.write is missing required field 'transaction_completion'\n"
        unless exists $raw->{transaction_completion};

    my $response_event = _identifier_value(
        _nonempty_scalar($raw->{response_event}, 'response_demux.write.response_event'),
        'response_demux.write.response_event',
    );
    my $expected_event = $args{events}{write_complete};
    confess "AXI manager capacity/status IAL2 contract response_demux.write.response_event must equal write_complete event '$expected_event' in this slice\n"
        unless $response_event eq $expected_event;

    my $transaction_completion = _nonempty_scalar(
        $raw->{transaction_completion},
        'response_demux.write.transaction_completion',
    );
    confess "AXI manager capacity/status IAL2 contract response_demux.write.transaction_completion must be generated in this slice\n"
        unless $transaction_completion eq 'generated';

    my $queue_head_plan = $args{queue_head_plan};
    my $queue_head_selected = ref($queue_head_plan) eq 'HASH'
        && ($queue_head_plan->{mode} // '') eq 'queue_head';
    my @completion_signals = $queue_head_selected
        ? @{$queue_head_plan->{completion_signals} || []}
        : map { $_->{completion_event} } @{$args{write_lifecycle}{transaction_state} || []};
    for my $completion_signal (@completion_signals) {
        confess "AXI manager capacity/status IAL2 contract response_demux.write generated transaction completion signal '$completion_signal' must be distinct from response_event '$response_event'\n"
            if $completion_signal eq $response_event;
    }

    if ($queue_head_selected) {
        return {
            mode                         => 'bounded_write_bid_queue_head_demux_contract',
            generated_behavior           => 0,
            implementation_status        => 'selected_not_generated',
            response_event                => $response_event,
            response_event_role           => 'raw_accepted_write_response',
            response_id_signal            => $args{write_family}{response_id_signal},
            response_id_direction         => 'generated_input',
            transaction_completion_source => 'generated_queue_head_demux',
            transaction_completion_semantics => 'matched_concrete_id_queue_head',
            queue_state_representation    => 'compact_onehot_transaction_slots',
            same_id_issue_order_queues    => _clone_jsonish($queue_head_plan->{groups}),
            selected_completion_signals   => _clone_jsonish(\@completion_signals),
        };
    }

    confess "AXI manager capacity/status IAL2 contract response_demux.write requires write auto_id_lifecycle metadata\n"
        unless ref($args{write_lifecycle}) eq 'HASH';
    confess "AXI manager capacity/status IAL2 contract response_demux.write requires at least one write auto-ID transaction\n"
        unless @{$args{write_lifecycle}{auto_transactions} || []};

    return {
        mode                         => 'bounded_write_bid_demux_contract',
        generated_behavior           => 1,
        response_event                => $response_event,
        response_id_signal            => $args{write_family}{response_id_signal},
        response_id_direction         => 'generated_input',
        transaction_completion_source => 'generated_demux',
        auto_transactions             => _clone_jsonish($args{write_lifecycle}{auto_transactions}),
        generated_completion_signals  => _clone_jsonish(\@completion_signals),
    };
}

sub _normalize_response_demux_read(%args) {
    my $raw = $args{raw_read};
    confess "AXI manager capacity/status IAL2 contract response_demux.read must be a hash reference\n"
        unless ref($raw) eq 'HASH';

    my %allowed = map { $_ => 1 } qw(
        response_event response_scope last_signal last_signal_width
        transaction_completion
    );
    for my $field (sort keys %$raw) {
        confess "AXI manager capacity/status IAL2 contract response_demux.read unsupported field '$field'\n"
            unless $allowed{$field};
    }
    confess "AXI manager capacity/status IAL2 contract response_demux.read is missing required field 'response_event'\n"
        unless exists $raw->{response_event};
    confess "AXI manager capacity/status IAL2 contract response_demux.read is missing required field 'response_scope'\n"
        unless exists $raw->{response_scope};
    confess "AXI manager capacity/status IAL2 contract response_demux.read is missing required field 'transaction_completion'\n"
        unless exists $raw->{transaction_completion};

    my $response_event = _identifier_value(
        _nonempty_scalar($raw->{response_event}, 'response_demux.read.response_event'),
        'response_demux.read.response_event',
    );
    my $expected_event = $args{events}{read_complete};
    confess "AXI manager capacity/status IAL2 contract response_demux.read.response_event must equal read_complete event '$expected_event' in this slice\n"
        unless $response_event eq $expected_event;

    my $response_scope = _nonempty_scalar(
        $raw->{response_scope},
        'response_demux.read.response_scope',
    );
    confess "AXI manager capacity/status IAL2 contract response_demux.read.response_scope must be single-beat or burst-last in this slice\n"
        unless $response_scope =~ /\A(?:single-beat|burst-last)\z/;

    my $transaction_completion = _nonempty_scalar(
        $raw->{transaction_completion},
        'response_demux.read.transaction_completion',
    );
    confess "AXI manager capacity/status IAL2 contract response_demux.read.transaction_completion must be generated in this slice\n"
        unless $transaction_completion eq 'generated';

    my $queue_head_plan = $args{queue_head_plan};
    my $queue_head_selected = ref($queue_head_plan) eq 'HASH'
        && ($queue_head_plan->{mode} // '') eq 'queue_head';
    my @completion_signals = $queue_head_selected
        ? @{$queue_head_plan->{completion_signals} || []}
        : map { $_->{completion_event} } @{$args{read_lifecycle}{transaction_state} || []};
    for my $completion_signal (@completion_signals) {
        confess "AXI manager capacity/status IAL2 contract response_demux.read generated transaction completion signal '$completion_signal' must be distinct from response_event '$response_event'\n"
            if $completion_signal eq $response_event;
    }

    if ($response_scope eq 'single-beat') {
        confess "AXI manager capacity/status IAL2 contract response_demux.read.last_signal is only supported with response_scope burst-last\n"
            if exists($raw->{last_signal}) || exists($raw->{last_signal_width});
        if ($queue_head_selected) {
            return {
                mode                         => 'bounded_read_rid_queue_head_demux_contract',
                generated_behavior           => 0,
                implementation_status        => 'selected_not_generated',
                response_event                => $response_event,
                response_event_role           => 'raw_accepted_read_response',
                response_scope                => 'single_beat',
                response_id_signal            => $args{read_family}{response_id_signal},
                response_id_direction         => 'generated_input',
                transaction_completion_source => 'generated_queue_head_demux',
                transaction_completion_semantics => 'matched_concrete_id_queue_head',
                queue_state_representation    => 'compact_onehot_transaction_slots',
                same_id_issue_order_queues    => _clone_jsonish($queue_head_plan->{groups}),
                selected_completion_signals   => _clone_jsonish(\@completion_signals),
            };
        }
        confess "AXI manager capacity/status IAL2 contract response_demux.read requires read auto_id_lifecycle metadata\n"
            unless ref($args{read_lifecycle}) eq 'HASH';
        confess "AXI manager capacity/status IAL2 contract response_demux.read requires at least one read auto-ID transaction\n"
            unless @{$args{read_lifecycle}{auto_transactions} || []};
        return {
            mode                         => 'bounded_read_rid_demux_contract',
            generated_behavior           => 1,
            response_event                => $response_event,
            response_event_role           => 'raw_accepted_read_response',
            response_scope                => 'single_beat',
            response_id_signal            => $args{read_family}{response_id_signal},
            response_id_direction         => 'generated_input',
            transaction_completion_source => 'generated_demux',
            auto_transactions             => _clone_jsonish($args{read_lifecycle}{auto_transactions}),
            generated_completion_signals  => _clone_jsonish(\@completion_signals),
        };
    }

    confess "AXI manager capacity/status IAL2 contract response_demux.read.response_scope burst-last requires field 'last_signal'\n"
        unless exists $raw->{last_signal};
    confess "AXI manager capacity/status IAL2 contract response_demux.read.response_scope burst-last requires field 'last_signal_width'\n"
        unless exists $raw->{last_signal_width};

    my $last_signal = _identifier_value(
        _nonempty_scalar($raw->{last_signal}, 'response_demux.read.last_signal'),
        'response_demux.read.last_signal',
    );
    my $last_signal_width = _positive_integer(
        $raw->{last_signal_width},
        'response_demux.read.last_signal_width',
    );
    confess "AXI manager capacity/status IAL2 contract response_demux.read.last_signal_width must be 1 in this slice\n"
        unless $last_signal_width == 1;

    if ($queue_head_selected) {
        return {
            mode                         => 'bounded_read_rid_queue_head_demux_contract',
            generated_behavior           => 0,
            implementation_status        => 'selected_not_generated',
            response_event                => $response_event,
            response_event_role           => 'raw_accepted_read_response_beat',
            response_scope                => 'burst_last',
            response_id_signal            => $args{read_family}{response_id_signal},
            response_id_direction         => 'generated_input',
            last_signal                   => $last_signal,
            last_signal_direction         => 'generated_input',
            last_signal_width             => $last_signal_width,
            transaction_completion_source => 'generated_queue_head_demux',
            transaction_completion_semantics => 'matched_concrete_id_queue_head_and_last_signal',
            queue_state_representation    => 'compact_onehot_transaction_slots',
            same_id_issue_order_queues    => _clone_jsonish($queue_head_plan->{groups}),
            selected_completion_signals   => _clone_jsonish(\@completion_signals),
        };
    }

    confess "AXI manager capacity/status IAL2 contract response_demux.read requires read auto_id_lifecycle metadata\n"
        unless ref($args{read_lifecycle}) eq 'HASH';
    confess "AXI manager capacity/status IAL2 contract response_demux.read requires at least one read auto-ID transaction\n"
        unless @{$args{read_lifecycle}{auto_transactions} || []};

    return {
        mode                         => 'bounded_read_rid_demux_contract',
        generated_behavior           => 1,
        response_event                => $response_event,
        response_event_role           => 'raw_accepted_read_response_beat',
        response_scope                => 'burst_last',
        response_id_signal            => $args{read_family}{response_id_signal},
        response_id_direction         => 'generated_input',
        last_signal                   => $last_signal,
        last_signal_direction         => 'generated_input',
        last_signal_width             => $last_signal_width,
        transaction_completion_source => 'generated_demux_last_beat',
        transaction_completion_semantics => 'matched_rid_and_last_signal',
        beat_valid_output             => 'none',
        burst_length_source           => 'rlast_only',
        burst_length_validation       => 'not_generated',
        auto_transactions             => _clone_jsonish($args{read_lifecycle}{auto_transactions}),
        generated_completion_signals  => _clone_jsonish(\@completion_signals),
    };
}

sub _normalize_read_data(%args) {
    my $raw = $args{raw_read_data};
    confess "AXI manager capacity/status IAL2 contract field 'read_data' must be a hash reference\n"
        unless ref($raw) eq 'HASH';

    for my $family (sort keys %$raw) {
        confess "AXI manager capacity/status IAL2 contract read_data has unsupported family '$family'; supported family: read\n"
            unless $family eq 'read';
    }
    confess "AXI manager capacity/status IAL2 contract read_data requires a read family\n"
        unless exists $raw->{read};
    confess "AXI manager capacity/status IAL2 contract read_data requires generated read response_demux metadata\n"
        unless ref($args{response_demux}) eq 'HASH'
            && ref($args{response_demux}{read}) eq 'HASH'
            && $args{response_demux}{read}{generated_behavior};
    confess "AXI manager capacity/status IAL2 contract read_data requires transactions metadata\n"
        unless ref($args{transactions}) eq 'ARRAY';

    my $read = _normalize_read_data_read(
        raw_read       => $raw->{read},
        manager_name   => $args{manager_name},
        transactions   => $args{transactions},
        response_demux => $args{response_demux}{read},
    );
    my %required_response_scope = (
        single_beat => 'single_beat',
        last_beat   => 'burst_last',
        multi_beat  => 'burst_last',
    );
    my $required_response_scope = $required_response_scope{$read->{capture_scope}};
    if (($args{response_demux}{read}{response_scope} // '') ne $required_response_scope) {
        if ($read->{capture_scope} eq 'single_beat') {
            confess "AXI manager capacity/status IAL2 contract read_data requires response_demux.read.response_scope single_beat for capture_scope single-beat in this slice\n";
        }
        if ($read->{capture_scope} eq 'last_beat') {
            confess "AXI manager capacity/status IAL2 contract read_data.read capture_scope last-beat requires response_demux.read.response_scope burst_last in this slice\n";
        }
        confess "AXI manager capacity/status IAL2 contract read_data.read capture_scope multi-beat requires response_demux.read.response_scope burst_last in this slice\n";
    }

    my $last_beat_capture = $read->{capture_scope} eq 'last_beat';
    my $multi_beat_capture = $read->{capture_scope} eq 'multi_beat';
    my $mode = $multi_beat_capture
        ? 'bounded_multi_beat_read_data_contract'
        : $last_beat_capture
            ? 'bounded_last_beat_read_data_contract'
            : 'bounded_single_beat_read_data_contract';
    my $multi_beat_generated = $multi_beat_capture
        && ($read->{multi_beat_reassembly_generated_behavior} || 0);
    my @multi_beat_status_residue = !$multi_beat_capture
        ? ()
        : ($read->{status_aggregation} // 'none') eq 'none'
            ? ('rresp_aggregation')
            : $read->{status_aggregation_generated_behavior}
                ? ()
                : ('generated_rresp_aggregation');
    my $residue = $multi_beat_capture
        ? [
            ($multi_beat_generated ? () : (
                'multi_beat_read_data_reassembly',
                'per_beat_outputs',
            )),
            @multi_beat_status_residue,
        ]
        : !$last_beat_capture
        ? [
            'rlast_completion',
            'bursts',
            'multi_beat_read_data_reassembly',
        ]
        : ($read->{burst_length_source} || '') eq 'arlen_signal'
            ? [
                ($read->{beat_count_validation_generated_behavior}
                    ? ()
                    : ('generated_beat_count_validation')),
                'multi_beat_read_data_reassembly',
                'per_beat_outputs',
                'rresp_aggregation',
            ]
            : [
                'multi_beat_read_data_reassembly',
                'per_beat_outputs',
                'rresp_aggregation',
                'arlen_or_beat_count_validation',
            ];

    return {
        mode               => $mode,
        generated_behavior => 1,
        read               => $read,
        residue            => $residue,
    };
}

sub _read_data_response_demux_transaction_coverage(%args) {
    my $response_demux = $args{response_demux};
    my $capture_scope = $args{capture_scope};
    confess "Internal error: read-data coverage requires read response_demux metadata\n"
        unless ref($response_demux) eq 'HASH';

    my $transaction_completion_source = $response_demux->{transaction_completion_source} // '';
    if ($transaction_completion_source eq 'generated_queue_head_demux') {
        my %supported_boundaries = (
            'single-beat' => {
                response_scope              => 'single_beat',
                generated_queue_boundary    => 'generated_read_single_beat_queue_head_demux',
                completion_validity         => 'generated_queue_head_response_demux_completion_pulse',
            },
            'last-beat' => {
                response_scope              => 'burst_last',
                generated_queue_boundary    => 'generated_read_burst_last_queue_head_demux',
                completion_validity         => 'generated_queue_head_response_demux_last_beat_completion_pulse',
            },
            'multi-beat' => {
                response_scope              => 'burst_last',
                generated_queue_boundary    => 'generated_read_burst_last_queue_head_demux',
                completion_validity         => 'generated_queue_head_response_demux_last_beat_completion_pulse',
            },
        );
        my $supported = $supported_boundaries{$capture_scope};
        confess "AXI manager capacity/status IAL2 contract read_data.read can consume concrete same-ID queue-head response_demux.read only for generated read single-beat queue-head demux with capture_scope single-beat or generated read burst-last queue-head demux with capture_scope last-beat or multi-beat in this slice\n"
            unless ref($supported) eq 'HASH'
                && ($response_demux->{response_scope} // '') eq $supported->{response_scope}
                && ($response_demux->{generated_queue_behavior_boundary} // '') eq $supported->{generated_queue_boundary};

        my $groups = $response_demux->{same_id_issue_order_queues};
        confess "AXI manager capacity/status IAL2 contract read_data.read queue-head coverage requires exactly one depth-2 concrete same-ID read queue group in this slice\n"
            unless ref($groups) eq 'ARRAY' && @$groups == 1;
        my $group = $groups->[0];
        confess "AXI manager capacity/status IAL2 contract read_data.read queue-head coverage requires exactly one depth-2 concrete same-ID read queue group in this slice\n"
            unless ref($group) eq 'HASH'
                && ($group->{depth} // 0) == 2
                && ref($group->{transactions}) eq 'ARRAY'
                && @{$group->{transactions}} == 2;

        my @transactions = @{$group->{transactions}};
        my @completion_signals = @{$response_demux->{generated_completion_signals} || []};
        confess "AXI manager capacity/status IAL2 contract read_data.read queue-head coverage requires one generated completion signal per covered read transaction\n"
            unless @completion_signals == @transactions;
        my %completion_signal_by_transaction;
        @completion_signal_by_transaction{@transactions} = @completion_signals;

        return {
            transactions                     => \@transactions,
            completion_signal_by_transaction => \%completion_signal_by_transaction,
            missing_diagnostic               => 'read response_demux queue-head transaction(s)',
            uncovered_diagnostic             => 'generated read response_demux queue-head transactions',
            completion_validity              => $supported->{completion_validity},
            queue_head_response_demux        => 1,
        };
    }

    my @transactions = @{$response_demux->{auto_transactions} || []};
    confess "AXI manager capacity/status IAL2 contract read_data.read requires read response_demux auto transaction coverage metadata\n"
        unless @transactions;
    my @completion_signals = @{$response_demux->{generated_completion_signals} || []};
    my %completion_signal_by_transaction;
    @completion_signal_by_transaction{@transactions} = @completion_signals
        if @completion_signals == @transactions;

    return {
        transactions                     => \@transactions,
        completion_signal_by_transaction => \%completion_signal_by_transaction,
        missing_diagnostic               => 'read response_demux auto transaction(s)',
        uncovered_diagnostic             => 'generated read response_demux auto transactions',
    };
}

sub _normalize_read_data_read(%args) {
    my $raw = $args{raw_read};
    confess "AXI manager capacity/status IAL2 contract read_data.read must be a hash reference\n"
        unless ref($raw) eq 'HASH';

    my %allowed = map { $_ => 1 } qw(
        capture_scope completion_source data_signal data_width status_signal
        status_width status_policy status_aggregation interleaving burst_length
        transactions
    );
    for my $field (sort keys %$raw) {
        confess "AXI manager capacity/status IAL2 contract read_data.read unsupported field '$field'\n"
            unless $allowed{$field};
    }

    for my $required (qw(capture_scope completion_source data_signal data_width status_signal status_width interleaving transactions)) {
        confess "AXI manager capacity/status IAL2 contract read_data.read is missing required field '$required'\n"
            unless exists $raw->{$required};
    }

    my $capture_scope = _nonempty_scalar($raw->{capture_scope}, 'read_data.read.capture_scope');
    confess "AXI manager capacity/status IAL2 contract read_data.read.capture_scope must be single-beat, last-beat, or multi-beat in this slice\n"
        unless $capture_scope =~ /\A(?:single-beat|last-beat|multi-beat)\z/;

    my $completion_source = _nonempty_scalar($raw->{completion_source}, 'read_data.read.completion_source');
    confess "AXI manager capacity/status IAL2 contract read_data.read.completion_source must be response-demux in this slice\n"
        unless $completion_source eq 'response-demux';

    my $status_policy = exists($raw->{status_policy})
        ? _nonempty_scalar($raw->{status_policy}, 'read_data.read.status_policy')
        : undef;
    my $status_aggregation = exists($raw->{status_aggregation})
        ? _normalize_read_data_status_aggregation($raw->{status_aggregation})
        : undef;
    if ($capture_scope eq 'single-beat') {
        confess "AXI manager capacity/status IAL2 contract read_data.read.status_policy is only supported with capture_scope last-beat or multi-beat in this slice\n"
            if defined $status_policy;
        confess "AXI manager capacity/status IAL2 contract read_data.read.burst_length is only supported with capture_scope last-beat or multi-beat in this slice\n"
            if exists $raw->{burst_length};
        confess "AXI manager capacity/status IAL2 contract read_data.read.status_aggregation is only supported with capture_scope multi-beat in this slice\n"
            if defined $status_aggregation;
    } elsif ($capture_scope eq 'last-beat') {
        confess "AXI manager capacity/status IAL2 contract read_data.read capture_scope last-beat requires status_policy last-beat in this slice\n"
            unless defined $status_policy && $status_policy eq 'last-beat';
        confess "AXI manager capacity/status IAL2 contract read_data.read.status_aggregation is only supported with capture_scope multi-beat in this slice\n"
            if defined $status_aggregation;
    } else {
        confess "AXI manager capacity/status IAL2 contract read_data.read capture_scope multi-beat requires status_policy per-beat in this slice\n"
            unless defined $status_policy && $status_policy eq 'per-beat';
        confess "AXI manager capacity/status IAL2 contract read_data.read capture_scope multi-beat requires burst_length metadata in this slice\n"
            unless exists $raw->{burst_length};
    }

    my $interleaving = _nonempty_scalar($raw->{interleaving}, 'read_data.read.interleaving');
    my %required_interleaving = (
        'single-beat' => 'single-beat-by-rid',
        'last-beat'   => 'last-beat-by-rid',
        'multi-beat'  => 'multi-beat-by-rid',
    );
    my $required_interleaving = $required_interleaving{$capture_scope};
    confess "AXI manager capacity/status IAL2 contract read_data.read.interleaving must be $required_interleaving for capture_scope $capture_scope in this slice\n"
        unless $interleaving eq $required_interleaving;

    my $data_signal = _identifier_value($raw->{data_signal}, 'read_data.read.data_signal');
    my $data_width = _positive_integer($raw->{data_width}, 'read_data.read.data_width');
    my $status_signal = _identifier_value($raw->{status_signal}, 'read_data.read.status_signal');
    my $status_width = _positive_integer($raw->{status_width}, 'read_data.read.status_width');
    confess "AXI manager capacity/status IAL2 contract read_data.read.status_width must be 2 in this slice\n"
        unless $status_width == 2;
    my $burst_length = exists($raw->{burst_length})
        ? _normalize_read_data_burst_length($raw->{burst_length})
        : undef;
    confess "AXI manager capacity/status IAL2 contract read_data.read capture_scope multi-beat requires burst_length.validation runtime-assertion in this slice\n"
        if $capture_scope eq 'multi-beat'
            && (!defined($burst_length) || ($burst_length->{burst_length_validation} // '') ne 'runtime_assertion');

    my $raw_transactions = $raw->{transactions};
    confess "AXI manager capacity/status IAL2 contract read_data.read.transactions must be an array reference\n"
        unless ref($raw_transactions) eq 'ARRAY';
    confess "AXI manager capacity/status IAL2 contract read_data.read requires at least one transaction binding\n"
        unless @$raw_transactions;

    my %transaction_by_name = map { $_->{name} => $_ } @{$args{transactions}};
    my $coverage = _read_data_response_demux_transaction_coverage(
        response_demux => $args{response_demux},
        capture_scope  => $capture_scope,
    );
    my @covered_transactions = @{$coverage->{transactions}};
    my %covered = map { $_ => 1 } @covered_transactions;
    my (%seen, @transactions);
    for my $index (0 .. $#$raw_transactions) {
        my $raw_transaction = $raw_transactions->[$index];
        confess "AXI manager capacity/status IAL2 contract read_data.read.transactions[$index] must be a hash reference\n"
            unless ref($raw_transaction) eq 'HASH';
        if ($capture_scope ne 'multi-beat' && exists $raw_transaction->{status_aggregate_output}) {
            confess "AXI manager capacity/status IAL2 contract read_data.read.transactions[$index].status_aggregate_output is only supported with capture_scope multi-beat in this slice\n";
        }
        if ($capture_scope eq 'multi-beat' && !defined($status_aggregation) && exists $raw_transaction->{status_aggregate_output}) {
            confess "AXI manager capacity/status IAL2 contract read_data.read.transactions[$index].status_aggregate_output requires read_data.read.status_aggregation\n";
        }
        my @transaction_fields = $capture_scope eq 'multi-beat'
            ? (
                qw(transaction data_output_prefix status_output_prefix valid_mask_output length_output),
                (defined($status_aggregation) ? ('status_aggregate_output') : ()),
            )
            : qw(transaction data_output status_output);
        my %transaction_allowed = map { $_ => 1 } @transaction_fields;
        for my $field (sort keys %$raw_transaction) {
            confess "AXI manager capacity/status IAL2 contract read_data.read.transactions[$index] unsupported field '$field'\n"
                unless $transaction_allowed{$field};
        }
        for my $required (@transaction_fields) {
            confess "AXI manager capacity/status IAL2 contract read_data.read.transactions[$index] is missing required field '$required'\n"
                unless exists $raw_transaction->{$required};
        }

        my $transaction_name = _identifier_value(
            $raw_transaction->{transaction},
            "read_data.read.transactions[$index].transaction",
        );
        confess "AXI manager capacity/status IAL2 contract read_data.read duplicates transaction '$transaction_name'\n"
            if $seen{$transaction_name}++;
        confess "AXI manager capacity/status IAL2 contract read_data.read transaction '$transaction_name' is not covered by $coverage->{uncovered_diagnostic}\n"
            unless $covered{$transaction_name};
        my $transaction = $transaction_by_name{$transaction_name};
        confess "AXI manager capacity/status IAL2 contract read_data.read transaction '$transaction_name' is missing from transactions metadata\n"
            unless ref($transaction) eq 'HASH';
        confess "AXI manager capacity/status IAL2 contract read_data.read transaction '$transaction_name' must be a read transaction\n"
            unless ($transaction->{kind} // '') eq 'read';

        my %normalized_transaction = (
            transaction       => $transaction_name,
            completion_signal => $coverage->{completion_signal_by_transaction}{$transaction_name}
                // $transaction->{completion_event},
            data_width        => $data_width,
            status_width      => $status_width,
        );
        if ($capture_scope eq 'multi-beat') {
            my $max_beats = $burst_length->{max_beats};
            my $data_output_prefix = _identifier_value(
                $raw_transaction->{data_output_prefix},
                "read_data.read.transactions[$index].data_output_prefix",
            );
            my $status_output_prefix = _identifier_value(
                $raw_transaction->{status_output_prefix},
                "read_data.read.transactions[$index].status_output_prefix",
            );
            $normalized_transaction{data_output_prefix} = $data_output_prefix;
            $normalized_transaction{generated_data_outputs} = _multi_beat_lane_names($data_output_prefix, $max_beats);
            $normalized_transaction{status_output_prefix} = $status_output_prefix;
            $normalized_transaction{generated_status_outputs} = _multi_beat_lane_names($status_output_prefix, $max_beats);
            $normalized_transaction{valid_mask_output} = _identifier_value(
                $raw_transaction->{valid_mask_output},
                "read_data.read.transactions[$index].valid_mask_output",
            );
            $normalized_transaction{valid_mask_width} = $max_beats;
            $normalized_transaction{length_output} = _identifier_value(
                $raw_transaction->{length_output},
                "read_data.read.transactions[$index].length_output",
            );
            $normalized_transaction{length_output_width} = _counter_width($max_beats);
            if (defined $status_aggregation) {
                $normalized_transaction{status_aggregate_output} = _identifier_value(
                    $raw_transaction->{status_aggregate_output},
                    "read_data.read.transactions[$index].status_aggregate_output",
                );
                $normalized_transaction{status_aggregate_output_width} = $status_width;
            }
        } else {
            $normalized_transaction{data_output} = _identifier_value(
                $raw_transaction->{data_output},
                "read_data.read.transactions[$index].data_output",
            );
            $normalized_transaction{status_output} = _identifier_value(
                $raw_transaction->{status_output},
                "read_data.read.transactions[$index].status_output",
            );
        }
        push @transactions, \%normalized_transaction;
    }

    my @missing = grep { !$seen{$_} } @covered_transactions;
    confess "AXI manager capacity/status IAL2 contract read_data.read transaction coverage is missing $coverage->{missing_diagnostic}: " . join(', ', @missing) . "\n"
        if @missing;

    my %normalized_capture_scope = (
        'single-beat' => 'single_beat',
        'last-beat'   => 'last_beat',
        'multi-beat'  => 'multi_beat',
    );
    my $normalized_capture_scope = $normalized_capture_scope{$capture_scope};
    my $completion_validity = $capture_scope eq 'single-beat'
        ? 'generated_read_response_demux_completion_pulse'
        : 'generated_read_response_demux_last_beat_completion_pulse';
    $completion_validity = $coverage->{completion_validity}
        if defined $coverage->{completion_validity};
    my %interleaving_policy = (
        'single-beat' => 'single_beat_by_rid',
        'last-beat'   => 'last_beat_by_rid',
        'multi-beat'  => 'multi_beat_by_rid',
    );
    my %read = (
        capture_scope        => $normalized_capture_scope,
        completion_source    => 'response_demux',
        completion_validity  => $completion_validity,
        data_signal          => $data_signal,
        data_signal_width    => $data_width,
        data_signal_direction => 'generated_input',
        status_signal        => $status_signal,
        status_signal_width  => $status_width,
        status_signal_direction => 'generated_input',
        interleaving_policy  => $interleaving_policy{$capture_scope},
        transactions         => \@transactions,
    );
    if ($capture_scope eq 'last-beat') {
        @read{qw(status_policy status_aggregation beat_storage valid_output length_output)} = (
            'last_beat',
            'none',
            'none',
            'none',
            'none',
        );
    } elsif ($capture_scope eq 'multi-beat') {
        my $normalized_status_aggregation = defined($status_aggregation)
            ? $status_aggregation->{normalized_policy}
            : 'none';
        @read{qw(
            status_policy
            status_aggregation
            beat_match_source
            beat_storage
            output_shape
            valid_output
            length_output
            multi_beat_reassembly_generated_behavior
        )} = (
            'per_beat',
            $normalized_status_aggregation,
            'response_demux_matched_read_beat',
            'per_transaction_generated',
            'per_beat_output_bank',
            'per_transaction_valid_mask',
            'per_transaction_beat_count',
            1,
        );
        if (defined $status_aggregation) {
            @read{qw(
                status_aggregation_generated_behavior
                status_aggregate_output
                status_aggregate_output_width
            )} = (
                1,
                'per_transaction_scalar',
                $status_width,
            );
        }
    }
    if ($capture_scope eq 'last-beat' || $capture_scope eq 'multi-beat') {
        if (ref($burst_length) eq 'HASH') {
            @read{sort keys %$burst_length} = @{$burst_length}{sort keys %$burst_length};
            if (($read{burst_length_validation} // '') eq 'runtime_assertion') {
                @read{qw(
                    beat_count_validation_generated_behavior
                    expected_beat_count_encoding
                    beat_count_match_source
                    beat_count_width
                )} = (
                    1,
                    'arlen_plus_one',
                    'response_demux_matched_read_beat',
                    _counter_width($read{max_beats}),
                );
            }
            for my $transaction (@transactions) {
                $transaction->{burst_length_storage}
                    = "$args{manager_name}_$transaction->{transaction}_arlen_q";
                $transaction->{burst_length_capture_rule}
                    = "$args{manager_name}_$transaction->{transaction}_burst_length_capture";
                if (($read{burst_length_validation} // '') eq 'runtime_assertion') {
                    $transaction->{expected_beat_count_storage}
                        = "$args{manager_name}_$transaction->{transaction}_expected_beats_q";
                    $transaction->{beat_count_storage}
                        = "$args{manager_name}_$transaction->{transaction}_read_beat_count_q";
                    $transaction->{beat_count_init_rule}
                        = "$args{manager_name}_$transaction->{transaction}_beat_count_init";
                    $transaction->{beat_count_increment_rule}
                        = "$args{manager_name}_$transaction->{transaction}_read_beat_count";
                    $transaction->{beat_count_assertions} = [
                        "$args{manager_name}_$transaction->{transaction}_arlen_within_max",
                        "$args{manager_name}_$transaction->{transaction}_read_beat_before_expected_count",
                        "$args{manager_name}_$transaction->{transaction}_rlast_on_expected_beat",
                        "$args{manager_name}_$transaction->{transaction}_expected_final_beat_has_rlast",
                    ];
                    if ($capture_scope eq 'multi-beat') {
                        $transaction->{multi_beat_output_init_rule}
                            = "$args{manager_name}_$transaction->{transaction}_read_data_output_init";
                        $transaction->{multi_beat_capture_rules} = [
                            map {
                                "$args{manager_name}_$transaction->{transaction}_read_beat_${_}_capture"
                            } 0 .. ($read{max_beats} - 1)
                        ];
                        if (defined $status_aggregation) {
                            $transaction->{status_aggregate_init_rule}
                                = $transaction->{multi_beat_output_init_rule};
                            $transaction->{status_aggregate_update_rule}
                                = "$args{manager_name}_$transaction->{transaction}_rresp_aggregate";
                        }
                    }
                }
            }
        } else {
            @read{qw(burst_length_source burst_length_validation)} = (
                'rlast_only',
                'not_generated',
            );
        }
    }

    return \%read;
}

sub _multi_beat_lane_names($prefix, $max_beats) {
    return [map { "${prefix}_$_" } 0 .. ($max_beats - 1)];
}

sub _normalize_read_data_status_aggregation($raw) {
    confess "AXI manager capacity/status IAL2 contract read_data.read.status_aggregation must be a hash reference\n"
        unless ref($raw) eq 'HASH';

    my %allowed = map { $_ => 1 } qw(policy);
    for my $field (sort keys %$raw) {
        confess "AXI manager capacity/status IAL2 contract read_data.read.status_aggregation unsupported field '$field'\n"
            unless $allowed{$field};
    }
    confess "AXI manager capacity/status IAL2 contract read_data.read.status_aggregation is missing required field 'policy'\n"
        unless exists $raw->{policy};

    my $policy = _nonempty_scalar($raw->{policy}, 'read_data.read.status_aggregation.policy');
    confess "AXI manager capacity/status IAL2 contract read_data.read.status_aggregation.policy must be worst-observed in this slice\n"
        unless $policy eq 'worst-observed';

    return {
        policy            => 'worst-observed',
        normalized_policy => 'worst_observed',
    };
}

sub _normalize_read_data_burst_length($raw) {
    confess "AXI manager capacity/status IAL2 contract read_data.read.burst_length must be a hash reference\n"
        unless ref($raw) eq 'HASH';

    my %allowed = map { $_ => 1 } qw(source signal signal_width encoding capture max_beats validation);
    for my $field (sort keys %$raw) {
        confess "AXI manager capacity/status IAL2 contract read_data.read.burst_length unsupported field '$field'\n"
            unless $allowed{$field};
    }

    for my $required (qw(source signal signal_width encoding capture max_beats validation)) {
        confess "AXI manager capacity/status IAL2 contract read_data.read.burst_length is missing required field '$required'\n"
            unless exists $raw->{$required};
    }

    my $source = _nonempty_scalar($raw->{source}, 'read_data.read.burst_length.source');
    confess "AXI manager capacity/status IAL2 contract read_data.read.burst_length.source must be arlen in this slice\n"
        unless $source eq 'arlen';

    my $signal = _identifier_value($raw->{signal}, 'read_data.read.burst_length.signal');
    my $signal_width = _positive_integer($raw->{signal_width}, 'read_data.read.burst_length.signal_width');
    confess "AXI manager capacity/status IAL2 contract read_data.read.burst_length.signal_width must be 8 for source arlen in this slice\n"
        unless $signal_width == 8;

    my $encoding = _nonempty_scalar($raw->{encoding}, 'read_data.read.burst_length.encoding');
    confess "AXI manager capacity/status IAL2 contract read_data.read.burst_length.encoding must be axlen-plus-one in this slice\n"
        unless $encoding eq 'axlen-plus-one';

    my $capture = _nonempty_scalar($raw->{capture}, 'read_data.read.burst_length.capture');
    confess "AXI manager capacity/status IAL2 contract read_data.read.burst_length.capture must be request in this slice\n"
        unless $capture eq 'request';

    my $max_beats = _positive_integer($raw->{max_beats}, 'read_data.read.burst_length.max_beats');
    confess "AXI manager capacity/status IAL2 contract read_data.read.burst_length.max_beats must be in 1..256\n"
        if $max_beats > 256;

    my $validation = _nonempty_scalar($raw->{validation}, 'read_data.read.burst_length.validation');
    confess "AXI manager capacity/status IAL2 contract read_data.read.burst_length.validation must be report-only or runtime-assertion in this slice\n"
        unless $validation eq 'report-only' || $validation eq 'runtime-assertion';

    return {
        burst_length_source             => 'arlen_signal',
        burst_length_signal             => $signal,
        burst_length_signal_direction   => 'generated_input',
        burst_length_signal_width       => $signal_width,
        burst_length_encoding           => 'axlen_plus_one',
        burst_length_capture            => 'transaction_request',
        max_beats                       => $max_beats,
        burst_length_generated_behavior => 1,
        burst_length_validation         => $validation eq 'runtime-assertion'
            ? 'runtime_assertion'
            : 'report_only',
    };
}

sub _normalize_same_id_ordering_policy($raw) {
    confess "AXI manager capacity/status IAL2 contract field 'same_id_ordering_policy' must be a hash reference\n"
        unless ref($raw) eq 'HASH';

    my %allowed = map { $_ => 1 } qw(read write);
    for my $family (sort keys %$raw) {
        confess "AXI manager capacity/status IAL2 contract same_id_ordering_policy has unsupported family '$family'; supported families: read, write\n"
            unless $allowed{$family};
    }
    confess "AXI manager capacity/status IAL2 contract same_id_ordering_policy requires at least one read/write family\n"
        unless exists($raw->{read}) || exists($raw->{write});

    my %normalized;
    for my $family (qw(read write)) {
        next unless exists $raw->{$family};
        $normalized{$family} = _normalize_same_id_ordering_policy_family($raw->{$family}, $family);
    }

    return \%normalized;
}

sub _normalize_same_id_ordering_policy_family($raw, $family) {
    confess "AXI manager capacity/status IAL2 contract same_id_ordering_policy.$family must be a hash reference\n"
        unless ref($raw) eq 'HASH';

    my %allowed = map { $_ => 1 } qw(concrete_id_reuse);
    for my $field (sort keys %$raw) {
        confess "AXI manager capacity/status IAL2 contract same_id_ordering_policy.$family unsupported field '$field'\n"
            unless $allowed{$field};
    }
    confess "AXI manager capacity/status IAL2 contract same_id_ordering_policy.$family is missing required field 'concrete_id_reuse'\n"
        unless exists $raw->{concrete_id_reuse};

    my $policy = _nonempty_scalar(
        $raw->{concrete_id_reuse},
        "same_id_ordering_policy.$family.concrete_id_reuse",
    );
    confess "AXI manager capacity/status IAL2 contract same_id_ordering_policy.$family.concrete_id_reuse must be reject or issue-order-queue in this slice\n"
        unless $policy =~ /\A(?:reject|issue-order-queue)\z/;

    return {
        policy                   => 'issue_order_queue',
        implementation_status    => 'selected_not_generated',
        enforcement              => 'not_generated',
        accepted_same_id_reuse   => 0,
        generated_queue_behavior => 0,
    } if $policy eq 'issue-order-queue';

    return {
        policy                   => 'reject',
        enforcement              => 'static_validation',
        accepted_same_id_reuse   => 0,
        generated_queue_behavior => 0,
    };
}

sub _auto_id_lifecycle_family_by_name($auto_id_lifecycle, $family_name) {
    return undef unless ref($auto_id_lifecycle) eq 'HASH';
    for my $family (@{$auto_id_lifecycle->{families} || []}) {
        return $family if ref($family) eq 'HASH' && ($family->{family} // '') eq $family_name;
    }
    return undef;
}

sub _build_same_id_ordering(%args) {
    my $lifecycle = $args{auto_id_lifecycle};
    my $policy = $args{same_id_ordering_policy};
    my $has_policy = ref($policy) eq 'HASH' && (exists($policy->{read}) || exists($policy->{write}));
    my $lifecycle_generated = ref($lifecycle) eq 'HASH' && $lifecycle->{generated_behavior};
    my $queue_generated = ref($args{same_id_issue_order_queue_behavior}) eq 'HASH'
        && $args{same_id_issue_order_queue_behavior}{generated_behavior};
    my @families;

    if ($lifecycle_generated) {
        my %response_demux_family = _same_id_response_demux_covered_families($args{response_demux});
        for my $family (@{$lifecycle->{families} || []}) {
            my @states = @{$family->{transaction_state} || []};
            next unless @states > 1;
            push @families, {
                family                  => $family->{family},
                strategy                => 'avoid_same_id_concurrency',
                enforcement             => 'allocator_free_id_guard',
                assertion_enforcement   => 'runtime_assertion',
                response_demux_covered  => $response_demux_family{$family->{family}} ? 1 : 0,
                auto_transactions       => _clone_jsonish($family->{auto_transactions}),
                selected_id_signals     => [map { $_->{selected_id_signal} } @states],
                busy_signals            => [map { $_->{busy_signal} } @states],
                generated_assertions    => [
                    map { $_->{name} }
                    _same_id_ordering_assertion_specs_for_family($family, $args{manager_name})
                ],
            };
        }
    }

    return undef unless @families || $has_policy;

    my @policy_entry = $has_policy
        ? (concrete_id_reuse_policy => _same_id_ordering_policy_with_admitted_boundary(
            policy => $policy,
            admitted_request_boundary => $args{same_id_admitted_request_boundary},
            response_demux => $args{response_demux},
            same_id_issue_order_queue_behavior => $args{same_id_issue_order_queue_behavior},
        ))
        : ();
    if (!@families) {
        return {
            mode               => 'concrete_id_reuse_policy',
            generated_behavior => $queue_generated ? 1 : 0,
            source_anchors     => _clone_jsonish($args{source_anchors} || []),
            @policy_entry,
            residue            => $queue_generated
                ? ['per_id_issue_order_queues']
                : [
                    'concrete_id_same_id_ordering',
                    'per_id_issue_order_queues',
                ],
        };
    }

    return {
        mode               => 'auto_id_same_id_avoidance',
        generated_behavior => 1,
        strategy           => 'avoid_same_id_concurrency',
        source_anchors     => _clone_jsonish($args{source_anchors} || []),
        families           => \@families,
        @policy_entry,
        residue            => [
            'concrete_id_same_id_ordering',
            'per_id_issue_order_queues',
            'read_response_demux',
            'read_data_interleaving',
            'bursts',
        ],
    };
}

sub _same_id_ordering_policy_with_admitted_boundary(%args) {
    my $policy = _clone_jsonish($args{policy});
    my $boundary = $args{admitted_request_boundary};
    my $queue_behavior = $args{same_id_issue_order_queue_behavior};
    return $policy unless ref($policy) eq 'HASH';

    for my $family_name (qw(read write)) {
        next unless ref($policy->{$family_name}) eq 'HASH';

        if (ref($boundary) eq 'HASH') {
            my $family = $boundary->{families}{$family_name};
            if (ref($family) eq 'HASH') {
                my %admitted_boundary = %$family;
                delete $admitted_boundary{family};
                delete $admitted_boundary{assertions};
                $policy->{$family_name}{enforcement} = 'admitted_request_boundary';
                $policy->{$family_name}{implementation_status} = 'admitted_request_pulses_generated';
                $policy->{$family_name}{admitted_request_boundary} = _clone_jsonish(\%admitted_boundary);
            }
        }

        if (_response_demux_family_has_queue_head_contract($args{response_demux}, $family_name)) {
            $policy->{$family_name}{response_demux_strategy} = 'queue_head_issue_order';
            $policy->{$family_name}{response_demux_implementation_status} = 'selected_not_generated';
        }

        my $queue_family = _same_id_issue_order_queue_family_behavior($queue_behavior, $family_name);
        if (ref($queue_family) eq 'HASH') {
            $policy->{$family_name}{enforcement} = 'generated_issue_order_queue';
            $policy->{$family_name}{implementation_status} = $queue_family->{implementation_status};
            $policy->{$family_name}{accepted_same_id_reuse} = 1;
            $policy->{$family_name}{generated_queue_behavior} = 1;
            $policy->{$family_name}{queue_state_representation} = 'compact_onehot_transaction_slots';
            $policy->{$family_name}{response_demux_strategy} = 'queue_head_issue_order';
            $policy->{$family_name}{response_demux_implementation_status} = 'generated';
            $policy->{$family_name}{generated_queues} =
                _same_id_issue_order_queue_report_groups($queue_family);
        }
    }

    return $policy;
}

sub _same_id_response_demux_covered_families($response_demux) {
    return () unless ref($response_demux) eq 'HASH' && $response_demux->{generated_behavior};
    return map { $_ => 1 }
        grep {
            ref($response_demux->{$_}) eq 'HASH'
            && $response_demux->{$_}{generated_behavior}
        } qw(write read);
}

sub _build_transaction_event_dispatch(%args) {
    my $transactions = $args{transactions};
    return undef unless ref($transactions) eq 'ARRAY';

    _validate_transaction_event_roles(
        events       => $args{events},
        transactions => $transactions,
    );

    my %dispatch = (mode => 'per_transaction_event_fanin');
    for my $direction (qw(read write)) {
        my @direction_transactions = grep { $_->{kind} eq $direction } @$transactions;
        my $request_events = @direction_transactions
            ? _unique_preserving([map { $_->{request_event} } @direction_transactions])
            : [_direction_level_event($args{events}, $direction, 'request')];
        my $completion_events = @direction_transactions
            ? _unique_preserving([map { $_->{completion_event} } @direction_transactions])
            : [_direction_level_event($args{events}, $direction, 'completion')];

        $dispatch{$direction} = {
            request_events    => $request_events,
            completion_events => $completion_events,
            request_fanin     => _fanin_expression($request_events),
            completion_fanin  => _fanin_expression($completion_events),
        };
    }

    return \%dispatch;
}

sub _validate_transaction_event_roles(%args) {
    my $events = $args{events};
    my $transactions = $args{transactions};
    my %role_by_event;

    for my $transaction (@$transactions) {
        for my $phase (qw(request completion)) {
            my $field = "${phase}_event";
            my $event = $transaction->{$field};
            my $role = "$transaction->{kind} $phase";
            confess "AXI manager capacity/status IAL2 contract transaction event '$event' cannot be reused for both $role_by_event{$event} and $role roles\n"
                if exists($role_by_event{$event}) && $role_by_event{$event} ne $role;
            $role_by_event{$event} = $role;
        }
    }

    for my $direction (qw(read write)) {
        my @direction_transactions = grep { $_->{kind} eq $direction } @$transactions;
        for my $phase (qw(request completion)) {
            my $field = "${phase}_event";
            my $direction_event = _direction_level_event($events, $direction, $phase);
            my $uses_distinct_event = grep { $_->{$field} ne $direction_event } @direction_transactions;
            next unless $uses_distinct_event;

            my %seen_by_transaction;
            for my $transaction (@direction_transactions) {
                my $event = $transaction->{$field};
                confess "AXI manager capacity/status IAL2 contract $direction ${field} '$event' is reused by transactions '$seen_by_transaction{$event}' and '$transaction->{name}' while using per-transaction dispatch\n"
                    if exists $seen_by_transaction{$event};
                $seen_by_transaction{$event} = $transaction->{name};
            }
        }
    }
}

sub _direction_level_event($events, $direction, $phase) {
    return $events->{read_submit} if $direction eq 'read' && $phase eq 'request';
    return $events->{read_complete} if $direction eq 'read' && $phase eq 'completion';
    return $events->{write_submit} if $direction eq 'write' && $phase eq 'request';
    return $events->{write_complete} if $direction eq 'write' && $phase eq 'completion';
    confess "Internal error: unknown AXI manager event direction/phase '$direction/$phase'\n";
}

sub _fanin_expression($events) {
    confess "Internal error: AXI manager fan-in requires at least one event\n"
        unless ref($events) eq 'ARRAY' && @$events;
    return $events->[0] if @$events == 1;
    return "(| " . join(' ', @$events) . ")";
}

sub _effective_event_inputs(%args) {
    my %generated_completion = _response_demux_generated_completion_signal_map($args{response_demux});
    my @response_events = _response_demux_response_event_inputs($args{response_demux});
    my $dispatch = $args{transaction_event_dispatch};
    if (ref($dispatch) eq 'HASH') {
        my @inputs;
        for my $direction (qw(read write)) {
            push @inputs, @{$dispatch->{$direction}{request_events}};
            push @inputs, grep { !$generated_completion{$_} } @{$dispatch->{$direction}{completion_events}};
        }
        push @inputs, @response_events;
        return _unique_preserving(\@inputs);
    }

    return _unique_preserving([
        @{_abstract_event_names($args{events})},
        @response_events,
    ]);
}

sub _response_demux_generated_completion_signal_map($response_demux) {
    my %generated;
    return %generated unless ref($response_demux) eq 'HASH';

    for my $family (qw(write read)) {
        my $entry = $response_demux->{$family};
        next unless ref($entry) eq 'HASH' && $entry->{generated_behavior};
        for my $signal (@{$entry->{generated_completion_signals} || []}) {
            $generated{$signal} = 1;
        }
    }
    return %generated;
}

sub _response_demux_response_event_inputs($response_demux) {
    return () unless ref($response_demux) eq 'HASH';
    return map { $response_demux->{$_}{response_event} }
        grep {
            ref($response_demux->{$_}) eq 'HASH'
            && $response_demux->{$_}{generated_behavior}
        } qw(write read);
}

sub _build_id_response_rule_engine(%args) {
    my $transactions = $args{transactions};
    my $id_families = $args{id_families};
    return undef unless ref($transactions) eq 'ARRAY' && ref($id_families) eq 'HASH';

    my @checks;
    my @id_signal_inputs;
    my %seen_concrete_event;
    my %seen_concrete_id;
    for my $transaction (@$transactions) {
        my $id = $transaction->{id};
        next unless ref($id) eq 'HASH' && ($id->{policy} // '') eq 'concrete';

        my $family = $id_families->{$transaction->{kind}};
        confess "Internal error: concrete AXI transaction ID missing normalized ID family\n"
            unless ref($family) eq 'HASH' && $family->{present};

        for my $phase_spec (
            [request  => 'request_event'    => 'request_id_signal'],
            [response => 'completion_event' => 'response_id_signal'],
        ) {
            my ($phase, $event_field, $signal_field) = @$phase_spec;
            my $id_signal = $family->{$signal_field};
            my $event = $transaction->{$event_field};
            my $event_key = "$phase\0$event";
            if (my $previous = $seen_concrete_event{$event_key}) {
                confess "AXI manager capacity/status IAL2 contract concrete ID assertions require unique $phase events; event '$event' is shared by transactions '$previous->{transaction}' and '$transaction->{name}'\n";
            }
            $seen_concrete_event{$event_key} = {
                transaction => $transaction->{name},
            };
            push @id_signal_inputs, $id_signal;
            push @checks, {
                transaction => $transaction->{name},
                tag         => $transaction->{tag},
                kind        => $transaction->{kind},
                phase       => $phase,
                event       => $event,
                id_signal   => $id_signal,
                id_value    => $id->{value},
                family_width => $id->{family_width},
                enforcement => 'runtime_assertion',
                assertion_name => "$transaction->{name}_${phase}_id_matches",
            };
        }

        my $id_key = "$transaction->{kind}\0$id->{value}";
        if (my $previous = $seen_concrete_id{$id_key}) {
            my $same_id_policy = _same_id_ordering_policy_for_family(
                $args{same_id_ordering_policy},
                $transaction->{kind},
            );
            if (ref($same_id_policy) eq 'HASH' && ($same_id_policy->{policy} // '') eq 'reject') {
                confess "AXI manager capacity/status IAL2 contract concrete $transaction->{kind} ID value $id->{value} is reused by transactions '$previous->{transaction}' and '$transaction->{name}'; selected same-id-ordering.$transaction->{kind} concrete-id-reuse reject policy rejects concrete same-ID reuse\n";
            }
            if (ref($same_id_policy) eq 'HASH' && ($same_id_policy->{policy} // '') eq 'issue_order_queue') {
                next if _response_demux_family_has_queue_head_contract(
                    $args{response_demux},
                    $transaction->{kind},
                );
                confess "AXI manager capacity/status IAL2 contract concrete $transaction->{kind} ID value $id->{value} is reused by transactions '$previous->{transaction}' and '$transaction->{name}'; selected same-id-ordering.$transaction->{kind} concrete-id-reuse issue-order-queue policy is selected_not_generated, so concrete same-ID reuse remains unsupported until generated issue-order queue behavior ships\n";
            }
            confess "AXI manager capacity/status IAL2 contract concrete $transaction->{kind} ID value $id->{value} is reused by transactions '$previous->{transaction}' and '$transaction->{name}'; concrete same-ID reuse requires a selected same-ID ordering policy or per-ID issue-order queue\n";
        }
        $seen_concrete_id{$id_key} = {
            transaction => $transaction->{name},
        };
    }

    return undef unless @checks;
    return {
        mode => 'concrete_id_assertions',
        id_signal_inputs => _unique_preserving(\@id_signal_inputs),
        checks => \@checks,
        residue => [
            'auto_id_allocation',
            'id_release',
            'same_id_ordering',
            'response_demux',
        ],
    };
}

sub _same_id_ordering_policy_for_family($policy, $family) {
    return undef unless ref($policy) eq 'HASH';
    return $policy->{$family};
}

sub _build_same_id_admitted_request_boundary(%args) {
    my $policy = $args{same_id_ordering_policy};
    return undef unless ref($policy) eq 'HASH';

    my %families;
    for my $family_name (qw(write read)) {
        my $policy_entry = _same_id_ordering_policy_for_family($policy, $family_name);
        next unless ref($policy_entry) eq 'HASH'
            && ($policy_entry->{policy} // '') eq 'issue_order_queue';

        my $transactions = $args{transactions};
        confess "AXI manager capacity/status IAL2 contract same-id-ordering.$family_name concrete-id-reuse issue-order-queue requires transactions metadata\n"
            unless ref($transactions) eq 'ARRAY';

        my $id_family = ref($args{id_families}) eq 'HASH' ? $args{id_families}{$family_name} : undef;
        confess "AXI manager capacity/status IAL2 contract same-id-ordering.$family_name concrete-id-reuse issue-order-queue requires a declared $family_name ID family\n"
            unless ref($id_family) eq 'HASH';
        confess "AXI manager capacity/status IAL2 contract same-id-ordering.$family_name concrete-id-reuse issue-order-queue requires positive $family_name ID-family width\n"
            unless $id_family->{present};

        my @concrete_transactions = grep {
            ($_->{kind} // '') eq $family_name
                && ref($_->{id}) eq 'HASH'
                && ($_->{id}{policy} // '') eq 'concrete'
        } @$transactions;
        confess "AXI manager capacity/status IAL2 contract same-id-ordering.$family_name concrete-id-reuse issue-order-queue requires at least one concrete $family_name transaction\n"
            unless @concrete_transactions;

        my %seen_request_event;
        for my $transaction (@concrete_transactions) {
            my $event = $transaction->{request_event};
            confess "AXI manager capacity/status IAL2 contract same-id-ordering.$family_name concrete-id-reuse issue-order-queue admitted request pulses require unique $family_name request events; event '$event' is shared by transactions '$seen_request_event{$event}' and '$transaction->{name}'\n"
                if exists $seen_request_event{$event};
            $seen_request_event{$event} = $transaction->{name};
        }

        my $dispatch = $args{transaction_event_dispatch};
        confess "Internal error: same-ID admitted request boundary requires transaction event dispatch metadata\n"
            unless ref($dispatch) eq 'HASH' && ref($dispatch->{$family_name}) eq 'HASH';

        my $pending_storage = _same_id_admitted_request_pending_storage(%args, family => $family_name);
        my $max_pending = _same_id_admitted_request_max_pending(%args, family => $family_name);
        my $completion_fanin = $dispatch->{$family_name}{completion_fanin};
        my @pulses = map {
            my $transaction = $_;
            my $prefix = "$args{manager_name}_$transaction->{name}";
            my $guard = _same_id_admitted_request_guard_expr(
                request_event    => $transaction->{request_event},
                pending_storage  => $pending_storage,
                max_pending      => $max_pending,
                completion_fanin => $completion_fanin,
            );
            +{
                transaction   => $transaction->{name},
                tag           => $transaction->{tag},
                concrete_id   => $transaction->{id}{value},
                request_event => $transaction->{request_event},
                pulse         => "${prefix}_admitted_request_pulse_q",
                rule          => "${prefix}_admitted_request",
                guard         => $guard,
            }
        } @concrete_transactions;
        my @selected_request_events = @{_unique_preserving([map { $_->{request_event} } @concrete_transactions])};
        my @assertions = @selected_request_events > 1
            ? ({
                name      => "$args{manager_name}_${family_name}_issue_order_queue_request_onehot0",
                condition => _same_id_at_most_one_expr(@selected_request_events),
                message   => "$args{manager_name} $family_name same-ID issue-order queue requests are mutually exclusive",
            })
            : ();

        $families{$family_name} = {
            family                  => $family_name,
            guard_source            => 'capacity_storage_and_completion_fanin',
            pending_storage         => $pending_storage,
            max_pending             => $max_pending,
            completion_fanin        => $completion_fanin,
            selected_request_events => \@selected_request_events,
            generated_pulses        => \@pulses,
            generated_assertions    => [map { $_->{name} } @assertions],
            assertions              => \@assertions,
        };
    }

    return undef unless %families;
    return {
        mode     => 'admitted_request_pulses',
        families => \%families,
    };
}

sub _same_id_admitted_request_pending_storage(%args) {
    return $args{storage}{pending_reads} if $args{family} eq 'read';
    return $args{storage}{pending_writes} if $args{family} eq 'write';
    confess "Internal error: unknown same-ID admitted request family '$args{family}'\n";
}

sub _same_id_admitted_request_max_pending(%args) {
    return $args{read_max_pending} if $args{family} eq 'read';
    return $args{write_max_pending} if $args{family} eq 'write';
    confess "Internal error: unknown same-ID admitted request family '$args{family}'\n";
}

sub _build_same_id_issue_order_queue_behavior(%args) {
    my $demux = $args{response_demux};
    return undef unless ref($demux) eq 'HASH';

    my @queue_head_families = grep {
        _response_demux_family_has_queue_head_contract($demux, $_)
    } qw(write read);
    return undef unless @queue_head_families == 1;

    my $family_name = $queue_head_families[0];
    my $entry = $demux->{$family_name};
    return undef unless ref($entry) eq 'HASH' && !$entry->{generated_behavior};
    if ($family_name eq 'read') {
        my $scope = $entry->{response_scope} // '';
        return undef unless (
            $scope eq 'single_beat'
                && !defined $entry->{last_signal}
        ) || (
            $scope eq 'burst_last'
                && ($entry->{last_signal_width} // 0) == 1
        );
    }

    my $groups = $entry->{same_id_issue_order_queues};
    return undef unless ref($groups) eq 'ARRAY' && @$groups == 1;

    my $group = $groups->[0];
    return undef unless ref($group) eq 'HASH'
        && ($group->{depth} // 0) == 2
        && ref($group->{transactions}) eq 'ARRAY'
        && @{$group->{transactions}} == 2;

    my $policy = _same_id_ordering_policy_for_family($args{same_id_ordering_policy}, $family_name);
    return undef unless ref($policy) eq 'HASH'
        && ($policy->{policy} // '') eq 'issue_order_queue';

    my $boundary = $args{same_id_admitted_request_boundary};
    return undef unless ref($boundary) eq 'HASH'
        && ref($boundary->{families}{$family_name}) eq 'HASH';

    my $id_family = ref($args{id_families}) eq 'HASH' ? $args{id_families}{$family_name} : undef;
    return undef unless ref($id_family) eq 'HASH' && $id_family->{present};

    my %transaction_by_name = map { $_->{name} => $_ } @{$args{transactions} || []};
    my %pulse_by_transaction = map { $_->{transaction} => $_ }
        @{$boundary->{families}{$family_name}{generated_pulses} || []};
    my @transactions;
    for my $transaction_name (@{$group->{transactions}}) {
        my $transaction = $transaction_by_name{$transaction_name};
        my $pulse = $pulse_by_transaction{$transaction_name};
        return undef unless ref($transaction) eq 'HASH'
            && ($transaction->{kind} // '') eq $family_name
            && ref($transaction->{id}) eq 'HASH'
            && ($transaction->{id}{policy} // '') eq 'concrete'
            && ($transaction->{id}{value} // -1) == ($group->{concrete_id} // -2)
            && ref($pulse) eq 'HASH';
        push @transactions, {
            transaction    => $transaction->{name},
            tag            => $transaction->{tag},
            request_event  => $transaction->{request_event},
            completion_event => $transaction->{completion_event},
            admitted_pulse => $pulse->{pulse},
        };
    }

    my $prefix = _same_id_issue_order_queue_group_prefix(
        $args{manager_name},
        $family_name,
        $group->{concrete_id},
    );
    my %slot_signal;
    my @storage;
    for my $slot (0 .. 1) {
        for my $transaction (@transactions) {
            my $signal = "${prefix}_slot${slot}_$transaction->{transaction}_q";
            $slot_signal{$slot}{$transaction->{transaction}} = $signal;
            push @storage, $signal;
        }
    }

    for my $transaction (@transactions) {
        $transaction->{head_signal} = $slot_signal{0}{$transaction->{transaction}};
        $transaction->{slot_signals} = [
            map { $slot_signal{$_}{$transaction->{transaction}} } 0 .. 1
        ];
    }

    my $implementation_status = $family_name eq 'write'
        ? 'generated_write_bid_queue_head_demux'
        : ($entry->{response_scope} // '') eq 'single_beat'
            ? 'generated_read_single_beat_queue_head_demux'
            : 'generated_read_burst_last_queue_head_demux';
    my $queue_group = {
        family                  => $family_name,
        implementation_status   => $implementation_status,
        concrete_id             => $group->{concrete_id},
        concrete_id_literal     => _sized_decimal_literal($id_family->{width}, $group->{concrete_id}),
        id_width                => $id_family->{width},
        depth                   => 2,
        queue_state_representation => 'compact_onehot_transaction_slots',
        dequeue_event_source    => 'queue_head_response_demux',
        response_event          => $entry->{response_event},
        response_id_signal      => $entry->{response_id_signal},
        prefix                  => $prefix,
        transactions            => \@transactions,
        slot_signals            => \%slot_signal,
        storage                 => \@storage,
    };
    $queue_group->{last_signal} = $entry->{last_signal}
        if defined $entry->{last_signal};
    $queue_group->{transition_rules} = [
        map { $_->{name} } _same_id_issue_order_queue_transition_specs($queue_group)
    ];
    $queue_group->{generated_assertions} = [
        map { $_->{name} } _same_id_issue_order_queue_assertion_specs_for_group($queue_group)
    ];

    return {
        mode               => 'bounded_same_id_issue_order_queue',
        generated_behavior => 1,
        families           => {
            $family_name => {
                family                => $family_name,
                generated_behavior    => 1,
                implementation_status => $implementation_status,
                groups                => [$queue_group],
            },
        },
    };
}

sub _response_demux_with_same_id_issue_order_queue_behavior(%args) {
    my $demux = $args{response_demux};
    my $behavior = $args{behavior};
    return $demux unless ref($demux) eq 'HASH'
        && ref($behavior) eq 'HASH'
        && $behavior->{generated_behavior};

    my $updated = _clone_jsonish($demux);
    for my $family_name (qw(read write)) {
        my $family = $behavior->{families}{$family_name};
        next unless ref($family) eq 'HASH' && $family->{generated_behavior};
        my $entry = $updated->{$family_name};
        next unless ref($entry) eq 'HASH';

        $entry->{generated_behavior} = 1;
        $entry->{implementation_status} = 'generated';
        $entry->{generated_queue_behavior} = 1;
        $entry->{generated_queue_behavior_boundary} = $family->{implementation_status};
        $entry->{generated_completion_signals} = delete($entry->{selected_completion_signals}) || [];
    }
    my $generated_family_count = grep {
        ref($updated->{$_}) eq 'HASH' && $updated->{$_}{generated_behavior}
    } qw(write read);
    $updated->{generated_behavior} = $generated_family_count ? 1 : 0;
    $updated->{residue} = [
        grep { $_ ne 'generated_same_id_queue_head_demux' }
        @{$updated->{residue} || []}
    ];
    return $updated;
}

sub _same_id_issue_order_queue_family_behavior($behavior, $family_name) {
    return undef unless ref($behavior) eq 'HASH' && $behavior->{generated_behavior};
    my $family = $behavior->{families}{$family_name};
    return ref($family) eq 'HASH' && $family->{generated_behavior} ? $family : undef;
}

sub _same_id_issue_order_queue_groups($behavior, $family_name) {
    my $family = _same_id_issue_order_queue_family_behavior($behavior, $family_name);
    return () unless ref($family) eq 'HASH';
    return @{$family->{groups} || []};
}

sub _same_id_issue_order_queue_report_groups($family) {
    return [] unless ref($family) eq 'HASH';

    return [
        map {
            my $group = $_;
            my $report = {
                family                  => $group->{family},
                concrete_id             => $group->{concrete_id},
                depth                   => $group->{depth},
                queue_state_representation => $group->{queue_state_representation},
                dequeue_event_source    => $group->{dequeue_event_source},
                response_event          => $group->{response_event},
                response_id_signal      => $group->{response_id_signal},
                transactions            => [map { $_->{transaction} } @{$group->{transactions} || []}],
                slot_storage            => _clone_jsonish($group->{storage}),
                enqueue_pulses          => [
                    map {
                        +{
                            transaction => $_->{transaction},
                            pulse       => $_->{admitted_pulse},
                        }
                    } @{$group->{transactions} || []}
                ],
                generated_update_rules  => _clone_jsonish($group->{transition_rules}),
                generated_assertions    => _clone_jsonish($group->{generated_assertions}),
            };
            $report->{last_signal} = $group->{last_signal}
                if defined $group->{last_signal};
            $report;
        } @{$family->{groups} || []}
    ];
}

sub _same_id_issue_order_queue_group_prefix($manager_name, $family_name, $concrete_id) {
    return "${manager_name}_${family_name}_id${concrete_id}_same_id_issue_order";
}

sub _same_id_admitted_request_guard_expr(%args) {
    return _and_expr(
        $args{request_event},
        _or_expr(
            _lt_expr($args{pending_storage}, $args{max_pending}),
            $args{completion_fanin},
        ),
    );
}

sub _same_id_at_most_one_expr(@terms) {
    return '1' if @terms < 2;

    my @overlaps;
    for my $left_index (0 .. $#terms) {
        for my $right_index ($left_index + 1 .. $#terms) {
            push @overlaps, _and_expr($terms[$left_index], $terms[$right_index]);
        }
    }

    return _not_expr(_or_expr(@overlaps));
}

sub _reject_forbidden_or_duplicate_names(%args) {
    my $event_names = _unique_preserving([
        @{_abstract_event_names($args{events})},
        @{$args{event_inputs} || []},
    ]);
    my %seen;
    my @groups = (
        [clock   => [$args{clock}]],
        [reset   => [$args{reset}]],
        [events  => $event_names],
        [status  => [values %{$args{status}}]],
        [storage => [values %{$args{storage}}]],
    );
    push @groups, [id_families => _id_family_signal_names($args{id_families})]
        if defined $args{id_families};
    push @groups, [transactions => _transaction_names_and_tags($args{transactions})]
        if defined $args{transactions};
    push @groups, [auto_id_lifecycle => _auto_id_generated_signal_names($args{auto_id_lifecycle})]
        if defined $args{auto_id_lifecycle};
    push @groups, [response_demux => _response_demux_signal_names($args{response_demux})]
        if defined $args{response_demux};
    push @groups, [read_data => _read_data_signal_names($args{read_data})]
        if defined $args{read_data};
    push @groups, [same_id_admitted_request_boundary => _same_id_admitted_request_signal_names($args{same_id_admitted_request_boundary})]
        if defined $args{same_id_admitted_request_boundary};
    push @groups, [same_id_issue_order_queue_behavior => _same_id_issue_order_queue_signal_names($args{same_id_issue_order_queue_behavior})]
        if defined $args{same_id_issue_order_queue_behavior};

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

sub _abstract_event_names($events) {
    return [
        $events->{read_submit},
        $events->{read_complete},
        $events->{write_submit},
        $events->{write_complete},
    ];
}

sub _transaction_names_and_tags($transactions) {
    my @names;
    return \@names unless ref($transactions) eq 'ARRAY';

    for my $transaction (@$transactions) {
        push @names, $transaction->{name}, $transaction->{tag};
    }

    return \@names;
}

sub _unique_preserving($values) {
    my (%seen, @unique);
    for my $value (@$values) {
        next if $seen{$value}++;
        push @unique, $value;
    }
    return \@unique;
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

sub _auto_id_generated_signal_names($auto_id_lifecycle) {
    my @names;
    return \@names unless ref($auto_id_lifecycle) eq 'HASH';

    for my $family (@{$auto_id_lifecycle->{families} || []}) {
        for my $state (@{$family->{transaction_state} || []}) {
            push @names, $state->{selected_id_signal}, $state->{busy_signal};
        }
    }

    return \@names;
}

sub _response_demux_signal_names($response_demux) {
    return [] unless ref($response_demux) eq 'HASH';
    my @signals;
    for my $family (qw(write read)) {
        my $entry = $response_demux->{$family};
        next unless ref($entry) eq 'HASH';
        push @signals, $entry->{last_signal}
            if defined $entry->{last_signal};
        push @signals, @{$entry->{generated_completion_signals} || []}
            if $entry->{generated_behavior};
    }
    return _clone_jsonish(\@signals);
}

sub _read_data_signal_names($read_data) {
    return [] unless ref($read_data) eq 'HASH';

    my @signals;
    my $read = $read_data->{read};
    if (ref($read) eq 'HASH') {
        push @signals, grep { defined $_ } $read->{data_signal}, $read->{status_signal};
        push @signals, $read->{burst_length_signal}
            if defined $read->{burst_length_signal};
        for my $transaction (@{$read->{transactions} || []}) {
            push @signals, grep { defined $_ }
                $transaction->{data_output},
                $transaction->{status_output},
                $transaction->{status_aggregate_output},
                $transaction->{valid_mask_output},
                $transaction->{length_output};
            push @signals, @{$transaction->{generated_data_outputs} || []};
            push @signals, @{$transaction->{generated_status_outputs} || []};
            push @signals, $transaction->{burst_length_storage}
                if exists($transaction->{burst_length_storage})
                    && defined($transaction->{burst_length_storage});
            push @signals, $transaction->{expected_beat_count_storage}
                if exists($transaction->{expected_beat_count_storage})
                    && defined($transaction->{expected_beat_count_storage});
            push @signals, $transaction->{beat_count_storage}
                if exists($transaction->{beat_count_storage})
                    && defined($transaction->{beat_count_storage});
        }
    }

    return \@signals;
}

sub _same_id_admitted_request_signal_names($boundary) {
    return [] unless ref($boundary) eq 'HASH';

    my @signals;
    for my $family_name (qw(write read)) {
        my $family = $boundary->{families}{$family_name};
        next unless ref($family) eq 'HASH';
        push @signals, map { $_->{pulse} } @{$family->{generated_pulses} || []};
    }

    return \@signals;
}

sub _same_id_issue_order_queue_signal_names($behavior) {
    return [] unless ref($behavior) eq 'HASH';

    my @signals;
    for my $family_name (qw(write read)) {
        for my $group (_same_id_issue_order_queue_groups($behavior, $family_name)) {
            push @signals, @{$group->{storage} || []};
        }
    }

    return \@signals;
}

sub _read_data_payload_capture_enabled($read) {
    return _read_data_scalar_payload_capture_enabled($read)
        || _read_data_multi_beat_payload_capture_enabled($read);
}

sub _read_data_scalar_payload_capture_enabled($read) {
    return ref($read) eq 'HASH'
        && ($read->{capture_scope} // '') =~ /\A(?:single_beat|last_beat)\z/;
}

sub _read_data_multi_beat_payload_capture_enabled($read) {
    return ref($read) eq 'HASH'
        && ($read->{capture_scope} // '') eq 'multi_beat'
        && ($read->{multi_beat_reassembly_generated_behavior} || 0);
}

sub _read_data_source_inputs($contract) {
    my $read_data = $contract->{read_data};
    return () unless ref($read_data) eq 'HASH' && $read_data->{generated_behavior};
    my $read = $read_data->{read};
    return () unless ref($read) eq 'HASH';
    my @inputs;
    push @inputs, $read->{data_signal}, $read->{status_signal}
        if _read_data_payload_capture_enabled($read);
    push @inputs, $read->{burst_length_signal}
        if $read->{burst_length_generated_behavior};
    return @{_unique_preserving(\@inputs)};
}

sub _read_data_output_lines($contract) {
    my $read_data = $contract->{read_data};
    return () unless ref($read_data) eq 'HASH' && $read_data->{generated_behavior};
    my $read = $read_data->{read};
    return () unless ref($read) eq 'HASH';

    my @lines;
    if (_read_data_scalar_payload_capture_enabled($read)) {
        for my $transaction (@{$read->{transactions} || []}) {
            push @lines,
                _width_output_line($transaction->{data_output}, $transaction->{data_width}),
                _width_output_line($transaction->{status_output}, $transaction->{status_width});
        }
    }
    if (_read_data_multi_beat_payload_capture_enabled($read)) {
        for my $transaction (@{$read->{transactions} || []}) {
            push @lines,
                (map { _width_output_line($_, $transaction->{data_width}) }
                    @{$transaction->{generated_data_outputs} || []}),
                (map { _width_output_line($_, $transaction->{status_width}) }
                    @{$transaction->{generated_status_outputs} || []}),
                (defined($transaction->{status_aggregate_output})
                    ? (_width_output_line(
                        $transaction->{status_aggregate_output},
                        $transaction->{status_aggregate_output_width},
                    ))
                    : ()),
                _width_output_line($transaction->{valid_mask_output}, $transaction->{valid_mask_width}),
                _width_output_line($transaction->{length_output}, $transaction->{length_output_width});
        }
    }
    return @lines;
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
    my $read_events = _effective_direction_events($contract, 'read');
    my $write_events = _effective_direction_events($contract, 'write');
    my @read_rules = _direction_rules(
        direction => 'read',
        submit => $read_events->{request_fanin},
        complete => $read_events->{completion_fanin},
        max_pending => $contract->{read_max_pending},
        storage => $contract->{storage}{pending_reads},
        pending_output => $contract->{status_outputs}{pending_reads},
        slots_output => $contract->{status_outputs}{read_slots_available},
        full_output => $contract->{status_outputs}{read_full},
        can_accept_output => $contract->{status_outputs}{read_can_accept},
    );
    my @write_rules = _direction_rules(
        direction => 'write',
        submit => $write_events->{request_fanin},
        complete => $write_events->{completion_fanin},
        max_pending => $contract->{write_max_pending},
        storage => $contract->{storage}{pending_writes},
        pending_output => $contract->{status_outputs}{pending_writes},
        slots_output => $contract->{status_outputs}{write_slots_available},
        full_output => $contract->{status_outputs}{write_full},
        can_accept_output => $contract->{status_outputs}{write_can_accept},
    );
    my $interface_inputs = _unique_preserving([
        @{$contract->{event_inputs}},
        @{_id_response_signal_inputs($contract)},
        _response_demux_response_id_inputs($contract),
        _read_data_source_inputs($contract),
    ]);
    my @id_response_assertions = _id_response_assertion_transaction_lines($contract);
    my @response_demux_assertions = _response_demux_assertion_transaction_lines($contract);
    my @read_data_beat_count_assertions = _read_data_beat_count_assertion_transaction_lines($contract);
    my @same_id_ordering_assertions = _same_id_ordering_assertion_transaction_lines($contract);
    my @auto_id_assertions = _auto_id_lifecycle_assertion_transaction_lines($contract);
    my @assertion_transactions = (
        @id_response_assertions,
        @response_demux_assertions,
        @read_data_beat_count_assertions,
        @same_id_ordering_assertions,
        @auto_id_assertions,
    );
    my @auto_id_priorities = _auto_id_lifecycle_priority_lines($contract);
    my @same_id_issue_order_queue_priorities = _same_id_issue_order_queue_priority_lines($contract);
    my @same_id_admitted_request_rules = _same_id_admitted_request_rule_lines($contract);
    my @same_id_issue_order_queue_rules = _same_id_issue_order_queue_rule_lines($contract);
    my @response_demux_rules = _response_demux_rule_lines($contract);
    my @read_data_burst_length_capture_rules = _read_data_burst_length_capture_rule_lines($contract);
    my @read_data_beat_count_rules = _read_data_beat_count_rule_lines($contract);
    my @read_data_multi_beat_output_init_rules = _read_data_multi_beat_output_init_rule_lines($contract);
    my @read_data_capture_rules = _read_data_capture_rule_lines($contract);
    my @auto_id_rules = _auto_id_lifecycle_rule_lines($contract);
    my @storage_lines = (
        "    (var $contract->{storage}{pending_reads} (width $read_width))",
        "    (var $contract->{storage}{pending_writes} (width $write_width))",
        _same_id_admitted_request_storage_lines($contract),
        _same_id_issue_order_queue_storage_lines($contract),
        _auto_id_lifecycle_storage_lines($contract),
        _read_data_burst_length_storage_lines($contract),
        _read_data_beat_count_storage_lines($contract),
    );
    $storage_lines[-1] .= ")";

    return join("\n",
        "(actor $contract->{actor_name}",
        "  (clock $contract->{clock})",
        "  $reset",
        "  (interface",
        (map { _input_line($contract, $_) } @$interface_inputs),
        "    (output $contract->{status_outputs}{read_can_accept})",
        "    (output $contract->{status_outputs}{write_can_accept})",
        "    (output $contract->{status_outputs}{read_full})",
        "    (output $contract->{status_outputs}{write_full})",
        _width_output_line($contract->{status_outputs}{pending_reads}, $read_width),
        _width_output_line($contract->{status_outputs}{pending_writes}, $write_width),
        _width_output_line($contract->{status_outputs}{read_slots_available}, $read_width),
        _width_output_line($contract->{status_outputs}{write_slots_available}, $write_width),
        _auto_id_lifecycle_request_output_lines($contract),
        _response_demux_completion_output_lines($contract),
        _read_data_output_lines($contract),
        "  )",
        "  (storage",
        @storage_lines,
        "",
        @auto_id_priorities,
        (@auto_id_priorities ? ("") : ()),
        @same_id_issue_order_queue_priorities,
        (@same_id_issue_order_queue_priorities ? ("") : ()),
        @assertion_transactions,
        (@assertion_transactions ? ("") : ()),
        @same_id_admitted_request_rules,
        (@same_id_admitted_request_rules ? ("") : ()),
        @same_id_issue_order_queue_rules,
        (@same_id_issue_order_queue_rules ? ("") : ()),
        @response_demux_rules,
        (@response_demux_rules ? ("") : ()),
        @read_data_burst_length_capture_rules,
        (@read_data_burst_length_capture_rules ? ("") : ()),
        @read_data_beat_count_rules,
        (@read_data_beat_count_rules ? ("") : ()),
        @read_data_multi_beat_output_init_rules,
        (@read_data_multi_beat_output_init_rules ? ("") : ()),
        @read_data_capture_rules,
        (@read_data_capture_rules ? ("") : ()),
        @auto_id_rules,
        (@auto_id_rules ? ("") : ()),
        @read_rules,
        "",
        @write_rules,
        ")",
        "",
    );
}

sub _id_response_signal_inputs($contract) {
    my $engine = $contract->{id_response_rule_engine};
    return [] unless ref($engine) eq 'HASH';
    return $engine->{id_signal_inputs} || [];
}

sub _response_demux_response_id_inputs($contract) {
    my $demux = $contract->{response_demux};
    return () unless ref($demux) eq 'HASH' && $demux->{generated_behavior};
    my @signals;
    for my $family (qw(write read)) {
        my $entry = $demux->{$family};
        next unless ref($entry) eq 'HASH' && $entry->{generated_behavior};
        push @signals, $entry->{response_id_signal};
        push @signals, $entry->{last_signal}
            if defined $entry->{last_signal};
    }
    return @{_unique_preserving(\@signals)};
}

sub _input_line($contract, $name) {
    my $width = _input_width($contract, $name);
    return "    (input $name)" if !defined($width) || $width == 1;
    return "    (input $name (width $width))";
}

sub _input_width($contract, $name) {
    my $width = _id_signal_input_width($contract, $name);
    return $width if defined $width;
    $width = _response_demux_signal_input_width($contract, $name);
    return $width if defined $width;
    return _read_data_signal_input_width($contract, $name);
}

sub _id_signal_input_width($contract, $name) {
    my $families = $contract->{id_families};
    return undef unless ref($families) eq 'HASH';
    for my $family (qw(read write)) {
        my $entry = $families->{$family} || {};
        next unless $entry->{present};
        return $entry->{width}
            if ($entry->{request_id_signal} // '') eq $name
            || ($entry->{response_id_signal} // '') eq $name;
    }
    return undef;
}

sub _read_data_signal_input_width($contract, $name) {
    my $read_data = $contract->{read_data};
    return undef unless ref($read_data) eq 'HASH' && $read_data->{generated_behavior};
    my $read = $read_data->{read};
    return undef unless ref($read) eq 'HASH';
    if (_read_data_payload_capture_enabled($read)) {
        return $read->{data_signal_width} if ($read->{data_signal} // '') eq $name;
        return $read->{status_signal_width} if ($read->{status_signal} // '') eq $name;
    }
    return $read->{burst_length_signal_width}
        if $read->{burst_length_generated_behavior}
            && ($read->{burst_length_signal} // '') eq $name;
    return undef;
}

sub _response_demux_signal_input_width($contract, $name) {
    my $demux = $contract->{response_demux};
    return undef unless ref($demux) eq 'HASH' && $demux->{generated_behavior};
    for my $family (qw(write read)) {
        my $entry = $demux->{$family};
        next unless ref($entry) eq 'HASH' && $entry->{generated_behavior};
        return $entry->{last_signal_width}
            if defined($entry->{last_signal}) && $entry->{last_signal} eq $name;
    }
    return undef;
}

sub _id_response_assertion_transaction_lines($contract) {
    my $engine = $contract->{id_response_rule_engine};
    return () unless ref($engine) eq 'HASH' && @{$engine->{checks} || []};

    my @lines = ("  (transaction $contract->{name}_id_response_checks");
    for my $check (@{$engine->{checks}}) {
        my $message = "$contract->{name} $check->{transaction} $check->{phase} ID matches concrete ID";
        push @lines,
            "    (assert (=> $check->{event} (== $check->{id_signal} $check->{id_value})) "
            . _quoted_isf_string($message) . ")";
    }
    push @lines, "  )";
    return @lines;
}

sub _response_demux_assertion_transaction_lines($contract) {
    my @assertions = _response_demux_assertion_specs($contract);
    return () unless @assertions;

    my @lines = ("  (transaction $contract->{name}_response_demux_checks");
    for my $assertion (@assertions) {
        push @lines,
            "    (assert $assertion->{condition} " . _quoted_isf_string($assertion->{message}) . ")";
    }
    push @lines, "  )";
    return @lines;
}

sub _read_data_beat_count_assertion_transaction_lines($contract) {
    my @assertions = _read_data_beat_count_assertion_specs($contract);
    return () unless @assertions;

    my @lines = ("  (transaction $contract->{name}_read_data_beat_count_checks");
    for my $assertion (@assertions) {
        push @lines,
            "    (assert $assertion->{condition} " . _quoted_isf_string($assertion->{message}) . ")";
    }
    push @lines, "  )";
    return @lines;
}

sub _auto_id_lifecycle_request_output_lines($contract) {
    my $lifecycle = $contract->{auto_id_lifecycle};
    return () unless ref($lifecycle) eq 'HASH';

    return map {
        _width_output_line($_->{request_id_signal}, _auto_id_family_width($contract, $_->{family}))
    } @{$lifecycle->{families} || []};
}

sub _response_demux_completion_output_lines($contract) {
    my $demux = $contract->{response_demux};
    return () unless ref($demux) eq 'HASH' && $demux->{generated_behavior};
    return map { _width_output_line($_, 1) } @{_unique_preserving([
        map { @{$demux->{$_}{generated_completion_signals} || []} }
        grep {
            ref($demux->{$_}) eq 'HASH'
            && $demux->{$_}{generated_behavior}
        } qw(write read)
    ])};
}

sub _auto_id_lifecycle_storage_lines($contract) {
    my $lifecycle = $contract->{auto_id_lifecycle};
    return () unless ref($lifecycle) eq 'HASH';

    my @lines;
    for my $family (@{$lifecycle->{families} || []}) {
        my $width = _auto_id_family_width($contract, $family->{family});
        for my $state (@{$family->{transaction_state} || []}) {
            push @lines,
                "    (var $state->{selected_id_signal} (width $width))",
                "    (var $state->{busy_signal} (width 1))";
        }
    }
    return @lines;
}

sub _auto_id_lifecycle_assertion_transaction_lines($contract) {
    my $lifecycle = $contract->{auto_id_lifecycle};
    return () unless ref($lifecycle) eq 'HASH';

    my @assertions;
    for my $family (@{$lifecycle->{families} || []}) {
        for my $state (@{$family->{transaction_state} || []}) {
            my $available = _auto_id_available_expr($family, $state);
            push @assertions, [
                $state->{no_id_assertion},
                _implies_expr($state->{request_event}, $available),
                "$contract->{name} $state->{transaction} auto ID available",
            ];
            push @assertions, [
                $state->{completion_assertion},
                _implies_expr($state->{completion_event}, $state->{busy_signal}),
                "$contract->{name} $state->{transaction} completion releases active auto ID",
            ];
        }

        my @states = @{$family->{transaction_state} || []};
        for my $left_index (0 .. $#states) {
            for my $right_index ($left_index + 1 .. $#states) {
                my $left = $states[$left_index];
                my $right = $states[$right_index];
                push @assertions, [
                    "$contract->{name}_$left->{transaction}_$right->{transaction}_auto_id_mutual_exclusion",
                    _implies_expr($left->{request_event}, _not_expr($right->{request_event})),
                    "$contract->{name} $family->{family} auto ID requests are mutually exclusive",
                ];
            }
        }
    }
    return () unless @assertions;

    my @lines = ("  (transaction $contract->{name}_auto_id_lifecycle_checks");
    for my $assertion (@assertions) {
        my ($name, $condition, $message) = @$assertion;
        push @lines,
            "    (assert $condition " . _quoted_isf_string($message) . ")";
    }
    push @lines, "  )";
    return @lines;
}

sub _same_id_ordering_assertion_transaction_lines($contract) {
    my @assertions = _same_id_ordering_assertion_specs($contract);
    return () unless @assertions;

    my @lines = ("  (transaction $contract->{name}_same_id_ordering_checks");
    for my $assertion (@assertions) {
        push @lines,
            "    (assert $assertion->{condition} " . _quoted_isf_string($assertion->{message}) . ")";
    }
    push @lines, "  )";
    return @lines;
}

sub _same_id_ordering_assertion_specs($contract) {
    my $lifecycle = $contract->{auto_id_lifecycle};
    my @assertions;
    if (ref($lifecycle) eq 'HASH' && $lifecycle->{generated_behavior}) {
        for my $family (@{$lifecycle->{families} || []}) {
            push @assertions, _same_id_ordering_assertion_specs_for_family($family, $contract->{name});
        }
    }
    push @assertions, _same_id_admitted_request_assertion_specs($contract);
    push @assertions, _same_id_issue_order_queue_assertion_specs($contract);
    return @assertions;
}

sub _same_id_admitted_request_assertion_specs($contract) {
    my $boundary = $contract->{same_id_admitted_request_boundary};
    return () unless ref($boundary) eq 'HASH';

    my @assertions;
    for my $family_name (qw(write read)) {
        my $family = $boundary->{families}{$family_name};
        next unless ref($family) eq 'HASH';
        push @assertions, @{$family->{assertions} || []};
    }
    return @assertions;
}

sub _same_id_issue_order_queue_assertion_specs($contract) {
    my $behavior = $contract->{same_id_issue_order_queue_behavior};
    return () unless ref($behavior) eq 'HASH' && $behavior->{generated_behavior};

    my @assertions;
    for my $family_name (qw(write read)) {
        for my $group (_same_id_issue_order_queue_groups($behavior, $family_name)) {
            push @assertions, _same_id_issue_order_queue_assertion_specs_for_group($group);
        }
    }
    return @assertions;
}

sub _same_id_ordering_assertion_specs_for_family($family, $manager_name) {
    my @states = @{$family->{transaction_state} || []};
    my $name_prefix = defined($manager_name) && length($manager_name) ? "${manager_name}_" : '';
    my $message_prefix = defined($manager_name) && length($manager_name) ? "$manager_name " : '';
    my @assertions;
    for my $left_index (0 .. $#states) {
        for my $right_index ($left_index + 1 .. $#states) {
            my $left = $states[$left_index];
            my $right = $states[$right_index];
            push @assertions, {
                name      => "$name_prefix$left->{transaction}_$right->{transaction}_auto_id_unique_active_id",
                condition => _implies_expr(
                    _and_expr($left->{busy_signal}, $right->{busy_signal}),
                    _not_expr(_eq_expr($left->{selected_id_signal}, $right->{selected_id_signal})),
                ),
                message   => "$message_prefix$family->{family} auto ID active selected IDs are unique",
            };
        }
    }
    return @assertions;
}

sub _auto_id_lifecycle_priority_lines($contract) {
    my $lifecycle = $contract->{auto_id_lifecycle};
    return () unless ref($lifecycle) eq 'HASH';

    my @lines;
    for my $family (@{$lifecycle->{families} || []}) {
        my @allocation_rules = map { @{$_->{allocation_rules} || []} } @{$family->{transaction_state} || []};
        for my $index (0 .. $#allocation_rules - 1) {
            push @lines, "  (priority $allocation_rules[$index] over $allocation_rules[$index + 1])";
        }
    }
    return @lines;
}

sub _same_id_issue_order_queue_priority_lines($contract) {
    my $behavior = $contract->{same_id_issue_order_queue_behavior};
    return () unless ref($behavior) eq 'HASH' && $behavior->{generated_behavior};

    my @lines;
    for my $family_name (qw(write read)) {
        for my $group (_same_id_issue_order_queue_groups($behavior, $family_name)) {
            my @rules = @{$group->{transition_rules} || []};
            for my $left_index (0 .. $#rules) {
                for my $right_index ($left_index + 1 .. $#rules) {
                    push @lines, "  (priority $rules[$left_index] over $rules[$right_index])";
                }
            }
        }
    }
    return @lines;
}

sub _auto_id_lifecycle_rule_lines($contract) {
    my $lifecycle = $contract->{auto_id_lifecycle};
    return () unless ref($lifecycle) eq 'HASH';

    my @lines;
    for my $family (@{$lifecycle->{families} || []}) {
        for my $state (@{$family->{transaction_state} || []}) {
            my @earlier_free_exprs;
            my $rule_index = 0;
            for my $id (@{$family->{pool}}) {
                my $free = _auto_id_free_expr($family, $id);
                my $guard = _and_expr(
                    $state->{request_event},
                    _not_expr($state->{busy_signal}),
                    $free,
                    map { _not_expr($_) } @earlier_free_exprs,
                );
                push @lines, _auto_id_rule(
                    $state->{allocation_rules}[$rule_index],
                    $guard,
                    [
                        [$state->{selected_id_signal}, $id],
                        [$state->{busy_signal}, 1],
                        [$family->{request_id_signal}, $id],
                    ],
                );
                push @earlier_free_exprs, $free;
                ++$rule_index;
            }

            push @lines, _auto_id_rule(
                $state->{release_rule},
                _and_expr($state->{completion_event}, $state->{busy_signal}),
                [
                    [$state->{busy_signal}, 0],
                ],
            );
        }
    }

    return @lines;
}

sub _response_demux_rule_lines($contract) {
    my $demux = $contract->{response_demux};
    return () unless ref($demux) eq 'HASH' && $demux->{generated_behavior};

    my @lines;
    for my $state (_response_demux_transaction_states($contract)) {
        push @lines, _response_demux_rule(
            _response_demux_rule_name($contract, $state),
            _response_demux_guard_expr($contract, $state),
            $state->{completion_event},
        );
    }

    return @lines;
}

sub _response_demux_rule($name, $guard, $completion_signal) {
    return (
        "  (rule $name $guard",
        "    (pulse $completion_signal))",
    );
}

sub _same_id_admitted_request_storage_lines($contract) {
    my $boundary = $contract->{same_id_admitted_request_boundary};
    return () unless ref($boundary) eq 'HASH';

    return map { "    (var $_ (width 1))" } @{_same_id_admitted_request_signal_names($boundary)};
}

sub _same_id_issue_order_queue_storage_lines($contract) {
    my $behavior = $contract->{same_id_issue_order_queue_behavior};
    return () unless ref($behavior) eq 'HASH' && $behavior->{generated_behavior};

    my @signals;
    for my $family_name (qw(write read)) {
        for my $group (_same_id_issue_order_queue_groups($behavior, $family_name)) {
            push @signals, @{$group->{storage} || []};
        }
    }

    return map { "    (var $_ (width 1))" } @signals;
}

sub _same_id_admitted_request_rule_lines($contract) {
    my $boundary = $contract->{same_id_admitted_request_boundary};
    return () unless ref($boundary) eq 'HASH';

    my @lines;
    for my $family_name (qw(write read)) {
        my $family = $boundary->{families}{$family_name};
        next unless ref($family) eq 'HASH';
        for my $pulse (@{$family->{generated_pulses} || []}) {
            push @lines, _same_id_admitted_request_rule(
                $pulse->{rule},
                $pulse->{guard},
                $pulse->{pulse},
            );
        }
    }

    return @lines;
}

sub _same_id_admitted_request_rule($name, $guard, $pulse_signal) {
    return (
        "  (rule $name $guard",
        "    (pulse $pulse_signal))",
    );
}

sub _same_id_issue_order_queue_rule_lines($contract) {
    my $behavior = $contract->{same_id_issue_order_queue_behavior};
    return () unless ref($behavior) eq 'HASH' && $behavior->{generated_behavior};

    my @lines;
    for my $family_name (qw(write read)) {
        for my $group (_same_id_issue_order_queue_groups($behavior, $family_name)) {
            for my $transition (_same_id_issue_order_queue_transition_specs($group)) {
                push @lines, _auto_id_rule(
                    $transition->{name},
                    $transition->{guard},
                    _same_id_issue_order_queue_assignments($group, $transition->{to}),
                );
            }
        }
    }

    return @lines;
}

sub _same_id_issue_order_queue_transition_specs($group) {
    my ($t0, $t1) = @{$group->{transactions} || []};
    return () unless ref($t0) eq 'HASH' && ref($t1) eq 'HASH';

    my $n0 = $t0->{transaction};
    my $n1 = $t1->{transaction};
    my $e0 = $t0->{admitted_pulse};
    my $e1 = $t1->{admitted_pulse};
    my $m0 = _same_id_issue_order_queue_head_match_expr($group, $n0);
    my $m1 = _same_id_issue_order_queue_head_match_expr($group, $n1);
    my @specs = (
        ["empty_enqueue_$n0"          => []        => [$n0]      => [$e0, _not_expr($e1), _not_expr($m0), _not_expr($m1)]],
        ["empty_enqueue_$n1"          => []        => [$n1]      => [$e1, _not_expr($e0), _not_expr($m0), _not_expr($m1)]],
        ["${n0}_dequeue"              => [$n0]     => []         => [$m0, _not_expr($m1), _not_expr($e0), _not_expr($e1)]],
        ["${n1}_dequeue"              => [$n1]     => []         => [$m1, _not_expr($m0), _not_expr($e0), _not_expr($e1)]],
        ["${n0}_enqueue_$n1"          => [$n0]     => [$n0, $n1] => [$e1, _not_expr($e0), _not_expr($m0), _not_expr($m1)]],
        ["${n1}_enqueue_$n0"          => [$n1]     => [$n1, $n0] => [$e0, _not_expr($e1), _not_expr($m0), _not_expr($m1)]],
        ["${n0}_dequeue_enqueue_$n0"  => [$n0]     => [$n0]      => [$m0, $e0, _not_expr($m1), _not_expr($e1)]],
        ["${n0}_dequeue_enqueue_$n1"  => [$n0]     => [$n1]      => [$m0, $e1, _not_expr($m1), _not_expr($e0)]],
        ["${n1}_dequeue_enqueue_$n0"  => [$n1]     => [$n0]      => [$m1, $e0, _not_expr($m0), _not_expr($e1)]],
        ["${n1}_dequeue_enqueue_$n1"  => [$n1]     => [$n1]      => [$m1, $e1, _not_expr($m0), _not_expr($e0)]],
        ["${n0}_${n1}_dequeue_$n0"    => [$n0,$n1] => [$n1]      => [$m0, _not_expr($m1), _not_expr($e0), _not_expr($e1)]],
        ["${n1}_${n0}_dequeue_$n1"    => [$n1,$n0] => [$n0]      => [$m1, _not_expr($m0), _not_expr($e0), _not_expr($e1)]],
        ["${n0}_${n1}_dequeue_enqueue_$n0" => [$n0,$n1] => [$n1,$n0] => [$m0, $e0, _not_expr($m1), _not_expr($e1)]],
        ["${n1}_${n0}_dequeue_enqueue_$n1" => [$n1,$n0] => [$n0,$n1] => [$m1, $e1, _not_expr($m0), _not_expr($e0)]],
    );

    return map {
        my ($suffix, $from, $to, $events) = @$_;
        +{
            name  => "$group->{prefix}_$suffix",
            from  => $from,
            to    => $to,
            guard => _and_expr(
                _same_id_issue_order_queue_state_expr($group, $from),
                @$events,
            ),
        }
    } @specs;
}

sub _same_id_issue_order_queue_assignments($group, $state) {
    my %occupied;
    for my $slot (0 .. $#$state) {
        $occupied{$slot}{$state->[$slot]} = 1;
    }

    my @assignments;
    for my $slot (0 .. 1) {
        for my $transaction (@{$group->{transactions} || []}) {
            my $name = $transaction->{transaction};
            push @assignments, [
                $group->{slot_signals}{$slot}{$name},
                $occupied{$slot}{$name} ? 1 : 0,
            ];
        }
    }
    return \@assignments;
}

sub _same_id_issue_order_queue_state_expr($group, $state) {
    my %occupied;
    for my $slot (0 .. $#$state) {
        $occupied{$slot}{$state->[$slot]} = 1;
    }

    my @terms;
    for my $slot (0 .. 1) {
        for my $transaction (@{$group->{transactions} || []}) {
            my $name = $transaction->{transaction};
            my $signal = $group->{slot_signals}{$slot}{$name};
            push @terms, $occupied{$slot}{$name} ? $signal : _not_expr($signal);
        }
    }
    return _and_expr(@terms);
}

sub _same_id_issue_order_queue_slot_any_expr($group, $slot) {
    return _or_expr(map {
        $group->{slot_signals}{$slot}{$_->{transaction}}
    } @{$group->{transactions} || []});
}

sub _same_id_issue_order_queue_full_expr($group) {
    return _and_expr(
        _same_id_issue_order_queue_slot_any_expr($group, 0),
        _same_id_issue_order_queue_slot_any_expr($group, 1),
    );
}

sub _same_id_issue_order_queue_head_match_expr($group, $transaction_name) {
    my @terms = (
        $group->{response_event},
        _eq_expr($group->{response_id_signal}, $group->{concrete_id_literal}),
    );
    push @terms, $group->{last_signal}
        if defined $group->{last_signal};
    push @terms, $group->{slot_signals}{0}{$transaction_name};
    return _and_expr(
        @terms,
    );
}

sub _same_id_issue_order_queue_active_match_expr($group, $transaction_name) {
    return _and_expr(
        _eq_expr($group->{response_id_signal}, $group->{concrete_id_literal}),
        $group->{slot_signals}{0}{$transaction_name},
    );
}

sub _same_id_issue_order_queue_response_antecedent_expr($group) {
    return _and_expr(
        $group->{response_event},
        _eq_expr($group->{response_id_signal}, $group->{concrete_id_literal}),
    );
}

sub _same_id_issue_order_queue_dequeue_expr($group) {
    return _or_expr(map {
        _same_id_issue_order_queue_head_match_expr($group, $_->{transaction})
    } @{$group->{transactions} || []});
}

sub _same_id_issue_order_queue_remaining_after_dequeue_expr($group, $transaction_name) {
    my $head_match = _same_id_issue_order_queue_head_match_expr($group, $transaction_name);
    return _or_expr(
        _and_expr(
            $group->{slot_signals}{0}{$transaction_name},
            _not_expr($head_match),
        ),
        $group->{slot_signals}{1}{$transaction_name},
    );
}

sub _same_id_issue_order_queue_assertion_specs_for_group($group) {
    my ($t0, $t1) = @{$group->{transactions} || []};
    return () unless ref($t0) eq 'HASH' && ref($t1) eq 'HASH';

    my $prefix = $group->{prefix};
    my $slot0_any = _same_id_issue_order_queue_slot_any_expr($group, 0);
    my $slot1_any = _same_id_issue_order_queue_slot_any_expr($group, 1);
    my $dequeue = _same_id_issue_order_queue_dequeue_expr($group);
    my $response_for_id = _same_id_issue_order_queue_response_antecedent_expr($group);
    my @head_matches = map {
        _same_id_issue_order_queue_head_match_expr($group, $_->{transaction})
    } @{$group->{transactions} || []};
    my @enqueue_pulses = map { $_->{admitted_pulse} } @{$group->{transactions} || []};

    my @assertions = (
        {
            name      => "${prefix}_slot0_onehot0",
            condition => _same_id_at_most_one_expr(
                map { $group->{slot_signals}{0}{$_->{transaction}} } @{$group->{transactions}}
            ),
            message   => "$group->{family} same-ID issue-order queue slot 0 is one-hot-or-empty",
        },
        {
            name      => "${prefix}_slot1_onehot0",
            condition => _same_id_at_most_one_expr(
                map { $group->{slot_signals}{1}{$_->{transaction}} } @{$group->{transactions}}
            ),
            message   => "$group->{family} same-ID issue-order queue slot 1 is one-hot-or-empty",
        },
        {
            name      => "${prefix}_compact",
            condition => _implies_expr($slot1_any, $slot0_any),
            message   => "$group->{family} same-ID issue-order queue is compact",
        },
        {
            name      => "${prefix}_enqueue_requires_space_or_dequeue",
            condition => _implies_expr(
                _or_expr(@enqueue_pulses),
                _or_expr(_not_expr(_same_id_issue_order_queue_full_expr($group)), $dequeue),
            ),
            message   => "$group->{family} same-ID issue-order queue enqueue has space or selected dequeue",
        },
        {
            name      => "${prefix}_response_requires_nonempty",
            condition => _implies_expr($response_for_id, $slot0_any),
            message   => "$group->{family} same-ID queue-head response requires a nonempty queue",
        },
        {
            name      => "${prefix}_response_unique_head_match",
            condition => _implies_expr(
                $response_for_id,
                _same_id_at_most_one_expr(@head_matches),
            ),
            message   => "$group->{family} same-ID queue-head response matches at most one head",
        },
        {
            name      => "${prefix}_dequeue_requires_nonempty",
            condition => _implies_expr($dequeue, $slot0_any),
            message   => "$group->{family} same-ID issue-order queue dequeue requires a nonempty queue",
        },
    );
    push @assertions, {
        name      => "${prefix}_nonlast_no_dequeue",
        condition => _implies_expr(
            _and_expr($response_for_id, _not_expr($group->{last_signal})),
            _not_expr($dequeue),
        ),
        message   => "$group->{family} same-ID non-last response beat does not dequeue",
    } if defined $group->{last_signal};

    for my $transaction (@{$group->{transactions} || []}) {
        my $name = $transaction->{transaction};
        push @assertions,
            {
                name      => "${prefix}_${name}_unique_slot",
                condition => _not_expr(_and_expr(
                    $group->{slot_signals}{0}{$name},
                    $group->{slot_signals}{1}{$name},
                )),
                message   => "$group->{family} same-ID issue-order queue transaction $name appears in at most one slot",
            },
            {
                name      => "${prefix}_${name}_no_duplicate_after_dequeue",
                condition => _implies_expr(
                    $transaction->{admitted_pulse},
                    _not_expr(_same_id_issue_order_queue_remaining_after_dequeue_expr($group, $name)),
                ),
                message   => "$group->{family} same-ID issue-order queue enqueue for $name does not duplicate a remaining transaction",
            };
    }

    return @assertions;
}

sub _read_data_burst_length_storage_lines($contract) {
    my $read_data = $contract->{read_data};
    return () unless ref($read_data) eq 'HASH' && $read_data->{generated_behavior};
    my $read = $read_data->{read};
    return () unless ref($read) eq 'HASH' && $read->{burst_length_generated_behavior};

    return map {
        "    (var $_->{burst_length_storage} (width $read->{burst_length_signal_width}))"
    } @{$read->{transactions} || []};
}

sub _read_data_beat_count_storage_lines($contract) {
    my $read_data = $contract->{read_data};
    return () unless ref($read_data) eq 'HASH' && $read_data->{generated_behavior};
    my $read = $read_data->{read};
    return () unless ref($read) eq 'HASH' && _read_data_runtime_assertion_enabled($read);

    return map {
        (
            "    (var $_->{expected_beat_count_storage} (width $read->{beat_count_width}))",
            "    (var $_->{beat_count_storage} (width $read->{beat_count_width}))",
        )
    } @{$read->{transactions} || []};
}

sub _read_data_burst_length_capture_rule_lines($contract) {
    my $read_data = $contract->{read_data};
    return () unless ref($read_data) eq 'HASH' && $read_data->{generated_behavior};
    my $read = $read_data->{read};
    return () unless ref($read) eq 'HASH' && $read->{burst_length_generated_behavior};

    my %request_by_transaction = map {
        $_->{name} => $_->{request_event}
    } grep { ($_->{kind} // '') eq 'read' } @{$contract->{transactions} || []};

    my @lines;
    for my $transaction (@{$read->{transactions} || []}) {
        my $request_event = $request_by_transaction{$transaction->{transaction}};
        confess "Internal error: read-data burst-length capture transaction '$transaction->{transaction}' has no read request event\n"
            unless defined $request_event;
        push @lines, _read_data_capture_rule(
            _read_data_burst_length_capture_rule_name($contract, $transaction),
            $request_event,
            [
                [$transaction->{burst_length_storage}, $read->{burst_length_signal}],
            ],
        );
    }
    return @lines;
}

sub _read_data_beat_count_rule_lines($contract) {
    my $read_data = $contract->{read_data};
    return () unless ref($read_data) eq 'HASH' && $read_data->{generated_behavior};
    my $read = $read_data->{read};
    return () unless ref($read) eq 'HASH' && _read_data_runtime_assertion_enabled($read);

    my %request_by_transaction = _read_data_request_events_by_transaction($contract);
    my %state_by_transaction = _read_data_response_states_by_transaction($contract);

    my @lines;
    for my $transaction (@{$read->{transactions} || []}) {
        my $request_event = $request_by_transaction{$transaction->{transaction}};
        confess "Internal error: read-data beat-count transaction '$transaction->{transaction}' has no read request event\n"
            unless defined $request_event;
        my $state = $state_by_transaction{$transaction->{transaction}};
        confess "Internal error: read-data beat-count transaction '$transaction->{transaction}' has no read response-demux state\n"
            unless ref($state) eq 'HASH';

        push @lines, _read_data_capture_rule(
            $transaction->{beat_count_init_rule},
            $request_event,
            [
                [$transaction->{expected_beat_count_storage}, _read_data_expected_beat_count_expr($read)],
                [$transaction->{beat_count_storage}, 0],
            ],
        );
        push @lines, _read_data_capture_rule(
            $transaction->{beat_count_increment_rule},
            _and_expr(
                _read_data_matched_read_beat_expr($contract, $state),
                _not_expr($request_event),
            ),
            [
                [$transaction->{beat_count_storage}, _read_data_beat_count_plus_one_expr($read, $transaction->{beat_count_storage})],
            ],
        );
    }
    return @lines;
}

sub _read_data_multi_beat_output_init_rule_lines($contract) {
    my $read_data = $contract->{read_data};
    return () unless ref($read_data) eq 'HASH' && $read_data->{generated_behavior};
    my $read = $read_data->{read};
    return () unless _read_data_multi_beat_payload_capture_enabled($read);

    my %request_by_transaction = _read_data_request_events_by_transaction($contract);

    my @lines;
    for my $transaction (@{$read->{transactions} || []}) {
        my $request_event = $request_by_transaction{$transaction->{transaction}};
        confess "Internal error: multi-beat read-data output init transaction '$transaction->{transaction}' has no read request event\n"
            unless defined $request_event;
        push @lines, _read_data_capture_rule(
            _read_data_multi_beat_output_init_rule_name($contract, $transaction),
            $request_event,
            _read_data_multi_beat_output_init_assignments($transaction),
        );
    }
    return @lines;
}

sub _read_data_capture_rule_lines($contract) {
    my $read_data = $contract->{read_data};
    return () unless ref($read_data) eq 'HASH' && $read_data->{generated_behavior};
    my $read = $read_data->{read};
    return () unless ref($read) eq 'HASH';
    return () unless _read_data_payload_capture_enabled($read);

    my @lines;
    if (_read_data_scalar_payload_capture_enabled($read)) {
        for my $transaction (@{$read->{transactions} || []}) {
            push @lines, _read_data_capture_rule(
                _read_data_capture_rule_name($contract, $transaction),
                $transaction->{completion_signal},
                [
                    [$transaction->{data_output},   $read->{data_signal}],
                    [$transaction->{status_output}, $read->{status_signal}],
                ],
            );
        }
    }
    if (_read_data_multi_beat_payload_capture_enabled($read)) {
        my %request_by_transaction = _read_data_request_events_by_transaction($contract);
        my %state_by_transaction = _read_data_response_states_by_transaction($contract);
        for my $transaction (@{$read->{transactions} || []}) {
            my $request_event = $request_by_transaction{$transaction->{transaction}};
            confess "Internal error: multi-beat read-data capture transaction '$transaction->{transaction}' has no read request event\n"
                unless defined $request_event;
            my $state = $state_by_transaction{$transaction->{transaction}};
            confess "Internal error: multi-beat read-data capture transaction '$transaction->{transaction}' has no read response-demux state\n"
                unless ref($state) eq 'HASH';
            confess "Internal error: multi-beat read-data capture transaction '$transaction->{transaction}' has no beat-count storage\n"
                unless defined($transaction->{beat_count_storage});

            my @data_outputs = @{$transaction->{generated_data_outputs} || []};
            my @status_outputs = @{$transaction->{generated_status_outputs} || []};
            for my $lane (0 .. $#data_outputs) {
                confess "Internal error: multi-beat read-data capture transaction '$transaction->{transaction}' lane $lane has no status output\n"
                    unless defined $status_outputs[$lane];
                push @lines, _read_data_capture_rule(
                    _read_data_multi_beat_capture_rule_name($contract, $transaction, $lane),
                    _and_expr(
                        _read_data_matched_read_beat_expr($contract, $state),
                        _not_expr($request_event),
                        _eq_expr(
                            $transaction->{beat_count_storage},
                            _sized_decimal_literal($read->{beat_count_width}, $lane),
                        ),
                    ),
                    [
                        [$data_outputs[$lane], $read->{data_signal}],
                        [$status_outputs[$lane], $read->{status_signal}],
                        [$transaction->{valid_mask_output}, _read_data_valid_prefix_mask_expr($transaction, $lane)],
                        [$transaction->{length_output}, _sized_decimal_literal($transaction->{length_output_width}, $lane + 1)],
                    ],
                );
            }
            if (defined($transaction->{status_aggregate_output})) {
                push @lines, _read_data_capture_rule(
                    _read_data_status_aggregate_update_rule_name($contract, $transaction),
                    _and_expr(
                        _read_data_matched_read_beat_expr($contract, $state),
                        _not_expr($request_event),
                        _lt_expr($transaction->{status_aggregate_output}, $read->{status_signal}),
                    ),
                    [
                        [$transaction->{status_aggregate_output}, $read->{status_signal}],
                    ],
                );
            }
        }
    }
    return @lines;
}

sub _read_data_capture_rule($name, $guard, $assignments) {
    return _auto_id_rule($name, $guard, $assignments);
}

sub _read_data_capture_rule_name($contract, $transaction) {
    return "$contract->{name}_$transaction->{transaction}_read_data_capture";
}

sub _read_data_multi_beat_output_init_rule_name($contract, $transaction) {
    return $transaction->{multi_beat_output_init_rule}
        // "$contract->{name}_$transaction->{transaction}_read_data_output_init";
}

sub _read_data_multi_beat_capture_rule_name($contract, $transaction, $lane) {
    return $transaction->{multi_beat_capture_rules}[$lane]
        if ref($transaction->{multi_beat_capture_rules}) eq 'ARRAY'
            && defined($transaction->{multi_beat_capture_rules}[$lane]);
    return "$contract->{name}_$transaction->{transaction}_read_beat_${lane}_capture";
}

sub _read_data_status_aggregate_update_rule_name($contract, $transaction) {
    return $transaction->{status_aggregate_update_rule}
        if defined $transaction->{status_aggregate_update_rule};
    return "$contract->{name}_$transaction->{transaction}_rresp_aggregate";
}

sub _read_data_burst_length_capture_rule_name($contract, $transaction) {
    return $transaction->{burst_length_capture_rule}
        // "$contract->{name}_$transaction->{transaction}_burst_length_capture";
}

sub _read_data_multi_beat_output_init_assignments($transaction) {
    my @assignments;
    push @assignments, map {
        [$_, _sized_decimal_literal($transaction->{data_width}, 0)]
    } @{$transaction->{generated_data_outputs} || []};
    push @assignments, map {
        [$_, _sized_decimal_literal($transaction->{status_width}, 0)]
    } @{$transaction->{generated_status_outputs} || []};
    push @assignments, [
        $transaction->{status_aggregate_output},
        _sized_decimal_literal($transaction->{status_aggregate_output_width}, 0),
    ] if defined($transaction->{status_aggregate_output});
    push @assignments,
        [$transaction->{valid_mask_output}, _sized_binary_literal($transaction->{valid_mask_width}, '0')],
        [$transaction->{length_output}, _sized_decimal_literal($transaction->{length_output_width}, 0)];
    return \@assignments;
}

sub _read_data_valid_prefix_mask_expr($transaction, $lane) {
    my $width = $transaction->{valid_mask_width};
    my $ones = '1' x ($lane + 1);
    my $zeros = '0' x ($width - length($ones));
    return _sized_binary_literal($width, $zeros . $ones);
}

sub _auto_id_rule($name, $guard, $assignments) {
    my @lines = ("  (rule $name $guard");
    for my $index (0 .. $#$assignments) {
        my ($lhs, $rhs) = @{$assignments->[$index]};
        my $suffix = $index == $#$assignments ? ')' : '';
        push @lines, "    ($lhs $rhs)$suffix";
    }
    return @lines;
}

sub _response_demux_transaction_states($contract) {
    return map { _response_demux_transaction_states_for_family($contract, $_) } qw(write read);
}

sub _response_demux_transaction_states_for_family($contract, $family_name) {
    my $demux = $contract->{response_demux};
    return () unless ref($demux) eq 'HASH';
    return () unless ref($demux->{$family_name}) eq 'HASH' && $demux->{$family_name}{generated_behavior};

    my @queue_states = _same_id_issue_order_queue_response_states_for_family($contract, $family_name);
    return @queue_states if @queue_states;

    my $lifecycle = _auto_id_lifecycle_family_by_name($contract->{auto_id_lifecycle}, $family_name);
    return () unless ref($lifecycle) eq 'HASH';

    my %wanted = map { $_ => 1 } @{$demux->{$family_name}{auto_transactions} || []};
    return map { +{ family => $family_name, %$_ } }
        grep { $wanted{$_->{transaction}} } @{$lifecycle->{transaction_state} || []};
}

sub _same_id_issue_order_queue_response_states_for_family($contract, $family_name) {
    my $behavior = $contract->{same_id_issue_order_queue_behavior};
    my @states;
    for my $group (_same_id_issue_order_queue_groups($behavior, $family_name)) {
        for my $transaction (@{$group->{transactions} || []}) {
            push @states, {
                family                  => $family_name,
                response_demux_kind     => 'same_id_queue_head',
                transaction             => $transaction->{transaction},
                tag                     => $transaction->{tag},
                completion_event        => $transaction->{completion_event},
                head_signal             => $transaction->{head_signal},
                concrete_id             => $group->{concrete_id},
                concrete_id_literal     => $group->{concrete_id_literal},
                queue_head_guard_expr   => _same_id_issue_order_queue_head_match_expr($group, $transaction->{transaction}),
                queue_head_match_expr   => _same_id_issue_order_queue_active_match_expr($group, $transaction->{transaction}),
                queue_response_antecedent_expr => _same_id_issue_order_queue_response_antecedent_expr($group),
            };
        }
    }
    return @states;
}

sub _read_data_runtime_assertion_enabled($read) {
    return ref($read) eq 'HASH'
        && ($read->{beat_count_validation_generated_behavior} || 0);
}

sub _read_data_request_events_by_transaction($contract) {
    return map {
        $_->{name} => $_->{request_event}
    } grep { ($_->{kind} // '') eq 'read' } @{$contract->{transactions} || []};
}

sub _read_data_response_states_by_transaction($contract) {
    return map {
        $_->{transaction} => $_
    } _response_demux_transaction_states_for_family($contract, 'read');
}

sub _read_data_matched_read_beat_expr($contract, $state) {
    my $demux = $contract->{response_demux};
    return _and_expr(
        $demux->{read}{response_event},
        _response_demux_match_expr($contract, $state),
    );
}

sub _response_demux_rule_name($contract, $state) {
    return "$contract->{name}_$state->{transaction}_response_demux";
}

sub _response_demux_guard_expr($contract, $state) {
    return $state->{queue_head_guard_expr}
        if ($state->{response_demux_kind} // '') eq 'same_id_queue_head';

    my $demux = $contract->{response_demux};
    my $family = $state->{family};
    my @terms = (
        $demux->{$family}{response_event},
        $state->{busy_signal},
        _eq_expr($demux->{$family}{response_id_signal}, $state->{selected_id_signal}),
    );
    push @terms, $demux->{$family}{last_signal}
        if defined $demux->{$family}{last_signal};
    return _and_expr(
        @terms,
    );
}

sub _response_demux_match_expr($contract, $state) {
    return $state->{queue_head_match_expr}
        if ($state->{response_demux_kind} // '') eq 'same_id_queue_head';

    my $demux = $contract->{response_demux};
    my $family = $state->{family};
    return _and_expr(
        $state->{busy_signal},
        _eq_expr($demux->{$family}{response_id_signal}, $state->{selected_id_signal}),
    );
}

sub _response_demux_assertion_specs($contract) {
    my $demux = $contract->{response_demux};
    return () unless ref($demux) eq 'HASH' && $demux->{generated_behavior};

    return map { _response_demux_assertion_specs_for_family($contract, $_) } qw(write read);
}

sub _read_data_beat_count_assertion_specs($contract) {
    my $read_data = $contract->{read_data};
    return () unless ref($read_data) eq 'HASH' && $read_data->{generated_behavior};
    my $read = $read_data->{read};
    return () unless ref($read) eq 'HASH' && _read_data_runtime_assertion_enabled($read);

    my $demux = $contract->{response_demux};
    my $last_signal = $demux->{read}{last_signal};
    confess "Internal error: read-data beat-count validation requires a read RLAST signal\n"
        unless defined $last_signal;
    my %request_by_transaction = _read_data_request_events_by_transaction($contract);
    my %state_by_transaction = _read_data_response_states_by_transaction($contract);

    my @assertions;
    for my $transaction (@{$read->{transactions} || []}) {
        my $request_event = $request_by_transaction{$transaction->{transaction}};
        confess "Internal error: read-data beat-count assertion transaction '$transaction->{transaction}' has no read request event\n"
            unless defined $request_event;
        my $state = $state_by_transaction{$transaction->{transaction}};
        confess "Internal error: read-data beat-count assertion transaction '$transaction->{transaction}' has no read response-demux state\n"
            unless ref($state) eq 'HASH';

        my $matched_beat = _read_data_matched_read_beat_expr($contract, $state);
        my $accepted_beat_count = _read_data_beat_count_plus_one_expr($read, $transaction->{beat_count_storage});
        push @assertions,
            {
                name      => "$contract->{name}_$transaction->{transaction}_arlen_within_max",
                condition => _implies_expr(
                    $request_event,
                    _read_data_arlen_within_max_expr($read),
                ),
                message   => "$contract->{name} $transaction->{transaction} ARLEN is within configured max beats",
            },
            {
                name      => "$contract->{name}_$transaction->{transaction}_read_beat_before_expected_count",
                condition => _implies_expr(
                    $matched_beat,
                    _lt_expr($transaction->{beat_count_storage}, $transaction->{expected_beat_count_storage}),
                ),
                message   => "$contract->{name} $transaction->{transaction} read beat count is below expected count",
            },
            {
                name      => "$contract->{name}_$transaction->{transaction}_rlast_on_expected_beat",
                condition => _implies_expr(
                    _and_expr($matched_beat, $last_signal),
                    _eq_expr($accepted_beat_count, $transaction->{expected_beat_count_storage}),
                ),
                message   => "$contract->{name} $transaction->{transaction} RLAST appears only on the expected final read beat",
            },
            {
                name      => "$contract->{name}_$transaction->{transaction}_expected_final_beat_has_rlast",
                condition => _implies_expr(
                    _and_expr(
                        $matched_beat,
                        _eq_expr($accepted_beat_count, $transaction->{expected_beat_count_storage}),
                    ),
                    $last_signal,
                ),
                message   => "$contract->{name} $transaction->{transaction} expected final read beat has RLAST",
            };
    }
    return @assertions;
}

sub _response_demux_assertion_specs_for_family($contract, $family) {
    my $demux = $contract->{response_demux};
    my @states = _response_demux_transaction_states_for_family($contract, $family);
    return () unless @states;

    my @matches = map { _response_demux_match_expr($contract, $_) } @states;
    my $queue_head = grep { ($_->{response_demux_kind} // '') eq 'same_id_queue_head' } @states;
    my $antecedent = $queue_head
        ? _or_expr(@{_unique_preserving([map { $_->{queue_response_antecedent_expr} } @states])})
        : $demux->{$family}{response_event};
    my $active_message = $queue_head
        ? "$contract->{name} $family response matches nonempty same-ID queue head"
        : "$contract->{name} $family response matches active auto-ID transaction";
    my $unique_message = $queue_head
        ? "$contract->{name} $family response matches at most one same-ID queue head"
        : "$contract->{name} $family response matches at most one auto-ID transaction";
    my @assertions = ({
        name      => "$contract->{name}_${family}_response_demux_active_match",
        condition => _implies_expr($antecedent, _or_expr(@matches)),
        message   => $active_message,
    });

    for my $left_index (0 .. $#states) {
        for my $right_index ($left_index + 1 .. $#states) {
            my $left = $states[$left_index];
            my $right = $states[$right_index];
            push @assertions, {
                name      => "$contract->{name}_$left->{transaction}_$right->{transaction}_${family}_response_demux_unique_match",
                condition => _implies_expr(
                    $antecedent,
                    _not_expr(_and_expr(
                        _response_demux_match_expr($contract, $left),
                        _response_demux_match_expr($contract, $right),
                    )),
                ),
                message   => $unique_message,
            };
        }
    }

    return @assertions;
}

sub _auto_id_available_expr($family, $state) {
    return _and_expr(
        _not_expr($state->{busy_signal}),
        _or_expr(map { _auto_id_free_expr($family, $_) } @{$family->{pool}}),
    );
}

sub _auto_id_free_expr($family, $id) {
    return _and_expr(
        map {
            _or_expr(
                _not_expr($_->{busy_signal}),
                _not_expr("(== $_->{selected_id_signal} $id)"),
            )
        } @{$family->{transaction_state} || []}
    );
}

sub _auto_id_family_width($contract, $family) {
    return $contract->{id_families}{$family}{width};
}

sub _and_expr(@terms) {
    return '1' unless @terms;
    return $terms[0] if @terms == 1;
    return "(& " . join(' ', @terms) . ")";
}

sub _or_expr(@terms) {
    return '0' unless @terms;
    return $terms[0] if @terms == 1;
    return "(| " . join(' ', @terms) . ")";
}

sub _not_expr($term) {
    return "(! $term)";
}

sub _eq_expr($lhs, $rhs) {
    return "(== $lhs $rhs)";
}

sub _lt_expr($lhs, $rhs) {
    return "(< $lhs $rhs)";
}

sub _add_expr(@terms) {
    return '0' unless @terms;
    return $terms[0] if @terms == 1;
    return "(+ " . join(' ', @terms) . ")";
}

sub _read_data_expected_beat_count_expr($read) {
    return _add_expr(
        _signal_sliced_to_width(
            $read->{burst_length_signal},
            $read->{burst_length_signal_width},
            $read->{beat_count_width},
        ),
        _sized_decimal_literal($read->{beat_count_width}, 1),
    );
}

sub _read_data_beat_count_plus_one_expr($read, $signal) {
    return _add_expr($signal, _sized_decimal_literal($read->{beat_count_width}, 1));
}

sub _read_data_arlen_within_max_expr($read) {
    my $width = $read->{burst_length_signal_width};
    return '1' if $read->{max_beats} >= 2 ** $width;
    return _lt_expr($read->{burst_length_signal}, _sized_decimal_literal($width, $read->{max_beats}));
}

sub _signal_sliced_to_width($signal, $source_width, $target_width) {
    return $signal unless $source_width > $target_width;
    return $signal . "[" . ($target_width - 1) . ":0]";
}

sub _sized_decimal_literal($width, $value) {
    return "${width}'d$value";
}

sub _sized_binary_literal($width, $bits) {
    return "${width}'b$bits";
}

sub _implies_expr($antecedent, $consequent) {
    return "(=> $antecedent $consequent)";
}

sub _quoted_isf_string($value) {
    $value =~ s/\\/\\\\/g;
    $value =~ s/"/\\"/g;
    return "\"$value\"";
}

sub _effective_direction_events($contract, $direction) {
    my $dispatch = $contract->{transaction_event_dispatch};
    return $dispatch->{$direction} if ref($dispatch) eq 'HASH';

    return {
        request_fanin    => _direction_level_event($contract->{events}, $direction, 'request'),
        completion_fanin => _direction_level_event($contract->{events}, $direction, 'completion'),
    };
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
        (defined $contract->{auto_id_lifecycle}
            ? (auto_id_lifecycle => _report_auto_id_lifecycle($contract))
            : ()),
        (defined $contract->{response_demux}
            ? (response_demux => _report_response_demux($contract))
            : ()),
        (defined $contract->{read_data}
            ? (read_data => _report_read_data($contract))
            : ()),
        (defined $contract->{same_id_ordering}
            ? (same_id_ordering => _report_same_id_ordering($contract))
            : ()),
        (defined $contract->{transaction_event_dispatch}
            ? (transaction_event_dispatch => _report_transaction_event_dispatch($contract))
            : ()),
        (defined $contract->{id_response_rule_engine}
            ? (id_response_rule_engine => _report_id_response_rule_engine($contract))
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
            'if supplied, transactions must declare unique names and tags, read/write kind, identifier request/completion event bindings, and id policy/value',
            'transaction event dispatch rejects opposite-direction direction-level event bindings and duplicate per-direction request/completion event names when per-transaction dispatch is used',
            'concrete transaction ID values require a present matching ID family and must fit its declared width',
            'concrete transaction ID assertions require unique request/response events per concrete transaction',
            'concrete transaction ID values generate request/response ID equality assertions against the declared ID-family signals',
            'auto_id_lifecycle requires id_families and transactions metadata',
            'auto_id_lifecycle listed families must have at least one auto-ID transaction in that family',
            'auto_id_lifecycle pools are bounded to 1..4 unique values per family and must fit the declared positive ID width',
            'auto_id_lifecycle generates first-free request-ID drive, per-transaction busy/selected-ID state, completion-event release, no-ID assertions, inactive-completion assertions, and same-family request mutual-exclusion assertions',
            'same_id_ordering for generated auto-ID families is enforced by avoiding same-ID concurrency through allocator free-ID guards plus pairwise active selected-ID assertions',
            'same_id_ordering_policy accepts explicit read/write concrete-id-reuse reject policies plus issue-order-queue admitted-request pulse generation, and generates bounded read single-beat, read burst-last, or write depth-2 concrete same-ID queue state plus queue-head response demux for selected public sample shapes',
            'response_demux requires id_families, transactions, and either selected-family auto_id_lifecycle metadata or selected same-id-ordering concrete-id-reuse issue-order-queue metadata with a duplicate concrete-ID group',
            'response_demux.write requires response_event equal to write_complete and generates bounded write BID demux behavior for explicit opt-in contracts',
            'response_demux.read requires response_event equal to read_complete, response_scope single_beat or burst_last, read ID-family metadata, read transactions, and read auto_id_lifecycle metadata or selected concrete same-ID queue-head metadata',
            'response_demux.read response_scope single_beat generates bounded single-beat read RID demux behavior for explicit opt-in contracts',
            'response_demux.read response_scope burst_last requires one-bit last_signal metadata and generates matched-RID-and-RLAST last-beat completion behavior for explicit opt-in contracts',
            'response_demux transaction_completion must be generated; selected auto-ID families make transaction completion names generated demux pulse outputs, while the bounded read single-beat, read burst-last, and write depth-2 concrete same-ID queue-head shapes also make transaction completion names generated demux pulse outputs',
            'concrete same-ID queue-head response_demux is generated only for bounded one-group two-transaction depth-2 shapes: read single-beat, read burst-last, or write, with issue-order-queue policy, duplicate concrete-ID group, no same-family auto_id_lifecycle demux, and read_data consumption supported for generated read single-beat queue-head capture, generated read burst-last queue-head last-beat capture, report-only raw-ARLEN burst-length capture, runtime beat-count/RLAST validation on generated read burst-last queue-head last-beat capture, and generated multi-beat output-bank capture on generated read burst-last queue-head demux in this slice',
            'read_data supports explicit generated single-beat capture behavior with response_scope single_beat, explicit generated last-beat capture behavior with response_scope burst_last, and explicit generated multi-beat output-bank behavior with response_scope burst_last',
            'read_data.read data width must be positive and status width must be 2',
            'read_data.read optional burst_length metadata is accepted only for last-beat or multi-beat capture, source arlen, signal width 8, axlen-plus-one encoding, request capture, max_beats 1..256, report-only or runtime-assertion validation, generated raw-ARLEN capture, and generated beat-count/RLAST runtime assertions only for explicit runtime-assertion contracts; multi-beat capture requires runtime-assertion validation',
            'read_data.read optional status_aggregation metadata is accepted only for multi-beat capture, policy worst-observed, status width 2, status_policy per-beat, runtime-assertion burst-length validation, and complete per-transaction status_aggregate_output bindings',
            'read_data.read transaction outputs must exactly cover read response_demux auto transactions or the supported generated read queue-head transactions',
            'read_data generates bounded single-beat and last-beat RDATA/RRESP capture inputs, outputs, guarded assignments, raw-ARLEN burst-length capture storage/rules, beat-count/RLAST runtime assertions for explicit runtime-assertion contracts, multi-beat output-bank data/status lanes, valid masks, length outputs, request-time clearing, lane capture rules, and scalar RRESP aggregation outputs/init/update rules for explicit multi-beat contracts',
        ],
        unsupported_residue => [
            {
                id     => 'blocking_or_queued_policy',
                detail => 'The first slice implements only try-style acceptance/status feedback.',
            },
            {
                id     => 'axi_id_ordering_and_response_matching',
                detail => 'Concrete transaction ID request/response assertions, explicit bounded auto-ID request-ID drive plus completion-event release, generated auto-ID same-ID avoidance, explicit static concrete-ID reuse reject policy metadata, issue-order-queue admitted-request pulse generation for selected concrete-ID families, bounded read single-beat, read burst-last, and write depth-2 concrete same-ID issue-order queue state plus queue-head response-demux behavior for selected public sample shapes, generated write BID response demux, generated single-beat read RID response demux, generated single-beat read-data RDATA/RRESP capture, generated single-beat read-data RDATA/RRESP capture from generated read single-beat concrete same-ID queue-head response-demux, generated burst-last RLAST response-demux completion, structural last-beat read-data metadata, generated last-beat read-data RDATA/RRESP capture, generated last-beat read-data RDATA/RRESP capture from generated read burst-last concrete same-ID queue-head response-demux, generated raw-ARLEN burst-length capture including report-only generated read burst-last concrete same-ID queue-head read-data contracts, explicit runtime-assertion beat-count/RLAST validation for auto-ID and bounded read burst-last concrete same-ID queue-head read-data contracts, generated multi-beat read-data output-bank behavior for the covered auto-ID multi-beat-by-RID subset and bounded read burst-last concrete same-ID queue-head subset, bounded burst payload/output behavior through that per-beat output bank, and generated scalar RRESP aggregation behavior are supported; dynamic user-ID arbitration while issuing multiple same-family requests in one cycle, deeper/multiple-group concrete same-ID issue-order queues, generalized scoreboard policies, authored/general different-ID interleaving outside the covered auto-ID and bounded queue-head subsets, packed burst-vector outputs, alternate full burst payload assembly, and aggregate-only status output shapes remain outside this capacity/status shell.',
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

sub _report_auto_id_lifecycle($contract) {
    my $lifecycle = _clone_jsonish($contract->{auto_id_lifecycle});
    $lifecycle->{generated_behavior} = $contract->{auto_id_lifecycle}{generated_behavior}
        ? JSON::PP::true
        : JSON::PP::false;
    if (
        _response_demux_covers_auto_id_lifecycle($contract)
    ) {
        $lifecycle->{residue} = [
            grep { $_ ne 'response_demux' }
            @{$lifecycle->{residue} || []}
        ];
    }
    if (ref($contract->{same_id_ordering}) eq 'HASH' && $contract->{same_id_ordering}{generated_behavior}) {
        $lifecycle->{residue} = [
            grep { $_ ne 'same_id_ordering' }
            @{$lifecycle->{residue} || []}
        ];
    }
    return $lifecycle;
}

sub _report_response_demux($contract) {
    my $demux = _clone_jsonish($contract->{response_demux});
    $demux->{generated_behavior} = $contract->{response_demux}{generated_behavior}
        ? JSON::PP::true
        : JSON::PP::false;
    for my $family (qw(write read)) {
        next unless ref($demux->{$family}) eq 'HASH' && exists $demux->{$family}{generated_behavior};
        $demux->{$family}{generated_behavior} = $contract->{response_demux}{$family}{generated_behavior}
            ? JSON::PP::true
            : JSON::PP::false;
    }
    if ($contract->{response_demux}{generated_behavior}) {
        for my $family (qw(write read)) {
            next unless ref($contract->{response_demux}{$family}) eq 'HASH'
                && $contract->{response_demux}{$family}{generated_behavior};
            my $artifacts = _response_demux_generated_artifacts($contract, $family);
            $demux->{$family}{generated_rules} = $artifacts->{rules};
            $demux->{$family}{generated_completion_signals} = $artifacts->{completion_signals};
            $demux->{$family}{generated_assertions} = $artifacts->{assertions};
        }
    }
    if (_same_id_ordering_covers_response_demux_family($contract, 'write')) {
        $demux->{residue} = [
            grep { $_ ne 'same_id_ordering' }
            @{$demux->{residue} || []}
        ];
    }
    if (_read_data_covers_multi_beat_by_rid_interleaving($contract)) {
        $demux->{residue} = [
            grep { $_ ne 'read_data_interleaving' }
            @{$demux->{residue} || []}
        ];
    }
    if (_read_data_covers_bounded_multi_beat_burst_output($contract)) {
        $demux->{residue} = [
            grep { $_ ne 'bursts' }
            @{$demux->{residue} || []}
        ];
    }
    return $demux;
}

sub _report_read_data($contract) {
    my $read_data = _clone_jsonish($contract->{read_data});
    $read_data->{generated_behavior} = $contract->{read_data}{generated_behavior}
        ? JSON::PP::true
        : JSON::PP::false;
    if ($contract->{read_data}{generated_behavior}) {
        my $artifacts = _read_data_generated_artifacts($contract);
        $read_data->{read}{generated_inputs} = $artifacts->{inputs};
        $read_data->{read}{generated_outputs} = $artifacts->{outputs};
        $read_data->{read}{generated_rules} = $artifacts->{rules};
        if ($contract->{read_data}{read}{burst_length_generated_behavior}) {
            $read_data->{read}{generated_burst_length_inputs} = $artifacts->{burst_length_inputs};
            $read_data->{read}{generated_burst_length_storage} = $artifacts->{burst_length_storage};
            $read_data->{read}{generated_burst_length_rules} = $artifacts->{burst_length_rules};
        }
        if ($contract->{read_data}{read}{beat_count_validation_generated_behavior}) {
            $read_data->{read}{generated_expected_beat_count_storage} = $artifacts->{expected_beat_count_storage};
            $read_data->{read}{generated_beat_count_storage} = $artifacts->{beat_count_storage};
            $read_data->{read}{generated_beat_count_rules} = $artifacts->{beat_count_rules};
            $read_data->{read}{generated_beat_count_assertions} = $artifacts->{beat_count_assertions};
        }
        if (_read_data_multi_beat_payload_capture_enabled($contract->{read_data}{read})) {
            $read_data->{read}{generated_multi_beat_data_outputs} = $artifacts->{multi_beat_data_outputs};
            $read_data->{read}{generated_multi_beat_status_outputs} = $artifacts->{multi_beat_status_outputs};
            $read_data->{read}{generated_multi_beat_valid_outputs} = $artifacts->{multi_beat_valid_outputs};
            $read_data->{read}{generated_multi_beat_length_outputs} = $artifacts->{multi_beat_length_outputs};
            $read_data->{read}{generated_multi_beat_output_init_rules} = $artifacts->{multi_beat_output_init_rules};
            $read_data->{read}{generated_multi_beat_capture_rules} = $artifacts->{multi_beat_capture_rules};
        }
        if ($contract->{read_data}{read}{status_aggregation_generated_behavior}) {
            $read_data->{read}{generated_status_aggregate_outputs} = $artifacts->{status_aggregate_outputs};
            $read_data->{read}{generated_status_aggregate_init_rules} = $artifacts->{status_aggregate_init_rules};
            $read_data->{read}{generated_status_aggregate_update_rules} = $artifacts->{status_aggregate_update_rules};
        }
    }
    if (exists $read_data->{read}{burst_length_generated_behavior}) {
        $read_data->{read}{burst_length_generated_behavior}
            = $contract->{read_data}{read}{burst_length_generated_behavior}
                ? JSON::PP::true
                : JSON::PP::false;
    }
    if (exists $read_data->{read}{beat_count_validation_generated_behavior}) {
        $read_data->{read}{beat_count_validation_generated_behavior}
            = $contract->{read_data}{read}{beat_count_validation_generated_behavior}
                ? JSON::PP::true
                : JSON::PP::false;
    }
    if (exists $read_data->{read}{multi_beat_reassembly_generated_behavior}) {
        $read_data->{read}{multi_beat_reassembly_generated_behavior}
            = $contract->{read_data}{read}{multi_beat_reassembly_generated_behavior}
                ? JSON::PP::true
                : JSON::PP::false;
    }
    if (exists $read_data->{read}{status_aggregation_generated_behavior}) {
        $read_data->{read}{status_aggregation_generated_behavior}
            = $contract->{read_data}{read}{status_aggregation_generated_behavior}
                ? JSON::PP::true
                : JSON::PP::false;
    }
    return $read_data;
}

sub _same_id_ordering_covers_response_demux_family($contract, $family_name) {
    return 1 if ref($contract->{same_id_issue_order_queue_behavior}) eq 'HASH'
        && _same_id_issue_order_queue_family_behavior(
            $contract->{same_id_issue_order_queue_behavior},
            $family_name,
        );

    my $ordering = $contract->{same_id_ordering};
    return 0 unless ref($ordering) eq 'HASH' && $ordering->{generated_behavior};
    for my $family (@{$ordering->{families} || []}) {
        return 1 if ($family->{family} // '') eq $family_name && $family->{response_demux_covered};
    }
    return 0;
}

sub _read_data_covers_multi_beat_by_rid_interleaving($contract) {
    return 0 unless ref($contract) eq 'HASH';
    return 0 unless _same_id_ordering_covers_response_demux_family($contract, 'read');

    my $demux = $contract->{response_demux};
    return 0 unless ref($demux) eq 'HASH'
        && $demux->{generated_behavior}
        && ref($demux->{read}) eq 'HASH'
        && $demux->{read}{generated_behavior}
        && ($demux->{read}{response_scope} // '') eq 'burst_last';

    my $read_data = $contract->{read_data};
    return 0 unless ref($read_data) eq 'HASH' && $read_data->{generated_behavior};
    my $read = $read_data->{read};
    return 0 unless ref($read) eq 'HASH'
        && ($read->{capture_scope} // '') eq 'multi_beat'
        && ($read->{interleaving_policy} // '') eq 'multi_beat_by_rid'
        && ($read->{completion_source} // '') eq 'response_demux'
        && ($read->{beat_match_source} // '') eq 'response_demux_matched_read_beat'
        && ($read->{beat_count_match_source} // '') eq 'response_demux_matched_read_beat'
        && ($read->{beat_storage} // '') eq 'per_transaction_generated'
        && ($read->{output_shape} // '') eq 'per_beat_output_bank'
        && ($read->{valid_output} // '') eq 'per_transaction_valid_mask'
        && ($read->{length_output} // '') eq 'per_transaction_beat_count'
        && $read->{beat_count_validation_generated_behavior}
        && $read->{multi_beat_reassembly_generated_behavior};

    for my $transaction (@{$read->{transactions} || []}) {
        return 0 unless ref($transaction) eq 'HASH'
            && defined($transaction->{beat_count_storage})
            && ref($transaction->{generated_data_outputs}) eq 'ARRAY'
            && @{$transaction->{generated_data_outputs}}
            && ref($transaction->{generated_status_outputs}) eq 'ARRAY'
            && @{$transaction->{generated_status_outputs}}
            && defined($transaction->{valid_mask_output})
            && defined($transaction->{length_output});
    }

    return 1;
}

sub _read_data_covers_bounded_multi_beat_burst_output($contract) {
    return 0 unless _read_data_covers_multi_beat_by_rid_interleaving($contract);

    my $read = $contract->{read_data}{read};
    return 0 unless ($read->{burst_length_source} // '') eq 'arlen_signal'
        && ($read->{burst_length_validation} // '') eq 'runtime_assertion'
        && ($read->{expected_beat_count_encoding} // '') eq 'arlen_plus_one'
        && $read->{burst_length_generated_behavior}
        && $read->{beat_count_validation_generated_behavior}
        && $read->{multi_beat_reassembly_generated_behavior};

    my $max_beats = $read->{max_beats} // 0;
    return 0 unless $max_beats > 0;

    my $transactions = $read->{transactions};
    return 0 unless ref($transactions) eq 'ARRAY' && @{$transactions};

    for my $transaction (@{$transactions}) {
        return 0 unless ref($transaction) eq 'HASH'
            && defined($transaction->{burst_length_storage})
            && defined($transaction->{expected_beat_count_storage})
            && defined($transaction->{beat_count_storage})
            && defined($transaction->{valid_mask_output})
            && defined($transaction->{length_output})
            && ref($transaction->{generated_data_outputs}) eq 'ARRAY'
            && @{$transaction->{generated_data_outputs}} == $max_beats
            && ref($transaction->{generated_status_outputs}) eq 'ARRAY'
            && @{$transaction->{generated_status_outputs}} == $max_beats;
    }

    return 1;
}

sub _report_same_id_ordering($contract) {
    my $ordering = _clone_jsonish($contract->{same_id_ordering});
    $ordering->{generated_behavior} = $contract->{same_id_ordering}{generated_behavior}
        ? JSON::PP::true
        : JSON::PP::false;
    for my $family (@{$ordering->{families} || []}) {
        $family->{response_demux_covered} = $family->{response_demux_covered}
            ? JSON::PP::true
            : JSON::PP::false;
    }
    if (ref($ordering->{concrete_id_reuse_policy}) eq 'HASH') {
        for my $family_name (qw(read write)) {
            next unless ref($ordering->{concrete_id_reuse_policy}{$family_name}) eq 'HASH';
            my $policy = $ordering->{concrete_id_reuse_policy}{$family_name};
            for my $field (qw(accepted_same_id_reuse generated_queue_behavior)) {
                next unless exists $policy->{$field};
                $policy->{$field} = $policy->{$field}
                    ? JSON::PP::true
                    : JSON::PP::false;
            }
        }
    }
    if (_same_id_ordering_covers_response_demux_family($contract, 'read')) {
        $ordering->{residue} = [
            grep { $_ ne 'read_response_demux' }
            @{$ordering->{residue} || []}
        ];
    }
    if (_read_data_covers_multi_beat_by_rid_interleaving($contract)) {
        $ordering->{residue} = [
            grep { $_ ne 'read_data_interleaving' }
            @{$ordering->{residue} || []}
        ];
    }
    if (_read_data_covers_bounded_multi_beat_burst_output($contract)) {
        $ordering->{residue} = [
            grep { $_ ne 'bursts' }
            @{$ordering->{residue} || []}
        ];
    }
    return $ordering;
}

sub _response_demux_generated_artifacts($contract, $family) {
    return {
        rules => [
            map { _response_demux_rule_name($contract, $_) }
            _response_demux_transaction_states_for_family($contract, $family)
        ],
        completion_signals => _clone_jsonish($contract->{response_demux}{$family}{generated_completion_signals} || []),
        assertions => [
            map { $_->{name} }
            _response_demux_assertion_specs_for_family($contract, $family)
        ],
    };
}

sub _read_data_generated_artifacts($contract) {
    my $read_data = $contract->{read_data};
    my $read = $read_data->{read};
    my $payload_capture = _read_data_payload_capture_enabled($read);
    my $scalar_payload_capture = _read_data_scalar_payload_capture_enabled($read);
    my $multi_beat_payload_capture = _read_data_multi_beat_payload_capture_enabled($read);
    my @burst_length_inputs = $read->{burst_length_generated_behavior}
        ? ($read->{burst_length_signal})
        : ();
    my @burst_length_storage = map { $_->{burst_length_storage} }
        grep { exists($_->{burst_length_storage}) && defined $_->{burst_length_storage} }
        @{$read->{transactions} || []};
    my @burst_length_rules = map { _read_data_burst_length_capture_rule_name($contract, $_) }
        grep { exists($_->{burst_length_capture_rule}) && defined $_->{burst_length_capture_rule} }
        @{$read->{transactions} || []};
    my @expected_beat_count_storage = map { $_->{expected_beat_count_storage} }
        grep { exists($_->{expected_beat_count_storage}) && defined $_->{expected_beat_count_storage} }
        @{$read->{transactions} || []};
    my @beat_count_storage = map { $_->{beat_count_storage} }
        grep { exists($_->{beat_count_storage}) && defined $_->{beat_count_storage} }
        @{$read->{transactions} || []};
    my @beat_count_rules = map { ($_->{beat_count_init_rule}, $_->{beat_count_increment_rule}) }
        grep {
            exists($_->{beat_count_init_rule})
                && defined($_->{beat_count_init_rule})
                && exists($_->{beat_count_increment_rule})
                && defined($_->{beat_count_increment_rule})
        } @{$read->{transactions} || []};
    my @beat_count_assertions = map { $_->{name} }
        _read_data_beat_count_assertion_specs($contract);
    my @payload_outputs = $scalar_payload_capture
        ? map { ($_->{data_output}, $_->{status_output}) }
            @{$read->{transactions} || []}
        : ();
    if ($multi_beat_payload_capture) {
        push @payload_outputs, map {
            (
                @{$_->{generated_data_outputs} || []},
                @{$_->{generated_status_outputs} || []},
                (defined($_->{status_aggregate_output}) ? ($_->{status_aggregate_output}) : ()),
                $_->{valid_mask_output},
                $_->{length_output},
            )
        } @{$read->{transactions} || []};
    }
    my @payload_rules = $scalar_payload_capture
        ? map { _read_data_capture_rule_name($contract, $_) }
            @{$read->{transactions} || []}
        : ();
    my @multi_beat_output_init_rules = $multi_beat_payload_capture
        ? map { _read_data_multi_beat_output_init_rule_name($contract, $_) }
            @{$read->{transactions} || []}
        : ();
    my @multi_beat_capture_rules = $multi_beat_payload_capture
        ? map {
            my $transaction = $_;
            my @outputs = @{$transaction->{generated_data_outputs} || []};
            my @capture_rules = map {
                _read_data_multi_beat_capture_rule_name($contract, $transaction, $_)
            } 0 .. $#outputs;
            @capture_rules;
        } @{$read->{transactions} || []}
        : ();
    my @multi_beat_data_outputs = $multi_beat_payload_capture
        ? map { @{$_->{generated_data_outputs} || []} }
            @{$read->{transactions} || []}
        : ();
    my @multi_beat_status_outputs = $multi_beat_payload_capture
        ? map { @{$_->{generated_status_outputs} || []} }
            @{$read->{transactions} || []}
        : ();
    my @multi_beat_valid_outputs = $multi_beat_payload_capture
        ? map { $_->{valid_mask_output} }
            @{$read->{transactions} || []}
        : ();
    my @multi_beat_length_outputs = $multi_beat_payload_capture
        ? map { $_->{length_output} }
            @{$read->{transactions} || []}
        : ();
    my @status_aggregate_outputs = $read->{status_aggregation_generated_behavior}
        ? map { $_->{status_aggregate_output} }
            grep { defined($_->{status_aggregate_output}) }
            @{$read->{transactions} || []}
        : ();
    my @status_aggregate_init_rules = $read->{status_aggregation_generated_behavior}
        ? map { $_->{status_aggregate_init_rule} // _read_data_multi_beat_output_init_rule_name($contract, $_) }
            grep { defined($_->{status_aggregate_output}) }
            @{$read->{transactions} || []}
        : ();
    my @status_aggregate_update_rules = $read->{status_aggregation_generated_behavior}
        ? map { _read_data_status_aggregate_update_rule_name($contract, $_) }
            grep { defined($_->{status_aggregate_output}) }
            @{$read->{transactions} || []}
        : ();
    my @multi_beat_payload_rules = $multi_beat_payload_capture
        ? map {
            my $transaction = $_;
            my @outputs = @{$transaction->{generated_data_outputs} || []};
            my @capture_rules = map {
                _read_data_multi_beat_capture_rule_name($contract, $transaction, $_)
            } 0 .. $#outputs;
            my @status_aggregate_rules = defined($transaction->{status_aggregate_output})
                ? (_read_data_status_aggregate_update_rule_name($contract, $transaction))
                : ();
            (@capture_rules, @status_aggregate_rules);
        } @{$read->{transactions} || []}
        : ();
    return {
        inputs => _clone_jsonish(_unique_preserving([
            ($payload_capture ? ($read->{data_signal}, $read->{status_signal}) : ()),
            @burst_length_inputs,
        ])),
        outputs => \@payload_outputs,
        rules => [
            @payload_rules,
            @burst_length_rules,
            @beat_count_rules,
            @multi_beat_output_init_rules,
            @multi_beat_payload_rules,
        ],
        multi_beat_data_outputs => \@multi_beat_data_outputs,
        multi_beat_status_outputs => \@multi_beat_status_outputs,
        multi_beat_valid_outputs => \@multi_beat_valid_outputs,
        multi_beat_length_outputs => \@multi_beat_length_outputs,
        multi_beat_output_init_rules => \@multi_beat_output_init_rules,
        multi_beat_capture_rules => \@multi_beat_capture_rules,
        status_aggregate_outputs => \@status_aggregate_outputs,
        status_aggregate_init_rules => \@status_aggregate_init_rules,
        status_aggregate_update_rules => \@status_aggregate_update_rules,
        burst_length_inputs => _clone_jsonish(\@burst_length_inputs),
        burst_length_storage => _clone_jsonish(\@burst_length_storage),
        burst_length_rules => [
            @burst_length_rules,
        ],
        expected_beat_count_storage => _clone_jsonish(\@expected_beat_count_storage),
        beat_count_storage => _clone_jsonish(\@beat_count_storage),
        beat_count_rules => [
            @beat_count_rules,
        ],
        beat_count_assertions => [
            @beat_count_assertions,
        ],
    };
}

sub _response_demux_covers_auto_id_lifecycle($contract) {
    my $demux = $contract->{response_demux};
    my $lifecycle = $contract->{auto_id_lifecycle};
    return 0 unless ref($demux) eq 'HASH' && $demux->{generated_behavior};
    return 0 unless ref($lifecycle) eq 'HASH' && $lifecycle->{generated_behavior};

    for my $family (@{$lifecycle->{families} || []}) {
        my $family_name = $family->{family};
        return 0 unless ref($demux->{$family_name}) eq 'HASH'
            && $demux->{$family_name}{generated_behavior};
    }
    return 1;
}

sub _report_id_response_rule_engine($contract) {
    my $engine = $contract->{id_response_rule_engine};
    my @residue = @{$engine->{residue} || []};
    if (ref($contract->{auto_id_lifecycle}) eq 'HASH' && $contract->{auto_id_lifecycle}{generated_behavior}) {
        @residue = grep { $_ ne 'auto_id_allocation' && $_ ne 'id_release' } @residue;
    }
    if (
        _response_demux_covers_auto_id_lifecycle($contract)
    ) {
        @residue = grep { $_ ne 'response_demux' } @residue;
    }
    if (ref($contract->{same_id_issue_order_queue_behavior}) eq 'HASH'
        && $contract->{same_id_issue_order_queue_behavior}{generated_behavior}) {
        @residue = grep { $_ ne 'same_id_ordering' && $_ ne 'response_demux' } @residue;
    }
    return {
        mode => $engine->{mode},
        checks => _clone_jsonish($engine->{checks}),
        id_signal_inputs => _clone_jsonish($engine->{id_signal_inputs}),
        residue => _clone_jsonish(\@residue),
    };
}

sub _report_transaction_event_dispatch($contract) {
    my $dispatch = $contract->{transaction_event_dispatch};
    return {
        mode => $dispatch->{mode},
        directions => [
            map {
                my $direction = $_;
                my $entry = $dispatch->{$direction};
                +{
                    direction         => $direction,
                    request_events    => _clone_jsonish($entry->{request_events}),
                    completion_events => _clone_jsonish($entry->{completion_events}),
                    request_fanin     => $entry->{request_fanin},
                    completion_fanin  => $entry->{completion_fanin},
                }
            } qw(write read)
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
