use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::Backend::VerilogFamily::DeclarationCapture;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport;

my $class = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport';
my $json = JSON::PP->new->canonical;
unless ($class->can('prepare_targets') && $class->can('current_targets')) {
    fail('complete literal selected target proof exists');
    done_testing();
    exit;
}
sub copy {return $json->decode($json->encode($_[0]))}
sub targets {
    my ($p, $saved, %override) = @_;
    my %args = (width_support => $p->{owner}, signal_name => $p->{root},
        signal_info => $p->{rows}{$p->{root}}, signal_registry => $p->{rows},
        expression => $p->{expression}, target_language => 'systemverilog',
        %{$p->{snapshot}}, %override);
    return defined($saved) ? $class->current_targets(%args, observation => $saved)
        : $class->prepare_targets(%args);
}
sub fixture {
    my (%args) = @_;
    my $w = $args{w} // 1;
    my $x = $args{x} // 1;
    my $params = $args{fixed} ? '' : "(+params (W $w) (X $x))";
    my $sizes = $args{fixed} ? '(A 8) (B 64)' : '(A (param W)) (B (param X))';
    my $literal = $args{explicit} ? "9'b100000000" : '256';
    my $expr = $args{direct} ? "(| A $literal)" : "(^ (| A $literal) B)";
    $expr = "(^ (| A $literal) A)" if $args{repeat};
    my $text = "(?fsm:literal_targets $params (+size $sizes (DATA 1) (OTHER 1))"
        ." (idle (<$expr (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
    my $raw = scalar Lispish::multi(\$text);
    my $input = $json->encode($raw);
    my $module = FSM::Adapter::FSMGenFull->new->parse_fsm($raw);
    my $ctx = FSM::HDL::FlattenedDT->new;
    my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
    my $normalize = FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateNormalizationSupport
        ->can('_normalize_metadata');
    my $symbolic = FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateDeclarationSupport
        ->can('_source_bitwise_uses_symbolic');
    my $complete = FSM::Backend::VerilogFamily::DeclarationCapture->can('complete');
    my ($p, $observed);
    {
        no warnings 'redefine';
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateNormalizationSupport::_normalize_metadata = sub {
            my ($self, $rows) = @_;
            my $result = $normalize->(@_);
            my ($root) = grep {$module->signals->{$_}
                && $module->signals->{$_}->driving_ast->operator eq ($args{direct} ? '|' : '^')}
                keys %$rows;
            $p = {ctx => $ctx, module => $module, rows => $rows, root => $root,
                owner => $ctx->{backend_sv_intermediate_width_support}};
            my $recovery = $ctx->{backend_sv_intermediate_recovery_support};
            $p->{expression} = $recovery->render_intermediate_signal_expression($root, $rows->{$root});
            return $result;
        };
        # Private mutable record-contract seam: skip the old symbolic source-tree
        # selector only. Actual numeric emitters and final Core agreement stay
        # installed. This is deliberately not successful generic generation.
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateDeclarationSupport::_source_bitwise_uses_symbolic = sub {
            return 0 unless $args{fixed};
            return $symbolic->(@_);
        };
        my $binary = FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateDeclarationSupport
            ->can('_binary_symbolic_range');
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateDeclarationSupport::_binary_symbolic_range = sub {
            return unless $args{fixed};
            return $binary->(@_);
        };
        local *FSM::Backend::VerilogFamily::DeclarationCapture::complete = sub {
            $complete->(@_);
            $p->{snapshot} = $_[0]->snapshot;
            ++$observed;
            $args{check}->($p);
        };
        local $ctx->{declared_width_declaration_capture} = $capture;
        my $hdl = eval {$ctx->generate_systemverilog($module)};
        if ($args{fixed}) {
            ok(defined($hdl), 'ordinary fixed numeric generation succeeds') or diag($@);
        } elsif (!$args{mutating}) {
            ok(defined($hdl), 'literal generation closes independent final source/target agreement') or diag($@);
        } elsif ($args{mutating}) {
            ok(!defined($hdl) && length($@), 'mutated source still returns no qualified HDL');
        }
    }
    is($observed, 1, 'complete actual declaration/assignment transaction observed once');
    is($json->encode($raw), $input, 'original caller literal and parameter kinds conserve');
}

