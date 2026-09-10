#!/usr/bin/env perl
use strict;
use warnings;
our ($observing, $writer_path, $phase, $in_sources, $in_directories, $in_prior, $in_hold, $active_row, $cut);
our (%roles, %directory_roles, %originals, @held);
our $forbidden = 0;
BEGIN {
    *CORE::GLOBAL::fork = sub { ++$forbidden; die 'forbidden fork'; };
    *CORE::GLOBAL::system = sub { ++$forbidden; die 'forbidden system'; };
    *CORE::GLOBAL::binmode = sub (*;$) {
        observe_handle($_[0], 'writer', $writer_path) if $observing && caller eq 'NativeProxyImagePublication';
        return @_ == 1 ? CORE::binmode($_[0]) : CORE::binmode($_[0], $_[1]);
    };
}
use FindBin;
use lib "$FindBin::Bin/../../../perl", "$FindBin::Bin/../../../t/lib",
    map { "$FindBin::Bin/../$_" } qw(native-proxy-image-custody-20260910
        native-proxy-image-coordination-20260910 native-proxy-image-publication-20260910
        native-proxy-runtime-records-20260910 native-proxy-runtime-census-20260910
        native-proxy-runtime-acquisition-20260910 native-proxy-observation-acquisition-20260910
        native-proxy-observation-reuse-20260910);
use Digest::SHA qw(sha256_hex);
use Fcntl qw(S_ISDIR S_ISLNK S_ISREG F_GETFD FD_CLOEXEC);
use File::Spec;
use File::Temp ();
use JSON::PP ();
use Scalar::Util qw(refaddr);
use FixtureClone;
use Test::More;
use FSM::ProjectDataLocality qw(ensure_project_artifact_dir repository_root);
use FSM::Test::RustProxyFixture ();
BEGIN { *CORE::GLOBAL::exec = sub { ++$forbidden; die 'forbidden exec'; }; }
use ReferenceAcquisition;
use ObservationAcquisition;

my $ROOT = repository_root();
my $JSON = JSON::PP->new->canonical->ascii;
my $plan_bytes = read_bytes("$FindBin::Bin/plan.json");
die 'prospective plan changed' unless sha256_hex($plan_bytes) eq 'e1bc62c41afefe8a694d03eb4152dbf07d5818d436e7607af7f82a21d6a4397d';
my $plan = $JSON->decode($plan_bytes);
my $vector = $JSON->decode(read_bytes("$FindBin::Bin/../native-proxy-image-custody-20260910/vectors.json"));
my ($C, $IMAGE) = map { pack('H*', $_) } @$vector{qw(generated_c_hex image_hex)};
my $WRAPPER = "#!/usr/bin/perl\n# inert observation wrapper; never executed\n";
my $parent = ensure_project_artifact_dir(qw(tmp native-proxy-image-custody cases));
my $work_parent = ensure_project_artifact_dir(qw(tmp process-supervisor-tests));
my $evidence_parent = ensure_project_artifact_dir(qw(logs native-proxy-observation-acquisition-20260910 cases));
my $log = ensure_project_artifact_dir(qw(logs native-proxy-observation-snapshot-cuts-20260910));
my $result = {schema => 'fsmgen.inactive_observation_snapshot_cuts_qualification.v1',
    success => JSON::PP::false, allocated => [], cases => [], mutants => []};
my $acquire = \&NativeProxyObservationAcquisition::acquire_observation_reference;
my $reuse = \&NativeProxyObservationAcquisition::reuse_observation_reference;
my $source = \&NativeProxyImageCustody::_source;
my $recheck = \&NativeProxyImageCustody::_recheck_source;
my $directory = \&NativeProxyImageCustody::_directory;
my $prior = \&NativeProxyObservationAcquisition::_prior_directory;
my $source_closure = \&NativeProxyObservationAcquisition::_source_closure;
my $directory_closure = \&NativeProxyObservationAcquisition::_directory_closure;
my $admit = \&NativeProxyObservationAcquisition::_admit_locked;
my $publish = \&NativeProxyObservationAcquisition::_acquire_locked;
my $finish = \&NativeProxyObservationAcquisition::_finish_locked;
my $read_hold = \&NativeProxyObservationAcquisition::_read_hold;
my $open_lock = \&NativeProxyImageCoordination::_open_existing_lock;
my $close_sources = \&NativeProxyObservationAcquisition::_close_sources;
no warnings 'redefine';
local *FSM::Test::RustProxyFixture::supervise_process = sub { ++$forbidden; die 'forbidden compiler'; };
write_bytes("$log/admission.jsonl", '', 0600);

