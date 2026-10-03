use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use FSM::Test::LocalFormalOriginAuthority;

my $base = 'docs/audits/local-formal-helper-causes-20261003';
my $json = JSON::PP->new->canonical;
sub read_json {
    open my $fh, '<:raw', $_[0] or die $!;
    my $raw = do { local $/; <$fh> };
    close $fh or die $!;
    return $json->decode($raw);
}
my $bound = read_json("$base/bindings.json");
my $positive = read_json("$base/positive_inputs.json");
my $cases = read_json("$base/causes.json");
open my $source_fh, '<:raw', 't/2052-isf-local-formal-origin-authority.t' or die $!;
my $source = do { local $/; <$source_fh> };
close $source_fh or die $!;
my $helper = substr($source, index($source, 'sub first_line {'),
    index($source, 'sub unrelated_refusal {') - index($source, 'sub first_line {'));
eval "package CurrentFormalCause; use FSM::Test::DiagnosticCause qw(diagnostic_cause_matches); $helper";
die $@ if $@;
eval 'package PriorFormalCause;' . $bound->{helper};
die $@ if $@;
eval $bound->{packages};
die $@ if $@;
delete $ENV{FSMGEN_FORMAL_DIAGNOSTIC_FULL_STACK};

my %reasons = (
    'equal-body origin transplant' => 'local formal origin proof differs from authoritative source',
    'actual clone callback lost' => 'local formal origin conditional clone association missing',
    'actual Storable callback lost' => 'local formal origin conditional clone association missing',
    'imported producer boundary' => 'conditional origin imported source authority is not qualified',
    'actor network boundary' => 'local formal origin reusable/network scope is not qualified',
    'generated transaction boundary' => 'local formal origin generated specialization is not qualified',
    'domain constructor boundary' => 'local formal origin domain scope is not qualified',
    'no formal preparation boundary' => 'local formal origin requires an unprojected direct formal',
);
my @captures;
for my $case (@{$cases->{rows}}) {
    my ($name, $band) = @{$case}{qw(id band)};
    my $input = $band eq 'positive' ? $positive->{$name} : $case->{input};
    my ($accepted, $error);
    if ($input->{api} eq 'from_source') {
        $accepted = eval { $input->{class}->from_source($input->{source}, $input->{label}); 1 };
        $error = $@;
    } else {
        my $authority = FSM::Test::LocalFormalOriginAuthority->from_source(
            $positive->{$name}{authority_source}, $positive->{$name}{authority_label});
        my $context = $json->decode($json->encode(
            $band eq 'positive' ? $input->{context} : $input->{base_context}));
        my $proof = $json->decode($json->encode($input->{proof}));
        if ($band ne 'positive') {
            my $mutation = $input->{mutation};
            if ($band eq 'wrong_context') {
                $context->{actor}{name} = $mutation->{value};
            } else {
                $context->{extra} = bless {}, $mutation->{class};
            }
        }
        $accepted = eval { $authority->validate($context, $proof); 1 };
        $error = $@;
    }
    # The expected pattern enters only the consumer, after the real API error.
    my $old_pattern = eval 'qr/' . $case->{pattern} . '/';
    die $@ if $@;
    my $current = CurrentFormalCause::diagnostic_matches($error, $reasons{$name});
    my $prior = PriorFormalCause::diagnostic_matches($error, $old_pattern);
    my $observed = $ENV{FSMGEN_LOCAL_FORMAL_CAUSE_PRIOR_HELPER} ? $prior : $current;
    ok(!$accepted, "$name / $band actually refuses");
    is($observed, $band eq 'positive' ? 1 : 0, "$name / $band has the declared complete cause");
    push @captures, {
        id => $name, band => $band, input => $input, error => $error,
        accepted => $accepted ? 1 : 0, current => $current ? 1 : 0,
        prior => $prior ? 1 : 0, expected_cause => $reasons{$name},
    };
}
if (defined $ENV{FSMGEN_LOCAL_FORMAL_CAUSE_CAPTURE}) {
    my $path = $ENV{FSMGEN_LOCAL_FORMAL_CAUSE_CAPTURE};
    open my $fh, '>:raw', $path or die $!;
    print {$fh} $json->encode({ rows => \@captures }), "\n" or die $!;
    close $fh or die $!;
}
done_testing;
