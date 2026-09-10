#!/usr/bin/env perl
use strict;
use warnings;
our $forbidden = 0;
BEGIN {
    *CORE::GLOBAL::fork = sub { ++$forbidden; die 'forbidden fork'; };
    *CORE::GLOBAL::system = sub { ++$forbidden; die 'forbidden system'; };
}
use FindBin;
use lib "$FindBin::Bin/../../../perl", "$FindBin::Bin/../../../t/lib", $FindBin::Bin;
use Digest::SHA qw(sha256_hex);
use Fcntl qw(F_GETFD FD_CLOEXEC);
use File::Spec;
use File::Temp ();
use JSON::PP ();
use POSIX ();
use Test::More;
use FSM::ProjectDataLocality qw(ensure_project_artifact_dir repository_root);
# Load the qualified supervisor before overriding exec: Perl's indirect
# exec {program} argv syntax is not accepted by an ordinary sub override.
# Its fork boundary is already trapped; loading it runs no subprocess.
use FSM::Test::RustProxyFixture ();
BEGIN { *CORE::GLOBAL::exec = sub { ++$forbidden; die 'forbidden exec'; }; }
use ImageCustody;

my $json = JSON::PP->new->canonical->ascii;
my $root = repository_root();
my $parent = ensure_project_artifact_dir(qw(tmp native-proxy-image-custody cases));
my $log = ensure_project_artifact_dir(qw(logs native-proxy-image-custody-20260910));
my @controls;
my @retired;
my $snapshot;
my $v = $json->decode(read_bytes("$FindBin::Bin/vectors.json"));
my $c = pack('H*', $v->{generated_c_hex});
my $image = pack('H*', $v->{image_hex});
my $key = $v->{key};
my $read = \&NativeProxyImageCustody::read_entry;

no warnings 'redefine';
local *FSM::Test::RustProxyFixture::supervise_process = sub {
    ++$forbidden; die 'forbidden compiler';
};

sub read_bytes {
    open my $fh, '<:raw', $_[0] or die "read: $!";
    local $/; my $bytes = <$fh>;
    close $fh or die "close: $!";
    return $bytes;
}
sub write_bytes {
    my ($path, $bytes, $mode) = @_;
    chmod(0600, $path) == 1 or die "chmod: $!" if -e $path;
    open my $fh, '>:raw', $path or die "write: $!";
    print {$fh} $bytes or die "write bytes: $!";
    close $fh or die "close: $!";
    chmod($mode, $path) == 1 or die "seal: $!";
}
sub rejects {
    my ($name, $callback, $reason) = @_;
    my $ok = eval { $callback->(); 1 };
    my $error = $@;
    ok(!$ok && $error =~ $reason, $name) or diag($error || 'unexpected acceptance');
    push @controls, {name => $name, rejected => $ok ? 0 : 1,
        expected_diagnostic => $error =~ $reason ? 1 : 0};
}
sub with_entry {
    my ($callback) = @_;
    my $work = File::Temp->newdir('fsmgen-XXXXXXXX', DIR => $parent, CLEANUP => 1);
    mkdir("$work/images", 0700) or die "mkdir images: $!";
    my $entry = "$work/images/$key";
    mkdir($entry, 0700) or die "mkdir entry: $!";
    write_bytes("$entry/rustup.c", $c, 0400);
    write_bytes("$entry/rustup", $image, 0500);
    write_bytes("$entry/image.json", $v->{manifest}, 0400);
    my $relative = File::Spec->abs2rel("$work", $root);
    $callback->($relative, $entry);
    undef $work;
    die "owned inert workspace remains" if -e "$root/$relative" || -l "$root/$relative";
    push @retired, $relative;
}

is(NativeProxyImageCustody::image_key($c, $image), $key, 'Python unsigned-64 byte framing agrees');
is(NativeProxyImageCustody::manifest_bytes($c, $image), $v->{manifest}, 'Python canonical manifest agrees');
is(NativeProxyImageCustody::runtime_reference_key($v->{workspace}), $v->{runtime_reference_key},
   'Python runtime reference key agrees');
is(NativeProxyImageCustody::observation_reference_key(@$v{qw(evidence_directory observer_birth target_birth)}),
   $v->{observation_reference_key}, 'Python Unicode observation reference key agrees');
