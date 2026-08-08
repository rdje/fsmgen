package FSM::Test::T296Checkpoint;

use v5.20;
use strict;
use warnings;

use Cwd qw(abs_path);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempfile);
use IO::Handle ();
use JSON::PP ();

my $SCHEMA_VERSION = 1;
my $MAX_STATE_BYTES = 1024 * 1024;

sub new {
    my ($class, %args) = @_;
    my $repo_root = delete $args{repo_root};
    my $relative_path = delete $args{relative_path};
    my $fingerprint = delete $args{fingerprint};
    my $contract_version = delete $args{contract_version};
    die "Unknown t296 checkpoint argument: $_\n" for sort keys %args;

    die "t296 checkpoint repository root is required\n"
        unless defined $repo_root && length $repo_root;
    die "t296 checkpoint path is required\n"
        unless defined $relative_path && length $relative_path;
    die "Invalid t296 checkpoint fingerprint\n"
        unless defined $fingerprint && $fingerprint =~ /\A[0-9a-f]{40,64}\z/;
    die "Invalid t296 checkpoint contract version\n"
        unless defined $contract_version
        && $contract_version =~ /\A[A-Za-z0-9][A-Za-z0-9._-]*\z/;

    my ($filename) = $relative_path =~ m{
        \A\.artifacts/t296/
        ([A-Za-z0-9][A-Za-z0-9._-]{0,127}\.json)\z
    }x;
    die "t296 checkpoint path must match .artifacts/t296/<safe-name>.json\n"
        unless defined $filename;

    my $resolved_root = abs_path($repo_root)
        or die "Cannot resolve t296 checkpoint repository root '$repo_root': $!\n";
    die "t296 checkpoint repository root must be a directory\n"
        unless -d $resolved_root;

    my $artifact_root = File::Spec->catdir($resolved_root, '.artifacts');
    my $checkpoint_dir = File::Spec->catdir($artifact_root, 't296');
    _reject_symlink($artifact_root, 'artifact root');
    _reject_symlink($checkpoint_dir, 'checkpoint directory');
    eval { make_path($checkpoint_dir); 1 }
        or die "Cannot create t296 checkpoint directory '$checkpoint_dir': $@";
    _reject_symlink($artifact_root, 'artifact root');
    _reject_symlink($checkpoint_dir, 'checkpoint directory');

    my $resolved_dir = abs_path($checkpoint_dir)
        or die "Cannot resolve t296 checkpoint directory '$checkpoint_dir': $!\n";
    _assert_within_root($resolved_root, $resolved_dir);
    _assert_same_volume($resolved_root, $resolved_dir);

    my $path = File::Spec->catfile($resolved_dir, $filename);
    die "t296 checkpoint must be a regular file, not a symlink\n" if -l $path;
    die "t296 checkpoint path is not a regular file\n" if -e $path && !-f $path;

    my $self = bless {
        path => $path,
        directory => $resolved_dir,
        filename => $filename,
        fingerprint => $fingerprint,
        contract_version => $contract_version,
        completed => {},
    }, $class;
    $self->_load_existing() if -e $path;
    return $self;
}

sub is_complete {
    my ($self, %args) = @_;
    my $key = _batch_key(%args);
    return exists $self->{completed}{$key};
}

sub mark_complete {
    my ($self, %args) = @_;
    my $key = _batch_key(%args);
    return 0 if exists $self->{completed}{$key};
    $self->{completed}{$key} = 1;
    my $ok = eval { $self->_write_atomic(); 1 };
    my $error = $@;
    delete $self->{completed}{$key} unless $ok;
    die $error unless $ok;
    return 1;
}

sub completed_count {
    my ($self) = @_;
    return scalar keys %{$self->{completed}};
}

sub clear {
    my ($self) = @_;
    die "Refusing to clear symlinked t296 checkpoint '$self->{path}'\n"
        if -l $self->{path};
    if (-e $self->{path}) {
        unlink $self->{path}
            or die "Cannot remove completed t296 checkpoint '$self->{path}': $!\n";
    }
    $self->{completed} = {};
    return 1;
}

sub path {
    my ($self) = @_;
    return $self->{path};
}

sub fingerprint {
    my ($self) = @_;
    return $self->{fingerprint};
}

sub _load_existing {
    my ($self) = @_;
    my $size = -s $self->{path};
    die "Cannot size t296 checkpoint '$self->{path}'\n" unless defined $size;
    die "t296 checkpoint '$self->{path}' exceeds $MAX_STATE_BYTES bytes\n"
        if $size > $MAX_STATE_BYTES;

    open my $fh, '<:raw', $self->{path}
        or die "Cannot read t296 checkpoint '$self->{path}': $!\n";
    local $/;
    my $encoded = <$fh>;
    close $fh or die "Cannot close t296 checkpoint '$self->{path}': $!\n";

    my $state = eval { JSON::PP->new->decode($encoded) };
    die "Malformed t296 checkpoint '$self->{path}': $@" if $@;
    _validate_state($self, $state);
    $self->{completed} = {%{$state->{completed}}};
}

