package FSM::VIAL::ArchitectureScaleSemanticCatalog;

use v5.20;
use strict;
use warnings;
use bytes ();
use Carp qw(confess);
use Digest::SHA qw(sha256_hex);
use JSON::PP ();
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::VIAL::ArchitectureScaleWorkload;
use FSM::VIAL::Parser;
use FSM::VIAL::SemanticReport;
use FSM::VIAL::SourceProjection;

my $FAMILY = 'semantic_catalog_v1';
my $ROOT_SOURCE = 'generated/vial-scale/semantic_catalog/root.vial';
my $REFERENCE_SOURCE = 'vial/ahb_subordinate_base_output_arbitration.vial';
my $REFERENCE_BYTES = 4_986;
my $REFERENCE_SHA256 = '2205b3b4f073a61374b19cb72f06afe31d75fc4d88f903c414b9b28a744ca4cd';
my $EVALUATION_SCHEMA = 'fsmgen.vial_architecture_scale_semantic_evaluation.v1';
my @CONSTRUCT_KEYS = qw(level primary_axis reference_text);
my @EVALUATE_KEYS = qw(construction);
my @EVALUATION_KEYS = qw(
    ok status schema schema_version workload_identity family level primary_axis
    requested_counts observed_outcome metrics semantic_projection_sha256
    semantic_report_sha256 format_identities diagnostics contract_discrepancies
);

sub construct($class, @args) {
    _exact_invocant($class, 'construct');
    confess __PACKAGE__ . "->construct expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    my $raw = $args[0];
    _confess_exact_keys($raw, \@CONSTRUCT_KEYS, 'semantic construction');

    my ($axis, $level) = @{$raw}{qw(primary_axis level)};
    my $catalog = FSM::VIAL::ArchitectureScaleWorkload->catalog;
    my $axis_contract = defined($axis)
        ? $catalog->{families}{$FAMILY}{axes}{$axis}
        : undef;
    confess "unknown semantic-catalog primary axis\n" unless defined $axis_contract;
    confess "unknown semantic-catalog level\n"
        unless defined($level) && exists $axis_contract->{levels}{$level};

    my $inputs;
    if ($level eq 'reference_v1') {
        _validate_reference_text($raw->{reference_text});
        $inputs = [_input($REFERENCE_SOURCE, $raw->{reference_text})];
    }
    else {
        confess "reference_text is accepted only for reference_v1\n"
            if defined $raw->{reference_text};
        $inputs = _generated_inputs($axis, $level, $axis_contract->{levels}{$level});
    }

    return FSM::VIAL::ArchitectureScaleWorkload->construct({
        family => $FAMILY,
        level => $level,
        primary_axis => $axis,
        backend_profile => undef,
        tool_profile => undef,
        inputs => $inputs,
    });
}

sub parse($class, @args) {
    _exact_invocant($class, 'parse');
    confess __PACKAGE__ . "->parse expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    _confess_exact_keys($args[0], \@EVALUATE_KEYS, 'semantic parse');
    my $invocation = _parser_invocation($args[0]{construction});
    return FSM::VIAL::Parser->parse_source($invocation);
}

