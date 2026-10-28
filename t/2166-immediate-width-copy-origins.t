use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(refaddr);
use Lispish;
use FSM::CoreAST;
use FSM::Adapter::FSMGenFull;

my $json = JSON::PP->new->canonical;
sub copy { $json->decode($json->encode($_[0])) }
sub parse_text {
    my ($text) = @_;
    my $a = FSM::Adapter::FSMGenFull->new(debug => 0);
    $a->parse_fsm(scalar Lispish::multi(\$text)); return $a;
}
sub signal { $_[0]{signal_manager}->get_signal($_[1]) }
sub record { signal(@_)->declared_width_requirements }
sub generated {
    my ($original, $parameter, $width, $immediate) = @_;
    return {kind => 'generated', signal => $original, expression => ['param', [$parameter]], width => $width,
        copy_origin => $immediate, declared_type_name => undef, declared_type_spec => undef,
        width_capture => {scope => {kind => 'direct_module', owner => 'origins'}, width => $width,
            binding => {kind => 'reference', observation_index => 0, value_expression => {kind => 'literal', token => "$width"}},
            observations => [{lookup => 'parameter', kind => 'parameter', token => $parameter,
                parameter => $parameter, suffix => '', value_payload => {kind => 'scalar', payload => "$width"}}]}};
}

subtest 'overlapping actual next/q events retain distinct immediate origins' => sub {
    for my $x (8, 16) {
        my $a = parse_text("(?fsm:origins (+params (W 8) (X $x)) (+size (data (param W)) (data_r (param X))) (idle (<-= (data 0)) (<-= (data_r 0)) (<=- (next_data 0))))");
        is($json->encode(record($a, 'next_data_r')), $json->encode({scope => {kind => 'direct_module', owner => 'origins'},
            width => $x, requirements => [generated('data_r', 'X', $x, 'data_r'),
                generated('data', 'W', 8, 'next_data')]}), 'complete independent origin envelope survives equal/opposed defaults');
        is(signal($a, 'next_data_r')->declared_width_binding, undef, 'independent copy paths do not lend one binding');
        ok(!exists record($a, 'data')->{requirements}[0]{copy_origin}, 'authored declaration does not invent a copy event');
    }
    my $a = parse_text('(?fsm:origins (+params (W 8)) (+size (data (param W))) (idle (<-= (data 0)) (<=- (data 0)) (<-= (data_r 0)) (<=- (next_data 0))))');
    is($json->encode(record($a, 'next_data_r')->{requirements}),
        $json->encode([generated('data', 'W', 8, 'data_r'), generated('data', 'W', 8, 'next_data')]),
        'even identical original captures retain distinct attested immediate edges');
    is_deeply(signal($a, 'next_data_r')->declared_width_binding,
        {%{record($a, 'next_data_r')->{requirements}[0]{width_capture}}, signal => 'data', expression => ['param', ['W']]},
        'equivalent original captures share one binding while both immediate edges remain retained');
};

subtest 'chains retain original declarations and replace only the immediate edge field' => sub {
    my $a = parse_text('(?fsm:origins (+params (W 1)) (+size (data (param W))) (idle (<-= (data 0)) (<-= (next_data 0))))');
    is($json->encode(record($a, 'next_data')->{requirements}), $json->encode([generated('data', 'W', 1, 'data')]), 'first actual one-bit edge');
    is($json->encode(record($a, 'next_next_data')->{requirements}), $json->encode([generated('data', 'W', 1, 'next_data')]), 'next actual edge retains original declaration and observations');
    is(signal($a, 'next_next_data')->declared_width_binding->{signal}, 'data', 'coherent binding schema/original identity unchanged');
    my $held = record($a, 'next_next_data'); $held->{requirements}[0]{copy_origin} = 'WRONG';
    is(record($a, 'next_next_data')->{requirements}[0]{copy_origin}, 'next_data', 'getter mutation cannot change attested copy origin');
};

