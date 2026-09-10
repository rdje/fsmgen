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
    "$FindBin::Bin/../native-proxy-image-coordination-20260910",
    "$FindBin::Bin/../native-proxy-image-publication-20260910",
    "$FindBin::Bin/../native-proxy-runtime-records-20260910", $FindBin::Bin;
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
use ReferenceCensus;

my $root = repository_root();
my $json = JSON::PP->new->canonical->ascii;
my $parent = ensure_project_artifact_dir(qw(tmp native-proxy-image-custody cases));
my $log = ensure_project_artifact_dir(qw(logs native-proxy-runtime-census-20260910));
my $v = $json->decode(read_bytes("$FindBin::Bin/../native-proxy-image-custody-20260910/vectors.json"));
my ($c, $image) = map { pack('H*', $_) } @$v{qw(generated_c_hex image_hex)};
my $inspect = \&NativeProxyReferenceCensus::inspect_runtime_references;
my $closure = \&NativeProxyReferenceCensus::_closure;
my (@controls, @retired, @mutants, $positive, $capacity, $incomplete);
no warnings 'redefine';
local *FSM::Test::RustProxyFixture::supervise_process = sub { ++$forbidden; die 'forbidden compiler'; };

sub read_bytes {
    open my $fh, '<:raw', $_[0] or die "read: $!";
    my $bytes = do { local $/; <$fh> };
    close $fh or die "close read: $!";
    return $bytes;
}
sub write_bytes {
    my ($path, $bytes, $mode) = @_;
    chmod(0600, $path) == 1 or die "writable fixture: $!" if -e $path;
    open my $fh, '>:raw', $path or die "write: $!";
    print {$fh} $bytes or die "bytes: $!";
    close $fh or die "close write: $!";
    chmod($mode, $path) == 1 or die "seal fixture: $!";
}
sub clone { return $json->decode($json->encode($_[0])); }
sub with_store {
    my ($callback) = @_;
    my $work = File::Temp->newdir('fsmgen-XXXXXXXX', DIR => $parent, CLEANUP => 1);
    my $case = File::Spec->abs2rel("$work", $root);
    my $published = NativeProxyImagePublication::publish_image($case, $c, $image);
    $callback->($case, $published->{image});
    undef $work;
    die 'owned inert case remains' if -e "$root/$case" || -l "$root/$case";
    push @retired, $case;
}
sub record_for {
    my ($case, $snapshot, $suffix) = @_;
    my $workspace = '.artifacts/tmp/process-supervisor-tests/fsmgen-Census20260910' . $suffix;
    die 'synthetic workspace unexpectedly exists' if -e "$root/$workspace" || -l "$root/$workspace";
    my @sources = map { clone($_->{identity}) } @{$snapshot->{snapshots}}[0,1];
    # These stale values intentionally differ from the observed image IDs.
    for my $index (0, 1) { $sources[$index]{device} = 17; $sources[$index]{inode} = 100 + $index; }
    return {schema => 'fsmgen.test.rust_proxy_image_reference.v1',
        workspace => $workspace, reference_key => NativeProxyImageCustody::runtime_reference_key($workspace),
        image_key => $snapshot->{key}, workspace_identity => {path => $workspace, device => 17, inode => 99},
        selected_sources => \@sources};
}
sub add_reference {
    my ($case, $record, $name) = @_;
    $name //= "$record->{reference_key}.json";
    my $path = "$root/$case/references/$name";
    write_bytes($path, $json->encode($record), 0400);
    return $path;
}
sub rejects {
    my ($name, $callback, $reason) = @_;
    my $value;
    my $ok = eval { $value = $callback->(); 1 };
    my $error = $@;
    ok(!$ok && $error =~ $reason && !defined($value), $name) or diag($error || 'unexpected acceptance');
    push @controls, {name => $name, rejected => $ok ? 0 : 1,
        expected_diagnostic => $error =~ $reason ? 1 : 0, returned_result => defined($value) ? 1 : 0};
}

