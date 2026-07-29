package FSM::IAL2::ProtocolIntent::AhbSubordinate;

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
    confess "FSM::IAL2::ProtocolIntent::AhbSubordinate->generate expects exactly one contract hash reference\n"
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
        kind  => 'protocol_intent.ahb_subordinate',
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
    confess "FSM::IAL2::ProtocolIntent::AhbSubordinate->new must be called with the FSM::IAL2::ProtocolIntent::AhbSubordinate class invocant\n"
        unless defined($class) && !ref($class) && $class eq 'FSM::IAL2::ProtocolIntent::AhbSubordinate';
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
    confess "FSM::IAL2::ProtocolIntent::AhbSubordinate->$method must be called on an FSM::IAL2::ProtocolIntent::AhbSubordinate object\n"
        unless blessed($self) && $self->isa('FSM::IAL2::ProtocolIntent::AhbSubordinate');
}

sub _normalize_contract($raw) {
    my $kind = _required_scalar($raw, 'kind');
    confess "AHB subordinate IAL2 contract kind must be ahb_subordinate\n"
        unless $kind eq 'ahb_subordinate';

    my $protocol = lc _required_scalar($raw, 'protocol');
    confess "AHB subordinate IAL2 contract profile must be ahb\n"
        unless $protocol eq 'ahb';

    my $name = _required_identifier($raw, 'name');
    my $actor_name = exists($raw->{actor_name})
        ? _identifier_value($raw->{actor_name}, 'actor_name')
        : $name;
    my $role = lc _required_scalar($raw, 'role');
    confess "AHB subordinate IAL2 contract role must be subordinate\n"
        unless $role eq 'subordinate';

    my $clock = _required_identifier($raw, 'clock');
    my $reset = _normalize_reset($raw->{reset});
    my $control = _normalize_control(_required_hash($raw, 'control'));
    my $bus = _normalize_bus(_required_hash($raw, 'bus'));
    my $storage = _normalize_storage(_required_hash($raw, 'storage'), $bus);
    my $transfer = _normalize_transfer(_required_hash($raw, 'transfer'), $control, $storage, $bus);

    my @internal_signals = qw(
        addr_q write_q size_q trans_q wait_n ahb_access_done_q
        ahb_phase_pending_q next_addr_q next_write_q next_size_q next_trans_q next_wait_n
    );
    push @internal_signals, qw(seq_valid_q seq_expected_addr_q seq_size_q seq_write_q)
        if _transfer_selects_seq_policy($transfer);
    push @internal_signals, qw(burst_q next_burst_q seq_hburst_q seq_beats_remaining_q)
        if _transfer_selects_hburst_seq_policy($transfer);

    _reject_duplicate_signal_names(
        $clock,
        $reset->{signal},
        $control->{wait_cycles}{name},
        $bus->{select},
        $bus->{ready_in},
        $bus->{address}{name},
        $bus->{transfer}{name},
        exists($bus->{burst}) ? $bus->{burst}{name} : undef,
        $bus->{write},
        $bus->{size}{name},
        $bus->{write_data}{name},
        $bus->{ready_out},
        $bus->{response}{name},
        $bus->{read_data}{name},
        $storage->{register}{data}{name},
        @internal_signals,
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
        control          => $control,
        bus              => $bus,
        storage          => $storage,
        transfer         => $transfer,
        intent_name      => $intent_name,
        source_object_id => $source_object_id,
        source_anchors   => $anchors,
    };
}

sub _normalize_control($raw) {
    return {
        wait_cycles => _normalize_width_binding($raw->{wait_cycles}, 'control.wait_cycles', 4),
    };
}

sub _normalize_bus($raw) {
    my %bus = (
        select     => _required_identifier_field($raw, 'select', 'bus.select'),
        ready_in   => _required_identifier_field($raw, 'ready_in', 'bus.ready_in'),
        address    => _normalize_width_binding($raw->{address}, 'bus.address', 32),
        transfer   => _normalize_width_binding($raw->{transfer}, 'bus.transfer', 2),
        write      => _required_identifier_field($raw, 'write', 'bus.write'),
        size       => _normalize_width_binding($raw->{size}, 'bus.size', 3),
        write_data => _normalize_width_binding($raw->{write_data}, 'bus.write_data', 32),
        ready_out  => _required_identifier_field($raw, 'ready_out', 'bus.ready_out'),
        response   => _normalize_width_binding($raw->{response}, 'bus.response', 1),
        read_data  => _normalize_width_binding($raw->{read_data}, 'bus.read_data', 32),
    );
    $bus{burst} = _normalize_width_binding($raw->{burst}, 'bus.burst', 3)
        if exists $raw->{burst};

    return \%bus;
}

sub _normalize_storage($raw, $bus) {
    confess "AHB subordinate IAL2 contract storage.register must be a hash reference\n"
        unless ref($raw->{register}) eq 'HASH';
    confess "AHB subordinate IAL2 contract storage supports only one register in this slice\n"
        if exists $raw->{registers};

    my $register = $raw->{register};
    my $name = _required_identifier_field($register, 'name', 'storage.register.name');
    my $address = _normalize_address_binding($register->{address}, 'storage.register.address', 0, 32);
    my $data = _normalize_storage_data($register->{data}, 'storage.register.data', $bus->{read_data}{width}, 0);

    return {
        register => {
            name    => $name,
            address => $address,
            data    => $data,
        },
    };
}

