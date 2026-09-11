package NativeProxyObservationArchiveRecord;

use strict;
use warnings;
use JSON::PP ();
use ObservationAcquisition;
use RuntimeRecord;

# Pure inactive records only. Supplied archive snapshots/identities are data,
# not independently observed files or permission to release an observation.
my $JSON = JSON::PP->new->canonical->ascii->max_depth(8)->allow_nonref(0);
my $RECEIPT_LIMIT = 65_536;
my @ROLES = qw(wrapper private_reference global_reference c image);

sub _same {
    return $JSON->encode($_[0]) eq $JSON->encode($_[1]);
}

sub _directory_identity {
    my ($identity, $path, $device) = @_;
    NativeProxyRuntimeRecord::_fields($identity, qw(path device inode));
    NativeProxyRuntimeRecord::_integer($identity->{$_}) for qw(device inode);
    die "archive directory path or device differs\n"
        unless NativeProxyRuntimeRecord::_string($identity->{path}) eq $path
            && $identity->{device} == $device;
}

sub _file_identity {
    my ($identity) = @_;
    NativeProxyRuntimeRecord::_fields($identity, qw(path device inode size_bytes sha256));
    NativeProxyRuntimeRecord::_string($identity->{path});
    NativeProxyRuntimeRecord::_integer($identity->{$_}) for qw(device inode size_bytes);
    NativeProxyRuntimeRecord::_digest($identity->{sha256});
    die "archive file exceeds source ceiling\n" if $identity->{size_bytes} > 65_536;
}

sub _matches_source {
    my ($archive, $source, $path, $actual_bytes, $expected_bytes) = @_;
    die "archive content binding differs from retained source\n"
        unless $archive->{path} eq $path
            && $archive->{size_bytes} == $source->{size_bytes}
            && $archive->{sha256} eq $source->{sha256}
            && (!defined($actual_bytes) || $actual_bytes eq $expected_bytes);
}

sub _matches_original {
    my ($source, $expected) = @_;
    die "archive binding changes original source identity\n" unless _same($source, $expected);
}

sub _same_shared_identity {
    my ($before, $current) = @_;
    die "shared archive path has inconsistent native identities\n" unless _same($before, $current);
}

sub archive_specification {
    die "expected store, request and original acquisition\n" unless @_ == 3;
    my ($case, $request, $acquired) = @_;
    $request = NativeProxyObservationAcquisition::_request($request);
    $acquired = NativeProxyObservationAcquisition::_previous($case, $request, $acquired);
    my $evidence = $request->{evidence_directory_identity};
    my $device = $evidence->{device};
    # Same-volume consistency is a property of the admitted historical record.
    # No comparison with today's filesystem or reinterpretation after a move.
    for my $identity ($request->{workspace_identity}, $acquired->{lock},
            $acquired->{observation_reference}{source}{identity},
            map { $_->{identity} } @{$acquired->{target_sources}}) {
        die "acquired source devices do not agree\n" unless $identity->{device} == $device;
    }
    my $directory = "$evidence->{path}/retained-sources";
    my (@sources, @files, %seen);
    for my $index (0..$#ROLES) {
        my $snapshot = $acquired->{target_sources}[$index];
        my $path = "$directory/$snapshot->{identity}{sha256}.source";
        push @sources, {role => $ROLES[$index], destination => $path,
            snapshot => {bytes => $snapshot->{bytes}, identity => {%{$snapshot->{identity}}}}};
        if (exists($seen{$path})) {
            die "equal archive digest names different retained bytes\n"
                unless $files[$seen{$path}]{bytes} eq $snapshot->{bytes};
        } else {
            $seen{$path} = scalar(@files);
            push @files, {path => $path, bytes => $snapshot->{bytes},
                size_bytes => $snapshot->{identity}{size_bytes}, sha256 => $snapshot->{identity}{sha256}};
        }
    }
    return {schema => 'fsmgen.inactive_observation_archive_specification.v1',
        runtime_authorized => 0, executable => undef,
        evidence_directory_identity => {%$evidence}, archive_directory => $directory,
        observation_reference_key => $acquired->{observation_reference}{record}{reference_key},
        sources => \@sources, files => \@files};
}

