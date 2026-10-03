#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Storable qw(dclone);
use File::Temp qw(tempdir);
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::FormalIdentityPlan;
use FSM::Scheduler::ISF::FormalClauseResolver;
use FSM::Scheduler::ISF::FormalReservationInventory;

my $s = FSM::Scheduler::ISF->new;
my $l = $s->{ir};
my $work = tempdir(CLEANUP => 1);
sub parse {FSM::Adapter::ISF->new->parse_source($_[0], 'reusable_products.isf')}
sub file_actor {FSM::Adapter::ISF->new->parse_file($_[0])}
sub inventory {FSM::Scheduler::ISF::FormalReservationInventory->collect($_[0])->{reserved_names}}
sub project {
    my ($p) = @_;
    my $a = dclone($p->{actor});
    my $plan = FSM::Scheduler::ISF::FormalIdentityPlan->build($a,
        generated_children => $p->{generated_children}, reserved_names => inventory({map {$_ => $p->{$_}}
            qw(transaction_products parent_activation_products parent_wiring_products parent_point_products
                resource_signal_products generated_child_products parent_completion_products reusable_child_products)}));
    for my $tx (@{$a->{transactions}}) {
        next if $p->{pruned_transactions}{$tx->{name}};
        $tx = FSM::Scheduler::ISF::FormalClauseResolver->transaction($tx,
            plan => $plan, %{$p->{transactions}{$tx->{name}}})->{transaction};
    }
    return $a;
}
sub strict_child {
    my ($ir, $label) = @_;
    my $path = "$work/$label.fsm";
    open my $fh, '>', $path or die $!;
    print {$fh} $s->{fsm_emitter}->emit($ir);
    close $fh or die $!;
    my $r = FSM::Test::SourceQueryRunner::_capture([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $path], '');
    is($r->{exit_code}, 0, "$label strict child carrier") or diag($r->{stdout}, $r->{stderr});
}
sub actual_products {
    my ($ir, $generated) = @_;
    return {children => {map {$_ => $ir->{children}{$_}} grep {!$generated->{$_}} keys %{$ir->{children}}},
        library_uses => $ir->{library_uses}, atl_top_instances => $ir->{atl_top_instances}};
}
sub qualify {
    my ($actor, $label) = @_;
    my $before = dclone($actor);
    my $p = $l->prepare_formal_source($actor);
    my $r = $p->{reusable_child_products};
    is_deeply($r, actual_products($l->build_module($actor), $p->{generated_children}), "$label complete real child and composition products agree");
    my $physical = project($p);
    is_deeply(actual_products($l->build_module($physical), $p->{generated_children}), $r, "$label formal projection preserves reusable modules and bindings");
    is_deeply($l->prepare_formal_source($physical)->{reusable_child_products}, $r, "$label re-preparation retains actual reusable products");
    for my $module (sort keys %{$r->{children}}) {
        strict_child($r->{children}{$module}, "${label}_$module");
        is($r->{children}{$module}{actor_name}, $module, 'actual generated module identity retained');
        is($r->{children}{$module}{library_origin}{parent_actor}, $actor->{actor_name}, 'real importing actor origin retained');
    }
    is_deeply($p->{actor}, $before, "$label prepared source unchanged");
    is_deeply($actor, $before, "$label authored source unchanged");
    return $p;
}

subtest 'file-backed reusable and ATL child composition products' => sub {
    for my $fixture (qw(fifo_library_use atl_resolved_child_pipeline
        atl_resolved_child_pin_ingress_vector_multi_pipeline
        atl_resolved_child_pin_egress_vector_multi_pipeline
        atl_two_child_vector_data_pipeline atl_two_child_trigger_batch_pipeline)) {
        my $a = file_actor("isf/$fixture.isf");
        my $local = parse('(actor scratch (transaction local_main (ports (input local_delay (width 4))) (wait local_delay)))')->{transactions}[0];
        push @{$a->{transactions}}, $local;
        my $p = qualify($a, $fixture);
        my $r = $p->{reusable_child_products};
        ok(keys %{$r->{children}}, 'actual independent children retained');
        is_deeply($p->{generated_child_products}, {}, 'reusable modules do not enter generated transaction scope');
        if ($fixture eq 'fifo_library_use') {
            my $use = $r->{library_uses}[0];
            is($use->{instance}, 'u_fifo', 'source library instance identity retained');
            my %params = map {$_->{name} => $_} @{$use->{parameters}};
            is($params{DEPTH}{source}, 'override', 'bound parameter provenance retained');
            is($params{DEPTH}{value}, 4, 'instance-local parameter value retained');
            my $child = $r->{children}{$use->{module}};
            ok(@{$child->{declared_storage}}, 'actual library storage declaration retained');
            ok(@{$child->{bank_accesses}}, 'actual library bank operations retained');
        } else {
            ok(@{$r->{atl_top_instances}}, 'actual supported composition selection retained');
            for my $child (values %{$r->{children}}) {
                is($child->{library_origin}{usage}, 'atl_static_instance', 'resolved ATL origin stays explicit');
            }
        }
        my $prior = dclone($p->{actor});
        my ($module) = sort keys %{$r->{children}};
        $r->{children}{$module}{actor_name} = 'changed';
        $r->{children}{$module}{ports}[0]{name} = 'changed';
        is_deeply($p->{actor}, $prior, 'product mutation cannot edit resolved actor shells');
    }
};