sub _normalize_transfer($raw, $control, $storage, $bus) {
    my $name = _required_identifier_field($raw, 'name', 'transfer.name');
    my $accept_when = _normalize_accept_when(_required_hash($raw, 'accept_when'));
    my @ignored = @{_required_array($raw, 'ignored_transfer')};
    my %ignored = map { _nonempty_scalar($_, 'transfer.ignored_transfer') => 1 } @ignored;
    my @parked = exists($raw->{parked_transfer}) ? @{_required_array($raw, 'parked_transfer')} : ();
    my %parked = map { _nonempty_scalar($_, 'transfer.parked_transfer') => 1 } @parked;
    my $has_size_policy = _has_ahb_subordinate_size_policy($raw);

    # Two accepted shapes in this slice: classic (BUSY ignored alongside IDLE,
    # clearing the burst history) or BUSY-park (IDLE ignored, BUSY parked so the
    # in-word SEQ burst context holds across the BUSY beat).
    my $classic_transfer = keys(%ignored) == 2 && $ignored{idle} && $ignored{busy} && !%parked;
    my $busy_park = keys(%ignored) == 1 && $ignored{idle}
        && keys(%parked) == 1 && $parked{busy};
    confess "AHB subordinate IAL2 contract transfer must either ignore {idle, busy} or ignore {idle} and park {busy} in this slice\n"
        unless $classic_transfer || $busy_park;
    confess "AHB subordinate IAL2 contract transfer.wait_cycles must name the control.wait_cycles signal\n"
        unless _required_scalar($raw, 'wait_cycles') eq $control->{wait_cycles}{name};
    confess "AHB subordinate IAL2 contract transfer.register must name the selected storage register\n"
        if exists($raw->{register}) && $raw->{register} ne $storage->{register}{name};

    my %transfer = (
        name                 => $name,
        accept_when          => $accept_when,
        idle                 => _exact_scalar($raw, 'idle', "2'b00", 'transfer.idle'),
        busy                 => _exact_scalar($raw, 'busy', "2'b01", 'transfer.busy'),
        nonseq               => _exact_scalar($raw, 'nonseq', "2'b10", 'transfer.nonseq'),
        seq                  => _exact_scalar($raw, 'seq', "2'b11", 'transfer.seq'),
        supported_transfer   => _exact_scalar($raw, 'supported_transfer', 'nonseq', 'transfer.supported_transfer'),
        ignored_transfer     => $busy_park ? [qw(idle)] : [qw(idle busy)],
        parked_transfer      => $busy_park ? [qw(busy)] : [],
        wait_cycles          => _exact_scalar($raw, 'wait_cycles', $control->{wait_cycles}{name}, 'transfer.wait_cycles'),
        read                 => _exact_scalar($raw, 'read', 'register', 'transfer.read'),
        write                => _exact_scalar($raw, 'write', 'register', 'transfer.write'),
        unmapped_address     => _exact_scalar($raw, 'unmapped_address', 'error', 'transfer.unmapped_address'),
        unsupported_size     => _exact_scalar($raw, 'unsupported_size', 'error', 'transfer.unsupported_size'),
        unsupported_transfer => _exact_scalar($raw, 'unsupported_transfer', 'error', 'transfer.unsupported_transfer'),
        response             => _normalize_response(_required_hash($raw, 'response')),
        error_completion     => _exact_scalar($raw, 'error_completion', 'two-cycle', 'transfer.error_completion'),
    );

    if ($has_size_policy) {
        $transfer{supported_size} = _normalize_supported_size_policy($raw);
        $transfer{lane_order} = _exact_scalar($raw, 'lane_order', 'little-endian', 'transfer.lane_order');
        $transfer{narrow_write} = _exact_scalar($raw, 'narrow_write', 'preserve-inactive-lanes', 'transfer.narrow_write');
        $transfer{narrow_read} = _exact_scalar($raw, 'narrow_read', 'zero-fill-inactive-lanes', 'transfer.narrow_read');
        $transfer{unaligned_access} = _exact_scalar($raw, 'unaligned_access', 'error', 'transfer.unaligned_access');
        $transfer{crossing_access} = _exact_scalar($raw, 'crossing_access', 'error', 'transfer.crossing_access');
    }

    if (exists $raw->{seq_policy}) {
        confess "AHB subordinate IAL2 contract transfer.seq_policy requires the selected byte-lane size policy in this slice\n"
            unless $has_size_policy;
        my $seq_policy = _nonempty_scalar($raw->{seq_policy}, 'transfer.seq_policy');
        if ($seq_policy eq 'in-word-progressive') {
            $transfer{seq_policy} = _seq_policy_report();
        } elsif ($seq_policy eq 'hburst-in-word-progressive') {
            confess "AHB subordinate IAL2 contract transfer.seq_policy hburst-in-word-progressive requires bus.burst in this slice\n"
                unless exists $bus->{burst};
            $transfer{seq_policy} = _hburst_seq_policy_report($bus->{burst}{name}, $busy_park);
        } else {
            confess "AHB subordinate IAL2 contract transfer.seq_policy must be in-word-progressive or hburst-in-word-progressive in this slice\n";
        }
    }

    confess "AHB subordinate IAL2 contract parked-transfer busy requires transfer.seq_policy hburst-in-word-progressive in this slice\n"
        if $busy_park && !_transfer_selects_hburst_seq_policy(\%transfer);

    return \%transfer;
}

sub _has_ahb_subordinate_size_policy($raw) {
    for my $field (qw(supported_size lane_order narrow_write narrow_read unaligned_access crossing_access)) {
        return 1 if exists $raw->{$field};
    }
    return 0;
}

sub _normalize_supported_size_policy($raw) {
    confess "AHB subordinate IAL2 contract transfer.supported_size is required when AHB subordinate size policy clauses are present\n"
        unless exists $raw->{supported_size};

    my @sizes = @{_required_array($raw, 'supported_size')};
    my %seen;
    for my $size (@sizes) {
        my $value = _nonempty_scalar($size, 'transfer.supported_size');
        confess "AHB subordinate IAL2 contract transfer.supported_size has duplicate '$value'\n"
            if $seen{$value}++;
    }

    confess "AHB subordinate IAL2 contract transfer.supported_size must contain exactly byte, halfword, and word in this slice\n"
        unless @sizes == 3 && $seen{byte} && $seen{halfword} && $seen{word};

    return [qw(byte halfword word)];
}

sub _normalize_accept_when($raw) {
    return {
        select   => _exact_scalar($raw, 'select', '1', 'transfer.accept_when.select'),
        ready_in => _exact_scalar($raw, 'ready_in', '1', 'transfer.accept_when.ready_in'),
    };
}

sub _normalize_response($raw) {
    return {
        okay  => _exact_scalar($raw, 'okay', "1'b0", 'transfer.response.okay'),
        error => _exact_scalar($raw, 'error', "1'b1", 'transfer.response.error'),
    };
}

