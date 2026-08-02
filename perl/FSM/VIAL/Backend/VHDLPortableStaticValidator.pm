package FSM::VIAL::Backend::VHDLPortableStaticValidator;

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

my $BACKEND_PROFILE = 'vhdl_portable_ghdl';
my @RESULT_KEYS = qw(
    ok status backend_profile validator_schema checks artifacts diagnostics
);
my @ARTIFACT_KEYS = qw(
    relpath kind language role content encoding source_layer generated_from
);
my @REQUIRED_SOURCE_ROLES = qw(
    generated_hial_vhdl_dut vhdl_types_package vhdl_runtime_package
    vhdl_fixture_metadata vhdl_fixture_top vhdl_probe_adapter
);

sub result_keys($class) {
    confess __PACKAGE__ . "->result_keys requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return [@RESULT_KEYS];
}

sub validate($class, @args) {
    return _failure('VIAL_VHDL_STATIC_INVOCATION_ERROR',
        'validate requires the exact validator class invocant', '/')
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return _failure('VIAL_VHDL_STATIC_INVOCATION_ERROR',
        'validate expects one closed argument hash', '/')
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);

    my $result = eval { _validate($args[0]) };
    return $result if defined $result;
    return _failure('VIAL_VHDL_STATIC_HOST_ERROR', _sanitize_exception($@), '/');
}

