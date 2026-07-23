package FSM::IAL2::ProtocolIntent::AhbRequester;

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
    confess "FSM::IAL2::ProtocolIntent::AhbRequester->generate expects exactly one contract hash reference\n"
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
        kind  => 'protocol_intent.ahb_requester',
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
    confess "FSM::IAL2::ProtocolIntent::AhbRequester->new must be called with the FSM::IAL2::ProtocolIntent::AhbRequester class invocant\n"
        unless defined($class) && !ref($class) && $class eq 'FSM::IAL2::ProtocolIntent::AhbRequester';
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
    confess "FSM::IAL2::ProtocolIntent::AhbRequester->$method must be called on an FSM::IAL2::ProtocolIntent::AhbRequester object\n"
        unless blessed($self) && $self->isa('FSM::IAL2::ProtocolIntent::AhbRequester');
}

sub _normalize_contract($raw) {
    my $kind = _required_scalar($raw, 'kind');
    confess "AHB requester IAL2 contract kind must be ahb_requester\n"
        unless $kind eq 'ahb_requester';

    my $protocol = lc _required_scalar($raw, 'protocol');
    confess "AHB requester IAL2 contract profile must be ahb\n"
        unless $protocol eq 'ahb';

    my $name = _required_identifier($raw, 'name');
    my $actor_name = exists($raw->{actor_name})
        ? _identifier_value($raw->{actor_name}, 'actor_name')
        : $name;
    my $role = lc _required_scalar($raw, 'role');
    confess "AHB requester IAL2 contract role must be requester\n"
        unless $role eq 'requester';

    my $clock = _required_identifier($raw, 'clock');
    my $reset = _normalize_reset($raw->{reset});
    my $local_command = _normalize_local_command(_required_hash($raw, 'local_command'));
    my $local_status = _normalize_local_status(_required_hash($raw, 'local_status'));
    my $bus = _normalize_bus(_required_hash($raw, 'bus'));
    my $burst = _normalize_burst(_required_hash($raw, 'burst'));
    my $transfer = _normalize_transfer(_required_hash($raw, 'transfer'));
    my $response = _normalize_response(_required_hash($raw, 'response'));

    my @internal_signal_names = qw(addr_step_q ahb_request_done_q beat_index_q beats_remaining_q beats_total_q burst_active_q last_error_q last_read_data_q last_resp_q last_retry_q last_split_q wrap_base_q wrap_high_q wrap_mode_q wrap_span_q);
    push @internal_signal_names, 'busy_inserted_q'
        if defined($transfer->{busy_before_beat});

    _reject_duplicate_signal_names(
        $clock,
        $reset->{signal},
        _binding_names($local_command),
        _binding_names($local_status),
        _binding_names($bus),
        @internal_signal_names,
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
        local_command    => $local_command,
        local_status     => $local_status,
        bus              => $bus,
        burst            => $burst,
        transfer         => $transfer,
        response         => $response,
        intent_name      => $intent_name,
        source_object_id => $source_object_id,
        source_anchors   => $anchors,
    };
}

sub _normalize_local_command($raw) {
    return {
        valid           => _required_identifier_field($raw, 'valid', 'local_command.valid'),
        ready           => _required_identifier_field($raw, 'ready', 'local_command.ready'),
        write           => _required_identifier_field($raw, 'write', 'local_command.write'),
        address         => _normalize_width_binding($raw->{address}, 'local_command.address', 32),
        write_data      => _normalize_width_binding($raw->{write_data}, 'local_command.write_data', 32),
        write_data_step => _normalize_width_binding($raw->{write_data_step}, 'local_command.write_data_step', 32),
        size            => _normalize_width_binding($raw->{size}, 'local_command.size', 3),
        protection      => _normalize_width_binding($raw->{protection}, 'local_command.protection', 4),
        lock            => _required_identifier_field($raw, 'lock', 'local_command.lock'),
        burst           => _normalize_width_binding($raw->{burst}, 'local_command.burst', 3),
        length          => _normalize_width_binding($raw->{length}, 'local_command.length', 5),
    };
}