sub _emit_isf($contract) {
    my $control = $contract->{control};
    my $bus = $contract->{bus};
    my $storage = $contract->{storage}{register};
    my $transfer = $contract->{transfer};
    my $response = $transfer->{response};
    my $reset = _reset_clause($contract->{reset});
    my $reg_data = $storage->{data}{name};
    my $internal_done = 'ahb_access_done_q';
    my @seq_storage_lines = _seq_policy_storage_lines($contract);
    my @seq_idle_clear_lines = _seq_policy_idle_clear_rule_lines($contract);
    my @read_drive_lines = _read_drive_lines($contract);
    my @access_lines = _access_lines($contract);
    my @burst_interface_lines = exists($bus->{burst}) ? _interface_line('input', $bus->{burst}) : ();
    my @burst_phase_storage_lines = exists($bus->{burst})
        ? "    (var next_burst_q (width $bus->{burst}{width}) (reset 0))"
        : ();
    my @burst_phase_capture_lines = exists($bus->{burst})
        ? "    (set next_burst_q $bus->{burst}{name})"
        : ();
    my @burst_phase_sample_lines = exists($bus->{burst})
        ? "      (sample next_burst_q as burst_q)"
        : ();

    return join("\n",
        "(actor $contract->{actor_name}",
        "  (clock $contract->{clock})",
        "  $reset",
        "  (watchdog 65536)",
        "",
        "  (interface",
        _interface_line('input', $bus->{select}),
        _interface_line('input', $bus->{ready_in}),
        _interface_line('input', $bus->{address}),
        _interface_line('input', $bus->{transfer}),
        @burst_interface_lines,
        _interface_line('input', $bus->{write}),
        _interface_line('input', $bus->{size}),
        _interface_line('input', $bus->{write_data}),
        _interface_line('input', $control->{wait_cycles}),
        _output_interface_line($bus->{ready_out}, 1, 1),
        _output_interface_line($bus->{response}, 0, 0),
        _output_interface_line($bus->{read_data}, 0, 0) . ")",
        "",
        "  (storage",
        "    (var $reg_data (width $storage->{data}{width}) (reset $storage->{data}{reset}))",
        "    (var $internal_done (width 1) (reset 0))",
        "    (var ahb_phase_pending_q (width 1) (reset 0))",
        "    (var next_addr_q (width $bus->{address}{width}) (reset 0))",
        "    (var next_write_q (width 1) (reset 0))",
        "    (var next_size_q (width $bus->{size}{width}) (reset 0))",
        "    (var next_trans_q (width $bus->{transfer}{width}) (reset 0))",
        @burst_phase_storage_lines,
        "    (var next_wait_n (width $control->{wait_cycles}{width}) (reset 0))",
        @seq_storage_lines,
        "  )",
        "",
        "  (drive enter_data_phase",
        "    ($bus->{ready_out} 0)",
        "    ($bus->{response}{name} $response->{okay})",
        "    ($bus->{read_data}{name} 0))",
        "",
        @read_drive_lines,
        "  (drive write_hit",
        "    ($bus->{ready_out} 1)",
        "    ($bus->{response}{name} $response->{okay})",
        "    ($bus->{read_data}{name} 0))",
        "",
        "  (drive error_first",
        "    ($bus->{ready_out} 0)",
        "    ($bus->{response}{name} $response->{error})",
        "    ($bus->{read_data}{name} 0))",
        "",
        "  (drive error_complete",
        "    ($bus->{ready_out} 1)",
        "    ($bus->{response}{name} $response->{error})",
        "    ($bus->{read_data}{name} 0))",
        "",
        "  (priority ahb_phase_capture over ahb_error_retire)",
        "  (priority ahb_phase_capture over ahb_phase_hold)",
        "  (priority ahb_phase_hold over ahb_error_retire)",
        "  (priority ahb_error_retire over $transfer->{name})",
        "  (priority ahb_phase_hold over $transfer->{name})",
        "",
        "  (rule ahb_phase_capture (& (! ahb_phase_pending_q) $bus->{select} $bus->{ready_in} (| (== $bus->{transfer}{name} $transfer->{nonseq}) (== $bus->{transfer}{name} $transfer->{seq})))",
        "    (set ahb_phase_pending_q 1)",
        "    (set next_addr_q $bus->{address}{name})",
        "    (set next_write_q $bus->{write})",
        "    (set next_size_q $bus->{size}{name})",
        "    (set next_trans_q $bus->{transfer}{name})",
        @burst_phase_capture_lines,
        "    (set next_wait_n $control->{wait_cycles}{name})",
        "    (set $bus->{ready_out} 0))",
        "",
        "  (rule ahb_phase_hold ahb_phase_pending_q",
        "    (set $bus->{ready_out} 0))",
        "",
        "  (rule ahb_error_retire (& $bus->{ready_out} (== $bus->{response}{name} $response->{error}))",
        "    (set $bus->{ready_out} 1)",
        "    (set $bus->{response}{name} $response->{okay}))",
        "",
        @seq_idle_clear_lines,
        "  (transaction $transfer->{name}",
        "    (when ahb_phase_pending_q",
        "      (sample next_addr_q as addr_q)",
        "      (sample next_write_q as write_q)",
        "      (sample next_size_q as size_q)",
        "      (sample next_trans_q as trans_q)",
        @burst_phase_sample_lines,
        "      (sample next_wait_n as wait_n))",
        "    (set ahb_phase_pending_q 0)",
        "    (drive enter_data_phase)",
        "    (repeat wait_n",
        "      (wait 1))",
        @access_lines,
        "    (complete $internal_done)))",
        "",
    );
}

sub _read_drive_lines($contract) {
    my $bus = $contract->{bus};
    my $response = $contract->{transfer}{response};
    my $reg_data = $contract->{storage}{register}{data}{name};

    return (
        "  (drive read_hit",
        "    ($bus->{ready_out} 1)",
        "    ($bus->{response}{name} $response->{okay})",
        "    ($bus->{read_data}{name} $reg_data))",
        "",
    ) unless _transfer_supports_narrow_sizes($contract->{transfer});

    my @drives;
    for my $entry (
        ['read_byte_lane0_hit',     _masked_read_expr($reg_data, 0x000000ff)],
        ['read_byte_lane1_hit',     _masked_read_expr($reg_data, 0x0000ff00)],
        ['read_byte_lane2_hit',     _masked_read_expr($reg_data, 0x00ff0000)],
        ['read_byte_lane3_hit',     _masked_read_expr($reg_data, 0xff000000)],
        ['read_halfword_lane0_hit', _masked_read_expr($reg_data, 0x0000ffff)],
        ['read_halfword_lane1_hit', _masked_read_expr($reg_data, 0xffff0000)],
        ['read_word_hit',           $reg_data],
    ) {
        my ($drive, $read_expr) = @$entry;
        push @drives,
            "  (drive $drive",
            "    ($bus->{ready_out} 1)",
            "    ($bus->{response}{name} $response->{okay})",
            "    ($bus->{read_data}{name} $read_expr))",
            "";
    }
    return @drives;
}

sub _access_lines($contract) {
    return _narrow_access_lines($contract)
        if _transfer_supports_narrow_sizes($contract->{transfer});
    return _word_only_access_lines($contract);
}

sub _word_only_access_lines($contract) {
    my $bus = $contract->{bus};
    my $storage = $contract->{storage}{register};
    my $transfer = $contract->{transfer};
    my $reg_data = $storage->{data}{name};

    return (
        "    (when (== trans_q $transfer->{seq})",
        "      (drive error_first)",
        "      (drive error_complete))",
        "    (when (& (== trans_q $transfer->{nonseq}) (! (== size_q 2)))",
        "      (drive error_first)",
        "      (drive error_complete))",
        "    (when (& (== trans_q $transfer->{nonseq}) (== size_q 2) (! (== addr_q $storage->{address}{value})))",
        "      (drive error_first)",
        "      (drive error_complete))",
        "    (when (& (== trans_q $transfer->{nonseq}) (== size_q 2) (== addr_q $storage->{address}{value}) write_q)",
        "      (set $reg_data $bus->{write_data}{name})",
        "      (drive write_hit))",
        "    (when (& (== trans_q $transfer->{nonseq}) (== size_q 2) (== addr_q $storage->{address}{value}) (! write_q))",
        "      (drive read_hit))",
    );
}

