use strict;
use warnings;
use lib 'perl';
use Test::More;
use Scalar::Util qw(refaddr);
use JSON::PP;
use Lispish;
use FSM::CoreAST;
use FSM::CoreExpressionWidthSupport;
use FSM::ExpressionNamer;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::Backend::VerilogFamily::DeclarationCapture;
use FSM::Synthesis::EnableGraph::CaptureSupport;
use FSM::Synthesis::EnableGraph::ASTSupport;

my $json = JSON::PP->new->canonical;
sub reference {
    FSM::CoreAST::SignalRef->new(FSM::CoreAST::Signal->new(name => $_[0], width => $_[1]));
}
sub profile {
    my ($module) = @_;
    return $json->encode({parameters => $module->parameters,
        signals => {map {
            my $signal = $module->signals->{$_};
            $_ => {width => $signal->width, binding => $signal->declared_width_binding,
                requirements => $signal->declared_width_requirements,
                expression => $signal->driving_ast ? $signal->driving_ast->to_systemverilog : undef}
        } sort keys %{$module->signals}}});
}

subtest 'capture retains typed ordered operands and independent exact sums' => sub {
    my $capture = FSM::Synthesis::EnableGraph::CaptureSupport->new(flattened_dt => {});
    my $a = reference('A', 8);
    my $b = reference('B', 3);
    my $literal = FSM::CoreAST::Literal->new('0101', width => 4, radix => 'binary');
    my @cases = (
        [FSM::CoreAST::Concatenation->new($a, $b), '{A, B}', 11],
        [FSM::CoreAST::Concatenation->new($b, $a), '{B, A}', 11],
        [FSM::CoreAST::Concatenation->new($a, $b, $a), '{A, B, A}', 19],
        [FSM::CoreAST::Concatenation->new($a,
            FSM::CoreAST::Concatenation->new($b, $literal)), '{A, {B, 4\'b101}}', 15],
    );
    for my $case (@cases) {
        my ($core, $text, $bits) = @$case;
        my @before = map {refaddr($_)} @{$core->operands};
        my $actual = $capture->convert_condition_to_ast($core);
        isa_ok($actual, 'FSM::CoreAST::Concatenation');
        is(refaddr($actual), refaddr($core), 'capture preserves the existing typed expression');
        is_deeply([map {refaddr($_)} @{$core->operands}], \@before,
            'every operand occurrence and order preserve');
        is($actual->to_systemverilog, $text, 'full typed source spelling conserves');
        is(FSM::CoreExpressionWidthSupport->infer_width($actual), $bits,
            'exact width is the independently expected ordered sum');
        is(FSM::ExpressionNamer->new->infer_ast_width($actual), $bits,
            'existing typed naming consumer retains the sum');
    }
    my $unknown = FSM::CoreAST::Concatenation->new($a, FSM::CoreAST::Literal->new('7'));
    my $actual = $capture->convert_condition_to_ast($unknown);
    ok(!defined FSM::CoreExpressionWidthSupport->infer_width($actual),
        'capture cannot turn an unsized source into an exact width');
};

subtest 'target rendering recursively consumes typed concatenation operands' => sub {
    my $fixture = '(?fsm:concat_render (+size (A 8) (B 3) (DATA 1) (OTHER 1))'
        .' (idle (<A (= (DATA 1)) (= (OTHER 1))) (-> idle)))';
    my $ctx = {fsm_module => FSM::Adapter::FSMGenFull->new->parse_fsm(scalar Lispish::multi(\$fixture))};
    $ctx->{enable_graph_capture_support} = FSM::Synthesis::EnableGraph::CaptureSupport->new(flattened_dt => $ctx);
    my $renderer = FSM::Synthesis::EnableGraph::ASTSupport->new(flattened_dt => $ctx);
    my $a = reference('A', 8);
    my $b = reference('B', 3);
    # Core spelling is retained by capture; nested target rendering must apply
    # the existing vector-NOT rule and preserve literal width/radix.
    my $literal = FSM::CoreAST::Literal->new('0101', width => 4, radix => 'binary');
    my $core = FSM::CoreAST::Concatenation->new($a,
        FSM::CoreAST::Concatenation->new($literal, $b, $a,
            FSM::CoreAST::UnaryOp->new(operator => '!', operand => $a)));
    my $before = $core->to_systemverilog;
    is($renderer->ast_to_systemverilog($core), "{A, {4'b101, B, A, (~|A)}}",
        'target conserves nested order, radix, explicit width and repeated operands');
    is($core->to_systemverilog, $before, 'target rendering preserves the caller tree');
};