sub _validate_state {
    my ($self, $state) = @_;
    die "Invalid t296 checkpoint: top level must be an object\n"
        unless ref($state) eq 'HASH';

    my @expected_keys = qw(completed contract_version fingerprint schema_version);
    my @actual_keys = sort keys %{$state};
    die "Invalid t296 checkpoint: unexpected top-level fields\n"
        unless join("\0", @actual_keys) eq join("\0", @expected_keys);
    die "Unsupported t296 checkpoint schema version\n"
        unless defined $state->{schema_version}
        && !ref($state->{schema_version})
        && $state->{schema_version} =~ /\A1\z/;
    die "t296 checkpoint belongs to a different repository revision\n"
        unless defined $state->{fingerprint}
        && !ref($state->{fingerprint})
        && $state->{fingerprint} eq $self->{fingerprint};
    die "t296 checkpoint belongs to a different test contract\n"
        unless defined $state->{contract_version}
        && !ref($state->{contract_version})
        && $state->{contract_version} eq $self->{contract_version};
    die "Invalid t296 checkpoint: completed batches must be an object\n"
        unless ref($state->{completed}) eq 'HASH';
    die "Invalid t296 checkpoint: too many completed batches\n"
        if keys(%{$state->{completed}}) > 10_000;

    for my $key (keys %{$state->{completed}}) {
        die "Invalid t296 checkpoint batch key '$key'\n"
            unless $key =~ /\A(?:pipeline|cli):(?:default|strict):\d+:[1-9]\d*\z/;
        my $value = $state->{completed}{$key};
        die "Invalid t296 checkpoint value for '$key'\n"
            if ref($value) || !defined($value) || $value !~ /\A1\z/;
    }
}

sub _write_atomic {
    my ($self) = @_;
    my $state = {
        schema_version => $SCHEMA_VERSION,
        fingerprint => $self->{fingerprint},
        contract_version => $self->{contract_version},
        completed => $self->{completed},
    };
    my $encoded = JSON::PP->new->ascii->canonical->pretty->encode($state);

    my ($fh, $temporary_path) = tempfile(
        "$self->{filename}.tmp-XXXXXXXX",
        DIR => $self->{directory},
        UNLINK => 0,
    );
    my $ok = eval {
        binmode $fh, ':raw'
            or die "Cannot set binary mode for '$temporary_path': $!\n";
        print {$fh} $encoded
            or die "Cannot write t296 checkpoint temporary '$temporary_path': $!\n";
        $fh->sync()
            or die "Cannot sync t296 checkpoint temporary '$temporary_path': $!\n";
        close $fh
            or die "Cannot close t296 checkpoint temporary '$temporary_path': $!\n";
        undef $fh;
        die "Refusing to replace symlinked t296 checkpoint '$self->{path}'\n"
            if -l $self->{path};
        rename $temporary_path, $self->{path}
            or die "Cannot atomically replace t296 checkpoint '$self->{path}': $!\n";
        1;
    };
    my $error = $@;
    close $fh if defined $fh;
    unlink $temporary_path if -e $temporary_path;
    die $error unless $ok;
}

sub _batch_key {
    my (%args) = @_;
    my $surface = delete $args{surface};
    my $strict_mode = delete $args{strict_mode};
    my $start = delete $args{start};
    my $count = delete $args{count};
    die "Unknown t296 checkpoint batch argument: $_\n" for sort keys %args;
    die "Invalid t296 checkpoint batch surface\n"
        unless defined $surface && ($surface eq 'pipeline' || $surface eq 'cli');
    die "Invalid t296 checkpoint batch strict selector\n"
        unless defined $strict_mode && $strict_mode =~ /\A[01]\z/;
    die "Invalid t296 checkpoint batch start\n"
        unless defined $start && $start =~ /\A\d+\z/;
    die "Invalid t296 checkpoint batch count\n"
        unless defined $count && $count =~ /\A[1-9]\d*\z/;
    my $mode = $strict_mode ? 'strict' : 'default';
    return join ':', $surface, $mode, $start, $count;
}

sub _reject_symlink {
    my ($path, $label) = @_;
    die "t296 checkpoint $label must not be a symlink: '$path'\n" if -l $path;
}

sub _assert_within_root {
    my ($root, $path) = @_;
    my $relative = File::Spec->abs2rel($path, $root);
    die "t296 checkpoint directory resolves outside the repository\n"
        if File::Spec->file_name_is_absolute($relative)
        || $relative eq File::Spec->updir()
        || $relative =~ m{\A\.\.(?:[\\/]|\z)};
}

sub _assert_same_volume {
    my ($root, $path) = @_;
    my @root_stat = stat($root);
    my @path_stat = stat($path);
    die "Cannot inspect t296 checkpoint filesystem volume\n"
        unless @root_stat && @path_stat;
    die "t296 checkpoint directory must stay on the repository filesystem volume\n"
        unless $root_stat[0] == $path_stat[0];
}

1;