sub _narrow_access_lines($contract) {
    return _narrow_hburst_seq_policy_access_lines($contract)
        if _transfer_selects_hburst_seq_policy($contract->{transfer});
    return _narrow_seq_policy_access_lines($contract)
        if _transfer_selects_seq_policy($contract->{transfer});

    my $bus = $contract->{bus};
    my $transfer = $contract->{transfer};
    my $storage = $contract->{storage}{register};
    my $reg_data = $storage->{data}{name};
    my $write_data = $bus->{write_data}{name};
    my $nonseq = "(== trans_q $transfer->{nonseq})";
    my $byte_valid = _byte_valid_access_expr();
    my $halfword_valid = _halfword_valid_access_expr();
    my $word_valid = _word_valid_access_expr($storage->{address}{value});
    my $supported_size = _supported_size_expr();
    my $valid_access = "(| $byte_valid $halfword_valid $word_valid)";

    my @lines = (
        "    (when (== trans_q $transfer->{seq})",
        "      (drive error_first)",
        "      (drive error_complete))",
        "    (when (& $nonseq (! $supported_size))",
        "      (drive error_first)",
        "      (drive error_complete))",
        "    (when (& $nonseq $supported_size (! $valid_access))",
        "      (drive error_first)",
        "      (drive error_complete))",
    );

    for my $entry (
        [$byte_valid,     _addr_low_expr(0x3, 0x0), 0x000000ff, 'read_byte_lane0_hit'],
        [$byte_valid,     _addr_low_expr(0x3, 0x1), 0x0000ff00, 'read_byte_lane1_hit'],
        [$byte_valid,     _addr_low_expr(0x3, 0x2), 0x00ff0000, 'read_byte_lane2_hit'],
        [$byte_valid,     _addr_low_expr(0x3, 0x3), 0xff000000, 'read_byte_lane3_hit'],
        [$halfword_valid, _addr_low_expr(0x2, 0x0), 0x0000ffff, 'read_halfword_lane0_hit'],
        [$halfword_valid, _addr_low_expr(0x2, 0x2), 0xffff0000, 'read_halfword_lane1_hit'],
        [$word_valid,     '(== addr_q 0)',          0xffffffff, 'read_word_hit'],
    ) {
        my ($valid_expr, $lane_expr, $write_mask, $read_drive) = @$entry;
        push @lines,
            "    (when (& $nonseq $valid_expr $lane_expr write_q)",
            _masked_write_line($reg_data, $write_data, $write_mask),
            "      (drive write_hit))",
            "    (when (& $nonseq $valid_expr $lane_expr (! write_q))",
            "      (drive $read_drive))";
    }

    return @lines;
}

sub _narrow_hburst_seq_policy_access_lines($contract) {
    my $bus = $contract->{bus};
    my $transfer = $contract->{transfer};
    my $storage = $contract->{storage}{register};
    my $reg_data = $storage->{data}{name};
    my $write_data = $bus->{write_data}{name};
    my $nonseq = "(== trans_q $transfer->{nonseq})";
    my $seq = "(== trans_q $transfer->{seq})";
    my $single = '(== burst_q 0)';
    my $wrap4 = '(== burst_q 2)';
    my $incr4 = '(== burst_q 3)';
    my $byte_valid = _byte_valid_access_expr();
    my $halfword_valid = _halfword_valid_access_expr();
    my $word_valid = _word_valid_access_expr($storage->{address}{value});
    my $valid_access = "(| $byte_valid $halfword_valid $word_valid)";
    my $byte_lane0 = _addr_low_expr(0x3, 0x0);
    my $nonseq_supported_access = "(| (& $single $valid_access) (& $wrap4 $byte_valid) (& $incr4 $byte_valid $byte_lane0))";
    my $seq_hburst_supported = '(| (== seq_hburst_q 2) (== seq_hburst_q 3))';
    my $seq_ok_base = "(& seq_valid_q (== addr_q seq_expected_addr_q) (== size_q seq_size_q) (== write_q seq_write_q) (== burst_q seq_hburst_q) (! (== seq_beats_remaining_q 0)) $seq_hburst_supported $byte_valid)";

    my @lines = (
        "    (when (& $nonseq (! $nonseq_supported_access))",
        _hburst_seq_clear_lines(),
        "      (drive error_first)",
        "      (drive error_complete))",
        "    (when (& $seq (! $seq_ok_base))",
        _hburst_seq_clear_lines(),
        "      (drive error_first)",
        "      (drive error_complete))",
    );

    for my $entry (
        [$byte_valid,     $byte_lane0,                  0x000000ff, 'read_byte_lane0_hit'],
        [$byte_valid,     _addr_low_expr(0x3, 0x1),     0x0000ff00, 'read_byte_lane1_hit'],
        [$byte_valid,     _addr_low_expr(0x3, 0x2),     0x00ff0000, 'read_byte_lane2_hit'],
        [$byte_valid,     _addr_low_expr(0x3, 0x3),     0xff000000, 'read_byte_lane3_hit'],
        [$halfword_valid, _addr_low_expr(0x2, 0x0),     0x0000ffff, 'read_halfword_lane0_hit'],
        [$halfword_valid, _addr_low_expr(0x2, 0x2),     0xffff0000, 'read_halfword_lane1_hit'],
        [$word_valid,     '(== addr_q 0)',              0xffffffff, 'read_word_hit'],
    ) {
        my ($valid_expr, $lane_expr, $write_mask, $read_drive) = @$entry;
        push @lines,
            "    (when (& $nonseq $single $valid_expr $lane_expr write_q)",
            _masked_write_line($reg_data, $write_data, $write_mask),
            _hburst_seq_clear_lines(),
            "      (drive write_hit))",
            "    (when (& $nonseq $single $valid_expr $lane_expr (! write_q))",
            _hburst_seq_clear_lines(),
            "      (drive $read_drive))";
    }

    for my $entry (
        [_addr_low_expr(0x3, 0x0), 0x000000ff, 'read_byte_lane0_hit', '32\'h00000001'],
        [_addr_low_expr(0x3, 0x1), 0x0000ff00, 'read_byte_lane1_hit', '32\'h00000002'],
        [_addr_low_expr(0x3, 0x2), 0x00ff0000, 'read_byte_lane2_hit', '32\'h00000003'],
        [_addr_low_expr(0x3, 0x3), 0xff000000, 'read_byte_lane3_hit', '32\'h00000000'],
    ) {
        my ($lane_expr, $write_mask, $read_drive, $wrap_next_addr) = @$entry;
        push @lines,
            "    (when (& $nonseq $wrap4 $byte_valid $lane_expr write_q)",
            _masked_write_line($reg_data, $write_data, $write_mask),
            _hburst_seq_arm_lines($wrap_next_addr),
            "      (drive write_hit))",
            "    (when (& $nonseq $wrap4 $byte_valid $lane_expr (! write_q))",
            _hburst_seq_arm_lines($wrap_next_addr),
            "      (drive $read_drive))";
    }

    push @lines,
        "    (when (& $nonseq $incr4 $byte_valid $byte_lane0 write_q)",
        _masked_write_line($reg_data, $write_data, 0x000000ff),
        _hburst_seq_arm_lines('32\'h00000001'),
        "      (drive write_hit))",
        "    (when (& $nonseq $incr4 $byte_valid $byte_lane0 (! write_q))",
        _hburst_seq_arm_lines('32\'h00000001'),
        "      (drive read_byte_lane0_hit))";

    for my $entry (
        [_addr_low_expr(0x3, 0x0), 0x000000ff, 'read_byte_lane0_hit'],
        [_addr_low_expr(0x3, 0x1), 0x0000ff00, 'read_byte_lane1_hit'],
        [_addr_low_expr(0x3, 0x2), 0x00ff0000, 'read_byte_lane2_hit'],
        [_addr_low_expr(0x3, 0x3), 0xff000000, 'read_byte_lane3_hit'],
    ) {
        my ($lane_expr, $write_mask, $read_drive) = @$entry;
        push @lines,
            "    (when (& $seq $seq_ok_base $lane_expr write_q)",
            _masked_write_line($reg_data, $write_data, $write_mask),
            _hburst_seq_advance_lines(),
            "      (drive write_hit))",
            "    (when (& $seq $seq_ok_base $lane_expr (! write_q))",
            _hburst_seq_advance_lines(),
            "      (drive $read_drive))";
    }

    return @lines;
}

