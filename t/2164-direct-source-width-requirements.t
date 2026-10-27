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
sub copy { $json->decode($json->encode($_[0])) }
sub adapter { FSM::Adapter::FSMGenFull->new(debug => 0) }
sub parse_text { my ($a, $text) = @_; $a->parse_fsm(scalar Lispish::multi(\$text)) }
sub requirements { $_[0]{signal_manager}->get_signal($_[1])->declared_width_requirements }
sub parameter_entry {
    my ($kind, $signal, $parameter, $width, $owner) = @_;
    return {kind => $kind, signal => $signal, expression => ['param', [$parameter]], width => $width,
        declared_type_name => undef, declared_type_spec => undef,
        width_capture => {scope => {kind => 'direct_module', owner => $owner}, width => $width,
            binding => {kind => 'reference', observation_index => 0,
                value_expression => {kind => 'literal', token => "$width"}},
            observations => [{lookup => 'parameter', kind => 'parameter', token => $parameter,
                parameter => $parameter, suffix => '', value_payload => {kind => 'scalar', payload => "$width"}}]}};
}
sub source_text {
    my ($op, $w, $x, $slot) = @_;
    my $aux = $op eq '<-=' ? 'next_data' : 'data_r';
    $slot = '(param X)' unless defined $slot;
    my $extra = length($slot) ? "($aux $slot)" : '';
    return "(?fsm:aux_origin (+params (W $w) (X $x)) (+size (data (param W)) $extra) (idle ($op (data 0))))";
}

subtest 'actual opposed defaults retain both complete independent requirements' => sub {
    for my $op ('<-=', '<=-', '<=+') {
        for my $pair ([8,8], [16,8], [8,16]) {
            my ($w, $x) = @$pair; my $aux = $op eq '<-=' ? 'next_data' : 'data_r';
            my $a = adapter(); my $text = source_text($op, $w, $x);
            my $raw = Lispish::multi(\$text); my $before = $json->encode($raw);
            my $m = $a->parse_fsm($raw);
            my $got = requirements($a, $aux);
            ok($got, "$op $w/$x retains private requirements");
            next unless $got;
            my $width = $w > $x ? $w : $x;
            is($json->encode($got), $json->encode({scope => {kind => 'direct_module', owner => 'aux_origin'},
                width => $width, requirements => [parameter_entry('declaration', $aux, 'X', $x, 'aux_origin'),
                    parameter_entry('generated', 'data', 'W', $w, 'aux_origin')]}), 'whole independent actual-source envelope');
            my $s = $a->{signal_manager}->get_signal($aux);
            is($s->width, $width, 'legacy maximum is unchanged');
            is($json->encode($s->declared_width_source), $json->encode({signal => 'data',
                expression => ['param', ['W']], resolved_width => $w}), 'legacy last-source getter remains exact');
            is($s->declared_width_binding, undef, 'independent auxiliary gains no single parent binding');
            is($json->encode($raw), $before, 'whole caller JSON kinds conserve');
            $m->{name} = 'physical_rename'; $got->{requirements}[0]{expression}[1][0] = 'W';
            is(requirements($a, $aux)->{requirements}[0]{expression}[1][0], 'X', 'getter mutation and physical naming cannot erase X');
        }
    }
};

