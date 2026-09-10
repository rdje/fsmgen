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
    "$FindBin::Bin/../native-proxy-runtime-census-20260910",
    "$FindBin::Bin/../native-proxy-runtime-acquisition-20260910",
    "$FindBin::Bin/../native-proxy-cleanup-receipts-20260910", $FindBin::Bin;
use Digest::SHA qw(sha256_hex);
use Fcntl qw(S_ISDIR S_ISLNK S_ISREG);
use File::Spec;
use File::Temp ();
use JSON::PP ();
use POSIX ();
use Test::More;
use FSM::ProjectDataLocality qw(ensure_project_artifact_dir repository_root);
use FSM::Test::RustProxyFixture ();
BEGIN { *CORE::GLOBAL::exec = sub { ++$forbidden; die 'forbidden exec'; }; }
use ReferenceAcquisition;
use RuntimeRetirement;

my $ROOT = repository_root();
my $JSON = JSON::PP->new->canonical->ascii;
my $parent = ensure_project_artifact_dir(qw(tmp native-proxy-image-custody cases));
my $work_parent = ensure_project_artifact_dir(qw(tmp process-supervisor-tests));
my $log = ensure_project_artifact_dir(qw(logs native-proxy-runtime-retirement-20260910));
my $plan = $JSON->decode(read_bytes("$FindBin::Bin/plan.json"));
my $vectors = $JSON->decode(read_bytes("$FindBin::Bin/../native-proxy-image-custody-20260910/vectors.json"));
my ($C, $IMAGE) = map { pack('H*', $_) } @$vectors{qw(generated_c_hex image_hex)};
my $acquire = \&NativeProxyReferenceAcquisition::acquire_runtime_reference;
my $retire = \&NativeProxyRuntimeRetirement::retire_runtime_reference;
my $result = {schema => 'fsmgen.inactive_runtime_retirement_qualification.v1',
              success => JSON::PP::false, cuts => [], controls => [], mutants => {}, allocated => []};
write_bytes("$log/admission.jsonl", '', 0600);
no warnings 'redefine';
local *FSM::Test::RustProxyFixture::supervise_process = sub { ++$forbidden; die 'forbidden compiler'; };