sub _narrow_seq_policy_access_lines($contract) {
    my $bus = $contract->{bus};
    my $transfer = $contract->{transfer};
    my $storage = $contract->{storage}{register};
    my $reg_data = $storage->{data}{name};
    my $write_data = $bus->{write_data}{name};
    my $nonseq = "(== trans_q $transfer->{nonseq})";
    my $seq = "(== trans_q $transfer->{seq})";
    my $byte_valid = _byte_valid_access_expr();
    my $halfword_valid = _halfword_valid_access_expr();
    my $word_valid = _word_valid_access_expr($storage->{address}{value});
    my $supported_size = _supported_size_expr();
    my $valid_access = "(| $byte_valid $halfword_valid $word_valid)";
    my $seq_supported_access = "(| $byte_valid $halfword_valid)";
    my $seq_ok_base = "(& seq_valid_q (== addr_q seq_expected_addr_q) (== size_q seq_size_q) (== write_q seq_write_q))";

    my @lines = (
        "    (when (& $nonseq (! $supported_size))",
        _seq_clear_lines(),
        "      (drive error_first)",
        "      (drive error_complete))",
        "    (when (& $nonseq $supported_size (! $valid_access))",
        _seq_clear_lines(),
        "      (drive error_first)",
        "      (drive error_complete))",
        "    (when (& $seq (! (& $seq_ok_base $seq_supported_access)))",
        _seq_clear_lines(),
        "      (drive error_first)",
        "      (drive error_complete))",
    );

    for my $entry (
        [$byte_valid,     _addr_low_expr(0x3, 0x0), 0x000000ff, 'read_byte_lane0_hit',     1],
        [$byte_valid,     _addr_low_expr(0x3, 0x1), 0x0000ff00, 'read_byte_lane1_hit',     2],
        [$byte_valid,     _addr_low_expr(0x3, 0x2), 0x00ff0000, 'read_byte_lane2_hit',     3],
        [$byte_valid,     _addr_low_expr(0x3, 0x3), 0xff000000, 'read_byte_lane3_hit', undef],
        [$halfword_valid, _addr_low_expr(0x2, 0x0), 0x0000ffff, 'read_halfword_lane0_hit', 2],
        [$halfword_valid, _addr_low_expr(0x2, 0x2), 0xffff0000, 'read_halfword_lane1_hit', undef],
        [$word_valid,     '(== addr_q 0)',          0xffffffff, 'read_word_hit', undef],
    ) {
        my ($valid_expr, $lane_expr, $write_mask, $read_drive, $next_addr) = @$entry;
        push @lines,
            "    (when (& $nonseq $valid_expr $lane_expr write_q)",
            _masked_write_line($reg_data, $write_data, $write_mask),
            _seq_update_lines($next_addr),
            "      (drive write_hit))",
            "    (when (& $nonseq $valid_expr $lane_expr (! write_q))",
            _seq_update_lines($next_addr),
            "      (drive $read_drive))";

        next if $write_mask == 0xffffffff;

        push @lines,
            "    (when (& $seq $seq_ok_base $valid_expr $lane_expr write_q)",
            _masked_write_line($reg_data, $write_data, $write_mask),
            _seq_update_lines($next_addr),
            "      (drive write_hit))",
            "    (when (& $seq $seq_ok_base $valid_expr $lane_expr (! write_q))",
            _seq_update_lines($next_addr),
            "      (drive $read_drive))";
    }

    return @lines;
}

sub _transfer_supports_narrow_sizes($transfer) {
    return exists $transfer->{supported_size};
}

sub _transfer_selects_seq_policy($transfer) {
    return ref($transfer->{seq_policy}) eq 'HASH' && $transfer->{seq_policy}{selected};
}

