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
        native-proxy-runtime-acquisition-20260910);
use Digest::SHA qw(sha256_hex);
use Fcntl qw(S_ISDIR S_ISLNK S_ISREG F_GETFD FD_CLOEXEC);
use File::Spec;
use File::Temp ();
use JSON::PP ();
use Test::More;
use FSM::ProjectDataLocality qw(ensure_project_artifact_dir repository_root);
use FSM::Test::RustProxyFixture ();
BEGIN { *CORE::GLOBAL::exec = sub { ++$forbidden; die 'forbidden exec'; }; }
use ReferenceAcquisition;
use ObservationAcquisition;

my $ROOT = repository_root();
my $JSON = JSON::PP->new->canonical->ascii;
my $parent = ensure_project_artifact_dir(qw(tmp native-proxy-image-custody cases));
my $work_parent = ensure_project_artifact_dir(qw(tmp process-supervisor-tests));
my $evidence_parent = ensure_project_artifact_dir(qw(logs native-proxy-observation-acquisition-20260910 cases));
my $log = ensure_project_artifact_dir(qw(logs native-proxy-observation-acquisition-20260910));
my $plan = $JSON->decode(read_bytes("$FindBin::Bin/plan.json"));
my $vector = $JSON->decode(read_bytes("$FindBin::Bin/../native-proxy-image-custody-20260910/vectors.json"));
my ($C, $IMAGE) = map { pack('H*', $_) } @$vector{qw(generated_c_hex image_hex)};
my $WRAPPER = "#!/usr/bin/perl\n# inert observation wrapper; never executed\n";
my $acquire = \&NativeProxyObservationAcquisition::acquire_observation_reference;
my $source_reader = \&NativeProxyImageCustody::_source;
my $finish = \&NativeProxyObservationAcquisition::_finish_locked;
my $prior_directory = \&NativeProxyObservationAcquisition::_prior_directory;
my $result = {schema => 'fsmgen.inactive_observation_acquisition_qualification.v1',
    success => JSON::PP::false, allocated => [], cases => [], late_changes => [], mutants => []};