sub read_bytes {
    open my $fh, '<:raw', $_[0] or die "fixture read: $!";
    my $raw = do { local $/; <$fh> }; close $fh or die $!; return $raw;
}
sub write_bytes {
    my ($path, $raw, $mode) = @_;
    chmod(0600, $path) == 1 or die $! if -e $path;
    open my $fh, '>:raw', $path or die "fixture write: $!";
    print {$fh} $raw or die $!; close $fh or die $!; chmod($mode, $path) == 1 or die $!;
}
sub clone { return NativeProxyObservationFixtureClone::clone($_[0]); }
sub save_result {
    my $progress = {schema => 'fsmgen.inactive_snapshot_cut_progress.v1', success => $result->{success},
        allocations => scalar(@{$result->{allocated}}), cases => scalar(@{$result->{cases}}),
        mutants => scalar(@{$result->{mutants}}), forbidden_process_attempts => $forbidden};
    write_bytes("$log/progress.json", $JSON->encode($progress), 0600);
}
sub tree_footprint {
    my ($base) = @_; my %nodes; my $walk;
    $walk = sub {
        my ($path, $relative) = @_; my @s = lstat("$ROOT/$path"); die 'oracle stat' unless @s;
        die 'oracle volume/census bound' unless $s[0] == (stat($ROOT))[0] && keys(%nodes) < 512;
        my $node = {device => $s[0], inode => $s[1], mode => $s[2] & 07777, uid => $s[4]};
        $nodes{$relative} = $node;
        if (S_ISDIR($s[2])) {
            $node->{kind} = 'directory'; opendir my $dir, "$ROOT/$path" or die $!;
            my @names = sort grep { $_ ne '.' && $_ ne '..' } readdir $dir; closedir $dir or die $!;
            $walk->("$path/$_", length($relative) ? "$relative/$_" : $_) for @names;
        } elsif (S_ISLNK($s[2])) {
            $node->{kind} = 'symlink'; $node->{target} = readlink("$ROOT/$path");
        } elsif (S_ISREG($s[2])) {
            die 'oracle byte ceiling' if $s[7] > 65537; my $raw = read_bytes("$ROOT/$path");
            $node->{kind} = 'file'; $node->{links} = $s[3];
            $node->{bytes} = length($raw); $node->{sha256} = sha256_hex($raw);
        } else { $node->{kind} = 'special'; }
    };
    $walk->($base, ''); return \%nodes;
}

