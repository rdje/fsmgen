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
my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $bounded_composition_path = File::Spec->catfile(
    $repo_root,
    't/corpus/composition_intent_integer_literals.fsm',
);
my $bounded_output_path = File::Spec->catfile($tempdir, 'composition_intent_integer_literals.vhd');
my $composition_path = File::Spec->catfile($tempdir, 'vhdl_composition_top.fsm');
my $output_path = File::Spec->catfile($tempdir, 'vhdl_composition_top.vhd');

write_file(
    $composition_path,
    <<'FSM'
(?top:vhdl_composition_top
  (?ports:public_io
    clk
    rstn
    output_data>8
  )
  (?fsmc:child child_src)
)

(?fsm:child_src
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

my $pipeline = FSM::Pipeline::HDLGenerator->new(
    debug_level => 0,
    target_language => 'vhdl',
    quiet => 1,
);

my $bounded_result = $pipeline->generate_hdl_from_file($bounded_composition_path);
like(
    $bounded_result->{hdl_code},
    qr/\bentity\s+composition_intent_integer_literals\s+is\b/s,
    'pipeline emits the bounded C3 external-RTL composition VHDL entity',
);
like(
    $bounded_result->{hdl_code},
    qr/\bdecimal_out\s+:\s+out\s+std_logic_vector\(4\s+downto\s+0\);/s,
    'pipeline emits VHDL structural top vector output ports',
);
like(
    $bounded_result->{hdl_code},
    qr/\bdecimal_out\s+<=\s+"10111";/s,
    'pipeline emits VHDL concurrent literal assignment',
);
like(
    $bounded_result->{hdl_code},
    qr/\bpacked_out\s+<=\s+"10111"\s+&\s+"11110110"\s+&\s+"00000000000000000001";/s,
    'pipeline emits VHDL concurrent concat assignment',
);
like(
    $bounded_result->{hdl_code},
    qr/\buart_tx\s+:\s+entity\s+work\.uart_tx\s+port\s+map\s*\(\s*decimal_in\s+=>\s+"10111",\s*negative_in\s+=>\s+"11110110",\s*packed_in\s+=>\s+"10111"\s+&\s+"11110110"\s+&\s+"00000000000000000001"\s*\);/s,
    'pipeline emits VHDL external-RTL entity port map with literal and concat actuals',
);
unlike(
    $bounded_result->{hdl_code},
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b/s,
    'pipeline bounded composition VHDL output does not leak SystemVerilog syntax',
);

my ($bounded_success, $bounded_error_message, $bounded_full_buf, $bounded_stdout_buf, $bounded_stderr_buf) = run(
    command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $bounded_output_path, $bounded_composition_path],
);

my $bounded_combined_output = join(
    '',
    @{ $bounded_stdout_buf || [] },
    @{ $bounded_stderr_buf || [] },
    ($bounded_error_message || ''),
);

ok($bounded_success, 'CLI accepts bounded composition --language vhdl for the C3 external-RTL literal/concat fixture')
    or diag($bounded_combined_output);
ok(-e $bounded_output_path, 'CLI writes bounded composition VHDL output');

my $bounded_cli_hdl = read_file($bounded_output_path);
like(
    $bounded_cli_hdl,
    qr/\bentity\s+composition_intent_integer_literals\s+is\b/s,
    'CLI bounded composition VHDL output includes the entity',
);
like(
    $bounded_cli_hdl,
    qr/\buart_tx\s+:\s+entity\s+work\.uart_tx\b/s,
    'CLI bounded composition VHDL output includes the external instance',
);
unlike(
    $bounded_cli_hdl,
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b/s,
    'CLI bounded composition VHDL output does not leak SystemVerilog syntax',
);

my $exception = eval {
    $pipeline->generate_hdl_from_file($composition_path);
    undef;
};
$exception = $@;

like(
    $exception,
    qr/recognized and parsed into typed composition IR, .*composition target support is blocked because the current active VHDL composition leaf only emits the bounded C3 external-RTL literal\/concat structural top.*Target language 'vhdl' is not implemented for this composition shape yet: generated-child composition VHDL is outside the first structural-top leaf/s,
    'pipeline now says composition target support is blocked for unsupported composition backends',
);
like(
    $exception,
    qr/docs\/COMPOSITION_SCOPE\.md/s,
    'pipeline target-support diagnostic points to the scoped composition doc',
);
like(
    $exception,
    qr/docs\/COMPOSITION_LEGACY_MAPPING\.md/s,
    'pipeline target-support diagnostic points to the legacy mapping note',
);
like(
    $exception,
    qr/Target language 'vhdl' is not implemented for this composition shape yet/s,
    'pipeline target-support diagnostic names the unsupported VHDL composition target',
);

my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
    command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $output_path, $composition_path],
);

ok(!$success, 'CLI rejects unsupported composition backend targets');
ok(!-e $output_path, 'CLI does not emit output for unsupported composition backend targets');

my $combined_output = join(
    '',
    @{ $stdout_buf || [] },
    @{ $stderr_buf || [] },
    ($error_message || ''),
);

like(
    $combined_output,
    qr/recognized and parsed into typed composition IR, .*composition target support is blocked because the current active VHDL composition leaf only emits the bounded C3 external-RTL literal\/concat structural top.*Target language 'vhdl' is not implemented for this composition shape yet: generated-child composition VHDL is outside the first structural-top leaf/s,
    'CLI surfaces the blocked composition target-support diagnostic',
);
like(
    $combined_output,
    qr/Target language 'vhdl' is not implemented for this composition shape yet/s,
    'CLI target-support diagnostic names the unsupported VHDL composition target',
);

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

sub read_file {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot open $path for read: $!";
    local $/;
    my $content = <$fh>;
    close $fh or die "Cannot close $path: $!";
    return $content;
}
