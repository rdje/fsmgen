use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport;

my $class = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport';
my $json = JSON::PP->new->canonical;
unless ($class->can('prepare_selection') && $class->can('current_selection')) {
    fail('actual literal selected expression preparation exists');
    done_testing();
    exit;
}
sub selection {
    my ($p, $saved, %override) = @_;
    my %args = (width_support => $p->{owner}, signal_name => $p->{root},
        signal_info => $p->{rows}{$p->{root}}, signal_registry => $p->{rows},
        expression => $p->{expression}, target_language => 'systemverilog', %override);
    return defined($saved) ? $class->current_selection(%args, observation => $saved)
        : $class->prepare_selection(%args);
}
sub fixture {
    my (%args) = @_;
    my $w = $args{w} // 1;
    my $x = $args{x} // 1;
    my $params = $args{fixed} ? '' : "(+params (W $w) (X $x))";
    my $sizes = $args{fixed} ? '(A 8) (B 64)' : '(A (param W)) (B (param X))';
    my $literal = $args{explicit} ? "9'b100000000" : '256';
    my $expr = $args{direct} ? "(| A $literal)" : "(^ (| A $literal) B)";
    my $text = "(?fsm:literal_selection $params (+size $sizes (DATA 1) (OTHER 1))"
        ." (idle (<$expr (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
    my $raw = scalar Lispish::multi(\$text);
    my $input = $json->encode($raw);
    my $module = FSM::Adapter::FSMGenFull->new->parse_fsm($raw);
    my $ctx = FSM::HDL::FlattenedDT->new;
    my $normalizer = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateNormalizationSupport';
    my $normalize = $normalizer->can('_normalize_metadata');
    {
        no warnings 'redefine';
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateNormalizationSupport::_normalize_metadata = sub {
            my ($self, $rows) = @_;
            my $result = $normalize->(@_);
            my ($root) = grep {$module->signals->{$_}->driving_ast->operator eq ($args{direct} ? '|' : '^')}
                keys %$rows;
            my $p = {ctx => $ctx, module => $module, rows => $rows, root => $root,
                owner => $ctx->{backend_sv_intermediate_width_support}};
            $p->{recovery} = $ctx->{backend_sv_intermediate_recovery_support};
            $p->{expression} = $p->{recovery}->render_intermediate_signal_expression($root, $rows->{$root});
            $args{check}->($p);
            die "selected expression preparation complete\n";
        };
        eval {$ctx->generate_systemverilog($module)};
        like($@, qr/selected expression preparation complete/, 'observer stops before live declaration integration');
    }
    is($json->encode($raw), $input, 'original caller literal and parameter kinds conserve');
}

subtest 'actual fixed and mutable selections retain complete typed source intent' => sub {
    for my $fixed (0, 1) {for my $direct (0, 1) {for my $explicit (0, 1) {
        fixture(fixed => $fixed, direct => $direct, explicit => $explicit, check => sub {
            my $p = shift;
            my $before = $class->can('_range_source_frame')->($p->{ctx});
            my $plan = selection($p);
            ok($plan, 'actual current literal selection prepares') or return;
            is($class->can('_range_source_frame')->($p->{ctx}), $before, 'complete original source declarations conserve');
            is($plan->{kind}, 'systemverilog_source_literal_selection', 'selection has its own contract');
            is($plan->{expression}, $p->{expression}, 'root uses the actual selected expression');
            is($plan->{numeric}{observation}{selected_width}, $direct ? ($explicit ? 9 : 32) : ($fixed ? 64 : ($explicit ? 9 : 32)),
                'independent target literal and leaf maximum controls selected width');
            is(scalar(@{$plan->{node_order}}), $direct ? 1 : 2, 'all actual typed child helpers precede root');
            is($plan->{node_order}[-1], $p->{root}, 'root occurs last');
            for my $name (@{$plan->{node_order}}) {
                my $node = $plan->{nodes}{$name};
                is($node->{numeric}{signal_name}, $name, 'each selected node binds its actual row');
                is($node->{expression}, $p->{recovery}->render_intermediate_signal_expression($name, $p->{rows}{$name}),
                    'each child retains its actual selected expression');
            }
            is(defined($plan->{range}) ? 1 : 0, $fixed ? 0 : 1, 'only actual mutable leaves require a generic range');
            is_deeply(selection($p, $plan), $plan, 'saved complete selection rederives from current owners and rows');
            my $escaped = $json->decode($json->encode($plan));
            $escaped->{nodes}{$p->{root}}{expression} = 'A';
            ok(!defined(selection($p, $escaped)), 'editing detached selection cannot lend authority');
            is_deeply(selection($p), $plan, 'escaped data cannot change current source intent');
        });
    }}}
    fixture(w => 8, x => 128, check => sub {
        my $p = shift;
        my $plan = selection($p);
        ok($plan, 'wider independent mutable leaf prepares') or return;
        is($plan->{numeric}{observation}{selected_width}, 128, 'independent wide leaf is retained');
        like($plan->{range}{range_text}, qr/\bW\b.*\bX\b/s, 'independent mutable names survive their selected defaults');
    });
};

