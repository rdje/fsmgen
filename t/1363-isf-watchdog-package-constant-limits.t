#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

subtest 'package scalar constants are valid static watchdog limits' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+constants
    (WD_LIMIT 17)
    (AWAIT_LIMIT 4'd9))
)
FSM

    my $actor_path = File::Spec->catfile($dir, 'package_constant_watchdog.isf');
    write_file($actor_path, <<'ISF');
(actor package_constant_watchdog
  (imports
    (package shared))
  (clock clk)
  (watchdog shared.WD_LIMIT)
  (interface
    (input start)
    (input ready)
    (output done))
  (transaction main
    (on start)
    (await ready)
    (complete done)))
ISF

    my $actor = parse_file($actor_path);
    is($actor->{watchdog}, '17', 'actor-level package watchdog resolves in the public actor shell');
    is($actor->{constant_symbols}{packages}{shared}{WD_LIMIT}{payload}, 17,
        'actor shell records imported package scalar watchdog limit');

    my ($fsm, $report) = lower_and_report($actor, 'package_constant_watchdog.fsm');
    like($fsm, qr/\(\+import\s+shared\s+\)/s, 'scheduled .fsm emits package import');
    like($fsm, qr/\(\?pkg:shared[\s\S]*\(\+constants[\s\S]*\(WD_LIMIT 17\)[\s\S]*\(AWAIT_LIMIT 4'd9\)/,
        'scheduled .fsm embeds imported package constants');
    like($fsm, qr/\(main_wd 5\)/, 'actor-level package watchdog drives the inferred counter width');
    like($fsm, qr/\(<= \(main_wd \(- 17 1\)\)\)/,
        'actor-level package watchdog drives the init value');
    is($report->{watchdog}, '17', 'report exposes the resolved actor-level watchdog limit');

    my $await_path = File::Spec->catfile($dir, 'package_constant_await_watchdog.isf');
    write_file($await_path, <<'ISF');
(actor package_constant_await_watchdog
  (imports
    (package shared))
  (clock clk)
  (interface
    (input start)
    (input ready)
    (output done))
  (transaction main
    (on start)
    (await ready (watchdog shared.AWAIT_LIMIT))
    (complete done)))
ISF

    my $await_actor = parse_file($await_path);
    my ($await_fsm, $await_report) = lower_and_report($await_actor, 'package_constant_await_watchdog.fsm');
    like($await_fsm, qr/\(main_wd 4\)/, 'await-local package watchdog drives the inferred counter width');
    like($await_fsm, qr/\(<= \(main_wd \(- 9 1\)\)\)/,
        'await-local package watchdog drives the init value');
    is($await_report->{watchdog}, '65535',
        'actor-level default watchdog remains report-visible for await-local package override');
};

subtest 'package constant watchdog diagnostics fail closed' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+constants
    (WD_LIMIT 17)
    (WD_ZERO 0)
    (WD_LIMITS (9 10)))
)
FSM

    assert_parse_file_rejected(
        $dir,
        'unknown_package_constant_watchdog.isf',
        <<'ISF',
(actor unknown_package_constant_watchdog
  (imports
    (package shared))
  (clock clk)
  (watchdog shared.MISSING)
  (interface (input start)))
ISF
        qr/Error: actor 'unknown_package_constant_watchdog' watchdog references unknown package constant 'shared\.MISSING'/,
        'unknown package constants are rejected as actor-level watchdog limits',
    );

    assert_parse_file_rejected(
        $dir,
        'unqualified_package_constant_watchdog.isf',
        <<'ISF',
(actor unqualified_package_constant_watchdog
  (imports
    (package shared))
  (clock clk)
  (watchdog WD_LIMIT)
  (interface (input start)))
ISF
        qr/Error: actor 'unqualified_package_constant_watchdog' watchdog token 'WD_LIMIT' is not a declared actor constant, actor scalar parameter, or qualified package scalar constant/,
        'unqualified package constants are rejected as actor-level watchdog limits',
    );

    assert_parse_file_rejected(
        $dir,
        'aggregate_package_constant_watchdog.isf',
        <<'ISF',
(actor aggregate_package_constant_watchdog
  (imports
    (package shared))
  (clock clk)
  (watchdog shared.WD_LIMITS)
  (interface (input start)))
ISF
        qr/Error: actor 'aggregate_package_constant_watchdog' watchdog package constant 'shared\.WD_LIMITS' must resolve to a positive integer scalar/,
        'aggregate package constants remain deferred as actor-level watchdog limits',
    );

    assert_parse_file_rejected(
        $dir,
        'package_constant_watchdog_path.isf',
        <<'ISF',
(actor package_constant_watchdog_path
  (imports
    (package shared))
  (clock clk)
  (watchdog shared.WD_LIMITS[0])
  (interface (input start)))
ISF
        qr/Error: actor 'package_constant_watchdog_path' watchdog package constant 'shared\.WD_LIMITS' aggregate\/member path 'shared\.WD_LIMITS\[0\]' remains deferred/,
        'package aggregate constant scalar-leaf paths remain deferred as actor-level watchdog limits',
    );

    assert_parse_file_rejected(
        $dir,
        'zero_package_constant_watchdog.isf',
        <<'ISF',
(actor zero_package_constant_watchdog
  (imports
    (package shared))
  (clock clk)
  (watchdog shared.WD_ZERO)
  (interface (input start)))
ISF
        qr/Error: actor 'zero_package_constant_watchdog' watchdog package constant 'shared\.WD_ZERO' must resolve to a positive integer scalar/,
        'zero-valued package constants keep the positive actor-level watchdog policy',
    );

    my $mode_dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($mode_dir, 'mode.fsm'), <<'FSM');
