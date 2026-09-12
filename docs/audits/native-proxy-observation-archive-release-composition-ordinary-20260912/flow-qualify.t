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
use CompositionPlan;

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
my $out = "$ROOT/.artifacts/logs/native-proxy-observation-archive-release-composition-ordinary-20260912/flow-qualification.json";
die "pure binding result already exists\n" if -e $out || -l $out;
my $result = {schema => 'fsmgen.release_composition_binding_qualification.v1', success => JSON::PP::false,
    prospective_pins => $pins, variants => [], controls => [], allocated => []};
for my $profile (@{$vectors->{profiles}}) {
    for my $variant (@{$profile->{variants}}) {
        my $before = sha256_hex($JSON->encode([$profile->{context}, $profile->{recipes}, $variant->{calls}]));
        my @resolved = map { NativeProxyReleaseCompositionPlan::resolve(
            $variant->{calls}, $profile->{context}, $_) } @{$profile->{recipes}};
        my $id = "$profile->{profile}:$variant->{name}";
        is_deeply(\@resolved, $variant->{expected}, "$id: independent current-flow composition agrees");
        my $after = sha256_hex($JSON->encode([$profile->{context}, $profile->{recipes}, $variant->{calls}]));
        is($after, $before, "$id: input bytes and numeric/string representations remain unchanged");
        push @{$result->{variants}}, {profile => $profile->{profile}, name => $variant->{name},
            resolved => scalar(@resolved), resolution_sha256 => sha256_hex($JSON->encode(\@resolved)),
            inputs_unchanged => $before eq $after ? 1 : 0};
        unless (Test::More->builder->is_passing) {
            $result->{success} = JSON::PP::false;
            sysopen(my $failed, $out, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0600) or die "cannot save first resolver failure: $!\n";
            print {$failed} $JSON->pretty->encode($result) or die "cannot write first resolver failure: $!\n";
            close $failed or die "cannot close first resolver failure: $!\n";
            BAIL_OUT('first pure composition mismatch retained before any fixture');
        }
    }
}
my $profile = $vectors->{profiles}[0]; my $calls = $profile->{variants}[0]{calls};
my @controls = (
    ['missing kind', sub { delete $_[0]{kind} }, 'composition recipe fields differ'],
    ['stale numeric call', sub { $_[0]{call_id} = 0 }, 'composition recipe fields differ'],
    ['structured kind', sub { $_[0]{kind} = [] }, 'composition recipe text is missing or structured'],
    ['missing order', sub { $_[0]{order} = undef }, 'composition recipe text is missing or structured'],
    ['unknown order', sub { $_[0]{order} = 'random' }, 'unknown composition declaration order'],
    ['missing scope', sub { $_[0]{scope} = undef }, 'composition scope is missing or structured'],
    ['structured scope', sub { $_[0]{scope} = {} }, 'composition scope is missing or structured'],
    ['foreign scope', sub { $_[0]{scope} = 'Foreign::_close' }, 'unknown composition kind or scope'],
    ['foreign kind', sub { $_[0]{kind} = 'all-errors' }, 'unknown composition kind or scope'],
    ['scoped healthy', sub { $_[0]{kind} = 'healthy' }, 'healthy composition carries a scope or order'],
);
for my $control (@controls) {
    my ($name, $change, $diagnostic) = @$control;
    my $recipe = clone($profile->{recipes}[1]); $change->($recipe);
    my $ok = eval { NativeProxyReleaseCompositionPlan::resolve($calls, $profile->{context}, $recipe); 1 };
    my $error = $@;
    ok(!$ok, "$name: rejected before flow resolution");
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
