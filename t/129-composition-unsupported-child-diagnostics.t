#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

my $tempdir = tempdir(CLEANUP => 1);
my $composition_path = File::Spec->catfile($tempdir, 'unsupported_child_top.fsm');
my $output_path = File::Spec->catfile($tempdir, 'unsupported_child_top.sv');

write_file(
    $composition_path,
    <<'FSM'
(?top:unsupported_child_top
  (?bogus:child foo)
)
FSM
);

my $pipeline = FSM::Pipeline::HDLGenerator->new(
    debug_level => 0,
    target_language => 'systemverilog',
    quiet => 1,
);

my $exception = eval {
    $pipeline->generate_hdl_from_file($composition_path);
    undef;
};
$exception = $@;

like(
    $exception,
    qr/Composition top 'unsupported_child_top' contains child '\?bogus:child', .*composition child kind support is blocked because the active composition parser currently accepts only '\?fsmc', '\?dtc', '\?rtl', '\?ports', '\?toplink', '\+constants', '\+enums', and '\+import'/s,
    'pipeline now says unsupported child kinds block composition child-kind support',
);
like(
    $exception,
    qr/docs\/COMPOSITION_SCOPE\.md/s,
    'pipeline unsupported-child diagnostic points to the scoped composition doc',
);
like(
    $exception,
    qr/docs\/COMPOSITION_LEGACY_MAPPING\.md/s,
    'pipeline unsupported-child diagnostic points to the legacy mapping note',
);

my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
    command => ['./bin/fsmgen', '--quiet', '-o', $output_path, $composition_path],
);

ok(!$success, 'CLI rejects unsupported composition child kinds');
ok(!-e $output_path, 'CLI does not emit output for unsupported composition child kinds');

my $combined_output = join(
    '',
    @{ $stdout_buf || [] },
    @{ $stderr_buf || [] },
    ($error_message || ''),
);

like(
    $combined_output,
    qr/composition child kind support is blocked because the active composition parser currently accepts only '\?fsmc', '\?dtc', '\?rtl', '\?ports', '\?toplink', '\+constants', '\+enums', and '\+import'/s,
    'CLI surfaces the blocked unsupported-child diagnostic',
);

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