sub evaluate($class, @args) {
    _exact_invocant($class, 'evaluate');
    confess __PACKAGE__ . "->evaluate expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    _confess_exact_keys($args[0], \@EVALUATE_KEYS, 'semantic evaluation');
    my $construction = $args[0]{construction};
    my $invocation = _parser_invocation($construction);
    my $spec = $construction->{specification};
    my ($axis, $level) = @{$spec}{qw(primary_axis level)};
    my ($expected_rejection, $discrepancies) = _expected_rejection($axis, $level);

    my $checked = FSM::VIAL::Parser->check_source($invocation);
    if (!$checked->{ok}) {
        my @oracle_errors = _rejection_oracle_errors(
            $axis, $level, $checked->{diagnostics}, $expected_rejection,
        );
        return _evaluation({
            ok => @oracle_errors ? JSON::PP::false : JSON::PP::true,
            status => @oracle_errors ? 'oracle_failure' : 'expected_rejection',
            schema => $EVALUATION_SCHEMA,
            schema_version => 1,
            workload_identity => $construction->{workload_identity},
            family => $FAMILY,
            level => $level,
            primary_axis => $axis,
            requested_counts => _clone($spec->{requested_counts}),
            observed_outcome => 'rejected',
            metrics => _source_metrics($construction),
            semantic_projection_sha256 => undef,
            semantic_report_sha256 => undef,
            format_identities => [],
            diagnostics => @oracle_errors ? \@oracle_errors : _clone($checked->{diagnostics}),
            contract_discrepancies => _clone($discrepancies),
        });
    }

    my @oracle_errors;
    push @oracle_errors, _oracle_error(
        'VIAL_SCALE_SEMANTIC_OUTCOME_ERROR',
        'workload was accepted but the selected oracle requires rejection',
        '/observed_outcome',
    ) if $expected_rejection;

    my $ir = FSM::VIAL::Parser->parse_source($invocation);
    my $data = $ir->as_hashref;
    my $report = FSM::VIAL::SemanticReport->build($ir);
    my $json = JSON::PP->new->canonical(1)->utf8(1);
    push @oracle_errors, _oracle_error(
        'VIAL_SCALE_SEMANTIC_REPORT_ERROR',
        'independent canonical parser passes produced different semantic reports',
        '/semantic_report',
    ) unless $json->encode($report) eq $json->encode($checked->{semantic_report});

    my ($metrics, $integrity_errors) = _semantic_metrics_and_integrity(
        $construction, $data, $axis, $level,
    );
    push @oracle_errors, @{$integrity_errors};
    my $formats = _format_identities($construction);
    my $projection_sha256 = FSM::VIAL::SourceProjection->semantic_projection_sha256($ir);
    my $report_sha256 = sha256_hex($json->encode($report));

    return _evaluation({
        ok => @oracle_errors ? JSON::PP::false : JSON::PP::true,
        status => @oracle_errors ? 'oracle_failure' : 'accepted',
        schema => $EVALUATION_SCHEMA,
        schema_version => 1,
        workload_identity => $construction->{workload_identity},
        family => $FAMILY,
        level => $level,
        primary_axis => $axis,
        requested_counts => _clone($spec->{requested_counts}),
        observed_outcome => 'accepted',
        metrics => $metrics,
        semantic_projection_sha256 => $projection_sha256,
        semantic_report_sha256 => $report_sha256,
        format_identities => $formats,
        diagnostics => \@oracle_errors,
        contract_discrepancies => _clone($discrepancies),
    });
}

sub evaluation_keys($class) {
    _exact_invocant($class, 'evaluation_keys');
    return [@EVALUATION_KEYS];
}

sub _generated_inputs($axis, $level, $requested) {
    my ($key) = grep { $_ ne 'derivation' && $_ ne 'construction_rule'
        && $_ ne 'declared_cap_bytes' && $_ ne 'minimum_bytes'
        && $_ ne 'earliest_cap_authoritative' } sort keys %{$requested};

    if ($axis eq 'source_bytes_per_source') {
        my $target = $level eq 'over_limit_v1'
            ? $requested->{declared_cap_bytes}
            : $requested->{$axis};
        my $source = _byte_source({
            target_bytes => $target,
            axis => $axis,
            source_ordinal => 0,
            package_name => 'semantic_byte_root',
            imports => [],
            append_complete_record_over_boundary => $level eq 'over_limit_v1' ? 1 : 0,
        });
        return [_input($ROOT_SOURCE, $source)];
    }
    if ($axis eq 'source_bytes_combined') {
        return _combined_byte_inputs($level, $requested);
    }

    my $count = $requested->{$key};
    confess "semantic workload count is unavailable\n"
        unless defined($count) && !ref($count) && $count =~ /\A[0-9]+\z/;
    return _structural_inputs($axis, 0 + $count);
}

