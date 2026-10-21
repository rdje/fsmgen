use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Storable qw(dclone);
use FSM::Adapter::ISF;
use FSM::Support::ISFReductions qw(capture_expression_reductions snapshot_reductions reduction_metadata_contract);
use FSM::Support::ISFRecordPortScopes qw(record_actor_scope record_transaction_scope record_drive_scope);
use FSM::Support::ISFRecordPortSamples qw(record_transaction_samples);
use FSM::Support::ISFRecordPortValues qw(record_value_scope);

my $json = JSON::PP->new->canonical;
my $parser = FSM::Adapter::ISF->new;
sub capture {
    my ($expression, $scope, $kind, $owner, $context) = @_;
    return capture_expression_reductions(expression => $expression, scope => $scope,
        owner_kind => $kind, owner => $owner, context => $context);
}
sub expected {
    my ($kind, $owner, $context, $operator, $operand, $width) = @_;
    return {owner_kind => $kind, owner => $owner, context => $context,
        kind => 'unary', operator => $operator, operand => $operand,
        operand_width => $width, result_width => 1};
}
sub rejects {
    my ($operation, $pattern, $label) = @_;
    my $ok = eval {$operation->(); 1};
    my $error = $@;
    ok(!$ok, "$label refuses");
    like($error, $pattern, "$label names its cause");
}

subtest 'actual supplied parsed rules retain exact slice and owner facts' => sub {
    my $actor = $parser->parse_file('docs/audits/specforge-reduction-intake-20261021/reduction-over-slice.isf');
    my $before = $json->encode($actor);
    my $scope = record_actor_scope(actor => $actor);
    my @records;
    for my $rule (@{$actor->{rules}}) {
        push @records, @{capture($rule->{actions}[0][1], $scope,
            'rule', $rule->{name}, "rule '$rule->{name}' assignment")};
    }
    is_deeply(\@records, [
        expected('rule','parity_byte0',"rule 'parity_byte0' assignment",'^','DATA[7:0]',8),
        expected('rule','parity_byte1',"rule 'parity_byte1' assignment",'^','DATA[15:8]',8),
    ], 'independent literal inventory joins both actual source rules and slices');
    is($json->encode($actor), $before, 'complete caller actor bytes and JSON kinds are preserved');
};

my $actor = $parser->parse_source(<<'ISF', 'reduction-records.isf');
(actor reduction_records
 (params (P 8)) (constants (C 8))
 (types (type frame (record (high (bits 3)) (low (bits 5)))))
 (interface (input start) (input bus (width 8)) (input packet (type frame))
  (output out) (output done))
 (drive tap (out (^ bus)))
 (drive (shadow bus) (out (^ bus)))
 (transaction main (on start) (local tmp (width 5))
  (sample bus as snap) (set out (^ snap)) (complete done))
 (rule mixed start (out (concat (^ bus) (and bus[7:4]) (or bus[0])))))
ISF
my $scope = record_actor_scope(actor => $actor);

subtest 'actual nested expressions, aliases and scalar record paths use declared widths' => sub {
    my $rule = $actor->{rules}[0];
    is_deeply(capture($rule->{actions}[0][1], $scope, 'rule', 'mixed', 'mixed RHS'), [
        expected('rule','mixed','mixed RHS','^','bus',8),
        expected('rule','mixed','mixed RHS','&','bus[7:4]',4),
        expected('rule','mixed','mixed RHS','|','bus[0]',1),
    ], 'preorder is independent of operator aliases and includes bit selection');
    for my $case (['packet.low',5], ['packet.high[1:0]',2], ['packet.low[0]',1]) {
        is_deeply(capture(['^',$case->[0]], $scope, 'rule', 'field', 'field RHS'),
            [expected('rule','field','field RHS','^',$case->[0],$case->[1])],
            "resolved packed scalar path $case->[0]");
    }
    is_deeply(capture(['^','bus','bus'], $scope, 'rule', 'binary', 'binary RHS'), [],
        'multi-operand expression is not reported as a unary reduction');
    is_deeply(capture('bus', $scope, 'rule', 'plain', 'plain RHS'), [], 'ordinary scalar yields no invented record');
};

