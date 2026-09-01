#!/usr/bin/env perl

use strict;
use warnings;

use Digest::SHA qw(sha256_hex);
use JSON::PP ();
use Test::More;

use lib 'perl';

use FSM::VIAL::Backend::GHDLLifecycle;

my $JSON = JSON::PP->new->canonical(1);

subtest 'portable authority and selected version objects are rebound' => sub {
    ok(FSM::VIAL::Backend::GHDLLifecycle->can(
        '_validate_authority_objects'),
        'authority-object admission seam exists') or return;

    my $authority = {
        schema => 'fsmgen.vial_ghdl_lifecycle.v1',
        schema_version => 1,
        role => 'qualification',
    };
    my $selected_version = 'GHDL selected version';
    ok(validated_provider($selected_version),
        'selected provider version without a trailing line ending admits');
    rejects_provider_version("$selected_version\n");
    my %payload = (
        lifecycle_authority => canonical_line($authority),
        tool_version_output => "$selected_version\n",
    );
    my $session = {
        authority => $authority,
        role => 'qualification',
        provider => {version_output => $selected_version},
        commands => {},
    };

    with_payloads(\%payload, sub {
        ok(validate_authority($session, record(
            'tool_verified', \%payload,
            qw(lifecycle_authority tool_version_output),
        )), 'exact portable authority and selected version admit');

        local $payload{lifecycle_authority} = canonical_line({
            %$authority,
            role => 'architecture_scale_measurement',
        });
        rejects_authority($session, record(
            'tool_verified', \%payload,
            qw(lifecycle_authority tool_version_output),
        ), 'foreign canonical lifecycle authority rejects');

        local $payload{lifecycle_authority} = canonical_line($authority);
        local $payload{tool_version_output} = "GHDL foreign version\n";
        rejects_authority($session, record(
            'tool_verified', \%payload,
            qw(lifecycle_authority tool_version_output),
        ), 'foreign tool-version transcript rejects');

        local $payload{tool_version_output} = "$selected_version\n\n";
        rejects_authority($session, record(
            'tool_verified', \%payload,
            qw(lifecycle_authority tool_version_output),
        ), 'noncanonical selected-version transcript rejects');
    });
};

subtest 'OSVVM generated-settings object is rebound when prepared' => sub {
    my $authority = {
        schema => 'fsmgen.vial_ghdl_lifecycle.v2',
        schema_version => 2,
        role => 'osvvm_qualification',
    };
    my $settings = "package OsvvmScriptSettingsPkg is\nend package;\n";
    my %payload = (
        lifecycle_authority => canonical_line($authority),
        generated_settings => $settings,
    );
    my $session = {
        authority => $authority,
        role => 'osvvm_qualification',
        provider => {version_output => 'GHDL selected version'},
        commands => {generated_settings => {content => $settings}},
    };

    with_payloads(\%payload, sub {
        ok(validate_authority($session, record(
            'prepared', \%payload,
            qw(lifecycle_authority generated_settings),
        )), 'exact OSVVM settings object admits');

        local $payload{generated_settings} =
            "package OsvvmScriptSettingsPkg is\nconstant FOREIGN : boolean := true;\nend package;\n";
        rejects_authority($session, record(
            'prepared', \%payload,
            qw(lifecycle_authority generated_settings),
        ), 'foreign generated-settings object rejects');
    });
};

done_testing();

sub with_payloads {
    my ($payload, $code) = @_;
    no warnings 'redefine';
    local *FSM::VIAL::Backend::GHDLLifecycle::_object_content_from = sub {
        my ($ignored_session, $ignored_objects, $kind) = @_;
        die "unexpected focused object '$kind'\n"
            unless exists $payload->{$kind};
        return $payload->{$kind};
    };
    $code->();
}

sub validate_authority {
    my ($session, $record) = @_;
    return eval {
        FSM::VIAL::Backend::GHDLLifecycle::_validate_authority_objects(
            $session, $record,
        );
        1;
    } ? 1 : 0;
}

sub rejects_authority {
    my ($session, $record, $label) = @_;
    my $ok = eval {
        FSM::VIAL::Backend::GHDLLifecycle::_validate_authority_objects(
            $session, $record,
        );
        1;
    };
    ok(!$ok, $label);
    isa_ok($@, 'FSM::VIAL::Backend::GHDLLifecycle::Failure');
    is(ref($@) ? $@->{code} : undef,
        'VIAL_GHDL_LIFECYCLE_STATE_ERROR',
        "$label uses state-admission authority");
}

sub record {
    my ($state, $payload, @kind) = @_;
    return {
        state => $state,
        objects => [map { object($_, $payload->{$_}) } @kind],
    };
}

sub object {
    my ($kind, $content) = @_;
    my $digest = sha256_hex($content);
    return {
        kind => $kind,
        sha256 => $digest,
        bytes => length($content),
        executable => JSON::PP::false,
        relative_path => ".artifacts/tmp/tests/objects/$digest",
    };
}

sub canonical_line {
    return $JSON->encode($_[0]) . "\n";
}

sub validated_provider {
    my ($version_output) = @_;
    my $digest = '0' x 64;
    return eval {
        FSM::VIAL::Backend::GHDLLifecycle::_validated_provider(
            '.', 0,
            {
                root => '.artifacts/tmp/tests/provider',
                archive => '.artifacts/tmp/tests/provider/archive.tar',
                archive_bytes => 1,
                archive_sha256 => $digest,
                binary => '.artifacts/tmp/tests/provider/bin/ghdl',
                binary_sha256 => $digest,
                version_output => $version_output,
            },
            0,
        );
        1;
    } ? 1 : 0;
}

sub rejects_provider_version {
    my ($version_output) = @_;
    my $ok = validated_provider($version_output);
    ok(!$ok, 'selected provider version with a trailing line ending rejects');
    isa_ok($@, 'FSM::VIAL::Backend::GHDLLifecycle::Failure');
    is(ref($@) ? $@->{code} : undef,
        'VIAL_GHDL_LIFECYCLE_INVOCATION_ERROR',
        'non-normalized selected version uses invocation authority');
}
