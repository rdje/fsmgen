#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Config;
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use Errno qw(EPERM EIO);
use Fcntl qw(O_WRONLY O_CREAT O_EXCL O_APPEND);
use IO::Select;
use JSON::PP;
use POSIX ();
use lib 'perl', 't/lib', 'docs/audits/native-group-witness-20260927',
        'docs/audits/native-group-witness-20260927/failure-only';
use FSM::Test::ProjectDataLocality;
use FSM::Test::ProcessSupervisor qw(supervise_process);
use GroupWitness;
use FailureWitness;

sub read_bytes {
    open my $fh, '<:raw', $_[0] or die $!;
    local $/; my $data = <$fh>; close $fh or die $!; return $data;
}
my $json = JSON::PP->new->canonical;
my $base = 'docs/audits/native-group-witness-20260927';
my $qualification = $json->decode(read_bytes("$base/manifest.json"));
die "qualified Perl ABI changed\n" unless $Config{version} eq $qualification->{build}{perl_version};
for my $file (keys %{$qualification->{sha256}}) {
    die "qualified witness input changed: $file\n"
        unless sha256_hex(read_bytes("$base/$file")) eq $qualification->{sha256}{$file};
}
my $helper = '.artifacts/native-group-witness/context.bundle';
die "qualified native helper changed\n"
    unless sha256_hex(read_bytes($helper)) eq $qualification->{build}{binary_sha256};
GroupWitness->load_context(abs_path($helper));
my $name = shift(@ARGV) // 'qualification';
die "invalid capture name\n" unless $name =~ /\A[a-z0-9_]+\z/ && !@ARGV;
my $work = ".artifacts/native-failure-context/$name";
mkdir $work or die "exclusive qualification directory: $!";
sysopen my $sink, "$work/events.jsonl", O_WRONLY | O_CREAT | O_EXCL | O_APPEND, 0600 or die $!;
my $observer_group = CORE::getpgrp(0);
my $native = \&FSM::Support::ProcessSupervisor::setpgid;
my $query = \&FailureWitness::_query_context;
my $write = \&FailureWitness::_write;
my @results;