subtest 'literal/type/inferred copies and unattested numeric floors stay distinct' => sub {
    for my $slot ('8', 'word_t', '') {
        my $size = length($slot) ? "(+size (data $slot))" : '';
        my $a = parse_text("(?fsm:origins (+types (type word_t (bits 8))) $size (idle (<-= (data 0))))");
        my $entry = record($a, 'next_data')->{requirements}[0];
        is($entry->{copy_origin}, 'data', 'actual copy edge is recorded without fabricating a parameter');
        is($entry->{width_capture}, undef, 'non-capture branch remains non-capture');
        is($entry->{expression}, length($slot) ? $slot : undef, 'authored versus opaque origin preserved');
    }
    my $a = parse_text('(?fsm:origins (+params (W 16)) (+size (data (param W))) (idle (<-= (data 0))))');
    my $text = '(?fsm:origins (+params (W 8)) (+size (data (param W))) (idle (<-= (data 0))))';
    $a->parse_fsm(scalar Lispish::multi(\$text));
    my $floor = record($a, 'data')->{requirements}[1];
    is($floor->{expression}, undef, 'larger inherited floor remains opaque');
    ok(!exists $floor->{copy_origin}, 'numeric floor has no invented actual copy event');
};

subtest 'optional holder field preserves older records and rejects invalid roles or shapes' => sub {
    my $a = parse_text('(?fsm:origins (+params (W 8)) (+size (data (param W))) (idle (<-= (data 0))))');
    my $r = record($a, 'next_data'); my $source = signal($a, 'next_data')->declared_width_source;
    my $s = FSM::CoreAST::Signal->new(name => 'physical_copy', width => 8, _declared_width_source => $source);
    my $input = copy($r); $s->set_declared_width_requirements($input);
    $input->{requirements}[0]{copy_origin} = 'WRONG';
    is($s->declared_width_requirements->{requirements}[0]{copy_origin}, 'data', 'setter detaches origin input');
    my $older = copy($r); delete $older->{requirements}[0]{copy_origin};
    $s->set_declared_width_requirements($older);
    is($json->encode($s->declared_width_requirements), $json->encode($older), 'older unattested private records remain exactly accepted');
    for my $change ({copy_origin => {}}, {copy_origin => ''}, {kind => 'declaration', copy_origin => 'data'}) {
        my $bad = copy($r); @{$bad->{requirements}[0]}{keys %$change} = values %$change;
        $s->set_declared_width_requirements($r);
        ok(!eval {$s->set_declared_width_requirements($bad); 1}, 'malformed origin/role refuses');
        like($@, qr/Declared width requirements/, 'private boundary names refusal');
        is($s->declared_width_requirements, undef, 'failed replacement clears old metadata');
        is($s->width, 8, 'old numeric width unchanged');
        is($json->encode($s->declared_width_source), $json->encode($source), 'old source unchanged');
    }
    my $unknown = copy($r); $unknown->{requirements}[0]{copy_origin} = undef;
    $s->set_declared_width_requirements($unknown);
    is($json->encode($s->declared_width_requirements), $json->encode($unknown), 'explicit null attestation remains conservative');
};

subtest 'recording requires actual registry identity rather than a matching name' => sub {
    my $a = parse_text('(?fsm:origins (+params (W 8)) (+size (data (param W))) (idle (<-= (data 0))))');
    my $p = $a->{parser}; my $actual = signal($a, 'data'); my $r = $actual->declared_width_requirements;
    local $p->{_declared_width_capture_context} = {scope => $r->{scope}, requirements => {
        refaddr($actual) => $p->_width_event($actual, record => $r)}};
    $actual->{name} = 'physical_rename';
    my $got = $p->_generated_width_requirements($actual, 'data', 8);
    is($json->encode($got), $json->encode([generated('data', 'W', 8, 'data')]), 'actual registry key attests the edge despite physical Signal rename');
    my $impostor = FSM::CoreAST::Signal->new(name => 'data', width => 8);
    $got = $p->_generated_width_requirements($impostor, 'data', 8);
    ok(!exists $got->[0]{copy_origin}, 'same-name different object cannot claim the registry edge');
    is($got->[0]{width_capture}, undef, 'same-name object also gains no captured relationship');
};
done_testing();
