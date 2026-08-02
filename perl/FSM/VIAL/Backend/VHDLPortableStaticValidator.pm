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
    vhdl_fixture_metadata vhdl_fixture_top
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
        [vhdl_fixture_metadata => qr/\bpackage\s+[a-z][a-z0-9_]*_metadata_pkg\s+is\b/i,
            'fixture metadata package'],
        [vhdl_fixture_top => qr/\bentity\s+[a-z][a-z0-9_]*_tb\s+is\b/i,
            'fixture testbench entity'],
        [vhdl_fixture_top => qr/\bdut\s*:\s*entity\s+work\.[a-z][a-z0-9_]*\s*\(\s*rtl\s*\)/i,
            'direct HIAL DUT binding'],
        [vhdl_fixture_top => qr/\bport\s+map\s*\(/i,
            'named DUT port map'],
    );
    my $foundation_ok = 1;
    for my $requirement (@required_shape) {
        my ($role, $pattern, $label) = @$requirement;
        next if $text{$role} =~ $pattern;
        _diagnose(\@diagnostics, 'VIAL_VHDL_STATIC_FOUNDATION_ERROR',
            "generated source is missing $label", "/roles/$role");
        $foundation_ok = 0;
    }
    _record_check(\@checks, 'selected_vhdl_foundation_shape', $foundation_ok);

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
