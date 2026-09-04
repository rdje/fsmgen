#!/usr/bin/env perl

use strict;
use warnings;

use Digest::SHA qw(sha256_hex);
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::VIALSemanticFamilyRegistry qw(
    build_vial_semantic_family_registry
);
use FSM::Support::VIALToolingContract qw(
    build_vial_tooling_contract_v2
);
use FSM::VIAL::LifecycleControl qw(
    validate_vial_lifecycle_condition
    validate_vial_lifecycle_result
);
use FSM::VIAL::Parser;
use FSM::VIAL::PlanBuilder;
use FSM::VIAL::SourceProjection;
use FSM::VIAL::Tool qw(execute_vial_tool_request);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $source_name =
    'vial/ahb_subordinate_base_output_arbitration_lifecycle_v2.vial';
my $base_name = 'vial/ahb_subordinate_base_output_arbitration_v2.vial';
my $hial_name = 'ppif/ahb_lite_subordinate.ppif';
my $base_source = slurp(repo_path($base_name));
my $selected_source = slurp(repo_path($source_name));
my $hial_source = slurp(repo_path($hial_name));
my $spec = slurp(repo_path('docs/vial-spec/lifecycle-control-v2.md'));
my $json = JSON::PP->new->canonical(1)->utf8(1);
my $normal_intents = marked_vial($spec, 'normal');
my $fixture_shape = $selected_source;
$fixture_shape =~ s/^\h+//mg;
$normal_intents =~ s/^\h+//mg;
die 'maintained lifecycle fixture and normative example disagree'
    if index($fixture_shape, $normal_intents) < 0;

subtest 'normal and terse source produce one target-neutral SemanticIR' => sub {
    my $checked = check_source($selected_source);
    ok($checked->{ok}, 'selected lifecycle source reaches typed SemanticIR');
    diag explain $checked->{diagnostics} unless $checked->{ok};

    my $ir = parse_source($selected_source);
    my $semantic = $ir->as_hashref;
    my $family = $semantic->{packages}[0]{intent_families}[0];
    is_deeply([map { $_->{node_kind} } @{$family->{nodes}}], [qw(
        dependency dependency service readiness stimulus_start completion
        drain shutdown finalize deadline deadline failure
    )], 'the compact lifecycle expands to twelve ordered typed records');
    is_deeply($semantic->{required_capabilities}, [qw(
        vial.family.lifecycle_control.deadline.v1
        vial.family.lifecycle_control.v1
        vial.profile.core_directed_single_clock_v2
        vial.semantic_family_envelope.v2
        vial.semantic_ir.v2
        vial.source.v2
    )], 'SemanticIR advertises exactly the compiler capabilities it requires');
    ok(!contains_parser_node($semantic),
        'SemanticIR retains no parser-node implementation objects');

    my ($service) = grep { $_->{node_kind} eq 'service' } @{$family->{nodes}};
    is($service->{payload}{detail}{target}, 'fixture_background',
        'service target remains the target-neutral fixture aggregate');
    is($service->{lifetime}{cancellation}, 'cooperative',
        'service cancellation default is explicit');
    my ($failure) = grep { $_->{node_kind} eq 'failure' } @{$family->{nodes}};
    is_deeply($failure->{payload}{detail}, {
        cleanup => 'finalize', cleanup_max_cycles => 256,
        diagnostics => 'all', disposition => 'fail',
    }, 'failure defaults are materialized in typed payload data');
    my ($readiness) = grep {
        $_->{node_kind} eq 'readiness'
    } @{$family->{nodes}};
    is_deeply(
        [map { $_->{kind} } @{$readiness->{payload}{condition}{operands}}],
        [qw(dependency_satisfied dependency_satisfied service_ready)],
        'readiness keeps dependency and service prerequisites as distinct conditions',
    );
    my @condition_shape_error;
    for my $node (@{$family->{nodes}}) {
        my $payload = $node->{payload};
        push @condition_shape_error,
            condition_shape_errors($payload->{condition}, "$node->{node_kind}/condition")
                if defined($payload->{condition});
        if ($node->{node_kind} eq 'service') {
            push @condition_shape_error,
                condition_shape_errors(
                    $payload->{detail}{$_}, "service/$_",
                ) for qw(
                    start_condition ready_condition quiescent_condition
                    stop_condition
                );
        }
        if ($node->{node_kind} eq 'deadline') {
            push @condition_shape_error,
                condition_shape_errors(
                    $payload->{detail}{$_}, "deadline/$_",
                ) for qw(from until);
        }
    }
    is_deeply(
        \@condition_shape_error, [],
        'every lifecycle condition recursively keeps the exact scalar-or-null shape',
    );
    my $hostile_condition = clone($readiness->{payload}{condition});
    $hostile_condition->{operands}[2]{reference_id} = {
        kind => 'service_ready', reference_id => 'forged/service',
        domain_id => undef, operands => [],
    };
    dies_like(sub {
        validate_vial_lifecycle_condition($hostile_condition)
    }, qr/reference_id must be a stable non-empty identity/,
        'object-valued lifecycle reference substitution fails closed');
    my ($total) = grep {
        $_->{node_kind} eq 'deadline'
            && $_->{payload}{detail}{max_cycles} == 1024
    } @{$family->{nodes}};
    ok($total->{payload}{detail}{last_cycle_inclusive},
        'deadline inclusivity is explicit typed data');

    my $terse = FSM::VIAL::SourceProjection->format_source({
        text => $selected_source, source_name => $source_name,
        output_style => 'terse',
    })->{text};
    my $terse_ir = parse_source($terse);
    is(
        FSM::VIAL::SourceProjection->semantic_projection_sha256($ir),
        FSM::VIAL::SourceProjection->semantic_projection_sha256($terse_ir),
        'normal and terse projections preserve one semantic identity',
    );
    my $empty_ir = parse_source($base_source);
    is(
        FSM::VIAL::SourceProjection->compatibility_projection_sha256($ir),
        FSM::VIAL::SourceProjection->compatibility_projection_sha256($empty_ir),
        'additive lifecycle intent leaves the v1 compatibility projection unchanged',
    );
    is($checked->{semantic_report}{packages}[0]{intent_families}[0]{node_count},
        12, 'the public semantic report exposes the typed node count');
};