sub allocate {
    my ($kind, $path) = @_; my @s = lstat("$path");
    my $row = {kind => $kind, path => File::Spec->abs2rel("$path", $ROOT), device => $s[0], inode => $s[1]};
    open my $fh, '>>:raw', "$log/admission.jsonl" or die $!;
    print {$fh} $JSON->encode($row), "\n" or die $!; close $fh or die $!;
    push @{$result->{allocated}}, $row; save_result(); return $row;
}
sub identity { return {map { $_ => $_[0]{$_} } qw(path device inode)}; }
sub footprint {
    my ($context) = @_;
    return {map { $_ => tree_footprint($context->{$_}{path}) } qw(store workspace other_workspace evidence)};
}
sub save_qualification {
    $result->{forbidden_process_attempts} = $forbidden;
    write_bytes("$log/qualification.json", JSON::PP->new->canonical->ascii->pretty->encode($result), 0600);
}
sub record_row {
    my ($category, $row) = @_;
    push @{$result->{$category}}, $row;
    open my $stream, '>>:raw', "$log/rows.jsonl" or die $!;
    print {$stream} $JSON->encode({category => $category, row => $row}), "\n" or die $!;
    close $stream or die $!;
    save_result();
}
sub context {
    my ($route, $callback) = @_;
    my @temporary;
    my $context = {};
    my $ok = eval {
        for my $spec ([store => $parent], [workspace => $work_parent],
                      [other_workspace => $work_parent], [evidence => $evidence_parent]) {
            my $directory = File::Temp->newdir('fsmgen-XXXXXXXX', DIR => $spec->[1], CLEANUP => 1);
            push @temporary, $directory;
            $context->{$spec->[0]} = allocate($spec->[0] eq 'other_workspace' ? 'workspace' : $spec->[0], $directory);
        }
        my $case = $context->{store}{path};
        for my $kind (qw(workspace other_workspace)) {
            my $path = $context->{$kind}{path}; mkdir("$ROOT/$path/rust-tools", 0700) or die $!;
            write_bytes("$ROOT/$path/rust-tool-resolution", $WRAPPER, 0700);
            $context->{$kind eq 'workspace' ? 'runtime' : 'other_runtime'} =
                NativeProxyReferenceAcquisition::acquire_runtime_reference($case, identity($context->{$kind}),
                    $C, $IMAGE.($kind eq 'workspace' ? '' : 'other'));
        }
        $context->{request} = {workspace_identity => identity($context->{workspace}),
            evidence_directory_identity => identity($context->{evidence}),
            observer_birth => {pid => 101, ppid => 100, uid => 501, ruid => 501, start_sec => 123, start_usec => 456},
            target_birth => {pid => 201, ppid => 200, uid => 501, ruid => 501, start_sec => 124, start_usec => 789}};
        $context->{before_seed} = footprint($context);
        # This independent second owner belongs to the other image and is never
        # released by the operation under measurement.
        my $record = {schema => 'fsmgen.test.rust_proxy_image_observation_reference.v1',
            image_key => $context->{other_runtime}{image}{key},
            evidence_directory => $context->{evidence}{path},
            evidence_directory_identity => identity($context->{evidence}),
            observer_birth => clone($context->{request}{observer_birth}),
            target_birth => clone($context->{request}{target_birth}),
            selected_sources => clone($context->{other_runtime}{reference}{record}{selected_sources})};
        $record->{$_}{pid} += 1000 for qw(observer_birth target_birth);
        $record->{reference_key} = NativeProxyImageCustody::observation_reference_key(
            @$record{qw(evidence_directory observer_birth target_birth)});
        my $seed = "$case/references/$record->{reference_key}.json";
        die 'independent hold already exists' if -e "$ROOT/$seed" || -l "$ROOT/$seed";
        write_bytes("$ROOT/$seed", NativeProxyObservationRecord::encode_observation_record($case, $record), 0400);
        $context->{seeded_record} = $record;
        $context->{before_acquisition} = footprint($context);
        $context->{previous} = $acquire->($case, $context->{request}) if $route eq 'reuse';
        $context->{after_acquisition} = footprint($context);
        $callback->($context);
        1;
    };
    my $error = $@;
    @temporary = ();
    for my $kind (qw(store workspace other_workspace evidence)) {
        next unless $context->{$kind};
        my $path = "$ROOT/$context->{$kind}{path}";
        die 'snapshot fixture remains' if -e $path || -l $path;
    }
    if (!$ok) {
        $error =~ s/\Q$ROOT\E/./g;
        $result->{unexpected_error} = $error;
        $result->{failed_context} = clone($context);
        save_qualification();
        die $error;
    }
}
sub metadata {
    my ($values) = @_;
    return {device => 0+$values->[0], inode => 0+$values->[1], mode => $values->[2] & 07777,
        links => 0+$values->[3], uid => 0+$values->[4], size_bytes => 0+$values->[7]};
}
sub observe_handle {
    my ($handle, $kind, $path, $snapshot) = @_;
    my $entry = {handle => $handle, kind => $kind, path => $path, descriptor => fileno($handle)};
    push @held, $entry;
    my @s = stat($handle); die 'cannot observe returned handle' unless @s;
    $entry->{identity} = metadata(\@s);
    $entry->{snapshot} = clone($snapshot) if $snapshot;
    if ($kind eq 'source') {
        my $flags = CORE::fcntl($handle, F_GETFD, 0);
        $entry->{cloexec} = defined($flags) && ($flags & FD_CLOEXEC) ? 1 : 0;
    }
}
sub event {
    my ($name) = @_;
    return if $active_row->{cut_fired};
    push @{$active_row->{trace}}, $name;
    if (defined($cut) && $name eq $cut) {
        $active_row->{cut_fired} = 1;
        die "injected snapshot cut: $name\n";
    }
}
sub role {
    my ($path, $mapping) = @_;
    my $relative = File::Spec->abs2rel($path, $ROOT);
    die "unknown observation path: $relative\n" unless exists($mapping->{$relative});
    return $mapping->{$relative};
}
sub evaluate {
    my ($context, $spec, $mutant) = @_;
    my $row = {id => $spec->{id}, route => $spec->{route}, context => clone($context),
        before => footprint($context), trace => [], cut_fired => 0};
    my $runtime = $context->{runtime};
    my $hold_key = NativeProxyImageCustody::observation_reference_key(
        $context->{evidence}{path}, @{$context->{request}}{qw(observer_birth target_birth)});
    local $writer_path = "$context->{store}{path}/references/$hold_key.json";
    local %roles = (
        "$context->{workspace}{path}/rust-tool-resolution" => 'wrapper',
        $runtime->{reference}{private}{identity}{path} => 'private',
        $runtime->{reference}{global}{identity}{path} => 'global',
        $runtime->{image}{snapshots}[0]{identity}{path} => 'c',
        $runtime->{image}{snapshots}[1]{identity}{path} => 'image', $writer_path => 'hold');
    local %directory_roles = ($context->{workspace}{path} => 'workspace', $context->{evidence}{path} => 'evidence',
        "$context->{workspace}{path}/rust-tools" => 'tools', "$context->{store}{path}/images/$runtime->{image}{key}" => 'image');
    local ($observing, $phase, $in_sources, $in_directories, $in_prior, $in_hold) = (1, '', 0, 0, 0, 0);
    local $active_row = $row; local $cut = $spec->{cut}; local @held; local %originals;
    my $request = clone($context->{request}); my $previous = clone($context->{previous});
    my $ok = eval {
        local *NativeProxyImageCoordination::_open_existing_lock = sub {
            my $handle = $open_lock->(@_);
            observe_handle($handle, 'lock', File::Spec->abs2rel($_[0], $ROOT));
            return $handle;
        };
        # Sealed callers see their real coordinator. The operation stage lives
        # outside these tail-call wrappers, so it survives goto unwinding.
        local *NativeProxyObservationAcquisition::_admit_locked = sub {
            $phase = 'admit'; event('admit:enter'); goto &$admit;
        };
        local *NativeProxyObservationAcquisition::_acquire_locked = sub {
            $phase = 'acquire'; event('acquire:enter'); goto &$publish;
        };
        local *NativeProxyObservationAcquisition::_finish_locked = sub {
            $phase = 'finish'; event('finish:enter'); goto &$finish;
        };
        local *NativeProxyObservationAcquisition::_prior_directory = sub {
            local $in_prior = 1; event('admit:prior:'.$_[1]); return $prior->(@_);
        };
        local *NativeProxyObservationAcquisition::_source_closure = sub {
            local $in_sources = 1;
            local %originals = map { refaddr($_) => 1 } @{$_[0]{sources}};
            event("$phase:sources:enter"); return $source_closure->(@_);
        };
        local *NativeProxyObservationAcquisition::_directory_closure = sub {
            local $in_directories = 1; event("$phase:directories:enter"); return $directory_closure->(@_);
        };
        local *NativeProxyObservationAcquisition::_read_hold = sub {
            local $in_hold = 1; event('finish:hold:enter');
            my $snapshot = $read_hold->(@_);
            # _read_hold has already explicitly closed its temporary handle.
            event('finish:hold:return'); return $snapshot;
        };
        local *NativeProxyObservationAcquisition::_close_sources = sub {
            return '' if $mutant;
            return $close_sources->(@_);
        };
        local *NativeProxyImageCustody::_directory = sub {
            if (caller eq 'NativeProxyObservationAcquisition' && !$in_prior) {
                event(($in_directories ? $phase : 'admit').':directory:'.role($_[0], \%directory_roles));
            }
            return $directory->(@_);
        };
        local *NativeProxyImageCustody::_source = sub {
            if (caller eq 'NativeProxyObservationAcquisition') {
                my $name = role($_[0], \%roles);
                event($in_sources ? "$phase:sources:read:$name" : $in_hold ? 'finish:hold:read' : "admit:read:$name");
            }
            # Never inject after a reader returns and before its caller owns
            # the handle. The observer retains an alias without a new cut.
            my $opened = $source->(@_);
            observe_handle($opened->{handle}, 'source', File::Spec->abs2rel($opened->{path}, $ROOT),
                NativeProxyReferenceCensus::_snapshot($opened));
            return $opened;
        };
        local *NativeProxyImageCustody::_recheck_source = sub {
            if (caller eq 'NativeProxyObservationAcquisition') {
                if ($in_sources) {
                    my $which = $originals{refaddr($_[0])} ? 'original' : 'fresh';
                    event("$phase:sources:$which:".role($_[0]{path}, \%roles));
                } elsif ($in_hold) { event('finish:hold:check'); }
            }
            return $recheck->(@_);
        };
        $row->{result} = $spec->{route} eq 'fresh'
            ? $acquire->($context->{store}{path}, $request)
            : $reuse->($context->{store}{path}, $request, $previous);
        1;
    };
    my $error = $@; $error =~ s/\Q$ROOT\E/./g;
    $row->{error} = $error; $row->{returned} = $ok && defined($row->{result}) ? 1 : 0;
    $row->{request_after} = $request; $row->{previous_after} = $previous;
    my @observed;
    for my $entry (@held) {
        my %copy = %$entry; my $handle = delete $copy{handle};
        my $open = defined(fileno($handle)) ? 1 : 0;
        $copy{closed_before_recovery} = $open ? 0 : 1;
        $copy{recovery_close_ok} = undef;
        if ($open) {
            my @s = stat($handle); $copy{current_identity} = metadata(\@s);
            my $flags = CORE::fcntl($handle, F_GETFD, 0);
            $copy{open_cloexec} = defined($flags) && ($flags & FD_CLOEXEC) ? 1 : 0;
            $copy{recovery_close_ok} = CORE::close($handle) ? 1 : 0;
        }
        $copy{closed_after_recovery} = defined(fileno($handle)) ? 0 : 1;
        push @observed, \%copy;
    }
    $row->{handles} = \@observed;
    $row->{after} = footprint($context);
    return $row;
}
write_bytes("$log/rows.jsonl", '', 0600);
save_result();
for my $category (qw(cases mutants)) {
    for my $spec (@{$plan->{$category}}) {
        my $mutant = $category eq 'mutants' ? 1 : 0;
        my $row;
        context($spec->{route}, sub { $row = evaluate($_[0], $spec, $mutant); });
        record_row($category, $row);
        my @expected = @{$plan->{traces}{$spec->{route}}};
        if (defined($spec->{cut})) {
            my ($index) = grep { $expected[$_] eq $spec->{cut} } 0..$#expected;
            @expected = @expected[0..$index];
        }
        my $returns = !defined($spec->{cut});
        my $error = $returns ? '' : "injected snapshot cut: $spec->{cut}\n";
        my $open = grep { !$_->{closed_before_recovery} } @{$row->{handles}};
        my $expected_open = $mutant ? ($spec->{route} eq 'fresh' ? 5 : 6) : 0;
        my $behavior = $row->{returned} == ($returns ? 1 : 0) && $row->{error} eq $error
            && $row->{cut_fired} == ($returns ? 0 : 1) && $JSON->encode($row->{trace}) eq $JSON->encode(\@expected);
        my $custody = @{$row->{handles}} && $open == $expected_open
            && !grep({ !$_->{closed_after_recovery} || (defined($_->{recovery_close_ok}) && !$_->{recovery_close_ok})
                || ($_->{kind} eq 'source' && !$_->{cloexec}) } @{$row->{handles}});
        ok($behavior, "$spec->{id}: exact executed prefix and outcome");
        ok($custody, "$spec->{id}: explicit descriptor disposition and observer recovery");
        unless ($behavior && $custody) {
            $result->{first_failure} = $spec->{id}; save_qualification();
            diag($row->{error} || "open handles $open, expected $expected_open");
            BAIL_OUT('unexpected snapshot interruption result');
        }
    }
}
is($forbidden, 0, 'no process attempt');
$result->{success} = JSON::PP::true; save_qualification(); save_result(); done_testing();
