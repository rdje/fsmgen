#!/usr/bin/env perl
use strict;
use warnings;
our ($forbidden, $lookups) = (0, 0);
BEGIN {
    *CORE::GLOBAL::fork = sub { ++$forbidden; die 'forbidden fork'; };
    *CORE::GLOBAL::system = sub { ++$forbidden; die 'forbidden system'; };
}
use FindBin;
use lib "$FindBin::Bin/../../../perl", "$FindBin::Bin/../../../t/lib",
    "$FindBin::Bin/../native-proxy-image-custody-20260910", $FindBin::Bin;
use JSON::PP ();
use Test::More;
use FSM::ProjectDataLocality qw(ensure_project_artifact_dir);
use FSM::Test::RustProxyFixture ();
BEGIN { *CORE::GLOBAL::exec = sub { ++$forbidden; die 'forbidden exec'; }; }
use RuntimeRecord;

my $json = JSON::PP->new->canonical->ascii;
open my $input, '<:raw', "$FindBin::Bin/vectors.json" or die "vectors: $!";
my $v = $json->decode(do { local $/; <$input> });
close $input or die "close vectors: $!";
my $log = ensure_project_artifact_dir(qw(logs native-proxy-runtime-records-20260910));
my $case = $v->{case};
my $encode = \&NativeProxyRuntimeRecord::encode_runtime_record;
my $decode = \&NativeProxyRuntimeRecord::decode_runtime_record;
my (@encoded, @controls, %mutants);

no warnings 'redefine';
local *FSM::Test::RustProxyFixture::supervise_process = sub { ++$forbidden; die 'forbidden compiler'; };
local *NativeProxyImageCustody::_directory = sub { ++$lookups; die 'unexpected filesystem lookup'; };
local *NativeProxyImageCustody::read_entry = sub { ++$lookups; die 'unexpected image lookup'; };

