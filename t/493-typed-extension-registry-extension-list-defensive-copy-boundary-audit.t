#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);
use Scalar::Util qw(refaddr);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Extension::Context;
use FSM::Extension::Registry;
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::ExtensionContract qw(build_extension_contract);

my $audit_test = 't/493-typed-extension-registry-extension-list-defensive-copy-boundary-audit.t';
my $extension_list_policy = 'constructor and extensions accessor copy the extension array; extension objects remain live hook objects';

{
    package Test::RegistryListCopyBoundaryExtension;

    use strict;
    use warnings;

    sub new {
        my ($class, $name) = @_;
        return bless { name => $name }, $class;
    }

    sub after_generate_result {
        my ($self, $context) = @_;
        push @{$context->result->{extension_calls}}, $self->{name};
    }
}

subtest 'typed-extension manifests publish the registry extension-list copy policy' => sub {
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
            contract => run_capability_manifest('--capability-manifest')->{embedding}{typed_extensions},
        },
        {
            label => 'CLI alias capability manifest typed-extension contract',
            contract => run_capability_manifest('--emit-capability-manifest')->{embedding}{typed_extensions},
        },
    );

    for my $view (@views) {
        my $object_contract = $view->{contract}{extension_object_contract} || {};
        my $label = $view->{label};

        is(
            $object_contract->{registry_extension_list_policy},
            $extension_list_policy,
            "$label advertises the registry extension-list copy policy",
        );
        ok(
            contains_value($view->{contract}{tested_by}, $audit_test),
            "$label lists this registry extension-list audit in tested_by provenance",
        );
    }
};

subtest 'registry copies constructor and accessor extension arrays' => sub {
    my $first = Test::RegistryListCopyBoundaryExtension->new('first');
    my $second = Test::RegistryListCopyBoundaryExtension->new('second');
    my @extensions = ($first);
    my $registry = FSM::Extension::Registry->new(extensions => \@extensions);

    push @extensions, $second;

    my $first_view = $registry->extensions;
    my $second_view = $registry->extensions;

    isnt(
        refaddr($first_view),
        refaddr($second_view),
        'extensions accessor returns a fresh array reference each time',
    );
    is_deeply(
        $first_view,
        [$first],
        'constructor copy is isolated from caller-side list mutation',
    );

    push @{$first_view}, $second;

    is_deeply(
        $registry->extensions,
        [$first],
        'accessor copy mutation does not change the registry extension list',
    );

    my $context = make_result_context();
    $registry->after_generate_result($context);

    is_deeply(
        $context->result->{extension_calls},
        ['first'],
        'dispatch uses only the registry-owned extension list while preserving hook objects',
    );
};

done_testing();

sub make_result_context {
    return FSM::Extension::Context->new(
        stage => 'after_generate_result',
        pipeline => bless({}, 'Test::RegistryListCopyBoundaryPipeline'),
        source_path => 'synthetic.fsm',
        target_language => 'systemverilog',
        source_info => {
            kind => 'fsm',
        },
        result => {
            module_info => {
                module_name => 'registry_list_copy_boundary',
            },
            extension_calls => [],
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
        return 1 if defined($value) && !ref($value) && $value eq $wanted;
    }

    return 0;
}
