#!/usr/bin/env perl
use strict;
use warnings;
our ($observing, $writer_path, $stage, $active_row, $cut, $omit_guard);
our ($lock_address, $reference_address, $directory_address);
our (%counters, %coordinator_directories, @held);
our $forbidden = 0;
BEGIN {
    *CORE::GLOBAL::fork = sub { ++$forbidden; die 'forbidden fork'; };
    *CORE::GLOBAL::system = sub { ++$forbidden; die 'forbidden system'; };
    *CORE::GLOBAL::binmode = sub (*;$) {
        observe_handle($_[0], 'writer', $writer_path) if $observing && caller eq 'NativeProxyImagePublication';
        return @_ == 1 ? CORE::binmode($_[0]) : CORE::binmode($_[0], $_[1]);
    };
    *CORE::GLOBAL::opendir = sub (*$) {
        my $ok = CORE::opendir($_[0], $_[1]); my $error = 0+$!;
        if ($observing && $ok && (caller eq 'NativeProxyImageCoordination' || caller eq 'NativeProxyImageCustody')) {
            observe_directory($_[0], $_[1]);
        }
        $! = $error; return $ok;
    };
    *CORE::GLOBAL::closedir = sub (*) {
        if ($observing && $omit_guard eq 'omit_directory_close'
                && defined($directory_address) && Scalar::Util::refaddr($_[0]) == $directory_address) {
            ++$active_row->{omitted_close_calls}; return 1;
        }
        return CORE::closedir($_[0]);
    };
    *CORE::GLOBAL::close = sub (*) {
        if ($observing && caller eq 'NativeProxyImageCoordination') {
            my $selected = $omit_guard eq 'omit_lock_close' ? $lock_address
                : $omit_guard eq 'omit_reference_close' ? $reference_address : undef;
            if (defined($selected) && Scalar::Util::refaddr($_[0]) == $selected) {
                ++$active_row->{omitted_close_calls}; return 1;
            }
        }
        return CORE::close($_[0]);
    };
    *CORE::GLOBAL::fcntl = sub (*$$) {
        my ($handle, $operation, $argument) = @_;
        my $lock_call = $observing && caller eq 'NativeProxyImageCoordination';
        if ($lock_call) {
            die 'unexpected coordinator fcntl' unless $operation == Fcntl::F_GETFD() || $operation == Fcntl::F_SETFD();
            event('coordinator:lock:flags:'.($operation == Fcntl::F_GETFD() ? 'get' : 'set'));
        }
        my $value = CORE::fcntl($handle, $operation, $argument); my $error = 0+$!;
        if ($lock_call && $operation == Fcntl::F_SETFD() && $value) {
            my $flags = CORE::fcntl($handle, Fcntl::F_GETFD(), 0);
            $active_row->{lock_cloexec_after_set} = defined($flags) && ($flags & Fcntl::FD_CLOEXEC()) ? 1 : 0;
        }
        $! = $error; return $value;
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
die 'prospective plan changed' unless sha256_hex($plan_bytes) eq '4b3bfcb6f1f1d9c938cc95561620928e8b50572cb9e132426c7c72c7967a1e10';
my $plan = $JSON->decode($plan_bytes);
my $vector = $JSON->decode(read_bytes("$FindBin::Bin/../native-proxy-image-custody-20260910/vectors.json"));
my ($C, $IMAGE) = map { pack('H*', $_) } @$vector{qw(generated_c_hex image_hex)};
my $WRAPPER = "#!/usr/bin/perl\n# inert observation wrapper; never executed\n";
my $parent = ensure_project_artifact_dir(qw(tmp native-proxy-image-custody cases));
my $work_parent = ensure_project_artifact_dir(qw(tmp process-supervisor-tests));
my $evidence_parent = ensure_project_artifact_dir(qw(logs native-proxy-observation-acquisition-20260910 cases));
my $log = ensure_project_artifact_dir(qw(logs native-proxy-observation-coordinator-cuts-20260911));
my $result = {schema => 'fsmgen.inactive_observation_coordinator_cuts_qualification.v1',
    success => JSON::PP::false, allocated => [], cases => [], mutants => []};
my $acquire = \&NativeProxyObservationAcquisition::acquire_observation_reference;
my $reuse = \&NativeProxyObservationAcquisition::reuse_observation_reference;
my $source = \&NativeProxyImageCustody::_source;
my $recheck = \&NativeProxyImageCustody::_recheck_source;
my $directory = \&NativeProxyImageCustody::_directory;
my $open_lock = \&NativeProxyImageCoordination::_open_existing_lock;
my $lock_identity = \&NativeProxyImageCoordination::_lock_identity;
my $coord_acquire = \&NativeProxyImageCoordination::_acquire;
my $structure = \&NativeProxyImageCoordination::_structure;
my $census = \&NativeProxyImageCoordination::_census;
my $names = \&NativeProxyImageCoordination::_names;
my $inspect = \&NativeProxyReferenceCensus::_inspect_locked;
my $admit = \&NativeProxyObservationAcquisition::_admit_locked;
my $publish = \&NativeProxyObservationAcquisition::_acquire_locked;
my $finish = \&NativeProxyObservationAcquisition::_finish_locked;
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
    my $progress = {schema => 'fsmgen.inactive_coordinator_cut_progress.v1', success => $result->{success},
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
        die 'coordinator fixture remains' if -e $path || -l $path;
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
sub observe_directory {
    my ($handle, $absolute) = @_;
    my $entry = {handle => $handle, kind => 'directory', path => File::Spec->abs2rel($absolute, $ROOT),
        descriptor => fileno($handle)};
    push @held, $entry;
    $directory_address //= refaddr($handle);
    die 'directory descriptor unavailable' unless defined($entry->{descriptor});
    open my $probe, '<&', $entry->{descriptor} or die $!;
    my @s = stat($probe); die 'directory observer type' unless @s && S_ISDIR($s[2]);
    $entry->{identity} = {device => 0+$s[0], inode => 0+$s[1], mode => $s[2] & 07777, uid => 0+$s[4]};
    $entry->{observer_descriptor} = fileno($probe);
    $entry->{observer_close_ok} = CORE::close($probe) ? 1 : 0;
    $entry->{observer_closed} = defined(fileno($probe)) ? 0 : 1;
    die 'directory observer close failed' unless $entry->{observer_close_ok} && $entry->{observer_closed};
}
sub event {
    my ($name) = @_;
    return if $active_row->{cut_fired};
    push @{$active_row->{trace}}, $name;
    if (defined($cut) && $name eq $cut) {
        $active_row->{cut_fired} = 1;
        die "injected coordinator cut: $name\n";
    }
}
sub coordinator_directory_event {
    my ($path) = @_;
    my $relative = File::Spec->abs2rel($path, $ROOT);
    if ($stage =~ /\Astructure:/) {
        die 'unexpected structure directory' unless exists($coordinator_directories{$relative});
        event($stage.':directory:'.$coordinator_directories{$relative});
    } elsif ($stage =~ /\Acensus:/) {
        event($stage.':directory:'.$counters{$stage.':directory'}++);
    } else {
        die 'unexpected coordinator directory' unless exists($coordinator_directories{$relative});
        my $role = $coordinator_directories{$relative};
        my $index = $counters{'coordinator:directory:'.$role}++;
        if ($role eq 'store') {
            die 'unexpected root read' if $index > 2;
            event('coordinator:root:'.(qw(initial acquired final))[$index]);
        } else {
            die 'unexpected namespace read' if $index > 1;
            event('coordinator:namespace:'.($index ? 'final' : 'initial').':'.$role);
        }
    }
}
sub evaluate {
    my ($context, $spec, $mutant) = @_;
    my $row = {id => $spec->{id}, route => $spec->{route}, context => clone($context),
        before => footprint($context), trace => [], cut_fired => 0, omitted_close_calls => 0};
    my $store = $context->{store}{path};
    my $hold_key = NativeProxyImageCustody::observation_reference_key(
        $context->{evidence}{path}, @{$context->{request}}{qw(observer_birth target_birth)});
    local $writer_path = "$store/references/$hold_key.json";
    local %coordinator_directories = ($store => 'store', "$store/images" => 'images', "$store/references" => 'references');
    local ($observing, $stage, $active_row, $cut, $omit_guard) = (1, '', $row, $spec->{cut}, $spec->{guard} // '');
    local ($lock_address, $reference_address, $directory_address);
    local @held; local %counters;
    my $request = clone($context->{request}); my $previous = clone($context->{previous});
    my $ok = eval {
        local *NativeProxyImageCoordination::_open_existing_lock = sub {
            event('coordinator:lock:open');
            my $handle = $open_lock->(@_);
            observe_handle($handle, 'lock', File::Spec->abs2rel($_[0], $ROOT));
            $lock_address = refaddr($handle); return $handle;
        };
        local *NativeProxyImageCoordination::_lock_identity = sub {
            my $index = $counters{'lock_identity'}++;
            die 'unexpected lock identity read' if $index > 2;
            event('coordinator:lock:identity:'.(qw(initial acquired final))[$index]);
            return $lock_identity->(@_);
        };
        local *NativeProxyImageCoordination::_acquire = sub {
            event('coordinator:lock:acquire'); return $coord_acquire->(@_);
        };
        local *NativeProxyImageCoordination::_structure = sub {
            my $index = $counters{'structure'}++;
            die 'unexpected structure call or creation' if $index > 1 || $_[1];
            local $stage = 'structure:'.($index ? 'final' : 'pre');
            event($stage.':enter'); my $value = $structure->(@_);
            event($stage.':return'); return $value;
        };
        local *NativeProxyImageCoordination::_census = sub {
            my $index = $counters{'census'}++;
            die 'unexpected structural census' if $index > 1;
            local $stage = 'census:'.($index ? 'post' : 'pre');
            event($stage.':enter'); my $value = $census->(@_);
            event($stage.':return'); return $value;
        };
        local *NativeProxyImageCoordination::_names = sub {
            if (caller eq 'NativeProxyImageCoordination') {
                my $index = $counters{$stage.':names'}++;
                die 'unexpected namespace enumeration' if $index > 1;
                my $name = $stage =~ /\Astructure:/ ? ($index ? 'complete' : 'entry') : ($index ? 'references' : 'images');
                event($stage.':names:'.$name);
            }
            return $names->(@_);
        };
        # The semantic and observation entrypoints are caller-sealed. Tail calls
        # preserve the real coordinator; the stage remains outside local scopes.
        local *NativeProxyReferenceCensus::_inspect_locked = sub {
            my $index = $counters{'semantic'}++;
            die 'unexpected semantic census' if $index > 1;
            $stage = 'semantic:'.($index ? 'post' : 'pre'); event($stage.':enter'); goto &$inspect;
        };
        local *NativeProxyObservationAcquisition::_admit_locked = sub {
            $stage = 'operation:admit'; event($stage.':enter'); goto &$admit;
        };
        local *NativeProxyObservationAcquisition::_acquire_locked = sub {
            $stage = 'operation:acquire'; event($stage.':enter'); goto &$publish;
        };
        local *NativeProxyObservationAcquisition::_finish_locked = sub {
            $stage = 'operation:finish'; event($stage.':enter'); goto &$finish;
        };
        local *NativeProxyImageCustody::_directory = sub {
            coordinator_directory_event($_[0]) if caller eq 'NativeProxyImageCoordination';
            return $directory->(@_);
        };
        local *NativeProxyImageCustody::_source = sub {
            my $structural = caller eq 'NativeProxyImageCoordination';
            my $index;
            if ($structural) {
                die 'unexpected structural source' unless $stage =~ /\Acensus:/;
                $index = $counters{$stage.':source'}++; event($stage.':source:'.$index);
            }
            my $opened = $source->(@_);
            observe_handle($opened->{handle}, 'source', File::Spec->abs2rel($opened->{path}, $ROOT),
                NativeProxyReferenceCensus::_snapshot($opened));
            $reference_address = refaddr($opened->{handle}) if $structural && $stage eq 'census:pre' && $index == 0;
            return $opened;
        };
        local *NativeProxyImageCustody::_recheck_source = sub {
            event($stage.':check:'.$counters{$stage.':check'}++) if caller eq 'NativeProxyImageCoordination';
            return $recheck->(@_);
        };
        $row->{result} = $spec->{route} eq 'fresh'
            ? $acquire->($store, $request) : $reuse->($store, $request, $previous);
        1;
    };
    my $error = $@; $error =~ s/\Q$ROOT\E/./g;
    $row->{error} = $error; $row->{returned} = $ok && defined($row->{result}) ? 1 : 0;
    $row->{request_after} = $request; $row->{previous_after} = $previous;
    my @observed;
    for my $entry (@held) {
        my %copy = %$entry; my $handle = delete $copy{handle};
        my $open = defined(fileno($handle)) ? 1 : 0;
        $copy{closed_before_recovery} = $open ? 0 : 1; $copy{recovery_close_ok} = undef;
        if ($open) {
            if ($copy{kind} eq 'directory') {
                $copy{recovery_close_ok} = CORE::closedir($handle) ? 1 : 0;
            } else {
                my @s = stat($handle); $copy{current_identity} = metadata(\@s);
                my $flags = CORE::fcntl($handle, F_GETFD, 0);
                $copy{open_cloexec} = defined($flags) && ($flags & FD_CLOEXEC) ? 1 : 0;
                $copy{recovery_close_ok} = CORE::close($handle) ? 1 : 0;
            }
        }
        $copy{closed_after_recovery} = defined(fileno($handle)) ? 0 : 1; push @observed, \%copy;
    }
    $row->{handles} = \@observed; $row->{after} = footprint($context); return $row;
}
write_bytes("$log/rows.jsonl", '', 0600);
save_result();
for my $category (qw(cases mutants)) {
    for my $spec (@{$plan->{$category}}) {
        my $mutant = $category eq 'mutants' ? 1 : 0;
        my $row;
        context($spec->{route}, sub { $row = evaluate($_[0], $spec, $mutant); });
        record_row($category, $row);
        my @expected = map { $_->{event} } @{$plan->{flows}{$spec->{route}}};
        if (defined($spec->{cut})) {
            my ($index) = grep { $expected[$_] eq $spec->{cut} } 0..$#expected;
            @expected = @expected[0..$index];
        }
        my $returns = !defined($spec->{cut});
        my $error = $returns ? '' : "injected coordinator cut: $spec->{cut}\n";
        my $open = grep { !$_->{closed_before_recovery} } @{$row->{handles}};
        my $expected_open = $mutant ? 1 : 0;
        my $behavior = $row->{returned} == ($returns ? 1 : 0) && $row->{error} eq $error
            && $row->{cut_fired} == ($returns ? 0 : 1) && $JSON->encode($row->{trace}) eq $JSON->encode(\@expected);
        my $custody = $open == $expected_open && $row->{omitted_close_calls} == $expected_open
            && !grep({ !$_->{closed_after_recovery} || (defined($_->{recovery_close_ok}) && !$_->{recovery_close_ok})
                || ($_->{kind} eq 'source' && !$_->{cloexec})
                || ($_->{kind} eq 'directory' && (!$_->{observer_close_ok} || !$_->{observer_closed})) } @{$row->{handles}});
        ok($behavior, "$spec->{id}: exact executed prefix and outcome");
        ok($custody, "$spec->{id}: explicit descriptor disposition and observer recovery");
        unless ($behavior && $custody) {
            $result->{first_failure} = $spec->{id}; save_qualification();
            diag($row->{error} || "open handles $open, expected $expected_open");
            BAIL_OUT('unexpected coordinator interruption result');
        }
    }
}
is($forbidden, 0, 'no process attempt');
$result->{success} = JSON::PP::true; save_qualification(); save_result(); done_testing();
