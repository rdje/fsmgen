#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Extension::Loader;
use FSM::Pipeline::HDLGenerator;
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::ExtensionContract qw(build_extension_contract);

my $audit_test = 't/411-typed-extension-programmatic-entry-shape-boundary-audit.t';
my $module_name_shape = 'scalar Module::Name value';
my $config_file_path_shape = 'scalar non-empty extension config file path';
my $module_entry_error = qr/FSM::Extension::Loader expects extension module names to be scalar Module::Name values/s;
my $config_path_entry_error = qr/FSM::Extension::Loader expects extension config paths to be scalar non-empty filesystem paths/s;

subtest 'typed-extension manifests publish programmatic entry shapes' => sub {
    my @views = (
        {
            label => 'direct typed-extension contract',
            contract => build_extension_contract(),
        },
        {
            label => 'in-process capability manifest typed-extension contract',
            contract => build_capability_manifest()->{embedding}{typed_extensions},
        },
        {
            label => 'CLI capability manifest typed-extension contract',
            contract => run_capability_manifest('--capability-manifest')
                ->{embedding}{typed_extensions},
        },
        {
            label => 'CLI alias capability manifest typed-extension contract',
            contract => run_capability_manifest('--emit-capability-manifest')
                ->{embedding}{typed_extensions},
        },
    );

    for my $view (@views) {
        my $contract = $view->{contract};
        my $label = $view->{label};

        is(
            $contract->{extension_object_contract}{module_name_shape},
            $module_name_shape,
            "$label publishes the programmatic module-name entry shape",
        );
        is(
            $contract->{extension_object_contract}{config_file_path_shape},
            $config_file_path_shape,
            "$label publishes the programmatic config-file path entry shape",
        );
        ok(
            contains_value($contract->{tested_by}, $audit_test),
            "$label lists this programmatic entry-shape audit in tested_by provenance",
        );
        like(
            $contract->{entrypoints}{programmatic_modules} || '',
            qr/extension_modules\s*=>\s*\[\s*"Module::Name"/s,
            "$label keeps the programmatic module-loading entrypoint concrete",
        );
        like(
            $contract->{entrypoints}{programmatic_config_files} || '',
            qr/extension_config_files\s*=>\s*\[\s*"extensions\.fsmext"/s,
            "$label keeps the programmatic config-loading entrypoint concrete",
        );
    }
};

subtest 'loader rejects malformed programmatic module entries before loading' => sub {
    my $loader = FSM::Extension::Loader->new();

    for my $case (malformed_entry_cases()) {
        my $error = capture_exception(sub {
            $loader->load_modules([$case->{value}]);
        });

        like(
            $error,
            qr/Extension module:\s+'\Q$case->{context_label}\E'/s,
            "$case->{label}: error keeps non-stringifying module context",
        );
        like(
            $error,
            $module_entry_error,
            "$case->{label}: error reports the bounded module-name entry shape",
        );
        unlike(
            $error,
            qr/Unable to load extension module|Can't locate|strict refs|HASH\(|ARRAY\(|Use of uninitialized/s,
            "$case->{label}: module rejection does not leak require, stringification, or raw Perl fallout",
        );
    }
};

subtest 'pipeline rejects malformed programmatic module entries at construction' => sub {
    for my $case (
        {
            label => 'undef module entry',
            value => undef,
            context_label => '<missing>',
        },
        {
            label => 'hashref module entry',
            value => { module => 'FSM::BoundaryAudit::Marker' },
            context_label => '<non-scalar>',
        },
    ) {
        my $error = capture_exception(sub {
            FSM::Pipeline::HDLGenerator->new(
                debug_level => 0,
                target_language => 'systemverilog',
                strict_mode => 1,
                quiet => 1,
                extension_modules => [$case->{value}],
            );
        });

        like(
            $error,
            qr/Extension module:\s+'\Q$case->{context_label}\E'/s,
            "$case->{label}: pipeline error keeps bounded module context",
        );
        like(
            $error,
            $module_entry_error,
            "$case->{label}: pipeline reports the bounded module-name entry shape",
        );
        unlike(
            $error,
            qr/Unable to load extension module|Can't locate|strict refs|HASH\(|ARRAY\(|Use of uninitialized/s,
            "$case->{label}: pipeline rejection does not leak require, stringification, or raw Perl fallout",
        );
    }
};

subtest 'loader rejects malformed programmatic config-file entries before file checks' => sub {
    my $loader = FSM::Extension::Loader->new();

    for my $case (malformed_entry_cases()) {
        my $error = capture_exception(sub {
            $loader->module_names_from_config_files([$case->{value}]);
        });

        like(
            $error,
            qr/Extension config file:\s+'\Q$case->{context_label}\E'/s,
            "$case->{label}: error keeps non-stringifying config-file context",
        );
        like(
            $error,
            $config_path_entry_error,
            "$case->{label}: error reports the bounded config-file entry shape",
        );
        unlike(
            $error,
            qr/Extension config file not found|Cannot open extension config file|strict refs|HASH\(|ARRAY\(|Use of uninitialized/s,
            "$case->{label}: config-file rejection does not leak file-open, stringification, or raw Perl fallout",
        );
    }
};

subtest 'pipeline rejects malformed programmatic config-file entries at construction' => sub {
    for my $case (
        {
            label => 'blank config entry',
            value => '   ',
            context_label => '<blank>',
        },
        {
            label => 'arrayref config entry',
            value => ['extensions.fsmext'],
            context_label => '<non-scalar>',
        },
    ) {
        my $error = capture_exception(sub {
            FSM::Pipeline::HDLGenerator->new(
                debug_level => 0,
                target_language => 'systemverilog',
                strict_mode => 1,
                quiet => 1,
                extension_config_files => [$case->{value}],
            );
        });

        like(
            $error,
            qr/Extension config file:\s+'\Q$case->{context_label}\E'/s,
            "$case->{label}: pipeline error keeps bounded config-file context",
        );
        like(
            $error,
            $config_path_entry_error,
            "$case->{label}: pipeline reports the bounded config-file entry shape",
        );
        unlike(
            $error,
            qr/Extension config file not found|Cannot open extension config file|strict refs|HASH\(|ARRAY\(|Use of uninitialized/s,
            "$case->{label}: pipeline rejection does not leak file-open, stringification, or raw Perl fallout",
        );
    }
};

done_testing();

sub malformed_entry_cases {
    return (
        {
            label => 'undef entry',
            value => undef,
            context_label => '<missing>',
        },
        {
            label => 'empty-string entry',
            value => '',
            context_label => '<blank>',
        },
        {
            label => 'whitespace-only entry',
            value => '   ',
            context_label => '<blank>',
        },
        {
            label => 'arrayref entry',
            value => ['FSM::BoundaryAudit::Marker'],
            context_label => '<non-scalar>',
        },
        {
            label => 'hashref entry',
            value => { module => 'FSM::BoundaryAudit::Marker' },
            context_label => '<non-scalar>',
        },
    );
}

sub run_capability_manifest {
    my ($mode) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', $mode],
    );

    ok($success, "$mode succeeds");
    is(join('', @{$stderr_buf || []}), '', "$mode keeps stderr clean");

    return decode_json(join('', @{$stdout_buf || []}));
}

sub contains_value {
    my ($values, $wanted) = @_;
    return 0 unless ref($values) eq 'ARRAY';

    for my $value (@{$values}) {
        return 1 if defined($value) && $value eq $wanted;
    }

    return 0;
}

sub capture_exception {
    my ($code) = @_;
    my $ok = eval {
        $code->();
        1;
    };

    return '' if $ok;
    return $@ || 'unknown error';
}
