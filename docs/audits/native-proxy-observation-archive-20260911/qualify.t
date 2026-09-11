#!/usr/bin/env perl
use strict;
use warnings;
our $forbidden = 0;
BEGIN {
    *CORE::GLOBAL::fork = sub { ++$forbidden; die 'forbidden fork'; };
    *CORE::GLOBAL::system = sub { ++$forbidden; die 'forbidden system'; };
}
use FindBin;
use lib "$FindBin::Bin/../../../perl", "$FindBin::Bin/../../../t/lib", $FindBin::Bin,
    map { "$FindBin::Bin/../$_" } qw(native-proxy-image-custody-20260910
        native-proxy-image-coordination-20260910 native-proxy-image-publication-20260910
        native-proxy-runtime-records-20260910 native-proxy-runtime-census-20260910
        native-proxy-runtime-acquisition-20260910 native-proxy-runtime-retirement-20260910
        native-proxy-cleanup-receipts-20260910 native-proxy-observation-records-20260910
        native-proxy-observation-acquisition-20260910 native-proxy-observation-reuse-20260910
        native-proxy-observation-archive-records-20260911);
use Digest::SHA qw(sha256_hex);
use Fcntl qw(S_ISDIR S_ISREG S_ISLNK F_GETFD FD_CLOEXEC);
use File::Spec;
use File::Temp ();
use JSON::PP ();
use Test::More;
use FSM::ProjectDataLocality qw(ensure_project_artifact_dir repository_root);
use FSM::Test::RustProxyFixture ();
BEGIN { *CORE::GLOBAL::exec = sub { ++$forbidden; die 'forbidden exec'; }; }
use ReferenceAcquisition;
use RuntimeRetirement;
use ObservationAcquisition;
use ObservationArchive;
use FixtureClone;

my $ROOT = repository_root();
my $JSON = JSON::PP->new->canonical->ascii;
my $log = ensure_project_artifact_dir(qw(logs native-proxy-observation-archive-20260911));
my $parents = {
    store => ensure_project_artifact_dir(qw(tmp native-proxy-image-custody cases)),
    workspace => ensure_project_artifact_dir(qw(tmp process-supervisor-tests)),
    evidence => ensure_project_artifact_dir(qw(logs native-proxy-observation-acquisition-20260910 cases)),
};
$parents->{other_workspace} = $parents->{workspace};
my $plan = $JSON->decode(read_bytes("$FindBin::Bin/plan.json"));
my $vector = $JSON->decode(read_bytes("$FindBin::Bin/../native-proxy-image-custody-20260910/vectors.json"));
my ($C, $IMAGE) = map { pack('H*', $_) } @$vector{qw(generated_c_hex image_hex)};
my $WRAPPER = "#!/usr/bin/perl\n# inert observation wrapper; never executed\n";
my $result = {schema => 'fsmgen.inactive_observation_archive_qualification.v1',
    success => JSON::PP::false, cases => [], allocated => []};
write_bytes("$log/admission.jsonl", '', 0600);
my $reader = \&NativeProxyImageCustody::_source;
my $lower_reader = \&FSM::Test::RustProxyFixture::_read_file;
my $writer = \&NativeProxyImagePublication::_write_payload;
my $directory = \&NativeProxyImageCustody::_directory;
no warnings 'redefine';
local *FSM::Test::RustProxyFixture::supervise_process = sub { ++$forbidden; die 'forbidden process'; };

