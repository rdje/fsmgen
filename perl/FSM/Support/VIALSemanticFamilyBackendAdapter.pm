package FSM::Support::VIALSemanticFamilyBackendAdapter;

use strict;
use warnings;

use Digest::SHA qw(sha256_hex);
use Exporter 'import';
use JSON::PP ();
use Scalar::Util qw(blessed reftype);

use FSM::Support::VIALSemanticFamilyRegistry qw(
    build_vial_semantic_family_registry
    negotiate_vial_semantic_family_requirements
    vial_family_requirements_from_execution_ir
);

our @EXPORT_OK = qw(
    build_vial_semantic_family_backend_adapter_registry
    preflight_vial_semantic_family_backend_adapter
    vial_semantic_family_backend_adapter_registry_keys
);

my @REGISTRY_KEYS = qw(
    schema schema_version registry_id status contract_source adapter_keys
    maturity_keys maturity_levels adapters explicit_nonclaims
);
my @ADAPTER_KEYS = qw(
    profile_id implementation target_language target_mechanism ir_boundary
    accepted_execution_schemas accepted_execution_profiles backend_schema
    source_map_schema artifact_model maturity
);
my @MATURITY_KEYS = qw(emission compile runtime result parity public);
my @MATURITY_LEVELS = qw(unavailable selected implemented qualified);
my @PREFLIGHT_KEYS = qw(
    schema schema_version adapter_registry_id profile_id accepted adapter
    required satisfied unsatisfied issues
);

sub vial_semantic_family_backend_adapter_registry_keys {
    return [@REGISTRY_KEYS];
}

sub build_vial_semantic_family_backend_adapter_registry {
    my @adapters = (
        {
            profile_id => 'sv_portable_verilator',
            implementation => 'FSM::VIAL::Backend::SVPortableVerilator',
            target_language => 'IEEE_SystemVerilog',
            target_mechanism => 'portable_static_scheduler_and_Verilator_5_046',
            ir_boundary => 'FSM::VIAL::ExecutionIR',
            accepted_execution_schemas => ['fsmgen.vial_execution_ir.v1'],
            accepted_execution_profiles => [
                'core_directed_single_clock_execution_v1',
            ],
            backend_schema => 'fsmgen.vial_backend.sv_portable_verilator.v1',
            source_map_schema => 'fsmgen.vial_backend_source_map.v1',
            artifact_model => 'deterministic_in_memory_graph_atomic_publication',
            maturity => {
                emission => 'qualified', compile => 'qualified',
                runtime => 'qualified', result => 'qualified',
                parity => 'qualified', public => 'qualified',
            },
        },
        {
            profile_id => 'sv_uvm_emit.accellera_2020_3_1',
            implementation => 'FSM::VIAL::Backend::SVUVMAccellera2020_3_1',
            target_language => 'IEEE_SystemVerilog_UVM',
            target_mechanism => 'simulator_neutral_Accellera_UVM_2020_3_1',
            ir_boundary => 'FSM::VIAL::ExecutionIR',
            accepted_execution_schemas => ['fsmgen.vial_execution_ir.v1'],
            accepted_execution_profiles => [
                'core_directed_single_clock_execution_v1',
            ],
            backend_schema =>
                'fsmgen.vial_backend.sv_uvm_emit.accellera_2020_3_1.v1',
            source_map_schema => 'fsmgen.vial_uvm_backend_source_map.v1',
            artifact_model => 'deterministic_in_memory_review_graph_atomic_publication',
            maturity => {
                emission => 'implemented', compile => 'unavailable',
                runtime => 'unavailable', result => 'unavailable',
                parity => 'unavailable', public => 'unavailable',
            },
        },
        {
            profile_id => 'vhdl_osvvm_qualified',
            implementation => 'FSM::VIAL::Backend::VHDLOSVVM2026_05',
            target_language => 'IEEE_VHDL_2008_OSVVM',
            target_mechanism => 'OSVVM_2026_05_over_provider_free_VHDL_core',
            ir_boundary => 'FSM::VIAL::ExecutionIR',
            accepted_execution_schemas => ['fsmgen.vial_execution_ir.v1'],
            accepted_execution_profiles => [
                'core_directed_single_clock_execution_v1',
            ],
            backend_schema => 'fsmgen.vial_backend.vhdl_osvvm.v1',
            source_map_schema => 'fsmgen.vial_vhdl_osvvm_source_map.v1',
            artifact_model => 'deterministic_in_memory_graph_atomic_publication',
            maturity => {
                emission => 'qualified', compile => 'qualified',
                runtime => 'qualified', result => 'qualified',
                parity => 'qualified', public => 'unavailable',
            },
        },
        {
            profile_id => 'vhdl_portable_ghdl',
            implementation => 'FSM::VIAL::Backend::VHDLPortableGHDL',
            target_language => 'IEEE_VHDL_2008',
            target_mechanism => 'provider_free_VHDL_core_and_GHDL_6_0_0',
            ir_boundary => 'FSM::VIAL::ExecutionIR',
            accepted_execution_schemas => ['fsmgen.vial_execution_ir.v1'],
            accepted_execution_profiles => [
                'core_directed_single_clock_execution_v1',
            ],
            backend_schema => 'fsmgen.vial_backend.vhdl_portable.v1',
            source_map_schema => 'fsmgen.vial_vhdl_backend_source_map.v1',
            artifact_model => 'deterministic_in_memory_graph_atomic_publication',
            maturity => {
                emission => 'qualified', compile => 'qualified',
                runtime => 'qualified', result => 'qualified',
                parity => 'qualified', public => 'unavailable',
            },
        },
    );
    my $registry = {
        schema => 'fsmgen.vial_semantic_family_backend_adapter_registry.v1',
        schema_version => 1,
        registry_id => undef,
        status => 'v1_routes_registered_v2_family_support_unavailable',
        contract_source => __PACKAGE__,
        adapter_keys => [@ADAPTER_KEYS],
        maturity_keys => [@MATURITY_KEYS],
        maturity_levels => [@MATURITY_LEVELS],
        adapters => \@adapters,
        explicit_nonclaims => [qw(
            family_emission family_compile family_runtime family_result
            family_parity public_v2_tooling target_mechanism_in_semantic_ir
        )],
    };
    my $identity = _clone($registry);
    $identity->{registry_id} = undef;
    $registry->{registry_id} = 'vial-backend-adapters/'
        . sha256_hex(_canonical_json($identity));
    return _validate_registry($registry);
}

