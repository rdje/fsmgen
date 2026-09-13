package NativeProxyPrivateWorkspace;

use strict;
use warnings;
use Errno qw(ENOENT);
use Fcntl qw(S_ISDIR S_ISLNK S_ISREG);
use JSON::PP ();
use FSM::Test::ProcessSupervisor qw(repository_root);
use ImageCustody;
use Coordination;

my $ROOT = repository_root();
my $DEVICE = (stat($ROOT))[0];
my $JSON = JSON::PP->new->canonical->ascii;
# Inactive qualification ceilings, not measured compiler-workspace capacity.
my $NODE_LIMIT = 256;
my $DEPTH_LIMIT = 8;
my $TOTAL_LIMIT = 4_194_304;

sub _absent {
    my ($path) = @_;
    my @metadata = lstat("$ROOT/$path");
    return 0 if @metadata;
    die "cannot establish exact path absence: $!\n" unless $! == ENOENT;
    return 1;
}

sub _identity {
    my ($path, $metadata) = @_;
    return {path => $path, device => $metadata->[0], inode => $metadata->[1],
            mode => $metadata->[2] & 07777, uid => $metadata->[4]};
}

sub _node {
    my ($path) = @_;
    my @metadata = lstat("$ROOT/$path");
    die "workspace node is absent, foreign or off-volume\n"
        unless @metadata && $metadata[0] == $DEVICE && $metadata[4] == $<;
    if (S_ISDIR($metadata[2])) {
        my $checked = NativeProxyImageCustody::_directory("$ROOT/$path");
        die "workspace directory changed during inspection\n"
            unless NativeProxyImageCustody::_same_metadata(\@metadata, $checked, 0,1,2,4);
        return {kind => 'directory', identity => _identity($path, $checked)};
    }
    die "workspace node has shared links\n" unless $metadata[3] == 1;
    if (S_ISLNK($metadata[2])) {
        # Inspect and remove the owned link itself. Never resolve its target.
        my $target = readlink("$ROOT/$path");
        die "workspace symlink target is unavailable or oversized\n"
            unless defined($target) && length($target) <= 4096;
        my @after = lstat("$ROOT/$path");
        die "workspace symlink changed during inspection\n"
            unless NativeProxyImageCustody::_same_metadata(\@metadata, \@after, 0,1,2,3,4,7,9,10);
        return {kind => 'symlink', identity => _identity($path, \@metadata), target => $target};
    }
    my $mode = $metadata[2] & 07777;
    # T1669 writes this wrapper with 0755 inside its owned private workspace.
    # Keep the exception bound to that producer role, not every executable.
    my $generated_wrapper = $path =~ m{\A\.artifacts/tmp/process-supervisor-tests/
        fsmgen-[A-Za-z0-9_]+/rust-tool-resolution\z}x;
    die "workspace node is not a private regular file\n" unless S_ISREG($metadata[2])
        && ($mode == 0400 || $mode == 0500 || $mode == 0600 || $mode == 0700
            || ($mode == 0755 && $generated_wrapper));
    my $source = NativeProxyImageCustody::_source("$ROOT/$path", $mode, 65_536);
    my $result;
    my $ok = eval {
        die "workspace file changed during inspection\n"
            unless NativeProxyImageCustody::_same_metadata(\@metadata, $source->{metadata}, 0,1,2,3,4,7,9,10);
        NativeProxyImageCustody::_recheck_source($source);
        $result = {kind => 'file', identity => _identity($path, $source->{metadata}), bytes => $source->{bytes}};
        1;
    };
    my $error = $@;
    my $closed = close($source->{handle});
    die $error unless $ok;
    die "cannot close workspace file: $!\n" unless $closed;
    return $result;
}

sub _walk {
    my ($path, $depth, $nodes, $total) = @_;
    die "workspace census depth exceeded\n" if $depth > $DEPTH_LIMIT;
    die "workspace census node ceiling exceeded\n" if @$nodes >= $NODE_LIMIT;
    my $node = _node($path);
    push @$nodes, $node;
    if ($node->{kind} eq 'file') {
        $$total += length($node->{bytes});
        die "workspace census byte ceiling exceeded\n" if $$total > $TOTAL_LIMIT;
    }
    elsif ($node->{kind} eq 'directory') {
        for my $name (@{NativeProxyImageCoordination::_names("$ROOT/$path", $NODE_LIMIT)}) {
            die "unknown workspace member spelling\n" unless $name =~ /\A[A-Za-z0-9_.-]+\z/;
            _walk("$path/$name", $depth + 1, $nodes, $total);
        }
        die "workspace directory replaced during census\n"
            unless $JSON->encode(_node($path)) eq $JSON->encode($node);
    }
}

sub _capture {
    die "workspace custody requires inactive retirement\n"
        unless caller eq 'NativeProxyRuntimeRetirement';
    my ($expected) = @_;
    my $root = _node($expected->{path});
    die "workspace root differs from acquired ownership\n"
        unless $root->{kind} eq 'directory' && $root->{identity}{device} == $expected->{device}
            && $root->{identity}{inode} == $expected->{inode};
    my (@nodes, $total);
    $total = 0;
    _walk($expected->{path}, 0, \@nodes, \$total);
    die "workspace root differs from acquired ownership\n"
        unless $JSON->encode($nodes[0]) eq $JSON->encode($root);
    my $plan = {workspace => {%$expected}, nodes => \@nodes, file_bytes => $total};
    _closure($plan);
    return $plan;
}

sub _closure {
    my ($plan) = @_;
    my (@nodes, $total);
    $total = 0;
    _walk($plan->{workspace}{path}, 0, \@nodes, \$total);
    die "workspace contents or identity changed\n"
        unless $total == $plan->{file_bytes} && $JSON->encode(\@nodes) eq $JSON->encode($plan->{nodes});
}

sub _unlink { unlink("$ROOT/$_[0]") == 1 or die "cannot unlink owned workspace node: $!\n"; }
sub _rmdir { rmdir("$ROOT/$_[0]") or die "cannot remove owned workspace directory: $!\n"; }

sub _remove {
    die "workspace removal requires inactive retirement\n"
        unless caller eq 'NativeProxyRuntimeRetirement';
    my ($plan) = @_;
    _closure($plan);
    my %directories = map { $_->{identity}{path} => $_ }
        grep { $_->{kind} eq 'directory' } @{$plan->{nodes}};
    for my $node (reverse @{$plan->{nodes}}) {
        my $path = $node->{identity}{path};
        for my $parent (sort keys %directories) {
            next unless index($path, "$parent/") == 0;
            die "workspace ancestor replaced before removal\n"
                unless $JSON->encode(_node($parent)) eq $JSON->encode($directories{$parent});
        }
        die "workspace node changed before removal\n"
            unless $JSON->encode(_node($path)) eq $JSON->encode($node);
        $node->{kind} eq 'directory' ? _rmdir($path) : _unlink($path);
        die "removed workspace node is still present\n" unless _absent($path);
    }
    die "retired workspace remains present\n" unless _absent($plan->{workspace}{path});
}

1;
