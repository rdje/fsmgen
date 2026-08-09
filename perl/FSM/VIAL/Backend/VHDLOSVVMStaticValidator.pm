package FSM::VIAL::Backend::VHDLOSVVMStaticValidator;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use JSON::PP ();
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

my $SCHEMA = 'fsmgen.vial_vhdl_osvvm_static_validation.v1';
my @RESULT_KEYS = qw(ok status schema schema_version checks diagnostics);

sub result_keys($class) {
    _exact_class($class, 'result_keys');
    return [@RESULT_KEYS];
}

sub validate($class, @args) {
    return _failure('VIAL_OSVVM_STATIC_INVOCATION_ERROR',
        'validate requires the exact validator class invocant', '/')
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return _failure('VIAL_OSVVM_STATIC_INVOCATION_ERROR',
        'validate expects one closed argument hash', '/')
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    my $result = eval { _validate($args[0]) };
    return $result if defined $result;
    my $error = $@ || 'unknown OSVVM static-validation error';
    $error =~ s/\s+\z//;
    return _failure('VIAL_OSVVM_STATIC_HOST_ERROR', $error, '/');
}

sub _validate($raw) {
    _require_keys($raw, [qw(
        artifacts materialization mapping_matrix semantic_preservation
    )]);
    confess "artifacts must be one array\n"
        unless ref($raw->{artifacts}) eq 'ARRAY';
    confess "materialization must be one unblessed hash\n"
        unless ref($raw->{materialization}) eq 'HASH'
            && !blessed($raw->{materialization});
    confess "mapping_matrix must be one unblessed hash\n"
        unless ref($raw->{mapping_matrix}) eq 'HASH'
            && !blessed($raw->{mapping_matrix});
    confess "semantic_preservation must be one unblessed hash\n"
        unless ref($raw->{semantic_preservation}) eq 'HASH'
            && !blessed($raw->{semantic_preservation});

    my @checks;
    my %role;
    for my $artifact (@{$raw->{artifacts}}) {
        confess "OSVVM static artifact must be one unblessed hash\n"
            unless ref($artifact) eq 'HASH' && !blessed($artifact);
        confess "OSVVM static artifact role is absent\n"
            unless defined($artifact->{role}) && !ref($artifact->{role});
        confess "OSVVM static artifact role '$artifact->{role}' is duplicated\n"
            if $role{$artifact->{role}}++;
    }
    my ($adapter) = grep { $_->{role} eq 'vhdl_osvvm_adapter_package' }
        @{$raw->{artifacts}};
    return _rejected('VIAL_OSVVM_STATIC_ADAPTER_ERROR',
        'exactly one OSVVM adapter package is required', '/artifacts')
        unless $adapter && defined($adapter->{content}) && !ref($adapter->{content});
    push @checks, _check('one_adapter', $adapter->{relpath});

    my $provider = $raw->{materialization};
    return _rejected('VIAL_OSVVM_STATIC_PROVIDER_IDENTITY_ERROR',
        'provider materialization is not the exact complete OSVVM 2026.05 graph',
        '/materialization')
        unless ($provider->{schema} // '') eq 'fsmgen.vial_osvvm_materialization.v1'
            && ($provider->{version} // '') eq '2026.05'
            && ($provider->{root_commit} // '')
                eq '2f7c391051dfb11890fa4bdbda9918d1db492250'
            && ref($provider->{repositories}) eq 'ARRAY'
            && @{$provider->{repositories}} == 14
            && ref($provider->{recursive_gitlinks}) eq 'ARRAY'
            && @{$provider->{recursive_gitlinks}} == 13
            && ref($provider->{license_notice_files}) eq 'ARRAY'
            && @{$provider->{license_notice_files}} == 14
            && ($provider->{license_notice_summary}{notice_file_count} // -1) == 0;
    return _rejected('VIAL_OSVVM_STATIC_PROVIDER_LICENCE_ERROR',
        'the exact Documentation no-licence/no-notice finding must remain explicit',
        '/materialization/license_notice_summary')
        unless ref($provider->{license_notice_summary}
                {repositories_without_tracked_license_or_notice}) eq 'ARRAY'
            && @{$provider->{license_notice_summary}
                {repositories_without_tracked_license_or_notice}} == 1
            && $provider->{license_notice_summary}
                {repositories_without_tracked_license_or_notice}[0] eq 'Documentation'
            && !$provider->{license_notice_summary}{inferred_license_coverage};
    push @checks, _check('exact_recursive_provider_identity',
        '14 repositories; 13 gitlinks; 14 licence files; 0 notice files');

    my $text = $adapter->{content};
    my @token_check = (
        ['provider_context', 'library osvvm;', 'context osvvm.OsvvmContext;'],
        ['randomization', 'osvvm.RandomPkg.RandomPType', '.Uniform(minimum, maximum)'],
        ['coverage', 'osvvm.CoveragePkg.CoverageIDType', 'osvvm.CoveragePkg.ICover'],
        ['scoreboard', 'osvvm.ScoreboardGenericPkg', 'osvvm.ScoreboardPkg_slv.Check'],
        ['reporting', 'osvvm.AlertLogPkg.AffirmIf'],
        ['synchronization', 'osvvm.TbUtilPkg.BarrierType',
            'osvvm.TbUtilPkg.WaitForBarrier'],
        ['data_structure', 'osvvm.MemoryPkg.MemoryIDType', 'osvvm.MemoryPkg.MemWrite'],
        ['verification_component', 'library osvvm_common;',
            'osvvm_common.AddressBusTransactionPkg.AddressBusRecType'],
    );
    for my $check (@token_check) {
        my ($id, @token) = @$check;
        my @missing = grep { index($text, $_) < 0 } @token;
        return _rejected('VIAL_OSVVM_STATIC_MAPPING_ERROR',
            "adapter mapping '$id' is missing exact token '$missing[0]'",
            '/artifacts/vhdl_osvvm_adapter_package') if @missing;
        push @checks, _check("adapter_$id", join(', ', @token));
    }

    my $matrix = $raw->{mapping_matrix};
    my @mapping = @{$matrix->{mappings} || []};
    return _rejected('VIAL_OSVVM_STATIC_MAPPING_MATRIX_ERROR',
        'advanced mapping matrix must contain seven exact mappings', '/mapping_matrix')
        unless ($matrix->{schema} // '') eq 'fsmgen.vial_vhdl_osvvm_mapping_matrix.v1'
            && @mapping == 7;
    my @mapping_id = map { $_->{mapping_id} // '' } @mapping;
    return _rejected('VIAL_OSVVM_STATIC_MAPPING_MATRIX_ERROR',
        'advanced mapping identities must be unique and sorted', '/mapping_matrix/mappings')
        unless join("\0", @mapping_id) eq join("\0", sort @mapping_id)
            && keys(%{{map { $_ => 1 } @mapping_id}}) == @mapping_id;
    for my $mapping (@mapping) {
        return _rejected('VIAL_OSVVM_STATIC_MAPPING_MATRIX_ERROR',
            "mapping '$mapping->{mapping_id}' overstates qualification",
            '/mapping_matrix/mappings')
            unless ($mapping->{emission_status} // '') eq 'emitted'
                && ($mapping->{static_status} // '') eq 'passed'
                && ($mapping->{qualification_status} // '') eq 'not_run';
    }
    push @checks, _check('closed_mapping_matrix', '7 emitted/static-only mappings');

    my $preservation = $raw->{semantic_preservation};
    my @portable = @{$preservation->{portable_sources} || []};
    return _rejected('VIAL_OSVVM_STATIC_SEMANTIC_PRESERVATION_ERROR',
        'semantic preservation must cover six byte-identical portable sources',
        '/semantic_preservation')
        unless ($preservation->{schema} // '')
                eq 'fsmgen.vial_vhdl_osvvm_semantic_preservation.v1'
            && @portable == 6
            && !grep { !$_->{byte_identical}
                || ($_->{portable_sha256} // '') ne ($_->{advanced_sha256} // '') }
                @portable;
    for my $artifact (@{$raw->{artifacts}}) {
        next unless ($artifact->{role} // '') =~ /\Aportable_/;
        return _rejected('VIAL_OSVVM_STATIC_SEMANTIC_PRESERVATION_ERROR',
            "portable role '$artifact->{role}' contains provider API text",
            '/artifacts')
            if ($artifact->{content} // '') =~ /\bosvvm(?:_common)?\b/i;
    }
    return _rejected('VIAL_OSVVM_STATIC_SEMANTIC_PRESERVATION_ERROR',
        'semantic-authority guards are incomplete', '/semantic_preservation/guards')
        unless ref($preservation->{guards}) eq 'HASH'
            && $preservation->{guards}{portable_random_replay_unchanged}
            && $preservation->{guards}{phase_order_unchanged}
            && $preservation->{guards}{comparison_semantics_unchanged}
            && $preservation->{guards}{coverage_semantics_unchanged}
            && $preservation->{guards}{closed_trace_unchanged}
            && $preservation->{guards}{normalized_result_unchanged};
    push @checks, _check('portable_semantic_authority',
        '6 byte-identical sources and 6 explicit unchanged guards');

    return {
        ok => JSON::PP::true,
        status => 'passed_structural_only',
        schema => $SCHEMA,
        schema_version => 1,
        checks => \@checks,
        diagnostics => [],
    };
}

sub _check($check_id, $evidence) {
    return {check_id => $check_id, status => 'passed', evidence => $evidence};
}

sub _rejected($code, $message, $path) {
    return {
        ok => JSON::PP::false,
        status => 'rejected',
        schema => $SCHEMA,
        schema_version => 1,
        checks => [],
        diagnostics => [{code => $code, message => $message, path => $path}],
    };
}

sub _failure($code, $message, $path) {
    return {
        ok => JSON::PP::false,
        status => 'failed',
        schema => $SCHEMA,
        schema_version => 1,
        checks => [],
        diagnostics => [{code => $code, message => $message, path => $path}],
    };
}

sub _require_keys($value, $expected) {
    my $actual = join("\0", sort keys %$value);
    my $wanted = join("\0", sort @$expected);
    confess "static-validation invocation key set is not closed\n"
        unless $actual eq $wanted;
}

sub _exact_class($class, $method) {
    confess __PACKAGE__ . "->$method requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
}

1;
