package NativeProxyObservationAcquisition;

use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use JSON::PP ();
use FSM::Test::ProcessSupervisor qw(repository_root);
use ImageCustody;
use RuntimeRecord;
use ReferenceCensus;
use ObservationRecord;
use Publication;

my $ROOT = repository_root();
my $JSON = JSON::PP->new->canonical->ascii;
my $WORKSPACE = qr{\.artifacts/tmp/process-supervisor-tests/fsmgen-[A-Za-z0-9_]+};
my $EVIDENCE = qr{\.artifacts/logs/native-proxy-observation-acquisition-20260910/cases/fsmgen-[A-Za-z0-9_]+};

# Inactive filesystem custody only. Caller-supplied birth records must be
# independently authenticated outside coordination before any native capture.
sub acquire_observation_reference {
    die "expected isolated store and observation request\n" unless @_ == 2;
    my ($case, $request) = @_;
    return NativeProxyImageCoordination::_transaction($case, 'acquire_observation_reference', _request($request));
}

sub reuse_observation_reference {
    die "expected isolated store, observation request and previous acquisition\n" unless @_ == 3;
    my ($case, $request, $previous) = @_;
    $request = _request($request);
    $previous = _previous($case, $request, $previous);
    return NativeProxyImageCoordination::_transaction($case, 'reuse_observation_reference', $request, $previous);
}

sub _snapshot_fields {
    my ($snapshot, $path, $limit, $expected_bytes) = @_;
    NativeProxyRuntimeRecord::_fields($snapshot, qw(bytes identity));
    NativeProxyRuntimeRecord::_string($snapshot->{bytes});
    NativeProxyImageCustody::_bytes($snapshot->{bytes}, $limit);
    my $identity = $snapshot->{identity};
    NativeProxyRuntimeRecord::_fields($identity, qw(path device inode size_bytes sha256));
    NativeProxyRuntimeRecord::_integer($identity->{$_}) for qw(device inode size_bytes);
    NativeProxyRuntimeRecord::_digest($identity->{sha256});
    die "acquired snapshot bytes or path differ\n"
        unless NativeProxyRuntimeRecord::_string($identity->{path}) eq $path
            && $identity->{size_bytes} == length($snapshot->{bytes})
            && $identity->{sha256} eq sha256_hex($snapshot->{bytes})
            && (!defined($expected_bytes) || $snapshot->{bytes} eq $expected_bytes);
}

sub _previous {
    my ($case, $request, $previous) = @_;
    NativeProxyRuntimeRecord::_fields($previous,
        qw(schema runtime_authorized executable lock observation_reference target_sources));
    die "expected inactive observation acquisition\n"
        unless NativeProxyRuntimeRecord::_string($previous->{schema}) eq 'fsmgen.inactive_observation_acquisition.v1'
            && !defined($previous->{executable});
    NativeProxyRuntimeRecord::_integer($previous->{runtime_authorized});
    die "invalid inactive observation authority\n" unless $previous->{runtime_authorized} == 0;
    NativeProxyRuntimeRecord::_fields($previous->{lock}, qw(path device inode));
    NativeProxyRuntimeRecord::_integer($previous->{lock}{$_}) for qw(device inode);
    die "acquired observation lock path differs from store\n"
        unless NativeProxyRuntimeRecord::_string($previous->{lock}{path}) eq "$case/coordination.lock";
    my $hold = $previous->{observation_reference};
    NativeProxyRuntimeRecord::_fields($hold, qw(record source));
    my $record = $hold->{record};
    my $bytes = NativeProxyObservationRecord::encode_observation_record($case, $record);
    die "observation record differs from requested ownership\n"
        unless $JSON->encode([@$record{qw(evidence_directory_identity observer_birth target_birth)}])
            eq $JSON->encode([@$request{qw(evidence_directory_identity observer_birth target_birth)}]);
    _snapshot_fields($hold->{source}, "$case/references/$record->{reference_key}.json", 4096, $bytes);
    my $sources = $previous->{target_sources};
    die "expected ordered observation target snapshots\n" unless ref($sources) eq 'ARRAY' && @$sources == 5;
    my $workspace = $request->{workspace_identity}{path};
    my $runtime_key = NativeProxyImageCustody::runtime_reference_key($workspace);
    my @paths = ("$workspace/rust-tool-resolution", "$workspace/rust-tools/image-reference.json",
        "$case/references/$runtime_key.json", "$case/images/$record->{image_key}/rustup.c",
        "$case/images/$record->{image_key}/rustup");
    _snapshot_fields($sources->[$_], $paths[$_], ($_ == 1 || $_ == 2) ? 4096 : 65_536)
        for 0..4;
    die "acquired runtime reference pair differs\n" unless $sources->[1]{bytes} eq $sources->[2]{bytes};
    my $runtime = NativeProxyRuntimeRecord::decode_runtime_record($case, $sources->[1]{bytes});
    die "acquired runtime record differs from requested workspace\n"
        unless $JSON->encode($runtime->{workspace_identity}) eq $JSON->encode($request->{workspace_identity});
    my $selected = [map { $_->{identity} } @$sources[3,4]];
    die "acquired canonical source pair differs\n"
        unless $JSON->encode($selected) eq $JSON->encode($record->{selected_sources})
            && $JSON->encode($selected) eq $JSON->encode($runtime->{selected_sources})
            && $runtime->{image_key} eq $record->{image_key}
            && NativeProxyImageCustody::image_key($sources->[3]{bytes}, $sources->[4]{bytes}) eq $record->{image_key};
    my $copy = $JSON->decode($JSON->encode($previous));
    # JSON cloning must not turn already validated octets into character data.
    utf8::downgrade($_->{bytes}, 1) or die "cannot retain observation snapshot octets\n"
        for ($copy->{observation_reference}{source}, @{$copy->{target_sources}});
    return $copy;
}