sub _transfer_selects_hburst_seq_policy($transfer) {
    return _transfer_selects_seq_policy($transfer)
        && ($transfer->{seq_policy}{mode} // '') eq 'hburst_in_word_progressive';
}

sub _transfer_parks_busy($transfer) {
    return ref($transfer->{parked_transfer}) eq 'ARRAY'
        && scalar(grep { $_ eq 'busy' } @{$transfer->{parked_transfer}});
}

sub _seq_policy_storage_lines($contract) {
    return () unless _transfer_selects_seq_policy($contract->{transfer});
    my @lines = (
        "    (var seq_valid_q (width 1) (reset 0))",
        "    (var seq_expected_addr_q (width 32) (reset 0))",
        "    (var seq_size_q (width 3) (reset 0))",
        "    (var seq_write_q (width 1) (reset 0))",
    );
    push @lines,
        "    (var seq_hburst_q (width 3) (reset 0))",
        "    (var seq_beats_remaining_q (width 2) (reset 0))"
        if _transfer_selects_hburst_seq_policy($contract->{transfer});
    return @lines;
}

sub _seq_policy_idle_clear_rule_lines($contract) {
    return () unless _transfer_selects_seq_policy($contract->{transfer});

    my $bus = $contract->{bus};
    my $transfer = $contract->{transfer};
    my @clear_lines = _transfer_selects_hburst_seq_policy($transfer)
        ? _hburst_seq_clear_lines('      ')
        : _seq_clear_lines('      ');
    # When BUSY parks, the burst context is held across a BUSY beat, so the
    # idle-clear rule fires on IDLE only; otherwise BUSY clears like IDLE.
    my $clear_when = _transfer_parks_busy($transfer)
        ? "(== $bus->{transfer}{name} $transfer->{idle})"
        : "(| (== $bus->{transfer}{name} $transfer->{idle}) (== $bus->{transfer}{name} $transfer->{busy}))";
    return (
        "  (priority ahb_seq_idle_clear over $transfer->{name})",
        "",
        "  (rule ahb_seq_idle_clear (& $bus->{select} $bus->{ready_in} $clear_when)",
        @clear_lines,
        "  )",
        "",
    );
}

sub _seq_update_lines($next_addr) {
    return _seq_clear_lines()
        unless defined $next_addr;

    return (
        "      (set seq_valid_q 1)",
        "      (set seq_expected_addr_q " . _hex_literal(32, $next_addr) . ")",
        "      (set seq_size_q size_q)",
        "      (set seq_write_q write_q)",
    );
}

sub _hburst_seq_arm_lines($next_addr_expr) {
    return (
        "      (set seq_valid_q 1)",
        "      (set seq_expected_addr_q $next_addr_expr)",
        "      (set seq_size_q size_q)",
        "      (set seq_write_q write_q)",
        "      (set seq_hburst_q burst_q)",
        "      (set seq_beats_remaining_q 3)",
    );
}

sub _hburst_seq_advance_lines() {
    return (
        "      (when (== seq_beats_remaining_q 1)",
        _hburst_seq_clear_lines('        '),
        "      )",
        "      (when (! (== seq_beats_remaining_q 1))",
        "        (set seq_valid_q 1)",
        "        (when (== seq_hburst_q 2) (set seq_expected_addr_q (& (+ addr_q 1) 32'h00000003)))",
        "        (when (== seq_hburst_q 3) (set seq_expected_addr_q (+ addr_q 1)))",
        "        (set seq_beats_remaining_q (- seq_beats_remaining_q 1)))",
    );
}

sub _hburst_seq_clear_lines($indent = '      ') {
    return (
        _seq_clear_lines($indent),
        "${indent}(set seq_hburst_q 0)",
        "${indent}(set seq_beats_remaining_q 0)",
    );
}

sub _seq_clear_lines($indent = '      ') {
    return (
        "${indent}(set seq_valid_q 0)",
        "${indent}(set seq_expected_addr_q 0)",
        "${indent}(set seq_size_q 0)",
        "${indent}(set seq_write_q 0)",
    );
}

sub _supported_size_expr() {
    return "(| (== size_q 0) (== size_q 1) (== size_q 2))";
}

sub _byte_valid_access_expr() {
    return "(& (== size_q 0) (== (& addr_q 32'hfffffffc) 32'h00000000))";
}

sub _halfword_valid_access_expr() {
    return "(& (== size_q 1) (== (& addr_q 32'hfffffffc) 32'h00000000) (== (& addr_q 32'h00000001) 32'h00000000))";
}

sub _word_valid_access_expr($address) {
    return "(& (== size_q 2) (== addr_q $address))";
}

sub _addr_low_expr($mask, $value) {
    return "(== (& addr_q " . _hex_literal(32, $mask) . ") " . _hex_literal(32, $value) . ")";
}

sub _masked_write_line($data_signal, $write_data, $write_mask) {
    return "      (set $data_signal $write_data)"
        if $write_mask == 0xffffffff;

    my $preserve_mask = 0xffffffff ^ $write_mask;
    return "      (set $data_signal (| (& $data_signal " . _hex_literal(32, $preserve_mask) . ") (& $write_data " . _hex_literal(32, $write_mask) . ")))";
}

sub _masked_read_expr($data_signal, $read_mask) {
    return "(& $data_signal " . _hex_literal(32, $read_mask) . ")";
}

sub _build_report(%args) {
    my $contract = $args{contract};
    my @fsm_files = @{$args{fsm_files} || []};
    my $bus = $contract->{bus};
    my $control = $contract->{control};
    my $transfer = $contract->{transfer};
    my @captured_address_control = (
        $bus->{address}{name},
        $bus->{transfer}{name},
        (exists($bus->{burst}) ? $bus->{burst}{name} : ()),
        $bus->{write},
        $bus->{size}{name},
        $control->{wait_cycles}{name},
    );

    my %source_object = (
        id      => $contract->{source_object_id},
        anchors => _clone_jsonish($contract->{source_anchors}),
    );
    $source_object{intent_name} = $contract->{intent_name}
        if defined($contract->{intent_name}) && length($contract->{intent_name});

    my @enforced_static_rules = (
        'profile must be ahb and the object must be ahb-subordinate',
        'role must be subordinate',
        'address, write-data, read-data, and register data widths are 32 in this slice',
        'AHB transfer width is 2, size width is 3, response width is 1, and wait-cycles width is 4 in this slice',
        'every selected ready NONSEQ or SEQ address phase is retained exactly once through one accepted next address/control bank while HWDATA remains live data-phase state',
        _transfer_selects_hburst_seq_policy($contract->{transfer})
            ? (
                'selected transfer support is NONSEQ SINGLE byte, halfword, and word access plus byte-only HBURST WRAP4/INCR4 in-word SEQ; IDLE and BUSY remain ignored and clear HBURST continuation history',
                'HBURST SINGLE completes only independent NONSEQ transfers and never arms SEQ history; HBURST WRAP4 may start on any byte lane, and HBURST INCR4 must start on byte lane 0',
                'SEQ completes OKAY only when the previous active transfer completed OKAY as HBURST WRAP4/INCR4 NONSEQ or valid SEQ, HBURST, HWRITE, and HSIZE match, HADDR equals the expected next in-word byte address, and four-beat history remains active',
                'byte accesses require HSIZE 0 and HADDR[31:2] == 0; halfword accesses require HSIZE 1, HADDR[31:2] == 0, and HADDR[0] == 0; word accesses require HSIZE 2 and HADDR == 0 but do not arm SEQ continuation',
                'little-endian byte lanes map lane0 to bits [7:0], lane1 to bits [15:8], lane2 to bits [23:16], and lane3 to bits [31:24]',
                'narrow writes preserve inactive register lanes and narrow reads zero-fill inactive HRDATA lanes',
            )
            : _transfer_selects_seq_policy($contract->{transfer})
            ? (
                'selected transfer support is NONSEQ byte, halfword, and word access plus bounded in-word SEQ byte/halfword continuation; IDLE and BUSY remain ignored and clear continuation history',
                'SEQ completes OKAY only when the previous active transfer completed OKAY as NONSEQ or valid SEQ, HWRITE and HSIZE match, HADDR equals the expected next in-word address, and the current size is byte or halfword',
                'byte accesses require HSIZE 0 and HADDR[31:2] == 0; halfword accesses require HSIZE 1, HADDR[31:2] == 0, and HADDR[0] == 0; word accesses require HSIZE 2 and HADDR == 0 but do not arm SEQ continuation',
                'little-endian byte lanes map lane0 to bits [7:0], lane1 to bits [15:8], lane2 to bits [23:16], and lane3 to bits [31:24]',
                'narrow writes preserve inactive register lanes and narrow reads zero-fill inactive HRDATA lanes',
            )
            : _transfer_supports_narrow_sizes($contract->{transfer})
            ? (
                'selected transfer support is NONSEQ byte, halfword, and word access; IDLE and BUSY remain ignored, and SEQ is an unsupported burst continuation',
                'byte accesses require HSIZE 0 and HADDR[31:2] == 0; halfword accesses require HSIZE 1, HADDR[31:2] == 0, and HADDR[0] == 0; word accesses require HSIZE 2 and HADDR == 0',
                'little-endian byte lanes map lane0 to bits [7:0], lane1 to bits [15:8], lane2 to bits [23:16], and lane3 to bits [31:24]',
                'narrow writes preserve inactive register lanes and narrow reads zero-fill inactive HRDATA lanes',
            )
            : 'selected transfer support is NONSEQ word access only; IDLE and BUSY remain ignored, and SEQ is an unsupported burst continuation',
        'the implemented register map contains exactly one address-0 register with reset value 0',
        _transfer_selects_hburst_seq_policy($contract->{transfer})
            ? 'unsupported transfer, standalone SEQ, SEQ after SINGLE/IDLE/BUSY/ERROR, changed-HBURST/HWRITE/HSIZE SEQ, unexpected-address SEQ, unsupported HBURST, unsupported size, unmapped address, unaligned access, and crossing access complete with the selected two-cycle ERROR response'
            : _transfer_selects_seq_policy($contract->{transfer})
            ? 'unsupported transfer, standalone SEQ, SEQ after IDLE/BUSY/ERROR, changed-control SEQ, unexpected-address SEQ, unsupported size, unmapped address, unaligned access, and crossing access complete with the selected two-cycle ERROR response'
            : _transfer_supports_narrow_sizes($contract->{transfer})
            ? 'unsupported transfer, unsupported size, unmapped address, unaligned access, and crossing access complete with the selected two-cycle ERROR response'
            : 'unsupported transfer, unsupported size, and unmapped address complete with the selected two-cycle ERROR response',
        'direct IAL2-to-IAL0 lowering is forbidden',
    );

    my %report = (
        schema => 'fsmgen.ial2.protocol_intent.ahb_subordinate.v1',
        mode   => 'subordinate',
        layering => {
            source_layer          => 'IAL2',
            generated_ial1_format => 'isf',
            generated_ial0_format => 'fsm',
            direct_ial2_to_ial0   => JSON::PP::false,
        },
        source_object => \%source_object,
        target_protocol => {
            profile => $contract->{protocol},
            object  => 'ahb-subordinate',
            role    => $contract->{role},
            transfer => $contract->{transfer}{name},
        },
        subordinate => {
            name       => $contract->{name},
            actor_name => $contract->{actor_name},
        },
        bindings => {
            clock   => $contract->{clock},
            reset   => _clone_jsonish($contract->{reset}),
            control => _clone_jsonish($contract->{control}),
            bus     => _clone_jsonish($contract->{bus}),
            storage => _clone_jsonish($contract->{storage}),
        },
        transfer => _clone_jsonish($contract->{transfer}),
        output_defaults => {
            $contract->{bus}{ready_out} => { reset => 1, default => 1 },
            $contract->{bus}{response}{name} => { reset => 0, default => 0 },
            $contract->{bus}{read_data}{name} => { reset => 0, default => 0 },
        },
        phase_pipeline => {
            selected => JSON::PP::true,
            mode => 'one_accepted_next_address_control',
            accepted_next_capacity => 1,
            acceptance => {
                select => $bus->{select},
                ready => $bus->{ready_in},
                transfer => $bus->{transfer}{name},
                active_values => [$transfer->{nonseq}, $transfer->{seq}],
            },
            captured_address_control => \@captured_address_control,
            write_data => {
                signal => $bus->{write_data}{name},
                policy => 'live_data_phase_held_while_stalled',
            },
            overflow => 'stall_before_another_acceptance',
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
                kind           => 'generated_subordinate_fsm',
                entry_artifact => "$contract->{actor_name}.fsm",
            },
        },
        enforced_static_rules => \@enforced_static_rules,
        unsupported_residue => _unsupported_residue($contract),
    );

    $report{narrow_transfer_policy} = _narrow_transfer_policy_report()
        if _transfer_supports_narrow_sizes($contract->{transfer});

    return \%report;
}