sub _normalize_local_status($raw) {
    return {
        busy            => _required_identifier_field($raw, 'busy', 'local_status.busy'),
        beat_done       => _required_identifier_field($raw, 'beat_done', 'local_status.beat_done'),
        done            => _required_identifier_field($raw, 'done', 'local_status.done'),
        burst_active    => _required_identifier_field($raw, 'burst_active', 'local_status.burst_active'),
        wrap_active     => _required_identifier_field($raw, 'wrap_active', 'local_status.wrap_active'),
        beat_index      => _normalize_width_binding($raw->{beat_index}, 'local_status.beat_index', 5),
        beats_remaining => _normalize_width_binding($raw->{beats_remaining}, 'local_status.beats_remaining', 5),
        active_address  => _normalize_width_binding($raw->{active_address}, 'local_status.active_address', 32),
        active_burst    => _normalize_width_binding($raw->{active_burst}, 'local_status.active_burst', 3),
        last_error      => _required_identifier_field($raw, 'last_error', 'local_status.last_error'),
        last_retry      => _required_identifier_field($raw, 'last_retry', 'local_status.last_retry'),
        last_split      => _required_identifier_field($raw, 'last_split', 'local_status.last_split'),
        last_response   => _normalize_width_binding($raw->{last_response}, 'local_status.last_response', 2),
        last_read_data  => _normalize_width_binding($raw->{last_read_data}, 'local_status.last_read_data', 32),
    };
}

sub _normalize_bus($raw) {
    return {
        grant      => _required_identifier_field($raw, 'grant', 'bus.grant'),
        ready      => _required_identifier_field($raw, 'ready', 'bus.ready'),
        response   => _normalize_width_binding($raw->{response}, 'bus.response', 2),
        read_data  => _normalize_width_binding($raw->{read_data}, 'bus.read_data', 32),
        request    => _required_identifier_field($raw, 'request', 'bus.request'),
        lock       => _required_identifier_field($raw, 'lock', 'bus.lock'),
        address    => _normalize_width_binding($raw->{address}, 'bus.address', 32),
        transfer   => _normalize_width_binding($raw->{transfer}, 'bus.transfer', 2),
        write      => _required_identifier_field($raw, 'write', 'bus.write'),
        size       => _normalize_width_binding($raw->{size}, 'bus.size', 3),
        burst      => _normalize_width_binding($raw->{burst}, 'bus.burst', 3),
        protection => _normalize_width_binding($raw->{protection}, 'bus.protection', 4),
        write_data => _normalize_width_binding($raw->{write_data}, 'bus.write_data', 32),
    };
}

sub _normalize_burst($raw) {
    return {
        single => _exact_scalar($raw, 'single', "3'b000", 'burst.single'),
        incr   => _exact_scalar($raw, 'incr',   "3'b001", 'burst.incr'),
        wrap4  => _exact_scalar($raw, 'wrap4',  "3'b010", 'burst.wrap4'),
        incr4  => _exact_scalar($raw, 'incr4',  "3'b011", 'burst.incr4'),
        wrap8  => _exact_scalar($raw, 'wrap8',  "3'b100", 'burst.wrap8'),
        incr8  => _exact_scalar($raw, 'incr8',  "3'b101", 'burst.incr8'),
        wrap16 => _exact_scalar($raw, 'wrap16', "3'b110", 'burst.wrap16'),
        incr16 => _exact_scalar($raw, 'incr16', "3'b111", 'burst.incr16'),
        length_zero_means_one => _exact_scalar($raw, 'length_zero_means_one', '1', 'burst.length_zero_means_one'),
        max_beats => _exact_scalar($raw, 'max_beats', '16', 'burst.max_beats'),
    };
}

sub _normalize_transfer($raw) {
    confess "AHB requester transfer.busy_before_beat requires transfer.busy 2'b01\n"
        if exists($raw->{busy_before_beat}) && !exists($raw->{busy});

    my %transfer = (
        idle       => _exact_scalar($raw, 'idle', "2'b00", 'transfer.idle'),
        nonseq     => _exact_scalar($raw, 'nonseq', "2'b10", 'transfer.nonseq'),
        seq        => _exact_scalar($raw, 'seq', "2'b11", 'transfer.seq'),
        first_beat => _exact_scalar($raw, 'first_beat', 'nonseq', 'transfer.first_beat'),
        later_beats => _exact_scalar($raw, 'later_beats', 'seq', 'transfer.later_beats'),
        advance_on => _exact_scalar($raw, 'advance_on', 'ready', 'transfer.advance_on'),
    );

    $transfer{busy} = _exact_scalar($raw, 'busy', "2'b01", 'transfer.busy')
        if exists($raw->{busy});

    if (exists($raw->{busy_before_beat})) {
        my $value = $raw->{busy_before_beat};
        confess "AHB requester transfer.busy_before_beat must be a literal integer in 1..15\n"
            if ref($value) || !defined($value) || $value !~ /\A(?:[1-9]|1[0-5])\z/;
        $transfer{busy_before_beat} = 0 + $value;
    }

    return \%transfer;
}

