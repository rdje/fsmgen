use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use Storable qw(dclone);
use JSON::PP;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::ISFRecordPortContexts qw(validate_actor_record_contexts);

my $parser = FSM::Adapter::ISF->new;
my $json = JSON::PP->new->canonical;
my $source = <<'ISF';
(actor contexts
  (types (type frame (record (flag bit) (data (signed (four_state (bits 7))))))
    (type alias frame) (type other (record (flag bit) (data (bits 7)))))
  (enums (mode (IDLE 0) (BUSY 1)))
  (interface (input start) (input scalar (width 8)) (output seen (width 8)) (output done))
  (storage (var packet (type frame)) (var held (type alias)) (var mismatch (type other)))
  (transaction main (on start) (set held packet) (set seen packet.data) (complete done)))
ISF
my $original = $parser->parse_source($source, 'record-context-controls.isf');
my $prepared = dclone($original);
my $port = shift @{$prepared->{storage}};
push @{$prepared->{interface}{inputs}}, {map {$_ => $port->{$_}} qw(name width type type_spec)};

sub transaction {
    my (@clauses) = @_;
    my $actor = dclone($prepared);
    $actor->{transactions}[0]{clauses} = \@clauses;
    return $actor;
}
sub rules {
    my ($guard, @actions) = @_;
    my $actor = transaction();
    $actor->{rules} = [{name => 'copy', when => ['when', $guard], actions => \@actions}];
    return $actor;
}
sub drives {
    my ($params, @body) = @_;
    my $actor = transaction();
    $actor->{drives} = {publish => {params => $params, body => \@body}};
    return $actor;
}
sub accepts {
    my ($actor, $name) = @_;
    my $before = $json->encode($actor);
    my $ok = eval {validate_actor_record_contexts(actor => $actor); 1};
    ok($ok, "$name validates") or diag((split /\n/, $@)[0]);
    is($json->encode($actor), $before, "$name leaves complete actor unchanged");
}
sub refuses {
    my ($actor, $pattern, $name) = @_;
    my $before = $json->encode($actor);
    my $ok = eval {validate_actor_record_contexts(actor => $actor); 1};
    my ($line) = split /\n/, $@;
    ok(!$ok, "$name refuses");
    like($line // '', $pattern, "$name names its first-line cause");
    is($json->encode($actor), $before, "$name leaves complete actor unchanged");
}

subtest 'selected transaction scalar contexts retain scalar leaves' => sub {
    accepts(transaction(['set', 'seen', 'packet.data']), 'set scalar leaf');
    accepts(transaction(['update', 'seen', ['+', 'packet.data[3:1]', 'scalar']]), 'update expression and leaf slice');
    for my $head (qw(when while until)) {
        accepts(transaction([$head, ['==', 'packet.flag', 1], ['set', 'seen', 'packet.data']]), "$head body");
        accepts(transaction([$head, '!packet.flag', ['set', 'seen', 1]]), "$head compact negation");
        accepts(transaction([$head, '1==packet.flag', ['set', 'seen', 1]]), "$head compact comparison");
    }
    accepts(transaction(['repeat', 2, ['when', 'packet.flag', ['set', 'seen', 'packet.data']]]), 'repeat nested body');
    accepts(transaction(['switch', 'packet.data', ['packet.flag', ['set', 'seen', 'packet.data']],
        ['default', ['set', 'seen', 0]]]), 'switch selector and branch values');
};

subtest 'whole record copies consume strict type and declared roles' => sub {
    accepts(transaction(['set', 'held', 'packet']), 'set input to equivalent alias storage');
    accepts(transaction(['update', 'held', 'packet']), 'update whole copy');
    accepts(rules('packet.flag', ['set', 'held', 'packet']), 'rule whole copy');
    accepts(rules(['==', 'packet.flag', 1], ['held', 'packet']), 'rule shorthand whole copy');
    accepts(drives([], ['held', 'packet']), 'named drive whole copy');
    accepts(transaction(['drive', 'inline', ['held', 'packet']]), 'inline drive whole copy');
    for my $head (qw(set update)) {
        refuses(transaction([$head, 'mismatch', 'packet']), qr/requires the same resolved record type/,
            "$head equal-width signed/state mismatch");
        refuses(transaction([$head, 'seen', 'packet']), qr/whole record port copy requires declared record roots/,
            "$head whole record to scalar");
        refuses(transaction([$head, 'held.data', 'packet']), qr/whole record port copy requires declared record roots/,
            "$head whole record to scalar leaf");
    }
};

subtest 'rule and drive scalar reads keep selected scope' => sub {
    accepts(rules('packet.flag', ['set', 'seen', ['+', 'packet.data', 'scalar']]), 'rule scalar guard and RHS');
    accepts(rules(['==', 'packet.data', 3], ['seen', 'packet.data']), 'rule expression guard and shorthand RHS');
    accepts(drives([], ['seen', ['+', 'packet.data', 'scalar']]), 'named drive leaf expression');
    accepts(transaction(['drive', 'inline', ['seen', 'packet.data']]), 'labeled inline drive');
    accepts(transaction(['drive', ['seen', 'packet.data']]), 'unlabeled inline drive');
    my $actor = transaction(['drive', 'publish', ['+', 'packet.data', 'scalar']]);
    $actor->{drives} = {publish => {params => ['value'], body => [['seen', 'value']]}};
    accepts($actor, 'named drive scalar actual');
    accepts(drives(['packet'], ['seen', 'packet']), 'untyped drive parameter masks actor record');
};

subtest 'every selected scalar context rejects whole record ports' => sub {
    for my $value ('packet', '!packet', 'packet==1', '1==packet', ['+', 1, 'packet']) {
        for my $head (qw(when while until)) {
            refuses(transaction([$head, $value, ['set', 'seen', 1]]), qr/requires a scalar value.*whole record port/,
                "$head whole record condition " . $json->encode($value));
        }
        refuses(transaction(['switch', $value, [0, ['set', 'seen', 1]]]),
            qr/requires a scalar value.*whole record port/, 'whole record switch selector');
        refuses(rules($value, ['seen', 1]), qr/requires a scalar value.*whole record port/, 'whole record rule guard');
        my $actor = transaction(['drive', 'publish', $value]);
        $actor->{drives} = {publish => {params => ['value'], body => [['seen', 'value']]}};
        refuses($actor, qr/requires a scalar value.*whole record port/, 'whole record drive actual');
    }
    refuses(transaction(['switch', 'scalar', ['packet', ['set', 'seen', 1]]]),
        qr/switch branch value requires a scalar value/, 'whole record switch branch');
    refuses(transaction(['set', 'seen', ['+', 1, 'packet']]), qr/requires a scalar value.*whole record port/,
        'whole record arithmetic RHS');
    refuses(transaction(['set', 'seen', ['packet.data', 1]]), qr/operator cannot use declared aggregate reference/,
        'leaf reference in expression operator position');
};

subtest 'known input targets and invalid paths fail in each assignment family' => sub {
    for my $target ('packet', 'packet.data') {
        for my $actor (
            transaction(['set', $target, 0]), transaction(['update', $target, 0]),
            rules('start', ['set', $target, 0]), rules('start', [$target, 0]),
            drives([], [$target, 0]), transaction(['drive', 'inline', [$target, 0]]),
            rules('start', ['pulse', $target]),
        ) {
            refuses($actor, qr/cannot write declared input '\Q$target\E'/, "input target $target");
        }
    }
    refuses(transaction(['set', 'seen', 'packet.missing']), qr/invalid declared path 'packet.missing': unknown_member/,
        'unknown declared record member');
    refuses(transaction(['set', 'seen', 'packet.data[7]']), qr/scalar_index_out_of_range/,
        'leaf index outside resolved width');
    my $shadow = transaction(['set', 'seen', 'packet.data']);
    $shadow->{transactions}[0]{ports} = {inputs => [], outputs => [{name => 'packet', width => 3}]};
    refuses($shadow, qr/member_on_non_record/, 'scalar formal prevents outer record lookup');
    $shadow = transaction(['set', 'seen', 'packet.data']);
    $shadow->{transactions}[0]{ports} = {inputs => [], outputs => [{name => 'packet', width => 1, type => 'unresolved'}]};
    accepts($shadow, 'unresolved formal is delegated without outer type borrowing');
};

subtest 'unselected source contexts do not inherit leaf-read permission' => sub {
    for my $clause (
        ['wait', 'packet.data'], ['repeat', 'packet.data', ['set', 'seen', 1]],
        ['sample', 'packet.data', 'as', 'captured'], ['on', 'packet.flag'],
    ) {
        refuses(transaction($clause), qr/does not admit record port reference/,
            'unselected ' . $clause->[0]);
    }
};

subtest 'legacy storage and unrelated tokens remain under existing validators' => sub {
    accepts(dclone($original), 'actual admitted record storage and scalar-port source');
    my $actor = transaction(['set', 'held', 'mismatch'], ['set', 'seen', 'mode.BUSY'],
        ['when', ['==', 'shared.LIMIT', "scalar'8"], ['set', 'seen', 1]],
        ['when', ['state_active', 'packet'], ['set', 'seen', 1]]);
    accepts($actor, 'storage-only packed transfers and enum/package/scalar annotations');
    accepts(transaction(['set', 'seen', 'unknown.member']), 'unknown token remains delegated');
    my $enum_pin = $parser->parse_source('(actor enum_pin (enums (mode (BUSY 1)))'
        . ' (interface (input mode) (output seen)) (transaction main (set seen mode.BUSY)))', 'enum-pin.isf');
    accepts($enum_pin, 'actual admitted enum namespace sharing a scalar pin name');
    my $shadow = transaction(['set', 'seen', 'packet.data']);
    $shadow->{enum_symbols}{local}{packet} = {data => 1};
    $shadow->{transactions}[0]{ports} = {inputs => [], outputs => [{name => 'packet', width => 3}]};
    refuses($shadow, qr/member_on_non_record/,
        'enum token cannot supply a shadowed actor aggregate member');
    my $before = $json->encode($original);
    my $lowered = $json->encode(FSM::Scheduler::ISF->new->lower(dclone($original)));
    validate_actor_record_contexts(actor => $original);
    is($json->encode($original), $before, 'complete actual parsed actor unchanged');
    is($json->encode(FSM::Scheduler::ISF->new->lower(dclone($original))), $lowered,
        'complete scheduled object and emitted source bytes unchanged');
};

done_testing;
