#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use IPC::Cmd qw(can_run);
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Test::VerilatorRuntime qw(darwin_verilator_runtime_qualified run_verilator_compile run_generated_binary);
use FSM::Pipeline::HDLGenerator;
use FSM::Backend::VerilogFamily::TypeDeclarationSupport;

my $work = tempdir(CLEANUP => 1);
my $pipeline = FSM::Pipeline::HDLGenerator->new(quiet => 1, target_language => 'systemverilog');
my $capture = \&FSM::Test::SourceQueryRunner::_capture;
for my $case (
    ['equal_record', '(record (payload (bits 8)))', '(record (payload (bits 8)))'],
    ['different_record', '(record (payload (bits 8)))', '(record (flag bit) (payload (bits 7)))'],
    ['nested', '(record (payload (list bit (bits 7))))', '(list (record (payload (bits 8))))'],
) {
    my ($name, $first, $second) = @$case;
    subtest $name => sub {
        my $dir = "$work/$name";
        mkdir $dir or die $!;
        my $source = write_file("$dir/source.fsm", source($first, $second));
        my $result = $pipeline->generate_hdl_from_file($source);
        my $hdl = $result->{hdl_code};
        my @names = $hdl =~ /^\}\s+(\w+__fsmgen_t);/mg;
        my %unique = map {$_ => 1} @names;
        is(scalar(@names), 4, 'both child and both top boundary types are emitted');
        is(scalar(keys %unique), scalar(@names), 'no duplicate compilation-unit typedef identifiers');
        for my $alias (qw(frame_t other_t)) {
            ok(grep(/\Q$alias\E__fsmgen_t\z/, @names), "authored $alias remains recognizable");
        }
        my $replayed = $pipeline->generate_hdl_from_file($source)->{hdl_code};
        s/^\/\/ Date:.*\n//mg for ($hdl, $replayed);
        is($replayed, $hdl, 'reused pipeline keeps deterministic independent module scopes');
        my $native = $capture->([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $source], '');
        is($native->{exit_code}, 0, 'canonical composition strict-admits') or diag($native->{stdout}, $native->{stderr});
        my $sv = write_file("$dir/dut.sv", $hdl);
        my $tb = write_file("$dir/tb.sv", <<'SV');
module tb;
  logic [7:0] first_in, second_in;
  wire [7:0] first_out, second_out;
  aggregate_top dut(.*);
  initial begin
    for (int i=0; i<256; i++) begin
      first_in = 8'(i); second_in = 8'(255-i); #1;
      if (first_out !== first_in || second_out !== second_in) $fatal(1, "typed channels changed value");
    end
    $display("aggregate module scopes preserve both channels"); $finish;
  end
endmodule
SV
        SKIP: {
            skip 'qualified Verilator runtime unavailable', 3
                unless can_run('verilator') && darwin_verilator_runtime_qualified();
            my $obj = "$dir/obj";
            my $compile = run_verilator_compile(['verilator', '--binary', '--timing', '-Wno-fatal',
                '--top-module', 'tb', '--Mdir', $obj, $sv, $tb]);
            is($compile->{exit_code}, 0, 'independent HDL compiler admits scoped typedefs')
                or diag($compile->{stdout}, $compile->{stderr});
            if ($compile->{exit_code}) { fail('runtime did not compile'); fail('runtime observation absent'); }
            else {
                my $run = run_generated_binary(["$obj/Vtb"]);
                is($run->{exit_code}, 0, 'independent packed-value runtime passes') or diag($run->{stdout}, $run->{stderr});
                like($run->{stdout}, qr/aggregate module scopes preserve both channels/, 'both independently driven channels observed');
            }
        }
    };
}

subtest 'same-width different type shapes still fail at the semantic boundary' => sub {
    my $text = source('(record (payload (bits 8)))', '(record (payload (bits 8)))');
    $text =~ s/\(type frame_t \(record \(payload \(bits 8\)\)\)\)/\(type frame_t (list (bits 8)))/;
    my $path = write_file("$work/mismatch.fsm", $text);
    my $ok = eval { $pipeline->generate_hdl_from_file($path); 1 };
    ok(!$ok, 'equal width does not erase aggregate type incompatibility');
    like($@, qr/type.*(?:mismatch|compatib)|(?:mismatch|compatib).*type/is, 'failure identifies the type contract');
};

subtest 'namespace delimiters and local alias sanitization cannot merge identifiers' => sub {
    my $type = {kind => 'list', width => 1, signed => 0, items => [{kind => 'bit', width => 1, signed => 0}]};
    my @names;
    for my $module (qw(a a__b)) {
        my $state = FSM::Backend::VerilogFamily::TypeDeclarationSupport->typedef_state(module_name => $module);
        my @entries = map {{declared_type_name => $_, declared_type_spec => $type}} qw(c b__c pkg.t pkg__t);
        my ($lines, $lookup) = FSM::Backend::VerilogFamily::TypeDeclarationSupport->collect_declared_aggregate_typedefs(\@entries, $state);
        push @names, values %$lookup;
        my ($again) = FSM::Backend::VerilogFamily::TypeDeclarationSupport->collect_declared_aggregate_typedefs(\@entries, $state);
        is_deeply($again, [], 'same module declaration collection is idempotent');
    }
    my %unique = map {$_ => 1} @names;
    is(scalar(keys %unique), scalar(@names), 'module boundaries and sanitized alias collisions stay distinct');
};
done_testing();

sub source {
    my ($first, $second) = @_;
    return <<"FSM";
(?top:aggregate_top
 (+types (type frame_t $first) (type other_t $second))
 (?ports:io first_in<frame_t first_out>frame_t second_in<other_t second_out>other_t)
 (?dtc:first_reader reader_one)
 (?dtc:second_reader reader_two)
 (?wiring:links (first_in first_reader.IN_FRAME) (first_reader.OUT_FRAME first_out)
   (second_in second_reader.IN_FRAME) (second_reader.OUT_FRAME second_out)))
(?dt:reader_one
 (+types (type frame_t $first))
 (+size (IN_FRAME frame_t) (OUT_FRAME frame_t))
 (-pass (= (OUT_FRAME IN_FRAME))))
(?dt:reader_two
 (+types (type frame_t $second))
 (+size (IN_FRAME frame_t) (OUT_FRAME frame_t))
 (-pass (= (OUT_FRAME IN_FRAME))))
FSM
}
sub write_file {
    my ($path, $text) = @_;
    open my $fh, '>', $path or die "open $path: $!";
    print {$fh} $text;
    close $fh or die "close $path: $!";
    return $path;
}
