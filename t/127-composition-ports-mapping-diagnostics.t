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
my $composition_path = File::Spec->catfile($tempdir, 'ports_mapping_top.fsm');
my $output_path = File::Spec->catfile($tempdir, 'ports_mapping_top.sv');

write_file(
    $composition_path,
    <<'FSM'
(?top:ports_mapping_top
  (?ports:public_io
    /foo/bar/
    result_data>8
  )
  (?fsmc:child child_src)
)

(?fsm:child_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (result_data> <= 8'1)
  )
  (+size
    (result_data 8)
  )
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
    qr/Composition top 'ports_mapping_top' contains '\?ports' mapping directive '\/foo\/bar\/', .*composition port declaration mode is blocked because the active composition parser only supports explicit top-port declarations inside '\?ports'/s,
    'pipeline now says legacy ports mapping directives block composition port declaration mode',
);
like(
    $exception,
    qr/docs\/COMPOSITION_SCOPE\.md/s,
    'pipeline ports-mapping diagnostic points to the scoped composition doc',
);
like(
    $exception,
    qr/docs\/COMPOSITION_LEGACY_MAPPING\.md/s,
    'pipeline ports-mapping diagnostic points to the legacy mapping note',
);

my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
    command => ['./bin/fsmgen', '--quiet', '-o', $output_path, $composition_path],
);

ok(!$success, 'CLI rejects composition with legacy ?ports mapping directives');
ok(!-e $output_path, 'CLI does not emit output for legacy ?ports mapping directives');

my $combined_output = join(
    '',
    @{ $stdout_buf || [] },
    @{ $stderr_buf || [] },
    ($error_message || ''),
);

like(
    $combined_output,
    qr/composition port declaration mode is blocked because the active composition parser only supports explicit top-port declarations inside '\?ports'/s,
    'CLI surfaces the blocked ports-mapping diagnostic',
);

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