sub read_bytes {
    open my $fh, '<:raw', $_[0] or die "read fixture: $!";
    my $bytes = do { local $/; <$fh> };
    close $fh or die "close fixture: $!";
    return $bytes;
}
sub write_bytes {
    my ($path, $bytes, $mode) = @_;
    chmod(0600, $path) == 1 or die $! if -e $path;
    open my $fh, '>:raw', $path or die "write fixture: $!";
    print {$fh} $bytes or die "write fixture bytes: $!";
    close $fh or die "close fixture bytes: $!";
    chmod($mode, $path) == 1 or die "fixture mode: $!";
}
sub save_result {
    $result->{forbidden_process_attempts} = $forbidden;
    write_bytes("$log/qualification.json", JSON::PP->new->canonical->ascii->pretty->encode($result), 0600);
}
sub allocate {
    my ($kind, $path) = @_;
    my @metadata = lstat("$path");
    my $row = {kind => $kind, path => File::Spec->abs2rel("$path", $ROOT), device => $metadata[0], inode => $metadata[1]};
    open my $fh, '>>:raw', "$log/admission.jsonl" or die $!;
    print {$fh} $JSON->encode($row), "\n" or die $!;
    close $fh or die $!;
    push @{$result->{allocated}}, $row;
    save_result();
}
sub cleanup_receipts {
    my $owner = sub { return {cleanup => {leader_started => 1, leader_reaped => 1, group_gone => 1}}; };
    return {compiler => $owner->(), outer => $owner->(), stages => [$owner->(), $owner->()]};
}
sub populate {
    my ($work) = @_;
    write_bytes("$work/rust-tool-resolution", 'inert wrapper; never executed', 0700);
    mkdir("$work/rust-tools/$_", 0700) or die $! for qw(compiler-cache compiler-temp);
    write_bytes("$work/rust-tools/compiler-cache/cache.dat", 'inert cache', 0400);
    write_bytes("$work/rust-tools/compiler-temp/scratch.dat", 'inert scratch', 0600);
    write_bytes("$work/rust-tools/rustup.c", $C, 0400);
    write_bytes("$work/rust-tools/rustup", $IMAGE, 0500);
    symlink('../../inert-dangling-target', "$work/rust-tools/cargo") or die $!;
}
sub context {
    my ($callback) = @_;
    my $store = File::Temp->newdir('fsmgen-XXXXXXXX', DIR => $parent, CLEANUP => 1);
    allocate('store', $store);
    my $case = File::Spec->abs2rel("$store", $ROOT);
    my (@work, @acquired);
    for (1, 2) {
        my $work = File::Temp->newdir('fsmgen-XXXXXXXX', DIR => $work_parent, CLEANUP => 1);
        allocate('workspace', $work);
        mkdir("$work/rust-tools", 0700) or die $!;
        my @metadata = stat("$work");
        my $identity = {path => File::Spec->abs2rel("$work", $ROOT), device => $metadata[0], inode => $metadata[1]};
        push @acquired, $acquire->($case, $identity, $C, $IMAGE);
        populate("$work");
        push @work, $work;
    }
    $callback->($case, \@acquired);
    my @paths = ("$store", map { "$_" } @work);
    @work = (); undef $store;
    die 'owned inert fixture residue' if grep { -e $_ || -l $_ } @paths;
    save_result();
}
# Independent physical census: direct lstat/readlink/reads, not the prototype's
# custody or deletion plan. It records hashes, native identities and file modes.
sub footprint {
    my ($base) = @_;
    return {} unless -e "$ROOT/$base" || -l "$ROOT/$base";
    my %nodes;
    my $walk;
    $walk = sub {
        my ($path, $relative) = @_;
        my @s = lstat("$ROOT/$path"); die 'oracle stat' unless @s;
        die 'oracle off-volume or oversized census' unless $s[0] == (stat($ROOT))[0] && keys(%nodes) < 512;
        my $entry = {device => $s[0], inode => $s[1], mode => $s[2] & 07777, uid => $s[4]};
        $nodes{$relative} = $entry;
        if (S_ISDIR($s[2])) {
            $entry->{kind} = 'directory';
            opendir my $dir, "$ROOT/$path" or die $!;
            my @names = sort grep { $_ ne '.' && $_ ne '..' } readdir $dir;
            closedir $dir or die $!;
            $walk->("$path/$_", length($relative) ? "$relative/$_" : $_) for @names;
        }
        elsif (S_ISLNK($s[2])) { $entry->{kind} = 'symlink'; $entry->{target} = readlink("$ROOT/$path"); }
        elsif (S_ISREG($s[2])) {
            die 'oracle file ceiling' if $s[7] > 65537;
            my $bytes = read_bytes("$ROOT/$path");
            $entry->{kind} = 'file'; $entry->{bytes} = length($bytes);
            $entry->{sha256} = sha256_hex($bytes); $entry->{links} = $s[3];
        }
        else { $entry->{kind} = 'special'; }
    };
    $walk->($base, '');
    return \%nodes;
}
sub workspace { return $_[0]{reference}{record}{workspace}; }
sub global_present { return (-e "$ROOT/$_[0]{reference}{global}{identity}{path}" || -l "$ROOT/$_[0]{reference}{global}{identity}{path}") ? 1 : 0; }
sub image_footprint { return footprint("$_[0]/images"); }
sub prior_footprint {
    my ($a) = @_;
    return {workspace => footprint(workspace($a)), global => footprint($a->{reference}{global}{identity}{path})};
}

