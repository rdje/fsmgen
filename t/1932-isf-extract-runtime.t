#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use IPC::Cmd qw(can_run);
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::HDLBehaviorRuntime qw(ghdl_behavior_provider run_ghdl_analysis run_ghdl_behavior);
use FSM::Test::VerilatorRuntime qw(darwin_verilator_runtime_qualified run_verilator_compile run_generated_binary);
use FSM::Pipeline::HDLGenerator;

my $work = tempdir(CLEANUP => 1);
my $source = write_file("$work/extract.isf", <<'ISF');
(actor extract_runtime
 (clock clk) (reset (rst_n async active_low))
 (interface (input start) (input cycles (width 4))
  (input packet (width 16)) (input din (width 8))
  (output header (width 4) (reset 0)) (output payload (width 8) (reset 0))
  (output crc (width 4) (reset 0)) (output observed (width 8) (reset 0)) (output done))
 (transaction main (on start) (sample din as hold) (wait cycles)
  (extract packet as header payload crc) (set observed hold) (complete done)))
ISF
my $roundtrip = write_file("$work/roundtrip.isf", <<'ISF');
(actor extract_roundtrip
 (clock clk) (reset (rst_n async active_low))
 (interface (input start) (input hi (width 4)) (input mid (width 8)) (input lo (width 4))
  (output header (width 4) (reset 0)) (output payload (width 8) (reset 0))
  (output crc (width 4) (reset 0)) (output done))
 (transaction main (on start) (assemble hi mid lo as packet)
  (extract packet as header payload crc) (complete done)))
ISF

