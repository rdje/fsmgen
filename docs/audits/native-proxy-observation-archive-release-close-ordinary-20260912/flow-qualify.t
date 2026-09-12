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
use ClosePlan;

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
my $vectors = $JSON->decode(raw("$FindBin::Bin/flow-vectors.json"));
my $pins = $JSON->decode(raw("$FindBin::Bin/flow-preflight-pins.json"));
for my $pin (@$pins) {
    my $bytes = raw("$ROOT/$pin->{path}");
    die "prospective binding source changed\n" unless length($bytes) == $pin->{size_bytes}
        && sha256_hex($bytes) eq $pin->{sha256};
}
my $out = "$ROOT/.artifacts/logs/native-proxy-observation-archive-release-close-ordinary-20260912/flow-qualification.json";
die "pure binding result already exists\n" if -e $out || -l $out;
my $result = {schema => 'fsmgen.release_close_binding_qualification.v1', success => JSON::PP::false,
    prospective_pins => $pins, variants => [], controls => [], allocated => []};
for my $profile (@{$vectors->{profiles}}) {
    for my $variant (@{$profile->{variants}}) {
        my $before = sha256_hex($JSON->encode([$profile->{context}, $profile->{reports}, $variant->{calls}]));
        my @resolved;
        for my $report (@{$profile->{reports}}) {
            my $bound = NativeProxyReleaseClosePlan::resolve($variant->{calls}, $profile->{context}, [$report]);
            die "single binding changed cardinality\n" unless @$bound == 1;
            push @resolved, $bound->[0];
        }
        my $id = "$profile->{profile}:$variant->{name}";
        is_deeply(\@resolved, $variant->{expected}, "$id: independently derived current ownership matches");
        my $after = sha256_hex($JSON->encode([$profile->{context}, $profile->{reports}, $variant->{calls}]));
        is($after, $before, "$id: input values and numeric/string representation remain unchanged");
        is_deeply(NativeProxyReleaseClosePlan::resolve($variant->{calls}, $profile->{context}, []), [], "$id: healthy selection resolves empty");
        push @{$result->{variants}}, {profile => $profile->{profile}, name => $variant->{name},
            resolved => scalar(@resolved), resolution_sha256 => sha256_hex($JSON->encode(\@resolved)), inputs_unchanged => $before eq $after ? 1 : 0};
    }
}
my $profile = $vectors->{profiles}[0]; my $calls = $profile->{variants}[0]{calls};
my @controls = (
    ['missing errno', sub { delete $_[0][0]{errno} }, 'close-report fields differ from the pinned contract'],
    ['stale numeric call', sub { $_[0][0]{call_id} = 0 }, 'close-report fields differ from the pinned contract'],
    ['unknown errno', sub { $_[0][0]{errno} = 'ENOSPC' }, 'unsupported close-report errno'],
    ['negative occurrence', sub { $_[0][0]{occurrence} = -1 }, 'invalid close-report occurrence'],
    ['string occurrence', sub { $_[0][0]{occurrence} = '0' }, 'invalid close-report occurrence'],
    ['boolean occurrence', sub { $_[0][0]{occurrence} = JSON::PP::true }, 'invalid close-report occurrence'],
    ['structured occurrence', sub { $_[0][0]{occurrence} = [] }, 'invalid close-report occurrence'],
    ['wrong address', sub { $_[0][0]{address} = 'invented' }, 'close-report address differs from its fields'],
    ['unknown opening', sub { $_[0][0]{symbol} = 'Foreign::_source'; $_[0][0]{address} = "$_[0][0]{kind}|Foreign::_source#$_[0][0]{occurrence}" }, 'duplicate or unknown close report'],
    ['multiple reports', sub { push @{$_[0]}, clone($_[0][0]) }, 'expected prospective flow, context and single close reports'],
);
for my $control (@controls) {
    my ($name, $change, $diagnostic) = @$control;
    my $reports = [clone($profile->{reports}[0])]; $change->($reports);
    my $ok = eval { NativeProxyReleaseClosePlan::resolve($calls, $profile->{context}, $reports); 1 };
    my $error = $@;
    ok(!$ok, "$name: rejected before resolution");
    is($error, "$diagnostic\n", "$name: exact closed-contract diagnostic");
    push @{$result->{controls}}, {name => $name, returned => $ok ? 1 : 0, error => $error};
}
is($forbidden, 0, 'pure resolution makes no process attempt');
$result->{forbidden_process_attempts} = $forbidden;
$result->{success} = Test::More->builder->is_passing ? JSON::PP::true : JSON::PP::false;
sysopen(my $fh, $out, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0600) or die "cannot write pure binding result: $!\n";
print {$fh} $JSON->pretty->encode($result) or die "cannot save pure binding result: $!\n";
close $fh or die "cannot close pure binding result: $!\n";
done_testing;
