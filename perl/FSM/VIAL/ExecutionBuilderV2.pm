package FSM::VIAL::ExecutionBuilderV2;

use strict;
use warnings;

use Digest::SHA qw(sha256_hex);
use JSON::PP ();
use Scalar::Util qw(blessed reftype);

use FSM::Support::VIALSemanticFamilyRegistry qw(
    negotiate_vial_semantic_family_requirements
    vial_family_requirements_from_semantic_ir
    vial_semantic_family_negotiation_message
);
use FSM::VIAL::LifecycleControl qw(
    build_vial_lifecycle_execution_records
);

my $PROFILE = 'core_directed_single_clock_execution_v2';
my %CAPABILITY_REPLACEMENT = (
    'vial.source.v1' => 'vial.source.v2',
    'vial.semantic_ir.v1' => 'vial.semantic_ir.v2',
    'vial.profile.core_directed_single_clock_v1' =>
        'vial.profile.core_directed_single_clock_v2',
    'vial.execution_ir.v1' => 'vial.execution_ir.v2',
    'vial.execution_profile.core_directed_single_clock_execution_v1' =>
        'vial.execution_profile.core_directed_single_clock_execution_v2',
    'vial.plan.v1' => 'vial.plan.v2',
);

sub build {
    my ($class, @args) = @_;
    return _failure(
        'VIAL_EXECUTION_INVOCATION_ERROR', 'invocation',
        'build must be called with the FSM::VIAL::ExecutionBuilderV2 class invocant', '/',
    ) unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return _failure(
        'VIAL_EXECUTION_INVOCATION_ERROR', 'invocation',
        'build expects exactly one closed argument hash', '/',
    ) unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);

    my $result = eval { _build($args[0]) };
    return $result if defined $result;
    my $error = $@;
    if (blessed($error)
        && $error->isa('FSM::VIAL::LifecycleControl::ExecutionDiagnostic')) {
        return _failure(
            $error->{code}, $error->{phase}, $error->{message},
            $error->{semantic_path}, $error->{source_location},
        );
    }
    my $message = _sanitize_exception($error);
    return _failure(
        'VIAL_EXECUTION_INTERNAL_ERROR', 'internal', $message, '/',
    );
}

sub _build {
    my ($raw) = @_;
    my @keys = qw(
        semantic_ir bridge_manifest fixture_id scenario_ids execution_profile
        replay_manifest native_extension_catalog
    );
    my %expected = map { $_ => 1 } @keys;
    my @unknown = sort grep { !$expected{$_} } keys %{$raw};
    my @missing = grep { !exists($raw->{$_}) } @keys;
    return _failure(
        'VIAL_EXECUTION_INVOCATION_ERROR', 'invocation',
        "unknown build key '$unknown[0]'", '/',
    ) if @unknown;
    return _failure(
        'VIAL_EXECUTION_INVOCATION_ERROR', 'invocation',
        "missing build key '$missing[0]'", '/',
    ) if @missing;
    return _failure(
        'VIAL_EXECUTION_INVOCATION_ERROR', 'invocation',
        'semantic_ir must be an exact FSM::VIAL::SemanticIR object', '/semantic_ir',
    ) unless blessed($raw->{semantic_ir})
        && ref($raw->{semantic_ir}) eq 'FSM::VIAL::SemanticIR';
    return _failure(
        'VIAL_CAPABILITY_ERROR', 'capability',
        'version-2 execution requires VIAL SemanticIR version 2', '/semantic_ir',
    ) unless $raw->{semantic_ir}->language_version == 2;
    return _failure(
        'VIAL_CAPABILITY_ERROR', 'capability',
        "execution profile must be $PROFILE", '/execution_profile',
    ) unless defined($raw->{execution_profile})
        && !ref($raw->{execution_profile}) && $raw->{execution_profile} eq $PROFILE;

    my $semantic = $raw->{semantic_ir}->as_hashref;
    my $family_negotiation = negotiate_vial_semantic_family_requirements({
        stage => 'planner',
        profile_id => $PROFILE,
        source_language_version => 2,
        execution_schema => undef,
        execution_profile => $PROFILE,
        requirements => vial_family_requirements_from_semantic_ir($semantic),
    });
    return _failure(
        'VIAL_FAMILY_UNSUPPORTED', 'capability',
        vial_semantic_family_negotiation_message($family_negotiation),
        '/semantic_ir/packages',
    ) unless $family_negotiation->{accepted};

    my $v1_semantic = $raw->{semantic_ir}->_v1_base_projection;
    my $base = _clone($raw);
    $base->{semantic_ir} = $v1_semantic;
    $base->{execution_profile} = 'core_directed_single_clock_execution_v1';
    require FSM::VIAL::ExecutionBuilder;
    my $built = FSM::VIAL::ExecutionBuilder->build($base);
    return _upgrade_failure($built) unless $built->{ok};

    my $data = $built->{execution_ir}->as_hashref;
    $data->{schema} = 'fsmgen.vial_execution_ir.v2';
    $data->{schema_version} = 2;
    $data->{profile} = $PROFILE;
    $data->{semantic_identity} = {
        semantic_ir_id => 'semantic/' . sha256_hex(_canonical_json($semantic)),
        schema_version => 2,
        profile => $semantic->{profile},
        root_source_name => $semantic->{root_source}{source_name},
        root_content_sha256 => $semantic->{root_source}{content_sha256},
        selected_fixture_id => $data->{fixture}{fixture_id},
    };
    my $bridge = $raw->{bridge_manifest}->as_hashref;
    $data->{semantic_families} = build_vial_lifecycle_execution_records({
        semantic => $semantic, execution => $data, bridge => $bridge,
    });
    $data->{capability_ledger} = _v2_capability_ledger(
        $data->{capability_ledger}, $data->{semantic_families},
    );
    $data->{resource_summary}{semantic_family_nodes}
        = scalar(@{$data->{semantic_families}});
    my $identity = _clone($data);
    delete $identity->{plan_id};
    delete $identity->{diagnostics};
    $data->{plan_id} = 'plan/' . sha256_hex(_canonical_json($identity));

    require FSM::VIAL::ExecutionIR;
    my $execution_ir = FSM::VIAL::ExecutionIR->_from_builder($data);
    require FSM::VIAL::ExecutionReport;
    my $plan = FSM::VIAL::ExecutionReport->build($execution_ir);
    return {
        ok => JSON::PP::true,
        execution_ir => $execution_ir,
        plan => $plan,
        diagnostics => [],
    };
}

