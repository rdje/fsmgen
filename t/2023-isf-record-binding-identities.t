use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::ISFRecordPortContexts qw(validate_actor_record_contexts);

my $json = JSON::PP->new->canonical;
my $parser = FSM::Adapter::ISF->new;

sub source {
    my ($kind, %args) = @_;
    my $target = $args{target} // 'worker';
    my $instance = $args{instance} // 'job';
    my $formal = $args{formal} // 'packet';
    my $output = $args{output} // 'result';
    my $actual = $args{actual} // 'scalar';
    my $parameter = $args{parameter} // 'LAT';
    my $params = $kind =~ /generated/ ? "(params ($parameter 1))" : '';
    my $timing = $args{timing} ? " (timing $args{timing})" : '';
    my $domain = $args{domain} ? " (domain $args{domain})" : '';
    my $root = $args{record_root} // 'packet';
    my $binding = "(bind (input $formal $actual$timing)";
    $binding .= " (output $output seen)" unless $kind eq 'local_trigger';
    $binding .= ')';
    my $body;
    if ($kind eq 'spawn') {
        $body = "(transaction main (on start) (spawn $target as $instance $binding$domain) (await_all done) (complete done))";
    } elsif ($kind =~ /do/) {
        $body = "(transaction main (on start) (do $target $params $binding$domain) (complete done))";
    } else {
        $body = "(rule launch start (trigger $target $params $binding))";
    }
    my $record = $args{scalar_control} ? '(width 4)' : '(type frame)';
    my $worker_params = $kind =~ /generated/ || $kind eq 'spawn' ? "(params ($parameter 1))" : '';
    my $worker = "(transaction $target $worker_params (ports (input $formal (width 3))";
    $worker .= " (output $output (width 3))" unless $kind eq 'local_trigger';
    $worker .= ") (set " . ($kind eq 'local_trigger' ? 'seen' : $output) . " $formal\[2:0\]) (complete done))";
    my $system = $args{domain} ? "(clock-domains (domain $args{domain} (clock clk) :default) (domain aux (clock aux_clk)))"
        : '(clock clk) (reset (rst_n async active_low))';
    my $record_domain = $args{domain} ? ' (domain aux)' : '';
    return "(actor binding_identity $system"
        . ' (types (type frame (record (data (bits 4)))))'
        . " (interface (input start) (input scalar (width 3)) (input $root $record$record_domain) (output seen (width 3)) (output done))"
        . " $worker $body)";
}

subtest 'actual scalar-only controls calibrate each admitted activation family' => sub {
    for my $kind (qw(spawn local_do generated_do local_trigger generated_trigger)) {
        my $actor = eval {$parser->parse_source(source($kind, scalar_control => 1), "$kind-control.isf")};
        ok($actor, "$kind scalar-only source parses") or diag($@);
        next unless $actor;
        my $before = $json->encode($actor);
        my $lowered = eval {FSM::Scheduler::ISF->new->lower($actor)};
        ok($lowered, "$kind scalar-only source lowers with the existing binding contract") or diag($@);
        is($json->encode($actor), $before, "$kind leaves the complete first-read actor unchanged");
    }
};

subtest 'callee scalar formal names are identities in each actual activation family' => sub {
    for my $kind (qw(spawn local_do generated_do local_trigger generated_trigger)) {
        my $actor = eval {$parser->parse_source(source($kind), "$kind-record.isf")};
        ok($actor, "$kind scalar callee input name does not read the actor record") or diag((split /\n/, $@)[0]);
        next unless $actor;
        my $before = $json->encode($actor);
        ok(validate_actor_record_contexts(actor => $actor), "$kind module admission agrees with parsing");
        is($json->encode($actor), $before, "$kind context gate preserves complete actor facts");
        my $lowered = eval {FSM::Scheduler::ISF->new->lower($actor)};
        ok($lowered, "$kind actual record-bearing source lowers") or diag($@);
        is($json->encode($actor), $before, "$kind lowering preserves complete actor facts");
    }
};

subtest 'output formal, transaction target and instance labels retain identity roles' => sub {
    for my $args (
        {formal => 'data', output => 'packet'},
        {formal => 'data', target => 'packet'},
        {formal => 'data', instance => 'packet'},
    ) {
        my $actor = eval {$parser->parse_source(source('spawn', %$args), 'identity-roles.isf')};
        ok($actor, 'authored structural identity does not read the same-named actor record') or diag((split /\n/, $@)[0]);
        next unless $actor;
        my $before = $json->encode($actor);
        my $lowered = eval {FSM::Scheduler::ISF->new->lower($actor)};
        ok($lowered, 'actual scalar binding with the colliding identity lowers') or diag($@);
        is($json->encode($actor), $before, 'complete caller actor is unchanged');
    }
};

