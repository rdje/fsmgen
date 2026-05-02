#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::HDLGeneratorFacadeContract qw(build_hdl_generator_facade_contract);

{
    package Test::FacadeExtensionsShapeBlessedObject;

    use strict;
    use warnings;

    sub new {
        my ($class) = @_;
        return bless {}, $class;
    }
}

subtest 'manifests advertise extensions as a blessed-object list facade option' => sub {
    my @views = (
        {
            label => 'direct facade contract',
            facade => build_hdl_generator_facade_contract(),
        },
        {
            label => 'in-process capability manifest',
            facade => build_capability_manifest()->{embedding}{hdl_generator_facade},
        },
        {
            label => 'CLI capability manifest',
            facade => run_capability_manifest('--capability-manifest')
                ->{embedding}{hdl_generator_facade},
        },
        {
            label => 'CLI alias capability manifest',
            facade => run_capability_manifest('--emit-capability-manifest')
                ->{embedding}{hdl_generator_facade},
        },
    );

    for my $view (@views) {
        my $facade = $view->{facade};
        my $label = $view->{label};

        ok(
            contains_value($facade->{public_constructor_option_names}, 'extensions'),
            "$label advertises extensions as public",
        );
        ok(
            contains_value(
                $facade->{constructor_option_family_map}{direct_extension_option_names},
                'extensions',
            ),
            "$label groups extensions with direct extension constructor options",
        );
        is(
            $facade->{constructor_option_shape_map}{extensions},
            'array reference of blessed typed-extension objects',
            "$label advertises the extensions blessed-object array shape",
        );
        ok(
            !$facade->{object_injection_args_public},
            "$label still keeps internal owner-injection constructor args non-public",
        );
    }
};

subtest 'HDLGenerator accepts omitted and blessed-object extension lists' => sub {
    my $default_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
        strict_mode => 0,
    );
    is_deeply(
        $default_pipeline->{extension_registry}->extensions,
        [],
        'omitted extensions defaults to an empty direct extension list',
    );

    my $extension = Test::FacadeExtensionsShapeBlessedObject->new();
    my $pipeline = eval {
        FSM::Pipeline::HDLGenerator->new(
            debug_level => 0,
            target_language => 'systemverilog',
            quiet => 1,
            strict_mode => 0,
            extensions => [$extension],
        );
    };
    my $error = $@;

    ok($pipeline, 'constructor accepts an array reference of blessed extension objects')
        or diag($error);
    is_deeply(
        $pipeline->{extension_registry}->extensions,
        [$extension],
        'accepted blessed extension object is stored in the registry without rewriting',
    ) if $pipeline;
};

subtest 'HDLGenerator rejects malformed extensions values at the facade boundary' => sub {
    for my $case (
        {
            label => 'scalar string',
            value => 'Test::FacadeExtensionsShapeBlessedObject',
            expect => qr/FSM::Pipeline::HDLGenerator expects 'extensions' to be an array reference/s,
        },
        {
            label => 'hashref',
            value => { extension => 'Test::FacadeExtensionsShapeBlessedObject' },
            expect => qr/FSM::Pipeline::HDLGenerator expects 'extensions' to be an array reference/s,
        },
        {
            label => 'unblessed string element',
            value => ['Test::FacadeExtensionsShapeBlessedObject'],
            expect => qr/FSM::Pipeline::HDLGenerator accepts only blessed extension objects in 'extensions'/s,
        },
        {
            label => 'unblessed hash element',
            value => [{ label => 'not-blessed' }],
            expect => qr/FSM::Pipeline::HDLGenerator accepts only blessed extension objects in 'extensions'/s,
        },
        {
            label => 'undef element',
            value => [undef],
            expect => qr/FSM::Pipeline::HDLGenerator accepts only blessed extension objects in 'extensions'/s,
        },
    ) {
        my $error = capture_exception(sub {
            FSM::Pipeline::HDLGenerator->new(
                debug_level => 0,
                target_language => 'systemverilog',
                quiet => 1,
                strict_mode => 0,
                extensions => $case->{value},
            );
        });

        like(
            $error,
            $case->{expect},
            "$case->{label} extensions input receives the targeted facade diagnostic",
        );
        unlike(
            $error,
            qr/FSM::Extension::Registry|Can't use .* as an ARRAY ref|strict refs/s,
            "$case->{label} extensions input does not leak registry or raw Perl diagnostics",
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
