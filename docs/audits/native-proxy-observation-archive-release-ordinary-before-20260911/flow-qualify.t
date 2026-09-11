#!/usr/bin/env perl
use strict;
use warnings;
our $forbidden = 0;
BEGIN {
    *CORE::GLOBAL::fork = sub { ++$forbidden; die 'forbidden fork'; };
    *CORE::GLOBAL::system = sub { ++$forbidden; die 'forbidden system'; };
    *CORE::GLOBAL::exec = sub { ++$forbidden; die 'forbidden exec'; };
}
use FindBin;
use lib "$FindBin::Bin/../../../perl", $FindBin::Bin;
use Digest::SHA qw(sha256_hex);
use JSON::PP ();
use Test::More;
use FSM::ProjectDataLocality qw(repository_root ensure_project_artifact_dir);
use CallPlan;

my $ROOT = repository_root();
my $JSON = JSON::PP->new->canonical->ascii;
sub read_raw {
    open my $fh, '<:raw', $_[0] or die "flow input: $!\n";
    my $raw = do { local $/; <$fh> }; close $fh or die "flow input close: $!\n"; return $raw;
}
sub copy { return $JSON->decode($JSON->encode($_[0])); }
sub signature { return sha256_hex($JSON->encode($_[0])); }
my $plan = $JSON->decode(read_raw("$FindBin::Bin/plan.json"));
my $vectors = $JSON->decode(read_raw("$FindBin::Bin/flow-vectors.json"));
my $pins = $JSON->decode(read_raw("$FindBin::Bin/flow-preflight-pins.json"));
for my $pin (@$pins, @{$plan->{inputs}}) {
    my $raw = read_raw("$ROOT/$pin->{path}");
    die "pure flow input differs from prospective pin\n"
        unless length($raw) == $pin->{size_bytes} && sha256_hex($raw) eq $pin->{sha256};
}
my $log = ensure_project_artifact_dir('logs', $plan->{component});
my $result = {schema => 'fsmgen.release_call_flow_qualification.v1', success => JSON::PP::false,
    prospective_pins => $pins, baselines => [], order_skeletons => [], rejected_selectors => [], allocated => []};
my %sealed = map { $_ => 1 } @{$vectors->{sealed_symbols}};
sub save {
    $result->{forbidden_process_attempts} = $forbidden;
    open my $fh, '>:raw', "$log/flow-qualification.json" or die "flow result: $!\n";
    print {$fh} JSON::PP->new->canonical->ascii->pretty->encode($result) or die "flow result write: $!\n";
    close $fh or die "flow result close: $!\n";
}

sub derive_checked {
    my ($label, $context, $before, $specification, $expected, $rows) = @_;
    my $input = signature([$context, $before, $specification]);
    my $calls = eval { NativeProxyReleaseCallPlan::derive($context, $before, $specification) };
    my $error = $@; $error =~ s/\Q$ROOT\E/./g;
    my $row = {name => $label, error => $error, calls => defined($calls) ? scalar(@$calls) : undef,
        flow_sha256 => defined($calls) ? signature($calls) : undef,
        inputs_unchanged => signature([$context, $before, $specification]) eq $input ? 1 : 0};
    my $matches = defined($calls) && !length($error) && $row->{calls} == $expected->{calls}
        && $row->{flow_sha256} eq $expected->{flow_sha256} && $row->{inputs_unchanged};
    $row->{first_unexpected_flow} = $calls unless $matches;
    push @$rows, $row; save();
    ok($matches, "$label: exact independent flow and unchanged inputs") or diag($error);
    BAIL_OUT('first prospective flow failure retained before any fixture') unless $matches;
    return $calls;
}

