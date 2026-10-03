use strict;
use warnings;
use lib 'perl';
use JSON::PP;
use Scalar::Util qw(refaddr blessed reftype);
use FSM::Scheduler::ISF::FormalReservationCoverage;
use Test::More;

my $base = 'docs/audits/reservation-coverage-cause-diagnosis-20261003';
my $json = JSON::PP->new->canonical;
sub read_json {
    my ($path) = @_;
    open my $file, '<:raw', $path or die $!;
    my $value = $json->decode(do {local $/; <$file>});
    close $file or die $!;
    return $value;
}
my $profile = read_json('docs/audits/reservation-coverage-helper-causes-20261003/initial-observations-unqualified.json');
my $causes = read_json('docs/audits/reservation-coverage-helper-causes-20261003/declared-causes.json');

sub escape_key {
    my ($key) = @_;
    $key =~ s/~/~0/g;
    $key =~ s{/}{~1}g;
    return $key;
}
sub restore {
    my ($value, $nodes, $path) = @_;
    return $value unless ref($value);
    $nodes ||= {}; $path //= '';
    die 'malformed graph node' unless ref($value) eq 'ARRAY' && @$value == 2;
    my ($kind, $body) = @$value;
    if ($kind eq 'reference') {
        die 'missing first-touch reference' unless exists $nodes->{$body};
        return $nodes->{$body};
    }
    if ($kind eq 'hash') {
        die 'malformed graph hash' unless ref($body) eq 'HASH';
        my $out = {}; $nodes->{$path} = $out;
        for my $key (sort keys %$body) {
            $out->{$key} = restore($body->{$key}, $nodes, $path . '/' . escape_key($key));
        }
        return $out;
    }
    if ($kind eq 'array') {
        die 'malformed graph array' unless ref($body) eq 'ARRAY';
        my $out = []; $nodes->{$path} = $out;
        push @$out, restore($body->[$_], $nodes, "$path/$_") for 0..$#$body;
        return $out;
    }
    die 'undeclared graph node';
}
sub graph {
    my ($value, $seen, $path) = @_;
    return $value unless ref($value);
    $seen ||= {}; $path //= '';
    my $address = refaddr($value);
    return ['reference', $seen->{$address}] if exists $seen->{$address};
    $seen->{$address} = $path;
    if (blessed($value)) {
        die 'undeclared native marker' unless blessed($value) eq 'CoverageCauseSentinel'
            && reftype($value) eq 'HASH' && !keys %$value;
        return ['blessed', 'CoverageCauseSentinel'];
    }
    if (ref($value) eq 'HASH') {
        return ['hash', {map {$_ => graph($value->{$_}, $seen,
            $path . '/' . escape_key($_))} sort keys %$value}];
    }
    return ['array', [map {graph($value->[$_], $seen, "$path/$_")} 0..$#$value]]
        if ref($value) eq 'ARRAY';
    die 'undeclared native reference';
}

open my $file, '<:raw', 't/1960-isf-formal-reservation-coverage.t' or die $!;
my $test = do {local $/; <$file>}; close $file or die $!;
my $start = index($test, 'sub reject {');
my $end = index($test, "subtest 'missing declarations", $start);
die 'exact coverage helper missing' unless $start >= 0 && $end > $start;
my $helper = substr($test, $start, $end - $start);
$start = index($test, 'for my $case (', $end);
$end = index($test, "    ) {\n", $start);
die 'exact QR case declarations missing' unless $start >= 0 && $end > $start;
my $cases = substr($test, $start + length('for my $case ('),
    $end - $start - length('for my $case ('));
my ($stale) = $test =~ /reject\(\$prepared, \$bad_plan, \$modules, (qr\/.+?\/), 'stale or incomplete allocation'\)/;
my ($omitted) = $test =~ /reject\(\$incomplete, \$same_plan, \$modules, (qr\/.+?\/), 'omitted real producer declaration'\)/;
die 'exact direct QR declarations missing' unless defined $stale && defined $omitted;

{
    package RealCoverageConsumer;
    use Test::More;
    use Storable qw(dclone);
    our ($band, @decisions, @errors, @incoming, @accepted, @results);
    sub verify {
        my ($result, $error);
        my $ok = eval {
            $result = FSM::Scheduler::ISF::FormalReservationCoverage->verify(@_);
            1;
        };
        $error = $@;
        push @errors, $error;
        push @accepted, $ok ? 1 : 0;
        push @results, $ok ? main::graph($result) : undef;
        die $error unless $ok;
        return $result;
    }
    no warnings 'redefine';
    sub like ($$;$) {
        my ($error, $pattern, $label) = @_;
        my $match = $error =~ $pattern ? 1 : 0;
        push @decisions, $match; push @incoming, $error;
        return Test::More::is($match, $band eq 'current_fixture' ? 1 : 0,
            "$label: matches only the intended cause");
    }
}
# Compile exact original helper/QR declarations before native calls. The mutation
# closures in the original table are compiled but not executed; inputs come from
# the complete authenticated native profile. No source eval remains on the stack.
my $program = 'package RealCoverageConsumer;' . $helper
    . 'sub patterns {my $private = "isf_port_main_payload_formal"; my $helper = "main_wait_4_cnt"; my @cases = ('
    . $cases . '); return (map {[$_->[2], $_->[1]]} @cases), '
    . '["stale or incomplete allocation",' . $stale . '],'
    . '["omitted real producer declaration",' . $omitted . '];}';
eval $program; die $@ if $@;
my %patterns = map {@$_} RealCoverageConsumer::patterns();
die 'wrong QR membership' unless keys(%patterns) == @{$profile->{consumers}};
my @rows;
for my $consumer (@{$profile->{consumers}}) {
    my $label = $consumer->{label}; $label =~ s/ diagnosed$//;
    my $pattern = $patterns{$label} // die 'undeclared exact QR';
    die 'exact QR flag/spelling drift' unless "$pattern" eq $consumer->{pattern};
    my $expected = $causes->{$label} // die 'undeclared complete cause';
    for my $band (qw(current_fixture earlier_reference primary_path_echo)) {
        my $input = restore($profile->{api}[$consumer->{api_index}]{before});
        my $original = graph($input);
        my $marker;
        if ($band ne 'current_fixture') {
            $marker = bless {}, 'CoverageCauseSentinel';
            my $value = $marker;
            if ($band eq 'primary_path_echo') {
                # Separate keys preserve actual JSON-pointer slash separators.
                for my $key (reverse split m{/}, $expected, -1) {$value = {$key => $value}}
            }
            die 'unexpected earlier-reference key' if exists $input->[0]{_early_reference};
            $input->[0]{_early_reference} = $value;
        }
        my $before = graph($input);
        my $marker_before = defined($marker) ? refaddr($marker) : undef;
        @RealCoverageConsumer::decisions = ();
        @RealCoverageConsumer::errors = ();
        @RealCoverageConsumer::incoming = ();
        @RealCoverageConsumer::accepted = ();
        @RealCoverageConsumer::results = ();
        $RealCoverageConsumer::band = $band;
        RealCoverageConsumer::reject(@$input, $pattern, "$label / $band");
        die 'wrong actual consumer cardinality' unless @RealCoverageConsumer::errors == 1
            && @RealCoverageConsumer::decisions == 1 && @RealCoverageConsumer::incoming == 1;
        is($RealCoverageConsumer::incoming[0], $RealCoverageConsumer::errors[0],
            "$label / $band: actual complete native error retained");
        is($json->encode(graph($input)), $json->encode($before),
            "$label / $band: original graph values/kinds/sharing retained");
        my $marker_after;
        if (defined($marker)) {
            my $observed = $input->[0]{_early_reference};
            if ($band eq 'primary_path_echo') {
                for my $key (split m{/}, $expected, -1) {$observed = $observed->{$key}}
            }
            $marker_after = refaddr($observed);
            die 'native marker identity/shape changed' unless defined($marker_after)
                && $marker_before == $marker_after && blessed($observed) eq 'CoverageCauseSentinel'
                && reftype($observed) eq 'HASH' && !keys %$observed;
        }
        push @rows, {label => $label, band => $band, api_index => $consumer->{api_index},
            expected_cause => $expected, pattern => "$pattern", original => $original,
            before => $before, after => graph($input), error => $RealCoverageConsumer::errors[0],
            incoming_error => $RealCoverageConsumer::incoming[0], matched => $RealCoverageConsumer::decisions[0],
            accepted => $RealCoverageConsumer::accepted[0], result => $RealCoverageConsumer::results[0],
            marker_before => $marker_before, marker_after => $marker_after};
    }
}
open $file, '>:raw', "$base/observations-unqualified.json" or die $!;
print {$file} $json->encode({helper => $helper, qr_program => $program, rows => \@rows}), "\n" or die $!;
close $file or die $!;
done_testing;