sub _prior_hold_matches {
    my ($previous, $entry) = @_;
    die "previous observation hold is absent or changed\n" unless defined($entry)
        && $JSON->encode($entry) eq $JSON->encode($previous->{observation_reference});
}

sub _prior_targets_match {
    my ($previous, $snapshots) = @_;
    die "observation target sources differ from acquired snapshots\n"
        unless $JSON->encode($snapshots) eq $JSON->encode($previous->{target_sources});
}

sub _request {
    my ($request) = @_;
    NativeProxyRuntimeRecord::_fields($request,
        qw(workspace_identity evidence_directory_identity observer_birth target_birth));
    for my $selection ([workspace_identity => $WORKSPACE], [evidence_directory_identity => $EVIDENCE]) {
        my ($field, $pattern) = @$selection;
        my $directory = $request->{$field};
        NativeProxyRuntimeRecord::_fields($directory, qw(path device inode));
        die "unexpected prior $field path\n"
            unless NativeProxyRuntimeRecord::_string($directory->{path}) =~ /\A$pattern\z/;
        NativeProxyRuntimeRecord::_integer($directory->{$_}) for qw(device inode);
    }
    NativeProxyImageCustody::_birth($request->{$_}) for qw(observer_birth target_birth);
    return $JSON->decode($JSON->encode($request));
}

sub _prior_directory {
    my ($expected, $purpose) = @_;
    my $current = NativeProxyImageCustody::_directory("$ROOT/$expected->{path}");
    die "prior $purpose identity differs from current directory\n"
        unless $current->[0] == $expected->{device} && $current->[1] == $expected->{inode};
    return $current;
}

sub _directory_closure {
    my ($plan) = @_;
    for my $directory (@{$plan->{directories}}) {
        die "observation directory changed\n" unless NativeProxyImageCustody::_same_metadata(
            $directory->{metadata}, NativeProxyImageCustody::_directory("$ROOT/$directory->{path}"), 0,1,2,4);
    }
}

sub _close_sources {
    my ($sources) = @_;
    my $error = '';
    for my $source (@$sources) {
        $error ||= "cannot close observation source: $!\n" unless close($source->{handle});
    }
    return $error;
}

