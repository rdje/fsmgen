#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use File::Spec;
use JSON::PP ();
use IPC::Cmd qw(can_run);
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Test::VerilatorRuntime qw(darwin_verilator_runtime_qualified run_verilator_compile run_generated_binary);
use FSM::Test::ProcessSupervisor qw(supervise_process);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $work = tempdir(CLEANUP => 1);
my $root = abs_path('.');
my $json = JSON::PP->new->canonical->utf8;
my $capture = \&FSM::Test::SourceQueryRunner::_capture;
my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
my $base = <<'ISF';
(actor shared_reads
 (clock clk) (reset (rst_n async active_low))
 (interface (input start) (input wdata (width 8)) (output done) (output observed (width 8)))
 (storage (var status (width 8) (reset 19)) (var unrelated (width 7) (reset 3)))
 (transaction worker (ports (output result (width 8))) (wait 4) (set result status) (complete done))
 (transaction parent (on start) (set status 53)
  (spawn worker as w0 (bind (output result observed))) (wait 1) (set status wdata)
  (await_all done) (complete done)))
ISF
my $guard = $base;
$guard =~ s/\(set result status\)/(when (== status 53) (set result (+ status 1)))/;
my $guard_only = $guard;
$guard_only =~ s/\(\+ status 1\)/54/;
my $typed = $base;
$typed =~ s/\(storage/(types (type byte_t (signed (bits 8)))) (storage/;
$typed =~ s/\(var status \(width 8\)/\(var status (type byte_t)/;
my $record = $typed;
$record =~ s/\(signed \(bits 8\)\)/(record (payload (bits 7)) (flag bit))/;
my $bank = $base;
$bank =~ s/\(var status \(width 8\) \(reset 19\)\)/(bank slots (width 8) (depth 2))/;
$bank =~ s/\(set status 53\)/(store slots 0 53)/;
$bank =~ s/\(set status wdata\)/(store slots 1 wdata)/;
$bank =~ s/\(set result status\)/(load slots 1 as result)/;
my $dynamic = $bank;
$dynamic =~ s/\(input start\)/(input start) (input index)/;
$dynamic =~ s/\(load slots 1 as result\)/(load slots index as result)/;
my $named = $base;
$named =~ s/\(clock clk\) \(reset \(rst_n async active_low\)\)/(clock-domains (domain core (clock clk) (reset (rst_n async active_low))))/;
my $domains = $base;
$domains =~ s/\(clock clk\) \(reset \(rst_n async active_low\)\)/(clock-domains (domain core (clock clk) (reset (rst_n async active_low)) :default) (domain aux (clock aux_clk) (reset (aux_rst_n async active_low))))/;
$domains =~ s/\(interface/(interface (input aux_start (domain aux)) (output aux_out (width 8) (domain aux))/;
$domains =~ s/\(storage/(storage (var aux_status (width 8) (reset 7) (domain aux))/;
$domains =~ s/\(transaction worker/(transaction aux_tx (domain aux) (on aux_start) (set aux_out aux_status)) (transaction worker/;
my $collision = $base;
$collision =~ s/\(var unrelated/(var isf_storage_read_status (width 8) (reset 5)) (var unrelated/;
my $local = $base;
$local =~ s/\(wait 4\)/(local acc (width 8) (reset 5)) (set acc status) (wait 4)/;
$local =~ s/\(set result status\)/(set result acc)/;
my $literal = $base;
$literal =~ s/\(var status/(var hff (width 8) (reset 2)) (var state_active (width 1) (reset 0)) (var status/;
$literal =~ s/\(set result status\)/(set result 8'hff)/;
my $shadow = $base;
$shadow =~ s/\(ports \(output result/\(ports (input payload (width 8)) (output result/;
$shadow =~ s/\(bind \(output result observed\)\)/(bind (input payload status) (output result observed))/;
$shadow =~ s/\(set result status\)/(set result payload)/;
my $multiple = $base;
$multiple =~ s/\(output observed \(width 8\)\)/(output observed (width 8)) (output observed_two (width 8))/;
$multiple =~ s/\(wait 1\)/(spawn worker as w1 (bind (output result observed_two))) (wait 1)/;
$multiple =~ s/await_all/await_any/;

for my $case (
    {name=>'live', source=>$base, runtime=>1, reads=>['status']},
    {name=>'guard', source=>$guard, reads=>['status']},
    {name=>'guard_only', source=>$guard_only, reads=>['status']},
    {name=>'typed', source=>$typed, reads=>['status'], runtime=>1},
    {name=>'record', source=>$record, reads=>['status'], runtime=>1},
    {name=>'bank', source=>$bank, reads=>['slots_1'], runtime=>1},
    {name=>'dynamic_bank', source=>$dynamic, reads=>[qw(slots_0 slots_1)]},
    {name=>'named', source=>$named, reads=>['status']},
    {name=>'domains', source=>$domains, domains=>1, reads=>['status']},
    {name=>'collision', source=>$collision, reads=>['status']},
    {name=>'local', source=>$local, reads=>['status']},
    {name=>'literal', source=>$literal, reads=>[]},
    {name=>'explicit_binding', source=>$shadow, reads=>[]},
    {name=>'multiple_readers', source=>$multiple, reads=>['status']},
) {
    subtest $case->{name} => sub {
        my $dir="$work/$case->{name}";
        mkdir $dir or die $!;
        my $source="$dir/source.isf";
        write_file($source,$case->{source});
        my @warnings;
        my $actor;
        { local $SIG{__WARN__} = sub { push @warnings, @_ };
        $actor=FSM::Adapter::ISF->new->parse_file($source); }
        is_deeply(\@warnings, [], 'declaration parsing is warning-free');
        my $scheduler=FSM::Scheduler::ISF->new;
        my $ir=$scheduler->{ir}->build_module($actor);
        is_deeply([map {$_->{name}} @{$ir->{children}{worker}{actor_storage_reads}}],$case->{reads},'exact semantic reads, not unrelated declarations');
        is_deeply($ir->{children}{worker}{declared_storage},[],'no independent child copies');
        ok(!exists $ir->{children}{worker}{reset_values}{status},'actor reset belongs only to owner');
        my $lowered=$scheduler->lower($actor);
        is_deeply($scheduler->lower($actor),$lowered,'deterministic and source immutable');
        for my $file(sort keys %{$lowered->{files}}) {
            write_file("$dir/$file",$lowered->{files}{$file});
            my $r=$capture->([$^X,'bin/fsmgen','--strict','--check','--json',"$dir/$file"],'');
            is($r->{exit_code},0,"$file direct replay") or diag($r->{stdout},$r->{stderr});
        }
        my $relative=File::Spec->abs2rel($source,$root);
        for my $kind(qw(check semantic schedule)) {
            my %flags=(check=>[qw(--strict --check --json)],semantic=>[qw(--strict --emit-semantic-json)],schedule=>['--emit-schedule-json']);
            my %tools=(check=>'fsmgen_check',semantic=>'fsmgen_semantic_introspect',schedule=>'fsmgen_schedule_preview');
            my $r=$capture->([$^X,'bin/fsmgen',@{$flags{$kind}},$relative],'');
            unlike($r->{stderr},qr/uninitialized value/, 'native query emits no undefined-width warning');
            is($r->{exit_code},0,"native $kind") or diag($r->{stdout},$r->{stderr});
            next if $r->{exit_code};
            my $report=FSM::Test::SourceQueryRunner::normalize_repository_paths($json->decode($r->{stdout}),$root);
            my $request={jsonrpc=>'2.0',id=>1,method=>'tools/call',params=>{name=>$tools{$kind},arguments=>{source_id=>$relative}}};
            my $response=$api->handle_jsonrpc_request($request);
            is_deeply($response->{result}{structuredContent}{report},$report,"complete native/API $kind parity");
            my $wire=$capture->([$^X,'bin/fsmgen-mcp','--workspace-root','.'],$json->encode($request)."\n");
            is($wire->{exit_code},0,"newline $kind");
            is_deeply($json->decode($wire->{stdout}),$response,"complete newline/API $kind parity");
            if($kind eq 'semantic') {
                my %inputs=map {$_->{name}=>1} @{$report->{semantic}{signal_analysis}{inputs}};
                my @expected_inputs = ((map { $_->{name} } @{$actor->{interface}{inputs}}), 'clk', 'rst_n');
                push @expected_inputs, qw(aux_clk aux_rst_n) if $case->{domains};
                is_deeply([sort keys %inputs], [sort @expected_inputs], 'exact public inputs with no leaked storage or handoffs');
            }
        }
        for my $language(qw(systemverilog verilog)) {
            my $hdl="$dir/dut.".($language eq 'vhdl'?'vhd':'sv');
            my $r=$capture->([$^X,'bin/fsmgen','--strict','--quiet','--language',$language,'--output',$hdl,$source],'');
            is($r->{exit_code},0,"$language generation") or diag($r->{stdout},$r->{stderr});
            simulate($language,$hdl,$dir) if !$r->{exit_code} && $case->{runtime} && $language eq 'systemverilog';
        }
        if ($case->{name} eq 'live') {
            my @vhdl;
            for my $module (qw(shared_reads worker)) {
                my $hdl="$dir/$module.vhd";
                my $r=$capture->([$^X,'bin/fsmgen','--strict','--quiet','--language','vhdl','--output',$hdl,"$dir/$module.fsm"],'');
                is($r->{exit_code},0,"$module standalone VHDL generation") or diag($r->{stdout},$r->{stderr});
                push @vhdl,$hdl;
            }
            simulate('vhdl',\@vhdl,$dir);
        }
    };
}
for my $write ('(set status 37)','(update status 37)','(set status[3:0] 7)','(store slots 1 37)') {
    subtest "refuse unqualified child writer $write" => sub {
        my $s=$base;
        $s =~ s/\(set result status\)/$write (set result 0)/;
        $s =~ s/\(storage/(storage (bank slots (width 8) (depth 2))/ if $write =~ /slots/;
        my $path="$work/writer.isf";
        write_file($path,$s);
        my $r=$capture->([$^X,'bin/fsmgen','--strict','--check','--json',$path],'');
        isnt($r->{exit_code},0,'writer rejected');
        my $diagnostic = $write =~ /\[/
            ? qr/set target must be a scalar HDL identifier or declared aggregate storage path/
            : qr/generated child writes actor-owned storage/;
        like($r->{stdout}.$r->{stderr}, $diagnostic, 'earliest authoritative writer diagnostic');
    };
}
subtest 'resolved storage widths validate reset fit without warnings' => sub {
    for my $declaration (
        ['literal', '', '(width 8)'],
        ['type', '(types (type byte_t (bits 8)))', '(type byte_t)'],
        ['parameter', '(params (WIDTH 8))', '(width WIDTH)'],
        ['constant', '(constants (WIDTH 8))', '(width WIDTH)'],
    ) {
        for my $reset (0, 255, 256) {
            my ($name, $prefix, $width) = @$declaration;
            my $source = "(actor reset_fit (clock clk) $prefix (storage (var status $width (reset $reset))))";
            my $path = "$work/reset_fit.isf";
            write_file($path, $source);
            my @warnings;
            my $actor;
            my $error;
            {
                local $SIG{__WARN__} = sub { push @warnings, @_ };
                $actor = eval { FSM::Adapter::ISF->new->parse_file($path) };
                $error = $@;
            }
            is_deeply(\@warnings, [], "$name reset $reset has no warnings");
            if ($reset == 256) {
                ok(!$actor, "$name reset overflow rejected");
                like($error, qr/reset value 256 does not fit in 8 bit/, 'resolved-width diagnostic');
            } else {
                ok($actor, "$name reset $reset accepted") or diag($error);
            }
        }
    }
};
done_testing();

sub simulate {
    my ($language,$hdl,$dir)=@_;
    subtest "$language live read runtime" => sub {
        if($language eq 'systemverilog') {
            plan skip_all=>'Verilator unavailable or unqualified' unless can_run('verilator') && darwin_verilator_runtime_qualified();
            my $tb="$dir/read_tb.sv";
            write_file($tb,<<'SV');
`timescale 1ns/1ps
module read_tb;
 logic clk=0,rst_n=1,start=0; logic [7:0] wdata=91; wire [7:0] observed; wire done;
 always #5 clk=~clk;
 shared_reads_top dut(.clk(clk),.rst_n(rst_n),.start(start),.wdata(wdata),.observed(observed),.done(done));
 initial begin
  #2; rst_n=0; #10; rst_n=1; #8; start=1; #10; start=0;
  wait(done); #1; assert(observed===8'd91) else $fatal(1,"live parent update lost");
  #50; wdata=7; start=1; #10; start=0;
  wait(done); #1; assert(observed===8'd7) else $fatal(1,"repeated live read lost");
  $display("CHILD_STORAGE_READ_PASS"); $finish;
 end
 initial begin #1000; $fatal(1,"completion timeout"); end
endmodule
SV
            my $obj="$dir/obj";
            my $c=run_verilator_compile(['verilator','--binary','--timing','--assert','-Wno-fatal','-j','1','--top-module','read_tb','--Mdir',$obj,$hdl,$tb]);
            ok($c->{ok},'Verilator compile') or diag($c->{diagnostic},$c->{stderr});
            return unless $c->{ok};
            my $r=run_generated_binary(["$obj/Vread_tb"]); ok($r->{ok},'live and repeated reads pass') or diag($r->{diagnostic},$r->{stdout},$r->{stderr});
            like($r->{stdout},qr/CHILD_STORAGE_READ_PASS/,'independent oracle completes');
        } else {
            my $ghdl=$ENV{FSMGEN_RESET_GHDL}//'ghdl';
            $ghdl=$ghdl =~ m{/}?abs_path($ghdl):can_run($ghdl);
            plan skip_all=>'GHDL provider unavailable' unless $ghdl && -x $ghdl;
            my $tb="$dir/read_tb.vhd";
            write_file($tb,<<'VHDL');
library ieee; use ieee.std_logic_1164.all;
entity read_tb is end;
architecture behavior of read_tb is
 signal clk: std_logic := '0'; signal rst_n: std_logic := '1'; signal start: std_logic := '0';
 signal wdata: std_logic_vector(7 downto 0) := x"5B"; signal observed: std_logic_vector(7 downto 0); signal done: std_logic;
 signal child_start, child_done: std_logic; signal child_result, live_status: std_logic_vector(7 downto 0);
begin
 clk <= not clk after 5 ns;
 owner: entity work.shared_reads port map(clk=>clk,rst_n=>rst_n,start=>start,wdata=>wdata,observed=>observed,done=>done,
 w0_start=>child_start,w0_done=>child_done,w0_result=>child_result,isf_storage_read_status=>live_status);
 child: entity work.worker port map(clk=>clk,rst_n=>rst_n,start=>child_start,done=>child_done,result=>child_result,status=>live_status);
 process begin
  wait for 2 ns; rst_n<='0'; wait for 10 ns; rst_n<='1'; wait for 8 ns; start<='1'; wait for 10 ns; start<='0';
  wait until done='1' for 400 ns; assert done='1' report "completion timeout" severity failure; wait for 1 ns;
  assert observed=x"5B" report "live parent update lost" severity failure;
  wait for 50 ns; wdata<=x"07"; start<='1'; wait for 10 ns; start<='0';
  wait until done='1' for 400 ns; assert done='1' report "completion timeout" severity failure; wait for 1 ns;
  assert observed=x"07" report "repeated live read lost" severity failure;
  report "CHILD_STORAGE_READ_PASS" severity note; std.env.stop; wait;
 end process;
end;
VHDL
            my $c=ghdl_stage([$ghdl,'-a','--std=08','--workdir='.$dir,@$hdl,$tb],$dir);
            ok($c->{ok},'GHDL analysis') or diag($c->{diagnostic},$c->{stderr});
            return unless $c->{ok};
            my $r=ghdl_stage([$ghdl,'--elab-run','--std=08','--workdir='.$dir,'read_tb','--assert-level=error','--stop-time=1000ns'],$dir);
            ok($r->{ok},'live and repeated reads pass') or diag($r->{diagnostic},$r->{stdout},$r->{stderr});
            like($r->{stdout}.$r->{stderr},qr/CHILD_STORAGE_READ_PASS/,'independent oracle completes');
        }
    };
}
sub ghdl_stage { my ($argv,$cwd)=@_; return supervise_process(schema=>'fsmgen.test.child_storage_reads.v1',stage=>'ghdl',bounds=>{timeout_seconds=>60,capture_limit_bytes=>1_048_576},containment=>'test_runtime_process_group',cwd=>$cwd,argv=>$argv); }
sub read_file { open my $f,'<',$_[0] or die $!; local $/; return <$f>; }
sub write_file { open my $f,'>',$_[0] or die $!; print {$f} $_[1] or die $!; close $f or die $!; }
