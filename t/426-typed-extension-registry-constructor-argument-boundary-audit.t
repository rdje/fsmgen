#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Extension::Registry;
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::ExtensionContract qw(
    build_extension_contract
    extension_contract_registry_constructor_option_names
);

my $audit_test = 't/426-typed-extension-registry-constructor-argument-boundary-audit.t';
my $receiver_shape = 'scalar FSM::Extension::Registry class name';
my $argument_list_shape = 'even-length list of unique scalar non-empty supported option-name/value pairs after class invocant';

{
    package Test::RegistryConstructorBoundaryExtension;

    use strict;
    use warnings;

    sub new { return bless {}, shift }
    sub after_parse_source { return }
}

{
    package Test::RegistryConstructorBoundaryHooklessExtension;

    use strict;
    use warnings;

    sub new { return bless {}, shift }
}

{
    package Test::RegistryConstructorBoundarySubclass;

    use strict;
    use warnings;

    our @ISA = ('FSM::Extension::Registry');
}

subtest 'typed-extension manifests publish the registry constructor argument boundary' => sub {
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
            $object_contract->{registry_constructor_receiver_shape},
            $receiver_shape,
            "$label advertises the direct registry constructor receiver shape",
        );
        is(
            $object_contract->{registry_constructor_argument_list_shape},
            $argument_list_shape,
            "$label advertises the direct registry constructor argument-list shape",
        );
        is_deeply(
            sorted($object_contract->{registry_constructor_supported_option_names}),
            sorted(extension_contract_registry_constructor_option_names()),
            "$label advertises the direct registry constructor supported option names",
        );
        ok(
            contains_value($view->{contract}{tested_by}, $audit_test),
            "$label lists this registry-constructor audit in tested_by provenance",
        );
    }
};

subtest 'direct registry construction accepts the exact class receiver and supported options' => sub {
    my $empty_registry = FSM::Extension::Registry->new();
    is_deeply($empty_registry->extensions, [], 'registry defaults to an empty extension list');

    my $extension = Test::RegistryConstructorBoundaryExtension->new();
    my $extensions = [$extension];
    my $registry = FSM::Extension::Registry->new(extensions => $extensions);

    isa_ok($registry, 'FSM::Extension::Registry');
    is(
        $registry->extensions,
        $extensions,
        'registry preserves the accepted extension array reference',
    );
};

subtest 'direct registry construction rejects malformed receivers before bless fallout' => sub {
    my $registry = FSM::Extension::Registry->new();

    for my $case (
        {
            label => 'object receiver',
            build => sub { $registry->new() },
        },
        {
            label => 'subclass receiver',
            build => sub { Test::RegistryConstructorBoundarySubclass->new() },
        },
    ) {
        my $error = capture_exception($case->{build});
        like(
            $error,
            qr/FSM::Extension::Registry constructor receiver must be scalar FSM::Extension::Registry class name/s,
            "$case->{label} receives the targeted registry receiver diagnostic",
        );
        unlike(
            primary_diagnostic($error),
            qr/Attempt to bless|HASH\(|Can't use/s,
            "$case->{label} does not leak raw receiver fallout",
        );
    }
};

subtest 'direct registry construction rejects malformed option lists before hash coercion' => sub {
    my @cases = (
        {
            label => 'odd argument list',
            args => [extensions => [], 'dangling'],
            pattern => qr/FSM::Extension::Registry constructor arguments must be an even-length option\/value list/s,
        },
        {
            label => 'undef option name',
            args => [undef, []],
            pattern => qr/FSM::Extension::Registry constructor option names must be scalar non-empty strings/s,
        },
        {
            label => 'reference option name',
            args => [[], []],
            pattern => qr/FSM::Extension::Registry constructor option names must be scalar non-empty strings/s,
        },
        {
            label => 'unsupported option name',
            args => [unknown => 1],
            pattern => qr/FSM::Extension::Registry constructor rejects unsupported option name\(s\): unknown/s,
        },
        {
            label => 'duplicate supported option name',
            args => [extensions => [], extensions => []],
            pattern => qr/FSM::Extension::Registry constructor rejects duplicate option name\(s\): extensions/s,
        },
        {
            label => 'unsupported option before extension value shape',
            args => [extensions => 'not_an_array', typo => 1],
            pattern => qr/FSM::Extension::Registry constructor rejects unsupported option name\(s\): typo/s,
        },
        {
            label => 'duplicate option before extension value shape',
            args => [extensions => 'not_an_array', extensions => []],
            pattern => qr/FSM::Extension::Registry constructor rejects duplicate option name\(s\): extensions/s,
        },
    );

    for my $case (@cases) {
        my $error = capture_exception(sub {
            FSM::Extension::Registry->new(@{$case->{args}});
        });

        like(
            $error,
            $case->{pattern},
            "$case->{label} receives the targeted registry constructor diagnostic",
        );
        unlike(
            primary_diagnostic($error),
            qr/Odd number|HASH\(|ARRAY\(|Can't use|expects 'extensions'/s,
            "$case->{label} does not leak raw hash coercion or later value-shape fallout",
        );
    }
};

subtest 'direct registry construction still rejects malformed extension values after constructor mechanics' => sub {
    for my $case (
        {
            label => 'scalar extensions value',
            args => [extensions => 'not_an_array'],
            pattern => qr/FSM::Extension::Registry expects 'extensions' to be an array reference/s,
        },
        {
            label => 'non-object extension entry',
            args => [extensions => ['not_an_object']],
            pattern => qr/FSM::Extension::Registry accepts only blessed extension objects/s,
        },
        {
            label => 'hookless extension object',
            args => [extensions => [Test::RegistryConstructorBoundaryHooklessExtension->new()]],
            pattern => qr/FSM::Extension::Registry expects extension objects to provide at least one supported hook method: after_parse_source, after_generate_result/s,
        },
    ) {
        my $error = capture_exception(sub {
            FSM::Extension::Registry->new(@{$case->{args}});
        });

        like(
            $error,
            $case->{pattern},
            "$case->{label} preserves the existing extension value boundary",
        );
    }
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
