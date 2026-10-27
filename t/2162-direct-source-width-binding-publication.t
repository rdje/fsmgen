use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(weaken refaddr);
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::Adapter::FSMGenFull::Parser;
use FSM::Adapter::FSMGenFull::SignalAnalyzer;

my $json = JSON::PP->new->canonical;
sub parse_text { my ($a, $text) = @_; return $a->parse_fsm(scalar Lispish::multi(\$text)) }
sub adapter { return FSM::Adapter::FSMGenFull->new(debug => 0) }
sub binding { return $_[0]{signal_manager}->get_signal($_[1])->declared_width_binding }
my $valid = '(?fsm:source_widths (+params (W 8) (ONE 1)) (+size (DATA (param W)) (FLAG (param ONE)))'
    .' (idle (= (DATA 0)) (= (FLAG 0))))';

subtest 'actual source publishes complete lexical bindings on the real assigned objects' => sub {
    my $a = adapter(); my $raw = Lispish::multi('t/corpus/direct_size_parameter_selection.fsm');
    my $before = $json->encode($raw); my $m = $a->parse_fsm($raw);
    my $record = binding($a, 'SELECTED');
    ok($record, 'actual explicit parameter width publishes a binding');
    if ($record) {
        is($json->encode($record), $json->encode({width => 16,
            scope => {kind => 'direct_module', owner => 'direct_size_parameter_selection'},
            signal => 'SELECTED', expression => ['param', ['W']],
            binding => {kind => 'reference', observation_index => 0, value_expression => {kind => 'literal', token => '16'}},
            observations => [{lookup => 'parameter', kind => 'parameter', token => 'W', parameter => 'W', suffix => '',
                value_payload => {kind => 'scalar', payload => '16'}}]}), 'whole independently expected source association');
        $m->{name} = 'physical_rename';
        is(binding($a, 'SELECTED')->{scope}{owner}, 'direct_size_parameter_selection', 'physical module rename cannot rewrite lexical scope');
    }
    my @targets;
    for my $state (@{$m->states}) {
        for my $tree (@{$state->decision_trees}) {
            for my $action (@{$tree->elements}) {
                push @targets, @{$action->get_target_signals}
                    if $action->isa('FSM::CoreAST::Assignment');
            }
        }
    }
    my ($actual) = grep {$_->name eq 'SELECTED'} @targets;
    ok($actual, 'actual assignment AST reaches the declared target');
    if ($actual) {
        is(refaddr($actual), refaddr($a->{signal_manager}->get_signal('SELECTED')), 'publication updates the identical actual target object');
        is($json->encode($actual->declared_width_binding), $json->encode(binding($a, 'SELECTED')), 'AST target exposes the same complete source binding');
    }
    ok(!exists($m->signals->{SELECTED}), 'fixture independently proves module signals is not exhaustive for assigned targets');
    is(binding($a, 'BARE'), undef, 'named type acquires no parameter binding');
    is(binding($a, 'LITERAL'), undef, 'bare decimal acquires no invented relationship');
    my $static = binding($a, 'SCALAR');
    ok($static && $static->{observations}[0]{kind} eq 'static_symbol', 'actual competing constant remains static');
    my $alias = binding($a, 'ALIASED');
    ok($alias && $alias->{observations}[0]{parameter} eq 'ALIAS', 'alias retains immediate identity');
    is($json->encode($raw), $before, 'complete actual frontend caller retains JSON kinds');
};

subtest 'records remain staged until all parser validation succeeds' => sub {
    my $a = adapter(); my $validate = FSM::Adapter::FSMGenFull::Parser->can('validate_transition_targets');
    my $seen;
    {
        no warnings 'redefine';
        local *FSM::Adapter::FSMGenFull::Parser::validate_transition_targets = sub {
            my ($p, @rest) = @_;
            $seen = $p->{signal_manager}->get_signal('DATA')->declared_width_binding;
            return $validate->($p, @rest);
        };
        parse_text($a, $valid);
    }
    is($seen, undef, 'no publication before late parser validation');
    my $data = binding($a, 'DATA'); my $flag = binding($a, 'FLAG');
    ok($data && $flag, 'both actual source declarations publish on success');
    is($flag && $flag->{width}, 1, 'one-bit selected default retains its relationship');
    is($flag && $flag->{signal}, 'FLAG', 'one-bit origin is explicit');
    my $first = $a->{signal_manager}->get_signal('DATA');
    my $bad = '(?fsm:source_widths (+params (W 8)) (+size (DATA (param W))) (idle (-> MISSING)))';
    my $ok = eval {parse_text($a, $bad); 1};
    ok(!$ok, 'actual late source refusal remains'); like($@, qr/MISSING/, 'late refusal reason retained');
    is($first->declared_width_binding, undef, 'held actual object exposes no stale prior binding after refusal');
    for my $name ($a->{signal_manager}->get_all_signal_names) {
        is(binding($a, $name), undef, 'failed source leaves no partial binding on ' . $name);
    }
    parse_text($a, $valid);
    ok(binding($a, 'DATA'), 'successful source retry publishes a fresh record');
};

