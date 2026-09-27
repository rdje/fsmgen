#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Storable qw(dclone);
use JSON::PP;
use File::Temp qw(tempdir);
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::PhysicalWriteDeclarations;
use FSM::Scheduler::ISF::PhysicalWriteTargets;

my $collector = 'FSM::Scheduler::ISF::PhysicalWriteDeclarations';
my $targets = 'FSM::Scheduler::ISF::PhysicalWriteTargets';
my $scheduler = FSM::Scheduler::ISF->new;
my $work = tempdir(CLEANUP=>1);
my $capture = \&FSM::Test::SourceQueryRunner::_capture;
my $json = JSON::PP->new;
sub write_file {my ($name,$text)=@_; open my $fh,'>',"$work/$name" or die $!;print {$fh} $text;close $fh or die $!;return "$work/$name"}
sub source {
    my ($width, $reverse) = @_;
    my @body = ('(set copy captured)', '(set scratch 1)');
    @body = reverse @body if $reverse;
    return "(actor implicit_writes (clock clk)\n"
        . "(interface (input start) (input source (width $width)) (output result (width $width)))\n"
        . "(transaction main (on start) (sample source as captured) @body (set result copy)))\n";
}

subtest 'whole-root contracts follow actual carriers without guessing inferred widths' => sub {
    my $reference;
    for my $width (8,13) {
        for my $reverse (0,1) {
            my $text = source($width,$reverse);
            my $actor = FSM::Adapter::ISF->new->parse_source($text,'implicit_writes.isf');
            my $ir = $scheduler->{ir}->build_module($actor);
            my $before = dclone($ir);
            my $collection = $collector->collect($ir);
            my $contracts = $collector->target_contracts($ir);
            is_deeply($collection->{unresolved_targets}, [map {{root=>$_,target=>$_}} qw(captured copy scratch)],
                'implicit widths are still distinguished from explicit declarations');
            my %implicit = map {$_=>$contracts->{$_}} qw(captured copy scratch);
            for my $name (sort keys %implicit) {
                is_deeply($implicit{$name}, {module=>'implicit_writes',root=>$name,target=>$name,coverage=>'whole_root'},
                    "$name covers its entire actual root without a fabricated range");
            }
            $reference //= dclone(\%implicit);
            is_deeply(\%implicit,$reference,'width and state-order changes do not change whole-root identity');
            my %actual = map {$_->{lhs}=>1} map {@{$_->{assignments} || []}} (@{$ir->{states}},@{$ir->{dt_blocks}});
            is_deeply([sort keys %$contracts],[sort keys %actual],'every actual target has exactly one contract');
            is_deeply($ir,$before,'target collection leaves actual IR unchanged');
            my $carrier = $scheduler->lower($actor)->{files}{'implicit_writes.fsm'};
            my $path = write_file("carrier_${width}_${reverse}.fsm",$carrier);
            my $checked = $capture->([$^X,'bin/fsmgen','--strict','--check','--json',$path],'');
            is($checked->{exit_code},0,'actual carrier passes strict check') or diag($checked->{stdout},$checked->{stderr});
            my $semantic = $capture->([$^X,'bin/fsmgen','--strict','--emit-semantic-json',$path],'');
            is($semantic->{exit_code},0,'carrier semantic report succeeds') or diag($semantic->{stdout},$semantic->{stderr});
            my $report = $json->decode($semantic->{stdout});
            my %nets = map {$_->{name}=>$_} @{$report->{semantic}{forward_ir}{structural_rtl_ir}{nets}};
            is_deeply([map {$nets{$_}{width}} qw(captured copy scratch)],[$width,$width,1],
                'canonical downstream inference supplies the actual widths');
            my $native_path = write_file("native_${width}_${reverse}.isf",$text);
            my $native = $capture->([$^X,'bin/fsmgen','--strict','--emit-semantic-json',$native_path],'');
            is($native->{exit_code},0,'native source semantic report succeeds') or diag($native->{stdout},$native->{stderr});
            is_deeply($json->decode($native->{stdout})->{semantic},$report->{semantic},
                'complete native and replayed carrier semantic products agree');
        }
    }
};