subtest 'literal, type, inferred and clean one-bit branches are preserved' => sub {
    for my $op ('<-=', '<=-', '<=+') {
        my $aux = $op eq '<-=' ? 'next_data' : 'data_r';
        for my $slot ('(param X)', '8', '') {
            my $a = adapter(); parse_text($a, source_text($op, 1, 8, $slot));
            my $got = requirements($a, $aux);
            ok($got, "$op slot '$slot' has a retained requirement set"); next unless $got;
            my @entries;
            push @entries, $slot eq '8'
                ? {kind => 'declaration', signal => $aux, expression => '8', width => 8,
                    width_capture => undef, declared_type_name => undef, declared_type_spec => undef}
                : parameter_entry('declaration', $aux, 'X', 8, 'aux_origin') if length($slot);
            push @entries, parameter_entry('generated', 'data', 'W', 1, 'aux_origin');
            is($json->encode($got), $json->encode({scope => {kind => 'direct_module', owner => 'aux_origin'},
                width => length($slot) ? 8 : 1, requirements => \@entries}), 'complete slot distinction survives equal defaults');
        }
        my $a = adapter(); parse_text($a, "(?fsm:typed (+types (type word_t (bits 8))) (+size (data word_t)) (idle ($op (data 0))))");
        my $typed = requirements($a, $aux);
        ok($typed, 'named-type origin also retains requirements');
        if ($typed) {
            my $entry = $typed->{requirements}[0];
            is($entry->{expression}, 'word_t', 'authored type token retained');
            is($entry->{declared_type_name}, 'word_t', 'type namespace retained');
            is($json->encode($entry->{declared_type_spec}), $json->encode($a->{signal_manager}->get_signal('data')->declared_type_spec), 'actual type spec copied');
            is($entry->{width_capture}, undef, 'type does not fabricate a parameter capture');
        }
        $a = adapter(); my $m = parse_text($a, "(?fsm:inferred (+params (W 8)) (idle ($op (data 0))))");
        my $unknown = requirements($a, $aux);
        ok($unknown, 'unrecorded source contribution is retained explicitly');
        is($unknown && $unknown->{requirements}[0]{expression}, undef, 'unrecorded source has no guessed expression');
        $m->{name} = 'renamed';
        $a->{parser}->parse_size_section(['+size', [['data', ['param', ['W']]]]]);
        is(requirements($a, $aux), undef, 'ordinary late sizing clears metadata without inferring scope');
    }
};

subtest 'event snapshots do not follow later live source replacement or revive' => sub {
    my $a = adapter(); my $validate = FSM::Adapter::FSMGenFull::Parser->can('validate_transition_targets');
    my ($inside, $data, $aux);
    {
        no warnings 'redefine';
        local *FSM::Adapter::FSMGenFull::Parser::validate_transition_targets = sub {
            my ($p, @rest) = @_;
            $inside = requirements($a, 'next_data');
            $data = $p->{signal_manager}->get_signal('data'); $aux = $p->{signal_manager}->get_signal('next_data');
            my $original = $data->declared_width_source;
            $p->{signal_manager}->register_signal('data', _declared_width_source => {signal => 'data', expression => ['param', ['X']], resolved_width => 8});
            $p->{signal_manager}->register_signal('data', _declared_width_source => $original);
            return $validate->($p, @rest);
        };
        parse_text($a, source_text('<-=', 8, 8));
    }
    is($inside, undef, 'requirements are not published before complete validation');
    is($data->declared_width_requirements, undef, 'destructive matching-state replacement revokes the original source event');
    is($data->declared_width_binding, undef, 'old primary binding cannot revive either');
    my $record = $aux->declared_width_requirements;
    is($record && $record->{requirements}[1]{width_capture}{observations}[0]{parameter}, 'W', 'earlier auxiliary copy retains its immutable W event');
    is(refaddr($aux), refaddr($a->{signal_manager}->get_signal('next_data')), 'publication uses the identical actual registry object');

    $a = adapter();
    {
        no warnings 'redefine';
        local *FSM::Adapter::FSMGenFull::Parser::validate_transition_targets = sub {
            my ($p, @rest) = @_;
            my $target = $p->{signal_manager}->get_signal('next_data');
            my $original = $target->declared_width_source;
            $p->{signal_manager}->register_signal('next_data', _declared_width_source => undef);
            $p->{signal_manager}->register_signal('next_data', _declared_width_source => $original);
            return $validate->($p, @rest);
        };
        parse_text($a, source_text('<-=', 8, 8));
    }
    is(requirements($a, 'next_data'), undef, 'matching-state target replacement also revokes the copied event');
};

