#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(can_run);
use JSON::PP ();
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Test::VerilatorRuntime qw(darwin_verilator_runtime_qualified run_verilator_compile run_generated_binary);
use FSM::Test::HDLBehaviorRuntime qw(ghdl_behavior_provider run_ghdl_analysis run_ghdl_behavior);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $work = tempdir(CLEANUP => 1);
my $root = abs_path('.');
my $capture = \&FSM::Test::SourceQueryRunner::_capture;
my $json = JSON::PP->new->canonical->utf8;
my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
my $audit = $json->decode(read_file('docs/audits/specforge-storage-register-access-intake-20260926.json'));
my %sources = map {my ($name) = $_->{source}{path} =~ m{/([^/]+)\.isf\z}; $name => $_->{source}{text}} @{$audit->{cases}};
my $baseline = $sources{'baseline-good'};
my $nonzero = $baseline;
$nonzero =~ s/\(var status \(width 8\) \(reset 0\)\)/(var status (width 8) (reset 19))/;
my $unreset = $baseline;
$unreset =~ s/\(var status \(width 8\) \(reset 0\)\)/(var status (width 8))/;
my $unused = $nonzero;
$unused =~ s/\(storage/(types (type signed_word_t (signed (bits 6))))\n  (storage\n    (var spare (width 7) (reset 5))\n    (var typed_spare (type signed_word_t))\n    (bank slots (width 4) (depth 2))/;
my $named = $nonzero;
$named =~ s/\(clock clk\)\s*\(reset \(rst_n async active_low\)\)/(clock-domains (domain core (clock clk) (reset (rst_n async active_low))))/;
my $domains = $nonzero;
$domains =~ s/\(clock clk\)\s*\(reset \(rst_n async active_low\)\)/(clock-domains (domain core (clock clk) (reset (rst_n async active_low)) :default)\n    (domain aux (clock aux_clk) (reset (aux_rst_n async active_low))))/;
$domains =~ s/\(interface/(interface (input aux_start (domain aux)) (output aux_out (width 8) (domain aux))/;
$domains =~ s/\(storage/(storage (var aux_status (width 8) (reset 7) (domain aux))/;
$domains =~ s/\(transaction main/(transaction aux_tx (domain aux) (on aux_start) (update aux_out aux_status))\n  (transaction main/;

for my $case (
    {name => 'baseline', source => $baseline},
    {name => 'fields', source => $sources{'whole-word-field'}},
    {name => 'nonzero', source => $nonzero, simulate => 1},
    {name => 'unreset', source => $unreset, unreset => 1},
    {name => 'unused', source => $unused, unused => 1},
    {name => 'named', source => $named},
    {name => 'domains', source => $domains, domains => 1, simulate => 1},
) {
    subtest "$case->{name} retains actor storage identity and behavior" => sub {
        my $dir = "$work/$case->{name}";
        mkdir $dir or die $!;
        my $source = "$dir/source.isf";
        write_file($source, $case->{source});
        my $actor = FSM::Adapter::ISF->new->parse_file($source);
        my $lowered = FSM::Scheduler::ISF->new->lower($actor);
        is_deeply(FSM::Scheduler::ISF->new->lower($actor), $lowered, 'lowering is deterministic and preserves its source actor');
        for my $file (sort keys %{$lowered->{files}}) {
            write_file("$dir/$file", $lowered->{files}{$file});
            next unless $file =~ /\.fsm\z/;
            my @expected = $file =~ /__domain_aux/ ? ('aux_status') : qw(status control);
            push @expected, qw(spare typed_spare slots_0 slots_1) if $case->{unused};
            @expected = () if $lowered->{files}{$file} =~ /\(\?fsmc:/;
            my @actual = $lowered->{files}{$file} =~ /\(internal (\w+)\)/g;
            is_deeply([sort @actual], [sort @expected], "$file has exactly its owned internal declarations");
            my $check = $capture->([$^X, 'bin/fsmgen', '--strict', '--check', '--json', "$dir/$file"], '');
            is($check->{exit_code}, 0, "$file replays through direct admission") or diag($check->{stdout}, $check->{stderr});
        }
        my $relative = File::Spec->abs2rel($source, $root);
        my %reports;
        for my $kind (qw(check semantic schedule)) {
            my %flags = (check => [qw(--strict --check --json)], semantic => [qw(--strict --emit-semantic-json)], schedule => ['--emit-schedule-json']);
            my %tools = (check => 'fsmgen_check', semantic => 'fsmgen_semantic_introspect', schedule => 'fsmgen_schedule_preview');
            my $r = $capture->([$^X, 'bin/fsmgen', @{$flags{$kind}}, $relative], '');
            is($r->{exit_code}, 0, "$kind native succeeds") or diag($r->{stdout}, $r->{stderr});
            return if $r->{exit_code};
            my $report = FSM::Test::SourceQueryRunner::normalize_repository_paths($json->decode($r->{stdout}), $root);
            $reports{$kind} = $report;
            my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
                name => $tools{$kind}, arguments => {source_id => $relative}}};
            my $response = $api->handle_jsonrpc_request($request);
            ok(!$response->{error} && !$response->{result}{isError}, "$kind API succeeds");
            is_deeply($response->{result}{structuredContent}{report}, $report, "$kind complete native/API parity");
            my $wire = $capture->([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request)."\n");
            is($wire->{exit_code}, 0, "$kind newline succeeds");
            is_deeply($json->decode($wire->{stdout}), $response, "$kind complete newline/API parity");
        }
        my $semantic = $reports{semantic}{semantic};
        my %expected_inputs = (start => 1, wdata => 8, ($case->{domains} ? (aux_start => 1, clk => 1, rst_n => 1, aux_clk => 1, aux_rst_n => 1) : ()));
        my %expected_outputs = (done => 1, status_out => 8, control_out => 8, ($case->{domains} ? (aux_out => 8) : ()));
        is_deeply(widths($semantic->{signal_analysis}{inputs}), \%expected_inputs, 'actor storage is never an external input');
        is_deeply(widths($semantic->{signal_analysis}{outputs}), \%expected_outputs, 'storage writes create no external outputs');
        if (!$case->{domains}) {
            my %storage = map {$_->{name} => $_} @{$reports{schedule}{inferred_storage}};
            for my $name (qw(status control)) {
                is($storage{$name}{role}, 'actor_storage', "$name remains actor storage in the schedule");
                is($storage{$name}{width}, 8, "$name retains authored width");
            }
            my ($control) = grep {$_->{name} eq 'control'} @{$actor->{storage}};
            is_deeply($storage{control}{fields}, $control->{fields}, 'existing control field metadata is unchanged');
            if ($case->{name} eq 'fields') {
                my ($status) = grep {$_->{name} eq 'status'} @{$actor->{storage}};
                is_deeply($storage{status}{fields}, $status->{fields}, 'whole-word field metadata is unchanged');
            }
        }
        if ($case->{domains}) {
            is_deeply($reports{schedule}{inferred_storage}, [], 'composition top has no flattened storage detail');
            my %children = map {$_->{module_name} => $_} @{$semantic->{forward_ir}{intent_hir}{composition_children}};
            for my $domain (@{$reports{schedule}{clock_domains}}) {
                (my $module = $domain->{scheduled_fsm}) =~ s/\.fsm\z//;
                is_deeply($domain->{storage}, $domain->{name} eq 'aux' ? ['aux_status'] : [qw(status control)], 'schedule keeps storage under its owning domain');
                my $analysis = $children{$module}{intent_hir}{signal_analysis};
                is_deeply(widths($analysis->{inputs}), $domain->{name} eq 'aux' ? {aux_start => 1} : {start => 1, wdata => 8}, "$module has no storage inputs");
            }
        }
        for my $language (qw(systemverilog verilog), ($case->{name} eq 'nonzero' ? 'vhdl' : ())) {
            my $hdl = "$dir/$language.".($language eq 'vhdl' ? 'vhd' : 'sv');
            my $r = $capture->([$^X, 'bin/fsmgen', '--strict', '--quiet', '--language', $language, '--output', $hdl, $source], '');
            is($r->{exit_code}, 0, "$language generation succeeds") or diag($r->{stdout}, $r->{stderr});
            next if $r->{exit_code};
            my $text = read_file($hdl);
            if ($case->{unreset}) {
                unlike($text, qr/\bstatus\s*(?:<=|=)/, 'unwritten storage without a reset gains no invented driver');
            } else {
                like($text, qr/\bstatus\s*<=/, 'explicit storage reset has a real driver');
            }
            if ($case->{unused}) {
                like($text, qr/\breg signed\s+\[5:0\] typed_spare\b/, 'unused scalar preserves its signed type');
                like($text, qr/\breg\s+\[3:0\] slots_1\b/, 'unused bank element retains its declaration');
                unlike($text, qr/\b(?:typed_spare|slots_0|slots_1)\s*(?:<=|=)/, 'unused unreset storage acquires no driver');
                like($text, qr/\bspare\s*<=\s*5\b/, 'unused explicitly reset storage is initialized by hardware reset');
            }
            simulate($language, $hdl, $dir, $case) if $case->{simulate};
        }
    };
}
done_testing();

sub simulate {
    my ($language, $hdl, $dir, $case) = @_;
    subtest "$language independent CSR runtime" => sub {
        if ($language eq 'vhdl') {
            my $ghdl = ghdl_behavior_provider('storage_ownership');
            plan skip_all => 'GHDL provider unavailable' unless defined($ghdl) && -x $ghdl;
            my $tb = "$dir/storage_tb.vhd";
            write_file($tb, <<'VHDL');
library ieee; use ieee.std_logic_1164.all;
entity storage_tb is end;
architecture behavior of storage_tb is
 signal clk: std_logic := '0'; signal rst_n: std_logic := '1'; signal start: std_logic := '0';
 signal wdata: std_logic_vector(7 downto 0) := x"35";
 signal status_out, control_out: std_logic_vector(7 downto 0); signal done: std_logic;
begin
 clk <= not clk after 5 ns;
 dut: entity work.csr_access port map(clk=>clk, rst_n=>rst_n, start=>start, wdata=>wdata,
   status_out=>status_out, control_out=>control_out, done=>done);
 process
 begin
  wait for 2 ns; rst_n <= '0'; wait for 10 ns; rst_n <= '1';
  wait for 8 ns; start <= '1'; wait for 10 ns; start <= '0';
  wait until done = '1' for 200 ns; assert done = '1' report "completion timeout" severity failure;
  wait for 1 ns;
  assert status_out = x"13" and control_out = x"35" report "storage reset/write/readback mismatch" severity failure;
  wdata <= x"A7"; wait for 40 ns;
  assert status_out = x"13" and control_out = x"35" report "idle hold mismatch" severity failure;
  report "STORAGE_PASS" severity note; std.env.stop; wait;
 end process;
end;
VHDL
            my $compile = run_ghdl_analysis('storage_ownership', $dir, [$hdl, $tb]);
            ok($compile->{ok}, 'GHDL analyzes the generated actor and independent oracle') or diag($compile->{diagnostic}, $compile->{stderr});
            return unless $compile->{ok};
            my $r = run_ghdl_behavior('storage_ownership', $dir);
            ok($r->{ok}, 'GHDL storage reset/write/read/hold passes') or diag($r->{diagnostic},$r->{stdout},$r->{stderr});
            like($r->{stdout}.$r->{stderr}, qr/STORAGE_PASS/, 'VHDL oracle completes');
        } else {
            plan skip_all => 'Verilator provider unavailable or not qualified' unless can_run('verilator') && darwin_verilator_runtime_qualified();
            my $tb = "$dir/storage_tb.sv";
            my $tb_text = <<'SV';
`timescale 1ns/1ps
module storage_tb;
 logic clk=0, rst_n=1, start=0;
 logic [7:0] wdata=8'h35;
 wire [7:0] status_out, control_out; wire done;
 always #5 clk=~clk;
 csr_access dut(.clk(clk), .rst_n(rst_n), .start(start), .wdata(wdata),
   .status_out(status_out), .control_out(control_out), .done(done));
 initial begin
  #2; rst_n=0; #10; rst_n=1;
  #8; start=1; #10; start=0;
  wait(done); #1;
  assert(status_out === 8'h13 && control_out === 8'h35) else $fatal(1,"storage reset/write/readback mismatch");
  wdata=8'hA7; #40;
  assert(status_out === 8'h13 && control_out === 8'h35) else $fatal(1,"idle hold mismatch");
  $display("STORAGE_PASS"); $finish;
 end
 initial begin #300; $fatal(1,"completion timeout"); end
endmodule
SV
            if ($case->{domains}) {
                $tb_text =~ s/wire done;/wire done; wire [7:0] aux_out;/;
                $tb_text =~ s/csr_access dut\(/csr_access_top dut(.aux_clk(clk), .aux_rst_n(rst_n), .aux_start(start), .aux_out(aux_out), /;
                $tb_text =~ s/control_out === 8'h35/control_out === 8'h35 \&\& aux_out === 8'h07/g;
            }
            write_file($tb, $tb_text);
            my $obj = "$dir/obj_$language";
            my $compile = run_verilator_compile(['verilator', '--binary', '--timing', '--assert', '-Wno-fatal', '-j', '1', '--top-module', 'storage_tb', '--Mdir', $obj, $hdl, $tb]);
            ok($compile->{ok}, 'Verilator builds generated actor and independent oracle') or diag($compile->{diagnostic},substr($compile->{stderr},0,8192));
            return unless $compile->{ok};
            my $r = run_generated_binary(["$obj/Vstorage_tb"]);
            ok($r->{ok}, 'Verilator storage reset/write/read/hold passes') or diag($r->{diagnostic},$r->{stdout},$r->{stderr});
            like($r->{stdout}, qr/STORAGE_PASS/, 'Verilog-family oracle completes');
        }
    };
}
sub widths { return {map {$_->{name} => $_->{width}} @{$_[0] || []}}; }
sub read_file { open my $fh, '<', $_[0] or die $!; local $/; return <$fh>; }
sub write_file { open my $fh, '>', $_[0] or die $!; print {$fh} $_[1] or die $!; close $fh or die $!; }
