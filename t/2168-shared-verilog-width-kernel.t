use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(weaken);
use FSM::Backend::VerilogFamily::CompositionWidthEmitter;

my $class = 'FSM::Backend::VerilogFamily::WidthExpressionEmitter';
ok(eval {require FSM::Backend::VerilogFamily::WidthExpressionEmitter; 1},
    'shared scoped Verilog-family width kernel exists') or do {done_testing(); exit};
my $json = JSON::PP->new->canonical;
sub copy { $json->decode($json->encode($_[0])) }
sub fixture {
    my ($kind) = @_;
    my $scope = {kind => $kind, owner => 'original_source'};
    return {port => {name => 'data', width => 999,
            width_contract => {scope => copy($scope), expression => ['param', [['ALIAS']]],
                references => [{kind => 'parameter', token => 'ALIAS'}]}},
        environment => {scope => copy($scope), declaration_order => [qw(W ALIAS SAME)],
            parameters => {map {$_ => {value_payload => {kind => 'scalar', payload => '1'}}} qw(W ALIAS SAME)}},
        target_language => 'systemverilog'};
}

subtest 'both explicit source scopes retain prepared names and one-bit vector rank' => sub {
    for my $kind ('direct_module', 'composition_top') {
        for my $language (qw(systemverilog sv verilog v)) {
            my $input = fixture($kind); $input->{target_language} = $language;
            my $before = $json->encode($input);
            is($class->lower_range(%$input), '[(ALIAS - 1):0] ', "$kind $language retains selected alias and vector rank");
            is($json->encode($input), $before, 'complete caller data remains unchanged');
            $input->{port}{width_contract}{expression} = ['param', 'SAME'];
            $input->{port}{width_contract}{references}[0]{token} = 'SAME';
            is($class->lower_range(%$input), '[(SAME - 1):0] ', 'equal-default alternative keeps its distinct selected name');
        }
    }
    my $input = fixture('direct_module');
    my $ok = eval {FSM::Backend::VerilogFamily::CompositionWidthEmitter->lower_range(%$input); 1};
    ok(!$ok, 'composition wrapper never borrows direct scope');
    like($@, qr/Composition port 'data' width requires the matching captured top scope/, 'composition boundary stays contextual');
};

subtest 'actual lookup order, canonical arithmetic and static folding keep old semantics' => sub {
    my $input = fixture('direct_module'); my $c = $input->{port}{width_contract};
    $c->{expression} = ['/', ['*', ['param', 'W'], 'SCALE'], 2];
    $c->{references} = [{kind => 'parameter', token => 'W'},
        {kind => 'static_symbol', token => 'SCALE', value_payload => {kind => 'scalar', payload => '6'}}];
    my $before = $json->encode($input);
    is($class->lower_range(%$input), '[(((W * 6) / 2) - 1):0] ', 'symbolic left fold preserves independent static selection');
    is($json->encode($input), $before, 'nested caller kinds remain unchanged');
    $c->{expression} = ['+', 'SCALE', 2]; $c->{references} = [$c->{references}[1]];
    is($class->lower_range(%$input), '[(8 - 1):0] ', 'all-static subtree folds through the canonical width evaluator');
    $c->{expression} = ['+', ['param', 'W'], ['param', 'W']];
    $c->{references} = [map {{kind => 'parameter', token => 'W'}} 1..2];
    is($class->lower_range(%$input), '[((W + W) - 1):0] ', 'repeated actual lookups remain distinct');
};

subtest 'hostile scope and lookup contracts refuse without numeric fallback' => sub {
    for my $change (
        sub {$_[0]{environment}{scope}{kind} = $_[0]{port}{width_contract}{scope}{kind} = 'unknown'},
        sub {$_[0]{port}{width_contract}{scope}{owner} = 'renamed_physical'},
        sub {$_[0]{port}{width_contract}{references} = []},
        sub {$_[0]{port}{width_contract}{references}[0]{token} = 'W'},
        sub {push @{$_[0]{port}{width_contract}{references}}, {kind => 'parameter', token => 'ALIAS'}},
        sub {$_[0]{port}{declared_type_name} = 'word_t'},
        sub {$_[0]{port}{width_contract}{expression} = ['/', 1, 0]; $_[0]{port}{width_contract}{references} = []},
        sub {$_[0]{port}{width_contract}{expression} = ['-', 1, 1]; $_[0]{port}{width_contract}{references} = []},
        sub {$_[0]{port}{width_contract}{expression} = ['<<', 1, 1]},
        sub {$_[0]{target_language} = 'vhdl'},
    ) {
        my $input = fixture('direct_module'); $change->($input); my $before = $json->encode($input);
        ok(!eval {$class->lower_range(%$input); 1}, 'invalid prepared input refuses');
        like($@, qr/(?:width|Verilog-family)/i, 'refusal identifies the width boundary');
        is($json->encode($input), $before, 'refusal preserves all caller records');
    }
    my $input = fixture('direct_module');
    $input->{port}{width_contract}{expression} = 4; $input->{port}{width_contract}{references} = [];
    $input->{target_language} = 'vhdl';
    ok(!eval {$class->lower_range(%$input); 1}, 'static-only width cannot emit a foreign target format');
    like($@, qr/Verilog-family target/, 'static target boundary is explicit');
};

subtest 'plain result retains no environment or source record owner' => sub {
    for my $fail (0, 1) {
        my ($weak_env, $weak_port, $held);
        {
            my $input = fixture('direct_module');
            $input->{port}{width_contract}{references} = [] if $fail;
            $weak_env = $input->{environment}; weaken($weak_env);
            $weak_port = $input->{port}; weaken($weak_port);
            $held = eval {$class->lower_range(%$input)};
        }
        ok(!defined($weak_env) && !defined($weak_port), 'success/refusal leaves no retained caller graph');
        is($held, '[(ALIAS - 1):0] ', 'held successful range remains plain text') unless $fail;
    }
};
done_testing();
