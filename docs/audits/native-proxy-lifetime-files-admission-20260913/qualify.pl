#!/usr/bin/env perl
package NativeProxyLifetimeQualification;
use strict;
use warnings;
our $FORBIDDEN = 0;
BEGIN {
    *CORE::GLOBAL::fork = sub { ++$FORBIDDEN; die "forbidden child process\n"; };
    *CORE::GLOBAL::system = sub { ++$FORBIDDEN; die "forbidden system command\n"; };
}
use FindBin;
use lib $FindBin::Bin, "$FindBin::Bin/../../../perl", "$FindBin::Bin/../../../t/lib",
    map { "$FindBin::Bin/../$_" } qw(native-proxy-image-custody-20260910
        native-proxy-image-coordination-20260910 native-proxy-image-publication-20260910
        native-proxy-runtime-records-20260910 native-proxy-runtime-census-20260910
        native-proxy-runtime-acquisition-20260910 native-proxy-runtime-retirement-20260910
        native-proxy-image-maintenance-20260910
        native-proxy-cleanup-receipts-20260910 native-proxy-observation-records-20260910
        native-proxy-observation-acquisition-20260910 native-proxy-observation-reuse-20260910
        native-proxy-observation-archive-records-20260911 native-proxy-observation-archive-20260911
        native-proxy-observation-work-records-20260911 native-proxy-observation-archive-release-20260911);
use LifetimeTrace;
use LifetimeFiles;
use JSON::PP ();
use Digest::SHA qw(sha256_hex);
use Fcntl qw(O_CREAT O_EXCL S_ISDIR S_ISREG);
use Time::HiRes qw(clock_gettime CLOCK_MONOTONIC alarm);
use FSM::ProjectDataLocality qw(ensure_project_artifact_dir repository_root);
use FSM::Test::RustProxyFixture ();
BEGIN { *CORE::GLOBAL::exec = sub { ++$FORBIDDEN; die "forbidden exec\n"; }; }
use Coordination;
use ReferenceAcquisition;
use RuntimeRetirement;
use ImageMaintenance;
use ObservationAcquisition;
use ObservationArchive;
use ObservationRelease;
use WorkRecord;
use FixtureClone;

my $ROOT = repository_root();
my $JSON = JSON::PP->new->canonical->ascii;
my ($PLAN, $SELECTION, $PINS, $JOURNAL, $STARTED, $JOURNAL_FAILED);
my ($SERIAL, $TOTAL_BYTES) = (0, 0);
my %OWNED;

sub read_bytes {
    open my $handle, '<:raw', "$ROOT/$_[0]" or die "input open: $!\n";
    my $bytes = do { local $/; <$handle> };
    close($handle) or die "input close: $!\n";
    return $bytes;
}
sub document { return $JSON->decode(read_bytes($_[0])); }
sub clone { return NativeProxyObservationFixtureClone::clone($_[0]); }
sub retain {
    my ($value) = @_;
    return [map { retain($_) } @$value] if ref($value) eq 'ARRAY';
    return {map { $_ eq 'bytes' ? (bytes_hex => unpack('H*', $value->{$_})) : ($_ => retain($value->{$_})) }
            keys %$value} if ref($value) eq 'HASH';
    return $value;
}
sub same { return $JSON->encode(retain($_[0])) eq $JSON->encode(retain($_[1])); }
sub now_ns { return int(clock_gettime(CLOCK_MONOTONIC) * 1_000_000_000); }

sub authenticate {
    for my $pin (@{$PLAN->{inputs}}, @$PINS) {
        my $bytes = read_bytes($pin->{path});
        die "admitted source changed: $pin->{path}\n"
            unless length($bytes) == $pin->{size_bytes} && sha256_hex($bytes) eq $pin->{sha256};
    }
}

sub journal {
    my ($kind, $value) = @_;
    my $bytes = $JSON->encode(retain({schema => 'fsmgen.inactive_lifetime_files_event.v1', sequence => $SERIAL,
        kind => $kind, monotonic_ns => now_ns(), value => $value})) . "\n";
    my $ok = eval {
        die "journal record or aggregate bound exceeded\n" if length($bytes) > $SELECTION->{bounds}{record_bytes}
            || $TOTAL_BYTES + length($bytes) > $SELECTION->{bounds}{total_record_bytes};
        my $path = sprintf('%s/event-%06d.json', $JOURNAL, $SERIAL);
        NativeProxyLifetimeFiles::write_exclusive($path, $bytes, 0600, $SELECTION->{bounds}{record_bytes});
        $TOTAL_BYTES += length($bytes); ++$SERIAL;
        1;
    };
    unless ($ok) {
        $JOURNAL_FAILED = 1;
        die "first journal failure; preserve fixture roots: $@";
    }
}

