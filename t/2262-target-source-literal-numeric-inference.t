use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(refaddr);
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport;

my $class = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport';
my $json = JSON::PP->new->canonical;
sub probe {
    my (%args) = @_;
    my $bits = $args{bits} // 8;
    my $slot = $args{mutable} ? '(param W)' : $bits;
    my $literal = $args{explicit} ? "9'b100000000" : '256';
    my $header = $args{mutable} ? "(+params (W $bits))" : '';
    my $text = "(?fsm:literal_numeric $header"
        ." (+size (A $slot) (B $slot) (C 16) (DATA 1) (OTHER 1))"
        ." (idle (<(^ (| A B $literal) C) (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
    my $raw = scalar Lispish::multi(\$text);
    my $before = $json->encode($raw);
    my $module = FSM::Adapter::FSMGenFull->new->parse_fsm($raw);
    my $backend = FSM::HDL::FlattenedDT->new;
    my $normalizer = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateNormalizationSupport';
    my $normalize = $normalizer->can('_normalize_metadata');
    my $p = {module => $module, backend => $backend, text => $text};
    {
        no warnings 'redefine';
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateNormalizationSupport::_normalize_metadata = sub {
            my ($self, $rows) = @_;
            $p->{rows} = $rows;
            $p->{owner} = $backend->{backend_sv_intermediate_width_support};
            $args{before}->($p) if $args{before};
            my $result = $normalize->(@_);
            $args{after}->($p) if $args{after};
            die "numeric observation complete\n" if $args{stop};
            return $result;
        };
        $p->{ok} = eval {$p->{hdl} = $backend->generate_systemverilog($module); 1};
        $p->{error} = $@;
    }
    is($json->encode($raw), $before, 'complete original caller and parameter kinds conserve');
    return $p;
}
sub root_name {
    my ($p, $operator) = @_;
    return (grep {$p->{module}->signals->{$_}->driving_ast->operator eq $operator} keys %{$p->{rows}})[0];
}
sub observe {
    my ($p, $name, $row) = @_;
    return unless $class->can('prepare_inference');
    return $class->prepare_inference(width_support => $p->{owner}, signal_name => $name,
        signal_info => $row // $p->{rows}{$name}, signal_registry => $p->{rows});
}

subtest 'actual fixed helpers select target widths before nominal Core child and native metadata' => sub {
    for my $bits (1, 8, 64) {for my $explicit (0, 1) {
        my $p = probe(bits => $bits, explicit => $explicit);
        ok($p->{ok}, 'ordinary generation succeeds') or diag $p->{error};
        next unless $p->{ok};
        my $floor = $explicit ? 9 : 32;
        my $child_width = $bits > $floor ? $bits : $floor;
        my $parent_width = $child_width > 16 ? $child_width : 16;
        for my $case (['|', $child_width], ['^', $parent_width]) {
            my ($op, $width) = @$case;
            my $name = root_name($p, $op);
            is($p->{rows}{$name}{width}, $width, 'actual numeric width keeps literal and independent floors');
            is($p->{rows}{$name}{width_source}, 'source_literal_intent', 'qualified source observation precedes compatibility branches');
            like($p->{hdl}, qr/^  wire \[\Q@{[$width - 1]}\E:0\] \Q$name\E;$/m, 'actual emitted wire keeps every selected bit');
        }
        my $child = root_name($p, '|');
        my $root = root_name($p, '^');
        like($p->{hdl}, qr/^  assign \Q$root\E = \Q$child\E \^ C;/m, 'actual nested expression references its owned child');
        # Independent finite mask algebra distinguishes parent truncation from
        # merely widening the child. No simulator or compiler runs here.
        my $width = $p->{rows}{$root}{width};
        ok($width >= 9 && (256 & ((1 << ($width < 32 ? $width : 31)) - 1)) == 256,
            'the high-bit witness survives the actual selected parent declaration');
        is($p->{module}->signals->{$child}->width, $explicit ? ($bits > 9 ? $bits : 9) : 1,
            'backend sizing never changes Core source allocation width');
    }}
};

subtest 'mutable default-one and wide sources use the same numeric observation before final declaration work' => sub {
    for my $bits (1, 64) {
        my $p = probe(bits => $bits, mutable => 1, stop => 1, after => sub {
            my ($p) = @_;
            my $root = root_name($p, '^');
            my $o = observe($p, $root);
            ok($o, 'actual normalized row has fresh source/target numeric observation') or return;
            is($o->{observation}{selected_width}, $bits > 32 ? $bits : 32, 'numeric inference preserves both independent sources');
            is_deeply($o->{observation}{source_capsule}, $p->{module}->signals->{$root}{_source_literal_width_allocation},
                'complete original source capsule and mutable binding kinds conserve');
            is($p->{owner}->resolve_ast_signal_ref_width(root_name($p, '|'), $p->{rows}), $bits > 32 ? $bits : 32,
                'actual reference resolver consumes target row before Core placeholder');
        });
        like($p->{error}, qr/numeric observation complete/, 'probe stops before generic/final declaration obligations');
    }
};

subtest 'row registry epoch owner source and independent constraints cannot borrow numeric authority' => sub {
    my @changes = (
        sub {my ($p,$n)=@_;$p->{rows}{$n}={%{$p->{rows}{$n}}}},
        sub {my ($p,$n)=@_;$p->{backend}{intermediate_signals}{$n}={%{$p->{backend}{intermediate_signals}{$n}}}},
        sub {$_[0]{owner}{_width_inference_epoch}++},
        sub {my ($p,$n)=@_;$p->{rows}{$n}{constraints}=['independent']},
        sub {my ($p,$n)=@_;$p->{rows}{$n}{width}=7},
        sub {my ($p,$n)=@_;$p->{rows}{$n}{width_source}='foreign'},
        sub {my ($p,$n)=@_;$p->{module}->signals->{$n}->set_attribute('is_intermediate',1)},
        sub {my ($p,$n)=@_;delete $p->{module}->signals->{$n}{_source_literal_width_allocation}},
        sub {my ($p,$n)=@_;$p->{module}->signals->{A}=FSM::CoreAST::Signal->new(name=>'A',width=>8)},
        sub {$_[0]{backend}{backend_sv_intermediate_width_support} = $_[0]{owner}->new(flattened_dt => $_[0]{backend})},
    );
    for my $change (@changes) {
        probe(stop => 1, after => sub {
            my $p = shift;
            my $name = root_name($p, '^');
            my $row = $p->{rows}{$name};
            my $saved = observe($p,$name);
            ok($saved,'actual baseline numeric join exists') or return;
            $change->($p,$name);
            my $current = $class->current_inference(width_support => $p->{owner}, signal_name => $name,
                signal_info => $row, signal_registry => $p->{rows}, observation => $saved);
            ok(!defined $current, 'changed source row registry constraint or owner withholds saved authority');
        });
    }
};

subtest 'numeric data detaches and late target changes cannot escape the source recheck' => sub {
    ok($class->can('prepare_inference'), 'numeric inference boundary exists') or return;
    probe(stop => 1, after => sub {
        my $p = shift;
        my $name = root_name($p, '^');
        my $saved = observe($p, $name);
        ok($saved, 'current actual numeric observation exists') or return;
        ok(eval {$json->encode($saved); 1}, 'returned frame has no live source or registry owners');
        my $copy = $json->decode($json->encode($saved));
        $copy->{observation}{selected_width} = JSON::PP::true;
        ok(!defined($class->current_inference(width_support => $p->{owner}, signal_name => $name,
            signal_info => $p->{rows}{$name}, signal_registry => $p->{rows}, observation => $copy)),
            'Boolean width cannot impersonate numeric authority');
        is_deeply(observe($p, $name), $saved, 'editing escaped data cannot change current observation');
        my $current = $class->can('current');
        my $fired = 0;
        {
            no warnings 'redefine';
            local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::SourceLiteralWidthSupport::current = sub {
                my $result = $current->(@_);
                $p->{rows}{$name}{signed} = 1;
                ++$fired;
                return $result;
            };
            ok(!defined(observe($p, $name)), 'target constraint added at the last source recheck withholds');
        }
        ok($fired, 'late target mutation really executes');
    });
    my $backend = FSM::HDL::FlattenedDT->new;
    my $owner = $backend->{backend_sv_intermediate_width_support};
    my @keys = sort keys %$backend;
    ok(!defined($class->prepare_inference(width_support => $owner, signal_name => 'absent',
        signal_info => {}, signal_registry => {})), 'missing source context withholds');
    is_deeply([sort keys %$backend], \@keys, 'failed observation never autovivifies source context');
};

done_testing();
