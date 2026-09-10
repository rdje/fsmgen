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
    "$FindBin::Bin/../native-proxy-image-custody-20260910",
    "$FindBin::Bin/../native-proxy-runtime-records-20260910", $FindBin::Bin;
use JSON::PP ();
use Test::More;
use FSM::ProjectDataLocality qw(ensure_project_artifact_dir);
use FSM::Test::RustProxyFixture ();
BEGIN { *CORE::GLOBAL::exec = sub { ++$forbidden; die 'forbidden exec'; }; }
use RuntimeRecord;
use ObservationRecord;

my $json = JSON::PP->new->canonical->ascii;
sub read_json {
    open my $input, '<:raw', $_[0] or die "input: $!";
    my $value = $json->decode(do { local $/; <$input> });
    close $input or die "close input: $!";
    return $value;
}
my $plan = read_json("$FindBin::Bin/plan.json");
my $runtime = read_json("$FindBin::Bin/../native-proxy-runtime-records-20260910/vectors.json");
my $log = ensure_project_artifact_dir(qw(logs native-proxy-observation-records-20260910));
my $case = $plan->{case};
my $encode = \&NativeProxyObservationRecord::encode_observation_record;
my $decode = \&NativeProxyObservationRecord::decode_observation_record;
my (@encoded, @controls, @mutants);

no warnings 'redefine';
local *FSM::Test::RustProxyFixture::supervise_process = sub { ++$forbidden; die 'forbidden compiler'; };
local *NativeProxyImageCustody::_directory = sub { ++$lookups; die 'unexpected filesystem lookup'; };
local *NativeProxyImageCustody::read_entry = sub { ++$lookups; die 'unexpected image lookup'; };

sub rejects {
    my ($name, $callback, $reason) = @_;
    my $ok = eval { $callback->(); 1 };
    my $error = $@;
    ok(!$ok && $error =~ $reason, $name) or diag($error || 'unexpected acceptance');
    push @controls, {name => $name, rejected => $ok ? 0 : 1,
                     expected_diagnostic => $error =~ $reason ? 1 : 0};
}

for my $vector (@{$plan->{vectors}}) {
    my $bytes = $encode->($case, $vector->{record});
    is($bytes, $vector->{raw}, "independent Python bytes: $vector->{name}");
    is_deeply($decode->($case, $bytes), $vector->{record}, "decoded record: $vector->{name}");
    push @encoded, $bytes;
}
for my $control (@{$plan->{rejects}}) {
    my $diagnostic = qr/\Q$control->{diagnostic}\E/;
    if ($control->{operation} eq 'encode') {
        rejects($control->{name}, sub { $encode->($control->{case}, $control->{record}) }, $diagnostic);
    } elsif ($control->{operation} eq 'decode') {
        rejects($control->{name}, sub { $decode->($control->{case}, $control->{raw}) }, $diagnostic);
    } else {
        die "unknown planned operation\n";
    }
}
my $raw = $plan->{vectors}[0]{raw};
my $base = $plan->{vectors}[0]{record};
my $wide = $raw;
utf8::upgrade($wide);
rejects('raw non-ASCII', sub { $decode->($case, "\xff") }, qr/bounded ASCII/);
rejects('character instead of bytes', sub { $decode->($case, $wide) }, qr/bounded ASCII/);
rejects('reference instead of bytes', sub { $decode->($case, []) }, qr/bounded ASCII/);
rejects('extra encode argument', sub { $encode->($case, $base, 'extra') }, qr/expected isolated/);
rejects('missing decode argument', sub { $decode->($case) }, qr/expected isolated/);
rejects('extra decode argument', sub { $decode->($case, $raw, 'extra') }, qr/expected isolated/);
rejects('runtime record in observation decoder',
    sub { $decode->($runtime->{case}, $runtime->{vectors}[0]{raw}) }, qr/closed record/);
rejects('observation record in runtime decoder',
    sub { NativeProxyRuntimeRecord::decode_runtime_record($case, $raw) }, qr/closed record/);

for my $mutant (@{$plan->{mutants}}) {
    my $bytes;
    if ($mutant->{name} eq 'omitted field closure') {
        local *NativeProxyObservationRecord::_fields = sub { die 'not a map' unless ref($_[0]) eq 'HASH' };
        $bytes = $encode->($case, $mutant->{record});
    } elsif ($mutant->{name} eq 'omitted key derivation') {
        local *NativeProxyObservationRecord::_reference_key = sub { return };
        $bytes = $encode->($case, $mutant->{record});
    } elsif ($mutant->{name} eq 'omitted birth validation') {
        local *NativeProxyImageCustody::_birth = sub { return $_[0] };
        $bytes = $encode->($case, $mutant->{record});
    } else {
        die "unknown planned mutant\n";
    }
    is($bytes, $mutant->{raw}, "counterimplementation admits independently invalid bytes: $mutant->{name}");
    push @mutants, {name => $mutant->{name}, raw => $bytes, accepted_by_mutant => 1};
}
is($lookups, 0, 'codec does not invoke current filesystem custody');
is($forbidden, 0, 'no compiler or process attempt');
my $success = Test::More->builder->is_passing;
open my $output, '>:raw', "$log/qualification.json" or die "result: $!";
print {$output} JSON::PP->new->canonical->ascii->pretty->encode({
    schema => 'fsmgen.inactive_observation_record_qualification.v1',
    success => $success ? JSON::PP::true : JSON::PP::false,
    encoded => \@encoded, controls => \@controls, mutants => \@mutants,
    forbidden_process_attempts => $forbidden, filesystem_lookup_attempts => $lookups,
}) or die "write result: $!";
close $output or die "close result: $!";
done_testing;
