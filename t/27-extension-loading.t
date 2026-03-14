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
my $fsm_path = File::Spec->catfile($tempdir, 'extension_loader_smoke.fsm');
my $cli_output_path = File::Spec->catfile($tempdir, 'extension_loader_smoke.sv');
my $missing_output_path = File::Spec->catfile($tempdir, 'missing_extension.sv');
my $test_lib = File::Spec->catdir($FindBin::Bin, 'lib');

write_file(
    $fsm_path,
    <<'FSM'
(?fsm:extension_loader_smoke
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

my $loader = FSM::Extension::Loader->new();
my $extensions = $loader->load_modules(['FSM::TestExtension::Marker']);

is(ref($extensions), 'ARRAY', 'loader returns an array reference of extension objects');
is(scalar(@$extensions), 1, 'loader returns one extension object for one module name');
isa_ok($extensions->[0], 'FSM::TestExtension::Marker');

my $invalid_error = eval {
    $loader->load_modules(['bad;name']);
    undef;
};
$invalid_error = $@;

like(
    $invalid_error,
    qr/rejects invalid extension module name 'bad;name'/s,
    'loader rejects invalid module names before require dispatch',
);

my $pipeline = FSM::Pipeline::HDLGenerator->new(
    debug_level => 0,
    target_language => 'systemverilog',
    quiet => 1,
    extension_modules => ['FSM::TestExtension::Marker'],
);

my $result = $pipeline->generate_hdl_from_file($fsm_path);
is(
    $result->{extension_marker}{module_name},
    'FSM::TestExtension::Marker',
    'pipeline can instantiate extension modules through the typed loader',
);
is(
    $result->{extension_marker}{parsed_kind},
    'fsm',
    'module-loaded extension also sees the typed parse-source hook before result generation',
);
like(
    $result->{hdl_code},
    qr{// extension marker: FSM::TestExtension::Marker}s,
    'loaded extension module can mutate the returned HDL result',
);
like(
    $result->{hdl_code},
    qr{// parsed source kind: fsm}s,
    'module-loaded extension can reflect parse-hook state into the generated HDL result',
);

my ($cli_success, $cli_error_message, $cli_full_buf, $cli_stdout_buf, $cli_stderr_buf) = run(
    command => [
        $^X,
        '-I', $test_lib,
        './bin/fsmgen',
        '--extension-module', 'FSM::TestExtension::Marker',
        '-o', $cli_output_path,
        '--quiet',
        $fsm_path,
    ],
);

ok($cli_success, 'CLI succeeds when given an explicit typed extension module');
ok(-e $cli_output_path, 'CLI writes HDL output when extension loading succeeds');

my $cli_hdl = slurp($cli_output_path);
like(
    $cli_hdl,
    qr{// extension marker: FSM::TestExtension::Marker}s,
    'CLI-loaded extension module can affect generated HDL output',
);
like(
    $cli_hdl,
    qr{// parsed source kind: fsm}s,
    'CLI-loaded extension module can also reflect parse-hook state into output',
);

my ($missing_success, $missing_error_message, $missing_full_buf, $missing_stdout_buf, $missing_stderr_buf) = run(
    command => [
        $^X,
        '-I', $test_lib,
        './bin/fsmgen',
        '--extension-module', 'FSM::TestExtension::Missing',
        '-o', $missing_output_path,
        '--quiet',
        $fsm_path,
    ],
);

ok(!$missing_success, 'CLI fails when an explicit extension module cannot be loaded');
ok(!-e $missing_output_path, 'CLI does not emit output when extension loading fails');

my $missing_output = join(
    '',
    @{ $missing_stdout_buf || [] },
    @{ $missing_stderr_buf || [] },
    ($missing_error_message || ''),
);

like(
    $missing_output,
    qr/Unable to load extension module 'FSM::TestExtension::Missing'/s,
    'CLI surfaces a targeted extension-loading diagnostic',
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