with_store(sub {
    my ($case, $snapshot) = @_;
    my $empty = $inspect->($case);
    is_deeply($empty->{references}, [], 'empty reference census grants no holds');
    is_deeply($empty->{images}, [], 'unreferenced images are outside reference content admission');
    add_reference($case, record_for($case, $snapshot, $_)) for qw(A B);
    {
        local *NativeProxyReferenceCensus::_closure = sub {
            for my $source (@{$_[2]}) {
                my $flags = fcntl($source->{handle}, F_GETFD, 0);
                ok(defined($flags) && ($flags & FD_CLOEXEC), 'held reference descriptor excludes inheritance');
            }
            return $closure->(@_);
        };
        $positive = $inspect->($case);
    }
    is(scalar(@{$positive->{references}}), 2, 'both absent-workspace owners remain retained');
    is(scalar(@{$positive->{images}}), 1, 'shared image has one returned snapshot');
    is($positive->{runtime_authorized}, 0, 'inspection grants no runtime authority');
    ok(!defined($positive->{executable}), 'inspection returns no runnable executable');
    is_deeply($positive->{references}[0]{record}{workspace_identity},
        {path => $positive->{references}[0]{record}{workspace}, device => 17, inode => 99},
        'historical identity preserved rather than reinterpreted');
    is(read_bytes("$root/" . $positive->{references}[0]{source}{identity}{path}),
        $positive->{references}[0]{source}{bytes}, 'checked reference bytes remain present');
});