sub _source_closure {
    my ($plan) = @_;
    for my $index (0..$#{$plan->{sources}}) {
        my $source = $plan->{sources}[$index];
        NativeProxyImageCustody::_recheck_source($source);
        my ($path, $mode, $limit) = @{$plan->{specifications}[$index]};
        my $fresh = NativeProxyImageCustody::_source("$ROOT/$path", $mode, $limit);
        my $ok = eval {
            die "observation source bytes or identity changed\n"
                unless $source->{bytes} eq $fresh->{bytes}
                    && NativeProxyImageCustody::_same_metadata(
                        $source->{metadata}, $fresh->{metadata}, 0,1,2,3,4,7,9,10);
            NativeProxyImageCustody::_recheck_source($fresh);
            1;
        };
        my $error = $@;
        my $closed = close($fresh->{handle});
        die $error unless $ok;
        die "cannot close fresh observation source: $!\n" unless $closed;
    }
}

sub _admit_locked {
    die "observation admission requires the sealed coordinator\n"
        unless caller eq 'NativeProxyImageCoordination';
    my ($case, $census, $request, $previous) = @_;
    $request = _request($request);
    $previous = _previous($case, $request, $previous) if defined($previous);
    my $workspace = $request->{workspace_identity};
    my $evidence = $request->{evidence_directory_identity};
    my $reference_key = NativeProxyImageCustody::observation_reference_key(
        $evidence->{path}, $request->{observer_birth}, $request->{target_birth});
    my $destination = "$case/references/$reference_key.json";
    if (defined($previous)) {
        my ($entry) = grep { $_->{source}{identity}{path} eq $destination } @{$census->{references}};
        _prior_hold_matches($previous, $entry);
    } else {
        die "observation reference already exists\n" if -e "$ROOT/$destination" || -l "$ROOT/$destination";
        die "observation reference capacity exceeded\n" if @{$census->{references}} >= 128;
    }
    my $runtime_key = NativeProxyImageCustody::runtime_reference_key($workspace->{path});
    my @runtime = grep { $_->{record}{schema} eq 'fsmgen.test.rust_proxy_image_reference.v1'
        && $_->{record}{reference_key} eq $runtime_key } @{$census->{references}};
    die "observation runtime reference is absent\n" unless @runtime == 1;
    my $runtime = $runtime[0];
    die "runtime reference differs from prior workspace\n"
        unless $JSON->encode($runtime->{record}{workspace_identity}) eq $JSON->encode($workspace);
    my $image_key = $runtime->{record}{image_key};
    my @images = grep { $_->{key} eq $image_key } @{$census->{images}};
    die "observation image snapshot is absent\n" unless @images == 1;
    my $image = $images[0];
    my $plan = {request => $request, destination => $destination, sources => [], directories => []};
    $plan->{previous} = $previous if defined($previous);
    my $ok = eval {
        push @{$plan->{directories}}, {path => $workspace->{path}, metadata => _prior_directory($workspace, 'workspace')};
        push @{$plan->{directories}}, {path => $evidence->{path}, metadata => _prior_directory($evidence, 'evidence')};
        for my $path ("$workspace->{path}/rust-tools", "$case/images/$image_key") {
            push @{$plan->{directories}}, {path => $path, metadata => NativeProxyImageCustody::_directory("$ROOT/$path")};
        }
        $plan->{specifications} = [
            ["$workspace->{path}/rust-tool-resolution", 0700, 65_536],
            ["$workspace->{path}/rust-tools/image-reference.json", 0400, 4096],
            ["$case/references/$runtime_key.json", 0400, 4096],
            ["$case/images/$image_key/rustup.c", 0400, 65_536],
            ["$case/images/$image_key/rustup", 0500, 65_536],
        ];
        for my $spec (@{$plan->{specifications}}) {
            push @{$plan->{sources}}, NativeProxyImageCustody::_source("$ROOT/$spec->[0]", @$spec[1,2]);
        }
        my @snapshots = map { NativeProxyReferenceCensus::_snapshot($_) } @{$plan->{sources}};
        die "private/global runtime reference differs\n"
            unless $snapshots[1]{bytes} eq $snapshots[2]{bytes}
                && $JSON->encode($snapshots[2]) eq $JSON->encode($runtime->{source});
        NativeProxyRuntimeRecord::decode_runtime_record($case, $snapshots[1]{bytes});
        for my $index (0,1) {
            die "runtime reference does not bind current canonical source\n"
                unless $JSON->encode($runtime->{record}{selected_sources}[$index])
                    eq $JSON->encode($snapshots[$index+3]{identity});
            die "observation source differs from admitted image\n"
                unless $JSON->encode($snapshots[$index+3]) eq $JSON->encode($image->{snapshots}[$index]);
        }
        if (defined($previous)) {
            _prior_targets_match($previous, \@snapshots);
            push @{$plan->{specifications}}, [$destination, 0400, 4096];
            my $hold = NativeProxyImageCustody::_source("$ROOT/$destination", 0400, 4096);
            push @{$plan->{sources}}, $hold;
            _prior_hold_matches($previous, {
                record => NativeProxyObservationRecord::decode_observation_record($case, $hold->{bytes}),
                source => NativeProxyReferenceCensus::_snapshot($hold)});
            $plan->{sealed} = $hold->{metadata};
        }
        $plan->{record} = {schema => 'fsmgen.test.rust_proxy_image_observation_reference.v1',
            reference_key => $reference_key, image_key => $image_key,
            evidence_directory => $evidence->{path}, evidence_directory_identity => $evidence,
            observer_birth => $request->{observer_birth}, target_birth => $request->{target_birth},
            selected_sources => [map { +{%{$snapshots[$_]{identity}}} } (3,4)]};
        $plan->{bytes} = NativeProxyObservationRecord::encode_observation_record($case, $plan->{record});
        _source_closure($plan);
        _directory_closure($plan);
        1;
    };
    my $error = $@;
    unless ($ok) {
        _close_sources($plan->{sources});
        die $error;
    }
    return $plan;
}

