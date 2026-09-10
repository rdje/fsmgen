#!/usr/bin/env perl
use strict;
use warnings;
our $forbidden = 0;
BEGIN {
    *CORE::GLOBAL::fork = sub { ++$forbidden; die 'forbidden fork'; };
    *CORE::GLOBAL::system = sub { ++$forbidden; die 'forbidden system'; };
}
use FindBin;
use lib "$FindBin::Bin/../../../perl", "$FindBin::Bin/../../../t/lib",
    "$FindBin::Bin/../native-proxy-image-custody-20260910",
    "$FindBin::Bin/../native-proxy-image-coordination-20260910", $FindBin::Bin;
use Digest::SHA qw(sha256_hex);
use Fcntl qw(F_GETFD FD_CLOEXEC);
use File::Spec;
use File::Temp ();
use JSON::PP ();
use Test::More;
use FSM::ProjectDataLocality qw(ensure_project_artifact_dir repository_root);
use FSM::Test::RustProxyFixture ();
BEGIN { *CORE::GLOBAL::exec = sub { ++$forbidden; die 'forbidden exec'; }; }
use Publication;

my $root = repository_root();
my $parent = ensure_project_artifact_dir(qw(tmp native-proxy-image-custody cases));
my $logs = ensure_project_artifact_dir(qw(logs native-proxy-image-publication-20260910));
my $json = JSON::PP->new->canonical->ascii;
my $vector = $json->decode(read_bytes("$FindBin::Bin/../native-proxy-image-custody-20260910/vectors.json"));
my ($c, $image) = map { pack('H*', $_) } @$vector{qw(generated_c_hex image_hex)};
my $key = $vector->{key};
my $publish = \&NativeProxyImagePublication::publish_image;
my @retired;
my @controls;
my ($first, $reuse);
no warnings 'redefine';
local *FSM::Test::RustProxyFixture::supervise_process = sub { ++$forbidden; die 'forbidden compiler'; };

sub read_bytes {
    open my $fh, '<:raw', $_[0] or die "read: $!";
    local $/; my $bytes = <$fh>; close $fh or die "close: $!"; return $bytes;
}
sub write_bytes {
    my ($path, $bytes, $mode) = @_;
    open my $fh, '>:raw', $path or die "write: $!";
    print {$fh} $bytes or die "write bytes: $!";
    close $fh or die "close: $!"; chmod($mode, $path) or die "chmod: $!";
}
sub with_case {
    my ($callback) = @_;
    my $work = File::Temp->newdir('fsmgen-XXXXXXXX', DIR => $parent, CLEANUP => 1);
    my $case = File::Spec->abs2rel("$work", $root);
    $callback->($case, "$work");
    undef $work;
    die 'inert case remains' if -e "$root/$case" || -l "$root/$case";
    push @retired, $case;
}
sub rejects {
    my ($name, $callback, $expected) = @_;
    my $result;
    my $ok = eval { $result = $callback->(); 1 };
    my $error = $@;
    ok(!$ok && $error =~ $expected && !defined($result), $name)
        or diag($error || 'unexpected success');
    push @controls, {name => $name, rejected => $ok ? 0 : 1,
        expected_diagnostic => $error =~ $expected ? 1 : 0, returned_result => defined($result) ? 1 : 0};
}

with_case(sub {
    my ($case, $path) = @_;
    my $seal = \&NativeProxyImagePublication::_seal_payload;
    my @handles;
    local *NativeProxyImagePublication::_seal_payload = sub {
        push @handles, $_[0];
        ok(fcntl($_[0], F_GETFD, 0) & FD_CLOEXEC, 'canonical writer is close-on-exec');
        is((stat($_[0]))[2] & 07777, 0400, 'payload stays non-executable before sealing');
        return $seal->(@_);
    };
    $first = $publish->($case, $c, $image);
    is($first->{created}, 1, 'first publication creates canonical image');
    is($first->{runtime_authorized}, 0, 'content publication grants no runtime authorization');
    ok(!defined($first->{executable}), 'content result has no runnable executable');
    is($first->{image}{key}, $key, 'independent Python key selects canonical directory');
    is_deeply([map { $_->{bytes} } @{$first->{image}{snapshots}}], [$c, $image, $vector->{manifest}],
        'final snapshots contain independently expected C, image and manifest');
    for my $source (@{$first->{image}{snapshots}}) {
        my @metadata = lstat("$root/$source->{identity}{path}");
        is($source->{identity}{inode}, $metadata[1], 'snapshot joins actual native inode');
        is($metadata[3], 1, 'canonical files have no hard-link aliases');
        is($source->{identity}{sha256}, sha256_hex(read_bytes("$root/$source->{identity}{path}")), 'actual bytes join snapshot digest');
    }
    ok(!grep(defined(fileno($_)), @handles), 'every canonical writer closes');
    $reuse = $publish->($case, $c, $image);
    is($reuse->{created}, 0, 'equal bytes reuse an existing complete image');
    is_deeply($reuse->{image}, $first->{image}, 'reuse preserves exact canonical inodes and bytes');
    is(scalar @handles, 3, 'reuse performs no new payload write or seal');
    is_deeply($reuse->{lock}, $first->{lock}, 'creation and reuse share the permanent lock identity');
});

