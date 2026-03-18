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
my $composition_path = File::Spec->catfile($tempdir, 'invalid_token_rtlif_top.fsm');
my $metadata_path = File::Spec->catfile($tempdir, 'uart_tx.rtlif');
my $output_path = File::Spec->catfile($tempdir, 'invalid_token_rtlif_top.sv');

write_file(
    $composition_path,
    <<'FSM'
(?top:invalid_token_rtlif_top
  (?ports:public_io
    clk
    rstn
    serial_out>
  )
  (?fsmc:producer producer_src)
  (?rtl:uart_tx)
  (?toplink:wiring
    /producer.output_data/uart_tx.data_in/
    /uart_tx.txd/serial_out/
  )
)

(?fsm:producer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (output_data> <= 8'1)
  )
  (+size
    (output_data 8)
  )
)
FSM
);

write_file(
    $metadata_path,
    <<'RTLIF'
(?rtlif:uart_tx
  clk:clock
  rstn:reset
  data-in<8:data
  txd>:data
)
RTLIF
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
    qr/Composition references external RTL module 'uart_tx', .*RTL interface metadata token shape is blocked because token 'data-in<8:data' in declared interface metadata '.*uart_tx\.rtlif' is an invalid port token/s,
    'pipeline now says invalid rtlif tokens block metadata token shape',
);
like(
    $exception,
    qr/docs\/COMPOSITION_SCOPE\.md/s,
    'pipeline invalid-token rtlif diagnostic points to the scoped composition doc',
);
like(
    $exception,
    qr/docs\/COMPOSITION_LEGACY_MAPPING\.md/s,
    'pipeline invalid-token rtlif diagnostic points to the legacy mapping note',
);

my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
    command => ['./bin/fsmgen', '--quiet', '-o', $output_path, $composition_path],
);

ok(!$success, 'CLI rejects external RTL composition with invalid rtlif port tokens');
ok(!-e $output_path, 'CLI does not emit output when rtlif port tokens are invalid');

my $combined_output = join(
    '',
    @{ $stdout_buf || [] },
    @{ $stderr_buf || [] },
    ($error_message || ''),
);

like(
    $combined_output,
    qr/RTL interface metadata token shape is blocked because token 'data-in<8:data' in declared interface metadata '.*uart_tx\.rtlif' is an invalid port token/s,
    'CLI surfaces the blocked invalid-token rtlif diagnostic',
);

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