sub _normalize_response($raw) {
    return {
        okay   => _exact_scalar($raw, 'okay', "2'b00", 'response.okay'),
        error  => _exact_scalar($raw, 'error', "2'b01", 'response.error'),
        retry  => _exact_scalar($raw, 'retry', "2'b10", 'response.retry'),
        split  => _exact_scalar($raw, 'split', "2'b11", 'response.split'),
        error_action => _exact_scalar($raw, 'error_action', 'complete-error', 'response.error_action'),
        retry_action => _exact_scalar($raw, 'retry_action', 're-request', 'response.retry_action'),
        split_action => _exact_scalar($raw, 'split_action', 're-request', 'response.split_action'),
        read_sample  => _exact_scalar($raw, 'read_sample', 'last-read-data', 'response.read_sample'),
    };
}

sub _emit_isf($contract) {
    my $cmd = $contract->{local_command};
    my $status = $contract->{local_status};
    my $bus = $contract->{bus};
    my $burst = $contract->{burst};
    my $transfer = $contract->{transfer};
    my $response = $contract->{response};
    my $reset = _reset_clause($contract->{reset});
    my $internal_done = 'ahb_request_done_q';
    my $busy_before_beat = $transfer->{busy_before_beat};
    my @transfer_busy_drive = defined($busy_before_beat)
        ? (
            "  (drive transfer_busy",
            _status_drive_lines($status),
            "    ($bus->{request} 1)",
            "    ($bus->{lock} lock_q)",
            "    ($bus->{address}{name} addr_q)",
            "    ($bus->{transfer}{name} $transfer->{busy})",
            "    ($bus->{write} write_q)",
            "    ($bus->{size}{name} size_q)",
            "    ($bus->{burst}{name} burst_q)",
            "    ($bus->{protection}{name} prot_q)",
            "    ($bus->{write_data}{name} wdata_q))",
            "",
        )
        : ();
    my @busy_local = defined($busy_before_beat)
        ? "    (local busy_inserted_q (width 1))"
        : ();
    my @busy_init = defined($busy_before_beat)
        ? "    (set busy_inserted_q 0)"
        : ();
    my @busy_insertion = defined($busy_before_beat)
        ? (
            "        (when (& (== beat_index_q $busy_before_beat) (== busy_inserted_q 0))",
            "          (drive transfer_busy)",
            "          (set busy_inserted_q 1)",
            "          (continue-when (== busy_inserted_q 1)))",
        )
        : ();

    return join("\n",
        "(actor $contract->{actor_name}",
        "  (clock $contract->{clock})",
        "  $reset",
        "  (watchdog 65536)",
        "",
        "  (interface",
        _interface_line('input', $cmd->{valid}),
        _interface_line('input', $cmd->{write}),
        _interface_line('input', $cmd->{address}),
        _interface_line('input', $cmd->{write_data}),
        _interface_line('input', $cmd->{write_data_step}),
        _interface_line('input', $cmd->{size}),
        _interface_line('input', $cmd->{protection}),
        _interface_line('input', $cmd->{lock}),
        _interface_line('input', $cmd->{burst}),
        _interface_line('input', $cmd->{length}),
        _interface_line('input', $bus->{grant}),
        _interface_line('input', $bus->{ready}),
        _interface_line('input', $bus->{response}),
        _interface_line('input', $bus->{read_data}),
        _interface_line('output', $cmd->{ready}),
        _interface_line('output', $status->{busy}),
        _interface_line('output', $status->{beat_done}),
        _interface_line('output', $status->{done}),
        _interface_line('output', $status->{burst_active}),
        _interface_line('output', $status->{wrap_active}),
        _interface_line('output', $status->{beat_index}),
        _interface_line('output', $status->{beats_remaining}),
        _interface_line('output', $status->{active_address}),
        _interface_line('output', $status->{active_burst}),
        _interface_line('output', $status->{last_error}),
        _interface_line('output', $status->{last_retry}),
        _interface_line('output', $status->{last_split}),
        _interface_line('output', $status->{last_response}),
        _interface_line('output', $status->{last_read_data}),
        _interface_line('output', $bus->{request}),
        _interface_line('output', $bus->{lock}),
        _interface_line('output', $bus->{address}),
        _interface_line('output', $bus->{transfer}),
        _interface_line('output', $bus->{write}),
        _interface_line('output', $bus->{size}),
        _interface_line('output', $bus->{burst}),
        _interface_line('output', $bus->{protection}),
        _interface_line('output', $bus->{write_data}) . ")",
        "",
        "  (storage",
        "    (var $internal_done (width 1) (reset 0)))",
        "",
        "  (drive accept_command",
        "    ($cmd->{ready} 1)",
        "    ($status->{busy} 1)",
        "    ($status->{beat_done} 0)",
        "    ($status->{done} 0))",
        "",
        "  (drive request_bus",
        _status_drive_lines($status),
        "    ($bus->{request} 1)",
        "    ($bus->{lock} lock_q)",
        "    ($bus->{address}{name} addr_q)",
        "    ($bus->{transfer}{name} $transfer->{idle})",
        "    ($bus->{write} write_q)",
        "    ($bus->{size}{name} size_q)",
        "    ($bus->{burst}{name} burst_q)",
        "    ($bus->{protection}{name} prot_q)",
        "    ($bus->{write_data}{name} wdata_q))",
        "",
        "  (drive transfer_nonseq",
        _status_drive_lines($status),
        "    ($bus->{request} 1)",
        "    ($bus->{lock} lock_q)",
        "    ($bus->{address}{name} addr_q)",
        "    ($bus->{transfer}{name} $transfer->{nonseq})",
        "    ($bus->{write} write_q)",
        "    ($bus->{size}{name} size_q)",
        "    ($bus->{burst}{name} burst_q)",
        "    ($bus->{protection}{name} prot_q)",
        "    ($bus->{write_data}{name} wdata_q))",
        "",
        "  (drive transfer_seq",
        _status_drive_lines($status),
        "    ($bus->{request} 1)",
        "    ($bus->{lock} lock_q)",
        "    ($bus->{address}{name} addr_q)",
        "    ($bus->{transfer}{name} $transfer->{seq})",
        "    ($bus->{write} write_q)",
        "    ($bus->{size}{name} size_q)",
        "    ($bus->{burst}{name} burst_q)",
        "    ($bus->{protection}{name} prot_q)",
        "    ($bus->{write_data}{name} wdata_q))",
        "",
        @transfer_busy_drive,
        "  (drive okay_beat",
        _status_drive_lines($status, beat_done => 1, read_data => $bus->{read_data}{name}, response => $response->{okay}),
        "    ($bus->{request} 1)",
        "    ($bus->{transfer}{name} $transfer->{idle}))",
        "",
        "  (drive retry_seen",
        _status_drive_lines($status, retry => 1, response => $response->{retry}),
        "    ($bus->{request} 1)",
        "    ($bus->{transfer}{name} $transfer->{idle}))",
        "",
        "  (drive split_seen",
        _status_drive_lines($status, split => 1, response => $response->{split}),
        "    ($bus->{request} 1)",
        "    ($bus->{transfer}{name} $transfer->{idle}))",
        "",
        "  (drive error_done",
        _status_drive_lines($status, error => 1, response => $response->{error}),
        "    ($bus->{request} 0)",
        "    ($bus->{transfer}{name} $transfer->{idle}))",
        "",
        "  (drive finish",
        _status_drive_lines($status, busy => 0, done => 1),
        "    ($cmd->{ready} 1)",
        "    ($bus->{request} 0)",
        "    ($bus->{lock} 0)",
        "    ($bus->{transfer}{name} $transfer->{idle}))",
        "",
        "  (transaction ahb_request",
        "    (on $cmd->{valid}",
        "      (sample $cmd->{address}{name} as addr_q)",
        "      (sample $cmd->{write} as write_q)",
        "      (sample $cmd->{write_data}{name} as wdata_q)",
        "      (sample $cmd->{write_data_step}{name} as wdata_step_q)",
        "      (sample $cmd->{size}{name} as size_q)",
        "      (sample $cmd->{protection}{name} as prot_q)",
        "      (sample $cmd->{lock} as lock_q)",
        "      (sample $cmd->{burst}{name} as burst_q)",
        "      (sample $cmd->{length}{name} as len_q))",
        "    (local addr_step_q (width 32))",
        "    (local beat_index_q (width 5))",
        "    (local beats_remaining_q (width 5))",
        "    (local beats_total_q (width 5))",
        "    (local burst_active_q (width 1))",
        @busy_local,
        "    (local last_error_q (width 1))",
        "    (local last_read_data_q (width 32))",
        "    (local last_resp_q (width 2))",
        "    (local last_retry_q (width 1))",
        "    (local last_split_q (width 1))",
        "    (local wrap_base_q (width 32))",
        "    (local wrap_high_q (width 32))",
        "    (local wrap_mode_q (width 1))",
        "    (local wrap_span_q (width 32))",
        "    (set beat_index_q 0)",
        @busy_init,
        "    (set last_error_q 0)",
        "    (set last_retry_q 0)",
        "    (set last_split_q 0)",
        "    (set last_resp_q $response->{okay})",
        "    (set last_read_data_q 0)",
        "    (drive accept_command)",
        "    (switch burst_q",
        "      ($burst->{single} (set beats_total_q 1) (set beats_remaining_q 1) (set wrap_mode_q 0) (set burst_active_q 0))",
        "      ($burst->{incr} (when (== len_q 0) (set beats_total_q 1) (set beats_remaining_q 1)) (when (! (== len_q 0)) (set beats_total_q len_q) (set beats_remaining_q len_q)) (set wrap_mode_q 0) (set burst_active_q 1))",
        "      ($burst->{wrap4} (set beats_total_q 4) (set beats_remaining_q 4) (set wrap_mode_q 1) (set burst_active_q 1))",
        "      ($burst->{incr4} (set beats_total_q 4) (set beats_remaining_q 4) (set wrap_mode_q 0) (set burst_active_q 1))",
        "      ($burst->{wrap8} (set beats_total_q 8) (set beats_remaining_q 8) (set wrap_mode_q 1) (set burst_active_q 1))",
        "      ($burst->{incr8} (set beats_total_q 8) (set beats_remaining_q 8) (set wrap_mode_q 0) (set burst_active_q 1))",
        "      ($burst->{wrap16} (set beats_total_q 16) (set beats_remaining_q 16) (set wrap_mode_q 1) (set burst_active_q 1))",
        "      ($burst->{incr16} (set beats_total_q 16) (set beats_remaining_q 16) (set wrap_mode_q 0) (set burst_active_q 1)))",
        "    (switch size_q",
        "      (3'b000 (set addr_step_q 1))",
        "      (3'b001 (set addr_step_q 2))",
        "      (3'b010 (set addr_step_q 4))",
        "      (3'b011 (set addr_step_q 8))",
        "      (3'b100 (set addr_step_q 16))",
        "      (3'b101 (set addr_step_q 32))",
        "      (3'b110 (set addr_step_q 64))",
        "      (3'b111 (set addr_step_q 128)))",
        "    (set wrap_span_q (* beats_total_q addr_step_q))",
        "    (set wrap_base_q (- addr_q (% addr_q (* beats_total_q addr_step_q))))",
        "    (set wrap_high_q (+ (- addr_q (% addr_q (* beats_total_q addr_step_q))) (* beats_total_q addr_step_q)))",
        "    (while beats_remaining_q",
        "      (drive request_bus)",
        "      (when $bus->{grant}",
        @busy_insertion,
        "        (when (== beat_index_q 0)",
        "          (drive transfer_nonseq))",
        "        (when (! (== beat_index_q 0))",
        "          (drive transfer_seq))",
        "        (when $bus->{ready}",
        "          (when (== $bus->{response}{name} $response->{okay})",
        "            (drive okay_beat)",
        "            (set last_resp_q $response->{okay})",
        "            (when (! write_q) (set last_read_data_q $bus->{read_data}{name}))",
        "            (when (== beats_remaining_q 1)",
        "              (set beats_remaining_q 0)",
        "              (set burst_active_q 0))",
        "            (when (> beats_remaining_q 1)",
        "              (set beats_remaining_q (- beats_remaining_q 1))",
        "              (set beat_index_q (+ beat_index_q 1))",
        "              (when write_q (set wdata_q (+ wdata_q wdata_step_q)))",
        "              (when wrap_mode_q",
        "                (when (== (+ addr_q addr_step_q) wrap_high_q) (set addr_q wrap_base_q))",
        "                (when (! (== (+ addr_q addr_step_q) wrap_high_q)) (set addr_q (+ addr_q addr_step_q))))",
        "              (when (! wrap_mode_q) (set addr_q (+ addr_q addr_step_q)))))",
        "          (when (== $bus->{response}{name} $response->{error})",
        "            (set last_error_q 1)",
        "            (set last_resp_q $response->{error})",
        "            (set beats_remaining_q 0)",
        "            (set burst_active_q 0)",
        "            (drive error_done))",
        "          (when (== $bus->{response}{name} $response->{retry})",
        "            (set last_retry_q 1)",
        "            (set last_resp_q $response->{retry})",
        "            (drive retry_seen))",
        "          (when (== $bus->{response}{name} $response->{split})",
        "            (set last_split_q 1)",
        "            (set last_resp_q $response->{split})",
        "            (drive split_seen)))))",
        "    (drive finish)",
        "    (complete $internal_done)))",
        "",
    );
}