save_result();
for my $case_plan (@{$plan->{cases}}) {
    context(sub {
        my ($case, $a) = @_;
        my ($prior, $target) = @$a;
        my $work = workspace($target);
        my $row = {name => $case_plan->{name}, case => $case, workspace => $work,
                   prior_workspace => workspace($prior), before => footprint($work),
                   prior_before => prior_footprint($prior), image_before => image_footprint($case), trace => []};
        my $step = sub {
            my ($path, $phase) = @_;
            my $relative = $path eq $target->{reference}{global}{identity}{path} ? 'GLOBAL'
                : $path eq $work ? '' : substr($path, length($work) + 1);
            my $entry = {path => $relative, phase => $phase};
            push @{$row->{trace}}, $entry;
            die "selected retirement cut\n" if defined($case_plan->{cut})
                && $JSON->encode($entry) eq $JSON->encode($case_plan->{cut});
        };
        my $unlink = \&NativeProxyPrivateWorkspace::_unlink;
        my $rmdir = \&NativeProxyPrivateWorkspace::_rmdir;
        my $global = \&NativeProxyRuntimeRetirement::_unlink_global;
        local *NativeProxyPrivateWorkspace::_unlink = sub { $step->($_[0], 'before'); $unlink->(@_); $step->($_[0], 'after'); };
        local *NativeProxyPrivateWorkspace::_rmdir = sub { $step->($_[0], 'before'); $rmdir->(@_); $step->($_[0], 'after'); };
        local *NativeProxyRuntimeRetirement::_unlink_global = sub { $step->($_[0], 'before'); $global->(@_); $step->($_[0], 'after'); };
        my $value; eval { $value = $retire->($case, $target, cleanup_receipts()); 1 }; $row->{error} = $@;
        $row->{returned} = defined($value) ? 1 : 0; $row->{result} = $value;
        $row->{after} = footprint($work); $row->{remaining} = [sort keys %{$row->{after}}];
        $row->{global_retained} = global_present($target);
        $row->{prior_after} = prior_footprint($prior); $row->{image_after} = image_footprint($case);
        push @{$result->{cuts}}, $row; save_result();
        my $pass = $row->{returned} == $case_plan->{returned}
            && $row->{error} eq ($case_plan->{returned} ? '' : "selected retirement cut\n")
            && $row->{global_retained} == $case_plan->{global_retained}
            && $JSON->encode($row->{trace}) eq $JSON->encode($case_plan->{trace})
            && $JSON->encode($row->{remaining}) eq $JSON->encode($case_plan->{remaining})
            && $JSON->encode($row->{prior_before}) eq $JSON->encode($row->{prior_after})
            && $JSON->encode($row->{image_before}) eq $JSON->encode($row->{image_after});
        ok($pass, "retirement boundary: $case_plan->{name}") or do { diag($row->{error}); BAIL_OUT('first unexpected retirement cut retained'); };
    });
}