(?pkg:mode
  (+constants
    (BUSY 9))
)
FSM
    assert_parse_file_rejected(
        $mode_dir,
        'ambiguous_package_constant_watchdog.isf',
        <<'ISF',
(actor ambiguous_package_constant_watchdog
  (imports
    (package mode))
  (enums
    (mode (BUSY 1)))
  (clock clk)
  (watchdog mode.BUSY)
  (interface (input start)))
ISF
        qr/Error: actor 'ambiguous_package_constant_watchdog' watchdog token 'mode\.BUSY' is ambiguous: it matches local enum member 'mode\.BUSY' and imported package constant 'mode\.BUSY'/,
        'ambiguous local-enum and package-constant actor-level watchdog tokens are rejected',
    );

    assert_parse_file_rejected(
        $dir,
        'expression_package_constant_watchdog.isf',
        <<'ISF',
(actor expression_package_constant_watchdog
  (imports
    (package shared))
  (clock clk)
  (watchdog (+ shared.WD_LIMIT 1))
  (interface (input start)))
ISF
        qr/Error: \(watchdog \.\.\.\) requires a positive integer literal, actor constant, actor scalar parameter, or qualified package scalar constant/,
        'package constant expressions remain rejected as actor-level watchdog limits',
    );

    assert_lower_file_rejected(
        $dir,
        'unknown_package_constant_await_watchdog.isf',
        <<'ISF',
(actor unknown_package_constant_await_watchdog
  (imports
    (package shared))
  (clock clk)
  (interface
    (input start)
    (input ready)
    (output done))
  (transaction main
    (on start)
    (await ready (watchdog shared.MISSING))
    (complete done)))
ISF
        qr/Transaction 'main': watchdog references unknown package constant 'shared\.MISSING' in await watchdog override/,
        'unknown package constants are rejected as await-local watchdog limits',
    );

    assert_lower_file_rejected(
        $dir,
        'expression_package_constant_await_watchdog.isf',
        <<'ISF',
(actor expression_package_constant_await_watchdog
  (imports
    (package shared))
  (clock clk)
  (interface
    (input start)
    (input ready)
    (output done))
  (transaction main
    (on start)
    (await ready (watchdog (+ shared.WD_LIMIT 1)))
    (complete done)))
ISF
        qr/Error: transaction 'main' await watchdog references enum member 'shared\.WD_LIMIT'/,
        'package constant expressions remain rejected as await-local watchdog limits',
    );
};

done_testing();

sub parse_file {
    my ($path) = @_;
    return FSM::Adapter::ISF->new()->parse_file($path);
}

sub lower_and_report {
    my ($actor, $fsm_name) = @_;
    my $scheduler = FSM::Scheduler::ISF->new();
    my $lowered = $scheduler->lower($actor);
    my $fsm = $lowered->{files}{$fsm_name};
    ok(defined($fsm), "lowering emits $fsm_name");
    my $report = decode_json($scheduler->report($actor));
    return ($fsm, $report);
}

sub assert_parse_file_rejected {
    my ($dir, $filename, $source, $regex, $label) = @_;
    my $path = File::Spec->catfile($dir, $filename);
    write_file($path, $source);

    my $ok = eval {
        parse_file($path);
        1;
    };
    ok(!$ok, "$label fails closed during parsing");
    like($@, $regex, "$label diagnostic");
}

sub assert_lower_file_rejected {
    my ($dir, $filename, $source, $regex, $label) = @_;
    my $path = File::Spec->catfile($dir, $filename);
    write_file($path, $source);

    my $ok = eval {
        my $actor = parse_file($path);
        FSM::Scheduler::ISF->new()->lower($actor);
        1;
    };
    ok(!$ok, "$label fails closed during lowering");
    like($@, $regex, "$label diagnostic");
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "open $path: $!";
    print {$fh} $content or die "write $path: $!";
    close $fh or die "close $path: $!";
    return $path;
}
