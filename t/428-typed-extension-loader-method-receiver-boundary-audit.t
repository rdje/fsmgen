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
use FSM::Support::ExtensionContract qw(
    build_extension_contract
    extension_contract_loader_method_names
);

my $audit_test = 't/428-typed-extension-loader-method-receiver-boundary-audit.t';
my $receiver_shape = 'exact hash-backed FSM::Extension::Loader object constructed by new(...)';
my $tempdir = tempdir(CLEANUP => 1);
my $empty_config = File::Spec->catfile($tempdir, 'empty.fsmext');
write_file($empty_config, "# no extension modules\n");

{
    package Test::LoaderMethodReceiverBoundarySubclass;

    use strict;
    use warnings;

    our @ISA = ('FSM::Extension::Loader');
}

subtest 'typed-extension manifests publish the loader method receiver boundary' => sub {
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
            $object_contract->{loader_method_receiver_shape},
            $receiver_shape,
            "$label advertises the direct loader method receiver shape",
        );
        is_deeply(
            sorted($object_contract->{loader_method_names}),
            sorted(extension_contract_loader_method_names()),
            "$label advertises the direct loader method names",
        );
        ok(
            contains_value($view->{contract}{tested_by}, $audit_test),
            "$label lists this loader-method receiver audit in tested_by provenance",
        );
    }
};

subtest 'direct loader methods accept only a constructed exact loader instance' => sub {
    my $loader = FSM::Extension::Loader->new();

    is_deeply(
        $loader->load_modules([]),
        [],
        'constructed loader accepts empty module-name loading list',
    );
    is_deeply(
        $loader->module_names_from_config_files([]),
        [],
        'constructed loader accepts empty config-file loading list',
    );
    is_deeply(
        $loader->module_names_from_config_file($empty_config),
        [],
        'constructed loader parses an empty explicit config file',
    );
};

subtest 'direct loader methods reject malformed receivers before payload diagnostics' => sub {
    my @receivers = (
        {
            label => 'class receiver',
            value => 'FSM::Extension::Loader',
        },
        {
            label => 'subclass object',
            value => bless({}, 'Test::LoaderMethodReceiverBoundarySubclass'),
        },
        {
            label => 'fake exact-class hash object',
            value => bless({}, 'FSM::Extension::Loader'),
        },
        {
            label => 'fake exact-class array object',
            value => bless([], 'FSM::Extension::Loader'),
        },
    );
    my @methods = (
        {
            name => 'load_modules',
            call => sub {
                my ($receiver) = @_;
                return $receiver->load_modules('not_a_module_list');
            },
        },
        {
            name => 'module_names_from_config_files',
            call => sub {
                my ($receiver) = @_;
                return $receiver->module_names_from_config_files('not_a_config_list');
            },
        },
        {
            name => 'module_names_from_config_file',
            call => sub {
                my ($receiver) = @_;
                return $receiver->module_names_from_config_file(undef);
            },
        },
    );

    for my $method (@methods) {
        for my $receiver (@receivers) {
            my $error = capture_exception(sub {
                $method->{call}->($receiver->{value});
            });

            like(
                $error,
                qr/FSM::Extension::Loader::\Q$method->{name}\E requires an exact FSM::Extension::Loader object constructed by new\(\.\.\.\)/s,
                "$method->{name} rejects $receiver->{label} with the targeted receiver diagnostic",
            );
            unlike(
                primary_diagnostic($error),
                qr/expects an array reference|Extension config file|HASH\(|ARRAY\(|Can't locate object method|Can't use/s,
                "$method->{name} $receiver->{label} does not leak payload or raw receiver fallout",
            );
        }
    }
};

subtest 'constructed loader still preserves existing payload boundaries' => sub {
    my $loader = FSM::Extension::Loader->new();

    my $module_error = capture_exception(sub {
        $loader->load_modules('Not::A::List');
    });
    like(
        $module_error,
        qr/FSM::Extension::Loader expects an array reference of module names/s,
        'load_modules keeps the module-name list boundary after receiver validation',
    );

    my $config_list_error = capture_exception(sub {
        $loader->module_names_from_config_files('extensions.fsmext');
    });
    like(
        $config_list_error,
        qr/FSM::Extension::Loader expects an array reference of config file paths/s,
        'module_names_from_config_files keeps the config-file list boundary after receiver validation',
    );

    my $config_path_error = capture_exception(sub {
        $loader->module_names_from_config_file(undef);
    });
    like(
        $config_path_error,
        qr/Extension config file:\s+'<missing>'/s,
        'module_names_from_config_file keeps missing-path context after receiver validation',
    );
    like(
        $config_path_error,
        qr/FSM::Extension::Loader expects extension config paths to be scalar non-empty filesystem paths/s,
        'module_names_from_config_file keeps the config-path value boundary after receiver validation',
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

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
