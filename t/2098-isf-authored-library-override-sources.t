use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use File::Temp qw(tempdir);
use JSON::PP;
use Digest::SHA qw(sha256_hex);
use B;
use FSM::Test::ProjectDataLocality;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

my $json = JSON::PP->new->canonical;
my $work = tempdir(CLEANUP => 1);
open my $package, '>:raw', "$work/shared.fsm" or die $!;
print {$package} '(?pkg:shared (+constants (LIMIT 16)) (+enums (mode (IDLE 0) (BUSY 1))))' or die $!;
close $package or die $!;

sub source {
    my ($first, $second) = @_;
    $first = length($first) ? "(params $first)" : '';
    $second = defined($second) ? "(params $second)" : '';
    return <<"ISF";
(library widths (exports (actor child))
  (actor child (clock clk)
    (params (W 8) (PAIR (0 0)) (TREE ((16 16) (16 16))))
    (interface (input data (width W)) (output result (width W)))
    (rule copy 1 (result data))))
(actor library_sources (clock clk)
  (params (LIMIT 16) (ALIAS LIMIT) (OTHER 16)) (constants (FIXED 16))
  (enums (mode (IDLE 0) (BUSY 1)))
  (imports (package shared) (library widths as lib))
  (interface (input data (width 8)) (output first_result (width 8)) (output second_result (width 8)))
  (use lib.child as first $first
    (bind (clock clk) (input data data) (output result first_result)))
  (use lib.child as second $second
    (bind (clock clk) (input data data) (output result second_result))))
ISF
}

sub parse {
    return FSM::Adapter::ISF->new->parse_source($_[0], "$work/peer.isf");
}

# These literal JSON oracles deliberately distinguish each original source's
# primitive kinds. A package/enum number is not a parameter/literal string.
my @cases = (
    ['parameter', '(W LIMIT)', '["LIMIT"]', '["16"]'],
    ['alias', '(W ALIAS)', '["ALIAS"]', '["16"]'],
    ['equal_default', '(W OTHER)', '["OTHER"]', '["16"]'],
    ['constant', '(W FIXED)', '["FIXED"]', '["16"]'],
    ['package', '(W shared.LIMIT)', '["shared.LIMIT"]', '[16]'],
    ['enum', '(W mode.BUSY)', '["mode.BUSY"]', '[1]'],
    ['package_enum', '(W shared.mode.BUSY)', '["shared.mode.BUSY"]', '[1]'],
    ['literal', '(W 16)', '["16"]', '["16"]'],
    ['exact_width', "(W 5'd16)", q{["5'd16"]}, q{["5'd16"]}],
    ['list', '(PAIR (mode.BUSY shared.mode.IDLE))',
        '[["mode.BUSY","shared.mode.IDLE"]]', '[[1,0]]'],
    ['nested', '(TREE ((LIMIT ALIAS) (shared.LIMIT 16)))',
        '[[["LIMIT","ALIAS"],["shared.LIMIT","16"]]]', '[[["16","16"],[16,"16"]]]'],
    ['multiple', '(W ALIAS) (TREE ((LIMIT ALIAS) (shared.LIMIT 16))) (PAIR (1 0))',
        '["ALIAS",[["LIMIT","ALIAS"],["shared.LIMIT","16"]],["1","0"]]',
        '["16",[["16","16"],[16,"16"]],["1","0"]]'],
    ['defaults', '', '[]', '[]'],
);

