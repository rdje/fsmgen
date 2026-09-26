#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use IPC::Cmd qw(can_run);
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::ProcessSupervisor qw(supervise_process);
use FSM::Pipeline::HDLGenerator;

my $dir = tempdir(CLEANUP => 1);
my @cases = (
    ['gt_one', '(> DATA 1\'b1)', 'n > 1'],
    ['ge_one', '(>= DATA 1\'b1)', 'n >= 1'],
    ['lt_one', '(< DATA 1\'b1)', 'n < 1'],
    ['le_one', '(<= DATA 1\'b1)', 'n <= 1'],
    ['eq_one', '(== DATA 1\'b1)', 'n = 1'],
    ['ne_one', '(!= DATA 1\'b1)', 'n /= 1'],
    ['reverse_gt', '(> 1\'b1 DATA)', '1 > n'],
    ['reverse_le', '(<= 1\'b1 DATA)', '1 <= n'],
    ['narrow_gt', '(> DATA 2\'b10)', 'n > 2'],
    ['reverse_narrow', '(< 2\'b10 DATA)', '2 < n'],
    ['wide_lt', '(< DATA 8\'h10)', 'n < 16'],
    ['reverse_wide', '(> 8\'h10 DATA)', '16 > n'],
    ['same_eq', '(== DATA 4\'d2)', 'n = 2'],
    ['scalar_eq', '(== FLAG 1\'b1)', '(n mod 2) = 1'],
    ['vector_result', '(> DATA 1\'b1)', 'n > 1', 3],
);
my $source = "(?dt:unsigned_comparisons (+size (DATA 4) (FLAG 1) "
    . join(' ', map { "($_->[0] " . ($_->[3] // 1) . ")" } @cases) . ")\n(-evaluate "
    . join(' ', map { "(= ($_->[0] $_->[1]))" } @cases) . "))\n";
my $file = write_file("$dir/source.fsm", $source);
my $hdl = FSM::Pipeline::HDLGenerator->new(quiet => 1, target_language => 'vhdl')->generate_hdl_from_file($file)->{hdl_code};
like($hdl, qr/entity unsigned_comparisons is/, 'public pipeline emits unsigned comparison design');
my $ghdl = $ENV{FSMGEN_RESET_GHDL} // 'ghdl';
$ghdl = $ghdl =~ m{/} ? abs_path($ghdl) : can_run($ghdl);
SKIP: {
    skip 'GHDL provider unavailable', 3 unless $ghdl && -x $ghdl;
    my $dut = write_file("$dir/dut.vhd", $hdl);
    my $signals = join(', ', map { $_->[0] } grep { !$_->[3] } @cases);
    my $ports = join(', ', map { "$_->[0]=>$_->[0]" } @cases);
    my $assertions = join("\n", map {
        my $conversion = $_->[3] ? 'logic_vector' : 'logic_bit';
        "   assert $_->[0]=$conversion($_->[2]) report \"$_->[0] mismatch at \" & integer'image(n) severity failure;"
    } @cases);
    my $tb = write_file("$dir/comparison_tb.vhd", <<"VHDL");
library ieee;use ieee.std_logic_1164.all;use ieee.numeric_std.all;
entity comparison_tb is end;
architecture behavior of comparison_tb is
 signal data_value:std_logic_vector(3 downto 0):=(others=>'0');
 signal flag_value:std_logic:='0';
 signal $signals:std_logic;
 signal vector_result:std_logic_vector(2 downto 0);
 function logic_bit(value:boolean) return std_logic is
 begin if value then return '1';else return '0';end if;end;
 function logic_vector(value:boolean) return std_logic_vector is
 begin if value then return "001";else return "000";end if;end;
begin
 dut:entity work.unsigned_comparisons port map(DATA=>data_value,FLAG=>flag_value,$ports);
 process begin
  for n in 0 to 15 loop
   data_value<=std_logic_vector(to_unsigned(n,4));flag_value<=logic_bit((n mod 2)=1);wait for 1 ns;
$assertions
  end loop;
  report "COMPARISON_TRUTH_PASS" severity note;std.env.stop;wait;
 end process;
end;
VHDL
    my $run = sub { supervise_process(schema => 'fsmgen.test.unsigned_comparison.v1', stage => 'ghdl',
        bounds => {timeout_seconds => 60, capture_limit_bytes => 1_048_576},
        containment => 'test_runtime_process_group', cwd => $dir, argv => $_[0]) };
    my $compile = $run->([$ghdl, '-a', '--std=08', '--workdir='.$dir, $dut, $tb]);
    ok($compile->{ok}, 'GHDL analysis of comparison types') or diag($compile->{diagnostic}, $compile->{stderr});
    if (!$compile->{ok}) { fail('runtime compilation failed'); fail('runtime observation absent'); }
    else {
        my $result = $run->([$ghdl, '--elab-run', '--std=08', '--workdir='.$dir, 'comparison_tb', '--assert-level=error', '--stop-time=100ns']);
        ok($result->{ok}, 'independent integer truth table matches') or diag($result->{diagnostic}, $result->{stdout}, $result->{stderr});
        like($result->{stdout}.$result->{stderr}, qr/COMPARISON_TRUTH_PASS/, 'every comparison observation completed');
    }
}
done_testing();
sub write_file {
    my ($path, $text) = @_;
    open my $fh, '>', $path or die "open $path: $!"; print {$fh} $text; close $fh or die "close $path: $!"; return $path;
}
