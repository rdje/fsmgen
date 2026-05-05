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
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::ExtensionContract qw(
    build_extension_contract
    extension_contract_loader_constructor_option_names
);

my $audit_test = 't/427-typed-extension-loader-constructor-argument-boundary-audit.t';
my $receiver_shape = 'scalar FSM::Extension::Loader class name';
my $argument_list_shape = 'no option/value arguments after class invocant';

{
    package Test::LoaderConstructorBoundarySubclass;

    use strict;
    use warnings;

    our @ISA = ('FSM::Extension::Loader');
}

subtest 'typed-extension manifests publish the loader constructor argument boundary' => sub {
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
            $object_contract->{loader_constructor_receiver_shape},
            $receiver_shape,
            "$label advertises the direct loader constructor receiver shape",
        );
        is(
            $object_contract->{loader_constructor_argument_list_shape},
            $argument_list_shape,
            "$label advertises the direct loader constructor argument-list shape",
        );
        is_deeply(
            $object_contract->{loader_constructor_supported_option_names},
            extension_contract_loader_constructor_option_names(),
            "$label advertises the direct loader constructor supported option names",
        );
        ok(
            contains_value($view->{contract}{tested_by}, $audit_test),
            "$label lists this loader-constructor audit in tested_by provenance",
        );
    }
};

subtest 'direct loader construction accepts only the exact class receiver without options' => sub {
    my $loader = FSM::Extension::Loader->new();
    isa_ok($loader, 'FSM::Extension::Loader');
};

subtest 'direct loader construction rejects malformed receivers before bless fallout' => sub {
    my $loader = FSM::Extension::Loader->new();

    for my $case (
        {
            label => 'object receiver',
            build => sub { $loader->new() },
        },
        {
            label => 'subclass receiver',
            build => sub { Test::LoaderConstructorBoundarySubclass->new() },
        },
    ) {
        my $error = capture_exception($case->{build});
        like(
            $error,
            qr/FSM::Extension::Loader constructor receiver must be scalar FSM::Extension::Loader class name/s,
            "$case->{label} receives the targeted loader receiver diagnostic",
        );
        unlike(
            primary_diagnostic($error),
            qr/Attempt to bless|HASH\(|Can't use/s,
            "$case->{label} does not leak raw receiver fallout",
        );
    }
};

subtest 'direct loader construction rejects any argument tail before hash coercion' => sub {
    for my $case (
        {
            label => 'single dangling argument',
            args => ['dangling'],
        },
        {
            label => 'ignored option pair',
            args => [ignored => 1],
        },
        {
            label => 'reference option name',
            args => [[], 1],
        },
    ) {
        my $error = capture_exception(sub {
            FSM::Extension::Loader->new(@{$case->{args}});
        });

        like(
            $error,
            qr/FSM::Extension::Loader constructor does not accept option\/value arguments/s,
            "$case->{label} receives the targeted loader constructor diagnostic",
        );
        unlike(
            primary_diagnostic($error),
            qr/Odd number|HASH\(|ARRAY\(|Can't use/s,
            "$case->{label} does not leak raw hash coercion fallout",
        );
    }
};

subtest 'accepted loader still preserves existing list-shaped loading boundaries' => sub {
    my $loader = FSM::Extension::Loader->new();

    my $module_error = capture_exception(sub {
        $loader->load_modules('Not::A::List');
    });
    like(
        $module_error,
        qr/FSM::Extension::Loader expects an array reference of module names/s,
        'load_modules keeps its list-shaped module-name boundary',
    );

    my $config_error = capture_exception(sub {
        $loader->module_names_from_config_files('extensions.fsmext');
    });
    like(
        $config_error,
        qr/FSM::Extension::Loader expects an array reference of config file paths/s,
        'module_names_from_config_files keeps its list-shaped config-file boundary',
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