sub _structural_inputs($axis, $count) {
    if ($axis eq 'imports') {
        my @imports;
        my @inputs;
        my @root_types = ('(type bit_t (logic 1))');
        my @root_fields = ('(value (type bit_t))');
        for my $ordinal (0 .. $count - 1) {
            my $suffix = sprintf('%08d', $ordinal);
            my $alias = "import_$suffix";
            my $path = "generated/vial-scale/semantic_catalog/import_$suffix.vial";
            push @imports, [$alias, $path];
            push @root_types, "(type imported_type_$suffix (type $alias.bit_t))";
            push @root_fields, "(imported_field_$suffix (type imported_type_$suffix))";
            push @inputs, _input($path, _render_source({
                package_name => "semantic_import_$suffix",
                imports => [],
                types => ['(type bit_t (logic 1))'],
                fields => ['(value (type bit_t))'],
                scoreboards => [],
                fixtures => [_fixture("fixture_$suffix", 'bit_t', undef, undef, '(reset c 1)')],
                unit_ref => "unit/import_$suffix",
            }));
        }
        my $root = _render_source({
            package_name => 'semantic_import_root',
            imports => \@imports,
            types => \@root_types,
            fields => \@root_fields,
            scoreboards => [],
            fixtures => [_fixture('root_fixture', 'bit_t', undef, undef, '(reset c 1)')],
            unit_ref => 'unit/import_root',
        });
        return [_input($ROOT_SOURCE, $root), @inputs];
    }

    my @types = ('(type bit_t (logic 1))');
    my @fields = ('(value (type bit_t))');
    my @scoreboards;
    my @fixtures;
    my $endpoint_type = 'bit_t';
    my $action = '(reset c 1)';
    my $coverage;
    my $scoreboard_name;

    if ($axis eq 'declarations') {
        @types = ();
        @fields = ();
        for my $ordinal (0 .. $count - 1) {
            my $suffix = sprintf('%08d', $ordinal);
            push @types, "(type declared_$suffix (logic 1))";
            push @fields, "(field_$suffix (type declared_$suffix))";
        }
        $endpoint_type = 'declared_00000000';
    }
    elsif ($axis eq 'fixtures') {
        @fixtures = map {
            _fixture(sprintf('fixture_%08d', $_), 'bit_t', undef, undef, '(reset c 1)')
        } 0 .. $count - 1;
    }
    elsif ($axis eq 'actions') {
        $action = join(' ', ('(reset c 1)') x $count);
    }
    elsif ($axis eq 'parallel_depth') {
        $action = '(reset c 1)';
        for my $depth (reverse 1 .. $count) {
            my $suffix = sprintf('%02d', $depth);
            $action = "(parallel all (fiber chain_$suffix $action) (fiber sibling_$suffix (reset c 1)))";
        }
    }
    elsif ($axis eq 'fibers_per_parallel') {
        $action = '(parallel all ' . join(' ', map {
            sprintf('(fiber fiber_%08d (reset c 1))', $_)
        } 0 .. $count - 1) . ')';
    }
    elsif ($axis eq 'scalar_or_list_length') {
        @types = ("(type scaled_type (list $count (logic 1)))");
        @fields = ('(value (type scaled_type))');
        $endpoint_type = 'scaled_type';
    }
    elsif ($axis eq 'record_fields') {
        my $record = join(' ', map {
            sprintf('(field_%08d (logic 1))', $_)
        } 0 .. $count - 1);
        @types = ("(type scaled_type (record $record))");
        @fields = ('(value (type scaled_type))');
        $endpoint_type = 'scaled_type';
    }
    elsif ($axis eq 'aggregate_depth') {
        my $type = '(logic 1)';
        $type = "(list 1 $type)" for 1 .. $count;
        @types = ("(type scaled_type $type)");
        @fields = ('(value (type scaled_type))');
        $endpoint_type = 'scaled_type';
    }
    elsif ($axis eq 'scoreboard_capacity') {
        @scoreboards = ("(scoreboard scaled_scoreboard (transaction txn) (policy in_order) (capacity $count))");
        $scoreboard_name = 'scaled_scoreboard';
    }
    elsif ($axis eq 'coverage_bins') {
        $coverage = join(' ',
            '(coverpoint point_a (sample c) (expr (sample endpoint)) (bins (bin zero normal (value #b0))))',
            '(coverpoint point_b (sample c) (expr (sample endpoint)) (bins (bin zero normal (value #b0))))',
            "(cross scaled_cross (points point_a point_b) (max_bins $count))",
        );
    }
    elsif ($axis eq 'literal_repeat_count') {
        $action = "(repeat $count (reset c 1))";
    }
    else {
        confess "unsupported semantic structural axis '$axis'\n";
    }

    @fixtures = (_fixture('root_fixture', $endpoint_type, $scoreboard_name, $coverage, $action))
        unless @fixtures;
    my $source = _render_source({
        package_name => "semantic_$axis",
        imports => [],
        types => \@types,
        fields => \@fields,
        scoreboards => \@scoreboards,
        fixtures => \@fixtures,
        unit_ref => "unit/$axis",
    });
    return [_input($ROOT_SOURCE, $source)];
}

sub _combined_byte_inputs($level, $requested) {
    my $declared = $level eq 'over_limit_v1'
        ? $requested->{declared_cap_bytes}
        : $requested->{source_bytes_combined};
    my $full_sources = int($declared / 1_048_576);
    my $remainder = $declared % 1_048_576;
    my $extra = $level eq 'over_limit_v1' ? 1 : 0;
    my $source_count = $full_sources + ($remainder ? 1 : 0) + $extra;
    confess "combined byte workload must contain at least one source\n" unless $source_count;

    my @imports;
    for my $ordinal (1 .. $source_count - 1) {
        my $suffix = sprintf('%08d', $ordinal);
        push @imports, ["source_$suffix", "generated/vial-scale/semantic_catalog/source_$suffix.vial"];
    }

    my @inputs;
    for my $ordinal (0 .. $source_count - 1) {
        my $is_extra = $extra && $ordinal == $source_count - 1;
        my $target = $is_extra ? 65_536
            : $ordinal < $full_sources ? 1_048_576
            : $remainder;
        my $suffix = sprintf('%08d', $ordinal);
        my $path = $ordinal == 0
            ? $ROOT_SOURCE
            : "generated/vial-scale/semantic_catalog/source_$suffix.vial";
        my $source = _byte_source({
            target_bytes => $target,
            axis => 'source_bytes_combined',
            source_ordinal => $ordinal,
            package_name => "semantic_bytes_$suffix",
            imports => $ordinal == 0 ? \@imports : [],
            append_complete_record_over_boundary => 0,
        });
        push @inputs, _input($path, $source);
    }
    return \@inputs;
}