ok(NativeProxyImageCustody::validate_manifest($v->{manifest}, $c, $image), 'exact manifest accepted');
for my $change (
    ['unknown field', sub { $_[0]{extra} = 0 }],
    ['numeric string', sub { $_[0]{executable}{size_bytes} = sprintf('%d', $_[0]{executable}{size_bytes}) }],
    ['boolean size', sub { $_[0]{executable}{size_bytes} = JSON::PP::true }],
    ['negative size', sub { $_[0]{generated_c}{size_bytes} = -1 }],
    ['null payload', sub { $_[0]{generated_c} = undef }],
    ['wrong schema', sub { $_[0]{schema} = 'other' }],
    ['changed digest', sub { $_[0]{executable}{sha256} = '0' x 64 }],
    ['missing key', sub { delete $_[0]{key} }],
    ['array payload', sub { $_[0]{executable} = [] }],
) {
    my $manifest = $json->decode($v->{manifest});
    $change->[1]->($manifest);
    rejects("manifest $change->[0]", sub {
        NativeProxyImageCustody::validate_manifest($json->encode($manifest), $c, $image);
    }, qr/manifest differs/);
}
for my $spelling ("$v->{manifest}\n", '{"key":"duplicate",'.substr($v->{manifest},1),
                    $v->{manifest} =~ s/("size_bytes":)([0-9]+)/${1}${2}.0/r) {
    rejects('noncanonical or duplicate JSON spelling', sub {
        NativeProxyImageCustody::validate_manifest($spelling, $c, $image);
    }, qr/manifest differs/);
}
rejects('manifest byte limit', sub { NativeProxyImageCustody::validate_manifest(' ' x 4097, $c, $image) }, qr/bounded bytes/);
rejects('source byte limit', sub { NativeProxyImageCustody::image_key('x' x 65537, $image) }, qr/bounded bytes/);
rejects('byte scalar reference', sub { NativeProxyImageCustody::image_key([], $image) }, qr/bounded bytes/);
for my $path ('/absolute', 'a/../b', 'a//b', 'a/', '.', "a\0b", 'a\\b') {
    rejects('noncanonical relative path', sub { NativeProxyImageCustody::runtime_reference_key($path) }, qr/root-relative/);
}
for my $value ('101', JSON::PP::true, undef, -1, 1.5) {
    my $birth = {%{$v->{observer_birth}}, pid => $value};
    rejects('wrong native birth integer type', sub {
        NativeProxyImageCustody::observation_reference_key($v->{evidence_directory}, $birth, $v->{target_birth});
    }, qr/birth integer/);
}

with_entry(sub {
    my ($case) = @_;
    $snapshot = $read->($case, $key, $c, $image);
    is_deeply([map { $_->{bytes} } @{$snapshot->{snapshots}}], [$c, $image, $v->{manifest}],
        'actual descriptor snapshots preserve exact C, image and manifest bytes');
    for my $source (@{$snapshot->{snapshots}}) {
        is($source->{identity}{sha256}, sha256_hex($source->{bytes}), 'snapshot digest matches retained bytes');
        is($source->{identity}{device}, (stat($root))[0], 'snapshot stays on repository volume');
        is($source->{identity}{inode}, (lstat("$root/$source->{identity}{path}"))[1], 'snapshot inode matches current name');
    }
});

my @filesystem = (
    ['writable source', sub { chmod(0600, "$_[1]/rustup.c") or die $! }, qr/mode, links or size/],
    ['hard-linked image', sub { link("$_[1]/rustup", "$_[0]/alias") or die $! }, qr/mode, links or size/],
    ['symlink image', sub { unlink("$_[1]/rustup") or die $!; symlink('rustup.c', "$_[1]/rustup") or die $! }, qr/symlink/],
    ['FIFO image', sub { unlink("$_[1]/rustup") or die $!; POSIX::mkfifo("$_[1]/rustup", 0500) == 0 or die $! }, qr/regular file/],
    ['directory image', sub { unlink("$_[1]/rustup") or die $!; mkdir("$_[1]/rustup", 0500) or die $! }, qr/regular file/],
    ['oversized image', sub { write_bytes("$_[1]/rustup", 'x' x 65537, 0500) }, qr/regular file/],
    ['oversized manifest', sub { write_bytes("$_[1]/image.json", ' ' x 4097, 0400) }, qr/mode, links or size/],
    ['changed image bytes', sub { write_bytes("$_[1]/rustup", 'z' x length($image), 0500) }, qr/compiled byte pair/],
    ['changed C bytes', sub { write_bytes("$_[1]/rustup.c", 'z' x length($c), 0400) }, qr/compiled byte pair/],
    ['unknown member', sub { write_bytes("$_[1]/unknown", '', 0400) }, qr/too many image/],
    ['missing manifest', sub { unlink("$_[1]/image.json") or die $! }, qr/incomplete/],
    ['public directory', sub { chmod(0755, $_[1]) or die $! }, qr/private same-volume directory/],
    ['symlink ancestry', sub { rename($_[1], "$_[0]/moved") or die $!; symlink("$_[0]/moved", $_[1]) or die $! }, qr/symlink ancestry/],
);
for my $control (@filesystem) {
    with_entry(sub {
        my ($case, $entry) = @_;
        $control->[1]->("$root/$case", $entry);
        rejects($control->[0], sub { $read->($case, $key, $c, $image) }, $control->[2]);
    });
}