subtest 'grammar, identity, order, references, and bounds fail atomically' => sub {
    check_failure(
        changed($selected_source, '(target fixture_background)',
            '(target uvm_phase)', 'target escape'),
        'VIAL_PARSE_ERROR', qr/service target must be fixture_background/,
        'target-specific service escape',
    );
    check_failure(
        changed($selected_source, '(readiness ready)',
            '(readiness configured_gate)', 'duplicate lifecycle identity'),
        'VIAL_SEMANTIC_ERROR', qr/identifier 'configured_gate' is duplicated/,
        'shared lifecycle namespace collision',
    );
    check_failure(
        changed($selected_source,
            "            (deadline total\n              (from (lifecycle_entered))\n              (until (lifecycle_point finalized))\n              (within 1024))\n",
            '', 'full deadline removal'),
        'VIAL_SEMANTIC_ERROR', qr/exactly one full deadline/,
        'missing full-lifecycle deadline',
    );
    check_failure(
        changed($selected_source, '(readiness ready)',
            '(readiness ready (requires (lifecycle_point finalized)))',
            'dependency cycle'),
        'VIAL_SEMANTIC_ERROR', qr/dependency graph contains a cycle/,
        'cyclic lifecycle ordering',
    );
    check_failure(
        changed($selected_source, '(when (configured))',
            '(when (uvm_build_complete))', 'unknown condition'),
        'VIAL_PARSE_ERROR', qr/unknown lifecycle condition/,
        'target-specific condition escape',
    );
    check_failure(
        changed($selected_source, '(within 1024)', '(within 2147483648)',
            'deadline bound overflow'),
        'VIAL_LIMIT_ERROR', qr/exceeds the 2147483647-cycle limit/,
        'deadline bound overflow',
    );
};

