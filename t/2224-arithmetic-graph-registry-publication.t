use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(refaddr);
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
my $json = JSON::PP->new->canonical;
my $width_class = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport';
my $sync_class = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport';
sub events {
    my ($owner, $rows) = @_;
    my %records;
    for my $name (sort keys %$rows) {
        my $record = $owner->factorized_graph_inference_event($name, $rows->{$name});
        $records{$name} = $record if $record;
    }
    return \%records;
}
sub fixture {
    my ($expression, $width, %options) = @_;
    my $source = "(?fsm:graph_registry (+params (W $width))"
        . ' (+size (A (param W)) (B (param W)) (C (param W)) (D (param W)) (DATA 1) (OTHER 1))'
        . " (idle (<$expression (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
    my $module = FSM::Adapter::FSMGenFull->new->parse_fsm(scalar Lispish::multi(\$source));
    my $ctx = $options{ctx} // FSM::HDL::FlattenedDT->new;
    my $sync = $sync_class->can('sync_consolidated_signals_to_registry');
    my $finish = $width_class->can('_finish_graph_registry_copies');
    my $checkpoint = $width_class->can('_checkpoint_factorized_registry_copies');
    my (%observed, $error, $hdl);
    {
        no warnings 'redefine';
        no strict 'refs';
        local *{"${sync_class}::sync_consolidated_signals_to_registry"} = sub {
            my ($support, $rows) = @_;
            my $owner = $ctx->{backend_sv_intermediate_width_support};
            my $before = events($owner, $rows);
            $sync->(@_);
            if (keys %$before) {
                $observed{before} //= $before;
                $observed{after} = events($owner, $rows);
                $observed{rows} = $rows; # Keep the actual weak-view referent alive for these observations.
                $options{after_copy}->($support, $owner, $rows, \%observed)
                    if $options{after_copy} && !$observed{callback}++;
            }
        };
        local *{"${width_class}::_checkpoint_factorized_registry_copies"} = sub {
            my $result = $checkpoint->(@_);
            my ($owner, $rows) = @_;
            $options{after_checkpoint}->($owner, $rows)
                if $options{after_checkpoint} && $owner->{_width_inference_epoch} && !$observed{changed}++;
            return $result;
        };
        if ($finish) {
            local *{"${width_class}::_finish_graph_registry_copies"} = sub {
                my ($owner, $rows, $checkpoints, $installed) = @_;
                $options{before_finish}->($owner, $rows, $checkpoints, $installed)
                    if $options{before_finish} && keys %$checkpoints && !$observed{changed}++;
                return $finish->(@_);
            };
            eval {$hdl = $ctx->generate_systemverilog($module); 1} or $error = $@;
        } else {
            eval {$hdl = $ctx->generate_systemverilog($module); 1} or $error = $@;
        }
    }
    return {observed => \%observed, ctx => $ctx, error => $error, hdl => $hdl};
}
subtest 'actual registry rebuild restores transitive graph proof after all exact copies install' => sub {
    for my $expression ('(+ A B C)', '(+ A (* B C))', '(+ A (* B (+ C D)))', '(+ (+ A B C) (+ B C D))') {
        for my $width (1, 8) {
            my $p = fixture($expression, $width);
            is($p->{error}, undef, 'ordinary generation succeeds');
            ok(keys %{$p->{observed}{before} // {}}, 'current graph proof exists before actual registry reset');
            is_deeply($p->{observed}{after}, $p->{observed}{before}, 'all actual graph records survive exact installed registry copies');
        }
    }
};
subtest 'merged copies preserve and copied view maps cannot recreate qualification' => sub {
    plan skip_all => 'graph registry protocol absent' unless $width_class->can('_finish_graph_registry_copies');
    fixture('(+ A (* B (+ C D)))', 8, after_copy => sub {
        my ($support, $owner, $rows, $o) = @_;
        my $expected = events($owner, $rows);
        my ($name) = sort keys %$expected;
        my $prior = refaddr($owner->{flattened_dt}{intermediate_signals}{$name});
        $support->sync_consolidated_signals_to_registry($rows, 0);
        isnt(refaddr($owner->{flattened_dt}{intermediate_signals}{$name}), $prior, 'actual merged copy installs a new registry row');
        is_deeply(events($owner, $rows), $expected, 'owned merge preserves current transitive records');
        $support->sync_consolidated_signals_to_registry({%$rows}, 0);
        is_deeply(events($owner, $rows), {}, 'copied map cannot attest the current actual row-view boundary');
        $support->sync_consolidated_signals_to_registry($rows, 0);
        is_deeply(events($owner, $rows), {}, 'later matching copies cannot revive absent graph proof');
    });
};
subtest 'equal foreign replacements source writes and partial failures withhold' => sub {
    plan skip_all => 'graph registry protocol absent' unless $width_class->can('_finish_graph_registry_copies');
    for my $change (
        sub {my ($owner, $rows, $checkpoints) = @_; for my $name (keys %$checkpoints) {
            $owner->{flattened_dt}{intermediate_signals}{$name} = {%{$owner->{flattened_dt}{intermediate_signals}{$name}}};
        }},
        sub {my ($owner, $rows, $checkpoints) = @_; for my $name (keys %$checkpoints) {
            $owner->{flattened_dt}{intermediate_signals}{$name}{signed} = 1;
        }},
    ) {
        my $p = fixture('(+ A (* B C))', 8, before_finish => $change);
        ok($p->{observed}{changed}, 'unsupported actual registry mutation ran after installed identities were witnessed');
        is_deeply($p->{observed}{after}, {}, 'equal copied rows or added constraints cannot refresh proof');
    }
    my $source = fixture('(+ A (* B C))', 8, after_checkpoint => sub {
        my ($owner) = @_;
        my $a = $owner->{flattened_dt}{fsm_module}->signals->{A};
        $a->set_attribute('width_declared', $a->get_attribute('width_declared'));
    });
    is_deeply($source->{observed}{after}, {}, 'matching source write after checkpoint invalidates graph restoration');
    my $failed = fixture('(+ A (* B C))', 8, before_finish => sub {die "graph registry controlled failure\n"});
    like($failed->{error}, qr/graph registry controlled failure/, 'registry finish failure propagates');
    is_deeply($failed->{ctx}{backend_sv_intermediate_width_support}{_graph_inference_events}, {}, 'collector failure clears partial graph holders');
    my $retry = fixture('(+ A (* B C))', 8, ctx => $failed->{ctx});
    is($retry->{error}, undef, 'actual failed backend can generate afresh');
    is_deeply($retry->{observed}{after}, $retry->{observed}{before}, 'fresh graph proofs qualify after reuse');
};
done_testing();
