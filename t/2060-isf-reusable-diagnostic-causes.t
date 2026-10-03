use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use FSM::Scheduler::ISF;
use FSM::Test::DiagnosticCause;

my $base = 'docs/audits/reusable-product-helper-causes-20261003';
my $json = JSON::PP->new->canonical;
open my $fh, '<:raw', "$base/causes.json" or die $!;
my $fixtures = $json->decode(do {local $/; <$fh>});
close $fh or die $!;
my %reasons = (
    'missing library module' => "Library use 'rx' is missing a generated module name",
    'library versus generated module collision' =>
        "Library use 'rx' generated module 'worker' conflicts with another generated child",
    'missing library actor' => "Library use 'rx' does not carry a reusable actor shell",
    'missing resolved ATL module' => "ATL static actor instance 'worker' is missing a generated module name",
    'unsupported ATL group composition' =>
        "ATL generated top for actor 'atl_resolved_child_pipeline' "
        . "cannot combine generated child wiring with static group metadata in the current subset",
    'raw parent width conflict' =>
        "signal width for 'payload' conflicts across transactions while merging 'main'",
);
open $fh, '<:raw', 't/1947-isf-formal-reusable-products.t' or die $!;
my $test = do {local $/; <$fh>};
close $fh or die $!;
my $start = index($test, 'sub refused {');
my $end = index($test, "subtest '", $start);
die 'current helper missing' unless $start >= 0 && $end > $start;
my $helper = substr($test, $start, $end - $start);
$start = index($test, 'my $width_ok = eval');
$end = index($test, 'my $physical = project($q);', $start);
die 'current direct assertion missing' unless $start >= 0 && $end > $start;
my $direct = substr($test, $start, $end - $start);
{
    package ReusableCauseSubject;
    use Storable qw(dclone);
    our ($l, $a, @assertions, @errors);
    $l = FSM::Scheduler::ISF->new->{ir};
    # Deliberate negative calls observe bits; default T1947 separately runs
    # the real Test::More consumers.
    sub ok {push @assertions, $_[0] ? 1 : 0; return $_[0]}
    sub diag {}
    sub diagnostic_cause_matches {
        push @errors, $_[0];
        return FSM::Test::DiagnosticCause::diagnostic_cause_matches(@_);
    }
}
# Compile before API calls: active consumer-string eval frames can echo causes.
eval 'package ReusableCauseSubject; our ($l,$a);'
    . $helper . 'sub direct_consumer {' . $direct . "\n}";
die $@ if $@;
my @captures;
for (my $index = 0; $index < @{$fixtures->{rows}};) {
    my $row = $fixtures->{rows}[$index];
    my $is_direct = $row->{id} eq 'raw parent width conflict';
    my $actor = $json->decode($json->encode($row->{actor_before}));
    my $before = $json->encode($actor);
    my $expected = $reasons{$row->{id}};
    die 'unowned case' unless defined $expected;
    @ReusableCauseSubject::assertions = ();
    @ReusableCauseSubject::errors = ();
    if ($is_direct) {
        $ReusableCauseSubject::a = $actor;
        ReusableCauseSubject::direct_consumer();
    } else {
        ReusableCauseSubject::refused($actor, $expected, "$row->{id} / $row->{band}");
    }
    my $count = $is_direct ? 1 : 2;
    for my $offset (0 .. $count - 1) {
        my $input = $fixtures->{rows}[$index + $offset];
        my $label = "$input->{id} / $input->{band} / $input->{method}";
        my @bits = @ReusableCauseSubject::assertions[$offset * 2, $offset * 2 + 1];
        is_deeply(\@bits, [1, $input->{band} eq 'current_fixture' ? 1 : 0],
            "$label qualifies only its complete cause");
        my $cause = (split /\n/, $input->{error})[0];
        is((split /\n/, $ReusableCauseSubject::errors[$offset])[0], $cause,
            "$label actual primary cause is conserved");
        is($json->encode($actor), $before, "$label preserves complete submitted actor and kinds");
        push @captures, {
            id => $input->{id}, band => $input->{band}, method => $input->{method},
            source => $input->{source}, actor => $json->decode($before),
            expected_cause => $expected, error => $ReusableCauseSubject::errors[$offset],
            assertions => \@bits,
        };
    }
    $index += $count;
}
if (defined $ENV{FSMGEN_REUSABLE_CAUSE_CAPTURE}) {
    open my $out, '>:raw', $ENV{FSMGEN_REUSABLE_CAUSE_CAPTURE} or die $!;
    print {$out} $json->encode({rows => \@captures}), "\n" or die $!;
    close $out or die $!;
}
done_testing;