sub _v2_capability_ledger {
    my ($records, $families) = @_;
    my @result = map {
        my $record = _clone($_);
        my $replacement = $CAPABILITY_REPLACEMENT{$record->{capability_id}};
        $record->{capability_id} = $replacement if defined $replacement;
        $record;
    } @{$records};
    push @result, {
        capability_id => 'vial.semantic_family_envelope.v2',
        origins => ['execution_profile'],
        classification => 'satisfied_by_execution_profile',
        portable_class => 'portable',
        evidence_ids => ['execution_profile'],
    };
    my %present = map { $_->{capability_id} => 1 } @result;
    my %evidence;
    for my $family (@{$families}) {
        push @{$evidence{$_}}, $family->{semantic}{semantic_id}
            for @{$family->{required_capabilities}};
    }
    for my $capability (sort keys %evidence) {
        next if $present{$capability}++;
        my %seen;
        push @result, {
            capability_id => $capability,
            origins => ['semantic_family'],
            classification => 'satisfied_by_execution_profile',
            portable_class => 'portable',
            evidence_ids => [grep { !$seen{$_}++ } @{$evidence{$capability}}],
        };
    }
    return [sort { $a->{capability_id} cmp $b->{capability_id} } @result];
}

sub _upgrade_failure {
    my ($result) = @_;
    my $copy = _clone($result);
    for my $diagnostic (@{$copy->{diagnostics}}) {
        $diagnostic->{schema} = 'fsmgen.vial_execution_diagnostic.v2';
        $diagnostic->{schema_version} = 2;
    }
    return $copy;
}

sub _failure {
    my ($code, $phase, $message, $path, $source_location) = @_;
    $message =~ s/[\r\n]+/ /g;
    return {
        ok => JSON::PP::false,
        execution_ir => undef,
        plan => undef,
        diagnostics => [{
            schema => 'fsmgen.vial_execution_diagnostic.v2',
            schema_version => 2,
            severity => 'error',
            code => $code,
            phase => $phase,
            message => $message,
            semantic_path => $path,
            source_location => _clone($source_location),
            bridge_fact_paths => [],
            related => [],
        }],
    };
}

sub _sanitize_exception {
    my ($error) = @_;
    my $message = defined($error) ? "$error" : 'unknown execution failure';
    $message =~ s/\s+at\s+\S+\s+line\s+\d+\.?\s*\z//s;
    $message =~ s{(?:[A-Za-z]:)?[/\\][^\s:]+[/\\][^\s:]+}{<host-path>}g;
    $message =~ s/[\r\n]+/ /g;
    $message =~ s/\s+/ /g;
    $message =~ s/\A\s+|\s+\z//g;
    return length($message) ? $message : 'unknown execution failure';
}

sub _canonical_json {
    return JSON::PP->new->canonical->utf8->encode($_[0]);
}

sub _clone {
    my ($value) = @_;
    return undef unless defined $value;
    return $value ? JSON::PP::true : JSON::PP::false
        if blessed($value) && $value->isa('JSON::PP::Boolean');
    return $value if blessed($value);
    my $type = ref($value) ? (reftype($value) || '') : '';
    return {map { $_ => _clone($value->{$_}) } sort keys %{$value}}
        if $type eq 'HASH';
    return [map { _clone($_) } @{$value}] if $type eq 'ARRAY';
    die "VIAL v2 execution wrapper received unsupported reference type '$type'\n"
        if ref($value);
    return $value;
}

1;
