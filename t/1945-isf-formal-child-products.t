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
my $lowerer = $s->{ir};
my $work = tempdir(CLEANUP => 1);
my $base = <<'ISF';
(actor child_products (clock clk) (reset rst_n)
 (interface (input fire) (input din (width 4)) (output child_done) (output done))
 (storage (var cell (width 4) (reset 3)))
 (transaction main (ports (input payload (width 4))) (on fire) (set payload din)
  (spawn worker as job (bind (input data payload))) (await_all done) (complete done))
 (transaction worker (ports (input data (width 4)))
  (point armed) (assert (=> (at armed) fire)) (set cell (+ cell data)) (complete child_done)))
ISF
sub parse {FSM::Adapter::ISF->new->parse_source($_[0], 'child_products.isf')}
sub inventory {FSM::Scheduler::ISF::FormalReservationInventory->collect($_[0])->{reserved_names}}
sub project {
    my ($p) = @_;
    my $products = {map {$_ => $p->{$_}} qw(transaction_products parent_activation_products
        parent_wiring_products parent_point_products resource_signal_products generated_child_products)};
    my $a = dclone($p->{actor});
    my $plan = FSM::Scheduler::ISF::FormalIdentityPlan->build($a,
        generated_children => $p->{generated_children}, reserved_names => inventory($products));
    for my $tx (@{$a->{transactions}}) {
        next if $p->{pruned_transactions}{$tx->{name}};
        $tx = FSM::Scheduler::ISF::FormalClauseResolver->transaction($tx,
            plan => $plan, %{$p->{transactions}{$tx->{name}}})->{transaction};
    }
    for my $rule (@{$a->{rules}}) {
        $rule = FSM::Scheduler::ISF::FormalClauseResolver->rule($rule,
            plan => $plan, %{$p->{actor_context}})->{rule};
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
sub qualify {
    my ($actor, $label) = @_;
    my $before = dclone($actor);
    my $p = $lowerer->prepare_formal_source($actor);
    my $children = $p->{generated_child_products};
    is_deeply($children, $lowerer->build_module($actor)->{children}, "$label complete actual child IR agrees");
    my $physical = project($p);
    is_deeply($lowerer->build_module($physical)->{children}, $children, "$label physical parent formals preserve child module products");
    my $q = $lowerer->prepare_formal_source($physical);
    is_deeply($q->{generated_child_products}, $children, "$label physical preparation preserves actual child products");
    for my $name (sort keys %$children) {
        strict_child($children->{$name}, "${label}_$name");
    }
    is_deeply($p->{actor}, $before, "$label prepared source unchanged");
    is_deeply($actor, $before, "$label authored source unchanged");
    return $p;
}

subtest 'real child producer retains activation storage completion and point products' => sub {
    for my $kind (qw(spawn do trigger)) {
        my $text = $base;
        if ($kind ne 'spawn') {
            $text =~ s/\(transaction worker/(transaction worker (params (MODE 0))/;
            if ($kind eq 'do') {
                $text =~ s/\(spawn worker as job/\(do worker (params (MODE 1))/;
                $text =~ s/\(await_all done\) //;
            } else {
                $text =~ s/\(spawn worker as job \(bind \(input data payload\)\)\) \(await_all done\)/(wait 1)/;
                $text =~ s/\)\s*\z//;
                $text .= '(rule launch fire (trigger worker (params (MODE 1)) (bind (input data din)))))';
            }
        }
        my $p = qualify(parse($text), $kind);
        my $child = $p->{generated_child_products}{worker};
        is_deeply([map {$_->{name}} @{$child->{actor_storage_reads}}], ['cell'], 'actual live actor storage read retained');
        is_deeply([map {$_->{name}} @{$child->{actor_storage_writes}}], ['cell'], 'actual actor storage write interface retained');
        is_deeply([map {$_->{name}} @{$child->{actor_completion_outputs}}], ['child_done'], 'actual named completion retained');
        is_deeply($child->{declared_storage}, [], 'child holds no duplicate actor storage');
        ok(!exists $child->{reset_values}{cell}, 'owner reset is not copied into child');
        my @history = grep {$child->{storage_roles}{$_} eq 'child_start_history'} keys %{$child->{storage_roles}};
        is(scalar @history, 1, 'actual activation history declaration retained');
        my @points = grep {($_->{source_kind}//'') eq 'point_active'} map {@{$_->{assignments}}} @{$child->{states}};
        is(scalar @points, 1, 'actual child point resolution retained');
        my $raw = $p->{transaction_products}{worker};
        my $old = inventory({transactions => $p->{transaction_products}, parent => $p->{parent_activation_products}});
        my $new = inventory($p->{generated_child_products});
        for my $name ($history[0], $points[0]{lhs}, $child->{actor_storage_writes}[0]{data_port}, $child->{actor_storage_writes}[0]{enable_port}) {
            ok(!$old->{$name}, "$name absent from earlier products");
            ok($new->{$name}, "$name present in actual child products");
        }
        like($raw->{immediate_assertions}[0]{condition}, qr/\(at armed\)/, 'raw child assertions remain unresolved');
        my $prior = dclone($p->{transaction_products});
        $child->{ports}[0]{name} = 'changed';
        $child->{states}[0]{name} = 'changed';
        is_deeply($p->{transaction_products}, $prior, 'complete child products cannot mutate earlier transaction products');
        is_deeply($p->{actor}, parse($text), 'child product mutation cannot alter prepared actor');
    }
};

subtest 'child-local helper allocation respects exact and portable case collisions' => sub {
    my $p = $lowerer->prepare_formal_source(parse($base));
    my $child = $p->{generated_child_products}{worker};
    my ($history) = grep {$child->{storage_roles}{$_} eq 'child_start_history'} keys %{$child->{storage_roles}};
    my $write = $child->{actor_storage_writes}[0]{data_port};
    for my $desired ($history, $write) {
        for my $port ($desired, uc($desired)) {
            (my $text = $base) =~ s/\bdata\b/$port/g;
            my $q = qualify(parse($text), $port);
            my $c = $q->{generated_child_products}{worker};
            my ($actual) = $desired eq $history
                ? grep {$c->{storage_roles}{$_} eq 'child_start_history'} keys %{$c->{storage_roles}}
                : $c->{actor_storage_writes}[0]{data_port};
            isnt(lc($actual), lc($port), 'actual canonical allocator keeps helper separate from child public port');
            ok(inventory($q->{generated_child_products})->{$actual}, 'allocated helper is collected without guessing its suffix');
            my ($public) = grep {$_->{name} eq $port} @{$c->{ports}};
            is($public->{width}, 4, 'public child formal retains its own width');
        }
    }
};

subtest 'reused definitions and actual domain projections retain separate module scopes' => sub {
    my $text = $base;
    $text =~ s/\(set cell \(\+ cell data\)\)/(local snapshot (width 4)) (set snapshot (+ cell data))/;
    $text =~ s/\(spawn worker as job \(bind \(input data payload\)\)\)/(spawn worker as first (bind (input data payload))) (spawn worker as second (bind (input data payload)))/;
    my $p = qualify(parse($text), 'reused');
    is_deeply([keys %{$p->{generated_child_products}}], ['worker'], 'reused worker definition collected once');
    $text =~ s/\(clock clk\) \(reset rst_n\)/(clock-domains (domain core (clock clk) (reset rst_n) :default) (domain aux (clock aux_clk)))/;
    my $actor = parse($text);
    my $ir = $lowerer->build_module($actor);
    for my $r (@{$s->_multi_domain_realizations($actor, $ir->{domain_partition})}) {
        my $a = FSM::Scheduler::ISF::_domain_actor_for_scheduled_artifact($actor, $r->{domain}, $ir->{domain_partition}{default_domain});
        my $q = qualify($a, $r->{domain}{name});
        is_deeply($q->{generated_child_products}, $r->{ir}{children}, 'actual realized domain child scope agrees');
    }
};

subtest 'parent conflicts remain separate and child admission stays canonical' => sub {
    (my $text = $base) =~ s/\(storage/(storage (var payload (width 8))/;
    my $actor = parse($text);
    my $p = $lowerer->prepare_formal_source($actor);
    is_deeply($p->{generated_child_products}, $lowerer->prepare_formal_source(parse($base))->{generated_child_products}, 'unused parent formal shadow does not alter independent child products');
    eval {$lowerer->build_module($p->{actor})};
    like($@, qr/signal width.*conflicts across transactions/, 'raw conflicting parent merge remains refused');
    $text = $base;
    $text =~ s/\(at armed\)/(at missing)/;
    eval {$lowerer->prepare_formal_source(parse($text))};
    like($@, qr/references unknown point\/activation name 'missing'/, 'actual child resolver rejects unknown anchor');
    $text = $base;
    $text =~ s/\(set cell \(\+ cell data\)\)/(set-bit cell 0)/;
    # Bit helpers desugar to whole-word read/modify/write, so they are a valid
    # control for the qualified full-width writer rather than a partial LHS.
    my $bit = qualify(parse($text), 'whole_word_setbit');
    is($bit->{generated_child_products}{worker}{actor_storage_writes}[0]{name}, 'cell',
        'normalized whole-word bit helper keeps the qualified write handoff');
    $text = $base;
    $text =~ s/\(storage/(storage (bank slots (width 4) (depth 2))/;
    $text =~ s/\(set cell \(\+ cell data\)\)/(store slots 1 data)/;
    eval {$lowerer->prepare_formal_source(parse($text))};
    like($@, qr/only full-width variable sequential writes are qualified/, 'canonical unsupported child bank-write boundary retained');
    $text = $base;
    $text =~ s/\(spawn worker/(repeat 0 (spawn dead as unused)) (spawn worker/;
    $text =~ s/\)\s*\z//;
    $text .= '(transaction dead (assert (at missing))))';
    $p = $lowerer->prepare_formal_source(parse($text));
    ok($p->{pruned_transactions}{dead}, 'invalid dead body is statically pruned');
    is_deeply([keys %{$p->{generated_child_products}}], ['worker'], 'pruned child is never built');
};
done_testing;