subtest 'real declaration and sample scopes preserve local widths and mask untyped drive parameters' => sub {
    my $tx = $actor->{transactions}[0];
    my $local = record_transaction_scope(actor => $actor, transaction => $tx);
    is_deeply(capture(['|','tmp[3:1]'], $local, 'transaction','main','local RHS'),
        [expected('transaction','main','local RHS','|','tmp[3:1]',3)], 'literal local declaration is retained');
    my $samples = record_transaction_samples(actor => $actor, transaction => $tx);
    $local = record_value_scope(outer => $local, local => $samples->{bindings});
    my ($set) = grep {ref($_) eq 'ARRAY' && $_->[0] eq 'set'} @{$tx->{clauses}};
    is_deeply(capture($set->[2], $local, 'transaction','main','sample RHS'),
        [expected('transaction','main','sample RHS','^','snap',8)], 'actual parsed sample alias uses existing sample facts');
    my $drive = $actor->{drives}{tap};
    is_deeply(capture($drive->{body}[0][1], record_drive_scope(actor => $actor, drive => $drive),
        'drive','tap','tap RHS'), [expected('drive','tap','tap RHS','^','bus',8)], 'named drive sees declared actor input');
    $drive = $actor->{drives}{shadow};
    rejects(sub {capture($drive->{body}[0][1], record_drive_scope(actor => $actor, drive => $drive),
        'drive','shadow','shadow RHS')}, qr/shadow RHS.*operand 'bus'.*not a declared packed scalar signal/s,
        'untyped formal does not borrow the same-named actor input width');
};

subtest 'invalid operands fail contextually without changing caller state' => sub {
    for my $operand ('missing', 'P', 'C', '"bus"', "8'hAA", 'packet', 'bus[8]', 'packet.nope', 'bus[index]') {
        my $before = $json->encode($scope);
        rejects(sub {capture(['^',$operand], $scope, 'rule','bad','bad RHS')},
            qr/bad RHS.*(?:operand|scalar|path)/s, "nonvector or invalid path $operand");
        is($json->encode($scope), $before, "$operand failure preserves all declaration kinds");
    }
    rejects(sub {capture(['^',['+','bus','bus']], $scope, 'rule','bad','bad RHS')},
        qr/bad RHS.*operand must be a declared packed scalar/s, 'expression is not a declared vector operand');
    my $cycle = ['+','bus'];
    push @$cycle, $cycle;
    rejects(sub {capture($cycle, $scope, 'rule','bad','bad RHS')}, qr/expression is cyclic/, 'cyclic caller expression');
};

subtest 'snapshots are detached closed scalar records with canonical result kinds' => sub {
    my $record = expected('rule','r','r RHS','^','bus','8');
    $record->{result_width} = '1';
    my $before = $json->encode($record);
    my $snapshot = snapshot_reductions([$record]);
    is_deeply($snapshot, [expected('rule','r','r RHS','^','bus',8)], 'snapshot normalizes copied numeric facts');
    is($json->encode($record), $before, 'numeric validation preserves original caller JSON strings');
    $snapshot->[0]{operand} = 'changed';
    is($record->{operand}, 'bus', 'result mutation cannot change caller');
    $record->{owner} = 'changed';
    is($snapshot->[0]{owner}, 'r', 'caller mutation cannot change result');
    is(snapshot_reductions(undef), undef, 'absent declarations stay absent');
    is_deeply(snapshot_reductions([]), [], 'empty declarations stay empty');
    my @controls = (
        [kind => 'binary'], [operator => 'xor'], [operator => '+'],
        [owner_kind => 'external'], [owner => 'bad-name'], [owner => []], [context => {}], [operand => []],
        [operand_width => 0], [operand_width => JSON::PP::true], [result_width => 8],
        [result_width => JSON::PP::true], [ast => {private => 1}],
    );
    for my $control (@controls) {
        my $bad = expected('rule','r','r RHS','^','bus',8);
        $bad->{$control->[0]} = $control->[1];
        rejects(sub {snapshot_reductions([$bad])}, qr/Invalid ISF reductions:/,
            "genuine altered field $control->[0]");
    }
    my $bad = expected('rule','r','r RHS','^','bus',8);
    delete $bad->{operand};
    rejects(sub {snapshot_reductions([$bad])}, qr/missing fields/, 'omitted required operand');
    rejects(sub {FSM::Support::ISFReductions::_require('missing predicate')},
        qr/requires a predicate and message/, 'a dropped predicate cannot turn its message into success');
    my $contract = reduction_metadata_contract();
    $contract->{operator_values}[0] = 'changed';
    is_deeply(reduction_metadata_contract()->{operator_values}, ['^','&','|'], 'contract is freshly detached');
};

done_testing();
