#!/usr/bin/env perl
use strict;
use warnings;
our ($forbidden, $lookups) = (0, 0);
BEGIN {
    *CORE::GLOBAL::fork = sub { ++$forbidden; die 'forbidden fork'; };
    *CORE::GLOBAL::system = sub { ++$forbidden; die 'forbidden system'; };
}
use FindBin;
use lib "$FindBin::Bin/../../../perl", "$FindBin::Bin/../../../t/lib", $FindBin::Bin,
    map { "$FindBin::Bin/../$_" } qw(native-proxy-image-custody-20260910
        native-proxy-image-coordination-20260910 native-proxy-image-publication-20260910
        native-proxy-runtime-records-20260910 native-proxy-runtime-census-20260910
        native-proxy-observation-records-20260910 native-proxy-observation-acquisition-20260910
        native-proxy-observation-archive-records-20260911 native-proxy-observation-archive-20260911);
use Digest::SHA qw(sha256_hex);
use JSON::PP ();
use Test::More;
use FSM::ProjectDataLocality qw(ensure_project_artifact_dir);
use FSM::Test::RustProxyFixture ();
BEGIN { *CORE::GLOBAL::exec = sub { ++$forbidden; die 'forbidden exec'; }; }
use Coordination;
use ObservationArchive;

my $ROOT = FSM::Test::ProcessSupervisor::repository_root();
my $JSON = JSON::PP->new->canonical->ascii;
sub read_bytes {
    open my $fh, '<:raw', $_[0] or die "input open: $!";
    my $raw = do { local $/; <$fh> }; close $fh or die "input close: $!"; return $raw;
}
my $plan = $JSON->decode(read_bytes("$FindBin::Bin/plan.json"));
my $pins = $JSON->decode(read_bytes("$FindBin::Bin/preflight-pins.json"));
for my $pin (@$pins, @{$plan->{inputs}}) {
    my $raw = read_bytes("$ROOT/$pin->{path}");
    die "prospective guard input changed\n" unless length($raw) == $pin->{size_bytes} && sha256_hex($raw) eq $pin->{sha256};
}
my $log = ensure_project_artifact_dir(qw(logs native-proxy-observation-archive-guards-20260911));
die "preserve the first guard qualification\n" if -e "$log/qualification.json" || -l "$log/qualification.json";
my $result = {schema => 'fsmgen.inactive_archive_guards_qualification.v1', success => JSON::PP::false, cases => []};
sub save_result {
    $result->{forbidden_process_attempts} = $forbidden;
    $result->{forbidden_lookup_attempts} = $lookups;
    open my $fh, '>:raw', "$log/qualification.json" or die "result open: $!";
    print {$fh} JSON::PP->new->canonical->ascii->pretty->encode($result) or die "result write: $!";
    close $fh or die "result close: $!";
}

# The tested helper only calls the pure byte validator. These are the original
# prototype filesystem/process entry points; qualification output I/O is separate.
no warnings 'redefine';
local *FSM::Test::RustProxyFixture::supervise_process = sub { ++$forbidden; die 'forbidden process'; };
local *FSM::Test::RustProxyFixture::_read_file = sub { ++$lookups; die 'forbidden file read'; };
local *NativeProxyImageCustody::_directory = sub { ++$lookups; die 'forbidden directory lookup'; };
local *NativeProxyImageCustody::_source = sub { ++$lookups; die 'forbidden source lookup'; };
local *NativeProxyImageCustody::read_entry = sub { ++$lookups; die 'forbidden image lookup'; };
local *NativeProxyImagePublication::_write_payload = sub { ++$lookups; die 'forbidden publication'; };
local *NativeProxyImageCoordination::_transaction = sub { ++$lookups; die 'forbidden coordination'; };
local *NativeProxyImageCoordination::_names = sub { ++$lookups; die 'forbidden namespace read'; };
local *NativeProxyObservationAcquisition::_prior_directory = sub { ++$lookups; die 'forbidden prior directory'; };

sub materialize {
    my ($recipe) = @_;
    return undef if $recipe->{kind} eq 'undefined';
    return [1] if $recipe->{kind} eq 'reference';
    if ($recipe->{kind} eq 'utf8') { my $value = 'u' x 12; utf8::upgrade($value); return $value; }
    die "unknown guard recipe\n" unless $recipe->{kind} eq 'raw';
    return $recipe->{pattern} eq 'binary' ? pack('C*', 0..255) : 'x' x $recipe->{size};
}
sub signature {
    my ($value) = @_;
    my $reference = ref($value);
    my ($size, $digest);
    if (defined($value) && !$reference) {
        my $bytes = $value;
        utf8::downgrade($bytes, 1) or die "signature byte projection failed\n";
        $size = 0 + length($bytes); $digest = sha256_hex($bytes);
    }
    return {defined => defined($value) ? 1 : 0, reference => $reference,
        utf8 => utf8::is_utf8($value) ? 1 : 0, size_bytes => $size, sha256 => $digest,
        reference_value => $reference ? $JSON->encode($value) : undef};
}

my $validator = \&NativeProxyImageCustody::_bytes;
for my $selection (@{$plan->{cases}}) {
    my $spec = {files => [map { +{bytes => materialize($_)} } @{$selection->{values}}]};
    my $before = [map { signature($_->{bytes}) } @{$spec->{files}}];
    my @calls;
    local *NativeProxyImageCustody::_bytes = sub {
        my ($value, $limit) = @_;
        my $call = {index => scalar(@calls), limit => 0 + $limit, input => signature($value)};
        push @calls, $call;
        my $returned;
        my $ok = eval { $returned = $validator->(@_); 1; };
        my $error = $@;
        $call->{returned} = $ok ? 1 : 0; $call->{error} = $error;
        die $error unless $ok;
        return $returned;
    };
    my $ok = eval { NativeProxyObservationArchive::_limits($spec); 1; };
    my $error = $@;
    my $after = [map { signature($_->{bytes}) } @{$spec->{files}}];
    push @{$result->{cases}}, {name => $selection->{name}, returned => $ok ? 1 : 0, error => $error,
        before => $before, after => $after, calls => \@calls};
    save_result();
    is($ok ? 1 : 0, $selection->{returned} ? 1 : 0, "$selection->{name}: expected structural admission");
    is($error, $selection->{error}, "$selection->{name}: exact first guard error");
    is_deeply($after, $before, "$selection->{name}: all original value types and bytes preserved");
    BAIL_OUT('first unexpected archive guard result retained') unless Test::More->builder->is_passing;
}
is($lookups, 0, 'no target or archive filesystem helper call');
is($forbidden, 0, 'no compiler or native process attempt');
$result->{success} = Test::More->builder->is_passing ? JSON::PP::true : JSON::PP::false;
save_result();
done_testing;
