#!/usr/bin/env perl
use strict;
use warnings;
our ($fault, $omit_close, $current_path, $write_calls);
our @held;
our $forbidden = 0;
BEGIN {
    *CORE::GLOBAL::fork = sub { ++$forbidden; die 'forbidden fork'; };
    *CORE::GLOBAL::system = sub { ++$forbidden; die 'forbidden system'; };
    *CORE::GLOBAL::binmode = sub (*;$) {
        if ($fault && caller eq 'NativeProxyImagePublication') {
            observe_handle($_[0], 'writer', $current_path);
            if ($fault eq 'writer_byte_mode') { $! = Errno::EIO(); return 0; }
        }
        return @_ == 1 ? CORE::binmode($_[0]) : CORE::binmode($_[0], $_[1]);
    };
    *CORE::GLOBAL::fcntl = sub (*$$) {
        my $owner = caller;
        if ($fault && (($owner eq 'NativeProxyImageCustody' && $fault =~ /\Asource_/)
                || ($owner eq 'NativeProxyImagePublication' && $fault =~ /\Awriter_/))) {
            if (($fault =~ /_get_flags\z/ && $_[1] == Fcntl::F_GETFD())
                    || ($fault =~ /_set_flags\z/ && $_[1] == Fcntl::F_SETFD())) {
                $! = Errno::EIO(); return undef;
            }
        }
        return CORE::fcntl($_[0], $_[1], $_[2]);
    };
    *CORE::GLOBAL::syswrite = sub (*$;$$) {
        if ($fault && caller eq 'NativeProxyImagePublication') {
            if ($fault eq 'writer_zero_write' || $fault eq 'writer_write_close_error') {
                $! = Errno::EIO(); return 0;
            }
            if ($fault eq 'writer_partial_write') {
                if (!$write_calls++) { return CORE::syswrite($_[0], $_[1], 8, 0); }
                $! = Errno::EIO(); return undef;
            }
        }
        return @_ == 4 ? CORE::syswrite($_[0], $_[1], $_[2], $_[3])
            : @_ == 3 ? CORE::syswrite($_[0], $_[1], $_[2]) : CORE::syswrite($_[0], $_[1]);
    };
    *CORE::GLOBAL::close = sub (*) {
        my $subject = caller eq 'NativeProxyImageCustody' || caller eq 'NativeProxyImagePublication';
        return 1 if $fault && $subject && $omit_close;
        my $ok = CORE::close($_[0]);
        if ($fault && $subject && $fault =~ /_close_error\z/) { $! = Errno::EIO(); return 0; }
        return $ok;
    };
}
use FindBin;
use lib "$FindBin::Bin/../../../perl", "$FindBin::Bin/../../../t/lib",
    map { "$FindBin::Bin/../$_" } qw(native-proxy-image-custody-20260910
        native-proxy-image-coordination-20260910 native-proxy-image-publication-20260910);
use Digest::SHA qw(sha256_hex);
use Errno ();
use Fcntl qw(F_GETFD FD_CLOEXEC S_ISDIR S_ISREG);
use File::Spec;
use File::Temp ();
use JSON::PP ();
use Test::More;
use FSM::ProjectDataLocality qw(ensure_project_artifact_dir repository_root);
use FSM::Test::RustProxyFixture ();
BEGIN { *CORE::GLOBAL::exec = sub { ++$forbidden; die 'forbidden exec'; }; }
use ImageCustody;
use Publication;

my $phase = shift(@ARGV) // '';
die 'choose exactly --baseline or --qualification' unless !@ARGV && $phase =~ /\A--(?:baseline|qualification)\z/;
$phase =~ s/\A--//;
my $ROOT = repository_root();
my $JSON = JSON::PP->new->canonical->ascii;
my $parent = ensure_project_artifact_dir(qw(tmp native-proxy-image-custody cases));
my $log = ensure_project_artifact_dir(qw(logs native-proxy-descriptor-handoff-20260910));
my $plan = $JSON->decode(read_bytes("$FindBin::Bin/plan.json"));
my $vector = $JSON->decode(read_bytes("$FindBin::Bin/../native-proxy-image-custody-20260910/vectors.json"));
my $SOURCE = pack('H*', $vector->{generated_c_hex});
my $PAYLOAD = "inert observation payload\0\xff\n";
my $read_file = \&FSM::Test::RustProxyFixture::_read_file;
my $seal = \&NativeProxyImagePublication::_seal_payload;
my $result = {schema => 'fsmgen.inactive_descriptor_handoff_qualification.v1', phase => $phase,
    success => JSON::PP::false, completed => JSON::PP::false, allocated => [], cases => [], mutants => []};
