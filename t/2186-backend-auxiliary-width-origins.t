use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::Backend::VerilogFamily::DeclarationCapture;

my $json = JSON::PP->new->canonical;
sub parse {
    my ($text) = @_;
    return FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(scalar Lispish::multi(\$text));
}
sub normalized {
    my ($hdl) = @_;
    $hdl =~ s{^// Date:.*$}{// Date: <generation-time>}mg;
    return $hdl;
}
sub row { return {name => $_[0], width => 1, signed => 0} }

subtest 'actual next/q allocation records parent identities without inferring equal-width origins' => sub {
    for my $width (1, 8) {
        for my $op ('<-', '<-=', '<=', '<=-', '<=+') {
            my $source = "(?fsm:aux_origins (+params (W $width))"
                .' (+size (DATA (param W)) (SOURCE (param W)) (FIXED 1) (BIT 1))'
                ." (idle ($op (DATA SOURCE)) (= (FIXED BIT)) (-> idle)))";
            my $module = parse($source);
            my $dt = FSM::HDL::FlattenedDT->new(debug => 0);
            my $baseline = $dt->generate_systemverilog($module);
            my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
            my $hdl;
            {local $dt->{declared_width_declaration_capture} = $capture;
                $hdl = $dt->generate_systemverilog($module)}
            is(normalized($hdl), normalized($baseline), 'whole captured HDL preserves ordinary generation');
            my $is_next = $op eq '<-' || $op eq '<-=';
            my $helper = $is_next ? 'DATA_next' : 'DATA_q';
            my $expected = {kind => $is_next ? 'register_next' : 'register_q', source_name => 'DATA'};
            my $plan = $dt->{enable_graph_module_planning_support}->build_internal_signal_declaration_plan(
                $module, $dt->{declared_port_signals});
            is_deeply($plan->{aux_width_origins}, {$helper => $expected}, 'whole allocation-origin map names actual assignment parent');
            my $snapshot = $capture->snapshot;
            is_deeply($snapshot->{target_declarations}{$helper}{width_origin}, $expected,
                'actual emitter preserves the complete allocation identity');
            is($snapshot->{target_declarations}{$helper}{width}, $width, 'selected numeric helper width remains unchanged');
            ok(!exists($snapshot->{target_declarations}{FIXED}{width_origin}), 'independent equal-default scalar has no borrowed origin');
            ok(!exists($snapshot->{target_declarations}{DATA}{width_origin}), 'parent declaration acquires no helper origin');
            my $before = $json->encode($capture->snapshot);
            $snapshot->{target_declarations}{$helper}{width_origin}{source_name} = 'WRONG';
            $plan->{aux_width_origins}{$helper}{source_name} = 'WRONG';
            is($json->encode($capture->snapshot), $before, 'held plan/snapshot mutation cannot rewrite captured origin');
        }
    }
};

subtest 'literal type and pulse allocations preserve their distinct width contracts' => sub {
    for my $slot ('8', 'word') {
        my $source = "(?fsm:fixed_aux (+types (type word (four_state (signed (bits 8)))))"
            ." (+size (DATA $slot) (SOURCE $slot) (PULSE 1))"
            .' (idle (<= (DATA SOURCE)) (<3 (PULSE 1)) (-> idle)))';
        my $module = parse($source);
        my $dt = FSM::HDL::FlattenedDT->new(debug => 0);
        my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
        {local $dt->{declared_width_declaration_capture} = $capture; $dt->generate_systemverilog($module)}
        my $plan = $dt->{enable_graph_module_planning_support}->build_internal_signal_declaration_plan(
            $module, $dt->{declared_port_signals});
        is_deeply($plan->{aux_width_origins}, {DATA_q => {kind => 'register_q', source_name => 'DATA'}},
            'only actual same-shape register allocation has a parent relationship');
        my $declarations = $capture->snapshot->{target_declarations};
        ok(!exists($declarations->{PULSE_pulse_delay_pipe}{width_origin}), 'pulse delay width cannot borrow its data width');
        is($declarations->{PULSE_pulse_delay_pipe}{width}, 3, 'pulse delay retains actual cycle-derived width');
        is($declarations->{DATA_q}{signed}, $slot eq 'word' ? 1 : 0, 'signedness remains selected type metadata');
        is_deeply($declarations->{DATA_q}{declared_type_spec}, $declarations->{DATA}{declared_type_spec},
            'complete parent/helper type metadata preserves');
    }
};

subtest 'collector detaches optional origins and rejects malformed or incomplete relationships' => sub {
    my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
    $capture->begin_module('valid');
    my $origin = {kind => 'register_next', source_name => 'DATA'};
    $capture->record_declaration('signals', {%{row('HELPER')}, width_origin => $origin});
    $origin->{source_name} = 'WRONG';
    $capture->record_declaration('signals', row('DATA'));
    $capture->complete;
    is_deeply($capture->snapshot->{target_declarations}{HELPER}{width_origin},
        {kind => 'register_next', source_name => 'DATA'}, 'input origin is detached and forward membership resolves at completion');
    for my $bad (undef, {}, 'DATA', {kind => 'pulse', source_name => 'DATA'},
        {kind => 'register_q', source_name => ''}, {kind => 'register_q', source_name => []},
        {kind => 'register_q', source_name => 'DATA', extra => 1},
        {kind => 'register_q', source_name => 'HELPER'}) {
        $capture->begin_module('malformed');
        ok(!eval {$capture->record_declaration('signals', {%{row('HELPER')}, width_origin => $bad}); 1}, 'malformed origin refuses');
        like($@, qr/width origin/, 'origin refusal is named');
        ok(!eval {$capture->snapshot; 1}, 'failed origin never exposes prior/partial snapshot');
    }
    $capture->begin_module('port');
    ok(!eval {$capture->record_declaration('ports', {%{row('HELPER')}, width_origin => {kind => 'register_q', source_name => 'DATA'}}); 1},
        'port declarations cannot claim backend helper allocation');
    $capture->begin_module('missing');
    $capture->record_declaration('signals', {%{row('HELPER')}, width_origin => {kind => 'register_q', source_name => 'MISSING'}});
    ok(!eval {$capture->complete; 1}, 'missing actual parent membership refuses completion');
    like($@, qr/width origin.*parent/, 'missing parent is explicit');
    ok(!eval {$capture->snapshot; 1}, 'failed completion invalidates origin snapshot');
    $capture->begin_module('legacy'); $capture->record_declaration('signals', row('FIXED')); $capture->complete;
    ok(!exists($capture->snapshot->{target_declarations}{FIXED}{width_origin}), 'legacy absent-field shape remains exact on reuse');
};
done_testing();