subtest 'actual fixed and private mutable records join every selected helper and original leaf' => sub {
    for my $fixed (0, 1) {for my $direct (0, 1) {for my $explicit (0, 1) {
        fixture(fixed => $fixed, direct => $direct, explicit => $explicit, check => sub {
            my $p = shift;
            my $before = $json->encode($p->{snapshot});
            my $source = $class->can('_range_source_frame')->($p->{ctx});
            my $plan = targets($p);
            ok($plan, 'complete actual literal target proof prepares') or return;
            is_deeply(targets($p, $plan), $plan, 'saved target proof rederives before caller inspection');
            is($plan->{kind}, 'systemverilog_source_literal_targets', 'physical proof has a distinct contract');
            my $width = $direct ? ($explicit ? 9 : 32) : ($fixed ? 64 : ($explicit ? 9 : 32));
            is($plan->{width}, "$width", 'literal and independent leaf algebra controls physical root width');
            is(scalar(@{$plan->{node_order}}), $direct ? 1 : 2, 'every physical child is inventoried');
            is($plan->{node_order}[-1], $p->{root}, 'children precede parent');
            my $literal_name = $plan->{node_order}[0];
            my $literal_text = $explicit ? "A | 9'b100000000" : 'A | 256';
            is($plan->{nodes}{$literal_name}{event}{expression}, $literal_text,
                'literal child matches independently authored target expression');
            if (!$direct) {
                is_deeply($plan->{nodes}{$p->{root}}{event}{bitwise_origin},
                    {kind => 'binary_bitwise', operator => '^', source_names => [$literal_name, 'B']},
                    'parent retains independently declared child/leaf operand order');
            }
            for my $name (@{$plan->{node_order}}) {
                my $node = $plan->{nodes}{$name};
                is($node->{target_name}, $name, 'actual physical helper is unrenamed');
                my $expected_width = "$node->{numeric}{observation}{selected_width}";
                is($node->{declaration}{width}, 0 + $expected_width,
                    'each actual child declaration agrees with its independent maximum');
                is_deeply($node->{event}, $p->{snapshot}{target_intermediates}{$name},
                    'complete actual event agrees, including its own syntactic family');
            }
            is(defined($plan->{selection}{range}) ? 1 : 0, $fixed ? 0 : 1,
                'original generic operands remain separate from fixed numeric records');
            is_deeply(targets($p, $plan), $plan, 'saved target proof rederives in full');
            is($json->encode($p->{snapshot}), $before, 'whole target input and raw kinds conserve');
            is($class->can('_range_source_frame')->($p->{ctx}), $source, 'whole original source conserves');
            $plan->{nodes}{$p->{root}}{event}{expression} = 'foreign';
            ok(!defined(targets($p, $plan)), 'escaped detached record grants no saved authority');
            ok(targets($p), 'escaped output cannot change actual source/target proof');
        });
    }}}
    fixture(w => 8, x => 128, check => sub {
        my $plan = targets(shift);
        is($plan->{width}, '128', 'wider independent mutable leaf is never a helper placeholder');
        like($plan->{selection}{range}{range_text}, qr/\bW\b.*\bX\b/s,
            'independent generic names survive their selected defaults');
    });
    fixture(repeat => 1, check => sub {
        my $plan = targets(shift);
        ok($plan, 'repeated source expression prepares') or return;
        is(scalar(@{$plan->{selection}{numeric}{observation}{leaves}}), 2,
            'both authored leaf occurrences remain in complete source intent');
        is(scalar(@{$plan->{leaf_targets}}), 2, 'physical leaf join preserves duplicate occurrences');
    });
};

