#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Storable qw(dclone);
use JSON::PP;
use lib 'perl';
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::FormalLowering;
use FSM::Scheduler::ISF::PhysicalWriteTargets;

my $targets = 'FSM::Scheduler::ISF::PhysicalWriteTargets';
open my $fh,'<','docs/audits/direct-writer-admission-20260927/cases.json' or die $!;
my $cases = JSON::PP->new->decode(do {local $/;<$fh>});close $fh;
my $scheduler = FSM::Scheduler::ISF->new;
my %resolved;
subtest 'actual admitted baseline assignments resolve to physical target ranges' => sub {
    for my $case (grep {$_->{expected_admission} eq 'admitted'} @$cases) {
        my $actor = FSM::Adapter::ISF->new->parse_source($case->{source},'physical_targets.isf');
        my $context = FSM::Scheduler::ISF::FormalLowering->prepare($scheduler->{ir},$actor);
        my $ir = $scheduler->{ir}->build_module($context ? $context->{actor} : $actor);
        my %declarations = map {$_=>{width=>$ir->{signal_widths}{$_}}} keys %{$ir->{signal_widths}};
        $declarations{$_} //= {width=>$ir->{counters}{$_}} for keys %{$ir->{counters}};
        $declarations{$_->{name}} = {width=>$_->{width}} for @{$ir->{ports}};
        for my $storage (@{$ir->{declared_storage}}) {
            for my $signal (@{$storage->{signals}}) {
                $declarations{$signal->{name}} = dclone($signal);
            }
        }
        my $before = dclone(\%declarations);
        my @all = map {$targets->resolve($ir->{actor_name},\%declarations,$_->{target})} @{$ir->{assignment_provenance}};
        is(scalar @all,scalar @{$ir->{assignment_provenance}},"$case->{case_id} accounts for all actual assignments");
        $resolved{$case->{case_id}} = [map {$all[$_]} grep {
            $ir->{assignment_provenance}[$_]{domain} eq 'data'
        } 0..$#all];
        is_deeply(\%declarations,$before,"$case->{case_id} declarations stay detached");
    }
    for my $name (qw(scalar_overlap scalar_equal output_overlap parsed_transaction_priority bank_overlap masked_updates named_drive_overlap)) {
        ok($targets->overlaps(@{$resolved{$name}}[0,1]),"$name has overlapping actual physical writes");
    }
    for my $name (qw(scalar_disjoint private_formals aggregate_disjoint_leaves)) {
        ok(!$targets->overlaps(@{$resolved{$name}}[0,1]),"$name has separate actual physical writes");
    }
    ok($targets->overlaps(@{$resolved{aggregate_overlap}}[0,1]),'whole aggregate overlaps its member');
    is_deeply([map {[@{$_}{qw(root low high width)}]} @{$resolved{aggregate_disjoint_leaves}}],
        [['frame',1,2,2],['frame',0,0,1]],'packed member offsets match independent source layout');
    is_deeply([map {[@{$_}{qw(root low high width)}]} @{$resolved{masked_updates}}],
        [['value_reg',0,7,8],['value_reg',0,7,8]],'disjoint authored masks remain whole-register writes');
};

subtest 'nested record/list fragments reuse the canonical packed layout' => sub {
    my $actor = FSM::Adapter::ISF->new->parse_source(<<'ISF','nested_targets.isf');
(actor nested_targets
 (types (type packet_t (record (tag (bits 2)) (lanes (list (bits 3) (bits 2))))))
 (storage (var packet (type packet_t)))
 (transaction main (set packet.tag 1)))
ISF
    my $signal = $actor->{storage}[0]{signals}[0];
    my $decl = {packet=>dclone($signal)};
    my @paths = qw(packet packet.tag packet.lanes packet.lanes[0] packet.lanes[1] packet.lanes[0][1:0]);
    my @ranges = map {$targets->resolve('nested_targets',$decl,$_)} @paths;
    is_deeply([map {[@{$_}{qw(low high width)}]} @ranges],
        [[0,6,7],[5,6,2],[0,4,5],[2,4,3],[0,1,2],[2,3,2]],'nested packed ranges match independent arithmetic');
    ok($targets->overlaps($ranges[2],$ranges[5]),'nested list contains its scalar slice');
    ok(!$targets->overlaps($ranges[1],$ranges[5]),'tag and nested slice are disjoint');
    for my $i (0..$#ranges) {
        for my $j (0..$#ranges) {
            is($targets->overlaps($ranges[$i],$ranges[$j]),$targets->overlaps($ranges[$j],$ranges[$i]),'overlap is symmetric');
        }
    }
    my $other = $targets->resolve('other_module',$decl,'packet');
    ok(!$targets->overlaps($ranges[0],$other),'identically named roots in different modules are distinct');
    $ranges[5]{path_segments}[0]{name}='mutated';
    is_deeply($decl->{packet},$signal,'returned path mutation cannot change source declaration');
    is($ranges[2]{path_segments}[0]{name},'lanes','returned results do not alias each other');
};

subtest 'missing and inconsistent target contracts fail closed' => sub {
    my $bits = {value=>{width=>8,type_spec=>{kind=>'bits',width=>8}}};
    for my $case (
        [undef,$bits,'value',qr/module identity/],
        ['m',{},'value',qr/no resolved declaration/],
        ['m',{value=>{width=>0}},'value',qr/no resolved declaration/],
        ['m',{value=>{width=>8,type_spec=>{kind=>'bits',width=>4}}},'value',qr/inconsistent resolved type width/],
        ['m',$bits,'value.bad',qr/unresolved aggregate path/],
        ['m',$bits,'value[0]',qr/unresolved aggregate path/],
        ['m',$bits,'(value)',qr/scalar assignment target/],
    ) {
        my ($module,$decl,$target,$pattern)=@$case;
        eval {$targets->resolve($module,$decl,$target)};
        like($@,$pattern,'invalid declaration/target has a focused refusal');
    }
    my $good = $targets->resolve('m',$bits,'value');
    for my $mutation (
        sub {delete $_[0]{module}}, sub {$_[0]{low}=-1}, sub {$_[0]{high}=8},
        sub {$_[0]{width}=7}, sub {$_[0]{root_width}=0},
    ) {
        my $bad=dclone($good);$mutation->($bad);
        eval {$targets->overlaps($good,$bad)};
        like($@,qr/requires a resolved packed range/,'malformed overlap operand cannot silently prove disjointness');
    }
    my $different=$targets->resolve('m',{value=>{width=>4}},'value');
    eval {$targets->overlaps($good,$different)};
    like($@,qr/inconsistent root widths/,'same physical root cannot carry conflicting widths');
};
done_testing();
