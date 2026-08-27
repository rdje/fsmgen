package FSM::VIAL::Backend::VHDLPortableTraceValidator;

use v5.20;
use strict;
use warnings;
use bytes ();
use Digest::SHA qw(sha256_hex);
use JSON::PP ();
use Scalar::Util qw(blessed looks_like_number);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

my $JSON = JSON::PP->new->canonical(1);
my $PREFIX = "FSMGEN_VIAL_TRACE_V2\t";
my $TRACE_SCHEMA = 'fsmgen.vial_vhdl_runtime_trace.v2';
my $CATALOG_SCHEMA = 'fsmgen.vial_vhdl_observation_catalog.v1';
my $MAX_BYTES = 67_108_864;
my $MAX_RECORDS = 8_000_002;
my @KIND = qw(
    header scenario_start events samples expectations scoreboards coverage faults
    scenario_end footer
);
my %KIND = map { $_ => 1 } @KIND;
my @RESULT_KEYS = qw(ok status trace diagnostics);
my $CHECKED_PLAN_ID =
    'plan/e236297c8b434a9b374d1800112841e00327bdbd5d8d9130440bd20681fbed6e';
my @CHECKED_RUN_ID = map { "run/$CHECKED_PLAN_ID/$_" } qw(
    ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success
    ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::unsupported_size
);
my $CHECKED_CATALOG_PROJECTION = {
    entries => [
        {
            sample_id => 'sample/endpoint/HRDATA',
            semantic_id => 'endpoint/HRDATA',
            width => 32,
        },
        {
            sample_id => 'sample/endpoint/HREADYOUT',
            semantic_id => 'endpoint/HREADYOUT',
            width => 1,
        },
        {
            sample_id => 'sample/endpoint/HRESP',
            semantic_id => 'endpoint/HRESP',
            width => 1,
        },
        {
            sample_id => 'sample/probe/reg_data_q',
            semantic_id => 'probe/reg_data_q',
            width => 32,
        },
    ],
    schema => $CATALOG_SCHEMA,
    total_width => 66,
};
my $CHECKED_OBSERVATION_CATALOG = {
    catalog_digest =>
        'sha256/' . sha256_hex($JSON->encode($CHECKED_CATALOG_PROJECTION)),
    %$CHECKED_CATALOG_PROJECTION,
};

sub result_keys($class) {
    die __PACKAGE__ . "->result_keys requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return [@RESULT_KEYS];
}

sub checked_reference_authority($class) {
    die __PACKAGE__
        . "->checked_reference_authority requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return $JSON->decode($JSON->encode({
        expected_plan_id => $CHECKED_PLAN_ID,
        expected_run_ids => \@CHECKED_RUN_ID,
        expected_observation_catalog => $CHECKED_OBSERVATION_CATALOG,
    }));
}

sub validate($class, @args) {
    return _failure('VIAL_VHDL_TRACE_INVOCATION_ERROR',
        'validate requires the exact validator class invocant', '/')
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return _failure('VIAL_VHDL_TRACE_INVOCATION_ERROR',
        'validate expects one closed argument hash', '/')
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    my $result = eval { _validate($args[0]) };
    return $result if defined $result;
    my $error = $@;
    return _failure($error->{code}, $error->{message}, $error->{path})
        if blessed($error)
            && $error->isa('FSM::VIAL::Backend::VHDLPortableTraceValidator::Failure');
    return _failure('VIAL_VHDL_TRACE_HOST_ERROR', _sanitize_exception($error), '/');
}

