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
use lib $FindBin::Bin;
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use Fcntl qw(O_WRONLY O_CREAT O_EXCL O_NOFOLLOW S_ISREG);
use JSON::PP ();
use Test::More;
use OmissionPlan;

my $ROOT = abs_path("$FindBin::Bin/../../..");
my $JSON = JSON::PP->new->canonical->ascii;
sub raw {
    my ($path) = @_;
    die "pure binding path leaves repository\n" unless index($path, "$ROOT/") == 0;
    my @native = lstat($path);
    die "pure binding input is not a direct same-volume file\n" unless @native && S_ISREG($native[2])
        && $native[0] == (stat($ROOT))[0] && abs_path($path) eq $path;
    open my $fh, '<:raw', $path or die "cannot read pure binding input: $!\n";
    local $/; my $bytes = <$fh>;
    close $fh or die "cannot close pure binding input: $!\n";
    return $bytes;
}
sub clone { return $JSON->decode($JSON->encode($_[0])); }
my $plan = $JSON->decode(raw("$FindBin::Bin/plan.json"));
my $pins = $JSON->decode(raw("$FindBin::Bin/binding-pins.json"));
for my $pin (@$pins, @{$plan->{inputs}}) {
    my $bytes = raw("$ROOT/$pin->{path}");
    die "omission binding source changed\n" unless length($bytes) == $pin->{size_bytes}
        && sha256_hex($bytes) eq $pin->{sha256};
}
my $vectors = $JSON->decode(raw("$ROOT/$plan->{binding_vectors}"));
my $out = "$ROOT/.artifacts/logs/$plan->{component}/binding.json";
die "omission binding result already exists\n" if -e $out || -l $out;
my $result = {schema => 'fsmgen.release_omission_binding.v1', success => JSON::PP::false,
    prospective_pins => $pins, variants => [], controls => [], allocated => []};
my %selected = map { $_->{id} => $_ } @{$plan->{binding_profiles}};
for my $profile (@{$vectors->{profiles}}) {
    my $cases = $selected{$profile->{profile}}{cases};
    die "binding profile missing\n" unless $cases;
    for my $variant (@{$profile->{variants}}) {
        my $before = sha256_hex($JSON->encode([$profile->{context}, $cases, $variant->{calls}]));
        my @resolved;
        for my $case (@$cases) {
            my $targets = NativeProxyReleaseOmissionPlan::resolve($variant->{calls}, $profile->{context}, $case->{recipe});
            push @resolved, {case_index => $case->{index}, targets => $targets};
        }
        my $id = "$profile->{profile}:$variant->{name}";
        is_deeply($resolved[0]{targets}, [], "$id: healthy resolves without a target");
        ok(@resolved == @$cases && !grep({ @{$_->{targets}} != 1 } @resolved[1..$#resolved]),
            "$id: each omission resolves exactly one current target");
        my $after = sha256_hex($JSON->encode([$profile->{context}, $cases, $variant->{calls}]));
        is($after, $before, "$id: input bytes and types remain unchanged");
        push @{$result->{variants}}, {profile => $profile->{profile}, name => $variant->{name},
            resolutions => \@resolved, inputs_unchanged => $before eq $after ? 1 : 0};
    }
}
my $profile = $vectors->{profiles}[0]; my $calls = $profile->{variants}[0]{calls};
my $recipe = $selected{$profile->{profile}}{cases}[1]{recipe};
my @controls = (
    ['missing field', sub { delete $_[0]{scope} }, 'omission recipe fields differ from the pinned contract'],
    ['stale numeric call', sub { $_[0]{call_id} = 0 }, 'omission recipe fields differ from the pinned contract'],
    ['archived label', sub { $_[0]{label} = 'source:0' }, 'omission recipe fields differ from the pinned contract'],
    ['unknown kind', sub { $_[0]{kind} = 'report' }, 'unsupported omission recipe kind'],
    ['structured kind', sub { $_[0]{kind} = [] }, 'invalid omission recipe kind'],
    ['healthy with target', sub { $_[0]{kind} = 'healthy' }, 'healthy omission recipe carries a target'],
    ['missing target', sub { $_[0]{scope} = undef }, 'invalid omission target'],
    ['structured target', sub { $_[0]{scope} = [] }, 'invalid omission target'],
    ['foreign scope', sub { $_[0]{scope} = 'Foreign::_close' }, 'unknown omission scope or handle kind'],
    ['wrong handle kind', sub { $_[0]{handle_kind} = 'foreign' }, 'unknown omission scope or handle kind'],
);
for my $control (@controls) {
    my ($name, $change, $diagnostic) = @$control;
    my $changed = clone($recipe); $change->($changed);
    my $ok = eval { NativeProxyReleaseOmissionPlan::resolve($calls, $profile->{context}, $changed); 1 };
    my $error = $@;
    ok(!$ok, "$name: rejected before resolution");
    is($error, "$diagnostic\n", "$name: exact closed-contract diagnostic");
    push @{$result->{controls}}, {name => $name, returned => $ok ? 1 : 0, error => $error};
}
is($forbidden, 0, 'pure omission resolution makes no process attempt');
$result->{forbidden_process_attempts} = $forbidden;
$result->{success} = Test::More->builder->is_passing ? JSON::PP::true : JSON::PP::false;
sysopen(my $fh, $out, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0600) or die "cannot write binding result: $!\n";
print {$fh} $JSON->pretty->encode($result) or die "cannot save binding result: $!\n";
close $fh or die "cannot close binding result: $!\n";
done_testing;