with_case(sub {
    my ($case, $path) = @_;
    my $original = $publish->($case, $c, $image);
    my $other = $publish->($case, $c, $image.'variant');
    isnt($other->{image}{key}, $key, 'different actual bytes select a distinct image');
    is_deeply($publish->($case, $c, $image)->{image}, $original->{image}, 'different publication leaves original immutable');
    local *NativeProxyImageCustody::image_key = sub { return $key; };
    rejects('modeled content-key collision', sub { $publish->($case, $c, $image.'collision') }, qr/compiled byte pair/);
    is(read_bytes("$path/images/$key/rustup"), $image, 'collision rejection never overwrites image');
});

with_case(sub {
    my ($case, $path) = @_;
    $publish->($case, $c, $image);
    for my $i (1 .. 31) { mkdir(sprintf('%s/images/%064x', $path, $i), 0700) or die $!; }
    is($publish->($case, $c, $image)->{created}, 0, 'equal image remains reusable at image capacity');
    rejects('new image at capacity', sub { $publish->($case, $c, $image.'new') }, qr/publication capacity/);
    opendir my $dir, "$path/images" or die $!;
    my @names = grep { $_ ne '.' && $_ ne '..' } readdir($dir); closedir $dir or die $!;
    is(scalar @names, 32, 'capacity rejection neither creates nor evicts an image');
});

for my $kind (qw(empty_directory missing_manifest writable_image changed_bytes)) {
    with_case(sub {
        my ($case, $path) = @_;
        NativeProxyImageCoordination::inspect_store($case);
        if ($kind eq 'empty_directory') { mkdir("$path/images/$key", 0700) or die $!; }
        else {
            $publish->($case, $c, $image);
            unlink("$path/images/$key/image.json") or die $! if $kind eq 'missing_manifest';
            if ($kind eq 'writable_image' || $kind eq 'changed_bytes') {
                chmod(0600, "$path/images/$key/rustup") or die $!;
                write_bytes("$path/images/$key/rustup", 'x' x length($image), 0500) if $kind eq 'changed_bytes';
            }
        }
        my $calls = 0;
        local *NativeProxyImagePublication::_write_payload = sub { ++$calls; die 'unexpected repair write'; };
        rejects("existing $kind", sub { $publish->($case, $c, $image) }, qr/incomplete|mode, links or size|compiled byte pair/);
        is($calls, 0, 'invalid existing image is never repaired');
    });
}

for my $role (qw(rustup.c image.json rustup)) {
    for my $boundary (qw(before after)) {
        with_case(sub {
            my ($case, $path) = @_;
            my $write = \&NativeProxyImagePublication::_write_payload;
            my @attempts;
            local *NativeProxyImagePublication::_write_payload = sub {
                my ($name) = $_[0] =~ m{/([^/]+)\z}; push @attempts, $name;
                die "injected $boundary $role\n" if $name eq $role && $boundary eq 'before';
                my $result = $write->(@_);
                die "injected $boundary $role\n" if $name eq $role && $boundary eq 'after';
                return $result;
            };
            rejects("interruption $boundary $role", sub { $publish->($case, $c, $image) }, qr/injected/);
            is($attempts[-1], $role, 'first failure stops all later payload operations');
            is(scalar(grep($_ eq $role, @attempts)), 1, 'failed payload is not retried');
            ok(-d "$path/images/$key", 'partial publication is conservatively retained');
        });
    }
}

for my $boundary (qw(before after)) {
    with_case(sub {
        my ($case, $path) = @_;
        my $seal = \&NativeProxyImagePublication::_seal_payload;
        local *NativeProxyImagePublication::_seal_payload = sub {
            die "injected before executable seal\n" if $_[1] == 0500 && $boundary eq 'before';
            $seal->(@_);
            die "injected after executable seal\n" if $_[1] == 0500 && $boundary eq 'after';
        };
        rejects("interruption $boundary executable seal", sub { $publish->($case, $c, $image) }, qr/injected/);
        is((lstat("$path/images/$key/rustup"))[2] & 07777, $boundary eq 'before' ? 0400 : 0500,
            'retained permission boundary is explicit; no result authorizes execution');
    });
}

