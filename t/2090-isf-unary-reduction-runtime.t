use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use File::Temp qw(tempdir);
use IPC::Cmd qw(can_run);
use JSON::PP;
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Test::VerilatorRuntime qw(darwin_verilator_runtime_qualified run_verilator_compile run_generated_binary);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

# ISF-REDUCTION-DELIVERY.1.3.1: fixed input/bench/profile/stage membership.
# The default invocation qualifies source/generation only. Live HDL requires
# a separately qualified, fresh fixed observer admission under .1.3.2/.1.4.
my $source_path = 't/data/unary_reduction_runtime.isf';
my $bench_path = 't/data/unary_reduction_runtime_tb.sv';
my $vectors_path = 't/data/unary_reduction_runtime_vectors.hex';
my $work = tempdir(CLEANUP => 1);
my $root = abs_path('.');
my $json = JSON::PP->new->canonical;
my $source = read_file($source_path);
my $bench = read_file($bench_path);
my @vectors = split /\n/, read_file($vectors_path);
my @inputs = ($source_path, $bench_path, $vectors_path, 't/2090-isf-unary-reduction-runtime.t',
    qw(bin/fsmgen perl/FSM/Adapter/ISF/Parser.pm perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm
    perl/FSM/Adapter/FSMGenFull/SignalManager.pm perl/FSM/ExpressionNamer.pm
    perl/FSM/Scheduler/ISF/LoweringIR.pm perl/FSM/Scheduler/ISF/Emitter/FSM.pm
    perl/FSM/Synthesis/EnableGraph/ASTSupport.pm t/lib/FSM/Test/VerilatorRuntime.pm
    t/lib/FSM/Test/ProcessSupervisor.pm perl/FSM/Support/ProcessSupervisor.pm));
my $before = {map {$_ => sha256_hex(read_file($_))} @inputs};
my @ports = (
    [valid => 'input',1], [data => 'input',8], [other => 'input',8],
    [scalar => 'input',1], [intermediate_xor_data_other_1 => 'input',1],
    map {[$_, 'output', 1]} qw(out_xor out_and out_or out_odd out_scalar_xor
        out_scalar_and out_scalar_or out_bit out_slice),
);
push @ports, [out_nested => 'output',4], map {[$_, 'output',8]} qw(out_binary_xor out_binary_and out_binary_or);
push @ports, [out_unrolled => 'output',1], [out_label => 'output',1];
my $expected_ports = [map {{name => $_->[0], direction => $_->[1], width => $_->[2]}} @ports];
my @records = map {
    {owner_kind => 'rule', owner => $_->[0], context => "rule '$_->[0]' action[0] RHS",
        kind => 'unary', operator => $_->[1], operand => $_->[2], operand_width => $_->[3], result_width => 1}
} (
    [xor_rule => '^','data',8], [and_rule => '&','data',8], [or_rule => '|','data',8],
    [odd_rule => '^','data',8], [scalar_xor => '^','scalar',1],
    [scalar_and => '&','scalar',1], [scalar_or => '|','scalar',1],
    [bit_rule => '&','data[3]',1], [slice_rule => '^','data[7:4]',4],
    [nested_rule => '^','data',8], [nested_rule => '^','data[3:0]',4],
    [nested_rule => '&','scalar',1], [nested_rule => '|','data[0]',1],
);
my %hdl;

sub vector_errors {
    my ($rows) = @_;
    return ['fixed vector count differs'] unless @$rows == 256;
    my @errors;
    for my $data (0..255) {
        my $row = $rows->[$data];
        if ($row !~ /\A[0-9a-f]{15}\z/) {push @errors, "invalid row $data"; next}
        my $bits = join '', map {sprintf '%04b', hex($_)} split //, $row;
        push @errors, "nonzero padding $data" unless substr($bits,0,3) eq '000';
        $bits = substr($bits,3);
        my $other = (73*$data+41)%256;
        my $scalar = int($data/2)%2;
        my $label = int($data/4)%2;
        my ($parity,$all,$any,$low,$high) = (0,1,0,0,0);
        for my $bit (0..7) {
            my $value = ($data >> $bit) & 1;
            $parity ^= $value; $all = $all && $value; $any = $any || $value;
            if ($bit < 4) {$low ^= $value} else {$high ^= $value}
        }
        my @binary;
        for my $op (qw(xor and or)) {
            my $value = '';
            for my $bit (reverse 0..7) {
                my ($a,$b) = (($data >> $bit)&1, ($other >> $bit)&1);
                $value .= $op eq 'xor' ? ($a != $b ? 1 : 0)
                    : $op eq 'and' ? ($a && $b ? 1 : 0) : ($a || $b ? 1 : 0);
            }
            push @binary,$value;
        }
        my $expected = join '', $parity, 0+$all, 0+$any, 1-$parity,
            $scalar, $scalar, $scalar, (($data>>3)&1), $high,
            (1-$parity).$low.$scalar.($data&1), @binary, $parity, $label;
        die 'independent output packing width differs' unless length($expected) == 39;
        my $input = sprintf('%08b%08b%01b%01b',$data,$other,$scalar,$label);
        push @errors, "wrong authored inputs $data" unless substr($bits,0,18) eq $input;
        push @errors, "wrong independent results $data" unless substr($bits,18) eq $expected;
    }
    return \@errors;
}

