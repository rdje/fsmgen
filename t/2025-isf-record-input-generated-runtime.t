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

my $work = tempdir(CLEANUP => 1);
my $json = JSON::PP->new->canonical;
my $bench_path = 't/data/isf_record_input_generated_runtime_tb.sv';
my @cases = (
    {name=>'domains', module=>'packed_input_generated_domains', domains=>1, writer=>'writer', copy_result_holds=>1},
    {name=>'blocking', module=>'packed_input_generated_blocking', domains=>0, writer=>'main_copier_do_0', copy_result_holds=>0},
);
$_->{source} = "t/data/isf_record_input_generated_$_->{name}_runtime.isf" for @cases;
my @inputs = ($bench_path, (map {$_->{source}} @cases), qw(bin/fsmgen
    perl/FSM/Adapter/ISF/Parser.pm perl/FSM/Scheduler/ISF/LoweringIR.pm
    perl/FSM/Scheduler/ISF/Emitter/FSM.pm perl/FSM/Scheduler/ISF/RecordSamples.pm
    perl/FSM/Scheduler/ISF/DomainSource.pm perl/FSM/Scheduler/ISF/ChildStorageOwnership.pm
    perl/FSM/Composition/GeneratedChildRealizer.pm
    perl/FSM/Package/AggregatePathSupport.pm
    perl/FSM/Backend/GeneratedModuleEmitter.pm
    perl/FSM/Backend/VerilogFamily/StructuralRTLIREmitter.pm
    t/lib/FSM/Test/VerilatorRuntime.pm t/lib/FSM/Test/ProcessSupervisor.pm));
my $before = {map {$_ => sha256_hex(read_file($_))} @inputs};
my $bench = read_file($bench_path);
my $fields = [
    {path=>'tag',width=>2,lsb=>8,msb=>9,signed=>0},
    {path=>'payload.data',width=>5,lsb=>3,msb=>7,signed=>1,state_model=>'four_state'},
    {path=>'payload.flags[0]',width=>1,lsb=>2,msb=>2,signed=>0,state_model=>'two_state'},
    {path=>'payload.flags[1]',width=>2,lsb=>0,msb=>1,signed=>0,state_model=>'two_state'},
];

