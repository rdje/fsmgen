use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(refaddr);
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::Backend::VerilogFamily::DeclarationCapture;
use FSM::IntermediateWidthGraphPolicySupport;

my $json = JSON::PP->new->canonical;
my $branched = '(+ (+ A B C) (+ B C A))';
my $deep = '(+ A (* B (+ A C)))';

sub generate {
    my ($expression, $width, %options) = @_;
    my $source = "(?fsm:graph_closure (+params (W $width))"
        . ' (+size (A (param W)) (B (param W)) (C (param W)) (DATA 1) (OTHER 1))'
        . " (idle (<$expression (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
    my $module = FSM::Adapter::FSMGenFull->new->parse_fsm(scalar Lispish::multi(\$source));
    my $ctx = $options{ctx} // FSM::HDL::FlattenedDT->new;
    my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
    my $snapshot_method = $capture->can('snapshot');
    my ($hdl, $error, $before, $after, $mutations);
    {
        no warnings 'redefine';
        local *FSM::Backend::VerilogFamily::DeclarationCapture::snapshot = sub {
            my ($self) = @_;
            my $snapshot = $snapshot_method->(@_);
            return $snapshot unless refaddr($self) == refaddr($capture);
            $before = $json->encode($snapshot);
            if ($options{mutate}) {
                $options{mutate}->($snapshot);
                ++$mutations;
            }
            # A public snapshot is detached: changing the consumer's input
            # must not modify the collector which produced it.
            $after = $json->encode($snapshot_method->($self));
            return $snapshot;
        };
        local $ctx->{declared_width_declaration_capture} = $capture;
        eval {
            $hdl = $width == 1 ? $ctx->generate_verilog($module) : $ctx->generate_systemverilog($module);
            1;
        } or $error = $@;
    }
    return {ctx => $ctx, capture => $capture, hdl => $hdl, error => $error,
        snapshot => $error ? undef : $capture->snapshot,
        before => $before, after => $after, mutations => $mutations // 0};
}

sub graph_names {
    my ($snapshot) = @_;
    return sort {
        my $a_leaves = FSM::IntermediateWidthGraphPolicySupport->leaf_names(
            $snapshot->{target_intermediates}{$a}{graph_width_allocation});
        my $b_leaves = FSM::IntermediateWidthGraphPolicySupport->leaf_names(
            $snapshot->{target_intermediates}{$b}{graph_width_allocation});
        @$b_leaves <=> @$a_leaves || $a cmp $b;
    } grep {$snapshot->{target_intermediates}{$_}{graph_width_allocation}}
        keys %{$snapshot->{target_intermediates}};
}

subtest 'deep and multiple-child actual graphs emit every selected generic range' => sub {
    for my $expression ($branched, $deep) {
        for my $width (1, 8) {
            my $p = generate($expression, $width);
            is($p->{error}, undef, 'actual Verilog-family generation succeeds') or diag $p->{error};
            next if $p->{error};
            my @names = graph_names($p->{snapshot});
            is(scalar @names, $expression eq $branched ? 3 : 2,
                'actual selected graph children and root are all present');
            for my $name (@names) {
                like($p->{hdl}, qr/^  wire \[\(W - 1\):0\] \Q$name\E;$/m,
                    'actual graph target has its canonical W range');
            }
            like($p->{hdl}, qr/^  assign idle_data_1_en = idle_en && \Q$names[0]\E;/m,
                'whole-value gating is independent of the selected default');
            is($p->{before}, $p->{after}, 'completed collector snapshot stays exact');
        }
    }
};

my @changes = (
    ['selected child text', sub {
        my ($s) = @_; my (undef, $child) = graph_names($s);
        $s->{target_intermediates}{$child}{expression} .= ' + 0';
    }],
    ['selected child original tree', sub {
        my ($s) = @_; my (undef, $child) = graph_names($s);
        $s->{target_intermediates}{$child}{graph_width_allocation}{expression_tree}[0] = '-';
    }],
    ['missing selected child record', sub {
        my ($s) = @_; my (undef, $child) = graph_names($s);
        delete $s->{target_intermediates}{$child};
    }],
    ['missing selected root allocation', sub {
        my ($s) = @_; my ($root) = graph_names($s);
        delete $s->{target_intermediates}{$root}{graph_width_allocation};
    }],
);

subtest 'late selected child and root changes return neither artifact nor completed capture' => sub {
    for my $case (@changes) {
        my ($label, $change) = @$case;
        my $p = generate($branched, 8, mutate => $change);
        is($p->{mutations}, 1, "$label reaches the actual final snapshot input");
        ok($p->{error}, "$label refuses independent final proof");
        is($p->{hdl}, undef, "$label returns no HDL");
        ok(!eval {$p->{capture}->snapshot; 1}, "$label invalidates completed capture");
        is($p->{before}, $p->{after}, "$label never changes the original detached collector data");
        my $retry = generate($deep, 1, ctx => $p->{ctx});
        is($retry->{error}, undef, "$label permits fresh same-backend recovery") or diag $retry->{error};
    }
};

done_testing();
