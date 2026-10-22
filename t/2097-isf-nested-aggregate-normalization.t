use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

my $json = JSON::PP->new->canonical;
my $work = tempdir(CLEANUP => 1);
open my $package, '>:raw', "$work/shared.fsm" or die $!;
print {$package} '(?pkg:shared (+constants (LIMIT 16)))' or die $!;
close $package or die $!;

sub source {
    my ($tree, $overrides) = @_;
    return <<"ISF";
(library widths (exports (actor child))
  (actor child (clock clk)
    (params (W 8) (PAIR (0 0)) (TREE $tree))
    (interface (input data (width W)) (output result (width W)))
    (rule copy 1 (result data))))
(actor nested_sources (clock clk) (reset (rst_n async active_low))
  (params (LIMIT 16) (ALIAS LIMIT)) (constants (FIXED 16))
  (imports (package shared) (library widths as lib))
  (interface (input data (width 8)) (output first_result (width 8)) (output second_result (width 8)))
  (use lib.child as first (params $overrides)
    (bind (clock clk) (input data data) (output result first_result)))
  (use lib.child as second
    (bind (clock clk) (input data data) (output result second_result))))
ISF
}

subtest 'actor defaults and cloned library overrides retain independent literal shapes and kinds' => sub {
    for my $case (
        ['literal', '((16 17) (18 19))', '(TREE ((20 21) (22 23)))',
            '[["16","17"],["18","19"]]', '[["20","21"],["22","23"]]'],
        ['named', '((16 16) (16 16))', '(TREE ((LIMIT ALIAS) (shared.LIMIT FIXED)))',
            '[["16","16"],["16","16"]]', '[["16","16"],[16,"16"]]'],
        ['scalar_control', '(0 0)', '(W 8)', '["0","0"]', undef],
        ['list_control', '(0 0)', '(PAIR (1 0))', '["0","0"]', undef],
    ) {
        my ($name, $tree, $overrides, $default, $override) = @$case;
        my $text = source($tree, $overrides);
        my $actor = FSM::Adapter::ISF->new->parse_source($text, "$work/peer.isf");
        # Serialize before any Test::More reads can add scalar flags.
        my $before = $json->encode($actor);
        my @defaults = map {$json->encode($_->{actor}{params}[2]{value})} @{$actor->{library_uses}};
        my @overrides = map {$json->encode($_->[0]{parameter_overrides}[0]{value})}
            @{$actor}{qw(uses library_uses)};
        my $scheduler = FSM::Scheduler::ISF->new;
        my $lowered = $scheduler->lower($actor);
        my $report = $scheduler->report($actor);
        my $after = $json->encode($actor);
        is_deeply(\@defaults, [$default, $default], "$name: both exported actor defaults normalize");
        if (defined $override) {
            is_deeply(\@overrides, [$override, $override], "$name: original/resolved uses retain exact leaf kinds");
        } else {
            my $expected = $name eq 'scalar_control' ? '"8"' : '["1","0"]';
            is_deeply(\@overrides, [$expected, $expected], "$name: scalar/flat-list overrides stay exact");
        }
        is($after, $before, "$name: complete lower/report caller kinds stay exact");
        ok(keys %{$lowered->{files}}, "$name: actual reusable library carriers are emitted");
        ok(length $report, "$name: actual schedule report is emitted");
        my $fresh = FSM::Adapter::ISF->new->parse_source($text, "$work/peer.isf");
        $actor->{library_uses}[0]{actor}{params}[2]{value}[0] = 'changed';
        is($json->encode($fresh), $before, "$name: separate parses retain complete independent values");
        is($json->encode($actor->{library_uses}[1]{actor}{params}[2]{value}), $default,
            "$name: exported default siblings are detached");
        if (my $capture = $ENV{FSMGEN_NESTED_NORMALIZATION_CAPTURE}) {
            open my $f, '>:raw', "$capture/$name.json" or die $!;
            # peer.isf is a logical source label; normalize only this test's workspace.
            my $record = $json->encode({source => $text, actor => $json->decode($before),
                lowered => $lowered, report => $report, caller_unchanged => $after eq $before ? 1 : 0});
            $record =~ s/\Q$work\E/<work>/g;
            print {$f} $record, "\n" or die $!;
            close $f or die $!;
        }
    }
};

done_testing;