subtest 'binding, execution, and plan stages retain typed provenance' => sub {
    my $built = build_plan($selected_source);
    my $first = execute_vial_tool_request(
        request_v2(action => 'plan'), environment([]),
    );
    my $second = execute_vial_tool_request(
        request_v2(action => 'plan'), environment([]),
    );
    ok($first->{success}, 'public lifecycle plan succeeds');
    diag explain $first->{diagnostics} unless $first->{success};
    is_deeply($first->{plan}, $second->{plan},
        'repeated lifecycle planning is deterministic');
    is(scalar(@{$first->{plan}{semantic_families}}), 12,
        'plan carries all twelve lifecycle records');
    my $semantic = parse_source($selected_source)->as_hashref;
    my ($semantic_readiness) = grep {
        $_->{node_kind} eq 'readiness'
    } @{$semantic->{packages}[0]{intent_families}[0]{nodes}};
    my ($execution_readiness) = grep {
        $_->{semantic}{node_kind} eq 'readiness'
    } @{$built->{execution_ir}->as_hashref->{semantic_families}};
    my ($plan_readiness) = grep {
        $_->{semantic}{node_kind} eq 'readiness'
    } @{$built->{plan}{semantic_families}};
    is_deeply(
        $execution_readiness->{semantic}{payload}{condition},
        $semantic_readiness->{payload}{condition},
        'execution preserves the corrected readiness condition exactly',
    );
    is_deeply(
        $plan_readiness->{semantic}{payload}{condition},
        $semantic_readiness->{payload}{condition},
        'plan preserves the corrected readiness condition exactly',
    );

    my $all_traces_complete = 1;
    my $all_bindings_typed = 1;
    my $all_operations_present = 1;
    for my $record (@{$first->{plan}{semantic_families}}) {
        $all_traces_complete &&= $record->{stage} eq 'plan'
            && @{$record->{source_map}{bridge_fact_paths}} == 2
            && @{$record->{source_map}{execution_paths}} == 1
            && @{$record->{source_map}{plan_paths}} == 1
            && @{$record->{source_map}{result_paths}} == 0
            && @{$record->{source_map}{source_locations}} >= 1;
        $all_bindings_typed &&= @{$record->{bindings}} == 2
            && !grep { !@{$_->{type_relation_ids}} }
                @{$record->{bindings}};
        $all_operations_present &&= @{$record->{operation_ids}} >= 2;
    }
    ok($all_traces_complete,
        'every plan record preserves source, bridge, execution, and plan paths');
    ok($all_bindings_typed,
        'every lifecycle record has typed fixture and domain bindings');
    ok($all_operations_present,
        'every lifecycle record expands to explicit operation identities');

    my %ledger = map { $_->{capability_id} => 1 }
        @{$first->{plan}{capability_ledger}};
    ok($ledger{'vial.family.lifecycle_control.v1'}
            && $ledger{'vial.family.lifecycle_control.deadline.v1'}
            && $ledger{'vial.semantic_family_envelope.v2'},
        'execution capability ledger accounts for the lifecycle family');
    is($first->{implementation}{stage}, 'public_lifecycle_planning',
        'public result names the implemented lifecycle-planning stage');
    is($first->{support_accounting}{feature_id},
        'feature.vial_v2_public_lifecycle_plan',
        'public result cites the maintained lifecycle support row');
    is($first->{tool_manifest}{support_accounting}{feature_id},
        'feature.vial_v2_public_lifecycle_plan',
        'persisted manifest cites the same lifecycle support row');
    is_deeply([map { $_->{relpath} } @{$first->{artifacts}}],
        [sort map { $_->{relpath} } @{$first->{artifacts}}],
        'virtual lifecycle artifacts are deterministic and path sorted');
};

