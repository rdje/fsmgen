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
    "$FindBin::Bin/../native-proxy-runtime-records-20260910",
    "$FindBin::Bin/../native-proxy-runtime-census-20260910", $FindBin::Bin;
use Digest::SHA qw(sha256_hex);
use File::Spec;
use File::Temp ();
use JSON::PP ();
use Test::More;
use FSM::ProjectDataLocality qw(ensure_project_artifact_dir repository_root);
use FSM::Test::RustProxyFixture ();
BEGIN { *CORE::GLOBAL::exec = sub { ++$forbidden; die 'forbidden exec'; }; }
use ReferenceAcquisition;

my $root = repository_root();
my $json = JSON::PP->new->canonical->ascii;
my $parent = ensure_project_artifact_dir(qw(tmp native-proxy-image-custody cases));
my $work_parent = ensure_project_artifact_dir(qw(tmp process-supervisor-tests));
my $log = ensure_project_artifact_dir(qw(logs native-proxy-runtime-acquisition-20260910));
my $v = $json->decode(read_bytes("$FindBin::Bin/../native-proxy-image-custody-20260910/vectors.json"));
my ($c, $image) = map { pack('H*', $_) } @$v{qw(generated_c_hex image_hex)};
my $acquire = \&NativeProxyReferenceAcquisition::acquire_runtime_reference;
my $writer = \&NativeProxyReferenceAcquisition::_write_reference;
my $finish = \&NativeProxyReferenceAcquisition::_finish_locked;
my (@controls, @retired_cases, @retired_workspaces, @interruptions, @mutants, @allocated,
    $first, $reuse, $different, $capacity);