for my $kind (qw(source directory)) {
    with_case(sub {
        my ($case, $path) = @_;
        my $write = \&NativeProxyImagePublication::_write_payload;
        local *NativeProxyImagePublication::_write_payload = sub {
            my $result = $write->(@_);
            if ($_[0] =~ /\/rustup\.c\z/) {
                if ($kind eq 'source') {
                    rename("$path/images/$key/rustup.c", "$path/references/old-source") or die $!;
                } else {
                    rename("$path/images/$key", "$path/references/old-image") or die $!;
                    mkdir("$path/images/$key", 0700) or die $!;
                }
                write_bytes("$path/images/$key/rustup.c", $c, 0400);
            }
            return $result;
        };
        rejects("same-byte sealed $kind replacement", sub { $publish->($case, $c, $image) },
            $kind eq 'source' ? qr/sealed canonical source identity/ : qr/canonical image directory replaced/);
    });
}

with_case(sub {
    my ($case, $path) = @_;
    rejects('no publication callback', sub { $publish->($case, $c, $image, sub { die 'callback ran' }) }, qr/expected inactive root/);
    rejects('unknown fixed transaction', sub { NativeProxyImageCoordination::_transaction($case, 'caller_operation') }, qr/unknown inactive transaction/);
    rejects('oversized publication bytes', sub { $publish->($case, $c, 'x' x 65537) }, qr/bounded bytes/);
    rejects('direct internal publication bypass', sub {
        NativeProxyImagePublication::_publish_locked($case, {images => []}, $c, $image);
    }, qr/sealed coordinator/);
    ok(!-e "$path/coordination.lock", 'invalid requests perform no store bootstrap');
});

my $mutant = read_bytes("$FindBin::Bin/Publication.pm");
$mutant =~ s/package NativeProxyImagePublication;/package NativeProxyImagePublicationMutant;/ or die 'package absent';
$mutant =~ s/        die "sealed canonical source identity changed\\n"\n.*?\$sealed->\[7\];\n//s or die 'sealed identity guard absent';
eval $mutant; die $@ if $@;
with_case(sub {
    my ($case, $path) = @_;
    my $original = \&NativeProxyImagePublicationMutant::_write_payload;
    my $original_c_inode;
    local *NativeProxyImagePublication::_publish_locked = \&NativeProxyImagePublicationMutant::_publish_locked;
    local *NativeProxyImagePublicationMutant::_write_payload = sub {
        my $metadata = $original->(@_);
        if ($_[0] =~ /\/rustup\.c\z/) {
            $original_c_inode = $metadata->[1];
            rename("$path/images/$key/rustup.c", "$path/references/old-source") or die $!;
            write_bytes("$path/images/$key/rustup.c", $c, 0400);
        }
        return $metadata;
    };
    my $result = $publish->($case, $c, $image);
    isnt($result->{image}{snapshots}[0]{identity}{inode}, $original_c_inode,
        'independent creation-inode oracle defeats removed sealed-source guard');
});

is($forbidden, 0, 'no compiler or process creation attempted');
ok(!grep(-e "$root/$_" || -l "$root/$_", @retired), 'all owned inert namespaces are absent');
my $result = {schema => 'fsmgen.inactive_image_publication_qualification.v1',
    success => Test::More->builder->is_passing ? JSON::PP::true : JSON::PP::false,
    first => {created => $first->{created}, lock => $first->{lock}, image_key => $first->{image}{key},
        runtime_authorized => $first->{runtime_authorized}, executable => $first->{executable},
        sources => [map { $_->{identity} } @{$first->{image}{snapshots}}]},
    reuse => {created => $reuse->{created}, lock => $reuse->{lock}, image_key => $reuse->{image}{key},
        runtime_authorized => $reuse->{runtime_authorized}, executable => $reuse->{executable},
        sources => [map { $_->{identity} } @{$reuse->{image}{snapshots}}]},
    controls => \@controls, retired_cases => \@retired, forbidden_process_attempts => $forbidden,
    sealed_source_mutant_defeated => 1,
    limits => 'Inert publication/custody only. No actual compiler, runtime reference, worker contention, '
        .'native behavior, maintenance or product activation.'};
write_bytes("$logs/qualification.json", $json->pretty->encode($result), 0600);
done_testing;