subtest 'missing changed conflicting or foreign target rows cannot borrow selected text' => sub {
    fixture(check => sub {
        my $p = shift;
        my $baseline = targets($p);
        ok($baseline, 'baseline target proof prepares') or return;
        my ($child) = grep {$_ ne $p->{root}} @{$baseline->{node_order}};
        for my $change (
            sub {delete $_[0]{target_intermediates}{$child}},
            sub {$_[0]{target_intermediates}{$child} = {}},
            sub {$_[0]{target_intermediates}{$child}{expression} = 'A'},
            sub {$_[0]{target_intermediates}{$p->{root}}{bitwise_origin}{source_names} = ['B', $child]},
            sub {delete $_[0]{target_intermediates}{$p->{root}}{bitwise_origin}},
            sub {$_[0]{target_intermediates}{$child}{reduction_origin} = {kind => 'scalar_reduction', operator => '|', source_name => 'A'}},
            sub {$_[0]{target_intermediates}{$child}{width_allocation} = {}},
            sub {$_[0]{target_intermediates}{A} = {expression => 'A'}},
            sub {$_[0]{target_intermediates}{UNDECLARED} = {expression => 'A'}},
            sub {$_[0]{target_declarations}{$child}{width} = 1},
            sub {$_[0]{target_declarations}{$child}{signed} = 1},
            sub {$_[0]{target_declarations}{$child}{state_model} = 'foreign'},
            sub {$_[0]{target_declarations}{$child}{declared_type_name} = 'foreign'},
            sub {$_[0]{target_declarations}{$child}{width_origin} = {kind => 'register_next', source_name => 'A'}},
            sub {$_[0]{target_declarations}{A}{width} = 2},
            sub {$_[0]{target_declarations}{A}{signed} = 1},
            sub {$_[0]{target_namespace}{identifier_map}{$child} = 'B'},
            sub {my $s = shift; @{$s->{target_namespace}{signals}} = grep {$_ ne $child} @{$s->{target_namespace}{signals}};
                push @{$s->{target_namespace}{ports}}, $child},
            sub {delete $_[0]{target_declarations}{$child}},
        ) {
            local $p->{snapshot} = copy($p->{snapshot});
            $change->($p->{snapshot});
            my $before = $json->encode($p->{snapshot});
            ok(!defined(targets($p)), 'incoherent complete physical target refuses');
            is($json->encode($p->{snapshot}), $before, 'failed proof preserves original input kinds');
        }
        local $p->{rows}{$child} = {%{$p->{rows}{$child}}};
        ok(!defined(targets($p, $baseline)), 'matching copied canonical child row cannot reuse authority');
    });
};

subtest 'last source recheck cannot hide earlier target source or owner changes' => sub {
    my @changes = (
        sub {$_[0]{snapshot}{target_intermediates}{$_[1]}{expression} = 'late'},
        sub {$_[0]{snapshot}{target_declarations}{A}{width} = 2},
        sub {$_[0]{snapshot}{target_namespace}{identifier_map}{unused} = 'late'},
        sub {$_[0]{rows}{$_[1]}{rendered_expression} = 'late'},
        sub {$_[0]{module}{parameters}{W}{value_payload}{payload} = '2'},
        sub {$_[0]{owner}{_width_inference_epoch}++},
    );
    for my $index (0 .. $#changes) {
        my $change = $changes[$index];
        # The first three interventions corrupt only the detached proof input.
        # The actual collector is unchanged and native generation must succeed.
        fixture(mutating => $index >= 3, check => sub {
            my $p = shift;
            my $baseline = targets($p);
            ok($baseline, 'baseline whole target prepares') or return;
            my ($child) = grep {$_ ne $p->{root}} @{$baseline->{node_order}};
            my $current = $class->can('current_selection');
            my $fired = 0;
            {
                no warnings 'redefine';
                local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport::current_selection = sub {
                    my $result = $current->(@_);
                    $change->($p, $child);
                    ++$fired;
                    return $result;
                };
                ok(!defined(targets($p)), 'late mutation withholds complete physical proof');
            }
            ok($fired, 'last-source-read intervention executes');
        });
    }
};

done_testing();
