#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Extension::Loader;
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::ExtensionContract qw(build_extension_contract);

my $audit_test = 't/431-typed-extension-loader-method-argument-list-boundary-audit.t';
my $argument_list_shape = 'exactly one payload argument after the loader invocant';
my $tempdir = tempdir(CLEANUP => 1);
my $empty_config = File::Spec->catfile($tempdir, 'empty.fsmext');
write_file($empty_config, "# no extension modules\n");

subtest 'typed-extension manifests publish the loader method argument-list boundary' => sub {
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
        my $object_contract = $view->{contract}{extension_object_contract} || {};
        my $label = $view->{label};

        is(
            $object_contract->{loader_method_argument_list_shape},
            $argument_list_shape,
            "$label advertises the direct loader method argument-list shape",
        );
        ok(
            contains_value($view->{contract}{tested_by}, $audit_test),
            "$label lists this loader-method argument-list audit in tested_by provenance",
        );
    }
};

subtest 'direct loader methods accept exactly one payload argument' => sub {
    my $loader = FSM::Extension::Loader->new();

    is_deeply(
        $loader->load_modules([]),
        [],
        'load_modules accepts one module-name list payload',
    );
    is_deeply(
        $loader->module_names_from_config_files([]),
        [],
        'module_names_from_config_files accepts one config-file list payload',
    );
    is_deeply(
        $loader->module_names_from_config_file($empty_config),
        [],
        'module_names_from_config_file accepts one config-file path payload',
    );
};

subtest 'direct loader methods reject missing and extra payload arguments before raw signature fallout' => sub {
    my $loader = FSM::Extension::Loader->new();
    my @methods = (
        {
            name => 'load_modules',
            missing => sub { $loader->load_modules() },
            extra => sub { $loader->load_modules([], []) },
        },
        {
            name => 'module_names_from_config_files',
            missing => sub { $loader->module_names_from_config_files() },
            extra => sub { $loader->module_names_from_config_files([], []) },
        },
        {
            name => 'module_names_from_config_file',
            missing => sub { $loader->module_names_from_config_file() },
            extra => sub { $loader->module_names_from_config_file($empty_config, $empty_config) },
        },
    );

    for my $method (@methods) {
        for my $case_name (qw(missing extra)) {
            my $error = capture_exception($method->{$case_name});

            like(
                $error,
                qr/FSM::Extension::Loader::\Q$method->{name}\E expects exactly one payload argument after the loader invocant/s,
                "$method->{name} rejects $case_name payload arguments with the targeted diagnostic",
            );
            unlike(
                primary_diagnostic($error),
                qr/Too few arguments|Too many arguments|expects an array reference|Extension config file/s,
                "$method->{name} $case_name payload arguments do not leak raw signature or value fallout",
            );
        }
    }
};

subtest 'valid argument counts still preserve existing payload value boundaries' => sub {
    my $loader = FSM::Extension::Loader->new();

    my $module_error = capture_exception(sub {
        $loader->load_modules('Not::A::List');
    });
    like(
        $module_error,
        qr/FSM::Extension::Loader expects an array reference of module names/s,
        'load_modules keeps the module-name list value boundary after argument-count validation',
    );

    my $config_list_error = capture_exception(sub {
        $loader->module_names_from_config_files('extensions.fsmext');
    });
    like(
        $config_list_error,
        qr/FSM::Extension::Loader expects an array reference of config file paths/s,
        'module_names_from_config_files keeps the config-file list value boundary after argument-count validation',
    );

    my $config_path_error = capture_exception(sub {
        $loader->module_names_from_config_file(undef);
    });
    like(
        $config_path_error,
        qr/Extension config file:\s+'<missing>'/s,
        'module_names_from_config_file keeps missing-path context after argument-count validation',
    );
    like(
        $config_path_error,
        qr/FSM::Extension::Loader expects extension config paths to be scalar non-empty filesystem paths/s,
        'module_names_from_config_file keeps the config-path value boundary after argument-count validation',
    );
};

done_testing();

sub run_capability_manifest {
    my ($mode) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', $mode],
    );

    ok($success, "$mode succeeds");
    is(join('', @{$stderr_buf || []}), '', "$mode keeps stderr clean");

    return decode_json(join('', @{$stdout_buf || []}));
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

sub primary_diagnostic {
    my ($error) = @_;
    my ($primary) = split /\n/, ($error || ''), 2;
    return $primary || '';
}

sub contains_value {
    my ($values, $wanted) = @_;
    return 0 unless ref($values) eq 'ARRAY';

    for my $value (@{$values}) {
        return 1 if defined($value) && $value eq $wanted;
    }

    return 0;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
