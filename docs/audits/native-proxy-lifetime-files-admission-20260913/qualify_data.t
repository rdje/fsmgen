#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use Test::More;
use JSON::PP ();
use Digest::SHA qw(sha256_hex);
use Fcntl qw(O_WRONLY O_CREAT O_EXCL);
require "$FindBin::Bin/qualify.pl";

my $json = JSON::PP->new->canonical->ascii;
my $read = sub {
    open my $handle, '<:raw', "${FindBin::Bin}/$_[0]" or die "data input: $!\n";
    my $bytes = do { local $/; <$handle> };
    close($handle) or die "data input close: $!\n";
    return $json->decode($bytes);
};
my $data = $read->('prepared.json');
my $plan = $read->('plan.json');
for my $pin (@{$plan->{inputs}}, @{$read->('corrected-data-pins.json')}) {
    my $bytes = NativeProxyLifetimeQualification::read_bytes($pin->{path});
    die "data qualification source differs: $pin->{path}\n"
        unless length($bytes) == $pin->{size_bytes} && sha256_hex($bytes) eq $pin->{sha256};
}
sub materialize {
    my ($value) = @_;
    return [map { materialize($_) } @$value] if ref($value) eq 'ARRAY';
    return {map { $_ eq 'bytes_hex' ? (bytes => pack('H*', $value->{$_})) : ($_ => materialize($value->{$_})) }
        keys %$value} if ref($value) eq 'HASH';
    return $value;
}
sub copied { return $json->decode($json->encode($_[0])); }
sub pure_context {
    my ($profile) = @_;
    my $value = materialize(copied($data->{contexts}{$profile}));
    # Physical snapshots deliberately retain their independently read hex form.
    $value->{initial} = copied($data->{contexts}{$profile}{initial});
    $value->{current} = copied($data->{contexts}{$profile}{current});
    return $value;
}
my $attempts = 0;
my @traps = (
    (map { "NativeProxyLifetimeFiles::$_" } qw(initialize _metadata _ancestors absent directory_identity
        create_directory write_exclusive _file _members _walk snapshot cleanup_exact)),
    (map { "NativeProxyLifetimeQualification::$_" } qw(main authenticate journal remember_ownership observe
        probe measure prepare_case execute_event cleanup_case)),
    'NativeProxyLifetimeTrace::observe',
    'NativeProxyReferenceAcquisition::acquire_runtime_reference',
    'NativeProxyRuntimeRetirement::retire_runtime_reference',
    'NativeProxyObservationAcquisition::acquire_observation_reference',
    'NativeProxyObservationAcquisition::reuse_observation_reference',
    'NativeProxyObservationArchive::archive_retained_sources',
    'NativeProxyObservationRelease::release_observation_reference',
    'NativeProxyImageMaintenance::remove_unreferenced_image',
    'FSM::Test::RustProxyFixture::supervise_process', 'FSM::Test::ProcessSupervisor::supervise_process',
    'FSM::Support::ProcessSupervisor::supervise_process');