open my $admission, '>:raw', "$log/admission.jsonl" or die "admission log: $!";
close $admission or die "close admission log: $!";
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
sub allocated {
    my ($kind, $path) = @_;
    my @metadata = lstat("$root/$path");
    my $row = {kind => $kind, path => $path, device => $metadata[0], inode => $metadata[1]};
    open my $fh, '>>:raw', "$log/admission.jsonl" or die "append admission: $!";
    print {$fh} $json->encode($row), "\n" or die "write admission: $!";
    close $fh or die "close admission: $!";
    push @allocated, $row;
}
sub with_context {
    my ($callback) = @_;
    my $store = File::Temp->newdir('fsmgen-XXXXXXXX', DIR => $parent, CLEANUP => 1);
    my $case = File::Spec->abs2rel("$store", $root);
    allocated('store', $case);
    NativeProxyImageCoordination::inspect_store($case);
    my (@work, @identities);
    for (1, 2) {
        my $workspace = File::Temp->newdir('fsmgen-XXXXXXXX', DIR => $work_parent, CLEANUP => 1);
        allocated('workspace', File::Spec->abs2rel("$workspace", $root));
        mkdir("$workspace/rust-tools", 0700) or die $!;
        my @metadata = stat("$workspace");
        push @identities, {path => File::Spec->abs2rel("$workspace", $root), device => $metadata[0], inode => $metadata[1]};
        push @work, $workspace;
    }
    $callback->($case, \@identities);
    @work = ();
    for my $identity (@identities) {
        die 'owned inert workspace remains' if -e "$root/$identity->{path}" || -l "$root/$identity->{path}";
        push @retired_workspaces, $identity->{path};
    }
    undef $store;
    die 'owned inert store remains' if -e "$root/$case" || -l "$root/$case";
    push @retired_cases, $case;
}
sub paths {
    my ($case, $workspace) = @_;
    my $key = NativeProxyImageCustody::runtime_reference_key($workspace->{path});
    return ("$root/$case/references/$key.json", "$root/$workspace->{path}/rust-tools/image-reference.json");
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
sub image_count { return scalar(@{NativeProxyImageCoordination::_names("$root/$_[0]/images", 32)}); }
sub replace_workspace {
    my ($workspace) = @_;
    my $path = "$root/$workspace->{path}";
    rename($path, "${path}_old") or die $!;
    mkdir($path, 0700) or die $!;
    rename("${path}_old/rust-tools", "$path/rust-tools") or die $!;
    rmdir("${path}_old") or die $!;
    my @metadata = stat($path);
    return {path => $workspace->{path}, device => $metadata[0], inode => $metadata[1]};
}

with_context(sub {
    my ($case, $work) = @_;
    my @order;
    {
        local *NativeProxyReferenceAcquisition::_write_reference = sub {
            push @order, $_[0];
            return $writer->(@_);
        };
        $first = $acquire->($case, $work->[0], $c, $image);
    }
    is_deeply(\@order, [map { File::Spec->abs2rel($_, $root) } paths($case, $work->[0])],
              'global reference is written before private receipt');
    $reuse = $acquire->($case, $work->[1], $c, $image);
    is($first->{created}, 1, 'first acquisition publishes image');
    is($reuse->{created}, 0, 'second owner reuses exact image');
    is_deeply($first->{image}, $reuse->{image}, 'equal image retains exact bytes and inodes');
    isnt($first->{reference}{record}{reference_key}, $reuse->{reference}{record}{reference_key},
          'separate workspaces retain distinct complete references');
    for my $result ($first, $reuse) {
        is($result->{runtime_authorized}, 0, 'inactive acquisition grants no runtime authority');
        ok(!defined($result->{executable}), 'inactive acquisition returns no runnable executable');
        is($result->{reference}{global}{bytes}, $result->{reference}{private}{bytes}, 'both reference copies agree');
    }
    rejects('duplicate global ownership', sub { $acquire->($case, $work->[0], $c, $image) }, qr/already exists/);
    is(scalar(@{NativeProxyImageCoordination::_names("$root/$case/references", 128)}), 2,
       'duplicate rejection preserves both owners');
});
with_context(sub {
    my ($case, $work) = @_;
    my $a = $acquire->($case, $work->[0], $c, $image);
    my $b = $acquire->($case, $work->[1], $c, $image . 'different');
    isnt($a->{image}{key}, $b->{image}{key}, 'different output creates a distinct image');
    is(image_count($case), 2, 'different output preserves both images');
    $different = {first => $a, second => $b};
});
for my $kind (qw(stale_inode wrong_device extra_field numeric_inode boolean_inode wrong_path missing_tools private_exists private_symlink malformed_global)) {
    with_context(sub {
        my ($case, $work) = @_;
        my $expected = clone($work->[0]);
        my ($global, $private) = paths($case, $work->[0]);
        if ($kind eq 'stale_inode') { $expected->{inode}++; }
        if ($kind eq 'wrong_device') { $expected->{device}++; }
        if ($kind eq 'extra_field') { $expected->{extra} = 0; }
        if ($kind eq 'numeric_inode') { $expected->{inode} = sprintf('%d', $expected->{inode}); }
        if ($kind eq 'boolean_inode') { $expected->{inode} = JSON::PP::true; }
        if ($kind eq 'wrong_path') { $expected->{path} .= '/..'; }
        if ($kind eq 'missing_tools') { rmdir("$root/$expected->{path}/rust-tools") or die $!; }
        if ($kind eq 'private_exists') { write_bytes($private, 'unfinished', 0400); }
        if ($kind eq 'private_symlink') { symlink('missing', $private) or die $!; }
        if ($kind eq 'malformed_global') { write_bytes($global, '{', 0400); }
        my %reason = (stale_inode => qr/prior workspace identity/, wrong_device => qr/prior workspace identity/,
            extra_field => qr/closed record/, numeric_inode => qr/JSON integer/, boolean_inode => qr/JSON integer/,
            wrong_path => qr/private workspace/, missing_tools => qr/(?:does not exist|missing|private same-volume directory)/,
            private_exists => qr/already exists/, private_symlink => qr/already exists/, malformed_global => qr/invalid runtime JSON/);
        rejects("admission $kind", sub { $acquire->($case, $expected, $c, $image) }, $reason{$kind});
        is(image_count($case), 0, "$kind fails before image publication");
    });
}
for my $boundary (qw(before_global after_global before_private after_private)) {
    with_context(sub {
        my ($case, $work) = @_;
        my ($global, $private) = paths($case, $work->[0]);
        local *NativeProxyReferenceAcquisition::_write_reference = sub {
            my $which = $_[0] =~ /\/references\// ? 'global' : 'private';
            die "injected before $which\n" if $boundary eq "before_$which";
            my $result = $writer->(@_);
            die "injected after $which\n" if $boundary eq "after_$which";
            return $result;
        };
        rejects("interruption $boundary", sub { $acquire->($case, $work->[0], $c, $image) }, qr/injected/);
        my $state = {boundary => $boundary, case => $case, workspace => $work->[0]{path},
                     global_present => -f($global) ? 1 : 0, private_present => -f($private) ? 1 : 0};
        is($state->{global_present}, $boundary eq 'before_global' ? 0 : 1, "$boundary preserves global state");
        is($state->{private_present}, $boundary eq 'after_private' ? 1 : 0, "$boundary preserves private state");
        $state->{global_bytes} = read_bytes($global) if $state->{global_present};
        $state->{private_bytes} = read_bytes($private) if $state->{private_present};
        push @interruptions, $state;
    });
}
for my $kind (qw(global_inode private_inode private_bytes workspace_root tools_directory prior_record prior_image)) {
    with_context(sub {
        my ($case, $work) = @_;
        my $prior = $acquire->($case, $work->[1], $c, $image);
        my ($global, $private) = paths($case, $work->[0]);
        local *NativeProxyReferenceAcquisition::_write_reference = sub {
            my $result = $writer->(@_);
            if ("$root/$_[0]" eq $private && $kind eq 'prior_record') {
                my $path = "$root/$prior->{reference}{global}{identity}{path}";
                my $record = $json->decode(read_bytes($path)); $record->{workspace_identity}{inode}++;
                write_bytes($path, $json->encode($record), 0400);
            } elsif ("$root/$_[0]" eq $private && $kind eq 'prior_image') {
                my $path = "$root/$prior->{image}{snapshots}[1]{identity}{path}";
                unlink($path) or die $!; write_bytes($path, $image, 0500);
            }
            return $result;
        };
        local *NativeProxyReferenceAcquisition::_finish_locked = sub {
            if ($kind eq 'global_inode' || $kind eq 'private_inode') {
                my $path = $kind eq 'global_inode' ? $global : $private;
                my $bytes = read_bytes($path); unlink($path) or die $!; write_bytes($path, $bytes, 0400);
            } elsif ($kind eq 'private_bytes') {
                my $record = $json->decode(read_bytes($private)); $record->{workspace_identity}{inode}++;
                write_bytes($private, $json->encode($record), 0400);
            } elsif ($kind eq 'workspace_root') {
                replace_workspace($work->[0]);
            } elsif ($kind eq 'tools_directory') {
                my $bin = "$root/$work->[0]{path}/rust-tools";
                rename($bin, "${bin}_old") or die $!; mkdir($bin, 0700) or die $!;
                rename("${bin}_old/image-reference.json", "$bin/image-reference.json") or die $!;
                rmdir("${bin}_old") or die $!;
            }
            goto &$finish;
        };
        my $reason = $kind eq 'prior_record' ? qr/prior runtime reference changed/
            : $kind eq 'prior_image' ? qr/retained image changed/ : qr/(?:changed|differs)/;
        rejects("closure $kind", sub { $acquire->($case, $work->[0], $c, $image) }, $reason);
        ok(-f($global), "$kind retains its global reference");
    });
}

with_context(sub {
    my ($case, $work) = @_;
    my $initial = $acquire->($case, $work->[1], $c, $image);
    my @keys = ($initial->{reference}{record}{reference_key});
    for my $index (0..126) {
        my $record = clone($initial->{reference}{record});
        my $workspace = '.artifacts/tmp/process-supervisor-tests/fsmgen-AcquisitionCapacity' . $index;
        die 'synthetic capacity workspace exists' if -e "$root/$workspace" || -l "$root/$workspace";
        $record->{workspace} = $workspace;
        $record->{workspace_identity} = {path => $workspace, device => 17, inode => 99};
        $record->{reference_key} = NativeProxyImageCustody::runtime_reference_key($workspace);
        my $bytes = NativeProxyRuntimeRecord::encode_runtime_record($case, $record);
        write_bytes("$root/$case/references/$record->{reference_key}.json", $bytes, 0400);
        push @keys, $record->{reference_key};
    }
    rejects('reference capacity before new publication',
        sub { $acquire->($case, $work->[0], $c, $image . 'unpublished') }, qr/runtime reference capacity/);
    is(image_count($case), 1, 'reference capacity rejects before another image is published');
    my @actual = map { s/\.json\z//r } @{NativeProxyImageCoordination::_names("$root/$case/references", 128)};
    is_deeply(\@actual, [sort @keys], 'capacity leaves the complete original reference set');
    $capacity = {case => $case, original_workspace => $work->[1]{path}, keys => \@actual};
});
with_context(sub {
    my ($case, $work) = @_;
    NativeProxyImagePublication::publish_image($case, $c, $image);
    mkdir("$root/$case/images/" . sprintf('%064x', $_), 0700) or die $! for 1..31;
    my $result = $acquire->($case, $work->[0], $c, $image);
    is($result->{created}, 0, 'existing image acquires a reference at the image ceiling');
    rejects('new image capacity', sub { $acquire->($case, $work->[1], $c, $image . 'other') }, qr/image publication capacity/);
    my ($global, $private) = paths($case, $work->[1]);
    ok(!-e($global) && !-e($private), 'image capacity creates no new reference copy');
    is(image_count($case), 32, 'image capacity retains every complete or partial entry');
});
with_context(sub {
    my ($case, $work) = @_;
    $acquire->($case, $work->[0], $c, $image);
    my ($global, $private) = paths($case, $work->[0]);
    my $before = read_bytes($global);
    unlink($private) or die $!;
    rejects('global without private is not reacquired', sub { $acquire->($case, $work->[0], $c, $image) }, qr/already exists/);
    is(read_bytes($global), $before, 'incomplete owner remains pinned');
    ok(!-e($private), 'incomplete private copy is not silently repaired');
    rejects('extra positional option', sub { $acquire->($case, $work->[1], $c, $image, sub { die 'callback ran' }) }, qr/expected isolated store/);
    rejects('oversized image input', sub { $acquire->($case, $work->[1], $c, 'x' x 65537) }, qr/bounded bytes/);
    rejects('direct admission bypass', sub { NativeProxyReferenceAcquisition::_admit_locked($case, {}, $work->[1]) }, qr/sealed coordinator/);
    rejects('direct acquisition bypass', sub { NativeProxyReferenceAcquisition::_acquire_locked($case, {}, {}) }, qr/sealed coordinator/);
    rejects('direct closure bypass', sub { NativeProxyReferenceAcquisition::_finish_locked($case) }, qr/sealed coordinator/);
});
with_context(sub {
    my ($case, $work) = @_;
    my $current;
    local *NativeProxyReferenceAcquisition::_workspace_closure = sub { return };
    local *NativeProxyReferenceAcquisition::_finish_locked = sub {
        $current = replace_workspace($work->[0]);
        goto &$finish;
    };
    my $result = $acquire->($case, $work->[0], $c, $image);
    isnt($result->{reference}{record}{workspace_identity}{inode}, $current->{inode},
          'omitted workspace closure admits independently stale directory identity');
    push @mutants, {kind => 'workspace_closure', accepted => $result, current_workspace => $current};
});
with_context(sub {
    my ($case, $work) = @_;
    my $reader = \&NativeProxyReferenceAcquisition::_read_reference;
    my $original;
    my (undef, $private) = paths($case, $work->[0]);
    local *NativeProxyReferenceAcquisition::_write_reference = sub {
        my $sealed = $writer->(@_);
        if ("$root/$_[0]" eq $private) { $original = {device => $sealed->[0], inode => $sealed->[1]}; }
        return $sealed;
    };
    local *NativeProxyReferenceAcquisition::_read_reference = sub {
        my ($case, $path, $bytes) = @_;
        # Counterimplementation replaces the original-writer identity with the
        # latest pathname identity, discarding the creation-to-return join.
        my @now = lstat("$root/$path");
        return $reader->($case, $path, $bytes, \@now);
    };
    local *NativeProxyReferenceAcquisition::_finish_locked = sub {
        my $bytes = read_bytes($private); unlink($private) or die $!; write_bytes($private, $bytes, 0400);
        goto &$finish;
    };
    my $result = $acquire->($case, $work->[0], $c, $image);
    isnt($result->{reference}{private}{identity}{inode}, $original->{inode},
          'omitted sealed-inode join admits independently replaced private receipt');
    push @mutants, {kind => 'sealed_identity', accepted => $result, original_private_identity => $original};
});
is($forbidden, 0, 'no compiler or process attempt');
my $success = Test::More->builder->is_passing;
open my $out, '>:raw', "$log/qualification.json" or die "result: $!";
print {$out} $json->pretty->encode({schema => 'fsmgen.inactive_runtime_reference_acquisition_qualification.v1',
    success => $success ? JSON::PP::true : JSON::PP::false, forbidden_process_attempts => $forbidden,
    first => $first, reuse => $reuse, different => $different, capacity => $capacity,
    interruptions => \@interruptions, mutants => \@mutants, controls => \@controls,
    allocated => \@allocated,
    retired_cases => \@retired_cases, retired_workspaces => \@retired_workspaces}) or die $!;
close $out or die $!;
done_testing;
