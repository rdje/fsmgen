use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;

my $renderer = 'FSM::Backend::VHDL::ParameterBindingEmitter';
my $loaded = eval {require FSM::Backend::VHDL::ParameterBindingEmitter; 1};
ok($loaded, 'shared canonical VHDL binding renderer exists') or do {diag($@); done_testing(); exit};
my $json = JSON::PP->new->canonical;
sub copy {return $json->decode($json->encode($_[0]))}
my $text = '(?fsm:natural_bindings (+constants (FIXED 16)) (+params (W 16) (COPY W) (STATIC FIXED) (SUM (+ W 3)) (REMAINDER (mod W 3)) (REPEATED (- W W))))';
my $raw = Lispish::multi(\$text);
my $module = FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm($raw);
my $environment = {scope => {kind => 'direct_module', owner => 'natural_bindings'},
    parameters => $module->parameters, declaration_order => [sort keys %{$module->parameters}]};
my $bindings = $module->parameter_default_bindings;
my $before = $json->encode([$raw, $environment, $bindings]);
my %capture;
sub lower {return $renderer->lower_expression(binding => $_[0], environment => $_[1] // $environment,
    target_language => $_[2] // 'vhdl')}

subtest 'actual direct Core bindings retain natural names and arithmetic with exact JSON kinds' => sub {
    my %expected = (W => [16, []], COPY => ['W', ['W']], STATIC => [16, []],
        SUM => ['(W + 3)', ['W']], REMAINDER => ['(W mod 3)', ['W']], REPEATED => ['(W - W)', ['W','W']]);
    for my $name (sort keys %expected) {
        my $actual = lower($bindings->{$name});
        is($json->encode($actual), $json->encode({text => $expected{$name}[0], parameter_references => $expected{$name}[1]}),
            "$name preserves immediate roots, operator order and scalar kinds");
        $capture{direct}{$name} = $actual;
    }
    my $changed = copy($environment); $changed->{parameters}{W}{value_payload}{payload} = '99';
    $changed->{parameters}{W}{value_text} = '99';
    is(lower($bindings->{SUM}, $changed)->{text}, '(W + 3)', 'validation-cache changes cannot replace named operands');
    my $intervened = copy($bindings->{STATIC}); $intervened->{value_payload}{payload} = '32';
    is(lower($intervened)->{text}, '32', 'a changed captured immutable selection changes the rendered literal');
    is($json->encode([$raw, $environment, $bindings]), $before, 'complete source/Core/caller JSON values and kinds remain unchanged');
    my $result = lower($bindings->{REPEATED}); $result->{parameter_references}[0] = 'WRONG';
    is_deeply(lower($bindings->{REPEATED})->{parameter_references}, ['W','W'], 'returned reference arrays are detached');
};

subtest 'existing legality and explicit scope boundaries refuse malformed or unsupported trees' => sub {
    for my $case (
        ['foreign source owner', sub {$_[0]{COPY}{scope}{owner} = 'physical_name'}, 'COPY', qr/scope/],
        ['selected path', sub {$_[0]{COPY}{suffix}='[0]'; $_[0]{COPY}{token}='W[0]'}, 'COPY', qr/exact scalar parameter token/],
        ['sized source literal', sub {$_[0]{W}{token}="8'h10"}, 'W', qr/decimal source literal/],
        ['negative literal', sub {$_[0]{W}{token}='-1'}, 'W', qr/decimal source literal/],
        ['portable bound', sub {$_[0]{W}{token}='2147483648'}, 'W', qr/portable integer range/],
        ['bitwise operator', sub {$_[0]{SUM}{operator}=$_[0]{SUM}{source_operator}='&'}, 'SUM', qr/arithmetic operator/],
        ['zero divisor', sub {$_[0]{REMAINDER}{operands}[1]{token}='0'}, 'REMAINDER', qr/modulo by zero|divides by zero/],
        ['underflow before addition', sub {$_[0]{SUM}={kind=>'operator',operator=>'+',source_operator=>'+',operands=>[
            {kind=>'operator',operator=>'-',source_operator=>'-',operands=>[{kind=>'literal',token=>'0'},{kind=>'literal',token=>'1'}]},
            {kind=>'literal',token=>'2'}]}}, 'SUM', qr/negative width-expression value/],
    ) {
        my ($name,$change,$selected,$reason)=@$case;
        my $input=copy($bindings); $change->($input); my $old=$json->encode($input);
        my $ok=eval {lower($input->{$selected});1}; my $error=$@;
        ok(!$ok, "$name refuses"); like($error,$reason,"$name identifies its boundary");
        is($json->encode($input),$old,"$name preserves caller JSON kinds");
        $capture{refusals}{$name}=$error;
    }
    my $unknown=copy($environment); $unknown->{scope}{kind}='instance';
    my $ok=eval {lower($bindings->{W},$unknown);1};
    ok(!$ok,'unselected scope refuses'); like($@,qr/explicit.*scope/,'scope contract is explicit');
    my $incomplete=copy($environment); pop @{$incomplete->{declaration_order}};
    $ok=eval {lower($bindings->{W},$incomplete);1};
    ok(!$ok,'incomplete declaration membership refuses'); like($@,qr/declaration order|membership/,'membership is checked');
    $ok=eval {lower($bindings->{W},undef,'systemverilog');1};
    ok(!$ok,'wrong target refuses'); like($@,qr/VHDL target/,'target is checked');
    my $cycle={kind=>'operator',operator=>'+',source_operator=>'+'};
    $cycle->{operands}=[$cycle,{kind=>'literal',token=>'1'}];
    $ok=eval {lower($cycle);1}; my $error=$@;
    ok(!$ok,'cyclic binding refuses'); like($error,qr/cyclic/,'cycle is identified'); $cycle->{operands}=[];
};

if (my $path=$ENV{FSMGEN_SHARED_VHDL_BINDING_CAPTURE}) {
    open my $out,'>',$path or die $!;
    print {$out} $json->encode({%capture,environment=>$environment,bindings=>$bindings}),"\n" or die $!;
    close $out or die $!;
}
done_testing();
