package NativeProxyObservationAcquisition;

use strict;
use warnings;
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
    my ($case, $census, $request) = @_;
    $request = _request($request);
    my $workspace = $request->{workspace_identity};
    my $evidence = $request->{evidence_directory_identity};
    my $reference_key = NativeProxyImageCustody::observation_reference_key(
        $evidence->{path}, $request->{observer_birth}, $request->{target_birth});
    my $destination = "$case/references/$reference_key.json";
    die "observation reference already exists\n" if -e "$ROOT/$destination" || -l "$ROOT/$destination";
    die "observation reference capacity exceeded\n" if @{$census->{references}} >= 128;
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
    die "unexpected observation reference membership\n"
        unless keys(%references) == @{$before->{references}} + 1
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
            target_sources => [map { NativeProxyReferenceCensus::_snapshot($_) } @{$plan->{sources}}]};
}

1;