subtest 'whole-root overlap stays conservative across explicit and implicit contracts' => sub {
    my $whole = $targets->whole_root('m','value');
    my $explicit = $targets->resolve('m',{value=>{width=>8}},'value');
    ok($targets->overlaps($whole,$explicit),'unknown-width root overlaps its explicit contract');
    ok($targets->overlaps($explicit,$whole),'mixed overlap is symmetric');
    ok($targets->overlaps($whole,$whole),'two implicit writes to one root overlap');
    ok(!$targets->overlaps($whole,$targets->whole_root('other','value')),'module identity remains separate');
    ok(!$targets->overlaps($whole,$targets->whole_root('m','other')),'different roots remain separate');
    my $aggregate = FSM::Adapter::ISF->new->parse_source(
        '(actor a (types (type record_t (record (high (bits 2)) (low bit)))) (storage (var value (type record_t))) (transaction main (set value.low 1)))','aggregate.isf');
    my $decl = {value=>$aggregate->{storage}[0]{signals}[0]};
    my $leaf = $targets->resolve('m',$decl,'value.low');
    ok($targets->overlaps($whole,$leaf),'whole-root coverage cannot claim disjointness from a member');
    ok($targets->overlaps($leaf,$whole),'member overlap is symmetric');
    for my $mutation (
        sub {delete $_[0]{module}}, sub {$_[0]{target}='value.part'},
        sub {$_[0]{coverage}='unknown'}, sub {$_[0]{width}=1},
        sub {$_[0]{low}=0}, sub {$_[0]{root}='different'},
    ) {
        my $bad=dclone($whole);$mutation->($bad);
        eval {$targets->overlaps($bad,$explicit)};
        like($@,qr/malformed whole-root contract/,'malformed coverage cannot silently prove compatibility');
    }
    for my $path ('value.part','value[0]','value[2:0]') {
        eval {$targets->whole_root('m',$path)};
        like($@,qr/bare signal target/,'partial target needs a resolved declaration layout');
    }
};

subtest 'actual sibling implicit writes share one conservative physical root' => sub {
    my $actor = FSM::Adapter::ISF->new->parse_source(
        '(actor siblings (interface (input first_start) (input second_start) (input left (width 8)) (input right (width 8))) (transaction first (on first_start) (set shared left)) (transaction second (on second_start) (set shared right)))', 'siblings.isf');
    my $ir = $scheduler->{ir}->build_module($actor);
    my @writes = grep {$_->{lhs} eq 'shared'} map {@{$_->{assignments}}} @{$ir->{states}};
    is(scalar @writes, 2, 'actual sibling states both write the implicit target');
    my $contracts = $collector->target_contracts($ir);
    ok($targets->overlaps(map {$contracts->{$_->{lhs}}} @writes), 'actual sibling writes cannot be called physically disjoint');
    $contracts->{shared}{root} = 'mutated';
    is($collector->target_contracts($ir)->{shared}{root}, 'shared', 'returned target mutation cannot alter later collection');
};

subtest 'missing aggregate declarations cannot become implicit whole-root evidence' => sub {
    my $actor = FSM::Adapter::ISF->new->parse_source(
        '(actor a (types (type r (record (member (bits 4))))) (storage (var value (type r))) (transaction main (set value.member 3)))','aggregate.isf');
    my $ir = $scheduler->{ir}->build_module($actor);
    ok($collector->target_contracts($ir)->{'value.member'},'declared member resolves');
    $ir->{declared_storage}=[];
    eval {$collector->target_contracts($ir)};
    like($@,qr/bare signal target/,'omitted layout refuses partial-target fallback despite retained known width');
};
done_testing();