subtest 'fixed native guard declarations and complete values conserve in both backends' => sub {
    my @cases = (
        ['(concat A B)', '{A, B}', 11],
        ['(concat B A)', '{B, A}', 11],
        ['(concat A B A)', '{A, B, A}', 19],
        ["(concat A (concat B 4'b0101))", "{A, {B, 4'b101}}", 15],
        ['(concat BIT BIT)', '{BIT, BIT}', 2],
    );
    for my $case (@cases) {
        my ($expression, $expected, $bits) = @$case;
        my $source = '(?fsm:concat_guard (+size (A 8) (B 3) (BIT 1) (DATA 1) (OTHER 1))'
            ." (idle (<$expression (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
        my $raw = scalar Lispish::multi(\$source);
        my $before = $json->encode($raw);
        my $module = FSM::Adapter::FSMGenFull->new->parse_fsm($raw);
        my $core_before = profile($module);
        my $backend = FSM::HDL::FlattenedDT->new;
        for my $language (qw(systemverilog verilog)) {
            my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
            my ($hdl, $error);
            {
                local $backend->{declared_width_declaration_capture} = $capture;
                eval {$hdl = $language eq 'verilog' ? $backend->generate_verilog($module)
                    : $backend->generate_systemverilog($module); 1} or $error = $@;
            }
            is($error, undef, "$language $expression generation completes on reused backend") or diag $error;
            next if $error;
            unlike($hdl, qr/\bcondition\b/, 'no invented condition signal reaches HDL');
            my %assignments = $hdl =~ /^  assign (\w+) = ([^;]+);/mg;
            my @names = grep {$assignments{$_} eq $expected} keys %assignments;
            is(scalar(@names), 1, 'one complete actual concatenation preserves every ordered operand');
            if (@names == 1) {
                my $name = $names[0];
                is($capture->snapshot->{target_declarations}{$name}{width}, $bits,
                    'actual captured declaration has the independent summed width');
                my $high = $bits - 1;
                like($hdl, qr/^  wire \[$high:0\] \Q$name\E;$/m,
                    'emitted helper declaration agrees with the summed width');
                ok(scalar(grep {/\b\Q$name\E\b/} values %assignments) > 0,
                    'actual guard uses the concatenation result');
            }
            is(profile($module), $core_before, 'Core widths, sources and bindings preserve');
            is($json->encode($raw), $before, 'complete caller source and JSON kinds preserve');
        }
    }
};

subtest 'unproved mutable concatenation helpers refuse atomically and permit reuse' => sub {
    for my $language (qw(systemverilog verilog)) {
        my $backend = FSM::HDL::FlattenedDT->new;
        for my $mutable (1, 0) {
            my $parameters = $mutable ? '(+params (W 8))' : '';
            my $width = $mutable ? '(param W)' : '8';
            my $source = "(?fsm:concat_boundary $parameters (+size (A $width) (B 3) (DATA 1) (OTHER 1))"
                .' (idle (<(concat A B) (= (DATA 1)) (= (OTHER 1))) (-> idle)))';
            my $raw = scalar Lispish::multi(\$source);
            my $before = $json->encode($raw);
            my $module = FSM::Adapter::FSMGenFull->new->parse_fsm($raw);
            my $core_before = profile($module);
            my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
            my ($hdl, $error);
            {
                local $backend->{declared_width_declaration_capture} = $capture;
                eval {$hdl = $language eq 'verilog' ? $backend->generate_verilog($module)
                    : $backend->generate_systemverilog($module); 1} or $error = $@;
            }
            if ($mutable) {
                like($error // '', qr/concatenation.*requires proved symbolic sum range/,
                    "$language refuses numeric default freezing of an unproved sum");
                ok(!defined $hdl, 'no partial HDL returns');
                my $snapshot = eval {$capture->snapshot};
                ok(!defined $snapshot, 'failed capture exposes no successful declaration snapshot');
            } else {
                is($error, undef, 'same backend recovers with a fixed source') or diag $error;
                my $snapshot = eval {$capture->snapshot};
                ok(defined $snapshot, 'fresh complete declaration capture succeeds');
            }
            is(profile($module), $core_before, 'success and refusal conserve actual Core sources');
            is($json->encode($raw), $before, 'success and refusal conserve caller bytes and kinds');
        }
    }
};

done_testing();