for my $mode (qw(ordinary success_stale session_leader context_error write_error diagnostic_errno)) {
    my $failure = $mode ne 'ordinary' && $mode ne 'success_stale';
    my ($calls, $queries, $writes) = (0, 0, 0);
    my $witness = FailureWitness->new($sink, $mode);
    pipe my $relay_read, my $relay_write or die $!;
    no warnings 'redefine';
    local *FailureWitness::_query_context = sub {
        ++$queries;
        die "modeled context query failure\n" if $mode eq 'context_error';
        return $query->(@_);
    };
    local *FailureWitness::_write = sub {
        ++$writes;
        if ($mode eq 'write_error') { $! = EIO; die "modeled capture write failure\n" }
        $write->(@_);
        $! = EIO if $mode eq 'diagnostic_errno';
    };
    my $wrapped = $witness->wrap(sub { ++$calls; return $native->(@_) });
    local *FSM::Support::ProcessSupervisor::setpgid = sub {
        my @arguments = @_;
        # Only the intentional session controls suppress parent group creation;
        # otherwise it would make the child a group leader before setsid.
        return $failure ? 0 : $wrapped->(@arguments) if $arguments[0] != 0;
        my $session;
        if ($failure) {
            $session = POSIX::setsid();
            die "native session control failed\n" unless defined($session) && $session == $$;
        }
        $! = EPERM if $mode eq 'success_stale';
        my $result = $wrapped->(@arguments);
        my $error = 0 + $!;
        my $data = $json->encode({pid => $$, ppid => getppid(), pgid => CORE::getpgrp(0),
            session_created => $session, result => $result, errno => $error,
            calls => $calls, queries => $queries, writes => $writes,
            capture_error => $witness->capture_error()}) . "\n";
        die "qualification relay envelope\n" if length($data) > 4096;
        my $size = syswrite($relay_write, $data);
        die "qualification relay write\n" unless defined($size) && $size == length($data);
        $! = $error;
        return $result;
    };
    my $result = supervise_process(
        schema => 'fsmgen.test.process_supervisor_probe.v1', stage => 'probe',
        bounds => {timeout_seconds => 2, capture_limit_bytes => 65_536},
        containment => 'process_supervisor_probe_group', cwd => abs_path($work),
        argv => [$^X, '-e', 'print "failure-witness-body=$$\n"'],
    );
    close $relay_write or die $!;
    die "qualification relay deadline\n" unless IO::Select->new($relay_read)->can_read(2);
    my $size = sysread($relay_read, my $data, 4096);
    die "qualification relay incomplete\n" unless defined($size) && $size > 0 && $data =~ /\n\z/;
    close $relay_read or die $!;
    my $child = $json->decode($data);
    is($child->{calls}, 1, "$mode invokes original child call exactly once");
    is($child->{queries}, $failure ? 1 : 0, "$mode queries only after rejection");
    is($child->{writes}, $failure ? 1 : 0, "$mode writes only after rejection");
    is($calls, $failure ? 0 : 1, "$mode preserves parent closure except explicit session control");
    if ($failure) {
        is($child->{errno}, EPERM, "$mode preserves immediate native errno");
        ok(!defined($child->{result}), "$mode preserves native failure return");
        is($result->{status}, 'exec_error', "$mode remains pre-exec rejection");
        like($result->{exec_error}, qr/pid=$child->{pid} operation=setpgid result=undef errno=1 /,
            "$mode preserves exact admission failure");
        is($result->{stdout}, '', "$mode never executes its body");
    } else {
        ok($result->{ok}, "$mode executes successfully") or diag explain $result;
        is($result->{stdout}, "failure-witness-body=$child->{pid}\n", "$mode runs its exact body");
        is($child->{errno}, EPERM, 'successful stale EPERM stays successful') if $mode eq 'success_stale';
    }
    like($child->{capture_error} // '', $mode eq 'write_error' ? qr/modeled capture write failure/ : qr/\A\z/,
        "$mode keeps capture failure distinct from native failure");
    ok($result->{cleanup}{leader_reaped} && $result->{cleanup}{group_gone}, "$mode exact cleanup");
    is(CORE::getpgrp(0), $observer_group, "$mode keeps observer group unchanged");
    push @results, {label => $mode, child => $child, result => $result};
}
my $original_capture = read_bytes("$work/events.jsonl");
my $boundary = FailureWitness->new($sink, 'sink_limits');
my $row_excess = eval { $boundary->_write({payload => 'x' x 4096}); 1 };
ok(!$row_excess && $@ =~ /capture envelope/, 'oversized record fails before writing');
is(read_bytes("$work/events.jsonl"), $original_capture, 'row excess preserves complete capture');
truncate($sink, 1_048_575) or die $!;
my $file_excess = eval { $boundary->_write({event => 'overflow'}); 1 };
ok(!$file_excess && $@ =~ /capture envelope/, 'aggregate excess fails before writing');
is(-s "$work/events.jsonl", 1_048_575, 'aggregate excess leaves only owned padding');
truncate($sink, length($original_capture)) or die $!;
is(read_bytes("$work/events.jsonl"), $original_capture, 'removing owned padding preserves all evidence');
pipe my $invalid_read, my $invalid_write or die $!;
my $invalid_sink = eval { FailureWitness->new($invalid_write, 'invalid_sink'); 1 };
ok(!$invalid_sink && $@ =~ /append-only regular capture/, 'pipe cannot become an unbounded capture sink');
close $invalid_read or die $!;
close $invalid_write or die $!;
close $sink or die $!;
open my $saved, '>:raw', "$work/results.json" or die $!;
print {$saved} $json->encode(\@results) . "\n" or die $!;
close $saved or die $!;
done_testing();
