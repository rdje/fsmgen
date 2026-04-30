#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Cwd qw(getcwd);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::ExtensionContract qw(build_extension_contract);

my $extension_module = 'FSM::BoundaryAudit::ExplicitDiscoveryProbe';
my $repo_root = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));
my $fsmgen_bin = File::Spec->catfile($repo_root, 'bin', 'fsmgen');
my $tempdir = tempdir(CLEANUP => 1);
my $extension_lib = File::Spec->catdir($tempdir, 'lib');
my $source_name = 'explicit_discovery_root.fsm';
my $source_path = File::Spec->catfile($tempdir, $source_name);
my $config_path = File::Spec->catfile($tempdir, 'extensions.fsmext');
my $alternate_config_path = File::Spec->catfile($tempdir, 'fsmgen.fsmext');
my $legacy_plg_path = File::Spec->catfile($tempdir, 'legacy_discovery_probe.plg');
my $plain_cli_output = File::Spec->catfile($tempdir, 'plain_cli.sv');
my $config_cli_output = File::Spec->catfile($tempdir, 'config_cli.sv');
my $module_cli_output = File::Spec->catfile($tempdir, 'module_cli.sv');

write_extension_module($extension_lib);
write_direct_fixture($source_path);
write_file($config_path, "module $extension_module\n");
write_file($alternate_config_path, "module $extension_module\n");
write_file(
    $legacy_plg_path,
    <<'PLG'
die "legacy .plg discovery should remain disabled\n";
PLG
);

unshift @INC, $extension_lib;

subtest 'typed-extension manifests advertise explicit discovery only' => sub {
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
        assert_explicit_discovery_contract(
            $view->{contract},
            $view->{label},
        );
    }
};

subtest 'in-process facade ignores nearby extension files without explicit loader args' => sub {
    my $plain_result = run_pipeline();
    assert_generated_without_marker(
        $plain_result,
        'plain in-process facade without extension loader args',
    );

    my $config_result = run_pipeline(
        extension_config_files => [$config_path],
    );
    assert_generated_with_marker(
        $config_result,
        'explicit in-process extension_config_files positive control',
    );

    my $module_result = run_pipeline(
        extension_modules => [$extension_module],
    );
    assert_generated_with_marker(
        $module_result,
        'explicit in-process extension_modules positive control',
    );
};

subtest 'CLI ignores cwd extension files unless explicit extension flags are present' => sub {
    my ($plain_success, $plain_error, $plain_full, $plain_stdout, $plain_stderr) =
        run_cli_from_source_dir(
            options => [],
            output_path => $plain_cli_output,
        );
    ok($plain_success, 'plain CLI run succeeds beside extension-looking files');
    is(join('', @{$plain_stderr || []}), '', 'plain CLI run keeps stderr clean');
    ok(-e $plain_cli_output, 'plain CLI run writes HDL output');
    assert_hdl_without_marker(
        slurp($plain_cli_output),
        'plain CLI run beside extension-looking files',
    );

    my ($config_success, $config_error, $config_full, $config_stdout, $config_stderr) =
        run_cli_from_source_dir(
            options => ['--extension-config', $config_path],
            output_path => $config_cli_output,
        );
    ok($config_success, 'CLI succeeds with explicit --extension-config');
    is(join('', @{$config_stderr || []}), '', 'explicit --extension-config keeps stderr clean');
    ok(-e $config_cli_output, 'explicit --extension-config writes HDL output');
    assert_hdl_with_marker(
        slurp($config_cli_output),
        'explicit --extension-config positive control',
    );

    my ($module_success, $module_error, $module_full, $module_stdout, $module_stderr) =
        run_cli_from_source_dir(
            options => ['--extension-module', $extension_module],
            output_path => $module_cli_output,
        );
    ok($module_success, 'CLI succeeds with explicit --extension-module');
    is(join('', @{$module_stderr || []}), '', 'explicit --extension-module keeps stderr clean');
    ok(-e $module_cli_output, 'explicit --extension-module writes HDL output');
    assert_hdl_with_marker(
        slurp($module_cli_output),
        'explicit --extension-module positive control',
    );
};

done_testing();

sub assert_explicit_discovery_contract {
    my ($contract, $label) = @_;
    my $object_contract = $contract->{extension_object_contract} || {};
    my $entrypoints = $contract->{entrypoints} || {};

    ok(
        !$object_contract->{legacy_plg_discovery},
        "$label keeps legacy .plg discovery disabled",
    );
    ok(
        !$object_contract->{automatic_directory_discovery},
        "$label keeps automatic directory discovery disabled",
    );
    is(
        $object_contract->{config_line_shape},
        'module Module::Name',
        "$label documents the explicit config line shape",
    );
    like(
        $entrypoints->{programmatic_modules} || '',
        qr/extension_modules/s,
        "$label advertises explicit programmatic module loading",
    );
    like(
        $entrypoints->{programmatic_config_files} || '',
        qr/extension_config_files/s,
        "$label advertises explicit programmatic config loading",
    );
    like(
        $entrypoints->{cli_modules} || '',
        qr/--extension-module/s,
        "$label advertises explicit CLI module loading",
    );
    like(
        $entrypoints->{cli_config_files} || '',
        qr/--extension-config/s,
        "$label advertises explicit CLI config loading",
    );
}

