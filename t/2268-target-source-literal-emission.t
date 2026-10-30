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
unless ($class->can('prepare_emission') && $class->can('validate_emission')
    && $class->can('capture_generation_fence')) {
    fail('literal declaration and assignment emission ledger exists');
    done_testing();
    exit;
}

my $json = JSON::PP->new->canonical;
sub copy {return $json->decode($json->encode($_[0]))}
sub fixture {
    my (%args) = @_;
    my $w = $args{w} // 1;
    my $x = $args{x} // 1;
    my $params = $args{fixed} ? '' : "(+params (W $w) (X $x))";
    my $sizes = $args{fixed} ? '(A 8) (B 64)' : '(A (param W)) (B (param X))';
    my $literal = $args{unsized} ? '256' : $args{scalar_literal} ? "1'b1" : "9'b100000000";
    my $expr = $args{direct} ? "(| A $literal)" : "(^ (| A $literal) B)";
    $expr = "(^ (| A $literal) A)" if $args{repeat};
    $expr = "(& (| A $literal) (^ B $literal))" if $args{siblings};
    $expr = "(! $expr)" if $args{negated};
    my $text = "(?fsm:literal_emission $params (+size $sizes (DATA 1) (OTHER 1))"
        ." (idle (<$expr (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
    my $raw = scalar Lispish::multi(\$text);
    my $original = $json->encode($raw);
    my $module = FSM::Adapter::FSMGenFull->new->parse_fsm($raw);
    my $ctx = $args{ctx} // FSM::HDL::FlattenedDT->new;
    my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
    my $p = {ctx => $ctx, module => $module, capture => $capture};
    my $stage_class = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateStageSupport';
    my $tail_class = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationTailSupport';
    my $prepare = $stage_class->can('prepare_consolidated_intermediate_block');
    my $tail = $tail_class->can('generate_systemverilog_tail');
    my $record = FSM::Backend::VerilogFamily::DeclarationCapture->can('record_intermediate_assignment');
    my $targets = $class->can('prepare_targets');
    {
        no strict 'refs'; no warnings 'redefine';
        local *{"${stage_class}::prepare_consolidated_intermediate_block"} = sub {
            my $block = $prepare->(@_);
            $p->{rows} = $block->{filtered_signals};
            $p->{names} = [grep {$class->requires_emission($module->signals->{$_})}
                sort keys %{$p->{rows}}];
            $args{before}->($p, $block) if $args{before};
            return $block;
        };
        local *FSM::Backend::VerilogFamily::DeclarationCapture::record_intermediate_assignment = sub {
            return if $args{omit_event} && $_[1] eq $p->{names}[0];
            return $record->(@_);
        };
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport::prepare_targets = sub {
            my ($owner, %input) = @_;
            my $result = $targets->(@_);
            push @{$p->{proved}}, $input{signal_name} if $result;
            $args{after_target}->($p, $input{signal_name}) if $args{after_target};
            return $result;
        };
        local *{"${tail_class}::generate_systemverilog_tail"} = sub {
            $p->{declarations} = copy($ctx->{direct_declared_width_emitted_literal_ranges});
            $p->{assignments} = copy($ctx->{direct_declared_width_emitted_literal_assignments});
            for my $name (@{$p->{names}}) {
                my $ast = FSM::AST::BinaryOp->new('==', FSM::AST::SignalRef->new($name),
                    FSM::AST::Literal->new('0'));
                $p->{zero_tests}{$name} = $ctx->{enable_graph_ast_support}->ast_to_systemverilog($ast);
            }
            my $result = $tail->(@_);
            $args{late}->($p) if $args{late};
            return $result;
        };
        local $ctx->{declared_width_declaration_capture} = $capture;
        my $ok = eval {
            $p->{hdl} = $args{verilog} ? $ctx->generate_verilog($module) : $ctx->generate_systemverilog($module);
            1;
        };
        $p->{error} = $@ unless $ok;
    }
    is($json->encode($raw), $original, 'original caller literal and parameter kinds conserve');
    ok(!exists($ctx->{direct_declared_width_emitted_literal_ranges})
        && !exists($ctx->{direct_declared_width_emitted_literal_assignments}),
        'per-generation ledgers leave no backend residue');
    return $p;
}

