package NativeProxyArchiveFixture;

use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use Fcntl qw(S_ISDIR S_ISREG S_ISLNK);
use File::Spec;
use File::Temp ();
use JSON::PP ();
use FSM::ProjectDataLocality qw(ensure_project_artifact_dir repository_root);
use ReferenceAcquisition;
use RuntimeRetirement;
use ObservationAcquisition;
use FixtureClone;

# Inactive qualification support. The preserved helper bodies come from the
# completed filesystem archive suite; extraction.json binds their exact source.
my $ROOT = repository_root();
my $JSON = JSON::PP->new->canonical->ascii;
my ($log, $parents, $result, $process_counter, $C, $IMAGE);
my $WRAPPER = "#!/usr/bin/perl\n# inert observation wrapper; never executed\n";

sub initialize {
    die "expected component, result map and process-counter reference\n" unless @_ == 3;
    my ($component, $report, $counter) = @_;
    die "fixture support already initialized\n" if defined($result);
    die "invalid task-local archive component\n" unless defined($component) && !ref($component)
        && $component =~ /\Anative-proxy-observation-archive-[a-z0-9-]+\z/;
    die "invalid fixture result or process counter\n" unless ref($report) eq 'HASH' && ref($counter) eq 'SCALAR';
    ($result, $process_counter) = ($report, $counter);
    $log = ensure_project_artifact_dir('logs', $component);
    $parents = {
        store => ensure_project_artifact_dir(qw(tmp native-proxy-image-custody cases)),
        workspace => ensure_project_artifact_dir(qw(tmp process-supervisor-tests)),
        evidence => ensure_project_artifact_dir(qw(logs native-proxy-observation-acquisition-20260910 cases)),
    };
    $parents->{other_workspace} = $parents->{workspace};
    my $vector = $JSON->decode(read_bytes("$ROOT/docs/audits/native-proxy-image-custody-20260910/vectors.json"));
    ($C, $IMAGE) = map { pack('H*', $_) } @$vector{qw(generated_c_hex image_hex)};
    write_bytes("$log/admission.jsonl", '', 0600);
    save_result();
    return $log;
}

sub save_result {
    $result->{forbidden_process_attempts} = $$process_counter;
    write_bytes("$log/qualification.json", JSON::PP->new->canonical->ascii->pretty->encode($result), 0600);
}

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

1;
