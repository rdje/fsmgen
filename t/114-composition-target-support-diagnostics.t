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
my $standalone_dtc_composition_path = File::Spec->catfile(
    $repo_root,
    't/corpus/standalone_dtc_explicit_system_autowire.fsm',
);
my $generated_fsmc_composition_path = File::Spec->catfile(
    $repo_root,
    't/corpus/implicit_composition_system_autowire.fsm',
);
my $apb_c4_composition_path = File::Spec->catfile(
    $repo_root,
    'fsm/apb_tb.fsm',
);
my $bounded_output_path = File::Spec->catfile($tempdir, 'composition_intent_integer_literals.vhd');
my $standalone_dtc_output_path = File::Spec->catfile($tempdir, 'standalone_dtc_explicit_system_autowire.vhd');
my $generated_fsmc_output_path = File::Spec->catfile($tempdir, 'implicit_composition_system_autowire.vhd');
my $apb_c4_output_path = File::Spec->catfile($tempdir, 'apb_tb.vhd');
my $scalar_generic_map_path = File::Spec->catfile($tempdir, 'vhdl_scalar_generic_map_top.fsm');
my $scalar_generic_map_output_path = File::Spec->catfile($tempdir, 'vhdl_scalar_generic_map_top.vhd');
my $vector_generic_map_path = File::Spec->catfile($tempdir, 'vhdl_vector_generic_map_deferred_top.fsm');
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
write_file(
    $scalar_generic_map_path,
    <<'FSM'
(?top:vhdl_scalar_generic_map_top
  (?ports:public_io
    clk
    payload_in<16
    serial_out>
  )
  (?rtl:u_uart
    (module uart_tx)
    (params
      (WIDTH 16)
    )
  )
  (?wiring:wiring
    /payload_in/u_uart.data_in/
    /u_uart.txd/serial_out/
  )
)

(?rtlif:uart_tx
  (params
    (WIDTH 8)
  )
  clk:clock
  data_in<16:data
  txd>:data
)
FSM
);
write_file(
    $vector_generic_map_path,
    <<'FSM'
(?top:vhdl_vector_generic_map_deferred_top
  (?ports:public_io
    clk
    payload_in<8
    serial_out>
  )
  (?rtl:u_uart
    (module uart_tx)
    (params
      (RESET_VALUE 8'hA5)
    )
  )
  (?wiring:wiring
    /payload_in/u_uart.data_in/
    /u_uart.txd/serial_out/
  )
)

(?rtlif:uart_tx
  (params
    (RESET_VALUE 8'h00)
  )
  clk:clock
  data_in<8:data
  txd>:data
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

my $scalar_generic_map_result = $pipeline->generate_hdl_from_file($scalar_generic_map_path);
like(
    $scalar_generic_map_result->{hdl_code},
    qr/\bentity\s+vhdl_scalar_generic_map_top\s+is\b/s,
    'pipeline emits the scalar generic-map VHDL composition entity',
);
like(
    $scalar_generic_map_result->{hdl_code},
    qr/\bu_uart\s+:\s+entity\s+work\.uart_tx\s+generic\s+map\s*\(\s*WIDTH\s+=>\s+16\s*\)\s+port\s+map\s*\(\s*clk\s+=>\s+clk,\s*data_in\s+=>\s+payload_in,\s*txd\s+=>\s+serial_out\s*\);/s,
    'pipeline emits the VHDL scalar integer generic map before the external RTL port map',
);
unlike(
    $scalar_generic_map_result->{hdl_code},
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(/s,
    'pipeline scalar generic-map VHDL output does not leak SystemVerilog structural syntax',
);

my $vector_generic_exception = eval {
    $pipeline->generate_hdl_from_file($vector_generic_map_path);
    undef;
};
$vector_generic_exception = $@;

like(
    $vector_generic_exception,
    qr/Structural VHDL composition-top scaffold unsupported: composition VHDL generic maps are currently limited to scalar integer actuals/s,
    'pipeline keeps vector generic-map actuals outside the bounded VHDL scaffold',
);

my $standalone_dtc_result = $pipeline->generate_hdl_from_file($standalone_dtc_composition_path);
like(
    $standalone_dtc_result->{hdl_code},
    qr/\bentity\s+standalone_route_src\s+is\b/s,
    'pipeline emits the standalone-DT child VHDL entity',
);
like(
    $standalone_dtc_result->{hdl_code},
    qr/\bentity\s+standalone_dtc_explicit_system_autowire\s+is\b/s,
    'pipeline emits the bounded C1 standalone-DT composition VHDL entity',
);
like(
    $standalone_dtc_result->{hdl_code},
    qr/\brouter\s+:\s+entity\s+work\.standalone_route_src\s+port\s+map\s*\(\s*clk\s+=>\s+clk,\s*rst_n\s+=>\s+rst_n,\s*data_in\s+=>\s+data_in,\s*result_data\s+=>\s+result_data\s*\);/s,
    'pipeline emits the standalone-DT child VHDL entity port map',
);
unlike(
    $standalone_dtc_result->{hdl_code},
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b/s,
    'pipeline standalone-DT composition VHDL output does not leak SystemVerilog syntax',
);

my $generated_fsmc_result = $pipeline->generate_hdl_from_file($generated_fsmc_composition_path);
like(
    $generated_fsmc_result->{hdl_code},
    qr/\bentity\s+implicit_autowire_producer\s+is\b/s,
    'pipeline emits the generated-FSM producer child VHDL entity',
);
like(
    $generated_fsmc_result->{hdl_code},
    qr/\bshared_dp_export_output_data_1_b1_en\s+:\s+out\s+std_logic\b/s,
    'pipeline emits VHDL shared-datapath export ports on generated-FSM children',
);
like(
    $generated_fsmc_result->{hdl_code},
    qr/\bentity\s+implicit_composition_system_autowire\s+is\b/s,
    'pipeline emits the bounded C2 generated-FSM composition VHDL entity',
);
like(
    $generated_fsmc_result->{hdl_code},
    qr/\bsignal\s+comp_link_producer_output_data\s+:\s+std_logic;/s,
    'pipeline emits VHDL scalar internal structural signals',
);
like(
    $generated_fsmc_result->{hdl_code},
    qr/\bproducer\s+:\s+entity\s+work\.implicit_autowire_producer\s+port\s+map\s*\(\s*clk\s+=>\s+clk,\s*rst_n\s+=>\s+rst_n,\s*output_data\s+=>\s+comp_link_producer_output_data,\s*shared_dp_export_output_data_1_b1_en\s+=>\s+shared_dp_unused_producer_shared_dp_export_output_data_1_b1_en\s*\);/s,
    'pipeline emits the generated-FSM producer VHDL entity port map',
);
like(
    $generated_fsmc_result->{hdl_code},
    qr/\bconsumer\s+:\s+entity\s+work\.implicit_autowire_consumer\s+port\s+map\s*\(\s*clk\s+=>\s+clk,\s*rst_n\s+=>\s+rst_n,\s*input_data\s+=>\s+comp_link_producer_output_data,\s*result_data\s+=>\s+result_data,\s*shared_dp_export_result_data_input_data_en\s+=>\s+shared_dp_unused_consumer_shared_dp_export_result_data_input_data_en\s*\);/s,
    'pipeline emits the generated-FSM consumer VHDL entity port map',
);
unlike(
    $generated_fsmc_result->{hdl_code},
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b/s,
    'pipeline generated-FSM composition VHDL output does not leak SystemVerilog syntax',
);

my $apb_c4_result = $pipeline->generate_hdl_from_file($apb_c4_composition_path);
like(
    $apb_c4_result->{hdl_code},
    qr/\bentity\s+apb_requester\s+is\b/s,
    'pipeline emits the APB requester child VHDL entity',
);
like(
    $apb_c4_result->{hdl_code},
    qr/\bshared_dp_export_paddr_32_h0_en\s+:\s+out\s+std_logic\b/s,
    'pipeline emits APB requester shared-datapath export ports',
);
like(
    $apb_c4_result->{hdl_code},
    qr/\bentity\s+apb_completer\s+is\b/s,
    'pipeline emits the APB completer child VHDL entity',
);
like(
    $apb_c4_result->{hdl_code},
    qr/\bentity\s+apb_tb\s+is\b/s,
    'pipeline emits the bounded APB/C4 composition VHDL entity',
);
like(
    $apb_c4_result->{hdl_code},
    qr/\breq_addr\s+:\s+in\s+std_logic_vector\(31\s+downto\s+0\);/s,
    'pipeline emits APB vector top input ports',
);
like(
    $apb_c4_result->{hdl_code},
    qr/\bwait_cycles\s+:\s+in\s+std_logic_vector\(3\s+downto\s+0\);/s,
    'pipeline emits APB wait-cycle vector top input port',
);
like(
    $apb_c4_result->{hdl_code},
    qr/\bsignal\s+comp_link_requester_PADDR\s+:\s+std_logic_vector\(31\s+downto\s+0\);/s,
    'pipeline emits APB vector internal structural signals',
);
like(
    $apb_c4_result->{hdl_code},
    qr/\brequester\s+:\s+entity\s+work\.apb_requester\b/s,
    'pipeline emits the APB requester VHDL entity port map',
);
like(
    $apb_c4_result->{hdl_code},
    qr/\bPADDR\s+=>\s+comp_link_requester_PADDR,/s,
    'pipeline maps requester APB address output to the structural link signal',
);
like(
    $apb_c4_result->{hdl_code},
    qr/\bcompleter\s+:\s+entity\s+work\.apb_completer\b/s,
    'pipeline emits the APB completer VHDL entity port map',
);
like(
    $apb_c4_result->{hdl_code},
    qr/\bPRDATA\s+=>\s+comp_link_completer_PRDATA,/s,
    'pipeline maps completer APB read-data output to the structural link signal',
);
unlike(
    $apb_c4_result->{hdl_code},
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b/s,
    'pipeline APB/C4 composition VHDL output does not leak SystemVerilog syntax',
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

my ($scalar_generic_map_success, $scalar_generic_map_error_message, $scalar_generic_map_full_buf, $scalar_generic_map_stdout_buf, $scalar_generic_map_stderr_buf) = run(
    command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $scalar_generic_map_output_path, $scalar_generic_map_path],
);

my $scalar_generic_map_combined_output = join(
    '',
    @{ $scalar_generic_map_stdout_buf || [] },
    @{ $scalar_generic_map_stderr_buf || [] },
    ($scalar_generic_map_error_message || ''),
);

ok($scalar_generic_map_success, 'CLI accepts bounded composition --language vhdl for the scalar generic-map external-RTL fixture')
    or diag($scalar_generic_map_combined_output);
ok(-e $scalar_generic_map_output_path, 'CLI writes scalar generic-map composition VHDL output');

my $scalar_generic_map_cli_hdl = read_file($scalar_generic_map_output_path);
like(
    $scalar_generic_map_cli_hdl,
    qr/\bu_uart\s+:\s+entity\s+work\.uart_tx\s+generic\s+map\s*\(\s*WIDTH\s+=>\s+16\s*\)\s+port\s+map\s*\(\s*clk\s+=>\s+clk,\s*data_in\s+=>\s+payload_in,\s*txd\s+=>\s+serial_out\s*\);/s,
    'CLI scalar generic-map composition VHDL output includes the generic map',
);
unlike(
    $scalar_generic_map_cli_hdl,
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b|\#\s*\(/s,
    'CLI scalar generic-map composition VHDL output does not leak SystemVerilog syntax',
);

my ($standalone_dtc_success, $standalone_dtc_error_message, $standalone_dtc_full_buf, $standalone_dtc_stdout_buf, $standalone_dtc_stderr_buf) = run(
    command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $standalone_dtc_output_path, $standalone_dtc_composition_path],
);

my $standalone_dtc_combined_output = join(
    '',
    @{ $standalone_dtc_stdout_buf || [] },
    @{ $standalone_dtc_stderr_buf || [] },
    ($standalone_dtc_error_message || ''),
);

ok($standalone_dtc_success, 'CLI accepts bounded composition --language vhdl for the C1 standalone-DT fixture')
    or diag($standalone_dtc_combined_output);
ok(-e $standalone_dtc_output_path, 'CLI writes bounded standalone-DT composition VHDL output');

my $standalone_dtc_cli_hdl = read_file($standalone_dtc_output_path);
like(
    $standalone_dtc_cli_hdl,
    qr/\bentity\s+standalone_route_src\s+is\b/s,
    'CLI standalone-DT composition VHDL output includes the child entity',
);
like(
    $standalone_dtc_cli_hdl,
    qr/\brouter\s+:\s+entity\s+work\.standalone_route_src\b/s,
    'CLI standalone-DT composition VHDL output includes the child instance',
);
unlike(
    $standalone_dtc_cli_hdl,
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b/s,
    'CLI standalone-DT composition VHDL output does not leak SystemVerilog syntax',
);

my ($generated_fsmc_success, $generated_fsmc_error_message, $generated_fsmc_full_buf, $generated_fsmc_stdout_buf, $generated_fsmc_stderr_buf) = run(
    command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $generated_fsmc_output_path, $generated_fsmc_composition_path],
);

my $generated_fsmc_combined_output = join(
    '',
    @{ $generated_fsmc_stdout_buf || [] },
    @{ $generated_fsmc_stderr_buf || [] },
    ($generated_fsmc_error_message || ''),
);

ok($generated_fsmc_success, 'CLI accepts bounded composition --language vhdl for the C2 generated-FSM fixture')
    or diag($generated_fsmc_combined_output);
ok(-e $generated_fsmc_output_path, 'CLI writes bounded generated-FSM composition VHDL output');

my $generated_fsmc_cli_hdl = read_file($generated_fsmc_output_path);
like(
    $generated_fsmc_cli_hdl,
    qr/\bentity\s+implicit_autowire_producer\s+is\b/s,
    'CLI generated-FSM composition VHDL output includes the producer child entity',
);
like(
    $generated_fsmc_cli_hdl,
    qr/\bsignal\s+comp_link_producer_output_data\s+:\s+std_logic;/s,
    'CLI generated-FSM composition VHDL output includes scalar structural signals',
);
like(
    $generated_fsmc_cli_hdl,
    qr/\bconsumer\s+:\s+entity\s+work\.implicit_autowire_consumer\b/s,
    'CLI generated-FSM composition VHDL output includes the consumer child instance',
);
unlike(
    $generated_fsmc_cli_hdl,
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b/s,
    'CLI generated-FSM composition VHDL output does not leak SystemVerilog syntax',
);

my ($apb_c4_success, $apb_c4_error_message, $apb_c4_full_buf, $apb_c4_stdout_buf, $apb_c4_stderr_buf) = run(
    command => ['./bin/fsmgen', '--language', 'vhdl', '--quiet', '-o', $apb_c4_output_path, $apb_c4_composition_path],
);

my $apb_c4_combined_output = join(
    '',
    @{ $apb_c4_stdout_buf || [] },
    @{ $apb_c4_stderr_buf || [] },
    ($apb_c4_error_message || ''),
);

ok($apb_c4_success, 'CLI accepts bounded composition --language vhdl for the APB/C4 fixture')
    or diag($apb_c4_combined_output);
ok(-e $apb_c4_output_path, 'CLI writes bounded APB/C4 composition VHDL output');

my $apb_c4_cli_hdl = read_file($apb_c4_output_path);
like(
    $apb_c4_cli_hdl,
    qr/\bentity\s+apb_tb\s+is\b/s,
    'CLI APB/C4 composition VHDL output includes the top entity',
);
like(
    $apb_c4_cli_hdl,
    qr/\bsignal\s+comp_link_requester_PWDATA\s+:\s+std_logic_vector\(31\s+downto\s+0\);/s,
    'CLI APB/C4 composition VHDL output includes vector structural signals',
);
like(
    $apb_c4_cli_hdl,
    qr/\bcompleter\s+:\s+entity\s+work\.apb_completer\b/s,
    'CLI APB/C4 composition VHDL output includes the completer child instance',
);
unlike(
    $apb_c4_cli_hdl,
    qr/\bmodule\b|\bassign\b|\bendmodule\b|\balways_(?:ff|comb)\b/s,
    'CLI APB/C4 composition VHDL output does not leak SystemVerilog syntax',
);

my $exception = eval {
    $pipeline->generate_hdl_from_file($composition_path);
    undef;
};
$exception = $@;

like(
    $exception,
    qr/recognized and parsed into typed composition IR, .*composition target support is blocked because the current active VHDL composition leaves only emit the bounded C3 external-RTL literal\/concat structural top, C1 standalone-DT passthrough structural top, C2 generated-FSM scalar autowire structural top, and APB\/C4 generated-FSM structural top.*Target language 'vhdl' is not implemented for this composition shape yet: generated-child composition VHDL is outside the bounded C2 scalar-autowire and APB\/C4 generated-FSM structural-top leaves/s,
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
    qr/recognized and parsed into typed composition IR, .*composition target support is blocked because the current active VHDL composition leaves only emit the bounded C3 external-RTL literal\/concat structural top, C1 standalone-DT passthrough structural top, C2 generated-FSM scalar autowire structural top, and APB\/C4 generated-FSM structural top.*Target language 'vhdl' is not implemented for this composition shape yet: generated-child composition VHDL is outside the bounded C2 scalar-autowire and APB\/C4 generated-FSM structural-top leaves/s,
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
