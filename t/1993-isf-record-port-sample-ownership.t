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

my $parser = FSM::Adapter::ISF->new;
my $scheduler = FSM::Scheduler::ISF->new;
my $json = JSON::PP->new->canonical;
my $work = tempdir(CLEANUP=>1);

sub authored {
    my ($transactions, $rules) = @_;
    return $parser->parse_source(<<"ISF", 'sample-ownership.isf');
(actor sample_owners
 (types (type frame (record (data (four_state (signed (bits 3)))) (ready (two_state bit)))))
 (interface (input start) (input alternate) (input scalar (width 3))
  (output seen (width 3)) (output done))
 (storage (var packet (type frame) (reset 0)))
 (drive (publish value) (seen value))
 $transactions
 ${\($rules // '')})
ISF
}
sub prepared {
    my ($actor) = @_;
    $actor = dclone($actor);
    my $packet = shift @{$actor->{storage}};
    push @{$actor->{interface}{inputs}}, {map {$_=>$packet->{$_}} qw(name width type type_spec)};
    return $actor;
}
sub sample { ['sample',$_[0],'as',$_[1]] }
sub reject {
    my ($actor,$pattern,$label) = @_;
    my $before = $json->encode($actor);
    my $ok = eval {$scheduler->lower($actor); 1};
    my ($line) = split /\n/,$@;
    ok(!$ok, "$label refuses before emission");
    like($line // '', $pattern, "$label first diagnostic identifies ownership");
    is($json->encode($actor),$before,"$label leaves caller facts unchanged");
}
sub strict_carrier {
    my ($name,$text) = @_;
    open my $f,'>',"$work/$name" or die $!;
    print {$f} $text;
    close $f or die $!;
    open my $cli,'-|','./bin/fsmgen','--quiet','--strict','--check','--json',"$work/$name" or die $!;
    my $out = do {local $/; <$cli>};
    close $cli;
    is($? >> 8,0,"$name strictly replays");
    ok($json->decode($out)->{success},"$name replay reports success");
}

subtest 'actual drive and dynamic-counter products reserve sample identities' => sub {
    for my $case (
        ['drive_request','(drive publish scalar)','packet.ready'],
        ['drive_payload','(drive publish scalar)','packet.data'],
        ['dynamic_wait_counter','(wait scalar)','packet.data'],
    ) {
        my ($role,$operation,$source) = @$case;
        my $ordinary = authored("(transaction main (on start) $operation (complete done))");
        my $ir = $scheduler->{ir}->build_module($ordinary);
        my @helpers = sort grep {($ir->{storage_roles}{$_}//'') eq $role} keys %{$ir->{storage_roles}};
        is(scalar(@helpers),1,"ordinary production has one actual $role helper");
        next unless @helpers==1;
        my $helper = $helpers[0];
        ok(exists $ir->{counters}{$helper},"actual $role helper has a real declaration");
        my $actor = prepared($ordinary);
        push @{$actor->{transactions}[0]{clauses}[0]}, sample($source,$helper);
        reject($actor,qr/record-derived sample alias '\Q$helper\E'.*collides with a generated (?:declaration|storage role)/,
            "actual $role $helper collision");
    }
};

subtest 'actual spawn handoff ports reserve private sample identities' => sub {
    my $ordinary = authored('(transaction main (on start) (spawn worker as job) (await_all done) (complete done))
        (transaction worker (wait 1))');
    my $ir = $scheduler->{ir}->build_module($ordinary);
    for my $role (qw(activation_start_handoff activation_done_handoff)) {
        my @helpers = sort grep {($ir->{storage_roles}{$_}//'') eq $role} keys %{$ir->{storage_roles}};
        is(scalar(@helpers),1,"ordinary production has one $role declaration");
        next unless @helpers==1;
        my $helper = $helpers[0];
        ok((grep {$_->{name} eq $helper} @{$ir->{ports}}),"actual $role is a module handoff port");
        my $actor = prepared($ordinary);
        push @{$actor->{transactions}[0]{clauses}[0]},sample('packet.ready',$helper);
        reject($actor,qr/record-derived sample alias '\Q$helper\E'.*collides with (?:a module port|a generated declaration)/,
            "actual spawn $role collision");
    }
};

subtest 'private samples cannot share a transaction owner or accept other writers' => sub {
    my $a = prepared(authored('(transaction first (on start) (complete done))
        (transaction second (on alternate) (wait 1))'));
    push @{$a->{transactions}[0]{clauses}[0]},sample('packet.data','q');
    push @{$a->{transactions}[1]{clauses}[0]},sample('packet.data','q');
    reject($a,qr/record-derived sample alias 'q' has multiple transaction owners/,'two record sample owners');
    $a = prepared(authored('(transaction first (on start) (complete done))
        (transaction second (on alternate) (wait 1))'));
    push @{$a->{transactions}[0]{clauses}[0]},sample('packet.data','q');
    push @{$a->{transactions}[1]{clauses}[0]},sample('scalar','q');
    reject($a,qr/record-derived sample alias 'q' has multiple sample owners/,'record and ordinary sample owners');
    $a = prepared(authored('(transaction first (on start) (complete done))
        (transaction second (on alternate) (set q scalar))'));
    push @{$a->{transactions}[0]{clauses}[0]},sample('packet.data','q');
    reject($a,qr/record-derived sample alias 'q' has a different state writer/,'different transaction writer');
    $a = prepared(authored('(transaction first (on start) (complete done))',
        '(rule overwrite alternate (set q scalar))'));
    push @{$a->{transactions}[0]{clauses}[0]},sample('packet.data','q');
    reject($a,qr/record-derived sample alias 'q' has a decision-tree writer/,'actor rule writer');
};

subtest 'repeated private captures and separate generated module owners are valid' => sub {
    my $a = prepared(authored('(transaction main (on start) (set seen scalar) (complete done))'));
    push @{$a->{transactions}[0]{clauses}[0]},sample('packet.data','q');
    splice @{$a->{transactions}[0]{clauses}},1,0,sample('packet.data','q');
    my $before = $json->encode($a);
    my $result = $scheduler->lower($a);
    is($json->encode($a),$before,'repeated same-owner captures preserve caller facts');
    my $fsm = $result->{files}{'sample_owners.fsm'};
    is(scalar(()=$fsm =~ /\(type _isf_sample_q /g),1,'same-owner scalar type declared once');
    like($fsm,qr/\(internal q\)/,'unused sampled value remains private');
    unlike($fsm,qr/\((?:input|output) q\)/,'unused sample creates no authored pin');
    strict_carrier('sample_owners.fsm',$fsm);

    $a = prepared(authored('(transaction main (on start) (spawn worker as job) (await_all done) (complete done))
        (transaction worker (wait 1))'));
    push @{$a->{transactions}[0]{clauses}[0]},sample('packet.data','q');
    unshift @{$a->{transactions}[1]{clauses}},sample('packet.data','q');
    $before=$json->encode($a);
    $result=$scheduler->lower($a);
    is($json->encode($a),$before,'separate physical owners preserve caller facts');
    for my $name ('sample_owners.fsm','worker.fsm') {
        like($result->{files}{$name},qr/\(q _isf_sample_q\)/,"$name owns its own typed sample");
        strict_carrier($name,$result->{files}{$name});
    }
};

done_testing;
