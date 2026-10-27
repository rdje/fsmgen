use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(weaken);
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::Adapter::FSMGenFull::Parser;
use FSM::CoreAST;

ok(FSM::Adapter::FSMGenFull::Parser->can('parse_size_section_in_scope'),
    'private explicitly scoped sizing entrypoint exists') or do {done_testing(); exit};
my $json = JSON::PP->new->canonical;
my $scope = {kind => 'direct_module', owner => 'late_case'};
sub copy { $json->decode($json->encode($_[0])) }
sub adapter { FSM::Adapter::FSMGenFull->new(debug => 0) }
sub parse_text { my ($a, $text) = @_; $a->parse_fsm(scalar Lispish::multi(\$text)) }
sub signal { $_[0]{signal_manager}->get_signal($_[1]) }
sub snapshot {
    my ($a) = @_; my %out;
    for my $name ($a->{signal_manager}->get_all_signal_names) {
        my $s = signal($a, $name);
        $out{$name} = {width => $s->width, source => $s->declared_width_source,
            type_name => $s->declared_type_name, type_spec => $s->declared_type_spec,
            requirements => $s->declared_width_requirements, binding => $s->declared_width_binding};
    }
    return $json->encode(\%out);
}
sub late_source {
    my ($op, $w, $slot, $normal, $parent) = @_;
    my $aux = $op eq '<-=' ? 'next_data' : 'data_r';
    my $extra = length($slot) ? "(+size ($aux $slot))" : '';
    $parent //= '(param W)';
    my $size = $normal ? "(+size (data $parent))" : '';
    return "(?fsm:late_case (+params (W $w) (X 8)) (+types (type word_t (bits 8))) $extra $size (idle ($op (data 0))))";
}
sub size_data { ['+size', [['data', ['param', ['W']]]]] }

subtest 'actual late sizing matches normal ordering without losing independent declarations' => sub {
    for my $op ('<-=', '<=-', '<=+') {
        for my $w (1, 8) {
            for my $slot ('', '(param X)', '8', 'word_t') {
                my $a = adapter(); my $text = late_source($op, $w, $slot, 0);
                my $raw = Lispish::multi(\$text); my $caller = $json->encode($raw);
                my $module = $a->parse_fsm($raw); $module->{name} = 'physical_rename';
                my $input = size_data(); my $before = $json->encode([$input, $scope]);
                $a->{parser}->parse_size_section_in_scope($input, copy($scope));
                my $normal = adapter(); parse_text($normal, late_source($op, $w, $slot, 1));
                is(snapshot($a), snapshot($normal), "$op W$w slot '$slot' complete actual late/normal products match");
                is($json->encode([$input, $scope]), $before, 'scope/size caller JSON kinds unchanged');
                is($json->encode($raw), $caller, 'original source caller remains unchanged');
            }
        }
    }
    for my $parent ('8', 'word_t') {
        my $a = adapter(); parse_text($a, late_source('<-=', 8, '', 0));
        $a->{parser}->parse_size_section_in_scope(['+size', [['data', $parent]]], copy($scope));
        my $normal = adapter(); parse_text($normal, late_source('<-=', 8, '', 1, $parent));
        if ($parent eq '8') {
            is(snapshot($a), snapshot($normal), 'literal late branch retains the normal complete contract');
        } else {
            my $legacy = adapter(); parse_text($legacy, late_source('<-=', 8, '', 0));
            $legacy->{parser}->parse_size_section(['+size', [['data', $parent]]]);
            for my $name ('data', 'next_data') {
                my $actual = signal($a, $name); my $old = signal($legacy, $name);
                is($json->encode([$actual->width, $actual->declared_width_source, $actual->declared_type_name, $actual->declared_type_spec]),
                    $json->encode([$old->width, $old->declared_width_source, $old->declared_type_name, $old->declared_type_spec]),
                    'named-type numeric/source/type getters preserve the actual legacy late contract');
                is($json->encode($actual->declared_width_requirements), $json->encode(signal($normal, $name)->declared_width_requirements),
                    'private type requirements still retain the normal declared origin');
            }
            is(signal($normal, 'next_data')->declared_type_name, undef, 'independent control pins the owned legacy early/late type asymmetry');
        }
    }
};