for my $replace ('source', 'directory') {
    with_entry(sub {
        my ($case, $entry) = @_;
        my $original = \&FSM::Test::RustProxyFixture::_read_file;
        local *FSM::Test::RustProxyFixture::_read_file = sub {
            my @result = $original->(@_);
            if ($_[0] eq "$entry/image.json") {
                if ($replace eq 'source') {
                    rename("$entry/rustup.c", "$root/$case/old-source") or die $!;
                    write_bytes("$entry/rustup.c", $c, 0400);
                } else {
                    rename($entry, "$root/$case/old-entry") or die $!;
                    mkdir($entry, 0700) or die $!;
                    write_bytes("$entry/rustup.c", $c, 0400);
                    write_bytes("$entry/rustup", $image, 0500);
                    write_bytes("$entry/image.json", $v->{manifest}, 0400);
                }
            }
            return @result;
        };
        rejects("same-byte $replace inode replacement", sub { $read->($case, $key, $c, $image) },
                $replace eq 'source' ? qr/source descriptor or named identity/ : qr/directory identity/);
    });
}

with_entry(sub {
    my ($case, $entry) = @_;
    my $source = NativeProxyImageCustody::_source("$entry/rustup.c", 0400, 65536);
    ok(fcntl($source->{handle}, F_GETFD, 0) & FD_CLOEXEC, 'source descriptor is close-on-exec');
    close($source->{handle}) or die $!;
    rejects('wrong key', sub { $read->($case, '0' x 64, $c, $image) }, qr/compiled bytes/);
    rejects('production root excluded', sub { $read->('.artifacts/cache/rust-proxy-images/v1', $key, $c, $image) }, qr/inactive qualification namespace/);
});

# A removed byte-equality guard must make the real corruption oracle fail.
my $mutant = read_bytes("$FindBin::Bin/ImageCustody.pm");
$mutant =~ s/package NativeProxyImageCustody;/package NativeProxyImageCustodyMutant;/ or die 'mutant package absent';
$mutant =~ s/        die "image differs from the actual compiled byte pair\\n"\n            unless .*?;\n//s or die 'mutant guard absent';
eval $mutant; die $@ if $@;
with_entry(sub {
    my ($case, $entry) = @_;
    write_bytes("$entry/rustup", 'z' x length($image), 0500);
    my $result = NativeProxyImageCustodyMutant::read_entry($case, $key, $c, $image);
    isnt($result->{snapshots}[1]{bytes}, $image, 'independent corruption oracle defeats removed byte guard');
});

is($forbidden, 0, 'no compiler or process creation attempted');
ok(!grep(-e "$root/$_" || -l "$root/$_", @retired), 'all exact inert cases are absent');
my $result = {schema => 'fsmgen.inactive_image_custody_qualification.v1',
    scope => 'inert byte/filesystem custody only; no publication, lifetime, native behavior or product activation',
    controls => \@controls, forbidden_process_attempts => $forbidden,
    retired_cases => \@retired, positive_snapshot => [map { $_->{identity} } @{$snapshot->{snapshots}}],
    byte_guard_mutant_defeated => 1,
    success => Test::More->builder->is_passing ? JSON::PP::true : JSON::PP::false};
write_bytes("$log/qualification.json", $json->pretty->encode($result), 0400);
done_testing;