subtest 'complete fixed vectors have an independent bit-walk oracle and hostile controls' => sub {
    same(vector_errors(\@vectors), [], 'every stored input/result bit is independently re-derived');
    my @wrong = @vectors;
    $wrong[1] = substr($wrong[1],0,14) . ($wrong[1] =~ /0\z/ ? '1' : '0');
    ok(@{vector_errors(\@wrong)}, 'a wrong expected output bit cannot pass');
    @wrong = @vectors; pop @wrong;
    ok(@{vector_errors(\@wrong)}, 'an omitted vector cannot pass');
    @wrong = @vectors; $wrong[0] = $wrong[1];
    ok(@{vector_errors(\@wrong)}, 'a substituted input row cannot pass');
    my ($one_xor,$one_and) = (0,1);
    for my $bit (0..7) {
        my $value = (1 >> $bit) & 1;
        $one_xor ^= $value; $one_and = $one_and && $value;
    }
    same([$one_xor,0+$one_and],[1,0], 'actual low-bit-only operand separates whole-vector XOR and AND');
    like($bench, qr/observed !== expected/, 'public-pin comparison rejects unknown or wrong output bits');
    like($bench, qr/checked != 512/, 'both complete sweeps are required');
    like($bench, qr/UNARY_RUNTIME_HOLD_PASS/, 'fixed disabled-write control remains in bench');
    like($bench, qr/UNARY_RUNTIME_RESET_PASS/, 'fixed reset control remains in bench');
};

subtest 'fixed source and actual carrier preserve complete declarations and generated widths' => sub {
    my $actor = FSM::Adapter::ISF->new->parse_file($source_path);
    my $caller = $json->encode($actor);
    same($actor->{interface_port_metadata}, $expected_ports, 'complete independent authored port roles/widths');
    my $scheduler = FSM::Scheduler::ISF->new;
    same($json->decode($scheduler->report($actor))->{reductions}, \@records, 'complete independent reduction source records');
    my $lowered = $scheduler->lower($actor);
    is($json->encode($actor), $caller, 'caller data and JSON kinds preserved');
    same([sort keys %{$lowered->{files}}], ['unary_reduction_runtime.fsm'], 'exact single carrier membership');
    my $carrier = write_file("$work/actual.fsm", $lowered->{files}{'unary_reduction_runtime.fsm'});
    my $check = capture([$^X,'bin/fsmgen','--strict','--check','--json',$carrier]);
    is($check->{exit_code},0,'actual canonical carrier strictly checks') or diag($check->{stdout},$check->{stderr});
    die 'fixed carrier refused before runtime' if $check->{exit_code};
    ok(!exists($json->decode($check->{stdout})->{source}{reductions}), 'carrier invents no authored ISF inventory');
    for my $target (qw(systemverilog verilog)) {
        $hdl{$target} = "$work/design_$target.sv";
        emit($source_path,$target,$hdl{$target});
        my $text = read_file($hdl{$target});
        for my $port (@ports) {
            my ($name,$direction,$width) = @$port;
            my $range = $width == 1 ? '' : '\\['.($width-1).':0\\]\\s+';
            like($text,qr/\b\Q$direction\E\s+\w+\s+$range\Q$name\E\b/,
                "$target independent port $name/$width");
        }
        unlike($text,qr/assign\s+intermediate_xor_data_other_1\s*=/,
            "$target external helper-like pin has no internal driver");
    }
    my $wrong = $source;
    is($wrong =~ s/\(out_xor \(\^ data\)\)/(out_xor (\& data))/g,1,'counterfactual changes exactly the first unary XOR');
    my $bad_source = write_file("$work/wrong.isf",$wrong);
    $hdl{wrong} = "$work/wrong.sv";
    emit($bad_source,'systemverilog',$hdl{wrong});
    my $bad_actor = FSM::Adapter::ISF->new->parse_file($bad_source);
    my @expected = map {{%$_}} @records;
    $expected[0]{operator} = '&';
    same($json->decode($scheduler->report($bad_actor))->{reductions},\@expected,
        'well-formed wrong source changes only its intended operator record');
};

