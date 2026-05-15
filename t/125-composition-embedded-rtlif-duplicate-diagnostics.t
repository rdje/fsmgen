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
my $composition_path = File::Spec->catfile($tempdir, 'duplicate_embedded_rtlif_diag_top.fsm');
my $output_path = File::Spec->catfile($tempdir, 'duplicate_embedded_rtlif_diag_top.sv');

write_file(
    $composition_path,
    <<'FSM'
(?top:duplicate_embedded_rtlif_diag_top
  (?ports:public_io
    clk
    rst_n
    serial_out>
  )
  (?dtc:router route_src)
  (?rtl:uart_tx)
  (?wiring:wiring
    /router.route_data/uart_tx.data_in/
    /uart_tx.txd/serial_out/
  )
)

(?dt:route_src
  (-route
    (route_data> = payload_in)
  )
  (+size
    (payload_in 8)
    (route_data 8)
  )
)

(?rtlif:uart_tx
  clk:clock
  rst_n:reset
  data_in<8:data
  txd>:data
)

(?rtlif:uart_tx
  clk
  rst_n
  txd>
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
    qr/Composition source '.*duplicate_embedded_rtlif_diag_top\.fsm' contains multiple embedded '\?rtlif:uart_tx' roots, .*RTL interface metadata embedded-root uniqueness is blocked/s,
    'pipeline now says duplicate embedded rtlif roots block embedded-root uniqueness',
);
like(
    $exception,
    qr/docs\/COMPOSITION_SCOPE\.md/s,
    'pipeline duplicate-embedded-rtlif diagnostic points to the scoped composition doc',
);
like(
    $exception,
    qr/docs\/COMPOSITION_LEGACY_MAPPING\.md/s,
    'pipeline duplicate-embedded-rtlif diagnostic points to the legacy mapping note',
);

my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
    command => ['./bin/fsmgen', '--quiet', '-o', $output_path, $composition_path],
);

ok(!$success, 'CLI rejects composition with duplicate embedded rtlif roots');
ok(!-e $output_path, 'CLI does not emit output when embedded rtlif roots are duplicated');

my $combined_output = join(
    '',
    @{ $stdout_buf || [] },
    @{ $stderr_buf || [] },
    ($error_message || ''),
);

like(
    $combined_output,
    qr/RTL interface metadata embedded-root uniqueness is blocked because the active RTL interface contract allows at most one embedded interface root per external RTL module name in the same source\./s,
    'CLI surfaces the blocked duplicate-embedded-rtlif diagnostic',
);

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
