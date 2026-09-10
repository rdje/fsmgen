#!/usr/bin/env perl
use strict;
use warnings;
our ($observing, $fault, $omit_close, $active_row, $selected_path, $read_error_after, $read_error_injected);
our @held;
our $forbidden = 0;
BEGIN {
    *CORE::GLOBAL::fork = sub { ++$forbidden; die 'forbidden fork'; };
    *CORE::GLOBAL::system = sub { ++$forbidden; die 'forbidden system'; };
    *CORE::GLOBAL::opendir = sub (*$) {
        my $ok = CORE::opendir($_[0], $_[1]);
        my $error = 0+$!;
        if ($observing && caller eq 'NativeProxyImageCoordination') {
            push @{$active_row->{calls}}, {kind => 'open', returned => $ok ? 1 : 0, errno => $error};
            observe_directory($_[0]) if $ok;
        }
        $! = $error; return $ok;
    };
    *CORE::GLOBAL::readdir = sub (*) {
        return CORE::readdir($_[0]) unless $observing && caller eq 'NativeProxyImageCoordination';
        die 'subject readdir must use scalar context' if wantarray;
        my $incoming = 0+$!;
        if (defined($read_error_after) && !$read_error_injected
                && @{$active_row->{actual_members}} >= $read_error_after) {
            $read_error_injected = 1;
            push @{$active_row->{calls}}, {kind => 'read', entry => undef, incoming_errno => $incoming,
                errno => 0+Errno::EIO(), injected => 1};
            $! = Errno::EIO(); return undef;
        }
        my $name = CORE::readdir($_[0]); my $error = 0+$!;
        push @{$active_row->{calls}}, {kind => 'read', entry => $name, incoming_errno => $incoming,
            errno => $error, injected => 0};
        push @{$active_row->{actual_members}}, $name if defined($name) && $name ne '.' && $name ne '..';
        $! = $error; return $name;
    };
    *CORE::GLOBAL::closedir = sub (*) {
        return CORE::closedir($_[0]) unless $observing && caller eq 'NativeProxyImageCoordination';
        if ($omit_close) {
            push @{$active_row->{calls}}, {kind => 'close', actual_close => 0, returned => 1, errno => 0};
            return 1;
        }
        my $ok = CORE::closedir($_[0]); my $error = 0+$!;
        my $reported = $fault eq 'close_error' || $fault eq 'capacity_and_close' || $fault eq 'read_and_close';
        push @{$active_row->{calls}}, {kind => 'close', actual_close => $ok ? 1 : 0,
            returned => $reported ? 0 : ($ok ? 1 : 0), errno => $reported ? 0+Errno::EIO() : $error};
        if ($reported) { $! = Errno::EIO(); return 0; }
        $! = $error; return $ok;
    };
}
use FindBin;
use lib "$FindBin::Bin/../../../perl", "$FindBin::Bin/../../../t/lib",
    "$FindBin::Bin/../native-proxy-image-custody-20260910",
    "$FindBin::Bin/../native-proxy-image-coordination-20260910";
use Config;
use Digest::SHA qw(sha256_hex);
use Errno ();
use Fcntl qw(S_ISDIR S_ISREG);
use File::Spec;
use File::Temp ();
use JSON::PP ();
use Test::More;
use FSM::ProjectDataLocality qw(ensure_project_artifact_dir repository_root);
use FSM::Test::RustProxyFixture ();
BEGIN { *CORE::GLOBAL::exec = sub { ++$forbidden; die 'forbidden exec'; }; }
use Coordination;

my $phase = shift(@ARGV) // '';
die 'choose exactly --baseline or --qualification' unless !@ARGV && $phase =~ /\A--(?:baseline|qualification)\z/;
$phase =~ s/\A--//;
my $ROOT = repository_root();
my $JSON = JSON::PP->new->canonical->ascii;
my $raw_plan = read_bytes("$FindBin::Bin/plan.json");
die 'prospective plan changed' unless sha256_hex($raw_plan) eq '883d5f4744bc1a8ba5b41d8a7c0ee46748a5b2c1a93334b74143d1f5549fc842';
my $plan = $JSON->decode($raw_plan);
my $parent = ensure_project_artifact_dir(qw(tmp native-proxy-image-custody cases));
my $log = ensure_project_artifact_dir(qw(logs native-proxy-namespace-reader-20260911));
my $result = {schema => 'fsmgen.inactive_namespace_reader_qualification.v1', phase => $phase,
    success => JSON::PP::false, qualified => JSON::PP::false, completed => JSON::PP::false,
    perl_version => "$^V", directory_descriptor_support => $Config{d_dirfd}, allocated => [], cases => [], mutants => []};
