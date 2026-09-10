package NativeProxyRuntimeRetirement;

use strict;
use warnings;
use JSON::PP ();
use FSM::Test::ProcessSupervisor qw(repository_root);
use ImageCustody;
use RuntimeRecord;
use ReferenceCensus;
use CleanupReceipts;
use PrivateWorkspace;

my $ROOT = repository_root();
my $JSON = JSON::PP->new->canonical->ascii;

# Only the inactive store is reachable through the fixed coordinator. Supplied
# cleanup receipts are synthetic qualification evidence, not authenticated owners.
sub retire_runtime_reference {
    die "expected inactive store, acquisition and complete cleanup receipts\n" unless @_ == 3;
    return NativeProxyImageCoordination::_transaction($_[0], 'retire_runtime_reference', @_[1,2]);
}

sub _snapshot_fields {
    my ($snapshot, $limit) = @_;
    NativeProxyRuntimeRecord::_fields($snapshot, qw(bytes identity));
    NativeProxyImageCustody::_bytes($snapshot->{bytes}, $limit);
    my $identity = $snapshot->{identity};
    NativeProxyRuntimeRecord::_fields($identity, qw(path device inode size_bytes sha256));
    NativeProxyImageCustody::_relative_path(NativeProxyRuntimeRecord::_string($identity->{path}));
    NativeProxyRuntimeRecord::_integer($identity->{$_}) for qw(device inode size_bytes);
    NativeProxyRuntimeRecord::_digest($identity->{sha256});
    die "acquisition snapshot exceeds byte ceiling\n" if $identity->{size_bytes} > $limit;
}

sub _request {
    my ($case, $acquired, $cleanup) = @_;
    NativeProxyRuntimeRecord::_fields($acquired,
        qw(schema runtime_authorized executable lock reference created image));
    die "expected inactive acquisition receipt\n"
        unless NativeProxyRuntimeRecord::_string($acquired->{schema}) eq 'fsmgen.inactive_runtime_reference_acquisition.v1'
            && !defined($acquired->{executable});
    NativeProxyRuntimeRecord::_integer($acquired->{$_}) for qw(runtime_authorized created);
    die "invalid inactive acquisition flags\n" if $acquired->{runtime_authorized} != 0 || $acquired->{created} > 1;
    NativeProxyRuntimeRecord::_fields($acquired->{lock}, qw(path device inode));
    die "acquired lock path differs from store\n"
        unless NativeProxyRuntimeRecord::_string($acquired->{lock}{path}) eq "$case/coordination.lock";
    NativeProxyRuntimeRecord::_integer($acquired->{lock}{$_}) for qw(device inode);
    NativeProxyRuntimeRecord::_fields($acquired->{reference}, qw(record global private));
    my $record = $acquired->{reference}{record};
    my $raw = NativeProxyRuntimeRecord::encode_runtime_record($case, $record);
    for my $kind (qw(global private)) {
        my $snapshot = $acquired->{reference}{$kind};
        _snapshot_fields($snapshot, 4096);
        my $path = $kind eq 'global' ? "$case/references/$record->{reference_key}.json"
            : "$record->{workspace}/rust-tools/image-reference.json";
        die "acquired reference path or bytes differ\n"
            unless $snapshot->{identity}{path} eq $path && $snapshot->{bytes} eq $raw;
    }
    NativeProxyRuntimeRecord::_fields($acquired->{image}, qw(key snapshots));
    NativeProxyRuntimeRecord::_digest($acquired->{image}{key});
    die "acquired image key or source set differs\n"
        unless $acquired->{image}{key} eq $record->{image_key}
            && ref($acquired->{image}{snapshots}) eq 'ARRAY' && @{$acquired->{image}{snapshots}} == 3;
    _snapshot_fields($_, 65_536) for @{$acquired->{image}{snapshots}};
    die "acquired record source identities differ from image\n"
        unless $JSON->encode($record->{selected_sources}) eq $JSON->encode(
            [map { $_->{identity} } @{$acquired->{image}{snapshots}}[0,1]]);
    NativeProxyRuntimeRecord::_fields($cleanup, qw(compiler outer stages));
    die "complete compiler, outer and inner cleanup is unproved\n"
        unless NativeProxyCleanupReceipts::cleanup_receipts_settled(@$cleanup{qw(compiler outer stages)});
}

