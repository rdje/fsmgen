#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use IPC::Cmd qw(can_run);
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::VerilatorRuntime qw(darwin_verilator_runtime_qualified run_verilator_compile run_generated_binary);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Pipeline::HDLGenerator;

my $work = tempdir(CLEANUP => 1);
sub source {
    my (%o) = @_;
    my $kind = $o{kind} // 'async';
    my $polarity = $o{polarity} // 'active_low';
    my $reset = $o{no_reset} ? '' : "(reset (rst $kind $polarity))";
    my $library_timing = $o{no_reset}
        ? '(clock-domains (domain local (clock clk) :default))'
        : '(clock clk) ' . ($o{library_reset} // $reset);
    my $bindings = $o{bindings} // '';
    my $domain = $o{domain} // 'io';
    return <<"ISF";
(library sample
 (exports (actor cell))
 (actor cell $library_timing
  (interface (input din (width 8)) (output q (width 8)))
  (rule sample_data 1 (q din))))
(actor domain_library
 (clock-domains
  (domain idle (clock aux_clk) (reset (aux_rst async active_high)) :default)
  (domain io (clock clk) $reset))
 (interface (input din (width 8) (domain io)) (output q (width 8) (domain io))
            (input alternate (domain io)) (output aux_seen (domain idle)))
 (rule aux_tick (domain idle) 1 (aux_seen 1))
 (imports (library sample as lib))
 (use lib.cell as u (domain $domain)
  (bind $bindings (input din din) (output q q))))
ISF
}

for my $case (['async_low','async','active_low'], ['async_high','async','active_high'],
              ['sync_low','sync','active_low'], ['sync_high','sync','active_high'], ['no_reset',undef,undef]) {
    my ($name,$kind,$polarity) = @$case;
    subtest $name => sub {
        my $no_reset = $name eq 'no_reset';
        my $text = source(kind=>$kind,polarity=>$polarity,no_reset=>$no_reset);
        my $file = write_file("$work/$name.isf", $text);
        my $actor = FSM::Adapter::ISF->new->parse_file($file);
        my $use = $actor->{library_uses}[0];
        my %bindings = map { $_->{role} => $_->{parent_name} } @{$use->{bindings}};
        is($bindings{clock},'clk','clock inference selects nondefault domain');
        is($bindings{reset},$no_reset ? undef : 'rst','reset inference respects selected domain absence');
        my $files = FSM::Scheduler::ISF->new->lower($actor)->{files};
        my $child = $files->{'domain_library__u.fsm'};
        if ($no_reset) { unlike($child,qr/\((?:a|s)reset\s/,'library does not acquire the default domain reset'); }
        else {
            is_deeply($use->{actor}{reset},{name=>'rst',kind=>$kind,polarity=>$polarity},'child reset policy survives domain selection');
        }
        my $hdl = FSM::Pipeline::HDLGenerator->new(quiet=>1)->generate_hdl_from_file($file)->{hdl_code};
        my $active = ($polarity // '') eq 'active_low' ? 0 : 1;
        my $inactive = 1 - $active;
        my $reset_decl = $no_reset ? '' : "logic rst=$inactive;";
        my $reset_check = $no_reset ? '' : "rst=$active;#1;if(q!==" . ($kind eq 'async' ? 0 : 37) . ") \$fatal(1,\"reset edge policy changed\");clk=1;#1;if(q!==0) \$fatal(1,\"reset clock failed\");clk=0;rst=$inactive;#1;";
        my $tb = <<"SV";
module tb;
 logic clk=0,aux_clk=0,aux_rst=0,alternate=0;
 logic [7:0] din=37;wire [7:0] q;wire aux_seen;
 $reset_decl
 domain_library_top dut(.*);
 initial begin
  #1;clk=1;#1;clk=0;#1;if(q!==37) \$fatal(1,"sample failed");
  $reset_check
  din=53;clk=1;#1;clk=0;#1;if(q!==53) \$fatal(1,"sample after reset failed");
  din=99;repeat(3) begin aux_clk=1;#1;aux_clk=0;#1;end
  if(q!==53 || aux_seen!==1) \$fatal(1,"library clock depends on default domain");
  aux_rst=1;#1;if(q!==53 || aux_seen!==0) \$fatal(1,"default reset escaped domain");
  \$display("LIBRARY_DOMAIN_RESET_PASS");\$finish;
 end
 initial begin #1000;\$fatal(1,"timeout");end
endmodule
SV
        simulate($name,$hdl,$tb);
    };
}

subtest 'explicit binding remaps identity without overriding child reset policy' => sub {
    my $actor = FSM::Adapter::ISF->new->parse_source(source(
        library_reset=>'(reset (child_rst sync active_high))',bindings=>'(clock clk) (reset rst)'), 'explicit-remap.isf');
    is_deeply($actor->{library_uses}[0]{actor}{reset},{name=>'child_rst',kind=>'sync',polarity=>'active_high'},
        'published explicit reset remapping keeps library policy');
};

subtest 'invalid or unowned system bindings fail at resolution' => sub {
    for my $case (
        [{bindings=>'(clock aux_clk)'}, qr/clock binding must use domain 'io' clock signal 'clk', not 'aux_clk'/],
        [{bindings=>'(reset aux_rst)'}, qr/reset binding must use domain 'io' reset signal 'rst', not 'aux_rst'/],
        [{bindings=>'(clock alternate)'}, qr/clock binding must use domain 'io' clock signal 'clk', not 'alternate'/],
        [{bindings=>'(clock missing)'}, qr/clock binding references unknown parent signal 'missing'/],
        [{domain=>'missing'}, qr/uses unknown clock domain 'missing'/],
        [{library_reset=>'(reset (rst sync active_low))'}, qr/requires a reset binding/],
        [{library_reset=>'(reset (rst async active_high))'}, qr/requires a reset binding/],
        [{library_reset=>'(reset (other async active_low))'}, qr/requires a reset binding/],
        [{no_reset=>1,bindings=>'(reset aux_rst)'}, qr/reset binding must use domain 'io' reset signal '<none>'/],
    ) {
        my ($options,$error) = @$case;
        my $ok = eval { FSM::Adapter::ISF->new->parse_source(source(%$options), 'refused-binding.isf'); 1 };
        ok(!$ok,'invalid binding refused');like($@,$error,'specific domain/policy diagnosis');
    }
};
done_testing();

sub simulate {
    my ($name,$hdl,$tb) = @_;
    SKIP: {
        skip 'qualified Verilator runtime unavailable',3 unless can_run('verilator') && darwin_verilator_runtime_qualified();
        my $dir="$work/$name";mkdir $dir or die $!;
        my $sv=write_file("$dir/dut.sv",$hdl);my $test=write_file("$dir/tb.sv",$tb);my $obj="$dir/obj";
        my $compile=run_verilator_compile(['verilator','--binary','--timing','--assert','-Wno-fatal','--top-module','tb','--Mdir',$obj,$sv,$test]);
        ok($compile->{ok},'reset runtime compiles') or diag($compile->{diagnostic},$compile->{stderr});
        if (!$compile->{ok}) { fail('runtime compilation failed');fail('observation absent'); }
        else {
            my $run=run_generated_binary(["$obj/Vtb"]);
            ok($run->{ok},'reset kind/polarity and independent clocks pass') or diag($run->{diagnostic},$run->{stdout},$run->{stderr});
            like($run->{stdout},qr/LIBRARY_DOMAIN_RESET_PASS/,'reset observations complete');
        }
    }
}
sub write_file {my ($path,$text)=@_;open my $fh,'>',$path or die $!;print {$fh} $text;close $fh or die $!;return $path;}