sub refused {
    my ($p, $pattern) = @_;
    like($p->{error} // '', $pattern, 'distinguishing refusal identifies the failed contract');
    ok(!defined($p->{hdl}), 'failure returns no HDL');
    ok(!eval {$p->{capture}->snapshot; 1}, 'failure invalidates complete capture');
}

subtest 'actual fixed and mutable declarations consume independent literal and leaf floors' => sub {
    for my $fixed (0,1) {for my $direct (0,1) {for my $wide (0,1) {
        my $p = fixture(fixed => $fixed, direct => $direct, w => $wide ? 64 : 1,
            x => $wide ? 128 : 1, verilog => !$wide);
        is($p->{error}, undef, 'actual explicit-literal generation succeeds') or diag($p->{error});
        next if $p->{error};
        my $snapshot = $p->{capture}->snapshot;
        is_deeply([sort keys %{$p->{declarations}}], $p->{names}, 'all selected helpers emit declarations');
        is_deeply([sort keys %{$p->{assignments}}], $p->{names}, 'all selected helpers emit assignments');
        is_deeply([sort @{$p->{proved}}], $p->{names}, 'final proof independently covers every physical helper');
        for my $name (@{$p->{names}}) {
            my $entry = $p->{declarations}{$name};
            my $is_parent = $entry->{expression} !~ /100000000/;
            my $expected = $fixed ? ($is_parent ? 64 : 9) : $wide ? ($is_parent ? 128 : 64) : 9;
            is($snapshot->{target_declarations}{$name}{width}, $expected,
                'actual physical width matches independent source algebra');
            is($entry->{width}, "$expected", 'emitted literal width agrees');
            is($entry->{expression}, $p->{assignments}{$name}, 'declaration and assignment select the same expression');
            is($entry->{profile}, $fixed ? 'fixed' : 'symbolic', 'generic rank follows source dependencies');
            my $range = $entry->{range_text};
            like($p->{hdl}, qr/^  wire \Q$range$name\E;$/m, 'actual wire uses the complete recorded range');
            my $expression = $entry->{expression};
            like($p->{hdl}, qr/^  assign \Q$name = $expression;\E/m, 'actual assign uses the complete selected expression');
            if ($fixed) {
                is($range, '['.($expected - 1).':0] ', 'fixed range matches independent arithmetic');
            } else {
                like($range, qr/\bW\b/, 'original W dependency survives');
                like($range, qr/\bX\b/, 'parent retains independent X dependency') if $is_parent;
                like($range, qr/\b9\b/, 'explicit literal floor survives');
            }
        }
    }}}
    for my $option ('repeat', 'siblings') {
        my $p = fixture($option => 1);
        is($p->{error}, undef, 'repeated and sibling literal children generate') or diag($p->{error});
        is(scalar(keys %{$p->{declarations}}), $option eq 'repeat' ? 2 : 3,
            'physical inventory preserves distinct helpers without duplicating repeated edges');
    }
    for my $negated (0,1) {
        my $p = fixture(scalar_literal => 1, negated => $negated);
        is($p->{error}, undef, 'one-bit literal maximum generates beside scalar negation') or diag($p->{error});
        for my $name (@{$p->{names}}) {
            is($p->{declarations}{$name}{width}, '1', 'default maximum really is one');
            like($p->{declarations}{$name}{range_text}, qr/\bW\b/, 'one-bit default retains mutable vector rank');
            is($p->{zero_tests}{$name}, "(~|$name)", 'one-bit default guard remains a whole-value test');
        }
    }
};

subtest 'unsized mutable final Core agreement remains a separately owned refusal' => sub {
    my $fixed = fixture(fixed => 1, unsized => 1);
    is($fixed->{error}, undef, 'ordinary fixed unsized emission remains admitted') or diag($fixed->{error});
    ok(@{$fixed->{proved} // []}, 'fixed unsized literals now receive complete emission proof');
    for my $direct (0,1) {
        my $p = fixture(unsized => 1, direct => $direct);
        refused($p, qr/disagrees with observed source width or signedness/);
        is_deeply([sort @{$p->{proved}}], $p->{names}, 'literal ledger closes before unchanged Core-width refusal');
    }
};

subtest 'missing policy declaration or assignment cannot select a numeric fallback' => sub {
    my $p = fixture(before => sub {
        my $p = shift;
        delete $p->{module}{signals}{$p->{names}[0]}{_source_literal_width_allocation};
    });
    refused($p, qr/Direct literal emission requires current completed source intent/);
    refused(fixture(direct => 1, before => sub {
        my $p = shift;
        my $signal = $p->{module}{signals}{$p->{names}[0]};
        delete $signal->{_source_literal_width_allocation};
        $signal->{attributes}{is_intermediate} = 0;
    }), qr/Direct literal emission requires current completed source intent/);
    refused(fixture(omit_event => 1), qr/Direct literal emission requires complete current selected targets/);
    for my $change (
        sub {my $p = shift; delete $p->{ctx}{direct_declared_width_emitted_literal_ranges}{$p->{names}[0]}},
        sub {my $p = shift; $p->{ctx}{direct_declared_width_emitted_literal_ranges}{$p->{names}[0]}{range_text} = '[0:0] '},
        sub {my $p = shift; $p->{ctx}{direct_declared_width_emitted_literal_ranges}{$p->{names}[0]}{selection}{expression} = 'A'},
        sub {my $p = shift; $p->{ctx}{direct_declared_width_emitted_literal_ranges}{FOREIGN} = {}},
        sub {my $p = shift; delete $p->{ctx}{direct_declared_width_emitted_literal_assignments}{$p->{names}[0]}},
        sub {my $p = shift; $p->{ctx}{direct_declared_width_emitted_literal_assignments}{$p->{names}[0]} = 'A'},
    ) {
        my $bad = fixture(late => $change);
        refused($bad, qr/Direct literal emitted (?:declarations|assignments) disagree/);
        my $fresh = fixture(ctx => $bad->{ctx});
        is($fresh->{error}, undef, 'fresh same-backend generation recovers') or diag($fresh->{error});
    }
};

subtest 'final raw generation fence catches an earlier root changed after its last proof' => sub {
    for my $change (
        sub {my $p = shift; $p->{rows}{$p->{names}[0]}{rendered_expression} = 'late'},
        sub {my $p = shift; $p->{module}{signals}{$p->{names}[0]}{driving_ast}{operands}[0]{slice} = [0,0]},
        sub {my $p = shift; $p->{module}{signals}{A}->set_attribute('width_declared',
            $p->{module}{signals}{A}->get_attribute('width_declared'))},
        sub {my $p = shift; ++$p->{ctx}{backend_sv_intermediate_width_support}{_width_inference_epoch}},
    ) {
        my $fired = 0;
        my $p = fixture(fixed => 1, siblings => 1, after_target => sub {
            my ($p, $name) = @_;
            return unless $name eq $p->{names}[-1];
            $change->($p); ++$fired;
        });
        is($fired, 1, 'intervention follows the last complete target proof');
        refused($p, qr/Direct literal emission source changed during generation/);
    }
};

done_testing();