sub run_pipeline {
    my (%extra_args) = @_;
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        strict_mode => 1,
        quiet => 1,
        %extra_args,
    );

    return $pipeline->generate_hdl_from_file($source_path);
}

sub assert_generated_without_marker {
    my ($result, $label) = @_;
    is(
        $result->{module_info}{module_name},
        'explicit_discovery_root',
        "$label still returns the generated module result",
    );
    ok(
        !exists $result->{explicit_discovery_audit_marker},
        "$label receives no extension result marker",
    );
    assert_hdl_without_marker($result->{hdl_code}, $label);
}

sub assert_generated_with_marker {
    my ($result, $label) = @_;
    is(
        $result->{module_info}{module_name},
        'explicit_discovery_root',
        "$label still returns the generated module result",
    );

    my $marker = $result->{explicit_discovery_audit_marker} || {};
    is($marker->{module_name}, $extension_module, "$label marker names the loaded module");
    is($marker->{parse_source_kind}, 'fsm', "$label parse hook sees fsm source kind");
    is($marker->{result_source_kind}, 'fsm', "$label result hook sees fsm source kind");
    is($marker->{target_language}, 'systemverilog', "$label hook context sees target language");
    is_deeply(
        $marker->{stages},
        [qw(after_parse_source after_generate_result)],
        "$label dispatches typed hooks in order",
    );
    assert_hdl_with_marker($result->{hdl_code}, $label);
}

sub assert_hdl_without_marker {
    my ($hdl, $label) = @_;
    like(
        $hdl,
        qr/\bmodule\s+explicit_discovery_root\b/s,
        "$label emits generated HDL",
    );
    unlike(
        $hdl,
        qr/explicit discovery marker/s,
        "$label HDL has no extension marker",
    );
}

sub assert_hdl_with_marker {
    my ($hdl, $label) = @_;
    like(
        $hdl,
        qr/\bmodule\s+explicit_discovery_root\b/s,
        "$label emits generated HDL",
    );
    like(
        $hdl,
        qr{// explicit discovery marker: \Q$extension_module\E}s,
        "$label HDL carries the explicit extension marker",
    );
}

sub run_cli_from_source_dir {
    my (%args) = @_;
    my $old_cwd = getcwd();
    my @result;
    my $ok = eval {
        chdir $tempdir or die "Cannot chdir to $tempdir: $!";
        @result = run(
            command => [
                $^X,
                '-I', $extension_lib,
                $fsmgen_bin,
                @{$args{options} || []},
                '-o', $args{output_path},
                '--quiet',
                $source_name,
            ],
        );
        1;
    };
    my $error = $@;
    chdir $old_cwd or die "Cannot restore cwd to $old_cwd: $!";
    die $error unless $ok;
    return @result;
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

sub write_extension_module {
    my ($lib_root) = @_;
    my $module_dir = File::Spec->catdir($lib_root, qw(FSM BoundaryAudit));
    my $module_path = File::Spec->catfile($module_dir, 'ExplicitDiscoveryProbe.pm');

    make_path($module_dir);
    write_file(
        $module_path,
        <<'PERL'
package FSM::BoundaryAudit::ExplicitDiscoveryProbe;

use strict;
use warnings;

sub new {
    my ($class) = @_;
    return bless {
        stages => [],
    }, $class;
}

sub after_parse_source {
    my ($self, $context) = @_;
    push @{$self->{stages}}, $context->stage;
    $self->{parse_source_kind} = $context->source_info->{kind};
}

sub after_generate_result {
    my ($self, $context) = @_;
    push @{$self->{stages}}, $context->stage;
    $context->result->{explicit_discovery_audit_marker} = {
        module_name => __PACKAGE__,
        parse_source_kind => $self->{parse_source_kind},
        result_source_kind => $context->source_info->{kind},
        target_language => $context->target_language,
        stages => [@{$self->{stages}}],
    };
    $context->result->{hdl_code} .= "\n// explicit discovery marker: " . __PACKAGE__ . "\n";
}

1;
PERL
    );
}

sub write_direct_fixture {
    my ($path) = @_;
    write_file(
        $path,
        <<'FSM'
(?fsm:explicit_discovery_root
  (+system
    (clock clk)
    (sreset rst)
  )
  (+size
    (OUT 1)
  )
  (idle
    (= (OUT 1))
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

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot open $path: $!";
    local $/ = undef;
    my $contents = <$fh>;
    close $fh or die "Cannot close $path: $!";
    return $contents;
}
