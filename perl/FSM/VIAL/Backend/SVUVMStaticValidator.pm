package FSM::VIAL::Backend::SVUVMStaticValidator;

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

my $BACKEND_PROFILE = 'sv_uvm_emit.accellera_2020_3_1';
my @RESULT_KEYS = qw(
    ok status backend_profile validator_schema checks artifacts diagnostics
);
my @ARTIFACT_KEYS = qw(
    relpath kind language role content encoding source_layer generated_from
);
my @REQUIRED_SOURCE_ROLES = qw(
    generated_hial_dut uvm_types_package uvm_component_foundations
    uvm_fixture_interface uvm_fixture_package uvm_fixture_top
);

sub result_keys($class) {
    confess __PACKAGE__ . "->result_keys requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return [@RESULT_KEYS];
}

sub validate($class, @args) {
    return _failure('VIAL_UVM_STATIC_INVOCATION_ERROR', 'validate requires the exact validator class invocant', '/')
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return _failure('VIAL_UVM_STATIC_INVOCATION_ERROR', 'validate expects one closed argument hash', '/')
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);

    my $result = eval { _validate($args[0]) };
    return $result if defined $result;
    return _failure('VIAL_UVM_STATIC_HOST_ERROR', _sanitize_exception($@), '/');
}

sub _validate($raw) {
    _require_exact_keys($raw, [qw(backend_profile artifacts)], 'static validation');
    confess "backend_profile must be '$BACKEND_PROFILE'"
        unless defined($raw->{backend_profile}) && !ref($raw->{backend_profile})
            && $raw->{backend_profile} eq $BACKEND_PROFILE;
    confess 'artifacts must be a non-empty array'
        unless ref($raw->{artifacts}) eq 'ARRAY' && @{$raw->{artifacts}};

    my (@diagnostics, @checks, @reports);
    my (%by_role, %by_path);
    my $total_bytes = 0;
    my $artifact_shape_ok = 1;
    for my $index (0 .. $#{$raw->{artifacts}}) {
        my $artifact = $raw->{artifacts}[$index];
        if (ref($artifact) ne 'HASH' || blessed($artifact)) {
            _diagnose(\@diagnostics, 'VIAL_UVM_STATIC_ARTIFACT_ERROR',
                "artifact $index must be one unblessed hash", "/artifacts/$index");
            $artifact_shape_ok = 0;
            next;
        }
        my $closed = eval { _require_exact_keys($artifact, \@ARTIFACT_KEYS, "artifact $index"); 1 };
        if (!$closed) {
            _diagnose(\@diagnostics, 'VIAL_UVM_STATIC_ARTIFACT_ERROR',
                _sanitize_exception($@), "/artifacts/$index");
            $artifact_shape_ok = 0;
            next;
        }
        if (!_safe_relpath($artifact->{relpath})
                || !defined($artifact->{role}) || ref($artifact->{role})
                || !defined($artifact->{content}) || ref($artifact->{content})
                || ($artifact->{encoding} // '') ne 'utf-8'
                || ref($artifact->{generated_from}) ne 'ARRAY') {
            _diagnose(\@diagnostics, 'VIAL_UVM_STATIC_ARTIFACT_ERROR',
                "artifact $index has an unsafe or malformed field", "/artifacts/$index");
            $artifact_shape_ok = 0;
            next;
        }
        if ($by_path{$artifact->{relpath}}++) {
            _diagnose(\@diagnostics, 'VIAL_UVM_STATIC_ARTIFACT_ERROR',
                "duplicate artifact path '$artifact->{relpath}'", "/artifacts/$index/relpath");
            $artifact_shape_ok = 0;
        }
        push @{$by_role{$artifact->{role}}}, $artifact;
        my $bytes = bytes::length($artifact->{content});
        $total_bytes += $bytes;
        push @reports, {
            relpath => $artifact->{relpath},
            role => $artifact->{role},
            bytes => $bytes,
            sha256 => sha256_hex($artifact->{content}),
        };
    }
    _record_check(\@checks, 'closed_safe_artifact_graph', $artifact_shape_ok);

    my $required_roles_ok = 1;
    for my $role (@REQUIRED_SOURCE_ROLES) {
        next if ref($by_role{$role}) eq 'ARRAY' && @{$by_role{$role}} == 1;
        _diagnose(\@diagnostics, 'VIAL_UVM_STATIC_REQUIRED_ROLE_ERROR',
            "required source role '$role' must occur exactly once", '/artifacts');
        $required_roles_ok = 0;
    }
    _record_check(\@checks, 'required_source_roles', $required_roles_ok);

    my $limits_ok = @{$raw->{artifacts}} <= 64 && $total_bytes <= 16_777_216;
    _diagnose(\@diagnostics, 'VIAL_UVM_STATIC_LIMIT_EXCEEDED',
        'static validation input exceeds 64 artifacts or 16 MiB', '/artifacts')
        unless $limits_ok;
    _record_check(\@checks, 'bounded_input', $limits_ok);

    my $text_shape_ok = 1;
    my $neutrality_ok = 1;
    my $balanced_ok = 1;
    my %text_by_role;
    for my $role (@REQUIRED_SOURCE_ROLES) {
        next unless ref($by_role{$role}) eq 'ARRAY' && @{$by_role{$role}} == 1;
        my $artifact = $by_role{$role}[0];
        my $text = $artifact->{content};
        $text_by_role{$role} = $text;
        my $uvm_text_shape_error = $role ne 'generated_hial_dut'
            && ($text =~ /\t/ || $text =~ /[ \t]+\r?$/m);
        if ($text !~ /\n\z/ || $uvm_text_shape_error
                || $text =~ /__FSMGEN_[A-Z0-9_]+__/) {
            _diagnose(\@diagnostics, 'VIAL_UVM_STATIC_TEXT_SHAPE_ERROR',
                "'$artifact->{relpath}' violates deterministic text-shape rules",
                "/artifacts/$artifact->{relpath}");
            $text_shape_ok = 0;
        }
        if ($text =~ /\b(?:xcelium|irun|vcs|questa|modelsim|verilator|iverilog|nexsim)\b/i
                || $text =~ m{(?:\A|[\s"'])(?:/tmp/|/private/tmp/|/Users/|[A-Za-z]:\\)}) {
            _diagnose(\@diagnostics, 'VIAL_UVM_STATIC_PROVIDER_LEAK',
                "'$artifact->{relpath}' contains provider-specific or host-path text",
                "/artifacts/$artifact->{relpath}");
            $neutrality_ok = 0;
        }
        my @pairs = (
            [qw(package endpackage)], [qw(interface endinterface)],
            [qw(class endclass)], [qw(module endmodule)],
            [qw(function endfunction)], [qw(task endtask)],
        );
        for my $pair (@pairs) {
            next if _construct_count($text, $pair->[0]) == _construct_count($text, $pair->[1]);
            _diagnose(\@diagnostics, 'VIAL_UVM_STATIC_BALANCE_ERROR',
                "'$artifact->{relpath}' has unbalanced $pair->[0]/$pair->[1] tokens",
                "/artifacts/$artifact->{relpath}");
            $balanced_ok = 0;
        }
    }
    _record_check(\@checks, 'deterministic_text_shape', $text_shape_ok);
    _record_check(\@checks, 'simulator_neutral_source', $neutrality_ok);
    _record_check(\@checks, 'balanced_generated_constructs', $balanced_ok);

    my @shape = (
        [uvm_types_package => qr/\bpackage\s+fsmgen_vial_uvm_types_pkg\s*;/,
            'types package declaration'],
        [uvm_types_package => qr/`uvm_object_utils\b/,
            'UVM object registration'],
        [uvm_component_foundations => qr/\bpackage\s+fsmgen_vial_uvm_components_pkg\s*;/,
            'component package declaration'],
        [uvm_component_foundations => qr/`uvm_component_utils\b/,
            'UVM component registration'],
        [uvm_fixture_interface => qr/\binterface\s+[a-z_][a-z0-9_]*_if\s*;/i,
            'fixture interface declaration'],
        [uvm_fixture_interface => qr/\bclocking\s+(?:driver|monitor)_cb\b/,
            'clocking block declaration'],
        [uvm_fixture_interface => qr/\bmodport\s+(?:driver|monitor)_mp\b/,
            'modport declaration'],
        [uvm_fixture_package => qr/\buvm_config_db\s*#\s*\(\s*virtual\b/,
            'typed virtual-interface configuration'],
        [uvm_fixture_top => qr/\buvm_config_db\s*#\s*\(\s*virtual\b/,
            'top-level virtual-interface publication'],
        [uvm_fixture_top => qr/\brun_test\s*\(/,
            'top-level UVM test selection'],
    );
    my $uvm_shape_ok = 1;
    for my $requirement (@shape) {
        my ($role, $pattern, $label) = @$requirement;
        next if defined($text_by_role{$role}) && $text_by_role{$role} =~ $pattern;
        _diagnose(\@diagnostics, 'VIAL_UVM_STATIC_SHAPE_ERROR',
            "generated source is missing $label", "/roles/$role");
        $uvm_shape_ok = 0;
    }
    _record_check(\@checks, 'selected_uvm_foundation_shape', $uvm_shape_ok);

    @reports = sort { $a->{relpath} cmp $b->{relpath} } @reports;
    my $ok = !@diagnostics;
    return _result({
        ok => $ok ? JSON::PP::true : JSON::PP::false,
        status => $ok ? 'passed' : 'rejected',
        backend_profile => $BACKEND_PROFILE,
        validator_schema => 'fsmgen.vial_uvm_static_validation.v1',
        checks => \@checks,
        artifacts => \@reports,
        diagnostics => \@diagnostics,
    });
}

sub _record_check($checks, $check_id, $passed) {
    push @$checks, {
        check_id => $check_id,
        status => $passed ? 'passed' : 'failed',
    };
}

sub _diagnose($diagnostics, $code, $message, $path) {
    push @$diagnostics, {
        code => $code,
        severity => 'error',
        message => $message,
        path => $path,
    };
}

sub _construct_count($text, $token) {
    my $copy = "$text";
    return scalar(() = $copy =~ /^\s*\Q$token\E\b/gm)
        if $token =~ /\Aend/ || $token =~ /\A(?:package|interface|module)\z/;
    return scalar(() = $copy =~ /^\s*(?:virtual\s+)?\Q$token\E\b/gm)
        if $token eq 'class';
    return scalar(() = $copy =~ /^\s*(?:(?:pure\s+)?virtual\s+|static\s+)?\Q$token\E\b/gm);
}

sub _safe_relpath($value) {
    return 0 unless defined($value) && !ref($value) && length($value);
    return 0 if $value =~ m{(?:\A/|\A~|\A[A-Za-z]:|://|\\|\x00)};
    return !grep { $_ eq '' || $_ eq '.' || $_ eq '..' } split m{/}, $value, -1;
}

sub _require_exact_keys($value, $keys, $label) {
    my %expected = map { $_ => 1 } @$keys;
    my @unknown = sort grep { !$expected{$_} } keys %$value;
    my @missing = grep { !exists($value->{$_}) } @$keys;
    confess "$label has unknown key '$unknown[0]'" if @unknown;
    confess "$label is missing key '$missing[0]'" if @missing;
}

sub _failure($code, $message, $path) {
    return _result({
        ok => JSON::PP::false,
        status => 'error',
        backend_profile => $BACKEND_PROFILE,
        validator_schema => 'fsmgen.vial_uvm_static_validation.v1',
        checks => [],
        artifacts => [],
        diagnostics => [{code => $code, severity => 'error', message => $message, path => $path}],
    });
}

sub _result($value) {
    my %expected = map { $_ => 1 } @RESULT_KEYS;
    confess 'static validator result has unknown key(s)'
        if grep { !$expected{$_} } keys %$value;
    confess 'static validator result is missing key(s)'
        if grep { !exists($value->{$_}) } @RESULT_KEYS;
    return _clone($value);
}

sub _sanitize_exception($error) {
    my $message = defined($error) ? "$error" : 'unknown static-validator host failure';
    $message =~ s/\s+at\s+\S+\s+line\s+\d+\.?\s*\z//s;
    $message =~ s{(?:[A-Za-z]:)?[/\\][^\s:]+[/\\][^\s:]+}{<host-path>}g;
    $message =~ s/[\r\n]+/ /g;
    $message =~ s/\s+/ /g;
    $message =~ s/\A\s+|\s+\z//g;
    return length($message) ? $message : 'unknown static-validator host failure';
}

sub _clone($value) {
    return undef unless defined $value;
    return $value ? JSON::PP::true : JSON::PP::false
        if blessed($value) && $value->isa('JSON::PP::Boolean');
    return {map { $_ => _clone($value->{$_}) } sort keys %$value}
        if ref($value) eq 'HASH';
    return [map { _clone($_) } @$value] if ref($value) eq 'ARRAY';
    confess 'static validator result contains unsupported reference data' if ref($value);
    return $value;
}

1;
