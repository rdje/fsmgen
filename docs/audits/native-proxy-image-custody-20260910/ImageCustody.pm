package NativeProxyImageCustody;

use strict;
use warnings;

use Digest::SHA qw(sha256_hex);
use Encode qw(encode FB_CROAK);
use Fcntl qw(F_GETFD F_SETFD FD_CLOEXEC S_ISDIR S_ISREG);
use File::Spec;
use JSON::PP ();
use FSM::Test::ProcessSupervisor qw(repository_contained_path repository_root);
use FSM::Test::RustProxyFixture ();

# Inactive, read-only qualification prototype. Nothing in the product imports
# this package. These snapshots neither publish an image nor authorize execution.
my $JSON = JSON::PP->new->canonical->ascii;
my $ROOT = repository_root();
my $DEVICE = (stat($ROOT))[0];
my $CASE_PREFIX = '.artifacts/tmp/native-proxy-image-custody/cases/';
my $SOURCE_LIMIT = 65_536;
my $MANIFEST_LIMIT = 4096;

sub _bytes {
    my ($value, $limit) = @_;
    die "expected bounded bytes\n"
        unless defined($value) && !ref($value) && !utf8::is_utf8($value)
            && length($value) <= $limit;
    return $value;
}

sub image_key {
    die "expected C and image bytes\n" unless @_ == 2;
    my ($c, $image) = map { _bytes($_, $SOURCE_LIMIT) } @_;
    # Lengths are bounded, so the high unsigned-64 word is always zero.
    return sha256_hex("fsmgen.rust_proxy_image.v1\0"
        . pack('NN', 0, length($c)) . $c
        . pack('NN', 0, length($image)) . $image);
}

sub manifest_bytes {
    die "expected C and image bytes\n" unless @_ == 2;
    my ($c, $image) = @_;
    my $key = image_key($c, $image);
    return $JSON->encode({schema => 'fsmgen.test.rust_proxy_image.v1', key => $key,
        generated_c => {size_bytes => length($c), sha256 => sha256_hex($c)},
        executable => {size_bytes => length($image), sha256 => sha256_hex($image)}});
}

sub validate_manifest {
    die "expected manifest, C and image bytes\n" unless @_ == 3;
    my ($manifest, $c, $image) = @_;
    _bytes($manifest, $MANIFEST_LIMIT);
    # Exact reconstruction enforces canonical spelling, closed fields and JSON
    # types without accepting duplicate keys or parser-dependent number coercion.
    die "manifest differs from exact content reconstruction\n"
        unless $manifest eq manifest_bytes($c, $image);
    return 1;
}

sub _relative_path {
    my ($value) = @_;
    die "expected canonical root-relative path\n"
        unless defined($value) && !ref($value) && $JSON->encode($value) =~ /\A"/
            && length($value) && $value !~ /[\x00-\x1f\x7f\\]/
            && !grep { $_ eq '' || $_ eq '.' || $_ eq '..' } split('/', $value, -1);
    return $value;
}

sub runtime_reference_key {
    die "expected workspace path\n" unless @_ == 1;
    my $workspace = _relative_path($_[0]);
    return sha256_hex("fsmgen.rust_proxy_reference.runtime.v1\0"
        . encode('UTF-8', $workspace, FB_CROAK));
}

sub _birth {
    my ($birth) = @_;
    my @fields = qw(pid ppid ruid start_sec start_usec uid);
    die "expected closed native birth\n" unless ref($birth) eq 'HASH'
        && keys(%$birth) == @fields && !grep { !exists($birth->{$_}) } @fields;
    for my $field (@fields) {
        my $value = $birth->{$field};
        die "expected native birth integer\n"
            unless defined($value) && !ref($value)
                && $JSON->encode($value) =~ /\A(?:0|[1-9][0-9]*)\z/;
    }
    die "invalid native birth\n" unless $birth->{pid} > 0 && $birth->{start_usec} < 1_000_000;
    return $birth;
}

sub observation_reference_key {
    die "expected evidence path and two births\n" unless @_ == 3;
    my ($directory, $observer, $target) = @_;
    return sha256_hex("fsmgen.rust_proxy_reference.observation.v1\0"
        . $JSON->encode([_relative_path($directory), _birth($observer), _birth($target)]));
}

sub _same_metadata {
    my ($a, $b, @fields) = @_;
    return @$a && @$b && !grep { $a->[$_] ne $b->[$_] } @fields;
}

sub _directory {
    my ($path) = @_;
    my ($absolute, $error) = repository_contained_path($path, must_exist => 1);
    die "$error\n" if defined $error;
    my @metadata = lstat($absolute);
    die "expected direct owned private same-volume directory\n"
        unless @metadata && S_ISDIR($metadata[2]) && $metadata[4] == $<
            && $metadata[0] == $DEVICE && ($metadata[2] & 07777) == 0700;
    return \@metadata;
}