sub _narrow_transfer_policy_report() {
    return {
        supported_sizes => [
            {
                name => 'byte',
                hsize => "3'b000",
                bytes => 1,
                address_rule => 'HADDR[31:2] == 0',
                active_lane => 'HADDR[1:0]',
            },
            {
                name => 'halfword',
                hsize => "3'b001",
                bytes => 2,
                address_rule => 'HADDR[31:2] == 0 && HADDR[0] == 0',
                active_lane => 'HADDR[1]',
            },
            {
                name => 'word',
                hsize => "3'b010",
                bytes => 4,
                address_rule => 'HADDR[31:2] == 0 && HADDR[1:0] == 0',
                active_lane => 'all',
            },
        ],
        lane_order => 'little-endian',
        byte_lanes => [
            { lane => 0, bits => '[7:0]',   mask => _hex_literal(32, 0x000000ff) },
            { lane => 1, bits => '[15:8]',  mask => _hex_literal(32, 0x0000ff00) },
            { lane => 2, bits => '[23:16]', mask => _hex_literal(32, 0x00ff0000) },
            { lane => 3, bits => '[31:24]', mask => _hex_literal(32, 0xff000000) },
        ],
        narrow_write => {
            policy => 'preserve-inactive-lanes',
            effect => 'active write lanes replace storage lanes; inactive storage lanes are preserved',
        },
        narrow_read => {
            policy => 'zero-fill-inactive-lanes',
            effect => 'active storage lanes drive HRDATA in place; inactive HRDATA lanes drive zero',
        },
        error_policy => [
            'unsupported-size',
            'unsupported-transfer',
            'unmapped-address',
            'unaligned-access',
            'crossing-access',
        ],
    };
}

sub _seq_policy_report() {
    return {
        selected => JSON::PP::true,
        mode => 'in_word_progressive',
        requires_prior_transfer => 'prior_okay_nonseq_or_seq',
        supported_sizes => [qw(byte halfword)],
        address_progression => 'previous_address_plus_size_bytes',
        control_stability => [qw(HWRITE HSIZE)],
        clears_on => [qw(reset idle busy error new_nonseq)],
    };
}

sub _hburst_seq_policy_report($burst_signal, $parks_busy = 0) {
    my %report = (
        selected => JSON::PP::true,
        mode => 'hburst_in_word_progressive',
        base_policy => 'in_word_progressive',
        length_source => $burst_signal,
        requires_prior_transfer => 'prior_okay_hburst_nonseq_or_seq',
        supported_sizes => [qw(byte)],
        supported_hburst_modes => [qw(WRAP4 INCR4)],
        fail_closed_hburst_modes => [qw(INCR WRAP8 INCR8 WRAP16 INCR16)],
        single_policy => 'nonseq_only_no_seq_history',
        beats_per_burst => 4,
        window_bytes => 4,
        address_progression => 'hburst_incr4_or_wrap4_within_word',
        control_stability => [qw(HBURST HWRITE HSIZE)],
    );
    if ($parks_busy) {
        # BUSY parks: the burst context is held across a BUSY beat instead of
        # cleared, so BUSY leaves clears_on and moves to parks_on.
        $report{clears_on} = [qw(reset idle error new_nonseq final_beat)];
        $report{parks_on} = [qw(busy)];
    } else {
        $report{clears_on} = [qw(reset idle busy error new_nonseq final_beat)];
    }
    return \%report;
}

sub _unsupported_residue($contract) {
    my $optional_signal_detail = _transfer_selects_hburst_seq_policy($contract->{transfer})
        ? 'HPROT, HMASTLOCK, AHB5 optional/property-gated signals, exclusive access, and legacy two-bit HRESP compatibility remain deferred.'
        : _transfer_supports_narrow_sizes($contract->{transfer})
        ? 'HBURST, HPROT, HMASTLOCK, AHB5 optional/property-gated signals, exclusive access, and legacy two-bit HRESP compatibility remain deferred.'
        : 'HBURST, HPROT, HMASTLOCK, AHB5 optional/property-gated signals, byte lanes, exclusive access, and legacy two-bit HRESP compatibility remain deferred.';
    my $seq_detail = _transfer_selects_hburst_seq_policy($contract->{transfer})
        ? (_transfer_parks_busy($contract->{transfer})
            ? 'Byte-only HBURST WRAP4/INCR4 in-word SEQ with BUSY-in-burst parking is shipped for this endpoint source; indefinite INCR, WRAP8/INCR8/WRAP16/INCR16, halfword/word burst SEQ, multi-word/register-bank progression, .ahb alias exposure, aggregate propagation, full-manager behavior, direct backend behavior, verification-output generation, backend-language variants, AXI, APB, broader AHB behavior, and VHDL remain future work.'
            : 'Byte-only HBURST WRAP4/INCR4 in-word SEQ is shipped for this endpoint source; indefinite INCR, WRAP8/INCR8/WRAP16/INCR16, halfword/word burst SEQ, BUSY-in-burst continuation, multi-word/register-bank progression, .ahb alias exposure, aggregate propagation, full-manager behavior, direct backend behavior, verification-output generation, backend-language variants, AXI, APB, broader AHB behavior, and VHDL remain future work.')
        : _transfer_selects_seq_policy($contract->{transfer})
        ? 'HBURST-driven length/wrap semantics, BUSY-in-burst continuation rather than history clearing, multi-word/register-bank progression, .ahb alias exposure, aggregate propagation, full-manager behavior, direct backend behavior, verification-output generation, backend-language variants, AXI, APB, broader AHB behavior, and VHDL remain future work.'
        : 'SEQ burst continuation, wrapping/incrementing bursts, burst address progression, and broader manager/subordinate behavior remain future work.';

    return [
        {
            id => 'ahb_subordinate_profile_alias_deferred',
            detail => 'The AHB subordinate behavior is exposed only through generic .ppif in this slice; widening the .ahb profile alias remains future work.',
        },
        {
            id => 'ahb_interconnect_generation_deferred',
            detail => 'AHB interconnect/decode, arbitration fabrics, and requester/subordinate composition remain future task-tree work.',
        },
        {
            id => 'ahb_subordinate_optional_signal_residue',
            detail => $optional_signal_detail,
        },
        {
            id => 'ahb_burst_seq_support_deferred',
            detail => $seq_detail,
        },
        {
            id => 'ahb_verification_output_deferred',
            detail => 'Verification-output generation, direct backend behavior, backend-language variants, AXI, APB, and VHDL remain deferred.',
        },
    ];
}