subtest 'text agreement cannot replace typed source row epoch or owner authority' => sub {
    for my $change (
        sub {my $p = shift; $p->{rows}{$p->{root}}{runtime_ast} = FSM::CoreAST::Literal->new('256')},
        sub {my $p = shift; $p->{rows}{$p->{root}}{defining_ast} = FSM::CoreAST::Literal->new('256')},
        sub {my $p = shift; $p->{rows}{$p->{root}}{rendered_expression} = 'A'},
        sub {my $p = shift; $p->{rows}{$p->{root}} = {%{$p->{rows}{$p->{root}}}}},
        sub {$_[0]{owner}{_width_inference_epoch}++},
        sub {my $p = shift; $p->{rows}{$p->{root}}{constraints} = ['independent']},
        sub {my $p = shift; delete $p->{module}->signals->{$p->{root}}->{_source_literal_width_allocation}},
        sub {my $p = shift; $p->{ctx}{backend_sv_intermediate_recovery_support} = bless {%{$p->{recovery}}}, ref($p->{recovery})},
        sub {my $p = shift; $p->{module}{parameters} = {%{$p->{module}{parameters}}}},
        sub {my $p = shift; my ($child) = grep {$_ ne $p->{root}} keys %{$p->{rows}};
            $p->{rows}{$child}{rendered_expression} = 'A'},
    ) {
        fixture(check => sub {
            my $p = shift;
            my $plan = selection($p);
            ok($plan, 'baseline current selection prepares') or return;
            $change->($p);
            ok(!defined(selection($p, $plan)), 'changed selected source or target cannot reuse a saved selection');
        });
    }
    fixture(check => sub {
        my $p = shift;
        ok(!defined(selection($p, undef, expression => 'A')), 'matching numeric width alone cannot license foreign selected text');
        ok(!defined(selection($p, undef, target_language => 'vhdl')), 'foreign target gets no selected literal authority');
    });
    for my $child (0, 1) {
        fixture(check => sub {
            my $p = shift;
            my ($name) = $child ? grep {$_ ne $p->{root}} keys %{$p->{rows}} : $p->{root};
            $p->{rows}{$name}{rendered_expression} = 'A';
            $p->{expression} = 'A' unless $child;
            ok(!defined(selection($p)), 'fresh typed rendering refuses matching cached-only selection');
        });
    }
    fixture(fixed => 1, check => sub {
        ok(!defined(selection($_[0], undef, target_language => 'vhdl')),
            'fixed observations cannot enter a foreign target through missing generic preparation');
    });
};

subtest 'last numeric recheck cannot hide an earlier child cache or source change' => sub {
    for my $source (0, 1) {
        fixture(check => sub {
            my $p = shift;
            my $original = $class->can('current_inference');
            my $fired = 0;
            {
                no warnings 'redefine';
                local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport::current_inference = sub {
                    my $result = $original->(@_);
                    my ($child) = grep {$_ ne $p->{root}} keys %{$p->{rows}};
                    if ($source) {$p->{module}{parameters}{W}{value_payload}{payload} = '2'}
                    else {$p->{rows}{$child}{rendered_expression} = 'A'}
                    ++$fired;
                    return $result;
                };
                ok(!defined(selection($p)), 'late earlier child cache or source mutation withholds the selection');
            }
            ok($fired, 'the last-read mutation really executes');
        });
    }
};

done_testing();