subtest 'normalized lifecycle result contract is closed and target-neutral' => sub {
    my $planned = execute_vial_tool_request(
        request_v2(action => 'plan'), environment([]),
    );
    ok($planned->{success}, 'result test obtains a typed lifecycle plan');
    my @records = @{$planned->{plan}{semantic_families}};
    my ($first) = @records;
    my @source_maps;
    for my $index (0 .. $#records) {
        my $source_map = clone($records[$index]{source_map});
        $source_map->{result_paths} = ["/lifecycle_results/0/source_map/$index"];
        seal_source_map($source_map);
        push @source_maps, $source_map;
    }
    my %by_kind;
    push @{$by_kind{$_->{semantic}{node_kind}}}, $_ for @records;
    my $domain_id = $first->{semantic}{order}{domain_id};
    my $time = sub {
        my ($cycle, $ordinal) = @_;
        return {domain_id => $domain_id, cycle => $cycle,
            phase => 'check', ordinal => $ordinal};
    };
    my $point = sub {
        my ($kind, $ordinal) = @_;
        return {record_id => $by_kind{$kind}[0]{semantic}{semantic_id},
            status => 'reached', reached_at => $time->($ordinal, $ordinal)};
    };
    my $result = {
        schema => 'fsmgen.vial_lifecycle_result.v1', schema_version => 1,
        lifecycle_id => $first->{semantic}{payload}{lifecycle_id},
        fixture_id => $first->{semantic}{scope}{owner_id},
        domain_id => $domain_id, status => 'pass', entered_at => $time->(0, 0),
        dependency_results => [map { +{
            record_id => $_->{semantic}{semantic_id}, status => 'satisfied',
            reached_at => $time->(1, $_->{semantic}{order}{rank}),
        } } @{$by_kind{dependency}}],
        readiness_result => $point->('readiness', 3),
        service_results => [map { +{
            record_id => $_->{semantic}{semantic_id}, status => 'stopped',
            started_at => $time->(1, 1), ready_at => $time->(2, 2),
            quiescent_at => $time->(5, 5), stopped_at => $time->(8, 8),
            diagnostic_ids => [],
        } } @{$by_kind{service}}],
        stimulus_start_result => $point->('stimulus_start', 4),
        completion_result => $point->('completion', 5),
        drain_result => $point->('drain', 6),
        shutdown_result => $point->('shutdown', 7),
        finalize_result => $point->('finalize', 8),
        deadline_results => [map { +{
            record_id => $_->{semantic}{semantic_id}, status => 'met',
            started_at => $time->(0, 0), ended_at => $time->(8, 8),
            max_cycles => $_->{semantic}{payload}{detail}{max_cycles},
            last_cycle_inclusive => JSON::PP::true,
        } } @{$by_kind{deadline}}],
        failure_result => {
            record_id => $by_kind{failure}[0]{semantic}{semantic_id},
            primary_diagnostic_id => undef, cleanup_status => 'not_required',
            cleanup_deadline_cycle => undef, diagnostic_ids => [],
        },
        source_map => \@source_maps,
    };
    my $validated = validate_vial_lifecycle_result($result, \@records);
    is_deeply($validated, $result,
        'a complete pass result validates without losing typed evidence');

    my $target_time = clone($result);
    $target_time->{target_timestamp} = '1ns';
    dies_like(sub { validate_vial_lifecycle_result($target_time, \@records) },
        qr/unknown key 'target_timestamp'/,
        'target-specific timestamp is outside the closed result');
    my $false_pass = clone($result);
    $false_pass->{failure_result}{primary_diagnostic_id} = 'diagnostic/failure';
    dies_like(sub { validate_vial_lifecycle_result($false_pass, \@records) },
        qr/passing lifecycle result retains a failure cause/,
        'terminal failure cannot be rewritten as pass');
    my $incomplete_drain = clone($result);
    $incomplete_drain->{drain_result}{status} = 'pending';
    $incomplete_drain->{drain_result}{reached_at} = undef;
    dies_like(sub { validate_vial_lifecycle_result($incomplete_drain, \@records) },
        qr/passing lifecycle result retains an unreached lifecycle point/,
        'incomplete drain cannot be published as pass');
    my $missing_deadline = clone($result);
    $missing_deadline->{deadline_results} = [];
    dies_like(sub { validate_vial_lifecycle_result($missing_deadline, \@records) },
        qr/requires at least one deadline result/,
        'result cannot omit the mandatory full deadline');
    my $exclusive = clone($result);
    $exclusive->{deadline_results}[0]{last_cycle_inclusive} = JSON::PP::false;
    dies_like(sub { validate_vial_lifecycle_result($exclusive, \@records) },
        qr/retain inclusive last-cycle semantics/,
        'exclusive deadline results are rejected');
    my $host_trace = clone($result);
    $host_trace->{source_map}[0]{source_locations}[0]{process_id} = 42;
    dies_like(sub { validate_vial_lifecycle_result($host_trace, \@records) },
        qr/unknown key 'process_id'/,
        'host-process trace data cannot enter normalized evidence');
    my $unrelated_trace = clone($result);
    $unrelated_trace->{source_map}[0]{semantic_id} = 'semantic/unrelated';
    seal_source_map($unrelated_trace->{source_map}[0]);
    dies_like(sub { validate_vial_lifecycle_result($unrelated_trace, \@records) },
        qr/names an unrelated semantic identity/,
        'result provenance cannot switch lifecycle identity');
    my $missing_dependency = clone($result);
    pop @{$missing_dependency->{dependency_results}};
    dies_like(sub {
        validate_vial_lifecycle_result($missing_dependency, \@records)
    }, qr/do not exactly cover the planned records/,
        'pass cannot omit a planned readiness dependency');
    my $missing_map = clone($result);
    pop @{$missing_map->{source_map}};
    dies_like(sub { validate_vial_lifecycle_result($missing_map, \@records) },
        qr/do not exactly cover the planned records/,
        'result provenance covers every planned lifecycle record');
    my $changed_deadline = clone($result);
    ++$changed_deadline->{deadline_results}[0]{max_cycles};
    dies_like(sub {
        validate_vial_lifecycle_result($changed_deadline, \@records)
    }, qr/changes its planned max_cycles/,
        'result cannot widen a planned deadline');
    my $expired_met_deadline = clone($result);
    $expired_met_deadline->{deadline_results}[0]{ended_at}{cycle}
        = $expired_met_deadline->{deadline_results}[0]{max_cycles};
    dies_like(sub {
        validate_vial_lifecycle_result($expired_met_deadline, \@records)
    }, qr/exceeds its inclusive planned window/,
        'result cannot call an expired inclusive deadline met');
    my $regressed_service = clone($result);
    $regressed_service->{service_results}[0]{ready_at} = $time->(0, 0);
    dies_like(sub {
        validate_vial_lifecycle_result($regressed_service, \@records)
    }, qr/service readiness precedes service start/,
        'passing service chronology cannot regress');
    my $regressed_finalize = clone($result);
    $regressed_finalize->{finalize_result}{reached_at} = $time->(6, 6);
    dies_like(sub {
        validate_vial_lifecycle_result($regressed_finalize, \@records)
    }, qr/finalize precedes service stop/,
        'passing lifecycle chronology cannot regress');
    my $substituted_point = clone($result);
    $substituted_point->{readiness_result}{record_id}
        = $substituted_point->{stimulus_start_result}{record_id};
    dies_like(sub {
        validate_vial_lifecycle_result($substituted_point, \@records)
    }, qr/readiness result does not match its planned record/,
        'result cannot substitute one lifecycle point for another');
    my $changed_provenance = clone($result);
    $changed_provenance->{source_map}[0]{plan_paths} = ['/substituted'];
    seal_source_map($changed_provenance->{source_map}[0]);
    dies_like(sub {
        validate_vial_lifecycle_result($changed_provenance, \@records)
    }, qr/changes planned plan_paths/,
        'result cannot replace planned provenance with self-consistent bytes');
    dies_like(sub { validate_vial_lifecycle_result($result) },
        qr/requires a non-empty plan-record array/,
        'result validation cannot detach from its plan authority');
};