sub _status_drive_lines($status, %override) {
    my $busy = exists($override{busy}) ? $override{busy} : 1;
    my $beat_done = exists($override{beat_done}) ? $override{beat_done} : 0;
    my $done = exists($override{done}) ? $override{done} : 0;
    my $error = exists($override{error}) ? $override{error} : 'last_error_q';
    my $retry = exists($override{retry}) ? $override{retry} : 'last_retry_q';
    my $split = exists($override{split}) ? $override{split} : 'last_split_q';
    my $response = exists($override{response}) ? $override{response} : 'last_resp_q';
    my $read_data = exists($override{read_data}) ? $override{read_data} : 'last_read_data_q';

    return (
        "    ($status->{busy} $busy)",
        "    ($status->{beat_done} $beat_done)",
        "    ($status->{done} $done)",
        "    ($status->{burst_active} burst_active_q)",
        "    ($status->{wrap_active} wrap_mode_q)",
        "    ($status->{beat_index}{name} beat_index_q)",
        "    ($status->{beats_remaining}{name} beats_remaining_q)",
        "    ($status->{active_address}{name} addr_q)",
        "    ($status->{active_burst}{name} burst_q)",
        "    ($status->{last_error} $error)",
        "    ($status->{last_retry} $retry)",
        "    ($status->{last_split} $split)",
        "    ($status->{last_response}{name} $response)",
        "    ($status->{last_read_data}{name} $read_data)",
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

    my $report = {
        schema => 'fsmgen.ial2.protocol_intent.ahb_requester.v1',
        mode   => 'requester',
        layering => {
            source_layer          => 'IAL2',
            generated_ial1_format => 'isf',
            generated_ial0_format => 'fsm',
            direct_ial2_to_ial0   => JSON::PP::false,
        },
        source_object => \%source_object,
        target_protocol => {
            profile => $contract->{protocol},
            object  => 'ahb-requester',
            role    => $contract->{role},
        },
        requester => {
            name       => $contract->{name},
            actor_name => $contract->{actor_name},
        },
        bindings => {
            clock         => $contract->{clock},
            reset         => _clone_jsonish($contract->{reset}),
            local_command => _clone_jsonish($contract->{local_command}),
            local_status  => _clone_jsonish($contract->{local_status}),
            bus           => _clone_jsonish($contract->{bus}),
        },
        burst => _clone_jsonish($contract->{burst}),
        transfer => _clone_jsonish($contract->{transfer}),
        response => _clone_jsonish($contract->{response}),
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
                kind           => 'generated_requester_fsm',
                entry_artifact => "$contract->{actor_name}.fsm",
            },
        },
        enforced_static_rules => [
            'profile must be ahb and the object must be ahb-requester',
            'role must be requester',
            'address and data widths are 32 in this slice',
            'AHB size and burst widths are 3 in this slice',
            'AHB protection width is 4 in this slice',
            'AHB transfer and response widths are 2 in this slice',
            'local length, beat-index, and beats-remaining widths are 5 in this slice',
            (defined($contract->{transfer}{busy_before_beat})
                ? 'BUSY insertion requires HTRANS BUSY 2\'b01 and a literal before-beat index in 1..15'
                : ()),
            'direct IAL2-to-IAL0 lowering is forbidden',
        ],
        unsupported_residue => _unsupported_residue($contract),
    };

    if (defined($contract->{transfer}{busy_before_beat})) {
        $report->{busy_insertion} = {
            generated_behavior   => JSON::PP::true,
            htrans_busy_encoding => $contract->{transfer}{busy},
            before_beat          => $contract->{transfer}{busy_before_beat},
            beats                => 'single',
        };
    }

    return $report;
}