for my $name (@traps) {
    no strict 'refs'; no warnings 'redefine';
    *{$name} = sub { ++$attempts; die "forbidden data-only call: $name\n"; };
}
my $payloads = {map { $_ => pack('H*', $data->{payloads}{"${_}_hex"}) } qw(wrapper c image)};
my @checks;
sub record {
    my ($name, $action, $accept) = @_;
    my $returned = eval { $action->(); 1 } ? 1 : 0;
    my $error = $@;
    push @checks, {name => $name, returned => $returned, expected => $accept, error_hex => unpack('H*', $error)};
    is($returned, $accept, $name);
}
for my $profile (sort keys %{$data->{contexts}}) {
    my $context = pure_context($profile);
    my $before = $json->encode(NativeProxyLifetimeQualification::retain($context));
    record("$profile initial", sub {
        NativeProxyLifetimeQualification::assert_initial($context, $payloads, $data->{different_image_suffix_hex});
    }, 1);
    is($json->encode(NativeProxyLifetimeQualification::retain($context)), $before, "$profile initial inputs unchanged");
    my %changes = (
        missing_member => sub { delete $_[0]{current}{nodes}{"$_[0]{paths}{target}/rust-tool-resolution"}; },
        unexpected_member => sub { $_[0]{current}{nodes}{"$_[0]{paths}{target}/unknown"} = {}; },
        changed_wrapper => sub { $_[0]{current}{nodes}{"$_[0]{paths}{target}/rust-tool-resolution"}{bytes_hex} .= '00'; },
        wrong_mode => sub { $_[0]{current}{nodes}{"$_[0]{paths}{target}/rust-tool-resolution"}{mode} = 0600; },
        runtime_authority => sub { $_[0]{runtimes}{target}{runtime_authorized} = 1; },
        runtime_record => sub { $_[0]{runtimes}{target}{reference}{record}{workspace} .= '_wrong'; },
        observation_identity => sub { ++$_[0]{observations}{b}{target_sources}[0]{identity}{inode}; },
        wrong_store_identity => sub { ++$_[0]{directories}{store}{inode}; });
    for my $name (sort keys %changes) {
        my $changed = pure_context($profile); $changes{$name}->($changed);
        record("$profile reject $name", sub {
            NativeProxyLifetimeQualification::assert_initial($changed, $payloads, $data->{different_image_suffix_hex});
        }, 0);
    }
    my $archive = $data->{archives}{$profile};
    my $archived = pure_context($profile);
    $archived->{archives} = materialize(copied($archive->{receipts}));
    $archived->{current}{nodes}{$_} = copied($archive->{nodes}{$_}) for keys %{$archive->{nodes}};
    record("$profile bind archive a", sub { NativeProxyLifetimeQualification::bind_archive_nodes($archived, 'a'); }, 1);
    record("$profile bind reused archive b", sub { NativeProxyLifetimeQualification::bind_archive_nodes($archived, 'b'); }, 1);
    for my $name (qw(changed_bytes changed_identity unexpected_member)) {
        my $changed = NativeProxyLifetimeQualification::clone($archived);
        my $binding = $changed->{archives}{a}{source_bindings}[0];
        my $path = $binding->{archive}{path};
        $changed->{current}{nodes}{$path}{bytes_hex} .= '00' if $name eq 'changed_bytes';
        ++$changed->{current}{nodes}{$path}{identity}{inode} if $name eq 'changed_identity';
        $changed->{current}{nodes}{"$changed->{archives}{a}{archive_directory_identity}{path}/unknown"} = {}
            if $name eq 'unexpected_member';
        record("$profile archive reject $name", sub { NativeProxyLifetimeQualification::bind_archive_nodes($changed, 'a'); }, 0);
    }
}
for my $vector (@{$data->{vectors}}) {
    my $context = pure_context($vector->{profile});
    $context->{completed} = {map { $_ => 1 } @{$vector->{completed}}};
    $context->{archive_nodes} = NativeProxyLifetimeFiles::stable({nodes => copied($data->{archives}{$vector->{profile}}{nodes})})
        if @{$vector->{archives}};
    my $actual = NativeProxyLifetimeQualification::expected_state($context);
    my $result = sha256_hex($json->encode($actual));
    push @checks, {name => "$vector->{case} prefix " . scalar(@{$vector->{completed}}),
        expected_sha256 => $vector->{expected_sha256}, actual_sha256 => $result, node_count => scalar(keys %$actual)};
    is($result, $vector->{expected_sha256}, $checks[-1]{name});
}
is($attempts, 0, 'no lifecycle or fixture filesystem calls');
is($NativeProxyLifetimeQualification::FORBIDDEN, 0, 'no subprocess attempts');
sysopen(my $output, "$FindBin::Bin/data-qualification.json", O_WRONLY | O_CREAT | O_EXCL, 0600)
    or die "exclusive data result: $!\n";
binmode($output) or die "data result byte mode: $!\n";
print {$output} $json->encode({schema => 'fsmgen.inactive_lifetime_files_data_qualification.v1', checks => \@checks,
    fixture_attempts => $attempts, process_attempts => $NativeProxyLifetimeQualification::FORBIDDEN}) . "\n" or die "data result write: $!\n";
close($output) or die "data result close: $!\n";
done_testing();
