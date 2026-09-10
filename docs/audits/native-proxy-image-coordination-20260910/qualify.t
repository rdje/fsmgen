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
    "$FindBin::Bin/../native-proxy-image-custody-20260910", $FindBin::Bin;
use Digest::SHA qw(sha256_hex);
use Errno qw(EAGAIN EIO);
use Fcntl qw(F_GETFD FD_CLOEXEC);
use File::Spec;
use File::Temp ();
use JSON::PP ();
use POSIX ();
use Test::More;
use FSM::ProjectDataLocality qw(ensure_project_artifact_dir repository_root);
use FSM::Test::RustProxyFixture ();
BEGIN { *CORE::GLOBAL::exec = sub { ++$forbidden; die 'forbidden exec'; }; }
use Coordination;

my $root = repository_root();
my $parent = ensure_project_artifact_dir(qw(tmp native-proxy-image-custody cases));
my $logs = ensure_project_artifact_dir(qw(logs native-proxy-image-coordination-20260910));
my @retired;
my @controls;
my $positive;
my $inspect = \&NativeProxyImageCoordination::inspect_store;
no warnings 'redefine';
local *FSM::Test::RustProxyFixture::supervise_process = sub { ++$forbidden; die 'forbidden compiler'; };

sub write_bytes {
    my ($path, $bytes, $mode) = @_;
    open my $fh, '>:raw', $path or die "write: $!";
    print {$fh} $bytes or die "write bytes: $!";
    close $fh or die "close: $!";
    chmod($mode, $path) or die "chmod: $!";
}
sub with_case {
    my ($callback) = @_;
    my $work = File::Temp->newdir('fsmgen-XXXXXXXX', DIR => $parent, CLEANUP => 1);
    my $case = File::Spec->abs2rel("$work", $root);
    $callback->($case, "$work");
    undef $work;
    die 'inert case remains' if -e "$root/$case" || -l "$root/$case";
    push @retired, $case;
}
sub rejects {
    my ($name, $callback, $expected) = @_;
    my $ok = eval { $callback->(); 1 };
    my $error = $@;
    ok(!$ok && $error =~ $expected, $name) or diag($error || 'unexpected success');
    push @controls, {name => $name, rejected => $ok ? 0 : 1,
        expected_diagnostic => $error =~ $expected ? 1 : 0};
}

with_case(sub {
    my ($case, $path) = @_;
    my $open = \&NativeProxyImageCoordination::_open_lock;
    my @handles;
    local *NativeProxyImageCoordination::_open_lock = sub {
        my $handle = $open->(@_); push @handles, $handle; return $handle;
    };
    my $census = \&NativeProxyImageCoordination::_census;
    local *NativeProxyImageCoordination::_census = sub {
        ok(fcntl($handles[-1], F_GETFD, 0) & FD_CLOEXEC, 'lock descriptor is close-on-exec while held');
        return $census->(@_);
    };
    $positive = $inspect->($case);
    is_deeply($positive->{images}, [], 'empty image namespace');
    is_deeply($positive->{references}, [], 'empty reference namespace');
    is($positive->{lock}{inode}, (lstat("$path/coordination.lock"))[1], 'actual named lock identity retained');
    is($positive->{lock}{device}, (stat($root))[0], 'lock stays on repository volume');
    is((lstat("$path/coordination.lock"))[2] & 07777, 0600, 'permanent lock has exact mode');
    is((lstat("$path/coordination.lock"))[7], 0, 'permanent lock stays empty');
    ok(!defined(fileno($handles[-1])), 'success closes lock descriptor');
    is_deeply($inspect->($case), $positive, 'existing store reuses exact permanent lock');
    ok(!defined(fileno($handles[-1])), 'repeated success closes descriptor');
    rejects('no caller callback accepted', sub { $inspect->($case, sub { die 'caller callback ran' }) }, qr/expected one inactive/);
});

