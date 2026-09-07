package FSM::Support::ProcessSupervisor::Wire;

use strict;
use warnings;

use bytes ();
use File::Spec;
use JSON::PP ();
use Math::BigInt;
use FSM::Support::ProcessSupervisor ();

# Private, producer-free wire contract. No sockets, processes, environment
# mutation, or public exports. Connection order and live authority belong to
# the coordinator; decoding syntax never establishes ownership or permission.
my %LIMIT = (
    jobs => 8, depth => 8, children => 16, connections => 8, backlog => 8,
    descriptors => 128, context => 8_192, cwd => 4_096, endpoint => 256,
    request => 1_048_576, control => 8_192, argv => 4_096, environment => 4_096,
    scalar => 65_536, snapshot => 524_288, metadata => 256, chunk => 16_384,
    stream_queue => 65_536, control_queue => 16_384, diagnostic => 2_048,
    handshake_seconds => 2, delivery_seconds => 2, idle_seconds => 0.05,
);
my $ENDPOINT_ROOT = '.artifacts/tmp/process-coordinator/';
my $JSON = JSON::PP->new->ascii->canonical->allow_nonref;
my @MESSAGE = (
    undef,
    ['HELLO', 'client', [qw(run raw16 parent id token raw32)]],
    ['READY', 'coordinator', [qw(run raw16 parent id)]],
    ['SPAWN', 'client', [qw(started_ns u64 schema metadata stage metadata
        containment metadata cwd cwd timeout_seconds positive
        capture_limit_bytes positive umask mask argv argv environment environment)]],
    ['ACCEPT', 'coordinator', [qw(job id)]],
    ['STDOUT', 'coordinator', [qw(job id offset u64 chunk chunk)]],
    ['STDERR', 'coordinator', [qw(job id offset u64 chunk chunk)]],
    ['CANCEL', 'client', [qw(job id)]],
    ['RESULT', 'coordinator', [qw(job id metadata terminal)]],
    ['ACK', 'client', [qw(job id)]],
    ['REJECT', 'coordinator', [qw(class rejection diagnostic diagnostic)]],
    ['STDOUT_END', 'coordinator', [qw(job id offset u64)]],
    ['STDERR_END', 'coordinator', [qw(job id offset u64)]],
);
my %TYPE = map { $MESSAGE[$_][0] => $_ } 1 .. $#MESSAGE;

sub limits { return {%LIMIT} }

sub _fail { die "private process wire: $_[0]\n" }

sub _keys {
    my ($value, @fields) = @_;
    _fail('expected closed record') unless ref($value) eq 'HASH';
    _fail('record fields do not match the grammar')
        unless keys(%$value) == @fields && !grep { !exists $value->{$_} } @fields;
}

sub _bytes {
    my ($value, $cap, $allow_nul) = @_;
    _fail('expected bounded scalar') unless defined($value) && !ref($value);
    # Check the current encoded storage before making a private string copy.
    _fail('scalar exceeds its byte bound') if bytes::length($value) > $cap;
    my $copy = "$value";
    utf8::encode($copy) if utf8::is_utf8($copy);
    _fail('scalar exceeds its byte bound') if length($copy) > $cap;
    _fail('NUL in execution scalar') if !$allow_nul && index($copy, "\0") >= 0;
    return $copy;
}

sub _wire_bytes {
    my ($value, $cap) = @_;
    _fail('wire input must be unflagged octets')
        unless defined($value) && !ref($value) && !utf8::is_utf8($value);
    _fail('wire input exceeds its byte bound') if length($value) > $cap;
}

sub _uint {
    my ($value, $maximum, $positive) = @_;
    _fail('noncanonical unsigned integer')
        unless defined($value) && !ref($value) && length($value) <= length($maximum)
            && $value =~ /\A(?:0|[1-9][0-9]*)\z/;
    _fail('unsigned integer out of range')
        if length($value) == length($maximum) && $value gt $maximum;
    _fail('unsigned integer must be positive') if $positive && $value eq '0';
    return "$value";
}

sub _metadata {
    my ($value) = @_;
    my $copy = _bytes($value, $LIMIT{metadata}, 0);
    _fail('metadata must be nonempty ASCII')
        unless length($copy) && $copy !~ /[^\x01-\x7f]/;
    return $copy;
}