sub _byte_source($raw) {
    my $target = $raw->{target_bytes};
    my $source_ordinal = $raw->{source_ordinal};
    my (@types, @fields);
    my $width = 4_096;
    my $ordinal = 0;
    my ($type, $field) = _byte_record($raw->{axis}, $source_ordinal, $ordinal, $width);
    push @types, $type;
    push @fields, $field;

    my $source = _render_source({
        package_name => $raw->{package_name}, imports => $raw->{imports},
        types => \@types, fields => \@fields, scoreboards => [],
        fixtures => [_fixture('byte_fixture', 'payload_00000000', undef, undef, '(reset c 1)')],
        unit_ref => 'unit/byte_boundary',
    });
    confess "byte target is too small for one valid referenced declaration\n"
        if bytes::length($source) > $target;

    my ($next_type, $next_field) = _byte_record($raw->{axis}, $source_ordinal, 1, $width);
    my $pair_bytes = bytes::length($next_type) + bytes::length($next_field) + 2;
    my $remaining = $target - bytes::length($source);
    my $additional = int($remaining / $pair_bytes);
    for my $index (1 .. $additional) {
        my ($record_type, $record_field) = _byte_record(
            $raw->{axis}, $source_ordinal, $index, $width,
        );
        push @types, $record_type;
        push @fields, $record_field;
    }
    $source = _render_source({
        package_name => $raw->{package_name}, imports => $raw->{imports},
        types => \@types, fields => \@fields, scoreboards => [],
        fixtures => [_fixture('byte_fixture', 'payload_00000000', undef, undef, '(reset c 1)')],
        unit_ref => 'unit/byte_boundary',
    });
    my $tail = $target - bytes::length($source);
    confess "byte source arithmetic exceeded its target\n" if $tail < 0;
    my $unit_ref = 'unit/byte_boundary' . ('x' x $tail);
    $source = _render_source({
        package_name => $raw->{package_name}, imports => $raw->{imports},
        types => \@types, fields => \@fields, scoreboards => [],
        fixtures => [_fixture('byte_fixture', 'payload_00000000', undef, undef, '(reset c 1)')],
        unit_ref => $unit_ref,
    });
    confess "byte source does not meet its exact requested boundary\n"
        unless bytes::length($source) == $target;

    if ($raw->{append_complete_record_over_boundary}) {
        my ($record_type, $record_field) = _byte_record(
            $raw->{axis}, $source_ordinal, scalar(@types), $width,
        );
        push @types, $record_type;
        push @fields, $record_field;
        $source = _render_source({
            package_name => $raw->{package_name}, imports => $raw->{imports},
            types => \@types, fields => \@fields, scoreboards => [],
            fixtures => [_fixture('byte_fixture', 'payload_00000000', undef, undef, '(reset c 1)')],
            unit_ref => $unit_ref,
        });
        confess "over-limit byte source did not append a whole referenced declaration\n"
            unless bytes::length($source) > $target;
    }
    return $source;
}

sub _byte_record($axis, $source_ordinal, $ordinal, $width) {
    my $suffix = sprintf('%08d', $ordinal);
    my $payload = FSM::VIAL::ArchitectureScaleWorkload->payload_uint({
        family => $FAMILY,
        primary_axis => $axis,
        ordinal => $source_ordinal * 10_000 + $ordinal,
        low => 0,
        high => 4_294_967_295,
    });
    my $bits = sprintf('%032b', $payload->{value});
    $bits = substr($bits x int(($width + 31) / 32), 0, $width);
    return (
        "(enum payload_$suffix (logic $width) (value #b$bits))",
        "(payload_field_$suffix (type payload_$suffix))",
    );
}