sub _acquire_locked {
    die "observation publication requires the sealed coordinator\n"
        unless caller eq 'NativeProxyImageCoordination';
    my ($plan) = @_;
    _source_closure($plan);
    _directory_closure($plan);
    return $plan->{sealed} if exists($plan->{previous});
    return NativeProxyImagePublication::_write_payload("$ROOT/$plan->{destination}", $plan->{bytes}, 0400);
}

sub _read_hold {
    my ($case, $plan, $sealed) = @_;
    my $source = NativeProxyImageCustody::_source("$ROOT/$plan->{destination}", 0400, 4096);
    my $snapshot;
    my $ok = eval {
        die "observation hold bytes or sealed identity changed\n" unless $source->{bytes} eq $plan->{bytes}
            && NativeProxyImageCustody::_same_metadata($sealed, $source->{metadata}, 0,1,2,3,4,7);
        NativeProxyObservationRecord::decode_observation_record($case, $source->{bytes});
        NativeProxyImageCustody::_recheck_source($source);
        $snapshot = NativeProxyReferenceCensus::_snapshot($source);
        1;
    };
    my $error = $@;
    my $closed = close($source->{handle});
    die $error unless $ok;
    die "cannot close observation hold: $!\n" unless $closed;
    return $snapshot;
}

sub _finish_locked {
    die "observation closure requires the sealed coordinator\n"
        unless caller eq 'NativeProxyImageCoordination';
    my ($case, $plan, $sealed, $before, $after) = @_;
    my %references = map { $_->{source}{identity}{path} => $_ } @{$after->{references}};
    my $added = exists($plan->{previous}) ? 0 : 1;
    die "unexpected observation reference membership\n"
        unless keys(%references) == @{$before->{references}} + $added
            && exists($references{$plan->{destination}});
    for my $entry (@{$before->{references}}) {
        my $path = $entry->{source}{identity}{path};
        die "prior reference changed during observation acquisition\n" unless exists($references{$path})
            && $JSON->encode($entry) eq $JSON->encode($references{$path});
    }
    die "image snapshots changed during observation acquisition\n"
        unless $JSON->encode($before->{images}) eq $JSON->encode($after->{images});
    my $hold = _read_hold($case, $plan, $sealed);
    die "observation census differs from acquired hold\n"
        unless $JSON->encode($hold) eq $JSON->encode($references{$plan->{destination}}{source})
            && $JSON->encode($plan->{record}) eq $JSON->encode($references{$plan->{destination}}{record});
    _source_closure($plan);
    _directory_closure($plan);
    return {observation_reference => {record => $plan->{record}, source => $hold},
            target_sources => [map { NativeProxyReferenceCensus::_snapshot($_) } @{$plan->{sources}}[0..4]]};
}

1;