sub reject_case {
    my ($name, $prepare, $diagnostic) = @_;
    context(sub {
        my ($case, $a) = @_;
        my $target = $a->[1]; my $cleanup = cleanup_receipts();
        $prepare->($case, $target, $cleanup);
        my $row = {name => $name, before => {store => footprint($case), workspace => footprint(workspace($target))}};
        my $value; my $ok = eval { $value = $retire->($case, $target, $cleanup); 1 }; my $error = $@;
        $row->{rejected} = $ok ? 0 : 1; $row->{returned} = defined($value) ? 1 : 0;
        $row->{expected_diagnostic} = $error =~ $diagnostic ? 1 : 0;
        $row->{after} = {store => footprint($case), workspace => footprint(workspace($target))};
        push @{$result->{controls}}, $row; save_result();
        ok(!$ok && !$row->{returned} && $row->{expected_diagnostic}
            && $JSON->encode($row->{before}) eq $JSON->encode($row->{after}), $name)
            or do { diag($error || 'unexpected acceptance'); BAIL_OUT('first unexpected rejection retained'); };
    });
}
sub replace_file {
    my ($path) = @_;
    my $bytes = read_bytes("$ROOT/$path");
    my $old = "$ROOT/${path}.old";
    die 'replacement backup exists' if -e $old || -l $old;
    rename("$ROOT/$path", $old) or die $!;
    write_bytes("$ROOT/$path", $bytes, 0400);
    unlink($old) == 1 or die $!;
}
sub replace_workspace {
    my ($target) = @_;
    my $path = "$ROOT/" . workspace($target);
    die 'workspace backup exists' if -e "${path}_old" || -l "${path}_old";
    rename($path, "${path}_old") or die $!;
    mkdir($path, 0700) or die $!;
    rename("${path}_old/$_", "$path/$_") or die $! for qw(rust-tools rust-tool-resolution);
    rmdir("${path}_old") or die $!;
}
reject_case('unsettled compiler', sub { $_[2]{compiler}{cleanup}{group_gone} = 0 }, qr/cleanup is unproved/);
reject_case('missing outer', sub { $_[2]{outer} = undef }, qr/cleanup is unproved/);
reject_case('missing inner stages', sub { $_[2]{stages} = [] }, qr/cleanup is unproved/);
reject_case('same-byte global replacement', sub { replace_file($_[1]{reference}{global}{identity}{path}) }, qr/global reference is absent or changed/);
reject_case('same-byte private replacement', sub { replace_file($_[1]{reference}{private}{identity}{path}) }, qr/reference differs from acquired/);
reject_case('replaced acquired workspace', sub { replace_workspace($_[1]) }, qr/workspace root differs/);
reject_case('unknown node spelling', sub { write_bytes("$ROOT/".workspace($_[1]).'/unknown name', 'inert', 0400) }, qr/member spelling/);
reject_case('special FIFO', sub { POSIX::mkfifo("$ROOT/".workspace($_[1]).'/fifo', 0600) == 0 or die $! }, qr/not a private regular file/);
reject_case('shared file links', sub { my $p="$ROOT/".workspace($_[1]); link("$p/rust-tools/rustup.c", "$p/alias") or die $! }, qr/shared links/);
reject_case('file byte ceiling', sub { write_bytes("$ROOT/".workspace($_[1]).'/big', 'x' x 65537, 0400) }, qr/(?:bound|size|large)/);
reject_case('node ceiling', sub { my $p="$ROOT/".workspace($_[1]); write_bytes("$p/node$_", 'x', 0400) for 1..256 }, qr/(?:namespace capacity|node ceiling)/);
reject_case('depth ceiling', sub { my $p="$ROOT/".workspace($_[1]); for (1..9) { $p.='/deep'; mkdir($p,0700) or die $! } }, qr/depth exceeded/);
reject_case('aggregate byte ceiling', sub { my $p="$ROOT/".workspace($_[1]); write_bytes("$p/large$_", 'x' x 65536, 0400) for 1..64 }, qr/byte ceiling exceeded/);
reject_case('absent lock cannot be recreated', sub { unlink("$ROOT/$_[0]/coordination.lock") == 1 or die $! }, qr/existing retirement lock/);
reject_case('absent namespace cannot be recreated', sub { rename("$ROOT/$_[0]/references", "$ROOT/$_[0]/references_saved") or die $! }, qr/unknown store member/);
reject_case('wrong lock identity', sub { $_[1]{lock}{inode} += 1 }, qr/lock differs/);
reject_case('changed acquired image', sub { write_bytes("$ROOT/$_[1]{image}{snapshots}[0]{identity}{path}", 'changed', 0400) }, qr/(?:differs|match)/);
reject_case('unknown acquisition field', sub { $_[1]{extra} = 1 }, qr/closed record/);
context(sub {
    my ($case, $a) = @_;
    my $before = {store => footprint($case), workspace => footprint(workspace($a->[1]))};
    my $ok = eval { NativeProxyRuntimeRetirement::_retire_locked({}); 1 }; my $error = $@;
    my $after = {store => footprint($case), workspace => footprint(workspace($a->[1]))};
    push @{$result->{controls}}, {name => 'direct retirement bypass', before => $before, after => $after,
        rejected => $ok ? 0 : 1, returned => 0, expected_diagnostic => $error =~ /sealed coordinator/ ? 1 : 0};
    save_result(); ok(!$ok && $error =~ /sealed coordinator/ && $JSON->encode($before) eq $JSON->encode($after), 'direct retirement bypass') or BAIL_OUT('caller bypass');
});
$result->{late_changes} = [];
for my $name (qw(changed_file replaced_file new_member replaced_root partial_new_member reappeared_root replaced_global)) {
    context(sub {
        my ($case, $a) = @_;
        my $target = $a->[1]; my $work = workspace($target);
        my $row = {name => $name, prior_before => prior_footprint($a->[0]), image_before => image_footprint($case)};
        my $remove = \&NativeProxyPrivateWorkspace::_remove;
        my $unlink = \&NativeProxyPrivateWorkspace::_unlink;
        my $rmdir = \&NativeProxyPrivateWorkspace::_rmdir;
        my $release = \&NativeProxyRuntimeRetirement::_release_locked;
        my $injected = 0;
        local *NativeProxyPrivateWorkspace::_remove = sub {
            if ($name eq 'changed_file') { write_bytes("$ROOT/$work/rust-tools/rustup.c", 'changed after admission', 0400); }
            elsif ($name eq 'replaced_file') { replace_file("$work/rust-tools/rustup.c"); }
            elsif ($name eq 'new_member') { write_bytes("$ROOT/$work/late-added", 'late', 0400); }
            elsif ($name eq 'replaced_root') { replace_workspace($target); }
            $row->{injected} = footprint($work) if $name =~ /\A(?:changed_file|replaced_file|new_member|replaced_root)\z/;
            goto &$remove;
        };
        local *NativeProxyPrivateWorkspace::_unlink = sub {
            $unlink->(@_);
            if ($name eq 'partial_new_member' && !$injected++) {
                write_bytes("$ROOT/$work/late-added", 'late', 0400);
            }
        };
        local *NativeProxyPrivateWorkspace::_rmdir = sub {
            $rmdir->(@_);
            if ($name eq 'reappeared_root' && $_[0] eq $work) {
                mkdir("$ROOT/$work", 0700) or die $!;
                $row->{injected} = footprint($work);
            }
        };
        local *NativeProxyRuntimeRetirement::_release_locked = sub {
            replace_file($target->{reference}{global}{identity}{path}) if $name eq 'replaced_global';
            goto &$release;
        };
        my $value; my $ok = eval { $value = $retire->($case, $target, cleanup_receipts()); 1 }; my $error = $@;
        $row->{rejected} = $ok ? 0 : 1; $row->{returned} = defined($value) ? 1 : 0;
        my $diagnostic = $name eq 'partial_new_member' ? qr/cannot remove owned workspace directory/
            : $name eq 'reappeared_root' ? qr/removed workspace node is still present/
            : $name eq 'replaced_global' ? qr/reference differs from acquired/
            : qr/workspace contents or identity changed/;
        $row->{expected_diagnostic} = $error =~ $diagnostic ? 1 : 0;
        $row->{after} = footprint($work); $row->{global_retained} = global_present($target);
        $row->{prior_after} = prior_footprint($a->[0]); $row->{image_after} = image_footprint($case);
        push @{$result->{late_changes}}, $row; save_result();
        ok(!$ok && !$row->{returned} && $row->{expected_diagnostic} && $row->{global_retained}
            && $JSON->encode($row->{prior_before}) eq $JSON->encode($row->{prior_after})
            && $JSON->encode($row->{image_before}) eq $JSON->encode($row->{image_after}), "late change: $name")
            or do { diag($error || 'unexpected acceptance'); BAIL_OUT('first late-change failure retained'); };
    });
}
$result->{positives} = [];
for my $name (qw(node_ceiling depth_ceiling byte_ceiling symlink_target)) {
    context(sub {
        my ($case, $a) = @_;
        my $target = $a->[1]; my $work = workspace($target);
        if ($name eq 'node_ceiling') { write_bytes("$ROOT/$work/padding$_", 'x', 0400) for 1..245; }
        elsif ($name eq 'depth_ceiling') { my $p="$ROOT/$work"; for (1..8) { $p.='/deep'; mkdir($p,0700) or die $! } }
        elsif ($name eq 'byte_ceiling') {
            my $before = footprint($work); my $remaining = 4_194_304;
            $remaining -= $_->{bytes} for grep { $_->{kind} eq 'file' } values %$before;
            my $index = 0;
            while ($remaining) {
                my $count = $remaining > 65536 ? 65536 : $remaining;
                write_bytes("$ROOT/$work/padding" . ++$index, 'x' x $count, 0400);
                $remaining -= $count;
            }
        }
        else {
            unlink("$ROOT/$work/rust-tools/cargo") == 1 or die $!;
            my $target_path = File::Spec->abs2rel("$ROOT/".workspace($a->[0]), "$ROOT/$work/rust-tools");
            symlink($target_path, "$ROOT/$work/rust-tools/cargo") or die $!;
        }
        my $row = {name => $name, before => footprint($work), prior_before => prior_footprint($a->[0]), image_before => image_footprint($case)};
        my $value = $retire->($case, $target, cleanup_receipts());
        $row->{result} = $value; $row->{after} = footprint($work); $row->{global_retained} = global_present($target);
        $row->{prior_after} = prior_footprint($a->[0]); $row->{image_after} = image_footprint($case);
        push @{$result->{positives}}, $row; save_result();
        ok(!keys(%{$row->{after}}) && !$row->{global_retained}
            && $JSON->encode($row->{prior_before}) eq $JSON->encode($row->{prior_after})
            && $JSON->encode($row->{image_before}) eq $JSON->encode($row->{image_after}), "positive boundary: $name")
            or BAIL_OUT('first positive boundary failure retained');
    });
}
context(sub {
    my ($case, $a) = @_;
    my $row = {image_before => image_footprint($case)};
    $retire->($case, $_, cleanup_receipts()) for @$a;
    $row->{image_after} = image_footprint($case);
    $row->{references_remaining} = scalar(keys %{footprint("$case/references")}) - 1;
    $row->{workspace_absent} = !keys(%{footprint(workspace($a->[0]))}) && !keys(%{footprint(workspace($a->[1]))}) ? 1 : 0;
    $result->{last_owner} = $row; save_result();
    ok(!$row->{references_remaining} && $row->{workspace_absent} && $JSON->encode($row->{image_before}) eq $JSON->encode($row->{image_after}), 'last owner release preserves complete shared image') or BAIL_OUT('last owner');
});
context(sub {
    my ($case, $a) = @_;
    my $cleanup = cleanup_receipts(); $cleanup->{compiler}{cleanup}{group_gone} = 0;
    local *NativeProxyCleanupReceipts::cleanup_receipts_settled = sub { 1 };
    my $value = $retire->($case, $a->[1], $cleanup);
    my $row = {returned => defined($value) ? 1 : 0, global_retained => global_present($a->[1]),
               workspace_absent => !keys(%{footprint(workspace($a->[1]))}) ? 1 : 0, compiler_group_gone => 0};
    $result->{mutants}{'omitted cleanup review'} = $row; save_result();
    ok($row->{returned} && !$row->{global_retained} && $row->{workspace_absent}, 'omitted cleanup admits independently unsettled compiler') or BAIL_OUT('cleanup mutant');
});
context(sub {
    my ($case, $a) = @_;
    my $target = $a->[1]; my $prior_inode = $target->{reference}{record}{workspace_identity}{inode};
    replace_workspace($target);
    my @current = stat("$ROOT/".workspace($target));
    my $capture = \&NativeProxyPrivateWorkspace::_capture;
    local *NativeProxyPrivateWorkspace::_capture = sub {
        $_[0] = {path => $_[0]{path}, device => $current[0], inode => $current[1]};
        goto &$capture;
    };
    my $value = $retire->($case, $target, cleanup_receipts());
    my $row = {returned => defined($value) ? 1 : 0, global_retained => global_present($target),
               workspace_absent => !keys(%{footprint(workspace($target))}) ? 1 : 0,
               prior_inode => $prior_inode, current_inode => $current[1]};
    $result->{mutants}{'discarded prior workspace identity'} = $row; save_result();
    ok($row->{returned} && !$row->{global_retained} && $row->{workspace_absent} && $prior_inode != $current[1], 'discarded prior identity deletes independently replaced workspace') or BAIL_OUT('identity mutant');
});
is($forbidden, 0, 'no compiler or process attempt');
$result->{success} = Test::More->builder->is_passing ? JSON::PP::true : JSON::PP::false;
save_result(); done_testing;
