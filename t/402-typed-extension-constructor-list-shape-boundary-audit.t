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
use FSM::Support::ExtensionContract qw(build_extension_contract);
use FSM::Support::HDLGeneratorFacadeContract qw(build_hdl_generator_facade_contract);

my $audit_test = 't/402-typed-extension-constructor-list-shape-boundary-audit.t';

subtest 'manifests advertise list-shaped typed-extension constructor entrypoints' => sub {
    my @views = (
        {
            label => 'direct contracts',
            typed_extensions => build_extension_contract(),
            facade => build_hdl_generator_facade_contract(),
        },
        {
            label => 'in-process capability manifest',
            typed_extensions => build_capability_manifest()->{embedding}{typed_extensions},
            facade => build_capability_manifest()->{embedding}{hdl_generator_facade},
        },
        {
            label => 'CLI capability manifest',
            typed_extensions => run_capability_manifest('--capability-manifest')
                ->{embedding}{typed_extensions},
            facade => run_capability_manifest('--capability-manifest')
                ->{embedding}{hdl_generator_facade},
        },
        {
            label => 'CLI alias capability manifest',
            typed_extensions => run_capability_manifest('--emit-capability-manifest')
                ->{embedding}{typed_extensions},
            facade => run_capability_manifest('--emit-capability-manifest')
                ->{embedding}{hdl_generator_facade},
        },
    );

    for my $view (@views) {
        my $typed_extensions = $view->{typed_extensions};
        my $facade = $view->{facade};
        my $label = $view->{label};

        like(
            $typed_extensions->{entrypoints}{programmatic_modules} || '',
            qr/extension_modules\s*=>\s*\[/s,
            "$label typed-extension contract advertises extension_modules as a list",
        );
        like(
            $typed_extensions->{entrypoints}{programmatic_config_files} || '',
            qr/extension_config_files\s*=>\s*\[/s,
            "$label typed-extension contract advertises extension_config_files as a list",
        );
        ok(
            contains_value($typed_extensions->{tested_by}, $audit_test),
            "$label typed-extension contract lists this constructor-list audit",
        );
        ok(
            contains_value($facade->{direct_extension_option_names}, 'extensions'),
            "$label facade contract advertises direct extension-object injection",
        );
    }
};

subtest 'HDLGenerator rejects scalar typed-extension constructor lists before dereference' => sub {
    for my $case (
        {
            arg => 'extension_modules',
            value => 'FSM::TestExtension::Marker',
        },
        {
            arg => 'extension_config_files',
            value => 'extensions.fsmext',
        },
        {
            arg => 'extensions',
            value => 'not-an-extension-object-list',
        },
    ) {
        my $error = capture_exception(sub {
            FSM::Pipeline::HDLGenerator->new(
                debug_level => 0,
                target_language => 'systemverilog',
                quiet => 1,
                $case->{arg} => $case->{value},
            );
        });

        like(
            $error,
            qr/FSM::Pipeline::HDLGenerator expects '\Q$case->{arg}\E' to be an array reference/s,
            "$case->{arg} scalar input receives a targeted constructor-list diagnostic",
        );
        unlike(
            $error,
            qr/Can't use .* as an ARRAY ref|strict refs/s,
            "$case->{arg} scalar input does not leak raw Perl dereference fallout",
        );
    }
};

subtest 'HDLGenerator rejects hashref typed-extension constructor lists before dereference' => sub {
    for my $case (
        {
            arg => 'extension_modules',
            value => { module => 'FSM::TestExtension::Marker' },
        },
        {
            arg => 'extension_config_files',
            value => { config => 'extensions.fsmext' },
        },
        {
            arg => 'extensions',
            value => { object => 'not-really' },
        },
    ) {
        my $error = capture_exception(sub {
            FSM::Pipeline::HDLGenerator->new(
                debug_level => 0,
                target_language => 'systemverilog',
                quiet => 1,
                $case->{arg} => $case->{value},
            );
        });

        like(
            $error,
            qr/FSM::Pipeline::HDLGenerator expects '\Q$case->{arg}\E' to be an array reference/s,
            "$case->{arg} hashref input receives a targeted constructor-list diagnostic",
        );
        unlike(
            $error,
            qr/Can't use .* as an ARRAY ref|strict refs/s,
            "$case->{arg} hashref input does not leak raw Perl dereference fallout",
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