subtest 'registry and public discovery claim exactly the implemented frontier' => sub {
    my $registry = build_vial_semantic_family_registry();
    my ($family) = grep { $_->{family_id} eq 'lifecycle_control' }
        @{$registry->{families}};
    is_deeply([@{$family->{maturity}}{qw(
        selection source semantic binding execution plan result
    )}], [qw(selected implemented implemented implemented implemented implemented implemented)],
        'lifecycle maturity reaches result-contract validation');
    for my $backend (@{$family->{backend_profiles}}) {
        is_deeply([@{$backend->{maturity}}{qw(emission compile runtime result parity)}],
            [qw(unavailable unavailable unavailable unavailable unavailable)],
            "$backend->{profile_id} remains explicitly unavailable");
    }

    my $tooling = build_vial_tooling_contract_v2();
    my %capability = map { $_ => 1 } @{$tooling->{capabilities}};
    ok($capability{'vial.family.lifecycle_control.v1'}
            && $capability{'vial.family.lifecycle_control.deadline.v1'},
        'public discovery advertises both lifecycle compiler capabilities');
    ok(!$capability{'vial.backend.sv_portable_verilator.v2'}
            && !$capability{'vial.result_manifest.v2'},
        'discovery does not promote a backend or complete result manifest');
    is_deeply($tooling->{unavailable_actions}, ['run'],
        'v2 run remains unavailable');

    for my $action (qw(check format)) {
        my $result = execute_vial_tool_request(
            request_v2(action => $action), environment([]),
        );
        ok($result->{success}, "public lifecycle $action succeeds");
    }
    my $sink = [];
    my $run = execute_vial_tool_request(
        request_v2(action => 'run'), environment($sink),
    );
    ok(!$run->{success}, 'public lifecycle run remains unavailable');
    is($run->{diagnostics}[0]{code}, 'VIAL_VERSION_UNSUPPORTED',
        'unavailable run fails at the versioned public boundary');
    is_deeply($sink, [], 'unavailable run publishes no artifact');
};