my $mixed = <<'ISF';
(library common.pulse (exports (actor pulse_actor))
 (actor pulse_actor (clock clk) (reset rst_n)
  (params (DELAY 2))
  (interface (input trigger) (output fired))
  (transaction pulse (on trigger) (wait DELAY) (complete fired))))
(actor mixed_children (clock clk) (reset rst_n)
 (interface (input fire) (output fired) (output done))
 (imports (library common.pulse as pulse_lib))
 (use pulse_lib.pulse_actor as rx (params (DELAY 3))
  (bind (clock clk) (reset rst_n) (input trigger fire) (output fired fired)))
 (transaction worker (wait 1) (complete done))
 (transaction main (ports (input payload (width 4))) (on fire)
  (spawn worker as job) (await_all done) (wait payload) (complete done)))
ISF
subtest 'generated and reusable modules remain separate through raw parent conflicts' => sub {
    my $p = qualify(parse($mixed), 'mixed');
    is_deeply([sort keys %{$p->{generated_child_products}}], ['worker'], 'generated child scope remains separate');
    is_deeply([sort keys %{$p->{reusable_child_products}{children}}], ['mixed_children__rx'], 'reusable module scope remains separate');
    my $before = dclone($p->{generated_child_products});
    $p->{reusable_child_products}{children}{mixed_children__rx}{states}[0]{name} = 'changed';
    is_deeply($p->{generated_child_products}, $before, 'reusable edits cannot reach generated child products');
    (my $text = $mixed) =~ s/\(transaction worker/(storage (var payload (width 8))) (transaction worker/;
    my $a = parse($text);
    my $q = $l->prepare_formal_source($a);
    is_deeply($q->{reusable_child_products}, $l->prepare_formal_source(parse($mixed))->{reusable_child_products}, 'raw parent width conflict leaves independent child products unchanged');
    eval {$l->build_module($a)};
    like($@, qr/(?:width|Width).*payload|payload.*(?:width|Width)/s, 'real parent still refuses raw conflicting declarations');
    my $physical = project($q);
    is_deeply(actual_products($l->build_module($physical), $q->{generated_children}), $q->{reusable_child_products}, 'physical parent passes with real reusable modules unchanged');
};

sub refused {
    my ($actor, $pattern, $label) = @_;
    for my $method (qw(prepare_formal_source build_module)) {
        my $ok = eval {$l->$method(dclone($actor)); 1};
        ok(!$ok, "$label refused by $method");
        like($@, $pattern, "$label canonical diagnosis in $method");
    }
}
subtest 'same module and composition admission remains mandatory' => sub {
    my $a = parse($mixed);
    my $missing = dclone($a);delete $missing->{library_uses}[0]{module};
    refused($missing, qr/missing a generated module name/, 'missing library module');
    my $collision = dclone($a);$collision->{library_uses}[0]{module} = 'worker';
    refused($collision, qr/conflicts with another generated child/, 'library versus generated module collision');
    my $broken = dclone($a);delete $broken->{library_uses}[0]{actor};
    refused($broken, qr/does not carry a reusable actor shell/, 'missing library actor');
    my $atl = file_actor('isf/atl_resolved_child_pipeline.isf');
    my ($key) = keys %{$atl->{_atl_actor_type_resolutions}};
    my $missing_atl = dclone($atl);delete $missing_atl->{_atl_actor_type_resolutions}{$key}{module};
    refused($missing_atl, qr/missing a generated module name/, 'missing resolved ATL module');
    my $groups = dclone($atl);$groups->{actor_network}{groups} = [{name => 'grouped'}];
    refused($groups, qr/cannot combine generated child wiring with static group metadata/, 'unsupported ATL group composition');
    my $external = parse('(actor external (instance reader of packet_reader) (transaction main (wait 1)))');
    my $r = $l->prepare_formal_source($external)->{reusable_child_products};
    is_deeply($r, {children => {}, library_uses => [], atl_top_instances => []}, 'unresolved external intent fabricates no child module');
};
done_testing;
