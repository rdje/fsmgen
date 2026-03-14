#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use FSM::Extension::Loader;
use FSM::Pipeline::HDLGenerator;

my $tempdir = tempdir(CLEANUP => 1);
my $fsm_path = File::Spec->catfile($tempdir, 'extension_config_smoke.fsm');
my $config_path = File::Spec->catfile($tempdir, 'extensions.fsmext');
my $bad_config_path = File::Spec->catfile($tempdir, 'bad_extensions.fsmext');
my $cli_output_path = File::Spec->catfile($tempdir, 'extension_config_smoke.sv');
my $bad_output_path = File::Spec->catfile($tempdir, 'bad_extension_config.sv');
my $test_lib = File::Spec->catdir($FindBin::Bin, 'lib');

write_file(
    $fsm_path,
    <<'FSM'
(?fsm:extension_config_smoke
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (OUT <= 1)
  )
  (+size
    (OUT 1)
  )
)
FSM
);

write_file(
    $config_path,
    <<'CFG'
# Explicit typed extension config
module FSM::TestExtension::Marker
CFG
);

write_file(
    $bad_config_path,
    <<'CFG'
module FSM::TestExtension::Marker
bad syntax here
CFG
);

my $loader = FSM::Extension::Loader->new();
my $module_names = $loader->module_names_from_config_files([$config_path]);
is_deeply(
    $module_names,
    ['FSM::TestExtension::Marker'],
    'loader parses explicit module names from extension config files',
);

my $config_error = eval {
    $loader->module_names_from_config_files([$bad_config_path]);
    undef;
};
$config_error = $@;

like(
    $config_error,
    qr/Invalid extension config line at '\Q$bad_config_path\E' line 2/s,
    'loader reports invalid extension-config syntax with file and line number',
);

my $pipeline = FSM::Pipeline::HDLGenerator->new(
    debug_level => 0,
    target_language => 'systemverilog',
    quiet => 1,
    extension_config_files => [$config_path],
);

my $result = $pipeline->generate_hdl_from_file($fsm_path);
is(
    $result->{extension_marker}{module_name},
    'FSM::TestExtension::Marker',
    'pipeline can load typed extensions from explicit config files',
);
like(
    $result->{hdl_code},
    qr{// extension marker: FSM::TestExtension::Marker}s,
    'config-loaded extension can mutate the returned HDL result',
);

my ($cli_success, $cli_error_message, $cli_full_buf, $cli_stdout_buf, $cli_stderr_buf) = run(
    command => [
        $^X,
        '-I', $test_lib,
        './bin/fsmgen',
        '--extension-config', $config_path,
        '-o', $cli_output_path,
        '--quiet',
        $fsm_path,
    ],
);

ok($cli_success, 'CLI succeeds when given an explicit extension config file');
ok(-e $cli_output_path, 'CLI writes HDL output when extension-config loading succeeds');

my $cli_hdl = slurp($cli_output_path);
like(
    $cli_hdl,
    qr{// extension marker: FSM::TestExtension::Marker}s,
    'CLI config-loaded extension can affect generated HDL output',
);

my ($bad_success, $bad_error_message, $bad_full_buf, $bad_stdout_buf, $bad_stderr_buf) = run(
    command => [
        $^X,
        '-I', $test_lib,
        './bin/fsmgen',
        '--extension-config', $bad_config_path,
        '-o', $bad_output_path,
        '--quiet',
        $fsm_path,
    ],
);

ok(!$bad_success, 'CLI fails when an explicit extension config file is malformed');
ok(!-e $bad_output_path, 'CLI does not emit output when extension-config loading fails');

my $bad_output = join(
    '',
    @{ $bad_stdout_buf || [] },
    @{ $bad_stderr_buf || [] },
    ($bad_error_message || ''),
);

like(
    $bad_output,
    qr/Invalid extension config line at '\Q$bad_config_path\E' line 2/s,
    'CLI surfaces a targeted extension-config diagnostic',
);

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot open $path: $!";
    local $/ = undef;
    my $content = <$fh>;
    close $fh or die "Cannot close $path: $!";
    return $content;
}