sub _validate($raw) {
    _require_exact_keys($raw, [qw(backend_profile artifacts)], 'static validation');
    confess "backend_profile must be '$BACKEND_PROFILE'"
        unless defined($raw->{backend_profile}) && !ref($raw->{backend_profile})
            && $raw->{backend_profile} eq $BACKEND_PROFILE;
    confess 'artifacts must be a non-empty array'
        unless ref($raw->{artifacts}) eq 'ARRAY' && @{$raw->{artifacts}};

    my (@checks, @diagnostics, @reports);
    my (%by_path, %by_role);
    my ($shape_ok, $text_ok, $provider_neutral) = (1, 1, 1);
    my $total_bytes = 0;
    for my $index (0 .. $#{$raw->{artifacts}}) {
        my $artifact = $raw->{artifacts}[$index];
        if (ref($artifact) ne 'HASH' || blessed($artifact)) {
            _diagnose(\@diagnostics, 'VIAL_VHDL_STATIC_ARTIFACT_ERROR',
                "artifact $index must be one unblessed hash", "/artifacts/$index");
            $shape_ok = 0;
            next;
        }
        my $closed = eval {
            _require_exact_keys($artifact, \@ARTIFACT_KEYS, "artifact $index");
            1;
        };
        if (!$closed || !_safe_relpath($artifact->{relpath})
                || ($artifact->{language} // '') ne 'vhdl'
                || ($artifact->{encoding} // '') ne 'utf-8'
                || !defined($artifact->{role}) || ref($artifact->{role})
                || !defined($artifact->{content}) || ref($artifact->{content})
                || ref($artifact->{generated_from}) ne 'ARRAY') {
            _diagnose(\@diagnostics, 'VIAL_VHDL_STATIC_ARTIFACT_ERROR',
                $closed ? "artifact $index has an unsafe or malformed field"
                    : _sanitize_exception($@),
                "/artifacts/$index");
            $shape_ok = 0;
            next;
        }
        if ($by_path{$artifact->{relpath}}++) {
            _diagnose(\@diagnostics, 'VIAL_VHDL_STATIC_ARTIFACT_ERROR',
                "duplicate artifact path '$artifact->{relpath}'",
                "/artifacts/$index/relpath");
            $shape_ok = 0;
        }
        push @{$by_role{$artifact->{role}}}, $artifact;
        my $content = $artifact->{content};
        my $bytes = bytes::length($content);
        $total_bytes += $bytes;
        push @reports, {
            relpath => $artifact->{relpath},
            role => $artifact->{role},
            bytes => $bytes,
            sha256 => sha256_hex($content),
        };
        if ($content !~ /\n\z/ || $content =~ /\r|\t|[ \t]+$/m
                || $content =~ /__FSMGEN_[A-Z0-9_]+__/) {
            _diagnose(\@diagnostics, 'VIAL_VHDL_STATIC_TEXT_SHAPE_ERROR',
                "'$artifact->{relpath}' violates deterministic text-shape rules",
                "/artifacts/$index/content");
            $text_ok = 0;
        }
        if ($content =~ /\b(?:ghdl|osvvm|uvvm|xcelium|nvc|modelsim|questa|riviera|activehdl)\b/i
                || $content =~ m{(?:\A|[\s"'])(?:/tmp/|/private/tmp/|/Users/|[A-Za-z]:\\)}) {
            _diagnose(\@diagnostics, 'VIAL_VHDL_STATIC_PROVIDER_LEAK',
                "'$artifact->{relpath}' contains provider-specific or host-path text",
                "/artifacts/$index/content");
            $provider_neutral = 0;
        }
    }
    _record_check(\@checks, 'closed_safe_vhdl_source_graph', $shape_ok);

    my $roles_ok = 1;
    for my $role (@REQUIRED_SOURCE_ROLES) {
        next if ref($by_role{$role}) eq 'ARRAY' && @{$by_role{$role}} == 1;
        _diagnose(\@diagnostics, 'VIAL_VHDL_STATIC_REQUIRED_ROLE_ERROR',
            "required source role '$role' must occur exactly once", '/artifacts');
        $roles_ok = 0;
    }
    _record_check(\@checks, 'required_vhdl_source_roles', $roles_ok);

    my $bounded = @{$raw->{artifacts}} <= 32 && $total_bytes <= 16_777_216;
    _diagnose(\@diagnostics, 'VIAL_VHDL_STATIC_LIMIT_EXCEEDED',
        'static validation input exceeds 32 artifacts or 16 MiB', '/artifacts')
        unless $bounded;
    _record_check(\@checks, 'bounded_static_input', $bounded);
    _record_check(\@checks, 'deterministic_vhdl_text_shape', $text_ok);
    _record_check(\@checks, 'simulator_and_methodology_neutral_vhdl', $provider_neutral);

    my %text = map {
        my $role = $_;
        $role => (ref($by_role{$role}) eq 'ARRAY' && @{$by_role{$role}} == 1
            ? $by_role{$role}[0]{content} : '')
    } @REQUIRED_SOURCE_ROLES;
    my @required_shape = (
        [vhdl_types_package => qr/\bpackage\s+fsmgen_vial_types_pkg\s+is\b/i,
            'types package'],
        [vhdl_types_package => qr/\btype\s+vial_value_symbol_t\s+is\s*\(/i,
            'typed value-symbol enumeration'],
        [vhdl_types_package => qr/\bfunction\s+normalize_vial_value\s*\(/i,
            'four-state normalization function'],
        [vhdl_runtime_package => qr/\bpackage\s+fsmgen_vial_runtime_pkg\s+is\b/i,
            'runtime package'],
        [vhdl_runtime_package => qr/\btype\s+vial_logical_time_t\s+is\s+record\b/i,
            'typed logical-time record'],
        [vhdl_runtime_package => qr/\btype\s+vial_fiber_status_t\s+is\s*\(/i,
            'bounded fiber status'],
        [vhdl_runtime_package => qr/\btype\s+vial_scenario_status_t\s+is\s*\(/i,
            'bounded scenario status'],
        [vhdl_fixture_metadata => qr/\bpackage\s+[a-z][a-z0-9_]*_metadata_pkg\s+is\b/i,
            'fixture metadata package'],
        [vhdl_fixture_top => qr/\bentity\s+[a-z][a-z0-9_]*_tb\s+is\b/i,
            'fixture testbench entity'],
        [vhdl_fixture_top => qr/\bdut\s*:\s*entity\s+work\.[a-z][a-z0-9_]*\s*\(\s*rtl\s*\)/i,
            'direct HIAL DUT binding'],
        [vhdl_fixture_top => qr/\bport\s+map\s*\(/i,
            'named DUT port map'],
        [vhdl_fixture_top => qr/^\s*vial_scheduler\s*:\s*process\b/mi,
            'semantic scheduler process'],
        [vhdl_probe_adapter => qr/^architecture\s+declared_external_names\s+of\s+[a-z][a-z0-9_]*\s+is/mi,
            'declared probe-adapter architecture'],
    );
    my $semantics_ok = 1;
    for my $requirement (@required_shape) {
        my ($role, $pattern, $label) = @$requirement;
        next if $text{$role} =~ $pattern;
        _diagnose(\@diagnostics, 'VIAL_VHDL_STATIC_SEMANTIC_SHAPE_ERROR',
            "generated source is missing $label", "/roles/$role");
        $semantics_ok = 0;
    }
    _record_check(\@checks, 'selected_vhdl_portable_semantic_shape', $semantics_ok);

    my $normalization_ok = $text{vhdl_types_package} =~ /when\s+'0'\s*=>\s*return\s+VIAL_VALUE_0/i
        && $text{vhdl_types_package} =~ /when\s+'1'\s*=>\s*return\s+VIAL_VALUE_1/i
        && $text{vhdl_types_package} =~ /when\s+'Z'\s*=>\s*return\s+VIAL_VALUE_Z/i
        && $text{vhdl_types_package} =~ /when\s+'L'\s*=>\s*return\s+VIAL_VALUE_0/i
        && $text{vhdl_types_package} =~ /when\s+'H'\s*=>\s*return\s+VIAL_VALUE_1/i
        && $text{vhdl_types_package} =~ /when\s+others\s*=>\s*return\s+VIAL_VALUE_X/i;
    _diagnose(\@diagnostics, 'VIAL_VHDL_STATIC_NORMALIZATION_ERROR',
        'types package does not close the selected std_logic normalization table',
        '/roles/vhdl_types_package') unless $normalization_ok;
    _record_check(\@checks, 'closed_std_logic_normalization', $normalization_ok);

    my $typed_io_ok = $text{vhdl_types_package} =~ /\bprocedure\s+drive_vial_value\s*\(/i
        && $text{vhdl_types_package} =~ /\bprocedure\s+drive_vial_vector\s*\(/i
        && $text{vhdl_types_package} =~ /\bfunction\s+observe_vial_value\s*\(/i
        && $text{vhdl_types_package} =~ /\bfunction\s+observe_vial_vector\s*\(/i
        && $text{vhdl_types_package} =~ /original_symbol\s*:\s*std_logic/i
        && _count_matches($text{vhdl_fixture_top}, qr/^\s*signal\s+[a-z][a-z0-9_]*\s*:/mi)
            == _count_matches($text{vhdl_fixture_top}, qr/:=\s*observe_vial_vector\s*\(/mi)
        && _count_matches($text{vhdl_fixture_top}, qr/\bdrive_vial_(?:value|vector)\s*\(/mi) >= 4;
    _diagnose(\@diagnostics, 'VIAL_VHDL_STATIC_TYPED_IO_ERROR',
        'typed drivers and original-symbol samplers do not cover the generated fixture signals',
        '/roles/vhdl_fixture_top') unless $typed_io_ok;
    _record_check(\@checks, 'typed_four_state_drivers_and_samplers', $typed_io_ok);

    my @process_label = $text{vhdl_fixture_top}
        =~ /^\s*([a-z][a-z0-9_]*)\s*:\s*process\b/gmi;
    my $inactive = _string_constant($text{vhdl_fixture_metadata}, 'VIAL_INACTIVE_EDGE');
    my $scheduler_ok = @process_label == 2
        && join(',', sort @process_label) eq 'vial_clock_generator,vial_scheduler'
        && _count_matches($text{vhdl_fixture_top}, qr/^\s*vial_scheduler\s*:\s*process\b/mi) == 1
        && _count_matches($text{vhdl_fixture_top}, qr/^\s*procedure\s+vial_inactive_barrier\s+is\b/mi) == 1
        && _count_matches($text{vhdl_fixture_top}, qr/\bwait\s+until\s+(?:rising_edge|falling_edge)\s*\(/mi) == 1
        && defined($inactive)
        && $text{vhdl_fixture_top} =~ /\bwait\s+until\s+\Q$inactive\E_edge\s*\(/i
        && _natural_constant($text{vhdl_fixture_metadata}, 'VIAL_SCHEDULER_COUNT') == 1
        && $text{vhdl_fixture_top} !~ /\b(?:wait\s+for\s+0\s+ns|after|transport|postponed)\b/i
        && $text{vhdl_fixture_top} !~ /\bprocess\s*\(\s*all\s*\)/i;
    _diagnose(\@diagnostics, 'VIAL_VHDL_STATIC_SCHEDULER_AUTHORITY_ERROR',
        'portable semantics require one inactive-edge scheduler and forbid delta/process-order authority',
        '/roles/vhdl_fixture_top') unless $scheduler_ok;
    _record_check(\@checks, 'single_inactive_edge_semantic_authority', $scheduler_ok);

    my @phase_marker = map {
        index($text{vhdl_fixture_top}, "-- FSMGEN VIAL PHASE: $_")
    } qw(SAMPLE REACT CHECK DRIVE);
    my $phase_ok = !(grep { $_ < 0 } @phase_marker)
        && $phase_marker[0] < $phase_marker[1]
        && $phase_marker[1] < $phase_marker[2]
        && $phase_marker[2] < $phase_marker[3]
        && _count_matches($text{vhdl_fixture_top}, qr/-- FSMGEN VIAL PHASE: (?:SAMPLE|REACT|CHECK|DRIVE)/m) == 4;
    _diagnose(\@diagnostics, 'VIAL_VHDL_STATIC_PHASE_ORDER_ERROR',
        'logical SAMPLE/REACT/CHECK/DRIVE markers are missing, duplicated, or unstable',
        '/roles/vhdl_fixture_top') unless $phase_ok;
    _record_check(\@checks, 'stable_sample_react_check_drive_order', $phase_ok);

    my $operation_count = _natural_constant($text{vhdl_fixture_metadata}, 'VIAL_OPERATION_COUNT');
    my $scenario_count = _natural_constant($text{vhdl_fixture_metadata}, 'VIAL_SCENARIO_COUNT');
    my $fiber_count = _natural_constant($text{vhdl_fixture_metadata}, 'VIAL_FIBER_COUNT');
    my $model_count = _natural_constant($text{vhdl_fixture_metadata}, 'VIAL_MODEL_COUNT');
    my $metadata_ok = defined($operation_count) && $operation_count >= 1
        && $operation_count <= 65_536
        && defined($scenario_count) && $scenario_count >= 1 && $scenario_count <= 1_024
        && defined($fiber_count) && $fiber_count >= 1 && $fiber_count <= 4_096
        && defined($model_count) && $model_count >= 0 && $model_count <= 4_096
        && _count_matches($text{vhdl_fixture_metadata}, qr/^\s*constant\s+VIAL_OPERATION_[0-9]+_ID\s*:/mi) == $operation_count
        && _count_matches($text{vhdl_fixture_metadata}, qr/^\s*constant\s+VIAL_OPERATION_[0-9]+_KIND\s*:/mi) == $operation_count
        && _count_matches($text{vhdl_fixture_metadata}, qr/^\s*constant\s+VIAL_OPERATION_[0-9]+_STATIC_RANK\s*:/mi) == $operation_count
        && _count_matches($text{vhdl_fixture_metadata}, qr/^\s*constant\s+VIAL_OPERATION_[0-9]+_FIBER_ID\s*:/mi) == $operation_count
        && _count_matches($text{vhdl_fixture_metadata}, qr/^\s*constant\s+VIAL_SCENARIO_[0-9]+_ID\s*:/mi) == $scenario_count
        && _count_matches($text{vhdl_fixture_metadata}, qr/^\s*constant\s+VIAL_FIBER_[0-9]+_ID\s*:/mi) == $fiber_count
        && _count_matches($text{vhdl_fixture_top}, qr/^\s*variable\s+vial_fiber_[0-9]+_status\s*:/mi) == $fiber_count;
    if ($metadata_ok) {
        for my $index (0 .. $operation_count - 1) {
            my $tag = sprintf('%02d', $index);
            my ($comment_kind, $comment_rank) = $text{vhdl_fixture_metadata}
                =~ /^\s*-- VIAL operation \Q$tag\E:\s+([a-z_]+)\s+at static rank ([0-9]+)\s*$/mi;
            my ($constant_kind) = $text{vhdl_fixture_metadata}
                =~ /^\s*constant\s+VIAL_OPERATION_\Q$tag\E_KIND\s*:\s*string\s*:=\s*"([a-z_]+)"\s*;/mi;
            my ($constant_rank) = $text{vhdl_fixture_metadata}
                =~ /^\s*constant\s+VIAL_OPERATION_\Q$tag\E_STATIC_RANK\s*:\s*natural\s*:=\s*([0-9]+)\s*;/mi;
            if (!defined($comment_kind) || !defined($comment_rank)
                    || !defined($constant_kind) || !defined($constant_rank)
                    || $comment_kind ne $constant_kind
                    || $comment_rank != $constant_rank) {
                $metadata_ok = 0;
                last;
            }
        }
    }
    _diagnose(\@diagnostics, 'VIAL_VHDL_STATIC_METADATA_ERROR',
        'operation ranks or bounded scenario/fiber metadata are incomplete or inconsistent',
        '/roles/vhdl_fixture_metadata') unless $metadata_ok;
    _record_check(\@checks, 'complete_rank_scenario_and_fiber_metadata', $metadata_ok);

    my $model_ok = defined($model_count)
        && _count_matches($text{vhdl_fixture_metadata}, qr/^\s*constant\s+VIAL_MODEL_[0-9]+_INSTANCE_ID\s*:/mi) == $model_count
        && _count_matches($text{vhdl_fixture_metadata}, qr/^\s*constant\s+VIAL_MODEL_[0-9]+_TRIGGER_EVENT_ID\s*:/mi) == $model_count
        && _count_matches($text{vhdl_fixture_top}, qr/^\s*variable\s+vial_model_[0-9]+_count\s*:/mi) == $model_count
        && _count_matches($text{vhdl_fixture_top}, qr/^\s*-- VIAL model update [0-9]+:/mi) == $model_count
        && $text{vhdl_fixture_top} !~ /\b(?:random|uniform|shared\s+variable)\b/i;
    _diagnose(\@diagnostics, 'VIAL_VHDL_STATIC_MODEL_ERROR',
        'deterministic model declarations and updates do not match metadata',
        '/roles/vhdl_fixture_top') unless $model_ok;
    _record_check(\@checks, 'deterministic_model_state_and_updates', $model_ok);

    my ($top_name) = $text{vhdl_fixture_top}
        =~ /^\s*entity\s+([a-z][a-z0-9_]*)\s+is\b/mi;
    my $probe_ok = defined($top_name)
        && _count_matches($text{vhdl_probe_adapter}, qr/^\s*-- VIAL declared probe\s+/mi) >= 1
        && _count_matches($text{vhdl_probe_adapter}, qr/<<\s*signal\s+/mi)
            == _count_matches($text{vhdl_probe_adapter}, qr/^\s*-- VIAL declared probe\s+/mi);
    my $combined_non_adapter = join("\n", map { $text{$_} }
        grep { $_ ne 'vhdl_probe_adapter' } @REQUIRED_SOURCE_ROLES);
    $probe_ok = 0 if $combined_non_adapter =~ /<<\s*signal\s+/i;
    my $parsed_probe = 0;
    while ($text{vhdl_probe_adapter} =~ /^\s*-- VIAL declared probe\s+(\S+)\s+maps to\s+([A-Za-z][A-Za-z0-9_]*)\s*\n\s*alias\s+([A-Za-z][A-Za-z0-9_]*)\s*:[^\n]+\s+is\s*\n\s*<<\s*signal\s+\.([A-Za-z][A-Za-z0-9_]*)\.dut\.([A-Za-z][A-Za-z0-9_]*)\s*:/gmi) {
        $parsed_probe++;
        $probe_ok = 0 unless $2 eq $5 && lc($4) eq lc($top_name);
    }
    $probe_ok = 0 unless $parsed_probe
        == _count_matches($text{vhdl_probe_adapter}, qr/^\s*-- VIAL declared probe\s+/mi);
    _diagnose(\@diagnostics, 'VIAL_VHDL_STATIC_PROBE_ADAPTER_ERROR',
        'probe hierarchy must occur only in source-mapped declared adapters',
        '/roles/vhdl_probe_adapter') unless $probe_ok;
    _record_check(\@checks, 'declared_source_mapped_probe_adapters', $probe_ok);

    my $ok = !@diagnostics;
    return {
        ok => $ok ? JSON::PP::true : JSON::PP::false,
        status => $ok ? 'passed' : 'failed',
        backend_profile => $BACKEND_PROFILE,
        validator_schema => 'fsmgen.vial_vhdl_static_validation.v1',
        checks => \@checks,
        artifacts => [sort { $a->{relpath} cmp $b->{relpath} } @reports],
        diagnostics => \@diagnostics,
    };
}

sub _record_check($checks, $name, $passed) {
    push @$checks, {check => $name, status => $passed ? 'passed' : 'failed'};
}

sub _count_matches($text, $pattern) {
    return scalar(() = $text =~ /$pattern/g);
}

sub _natural_constant($text, $name) {
    my @value = $text =~ /^\s*constant\s+\Q$name\E\s*:\s*natural\s*:=\s*([0-9]+)\s*;/gmi;
    return undef unless @value == 1;
    return 0 + $value[0];
}

sub _string_constant($text, $name) {
    my @value = $text =~ /^\s*constant\s+\Q$name\E\s*:\s*string\s*:=\s*"([^"]*)"\s*;/gmi;
    return undef unless @value == 1;
    return $value[0];
}

sub _diagnose($diagnostics, $code, $message, $path) {
    push @$diagnostics, {
        code => $code,
        severity => 'error',
        message => $message,
        path => $path,
    };
}

sub _safe_relpath($value) {
    return 0 unless defined($value) && !ref($value) && length($value);
    return 0 if $value =~ m{(?:\A/|\A~|\A[A-Za-z]:|://|\\|\x00)};
    my @part = split m{/}, $value, -1;
    return !grep { $_ eq '' || $_ eq '.' || $_ eq '..' } @part;
}

sub _require_exact_keys($value, $keys, $label) {
    confess "$label must be one unblessed hash"
        unless ref($value) eq 'HASH' && !blessed($value);
    my %expected = map { $_ => 1 } @$keys;
    my @unknown = sort grep { !$expected{$_} } keys %$value;
    my @missing = grep { !exists($value->{$_}) } @$keys;
    confess "$label has unknown key '$unknown[0]'" if @unknown;
    confess "$label is missing key '$missing[0]'" if @missing;
}

sub _sanitize_exception($error) {
    my $message = defined($error) ? "$error" : 'unknown static-validation failure';
    $message =~ s/\s+at\s+\S+\s+line\s+\d+\.?\s*\z//s;
    $message =~ s/[\r\n]+/ /g;
    $message =~ s/\s+/ /g;
    $message =~ s/\A\s+|\s+\z//g;
    return length($message) ? $message : 'unknown static-validation failure';
}

sub _failure($code, $message, $path) {
    return {
        ok => JSON::PP::false,
        status => 'error',
        backend_profile => $BACKEND_PROFILE,
        validator_schema => 'fsmgen.vial_vhdl_static_validation.v1',
        checks => [],
        artifacts => [],
        diagnostics => [{
            code => $code,
            severity => 'error',
            message => $message,
            path => $path,
        }],
    };
}

1;
