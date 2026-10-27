use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(weaken refaddr);
use FSM::Backend::VHDL::CompositionWidthEmitter;

my $class = 'FSM::Backend::VHDL::WidthExpressionEmitter';
ok(eval {require FSM::Backend::VHDL::WidthExpressionEmitter; 1},
    'shared portable scoped VHDL width kernel exists') or do {done_testing(); exit};
my $json = JSON::PP->new->canonical;
sub copy { $json->decode($json->encode($_[0])) }
sub fixture {
    my ($kind) = @_;
    my $scope = {kind => $kind, owner => 'original_source'};
    return {port => {name => 'data', width => 999, width_contract => {scope => copy($scope),
                expression => ['param', [['COPY']]], references => [{kind => 'parameter', token => 'COPY'}]}},
        environment => {scope => copy($scope), declaration_order => [qw(W COPY SAME)],
            parameters => {map {$_ => {value_payload => {kind => 'scalar', payload => '1'}}} qw(W COPY SAME)}},
        target_language => 'vhdl'};
}

subtest 'explicit direct/top scope preserves selected roots and one-bit vector rank' => sub {
    for my $kind ('direct_module', 'composition_top') {
        for my $language ('vhdl', 'VHDL') {
            my $input = fixture($kind); $input->{target_language} = $language;
            my $before = $json->encode($input);
            is($class->lower_range(%$input), '((COPY - 1) downto 0)', "$kind $language keeps alias and vector rank");
            is($json->encode($input), $before, 'complete caller remains unchanged');
            $input->{port}{width_contract}{expression} = ['param', 'SAME'];
            $input->{port}{width_contract}{references}[0]{token} = 'SAME';
            is($class->lower_range(%$input), '((SAME - 1) downto 0)', 'equal-default alternative keeps actual identity');
        }
    }
    my $input = fixture('direct_module');
    ok(!eval {FSM::Backend::VHDL::CompositionWidthEmitter->lower_range(%$input); 1}, 'composition wrapper rejects direct scope');
    like($@, qr/VHDL composition port 'data' width requires the matching captured top scope/, 'original composition diagnostic context retained');
};

subtest 'portable arithmetic retains fold order, static values and modulo spelling' => sub {
    my $input = fixture('direct_module'); my $c = $input->{port}{width_contract};
    $c->{expression} = ['+', ['%', ['param', 'COPY'], 3], 1];
    is($class->lower_range(%$input), '((((COPY mod 3) + 1) - 1) downto 0)', 'actual arithmetic tree keeps explicit parentheses and mod');
    $c->{expression} = ['/', ['*', ['param', 'W'], 'SCALE'], 2];
    $c->{references} = [{kind => 'parameter', token => 'W'},
        {kind => 'static_symbol', token => 'SCALE', value_payload => {kind => 'scalar', payload => '6'}}];
    is($class->lower_range(%$input), '((((W * 6) / 2) - 1) downto 0)', 'independent static selection is folded without losing mutable root');
    $c->{expression} = ['+', 'SCALE', 2]; $c->{references} = [$c->{references}[1]];
    is($class->lower_range(%$input), '((8 - 1) downto 0)', 'fully static tree folds through existing evaluator');
    $c->{expression} = '2147483647'; $c->{references} = [];
    is($class->lower_range(%$input), '((2147483647 - 1) downto 0)', 'portable natural maximum retains exact decimal text');
};

subtest 'bad scopes, names and every intermediate arithmetic boundary refuse' => sub {
    for my $change (
        sub {$_[0]{environment}{scope}{kind} = $_[0]{port}{width_contract}{scope}{kind} = 'unknown'},
        sub {$_[0]{port}{width_contract}{scope}{owner} = 'physical_rename'},
        sub {$_[0]{port}{width_contract}{references} = []},
        sub {$_[0]{port}{width_contract}{references}[0]{token} = 'W'},
        sub {push @{$_[0]{port}{width_contract}{references}}, {kind => 'parameter', token => 'COPY'}},
        sub {$_[0]{port}{declared_type_name} = 'word_t'},
        sub {$_[0]{port}{width_contract}{expression} = ['/', 1, 0]; $_[0]{port}{width_contract}{references} = []},
        sub {$_[0]{port}{width_contract}{expression} = ['%', 1, 0]; $_[0]{port}{width_contract}{references} = []},
        sub {$_[0]{port}{width_contract}{expression} = ['-', 1, 1]; $_[0]{port}{width_contract}{references} = []},
        sub {$_[0]{port}{width_contract}{expression} = ['-', 1, 2]; $_[0]{port}{width_contract}{references} = []},
        sub {$_[0]{port}{width_contract}{expression} = ['*', '2147483647', 2, 0]; $_[0]{port}{width_contract}{references} = []},
        sub {$_[0]{port}{width_contract}{expression} = '2147483648'; $_[0]{port}{width_contract}{references} = []},
        sub {$_[0]{port}{width_contract}{expression} = ['&', 1, 1]},
        sub {$_[0]{target_language} = 'systemverilog'},
        sub {$_[0]{environment}{parameters}{OUT} = delete $_[0]{environment}{parameters}{COPY};
            $_[0]{port}{width_contract}{expression} = ['param', 'OUT']; $_[0]{port}{width_contract}{references}[0]{token} = 'OUT'},
    ) {
        my $input = fixture('direct_module'); $change->($input); my $before = $json->encode($input);
        ok(!eval {$class->lower_range(%$input); 1}, 'invalid prepared width refuses');
        like($@, qr/(?:width|VHDL)/i, 'refusal identifies target/width boundary');
        is($json->encode($input), $before, 'failed preparation preserves complete caller data');
    }
    my $input = fixture('direct_module'); my $tree = []; push @$tree, $tree;
    $input->{port}{width_contract}{expression} = $tree;
    ok(!eval {$class->lower_range(%$input); 1}, 'actual recursive width expression refuses');
    like($@, qr/cyclic.*width expression/, 'cycle keeps contextual diagnostic');
    is(refaddr($tree->[0]), refaddr($tree), 'caller cycle topology is not rewritten');
    @$tree = ();
};

subtest 'plain successful/refused results keep no caller owner' => sub {
    for my $fail (0, 1) {
        my ($weak_env, $weak_port, $held);
        {
            my $input = fixture('direct_module');
            $input->{port}{width_contract}{references} = [] if $fail;
            $weak_env = $input->{environment}; weaken($weak_env);
            $weak_port = $input->{port}; weaken($weak_port);
            $held = eval {$class->lower_range(%$input)};
        }
        ok(!defined($weak_env) && !defined($weak_port), 'success/refusal releases source graph');
        is($held, '((COPY - 1) downto 0)', 'held range stays plain text') unless $fail;
    }
};
done_testing();