subtest 'size-copy ordering, independent auxiliary types and real copy chains retain origins' => sub {
    for my $op ('<-=', '<=-', '<=+') {
        my $aux = $op eq '<-=' ? 'next_data' : 'data_r';
        my $a = adapter();
        parse_text($a, "(?fsm:ordered (+params (W 16) (X 8)) (+size ($aux (param X))) (+size (data (param W))) (idle ($op (data 0))))");
        my $expected = {scope => {kind => 'direct_module', owner => 'ordered'}, width => 16,
            requirements => [parameter_entry('declaration', $aux, 'X', 8, 'ordered'),
                parameter_entry('generated', 'data', 'W', 16, 'ordered')]};
        is($json->encode(requirements($a, $aux)), $json->encode($expected), 'existing auxiliary updated during sizing retains the complete independent requirements');
        $a = adapter();
        parse_text($a, "(?fsm:typed_aux (+params (W 16)) (+types (type word_t (bits 8))) (+size ($aux word_t) (data (param W))) (idle ($op (data 0))))");
        my $r = requirements($a, $aux);
        ok($r && @{$r->{requirements}} == 2, 'independent auxiliary type survives generated copy');
        if ($r) {
            is($r->{requirements}[0]{expression}, 'word_t', 'actual auxiliary authored type retained');
            is($r->{requirements}[0]{declared_type_name}, 'word_t', 'auxiliary type namespace retained');
            is($r->{requirements}[1]{width_capture}{observations}[0]{parameter}, 'W', 'generated requirement remains independently selected');
            is($r->{width}, 16, 'numeric maximum still includes generated requirement');
        }
    }
    my $a = adapter();
    parse_text($a, '(?fsm:chain (+params (W 8) (X 16)) (+size (data (param W)) (next_data (param X))) (idle (<-= (data 0)) (<-= (next_data 0))))');
    my $r = requirements($a, 'next_next_data');
    is($json->encode($r), $json->encode({scope => {kind => 'direct_module', owner => 'chain'}, width => 16,
        requirements => [parameter_entry('generated', 'next_data', 'X', 16, 'chain'),
            parameter_entry('generated', 'data', 'W', 8, 'chain')]}), 'real chained copy freezes both original declaration identities');
};

subtest 'failure, replacement, no-op and retry boundaries clear every new record' => sub {
    my $valid = source_text('<-=', 8, 16);
    for my $fail (
        sub {parse_text($_[0], '(?fsm:bad (+params (W 8)) (+size (data (param W))) (idle (<-= (data 0)) (-> MISSING)))')},
        sub {parse_text($_[0], '(?fsm:bad (+params (W 8)) (+size (data (param W)) (bad (param MISSING))) (idle (<-= (data 0))))')},
        sub {$_[0]{parser}->resolve_pending_direct_root_params('aux_origin', [{name => 'BAD', value_ast => ['UNKNOWN']}])},
    ) {
        my $a = adapter(); parse_text($a, $valid); my $held = $a->{signal_manager}->get_signal('next_data');
        ok(!eval {$fail->($a); 1}, 'real source or environment failure refuses');
        for my $name ($a->{signal_manager}->get_all_signal_names) {
            is(requirements($a, $name), undef, 'whole actual registry clears: ' . $name);
        }
        is($held->declared_width_requirements, undef, 'held old actual object exposes no stale record');
        parse_text($a, $valid); ok(requirements($a, 'next_data'), 'successful retry captures fresh actual events');
    }
    my $a = adapter(); parse_text($a, $valid); my $inside;
    {
        no warnings 'redefine';
        local *FSM::Adapter::FSMGenFull::SignalAnalyzer::analyze_signal_roles = sub {
            $inside = requirements($a, 'next_data'); die "late facade refusal\n";
        };
        ok(!eval {parse_text($a, $valid); 1}, 'later facade refusal remains');
    }
    ok($inside, 'parser had published the complete requirement set');
    is(requirements($a, 'next_data'), undef, 'facade failure clears it');
    parse_text($a, $valid); my $before = $json->encode(requirements($a, 'next_data'));
    $a->{parser}->resolve_pending_direct_root_params('aux_origin', []);
    $a->{parser}->parse_size_section(['+size']);
    is($json->encode(requirements($a, 'next_data')), $before, 'legacy empty no-ops retain records');
};

subtest 'duplicate copy events and owner lifetimes stay bounded to plain records' => sub {
    my $a = adapter(); my $text = source_text('<-=', 8, 8);
    $text =~ s/\)\)\)\z/) (<-= (data 0))))/;
    parse_text($a, $text); my $got = requirements($a, 'next_data');
    is($got && scalar @{$got->{requirements}}, 2, 'only byte-identical complete requirements are deduplicated');
    my ($weak, $held);
    {
        my $local = adapter(); $weak = $local->{parser}; weaken($weak);
        parse_text($local, source_text('<-=', 8, 16)); $held = requirements($local, 'next_data');
    }
    ok(!defined($weak), 'held plain source requirements retain no parser');
    is($held && $held->{requirements}[0]{expression}[1][0], 'X', 'independent origin survives owner release');
};
done_testing();