done_testing();

sub repo_path {
    my ($relative) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relative);
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "Cannot read $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "Cannot close $path: $!";
    return $text;
}

sub marked_vial {
    my ($text, $name) = @_;
    my ($body) = $text =~ m{
        <!--\ lifecycle-\Q$name\E-example:start\ -->\s*
        ```vial\s*\n(.*?)\n```\s*
        <!--\ lifecycle-\Q$name\E-example:end\ -->
    }xs;
    die "selected $name lifecycle example was not found" unless defined $body;
    return $body;
}

sub changed {
    my ($source, $before, $after, $label) = @_;
    my $copy = $source;
    my $count = ($copy =~ s/\Q$before\E/$after/);
    die "$label mutation did not match exactly once" unless $count == 1;
    return $copy;
}

sub condition_shape_errors {
    my ($condition, $path) = @_;
    return ("$path is not one plain object")
        unless ref($condition) eq 'HASH';
    my @error;
    my @keys = sort keys %{$condition};
    push @error, "$path has the wrong keys"
        unless join("\0", @keys)
            eq join("\0", sort qw(domain_id kind operands reference_id));
    push @error, "$path kind is not scalar"
        if !defined($condition->{kind}) || ref($condition->{kind});
    push @error, "$path reference_id is not scalar-or-null"
        if defined($condition->{reference_id}) && ref($condition->{reference_id});
    push @error, "$path domain_id is not scalar-or-null"
        if defined($condition->{domain_id}) && ref($condition->{domain_id});
    if (ref($condition->{operands}) ne 'ARRAY') {
        push @error, "$path operands is not one array";
        return @error;
    }
    for my $index (0 .. $#{$condition->{operands}}) {
        push @error, condition_shape_errors(
            $condition->{operands}[$index], "$path/operands/$index",
        );
    }
    return @error;
}