sub _members {
    my ($path) = @_;
    opendir(my $directory, $path) or die "cannot inspect image members: $!\n";
    my @members;
    my $ok = eval {
        while (1) {
            $! = 0;
            my $name = readdir($directory);
            if (!defined($name)) {
                die "cannot read image members: $!\n" if $!;
                last;
            }
            next if $name eq '.' || $name eq '..';
            push @members, $name;
            die "too many image members\n" if @members > 3;
        }
        1;
    };
    my $error = $@;
    my $closed = closedir($directory);
    die $error unless $ok;
    die "cannot close image directory: $!\n" unless $closed;
    die "incomplete or unknown image members\n"
        unless @members == 3 && join(',', sort @members) eq 'image.json,rustup,rustup.c';
}

sub _source {
    my ($path, $mode, $limit) = @_;
    # Reuse the qualified bounded no-follow descriptor read. The additional
    # custody checks below enforce this store's stricter modes and link count.
    my ($bytes, $metadata, $handle) = FSM::Test::RustProxyFixture::_read_file($path, 1);
    my $ok = eval {
        die "invalid image source mode, links or size\n"
            unless ($metadata->[2] & 07777) == $mode && $metadata->[3] == 1
                && length($bytes) <= $limit;
        my $flags = fcntl($handle, F_GETFD, 0);
        die "cannot read descriptor flags: $!\n" unless defined $flags;
        fcntl($handle, F_SETFD, $flags | FD_CLOEXEC)
            or die "cannot seal descriptor inheritance: $!\n";
        1;
    };
    my $error = $@;
    unless ($ok) {
        # The lower reader transferred ownership even when these stricter
        # checks fail. Close that handle explicitly and preserve the cause.
        close($handle);
        die $error;
    }
    return {bytes => $bytes, metadata => $metadata, handle => $handle, path => $path};
}

sub _recheck_source {
    my ($source) = @_;
    my @descriptor = stat($source->{handle});
    my @named = lstat($source->{path});
    die "source descriptor or named identity changed\n"
        unless _same_metadata($source->{metadata}, \@descriptor, 0,1,2,3,4,7,9,10)
            && _same_metadata($source->{metadata}, \@named, 0,1,2,3,4,7,9,10)
            && S_ISREG($named[2]);
}

sub read_entry {
    die "expected isolated root, key and compiled byte pair\n" unless @_ == 4;
    my ($case, $key, $expected_c, $expected_image) = @_;
    _relative_path($case);
    die "only the inactive qualification namespace is admitted\n"
        unless $case =~ /\A\Q$CASE_PREFIX\Efsmgen-[A-Za-z0-9_]+\z/;
    die "invalid image key\n" unless defined($key) && !ref($key) && $key =~ /\A[0-9a-f]{64}\z/;
    die "key does not match compiled bytes\n" unless $key eq image_key($expected_c, $expected_image);
    my $base = File::Spec->catdir($ROOT, $case);
    my $entry = "$base/images/$key";
    my @directories = ($base, "$base/images", $entry);
    my @before = map { _directory($_) } @directories;
    _members($entry);
    my @sources;
    my $result;
    my $ok = eval {
        push @sources, _source("$entry/rustup.c", 0400, $SOURCE_LIMIT);
        push @sources, _source("$entry/rustup", 0500, $SOURCE_LIMIT);
        push @sources, _source("$entry/image.json", 0400, $MANIFEST_LIMIT);
        die "image differs from the actual compiled byte pair\n"
            unless $sources[0]{bytes} eq $expected_c && $sources[1]{bytes} eq $expected_image;
        validate_manifest($sources[2]{bytes}, $expected_c, $expected_image);
        _members($entry);
        for my $i (0 .. $#directories) {
            die "image directory identity changed\n"
                unless _same_metadata($before[$i], _directory($directories[$i]), 0,1,2,4);
        }
        _recheck_source($_) for @sources;
        $result = {key => $key, snapshots => [map {
            {bytes => $_->{bytes}, identity => {
                path => File::Spec->abs2rel($_->{path}, $ROOT),
                device => $_->{metadata}[0], inode => $_->{metadata}[1],
                size_bytes => length($_->{bytes}), sha256 => sha256_hex($_->{bytes})}}
        } @sources]};
        1;
    };
    my $error = $@;
    my $close_error = '';
    for my $source (@sources) {
        $close_error ||= "cannot close image descriptor: $!\n" unless close($source->{handle});
    }
    die $error unless $ok;
    die $close_error if length($close_error);
    return $result;
}

1;
