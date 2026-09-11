#!/usr/bin/env perl
use strict;
use warnings;
our $forbidden = 0;
BEGIN {
    *CORE::GLOBAL::fork = sub { ++$forbidden; die 'forbidden fork'; };
    *CORE::GLOBAL::system = sub { ++$forbidden; die 'forbidden system'; };
}
use FindBin;
use lib "$FindBin::Bin/../../../perl", "$FindBin::Bin/../../../t/lib", $FindBin::Bin;
use Digest::SHA qw(sha256_hex);
use Fcntl qw(S_ISREG S_ISDIR);
use File::Spec;
use File::Temp ();
use JSON::PP ();
use Test::More;
use LowerReaderTrace;
use FSM::Test::RustProxyFixture ();
use FSM::ProjectDataLocality qw(repository_root ensure_project_artifact_dir);
BEGIN { *CORE::GLOBAL::exec = sub { ++$forbidden; die 'forbidden exec'; }; }
use Errno qw(EBADF EIO);

my $ROOT = repository_root();
my $JSON = JSON::PP->new->canonical->ascii;
sub read_bytes {
    open my $fh, '<:raw', $_[0] or die "read qualification input: $!\n";
    my $raw = do { local $/; <$fh> };
    close($fh) or die "close qualification input: $!\n";
    return $raw;
}
sub write_bytes {
    my ($path, $raw, $mode) = @_;
    chmod(0600, $path) == 1 or die $! if -e $path;
    open my $fh, '>:raw', $path or die "write qualification fixture: $!\n";
    print {$fh} $raw or die $!;
    close($fh) or die $!;
    chmod($mode, $path) == 1 or die $!;
}
my $plan = $JSON->decode(read_bytes("$FindBin::Bin/plan.json"));
my $pins = $JSON->decode(read_bytes("$FindBin::Bin/preflight-pins.json"));
for my $pin (@$pins, @{$plan->{inputs}}) {
    my $raw = read_bytes("$ROOT/$pin->{path}");
    die "prospective lower-reader source changed\n" unless length($raw) == $pin->{size_bytes} && sha256_hex($raw) eq $pin->{sha256};
}
my $component = 'native-proxy-observation-archive-lower-reader-seam-20260911';
die "preserve the previous lower-reader qualification\n" if -e "$ROOT/.artifacts/logs/$component/qualification.json" || -l "$ROOT/.artifacts/logs/$component/qualification.json";
my $log = ensure_project_artifact_dir('logs', $component);
my $parent = ensure_project_artifact_dir('tmp', $component, 'cases');
my $result = {schema => 'fsmgen.inactive_archive_lower_reader_seam_qualification.v1', success => JSON::PP::false,
              cases => [], allocated => [], forbidden_process_attempts => 0};
sub save_result {
    $result->{forbidden_process_attempts} = $forbidden;
    write_bytes("$log/qualification.json", JSON::PP->new->canonical->ascii->pretty->encode($result), 0600);
}
write_bytes("$log/admission.jsonl", '', 0600);
save_result();
no warnings 'redefine';
local *FSM::Test::RustProxyFixture::supervise_process = sub { ++$forbidden; die 'forbidden process'; };

