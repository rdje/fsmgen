#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Path qw(make_path);
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

my $alpha_module = 'FSM::BoundaryAudit::ConfigShapeAlpha';
my $beta_module = 'FSM::BoundaryAudit::ConfigShapeBeta';
my $audit_test = 't/400-typed-extension-config-line-shape-boundary-audit.t';
my $tempdir = tempdir(CLEANUP => 1);
my $extension_lib = File::Spec->catdir($tempdir, 'lib');
my $config_a = File::Spec->catfile($tempdir, 'config-a.fsmext');
my $config_b = File::Spec->catfile($tempdir, 'config-b.fsmext');
my $source_path = File::Spec->catfile($tempdir, 'config_shape_root.fsm');

write_extension_module($extension_lib, $alpha_module);
write_extension_module($extension_lib, $beta_module);
write_direct_fixture($source_path);
write_file(
    $config_a,
    <<"CFG",
# Leading comments and blank lines are inert.

  module $alpha_module   # inline comments stay inert too
CFG
);
write_file(
    $config_b,
    <<"CFG",
module $beta_module

# Trailing comments and whitespace are inert.
CFG
);

unshift @INC, $extension_lib;

subtest 'typed-extension manifests publish the explicit config line shape' => sub {
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
            $contract->{extension_object_contract}{config_line_shape},
            'module Module::Name',
            "$label publishes the explicit config line shape",
        );
        like(
            $contract->{entrypoints}{programmatic_config_files} || '',
            qr/extension_config_files/s,
            "$label advertises programmatic config-file loading",
        );
        like(
            $contract->{entrypoints}{cli_config_files} || '',
            qr/--extension-config/s,
            "$label advertises CLI config-file loading",
        );
        ok(
            contains_value($contract->{tested_by}, $audit_test),
            "$label lists this config-shape audit in tested_by provenance",
        );
    }
};

subtest 'loader accepts only module lines plus inert comments and blanks' => sub {
    my $loader = FSM::Extension::Loader->new();
    my $module_names = $loader->module_names_from_config_files([$config_a, $config_b]);

    is_deeply(
        $module_names,
        [$alpha_module, $beta_module],
        'config parser preserves module order across repeated explicit config files',
    );

    for my $case (
        {
            label => 'missing module directive',
            contents => "$alpha_module\n",
            line_number => 1,
        },
        {
            label => 'invalid first module segment',
            contents => "module 9Bad::Name\n",
            line_number => 1,
        },
        {
            label => 'unsupported directive',
            contents => "plugin $alpha_module\n",
            line_number => 1,
        },
        {
            label => 'extra non-comment payload',
            contents => "module $alpha_module extra\n",
            line_number => 1,
        },
        {
            label => 'later malformed line after inert comments',
            contents => "# ok\n\nmodule $alpha_module\nnot-a-module $beta_module\n",
            line_number => 4,
        },
    ) {
        my $bad_config = File::Spec->catfile(
            $tempdir,
            sanitize_filename("$case->{label}.fsmext"),
        );
        write_file($bad_config, $case->{contents});

        my $error = capture_exception(sub {
            $loader->module_names_from_config_files([$bad_config]);
        });

        like(
            $error,
            qr/Extension config file:\s+'\Q$bad_config\E'/s,
            "$case->{label}: error keeps config-file context",
        );
        like(
            $error,
            qr/Invalid extension config line at '\Q$bad_config\E' line $case->{line_number}/s,
            "$case->{label}: error reports the exact invalid line",
        );
        like(
            $error,
            qr/expected 'module Module::Name'/s,
            "$case->{label}: error repeats the public config line shape",
        );
    }
};

subtest 'explicit config files load extensions in parsed order in-process' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        strict_mode => 1,
        quiet => 1,
        extension_config_files => [$config_a, $config_b],
    );
    my $result = $pipeline->generate_hdl_from_file($source_path);

    is(
        $result->{module_info}{module_name},
        'config_shape_root',
        'config-loaded facade still returns the generated module result',
    );
    is_deeply(
        $result->{config_shape_audit_modules},
        [$alpha_module, $beta_module],
        'config-loaded extensions dispatch in config-file parse order',
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

sub write_extension_module {
    my ($lib_root, $module_name) = @_;
    my @parts = split /::/, $module_name;
    my $leaf = pop @parts;
    my $module_dir = File::Spec->catdir($lib_root, @parts);
    my $module_path = File::Spec->catfile($module_dir, "$leaf.pm");

    make_path($module_dir);
    write_file(
        $module_path,
        <<"PERL",
package $module_name;

use strict;
use warnings;

sub new {
    my (\$class) = \@_;
    return bless {}, \$class;
}

sub after_generate_result {
    my (\$self, \$context) = \@_;
    push \@{\$context->result->{config_shape_audit_modules}}, __PACKAGE__;
}

1;
PERL
    );
}

sub write_direct_fixture {
    my ($path) = @_;
    write_file(
        $path,
        <<'FSM',
(?fsm:config_shape_root
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