no warnings 'redefine';
local *FSM::Test::RustProxyFixture::supervise_process = sub { ++$forbidden; die 'forbidden compiler'; };
write_bytes("$log/$phase-admission.jsonl", '', 0600);

sub read_bytes {
    open my $fh, '<:raw', $_[0] or die $!; my $raw = do { local $/; <$fh> }; close $fh or die $!; return $raw;
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
sub identity {
    my ($metadata) = @_;
    return {device => 0+$metadata->[0], inode => 0+$metadata->[1], mode => $metadata->[2] & 07777,
        links => 0+$metadata->[3], uid => 0+$metadata->[4], size_bytes => 0+$metadata->[7]};
}
sub observe_handle {
    my ($handle, $role, $path) = @_;
    my @metadata = stat($handle); die 'cannot observe actual descriptor' unless @metadata;
    push @held, {handle => $handle, role => $role, path => $path, descriptor => fileno($handle),
        identity => identity(\@metadata)};
}
sub footprint {
    my ($path) = @_; my @root = lstat("$ROOT/$path"); die 'bad fixture root' unless @root && S_ISDIR($root[2]);
    my %tree = ('' => {kind => 'directory', %{identity(\@root)}});
    # Directory byte sizes/link counts are not stable namespace semantics.
    delete @{$tree{''}}{qw(size_bytes links)};
    opendir my $dir, "$ROOT/$path" or die $!;
    my @names = sort grep { $_ ne '.' && $_ ne '..' } readdir $dir; closedir $dir or die $!;
    die 'unbounded fixture namespace' if @names > 2;
    for my $name (@names) {
        die 'unknown fixture member' unless $name eq 'source' || $name eq 'payload';
        my @s = lstat("$ROOT/$path/$name"); die 'bad fixture file' unless @s && S_ISREG($s[2]) && $s[7] <= 65536;
        my $bytes = read_bytes("$ROOT/$path/$name");
        $tree{$name} = {kind => 'file', %{identity(\@s)}, sha256 => sha256_hex($bytes), bytes => $bytes};
    }
    return \%tree;
}
sub run_case {
    my ($spec, $name, $mutant) = @_;
    my $temporary = File::Temp->newdir('fsmgen-XXXXXXXX', DIR => $parent, CLEANUP => 1);
    my $case = File::Spec->abs2rel("$temporary", $ROOT); my @directory = stat("$temporary");
    my $allocation = {path => $case, device => 0+$directory[0], inode => 0+$directory[1]};
    push @{$result->{allocated}}, $allocation;
    open my $ledger, '>>:raw', "$log/$phase-admission.jsonl" or die $!;
    print {$ledger} $JSON->encode($allocation), "\n" or die $!; close $ledger or die $!; save();
    write_bytes("$ROOT/$case/source", $SOURCE, 0400);
    my $row = {name => $name, operation => $spec->{operation}, fault => $spec->{name}, allocation => $allocation,
        before => footprint($case)};
    my ($value, $ok, $error);
    {
        local $fault = $spec->{name}; local $omit_close = $mutant; local $write_calls = 0;
        local $current_path = "$case/payload"; local @held;
        local *FSM::Test::RustProxyFixture::_read_file = sub {
            my @read = $read_file->(@_);
            observe_handle($read[2], 'reader', File::Spec->abs2rel($_[0], $ROOT)) if defined($read[2]);
            return @read;
        };
        local *NativeProxyImagePublication::_seal_payload = sub {
            die "injected canonical seal failure\n" if $fault eq 'writer_seal';
            return $seal->(@_);
        };
        $ok = eval {
            if ($spec->{operation} eq 'source') {
                my $mode = $fault eq 'source_mode' || $fault eq 'source_mode_close_error' ? 0500 : 0400;
                my $limit = $fault eq 'source_size' ? length($SOURCE)-1 : 65536;
                $value = NativeProxyImageCustody::_source("$ROOT/$case/source", $mode, $limit);
                $row->{result} = {bytes => $value->{bytes}, path => "$case/source", %{identity($value->{metadata})}};
            } else {
                $value = NativeProxyImagePublication::_write_payload("$ROOT/$case/payload", $PAYLOAD, 0400);
                $row->{result} = identity($value);
            }
            1;
        };
        $error = $@; $error =~ s/\Q$ROOT\E/./g;
        $row->{returned} = $ok && defined($value) ? 1 : 0; $row->{error} = $error;
        my @observed;
        for my $entry (@held) {
            my $handle = $entry->{handle}; my $open = defined(fileno($handle)) ? 1 : 0;
            my %record = %$entry; delete $record{handle};
            $record{closed_before_recovery} = $open ? 0 : 1;
            if ($open) {
                my @current = stat($handle); $record{current_identity} = identity(\@current);
                my $flags = CORE::fcntl($handle, F_GETFD, 0);
                $record{open_cloexec} = defined($flags) && ($flags & FD_CLOEXEC) ? 1 : 0;
                $record{recovery_close_ok} = CORE::close($handle) ? 1 : 0;
            } else { $record{recovery_close_ok} = undef; }
            $record{closed_after_recovery} = defined(fileno($handle)) ? 0 : 1;
            push @observed, \%record;
        }
        $row->{handles} = \@observed;
    }
    $row->{after} = footprint($case);
    undef $temporary;
    die 'handoff fixture remains' if -e "$ROOT/$case" || -l "$ROOT/$case";
    $row->{allocation_absent} = 1;
    return $row;
}
my %specifications = map { $_->{name} => $_ } @{$plan->{cases}};
my @selected = $phase eq 'baseline' ? map { $specifications{$_->{name}} } @{$plan->{baseline}} : @{$plan->{cases}};
save();
for my $spec (@selected) {
    my $row = run_case($spec, $spec->{name}, 0);
    my $success = !length($spec->{diagnostic});
    my $expected_open = $phase eq 'baseline' || ($success && $spec->{operation} eq 'source') ? 1 : 0;
    my $open = grep { !$_->{closed_before_recovery} } @{$row->{handles}};
    $row->{expected_open_handles} = $expected_open;
    push @{$result->{cases}}, $row; save();
    ok($row->{returned} == ($success ? 1 : 0) && ($success ? $row->{error} eq '' : index($row->{error}, $spec->{diagnostic}) >= 0)
        && @{$row->{handles}} && $open == $expected_open, "$spec->{name}: $phase descriptor disposition")
        or do { diag($row->{error} || "open handles $open, expected $expected_open"); BAIL_OUT('unexpected handoff disposition'); };
    ok(!grep({ !$_->{closed_after_recovery} || (defined($_->{recovery_close_ok}) && !$_->{recovery_close_ok}) } @{$row->{handles}}),
        "$spec->{name}: caller or observer recovery closes every retained descriptor");
}
if ($phase eq 'qualification') {
    for my $name (@{$plan->{mutants}}) {
        my $spec = $specifications{$name eq 'omit source failure close' ? 'source_mode' : 'writer_byte_mode'};
        my $row = run_case($spec, $name, 1); push @{$result->{mutants}}, $row; save();
        ok(!$row->{returned} && index($row->{error}, $spec->{diagnostic}) >= 0
            && @{$row->{handles}} == 1 && !$row->{handles}[0]{closed_before_recovery}, "$name exposes missing explicit closure");
        ok($row->{handles}[0]{recovery_close_ok} && $row->{handles}[0]{closed_after_recovery}, "$name observer recovery closes the actual descriptor");
    }
}
is($forbidden, 0, 'no process attempt');
$result->{completed} = JSON::PP::true;
$result->{success} = JSON::PP::true if $phase eq 'qualification';
save(); done_testing();