subtest 'fixed public-pin runtime requires fresh observer admission' => sub {
    plan skip_all => 'fixed unary observer qualification and explicit fresh runtime admission required'
        unless ($ENV{FSMGEN_UNARY_REDUCTION_RUNTIME} // '') eq '1';
    die 'Darwin runtime qualification absent' unless darwin_verilator_runtime_qualified();
    die 'Verilator unavailable in admitted runtime' unless can_run('verilator');
    for my $target (qw(systemverilog verilog wrong)) {
        my $object = "$work/obj_$target";
        my $build = run_verilator_compile(['verilator','--binary','--timing','--assert','-Wno-fatal',
            '-j','1','--top-module','tb','--Mdir',$object,$hdl{$target},$bench_path]);
        ok($build->{ok},"$target fixed bench compiles") or diag($json->encode($build));
        die 'native/HDL compilation failed; diagnose retained result' unless $build->{ok};
        my $run = run_generated_binary(["$object/Vtb"]);
        ok($run->{ok},"$target fixed process completes") or diag($json->encode($run));
        die 'native/runtime process failed; diagnose retained result' unless $run->{ok};
        if ($target eq 'wrong') {
            like($run->{stdout},qr/UNARY_RUNTIME_MISMATCH row=1 /,'independent public-pin oracle rejects actual wrong reduction');
            unlike($run->{stdout},qr/UNARY_RUNTIME_PASS/,'wrong reduction cannot reach semantic PASS');
            die 'wrong reduction was not independently rejected'
                unless $run->{stdout} =~ /UNARY_RUNTIME_MISMATCH row=1 / && $run->{stdout} !~ /UNARY_RUNTIME_PASS/;
        } else {
            like($run->{stdout},qr/UNARY_RUNTIME_PASS checked=512/,'every fixed vector sweep completes');
            like($run->{stdout},qr/UNARY_RUNTIME_HOLD_PASS/,'disabled writes retain outputs');
            like($run->{stdout},qr/UNARY_RUNTIME_RESET_PASS/,'reset clears and retains public outputs');
            unlike($run->{stdout},qr/UNARY_RUNTIME_(?:MISMATCH|COUNT_MISMATCH|DEADLINE)/,'no semantic rejection or deadline');
            die 'incomplete or wrong positive runtime oracle'
                unless $run->{stdout} =~ /UNARY_RUNTIME_PASS checked=512/
                    && $run->{stdout} =~ /UNARY_RUNTIME_HOLD_PASS/ && $run->{stdout} =~ /UNARY_RUNTIME_RESET_PASS/
                    && $run->{stdout} !~ /UNARY_RUNTIME_(?:MISMATCH|COUNT_MISMATCH|DEADLINE)/;
        }
    }
};

same({map {$_ => sha256_hex(read_file($_))} @inputs},$before,'all fixed witness and named producer bytes preserved');
done_testing;
sub same {is($json->encode($_[0]),$json->encode($_[1]),$_[2])}
sub capture {FSM::Test::SourceQueryRunner::_capture($_[0],'')}
sub read_file {open my $fh,'<:raw',$_[0] or die $!;local $/;my $s=<$fh>;close $fh or die $!;return $s}
sub write_file {open my $fh,'>:raw',$_[0] or die $!;print {$fh} $_[1] or die $!;close $fh or die $!;return $_[0]}
sub emit {
    my ($source,$target,$path) = @_;
    my $result = capture([$^X,'bin/fsmgen','--strict','--quiet','--language',$target,'--output',$path,$source]);
    is($result->{exit_code},0,"$target actual fixed source emission") or diag($result->{stdout},$result->{stderr});
    is($result->{stderr},'','generation stderr clean');
    die 'fixed source emission failed before runtime' if $result->{exit_code};
}
