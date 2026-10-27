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
sub adapter { FSM::Adapter::FSMGenFull->new(debug => 0) }
sub parse_text { my ($a, $text) = @_; $a->parse_fsm(scalar Lispish::multi(\$text)) }
sub signal { $_[0]{signal_manager}->get_signal($_[1]) }
sub binding { signal(@_)->declared_width_binding }
sub simple_source {
    my ($op, $width) = @_;
    return "(?fsm:origin (+params (W $width)) (+size (data (param W))) (idle ($op (data 0))))";
}
sub expected_binding {
    my ($width) = @_;
    return {scope => {kind => 'direct_module', owner => 'origin'}, width => $width,
        signal => 'data', expression => ['param', ['W']],
        binding => {kind => 'reference', observation_index => 0,
            value_expression => {kind => 'literal', token => "$width"}},
        observations => [{lookup => 'parameter', kind => 'parameter', token => 'W',
            parameter => 'W', suffix => '', value_payload => {kind => 'scalar', payload => "$width"}}]};
}

subtest 'actual clean auxiliary copies carry the complete original lexical binding' => sub {
    for my $op ('<-=', '<=-', '<=+') {
        my $aux = $op eq '<-=' ? 'next_data' : 'data_r';
        for my $width (1, 8, 16) {
            my $a = adapter(); my $text = simple_source($op, $width);
            my $raw = Lispish::multi(\$text); my $before = $json->encode($raw);
            my $m = $a->parse_fsm($raw); my $record = binding($a, $aux);
            is($json->encode($record), $json->encode(expected_binding($width)), "$op width $width has the independently expected original binding");
            is($json->encode(binding($a, 'data')), $json->encode(expected_binding($width)), 'primary binding keeps its full old meaning');
            is(signal($a, $aux)->width, $width, 'legacy numeric width retained');
            is($json->encode($raw), $before, 'whole source caller JSON kinds retained');
            if (my $public = $m->signals->{$aux}) {
                is(refaddr($public), refaddr(signal($a, $aux)), 'module exposes the actual registry object when present');
            }
            $m->{name} = 'physical_rename';
            if ($record) {
                $record->{scope}{owner} = 'WRONG'; $record->{observations}[0]{parameter} = 'WRONG';
                is($json->encode(binding($a, $aux)), $json->encode(expected_binding($width)), 'physical rename and getter mutation cannot rebind the source');
            }
        }
    }
};

subtest 'actual general/static/type namespace branches retain their selected meaning' => sub {
    for my $width_form ('(+ (param W) 1)', 'W', '(param W)') {
        my $a = adapter();
        parse_text($a, "(?fsm:branches (+constants (W 4)) (+params (W 8)) (+size (data $width_form)) (idle (<-= (data 0))))");
        my $primary = binding($a, 'data'); my $aux = binding($a, 'next_data');
        ok($primary && $aux, 'actual expression/static/parameter capture propagates');
        is($json->encode($aux), $json->encode($primary), 'copy retains the actual complete producer record');
        my $kind = $width_form eq 'W' ? 'static_symbol' : 'parameter';
        is($aux && $aux->{observations}[0]{kind}, $kind, 'independent namespace expectation');
        is(signal($a, 'next_data')->width, $width_form eq 'W' ? 4 : $width_form eq '(param W)' ? 8 : 9, 'actual width agrees with selected branch');
    }
    my $a = adapter();
    parse_text($a, '(?fsm:typed (+types (type W (bits 4))) (+params (W 8)) (+size (data W)) (idle (<-= (data 0))))');
    is(binding($a, 'next_data'), undef, 'named type with competing parameter supplies no borrowed binding');
    is(signal($a, 'next_data')->width, 4, 'type branch numeric width retained');
};

