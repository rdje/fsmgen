use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Storable qw(dclone);
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::ISFRecordPortContexts qw(validate_actor_record_contexts);

my $parser=FSM::Adapter::ISF->new;
my $scheduler=FSM::Scheduler::ISF->new;
my $json=JSON::PP->new->canonical;
my $work=tempdir(CLEANUP=>1);
my $header=<<'ISF';
(actor sample_replay
 (types (type frame (record (tag (bits 2))
   (payload (record (count (four_state (signed (bits 3))))
     (flags (list (two_state bit) (bits 2))))))))
 (interface (input start) (input ack) (input mode) (input scalar (width 3)) (input flag)
  (output seen (width 3)) (output done))
 (storage (var packet (type frame) (reset 0)))
 (drive (publish value) (seen value))
ISF
sub parsed { $parser->parse_source($header.$_[0].')','sample-replay.isf') }
sub substitute_sample_sources {
    my ($value)=@_;
    return unless ref($value) eq 'ARRAY';
    if (@$value==4 && !ref($value->[0]) && $value->[0] eq 'sample') {
        $value->[1]='packet.payload.count' if $value->[1] eq 'scalar';
        $value->[1]='packet.payload.flags[0]' if $value->[1] eq 'flag';
    } else {
        substitute_sample_sources($_) for @$value;
    }
}
sub prepared {
    my ($actor)=@_;
    $actor=dclone($actor);
    my $packet=shift @{$actor->{storage}};
    push @{$actor->{interface}{inputs}},{map {$_=>$packet->{$_}} qw(name width type type_spec)};
    # The source reference is admitted scalar sampling. Only these selected
    # sample operands change to the supplied record-input leaf facts.
    substitute_sample_sources($_->{clauses}) for @{$actor->{transactions}};
    return $actor;
}
sub cli_semantic {
    my ($text,$name)=@_;
    open my $f,'>',"$work/$name.fsm" or die $!;
    print {$f} $text; close $f or die $!;
    open my $cli,'-|','./bin/fsmgen','--quiet','--strict','--emit-semantic-json',"$work/$name.fsm" or die $!;
    my $out=do {local $/;<$cli>}; close $cli;
    is($? >> 8,0,"$name actual typed IAL0 semantic replay succeeds");
    my $report=$json->decode($out);
    ok($report->{success},"$name returns a complete successful semantic product");
    is($report->{source}{input},"$work/$name.fsm","$name retains the actual replay source identity");
    return $report->{semantic};
}
sub qualify {
    my ($ordinary,$aliases,$label)=@_;
    my $actor=prepared($ordinary);
    my $before=$json->encode($actor);
    ok(validate_actor_record_contexts(actor=>$actor),"$label contextual record sample bindings qualify");
    my $original=$scheduler->{ir}->build_module(dclone($ordinary));
    my $actual=$scheduler->{ir}->build_module($actor);
    my $expected=dclone($original->{states});
    for my $state (@$expected) {
        substitute_sample_sources($state->{body_clauses}) if exists $state->{body_clauses};
        for my $assignment (@{$state->{assignments}}) {
            next unless ($assignment->{source_kind}//'') eq 'sample_capture';
            $assignment->{rhs}='packet.payload.count' if $assignment->{rhs} eq 'scalar';
            $assignment->{rhs}='packet.payload.flags[0]' if $assignment->{rhs} eq 'flag';
        }
    }
    is_deeply($actual->{states},$expected,"$label complete assignments/guards/transitions/states match after only deliberate source substitution");
    is($json->encode($actor),$before,"$label complete caller facts stay unchanged");
    my $fsm=$scheduler->lower($actor)->{files}{'sample_replay.fsm'};
    my $sem=cli_semantic($fsm,$label);
    my %nets=map {$_->{name}=>$_} @{$sem->{forward_ir}{structural_rtl_ir}{nets}};
    for my $alias (sort keys %$aliases) {
        my $spec=$aliases->{$alias};
        is_deeply($sem->{symbol_contract}{types}{"_isf_sample_$alias"},$spec,
            "$label actual core scalar type matches the independent leaf witness for $alias");
        is_deeply($nets{$alias}{declared_type_spec},$spec,
            "$label actual private net retains the complete scalar type for $alias");
        unlike($fsm,qr/\((?:input|output) \Q$alias\E\)/,"$label $alias creates no public pin");
    }
    return ($actual,$fsm);
}
my $count={kind=>'bits',width=>3,signed=>1,state_model=>'four_state'};
my $flag={kind=>'bit',width=>1,signed=>0,state_model=>'two_state'};

subtest 'entry await named-drive and pre-data captures preserve complete existing states' => sub {
    my $ordinary=parsed(<<'ISF');
 (transaction main
  (on start (sample scalar as entry))
  (sample scalar as await_q) (await ack)
  (sample scalar as drive_q) (drive publish drive_q)
  (sample flag as data_q) (set seen await_q)
  (complete done))
ISF
    my ($ir,$fsm)=qualify($ordinary,
        {entry=>$count,await_q=>$count,drive_q=>$count,data_q=>$flag},'entry_body');
    my %states=map {$_->{name}=>$_} @{$ir->{states}};
    my ($entry)=grep {$_->{lhs} eq 'entry'} @{$states{main_idle_0}{assignments}};
    is_deeply($entry,
        {lhs=>'entry',rhs=>'packet.payload.count',op=>'<=',source_kind=>'sample_capture',guard=>{port=>'start'}},
        'entry sample retains its exact existing start-qualified capture');
    is_deeply($states{main_idle_0}{guard},{port=>'start'},'existing entry admission guard remains exact');
    my ($await)=grep {$_->{kind} eq 'await'} @{$ir->{states}};
    is_deeply($await->{assignments},[{lhs=>'await_q',rhs=>'packet.payload.count',op=>'<=',source_kind=>'sample_capture'}],
        'await carries the existing unguarded pending capture, without inventing entry-only timing');
    like($fsm,qr/\(<= \(drive_q packet.payload.count\)\)/,'named drive retains its piggyback capture');
    like($fsm,qr/main_sample_3[\s\S]*\(-> main_set_4\)/,'pre-data capture retains its dedicated predecessor state');
};

subtest 'nested when while until repeat and switch captures preserve complete states' => sub {
    for my $case (
        ['when','(when mode (sample scalar as q) (drive publish q))'],
        ['while','(while mode (sample scalar as q) (set seen q))'],
        ['until','(until ack (sample scalar as q) (set seen q))'],
        ['repeat','(repeat 2 (sample scalar as q) (set seen q))'],
        ['switch','(switch mode (1 (sample scalar as q) (set seen q)))'],
    ) {
        qualify(parsed("(transaction main (on start) $case->[1] (complete done))"),{q=>$count},$case->[0]);
    }
};

subtest 'actual nearest scalar formal cannot borrow an outer record sample type' => sub {
    my $ordinary=parsed('(transaction main (ports (input packet (width 3))) (on start)
        (sample packet as q) (set seen q) (complete done))');
    my $actor=prepared($ordinary);
    my $before=$json->encode($actor);
    ok(validate_actor_record_contexts(actor=>$actor),'nearest formal scalar sampling qualifies');
    my $fsm=$scheduler->lower($actor)->{files}{'sample_replay.fsm'};
    unlike($fsm,qr/\(type _isf_sample_q /,'scalar formal remains with ordinary sampling owner');
    unlike($fsm,qr/\(<= \(q packet\)/,'formal source uses its actual distinct physical identity');
    like($fsm,qr/\(<= \(q isf_port_main_packet\)/,'capture uses the actual renamed scalar formal');
    cli_semantic($fsm,'formal_shadow');
    is($json->encode($actor),$before,'nearest formal preserves complete caller facts');
};

subtest 'actual imported nested leaf samples preserve the same state and scalar contract' => sub {
    open my $pkg,'>',"$work/shared.fsm" or die $!;
    print {$pkg} '(?pkg:shared (+types (type frame (record (tag (bits 2))'
        . ' (payload (record (count (four_state (signed (bits 3))))'
        . ' (flags (list (two_state bit) (bits 2)))))))))';
    close $pkg or die $!;
    my $source=$header;
    my $first=index($source,' (types');
    my $last=index($source,' (interface',$first);
    substr($source,$first,$last-$first)=" (imports (package shared))\n";
    $source =~ s/\(type frame\)/(type shared.frame)/;
    $source .= '(transaction main (on start (sample scalar as q)) (set seen q) (complete done)))';
    open my $file,'>',"$work/imported.isf" or die $!;
    print {$file} $source; close $file or die $!;
    my $ordinary=$parser->parse_file("$work/imported.isf");
    my ($ir,$fsm)=qualify($ordinary,{q=>$count},'imported');
    is($ir->{signal_type_refs}{packet},'shared.frame','actual imported record root retains qualified alias');
    like($fsm,qr/\(packet shared\.frame\)/,'actual packed input keeps its imported type carrier');
};

subtest 'whole invalid and nearest-masked record sample references refuse before carriers' => sub {
    my $plain=parsed('(transaction main (on start (sample scalar as q)) (set seen q) (complete done))');
    for my $case (
        ['packet',qr/whole record/,'whole input snapshot'],
        ['packet.payload.missing',qr/unknown_member/,'invalid nested member'],
    ) {
        my $actor=prepared($plain);
        $actor->{transactions}[0]{clauses}[0][2][1]=$case->[0];
        my $before=$json->encode($actor);
        my $ok=eval {validate_actor_record_contexts(actor=>$actor);1};
        my ($line)=split /\n/,$@;
        ok(!$ok,"$case->[2] refuses before carrier construction");
        like($line // '',$case->[1],"$case->[2] retains its precise first diagnostic");
        is($json->encode($actor),$before,"$case->[2] preserves all caller facts");
    }
    my $actor=prepared(parsed('(transaction main (ports (input packet (width 3)))
        (on start (sample packet as q)) (set seen q) (complete done))'));
    $actor->{transactions}[0]{clauses}[0][2][1]='packet.payload.count';
    my $before=$json->encode($actor);
    my $ok=eval {validate_actor_record_contexts(actor=>$actor);1};
    my ($line)=split /\n/,$@;
    ok(!$ok,'nearest scalar formal cannot sample a borrowed record member');
    like($line // '',qr/member_on_non_record/,'nearest-mask refusal names the scalar member error');
    is($json->encode($actor),$before,'nearest-mask refusal preserves all caller facts');
};

done_testing;