sub clone { return NativeProxyObservationFixtureClone::clone($_[0]); }
sub read_bytes {
    open my $fh, '<:raw', $_[0] or die "fixture read: $!";
    my $raw = do { local $/; <$fh> }; close $fh or die "fixture read close: $!"; return $raw;
}
sub write_bytes {
    my ($path, $raw, $mode) = @_;
    chmod(0600, $path) == 1 or die $! if -e $path;
    open my $fh, '>:raw', $path or die "fixture write: $!";
    print {$fh} $raw or die "fixture write bytes: $!"; close $fh or die "fixture write close: $!";
    chmod($mode, $path) == 1 or die "fixture mode: $!";
}
sub save_result {
    $result->{forbidden_process_attempts} = $forbidden;
    write_bytes("$log/qualification.json", JSON::PP->new->canonical->ascii->pretty->encode($result), 0600);
}
sub allocate {
    my ($kind, $path) = @_;
    my @s = lstat("$path"); die 'allocation stat' unless @s;
    my $row = {kind => $kind, path => File::Spec->abs2rel("$path", $ROOT), device => $s[0], inode => $s[1]};
    open my $fh, '>>:raw', "$log/admission.jsonl" or die $!;
    print {$fh} $JSON->encode($row), "\n" or die $!; close $fh or die $!;
    push @{$result->{allocated}}, $row; save_result();
    return {map { $_ => $row->{$_} } qw(path device inode)};
}
sub tree {
    my ($base) = @_;
    return {} unless -e "$ROOT/$base" || -l "$ROOT/$base";
    my (%nodes, $walk);
    $walk = sub {
        my ($path, $relative) = @_;
        my @s = lstat("$ROOT/$path");
        die 'physical census bound/type' unless @s && $s[0] == (stat($ROOT))[0] && keys(%nodes) < 512;
        my $row = {device => $s[0], inode => $s[1], mode => $s[2] & 07777, uid => $s[4]};
        $nodes{$relative} = $row;
        if (S_ISDIR($s[2])) {
            $row->{kind} = 'directory';
            opendir my $fh, "$ROOT/$path" or die $!;
            my @names;
            my $ok = eval {
                while (1) {
                    $! = 0;
                    my $name = readdir($fh);
                    if (!defined($name)) { die "physical directory read: $!" if $!; last; }
                    next if $name eq '.' || $name eq '..';
                    push @names, $name;
                    die 'physical directory capacity' if @names > 512;
                }
                1;
            };
            my $error = $@;
            my $closed = closedir($fh);
            die $error unless $ok;
            die "physical directory close: $!" unless $closed;
            @names = sort @names;
            $walk->("$path/$_", length($relative) ? "$relative/$_" : $_) for @names;
        } elsif (S_ISREG($s[2])) {
            die 'physical source ceiling' if $s[7] > 65536;
            my $raw = read_bytes("$ROOT/$path");
            $row->{kind} = 'file'; $row->{bytes_hex} = unpack('H*', $raw);
            $row->{size_bytes} = length($raw); $row->{sha256} = sha256_hex($raw); $row->{links} = $s[3];
        } elsif (S_ISLNK($s[2])) { $row->{kind} = 'symlink'; $row->{target} = readlink("$ROOT/$path"); }
        else { die 'unexpected special fixture object'; }
    };
    $walk->($base, ''); return \%nodes;
}
sub footprint {
    my ($context) = @_;
    return {map { $_ => tree($context->{$_}{path}) } qw(store workspace other_workspace evidence)};
}
sub cleanup_receipts {
    my $owner = sub { return {cleanup => {leader_started => 1, leader_reaped => 1, group_gone => 1}} };
    return {compiler => $owner->(), outer => $owner->(), stages => [$owner->(), $owner->()]};
}
sub context {
    my ($selection, $callback) = @_;
    my (@temporary, $context);
    $context = {};
    for my $kind (qw(store workspace other_workspace evidence)) {
        my $temp = File::Temp->newdir('fsmgen-XXXXXXXX', DIR => $parents->{$kind}, CLEANUP => 1);
        push @temporary, $temp; $context->{$kind} = allocate($kind, $temp);
    }
    my $case = $context->{store}{path};
    for my $kind (qw(workspace other_workspace)) {
        my $work = "$ROOT/$context->{$kind}{path}";
        mkdir("$work/rust-tools", 0700) or die $!;
        write_bytes("$work/rust-tool-resolution", $WRAPPER, 0700);
        my $runtime = NativeProxyReferenceAcquisition::acquire_runtime_reference(
            $case, $context->{$kind}, $C, $IMAGE.($kind eq 'workspace' ? '' : 'other'));
        $context->{$kind eq 'workspace' ? 'runtime' : 'other_runtime'} = $runtime;
    }
    my $wrapper = $selection->{wrapper};
    if ($wrapper ne 'ordinary') {
        my $raw = $wrapper eq 'binary' ? pack('C*', 0..255)
            : $wrapper eq 'empty' ? '' : $wrapper eq 'maximum' ? 'W' x 65536
            : $wrapper eq 'equal_reference' ? $context->{runtime}{reference}{private}{bytes}
            : die 'unknown wrapper profile';
        write_bytes("$ROOT/$context->{workspace}{path}/rust-tool-resolution", $raw, 0700);
    }
    $context->{request} = {workspace_identity => clone($context->{workspace}),
        evidence_directory_identity => clone($context->{evidence}),
        observer_birth => {pid => 101, ppid => 100, uid => 501, ruid => 501, start_sec => 123, start_usec => 456},
        target_birth => {pid => 201, ppid => 200, uid => 501, ruid => 501, start_sec => 124, start_usec => 789}};
    $context->{acquired} = NativeProxyObservationAcquisition::acquire_observation_reference($case, $context->{request});
    my $other = clone($context->{request}); $other->{target_birth}{pid}++;
    $context->{other_observation} = NativeProxyObservationAcquisition::acquire_observation_reference($case, $other);
    $callback->($context);
    @temporary = ();
    for my $kind (qw(store workspace other_workspace evidence)) {
        die 'owned inert fixture residue' if -e "$ROOT/$context->{$kind}{path}" || -l "$ROOT/$context->{$kind}{path}";
    }
    save_result();
}