my $names = \&NativeProxyImageCoordination::_names;
no warnings 'redefine';
local *FSM::Test::RustProxyFixture::supervise_process = sub { ++$forbidden; die 'forbidden compiler'; };
write_bytes("$log/$phase-admission.jsonl", '', 0600);

sub read_bytes {
    open my $fh, '<:raw', $_[0] or die $!; my $raw = do { local $/; <$fh> };
    close $fh or die $!; return $raw;
}
sub write_bytes {
    my ($path, $raw, $mode) = @_;
    open my $fh, '>:raw', $path or die $!; print {$fh} $raw or die $!;
    close $fh or die $!; chmod($mode, $path) == 1 or die $!;
}
sub save {
    $result->{forbidden_process_attempts} = $forbidden;
    write_bytes("$log/$phase.json", JSON::PP->new->canonical->ascii->pretty->encode($result), 0600);
}
sub metadata {
    my ($values) = @_;
    return {device => 0+$values->[0], inode => 0+$values->[1], mode => $values->[2] & 07777,
        uid => 0+$values->[4]};
}
sub observe_directory {
    my ($handle) = @_;
    my $entry = {handle => $handle, path => $selected_path, descriptor => fileno($handle)};
    push @held, $entry;
    die 'actual directory descriptor unavailable' unless defined($entry->{descriptor}) && $entry->{descriptor} >= 0;
    # Duplicate only for descriptor-based stat. This observer descriptor closes
    # immediately and cannot close or advance the original directory stream.
    open my $probe, '<&', $entry->{descriptor} or die "cannot duplicate directory descriptor: $!";
    my @s = stat($probe); die 'directory descriptor did not identify a directory' unless @s && S_ISDIR($s[2]);
    $entry->{identity} = metadata(\@s);
    $entry->{observer_descriptor} = fileno($probe);
    $entry->{observer_close_ok} = CORE::close($probe) ? 1 : 0;
    $entry->{observer_closed} = defined(fileno($probe)) ? 0 : 1;
    die 'cannot close directory-stat observer' unless $entry->{observer_close_ok} && $entry->{observer_closed};
}
sub footprint {
    my ($relative) = @_;
    my @s = lstat("$ROOT/$relative"); die 'fixture root is not a directory' unless @s && S_ISDIR($s[2]);
    die 'fixture left the repository volume' unless $s[0] == (stat($ROOT))[0];
    my %nodes = ('' => {kind => 'directory', %{metadata(\@s)}});
    opendir my $directory, "$ROOT/$relative" or die $!;
    my @members = sort grep { $_ ne '.' && $_ ne '..' } readdir($directory);
    closedir($directory) or die $!;
    die 'fixture membership changed' if @members > 2 || grep { $_ ne 'a' && $_ ne 'b' } @members;
    for my $name (@members) {
        my @f = lstat("$ROOT/$relative/$name");
        die 'fixture member is not a bounded direct file' unless @f && S_ISREG($f[2]) && $f[3] == 1 && $f[7] <= 6;
        my $raw = read_bytes("$ROOT/$relative/$name");
        $nodes{$name} = {kind => 'file', %{metadata(\@f)}, links => 0+$f[3],
            bytes => $raw, size_bytes => length($raw), sha256 => sha256_hex($raw)};
    }
    return \%nodes;
}
sub error_check_mutant {
    my $source = read_bytes("$FindBin::Bin/../native-proxy-image-coordination-20260910/Coordination.pm");
    my ($body) = $source =~ /(sub _names \{.*?\n\})\n\nsub _structure/s;
    die 'cannot isolate namespace reader' unless defined($body);
    my $marker = 'die "cannot read bounded namespace: $!\n" if $!;';
    my $count = $body =~ s/\Q$marker\E//g;
    die 'read-error mutant must remove exactly one branch' unless $count == 1;
    $body =~ s/\Asub _names/sub/;
    my $mutant = eval "package NativeProxyImageCoordination; $body";
    die "cannot compile isolated read-error mutant: $@" unless ref($mutant) eq 'CODE';
    return $mutant;
}
sub run_case {
    my ($spec, $name, $mutant) = @_;
    my $temporary = File::Temp->newdir('fsmgen-XXXXXXXX', DIR => $parent, CLEANUP => 1);
    my $relative = File::Spec->abs2rel("$temporary", $ROOT); my @s = lstat("$temporary");
    my $allocation = {path => $relative, device => 0+$s[0], inode => 0+$s[1]};
    push @{$result->{allocated}}, $allocation;
    open my $ledger, '>>:raw', "$log/$phase-admission.jsonl" or die $!;
    print {$ledger} $JSON->encode($allocation), "\n" or die $!; close $ledger or die $!; save();
    if ($spec->{members}) {
        write_bytes("$temporary/a", "alpha\n", 0400);
        write_bytes("$temporary/b", "beta\n", 0400);
    }
    my $row = {name => $name, fault => $spec->{name}, allocation => $allocation, before => footprint($relative),
        calls => [], actual_members => []};
    {
        local $observing = 1; local $fault = $spec->{name}; local $active_row = $row;
        local $selected_path = $relative.($fault eq 'missing_directory' ? '/absent' : '');
        local @held; local $omit_close = $mutant eq 'omit_directory_close';
        local $read_error_injected = 0;
        local $read_error_after = $fault eq 'read_entry' ? 0 : $fault eq 'read_after_all' ? 2
            : ($fault eq 'read_after_one' || $fault eq 'read_and_close') ? 1 : undef;
        my $operation = $mutant eq 'omit_read_error_check' ? error_check_mutant() : $names;
        my $value;
        $! = Errno::EIO() if $fault eq 'stale_errno';
        my $ok = eval { $value = $operation->("$ROOT/$selected_path", $spec->{limit}); 1 };
        my $error = $@; $error =~ s/\Q$ROOT\E/./g;
        $row->{returned} = $ok && defined($value) ? 1 : 0;
        $row->{names} = $value if $row->{returned};
        $row->{error} = $error; $row->{read_error_injected} = $read_error_injected;
        my @observed;
        for my $entry (@held) {
            my %copy = %$entry; my $handle = delete $copy{handle};
            my $open = defined(fileno($handle)) ? 1 : 0;
            $copy{closed_before_recovery} = $open ? 0 : 1;
            $copy{recovery_close_ok} = $open ? (CORE::closedir($handle) ? 1 : 0) : undef;
            $copy{closed_after_recovery} = defined(fileno($handle)) ? 0 : 1;
            push @observed, \%copy;
        }
        $row->{handles} = \@observed;
    }
    $row->{after} = footprint($relative);
    undef $temporary;
    die 'namespace fixture remains' if -e "$ROOT/$relative" || -l "$ROOT/$relative";
    $row->{allocation_absent} = 1;
    return $row;
}
my %cases = map { $_->{name} => $_ } @{$plan->{cases}};
my @selected = $phase eq 'baseline' ? map { $cases{$_} } @{$plan->{baseline}} : @{$plan->{cases}};
save();
for my $spec (@selected) {
    my $row = run_case($spec, $spec->{name}, ''); push @{$result->{cases}}, $row; save();
    my $baseline_read = $phase eq 'baseline' && $spec->{name} =~ /\Aread_/;
    my $returns = $baseline_read || $spec->{returns};
    my $diagnostic = $returns ? '' : $spec->{diagnostic};
    my $open = grep { !$_->{closed_before_recovery} } @{$row->{handles}};
    my $expected_open = $phase eq 'baseline' && $spec->{name} eq 'capacity' ? 1 : 0;
    my $behavior = $row->{returned} == ($returns ? 1 : 0)
        && ($returns ? $row->{error} eq '' : index($row->{error}, $diagnostic) == 0) && $open == $expected_open;
    my $closed = !grep { !$_->{closed_after_recovery} || !$_->{observer_closed}
        || !$_->{observer_close_ok} || (defined($_->{recovery_close_ok}) && !$_->{recovery_close_ok}) } @{$row->{handles}};
    ok($behavior, "$spec->{name}: $phase outcome and explicit directory disposition");
    ok($closed && $JSON->encode($row->{before}) eq $JSON->encode($row->{after}), "$spec->{name}: exact state and observer recovery");
    unless ($behavior && $closed) {
        $result->{first_failure} = $spec->{name}; save(); diag($row->{error}); BAIL_OUT('unexpected namespace reader result');
    }
}
if ($phase eq 'qualification') {
    for my $mutant (@{$plan->{mutants}}) {
        my $row = run_case($cases{$mutant->{case}}, $mutant->{name}, $mutant->{name});
        push @{$result->{mutants}}, $row; save();
        my $open = grep { !$_->{closed_before_recovery} } @{$row->{handles}};
        my $gap = $mutant->{name} eq 'omit_directory_close' ? !$row->{returned} && $open == 1 : $row->{returned} && $open == 0;
        ok($gap, "$mutant->{name}: the omitted guard is observable");
        ok(@{$row->{handles}} == 1 && $row->{handles}[0]{closed_after_recovery}
            && $JSON->encode($row->{before}) eq $JSON->encode($row->{after}), "$mutant->{name}: observer recovers unchanged fixture");
        unless ($gap) { $result->{first_failure} = $mutant->{name}; save(); BAIL_OUT('namespace mutant did not expose its gap'); }
    }
}
is($forbidden, 0, 'no process attempt');
$result->{completed} = JSON::PP::true;
$result->{success} = $result->{qualified} = JSON::PP::true if $phase eq 'qualification';
save(); done_testing();