save();
my ($first_calls, $first_vector);
for my $vector (@{$vectors->{cases}}) {
    my $profile = $vector->{profile_id};
    my $calls = derive_checked($profile, @$vector{qw(context before specification)}, $vector, $result->{baselines});
    ($first_calls, $first_vector) = ($calls, $vector) unless defined($first_calls);
    my $selectors_before = signature($vector->{selectors});
    my @resolved;
    for my $selected (@{$vector->{selectors}}) {
        my $resolved = eval { NativeProxyReleaseCallPlan::resolve($calls, $selected, \%sealed) };
        my $error = $@;
        push @resolved, {address => $selected->{address}, resolution => $resolved, error => $error};
        unless (defined($resolved) && !length($error) && $resolved->{call_id} == $selected->{source_call_id}
                && $resolved->{address} eq $selected->{address}) {
            $result->{first_resolution_failure} = \@resolved; save();
            fail("$profile: exact current call resolution"); BAIL_OUT('first resolver failure retained');
        }
    }
    $result->{baselines}[-1]{resolved_selectors} = scalar(@resolved);
    $result->{baselines}[-1]{resolution_sha256} = signature(\@resolved);
    $result->{baselines}[-1]{selectors_unchanged} = signature($vector->{selectors}) eq $selectors_before ? 1 : 0;
    save(); ok($result->{baselines}[-1]{selectors_unchanged}, "$profile: every typed selector resolves without input changes");
    for my $expected (@{$vector->{order_skeletons}}) {
        my ($context, $before) = map { copy($_) } @$vector{qw(context before)};
        my @names = sort grep { m{\Areferences/} } keys %{$before->{store}};
        my %records = map { $_ => delete $before->{store}{$_} } @names;
        my $store = $context->{store}{path};
        my $hold = $context->{acquired}{observation_reference}{source}{identity}; my $original = $hold->{path};
        for my $rank (0..$#names) {
            my $name = $names[$expected->{order}[$rank]];
            my $renamed = 'references/'.sprintf('%064x', $rank).'.json';
            $before->{store}{$renamed} = $records{$name};
            $hold->{path} = "$store/$renamed" if "$store/$name" eq $original;
        }
        my $label = "$profile:order:".join(',', @{$expected->{order}});
        derive_checked($label, $context, $before, $vector->{specification}, $expected, $result->{order_skeletons});
    }
}

my @negative = (
    ['missing address', sub { delete $_[0]{address}; }],
    ['stale numeric target', sub { $_[0]{runtime_call_id} = 0; }],
    ['negative occurrence', sub { $_[0]{occurrence} = -1; }],
    ['leading-zero occurrence', sub { $_[0]{occurrence} = '00'; }],
    ['out-of-domain occurrence', sub { $_[0]{occurrence} = 999; }],
    ['undefined occurrence', sub { $_[0]{occurrence} = undef; }],
    ['structured occurrence', sub { $_[0]{occurrence} = []; }],
    ['unknown helper', sub { $_[0]{symbol} = 'Foreign::helper'; }],
    ['unknown phase', sub { $_[0]{phase} = 'during'; }],
    ['wrong address', sub { $_[0]{address} = 'foreign'; }],
);
for my $special ('source return', 'sealed return') {
    my $symbol = $special eq 'source return' ? 'NativeProxyImageCustody::_source' : 'NativeProxyObservationRelease::_unlink_exact';
    my ($original) = grep { $_->{symbol} eq $symbol && $_->{phase} eq 'before' } @{$first_vector->{selectors}};
    my $selected = copy($original); $selected->{phase} = 'after';
    $selected->{address} = "$symbol#$selected->{occurrence}:after";
    push @negative, [$special, sub { %{$_[0]} = %$selected; }];
}
for my $control (@negative) {
    my $selected = copy($first_vector->{selectors}[0]); $control->[1]->($selected);
    my $input = signature($selected);
    my $returned = eval { NativeProxyReleaseCallPlan::resolve($first_calls, $selected, \%sealed); 1 };
    my $error = $@;
    my $row = {name => $control->[0], returned => $returned ? 1 : 0, error => $error,
        inputs_unchanged => signature($selected) eq $input ? 1 : 0};
    push @{$result->{rejected_selectors}}, $row; save();
    ok(!$row->{returned} && length($error) && $row->{inputs_unchanged}, "$control->[0]: rejects before any fixture")
        or BAIL_OUT('first malformed selector acceptance retained');
}
is($forbidden, 0, 'no process attempt in pure flow qualification');
$result->{success} = Test::More->builder->is_passing ? JSON::PP::true : JSON::PP::false;
save(); done_testing;