sub _unsupported_residue($contract) {
    my @residue = (
        {
            id => 'ahb_profile_alias_deferred',
            detail => '.ahb remains an unsupported IAL2 profile alias candidate; this slice supports only generic .ppif.',
        },
        {
            id => 'ahb_completer_subordinate_deferred',
            detail => 'AHB completer/subordinate generation remains outside the bounded requester slice.',
        },
        {
            id => 'ahb_interconnect_decode_deferred',
            detail => 'AHB interconnect/decode, arbitration fabrics, and bus matrices remain future task-tree work.',
        },
        {
            id => 'ahb_full_manager_deferred',
            detail => 'Full AHB manager behavior beyond the bounded requester remains future work.',
        },
        {
            id => 'ahb_verification_output_deferred',
            detail => 'Verification-output generation and backend-language variants remain deferred.',
        },
    );

    push @residue, {
        id => 'ahb_requester_busy_insert_support',
        detail => 'Bounded single held requester HTRANS BUSY insertion before one literal SEQ beat is shipped; multi-beat or policy-driven BUSY throttling, runtime-driven insertion points, and requester BUSY beyond one held beat remain future work.',
    } if defined($contract->{transfer}{busy_before_beat});

    return \@residue;
}

sub _required_scalar($raw, $field) {
    confess "AHB requester IAL2 contract is missing required scalar field '$field'\n"
        unless exists($raw->{$field});
    return _nonempty_scalar($raw->{$field}, $field);
}