sub _render_source($raw) {
    my $imports = join(' ', map {
        '(import ' . $_->[0] . ' "' . $_->[1] . '")'
    } @{$raw->{imports}});
    my $types = join(' ', @{$raw->{types}});
    my $fields = join(' ', @{$raw->{fields}});
    my $scoreboards = join(' ', @{$raw->{scoreboards}});
    return join('',
        '(vial (version 1) (package ', $raw->{package_name},
        ' (imports ', $imports, ')',
        ' (types ', $types, ')',
        ' (transactions (transaction txn (fields ', $fields, ') (events completed)))',
        ' (models)',
        ' (scoreboards ', $scoreboards, ')',
        ' (fixtures ',
        join(' ', map {
            my $fixture = $_;
            $fixture =~ s/__UNIT_REF__/$raw->{unit_ref}/;
            $fixture;
        } @{$raw->{fixtures}}),
        ")))\n",
    );
}

sub _fixture($name, $endpoint_type, $scoreboard_name, $coverage, $action) {
    my $instances = defined($scoreboard_name)
        ? "(scoreboard scoreboard_instance $scoreboard_name (actual transaction))"
        : '';
    $coverage //= '';
    return join('',
        '(fixture ', $name,
        ' (dut dut (unit "__UNIT_REF__/', $name,
        '") (domains (domain c "domain/clock"))',
        ' (endpoints (endpoint endpoint "endpoint/value" (type ', $endpoint_type, ') public_port))',
        ' (transactions (transaction transaction "transaction/value" txn)))',
        ' (instances ', $instances, ')',
        ' (coverage ', $coverage, ')',
        ' (faults)',
        ' (randomness (seed 1701))',
        ' (scenarios (scenario scenario (timeout (cycles c 2147483647)) (steps ', $action, ')))',
        ')',
    );
}