sub _relative_path {
    my ($value, $cap, $root_allowed) = @_;
    my $copy = _bytes($value, $cap, 0);
    return $copy if $root_allowed && $copy eq '.';
    _fail('noncanonical relative directory')
        unless length($copy) && $copy !~ m{\A/|/\z|//}
            && !grep { $_ eq '.' || $_ eq '..' } split m{/}, $copy;
    return $copy;
}

sub _endpoint {
    my ($value) = @_;
    my $copy = _relative_path($value, $LIMIT{endpoint}, 0);
    _fail('context directory is outside the private endpoint root')
        unless index($copy, $ENDPOINT_ROOT) == 0
            && substr($copy, length($ENDPOINT_ROOT)) !~ m{/}
            && length($copy) > length($ENDPOINT_ROOT);
    return $copy;
}

sub encode_context {
    my ($context) = @_;
    _keys($context, qw(directory run parent token));
    my $directory = _endpoint($context->{directory});
    my $run = _raw_identity($context->{run}, 16);
    my $token = _raw_identity($context->{token}, 32);
    my $parent = _uint($context->{parent}, '4294967295', 1);
    return join(':', 1, unpack('H*', $directory), unpack('H*', $run),
        $parent, unpack('H*', $token));
}

sub decode_context {
    my ($encoded) = @_;
    _wire_bytes($encoded, $LIMIT{context});
    _fail('malformed coordinator context') unless $encoded =~
        /\A1:((?:[0-9a-f]{2})+):([0-9a-f]{32}):([1-9][0-9]{0,9}):([0-9a-f]{64})\z/;
    my ($directory, $run, $parent, $token) = ($1, $2, $3, $4);
    _fail('context directory exceeds its byte bound')
        if length($directory) > 2 * $LIMIT{endpoint};
    return {
        directory => _endpoint(pack('H*', $directory)), run => pack('H*', $run),
        parent => 0 + _uint($parent, '4294967295', 1), token => pack('H*', $token),
    };
}

sub _raw_identity {
    my ($value, $size) = @_;
    _wire_bytes($value, $size);
    _fail('identity has incorrect length') unless length($value) == $size;
    return $value;
}

sub snapshot_request {
    my ($request, $started_ns) = @_;
    _keys($request, qw(argv bounds containment cwd schema stage));
    _keys($request->{bounds}, qw(timeout_seconds capture_limit_bytes));
    my ($cwd, $error) = FSM::Support::ProcessSupervisor::repository_contained_path(
        _bytes($request->{cwd}, $LIMIT{cwd}, 0), must_exist => 1,
    );
    _fail('execution cwd is not an admitted repository directory')
        if defined($error) || !-d $cwd;
    # Read the live ENV magic, not a cached hash or an arbitrary pre-setenv
    # scalar. Perl's setenv byte conversion differs from argv conversion.
    _fail('too many environment pairs') if scalar(keys %ENV) > $LIMIT{environment};
    my $budget = $LIMIT{snapshot};
    _encode_value('argv', $request->{argv}, \$budget);
    my @environment;
    for my $key (keys %ENV) {
        my @pair = (_bytes($key, $LIMIT{scalar}, 0),
            _bytes($ENV{$key}, $LIMIT{scalar}, 0));
        _charge(\$budget, length($pair[0]) + length($pair[1]));
        push @environment, \@pair;
    }
    @environment = sort { $a->[0] cmp $b->[0] } @environment;
    my $snapshot = {
        type => 'SPAWN', started_ns => $started_ns,
        map({ $_ => $request->{$_} } qw(schema stage containment argv)),
        cwd => File::Spec->abs2rel($cwd, FSM::Support::ProcessSupervisor::repository_root()),
        %{$request->{bounds}}, umask => umask(), environment => \@environment,
    };
    # Return a detached, admitted byte snapshot. The same grammar is used on
    # the eventual receiving side; neither caller state nor wire data is kept.
    return decode_frame('client', encode_frame('client', $snapshot));
}

# Read four bytes first and admit the declared payload before body storage.
# After the next two bytes, frame_size applies the type/direction-specific cap.
sub payload_size {
    my ($header) = @_;
    _wire_bytes($header, 4);
    _fail('incomplete frame header') unless length($header) == 4;
    my $size = unpack('N', $header);
    _fail('payload length outside the frame bound')
        unless $size >= 2 && $size <= $LIMIT{request};
    return $size;
}

sub _message {
    my ($direction, $id) = @_;
    _fail('unknown direction')
        unless defined($direction) && !ref($direction)
            && ($direction eq 'client' || $direction eq 'coordinator');
    _fail('unknown message type') unless defined($id) && $id >= 1 && $id <= $#MESSAGE;
    _fail('message has wrong direction') unless $MESSAGE[$id][1] eq $direction;
    return $MESSAGE[$id];
}

sub _frame_cap {
    my ($id) = @_;
    return $LIMIT{request} if $id == 3;
    return $LIMIT{chunk} + 18 if $id == 5 || $id == 6;
    return $LIMIT{control};
}

sub frame_size {
    my ($direction, $prefix) = @_;
    _wire_bytes($prefix, 6);
    _fail('incomplete frame prefix') unless length($prefix) == 6;
    my $size = payload_size(substr($prefix, 0, 4));
    my ($version, $id) = unpack('CC', substr($prefix, 4, 2));
    _fail('unknown wire version') unless $version == 1;
    _message($direction, $id);
    _fail('payload exceeds message bound') if $size > _frame_cap($id);
    return $size + 4;
}

sub encode_frame {
    my ($direction, $message) = @_;
    _fail('expected message record') unless ref($message) eq 'HASH';
    my $type = $message->{type};
    _fail('unknown message name') unless defined($type) && !ref($type) && exists $TYPE{$type};
    my $id = $TYPE{$type};
    my $definition = _message($direction, $id);
    my @fields = @{$definition->[2]};
    _keys($message, 'type', map { $fields[$_ * 2] } 0 .. @fields / 2 - 1);
    my $body = pack('CC', 1, $id);
    my $budget = $LIMIT{snapshot};
    while (@fields) {
        my ($key, $kind) = splice @fields, 0, 2;
        my $encoded = _encode_value($kind, $message->{$key}, \$budget);
        _fail('encoded frame exceeds message bound')
            if length($body) + length($encoded) > _frame_cap($id);
        $body .= $encoded;
    }
    return pack('N', length($body)) . $body;
}

sub decode_frame {
    my ($direction, $frame) = @_;
    _wire_bytes($frame, $LIMIT{request} + 4);
    _fail('incomplete frame prefix') if length($frame) < 6;
    my $size = frame_size($direction, substr($frame, 0, 6));
    _fail('truncated frame or trailing data') unless length($frame) == $size;
    my $id = ord(substr($frame, 5, 1));
    my @fields = @{$MESSAGE[$id][2]};
    my $result = {type => $MESSAGE[$id][0]};
    my $reader = {data => \$frame, offset => 6, budget => $LIMIT{snapshot}};
    while (@fields) {
        my ($key, $kind) = splice @fields, 0, 2;
        $result->{$key} = _decode_value($kind, $reader);
    }
    _fail('trailing message fields') unless $reader->{offset} == length($frame);
    return $result;
}

sub _take {
    my ($reader, $size) = @_;
    _fail('truncated message field') if $size > length(${$reader->{data}}) - $reader->{offset};
    my $value = substr(${$reader->{data}}, $reader->{offset}, $size);
    $reader->{offset} += $size;
    return $value;
}

sub _u64_pack {
    my ($value) = @_;
    my $integer = Math::BigInt->new(_uint($value, '18446744073709551615', 0));
    my ($high, $low) = $integer->copy->bdiv(4_294_967_296);
    return pack('NN', $high->numify, $low->numify);
}

sub _u64_unpack {
    my ($bytes) = @_;
    my ($high, $low) = unpack('NN', $bytes);
    return Math::BigInt->new($high)->bmul(4_294_967_296)->badd($low)->bstr;
}

sub _charge {
    my ($budget, $size) = @_;
    _fail('execution snapshot exceeds aggregate byte bound') if $size > $$budget;
    $$budget -= $size;
}

sub _string {
    my ($kind, $value) = @_;
    return _metadata($value) if $kind eq 'metadata';
    return _relative_path($value, $LIMIT{cwd}, 1) if $kind eq 'cwd';
    if ($kind eq 'terminal') {
        _validate_terminal($value);
        return $JSON->encode($value);
    }
    if ($kind eq 'chunk') {
        _wire_bytes($value, $LIMIT{chunk});
        return $value;
    }
    return _bytes($value, $LIMIT{$kind}, $kind eq 'chunk');
}

sub _encode_value {
    my ($kind, $value, $budget) = @_;
    return _raw_identity($value, $kind eq 'raw16' ? 16 : 32) if $kind =~ /^raw/;
    return _u64_pack($value) if $kind eq 'u64';
    if ($kind eq 'id' || $kind eq 'positive' || $kind eq 'mask' || $kind eq 'rejection') {
        my $cap = $kind eq 'mask' ? '511' : $kind eq 'rejection' ? '2' : '4294967295';
        my $number = _uint($value, $cap, $kind ne 'mask');
        return pack($kind eq 'rejection' ? 'C' : 'N', $number);
    }
    if ($kind eq 'argv' || $kind eq 'environment') {
        _fail('invalid execution vector') unless ref($value) eq 'ARRAY'
            && @$value <= $LIMIT{$kind} && ($kind ne 'argv' || @$value);
        my $encoded = pack('N', scalar @$value);
        my $previous;
        for my $entry (@$value) {
            if ($kind eq 'argv') {
                my $copy = _bytes($entry, $LIMIT{scalar}, 0);
                _charge($budget, length($copy));
                $encoded .= pack('N', length($copy)) . $copy;
            }
            else {
                _fail('invalid environment pair') unless ref($entry) eq 'ARRAY' && @$entry == 2;
                my ($key, $val) = map { _bytes($_, $LIMIT{scalar}, 0) } @$entry;
                _environment_key($key, $previous);
                $previous = $key;
                _charge($budget, length($key) + length($val));
                $encoded .= pack('N', length($key)) . $key . pack('N', length($val)) . $val;
            }
        }
        return $encoded;
    }
    my $copy = _string($kind, $value);
    _fail('terminal metadata exceeds control bound')
        if $kind eq 'terminal' && length($copy) > $LIMIT{control};
    return pack('N', length($copy)) . $copy;
}

sub _environment_key {
    my ($key, $previous) = @_;
    _fail('invalid environment key') unless length($key) && index($key, '=') < 0;
    _fail('environment keys must be unique and byte ordered')
        if defined($previous) && $key le $previous;
}

sub _read_string {
    my ($reader, $cap, $snapshot) = @_;
    my $size = unpack('N', _take($reader, 4));
    _fail('declared scalar exceeds byte bound') if $size > $cap;
    _charge(\$reader->{budget}, $size) if $snapshot;
    return _take($reader, $size);
}

sub _decode_value {
    my ($kind, $reader) = @_;
    return _take($reader, $kind eq 'raw16' ? 16 : 32) if $kind =~ /^raw/;
    return _u64_unpack(_take($reader, 8)) if $kind eq 'u64';
    if ($kind eq 'id' || $kind eq 'positive' || $kind eq 'mask' || $kind eq 'rejection') {
        my $value = $kind eq 'rejection' ? ord(_take($reader, 1)) : unpack('N', _take($reader, 4));
        _encode_value($kind, $value, \$reader->{budget});
        return $value;
    }
    if ($kind eq 'argv' || $kind eq 'environment') {
        my $count = unpack('N', _take($reader, 4));
        _fail('declared vector exceeds item bound') if $count > $LIMIT{$kind};
        _fail('empty argument vector') if $kind eq 'argv' && !$count;
        my (@value, $previous);
        for (1 .. $count) {
            my $first = _read_string($reader, $LIMIT{scalar}, 1);
            _bytes($first, $LIMIT{scalar}, 0);
            if ($kind eq 'argv') { push @value, $first; next; }
            _environment_key($first, $previous);
            $previous = $first;
            my $second = _read_string($reader, $LIMIT{scalar}, 1);
            _bytes($second, $LIMIT{scalar}, 0);
            push @value, [$first, $second];
        }
        return \@value;
    }
    my $cap = $kind eq 'terminal' ? $LIMIT{control} : $LIMIT{$kind};
    my $value = _read_string($reader, $cap, 0);
    if ($kind eq 'terminal') {
        _fail('terminal metadata must be ASCII JSON') if $value =~ /[^\x00-\x7f]/;
        my $decoded = eval { $JSON->decode($value) };
        _fail('terminal metadata is not canonical JSON')
            if $@ || $JSON->encode($decoded) ne $value;
        _validate_terminal($decoded);
        return $decoded;
    }
    return _string($kind, $value);
}

sub _json_uint {
    my ($value, $max, $positive) = @_;
    _fail('terminal number must have JSON integer type')
        if !defined($value) || ref($value) || $JSON->encode($value) !~ /\A(?:0|[1-9][0-9]*)\z/;
    return _uint($value, $max, $positive);
}

sub _validate_terminal {
    my ($metadata) = @_;
    _keys($metadata, qw(result reservation_reaped subtree_closed delivery_complete));
    _json_uint($metadata->{$_}, '1', 0) for qw(reservation_reaped subtree_closed delivery_complete);
    _fail('delivery cannot be complete before ACK') if $metadata->{delivery_complete};
    my $r = $metadata->{result};
    my @times = qw(started_monotonic_ns exec_handoff_monotonic_ns
        first_output_monotonic_ns finished_monotonic_ns spawn_to_exec_ns
        execution_ns exec_to_first_output_ns first_output_to_exit_ns);
    _keys($r, qw(schema schema_version stage ok status diagnostic stdout_bytes stderr_bytes
        exit_code signal timed_out output_limited exec_failed exec_error timeout_seconds
        capture_limit_bytes cleanup), @times);
    _metadata($r->{$_}) for qw(schema stage);
    _json_uint($r->{schema_version}, '1', 1);
    _json_uint($r->{$_}, '1', 0) for qw(ok timed_out output_limited exec_failed);
    _json_uint($r->{$_}, '4294967295', 1) for qw(timeout_seconds capture_limit_bytes);
    _json_uint($r->{$_}, '4294967295', 0) for qw(stdout_bytes stderr_bytes);
    _fail('result capture exceeds policy')
        if $r->{stdout_bytes} + $r->{stderr_bytes} > $r->{capture_limit_bytes};
    _json_uint($r->{exit_code}, '255', 0) if defined $r->{exit_code};
    _json_uint($r->{signal}, '127', 0) if defined $r->{signal};
    _fail('result confuses signal and exit code')
        if $r->{signal} && defined $r->{exit_code};
    _bytes($r->{diagnostic}, $LIMIT{control}, 0);
    _bytes($r->{exec_error}, $LIMIT{diagnostic}, 0) if defined $r->{exec_error};
    for my $field (@times) {
        _json_uint($r->{$field}, '18446744073709551615', 0) if defined $r->{$field};
    }
    for my $pair (
        [qw(started_monotonic_ns exec_handoff_monotonic_ns spawn_to_exec_ns)],
        [qw(exec_handoff_monotonic_ns finished_monotonic_ns execution_ns)],
        [qw(exec_handoff_monotonic_ns first_output_monotonic_ns exec_to_first_output_ns)],
        [qw(first_output_monotonic_ns finished_monotonic_ns first_output_to_exit_ns)],
    ) {
        my ($begin, $end, $elapsed) = map { $r->{$_} } @$pair;
        if (defined($begin) && defined($end)) {
            my $difference = Math::BigInt->new($end)->bsub($begin);
            _fail('inconsistent terminal chronology') if $difference->is_neg
                || !defined($elapsed) || $difference->bcmp($elapsed) != 0;
        }
        else { _fail('elapsed time without endpoints') if defined $elapsed; }
    }
    _fail('finish precedes invocation start')
        if defined($r->{started_monotonic_ns}) && defined($r->{finished_monotonic_ns})
            && Math::BigInt->new($r->{finished_monotonic_ns})->bcmp($r->{started_monotonic_ns}) < 0;
    my $cleanup = $r->{cleanup};
    _keys($cleanup, qw(containment leader_started term_sent kill_sent leader_reaped
        group_gone surviving_descendants));
    _metadata($cleanup->{containment});
    _json_uint($cleanup->{$_}, '1', 0) for qw(leader_started term_sent kill_sent
        leader_reaped group_gone surviving_descendants);
    my %status = map { $_ => 1 } qw(success invocation_error host_error timed_out
        output_limited exec_error surviving_descendants cleanup_failed signaled nonzero_exit);
    _fail('unknown terminal status')
        unless defined($r->{status}) && !ref($r->{status}) && $status{$r->{status}};
    _fail('result success disagrees with status') if $r->{ok} != ($r->{status} eq 'success' ? 1 : 0);
    if ($r->{ok}) {
        _fail('success without complete command and subtree cleanup')
            unless $metadata->{reservation_reaped} && $metadata->{subtree_closed}
                && $cleanup->{leader_started} && $cleanup->{leader_reaped} && $cleanup->{group_gone}
                && !$cleanup->{surviving_descendants} && defined($r->{exit_code}) && $r->{exit_code} == 0
                && defined($r->{signal}) && $r->{signal} == 0
                && !$r->{timed_out} && !$r->{output_limited} && !$r->{exec_failed}
                && !defined($r->{exec_error}) && defined($r->{started_monotonic_ns})
                && defined($r->{exec_handoff_monotonic_ns}) && defined($r->{finished_monotonic_ns});
    }
    return;
}

1;