sub _required_hash($raw, $field) {
    confess "AHB requester IAL2 contract field '$field' must be a hash reference\n"
        unless ref($raw->{$field}) eq 'HASH';
    return $raw->{$field};
}

sub _required_identifier($raw, $field) {
    return _identifier_value(_required_scalar($raw, $field), $field);
}

sub _required_identifier_field($raw, $field, $label) {
    confess "AHB requester IAL2 contract is missing required field '$label'\n"
        unless exists($raw->{$field});
    return _identifier_value($raw->{$field}, $label);
}

sub _normalize_width_binding($raw, $field, $expected_width) {
    confess "AHB requester IAL2 contract field '$field' must be a hash reference\n"
        unless ref($raw) eq 'HASH';
    my $name = _identifier_value($raw->{name}, "$field.name");
    my $width = _positive_integer($raw->{width}, "$field.width");
    confess "AHB requester IAL2 contract $field.width must be $expected_width in this slice\n"
        unless $width == $expected_width;
    return {
        name  => $name,
        width => $width,
    };
}

sub _exact_scalar($raw, $field, $expected, $label) {
    confess "AHB requester IAL2 contract is missing required field '$label'\n"
        unless exists($raw->{$field});
    my $value = _nonempty_scalar($raw->{$field}, $label);
    confess "AHB requester IAL2 contract $label must be $expected in this slice\n"
        unless $value eq $expected;
    return $value;
}