sub validate_archive_receipt {
    die "expected store, request, acquisition and archive receipt\n" unless @_ == 4;
    my ($case, $request, $acquired, $receipt) = @_;
    my $spec = archive_specification($case, $request, $acquired);
    NativeProxyRuntimeRecord::_fields($receipt, qw(schema runtime_authorized executable
        evidence_directory_identity archive_directory_identity observation_reference_key source_bindings));
    die "expected inactive archive receipt\n"
        unless NativeProxyRuntimeRecord::_string($receipt->{schema}) eq 'fsmgen.inactive_observation_archive.v1'
            && !defined($receipt->{executable});
    NativeProxyRuntimeRecord::_integer($receipt->{runtime_authorized});
    die "archive receipt grants runtime authority\n" unless $receipt->{runtime_authorized} == 0;
    die "archive evidence identity differs from acquisition\n"
        unless _same($receipt->{evidence_directory_identity}, $spec->{evidence_directory_identity});
    _directory_identity($receipt->{archive_directory_identity}, $spec->{archive_directory},
                        $spec->{evidence_directory_identity}{device});
    die "archive directory aliases its evidence parent\n"
        if $receipt->{archive_directory_identity}{inode} == $spec->{evidence_directory_identity}{inode};
    die "archive observation reference differs\n"
        unless NativeProxyRuntimeRecord::_digest($receipt->{observation_reference_key})
            eq $spec->{observation_reference_key};
    my $bindings = $receipt->{source_bindings};
    die "expected all ordered archive source bindings\n" unless ref($bindings) eq 'ARRAY' && @$bindings == @ROLES;
    my %seen;
    my %native_paths = map {
        ($JSON->encode([@{$_}{qw(device inode)}]) => $_->{path})
    } @{$receipt}{qw(evidence_directory_identity archive_directory_identity)};
    for my $index (0..$#ROLES) {
        my $binding = $bindings->[$index];
        my $expected = $spec->{sources}[$index];
        NativeProxyRuntimeRecord::_fields($binding, qw(role source archive));
        die "archive source role or order differs\n"
            unless NativeProxyRuntimeRecord::_string($binding->{role}) eq $ROLES[$index];
        _file_identity($binding->{source});
        _matches_original($binding->{source}, $expected->{snapshot}{identity});
        _file_identity($binding->{archive});
        die "archive source device differs from directory\n"
            unless $binding->{archive}{device} == $receipt->{archive_directory_identity}{device};
        _matches_source($binding->{archive}, $expected->{snapshot}{identity}, $expected->{destination});
        my $path = $binding->{archive}{path};
        my $native = $JSON->encode([@{$binding->{archive}}{qw(device inode)}]);
        die "archive native identity aliases another path\n"
            if exists($native_paths{$native}) && $native_paths{$native} ne $path;
        $native_paths{$native} = $path;
        if (exists($seen{$path})) {
            _same_shared_identity($seen{$path}, $binding->{archive});
        } else {
            $seen{$path} = $binding->{archive};
        }
    }
    die "archive receipt exceeds byte ceiling\n" if length($JSON->encode($receipt)) > $RECEIPT_LIMIT;
    return 1;
}

sub archive_receipt {
    die "expected store, request, acquisition, archive directory and observed snapshots\n" unless @_ == 5;
    my ($case, $request, $acquired, $directory, $snapshots) = @_;
    my $spec = archive_specification($case, $request, $acquired);
    _directory_identity($directory, $spec->{archive_directory}, $spec->{evidence_directory_identity}{device});
    die "expected complete unique archive snapshot list\n"
        unless ref($snapshots) eq 'ARRAY' && @$snapshots == @{$spec->{files}};
    my %files;
    for my $index (0..$#{$spec->{files}}) {
        my $expected = $spec->{files}[$index];
        my $snapshot = $snapshots->[$index];
        NativeProxyObservationAcquisition::_snapshot_fields($snapshot, $expected->{path}, 65_536);
        die "archive snapshot device differs from directory\n"
            unless $snapshot->{identity}{device} == $directory->{device};
        _matches_source($snapshot->{identity}, $expected, $expected->{path},
                        $snapshot->{bytes}, $expected->{bytes});
        $files{$expected->{path}} = $snapshot->{identity};
    }
    my $receipt = {schema => 'fsmgen.inactive_observation_archive.v1', runtime_authorized => 0,
        executable => undef, evidence_directory_identity => {%{$spec->{evidence_directory_identity}}},
        archive_directory_identity => {%$directory}, observation_reference_key => $spec->{observation_reference_key},
        source_bindings => [map { +{role => $_->{role}, source => {%{$_->{snapshot}{identity}}},
            archive => {%{$files{$_->{destination}}}}} } @{$spec->{sources}}]};
    validate_archive_receipt($case, $request, $acquired, $receipt);
    return $receipt;
}

sub encode_archive_receipt {
    die "expected store, request, acquisition and archive receipt\n" unless @_ == 4;
    validate_archive_receipt(@_);
    return $JSON->encode($_[3]);
}

sub decode_archive_receipt {
    die "expected store, request, acquisition and archive bytes\n" unless @_ == 4;
    my ($case, $request, $acquired, $bytes) = @_;
    die "expected bounded ASCII archive bytes\n" unless defined($bytes) && !ref($bytes)
        && !utf8::is_utf8($bytes) && length($bytes) <= $RECEIPT_LIMIT && $bytes !~ /[^\x00-\x7f]/;
    my $receipt = eval { $JSON->decode($bytes) };
    die "invalid archive JSON\n" if $@;
    die "archive JSON is not canonical\n"
        unless $bytes eq encode_archive_receipt($case, $request, $acquired, $receipt);
    return $receipt;
}

1;