subtest 'SystemVerilog extract capture and pending-sample timing' => sub {
    plan skip_all => 'qualified Verilator unavailable'
        unless can_run('verilator') && darwin_verilator_runtime_qualified();
    my $hdl = FSM::Pipeline::HDLGenerator->new(quiet => 1)->generate_hdl_from_file($source)->{hdl_code};
    $hdl .= FSM::Pipeline::HDLGenerator->new(quiet => 1)->generate_hdl_from_file($roundtrip)->{hdl_code};
    my $dut = write_file("$work/dut.sv", $hdl);
    my $tb = write_file("$work/tb.sv", <<'SV');
module tb;
 logic clk=0, rst_n=1, start=0;
 logic [3:0] cycles=0;
 logic [15:0] packet=0;
 logic [7:0] din=0;
 wire [3:0] header, crc;
 wire [7:0] payload, observed;
 wire done;
 wire [3:0] rt_header, rt_crc;
 wire [7:0] rt_payload;
 wire rt_done;
 always #5 clk=~clk;
 extract_runtime dut(.*);
 extract_roundtrip rt(.clk(clk),.rst_n(rst_n),.start(start),
  .hi(packet[15:12]),.mid(packet[11:4]),.lo(packet[3:0]),
  .header(rt_header),.payload(rt_payload),.crc(rt_crc),.done(rt_done));
 task tick; @(posedge clk); #1; endtask
 task activation(input int n, input int first, input int second);
  int elapsed, expected;
  @(negedge clk); start=1; cycles=4'(n); packet=16'(first); din=8'ha5;
  tick;
  @(negedge clk);start=0;
  tick; // sample materializes here; zero wait also captures the first packet.
  @(negedge clk);packet=16'(second);din=8'h3c;cycles=0;
  elapsed=0;
  while(!done && elapsed<20) begin tick;elapsed++;end
  if(!done) $fatal(1,"extract did not complete");
  expected=(n==0)?first:second;
  if({header,payload,crc}!==16'(expected)) $fatal(1,"wrong extraction/capture n=%0d got=%h expected=%h",n,{header,payload,crc},16'(expected));
  if(observed!==8'ha5) $fatal(1,"pending sample was lost or resampled");
  if({rt_header,rt_payload,rt_crc}!==16'(first)) $fatal(1,"assembled word lost its scalar width, order or capture");
  @(negedge clk);packet=0;din=0;
  repeat(4) tick;
  if({header,payload,crc}!==16'(expected) || observed!==8'ha5) $fatal(1,"extracted fields failed to hold");
  if({rt_header,rt_payload,rt_crc}!==16'(first)) $fatal(1,"roundtrip fields failed to hold");
  if(done) $fatal(1,"completion failed to clear");
 endtask
 initial begin
  #2;rst_n=0;#10;rst_n=1;
  for(int n=0;n<=4;n++)
   for(int b=0;b<16;b++) activation(n,1<<b,65535-(1<<b));
  activation(0,16'ha5c3,16'h5a3c);
  activation(2,16'h5a3c,16'ha5c3);
  @(negedge clk);rst_n=0;#1;
  if({header,payload,crc,observed}!==24'b0) $fatal(1,"field reset failed");
  if({rt_header,rt_payload,rt_crc}!==16'b0) $fatal(1,"roundtrip reset failed");
  $display("EXTRACT_RUNTIME_PASS");$finish;
 end
 initial begin #100000;$fatal(1,"timeout");end
endmodule
SV
    my $obj = "$work/obj";
    my $compile = run_verilator_compile(['verilator', '--binary', '--timing', '--assert', '-Wno-fatal',
        '--top-module', 'tb', '--Mdir', $obj, $dut, $tb]);
    ok($compile->{ok}, 'Verilator compiles actual extraction HDL') or diag($compile->{diagnostic}, $compile->{stderr});
    return unless $compile->{ok};
    my $run = run_generated_binary(["$obj/Vtb"]);
    ok($run->{ok}, 'independent extraction values, capture, hold and reset pass') or diag($run->{diagnostic}, $run->{stdout}, $run->{stderr});
    like($run->{stdout}, qr/EXTRACT_RUNTIME_PASS/, 'SystemVerilog oracle completed');
};

subtest 'VHDL extract capture and pending-sample timing' => sub {
    my $ghdl = ghdl_behavior_provider('extract_runtime');
    plan skip_all => 'GHDL provider unavailable' unless $ghdl && -x $ghdl;
    my $hdl = FSM::Pipeline::HDLGenerator->new(quiet => 1, target_language => 'vhdl')->generate_hdl_from_file($source)->{hdl_code};
    $hdl .= FSM::Pipeline::HDLGenerator->new(quiet => 1, target_language => 'vhdl')->generate_hdl_from_file($roundtrip)->{hdl_code};
    my $dut = write_file("$work/dut.vhd", $hdl);
    my $tb = write_file("$work/extract_tb.vhd", <<'VHDL');
library ieee;use ieee.std_logic_1164.all;use ieee.numeric_std.all;
entity extract_tb is end;
architecture behavior of extract_tb is
 signal clk: std_logic := '0';signal rst_n: std_logic := '1';signal start: std_logic := '0';
 signal cycles: std_logic_vector(3 downto 0) := (others=>'0');
 signal packet: std_logic_vector(15 downto 0) := (others=>'0');
 signal din: std_logic_vector(7 downto 0) := (others=>'0');
 signal header,crc: std_logic_vector(3 downto 0);
 signal payload,observed: std_logic_vector(7 downto 0);
 signal done: std_logic;
 signal rt_header,rt_crc: std_logic_vector(3 downto 0);
 signal rt_payload: std_logic_vector(7 downto 0);
 signal rt_done: std_logic;
begin
 clk <= not clk after 5 ns;
 dut: entity work.extract_runtime port map(clk=>clk,rst_n=>rst_n,start=>start,cycles=>cycles,
  packet=>packet,din=>din,header=>header,payload=>payload,crc=>crc,observed=>observed,done=>done);
 rt: entity work.extract_roundtrip port map(clk=>clk,rst_n=>rst_n,start=>start,
  hi=>packet(15 downto 12),mid=>packet(11 downto 4),lo=>packet(3 downto 0),
  header=>rt_header,payload=>rt_payload,crc=>rt_crc,done=>rt_done);
 process
  procedure tick is begin wait until rising_edge(clk);wait for 1 ns;end;
  procedure activation(n,first,second: integer) is
   variable elapsed,expected: integer;
  begin
   wait until falling_edge(clk);start<='1';cycles<=std_logic_vector(to_unsigned(n,4));
   packet<=std_logic_vector(to_unsigned(first,16));din<=x"a5";tick;
   wait until falling_edge(clk);start<='0';tick;
   wait until falling_edge(clk);packet<=std_logic_vector(to_unsigned(second,16));din<=x"3c";cycles<=(others=>'0');
   elapsed:=0;
   while done/='1' and elapsed<20 loop tick;elapsed:=elapsed+1;end loop;
   assert done='1' report "extract did not complete" severity failure;
   if n=0 then expected:=first;else expected:=second;end if;
   assert (header & payload & crc)=std_logic_vector(to_unsigned(expected,16)) report "wrong extraction/capture" severity failure;
   assert observed=x"a5" report "pending sample lost or resampled" severity failure;
   assert (rt_header & rt_payload & rt_crc)=std_logic_vector(to_unsigned(first,16)) report "assembled scalar width, order or capture failed" severity failure;
   wait until falling_edge(clk);packet<=(others=>'0');din<=(others=>'0');
   for i in 1 to 4 loop tick;end loop;
   assert (header & payload & crc)=std_logic_vector(to_unsigned(expected,16)) and observed=x"a5" report "fields failed to hold" severity failure;
   assert done='0' report "completion failed to clear" severity failure;
   assert (rt_header & rt_payload & rt_crc)=std_logic_vector(to_unsigned(first,16)) report "roundtrip fields failed to hold" severity failure;
  end;
 begin
  wait for 2 ns;rst_n<='0';wait for 10 ns;rst_n<='1';
  for n in 0 to 4 loop
   for b in 0 to 15 loop activation(n,2**b,65535-2**b);end loop;
  end loop;
  activation(0,16#a5c3#,16#5a3c#);
  activation(2,16#5a3c#,16#a5c3#);
  wait until falling_edge(clk);rst_n<='0';wait for 1 ns;
  assert (header & payload & crc & observed)=x"000000" report "field reset failed" severity failure;
  assert (rt_header & rt_payload & rt_crc)=x"0000" report "roundtrip reset failed" severity failure;
  report "EXTRACT_RUNTIME_PASS" severity note;std.env.stop;wait;
 end process;
end;
VHDL
    my $compile = run_ghdl_analysis('extract_runtime', $work, [$dut, $tb]);
    ok($compile->{ok}, 'GHDL analyzes actual extraction HDL') or diag($compile->{diagnostic}, $compile->{stderr});
    return unless $compile->{ok};
    my $result = run_ghdl_behavior('extract_runtime', $work);
    ok($result->{ok}, 'VHDL independent extraction oracle passes') or diag($result->{diagnostic}, $result->{stdout}, $result->{stderr});
    like($result->{stdout}.$result->{stderr}, qr/EXTRACT_RUNTIME_PASS/, 'VHDL oracle completed');
};
done_testing;
sub write_file {
    my ($path, $text) = @_;
    open my $fh, '>', $path or die "open $path: $!";
    print {$fh} $text or die "write $path: $!";
    close $fh or die "close $path: $!";
    return $path;
}