subtest 'independent and opaque max-width contributions never become one binding' => sub {
    for my $slot ('(param X)', '8', 'word_t') {
        my $a = adapter();
        parse_text($a, "(?fsm:independent (+params (W 8) (X 8)) (+types (type word_t (bits 8))) (+size (data (param W)) (next_data $slot)) (idle (<-= (data 0))))");
        is(binding($a, 'next_data'), undef, 'equal-valued independent auxiliary requirement is withheld');
        is(scalar @{signal($a, 'next_data')->declared_width_requirements->{requirements}}, 2, 'both real constraints remain retained');
    }
    my $a = adapter();
    parse_text($a, '(?fsm:repeated (+params (W 16) (X 8)) (+size (data (param X)) (data (param W))) (idle (<-= (data 0))))');
    is(binding($a, 'data'), undef, 'repeated independent primary declaration cannot lend only its final expression');
    is(binding($a, 'next_data'), undef, 'copied independent primary constraints remain withheld too');
    is(signal($a, 'data')->width, 16, 'legacy repeated-declaration maximum remains unchanged');
    is(scalar @{signal($a, 'data')->declared_width_requirements->{requirements}}, 2, 'both primary requirements remain available for later shape rendering');
    $a = adapter(); parse_text($a, simple_source('<-=', 16)); parse_text($a, simple_source('<-=', 8));
    is(binding($a, 'data'), undef, 'larger inherited numeric floor cannot lend a smaller new declaration binding');
    is(binding($a, 'next_data'), undef, 'larger inherited floor remains unqualified through the copy');
    is(signal($a, 'data')->width, 16, 'legacy no-shrink behavior across source retries is preserved');
    my $floor = signal($a, 'data')->declared_width_requirements->{requirements};
    is($floor->[0]{width_capture}{width}, 8, 'current source declaration is freshly captured');
    is($floor->[1]{expression}, undef, 'unaccounted inherited numeric floor remains explicitly opaque');
    $a = adapter(); parse_text($a, '(?fsm:opaque (idle (<-= (data 0))))');
    is(binding($a, 'next_data'), undef, 'inference without an authored captured expression cannot invent a binding');
};

subtest 'copy chains and mutation versions preserve immutable actual events' => sub {
    my $a = adapter();
    parse_text($a, '(?fsm:origin (+params (W 8)) (+size (data (param W))) (idle (<-= (data 0)) (<-= (next_data 0))))');
    is($json->encode(binding($a, 'next_next_data')), $json->encode(expected_binding(8)), 'real chain retains the original data declaration rather than a physical intermediate name');
    my $validate = FSM::Adapter::FSMGenFull::Parser->can('validate_transition_targets');
    my $seen;
    $a = adapter();
    {
        no warnings 'redefine';
        local *FSM::Adapter::FSMGenFull::Parser::validate_transition_targets = sub {
            my ($p, @rest) = @_;
            $seen = binding($a, 'next_data');
            my $source = signal($a, 'data')->declared_width_source;
            $p->{signal_manager}->register_signal('data', _declared_width_source => undef);
            $p->{signal_manager}->register_signal('data', _declared_width_source => $source);
            return $validate->($p, @rest);
        };
        parse_text($a, simple_source('<-=', 8));
    }
    is($seen, undef, 'binding not exposed before final parser validation');
    is(binding($a, 'data'), undef, 'matching-state source replacement revokes old source event');
    is($json->encode(binding($a, 'next_data')), $json->encode(expected_binding(8)), 'earlier copy remains bound to its immutable event, without later live-source lookup');
};

subtest 'failures, direct unscoped replacement, no-ops and owner release remain safe' => sub {
    my $a = adapter(); parse_text($a, simple_source('<-=', 8));
    my $held = signal($a, 'next_data');
    ok(!eval {parse_text($a, '(?fsm:bad (+params (W 8)) (+size (data (param W))) (idle (<-= (data 0)) (-> MISSING)))'); 1}, 'real late parse failure refuses');
    is($held->declared_width_binding, undef, 'held old auxiliary exposes no stale binding');
    parse_text($a, simple_source('<-=', 8));
    my $inside;
    {
        no warnings 'redefine';
        local *FSM::Adapter::FSMGenFull::SignalAnalyzer::analyze_signal_roles = sub {
            $inside = binding($a, 'next_data'); die "facade refusal\n";
        };
        ok(!eval {parse_text($a, simple_source('<-=', 8)); 1}, 'later facade failure refuses');
    }
    ok($inside, 'complete auxiliary binding existed after parser success');
    is(binding($a, 'next_data'), undef, 'facade clears the actual auxiliary binding');
    parse_text($a, simple_source('<-=', 8));
    my $before = $json->encode(binding($a, 'next_data'));
    $a->{parser}->parse_size_section(['+size']);
    $a->{parser}->resolve_pending_direct_root_params('origin', []);
    is($json->encode(binding($a, 'next_data')), $before, 'legacy empty no-ops retain successful binding');
    $a->{parser}->parse_size_section(['+size', [['data', ['param', ['W']]]]]);
    is(binding($a, 'next_data'), undef, 'ordinary unscoped sizing does not infer fresh lexical ownership');
    my ($weak, $record);
    {
        my $local = adapter(); $weak = $local->{parser}; weaken($weak);
        parse_text($local, simple_source('<-=', 8)); $record = binding($local, 'next_data');
    }
    ok(!defined($weak), 'held params-only auxiliary record retains no parser');
    is($json->encode($record), $json->encode(expected_binding(8)), 'complete record outlives its owner');
};
done_testing();