sub _parser_invocation($construction) {
    confess "semantic parser construction must be one successful closed result\n"
        unless ref($construction) eq 'HASH' && !blessed($construction)
            && $construction->{ok}
            && ($construction->{specification}{family} // '') eq $FAMILY;
    my @vial = grep { $_->{role} eq 'vial_source' } @{$construction->{inputs}};
    my $root_name = $construction->{specification}{level} eq 'reference_v1'
        ? $REFERENCE_SOURCE : $ROOT_SOURCE;
    my ($root) = grep { $_->{relative_path} eq $root_name } @vial;
    confess "semantic workload root source is absent\n" unless defined $root;
    my %catalog = map { $_->{relative_path} => $_->{content} }
        grep { $_->{relative_path} ne $root_name } @vial;
    return {
        text => $root->{content},
        source_name => $root_name,
        source_catalog => \%catalog,
    };
}

sub _expected_rejection($axis, $level) {
    my @discrepancies;
    if ($axis eq 'literal_repeat_count'
        && ($level eq 'qualification_candidate_v1' || $level eq 'limit_v1')) {
        push @discrepancies, {
            code => 'VIAL_SCALE_LIMIT_INTERACTION',
            message => 'the 65536 expanded-action cap precedes the selected literal-repeat candidate',
            path => '/requested_counts/literal_repeat_count',
            repair_owner => 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.4',
        };
        return (1, \@discrepancies);
    }
    return ($level eq 'over_limit_v1' ? 1 : 0, \@discrepancies);
}

sub _rejection_oracle_errors($axis, $level, $diagnostics, $expected) {
    return (_oracle_error(
        'VIAL_SCALE_SEMANTIC_OUTCOME_ERROR',
        'workload was rejected but the selected oracle requires acceptance',
        '/observed_outcome',
    )) unless $expected;
    return (_oracle_error(
        'VIAL_SCALE_SEMANTIC_DIAGNOSTIC_ERROR',
        'rejected workload must return exactly one deterministic diagnostic',
        '/diagnostics',
    )) unless ref($diagnostics) eq 'ARRAY' && @{$diagnostics} == 1;
    my $diagnostic = $diagnostics->[0];
    my ($message, $path) = _rejection_patterns($axis, $level);
    my @errors;
    push @errors, _oracle_error(
        'VIAL_SCALE_SEMANTIC_DIAGNOSTIC_ERROR',
        'earliest semantic rejection did not use VIAL_LIMIT_ERROR',
        '/diagnostics/0/code',
    ) unless ($diagnostic->{code} // '') eq 'VIAL_LIMIT_ERROR';
    push @errors, _oracle_error(
        'VIAL_SCALE_SEMANTIC_DIAGNOSTIC_ERROR',
        'earliest semantic rejection message does not identify the authoritative cap',
        '/diagnostics/0/message',
    ) unless ($diagnostic->{message} // '') =~ $message;
    push @errors, _oracle_error(
        'VIAL_SCALE_SEMANTIC_DIAGNOSTIC_ERROR',
        'earliest semantic rejection path does not identify the authoritative boundary',
        '/diagnostics/0/semantic_path',
    ) unless ($diagnostic->{semantic_path} // '') =~ $path;
    return @errors;
}

sub _rejection_patterns($axis, $level) {
    return (qr/imported sources exceed the 64-source limit/, qr{/imports\z}) if $axis eq 'imports';
    return (qr/exceeds 4096 declarations/, qr{/types\z}) if $axis eq 'declarations';
    return (qr/exceeds 1024 fixtures/, qr{/fixtures\z}) if $axis eq 'fixtures';
    return (qr/exceeds 65536 expanded actions/, qr{/scenarios/0\z})
        if $axis eq 'actions'
            || ($axis eq 'literal_repeat_count' && $level ne 'over_limit_v1');
    return (qr/parallel nesting exceeds 16 levels/, qr{/actions/0\z}) if $axis eq 'parallel_depth';
    return (qr/parallel exceeds 256 fibers/, qr{/actions/0\z}) if $axis eq 'fibers_per_parallel';
    return (qr/bounded range 1 through 65536/, qr{/length\z}) if $axis eq 'scalar_or_list_length';
    return (qr/record exceeds 256 fields/, qr{/type\z}) if $axis eq 'record_fields';
    return (qr/aggregate nesting exceeds 32 levels/, qr{/element_type\z}) if $axis eq 'aggregate_depth';
    return (qr/bounded range 1 through 1000000/, qr{/capacity\z}) if $axis eq 'scoreboard_capacity';
    return (qr/bounded range 1 through 1000000/, qr{/max_bins\z}) if $axis eq 'coverage_bins';
    return (qr/bounded range 1 through 1000000/, qr{/count\z}) if $axis eq 'literal_repeat_count';
    return (qr/source exceeds the 1048576-byte limit/, qr{^/$}) if $axis eq 'source_bytes_per_source';
    return (qr/combined imported source bytes exceed the 16777216-byte limit/, qr{/imports\z})
        if $axis eq 'source_bytes_combined';
    confess "rejection oracle is unavailable for '$axis'\n";
}

sub _semantic_metrics_and_integrity($construction, $data, $axis, $level) {
    my @errors;
    my %source_bytes = map { $_->{source_name} => $_->{byte_length} } @{$data->{sources}};
    my %entity_ids;
    _walk($data, sub ($value, $path) {
        return unless ref($value) eq 'HASH';
        if (defined($value->{semantic_path})) {
            my $span = $value->{source_span};
            push @errors, _oracle_error(
                'VIAL_SCALE_SEMANTIC_SPAN_ERROR', 'semantic entity lacks one source span', $path,
            ) unless _valid_span($span, \%source_bytes);
            if (defined($value->{semantic_id}) && defined($value->{name})) {
                my $previous = $entity_ids{$value->{semantic_id}};
                push @errors, _oracle_error(
                    'VIAL_SCALE_SEMANTIC_ID_ERROR', 'semantic entity ID maps to multiple authored entities', $path,
                ) if defined($previous) && $previous ne $value->{semantic_path};
                $entity_ids{$value->{semantic_id}} //= $value->{semantic_path};
            }
        }
    });

    my %resolvable = %entity_ids;
    _walk($data, sub ($value, $path) {
        return unless ref($value) eq 'HASH';
        $resolvable{$value->{handle_id}} = 1
            if ($value->{kind} // '') eq 'start' && defined $value->{handle_id};
    });
    my @reference_keys = qw(
        package_id domain_id input_id model_id scoreboard_id actual_id
        transaction_id endpoint_id fault_id handle_id scoreboard_instance_id
        transaction_binding_id
    );
    my %reference_key = map { $_ => 1 } @reference_keys;
    _walk($data, sub ($value, $path) {
        return unless ref($value) eq 'HASH';
        for my $key (sort keys %{$value}) {
            next unless $reference_key{$key};
            next if ($value->{kind} // '') eq 'start' && $key eq 'handle_id';
            my $target = $value->{$key};
            push @errors, _oracle_error(
                'VIAL_SCALE_SEMANTIC_REFERENCE_ERROR', "internal reference '$key' is unresolved", "$path/$key",
            ) if defined($target) && !ref($target) && !$resolvable{$target};
        }
        if (ref($value->{point_ids}) eq 'ARRAY') {
            for my $index (0 .. $#{$value->{point_ids}}) {
                push @errors, _oracle_error(
                    'VIAL_SCALE_SEMANTIC_REFERENCE_ERROR', 'coverage point reference is unresolved', "$path/point_ids/$index",
                ) unless $resolvable{$value->{point_ids}[$index]};
            }
        }
        if (($value->{kind} // '') eq 'reference'
            && exists($value->{authored_name}) && exists($value->{resolved})) {
            push @errors, _oracle_error(
                'VIAL_SCALE_SEMANTIC_TYPE_ERROR', 'type reference is not closed over a declared semantic type', $path,
            ) unless $resolvable{$value->{semantic_id}} && ref($value->{resolved}) eq 'HASH';
        }
    });

    my $root = $data->{packages}[0];
    my $fixture = $root->{fixtures}[0];
    my $scenario = $fixture->{scenarios}[0];
    my $metrics = {
        sources => scalar(@{$data->{sources}}),
        source_bytes_per_source => 0 + $data->{root_source}{byte_length},
        source_bytes_combined => 0,
        imports => scalar(@{$root->{imports}}),
        declarations => scalar(@{$root->{types}}),
        fixtures => scalar(@{$root->{fixtures}}),
        actions => 0 + $scenario->{action_count},
        parallel_depth => _parallel_depth($scenario->{actions}),
        fibers_per_parallel => _max_fibers($scenario->{actions}),
        scalar_or_list_length => _selected_length($root->{types}),
        record_fields => _selected_record_fields($root->{types}),
        aggregate_depth => _selected_aggregate_depth($root->{types}),
        scoreboard_capacity => @{$root->{scoreboards}} ? 0 + $root->{scoreboards}[0]{capacity} : 0,
        coverage_bins => @{$fixture->{coverage}{crosses}} ? 0 + $fixture->{coverage}{crosses}[0]{max_bins} : 0,
        literal_repeat_count => _repeat_count($scenario->{actions}),
        semantic_ids => scalar(keys %entity_ids),
        provenance_records => scalar(keys %{$data->{provenance}}),
    };
    $metrics->{source_bytes_combined} += $_->{byte_length} for @{$data->{sources}};

    if ($level ne 'reference_v1') {
        my $requested = $construction->{specification}{requested_counts};
        my $expected = $requested->{$axis};
        push @errors, _oracle_error(
            'VIAL_SCALE_SEMANTIC_COUNT_ERROR',
            "observed '$axis' does not equal the requested count",
            "/metrics/$axis",
        ) if defined($expected) && ($metrics->{$axis} // -1) != $expected;
    }
    push @errors, _ordered_entity_errors($data);
    return ($metrics, \@errors);
}

sub _source_metrics($construction) {
    my @bytes = map { bytes::length($_->{content}) } @{$construction->{inputs}};
    my $combined = 0;
    $combined += $_ for @bytes;
    return {
        sources => scalar(@bytes),
        source_bytes_per_source => @bytes ? $bytes[0] : 0,
        source_bytes_combined => $combined,
    };
}

sub _format_identities($construction) {
    my @identities;
    for my $input (@{$construction->{inputs}}) {
        next unless $input->{role} eq 'vial_source';
        my $first = FSM::VIAL::SourceProjection->format_source({
            text => $input->{content}, source_name => $input->{relative_path}, output_style => 'normal',
        });
        my $second = FSM::VIAL::SourceProjection->format_source({
            output_style => 'normal', source_name => $input->{relative_path}, text => $input->{content},
        });
        confess "canonical VIAL formatter rerun is nondeterministic\n"
            unless $first->{text} eq $second->{text};
        push @identities, {
            source_name => $input->{relative_path},
            input_style => $first->{input_style},
            output_style => $first->{output_style},
            bytes => bytes::length($first->{text}),
            sha256 => sha256_hex($first->{text}),
        };
    }
    return \@identities;
}

sub _ordered_entity_errors($data) {
    my @errors;
    for my $package (@{$data->{packages}}) {
        for my $key (qw(imports types transactions models scoreboards fixtures)) {
            my $last = -1;
            for my $index (0 .. $#{$package->{$key}}) {
                my $item = $package->{$key}[$index];
                next unless ref($item->{source_span}) eq 'HASH';
                my $start = $item->{source_span}{start_byte};
                push @errors, _oracle_error(
                    'VIAL_SCALE_SEMANTIC_ORDER_ERROR', "authored '$key' order is not source order", "/$key/$index",
                ) if $start <= $last;
                $last = $start;
            }
        }
    }
    return @errors;
}

sub _valid_span($span, $source_bytes) {
    return 0 unless ref($span) eq 'HASH';
    my $source = $span->{source_name};
    return 0 unless defined($source) && exists $source_bytes->{$source};
    return 0 unless defined($span->{start_byte}) && defined($span->{end_byte_exclusive});
    return 0 unless $span->{start_byte} >= 0
        && $span->{start_byte} < $span->{end_byte_exclusive}
        && $span->{end_byte_exclusive} <= $source_bytes->{$source};
    return 0 unless ($span->{start_line} // 0) >= 1 && ($span->{start_column} // 0) >= 1;
    return 1;
}

sub _parallel_depth($actions) {
    my $max = 0;
    for my $action (@{$actions || []}) {
        next unless ($action->{kind} // '') eq 'parallel';
        my $child = 0;
        for my $fiber (@{$action->{fibers}}) {
            my $depth = _parallel_depth($fiber->{actions});
            $child = $depth if $depth > $child;
        }
        $max = 1 + $child if 1 + $child > $max;
    }
    return $max;
}

sub _max_fibers($actions) {
    my $max = 0;
    for my $action (@{$actions || []}) {
        next unless ($action->{kind} // '') eq 'parallel';
        $max = scalar(@{$action->{fibers}}) if @{$action->{fibers}} > $max;
        for my $fiber (@{$action->{fibers}}) {
            my $nested = _max_fibers($fiber->{actions});
            $max = $nested if $nested > $max;
        }
    }
    return $max;
}

sub _selected_length($types) {
    for my $type (@{$types || []}) {
        next unless $type->{name} eq 'scaled_type';
        my $resolved = $type->{type};
        return 0 + $resolved->{length} if ($resolved->{kind} // '') eq 'list';
        return 0 + $resolved->{width} if ($resolved->{kind} // '') eq 'scalar';
    }
    return 0;
}

sub _selected_record_fields($types) {
    for my $type (@{$types || []}) {
        next unless $type->{name} eq 'scaled_type';
        return scalar(@{$type->{type}{fields}}) if ($type->{type}{kind} // '') eq 'record';
    }
    return 0;
}

sub _selected_aggregate_depth($types) {
    for my $type (@{$types || []}) {
        next unless $type->{name} eq 'scaled_type';
        return _aggregate_depth($type->{type});
    }
    return 0;
}

sub _aggregate_depth($type) {
    return 0 unless ref($type) eq 'HASH';
    return 1 + _aggregate_depth($type->{element_type}) if ($type->{kind} // '') eq 'list';
    if (($type->{kind} // '') eq 'record') {
        my $max = 0;
        for my $field (@{$type->{fields}}) {
            my $depth = _aggregate_depth($field->{type});
            $max = $depth if $depth > $max;
        }
        return 1 + $max;
    }
    return _aggregate_depth($type->{resolved}) if ($type->{kind} // '') eq 'reference';
    return 0;
}

sub _repeat_count($actions) {
    for my $action (@{$actions || []}) {
        return 0 + $action->{count} if ($action->{kind} // '') eq 'repeat';
        if (($action->{kind} // '') eq 'parallel') {
            for my $fiber (@{$action->{fibers}}) {
                my $count = _repeat_count($fiber->{actions});
                return $count if $count;
            }
        }
    }
    return 0;
}

sub _walk($value, $consumer, $path = '') {
    return unless ref($value);
    $consumer->($value, length($path) ? $path : '/');
    if (ref($value) eq 'HASH') {
        _walk($value->{$_}, $consumer, "$path/$_") for sort keys %{$value};
    }
    elsif (ref($value) eq 'ARRAY') {
        _walk($value->[$_], $consumer, "$path/$_") for 0 .. $#{$value};
    }
}

sub _validate_reference_text($text) {
    confess "reference_text must contain the exact checked VIAL anchor\n"
        unless defined($text) && !ref($text)
            && bytes::length($text) == $REFERENCE_BYTES
            && sha256_hex($text) eq $REFERENCE_SHA256;
}

sub _input($relative_path, $content) {
    return {
        relative_path => $relative_path,
        role => 'vial_source',
        encoding => 'utf-8',
        content => $content,
    };
}

sub _evaluation($value) {
    my %expected = map { $_ => 1 } @EVALUATION_KEYS;
    confess "semantic evaluation has unknown keys\n" if grep { !$expected{$_} } keys %{$value};
    confess "semantic evaluation has missing keys\n" if grep { !exists($value->{$_}) } @EVALUATION_KEYS;
    return _clone($value);
}

sub _oracle_error($code, $message, $path) {
    return { code => $code, severity => 'error', message => $message, path => $path };
}

sub _confess_exact_keys($value, $keys, $label) {
    my %expected = map { $_ => 1 } @{$keys};
    my @unknown = sort grep { !$expected{$_} } keys %{$value};
    my @missing = grep { !exists($value->{$_}) } @{$keys};
    confess "$label has unknown key '$unknown[0]'\n" if @unknown;
    confess "$label is missing key '$missing[0]'\n" if @missing;
}

sub _exact_invocant($class, $method) {
    confess __PACKAGE__ . "->$method requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
}

sub _clone($value) {
    return undef unless defined $value;
    return { map { $_ => _clone($value->{$_}) } sort keys %{$value} } if ref($value) eq 'HASH';
    return [map { _clone($_) } @{$value}] if ref($value) eq 'ARRAY';
    return $value;
}

1;
