use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::AST::Node;
use FSM::DirectDeclaredWidthSupport;
use FSM::Backend::VerilogFamily::DeclarationCapture;

my $json = JSON::PP->new->canonical;
sub source_state {
    my ($module) = @_;
    return $json->encode([$module->parameters, $module->parameter_default_sources, $module->parameter_default_bindings,
        {map {
            my $signal = $module->signals->{$_};
            $_ => [$signal->width, $signal->declared_width_binding, $signal->declared_width_requirements];
        } sort keys %{$module->signals}}]);
}

sub fixture {
    my ($width, $operator, %options) = @_;
    my $left = $options{left} // '(param W)';
    my $right = $options{right} // $left;
    my ($a, $b) = @{$options{names} // ['A', 'B']};
    my $source = "(?fsm:arithmetic_emission (+params (W $width) (COPY W) (SAME $width))"
        . " (+size (A $left) (B $right) (DATA 1) (OTHER 1))"
        . " (idle (<($operator $a $b) (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
    my $module = FSM::Adapter::FSMGenFull->new->parse_fsm(scalar Lispish::multi(\$source));
    my $before = source_state($module);
    my $ctx = FSM::HDL::FlattenedDT->new;
    my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
    my $collector = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport';
    my $renderer = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateRenderingSupport';
    my $tail = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationTailSupport';
    my $collect = $collector->can('collect_consolidated_intermediate_signals');
    my $render = $renderer->can('render_prepared_consolidated_intermediate_block');
    my $generate_tail = $tail->can('generate_systemverilog_tail');
    my ($all, $name, $hdl, %truth);
    my ($collected, $rendered) = (0, 0);
    {
        no warnings 'redefine';
        no strict 'refs';
        local *{"${collector}::collect_consolidated_intermediate_signals"} = sub {
            $collected++;
            $all = $collect->(@_);
            ($name) = grep {
                my $shape = FSM::IntermediateWidthAllocationSupport->binary_operand_max_shape($all->{$_}{ast});
                $shape && $shape->{operator} eq $operator && $json->encode($shape->{source_names}) eq $json->encode([$a, $b]);
            } keys %$all;
            return $all;
        };
        local *{"${renderer}::render_prepared_consolidated_intermediate_block"} = sub {
            $rendered++;
            return $render->(@_);
        };
        local *{"${tail}::generate_systemverilog_tail"} = sub {
            for my $case (['==', 0], ['!=', 0], ['==', 1]) {
                my ($op, $value) = @$case;
                my $ast = FSM::AST::BinaryOp->new($op,
                    FSM::AST::SignalRef->new($name), FSM::AST::Literal->new("$value"));
                $truth{$op.$value} = $ctx->{enable_graph_ast_support}->ast_to_systemverilog($ast);
            }
            my $result = $generate_tail->(@_);
            $options{late}->($ctx, $name) if $options{late};
            return $result;
        };
        local $ctx->{declared_width_declaration_capture} = $capture;
        $options{before}->($ctx, $module, $capture) if $options{before};
        $hdl = ($options{language} // '') eq 'verilog'
            ? $ctx->generate_verilog($module) : $ctx->generate_systemverilog($module);
    }
    die "no actual arithmetic helper\n" unless defined $name;
    return {flattened_dt => $ctx, signal_name => $name, signal_info => $all->{$name},
        target_language => 'systemverilog', %{$capture->snapshot}, capture => $capture,
        hdl => $hdl, module => $module, source_before => $before, truth => \%truth,
        collected => $collected, rendered => $rendered};
}

subtest 'actual arithmetic declarations consume proved ranges once and retain whole-vector truth' => sub {
    for my $operator ('+', '-', '*', '/', '%') {
        for my $width (1, 8) {
            for my $language ('systemverilog', 'verilog') {
                my $p = fixture($width, $operator, language => $language);
                my $name = $p->{signal_name};
                like($p->{hdl}, qr/^  wire \[\(W - 1\):0\] \Q$name\E;$/m,
                    "$operator $language at default $width retains its generic vector range");
                like($p->{hdl}, qr/^  assign \Q$name\E = A \Q$operator\E B;/m, 'selected arithmetic expression retains');
                like($p->{hdl}, qr/^  assign idle_data_1_en = idle_en && /m, 'whole-value logical gating retains high bits');
                is($p->{truth}{'==0'}, "(~|$name)", 'zero compares the entire symbolic helper');
                is($p->{truth}{'!=0'}, "(|$name)", 'nonzero compares the entire symbolic helper');
                is($p->{truth}{'==1'}, "$name == 1", 'equals-one remains exact equality');
                is($p->{collected}, 1, 'one actual collection');
                is($p->{rendered}, 1, 'one actual rendering');
                is(source_state($p->{module}), $p->{source_before}, 'complete source maps/captures and numeric kinds conserve');
                my $plan = FSM::DirectDeclaredWidthSupport->prepare_binary_intermediate_range(%$p);
                is($plan->{width_plan}{range_text}, '[(W - 1):0] ', 'complete final target proof independently agrees');
                ok(!exists($p->{flattened_dt}{direct_declared_width_emitted_binary_ranges}), 'emitted ledger leaves the context after success');
            }
        }
    }
};

subtest 'ordered arithmetic operands and duplicates retain their actual operations' => sub {
    for my $names (['B', 'A'], ['A', 'A']) {
        my $p = fixture(1, '-', names => $names);
        my $name = $p->{signal_name};
        is_deeply($p->{target_intermediates}{$name}{arithmetic_origin}{source_names}, $names, 'operand slots retain order and duplicates');
        my $expression = join(' - ', @$names);
        like($p->{hdl}, qr/assign \Q$name\E = \Q$expression\E;/, 'noncommutative expression preserves operand order');
    }
};

subtest 'unproved operand relationships refuse and fixed helpers preserve numeric shape' => sub {
    for my $right ('(param COPY)', '(param SAME)', '8', '(+ (param W) 0)') {
        ok(!eval {fixture(8, '+', right => $right); 1}, 'independent operand contract returns no artifact');
        like($@, qr/identical mutable operand contracts/, 'canonical source relationship owns the refusal');
    }
    for my $width (1, 8) {
        my $p = fixture($width, '+', left => "$width", right => "$width");
        my $name = $p->{signal_name};
        my $range = $width == 1 ? '' : '[7:0] ';
        like($p->{hdl}, qr/^  wire \Q$range$name\E;$/m, 'fixed helper keeps its existing numeric declaration');
    }
};

subtest 'late emitted-record and current-source changes revoke output and permit fresh reuse' => sub {
    for my $change (
        sub {$_[0]{direct_declared_width_emitted_binary_ranges}{$_[1]}{width_plan}{range_text} = '[WRONG:0] '},
        sub {$_[0]{direct_declared_width_emitted_binary_ranges}{$_[1]}{arithmetic_origin}{operator} = '-'},
        sub {$_[0]{direct_declared_width_emitted_binary_ranges}{$_[1]}{allocation_role} = 'source_intermediate'},
        sub {$_[0]{declared_width_declaration_capture}{intermediates}{$_[1]}{expression} = 'A - B'},
        sub {delete $_[0]{declared_width_declaration_capture}{intermediates}{$_[1]}{width_allocation}},
        sub {
            my $a = $_[0]{fsm_module}->signals->{A};
            $a->set_attribute('width_declared', $a->get_attribute('width_declared'));
        },
    ) {
        my ($ctx, $module, $capture);
        my $ok = eval {fixture(8, '+', late => $change, before => sub {($ctx, $module, $capture) = @_}); 1};
        ok(!$ok, 'late conflict cannot return arithmetic HDL');
        like($@, qr/binary|allocation/, 'actual final proof identifies the conflict');
        ok(!eval {$capture->snapshot; 1}, 'failed closure exposes no completed snapshot');
        ok(!exists($ctx->{direct_declared_width_emitted_binary_ranges}), 'failed generation drops the emitted ledger');
        local $ctx->{declared_width_declaration_capture} = $capture;
        ok($ctx->generate_systemverilog($module), 'same backend/collector recover after refusal');
    }
};
done_testing();