sub _required_scalar($raw, $field) {
    confess "AHB subordinate IAL2 contract is missing required scalar field '$field'\n"
        unless exists($raw->{$field});
    return _nonempty_scalar($raw->{$field}, $field);
}

sub _required_hash($raw, $field) {
    confess "AHB subordinate IAL2 contract field '$field' must be a hash reference\n"
        unless ref($raw->{$field}) eq 'HASH';
    return $raw->{$field};
}

sub _required_array($raw, $field) {
    confess "AHB subordinate IAL2 contract field '$field' must be an array reference\n"
        unless ref($raw->{$field}) eq 'ARRAY';
    return $raw->{$field};
}

sub _required_identifier($raw, $field) {
    return _identifier_value(_required_scalar($raw, $field), $field);
}

sub _required_identifier_field($raw, $field, $label) {
    confess "AHB subordinate IAL2 contract is missing required field '$label'\n"
        unless exists($raw->{$field});
    return _identifier_value($raw->{$field}, $label);
}

sub _normalize_width_binding($raw, $field, $expected_width) {
    confess "AHB subordinate IAL2 contract field '$field' must be a hash reference\n"
        unless ref($raw) eq 'HASH';
    my $name = _identifier_value($raw->{name}, "$field.name");
    my $width = _positive_integer($raw->{width}, "$field.width");
    confess "AHB subordinate IAL2 contract $field.width must be $expected_width in this slice\n"
        unless $width == $expected_width;
    return {
        name  => $name,
        width => $width,
    };
}

sub _normalize_address_binding($raw, $field, $expected_value, $expected_width) {
    confess "AHB subordinate IAL2 contract field '$field' must be an address/width hash reference\n"
        unless ref($raw) eq 'HASH';
    my $value = _non_negative_integer($raw->{value}, "$field.value");
    my $width = _positive_integer($raw->{width}, "$field.width");
    confess "AHB subordinate IAL2 contract $field.value must be $expected_value in this slice\n"
        unless $value == $expected_value;
    confess "AHB subordinate IAL2 contract $field.width must be $expected_width in this slice\n"
        unless $width == $expected_width;
    return {
        value => $value,
        width => $width,
    };
}

sub _normalize_storage_data($raw, $field, $expected_width, $expected_reset) {
    confess "AHB subordinate IAL2 contract field '$field' must be a signal/width/reset hash reference\n"
        unless ref($raw) eq 'HASH';
    my $binding = _normalize_width_binding($raw, $field, $expected_width);
    my $reset = _non_negative_integer($raw->{reset}, "$field.reset");
    confess "AHB subordinate IAL2 contract $field.reset must be $expected_reset in this slice\n"
        unless $reset == $expected_reset;
    return {
        %$binding,
        reset => $reset,
    };
}

sub _exact_scalar($raw, $field, $expected, $label) {
    confess "AHB subordinate IAL2 contract is missing required field '$label'\n"
        unless exists($raw->{$field});
    my $value = _nonempty_scalar($raw->{$field}, $label);
    confess "AHB subordinate IAL2 contract $label must be $expected in this slice\n"
        unless $value eq $expected;
    return $value;
}

sub _normalize_reset($raw_reset) {
    confess "AHB subordinate IAL2 contract is missing required reset binding\n"
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
    confess "AHB subordinate IAL2 contract source.anchors must be an array reference\n"
        unless ref($anchors) eq 'ARRAY';

    my @normalized;
    for my $index (0 .. $#$anchors) {
        my $anchor = $anchors->[$index];
        if (ref($anchor) eq 'HASH') {
            for my $required (qw(document section page)) {
                confess "AHB subordinate IAL2 contract source.anchors[$index] is missing '$required'\n"
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

sub _reject_duplicate_signal_names(@names) {
    my %seen;
    for my $name (@names) {
        next unless defined($name) && !ref($name) && length($name);
        confess "AHB subordinate IAL2 contract duplicates interface/internal signal '$name'\n"
            if $seen{$name}++;
    }
}

sub _nonempty_scalar($value, $field) {
    confess "AHB subordinate IAL2 contract field '$field' must be a non-empty scalar\n"
        if !defined($value) || ref($value) || $value eq '';
    return $value;
}

sub _identifier_value($value, $field) {
    confess "AHB subordinate IAL2 contract field '$field' must be an ISF identifier\n"
        unless defined($value) && !ref($value) && $value =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
    return $value;
}

sub _positive_integer($value, $field) {
    confess "AHB subordinate IAL2 contract field '$field' must be a positive integer\n"
        unless defined($value) && !ref($value) && $value =~ /\A[1-9][0-9]*\z/;
    return int($value);
}

sub _non_negative_integer($value, $field) {
    confess "AHB subordinate IAL2 contract field '$field' must be a non-negative integer\n"
        unless defined($value) && !ref($value) && $value =~ /\A(?:0|[1-9][0-9]*)\z/;
    return int($value);
}

sub _bool_value($value, $field) {
    confess "AHB subordinate IAL2 contract field '$field' must be boolean 0 or 1\n"
        if ref($value) || !defined($value) || ($value ne '0' && $value ne '1');
    return $value ? 1 : 0;
}

sub _hex_literal($width, $value) {
    return sprintf("%d'h%0*x", $width, int($width / 4), $value);
}

sub _interface_line($direction, $binding) {
    return "    ($direction $binding)"
        unless ref($binding) eq 'HASH';
    return $binding->{width} == 1
        ? "    ($direction $binding->{name})"
        : "    ($direction $binding->{name} (width $binding->{width}))";
}

sub _output_interface_line($binding, $reset, $default) {
    my $name = ref($binding) eq 'HASH' ? $binding->{name} : $binding;
    my $width = ref($binding) eq 'HASH' ? $binding->{width} : 1;
    my $width_clause = $width == 1 ? '' : " (width $width)";
    return "    (output $name$width_clause (reset $reset) (default $default))";
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
    return { map { $_ => _clone_jsonish($value->{$_}) } sort keys %$value } if ref($value) eq 'HASH';
    return $value;
}

1;