sub _validate($raw) {
    _require_exact_keys($raw, [qw(
        trace_text expected_record_counts expected_plan_id expected_run_ids
        expected_observation_catalog
    )],
        'trace validation');
    _throw('VIAL_VHDL_TRACE_INVOCATION_ERROR',
        'trace_text must be one scalar LF-terminated trace', '/trace_text')
        unless defined($raw->{trace_text}) && !ref($raw->{trace_text})
            && $raw->{trace_text} =~ /\n\z/ && $raw->{trace_text} !~ /\r/;
    _throw('VIAL_VHDL_TRACE_LIMIT_ERROR',
        'trace exceeds the exact 64 MiB capture limit', '/trace_text')
        if bytes::length($raw->{trace_text}) > $MAX_BYTES;
    _require_exact_keys($raw->{expected_record_counts}, \@KIND,
        'expected record counts');
    for my $kind (@KIND) {
        _throw('VIAL_VHDL_TRACE_INVOCATION_ERROR',
            "expected count for '$kind' must be a nonnegative integer",
            "/expected_record_counts/$kind")
            unless _nonnegative_integer($raw->{expected_record_counts}{$kind});
    }
    _throw('VIAL_VHDL_TRACE_INVOCATION_ERROR',
        'expected_plan_id must be one bounded safe identity', '/expected_plan_id')
        unless defined($raw->{expected_plan_id}) && !ref($raw->{expected_plan_id})
            && length($raw->{expected_plan_id}) <= 4_096
            && $raw->{expected_plan_id} =~ /\A[A-Za-z0-9_.:\/-]+\z/;
    _throw('VIAL_VHDL_TRACE_INVOCATION_ERROR',
        'expected_run_ids must be one nonempty array', '/expected_run_ids')
        unless ref($raw->{expected_run_ids}) eq 'ARRAY'
            && @{$raw->{expected_run_ids}};
    my %expected_run_id;
    for my $index (0 .. $#{$raw->{expected_run_ids}}) {
        my $run_id = $raw->{expected_run_ids}[$index];
        _throw('VIAL_VHDL_TRACE_INVOCATION_ERROR',
            'expected run identity must be unique, bounded, and safe',
            "/expected_run_ids/$index")
            unless defined($run_id) && !ref($run_id)
                && length($run_id) <= 4_096
                && $run_id =~ /\A[A-Za-z0-9_.:\/-]+\z/
                && !$expected_run_id{$run_id}++;
    }
    my ($expected_catalog_digest, $expected_catalog_width,
        @expected_catalog_ids) = _validate_catalog(
            $raw->{expected_observation_catalog},
            '/expected_observation_catalog');

    my @line = split /\n/, $raw->{trace_text}, -1;
    pop @line;
    _throw('VIAL_VHDL_TRACE_LIMIT_ERROR',
        'trace record count is outside the supported closed interval', '/trace')
        unless @line >= 2 && @line <= $MAX_RECORDS;
    my (@record, %count);
    for my $index (0 .. $#line) {
        my $path = "/trace/$index";
        _throw('VIAL_VHDL_TRACE_PREFIX_ERROR',
            'trace line has a missing or foreign version prefix', $path)
            unless index($line[$index], $PREFIX) == 0;
        my $encoded = substr($line[$index], length($PREFIX));
        my $record = eval { $JSON->decode($encoded) };
        _throw('VIAL_VHDL_TRACE_JSON_ERROR',
            'trace line is not valid JSON', $path) unless ref($record) eq 'HASH';
        _throw('VIAL_VHDL_TRACE_CANONICAL_ERROR',
            'trace line is not canonical JSON', $path)
            unless $JSON->encode($record) eq $encoded;
        _require_exact_keys($record,
            [qw(payload plan_id record_kind run_id schema schema_version sequence)],
            "trace record $index", $path);
        _throw('VIAL_VHDL_TRACE_SCHEMA_ERROR',
            'trace record has a foreign schema or version', "$path/schema")
            unless ($record->{schema} // '') eq $TRACE_SCHEMA
                && _integer_equal($record->{schema_version}, 2);
        _throw('VIAL_VHDL_TRACE_KIND_ERROR',
            'trace record kind is outside the closed vocabulary', "$path/record_kind")
            unless defined($record->{record_kind}) && !ref($record->{record_kind})
                && $KIND{$record->{record_kind}};
        _throw('VIAL_VHDL_TRACE_SEQUENCE_ERROR',
            'trace sequence must be contiguous and zero based', "$path/sequence")
            unless _integer_equal($record->{sequence}, $index);
        _throw('VIAL_VHDL_TRACE_ID_ERROR',
            'plan_id must be one bounded safe identity', "$path/plan_id")
            unless defined($record->{plan_id}) && !ref($record->{plan_id})
                && length($record->{plan_id}) <= 4_096
                && $record->{plan_id} =~ /\A[A-Za-z0-9_.:\/-]+\z/;
        $count{$record->{record_kind}}++;
        push @record, $record;
    }

    for my $kind (@KIND) {
        my $actual = $count{$kind} // 0;
        _throw('VIAL_VHDL_TRACE_COUNT_ERROR',
            "trace record count for '$kind' is $actual; caller authority requires "
                . $raw->{expected_record_counts}{$kind},
            "/record_counts/$kind")
            unless $actual == $raw->{expected_record_counts}{$kind};
    }
    _throw('VIAL_VHDL_TRACE_CLOSURE_ERROR',
        'trace must have exactly one outer header and footer', '/trace')
        unless $record[0]{record_kind} eq 'header'
            && $record[-1]{record_kind} eq 'footer'
            && ($count{header} // 0) == 1 && ($count{footer} // 0) == 1;
    my $plan_id = $record[0]{plan_id};
    _throw('VIAL_VHDL_TRACE_ID_ERROR',
        'trace plan_id differs from caller authority', '/trace/0/plan_id')
        unless $plan_id eq $raw->{expected_plan_id};
    for my $index (0 .. $#record) {
        _throw('VIAL_VHDL_TRACE_ID_ERROR',
            'plan_id changed inside one trace', "/trace/$index/plan_id")
            unless $record[$index]{plan_id} eq $plan_id;
    }

    my ($catalog, $catalog_digest, $catalog_width, @catalog_ids);
    my (%run_state, @observed_run_id);
    for my $index (0 .. $#record) {
        my $record = $record[$index];
        my $kind = $record->{record_kind};
        my $path = "/trace/$index";
        my $outer = $kind eq 'header' || $kind eq 'footer';
        _throw('VIAL_VHDL_TRACE_RUN_ERROR',
            'only the outer header and footer may have null run_id', "$path/run_id")
            unless $outer ? !defined($record->{run_id})
                : defined($record->{run_id}) && !ref($record->{run_id})
                    && length($record->{run_id}) <= 4_096
                    && $record->{run_id} =~ /\A[A-Za-z0-9_.:\/-]+\z/;
        _throw('VIAL_VHDL_TRACE_PAYLOAD_ERROR',
            'payload must be one unblessed record', "$path/payload")
            unless ref($record->{payload}) eq 'HASH' && !blessed($record->{payload});
        if ($kind eq 'header') {
            _require_exact_keys($record->{payload},
                [qw(logical_time observation_catalog)], 'header payload', "$path/payload");
            $catalog = $record->{payload}{observation_catalog};
            ($catalog_digest, $catalog_width, @catalog_ids) =
                _validate_catalog($catalog, "$path/payload/observation_catalog");
            _throw('VIAL_VHDL_TRACE_CATALOG_ERROR',
                'trace observation catalog differs from caller authority',
                "$path/payload/observation_catalog")
                unless $catalog_digest eq $expected_catalog_digest
                    && $catalog_width == $expected_catalog_width
                    && $JSON->encode($catalog)
                        eq $JSON->encode($raw->{expected_observation_catalog})
                    && $JSON->encode(\@catalog_ids)
                        eq $JSON->encode(\@expected_catalog_ids);
        } elsif ($kind eq 'samples') {
            _require_exact_keys($record->{payload},
                [qw(logical_time normalized_bits)], 'sample payload', "$path/payload");
            my $bits = $record->{payload}{normalized_bits};
            _throw('VIAL_VHDL_TRACE_SAMPLE_ERROR',
                'sample bits must use the exact normalized 0/1/X/Z alphabet',
                "$path/payload/normalized_bits")
                unless defined($bits) && !ref($bits) && $bits =~ /\A[01XZ]+\z/;
            _throw('VIAL_VHDL_TRACE_SAMPLE_WIDTH_ERROR',
                'sample bit width differs from the authenticated catalog width',
                "$path/payload/normalized_bits")
                unless length($bits) == $catalog_width;
        } else {
            _require_exact_keys($record->{payload}, [qw(logical_time)],
                "$kind payload", "$path/payload");
        }
        my $time = _validate_time($record->{payload}{logical_time},
            "$path/payload/logical_time");
        _throw('VIAL_VHDL_TRACE_SAMPLE_PHASE_ERROR',
            'sample snapshots must occur in the inactive-edge SAMPLE phase',
            "$path/payload/logical_time/phase_rank")
            if $kind eq 'samples' && $time->[1] != 1;
        next if $outer;
        my $run = $record->{run_id};
        my $state = $run_state{$run} //= {open => 0, closed => 0, last_time => undef};
        _throw('VIAL_VHDL_TRACE_RUN_ERROR',
            'records may not follow a closed scenario run', "$path/run_id")
            if $state->{closed};
        if ($kind eq 'scenario_start') {
            _throw('VIAL_VHDL_TRACE_RUN_ERROR',
                'scenario run has a duplicate start', "$path/run_id") if $state->{open};
            $state->{open} = 1;
            push @observed_run_id, $run;
        } else {
            _throw('VIAL_VHDL_TRACE_RUN_ERROR',
                'scenario record precedes its start', "$path/run_id") unless $state->{open};
        }
        if (defined $state->{last_time}) {
            _throw('VIAL_VHDL_TRACE_TIME_ERROR',
                'logical cycle regressed within one scenario run: '
                    . $time->[0] . ' follows ' . $state->{last_time}[0],
                "$path/payload/logical_time")
                if $time->[0] < $state->{last_time}[0];
        }
        $state->{last_time} = $time;
        if ($kind eq 'scenario_end') {
            $state->{open} = 0;
            $state->{closed} = 1;
        }
    }
    for my $run (keys %run_state) {
        _throw('VIAL_VHDL_TRACE_RUN_ERROR',
            'scenario run did not close exactly once', '/trace')
            unless $run_state{$run}{closed} && !$run_state{$run}{open};
    }
    _throw('VIAL_VHDL_TRACE_RUN_ERROR',
        'trace run identities or order differ from caller authority', '/trace')
        unless $JSON->encode(\@observed_run_id)
            eq $JSON->encode($raw->{expected_run_ids});

    return {
        ok => JSON::PP::true,
        status => 'closed_validated',
        trace => {
            schema => $TRACE_SCHEMA,
            schema_version => 2,
            record_count => scalar(@record),
            record_counts => {map { $_ => 0 + ($count{$_} // 0) } @KIND},
            plan_id => $plan_id,
            observation_catalog => {
                schema => $CATALOG_SCHEMA,
                catalog_digest => $catalog_digest,
                total_width => $catalog_width,
                sample_ids => \@catalog_ids,
            },
            trace_sha256 => sha256_hex($raw->{trace_text}),
        },
        diagnostics => [],
    };
}

sub _validate_catalog($catalog, $path) {
    _throw('VIAL_VHDL_TRACE_CATALOG_ERROR',
        'observation catalog must be one unblessed record', $path)
        unless ref($catalog) eq 'HASH' && !blessed($catalog);
    _require_exact_keys($catalog,
        [qw(catalog_digest entries schema total_width)], 'observation catalog', $path);
    _throw('VIAL_VHDL_TRACE_CATALOG_ERROR',
        'observation catalog schema is foreign', "$path/schema")
        unless ($catalog->{schema} // '') eq $CATALOG_SCHEMA;
    _throw('VIAL_VHDL_TRACE_CATALOG_ERROR',
        'observation catalog entries must be nonempty and bounded', "$path/entries")
        unless ref($catalog->{entries}) eq 'ARRAY'
            && @{$catalog->{entries}} >= 1 && @{$catalog->{entries}} <= 65_536;
    my (%sample_id, %semantic_id, @sample_id);
    my $width = 0;
    for my $index (0 .. $#{$catalog->{entries}}) {
        my $entry = $catalog->{entries}[$index];
        my $entry_path = "$path/entries/$index";
        _throw('VIAL_VHDL_TRACE_CATALOG_ERROR',
            'catalog entry must be one unblessed record', $entry_path)
            unless ref($entry) eq 'HASH' && !blessed($entry);
        _require_exact_keys($entry, [qw(sample_id semantic_id width)],
            'observation catalog entry', $entry_path);
        for my $key (qw(sample_id semantic_id)) {
            _throw('VIAL_VHDL_TRACE_CATALOG_ERROR',
                "catalog $key must be a nonempty safe identifier", "$entry_path/$key")
                unless defined($entry->{$key}) && !ref($entry->{$key})
                    && $entry->{$key} =~ /\A[A-Za-z0-9_.:\/-]+\z/;
        }
        _throw('VIAL_VHDL_TRACE_CATALOG_ERROR',
            'catalog sample_id must be unique', "$entry_path/sample_id")
            if $sample_id{$entry->{sample_id}}++;
        _throw('VIAL_VHDL_TRACE_CATALOG_ERROR',
            'catalog semantic_id must be unique', "$entry_path/semantic_id")
            if $semantic_id{$entry->{semantic_id}}++;
        _throw('VIAL_VHDL_TRACE_CATALOG_ERROR',
            'catalog width must be a positive bounded integer', "$entry_path/width")
            unless _nonnegative_integer($entry->{width})
                && $entry->{width} >= 1 && $entry->{width} <= 16_777_216;
        $width += $entry->{width};
        _throw('VIAL_VHDL_TRACE_CATALOG_ERROR',
            'catalog total width exceeds the 16 MiB snapshot bound', "$path/total_width")
            if $width > 16_777_216;
        push @sample_id, $entry->{sample_id};
    }
    _throw('VIAL_VHDL_TRACE_CATALOG_ERROR',
        'catalog total_width differs from its entries', "$path/total_width")
        unless _integer_equal($catalog->{total_width}, $width);
    my $digest = sha256_hex($JSON->encode({
        entries => $catalog->{entries}, schema => $catalog->{schema}, total_width => $width,
    }));
    _throw('VIAL_VHDL_TRACE_CATALOG_DIGEST_ERROR',
        'catalog digest does not authenticate its canonical projection',
        "$path/catalog_digest")
        unless defined($catalog->{catalog_digest}) && !ref($catalog->{catalog_digest})
            && $catalog->{catalog_digest} eq "sha256/$digest";
    return ($catalog->{catalog_digest}, $width, @sample_id);
}

sub _validate_time($time, $path) {
    _throw('VIAL_VHDL_TRACE_TIME_ERROR',
        'logical time must be one unblessed record', $path)
        unless ref($time) eq 'HASH' && !blessed($time);
    my @key = qw(cycle local_index phase_rank static_rank);
    _require_exact_keys($time, \@key, 'logical time', $path);
    for my $key (@key) {
        _throw('VIAL_VHDL_TRACE_TIME_ERROR',
            "logical-time $key must be a bounded nonnegative integer", "$path/$key")
            unless _nonnegative_integer($time->{$key})
                && $time->{$key} <= $MAX_RECORDS;
    }
    _throw('VIAL_VHDL_TRACE_TIME_ERROR',
        'logical-time phase_rank is outside the closed DRIVE/SAMPLE/REACT/CHECK set',
        "$path/phase_rank") if $time->{phase_rank} > 3;
    return [map { 0 + $time->{$_} } qw(cycle phase_rank static_rank local_index)];
}

sub _integer_equal($value, $expected) {
    return _nonnegative_integer($value) && $value == $expected;
}

sub _nonnegative_integer($value) {
    return defined($value) && !ref($value) && looks_like_number($value)
        && "$value" =~ /\A(?:0|[1-9][0-9]*)\z/;
}

sub _require_exact_keys($value, $required, $label, $path = '/') {
    _throw('VIAL_VHDL_TRACE_SHAPE_ERROR', "$label must be one unblessed hash", $path)
        unless ref($value) eq 'HASH' && !blessed($value);
    my @actual = sort keys %$value;
    my @expected = sort @$required;
    _throw('VIAL_VHDL_TRACE_SHAPE_ERROR', "$label has an open or incomplete key set", $path)
        unless @actual == @expected && join("\0", @actual) eq join("\0", @expected);
}

sub _failure($code, $message, $path) {
    return {
        ok => JSON::PP::false,
        status => 'failed',
        trace => undef,
        diagnostics => [{code => $code, message => $message, path => $path}],
    };
}

sub _throw($code, $message, $path) {
    die bless {code => $code, message => $message, path => $path},
        'FSM::VIAL::Backend::VHDLPortableTraceValidator::Failure';
}

sub _sanitize_exception($error) {
    my $text = defined($error) ? "$error" : 'unknown host failure';
    $text =~ s/[\r\n]+/ /g;
    $text =~ s/\s+at\s+\S+\s+line\s+\d+.*\z//;
    return $text || 'unknown host failure';
}

package FSM::VIAL::Backend::VHDLPortableTraceValidator::Failure;

use overload '""' => sub { $_[0]{message} }, fallback => 1;

1;