sub snapshot {
    my ($path) = @_;
    my @root = lstat($path); die 'invalid owned observer fixture root' unless @root && S_ISDIR($root[2]);
    opendir(my $dir, $path) or die $!;
    my @names;
    my $ok = eval {
        while (1) {
            $! = 0; my $name = readdir($dir);
            if (!defined($name)) { die "read observer fixture namespace: $!\n" if $!; last; }
            next if $name eq '.' || $name eq '..';
            push @names, $name;
            die 'observer fixture namespace capacity' if @names > 2;
        }
        1;
    };
    my $error = $@; my $closed = closedir($dir);
    die $error unless $ok; die "close observer fixture namespace: $!\n" unless $closed;
    @names = sort @names;
    die 'unexpected observer fixture member' unless join(',', @names) eq 'other.data,source.data';
    my $state = {root => {device => $root[0], inode => $root[1], mode => $root[2] & 07777, uid => $root[4]}, files => {}};
    for my $name (@names) {
        my @stat = lstat("$path/$name");
        die 'invalid bounded observer fixture source' unless @stat && S_ISREG($stat[2]) && $stat[7] <= 65536
            && $stat[0] == (stat($ROOT))[0] && $stat[4] == $< && $stat[3] == 1;
        my $raw = read_bytes("$path/$name");
        $state->{files}{$name} = {device => $stat[0], inode => $stat[1], mode => $stat[2] & 07777,
            uid => $stat[4], links => $stat[3], size_bytes => length($raw), bytes_hex => unpack('H*', $raw), sha256 => sha256_hex($raw)};
    }
    return $state;
}

for my $selection (@{$plan->{cases}}) {
    my $temporary = File::Temp->newdir('fsmgen-XXXXXXXX', DIR => $parent, CLEANUP => 1);
    my $path = "$temporary"; my @native = lstat($path);
    my $identity = {path => File::Spec->abs2rel($path, $ROOT), device => $native[0], inode => $native[1]};
    push @{$result->{allocated}}, $identity;
    open my $journal, '>>:raw', "$log/admission.jsonl" or die $!;
    print {$journal} $JSON->encode($identity), "\n" or die $!;
    close($journal) or die $!;
    my $row = {name => $selection->{name}, selection => $selection, root => $identity};
    push @{$result->{cases}}, $row;
    save_result();
    my $profile = $selection->{profile};
    my $raw = $profile eq 'empty' ? '' : $profile eq 'binary' ? pack('C*', 0..255)
        : $profile eq 'maximum' ? 'M' x 65536 : die 'unknown observer source profile';
    write_bytes("$path/source.data", $raw, 0400);
    write_bytes("$path/other.data", "untouched\0observer\xff", 0400);
    $row->{before} = snapshot($path);
    save_result();
    my $operation = NativeProxyLowerReaderTrace::observe("$path/source.data", $selection);
    $row->{operation} = $operation;
    $row->{after} = snapshot($path);
    save_result();
    my $id = $selection->{name};
    ok($operation->{observer_completed} && !length($operation->{observer_error}), "$id: observer completed")
        or diag($operation->{observer_error});
    my $expected = '';
    if ($selection->{fail_read}) { local $! = EIO; $expected = "cannot read fixture bytes: $!\n"; }
    ok($operation->{reader_error} eq $expected && $operation->{reader_returned} == ($selection->{fail_read} ? 0 : 1),
        "$id: original lower-reader outcome retained") or diag($operation->{reader_error});
    ok($selection->{fail_read} ? !defined($operation->{result})
        : $operation->{result}{bytes_hex} eq unpack('H*', $raw), "$id: return bytes match direct source");
    my $open_expected = $selection->{strong_alias} || (!$selection->{fail_read} && $selection->{keep_open});
    ok(defined($operation->{at_reader_return}{duplicate}) == ($open_expected ? 1 : 0)
        && $operation->{alias_is_weak} == 1, "$id: actual reader-return liveness distinguished");
    ok(!defined($operation->{after_cleanup}{duplicate}) && $operation->{after_cleanup}{errno} == EBADF,
        "$id: caller or control cleanup leaves the actual descriptor closed");
    ok($JSON->encode($row->{before}) eq $JSON->encode($row->{after}), "$id: source and bystander preserved");
    undef $temporary;
    $row->{root_absent} = !-e $path && !-l $path ? 1 : 0;
    save_result();
    die 'owned lower-reader fixture residue' unless $row->{root_absent};
    BAIL_OUT('first unexpected lower-reader observer result retained') unless Test::More->builder->is_passing;
}
is($forbidden, 0, 'no compiler or native process attempt');
$result->{success} = Test::More->builder->is_passing ? JSON::PP::true : JSON::PP::false;
save_result();
done_testing;