my @bad_lock = (
    ['wrong lock mode', sub { write_bytes("$_[0]/coordination.lock", '', 0644) }, qr/lock identity/],
    ['nonempty lock', sub { write_bytes("$_[0]/coordination.lock", 'changed', 0600) }, qr/lock identity/],
    ['hard-linked lock', sub { write_bytes("$_[0]/coordination.lock", '', 0600); link("$_[0]/coordination.lock", "$_[0]/alias") or die $! }, qr/lock identity/],
    ['symlink lock', sub { write_bytes("$_[0]/target", '', 0600); symlink('target', "$_[0]/coordination.lock") or die $! }, qr/existing permanent lock/],
    ['directory lock', sub { mkdir("$_[0]/coordination.lock", 0700) or die $! }, qr/existing permanent lock/],
    ['FIFO lock', sub { POSIX::mkfifo("$_[0]/coordination.lock", 0600) == 0 or die $! }, qr/lock identity/],
);
for my $control (@bad_lock) {
    with_case(sub {
        my ($case, $path) = @_;
        $control->[1]->($path);
        my @before = lstat("$path/coordination.lock");
        rejects($control->[0], sub { $inspect->($case) }, $control->[2]);
        is_deeply([(lstat("$path/coordination.lock"))[0,1,2,3,7]], [@before[0,1,2,3,7]], 'invalid existing lock preserved');
        ok(!-e "$path/images" && !-e "$path/references", 'invalid lock creates no structural directories');
    });
}

with_case(sub {
    my ($case, $path) = @_;
    $inspect->($case);
    for my $i (1 .. 32) { mkdir(sprintf('%s/images/%064x', $path, $i), 0700) or die $!; }
    for my $i (1 .. 128) { write_bytes(sprintf('%s/references/%064x.json', $path, $i), '', 0400); }
    my $result = $inspect->($case);
    is(scalar @{$result->{images}}, 32, 'image boundary counts incomplete image directories');
    is(scalar @{$result->{references}}, 128, 'reference boundary counts incomplete records');
    like($result->{completeness}, qr/structure_only/, 'namespace census does not claim content admission');
    mkdir(sprintf('%s/images/%064x', $path, 33), 0700) or die $!;
    rejects('image over capacity', sub { $inspect->($case) }, qr/namespace capacity/);
    rmdir(sprintf('%s/images/%064x', $path, 33)) or die $!;
    write_bytes(sprintf('%s/references/%064x.json', $path, 129), '', 0400);
    rejects('reference over capacity', sub { $inspect->($case) }, qr/namespace capacity/);
    ok(-f sprintf('%s/references/%064x.json', $path, 129), 'capacity rejection does not evict');
});

for my $kind (qw(unknown image_name reference_name writable_reference symlink_directory)) {
    with_case(sub {
        my ($case, $path) = @_;
        $inspect->($case);
        write_bytes("$path/unknown", '', 0600) if $kind eq 'unknown';
        mkdir("$path/images/invalid", 0700) or die $! if $kind eq 'image_name';
        write_bytes("$path/references/invalid", '', 0400) if $kind eq 'reference_name';
        write_bytes("$path/references/".('1' x 64).'.json', '', 0600) if $kind eq 'writable_reference';
        if ($kind eq 'symlink_directory') {
            rmdir("$path/images") or die $!; symlink('references', "$path/images") or die $!;
        }
        rejects("invalid namespace $kind", sub { $inspect->($case) }, qr/capacity|invalid.*name|mode, links or size|symlink/);
    });
}

for my $kind (qw(busy_then_success busy_deadline other_error late_success)) {
    with_case(sub {
        my ($case, $path) = @_;
        my $open = \&NativeProxyImageCoordination::_open_lock;
        my ($handle, $attempts, $pauses, $clock) = (undef, 0, 0, 0);
        local *NativeProxyImageCoordination::_open_lock = sub { $handle = $open->(@_); return $handle; };
        local *NativeProxyImageCoordination::_now = sub { return $clock; };
        local *NativeProxyImageCoordination::_pause = sub {
            ok($_[0] > 0 && $_[0] <= 0.005, 'modeled lock polling interval stays bounded');
            ++$pauses; $clock += 1;
        };
        my $real_lock = \&NativeProxyImageCoordination::_try_lock;
        local *NativeProxyImageCoordination::_try_lock = sub {
            ++$attempts;
            if ($kind eq 'late_success') { $clock = 2; return $real_lock->(@_); }
            if ($kind eq 'other_error') { $! = EIO; return 0; }
            return $real_lock->(@_) if $kind eq 'busy_then_success' && $attempts == 2;
            $! = EAGAIN; return 0;
        };
        if ($kind eq 'busy_then_success') {
            ok($inspect->($case), 'modeled busy result permits bounded subsequent acquisition');
            is($attempts, 2, 'exact modeled busy/success attempts');
        } else {
            rejects("modeled $kind", sub { $inspect->($case) }, qr/deadline expired|acquisition failed/);
            is($attempts, $kind eq 'busy_deadline' ? 2 : 1, 'no extra acquisition after deadline or nonbusy error');
            ok(!-e "$path/images", 'failed acquisition performs no directory bootstrap');
        }
        ok(!defined(fileno($handle)), 'success or acquisition failure closes descriptor');
    });
}