sub evaluate {
    my ($context, $request, $change) = @_;
    my $path = "$ROOT/$context->{evidence}{path}/retained-sources";
    my (@held, @reads, @writes, @directories);
    my $row = {before => footprint($context)};
    my $ok = eval {
        local *FSM::Test::RustProxyFixture::_read_file = sub {
            push @reads, File::Spec->abs2rel($_[0], $ROOT);
            die "original target lookup attempted\n" unless index($_[0], "$path/") == 0;
            return $lower_reader->(@_);
        };
        local *NativeProxyImageCustody::_source = sub {
            my $source = $reader->(@_); my $flags = fcntl($source->{handle}, F_GETFD, 0);
            push @held, {handle => $source->{handle}, path => File::Spec->abs2rel($source->{path}, $ROOT),
                descriptor => fileno($source->{handle}), cloexec => defined($flags) && ($flags & FD_CLOEXEC) ? 1 : 0};
            return $source;
        };
        local *NativeProxyImagePublication::_write_payload = sub {
            push @writes, File::Spec->abs2rel($_[0], $ROOT);
            die "foreign archive write attempted\n" unless index($_[0], "$path/") == 0;
            return $writer->(@_);
        };
        local *NativeProxyImageCustody::_directory = sub {
            push @directories, File::Spec->abs2rel($_[0], $ROOT);
            die "original target directory attempted\n" unless $_[0] eq $path || $_[0] eq "$ROOT/$context->{evidence}{path}";
            return $directory->(@_);
        };
        my @args = ($context->{store}{path}, $request, $context->{acquired});
        pop @args if ($change // '') eq 'missing_argument';
        push @args, 'extra' if ($change // '') eq 'extra_argument';
        $row->{result} = NativeProxyObservationArchive::archive_retained_sources(@args);
        1;
    };
    my $error = $@; $error =~ s/\Q$ROOT\E/./g;
    $row->{returned} = $ok && defined($row->{result}) ? 1 : 0; $row->{error} = $error;
    $row->{reads} = \@reads; $row->{writes} = \@writes; $row->{directories} = \@directories;
    $row->{descriptors} = [map { +{
        path => $_->{path}, descriptor => $_->{descriptor}, cloexec => $_->{cloexec},
        closed => defined(fileno($_->{handle})) ? 0 : 1} } @held];
    $row->{after} = footprint($context);
    # Keep actual GLOB aliases alive until after the explicit-close assertion.
    ok(!grep({ !$_->{closed} || !$_->{cloexec} } @{$row->{descriptors}}), 'all returned archive source handles close')
        or do { $result->{first_failure} = $row; save_result(); BAIL_OUT('archive source custody failed'); };
    return $row;
}

save_result();
for my $selection (@{$plan->{cases}}) {
    context($selection, sub {
        my ($context) = @_;
        my $row = {name => $selection->{name}, context => clone($context), prior_retirement => footprint($context)};
        if ($selection->{retired}) {
            $row->{retirement} = NativeProxyRuntimeRetirement::retire_runtime_reference(
                $context->{store}{path}, $context->{runtime}, cleanup_receipts());
        }
        $row->{after_retirement} = footprint($context);
        my $request = clone($context->{request});
        my $spec = NativeProxyObservationArchiveRecord::archive_specification(
            $context->{store}{path}, $request, $context->{acquired});
        my $path = "$ROOT/$spec->{archive_directory}";
        my $prepare = $selection->{prepare};
        if ($prepare eq 'complete') {
            $row->{preparation} = evaluate($context, $request);
            die 'complete preparation failed' unless $row->{preparation}{returned};
        } elsif ($prepare eq 'file') { write_bytes($path, 'not a directory', 0400); }
        elsif ($prepare eq 'symlink') {
            mkdir("$ROOT/$context->{evidence}{path}/unrelated", 0700) or die $!;
            symlink('unrelated', $path) or die $!;
        } elsif ($prepare ne 'absent') {
            mkdir($path, 0700) or die $!;
            if ($prepare eq 'partial') { write_bytes("$ROOT/$spec->{files}[0]{path}", $spec->{files}[0]{bytes}, 0400); }
            elsif ($prepare eq 'unknown') { write_bytes("$path/unknown", 'unknown', 0400); }
            elsif ($prepare ne 'empty') { die 'unknown preparation'; }
        }
        my $change = $selection->{change} // '';
        my $first = "$ROOT/$spec->{files}[0]{path}";
        if ($change eq 'changed_bytes') { write_bytes($first, 'changed retained source', 0400); }
        elsif ($change eq 'changed_mode') { chmod(0600, $first) == 1 or die $!; }
        elsif ($change eq 'hardlink') { link($first, "$ROOT/$context->{evidence}{path}/unrelated-alias") or die $!; }
        elsif ($change eq 'missing_file') { unlink($first) or die $!; }
        elsif ($change eq 'extra_file') { write_bytes("$path/unrelated", 'unrelated', 0400); }
        elsif ($change eq 'wrong_directory_mode') { chmod(0755, $path) == 1 or die $!; }
        elsif ($change eq 'wrong_evidence_permissions') { chmod(0755, "$ROOT/$context->{evidence}{path}") == 1 or die $!; }
        elsif ($change eq 'foreign_evidence_identity') { $request->{evidence_directory_identity}{inode}++; }
        elsif ($change ne '' && $change ne 'missing_argument' && $change ne 'extra_argument') { die 'unknown planned change'; }
        $row->{request} = clone($request); $row->{input_before} = clone($context->{acquired});
        $row->{operation} = evaluate($context, $request, $change);
        $row->{input_after} = clone($context->{acquired}); $row->{request_after} = clone($request);
        my $operation = $row->{operation};
        $row->{diagnostic_matched} = $selection->{returned} ? $operation->{error} eq '' ? 1 : 0
            : index($operation->{error}, $selection->{diagnostic}) >= 0 ? 1 : 0;
        push @{$result->{cases}}, $row; save_result();
        ok($operation->{returned} == $selection->{returned} && $row->{diagnostic_matched}, $row->{name})
            or do { diag($operation->{error} || 'unexpected result'); BAIL_OUT('archive outcome mismatch'); };
        for my $key (qw(store workspace other_workspace)) {
            is($JSON->encode($operation->{after}{$key}), $JSON->encode($operation->{before}{$key}), "$row->{name}: preserve $key");
        }
        if (!$selection->{returned}) {
            is($JSON->encode($operation->{after}{evidence}), $JSON->encode($operation->{before}{evidence}), "$row->{name}: preserve rejected archive");
        }
    });
}
is($forbidden, 0, 'no compiler or native process attempt');
$result->{success} = Test::More->builder->is_passing ? JSON::PP::true : JSON::PP::false;
save_result(); done_testing;