subtest 'authored trees and resolved kinds use independent per-source expectations' => sub {
    for my $case (@cases) {
        my ($id, $overrides, $authored_json, $resolved_json) = @$case;
        my $text = source($overrides);
        my $actor = parse($text);
        # Capture before assertions or numeric reads can change Perl flags.
        my $before = $json->encode($actor);
        my $scheduler = FSM::Scheduler::ISF->new;
        my $lower = $scheduler->lower($actor);
        my $report = $scheduler->report($actor);
        my $after = $json->encode($actor);
        if (my $capture = $ENV{FSMGEN_LIBRARY_SOURCE_CAPTURE}) {
            my $path = $INC{'FSM/Adapter/ISF/Parser.pm'};
            open my $p, '<:raw', $path or die $!;
            my $bytes = do {local $/; <$p>};
            close $p or die $!;
            my $record = $json->encode({
                source => $text, actor => $json->decode($before), lower => $lower,
                report => $json->decode($report), caller_unchanged => $after eq $before ? JSON::PP::true : JSON::PP::false,
                loaded => {path => $path, sha256 => sha256_hex($bytes), methods => {
                    map {$_ => B::svref_2object(FSM::Adapter::ISF::Parser->can($_))->GV->FILE}
                        qw(_validate_use_params _resolve_library_uses _resolve_library_use_param_value)
                }},
            });
            $record =~ s/\Q$work\E/<work>/g;
            open my $f, '>:raw', "$capture/$id.json" or die $!;
            print {$f} $record, "\n" or die $!;
            close $f or die $!;
        }
        is($after, $before, "$id: lower/report preserve complete caller kinds");
        my $snapshot = $json->decode($before);
        my @names = $id eq 'defaults' ? () : $id eq 'multiple' ? qw(W TREE PAIR)
            : $id eq 'nested' ? ('TREE') : $id eq 'list' ? ('PAIR') : ('W');
        for my $key (qw(uses library_uses)) {
            my $use = $snapshot->{$key}[0];
            is_deeply([map {$_->{name}} @{$use->{parameter_overrides}}], \@names,
                "$id $key: exact independently declared override membership");
            is($json->encode([map {$_->{value}} @{$use->{parameter_overrides}}]), $resolved_json,
                "$id $key: canonical resolution preserves original primitive kinds");
            if (length $overrides) {
                my $values = $json->decode($authored_json);
                my @expected = map {{name => $names[$_], value => $values->[$_], owner => 'library_sources'}} 0..$#names;
                is($json->encode($use->{_parameter_override_sources}), $json->encode(\@expected),
                    "$id $key: authored tree retains order, tokens, kinds and owner");
            } else {
                ok(!exists $use->{_parameter_override_sources}, "$id $key: no invented default source");
            }
            ok(!exists $snapshot->{$key}[1]{_parameter_override_sources}, "$id $key: default sibling has no source");
        }
    }
};

subtest 'nested source lists detach original uses, resolved uses, siblings and fresh parses' => sub {
    my $overrides = '(W ALIAS) (TREE ((LIMIT ALIAS) (shared.LIMIT 16)))';
    my $text = source($overrides, $overrides);
    my $actor = parse($text);
    my $before = $json->encode($actor);
    my $sources = $actor->{uses}[0]{_parameter_override_sources};
    ok(ref($sources) eq 'ARRAY', 'actual authored source list exists');
    if (ref($sources) eq 'ARRAY') {
        $sources->[0]{value} = 'OTHER';
        $sources->[1]{value}[0][0] = 'wrong';
        is($actor->{library_uses}[0]{_parameter_override_sources}[0]{value}, 'ALIAS', 'resolved scalar source is detached');
        is($actor->{library_uses}[0]{_parameter_override_sources}[1]{value}[0][0], 'LIMIT', 'resolved nested source is detached');
        is($actor->{uses}[1]{_parameter_override_sources}[1]{value}[0][0], 'LIMIT', 'sibling source is detached');
        is($actor->{uses}[0]{parameter_overrides}[1]{value}[0][0], '16', 'canonical resolved tree is detached');
        $actor->{library_uses}[0]{_parameter_override_sources}[1]{value}[1][0] = 'wrong';
        is($actor->{library_uses}[1]{_parameter_override_sources}[1]{value}[1][0], 'shared.LIMIT', 'resolved sibling is detached');
    }
    is($json->encode(parse($text)), $before, 'fresh parses retain complete independent state');
};

done_testing;
