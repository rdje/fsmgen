package NativeProxyReferenceAcquisition;

use strict;
use warnings;
use JSON::PP ();
use FSM::Test::ProcessSupervisor qw(repository_root);
use ImageCustody;
use RuntimeRecord;
use Publication;
use ReferenceCensus;

my $ROOT = repository_root();
my $JSON = JSON::PP->new->canonical->ascii;

# Inactive acquisition of inert fixture records only. Actual compiler custody,
# runtime/observation lifetimes and product activation remain separate gates.
sub acquire_runtime_reference {
    die "expected isolated store, prior workspace identity and C/image bytes\n" unless @_ == 4;
    return NativeProxyImageCoordination::_transaction($_[0], 'acquire_runtime_reference', @_[1..3]);
}

sub _request {
    my ($workspace, $c, $image) = @_;
    NativeProxyRuntimeRecord::_fields($workspace, qw(path device inode));
    die "expected prior private workspace identity\n" unless NativeProxyRuntimeRecord::_string($workspace->{path})
        =~ /\A\.artifacts\/tmp\/process-supervisor-tests\/fsmgen-[A-Za-z0-9_]+\z/;
    NativeProxyRuntimeRecord::_integer($workspace->{$_}) for qw(device inode);
    NativeProxyImageCustody::image_key($c, $image);
}

sub _workspace_closure {
    my ($plan) = @_;
    for my $item ([$plan->{workspace}{path}, $plan->{directory}],
                  ["$plan->{workspace}{path}/rust-tools", $plan->{tools}]) {
        die "acquisition workspace directory changed\n" unless NativeProxyImageCustody::_same_metadata(
            $item->[1], NativeProxyImageCustody::_directory("$ROOT/$item->[0]"), 0,1,2,4);
    }
}

sub _admit_locked {
    die "reference admission requires the sealed coordinator\n"
        unless caller eq 'NativeProxyImageCoordination';
    my ($case, $census, $expected) = @_;
    my $workspace = {map { $_ => $expected->{$_} } qw(path device inode)};
    my $directory = NativeProxyImageCustody::_directory("$ROOT/$workspace->{path}");
    die "prior workspace identity differs from current directory\n"
        unless $workspace->{device} == $directory->[0] && $workspace->{inode} == $directory->[1];
    my $tools = NativeProxyImageCustody::_directory("$ROOT/$workspace->{path}/rust-tools");
    my $key = NativeProxyImageCustody::runtime_reference_key($workspace->{path});
    my $global = "$case/references/$key.json";
    my $private = "$workspace->{path}/rust-tools/image-reference.json";
    die "runtime reference capacity exceeded\n" if @{$census->{references}} >= 128;
    for my $path ($global, $private) {
        die "runtime reference already exists\n" if -e "$ROOT/$path" || -l "$ROOT/$path";
    }
    return {workspace => $workspace, directory => $directory, tools => $tools,
            key => $key, global => $global, private => $private};
}

sub _write_reference {
    my ($path, $bytes) = @_;
    NativeProxyImageCustody::_bytes($bytes, 4096);
    # The qualified writer requires exact readback equality and seals its
    # original inode. Codec-bounded input keeps accepted references within 4 KiB.
    return NativeProxyImagePublication::_write_payload("$ROOT/$path", $bytes, 0400);
}

sub _read_reference {
    my ($case, $path, $bytes, $sealed) = @_;
    my $source = NativeProxyImageCustody::_source("$ROOT/$path", 0400, 4096);
    my $snapshot;
    my $ok = eval {
        die "acquired reference bytes or sealed identity changed\n" unless $source->{bytes} eq $bytes
            && NativeProxyImageCustody::_same_metadata($sealed, $source->{metadata}, 0,1,2,3,4,7);
        NativeProxyRuntimeRecord::decode_runtime_record($case, $source->{bytes});
        NativeProxyImageCustody::_recheck_source($source);
        $snapshot = NativeProxyReferenceCensus::_snapshot($source);
        1;
    };
    my $error = $@;
    my $closed = close($source->{handle});
    die $error unless $ok;
    die "cannot close acquired reference: $!\n" unless $closed;
    return $snapshot;
}

sub _acquire_locked {
    die "reference acquisition requires the sealed coordinator\n"
        unless caller eq 'NativeProxyImageCoordination';
    my ($case, $plan, $publication) = @_;
    _workspace_closure($plan);
    my $image = $publication->{image};
    my $record = {schema => 'fsmgen.test.rust_proxy_image_reference.v1',
        reference_key => $plan->{key}, image_key => $image->{key},
        workspace => $plan->{workspace}{path}, workspace_identity => $plan->{workspace},
        selected_sources => [map { +{%{$_->{identity}}} } @{$image->{snapshots}}[0,1]]};
    my $bytes = NativeProxyRuntimeRecord::encode_runtime_record($case, $record);
    my $global = _write_reference($plan->{global}, $bytes);
    _read_reference($case, $plan->{global}, $bytes, $global);
    _workspace_closure($plan);
    my $private = _write_reference($plan->{private}, $bytes);
    return {record => $record, bytes => $bytes, global_sealed => $global, private_sealed => $private};
}

sub _finish_locked {
    die "reference closure requires the sealed coordinator\n"
        unless caller eq 'NativeProxyImageCoordination';
    my ($case, $plan, $publication, $acquired, $before, $after) = @_;
    my %references = map { $_->{source}{identity}{path} => $_ } @{$after->{references}};
    die "unexpected reference acquisition membership\n"
        unless keys(%references) == @{$before->{references}} + 1
            && exists($references{$plan->{global}});
    for my $entry (@{$before->{references}}) {
        my $path = $entry->{source}{identity}{path};
        die "prior runtime reference changed during acquisition\n"
            unless exists($references{$path}) && $JSON->encode($entry) eq $JSON->encode($references{$path});
    }
    my %images = map { $_->{key} => $_ } @{$after->{images}};
    for my $image (@{$before->{images}}, $publication->{image}) {
        die "retained image changed during acquisition\n" unless exists($images{$image->{key}})
            && $JSON->encode($image) eq $JSON->encode($images{$image->{key}});
    }
    my $global = _read_reference($case, $plan->{global}, $acquired->{bytes}, $acquired->{global_sealed});
    my $private = _read_reference($case, $plan->{private}, $acquired->{bytes}, $acquired->{private_sealed});
    die "global census differs from acquired reference\n"
        unless $JSON->encode($global) eq $JSON->encode($references{$plan->{global}}{source})
            && $JSON->encode($acquired->{record}) eq $JSON->encode($references{$plan->{global}}{record});
    _workspace_closure($plan);
    return {reference => {record => $acquired->{record}, global => $global, private => $private},
            created => $publication->{created}, image => $publication->{image}};
}

1;
