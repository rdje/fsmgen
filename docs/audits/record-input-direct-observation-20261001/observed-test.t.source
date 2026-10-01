use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Digest::SHA qw(sha256_hex);
use File::Temp qw(tempdir);
use IPC::Cmd qw(can_run);
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Test::VerilatorRuntime qw(darwin_verilator_runtime_qualified run_verilator_compile run_generated_binary);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

my $source_path = 't/data/isf_record_input_runtime.isf';
my $bench_path = 't/data/isf_record_input_runtime_tb.sv';
my $work = tempdir(CLEANUP => 1);
my $json = JSON::PP->new->canonical;
my @inputs = ($source_path, $bench_path, qw(bin/fsmgen
    perl/FSM/Adapter/ISF/Parser.pm perl/FSM/Scheduler/ISF/LoweringIR.pm
    perl/FSM/Scheduler/ISF/Emitter/FSM.pm perl/FSM/Package/AggregatePathSupport.pm
    perl/FSM/Backend/VerilogFamily/StructuralRTLIREmitter.pm
    t/lib/FSM/Test/VerilatorRuntime.pm t/lib/FSM/Test/ProcessSupervisor.pm));
my $before = {map {$_ => sha256_hex(read_file($_))} @inputs};
my $source = read_file($source_path);
my $bench = read_file($bench_path);
my $fields = [
    {path=>'tag',width=>2,lsb=>8,msb=>9,signed=>0},
    {path=>'payload.data',width=>5,lsb=>3,msb=>7,signed=>1,state_model=>'four_state'},
    {path=>'payload.flags[0]',width=>1,lsb=>2,msb=>2,signed=>0,state_model=>'two_state'},
    {path=>'payload.flags[1]',width=>2,lsb=>0,msb=>1,signed=>0,state_model=>'two_state'},
];
my $actor = FSM::Adapter::ISF->new->parse_file($source_path);
my $caller = $json->encode($actor);
my $scheduler = FSM::Scheduler::ISF->new;
my $product = $scheduler->lower($actor);
my $carrier = $product->{files}{'packed_input_runtime.fsm'};
my %hdl;