sub remember_ownership {
    my ($trace) = @_;
    for my $call (@{$trace->{calls}}) {
        my ($path, $native, $kind);
        if ($call->{operation} eq 'mkdir' && $call->{returned}) {
            ($path, $native, $kind) = ($call->{path}, $call->{native_after}, 'directory');
        } elsif ($call->{operation} eq 'sysopen' && $call->{returned}
                 && ($call->{flags} & O_CREAT) && ($call->{flags} & O_EXCL)) {
            my $handle = $trace->{handles}[$call->{handle}];
            ($path, $native, $kind) = ($call->{path}, $handle->{native_at_open}, 'file');
        } else { next; }
        next unless ref($native) eq 'ARRAY' && @$native == 13;
        my $identity = {path => $path, device => $native->[0], inode => $native->[1], kind => $kind};
        die "created path changes prior owned identity\n" if exists($OWNED{$path}) && !same($OWNED{$path}, $identity);
        $OWNED{$path} = $identity;
    }
}

sub observe {
    my ($context, $operation) = @_;
    my $trace = NativeProxyLifetimeTrace::observe($ROOT, $context->{roots}, $SELECTION->{trace_limits}, $operation);
    my $registered = eval { remember_ownership($trace); 1; };
    $trace->{ownership_registration_error_hex} = $registered ? '' : unpack('H*', $@);
    return $trace;
}

sub complete_trace {
    my ($trace) = @_;
    return 0 unless $trace->{returned} && !length($trace->{error_hex})
        && !length($trace->{ownership_registration_error_hex}) && !@{$trace->{recovery}};
    for my $handle (@{$trace->{handles}}) {
        return 0 unless $handle->{closed_at_return} && $handle->{close}
            && $handle->{close}{returned} && $handle->{close}{closed_after_call};
        return 0 if $handle->{kind} eq 'file' && !$handle->{close}{cloexec_before_close};
    }
    return 0 if grep { !$_->{closed_at_return} } @{$trace->{metadata_observers}};
    return 1;
}

sub probe {
    my ($context) = @_;
    return observe($context, sub { NativeProxyLifetimeFiles::snapshot($context->{roots}) });
}

