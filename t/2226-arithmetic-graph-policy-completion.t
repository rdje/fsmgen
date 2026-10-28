use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
my $json = JSON::PP->new->canonical;
my $width_class = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport';
my $build_class = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediatePreparedBlockSupport';
my $render_class = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateRenderingSupport';
my $has_policy = $width_class->can('factorized_graph_width_allocation');
sub fixture {
    my ($expression, $width, %options) = @_;
    my $input = "(?fsm:graph_policy (+params (W $width))"
        . ' (+size (A (param W)) (B (param W)) (C (param W)) (D (param W)) (DATA 1) (OTHER 1))'
        . " (idle (<$expression (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
    my $module = FSM::Adapter::FSMGenFull->new->parse_fsm(scalar Lispish::multi(\$input));
    my $ctx = $options{ctx} // FSM::HDL::FlattenedDT->new;
    my $complete = $width_class->can('_complete_factorized_width_inference');
    my $build = $build_class->can('build_prepared_consolidated_intermediate_block');
    my $render = $render_class->can('render_prepared_consolidated_intermediate_block');
    my (%observed, $block, $error, $hdl);
    my $snapshot = sub {
        my ($owner, $rows) = @_;
        my (%intrinsic, %policy);
        for my $name (sort keys %$rows) {
            my $r = $owner->factorized_graph_inference_event($name, $rows->{$name});
            next unless $r;
            $intrinsic{$name} = $r;
            $policy{$name} = scalar($owner->factorized_graph_width_allocation($name, $rows->{$name}));
        }
        return {intrinsic => \%intrinsic, policy => \%policy};
    };
    {
        no warnings 'redefine';
        no strict 'refs';
        local *{"${width_class}::_complete_factorized_width_inference"} = sub {
            my ($owner, $rows) = @_;
            $observed{before} = $snapshot->($owner, $rows);
            $options{before_complete}->($owner, $rows, \%observed) if $options{before_complete};
            die "graph controlled collection failure\n" if $options{fail_collection};
            $complete->(@_);
            $observed{after} = $snapshot->($owner, $rows);
            $options{after_complete}->($owner, $rows, \%observed) if $options{after_complete};
        };
        local *{"${build_class}::build_prepared_consolidated_intermediate_block"} = sub {
            my $r = $build->(@_);
            $block = $r if $options{retain_block};
            return $r;
        };
        local *{"${render_class}::render_prepared_consolidated_intermediate_block"} = sub {
            die "graph controlled post-completion failure\n" if $options{fail_render};
            return $render->(@_);
        };
        eval {$hdl = $ctx->generate_systemverilog($module); 1} or $error = $@;
    }
    return {ctx => $ctx, observed => \%observed, block => $block, error => $error, hdl => $hdl};
}
subtest 'actual collection completion alone exposes separate current graph policy' => sub {
    for my $expression ('(+ A B C)', '(+ A (* B (+ C D)))', '(+ (+ A B C) (+ B C D))') {
        for my $width (1, 8) {
            my $p = fixture($expression, $width, retain_block => 1);
            is($p->{error}, undef, 'ordinary collection and generation succeed');
            return unless $has_policy;
            my $before = $p->{observed}{before};
            ok(keys %{$before->{intrinsic}}, 'held intrinsic graph events precede completion');
            is_deeply([values %{$before->{policy}}], [(undef) x scalar(keys %{$before->{policy}})],
                'current intrinsic events supply no early completed policy');
            my $after = $p->{observed}{after};
            is_deeply($after->{policy}, $after->{intrinsic}, 'successful actual completion publishes current graph policy');
            is_deeply($after->{intrinsic}, $before->{intrinsic}, 'completion does not replace original intrinsic intent');
            my $owner = $p->{ctx}{backend_sv_intermediate_width_support};
            for my $name (sort keys %{$after->{policy}}) {
                my $info = $p->{block}{all_intermediate_signals}{$name};
                is_deeply($owner->factorized_graph_width_allocation($name, $info), $after->{policy}{$name},
                    'actual prepared ownership preserves completed current policy');
                is($owner->intermediate_width_allocation($name, $info), undef, 'ordinary allocation API retains its whole-reference profile');
                is($owner->factorized_graph_width_allocation($name, {%$info}), undef, 'equal copied metadata cannot borrow policy');
                my $copy = $owner->factorized_graph_width_allocation($name, $info);
                $copy->{expression_tree}[0] = 'WRONG';
                is_deeply($owner->factorized_graph_width_allocation($name, $info), $after->{policy}{$name}, 'completed record detaches');
            }
            delete $p->{block};
            is($owner->_current_graph_inference_rows, undef, 'dropping last prepared owner expires the current policy view');
        }
    }
};
subtest 'stale sources result floors and failed transactions expose no graph policy' => sub {
    plan skip_all => 'completed graph API absent' unless $has_policy;
    for my $change (
        sub {my ($owner) = @_; my $a = $owner->{flattened_dt}{fsm_module}->signals->{A};
            $a->set_attribute('width_declared', $a->get_attribute('width_declared'));},
        sub {my ($owner, $rows, $o) = @_; my ($name) = keys %{$o->{before}{intrinsic}}; $rows->{$name}{width} = 32;},
    ) {
        my $p = fixture('(+ A (* B C))', 8, before_complete => $change, retain_block => 1);
        is_deeply($p->{observed}{after}{policy}, {}, 'unowned changes prune stale graph proof before completion');
        my $owner = $p->{ctx}{backend_sv_intermediate_width_support};
        for my $name (keys %{$p->{observed}{before}{intrinsic}}) {
            is($owner->factorized_graph_width_allocation($name, $p->{block}{all_intermediate_signals}{$name}), undef,
                'completion flag cannot turn a stale graph into current policy');
        }
    }
    for my $kind ('fail_collection', 'fail_render') {
        my $p = fixture('(+ A (* B C))', 8, $kind => 1, retain_block => 1);
        like($p->{error}, qr/graph controlled (?:collection|post-completion) failure/, 'original generation failure propagates');
        my $owner = $p->{ctx}{backend_sv_intermediate_width_support};
        ok(!exists($owner->{_width_inference_complete}), 'failed generation clears completion');
        is_deeply($owner->{_graph_inference_events}, {}, 'failed generation clears graph holders');
        my $retry = fixture('(+ A (* B C))', 8, ctx => $p->{ctx}, retain_block => 1);
        is($retry->{error}, undef, 'actual failed backend can generate afresh');
        is_deeply($retry->{observed}{after}{policy}, $retry->{observed}{after}{intrinsic}, 'fresh actual completion qualifies new policy');
    }
};
subtest 'supported writes and later generations revoke retained completed policy' => sub {
    plan skip_all => 'completed graph API absent' unless $has_policy;
    my $p = fixture('(+ A (* B C))', 8, retain_block => 1);
    my $owner = $p->{ctx}{backend_sv_intermediate_width_support};
    my ($name) = keys %{$p->{observed}{after}{policy}};
    my $info = $p->{block}{all_intermediate_signals}{$name};
    my $a = $p->{ctx}{fsm_module}->signals->{A};
    $a->set_attribute('width_declared', $a->get_attribute('width_declared'));
    is($owner->factorized_graph_width_allocation($name, $info), undef, 'matching supported source write revokes completed graph policy');
    my $q = fixture('(+ A (* B C))', 1, ctx => $p->{ctx}, retain_block => 1);
    is($q->{error}, undef, 'fresh later generation succeeds while earlier block remains owned');
    is_deeply($q->{observed}{after}{policy}, $q->{observed}{after}{intrinsic}, 'later epoch publishes its actual policy');
    is($owner->factorized_graph_width_allocation($name, $info), undef, 'old retained row cannot borrow the later completion');
    $owner->_abort_factorized_width_inference;
    for my $current (keys %{$q->{observed}{after}{policy}}) {
        is($owner->factorized_graph_width_allocation($current, $q->{block}{all_intermediate_signals}{$current}), undef,
            'explicit reset clears otherwise retained current policy');
    }
};
done_testing();
