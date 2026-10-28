use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::DirectDeclaredWidthSupport;
use FSM::Backend::VerilogFamily::DeclarationCapture;

my $json = JSON::PP->new->canonical;
sub copy { $json->decode($json->encode($_[0])) }
sub parse {
    my ($text) = @_;
    return FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(scalar Lispish::multi(\$text));
}
sub source {
    my ($width, $op, $root) = @_;
    $root //= 'W';
    return "(?fsm:helper_ranges (+params (W $width) (SAME $width))"
        ." (+size (DATA (param $root)) (SOURCE (param W)) (FIXED 1) (BIT 1) (PULSE 1))"
        ." (idle ($op (DATA SOURCE)) (<= (FIXED BIT)) (<3 (PULSE 1)) (-> idle)))";
}
sub generate {
    my ($module, $language, $capture) = @_;
    my $dt = FSM::HDL::FlattenedDT->new(debug => 0);
    my $hdl;
    {local $dt->{declared_width_declaration_capture} = $capture;
        $hdl = $language eq 'verilog' ? $dt->generate_verilog($module) : $dt->generate_systemverilog($module)}
    return ($dt, $hdl);
}
sub prepare {
    my ($module, $dt, $snapshot) = @_;
    return FSM::DirectDeclaredWidthSupport->prepare_declarations(fsm_module => $module,
        assignment_analysis => $dt->{assignment_analysis}, target_language => 'systemverilog', %$snapshot);
}

subtest 'actual register helper ranges retain parent roots and vector rank' => sub {
    for my $width (1, 8) {
        for my $op ('<-', '<-=', '<=', '<=-', '<=+') {
            for my $language (qw(systemverilog verilog)) {
                my $module = parse(source($width, $op));
                my $before = $json->encode([$module->parameters, $module->parameter_default_sources, $module->parameter_default_bindings]);
                my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
                my ($dt, $hdl) = generate($module, $language, $capture);
                my $is_next = $op eq '<-' || $op eq '<-=';
                my $helper = $is_next ? 'DATA_next' : 'DATA_q';
                like($hdl, qr/^  reg \[\(W - 1\):0\] \Q$helper\E;$/m, 'complete helper declaration uses actual parent range at selected one/wider defaults');
                like($hdl, qr/^  reg FIXED_q;$/m, 'unrelated fixed helper remains scalar even at an equal default');
                like($hdl, qr/^  reg \[2:0\] PULSE_pulse_delay_pipe;$/m, 'pulse delay retains its cycle-count shape');
                my $plan = prepare($module, $dt, $capture->snapshot);
                my $parent = $plan->{ranges}{DATA};
                is_deeply($plan->{ranges}{$helper}, {source_name => 'DATA', declaration_kind => 'signal',
                    width_plan => $parent->{width_plan}, width_origin => {
                        kind => $is_next ? 'register_next' : 'register_q', source_name => 'DATA'}},
                    'whole independently expected helper plan preserves actual edge and canonical parent capture');
                ok(!exists($plan->{ranges}{FIXED_q}), 'fixed helper does not borrow a symbolic range');
                is($json->encode([$module->parameters, $module->parameter_default_sources, $module->parameter_default_bindings]), $before,
                    'complete source maps and caller JSON kinds conserve');
                ok(!exists($dt->{direct_declared_width_emitted_helper_origins}), 'emitted helper records are scoped to one generation');
            }
        }
    }
};

subtest 'helper metadata cannot override independent source ownership or inconsistent declarations' => sub {
    my $module = parse(source(1, '<-'));
    my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
    my ($dt) = generate($module, 'systemverilog', $capture);
    my $snapshot = $capture->snapshot;
    for my $change (
        sub {$_[0]{target_declarations}{DATA_next}{width_origin}{source_name} = 'UNKNOWN'},
        sub {$_[0]{target_declarations}{DATA_next}{width_origin}{kind} = 'pulse'},
        sub {$_[0]{target_declarations}{DATA_next}{width_origin}{extra} = 1},
        sub {$_[0]{target_declarations}{DATA_next}{width} = 8},
        sub {$_[0]{target_declarations}{DATA_next}{signed} = 1},
        sub {$_[0]{target_declarations}{DATA_next}{state_model} = 'four_state'},
        sub {$_[0]{target_declarations}{SOURCE}{width_origin} = {kind => 'register_q', source_name => 'DATA'}},
        sub {$_[0]{target_declarations}{DATA}{width_origin} = {kind => 'register_q', source_name => 'FIXED'}},
    ) {
        my $bad = copy($snapshot); $change->($bad); my $before = $json->encode($bad);
        ok(!eval {prepare($module, $dt, $bad); 1}, 'unknown, malformed, wrong-shape or source-owned origin refuses');
        like($@, qr/auxiliary|helper|origin|source Signal/, 'specific helper/ownership conflict is named');
        is($json->encode($bad), $before, 'refusal leaves complete target caller records unchanged');
    }
};

subtest 'late same-default parent replacement cannot bless already emitted helper ranges' => sub {
    my $module = parse(source(1, '<-'));
    my $other = parse(source(1, '<-', 'SAME'));
    my ($other_dt) = generate($other, 'systemverilog', FSM::Backend::VerilogFamily::DeclarationCapture->new);
    my $replacement = $other_dt->{assignment_analysis}{DATA}{lhs_ast};
    my $original = FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationTailSupport->can('generate_systemverilog_tail');
    my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
    my $dt = FSM::HDL::FlattenedDT->new(debug => 0);
    {
        no warnings 'redefine';
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationTailSupport::generate_systemverilog_tail = sub {
            my $hdl = $original->(@_);
            $_[0]{flattened_dt}{assignment_analysis}{DATA}{lhs_ast} = $replacement;
            return $hdl;
        };
        local $dt->{declared_width_declaration_capture} = $capture;
        ok(!eval {$dt->generate_systemverilog($module); 1}, 'late root replacement returns no HDL');
        like($@, qr/captured.*emitted|emitted.*captured/, 'emitted identity conflict is explicit');
    }
    ok(!eval {$capture->snapshot; 1}, 'failed qualification invalidates the collector');
};
subtest 'unchanged ranges cannot conceal a changed allocation-family snapshot' => sub {
    my $original = FSM::Backend::VerilogFamily::DeclarationCapture->can('snapshot');
    for my $helper ('DATA_next', 'FIXED_q') {
        my $module = parse(source(1, '<-'));
        my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
        no warnings 'redefine';
        {
            local *FSM::Backend::VerilogFamily::DeclarationCapture::snapshot = sub {
                my $snapshot = $original->(@_);
                $snapshot->{target_declarations}{$helper}{width_origin}{kind} =
                    $helper eq 'DATA_next' ? 'register_q' : 'register_next';
                return $snapshot;
            };
            ok(!eval {generate($module, 'systemverilog', $capture); 1}, 'same parent/width/range with a changed symbolic or fixed helper family returns no HDL');
            like($@, qr/captured auxiliary origins.*emitted helper identities/, 'separate emitted allocation identity guard rejects the conflicting family');
        }
        ok(!eval {$capture->snapshot; 1}, 'origin qualification failure invalidates the actual collector');
    }
};
done_testing();