sub measure {
    my ($context, $name, $operation, $inputs) = @_;
    $inputs //= {};
    my $input_before = clone($inputs);
    my $before = probe($context);
    unless (complete_trace($before)) {
        journal('stage', {case => $context->{name}, name => $name, before => $before, operation => undef, after => undef,
            input_before => $input_before, input_after => $inputs});
        die "independent pre-operation probe failed: $name\n";
    }
    my $started = now_ns();
    my $trace = observe($context, $operation);
    my $ended = now_ns();
    my $after = probe($context);
    journal('stage', {case => $context->{name}, name => $name, before => $before,
        operation => $trace, after => $after, input_before => $input_before, input_after => $inputs,
        started_monotonic_ns => $started, ended_monotonic_ns => $ended});
    die "caller input values changed: $name\n" unless same($input_before, $inputs);
    die "incomplete operation: $name\n" unless complete_trace($trace);
    die "independent post-operation probe failed: $name\n" unless complete_trace($after);
    if (ref($trace->{result}) eq 'HASH' && ($trace->{result}{schema} // '') eq 'fsmgen.inactive_observation_release_attempt.v1') {
        die "release reports failure: $name\n" unless $trace->{result}{success};
    }
    $context->{current} = $after->{result};
    return $trace->{result};
}

sub settled_owner {
    return {outcome => $_[0], cleanup => {leader_started => 1, leader_reaped => 1, group_gone => 1}};
}

sub observation_request {
    my ($context, $name) = @_;
    my $index = $name eq 'a' ? 0 : 1;
    return {workspace_identity => $context->{directories}{target},
        evidence_directory_identity => $context->{directories}{evidence},
        observer_birth => {pid => 101 + $index, ppid => 100, uid => 0 + $<, ruid => 0 + $<,
                           start_sec => 123, start_usec => 456 + $index},
        target_birth => {pid => 201, ppid => 200, uid => 0 + $<, ruid => 0 + $<, start_sec => 124, start_usec => 789}};
}

sub assert_initial {
    die "expected context, payloads and explicit other-image suffix\n" unless @_ == 3;
    my ($context, $payloads, $suffix_hex) = @_;
    my $nodes = NativeProxyLifetimeFiles::stable($context->{current});
    my %expected_paths;
    my $directory = sub {
        my ($path, $identity) = @_;
        $expected_paths{$path} = 1;
        die "initial directory is absent or changed\n" unless exists($nodes->{$path})
            && $nodes->{$path}{kind} eq 'directory' && $nodes->{$path}{mode} == 0700
            && (!defined($identity) || same($identity, $nodes->{$path}{identity}));
    };
    my $file = sub {
        my ($path, $bytes, $mode, $claimed) = @_;
        $expected_paths{$path} = 1;
        die "initial file bytes, mode or identity differ\n" unless exists($nodes->{$path})
            && $nodes->{$path}{kind} eq 'file' && $nodes->{$path}{mode} == $mode
            && $nodes->{$path}{bytes_hex} eq unpack('H*', $bytes)
            && (!defined($claimed) || same($claimed, $nodes->{$path}{identity}));
        return {bytes => $bytes, identity => clone($nodes->{$path}{identity})};
    };
    $directory->($context->{paths}{$_}, $context->{directories}{$_}) for qw(store target other evidence);
    $directory->("$context->{paths}{store}/$_") for qw(images references);
    my $lock = $file->("$context->{paths}{store}/coordination.lock", '', 0600)->{identity};
    $lock = {map { $_ => $lock->{$_} } qw(path device inode)};
    my %sources;
    for my $name (qw(target other)) {
        my $root = $context->{paths}{$name};
        $directory->("$root/rust-tools");
        my $wrapper = $file->("$root/rust-tool-resolution", $payloads->{wrapper}, 0700);
        my $c = $payloads->{c}; my $image = $payloads->{image};
        $image .= pack('H*', $suffix_hex)
            if $name eq 'other' && $context->{profile} eq 'different_image';
        my $key = sha256_hex("fsmgen.rust_proxy_image.v1\0" . pack('NN', 0, length($c)) . $c
                             . pack('NN', 0, length($image)) . $image);
        my $base = "$context->{paths}{store}/images/$key";
        $directory->($base);
        my @pair = ($file->("$base/rustup.c", $c, 0400), $file->("$base/rustup", $image, 0500));
        my $manifest = $JSON->encode({schema => 'fsmgen.test.rust_proxy_image.v1', key => $key,
            generated_c => {size_bytes => length($c), sha256 => sha256_hex($c)},
            executable => {size_bytes => length($image), sha256 => sha256_hex($image)}});
        my $manifest_snapshot = $file->("$base/image.json", $manifest, 0400);
        my $reference_key = sha256_hex("fsmgen.rust_proxy_reference.runtime.v1\0$root");
        my $record = {schema => 'fsmgen.test.rust_proxy_image_reference.v1', reference_key => $reference_key,
            image_key => $key, workspace => $root, workspace_identity => $context->{directories}{$name},
            selected_sources => [map { clone($_->{identity}) } @pair]};
        my $bytes = $JSON->encode($record);
        my $runtime = $context->{runtimes}{$name};
        my $private = $file->("$root/rust-tools/image-reference.json", $bytes, 0400, $runtime->{reference}{private}{identity});
        my $global = $file->("$context->{paths}{store}/references/$reference_key.json", $bytes, 0400, $runtime->{reference}{global}{identity});
        my $expected = {schema => 'fsmgen.inactive_runtime_reference_acquisition.v1', runtime_authorized => 0,
            executable => undef, lock => $lock, created => ($name eq 'target' || $context->{profile} eq 'different_image') ? 1 : 0,
            reference => {record => $record, global => $global, private => $private},
            image => {key => $key, snapshots => [@pair, $manifest_snapshot]}};
        die "runtime acquisition differs from independent initial construction\n" unless same($runtime, $expected);
        $sources{$name} = [$wrapper, $private, $global, @pair];
    }
    for my $name (qw(a b)) {
        my $request = $context->{requests}{$name};
        my $reference_key = sha256_hex("fsmgen.rust_proxy_reference.observation.v1\0" . $JSON->encode(
            [$context->{paths}{evidence}, $request->{observer_birth}, $request->{target_birth}]));
        my $record = {schema => 'fsmgen.test.rust_proxy_image_observation_reference.v1', reference_key => $reference_key,
            image_key => $context->{runtimes}{target}{image}{key}, evidence_directory => $context->{paths}{evidence},
            evidence_directory_identity => $context->{directories}{evidence}, observer_birth => $request->{observer_birth},
            target_birth => $request->{target_birth}, selected_sources => [map { $_->{identity} } @{$sources{target}}[3,4]]};
        my $hold = $file->("$context->{paths}{store}/references/$reference_key.json", $JSON->encode($record), 0400);
        my $expected = {schema => 'fsmgen.inactive_observation_acquisition.v1', runtime_authorized => 0,
            executable => undef, lock => $lock, observation_reference => {record => $record, source => $hold},
            target_sources => $sources{target}};
        die "observation differs from independent initial construction\n" unless same($context->{observations}{$name}, $expected);
    }
    die "initial tree membership differs from the complete declared layout\n"
        unless same([sort keys %$nodes], [sort keys %expected_paths]);
}

sub prepare_case {
    my ($case, $payloads) = @_;
    my $context = {name => $case->{name}, profile => $case->{profile}, paths => $case->{roots},
        roots => [map { $case->{roots}{$_} } qw(store target other evidence)], runtimes => {},
        observations => {}, requests => {}, archives => {}, selections => {}, settlements => {}, completed => {}};
    for my $path (@{$context->{roots}}) {
        die "new fixture root already exists: $path\n" unless NativeProxyLifetimeFiles::absent($path);
    }
    journal('case-intent', {case => $case, synthetic_ownership_only => 1, roots_absent_before_creation => $context->{roots}});
    $context->{directories} = measure($context, 'create_owned_roots', sub {
        return {map { $_ => NativeProxyLifetimeFiles::create_directory($case->{roots}{$_}) } qw(store target other evidence)};
    }, {roots => $case->{roots}});
    measure($context, 'prepare_private_wrappers', sub {
        for my $name (qw(target other)) {
            NativeProxyLifetimeFiles::create_directory("$case->{roots}{$name}/rust-tools");
            NativeProxyLifetimeFiles::write_exclusive("$case->{roots}{$name}/rust-tool-resolution", $payloads->{wrapper}, 0700, 65536);
        }
        return {private_wrappers_only => 1};
    }, {roots => $case->{roots}, wrapper_hex => unpack('H*', $payloads->{wrapper})});
    for my $name (qw(target other)) {
        my $image = $payloads->{image};
        $image .= pack('H*', $SELECTION->{payload_source}{different_image_suffix_hex})
            if $name eq 'other' && $case->{profile} eq 'different_image';
        $context->{runtimes}{$name} = measure($context, "acquire_runtime_$name", sub {
            NativeProxyReferenceAcquisition::acquire_runtime_reference(
                $case->{roots}{store}, $context->{directories}{$name}, $payloads->{c}, $image);
        }, {store => $case->{roots}{store}, workspace => $context->{directories}{$name},
            c_hex => unpack('H*', $payloads->{c}), image_hex => unpack('H*', $image)});
    }
    for my $name (qw(a b)) {
        $context->{requests}{$name} = observation_request($context, $name);
        $context->{observations}{$name} = measure($context, "acquire_observation_$name", sub {
            NativeProxyObservationAcquisition::acquire_observation_reference($case->{roots}{store}, $context->{requests}{$name});
        }, {store => $case->{roots}{store}, request => $context->{requests}{$name}});
        my @base = ($case->{roots}{store}, $context->{requests}{$name}, $context->{observations}{$name});
        my $entries = [map { {work_id => "$name:$_", role => $_,
            ownership_token => sha256_hex("lifetime:$case->{name}:$name:$_")} } qw(capture helper query)];
        my @outcomes = qw(completed failed cancelled);
        my $receipts = [map { {%{$entries->[$_]}, %{settled_owner($outcomes[$_])}} } 0..2];
        $context->{selections}{$name} = NativeProxyObservationWorkRecord::work_selection(@base, $entries);
        $context->{settlements}{$name} = NativeProxyObservationWorkRecord::work_settlement(
            @base, $context->{selections}{$name}, $receipts, 1);
    }
    die "observers differ on strict target snapshots\n" unless same(
        $context->{observations}{a}{target_sources}, $context->{observations}{b}{target_sources});
    assert_initial($context, $payloads, $SELECTION->{payload_source}{different_image_suffix_hex});
    $context->{initial} = clone($context->{current});
    journal('case-initial', $context);
    return $context;
}

sub expected_state {
    my ($context) = @_;
    my $expected = clone(NativeProxyLifetimeFiles::stable($context->{initial}));
    for my $name (qw(target other)) {
        next unless $context->{completed}{"retire_$name"};
        my $root = $context->{paths}{$name};
        delete $expected->{$_} for grep { $_ eq $root || index($_, "$root/") == 0 } keys %$expected;
        delete $expected->{$context->{runtimes}{$name}{reference}{global}{identity}{path}};
    }
    for my $name (qw(a b)) {
        delete $expected->{$context->{observations}{$name}{observation_reference}{source}{identity}{path}}
            if $context->{completed}{"release_$name"};
    }
    if ($context->{completed}{maintain_target}) {
        my $root = "$context->{paths}{store}/images/$context->{runtimes}{target}{image}{key}";
        delete $expected->{$_} for grep { $_ eq $root || index($_, "$root/") == 0 } keys %$expected;
    }
    if ($context->{archive_nodes}) {
        $expected->{$_} = clone($context->{archive_nodes}{$_}) for keys %{$context->{archive_nodes}};
    }
    return $expected;
}

sub bind_archive_nodes {
    my ($context, $name) = @_;
    my $receipt = $context->{archives}{$name};
    my $directory = $receipt->{archive_directory_identity}{path};
    my $current = NativeProxyLifetimeFiles::stable($context->{current});
    die "archive directory differs from independently read identity\n" unless exists($current->{$directory})
        && $current->{$directory}{kind} eq 'directory'
        && same($current->{$directory}{identity}, $receipt->{archive_directory_identity});
    my %expected = ($directory => 1);
    for my $binding (@{$receipt->{source_bindings}}) {
        my $path = $binding->{archive}{path}; $expected{$path} = 1;
        die "archive receipt differs from independently read source\n"
            unless exists($current->{$path}) && same($current->{$path}{identity}, $binding->{archive});
        my ($source) = grep { same($_->{identity}, $binding->{source}) }
            @{$context->{observations}{$name}{target_sources}};
        die "archive does not retain the original bytes\n" unless $source
            && $current->{$path}{bytes_hex} eq unpack('H*', $source->{bytes});
    }
    my @actual = grep { $_ eq $directory || index($_, "$directory/") == 0 } keys %$current;
    die "archive gained unknown or missing members\n" unless same([sort @actual], [sort keys %expected]);
    my $nodes = {map { $_ => $current->{$_} } @actual};
    die "archive reuse changed original content identities\n" if $context->{archive_nodes} && !same($context->{archive_nodes}, $nodes);
    $context->{archive_nodes} = $nodes;
}

sub execute_event {
    my ($context, $event) = @_;
    for my $name (qw(a b)) {
        next if $context->{completed}{retire_target} || $context->{completed}{"release_$name"};
        my $reused = measure($context, "reuse_${name}_before_$event", sub {
            NativeProxyObservationAcquisition::reuse_observation_reference($context->{paths}{store},
                $context->{requests}{$name}, $context->{observations}{$name});
        }, {store => $context->{paths}{store}, request => $context->{requests}{$name},
            acquired => $context->{observations}{$name}});
        die "repeated observation changes strict original custody\n" unless same($reused, $context->{observations}{$name});
        die "repeated observation changes physical state\n"
            unless same(expected_state($context), NativeProxyLifetimeFiles::stable($context->{current}));
    }
    if ($event =~ /\Aarchive_([ab])\z/) {
        my $name = $1;
        $context->{archives}{$name} = measure($context, $event, sub {
            NativeProxyObservationArchive::archive_retained_sources($context->{paths}{store},
                $context->{requests}{$name}, $context->{observations}{$name});
        }, {store => $context->{paths}{store}, request => $context->{requests}{$name},
            acquired => $context->{observations}{$name}});
        bind_archive_nodes($context, $name);
    } elsif ($event =~ /\Aretire_(target|other)\z/) {
        my $name = $1;
        my $cleanup = {compiler => settled_owner('failed'), outer => settled_owner('completed'),
                       stages => [settled_owner('cancelled')]};
        measure($context, $event, sub {
            NativeProxyRuntimeRetirement::retire_runtime_reference($context->{paths}{store}, $context->{runtimes}{$name}, $cleanup);
        }, {store => $context->{paths}{store}, acquired => $context->{runtimes}{$name}, cleanup => $cleanup});
    } elsif ($event =~ /\Arelease_([ab])\z/) {
        my $name = $1;
        measure($context, $event, sub {
            NativeProxyObservationRelease::release_observation_reference($context->{paths}{store},
                $context->{requests}{$name}, $context->{observations}{$name}, $context->{archives}{$name},
                $context->{selections}{$name}, $context->{settlements}{$name});
        }, {store => $context->{paths}{store}, request => $context->{requests}{$name},
            acquired => $context->{observations}{$name}, archive => $context->{archives}{$name},
            selection => $context->{selections}{$name}, settlement => $context->{settlements}{$name}});
    } elsif ($event eq 'maintain_target') {
        measure($context, $event, sub {
            NativeProxyImageMaintenance::remove_unreferenced_image($context->{paths}{store}, $context->{runtimes}{target}{image}{key});
        }, {store => $context->{paths}{store}, image_key => $context->{runtimes}{target}{image}{key}});
    } else { die "event outside admitted domain\n"; }
    $context->{completed}{$event} = 1;
    die "independent completed-event state projection differs\n"
        unless same(expected_state($context), NativeProxyLifetimeFiles::stable($context->{current}));
    journal('prefix-verified', {case => $context->{name}, completed => [sort keys %{$context->{completed}}],
        stable_state_sha256 => sha256_hex($JSON->encode(NativeProxyLifetimeFiles::stable($context->{current})))});
}

sub cleanup_case {
    my ($context) = @_;
    die "journal failed; preserve roots for recovery\n" if $JOURNAL_FAILED;
    my $current = probe($context);
    journal('cleanup-admission', {case => $context->{name}, observed => $current, created_identities => \%OWNED});
    die "independent cleanup admission failed\n" unless complete_trace($current);
    for my $path (keys %{$current->{result}{nodes}}) {
        my $node = $current->{result}{nodes}{$path}; my $owned = $OWNED{$path};
        die "unknown or replaced object retained before cleanup: $path\n" unless $owned
            && $node->{identity}{device} == $owned->{device} && $node->{identity}{inode} == $owned->{inode}
            && $node->{kind} eq $owned->{kind};
    }
    return measure($context, 'owned_cleanup', sub {
        NativeProxyLifetimeFiles::cleanup_exact($context->{roots}, $current->{result});
    }, {roots => $context->{roots}, expected => $current->{result}});
}

sub main {
    die "execution requires --execute-admitted\n" unless @ARGV == 1 && $ARGV[0] eq '--execute-admitted';
    my $base = 'docs/audits/native-proxy-lifetime-files-admission-20260913';
    $PLAN = document("$base/plan.json"); $SELECTION = document("$base/selection.json");
    $PINS = document("$base/preflight-pins.json");
    authenticate();
    my $permit = document('.artifacts/logs/native-proxy-lifetime-files-20260913/execution-admission.json');
    die "execution admission differs\n" unless $permit->{schema} eq 'fsmgen.inactive_lifetime_execution_admission.v1'
        && $permit->{execution_owner} eq $SELECTION->{execution_owner}
        && $permit->{admission_commit} =~ /\A[0-9a-f]{40}\z/
        && $permit->{plan_sha256} eq sha256_hex(read_bytes("$base/plan.json"))
        && $permit->{preflight_sha256} eq sha256_hex(read_bytes("$base/preflight-pins.json"))
        && $permit->{task_sha256} eq sha256_hex(read_bytes('docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md'));
    die "execution owner is not active\n" unless read_bytes('MEMORY.md') =~
        /active_work_unit: `\Q$SELECTION->{execution_owner}\E`/;
    die "normal user required\n" if $< == 0 || $< != $>;
    NativeProxyLifetimeFiles::initialize($ROOT);
    ensure_project_artifact_dir(qw(tmp native-proxy-image-custody cases));
    ensure_project_artifact_dir(qw(tmp process-supervisor-tests));
    ensure_project_artifact_dir(qw(logs native-proxy-observation-acquisition-20260910 cases));
    $JOURNAL = $SELECTION->{journal};
    NativeProxyLifetimeFiles::create_directory($JOURNAL);
    $STARTED = now_ns();
    journal('run-started', {admission => $permit, selection_sha256 => sha256_hex(read_bytes("$base/selection.json")),
        pid => 0 + $$, normal_uid => 0 + $<, runtime_qualification => 0, synthetic_ownership_only => 1});
    my $model = document($SELECTION->{payload_source}{path});
    my $sources = $model->{seeds}{$SELECTION->{payload_source}{profile}}{observers}{a}{acquired}{target_sources};
    my $payloads = {map { $_ => pack('H*', $sources->[$SELECTION->{payload_source}{target_sources}{$_}]{bytes_hex}) } qw(wrapper c image)};
    no warnings 'redefine';
    local *FSM::Test::RustProxyFixture::supervise_process = sub { ++$FORBIDDEN; die "forbidden fixture process\n"; };
    local *FSM::Test::ProcessSupervisor::supervise_process = sub { ++$FORBIDDEN; die "forbidden test process\n"; };
    local *FSM::Support::ProcessSupervisor::supervise_process = sub { ++$FORBIDDEN; die "forbidden supervisor process\n"; };
    my @cases;
    for my $case (@{$SELECTION->{cases}}) {
        authenticate();
        die "total lifetime wall exceeded\n" if (now_ns() - $STARTED) / 1e9 >= $SELECTION->{bounds}{total_wall_seconds};
        %OWNED = ();
        my $context = {name => $case->{name}, roots => [map { $case->{roots}{$_} } qw(store target other evidence)]};
        my ($ok, $error, $cleanup, $cleanup_error);
        {
            local $SIG{ALRM} = sub { die "case lifetime wall exceeded\n"; };
            my $remaining = $SELECTION->{bounds}{total_wall_seconds} - (now_ns() - $STARTED) / 1e9;
            my $allowance = $remaining < $SELECTION->{bounds}{case_wall_seconds}
                ? $remaining : $SELECTION->{bounds}{case_wall_seconds};
            $ok = eval {
                die "total wall exhausted before case\n" unless $allowance > 0;
                alarm($allowance);
                $context = prepare_case($case, $payloads);
                execute_event($context, $_) for @{$case->{order}};
                1;
            };
            $error = $@;
            alarm(0);
        }
        journal('case-primary', {case => $case->{name}, returned => $ok ? 1 : 0, error_hex => unpack('H*', $error)});
        my $clean;
        {
            local $SIG{ALRM} = sub { die "owned cleanup wall exceeded\n"; };
            my $remaining = $SELECTION->{bounds}{total_wall_seconds} - (now_ns() - $STARTED) / 1e9;
            my $allowance = $remaining < $SELECTION->{bounds}{cleanup_wall_seconds}
                ? $remaining : $SELECTION->{bounds}{cleanup_wall_seconds};
            $clean = eval {
                die "total wall exhausted before cleanup; preserve roots\n" unless $allowance > 0;
                alarm($allowance);
                $cleanup = cleanup_case($context);
                1;
            };
            $cleanup_error = $@;
            alarm(0);
        }
        my $result = {case => $case->{name}, primary_returned => $ok ? 1 : 0, error_hex => unpack('H*', $error),
            cleanup_returned => $clean ? 1 : 0, cleanup_error_hex => unpack('H*', $cleanup_error), cleanup => $cleanup};
        journal('case-final', $result); push @cases, $result;
        last unless $ok && $clean;
    }
    my $success = @cases == @{$SELECTION->{cases}} && !(grep { !$_->{primary_returned} || !$_->{cleanup_returned} } @cases) && !$FORBIDDEN;
    journal('run-final', {success => $success ? 1 : 0, cases => \@cases, forbidden_process_attempts => $FORBIDDEN,
        elapsed_ns => now_ns() - $STARTED, runtime_qualification => 0});
    print $JSON->encode({success => $success ? 1 : 0, cases => scalar(@cases), journal_records => $SERIAL,
                        journal_bytes => $TOTAL_BYTES, forbidden_process_attempts => $FORBIDDEN, runtime_qualification => 0}), "\n";
    die "new lifetime qualification incomplete; no retry\n" unless $success;
}

main() unless caller;
1;