subtest 'colliding other-origin and unattested older requirements stay conservative' => sub {
    for my $x (8, 16) {
        my $a = adapter(); parse_text($a, "(?fsm:late_case (+params (W 8) (X $x) (Y 8)) (+size (data (param W)) (data_r (param X))) (idle (<-= (data 0)) (<-= (data_r 0)) (<=- (next_data 0))))");
        $a->{parser}->parse_size_section_in_scope(['+size', [['next_data', ['param', ['Y']]]]], copy($scope));
        my $r = signal($a, 'next_data_r')->declared_width_requirements;
        is_deeply([map {[$_->{signal}, $_->{expression}, $_->{copy_origin}]} @{$r->{requirements}}],
            [['data_r', ['param', ['X']], 'data_r'], ['data', ['param', ['W']], 'next_data'],
                ['next_data', ['param', ['Y']], 'next_data']], 'all authored and other-copy-path requirements survive scoped replay');
        is(signal($a, 'next_data_r')->width, $x, 'legacy collision maximum is unchanged');
        is(signal($a, 'next_data_r')->declared_width_binding, undef, 'combined collision remains withheld');
    }
    my $a = adapter(); parse_text($a, '(?fsm:late_case (+params (W 8)) (idle (<-= (data 0))))');
    my $s = signal($a, 'next_data'); my $older = $s->declared_width_requirements;
    delete $older->{requirements}[0]{copy_origin}; $s->set_declared_width_requirements($older);
    $a->{parser}->parse_size_section_in_scope(size_data(), copy($scope));
    my $r = $s->declared_width_requirements;
    is(scalar @{$r->{requirements}}, 2, 'older unattested opaque contribution cannot authorize replacement');
    is($s->declared_width_binding, undef, 'unknown old origin stays withheld');
    $a = adapter(); parse_text($a, '(?fsm:late_case (+params (W 8)) (+size (data 16)) (idle (<-= (data 0))))');
    $a->{parser}->parse_size_section_in_scope(size_data(), copy($scope));
    is(signal($a, 'data')->width, 16, 'larger prior authored width does not shrink');
    is(signal($a, 'next_data')->declared_width_binding, undef, 'prior authored literal requirement cannot disappear behind a selected parameter');
};

subtest 'scope preflight refuses before mutation and ordinary unscoped sizing stays unchanged' => sub {
    my $a = adapter(); parse_text($a, late_source('<-=', 8, '', 1));
    for my $bad ({kind => 'composition_top', owner => 'late_case'}, {kind => 'direct_module'},
        {%$scope, extra => 1}, {%$scope, owner => 'physical_rename'}) {
        my $before = snapshot($a); my $caller = $json->encode($bad);
        ok(!eval {$a->{parser}->parse_size_section_in_scope(size_data(), $bad); 1}, 'invalid/incompatible explicit scope refuses');
        like($@, qr/(?:Declared width capture|Scoped late sizing)/, 'scope boundary names refusal');
        is(snapshot($a), $before, 'preflight refusal leaves prior completed records intact');
        is($json->encode($bad), $caller, 'invalid scope caller remains unchanged');
    }
    my $before = snapshot($a);
    $a->{parser}->parse_size_section(['+size']);
    is(snapshot($a), $before, 'ordinary empty no-op retains old records');
    $a->{parser}->parse_size_section(size_data());
    is(signal($a, 'next_data')->declared_width_binding, undef, 'ordinary nonempty late sizing invents no lexical ownership');
    ok(!defined $a->{parser}{_declared_width_capture_context}, 'ordinary sizing creates no dangling capture context');
    $a->{parser}->parse_size_section(size_data());
    is(signal($a, 'next_data')->declared_width_binding, undef, 'repeated ordinary sizing remains unscoped');
};

subtest 'scalar/list/void contexts and valid scoped no-ops preserve their exact contracts' => sub {
    for my $mode ('scalar', 'list', 'void') {
        my $a = adapter(); parse_text($a, late_source('<-=', 8, '', 1));
        my $original = FSM::Adapter::FSMGenFull::Parser->can('_parse_size_section');
        for my $input (['+size'], ['+size', []], size_data()) {
            my $before = snapshot($a); my @seen; my $result;
            {
                no warnings 'redefine';
                local *FSM::Adapter::FSMGenFull::Parser::_parse_size_section = sub {
                    my $context = wantarray;
                    push @seen, !defined($context) ? 'void' : $context ? 'list' : 'scalar'; goto &$original;
                };
                if ($mode eq 'scalar') {$result = scalar $a->{parser}->parse_size_section_in_scope($input, copy($scope))}
                elsif ($mode eq 'list') {my @r = $a->{parser}->parse_size_section_in_scope($input, copy($scope)); $result = \@r}
                else {$a->{parser}->parse_size_section_in_scope($input, copy($scope))}
            }
            is_deeply(\@seen, [$mode], 'actual inner sizing sees the original caller context');
            my $value = !defined($input->[1]) ? undef : '';
            is($json->encode($result), $json->encode($mode eq 'list' ? [defined($input->[1]) ? '' : ()] : $mode eq 'void' ? undef : $value), 'exact legacy return value retained');
            is(snapshot($a), $before, 'no-op or identical requirement preserves complete records');
        }
    }
};