sub _normalize_reset($raw_reset) {
    confess "AHB requester IAL2 contract is missing required reset binding\n"
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
    confess "AHB requester IAL2 contract source.anchors must be an array reference\n"
        unless ref($anchors) eq 'ARRAY';

    my @normalized;
    for my $index (0 .. $#$anchors) {
        my $anchor = $anchors->[$index];
        if (ref($anchor) eq 'HASH') {
            for my $required (qw(document section page)) {
                confess "AHB requester IAL2 contract source.anchors[$index] is missing '$required'\n"
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
        confess "AHB requester IAL2 contract duplicates interface/internal signal '$name'\n"
            if $seen{$name}++;
    }
}

sub _nonempty_scalar($value, $field) {
    confess "AHB requester IAL2 contract field '$field' must be a non-empty scalar\n"
        if !defined($value) || ref($value) || $value eq '';
    return $value;
}

sub _identifier_value($value, $field) {
    confess "AHB requester IAL2 contract field '$field' must be an ISF identifier\n"
        unless defined($value) && !ref($value) && $value =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
    return $value;
}

sub _positive_integer($value, $field) {
    confess "AHB requester IAL2 contract field '$field' must be a positive integer\n"
        unless defined($value) && !ref($value) && $value =~ /\A[1-9][0-9]*\z/;
    return int($value);
}

sub _bool_value($value, $field) {
    confess "AHB requester IAL2 contract field '$field' must be boolean 0 or 1\n"
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
