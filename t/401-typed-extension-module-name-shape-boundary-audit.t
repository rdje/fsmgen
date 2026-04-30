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
use FSM::Pipeline::HDLGenerator;
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::ExtensionContract qw(build_extension_contract);

my $audit_test = 't/401-typed-extension-module-name-shape-boundary-audit.t';
my $tempdir = tempdir(CLEANUP => 1);
my $source_path = File::Spec->catfile($tempdir, 'module_name_shape_root.fsm');
my $cli_output_path = File::Spec->catfile($tempdir, 'bad_module_name.sv');

write_direct_fixture($source_path);

subtest 'typed-extension manifests keep module-name loading tied to Module::Name shape' => sub {
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

        like(
            $contract->{entrypoints}{programmatic_modules} || '',
            qr/Module::Name/s,
            "$label advertises Module::Name-shaped programmatic module loading",
        );
        like(
            $contract->{entrypoints}{cli_modules} || '',
            qr/Module::Name/s,
            "$label advertises Module::Name-shaped CLI module loading",
        );
        is(
            $contract->{extension_object_contract}{config_line_shape},
            'module Module::Name',
            "$label keeps config lines tied to the same Module::Name shape",
        );
        ok(
            contains_value($contract->{tested_by}, $audit_test),
            "$label lists this module-name shape audit in tested_by provenance",
        );
    }
};

subtest 'loader rejects invalid module-name segments before require' => sub {
    my $loader = FSM::Extension::Loader->new();

    for my $module_name (
        '9Bad::Module',
        'FSM::BoundaryAudit::9Bad',
        'FSM::BoundaryAudit::Bad-Hyphen',
        'FSM::BoundaryAudit::',
    ) {
        my $error = capture_exception(sub {
            $loader->load_modules([$module_name]);
        });

        like(
            $error,
            qr/Extension module:\s+'\Q$module_name\E'/s,
            "$module_name rejection keeps extension-module context",
        );
        like(
            $error,
            qr/rejects invalid extension module name '\Q$module_name\E'/s,
            "$module_name is rejected by module-name validation",
        );
        unlike(
            $error,
            qr/Unable to load extension module|Can't locate/s,
            "$module_name does not fall through to require/load failure",
        );
    }
};

subtest 'config parser rejects invalid Module::Name segments at line parsing' => sub {
    my $loader = FSM::Extension::Loader->new();

    for my $case (
        {
            label => 'leading numeric segment',
            line => 'module 9Bad::Module',
        },
        {
            label => 'nested numeric segment',
            line => 'module FSM::BoundaryAudit::9Bad',
        },
        {
            label => 'hyphenated segment',
            line => 'module FSM::BoundaryAudit::Bad-Hyphen',
        },
    ) {
        my $config_path = File::Spec->catfile(
            $tempdir,
            sanitize_filename("$case->{label}.fsmext"),
        );
        write_file($config_path, "$case->{line}\n");

        my $error = capture_exception(sub {
            $loader->module_names_from_config_files([$config_path]);
        });

        like(
            $error,
            qr/Extension config file:\s+'\Q$config_path\E'/s,
            "$case->{label}: error keeps extension-config context",
        );
        like(
            $error,
            qr/Invalid extension config line at '\Q$config_path\E' line 1/s,
            "$case->{label}: invalid module line is rejected during config parsing",
        );
        like(
            $error,
            qr/expected 'module Module::Name'/s,
            "$case->{label}: error repeats the public module-name line shape",
        );
    }
};

subtest 'pipeline and CLI reject invalid module names before loading attempts' => sub {
    my $invalid_module = 'FSM::BoundaryAudit::9Bad';

    my $pipeline_error = capture_exception(sub {
        FSM::Pipeline::HDLGenerator->new(
            debug_level => 0,
            target_language => 'systemverilog',
            strict_mode => 1,
            quiet => 1,
            extension_modules => [$invalid_module],
        );
    });

    like(
        $pipeline_error,
        qr/Extension module:\s+'\Q$invalid_module\E'/s,
        'pipeline rejection keeps extension-module context',
    );
    like(
        $pipeline_error,
        qr/rejects invalid extension module name '\Q$invalid_module\E'/s,
        'pipeline rejects nested invalid module segment before loading',
    );
    unlike(
        $pipeline_error,
        qr/Unable to load extension module|Can't locate/s,
        'pipeline rejection does not fall through to require/load failure',
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => [
            $^X,
            './bin/fsmgen',
            '--extension-module',
            $invalid_module,
            '--quiet',
            '-o',
            $cli_output_path,
            $source_path,
        ],
    );

    ok(!$success, 'CLI fails for nested invalid extension module names');
    ok(!-e $cli_output_path, 'CLI does not emit HDL for invalid extension module names');
    my $combined_output = join(
        '',
        @{$stdout_buf || []},
        @{$stderr_buf || []},
        ($error_message || ''),
    );

    like(
        $combined_output,
        qr/Extension module:\s+'\Q$invalid_module\E'/s,
        'CLI rejection keeps extension-module context',
    );
    like(
        $combined_output,
        qr/rejects invalid extension module name '\Q$invalid_module\E'/s,
        'CLI rejects nested invalid module segment before loading',
    );
    unlike(
        $combined_output,
        qr/Unable to load extension module|Can't locate/s,
        'CLI rejection does not fall through to require/load failure',
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

sub sanitize_filename {
    my ($name) = @_;
    $name =~ s/[^A-Za-z0-9_.-]+/_/g;
    return $name;
}

sub write_direct_fixture {
    my ($path) = @_;
    write_file(
        $path,
        <<'FSM',
(?fsm:module_name_shape_root
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (OUT 1)
  )
  (idle
    (= (OUT 1'b1))
  )
)
FSM
    );
}

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $contents or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