subtest 'partial size failure and later facade failure both clear every new snapshot' => sub {
    my $a = adapter(); parse_text($a, $valid);
    my $bad = '(?fsm:source_widths (+params (W 8)) (+size (DATA (param W)) (BAD (param MISSING))) (idle (= (DATA 0))))';
    my $ok = eval {parse_text($a, $bad); 1};
    ok(!$ok, 'unknown width after a valid entry refuses'); like($@, qr/unknown declared parameter 'MISSING'/, 'canonical first width reason');
    is(binding($a, 'DATA'), undef, 'no partial declaration snapshot remains');
    is($a->{signal_manager}->get_signal('DATA')->width, 8, 'legacy successful-prefix numeric state is conserved');
    my $inside;
    {
        no warnings 'redefine';
        local *FSM::Adapter::FSMGenFull::SignalAnalyzer::analyze_signal_roles = sub {
            $inside = binding($a, 'DATA'); die "late facade refusal\n";
        };
        $ok = eval {parse_text($a, $valid); 1};
    }
    ok(!$ok, 'failure after complete parser return refuses');
    ok($inside, 'the actual parser had produced a complete declaration snapshot');
    is(binding($a, 'DATA'), undef, 'facade failure also clears published parser records');
    parse_text($a, $valid); ok(binding($a, 'DATA'), 'facade retry is fresh');
};

subtest 'declaration replacements and direct failed size retries cannot retain old bindings' => sub {
    for my $replace (
        sub {$_[0]->resolve_pending_direct_root_params('source_widths', [{name => 'BAD', value_ast => ['UNKNOWN']}])},
        sub {$_[0]->resolve_pending_direct_root_symbols('source_widths', [{name => 'BAD', value_ast => ['UNKNOWN']}], [])},
        sub {$_[0]->resolve_pending_direct_root_types('source_widths', [{name => 'BAD', spec_ast => ['MISSING']}])},
        sub {$_[0]->parse_define_directive(['+define', []])},
        sub {$_[0]->parse_size_section(['+size', [['DATA', ['param', ['MISSING']]]]])},
    ) {
        my $a = adapter(); parse_text($a, $valid); ok(binding($a, 'DATA'), 'start with a real published snapshot');
        my $ok = eval {$replace->($a->{parser}); 1};
        ok(!$ok, 'nonempty replacement or invalid direct sizing refuses');
        is(binding($a, 'DATA'), undef, 'refusal leaves no stale source binding');
    }
    my $a = adapter(); parse_text($a, $valid); my $before = $json->encode(binding($a, 'DATA'));
    $a->{parser}->resolve_pending_direct_root_params('source_widths', []);
    $a->{parser}->resolve_pending_direct_root_symbols('source_widths', [], []);
    $a->{parser}->resolve_pending_direct_root_types('source_widths', []);
    $a->{parser}->parse_size_section(['+size']);
    is($json->encode(binding($a, 'DATA')), $before, 'legacy empty declaration/size no-ops retain the completed snapshot');
};

subtest 'multiple size sections preserve actual origin and detach held results' => sub {
    my $a = adapter(); my $text = '(?fsm:sections (+params (W 8)) (+size (A (param W)))'
        .' (+size (B (param W))) (idle (= (A 0)) (= (B 0))))';
    parse_text($a, $text); ok(binding($a, 'A') && binding($a, 'B'), 'independent valid sections both publish');
    return unless binding($a, 'A') && binding($a, 'B');
    my $held = binding($a, 'A'); $held->{scope}{owner} = 'WRONG';
    is(binding($a, 'A')->{scope}{owner}, 'sections', 'getter mutation cannot rewrite source ownership');
    my ($weak, $record);
    {
        my $local = adapter(); $weak = $local->{parser}; weaken($weak);
        parse_text($local, $valid); $record = binding($local, 'DATA');
    }
    ok(!defined($weak), 'held plain record from a params-only source does not retain its parser');
    is($record && $record->{scope}{owner}, 'source_widths', 'detached result remains complete after owner release');
};
done_testing();