for my $kind (qw(lock_replace directory_replace directory_remove)) {
    with_case(sub {
        my ($case, $path) = @_;
        my $census = \&NativeProxyImageCoordination::_census;
        local *NativeProxyImageCoordination::_census = sub {
            my $result = $census->(@_);
            if ($kind eq 'lock_replace') {
                unlink("$path/coordination.lock") or die $!;
                write_bytes("$path/coordination.lock", '', 0600);
            } else {
                if ($kind eq 'directory_replace') {
                    rename("$path/images", "$path/references/old-images") or die $!;
                    mkdir("$path/images", 0700) or die $!;
                } else { rmdir("$path/images") or die $!; }
            }
            return $result;
        };
        rejects("census $kind", sub { $inspect->($case) }, qr/lock identity|directory replaced|does not exist/);
        ok(!-e "$path/images", 'final recheck cannot repair removed structure') if $kind eq 'directory_remove';
    });
}

open my $module_handle, '<:raw', "$FindBin::Bin/Coordination.pm" or die $!;
my $module = do { local $/; <$module_handle> };
close $module_handle or die $!;
for my $kind (qw(lock_guard no_repair_guard)) {
    my $mutant = $module;
    my $package = 'NativeProxyImageCoordinationMutant_' . $kind;
    $mutant =~ s/package NativeProxyImageCoordination;/package $package;/ or die 'package absent';
    if ($kind eq 'lock_guard') {
        $mutant =~ s/        die "permanent lock replaced during census\\n"\n.*?0,1,2,3,4,7\);\n//s
            or die 'lock guard absent';
    } else {
        $mutant =~ s/_structure\(\$base, 0\)/_structure(\$base, 1)/ or die 'no-repair guard absent';
    }
    eval $mutant; die $@ if $@;
    with_case(sub {
        my ($case, $path) = @_;
        no strict 'refs';
        my $census = \&{"${package}::_census"};
        local *{"${package}::_census"} = sub {
            my $result = $census->(@_);
            if ($kind eq 'lock_guard') {
                unlink("$path/coordination.lock") or die $!;
                write_bytes("$path/coordination.lock", '', 0600);
            } else { rmdir("$path/images") or die $!; }
            return $result;
        };
        if ($kind eq 'lock_guard') {
            my $result = &{"${package}::inspect_store"}($case);
            isnt($result->{lock}{inode}, (lstat("$path/coordination.lock"))[1],
                'independent named-inode oracle defeats removed final lock guard');
        } else {
            eval { &{"${package}::inspect_store"}($case) };
            ok(-d "$path/images", 'independent absence oracle defeats removed no-repair guard');
        }
    });
}

is($forbidden, 0, 'no compiler or process creation attempted');
ok(!grep(-e "$root/$_" || -l "$root/$_", @retired), 'all owned inert namespaces are absent');
my $result = {schema => 'fsmgen.inactive_image_coordination_qualification.v1',
    success => Test::More->builder->is_passing ? JSON::PP::true : JSON::PP::false,
    positive => $positive, controls => \@controls, retired_cases => \@retired,
    mutants_defeated => [qw(lock_guard no_repair_guard)],
    forbidden_process_attempts => $forbidden,
    limits => 'Single-process local lock/open/close observed; busy/error/deadline behavior modeled. '
        .'No real contender, native executable, publication, reference semantics or product activation.'};
write_bytes("$logs/qualification.json", JSON::PP->new->canonical->ascii->pretty->encode($result), 0600);
done_testing;
