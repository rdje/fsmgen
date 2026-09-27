#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(can_run);
use JSON::PP;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Test::VerilatorRuntime qw(darwin_verilator_runtime_qualified run_verilator_compile run_generated_binary);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Pipeline::HDLGenerator;
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $root = abs_path('.');
my $work = tempdir(CLEANUP => 1);
my $capture = \&FSM::Test::SourceQueryRunner::_capture;
my $json = JSON::PP->new->canonical;
my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);

for my $activation (qw(spawn do trigger)) {
    for my $actor_kind (qw(input output)) {
        for my $formal_kind (qw(input output)) {
            my $name = "${activation}_${actor_kind}_${formal_kind}";
            subtest $name => sub {
                my $dir = "$work/$name";
                mkdir $dir or die $!;
                my $source = write_file("$dir/source.isf", source($activation, $actor_kind, $formal_kind));
                my $actor = FSM::Adapter::ISF->new->parse_file($source);
                my $scheduler = FSM::Scheduler::ISF->new;
                my $ir = $scheduler->{ir}->build_module($actor);
                my $child = $ir->{children}{worker};
                my @ports = grep {$_->{name} eq 'value'} @{$child->{ports}};
                is(scalar @ports, 1, 'formal has one interface declaration');
                is($ports[0]{direction}, $formal_kind, 'formal direction wins over actor pin');
                is($ports[0]{width}, 4, 'formal width wins over actor pin');
                is($child->{signal_type_refs}{value}, 'local_t', 'formal type wins over actor type');
                ok(!exists $child->{reset_values}{value}, 'actor output reset does not leak into formal');
                my $files = $scheduler->lower($actor)->{files};
                for my $file (sort keys %$files) {
                    next unless $file =~ /\.fsm\z/;
                    my $path = write_file("$dir/$file", $files->{$file});
                    my $check = $capture->([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $path], '');
                    is($check->{exit_code}, 0, "$file strict replay") or diag($check->{stdout}, $check->{stderr});
                }
                qualify_reports($source);
                simulate($dir, $source, $activation, $actor_kind);
            };
        }
    }
}
done_testing;

sub source {
    my ($activation, $actor_kind, $formal_kind) = @_;
    my $actor_decl = $actor_kind eq 'output' ? '(width 8) (reset 19)' : '(type owner_t)';
    my $observe = $actor_kind eq 'output'
        ? '(rule owner 1 (value owner_data) (owner_seen owner_data))'
        : '(rule owner 1 (owner_seen value))';
    my $formal = $formal_kind eq 'input'
        ? '(input value (type local_t)) (output result (width 4))'
        : '(input payload (width 4)) (output value (type local_t))';
    my $bind = $formal_kind eq 'input'
        ? '(input value data) (output result child_seen)'
        : '(input payload data) (output value child_seen)';
    my ($lhs, $rhs) = $formal_kind eq 'input' ? ('result', 'value') : ('value', 'payload');
    my $params = $activation eq 'spawn' ? '' : '(params (MODE 0))';
    my $completion = 'done';
    my $caller;
    if ($activation eq 'trigger') {
        $formal .= ' (output finished)';
        $bind .= ' (output finished done)';
        $completion = 'finished';
        $caller = "(rule activate start (trigger worker (params (MODE 1)) (bind $bind)))";
    } else {
        my $call = $activation eq 'spawn'
            ? "(spawn worker as w0 (bind $bind)) (await_all done)"
            : "(do worker (params (MODE 1)) (bind $bind))";
        $caller = "(transaction parent (on start) $call (complete done))";
    }
    return "(actor pin_shadow (clock clk) (reset (rst_n async active_low))\n"
        . "(types (type owner_t (bits 8)) (type local_t (bits 4)))\n"
        . "(interface (input start) (input data (width 4)) (input owner_data (width 8))\n"
        . "($actor_kind value $actor_decl) (output owner_seen (width 8))\n"
        . "(output child_seen (width 4)) (output done)) $observe\n"
        . "(transaction worker $params (ports $formal) (wait 2) (set $lhs $rhs) (complete $completion))\n"
        . "$caller)\n";
}