subtest 'independent temporal counterexamples preserve binding and packed-copy checks' => sub {
    my @vectors = ([7,19,29,18], [30,9,5,19], [3,24,17,18]);
    for my $v (@vectors) {
        my ($entry,$copy,$live,$prior) = @$v;
        ok($copy && $copy != $entry && $copy != $live && $copy != $prior,
            'each copied value is nonzero and distinct from entry, live and prior values');
    }
    like($bench,qr/while \(phase !== 2'd2\).*?phase===2'd1 && copy_seen===copy_data.*?if \(!copy_result_observed\)/s,
        'actual bench requires copied result inside the public copy window');
    like($bench,qr/late_copy_result=COPY_RESULT_HOLDS \? copy_data : 5'b00000;/,
        'late bound-result expectation distinguishes forwarding from completion gating');
    is(scalar(()=$bench=~/copy_seen !== late_copy_result/g),2,
        'parent completion and idle independently check the role-specific result');
    for my $holds (0,1) {
        # Literal public-pin traces; no expected values come from FSMGen output.
        my $late = $holds ? 19 : 0;
        my $good = [[1,0], [1,19], [2,$late]];
        ok(copy_trace_matches($good,$holds,19,2,0,1),"role $holds accepts completion-window result and all packed leaves");
        ok(!copy_trace_matches([[1,0],[2,$late]],$holds,19,2,0,1),
            "role $holds rejects result missing from the copy window");
        ok(!copy_trace_matches([[1,0],[2,19]],$holds,19,2,0,1),
            "role $holds rejects a correct result arriving only after the window");
        ok(!copy_trace_matches([[1,19],[2,$holds ? 0 : 19]],$holds,19,2,0,1),
            "role $holds rejects wrong late retention");
        for my $wrong ([18,2,0,1],[19,3,0,1],[19,2,1,1],[19,2,0,2]) {
            ok(!copy_trace_matches($good,$holds,@$wrong),"role $holds rejects an independently wrong packed leaf");
        }
    }
};

subtest 'fixed source, generated roles and both emitted families preserve independent declarations' => sub {
    for my $case (@cases) {
        my ($name,$module,$domains,$writer) = @{$case}{qw(name module domains writer)};
        my $actor = FSM::Adapter::ISF->new->parse_file($case->{source});
        my $caller = $json->encode($actor);
        my @ports = (scalar_port('start','input',1),
            map {{name=>$_,direction=>'input',width=>10,type=>'frame',type_kind=>'record',fields=>$fields}} qw(packet unused));
        push @ports, map {scalar_port($_->[0],'output',$_->[1])}
            [phase=>2], [seen=>5], [again=>5], [negative_seen=>1], [negative_again=>1],
            [copy_seen=>5], [stored=>5], [copied_tag=>2], [stored_flag=>1], [stored_piece=>2], [captured=>5], [reset_seen=>5], [done=>1];
        if ($domains) {
            $_->{domain} = $_->{name} eq 'unused' ? 'idle' : 'io' for @ports;
        }
        same($actor->{interface_port_metadata},\@ports,"$name complete authored pins and packed ranges are literal");
        my $scheduler = FSM::Scheduler::ISF->new;
        my $product = $scheduler->lower($actor);
        my $report = $json->decode($scheduler->report($actor));
        is($json->encode($actor),$caller,"$name lowering/report preserve complete caller JSON kinds");
        my $parent = $domains ? "${module}__domain_io" : $module;
        my $copier = $domains ? "${parent}__child_copier" : 'copier';
        my $reader = $domains ? "${parent}__child_reader" : 'reader';
        my @files = ("$parent.fsm","$copier.fsm","$reader.fsm","${module}_top.fsm",
            $domains ? ("${module}__domain_idle.fsm") : ());
        same([sort keys %{$product->{files}}],[sort @files],"$name complete artifacts reuse exactly one reader definition");
        my $owner_text = $product->{files}{"$parent.fsm"};
        my $copy_text = $product->{files}{"$copier.fsm"};
        my $read_text = $product->{files}{"$reader.fsm"};
        like($owner_text,qr/\(held frame \(reset 149\)\)/,"$name packed state/reset stays in its owner");
        like($owner_text,qr/\(<= \(accepted packet\.payload\.data\) <start\)/,"$name only explicit entry sample captures input");
        unlike($owner_text,qr/\(<- \(held packet\)\)/,"$name parent does not duplicate the generated whole writer");
        for my $pair ([$copy_text,[qw(start packet done result isf_write_held_data isf_write_held_enable isf_child_start_seen)]],
                      [$read_text,[qw(start packet done result is_negative isf_child_start_seen)]]) {
            my ($text,$expected) = @$pair;
            my ($interface) = $text =~ /\(\+interface\n(.*?)\n  \)/s;
            my @actual = map {/\((?:input|output|internal) (\w+)\)/ ? $1 : die "unexpected interface line\n"}
                split /\n/, $interface // '';
            same(\@actual,$expected,"$name complete private child identities and order");
            like($text,qr/\(packet frame\)/,"$name inherited packet retains one typed packed root");
            unlike($text,qr/\(input unused\)|\(held frame|\(internal held\)/,"$name child has no unused input or owner register");
            like($text,qr/\(clock clk\)\s*\(areset rst_n\)/,"$name child has exactly its owning clock/reset");
        }
        ok(copy_edge_present($copy_text),"$name private copy data and explicit enable retain their authored edge");
        like($copy_text,qr/\(isf_write_held_data frame\)/,"$name private whole write data retains type");
        like($owner_text,qr/\(held isf_write_\Q$writer\E_held_data\).*isf_write_\Q$writer\E_held_enable/s,
            "$name owner consumes the actual generated packed data/enable handoff");
        like($read_text,qr/\(result> packet\.payload\.data\)/,"$name reused reader retains its live scalar read");
        like($read_text,qr/\(is_negative> \(< packet\.payload\.data 0\)\)/,"$name child owns the signed comparison");
        my $top = $product->{files}{"${module}_top.fsm"};
        my $owner_instance = $domains ? 'io' : $module;
        my @links = (['start', "$owner_instance.start"], ['packet', "$owner_instance.packet"]);
        push @links, ['unused', $domains ? 'idle.unused' : "$owner_instance.unused"];
        push @links, ["$owner_instance.$_", $_] for qw(phase seen again negative_seen negative_again copy_seen stored copied_tag stored_flag stored_piece captured reset_seen done);
        for my $instance (qw(left right)) {
            my $physical = $domains ? "io__$instance" : $instance;
            like($top,qr/\(\?fsmc:\Q$physical\E \Q$reader\E(?:\s|\))/,"$name $instance reuses the exact typed reader");
            like($top,qr/\(packet \Q$physical\E\.packet\)/,"$name $instance receives live packed input");
            my $output = $instance eq 'left' ? 'seen' : 'again';
            like($owner_text,qr/\(= \(\Q$output\E> \Q$instance\E_result\)\)/,
                "$name spawned output binding retains its live forwarding assignment");
            push @links, ['packet', "$physical.packet"],
                ["$owner_instance.${instance}_start", "$physical.start"],
                ["$physical.done", "$owner_instance.${instance}_done"],
                ["$physical.result", "$owner_instance.${instance}_result"],
                ["$physical.is_negative", "$owner_instance.${instance}_is_negative"];
        }
        my $physical_writer = $domains ? "io__$writer" : $writer;
        push @links, ['packet', "$physical_writer.packet"],
            ["$owner_instance.${writer}_start", "$physical_writer.start"],
            ["$physical_writer.done", "$owner_instance.${writer}_done"],
            ["$physical_writer.result", "$owner_instance.${writer}_result"];
        like($top,qr/\(packet \Q$physical_writer\E\.packet\)/,"$name sole writer receives packed input");
        for my $part (qw(data enable)) {
            like($top,qr/\(\Q$physical_writer\E\.isf_write_held_\Q$part\E \Q$owner_instance\E\.isf_write_\Q$writer\E_held_\Q$part\E\)/,
                "$name complete private $part endpoint ownership");
            push @links, ["$physical_writer.isf_write_held_$part", "$owner_instance.isf_write_${writer}_held_$part"];
        }
        my ($top_root) = $top =~ /\A(\(\?top:.*?\n\))/s;
        my @actual_links = ($top_root // '') =~ /^    \(([^()\n]+ [^()\n]+)\)$/mg;
        same([sort @actual_links],[sort map {join ' ', @$_} @links],"$name entire public/private wiring has exact endpoints");
        my $binding = '(= (copy_seen> ' . $writer . '_result)'
            . ($domains ? '' : ' <' . $writer . '_done') . ')';
        like($owner_text,qr/\Q$binding\E/,"$name sole copier preserves its call-form output-binding contract");
        if ($domains) {
            my %owned = map {$_->{name}=>$_} @{$report->{clock_domains}};
            is($owned{idle}{reset},undef,'clock-only unused sibling gains no reset');
            same($owned{idle}{inferred_storage},[],'clock-only sibling gains no state');
            same($owned{io}{reset},{name=>'rst_n',kind=>'async',polarity=>'active_low'},'whole-copy owner retains exact reset');
            like($top,qr/\(unused idle\.unused\)/,'unused declaration remains in the clock-only owner');
        }
        mkdir "$work/$name" or die $!;
        write_file("$work/$name/$_",$product->{files}{$_}) for @files;
        for my $file (@files) {
            my $path = "$work/$name/$file";
            my $checked = capture([$^X,'bin/fsmgen','--strict','--check','--json',$path]);
            is($checked->{exit_code},0,"$name $file strictly replays") or diag($checked->{stdout},$checked->{stderr});
            die "fixed carrier replay failed\n" if $checked->{exit_code};
        }
        for my $target (qw(systemverilog)) {
            my $path = "$work/${name}_$target.sv";
            my $emitted = capture([$^X,'bin/fsmgen','--strict','--quiet','--language',$target,'--output',$path,$case->{source}]);
            is($emitted->{exit_code},0,"$name $target original source emits") or diag($emitted->{stdout},$emitted->{stderr});
            die "fixed generated source emission failed\n" if $emitted->{exit_code};
            $case->{hdl}{$target} = $path;
            my $text = read_file($path);
            is(scalar(()=$text =~ /^module \Q$reader\E\b/mg),1,"$name $target emits one reused reader definition");
            like($text,qr/module \Q${module}_top\E\b/,"$name $target retains explicit generated top");
            like($text,qr/logic signed \[4:0\] data;/,"$name $target preserves signed packed scalar declaration");
        }
        my $rendered_bench = read_file(bench_for($case));
        unlike($rendered_bench,qr/__(?:DUT|IDLE_CLOCK|COPY_RESULT_HOLDS)__/,"$name bench substitutes only fixed module/clock/binding tokens");
        like($rendered_bench,qr/localparam bit COPY_RESULT_HOLDS = \Q$case->{copy_result_holds}\E;/,
            "$name rendered bench uses its independently declared binding role");
        my $bad = $copy_text;
        is($bad =~ s/\(isf_write_held_enable> 1\)/(isf_write_held_enable> 0)/g,1,"$name hostile copy changes exactly its enable");
        ok(!copy_edge_present($bad),"$name independent copy-edge witness rejects disabled actual handoff");
    }
};

subtest 'actual authored unsigned counterexample changes property without packed width' => sub {
    my $source = read_file($cases[0]{source});
    is($source =~ s/\(signed \(four_state \(bits 5\)\)\)/(four_state (bits 5))/g,1,'only authored signed property changes');
    my $path = write_file("$work/unsigned.isf",$source);
    my $actor = FSM::Adapter::ISF->new->parse_file($path);
    is($actor->{interface_port_metadata}[1]{width},10,'actual unsigned input keeps packed width');
    isnt($json->encode($actor->{interface_port_metadata}[1]{fields}),$json->encode($fields),
        'actual unsigned declaration fails the unchanged independent leaf witness');
    $cases[0]{unsigned} = "$work/unsigned.sv";
    my $emitted = capture([$^X,'bin/fsmgen','--strict','--quiet','--language','systemverilog',
        '--output',$cases[0]{unsigned},$path]);
    is($emitted->{exit_code},0,'actual unsigned generated source emits') or diag($emitted->{stdout},$emitted->{stderr});
    die "counterexample emission failed\n" if $emitted->{exit_code};
};

subtest 'generated behavior awaits independently qualified exact observation admission' => sub {
    # Historical two-emitter captures remain sealed. This SystemVerilog-only
    # target needs fresh observer qualification before another runtime admission.
    plan skip_all=>'fixed generated observer and explicit runtime admission required'
        unless ($ENV{FSMGEN_RECORD_INPUT_GENERATED_RUNTIME} // '') eq '1';
    plan skip_all=>'qualified Darwin Verilator runtime unavailable'
        unless darwin_verilator_runtime_qualified();
    plan skip_all=>'Verilator unavailable' unless can_run('verilator');
    for my $case (@cases) {
        my $tb = bench_for($case);
        for my $target (qw(systemverilog)) {
            my $run = simulate($case->{hdl}{$target},$tb,"$case->{name}_$target");
            ok($run->{ok},"$case->{name} $target independent generated public-pin behavior") or diag($json->encode($run));
            die "unexpected generated runtime result; diagnose retained evidence\n" unless $run->{ok};
            like($run->{stdout},qr/GENERATED_INPUT_RUNTIME_PASS/,'complete generated behavior marker');
            like($run->{stdout},qr/GENERATED_REPEATED_REQUEST_PASS/,'repeated generated requests complete');
            like($run->{stdout},qr/GENERATED_RESET_ABORT_PASS/,'generated reset/abort completes');
            is(scalar(()=$run->{stdout}=~/GENERATED_LAP_PASS/g),3,'all independent request laps complete');
            is(scalar(()=$run->{stdout}=~/GENERATED_COPY_WINDOW_PASS/g),3,'each lap observes its bound result in the copy window');
        }
    }
    my $run = simulate($cases[0]{unsigned},bench_for($cases[0]),'unsigned');
    my $rejected = !$run->{ok} && !$run->{exec_failed} && !$run->{timed_out}
        && !$run->{output_limited} && !$run->{signal} && $run->{status} eq 'nonzero_exit'
        && $run->{exit_code} != 0 && $run->{stdout} =~ /GENERATED_SIGNED_MISMATCH/
        && $run->{stdout} !~ /GENERATED_INPUT_RUNTIME_PASS/;
    ok($rejected,'generated public-pin predicate rejects actual unsigned property loss') or diag($json->encode($run));
    die "unexpected generated negative result; diagnose retained evidence\n" unless $rejected;
};
same({map {$_=>sha256_hex(read_file($_))} @inputs},$before,'fixed sources, bench and named producer/supervision bytes remain');
done_testing;

sub scalar_port { return {name=>$_[0],direction=>$_[1],width=>$_[2]}; }
sub copy_edge_present { return $_[0] =~ /\(= \(isf_write_held_data> packet\)\)/
    && $_[0] =~ /\(= \(isf_write_held_enable> 1\)\)/ ? 1 : 0; }
sub copy_trace_matches {
    my ($trace,$holds,$stored,$tag,$flag,$piece) = @_;
    my $observed = 0;
    for my $pin (@$trace) {
        if ($pin->[0] == 2) {
            return $observed && $pin->[1] == ($holds ? 19 : 0)
                && $stored == 19 && $tag == 2 && $flag == 0 && $piece == 1;
        }
        $observed = 1 if $pin->[0] == 1 && $pin->[1] == 19;
    }
    return 0;
}
sub bench_for {
    my ($case) = @_;
    my $text = $bench;
    die "fixed bench module token changed\n" unless $text =~ s/__DUT__/$case->{module}_top/g == 1;
    my $idle = $case->{domains} ? '.idle_clk(idle_clk), ' : '';
    die "fixed bench clock token changed\n" unless $text =~ s/__IDLE_CLOCK__/$idle/g == 1;
    die "fixed bench binding token changed\n" unless $text =~ s/__COPY_RESULT_HOLDS__/$case->{copy_result_holds}/g == 1;
    return write_file("$work/$case->{name}_tb.sv",$text);
}
sub simulate {
    my ($hdl,$tb,$name) = @_;
    my $obj = "$work/obj_$name";
    my $build = run_verilator_compile(['verilator','--binary','--timing','--assert','-Wno-fatal',
        '-j','1','--top-module','tb','--Mdir',$obj,$hdl,$tb]);
    ok($build->{ok},"$name fixed generated bench builds") or diag($json->encode($build));
    die "generated native compile failed; diagnose retained evidence\n" unless $build->{ok};
    return run_generated_binary(["$obj/Vtb"]);
}
sub same { is($json->encode($_[0]),$json->encode($_[1]),$_[2]); }
sub capture { FSM::Test::SourceQueryRunner::_capture($_[0],''); }
sub read_file { open my $fh,'<:raw',$_[0] or die $!; local $/; my $s=<$fh>; close $fh or die $!; return $s; }
sub write_file { open my $fh,'>:raw',$_[0] or die $!; print {$fh} $_[1] or die $!; close $fh or die $!; return $_[0]; }