sub clone { return $json->decode($json->encode($_[0])); }
sub rejects {
    my ($name, $callback, $reason) = @_;
    my $ok = eval { $callback->(); 1 };
    my $error = $@;
    ok(!$ok && $error =~ $reason, $name) or diag($error || 'unexpected acceptance');
    push @controls, {name => $name, rejected => $ok ? 0 : 1,
                     expected_diagnostic => $error =~ $reason ? 1 : 0};
}
for my $vector (@{$v->{vectors}}) {
    my $bytes = $encode->($case, $vector->{record});
    is($bytes, $vector->{raw}, "independent Python bytes: $vector->{name}");
    is_deeply($decode->($case, $bytes), $vector->{record}, "decoded record: $vector->{name}");
    push @encoded, $bytes;
}
my $base = $v->{vectors}[0]{record};
for my $change (
    ['extra root field', sub { $_[0]{extra} = 0 }, qr/closed record/],
    ['missing root field', sub { delete $_[0]{image_key} }, qr/closed record/],
    ['merged root fields', sub {
        $_[0]{'image_key,reference_key'} = delete $_[0]{image_key}; delete $_[0]{reference_key};
    }, qr/closed record/],
    ['null root', sub { $_[0] = undef }, qr/closed record/],
    ['array root', sub { $_[0] = [] }, qr/closed record/],
    ['wrong schema', sub { $_[0]{schema} = 'fsmgen.test.rust_proxy_image_observation_reference.v1' }, qr/runtime reference schema/],
    ['boolean schema', sub { $_[0]{schema} = JSON::PP::true }, qr/JSON string/],
    ['uppercase image key', sub { $_[0]{image_key} = uc($_[0]{image_key}) }, qr/lowercase SHA/],
    ['short image key', sub { chop $_[0]{image_key} }, qr/lowercase SHA/],
    ['numeric digest', sub { $_[0]{image_key} = 123 }, qr/JSON string/],
    ['wrong reference key', sub { $_[0]{reference_key} = '0' x 64 }, qr/key differs/],
    ['wrong workspace identity', sub { $_[0]{workspace_identity}{path} .= 'other' }, qr/identity path differs/],
    ['unknown directory field', sub { $_[0]{workspace_identity}{extra} = 1 }, qr/closed record/],
    ['merged directory fields', sub {
        $_[0]{workspace_identity}{'device,inode'} = 17;
        delete @{$_[0]{workspace_identity}}{qw(device inode)};
    }, qr/closed record/],
    ['numeric string inode', sub { $_[0]{workspace_identity}{inode} = '101' }, qr/JSON integer/],
    ['boolean inode', sub { $_[0]{workspace_identity}{inode} = JSON::PP::true }, qr/JSON integer/],
    ['negative device', sub { $_[0]{workspace_identity}{device} = -1 }, qr/JSON integer/],
    ['fractional device', sub { $_[0]{workspace_identity}{device} = 0.5 }, qr/JSON integer/],
    ['null inode', sub { $_[0]{workspace_identity}{inode} = undef }, qr/JSON integer/],
    ['array inode', sub { $_[0]{workspace_identity}{inode} = [] }, qr/JSON integer/],
    ['source order', sub { @{$_[0]{selected_sources}} = reverse @{$_[0]{selected_sources}} }, qr/source path differs/],
    ['missing source', sub { pop @{$_[0]{selected_sources}} }, qr/source pair/],
    ['extra source', sub { push @{$_[0]{selected_sources}}, clone($_[0]{selected_sources}[0]) }, qr/source pair/],
    ['source map', sub { $_[0]{selected_sources} = {} }, qr/source pair/],
    ['source null', sub { $_[0]{selected_sources}[0] = undef }, qr/closed record/],
    ['extra source field', sub { $_[0]{selected_sources}[0]{extra} = 1 }, qr/closed record/],
    ['merged source fields padded', sub {
        my $s = $_[0]{selected_sources}[0];
        $s->{'device,inode'} = 17; $s->{padding} = 1; delete @$s{qw(device inode)};
    }, qr/closed record/],
    ['source byte ceiling', sub { $_[0]{selected_sources}[0]{size_bytes} = 65537 }, qr/source exceeds/],
    ['source size string', sub { $_[0]{selected_sources}[0]{size_bytes} = '50' }, qr/JSON integer/],
    ['source size boolean', sub { $_[0]{selected_sources}[0]{size_bytes} = JSON::PP::false }, qr/JSON integer/],
    ['source negative inode', sub { $_[0]{selected_sources}[1]{inode} = -1 }, qr/JSON integer/],
    ['source digest spelling', sub { $_[0]{selected_sources}[0]{sha256} = 'G' x 64 }, qr/lowercase SHA/],
    ['private source substitution', sub { $_[0]{selected_sources}[0]{path} = $_[0]{workspace} . '/rust-tools/rustup.c' }, qr/source path differs/],
    ['foreign image source', sub { $_[0]{selected_sources}[0]{path} =~ s{/images/[0-9a-f]+/}{'/images/' . ('0' x 64) . '/'}e }, qr/source path differs/],
) {
    my $record = clone($base);
    $change->[1]->($record);
    rejects($change->[0], sub { $encode->($case, $record) }, $change->[2]);
}
for my $path ('/absolute', '../escape', '.artifacts/tmp/process-supervisor-tests/fsmgen-A/../B',
              '.artifacts/tmp/process-supervisor-tests//fsmgen-A', "$base->{workspace}/", "$base->{workspace}\n",
              '.artifacts/cache/rust-proxy-images/v1', '.artifacts/tmp/process-supervisor-tests/fsmgen-A\\B') {
    my $record = clone($base);
    $record->{workspace} = $path;
    (my $label = $path) =~ s/\n/\\n/g;
    rejects("workspace path $label", sub { $encode->($case, $record) }, qr/private workspace/);
}
for my $path ('/absolute', "$case/../other", "$case/", "$case\n", '.artifacts/cache/rust-proxy-images/v1') {
    (my $label = $path) =~ s/\n/\\n/g;
    rejects("case path $label", sub { $encode->($path, $base) }, qr/inactive image case/);
}
my $raw = $v->{vectors}[0]{raw};
for my $spelling (
    ['trailing newline', "$raw\n", qr/not canonical/],
    ['whitespace', ' ' . $raw, qr/not canonical/],
    ['duplicate root member', '{"schema":"discarded",' . substr($raw, 1), qr/not canonical/],
    ['duplicate nested member', $raw =~ s/"workspace_identity":\{/"workspace_identity":{"inode":0,/r, qr/not canonical/],
    ['noncanonical fraction', $raw =~ s/"inode":101/"inode":101.0/r, qr/not canonical/],
    ['noncanonical exponent', $raw =~ s/"inode":101/"inode":1.01e2/r, qr/not canonical/],
    ['noncanonical escaped ASCII', $raw =~ s/"workspace":/"worksp\\u0061ce":/r, qr/not canonical/],
    ['invalid JSON', '{', qr/invalid runtime JSON/],
    ['deep JSON', '[' x 20 . '0' . ']' x 20, qr/invalid runtime JSON/],
    ['raw non-ASCII', "\xff", qr/bounded ASCII/],
    ['record decode ceiling', ' ' x 4097, qr/bounded ASCII/],
) {
    rejects($spelling->[0], sub { $decode->($case, $spelling->[1]) }, $spelling->[2]);
}
my $wide = $raw; utf8::upgrade($wide);
rejects('character rather than byte input', sub { $decode->($case, $wide) }, qr/bounded ASCII/);
rejects('reference rather than byte input', sub { $decode->($case, []) }, qr/bounded ASCII/);
rejects('extra positional argument', sub { $encode->($case, $base, 'extra') }, qr/expected isolated/);
rejects('missing decode argument', sub { $decode->($case) }, qr/expected isolated/);
my $oversized = clone($v->{vectors}[2]{record});
$oversized->{workspace_identity}{inode} *= 10;
rejects('record encode ceiling', sub { $encode->($case, $oversized) }, qr/record exceeds/);
my $source_boundary = clone($base);
$source_boundary->{selected_sources}[0]{size_bytes} = 65536;
ok(defined($encode->($case, $source_boundary)), 'source ceiling is structural policy, not measured bytes');

{
    local *NativeProxyRuntimeRecord::_fields = sub { die 'not a map' unless ref($_[0]) eq 'HASH' };
    my $record = clone($base); $record->{extra} = 0;
    my $bytes = $encode->($case, $record);
    ok(exists($json->decode($bytes)->{extra}), 'removed field closure admits independently invalid member');
    $mutants{'omitted field closure'} = {accepted_by_mutant => 1, raw => $bytes};
}
{
    local *NativeProxyRuntimeRecord::_reference_key = sub { return };
    my $record = clone($base); $record->{reference_key} = '0' x 64;
    my $bytes = $encode->($case, $record);
    isnt($json->decode($bytes)->{reference_key}, $base->{reference_key},
          'removed key derivation admits independently invalid reference');
    $mutants{'omitted key derivation'} = {accepted_by_mutant => 1, raw => $bytes};
}
is($lookups, 0, 'codec does not invoke current filesystem custody');
is($forbidden, 0, 'no compiler or process attempt');
my $success = Test::More->builder->is_passing;
open my $output, '>:raw', "$log/qualification.json" or die "result: $!";
print {$output} $json->pretty->encode({schema => 'fsmgen.inactive_runtime_record_qualification.v1',
    success => $success ? JSON::PP::true : JSON::PP::false,
    encoded => \@encoded, controls => \@controls, mutants => \%mutants,
    forbidden_process_attempts => $forbidden, filesystem_lookup_attempts => $lookups}) or die "write result: $!";
close $output or die "close result: $!";
done_testing;