subtest 'accepted transactions stage atomically and failed prefixes clear all metadata' => sub {
    my $text = '(?fsm:late_case (+params (W 8)) (+size (KEEP (param W))) (idle (= (KEEP 0)) (<-= (data 0))))';
    my $a = adapter(); parse_text($a, $text);
    my $original = FSM::Adapter::FSMGenFull::Parser->can('_parse_size_section'); my $inside;
    {
        no warnings 'redefine';
        local *FSM::Adapter::FSMGenFull::Parser::_parse_size_section = sub {
            $inside = signal($a, 'KEEP')->declared_width_requirements;
            goto &$original;
        };
        $a->{parser}->parse_size_section_in_scope(size_data(), copy($scope));
    }
    is($inside, undef, 'previous metadata is withheld during the accepted sizing transaction');
    ok(signal($a, 'KEEP')->declared_width_binding && signal($a, 'next_data')->declared_width_binding, 'unaffected and new complete records publish together');
    my $bad = ['+size', [['data', ['param', ['W']]], ['BAD', ['param', ['MISSING']]]]];
    ok(!eval {$a->{parser}->parse_size_section_in_scope($bad, copy($scope)); 1}, 'partial sizing failure refuses');
    like($@, qr/unknown declared parameter 'MISSING'/, 'original canonical refusal retained');
    for my $name ($a->{signal_manager}->get_all_signal_names) {
        is(signal($a, $name)->declared_width_requirements, undef, 'failed transaction clears actual requirements: ' . $name);
        is(signal($a, $name)->declared_width_binding, undef, 'failed transaction clears actual binding: ' . $name);
    }
    is(signal($a, 'data')->width, 8, 'legacy successful-prefix numeric state retained');
    $a->{parser}->parse_size_section_in_scope(size_data(), copy($scope));
    ok(signal($a, 'next_data')->declared_width_binding, 'successful scoped retry captures fresh records');
    my $setter = FSM::CoreAST::Signal->can('set_declared_width_requirements');
    {
        no warnings 'redefine';
        local *FSM::CoreAST::Signal::set_declared_width_requirements = sub {
            die "publication refusal\n" if $_[0]->name eq 'next_data'; return $setter->(@_);
        };
        ok(!eval {$a->{parser}->parse_size_section_in_scope(size_data(), copy($scope)); 1}, 'late publication failure refuses');
    }
    is(signal($a, 'data')->declared_width_requirements, undef, 'publication failure clears any earlier installed record');
    is(signal($a, 'next_data')->declared_width_binding, undef, 'publication failure leaves no stale auxiliary binding');
};

subtest 'nested source transactions defer publication and plain held results retain no parser' => sub {
    my $validate = FSM::Adapter::FSMGenFull::Parser->can('validate_transition_targets');
    my $a = adapter(); my $inside;
    {
        no warnings 'redefine';
        local *FSM::Adapter::FSMGenFull::Parser::validate_transition_targets = sub {
            my ($p, @rest) = @_;
            $p->parse_size_section_in_scope(size_data(), copy($scope));
            $inside = signal($a, 'next_data')->declared_width_binding;
            return $validate->($p, @rest);
        };
        parse_text($a, '(?fsm:late_case (+params (W 8)) (idle (<-= (data 0))))');
    }
    is($inside, undef, 'nested scoped operation cannot publish ahead of outer source validation');
    ok(signal($a, 'next_data')->declared_width_binding, 'outer success publishes complete nested result');
    my ($weak, $held);
    {
        my $local = adapter(); $weak = $local->{parser}; weaken($weak);
        parse_text($local, '(?fsm:late_case (+params (W 8)) (idle (<-= (data 0))))');
        my $input_scope = copy($scope);
        $local->{parser}->parse_size_section_in_scope(size_data(), $input_scope);
        $input_scope->{owner} = 'WRONG';
        $held = signal($local, 'next_data')->declared_width_requirements;
    }
    ok(!defined($weak), 'held params-only scoped result retains no parser');
    is($held->{scope}{owner}, 'late_case', 'scope input and held record remain detached');
};
done_testing();