sub _reference {
    my ($expected) = @_;
    my $source = NativeProxyImageCustody::_source("$ROOT/$expected->{identity}{path}", 0400, 4096);
    my $ok = eval {
        NativeProxyImageCustody::_recheck_source($source);
        die "retirement reference differs from acquired bytes or inode\n"
            unless $JSON->encode(NativeProxyReferenceCensus::_snapshot($source)) eq $JSON->encode($expected);
        1;
    };
    my $error = $@;
    my $closed = close($source->{handle});
    die $error unless $ok;
    die "cannot close retirement reference: $!\n" unless $closed;
}

sub _admit_locked {
    die "retirement admission requires the sealed coordinator\n"
        unless caller eq 'NativeProxyImageCoordination';
    my ($case, $before, $acquired) = @_;
    my $reference = $acquired->{reference};
    my ($global) = grep { $_->{source}{identity}{path} eq $reference->{global}{identity}{path} }
        @{$before->{references}};
    die "acquired global reference is absent or changed\n" unless defined($global)
        && $JSON->encode($global->{record}) eq $JSON->encode($reference->{record})
        && $JSON->encode($global->{source}) eq $JSON->encode($reference->{global});
    my ($image) = grep { $_->{key} eq $acquired->{image}{key} } @{$before->{images}};
    die "acquired image bytes or native identities changed\n" unless defined($image)
        && $JSON->encode($image) eq $JSON->encode($acquired->{image});
    _reference($reference->{global});
    _reference($reference->{private});
    my $workspace = NativeProxyPrivateWorkspace::_capture($reference->{record}{workspace_identity});
    # The private reference must be inside the exact captured owned tree.
    my ($private) = grep { $_->{identity}{path} eq $reference->{private}{identity}{path} } @{$workspace->{nodes}};
    die "private reference is outside captured workspace custody\n" unless defined($private)
        && $private->{kind} eq 'file' && $private->{bytes} eq $reference->{private}{bytes}
        && $private->{identity}{device} == $reference->{private}{identity}{device}
        && $private->{identity}{inode} == $reference->{private}{identity}{inode};
    return {workspace => $workspace, reference => $reference, image => $image, before => $before};
}

sub _retire_locked {
    die "retirement requires the sealed coordinator\n" unless caller eq 'NativeProxyImageCoordination';
    my ($plan) = @_;
    _reference($plan->{reference}{global});
    _reference($plan->{reference}{private});
    NativeProxyPrivateWorkspace::_remove($plan->{workspace});
    die "private workspace absence is unproved\n"
        unless NativeProxyPrivateWorkspace::_absent($plan->{workspace}{workspace}{path});
}

sub _preserved {
    my ($before, $after) = @_;
    die "retirement changed another reference or image\n"
        unless $JSON->encode($before) eq $JSON->encode($after);
}

sub _unlink_global { unlink("$ROOT/$_[0]") == 1 or die "cannot unlink exact global reference: $!\n"; }

sub _release_locked {
    die "reference release requires the sealed coordinator\n" unless caller eq 'NativeProxyImageCoordination';
    my ($plan, $current) = @_;
    _preserved($plan->{before}, $current);
    die "private workspace reappeared before release\n"
        unless NativeProxyPrivateWorkspace::_absent($plan->{workspace}{workspace}{path});
    _reference($plan->{reference}{global});
    my $global = $plan->{reference}{global}{identity}{path};
    _unlink_global($global);
    die "released global reference remains present\n" unless NativeProxyPrivateWorkspace::_absent($global);
}

sub _finish_locked {
    die "retirement closure requires the sealed coordinator\n" unless caller eq 'NativeProxyImageCoordination';
    my ($case, $plan, $after) = @_;
    my $global = $plan->{reference}{global}{identity}{path};
    my @retained = grep { $_->{source}{identity}{path} ne $global } @{$plan->{before}{references}};
    my %referenced = map { $_->{record}{image_key} => 1 } @retained;
    my @images = grep { $referenced{$_->{key}} } @{$plan->{before}{images}};
    _preserved({references => \@retained, images => \@images, retention => $plan->{before}{retention}}, $after);
    # A last runtime release leaves its now-unreferenced complete image intact.
    my $image = NativeProxyReferenceCensus::_image($case, $plan->{image}{key});
    die "retirement changed the released image\n" unless $JSON->encode($image->{snapshot}) eq $JSON->encode($plan->{image});
    die "retired workspace or released reference reappeared\n"
        unless NativeProxyPrivateWorkspace::_absent($plan->{workspace}{workspace}{path})
            && NativeProxyPrivateWorkspace::_absent($global);
    return {retired_workspace => $plan->{workspace}{workspace}{path}, released_reference => $global,
            image => $image->{snapshot}, removed_nodes => scalar(@{$plan->{workspace}{nodes}})};
}

1;
