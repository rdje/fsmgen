#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Storable qw(dclone);
use File::Temp qw(tempdir);
use JSON::PP;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::LoweringIR;
use FSM::Scheduler::ISF::FormalIdentityPlan;
use FSM::Scheduler::ISF::FormalClauseResolver;

my $lowerer = FSM::Scheduler::ISF::LoweringIR->new;
my $work = tempdir(CLEANUP => 1);
my $capture = \&FSM::Test::SourceQueryRunner::_capture;
my $source = <<'ISF';
(actor source_context
  (clock clk) (reset (rst_n async active_low))
  (constants (LIMIT 3)) (params (ACTOR_COUNT 4))
  (interface (input start) (input payload (width 4)) (output done) (output observed (width 4)))
  (transaction main
    (ports (input count (width 4)) (output value (width 4)))
    (params (count 2))
    (on start)
    (local scratch (width 4) (init 1))
    (sample payload as count)
    (sample payload as inferred)
    (wait count)
    (wait (+ count 4'd1))
    (repeat count (set value count))
    (set scratch count)
    (set observed value)
    (complete done)))
ISF

sub parse { FSM::Adapter::ISF->new->parse_source($_[0], 'source_context.isf') }
sub prepare { $lowerer->prepare_formal_source(parse($_[0])) }
sub rewritten {
    my ($prepared, $name) = @_;
    my $plan = FSM::Scheduler::ISF::FormalIdentityPlan->build($prepared->{actor},
        generated_children => $prepared->{generated_children}, reserved_names => {});
    my ($tx) = grep {$_->{name} eq $name} @{$prepared->{actor}{transactions}};
    return (FSM::Scheduler::ISF::FormalClauseResolver->transaction($tx,
        plan => $plan, %{$prepared->{transactions}{$name}})->{transaction}, $plan);
}
sub rejects {
    my ($text, $pattern, $label) = @_;
    my $ok = eval {prepare($text); 1};
    ok(!$ok, "$label rejected before rewriting");
    like($@, $pattern, "$label source diagnostic");
}

subtest 'direct count and runtime expression scopes stay distinct' => sub {
    my $actor = parse($source);
    my $before = dclone($actor);
    my $prepared = $lowerer->prepare_formal_source($actor);
    is_deeply($actor, $before, 'preparation never mutates original source');
    is_deeply($prepared->{actor}, $before, 'prepared source retains authored records');
    my $ctx = $prepared->{transactions}{main};
    is_deeply($ctx->{locals}, {scratch => 1}, 'only explicit local shields a formal, not inferred samples');
    is_deeply($ctx->{static_symbols}, {LIMIT => 1, ACTOR_COUNT => 1}, 'direct runtime expressions use actor static scope');
    is_deeply($ctx->{static_count_symbols}, {LIMIT => 1, ACTOR_COUNT => 1, count => 1}, 'standalone counts include transaction parameters');
    ok(!exists $prepared->{actor_context}{static_symbols}{count}, 'actor context cannot borrow transaction parameter');
    my ($tx, $plan) = rewritten($prepared, 'main');
    my $physical = $plan->{formals}{main}{count}{physical_name};
    my @waits = grep {$_->[0] eq 'wait'} @{$tx->{clauses}};
    is_deeply(\@waits, [['wait', 'count'], ['wait', ['+', $physical, "4'd1"]]], 'scalar static wait remains static while expression reads the formal');
    my ($repeat) = grep {$_->[0] eq 'repeat'} @{$tx->{clauses}};
    is($repeat->[1], 'count', 'repeat keeps static count parameter');
    is($repeat->[2][2], $physical, 'repeat body reads renamed runtime formal');
    my ($sample) = grep {$_->[0] eq 'sample'} @{$tx->{clauses}};
    is($sample->[3], $physical, 'inferred sample collection does not shield an explicit formal');
    my $physical_actor = dclone($actor);
    $physical_actor->{transactions}[0] = $tx;
    my $scheduler = FSM::Scheduler::ISF->new;
    my $lowered = $scheduler->lower($physical_actor);
    my $report = JSON::PP->new->decode($scheduler->report($physical_actor));
    is($report->{transaction_waits}[0]{count_kind}, 'static', 'rewritten scalar wait remains statically lowered');
    is($report->{transaction_waits}[0]{cycles}, 2, 'rewritten scalar wait retains the parameter value');
    is($report->{transaction_waits}[1]{count_kind}, 'runtime_expression', 'rewritten expression retains runtime count kind');
    is($report->{transaction_waits}[1]{count_source}, "(+ $physical 4'd1)", 'runtime wait references the physical formal');
    my $fsm = $lowered->{files}{'source_context.fsm'};
    like($fsm, qr/\(scratch \Q$physical\E\)/, 'runtime read reaches scoped formal');
    unlike($fsm, qr/\(\+params\s+\(count /, 'direct count parameter does not become a parent HDL parameter');
    check_carrier('direct.fsm', $fsm);
    $prepared->{transactions}{main}{static_symbols}{LIMIT} = 0;
    $prepared->{actor}{transactions}[0]{clauses}[0][1][1] = 99;
    is_deeply($actor, $before, 'returned contexts and source are detached');
};

subtest 'generated child parameters belong to its expression scope' => sub {
    my $text = <<'ISF';
(actor generated_context (clock clk) (reset (rst_n async active_low))
  (interface (input start) (input payload (width 4)) (output done) (output observed (width 4)))
  (transaction main (on start) (spawn worker as job (bind (input data payload) (output result observed))) (await_all done))
  (transaction worker (ports (input data (width 4)) (output result (width 4))) (params (COUNT 2))
    (wait COUNT) (set result COUNT)))
ISF
    my $prepared = prepare($text);
    is_deeply($prepared->{generated_children}, {worker => 1}, 'actual placement supplies scope');
    ok($prepared->{transactions}{worker}{static_symbols}{COUNT}, 'generated parameter is an emitted expression symbol');
    ok(!exists $prepared->{transactions}{main}{static_symbols}{COUNT}, 'caller cannot borrow child parameter');
    my ($tx) = rewritten($prepared, 'worker');
    is($tx->{ports}{inputs}[0]{name}, 'data', 'generated public formal identity remains public');
    is_deeply($tx->{clauses}[-1], ['set', 'result', 'COUNT'], 'generated parameter expression unchanged');
    my $lowered = FSM::Scheduler::ISF->new->lower($prepared->{actor});
    check_carrier('worker.fsm', $lowered->{files}{'worker.fsm'});
};

subtest 'canonical enum and imported payload paths retain exact identities' => sub {
    write_file("$work/shared.fsm", <<'FSM');
(?pkg:shared
  (+constants (COUNT 2) (PAIR ((lo 4'd3) (hi 4'd5))) (LANES (4'd1 4'd2)))
  (+enums (mode (IDLE 0) (BUSY 1))))
FSM
    my $path = write_file("$work/imported.isf", <<'ISF');
(actor imported_context
  (imports (package shared))
  (enums (local_mode (IDLE 0) (BUSY 1)))
  (constants (LIMIT local_mode.BUSY))
  (params (ACTOR_COUNT shared.COUNT) (LANES (shared.COUNT LIMIT)))
  (interface (input start) (output done))
  (transaction main (ports (input shared (width 4)) (input local_mode (width 4)))
    (on start) (wait shared.COUNT) (set shared local_mode.BUSY) (complete done)))
ISF
    my $actor = FSM::Adapter::ISF->new->parse_file($path);
    my $prepared = $lowerer->prepare_formal_source($actor);
    my $static = $prepared->{transactions}{main}{static_symbols};
    for my $name (qw(LIMIT ACTOR_COUNT LANES local_mode.IDLE local_mode.BUSY shared.COUNT
        shared.PAIR shared.PAIR.lo shared.PAIR.hi shared.LANES shared.LANES[0] shared.LANES[1]
        shared.mode.IDLE shared.mode.BUSY)) {
        ok($static->{$name}, "canonical static identity $name");
    }
    for my $name (qw(shared local_mode shared.MISSING shared.LANES[2] LANES[0])) {
        ok(!exists $static->{$name}, "no invented runtime static identity $name");
    }
    my ($tx, $plan) = rewritten($prepared, 'main');
    my ($set) = grep {$_->[0] eq 'set'} @{$tx->{clauses}};
    is_deeply($set, ['set', $plan->{formals}{main}{shared}{physical_name}, 'local_mode.BUSY'],
        'enum member retained while same-spelled formal root is renamed');
};

subtest 'validated zero regions bypass dead binding resolution' => sub {
    my $base = <<'ISF';
(actor zero_context (constants (ZERO 0))
  (interface (input start) (output done))
  (transaction main (on start)
    (when start (repeat ZERO (do worker (bind (input missing unknown)))))
    (switch start (1 (repeat 0 (spawn worker as dead (bind (input missing unknown))))))
    (complete done))
  (transaction worker (ports (input data (width 4))) (local bad (width 0))))
ISF
    my $prepared = prepare($base);
    is_deeply($prepared->{pruned_transactions}, {worker => 1}, 'zero-only child remains pruned');
    ok(!exists $prepared->{transactions}{worker}, 'dead target local is not newly validated');
    is_deeply($prepared->{transactions}{main}{pruned_repeats}, {'clauses/1/2' => 1, 'clauses/2/2/1' => 1},
        'structural paths select nested zero bodies precisely');
    my ($tx) = rewritten($prepared, 'main');
    is_deeply($tx->{clauses}, $prepared->{actor}{transactions}[0]{clauses}, 'dead bindings stay untouched instead of failing detached lookup');
    (my $live = $base) =~ s/\(repeat ZERO/\(repeat 1/;
    rejects($live, qr/unknown transaction port 'missing'/, 'same binding made live');
    (my $malformed = $base) =~ s/\(input missing unknown\)/(input missing)/;
    rejects($malformed, qr/bind.*(?:entries|input|requires)/, 'malformed dead binding shape');
    (my $missing = $base) =~ s/\(do worker/\(do absent/;
    rejects($missing, qr/not a declared transaction/, 'unknown dead target');
};

subtest 'context omissions and stale pruning paths fail closed' => sub {
    my $prepared = prepare($source);
    my $plan = FSM::Scheduler::ISF::FormalIdentityPlan->build($prepared->{actor},
        generated_children => $prepared->{generated_children}, reserved_names => {});
    my $tx = $prepared->{actor}{transactions}[0];
    for my $key (qw(locals static_symbols static_count_symbols pruned_repeats named_drives)) {
        my %context = %{$prepared->{transactions}{main}};
        delete $context{$key};
        my $ok = eval {FSM::Scheduler::ISF::FormalClauseResolver->transaction($tx, plan => $plan, %context); 1};
        ok(!$ok, "missing $key rejected");
    }
    for my $path ('clauses/999', 'clauses/1', 'invalid/path') {
        my %context = (%{$prepared->{transactions}{main}}, pruned_repeats => {$path => 1});
        my $ok = eval {FSM::Scheduler::ISF::FormalClauseResolver->transaction($tx, plan => $plan, %context); 1};
        ok(!$ok, "invalid or stale pruning path $path rejected");
    }
};

subtest 'source checks run before parent identity merging' => sub {
    my $shadow = '(actor shadow (storage (var value (width 8))) '
        . '(interface (input start) (output done)) '
        . '(transaction main (ports (input value (width 4))) (on start) (wait value) (complete done)))';
    my $prepared = eval {prepare($shadow)};
    ok($prepared, 'contexts do not require a conflicting parent merge') or diag($@);
    my $ok = eval {FSM::Scheduler::ISF->new->lower(parse($shadow)); 1};
    ok($ok, 'production separates the source formal from actor storage') or diag($@);
    is($@, '', 'source context integrates without a physical merge conflict');
    for my $case (
        ['(local scratch (width 4) (init 1))', '(local scratch (width 4) (typo 1))', qr/unsupported local option/],
        ['(wait count)', '(wait (bogus count))', qr/supported expression operator shape/],
        ['(repeat count (set value count))', '(repeat count (local nested (width 4)))', qr/unsupported.*local/],
    ) {
        my $text = $source;
        $text =~ s/\Q$case->[0]\E/$case->[1]/;
        rejects($text, $case->[2], 'malformed retained clause');
    }
};
done_testing;

sub check_carrier {
    my ($name, $text) = @_;
    my $file = write_file("$work/$name", $text);
    my $result = $capture->([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $file], '');
    is($result->{exit_code}, 0, "$name strict replay") or diag($result->{stdout}, $result->{stderr});
}
sub write_file {
    my ($path, $text) = @_;
    open my $fh, '>', $path or die "open $path: $!";
    print {$fh} $text or die "write $path: $!";
    close $fh or die "close $path: $!";
    return $path;
}