sub preflight_vial_semantic_family_backend_adapter {
    my ($args) = @_;
    _plain_hash($args, 'backend-adapter preflight');
    _exact_hash($args, [qw(profile_id execution_ir)],
        'backend-adapter preflight');
    _identifier($args->{profile_id}, 'backend profile_id');
    die "backend-adapter preflight requires an exact FSM::VIAL::ExecutionIR object\n"
        unless blessed($args->{execution_ir})
            && ref($args->{execution_ir}) eq 'FSM::VIAL::ExecutionIR';

    my $registry = build_vial_semantic_family_backend_adapter_registry();
    my ($adapter) = grep {
        $_->{profile_id} eq $args->{profile_id}
    } @{$registry->{adapters}};
    my $execution = $args->{execution_ir}->as_hashref;
    my (@shape_required, @shape_satisfied, @shape_unsupported, @shape_issues);
    my $version = $execution->{schema_version};
    my $shape_requirement = 'execution_ir:typed_versioned';
    push @shape_required, $shape_requirement;
    if (defined($version) && !ref($version) && $version =~ /\A[12]\z/
        && ($execution->{schema} // '') eq "fsmgen.vial_execution_ir.v$version"
        && ($execution->{profile} // '')
            eq "core_directed_single_clock_execution_v$version"
        && (($version == 1 && !exists($execution->{semantic_families}))
            || ($version == 2
                && ref($execution->{semantic_families}) eq 'ARRAY'
                && !blessed($execution->{semantic_families})))) {
        push @shape_satisfied, $shape_requirement;
    }
    else {
        push @shape_unsupported, $shape_requirement;
        push @shape_issues, {
            kind => 'execution_ir_version',
            requirement => $shape_requirement,
            message => 'ExecutionIR schema, profile, version, and family carrier are inconsistent',
        };
    }

    my ($requirements, $carrier_error);
    {
        local $@;
        my $ok = eval {
            $requirements =
                vial_family_requirements_from_execution_ir($execution);
            1;
        };
        $carrier_error = $@ unless $ok;
    }
    my $negotiation;
    if (defined $carrier_error) {
        my $requirement = 'family_registry:valid_execution_family_carrier';
        push @shape_required, $requirement;
        push @shape_unsupported, $requirement;
        $carrier_error = _sanitize_exception($carrier_error);
        push @shape_issues, {
            kind => 'invalid_execution_family_carrier',
            requirement => $requirement,
            message => $carrier_error,
        };
        $requirements = [];
    }
    else {
        $negotiation = negotiate_vial_semantic_family_requirements({
            stage => 'emitter',
            profile_id => $args->{profile_id},
            source_language_version => undef,
            execution_schema => $execution->{schema},
            execution_profile => $execution->{profile},
            requirements => $requirements,
        });
    }
    my @required = (@shape_required,
        $negotiation ? @{$negotiation->{required}} : ());
    my @satisfied = (@shape_satisfied,
        $negotiation ? @{$negotiation->{satisfied}} : ());
    my @unsatisfied = (@shape_unsupported,
        $negotiation ? @{$negotiation->{unsupported}} : ());
    my @issues = (@shape_issues,
        $negotiation ? @{$negotiation->{issues}} : ());
    my %unsatisfied = map { $_ => 1 } @unsatisfied;
    @satisfied = grep { !$unsatisfied{$_} } @satisfied;
    my $result = {
        schema => 'fsmgen.vial_semantic_family_backend_preflight.v1',
        schema_version => 1,
        adapter_registry_id => $registry->{registry_id},
        profile_id => $args->{profile_id},
        accepted => $adapter && !@issues ? JSON::PP::true : JSON::PP::false,
        adapter => $adapter ? _clone($adapter) : undef,
        required => [sort(_unique(@required))],
        satisfied => [sort(_unique(@satisfied))],
        unsatisfied => [sort(_unique(@unsatisfied))],
        issues => \@issues,
    };
    _exact_hash($result, \@PREFLIGHT_KEYS, 'backend-adapter preflight result');
    return _clone($result);
}

sub _validate_registry {
    my ($registry) = @_;
    _exact_hash($registry, \@REGISTRY_KEYS, 'backend-adapter registry');
    die "backend-adapter registry schema is invalid\n"
        unless $registry->{schema}
                eq 'fsmgen.vial_semantic_family_backend_adapter_registry.v1'
            && $registry->{schema_version} == 1;
    my $identity = _clone($registry);
    $identity->{registry_id} = undef;
    die "backend-adapter registry identity is not content-derived\n"
        unless $registry->{registry_id} eq 'vial-backend-adapters/'
            . sha256_hex(_canonical_json($identity));

    my $family_registry = build_vial_semantic_family_registry();
    my %backend_profile = map {
        $_->{profile_kind} eq 'backend' ? ($_->{profile_id} => $_) : ()
    } @{$family_registry->{profiles}};
    my (%adapter, %level) = ();
    $level{$_} = 1 for @MATURITY_LEVELS;
    for my $entry (@{$registry->{adapters}}) {
        _exact_hash($entry, \@ADAPTER_KEYS, 'backend adapter');
        _identifier($entry->{profile_id}, 'backend adapter profile_id');
        die "backend adapter profile is duplicated\n"
            if $adapter{$entry->{profile_id}}++;
        my $profile = $backend_profile{$entry->{profile_id}}
            or die "backend adapter profile is absent from the family registry\n";
        die "backend adapter profile does not own emission\n"
            unless grep { $_ eq 'emitter' } @{$profile->{stages}};
        _class_name($entry->{implementation}, 'backend adapter implementation');
        _class_name($entry->{ir_boundary}, 'backend adapter IR boundary');
        for my $key (qw(
            target_language target_mechanism backend_schema source_map_schema
            artifact_model
        )) {
            _identifier($entry->{$key}, "backend adapter $key");
        }
        _sorted_identifiers($entry->{accepted_execution_schemas},
            'backend adapter execution schemas');
        _sorted_identifiers($entry->{accepted_execution_profiles},
            'backend adapter execution profiles');
        die "backend adapter execution schemas contradict the family registry\n"
            unless _canonical_json($entry->{accepted_execution_schemas})
                eq _canonical_json($profile->{accepted_execution_schemas});
        die "backend adapter execution profiles contradict the family registry\n"
            unless _canonical_json($entry->{accepted_execution_profiles})
                eq _canonical_json($profile->{accepted_execution_profiles});
        _exact_hash($entry->{maturity}, \@MATURITY_KEYS,
            'backend adapter maturity');
        die "backend adapter maturity level is invalid\n"
            if grep { !$level{$entry->{maturity}{$_}} } @MATURITY_KEYS;
    }
    die "backend adapter profile set is incomplete\n"
        unless join("\0", sort keys %adapter)
            eq join("\0", sort keys %backend_profile);
    return _clone($registry);
}

sub _sorted_identifiers {
    my ($values, $label) = @_;
    die "$label must be an unblessed array\n"
        unless ref($values) eq 'ARRAY' && !blessed($values);
    my @copy = map {
        _identifier($_, $label);
        $_;
    } @{$values};
    my @sorted = sort @copy;
    die "$label must be sorted and unique\n"
        unless _canonical_json(\@copy) eq _canonical_json(\@sorted)
            && @sorted == _unique(@sorted);
}

sub _identifier {
    my ($value, $label) = @_;
    die "$label is invalid\n"
        unless defined($value) && !ref($value)
            && $value =~ /\A[A-Za-z][A-Za-z0-9_.-]*\z/
            && length($value) <= 192;
}

sub _class_name {
    my ($value, $label) = @_;
    die "$label is invalid\n"
        unless defined($value) && !ref($value)
            && $value =~ /\A[A-Za-z][A-Za-z0-9_]*(?:::[A-Za-z][A-Za-z0-9_]*)+\z/
            && length($value) <= 192;
}

sub _plain_hash {
    my ($value, $label) = @_;
    die "$label must be one unblessed hash\n"
        unless ref($value) eq 'HASH' && !blessed($value);
}

sub _exact_hash {
    my ($value, $keys, $label) = @_;
    _plain_hash($value, $label);
    my %expected = map { $_ => 1 } @{$keys};
    my @unknown = sort grep { !$expected{$_} } keys %{$value};
    my @missing = grep { !exists($value->{$_}) } @{$keys};
    die "$label has unknown key '$unknown[0]'\n" if @unknown;
    die "$label is missing key '$missing[0]'\n" if @missing;
}

sub _sanitize_exception {
    my ($error) = @_;
    my $message = defined($error) ? "$error" : 'invalid family carrier';
    $message =~ s/\s+at\s+\S+\s+line\s+\d+\.?\s*\z//s;
    $message =~ s/[\r\n]+/ /g;
    $message =~ s/\s+/ /g;
    $message =~ s/\A\s+|\s+\z//g;
    return length($message) ? $message : 'invalid family carrier';
}

sub _unique {
    my %seen;
    return grep { !$seen{$_}++ } @_;
}

sub _canonical_json {
    return JSON::PP->new->canonical->utf8->encode($_[0]);
}

sub _clone {
    my ($value) = @_;
    return undef unless defined $value;
    return $value ? JSON::PP::true : JSON::PP::false
        if blessed($value) && $value->isa('JSON::PP::Boolean');
    my $type = ref($value) ? (reftype($value) || '') : '';
    return {map { $_ => _clone($value->{$_}) } sort keys %{$value}}
        if $type eq 'HASH';
    return [map { _clone($_) } @{$value}] if $type eq 'ARRAY';
    die "backend-adapter contract contains unsupported reference type '$type'\n"
        if ref($value);
    return $value;
}

1;
