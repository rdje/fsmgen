use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use FSM::CoreAST;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::Synthesis::EnableGraph::CaptureSupport;
use FSM::Package::IntegerLiteralSupport;

my $capture = FSM::Synthesis::EnableGraph::CaptureSupport->new(flattened_dt => {});
my $json = JSON::PP->new->canonical;
sub snapshot {my ($v) = @_; $json->encode([$v->value,$v->width,$v->radix])}

subtest 'captured Core literals preserve independent exact values, widths and radices' => sub {
    for my $case (
        ['00000011',8,'binary',"8'b11",'3'], ['f0',8,'hex',"8'hF0",'240'],
        ['17',8,'octal',"8'o17",'15'], ['3',8,'decimal',"8'd3",'3'],
        ['0',8,'decimal',"8'd0",'0'], ['1',8,'binary',"8'b1",'1'],
        ['-1',8,'decimal',"8'd255",'255'], ['0011',undef,'binary',"'b0011",'3'],
        ['F0',undef,'hex',"'hF0",'240'],
    ) {
        my ($value,$width,$radix,$expected,$integer) = @$case;
        my $core = FSM::CoreAST::Literal->new($value,width => $width,radix => $radix);
        my $before = snapshot($core);
        is($core->to_systemverilog, $expected, 'actual Core producer matches independently authored target spelling');
        my $ast = $capture->convert_condition_to_ast($core);
        is($ast->to_systemverilog, $expected, 'capture carries the complete literal contract into actual downstream rendering');
        my $parts = FSM::Package::IntegerLiteralSupport->literal_parts_from_literal_like($ast);
        is($parts ? $parts->{value}->bstr : undef, $integer, 'existing typed consumer recovers the independent numeric value');
        is($parts ? $parts->{width} : undef, $width, 'existing typed consumer recovers the declared width without defaulting');
        is(snapshot($core), $before, 'actual caller value/radix/width and JSON kinds preserve');
    }
};

subtest 'ordinary unsized zero, one, decimal and symbolic literal products preserve' => sub {
    for my $case (['0',"1'b0"],['1',"1'b1"],['3','3'],['WIDTH','WIDTH'],["8'b10","8'b10"]) {
        my $core = FSM::CoreAST::Literal->new($case->[0]); my $before = snapshot($core);
        is($capture->convert_condition_to_ast($core)->to_systemverilog, $case->[1], 'ordinary actual runtime literal spelling remains unchanged');
        is(snapshot($core), $before, 'ordinary caller record remains unchanged');
    }
};

sub public_module {
    my ($literal) = @_;
    my %signals = map {$_ => FSM::CoreAST::Signal->new(name => $_,width => /^[AB]$/ ? 8 : 1)} qw(A B DATA OTHER);
    my $ref = sub {FSM::CoreAST::SignalRef->new($signals{$_[0]})};
    my $value = FSM::CoreAST::BinaryOp->new('|',$ref->('A'),$ref->('B'));
    my $condition = FSM::CoreAST::BinaryOp->new('==',$value,$literal);
    my @actions = map {FSM::CoreAST::Assignment->new(target => $ref->($_),source => FSM::CoreAST::Literal->new('1'))} qw(DATA OTHER);
    my $branch = FSM::CoreAST::ConditionalBranch->new(condition => $condition,branches => [{condition => $condition,actions => \@actions}]);
    my $dt = FSM::CoreAST::DecisionTree->new(name => 'idle',elements => [$branch,FSM::CoreAST::StateTransitionFSM->new(target_state => 'idle')]);
    return FSM::CoreAST::FSMModule->new(name => 'core_literal_guard',signals => \%signals,
        states => [FSM::CoreAST::State->new(name => 'idle',decision_trees => [$dt])]);
}
subtest 'actual public Core and native nested comparison consume the typed binary value, not decimal digits' => sub {
    for my $case (['00000011','binary',"8'b11"],['03','hex',"8'h3"],['03','octal',"8'o3"],['3','decimal',"8'd3"]) {
        my ($value,$radix,$expected) = @$case;
        my $literal = FSM::CoreAST::Literal->new($value,width => 8,radix => $radix);
        my $before = snapshot($literal); my $module = public_module($literal);
        my $dt = FSM::HDL::FlattenedDT->new(debug => 0); my $hdl = $dt->generate_systemverilog($module);
        my ($vector) = $hdl =~ /^  assign (\w+) = A \| B; \/\/ Source: ast_factorization$/m;
        ok(defined($vector), 'actual native producer preserves vector OR');
        like($hdl, qr/^  wire \[7:0\] \Q$vector\E;$/m, 'actual nested producer retains vector width');
        my ($predicate) = $hdl =~ /^  assign (\w+) = \Q$vector\E == \Q$expected\E; \/\/ Source: ast_factorization$/m;
        ok(defined($predicate), 'actual associated comparison carries the independent exact sized radix literal');
        my $selected = $predicate // 'MISSING';
        for my $target ('data','other') {
            like($hdl, qr/^  assign idle_\Q$target\E_1_en = idle_en & \Q$selected\E; /m,
                'both actual output selectors consume the typed comparison result');
        }
        is(snapshot($literal), $before, 'native generation preserves the exact caller literal kinds');
        (my $stable = $hdl) =~ s{^// Date:.*\n}{}m;
        (my $again = $dt->generate_systemverilog($module)) =~ s{^// Date:.*\n}{}m;
        is($again, $stable, 'backend reuse preserves the complete actual typed product apart from Date');
    }
};
subtest 'parsed typed and ordinary decimal guard literals retain actual source meaning' => sub {
    for my $token ("8'b11", '3') {
        my $source = "(?fsm:source_literal_guard (+size (A 8) (B 8) (DATA 1) (OTHER 1))"
            ." (idle (<(== (| A B) $token) (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
        my $module = FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(scalar Lispish::multi(\$source));
        my $before = $json->encode([$module->parameters, $module->parameter_default_sources,
            $module->parameter_default_bindings, {map {$_ => $module->signals->{$_}->width} keys %{$module->signals}}]);
        my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($module);
        my ($producer) = $hdl =~ /^  assign (\w+) = A \| B; \/\/ Source: fsmgen_parsing$/m;
        ok(defined($producer), 'actual source parser keeps its separately hoisted vector producer');
        like($hdl, qr/^  assign \w+ = \Q$producer\E == \Q$token\E; \/\/ Source: ast_factorization$/m,
            'actual source-aware comparison retains authored typed or ordinary decimal value');
        is($json->encode([$module->parameters, $module->parameter_default_sources,
            $module->parameter_default_bindings, {map {$_ => $module->signals->{$_}->width} keys %{$module->signals}}]), $before,
            'complete parsed caller metadata and selected widths preserve kinds');
    }
};
done_testing();
