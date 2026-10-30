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
sub observe {
    my ($p, $name, $saved) = @_;
    my %args = (width_support => $p->{owner}, signal_name => $name,
        signal_info => $p->{rows}{$name}, signal_registry => $p->{rows}, target_language => 'systemverilog');
    return defined($saved) ? $class->current_range(%args, observation => $saved) : $class->prepare_range(%args);
}
sub probe {
    my (%args) = @_;
    my $w = $args{w} // 1;
    my $x = $args{x} // 1;
    my $fixed = $args{fixed} // 16;
    my $literal = $args{explicit} ? "9'b100000000" : '256';
    my $text = "(?fsm:literal_range (+params (W $w) (X $x))"
        ." (+size (A (param W)) (B (param X)) (C $fixed) (DATA 1) (OTHER 1))"
        ." (idle (<(^ (| A B $literal) C) (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
    my $raw = scalar Lispish::multi(\$text);
    my $input = $json->encode($raw);
    my $module = FSM::Adapter::FSMGenFull->new->parse_fsm($raw);
    my $backend = FSM::HDL::FlattenedDT->new;
    my $normalizer = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateNormalizationSupport';
    my $normalize = $normalizer->can('_normalize_metadata');
    my $p = {module => $module, backend => $backend};
    {
        no warnings 'redefine';
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateNormalizationSupport::_normalize_metadata = sub {
            my ($self, $rows) = @_;
            my $result = $normalize->(@_);
            $p->{rows} = $rows;
            $p->{owner} = $backend->{backend_sv_intermediate_width_support};
            ($p->{root}) = grep {$module->signals->{$_}->driving_ast->operator eq '^'} keys %$rows;
            $args{check}->($p);
            die "range preparation complete\n";
        };
        eval {$backend->generate_systemverilog($module)};
        like($@, qr/range preparation complete/, 'focused observer stops before declaration integration');
    }
    is($json->encode($raw), $input, 'complete original caller and parameter kinds conserve');
}

subtest 'actual numeric frames join original independent mutable and fixed contracts' => sub {
    ok($class->can('prepare_range'), 'literal generic range preparation exists') or return;
    for my $values ([1, 1, 16], [8, 64, 16], [64, 8, 128]) {for my $explicit (0, 1) {
        probe(w => $values->[0], x => $values->[1], fixed => $values->[2], explicit => $explicit, check => sub {
            my $p = shift;
            my $before = FSM::DirectDeclaredWidthSupport->_capture_source_state($p->{backend});
            my $plan = observe($p, $p->{root});
            ok($plan, 'actual installed numeric/source frame prepares a generic range') or return;
            is(FSM::DirectDeclaredWidthSupport->_capture_source_state($p->{backend}), $before,
                'complete canonical source declarations and parameter maps conserve');
            is($plan->{kind}, 'systemverilog_source_literal_range', 'prepared range has its own bounded contract');
            is_deeply([map {$_->{source}{name}} @{$plan->{numeric}{observation}{leaves}}], [qw(A B C)],
                'original independent leaves exclude helper placeholders');
            is_deeply([map {$_->{width}} @{$plan->{operands}}], [@$values, $explicit ? 9 : 32],
                'mutable leaves, fixed leaf and literal floor remain independent and ordered');
            is($plan->{operands}[0]{width_contract}{expression}[1], 'W', 'first mutable source is W');
            is($plan->{operands}[1]{width_contract}{expression}[1], 'X', 'equal-default independent source remains X');
            ok(!defined($plan->{operands}[2]{width_contract}), 'fixed leaf never becomes a mutable helper dependency');
            like($plan->{range_text}, qr/\bW\b.*\bX\b/s, 'both actual mutable contracts appear in the prepared maximum');
            my $expected = $explicit ? 9 : 32;
            $expected = $_ > $expected ? $_ : $expected for @$values;
            is($plan->{width}, $expected, 'selected target width agrees with independent maximum algebra');
            is_deeply(observe($p, $p->{root}, $plan), $plan, 'fresh source/module/target state reproduces the range');
            my $escaped = $json->decode($json->encode($plan));
            $escaped->{operands}[-1]{width} = 1;
            ok(!defined(observe($p, $p->{root}, $escaped)), 'altered literal floor cannot impersonate the range');
            is_deeply(observe($p, $p->{root}), $plan, 'editing escaped data leaves source and current range unchanged');
        });
    }}
};

subtest 'source parameter namespace row epoch and independent constraints cannot borrow range authority' => sub {
    return unless $class->can('prepare_range');
    for my $change (
        sub {$_[0]{module}{parameters}{W}{value_payload}{payload} = '2'},
        sub {$_[0]{module}{_parameter_default_sources}{W}{source_module} = 'foreign'},
        sub {my $p = shift; $p->{module}{parameters} = {%{$p->{module}{parameters}}}},
        sub {$_[0]{owner}{_width_inference_epoch}++},
        sub {my $p = shift; $p->{rows}{$p->{root}}{constraints} = ['independent']},
        sub {$_[0]{module}->signals->{A}->set_attribute('width_declared', 1)},
        sub {delete $_[0]{module}->signals->{C}},
        sub {my $p = shift; $p->{rows}{$p->{root}} = {%{$p->{rows}{$p->{root}}}}},
    ) {
        probe(check => sub {
            my $p = shift;
            my $plan = observe($p, $p->{root});
            ok($plan, 'current actual baseline prepares') or return;
            $change->($p);
            ok(!defined(observe($p, $p->{root}, $plan)), 'changed source namespace or target cannot reuse saved range');
        });
    }
};

subtest 'final raw source barrier rejects late changes from source re-observation' => sub {
    return unless $class->can('prepare_range');
    probe(check => sub {
        my $p = shift;
        my $original = $class->can('current_inference');
        my $fired = 0;
        {
            no warnings 'redefine';
            local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport::current_inference = sub {
                my $result = $original->(@_);
                $p->{module}{parameters}{X}{value_payload}{payload} = '2';
                ++$fired;
                return $result;
            };
            ok(!defined(observe($p, $p->{root})), 'late parameter change after the numeric recheck withholds');
        }
        ok($fired, 'the late source mutation really executes');
    });
    probe(check => sub {
        my $p = shift;
        my $plan = $class->prepare_range(width_support => $p->{owner}, signal_name => $p->{root},
            signal_info => $p->{rows}{$p->{root}}, signal_registry => $p->{rows}, target_language => 'vhdl');
        ok(!defined($plan), 'foreign target receives no target literal range authority');
    });
};

done_testing();
