#!/usr/bin/env perl
use strict;
use warnings;
our ($observing, $writer_path, $active_row, $cut, $omit_guard, $semantic_active, $semantic_phase);
our ($in_image, $in_closure, $image_part, $image_role, $image_directory_index, $current_reference);
our ($original_address, $image_input_address, $fresh_address);
our (%counters, %image_roles, %reference_indexes, %source_indexes, %fresh_indexes, @held);
our (%close_sources, $close_spec);
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
    *CORE::GLOBAL::close = sub (*) {
        return CORE::close($_[0]) unless $observing && caller eq 'NativeProxyReferenceCensus'
            && exists($close_sources{Scalar::Util::refaddr($_[0])});
        my $source = $close_sources{Scalar::Util::refaddr($_[0])};
        my $selected = $omit_guard eq 'omit_original_reference_close' ? $original_address
            : $omit_guard eq 'omit_image_input_close' ? $image_input_address
            : $omit_guard eq 'omit_fresh_reference_close' ? $fresh_address : undef;
        my $omitted = defined($selected) && Scalar::Util::refaddr($_[0]) == $selected;
        my $entry = {%$source, descriptor => fileno($_[0]), actual_attempted => $omitted ? 0 : 1};
        if ($omitted) {
            ++$active_row->{omitted_close_calls};
            @$entry{qw(actual_close_ok actual_errno reported_errno returned)} = (undef, undef, 0, 1);
        } else {
            $! = 0;
            $entry->{actual_close_ok} = CORE::close($_[0]) ? 1 : 0;
            $entry->{actual_errno} = 0+$!;
            my $report = $close_spec->{reports}{$source->{label}};
            $entry->{reported_errno} = defined($report)
                ? ($report eq 'EIO' ? Errno::EIO() : Errno::ENOSPC()) : 0;
            $entry->{returned} = $entry->{actual_close_ok} && !$entry->{reported_errno} ? 1 : 0;
        }
        $entry->{closed_after_call} = defined(fileno($_[0])) ? 0 : 1;
        push @{$active_row->{close_calls}}, $entry;
        $! = $entry->{reported_errno} || $entry->{actual_errno} || 0;
        return $entry->{returned};
    };
    *CORE::GLOBAL::fcntl = sub (*$$) {
        my ($handle, $operation, $argument) = @_;
        my $lock_call = $observing && caller eq 'NativeProxyImageCoordination';
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
use Errno qw(EIO ENOSPC);
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
die 'prospective plan changed' unless sha256_hex($plan_bytes) eq 'd2f3c20d2389c43b38bec715e825c34928237b01ce70a42b376a14702c89b934';
my $plan = $JSON->decode($plan_bytes);
my $vector = $JSON->decode(read_bytes("$FindBin::Bin/../native-proxy-image-custody-20260910/vectors.json"));
my ($C, $IMAGE) = map { pack('H*', $_) } @$vector{qw(generated_c_hex image_hex)};
my $WRAPPER = "#!/usr/bin/perl\n# inert observation wrapper; never executed\n";
my $parent = ensure_project_artifact_dir(qw(tmp native-proxy-image-custody cases));
my $work_parent = ensure_project_artifact_dir(qw(tmp process-supervisor-tests));
my $evidence_parent = ensure_project_artifact_dir(qw(logs native-proxy-observation-acquisition-20260910 cases));
my $log = ensure_project_artifact_dir(qw(logs native-proxy-observation-semantic-close-20260911));
my $result = {schema => 'fsmgen.inactive_observation_semantic_close_qualification.v1',
    success => JSON::PP::false, allocated => [], cases => [], mutants => []};
my $acquire = \&NativeProxyObservationAcquisition::acquire_observation_reference;
my $reuse = \&NativeProxyObservationAcquisition::reuse_observation_reference;
my $source = \&NativeProxyImageCustody::_source;
my $recheck = \&NativeProxyImageCustody::_recheck_source;
my $directory = \&NativeProxyImageCustody::_directory;
my $read_entry = \&NativeProxyImageCustody::read_entry;
my $open_lock = \&NativeProxyImageCoordination::_open_existing_lock;
my $names = \&NativeProxyImageCoordination::_names;
my $inspect = \&NativeProxyReferenceCensus::_inspect_locked;
my $decode = \&NativeProxyReferenceCensus::_decode_record;
my $filename_key = \&NativeProxyReferenceCensus::_filename_key;
my $image_reader = \&NativeProxyReferenceCensus::_image;
my $matches_image = \&NativeProxyReferenceCensus::_matches_image;
my $snapshot = \&NativeProxyReferenceCensus::_snapshot;
my $closure = \&NativeProxyReferenceCensus::_closure;
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
    my $progress = {schema => 'fsmgen.inactive_semantic_close_progress.v1', success => $result->{success},
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
        die 'semantic fixture remains' if -e $path || -l $path;
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
        die "injected semantic close primary: $semantic_phase:$name\n";
    }
}
sub image_prefix { return "image:$image_part:$image_role"; }
sub image_input {
    my ($path) = @_;
    return 'c' if $path =~ m{/rustup\.c\z};
    return 'image' if $path =~ m{/rustup\z};
    die 'unknown semantic image input';
}
sub reference_index {
    my ($path) = @_;
    my $relative = File::Spec->abs2rel($path, $ROOT);
    die 'unknown semantic reference path' unless exists($reference_indexes{$relative});
    return $reference_indexes{$relative};
}
sub evaluate {
    my ($context, $spec) = @_;
    my $row = {id => $spec->{id}, route => $spec->{route}, phase => $spec->{phase}, context => clone($context),
        before => footprint($context), trace => [], close_calls => [], cut_fired => 0, omitted_close_calls => 0};
    my $store = $context->{store}{path};
    my $hold_key = NativeProxyImageCustody::observation_reference_key(
        $context->{evidence}{path}, @{$context->{request}}{qw(observer_birth target_birth)});
    local $writer_path = "$store/references/$hold_key.json";
    local %image_roles = ($context->{runtime}{image}{key} => 'primary', $context->{other_runtime}{image}{key} => 'other');
    my @records = ($context->{runtime}{reference}{record}, $context->{other_runtime}{reference}{record}, $context->{seeded_record});
    push @records, {reference_key => $hold_key, image_key => $context->{runtime}{image}{key}}
        if $spec->{route} eq 'reuse' || $spec->{phase} eq 'post';
    @records = sort { $a->{reference_key} cmp $b->{reference_key} } @records;
    my $binding = join(',', map { $image_roles{$_->{image_key}} } @records);
    die 'unplanned semantic reference ordering' unless exists($plan->{flows}{$spec->{route}}{$spec->{phase}}{$binding});
    $row->{binding} = $binding;
    local %reference_indexes = map { ("$store/references/$records[$_]{reference_key}.json" => $_) } 0..$#records;
    local ($observing, $active_row, $cut, $omit_guard, $semantic_active, $semantic_phase) =
        (1, $row, $spec->{cut}, $spec->{guard} // '', 0, '');
    local ($original_address, $image_input_address, $fresh_address);
    local ($in_image, $in_closure, $image_part, $image_role, $image_directory_index, $current_reference);
    local @held; local %counters; local %source_indexes; local %fresh_indexes;
    local %close_sources; local $close_spec = $spec;
    my $request = clone($context->{request}); my $previous = clone($context->{previous});
    my $ok = eval {
        local *NativeProxyImageCoordination::_open_existing_lock = sub {
            my $handle = $open_lock->(@_);
            observe_handle($handle, 'lock', File::Spec->abs2rel($_[0], $ROOT)); return $handle;
        };
        local *NativeProxyReferenceCensus::_inspect_locked = sub {
            my $index = $counters{'semantic'}++;
            die 'unexpected semantic pass' if $index > 1;
            $semantic_phase = $index ? 'post' : 'pre';
            $semantic_active = $semantic_phase eq $spec->{phase};
            event('inspect:enter') if $semantic_active;
            goto &$inspect;
        };
        # These wrappers remain tail calls so the original sealed coordinator
        # remains the caller. Later operation work leaves the selected pass.
        local *NativeProxyObservationAcquisition::_admit_locked = sub {
            $semantic_active = 0; goto &$admit;
        };
        local *NativeProxyObservationAcquisition::_acquire_locked = sub {
            $semantic_active = 0; goto &$publish;
        };
        local *NativeProxyObservationAcquisition::_finish_locked = sub {
            $semantic_active = 0; goto &$finish;
        };
        local *NativeProxyReferenceCensus::_decode_record = sub {
            event("reference:initial:$current_reference:decode") if $semantic_active;
            return $decode->(@_);
        };
        local *NativeProxyReferenceCensus::_filename_key = sub {
            event("reference:initial:$current_reference:key") if $semantic_active;
            return $filename_key->(@_);
        };
        local *NativeProxyReferenceCensus::_matches_image = sub {
            event("reference:initial:$current_reference:match") if $semantic_active;
            return $matches_image->(@_);
        };
        local *NativeProxyReferenceCensus::_snapshot = sub {
            event("reference:initial:$current_reference:snapshot")
                if $semantic_active && caller eq 'NativeProxyReferenceCensus';
            return $snapshot->(@_);
        };
        local *NativeProxyReferenceCensus::_image = sub {
            return $image_reader->(@_) unless $semantic_active;
            die 'unknown semantic image key' unless exists($image_roles{$_[1]});
            local $in_image = 1; local $image_part = $in_closure ? 'closure' : 'initial';
            local $image_role = $image_roles{$_[1]}; local $image_directory_index = 0;
            event(image_prefix().':enter'); my $value = $image_reader->(@_);
            event(image_prefix().':return'); return $value;
        };
        local *NativeProxyReferenceCensus::_closure = sub {
            return $closure->(@_) unless $semantic_active;
            local $in_closure = 1;
            event('closure:enter'); my $value = $closure->(@_);
            event('closure:return'); return $value;
        };
        local *NativeProxyImageCoordination::_names = sub {
            event('closure:names') if $semantic_active && caller eq 'NativeProxyReferenceCensus';
            return $names->(@_);
        };
        local *NativeProxyImageCustody::read_entry = sub {
            return $read_entry->(@_) unless $semantic_active && caller eq 'NativeProxyReferenceCensus';
            die 'aggregate reader outside semantic image' unless $in_image;
            event(image_prefix().':reader:enter'); my $value = $read_entry->(@_);
            # read_entry has closed all of its descriptors and returns snapshots.
            event(image_prefix().':reader:return'); return $value;
        };
        local *NativeProxyImageCustody::_directory = sub {
            if ($semantic_active && caller eq 'NativeProxyReferenceCensus') {
                die 'unexpected semantic directory' unless $in_image && $image_directory_index < 2;
                event(image_prefix().':directory:'.($image_directory_index++ ? 'final' : 'initial'));
            }
            return $directory->(@_);
        };
        local *NativeProxyImageCustody::_source = sub {
            my $selected = $semantic_active && caller eq 'NativeProxyReferenceCensus';
            my ($index, $input);
            if ($selected) {
                if ($in_image) {
                    $input = image_input($_[0]); event(image_prefix().":input:$input:read");
                } else {
                    $index = reference_index($_[0]);
                    if ($in_closure) { event("reference:closure:$index:read"); }
                    else { $current_reference = $index; event("reference:initial:$index:read"); }
                }
            }
            my $opened = $source->(@_);
            observe_handle($opened->{handle}, 'source', File::Spec->abs2rel($opened->{path}, $ROOT),
                NativeProxyReferenceCensus::_snapshot($opened));
            if ($selected) {
                my $label = $in_image ? image_prefix().':'.$input
                    : ($in_closure ? 'fresh:' : 'original:').$index;
                $close_sources{refaddr($opened->{handle})} = {label => $label,
                    path => File::Spec->abs2rel($opened->{path}, $ROOT), handle_index => $#held};
                if ($in_image) {
                    $image_input_address //= refaddr($opened->{handle}) if $image_part eq 'initial' && $input eq 'c';
                } elsif ($in_closure) {
                    $fresh_indexes{refaddr($opened)} = $index;
                    $fresh_address //= refaddr($opened->{handle}) if $index == 0;
                } else {
                    $source_indexes{refaddr($opened)} = $index;
                    $original_address //= refaddr($opened->{handle}) if $index == 0;
                }
            }
            return $opened;
        };
        local *NativeProxyImageCustody::_recheck_source = sub {
            if ($semantic_active && caller eq 'NativeProxyReferenceCensus') {
                if ($in_image) { event(image_prefix().':input:'.image_input($_[0]{path}).':check'); }
                elsif ($in_closure) {
                    my $address = refaddr($_[0]);
                    if (exists($source_indexes{$address})) { event('reference:closure:'.$source_indexes{$address}.':original'); }
                    else {
                        die 'unknown fresh reference object' unless exists($fresh_indexes{$address});
                        event('reference:closure:'.$fresh_indexes{$address}.':fresh');
                    }
                } else { event("reference:initial:$current_reference:check"); }
            }
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
            if ($copy{kind} eq 'directory') { $copy{recovery_close_ok} = CORE::closedir($handle) ? 1 : 0; }
            else {
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
        my $expected = $spec->{expectations}{$row->{binding}};
        my $returns = !defined($expected->{error});
        my $error = '';
        if (!$returns) {
            my $reason = $expected->{error};
            if ($reason->{kind} eq 'primary') {
                $error = "injected semantic close primary: $spec->{phase}:$reason->{event}\n";
            } else {
                my $kind = $reason->{label} =~ /^original:/ ? 'reference'
                    : $reason->{label} =~ /^fresh:/ ? 'fresh reference' : 'image input';
                local $! = $reason->{errno} eq 'EIO' ? EIO : ENOSPC;
                $error = "cannot close $kind: $!\n";
            }
        }
        my $open = grep { !$_->{closed_before_recovery} } @{$row->{handles}};
        my $expected_open = $mutant ? 1 : 0;
        my @closes = map { $_->{label} } @{$row->{close_calls}};
        my $behavior = $row->{returned} == ($returns ? 1 : 0) && $row->{error} eq $error
            && $row->{cut_fired} == (defined($spec->{cut}) ? 1 : 0)
            && $JSON->encode($row->{trace}) eq $JSON->encode($expected->{trace})
            && $JSON->encode(\@closes) eq $JSON->encode($expected->{closes});
        my $custody = $open == $expected_open && $row->{omitted_close_calls} == $expected_open
            && !grep({ !$_->{closed_after_recovery} || (defined($_->{recovery_close_ok}) && !$_->{recovery_close_ok})
                || ($_->{kind} eq 'source' && !$_->{cloexec})
                || ($_->{kind} eq 'directory' && (!$_->{observer_close_ok} || !$_->{observer_closed})) } @{$row->{handles}});
        ok($behavior, "$spec->{id}: exact executed prefix and outcome");
        ok($custody, "$spec->{id}: explicit descriptor disposition and close-report recovery");
        unless ($behavior && $custody) {
            $result->{first_failure} = $spec->{id}; save_qualification();
            diag($row->{error} || "open handles $open, expected $expected_open");
            BAIL_OUT('unexpected semantic close-report result');
        }
    }
}
is($forbidden, 0, 'no process attempt');
$result->{success} = JSON::PP::true; save_qualification(); save_result(); done_testing();