sub check_source {
    my ($text) = @_;
    return FSM::VIAL::Parser->check_source({
        text => $text, source_name => $source_name, source_catalog => {},
    });
}

sub parse_source {
    my ($text) = @_;
    return FSM::VIAL::Parser->parse_source({
        text => $text, source_name => $source_name, source_catalog => {},
    });
}

sub build_plan {
    my ($text) = @_;
    my $built = FSM::VIAL::PlanBuilder->build({
        semantic_ir => parse_source($text),
        hial_source => {
            source_id => $hial_name, format => 'ppif', text => $hial_source,
        },
        fixture_id => 'base_output_arbitration', scenario_ids => [],
        execution_profile => 'core_directed_single_clock_execution_v2',
        replay_manifest => undef, native_extension_catalog => [],
    });
    die 'lifecycle plan did not build: ' . $json->encode($built->{diagnostics})
        unless $built->{ok};
    return $built;
}

sub check_failure {
    my ($text, $code, $message, $label) = @_;
    my $first = check_source($text);
    my $second = check_source($text);
    ok(!$first->{ok}, "$label is rejected");
    is_deeply($first, $second, "$label rejection is deterministic");
    is(scalar(@{$first->{diagnostics}}), 1,
        "$label returns one primary diagnostic");
    is($first->{diagnostics}[0]{code}, $code,
        "$label has the exact diagnostic code");
    like($first->{diagnostics}[0]{message}, $message,
        "$label explains its violated rule");
    is($first->{semantic_report}, undef,
        "$label returns no partial semantic report");
}

sub contains_parser_node {
    my ($value) = @_;
    return 0 unless ref($value);
    return 0 if eval { $value->isa('JSON::PP::Boolean') };
    return 1 if ref($value) ne 'HASH' && ref($value) ne 'ARRAY';
    return scalar(grep { contains_parser_node($_) } values %{$value})
        if ref($value) eq 'HASH';
    return scalar(grep { contains_parser_node($_) } @{$value});
}

sub source_envelope {
    my ($source_id, $text, $kind) = @_;
    return {
        source_id => $source_id, source_kind_hint => $kind, text => $text,
        encoding => 'utf-8', origin => 'memory', display_name => $source_id,
        canonical_id => undef, relative_path => $source_id, metadata => {},
    };
}

sub request_v2 {
    my (%override) = @_;
    my $action = delete($override{action}) || 'check';
    return {
        schema => 'fsmgen.vial_tool_request.v2', schema_version => 2,
        action => $action,
        vial_source => source_envelope($source_name, $selected_source, 'vial'),
        hial_source => ($action eq 'plan' || $action eq 'run')
            ? source_envelope($hial_name, $hial_source, 'ppif') : undef,
        options => {
            source_style => 'auto',
            output_style => $action eq 'format' ? 'terse' : undef,
            fixture_id => ($action eq 'plan' || $action eq 'run')
                ? 'base_output_arbitration' : undef,
            scenario_ids => [],
            execution_profile => ($action eq 'plan' || $action eq 'run')
                ? 'core_directed_single_clock_execution_v2' : undef,
            backend_profile => undef, replay_manifest => undef,
            native_extension_catalogs => [],
            artifact_policy => ($action eq 'plan' || $action eq 'run')
                ? {mode => 'virtual', artifact_root => undef} : undef,
            quiet => JSON::PP::false,
        },
        %override,
    };
}

sub environment {
    my ($sink) = @_;
    return {source_catalog => {}, artifact_sink => $sink || []};
}

sub clone {
    return $json->decode($json->encode($_[0]));
}

sub seal_source_map {
    my ($map) = @_;
    my $identity = clone($map);
    $identity->{source_map_id} = undef;
    $map->{source_map_id} = 'source-map/'
        . sha256_hex($json->encode($identity));
}

sub dies_like {
    my ($code, $pattern, $label) = @_;
    my $ok = eval { $code->(); 1 };
    my $error = $@;
    ok(!$ok, "$label is rejected");
    like($error, $pattern, "$label has the exact failure reason");
}