sub qualify_reports {
    my ($source) = @_;
    my $relative = File::Spec->abs2rel($source, $root);
    for my $query (
        [[qw(--strict --check --json)], 'fsmgen_check'],
        [[qw(--strict --emit-semantic-json)], 'fsmgen_semantic_introspect'],
        [['--emit-schedule-json'], 'fsmgen_schedule_preview'],
    ) {
        my ($flags, $tool) = @$query;
        my $native = $capture->([$^X, 'bin/fsmgen', @$flags, $relative], '');
        is($native->{exit_code}, 0, "$tool native success") or diag($native->{stdout}, $native->{stderr});
        my $expected = FSM::Test::SourceQueryRunner::normalize_repository_paths($json->decode($native->{stdout}), $root);
        my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
            name => $tool, arguments => {source_id => $relative}}};
        my $response = $api->handle_jsonrpc_request($request);
        is_deeply($response->{result}{structuredContent}{report}, $expected, "$tool complete native/API parity");
        my $wire = $capture->([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request)."\n");
        is($wire->{exit_code}, 0, "$tool protocol success");
        is_deeply($json->decode($wire->{stdout}), $response, "$tool complete newline/API parity");
    }
}

sub simulate {
    my ($dir, $source, $activation, $actor_kind) = @_;
    SKIP: {
        skip 'qualified Verilator unavailable', 3
            unless can_run('verilator') && darwin_verilator_runtime_qualified();
        my $hdl = FSM::Pipeline::HDLGenerator->new(quiet => 1)->generate_hdl_from_file($source)->{hdl_code};
        my $dut = write_file("$dir/dut.sv", $hdl);
        my $pin = $actor_kind eq 'input' ? 'logic [7:0] value=0;' : 'wire [7:0] value;';
        my $set_pin = $actor_kind eq 'input' ? 'value=owner;' : '';
        my $first = $activation eq 'trigger' ? 'data=payload;' : 'data=1;';
        my $later = $activation eq 'trigger' ? 'data=1;' : 'data=payload;';
        my $tb = write_file("$dir/tb.sv", <<"SV");
module tb;
 logic clk=0,rst_n=1,start=0;
 logic [3:0] data=0;logic [7:0] owner_data=0;
 $pin
 wire [7:0] owner_seen;wire [3:0] child_seen;wire done;
 always #5 clk=~clk;
 pin_shadow_top dut(.*);
 task activate(input int payload,input int owner);
  int pulses;bit seen;
  pulses=0;seen=0;
  @(negedge clk);owner_data=owner;$set_pin $first start=1;
  @(negedge clk);start=0;$later
  for(int cycle=0;cycle<20;cycle++) begin
   @(posedge clk);#1;
   if(done) pulses++;
   if(child_seen===4'(payload)) seen=1;
   if(value!==8'(owner) || owner_seen!==8'(owner)) \$fatal(1,"local formal changed actor pin");
   @(negedge clk);
  end
  if(pulses!=1 || !seen) \$fatal(1,"bound payload provenance/completion lost payload=%0d seen=%0d pulses=%0d",payload,child_seen,pulses);
 endtask
 initial begin
  #2;rst_n=0;#20;rst_n=1;
  activate(7,165);activate(13,90);
  @(negedge clk);rst_n=0;#1;
  if(child_seen!==0) \$fatal(1,"child reset lost");
  rst_n=1;activate(5,195);
  \$display("PIN_SHADOW_PASS");\$finish;
 end
 initial begin #10000;\$fatal(1,"timeout");end
endmodule
SV
        my $obj = "$dir/obj";
        my $compile = run_verilator_compile(['verilator', '--binary', '--timing', '--assert', '-Wno-fatal',
            '--top-module', 'tb', '--Mdir', $obj, $dut, $tb]);
        ok($compile->{ok}, 'independent pin-shadow HDL compiles') or diag($compile->{diagnostic}, $compile->{stderr});
        if (!$compile->{ok}) { fail('runtime compilation failed'); fail('runtime observations absent'); }
        else {
            my $run = run_generated_binary(["$obj/Vtb"]);
            ok($run->{ok}, 'bound local payload and actor pin stay independent') or diag($run->{diagnostic}, $run->{stdout}, $run->{stderr});
            like($run->{stdout}, qr/PIN_SHADOW_PASS/, 'runtime provenance/reset/repeat oracle completed');
        }
    }
}
sub write_file {
    my ($path, $text) = @_;
    open my $fh, '>', $path or die "open $path: $!";
    print {$fh} $text or die "write $path: $!";
    close $fh or die "close $path: $!";
    return $path;
}
