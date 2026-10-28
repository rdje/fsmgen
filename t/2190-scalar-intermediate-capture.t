use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::AST::Node;
use FSM::Backend::VerilogFamily::DeclarationCapture;

my $json = JSON::PP->new->canonical;
sub parse {my ($s) = @_; FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(scalar Lispish::multi(\$s))}
sub normalized {my ($s) = @_; $s =~ s{^// Date:.*$}{// Date: <time>}mg; $s}
sub reduction {FSM::AST::UnaryOp->new($_[0], FSM::AST::SignalRef->new($_[1] // 'INPUT'))}
sub row {{name => $_[0], width => $_[1] // 1, signed => 0}}
sub prepared {
    my ($dt, $capture, $info, $name) = @_; $name //= 'arbitrary_name';
    $capture->begin_module('prepared');
    $capture->record_declaration('ports', row('INPUT', 8));
    local $dt->{declared_width_declaration_capture} = $capture;
    my $block = {sorted_signals => [$name], filtered_signals => {$name => $info}};
    my $hdl = $dt->{backend_sv_consolidated_intermediate_declaration_support}
        ->render_consolidated_intermediate_declarations($block);
    $hdl .= $dt->{backend_sv_consolidated_intermediate_assignment_support}
        ->render_consolidated_intermediate_assignments($block);
    $capture->complete;
    return ($hdl, $capture->snapshot);
}

subtest 'actual scalar reduction declaration and assignment events preserve whole ordinary HDL' => sub {
    for my $width (1, 8) {
        for my $op ('^', '&', '|') {
            my $source = "(?fsm:scalar_origins (+params (W $width)) (+size (INPUT (param W)) (DATA 1) (OTHER 1))"
                ." (idle (<($op INPUT) (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
            my $module = parse($source);
            my $before = $json->encode([$module->parameters, $module->parameter_default_sources, $module->parameter_default_bindings]);
            my $dt = FSM::HDL::FlattenedDT->new(debug => 0);
            my $baseline = $dt->generate_systemverilog($module);
            my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
            my $hdl;
            {local $dt->{declared_width_declaration_capture} = $capture; $hdl = $dt->generate_systemverilog($module)}
            is(normalized($hdl), normalized($baseline), 'complete ordinary/captured artifact conserves');
            my $snapshot = $capture->snapshot;
            my ($name) = $hdl =~ /^  assign (\w+) = \(\Q$op\E\(INPUT\)\); \/\/ Source: ast_factorization$/m;
            ok(defined($name), 'native factorization emits actual whole-operand reduction');
            is_deeply($snapshot->{target_intermediates}, {$name => {expression => "($op(INPUT))",
                reduction_origin => {kind => 'scalar_reduction', operator => $op, source_name => 'INPUT'}}},
                'complete actual intermediate events retain selected expression and typed operand identity');
            is($snapshot->{target_declarations}{$name}{width}, 1, 'actual result declaration stays scalar at both operand defaults');
            is($snapshot->{target_declarations}{INPUT}{width}, $width, 'operand width remains independent');
            is($json->encode([$module->parameters, $module->parameter_default_sources, $module->parameter_default_bindings]), $before,
                'complete parameter/source/binding JSON kinds conserve');
            $snapshot->{target_intermediates}{$name}{expression} = 'WRONG';
            is($capture->snapshot->{target_intermediates}{$name}{expression}, "($op(INPUT))", 'returned expression events detach');
        }
    }
};

subtest 'actual selected AST and emitted expression agree without borrowing cache or name guesses' => sub {
    my $dt = FSM::HDL::FlattenedDT->new(debug => 0);
    my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
    my ($hdl, $valid) = prepared($dt, $capture, {width => 1, ast => reduction('^'), runtime_ast => reduction('^')}, 'not_a_suffix');
    is_deeply($valid->{target_intermediates}{not_a_suffix}{reduction_origin},
        {kind => 'scalar_reduction', operator => '^', source_name => 'INPUT'}, 'arbitrary allocated name has the actual AST relationship');
    my @unqualified = (
        {width => 1, rendered_expression => '(^(INPUT))', runtime_ast_resolution_state => 'missing'},
        {width => 1, ast => reduction('^'), runtime_ast => reduction('^'), rendered_expression => '(~|INPUT)'},
        {width => 1, ast => reduction('&'), runtime_ast => reduction('^')},
        {width => 1, ast => reduction('^'), defining_ast => reduction('|'), runtime_ast => reduction('^')},
        {width => 1, ast => reduction('!'), runtime_ast => reduction('!')},
        {width => 1, ast => FSM::AST::UnaryOp->new('^', FSM::AST::BinaryOp->new('&', FSM::AST::SignalRef->new('INPUT'), FSM::AST::SignalRef->new('INPUT')))},
    );
    for my $info (@unqualified) {
        my ($actual, $snapshot) = prepared($dt, $capture, $info, 'op_INPUT');
        my ($expression) = $actual =~ /^  assign op_INPUT = (.*); \/\/ Source:/m;
        is_deeply($snapshot->{target_intermediates}{op_INPUT}, {expression => $expression},
            'stored-only, stale, conflicting, logical and computed expressions retain actual text without reduction proof');
    }
    ok(!eval {prepared($dt, $capture, {width => 1, ast => reduction('^', 'FOREIGN')}); 1}, 'foreign operand absent from actual emitted declarations refuses completion');
    like($@, qr/intermediate.*operand/i, 'missing operand relationship is explicit');
    ok(!eval {$capture->snapshot; 1}, 'foreign failure exposes no old or partial snapshot');
};

subtest 'collector validates actual event membership, detachment, missing assignments and transaction reuse' => sub {
    my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
    $capture->begin_module('events');
    $capture->record_intermediate_declaration(row('RESULT'));
    $capture->record_declaration('ports', row('INPUT', 8));
    my $event = {expression => '(^(INPUT))', reduction_origin => {kind => 'scalar_reduction', operator => '^', source_name => 'INPUT'}};
    $capture->record_intermediate_assignment('RESULT', $event);
    $event->{reduction_origin}{operator} = '|'; $event->{expression} = 'WRONG';
    $capture->complete;
    is_deeply($capture->snapshot->{target_intermediates}{RESULT},
        {expression => '(^(INPUT))', reduction_origin => {kind => 'scalar_reduction', operator => '^', source_name => 'INPUT'}}, 'input event deeply detaches');
    $capture->begin_module('missing'); $capture->record_intermediate_declaration(row('RESULT')); $capture->complete;
    is_deeply($capture->snapshot->{target_intermediates}, {RESULT => {}}, 'actual missing assignment is preserved for consumer refusal');
    for my $bad (undef, {}, {expression => ''}, {expression => []}, {expression => 'INPUT', extra => 1},
        {expression => 'INPUT', reduction_origin => {}},
        {expression => 'INPUT', reduction_origin => {kind => 'scalar_reduction', operator => '!', source_name => 'INPUT'}}) {
        $capture->begin_module('malformed'); $capture->record_intermediate_declaration(row('RESULT'));
        ok(!eval {$capture->record_intermediate_assignment('RESULT', $bad); 1}, 'malformed event refuses');
        ok(!eval {$capture->snapshot; 1}, 'malformed event invalidates transaction');
    }
    $capture->begin_module('unknown'); $capture->record_declaration('signals', row('RESULT'));
    ok(!eval {$capture->record_intermediate_assignment('RESULT', {expression => 'INPUT'}); 1}, 'ordinary signal cannot claim an intermediate assignment');
    $capture->begin_module('duplicate'); $capture->record_intermediate_declaration(row('RESULT'));
    $capture->record_intermediate_assignment('RESULT', {expression => 'INPUT'});
    ok(!eval {$capture->record_intermediate_assignment('RESULT', {expression => 'INPUT'}); 1}, 'duplicate assignment event refuses');
    $capture->begin_module('wrong_width'); $capture->record_intermediate_declaration(row('RESULT', 8));
    ok(!eval {$capture->record_intermediate_assignment('RESULT', {expression => '(^(INPUT))',
        reduction_origin => {kind => 'scalar_reduction', operator => '^', source_name => 'INPUT'}}); 1},
        'numeric vector declaration cannot borrow a scalar reduction origin');
    $capture->begin_module('legacy'); $capture->record_declaration('signals', row('FIXED')); $capture->complete;
    ok(!exists($capture->snapshot->{target_intermediates}), 'empty event set preserves exact legacy snapshot shape on reuse');
};
done_testing();