subtest 'fixed authored behavior witness preserves literal layout and carrier edges' => sub {
    same($actor->{interface_port_metadata}[1],
        {name=>'packet',direction=>'input',width=>10,type=>'frame',type_kind=>'record',fields=>$fields},
        'entire packed declaration is independently authored');
    is($json->encode($actor),$caller,'lowering preserves complete caller JSON kinds');
    same([sort keys %{$product->{files}}],['packed_input_runtime.fsm'],
        'direct witness produces exactly one carrier');
    like($carrier,qr/\(packet frame\)/,'record remains a single typed input');
    like($carrier,qr/\(<= \(accepted packet\.payload\.data\) <start\)/,
        'entry sample has its explicit start-qualified registered leaf capture');
    like($carrier,qr/\(<- \(held packet\)\)/,'whole copy preserves its authored assignment');
    like($carrier,qr/\(live> packet\.payload\.data\)/,'later scalar read remains live');
    unlike($carrier,qr/\((?:input|output) accepted\)/,'sample alias adds no public pin');
    my $semantic = capture([$^X,'bin/fsmgen','--strict','--emit-semantic-json',$source_path]);
    is($semantic->{exit_code},0,'actual authored native semantic query succeeds')
        or diag($semantic->{stdout},$semantic->{stderr});
    die "fixed semantic source query failed\n" if $semantic->{exit_code};
    my $report = $json->decode($semantic->{stdout});
    ok($report->{success},'semantic report records complete source success');
    same($report->{source}{interface_ports}[1],$actor->{interface_port_metadata}[1],
        'native source declaration matches the independently checked literal');
    for my $target (qw(systemverilog verilog)) {
        $hdl{$target} = "$work/design_$target.sv";
        my $result = capture([$^X,'bin/fsmgen','--strict','--quiet','--language',$target,
            '--output',$hdl{$target},$source_path]);
        is($result->{exit_code},0,"$target emits actual authored source") or diag($result->{stdout},$result->{stderr});
        die "fixed source emission failed before native execution\n" if $result->{exit_code};
        my $text = read_file($hdl{$target});
        like($text,qr/input\s+\w+\s+packet\s*,/,
            "$target exposes exactly one typed packed record pin");
        like($text,qr/typedef struct packed \{\s*logic \[1:0\] tag;\s*struct packed \{\s*logic signed \[4:0\] data;\s*struct packed \{\s*bit item_0;\s*bit \[1:0\] item_1;\s*\} flags;\s*\} payload;/,
            "$target complete authored packed type preserves field order and leaf properties");
        unlike($text,qr/input[^;\n]*packet_(?:tag|payload)/,"$target adds no scalarized field pins");
        like($text,qr/(?:logic|reg)\s+signed\s+\[4:0\]\s+accepted\b/,
            "$target private sample preserves signed scalar declaration");
    }
};

subtest 'independent metadata rejects equal-width layout and leaf-property corruption' => sub {
    for my $variant (
        ['unsigned', '(signed (four_state (bits 5)))', '(four_state (bits 5))'],
        ['data_state', '(four_state (bits 5))', '(two_state (bits 5))'],
        ['flag_state', '(two_state bit)', '(four_state bit)'],
    ) {
        my ($name,$old,$new) = @$variant;
        my $changed = $source;
        is($changed =~ s/\Q$old\E/$new/g,1,"$name changes exactly its selected authored property");
        my $parsed = FSM::Adapter::ISF->new->parse_source($changed,"$work/$name.isf");
        is($parsed->{interface_port_metadata}[1]{width},10,"$name keeps the same packed width");
        isnt($json->encode($parsed->{interface_port_metadata}[1]{fields}),$json->encode($fields),
            "$name actual parsed declarations fail the unchanged independent literal witness");
        if ($name eq 'unsigned') {
            my $path = write_file("$work/unsigned.isf",$changed);
            $hdl{unsigned} = "$work/unsigned.sv";
            my $emitted = capture([$^X,'bin/fsmgen','--strict','--quiet','--language','systemverilog',
                '--output',$hdl{unsigned},$path]);
            is($emitted->{exit_code},0,'deliberately unsigned source emits through the actual backend')
                or diag($emitted->{stdout},$emitted->{stderr});
            die "unsigned counterexample emission failed before runtime\n" if $emitted->{exit_code};
        }
    }
    my $reordered = $source;
    my $types_start = index($reordered,' (types');
    my $types_end = index($reordered,' (interface',$types_start);
    die "fixed authored type block absent\n" if $types_start < 0 || $types_end < 0;
    substr($reordered,$types_start,$types_end-$types_start) =
        ' (types (type frame (record (payload (record'
        . ' (data (signed (four_state (bits 5))))'
        . ' (flags (list (two_state bit) (two_state (bits 2)))))) (tag (bits 2)))))' . "\n";
    my $parsed = FSM::Adapter::ISF->new->parse_source($reordered,"$work/reordered.isf");
    is($parsed->{interface_port_metadata}[1]{width},10,'reordered authored members keep the same packed width');
    isnt($json->encode($parsed->{interface_port_metadata}[1]{fields}),$json->encode($fields),
        'actual reordered declarations fail the unchanged independent layout witness');
};

subtest 'genuine public-pin behavior requires separate native observation admission' => sub {
    plan skip_all=>'fixed observer qualification and explicit record-input runtime admission required'
        unless ($ENV{FSMGEN_RECORD_INPUT_RUNTIME} // '') eq '1';
    plan skip_all=>'qualified Darwin Verilator runtime unavailable'
        unless darwin_verilator_runtime_qualified();
    plan skip_all=>'Verilator unavailable' unless can_run('verilator');
    my $tb = write_file("$work/tb.sv",$bench);
    for my $target (qw(systemverilog verilog)) {
        my $obj = "$work/obj_$target";
        my $build = run_verilator_compile(['verilator','--binary','--timing','--assert','-Wno-fatal',
            '-j','1','--top-module','tb','--Mdir',$obj,$hdl{$target},$tb]);
        ok($build->{ok},"$target fixed public-pin bench builds") or diag($json->encode($build));
        die "native compile admission or HDL compilation failed; diagnose retained result\n" unless $build->{ok};
        my $run = run_generated_binary(["$obj/Vtb"]);
        ok($run->{ok},"$target independent packed-input oracle passes") or diag($json->encode($run));
        die "native runtime admission or behavioral oracle failed; diagnose retained result\n" unless $run->{ok};
        for my $marker (qw(PACKED_REPEATED_REQUEST_PASS PACKED_RESET_ABORT_PASS PACKED_INPUT_RUNTIME_PASS)) {
            like($run->{stdout},qr/\Q$marker\E/,"$target completes $marker");
        }
        is(scalar(() = $run->{stdout} =~ /PACKED_LAP_PASS/g),3,"$target completes every independent request lap");
    }
    my $obj = "$work/obj_unsigned";
    my $build = run_verilator_compile(['verilator','--binary','--timing','--assert','-Wno-fatal',
        '-j','1','--top-module','tb','--Mdir',$obj,$hdl{unsigned},$tb]);
    ok($build->{ok},'same-width unsigned counterexample builds') or diag($json->encode($build));
    die "negative compilation failed; diagnose retained result\n" unless $build->{ok};
    my $run = run_generated_binary(["$obj/Vtb"]);
    my $rejected = !$run->{ok} && !$run->{exec_failed} && !$run->{timed_out}
        && !$run->{output_limited} && !$run->{signal}
        && $run->{status} eq 'nonzero_exit' && $run->{exit_code} != 0
        && $run->{stdout} =~ /PACKED_SIGNED_MISMATCH/
        && $run->{stdout} !~ /PACKED_INPUT_RUNTIME_PASS/;
    ok($rejected,'public-pin oracle rejects the deliberately lost signed property') or diag($json->encode($run));
    die "unexpected negative result; diagnose retained result\n" unless $rejected;
};

same({map {$_ => sha256_hex(read_file($_))} @inputs},$before,
    'complete source, bench and named production/supervision bytes remain unchanged');
done_testing;
sub same { is($json->encode($_[0]),$json->encode($_[1]),$_[2]); }
sub capture { FSM::Test::SourceQueryRunner::_capture($_[0],''); }
sub read_file { open my $fh,'<:raw',$_[0] or die $!; local $/; my $s=<$fh>; close $fh or die $!; return $s; }
sub write_file { open my $fh,'>:raw',$_[0] or die $!; print {$fh} $_[1] or die $!; close $fh or die $!; return $_[0]; }