subtest 'activation metadata names retain their declared identity roles' => sub {
    for my $case (
        ['generated_do', {formal => 'data', parameter => 'packet'}],
        ['spawn', {formal => 'data', domain => 'packet'}],
        ['spawn', {formal => 'data', record_root => 'live', timing => 'live'}],
        ['local_do', {formal => 'data', record_root => 'snapshot', timing => 'snapshot'}],
    ) {
        my ($kind, $args) = @$case;
        my $actor = eval {$parser->parse_source(source($kind, %$args), 'metadata-identities.isf')};
        ok($actor, 'actual static metadata identity does not read the actor record') or diag((split /\n/, $@)[0]);
        next unless $actor;
        my $before = $json->encode($actor);
        my $lowered = eval {FSM::Scheduler::ISF->new->lower($actor)};
        ok($lowered, 'existing static parameter/domain/timing validation still admits its matching control') or diag($@);
        is($json->encode($actor), $before, 'complete caller facts remain unchanged');
    }
};

subtest 'binding values keep the unsupported record-actual boundary' => sub {
    for my $kind (qw(spawn local_do generated_do local_trigger generated_trigger)) {
        for my $actual ('packet', 'packet.data', ['+', 'packet.data', 0]) {
            my $value = ref($actual) ? '(+ packet.data 0)' : $actual;
            my $actor = eval {$parser->parse_source(source($kind, actual => $value), "$kind-actual.isf")};
            ok(!$actor, "$kind actual record operand remains refused");
            like((split /\n/, $@)[0] // '', ($kind =~ /trigger/ && $value eq 'packet.data'
                    ? qr/input bind expression must be a scalar signal, numeric\/exact-width literal, or non-empty list expression/
                    : qr/does not admit record port reference 'packet(?:\.data)?'/),
                "$kind independently expected grammar or contextual first cause");
        }
    }
};

subtest 'malformed and unknown metadata cannot hide record operands' => sub {
    my $original = $parser->parse_source(source('spawn'), 'metadata-scan-control.isf');
    for my $activation (
        ['spawn', 'worker', 'as', 'job', ['bind', ['input', 'packet', 'scalar'], ['output', 'result', 'packet']]],
        ['spawn', 'worker', 'as', 'job', ['bind', ['input', 'packet', 'scalar', ['timing', 'packet']]]],
        ['spawn', 'worker', 'as', 'job', ['bind', ['packet', 'scalar', 0]]],
        ['spawn', 'worker', 'packet', 'job', ['bind', ['input', 'packet', 'scalar']]],
        ['spawn', 'worker', 'as', 'job', ['unknown', 'packet.data']],
        ['spawn', 'worker', 'as', 'job', ['params', ['KEY', ['+', 'packet.data', 0]]]],
        ['spawn', 'worker', 'as', 'job', ['params', ['packet', 'packet']]],
        ['spawn', 7, 'as', 'job', ['bind', ['input', 'packet', 'scalar']]],
        ['spawn', 'worker', 'as', 7, ['bind', ['input', 'packet', 'scalar']]],
        ['spawn', 'worker', 'as', 'job', ['bind', ['input', 7, 'packet']]],
        ['spawn', 'worker', 'as', 'job', ['bind', ['input', undef, 'packet']]],
        ['spawn', 'worker', 'as', 'job', ['params', [7, 'packet']]],
        ['spawn', 'worker', 'as', 'job', ['domain', 7], ['bind', ['input', 'packet', 'packet']]],
        ['spawn', 'worker', 'as', 'job', ['bind', ['input', 'packet', 'scalar', ['timing', 7], ['unknown', 'packet']]]],
    ) {
        my $actor = $json->decode($json->encode($original));
        $actor->{transactions}[1]{clauses}[1] = $activation;
        my $before = $json->encode($actor);
        my $ok = eval {validate_actor_record_contexts(actor => $actor); 1};
        ok(!$ok, 'record value in a malformed/unknown source form remains refused at module admission');
        like((split /\n/, $@)[0] // '', qr/does not admit record port reference 'packet(?:\.data)?'/,
            'conservative fallback retains the independent record-value cause');
        is($json->encode($actor), $before, 'module refusal preserves the entire caller actor');
    }
};

done_testing;