write_bytes("$log/admission.jsonl", '', 0600);
no warnings 'redefine';
local *FSM::Test::RustProxyFixture::supervise_process = sub { ++$forbidden; die 'forbidden compiler'; };

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
sub clone { return $JSON->decode($JSON->encode($_[0])); }
sub save_result {
    $result->{forbidden_process_attempts} = $forbidden;
    write_bytes("$log/qualification.json", JSON::PP->new->canonical->ascii->pretty->encode($result), 0600);
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
sub context {
    my ($callback) = @_;
    my @temporary;
    my $context = {};
    for my $spec ([store => $parent], [workspace => $work_parent],
                  [other_workspace => $work_parent], [evidence => $evidence_parent]) {
        my $directory = File::Temp->newdir('fsmgen-XXXXXXXX', DIR => $spec->[1], CLEANUP => 1);
        push @temporary, $directory;
        my $kind = $spec->[0] eq 'other_workspace' ? 'workspace' : $spec->[0];
        $context->{$spec->[0]} = allocate($kind, $directory);
    }
    my $case = $context->{store}{path};
    for my $kind (qw(workspace other_workspace)) {
        my $path = $context->{$kind}{path}; mkdir("$ROOT/$path/rust-tools", 0700) or die $!;
        write_bytes("$ROOT/$path/rust-tool-resolution", $WRAPPER, 0700);
        my $suffix = $kind eq 'workspace' ? '' : 'other';
        $context->{$kind eq 'workspace' ? 'runtime' : 'other_runtime'} =
            NativeProxyReferenceAcquisition::acquire_runtime_reference($case, identity($context->{$kind}), $C, $IMAGE.$suffix);
    }
    $context->{request} = {workspace_identity => identity($context->{workspace}),
        evidence_directory_identity => identity($context->{evidence}),
        observer_birth => {pid => 101, ppid => 100, uid => 501, ruid => 501, start_sec => 123, start_usec => 456},
        target_birth => {pid => 201, ppid => 200, uid => 501, ruid => 501, start_sec => 124, start_usec => 789}};
    $callback->($context);
    @temporary = ();
    for my $kind (qw(store workspace other_workspace evidence)) {
        my $path = "$ROOT/$context->{$kind}{path}";
        die 'inert observation allocation remains' if -e $path || -l $path;
    }
    save_result();
}
sub observation_record {
    my ($context, $offset) = @_;
    my $request = clone($context->{request}); $request->{target_birth}{pid} += $offset // 0;
    my $record = {schema => 'fsmgen.test.rust_proxy_image_observation_reference.v1',
        image_key => $context->{runtime}{image}{key},
        evidence_directory => $request->{evidence_directory_identity}{path},
        evidence_directory_identity => $request->{evidence_directory_identity},
        observer_birth => $request->{observer_birth}, target_birth => $request->{target_birth},
        selected_sources => clone($context->{runtime}{reference}{record}{selected_sources})};
    $record->{reference_key} = NativeProxyImageCustody::observation_reference_key(
        @$record{qw(evidence_directory observer_birth target_birth)});
    return $record;
}
sub add_observation {
    my ($context, $offset) = @_; my $record = observation_record($context, $offset);
    my $case = $context->{store}{path};
    write_bytes("$ROOT/$case/references/$record->{reference_key}.json",
        NativeProxyObservationRecord::encode_observation_record($case, $record), 0400);
}
sub replace_file {
    my ($path, $mode) = @_; my $raw = read_bytes($path);
    rename($path, "$path.old") or die $!;
    write_bytes($path, $raw, $mode); unlink("$path.old") or die $!;
}
sub replace_directory {
    my ($path) = @_;
    rename($path, "$path.old") or die $!; mkdir($path, 0700) or die $!;
    opendir my $directory, "$path.old" or die $!;
    my @names = grep { $_ ne '.' && $_ ne '..' } readdir $directory;
    closedir $directory or die $!;
    rename("$path.old/$_", "$path/$_") or die $! for @names;
    rmdir("$path.old") or die $!;
}
sub evaluate {
    my ($context, $row, $callback, $source_hook) = @_;
    my @held;
    my $ok = eval {
        local *NativeProxyImageCustody::_source = sub {
            my $owned = caller eq 'NativeProxyObservationAcquisition';
            my $source = $source_reader->(@_);
            if ($owned) {
                my $flags = fcntl($source->{handle}, F_GETFD, 0);
                push @held, {handle => $source->{handle}, descriptor => fileno($source->{handle}),
                    path => File::Spec->abs2rel($source->{path}, $ROOT),
                    cloexec => defined($flags) && ($flags & FD_CLOEXEC) ? 1 : 0};
                $source_hook->($source) if $source_hook;
            }
            return $source;
        };
        $row->{result} = $callback->(); 1;
    };
    my $error = $@; $error =~ s/\Q$ROOT\E/./g;
    $row->{error} = $error;
    $row->{returned} = $ok && defined($row->{result}) ? 1 : 0;
    $row->{descriptors} = [map { +{path => $_->{path}, descriptor => $_->{descriptor}, cloexec => $_->{cloexec},
        closed => defined(fileno($_->{handle})) ? 0 : 1} } @held];
    $row->{after} = footprint($context);
    # Keep intercepted handle references alive until after this assertion, so
    # garbage collection cannot substitute for the operation's explicit close.
    ok(!grep({ !$_->{closed} || !$_->{cloexec} } @{$row->{descriptors}}), "$row->{name}: retained descriptors close")
        or do { $result->{first_failure} = $row; save_result(); BAIL_OUT('observation descriptor custody failed'); };
    return $ok;
}
sub initial_row {
    my ($context, $name) = @_;
    return {name => $name, context => clone($context), before => footprint($context)};
}
save_result();
for my $case (@{$plan->{cases}}) {
    context(sub {
        my ($context) = @_; my $name = $case->{name}; my $request = clone($context->{request});
        my $workspace = "$ROOT/$context->{workspace}{path}";
        my $store = "$ROOT/$context->{store}{path}";
        my $private = "$ROOT/$context->{runtime}{reference}{private}{identity}{path}";
        my $global = "$ROOT/$context->{runtime}{reference}{global}{identity}{path}";
        my @args = ($context->{store}{path}, $request);
        my $callback = sub { $acquire->(@args) };
        if ($name eq 'wrapper exact byte ceiling') { write_bytes("$workspace/rust-tool-resolution", 'W' x 65536, 0700); }
        elsif ($name eq 'prior workspace identity mismatch') { $request->{workspace_identity}{inode}++; }
        elsif ($name eq 'prior evidence identity mismatch') { $request->{evidence_directory_identity}{inode}++; }
        elsif ($name eq 'missing existing lock') { unlink("$store/coordination.lock") or die $!; }
        elsif ($name eq 'missing existing namespace') {
            unlink("$ROOT/$_->{reference}{global}{identity}{path}") or die $!
                for @$context{qw(runtime other_runtime)};
            rmdir("$store/references") or die $!;
        } elsif ($name eq 'missing runtime reference') { unlink($global) or die $!; }
        elsif ($name eq 'mismatched private/global runtime bytes') {
            my $record = clone($context->{runtime}{reference}{record}); $record->{workspace_identity}{inode}++;
            write_bytes($private, $JSON->encode($record), 0400);
        } elsif ($name eq 'stale canonical runtime source identity') {
            my $record = clone($context->{runtime}{reference}{record}); $record->{selected_sources}[0]{inode}++;
            write_bytes($_, $JSON->encode($record), 0400) for ($global, $private);
        } elsif ($name eq 'foreign runtime workspace') {
            my $record = clone($context->{runtime}{reference}{record}); $record->{workspace_identity}{path} .= 'Other';
            write_bytes($global, $JSON->encode($record), 0400);
        } elsif ($name eq 'reference capacity before publication') { add_observation($context, 1000+$_) for 0..125; }
        elsif ($name eq 'existing observation hold') { add_observation($context, 0); }
        elsif ($name eq 'wrapper symlink') {
            unlink("$workspace/rust-tool-resolution") or die $!;
            symlink('rust-tools/image-reference.json', "$workspace/rust-tool-resolution") or die $!;
        } elsif ($name eq 'wrapper hardlink') {
            link("$workspace/rust-tool-resolution", "$workspace/wrapper-alias") or die $!;
        } elsif ($name eq 'wrapper wrong mode') { chmod(0600, "$workspace/rust-tool-resolution") == 1 or die $!; }
        elsif ($name eq 'wrapper byte excess') { write_bytes("$workspace/rust-tool-resolution", 'W' x 65537, 0700); }
        elsif ($name eq 'extra request field') { $request->{extra} = 0; }
        elsif ($name eq 'malformed birth') { $request->{observer_birth}{uid} = JSON::PP::true; }
        elsif ($name eq 'foreign evidence path') { $request->{evidence_directory_identity}{path} = '.artifacts/logs/foreign'; }
        elsif ($name eq 'extra argument') { push @args, 'extra'; }
        elsif ($name eq 'direct internal caller') {
            $callback = sub { NativeProxyObservationAcquisition::_admit_locked($context->{store}{path}, {}, $request) };
        } elsif ($name ne 'fresh acquisition') { die "unknown planned case $name"; }
        my $row = initial_row($context, $name); $row->{request} = clone($request);
        my $ok = evaluate($context, $row, $callback);
        $row->{request_after} = clone($request);
        if ($case->{kind} eq 'success') {
            $row->{diagnostic_matched} = $row->{error} eq '' ? 1 : 0;
            ok($ok && $row->{returned} && @{$row->{result}{target_sources}} == 5
                && @{$row->{descriptors}} >= 5, "$name returns separate hold and retained target sources")
                or do { push @{$result->{cases}}, $row; save_result(); diag($row->{error}); BAIL_OUT('fresh acquisition failed'); };
        } else {
            $row->{diagnostic_matched} = index($row->{error}, $case->{diagnostic}) >= 0 ? 1 : 0;
            ok(!$ok && !$row->{returned} && $row->{diagnostic_matched}
                && $JSON->encode($row->{before}) eq $JSON->encode($row->{after}), "$name rejects without mutation")
                or do { push @{$result->{cases}}, $row; save_result(); diag($row->{error} || 'unexpected acceptance'); BAIL_OUT('first acquisition rejection mismatch'); };
        }
        push @{$result->{cases}}, $row; save_result();
    });
}
for my $case (@{$plan->{late_cases}}) {
    context(sub {
        my ($context) = @_; my $name = $case->{name}; my $row = initial_row($context, $name);
        my $workspace = "$ROOT/$context->{workspace}{path}"; my $fired = 0;
        my $inject = sub {
            return if $fired++;
            if ($name eq 'source directory replacement') { replace_directory("$workspace/rust-tools"); }
            elsif ($name eq 'source replacement during admission') { replace_file("$workspace/rust-tool-resolution", 0700); }
            elsif ($name eq 'source bytes changed before return') { write_bytes("$workspace/rust-tool-resolution", $WRAPPER.'changed', 0700); }
            elsif ($name eq 'late evidence directory replacement') { replace_directory("$ROOT/$context->{evidence}{path}"); }
            elsif ($name eq 'late workspace directory replacement') { replace_directory($workspace); }
            elsif ($name eq 'sealed observation replacement') {
                my $record = observation_record($context, 0);
                replace_file("$ROOT/$context->{store}{path}/references/$record->{reference_key}.json", 0400);
            } else { die 'unknown planned late mutation'; }
            $row->{injected} = footprint($context);
        };
        my $callback = sub { $acquire->($context->{store}{path}, $context->{request}) };
        my $ok;
        if ($case->{phase} eq 'finish') {
            local *NativeProxyObservationAcquisition::_finish_locked = sub {
                $row->{before_injection} = footprint($context);
                $inject->(); goto &$finish;
            };
            $ok = evaluate($context, $row, $callback);
        } else {
            $ok = evaluate($context, $row, $callback, sub {
                $inject->() if $_[0]{path} eq "$workspace/rust-tool-resolution";
            });
        }
        $row->{diagnostic_matched} = $row->{error} =~ /(?:changed|identity differs)/ ? 1 : 0;
        push @{$result->{late_changes}}, $row; save_result();
        ok(!$ok && !$row->{returned} && $row->{diagnostic_matched} && $fired
            && $JSON->encode($row->{injected}) eq $JSON->encode($row->{after}), "$name fails while preserving observed partial state")
            or do { diag($row->{error} || 'unexpected acceptance'); BAIL_OUT('late observation change not detected'); };
    });
}
for my $name (@{$plan->{mutants}}) {
    context(sub {
        my ($context) = @_; my $request = clone($context->{request});
        $request->{evidence_directory_identity}{inode}++ if $name eq 'discard prior evidence identity';
        my $row = initial_row($context, $name); $row->{request} = clone($request);
        my $callback = sub { $acquire->($context->{store}{path}, $request) }; my $ok;
        if ($name eq 'discard prior evidence identity') {
            local *NativeProxyObservationAcquisition::_prior_directory = sub {
                return NativeProxyImageCustody::_directory("$ROOT/$_[0]{path}");
            };
            $ok = evaluate($context, $row, $callback);
        } elsif ($name eq 'discard retained source identity') {
            local *NativeProxyObservationAcquisition::_source_closure = sub { return };
            local *NativeProxyObservationAcquisition::_finish_locked = sub {
                replace_file("$ROOT/$context->{workspace}{path}/rust-tool-resolution", 0700);
                $row->{injected} = footprint($context); goto &$finish;
            };
            $ok = evaluate($context, $row, $callback);
        } else { die 'unknown planned mutant'; }
        push @{$result->{mutants}}, $row; save_result();
        ok($ok && $row->{returned}, "$name admits independently invalid custody")
            or do { diag($row->{error}); BAIL_OUT('observation mutant did not reach return'); };
    });
}
is($forbidden, 0, 'no compiler or fixture process attempt');
$result->{success} = Test::More->builder->is_passing ? JSON::PP::true : JSON::PP::false;
save_result();
done_testing;
