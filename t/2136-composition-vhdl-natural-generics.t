use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Composition::Parser;
use FSM::Composition::PackageImportResolver;
use FSM::Composition::Plan;
use FSM::IR::StructuralRTLIRBuilder;
use FSM::Backend::VHDL::StructuralRTLIREmitter;
use FSM::SourcePathResolver;
my $loaded = eval {require FSM::Backend::VHDL::CompositionParameterEmitter;1};
ok($loaded, 'VHDL canonical generic preparer exists') or BAIL_OUT($@);
my $json = JSON::PP->new->canonical;
sub copy { $json->decode($json->encode($_[0])) }
my $path = 't/data/composition-vhdl-natural-generics.fsm';
my $spec = FSM::Composition::Parser->new->parse_source(scalar Lispish::multi($path));
FSM::Composition::PackageImportResolver->resolve_imports(composition_spec => $spec,
    fsm_file => $path, source_path_resolver => FSM::SourcePathResolver->new);
my $plan = FSM::Composition::Plan->new(top_name => $spec->top->name, raw_spec => $spec,
    ports => $spec->top->ports_blocks->[0]->ports);
my $ir = FSM::IR::StructuralRTLIRBuilder->build_from_composition_plan($plan)->as_hashref;
$ir->{target_language} = 'vhdl';
sub lower { FSM::Backend::VHDL::CompositionParameterEmitter->lower_declarations(structural => $_[0]) }
sub refuses {
    my ($label, $change, $pattern) = @_;
    my $input = copy($ir); $change->($input);
    my $before = $json->encode($input);
    my $ok = eval {lower($input);1}; my $error = $@;
    ok(!$ok, "$label refuses"); like($error, $pattern, "$label identifies the boundary");
    is($json->encode($input), $before, "$label preserves input data");
}
subtest 'actual captured defaults preserve natural generic identity and dependency order' => sub {
    my $before = $json->encode($ir);
    my $expected = [
        {name=>'WIDTH', type=>'natural', default_text=>'16', parameter_references=>[]},
        {name=>'COPY', type=>'natural', default_text=>'WIDTH', parameter_references=>['WIDTH']},
        {name=>'EQUAL', type=>'natural', default_text=>'16', parameter_references=>[]},
        {name=>'TOTAL', type=>'natural', default_text=>'(COPY + 2)', parameter_references=>['COPY']},
    ];
    is_deeply(lower($ir), $expected, 'literal expected typed declarations retain aliases and ready authored ties');
    my $input = copy($ir);
    $input->{parameter_environment}{parameters}{WIDTH}{value_payload}{payload} = '99';
    $input->{parameter_environment}{parameters}{WIDTH}{value_text} = '99';
    is_deeply(lower($input), $expected, 'validation values cannot supply authored defaults or names');
    my $result = lower($ir); $result->[1]{parameter_references}[0] = 'WRONG';
    is_deeply(lower($ir), $expected, 'returned dependency arrays belong to the caller');
    is($json->encode($ir), $before, 'complete captured source/Plan/IR remains unchanged');
    my $text = FSM::Backend::VHDL::StructuralRTLIREmitter->emit_module($ir);
    like($text, qr/WIDTH : natural := 16;\n    COPY : natural := WIDTH;/,
        'prepared VHDL emitter consumes these canonical declarations');
};
subtest 'case insensitive namespace, default graphs and profile limits refuse explicitly' => sub {
    refuses('case-folded port collision', sub {$_[0]{ports}[0]{name}='width'}, qr/WIDTH.*port/);
    refuses('case-folded module collision', sub {$_[0]{module_name}='width'; $_[0]{parameter_environment}{scope}{owner}='width'}, qr/WIDTH.*module/);
    refuses('VHDL reserved word', sub {$_[0]{ports}[0]{name}='SIGNAL'}, qr/reserved.*SIGNAL|SIGNAL.*reserved/);
    refuses('generated type collision', sub {$_[0]{ports}[0]{name}='NATURAL'}, qr/hides a generated type/);
    refuses('underscore prefix', sub {$_[0]{ports}[0]{name}='_clk'}, qr/basic identifier/);
    refuses('adjacent underscores', sub {$_[0]{ports}[0]{name}='c__lk'}, qr/basic identifier/);
    refuses('trailing underscore', sub {$_[0]{ports}[0]{name}='clk_'}, qr/basic identifier/);
    refuses('foreign module scope', sub {$_[0]{parameter_environment}{scope}{owner}='other'}, qr/scope/);
    refuses('foreign parameter binding', sub {$_[0]{parameter_environment}{default_bindings}{COPY}{scope}{owner}='other'}, qr/scope/);
    refuses('incomplete declaration order', sub {pop @{$_[0]{parameter_environment}{declaration_order}}}, qr/membership|order/);
    refuses('duplicate declaration order', sub {push @{$_[0]{parameter_environment}{declaration_order}}, 'WIDTH'}, qr/order/);
    refuses('missing default binding', sub {delete $_[0]{parameter_environment}{default_bindings}{WIDTH}}, qr/membership/);
    refuses('unknown reference', sub {my $b=$_[0]{parameter_environment}{default_bindings}{COPY}; $b->{parameter}=$b->{token}='MISSING'}, qr/declared parameter/);
    refuses('aggregate root', sub {$_[0]{parameter_environment}{parameters}{WIDTH}{value_kind}='list'}, qr/scalar/);
    refuses('sized source literal', sub {$_[0]{parameter_environment}{default_bindings}{WIDTH}{token}="8'h10"}, qr/decimal|natural/);
    refuses('negative default literal', sub {$_[0]{parameter_environment}{default_bindings}{WIDTH}{token}='-1'}, qr/decimal|natural/);
    refuses('out of portable range', sub {$_[0]{parameter_environment}{default_bindings}{WIDTH}{token}='2147483648'}, qr/portable|range/);
    refuses('bitwise generic operation', sub {my $b=$_[0]{parameter_environment}{default_bindings}{TOTAL};$b->{operator}=$b->{source_operator}='&'}, qr/operator/);
    refuses('default cycle', sub {$_[0]{parameter_environment}{default_bindings}{WIDTH}=copy($_[0]{parameter_environment}{default_bindings}{COPY}); my $b=$_[0]{parameter_environment}{default_bindings}{WIDTH};$b->{parameter}=$b->{token}='COPY'}, qr/cycle/);
    refuses('non VHDL target', sub {$_[0]{target_language}='systemverilog'}, qr/VHDL target/);
};
subtest 'canonical arithmetic aliases and per-fold portable limits' => sub {
    for my $case (
        ['+', 'add', '(WIDTH + 3)'], ['-', 'sub', '(WIDTH - 3)'],
        ['*', 'mul', '(WIDTH * 3)'], ['/', 'div', '(WIDTH / 3)'],
        ['%', 'mod', '(WIDTH mod 3)'],
    ) {
        my ($operator,$source,$expected) = @$case;
        my $input = copy($ir);
        $input->{parameter_environment}{default_bindings}{TOTAL} = {
            kind=>'operator', operator=>$operator, source_operator=>$source,
            operands=>[copy($input->{parameter_environment}{default_bindings}{COPY}), {kind=>'literal',token=>'3'}]};
        my $result = lower($input);
        is($result->[-1]{default_text}, $expected, "$source preserves selected integer identity and exact target operator");
        is_deeply($result->[-1]{parameter_references}, ['WIDTH'], 'selected WIDTH reference remains independent of COPY');
    }
    refuses('integer overflow before zero multiplication', sub {
        $_[0]{parameter_environment}{default_bindings}{TOTAL} = {
            kind=>'operator',operator=>'*',source_operator=>'mul',operands=>[
                {kind=>'literal',token=>'2147483647'}, {kind=>'literal',token=>'2'}, {kind=>'literal',token=>'0'}]};
    }, qr/portable integer range/);
    refuses('zero divisor', sub {
        my $b=$_[0]{parameter_environment}{default_bindings}{TOTAL};
        $b->{operator}='/';$b->{source_operator}='div';$b->{operands}[1]={kind=>'literal',token=>'0'};
    }, qr/divides by zero/);
    refuses('case-folded parameter collision', sub {
        my $e=$_[0]{parameter_environment};
        $e->{parameters}{width}=copy($e->{parameters}{WIDTH});
        $e->{default_bindings}{width}=copy($e->{default_bindings}{WIDTH});
        push @{$e->{declaration_order}}, 'width';
    }, qr/width.*parameter/);
    my $input = copy($ir);
    my $node = {kind=>'operator',operator=>'+',source_operator=>'add'};
    $node->{operands} = [$node,{kind=>'literal',token=>'1'}];
    $input->{parameter_environment}{default_bindings}{TOTAL} = $node;
    my $ok = eval {lower($input);1};
    ok(!$ok, 'recursive caller binding tree refuses'); like($@, qr/cyclic tree/, 'cycle is contextual rather than unbounded recursion');
};
subtest 'ordinary static structures retain empty prepared declarations' => sub {
    is_deeply(lower({target_language=>'vhdl',module_name=>'static_top'}), [], 'static emitter preparation is empty');
};
done_testing;