for my $change (
    ['unknown runtime field', sub { $_[0]{extra} = 1 }, qr/closed record/],
    ['merged runtime fields', sub { $_[0]{'image_key,reference_key'} = delete $_[0]{image_key}; delete $_[0]{reference_key} }, qr/closed record/],
    ['boolean historical inode', sub { $_[0]{workspace_identity}{inode} = JSON::PP::true }, qr/JSON integer/],
    ['wrong runtime key', sub { $_[0]{reference_key} = '0' x 64 }, qr/key differs/],
    ['unknown observation format', sub { $_[0]{schema} = 'fsmgen.test.rust_proxy_image_observation_reference.v1' }, qr/runtime reference schema/],
    ['wrong reference content digest', sub { $_[0]{selected_sources}[0]{sha256} = '0' x 64 }, qr/content differs/],
    ['wrong reference content length', sub { $_[0]{selected_sources}[1]{size_bytes}++ }, qr/content differs/],
    ['dangling referenced image', sub {
        $_[0]{image_key} = '0' x 64;
        $_->{path} =~ s{/images/[0-9a-f]+/}{'/images/' . ('0' x 64) . '/'}e for @{$_[0]{selected_sources}};
    }, qr/absent image/],
) {
    with_store(sub {
        my ($case, $snapshot) = @_;
        my $record = record_for($case, $snapshot, 'Bad');
        my $name = "$record->{reference_key}.json";
        $change->[1]->($record);
        my $path = add_reference($case, $record, $name);
        my $before = read_bytes($path);
        rejects($change->[0], sub { $inspect->($case) }, $change->[2]);
        is(read_bytes($path), $before, "$change->[0] preserves the unresolved record");
    });
}
for my $shape (qw(wrong_filename partial duplicate writable hardlink)) {
    with_store(sub {
        my ($case, $snapshot) = @_;
        my $record = record_for($case, $snapshot, 'Shape');
        my $path = add_reference($case, $record, $shape eq 'wrong_filename' ? ('0' x 64) . '.json' : undef);
        if ($shape eq 'partial') { write_bytes($path, '', 0400); }
        if ($shape eq 'duplicate') { write_bytes($path, '{"schema":"discarded",' . substr($json->encode($record), 1), 0400); }
        if ($shape eq 'writable') { chmod(0600, $path) == 1 or die $!; }
        if ($shape eq 'hardlink') { link($path, "$root/$case/references/" . ('1' x 64) . '.json') or die $!; }
        my $before = read_bytes($path);
        my %reason = (wrong_filename => qr/filename differs/, partial => qr/invalid runtime JSON/,
            duplicate => qr/not canonical/, writable => qr/source mode/, hardlink => qr/source mode/);
        rejects("reference $shape", sub { $inspect->($case) }, $reason{$shape});
        is(read_bytes($path), $before, "$shape reference is not repaired or removed");
    });
}
for my $shape (qw(missing_manifest changed_image)) {
    with_store(sub {
        my ($case, $snapshot) = @_;
        add_reference($case, record_for($case, $snapshot, 'Image'));
        my $entry = "$root/$case/images/$snapshot->{key}";
        if ($shape eq 'missing_manifest') { unlink("$entry/image.json") or die $!; }
        else { write_bytes("$entry/rustup", $image . 'changed', 0500); }
        rejects("referenced image $shape", sub { $inspect->($case) }, qr/(?:incomplete|key does not match)/);
    });
}
for my $shape (qw(reference_replaced reference_bytes_changed reference_added image_replaced image_directory_replaced)) {
    with_store(sub {
        my ($case, $snapshot) = @_;
        my $path = add_reference($case, record_for($case, $snapshot, 'Replace'));
        local *NativeProxyReferenceCensus::_closure = sub {
            if ($shape eq 'reference_replaced') {
                my $bytes = read_bytes($path); unlink($path) or die $!; write_bytes($path, $bytes, 0400);
            } elsif ($shape eq 'reference_bytes_changed') {
                my $record = $json->decode(read_bytes($path)); $record->{workspace_identity}{inode}++;
                write_bytes($path, $json->encode($record), 0400);
            } elsif ($shape eq 'reference_added') {
                add_reference($case, record_for($case, $snapshot, 'Added'));
            } elsif ($shape eq 'image_replaced') {
                my $exe = "$root/$case/images/$snapshot->{key}/rustup";
                unlink($exe) or die $!; write_bytes($exe, $image, 0500);
            } else {
                my $entry = "$root/$case/images/$snapshot->{key}";
                rename($entry, "$entry.old") or die $!;
                mkdir($entry, 0700) or die $!;
                write_bytes("$entry/$_", read_bytes("$entry.old/$_"), $_ eq 'rustup' ? 0500 : 0400)
                    for qw(rustup rustup.c image.json);
            }
            return $closure->(@_);
        };
        rejects("closure $shape", sub { $inspect->($case) }, qr/(?:changed|replaced)/);
    });
}
with_store(sub {
    my ($case, $snapshot) = @_;
    add_reference($case, record_for($case, $snapshot, "Cap$_")) for 0..127;
    my $result = $inspect->($case);
    is(scalar(@{$result->{references}}), 128, 'exact combined reference ceiling retains every runtime owner');
    $capacity = {case => $case, keys => [map { $_->{record}{reference_key} } @{$result->{references}}]};
    add_reference($case, record_for($case, $snapshot, 'Cap128'));
    rejects('reference capacity exceeded', sub { $inspect->($case) }, qr/capacity exceeded/);
    is(scalar(@{NativeProxyImageCoordination::_names("$root/$case/references", 129)}), 129,
       'capacity failure removes no reference');
});
with_store(sub {
    my ($case, $snapshot) = @_;
    mkdir("$root/$case/images/" . ('0' x 64), 0700) or die $!;
    my $result = $inspect->($case);
    is_deeply($result->{images}, [], 'unreferenced incomplete image is not falsely admitted');
    my $partial = "$root/$case/images/" . ('0' x 64);
    $incomplete = {case => $case, retained_unreferenced_partial => -d($partial) ? 1 : 0};
    ok($incomplete->{retained_unreferenced_partial}, 'unreferenced partial state is left for owned recovery');
    rejects('direct inspection bypass', sub { NativeProxyReferenceCensus::_inspect_locked($case, {}) }, qr/sealed coordinator/);
    rejects('caller callback rejected', sub { $inspect->($case, sub { die 'callback ran' }) }, qr/expected one/);
});
for my $kind (qw(content filename)) {
    with_store(sub {
        my ($case, $snapshot) = @_;
        my $record = record_for($case, $snapshot, 'Mutant');
        if ($kind eq 'content') {
            $record->{selected_sources}[0]{sha256} = '0' x 64;
            add_reference($case, $record);
            local *NativeProxyReferenceCensus::_matches_image = sub { return };
            my $result = $inspect->($case);
            isnt($result->{references}[0]{record}{selected_sources}[0]{sha256}, sha256_hex($c),
                  'omitted content join admits independently invalid record');
            push @mutants, {kind => $kind, accepted => $result};
        } else {
            add_reference($case, $record, ('0' x 64) . '.json');
            local *NativeProxyReferenceCensus::_filename_key = sub { return };
            my $result = $inspect->($case);
            unlike($result->{references}[0]{source}{identity}{path}, qr/\Q$record->{reference_key}\E\.json\z/,
                   'omitted filename join admits independently invalid alias');
            push @mutants, {kind => $kind, accepted => $result};
        }
    });
}
is($forbidden, 0, 'no compiler or process attempt');
my $success = Test::More->builder->is_passing;
open my $out, '>:raw', "$log/qualification.json" or die "result: $!";
print {$out} $json->pretty->encode({schema => 'fsmgen.inactive_runtime_reference_census_qualification.v1',
    success => $success ? JSON::PP::true : JSON::PP::false, forbidden_process_attempts => $forbidden,
    positive => $positive, capacity => $capacity, incomplete => $incomplete,
    mutants => \@mutants, controls => \@controls, retired_cases => \@retired}) or die $!;
close $out or die $!;
done_testing;
