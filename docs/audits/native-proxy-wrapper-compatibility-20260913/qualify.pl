use strict;
use warnings;
our $forbidden = 0;
BEGIN {
    *CORE::GLOBAL::fork = sub { ++$forbidden; die 'forbidden fork'; };
    *CORE::GLOBAL::system = sub { ++$forbidden; die 'forbidden system'; };
}
use FindBin;
use lib "$FindBin::Bin/../../../perl", "$FindBin::Bin/../../../t/lib",
    map { "$FindBin::Bin/../native-proxy-$_-20260910" }
    qw(image-custody image-coordination image-publication runtime-records
       runtime-census runtime-acquisition cleanup-receipts runtime-retirement);
use Digest::SHA qw(sha256_hex);
use Fcntl qw(O_RDONLY O_NOFOLLOW O_NONBLOCK O_WRONLY O_CREAT O_EXCL S_ISDIR S_ISREG);
use JSON::PP ();
use FSM::Test::ProcessSupervisor qw(repository_root);
use FSM::Test::RustProxyFixture ();
BEGIN { *CORE::GLOBAL::exec = sub { ++$forbidden; die 'forbidden exec'; }; }
use ReferenceAcquisition;
use RuntimeRetirement;

my $ROOT = repository_root();
my $BASE = 'docs/audits/native-proxy-wrapper-compatibility-20260913';
my $LOG = '.artifacts/logs/native-proxy-wrapper-compatibility-20260913';
my $JSON = JSON::PP->new->canonical->ascii;
my $plan = $JSON->decode(read_bytes("$BASE/plan.json", 32768));
my $prepared = $JSON->decode(read_bytes("$LOG/prepared.json", 65536));
for my $pin (@{$JSON->decode(read_bytes("$BASE/source-pins.json", 65536))}) {
    my $raw = read_bytes($pin->{path}, 2_097_152);
    die 'source pin differs' unless length($raw) == $pin->{size_bytes} && sha256_hex($raw) eq $pin->{sha256};
}
my $baseline = read_bytes("$BASE/PrivateWorkspace.baseline.source", 32768);
die 'baseline namespace mismatch' unless $baseline =~ s/\Apackage NativeProxyPrivateWorkspace;/package NativeProxyPrivateWorkspaceBaseline;/;
eval $baseline or die "baseline source load: $@";
sysopen(my $journal, "$ROOT/$LOG/qualification.jsonl", O_WRONLY | O_CREAT | O_EXCL, 0600) or die $!;
my $old_select = select($journal); $| = 1; select($old_select);
my $journal_bytes = 0;
my @handles;
my $source = \&NativeProxyImageCustody::_source;
no warnings 'redefine';
local *FSM::Test::RustProxyFixture::supervise_process = sub { ++$forbidden; die 'forbidden compiler'; };
local *NativeProxyImageCustody::_source = sub {
    my $result = $source->(@_);
    push @handles, $result->{handle};
    return $result;
};
local $SIG{ALRM} = sub { die "qualification wall exceeded\n"; };
alarm($plan->{limits}{qualifier_wall_seconds});
my $ok = eval {
    die 'prepared footprint differs' unless $JSON->encode(census()) eq $JSON->encode($prepared);
    for my $case (@{$plan->{cases}}) {
        for my $version (qw(baseline repaired)) {
            emit({event => 'reader_intent', case => $case->{name}, version => $version});
            my $reader = $version eq 'baseline' ? \&NativeProxyPrivateWorkspaceBaseline::_node
                                              : \&NativeProxyPrivateWorkspace::_node;
            my $value = eval { $reader->($case->{path}) };
            my $error = $@;
            if ($value) {
                $value->{size_bytes} = length(delete($value->{bytes}));
            }
            emit({event => 'reader_result', case => $case->{name}, version => $version,
                  accepted => $error ? 0 : 1, error => $error, result => $value});
        }
    }
    die 'reader changed fixture' unless $JSON->encode(census()) eq $JSON->encode($prepared);
    my $work = $plan->{workspace};
    my $vectors = $JSON->decode(read_bytes('docs/audits/native-proxy-image-custody-20260910/vectors.json', 32768));
    my @bytes = map { pack('H*', $vectors->{$_}) } qw(generated_c_hex image_hex);
    emit({event => 'acquisition_intent', workspace => $work, store => $plan->{store}});
    my $acquired = NativeProxyReferenceAcquisition::acquire_runtime_reference($plan->{store},
        {path => $work, map { $_ => $prepared->{nodes}{$work}{$_} } qw(device inode)}, @bytes);
    my $before = census();
    emit({event => 'acquired', acquired => $acquired, census => $before});
    my $owner = sub { +{cleanup => {leader_started => 1, leader_reaped => 1, group_gone => 1}} };
    my $cleanup = {compiler => $owner->(), outer => $owner->(), stages => [$owner->(), $owner->()]};
    emit({event => 'baseline_retirement_intent', synthetic_cleanup => $cleanup});
    {
        local *NativeProxyPrivateWorkspace::_node = \&NativeProxyPrivateWorkspaceBaseline::_node;
        my $value = eval { NativeProxyRuntimeRetirement::retire_runtime_reference($plan->{store}, $acquired, $cleanup) };
        emit({event => 'baseline_retirement', result => $value, error => $@, census => census()});
    }
    emit({event => 'retirement_intent', synthetic_cleanup => $cleanup});
    my $retired = NativeProxyRuntimeRetirement::retire_runtime_reference($plan->{store}, $acquired, $cleanup);
    emit({event => 'retired', result => $retired, census => census()});
    die 'transferred source descriptor left open' if grep { defined fileno($_) } @handles;
    die 'forbidden process attempt' if $forbidden;
    emit({event => 'complete', forbidden_process_attempts => $forbidden,
          transferred_handles_closed => scalar(@handles), synthetic_cleanup_only => 1});
    1;
};
my $error = $@;
alarm(0);
emit({event => 'fatal', error => $error}) unless $ok;
close($journal) or die $!;
die $error unless $ok;
print "Bounded inert wrapper qualification settled; independent review required.\n";

sub read_bytes {
    my ($path, $limit) = @_;
    sysopen(my $fh, "$ROOT/$path", O_RDONLY | O_NOFOLLOW | O_NONBLOCK) or die "read $path: $!";
    my @s = stat($fh);
    die 'bounded regular evidence required' unless S_ISREG($s[2]) && $s[7] <= $limit;
    my $bytes = '';
    while (length($bytes) <= $limit) {
        my $n = sysread($fh, my $chunk, $limit + 1 - length($bytes));
        die $! unless defined $n;
        last unless $n;
        $bytes .= $chunk;
    }
    my @after = stat($fh); my @named = lstat("$ROOT/$path");
    die 'evidence changed' unless length($bytes) == $s[7] && length($bytes) <= $limit
        && join(':', @s[0,1,2,3,4,7,9,10]) eq join(':', @after[0,1,2,3,4,7,9,10])
        && join(':', @s[0,1,2,3,4,7,9,10]) eq join(':', @named[0,1,2,3,4,7,9,10]);
    close($fh) or die $!;
    return $bytes;
}

sub emit {
    my $raw = $JSON->encode($_[0]) . "\n";
    $journal_bytes += length($raw);
    die 'qualification journal ceiling' if $journal_bytes > $plan->{limits}{journal_bytes};
    print {$journal} $raw or die $!;
}

# This reader does not call the prototype's census, custody or removal helpers.
sub census {
    my (%nodes, @absent);
    my $walk;
    $walk = sub {
        my ($path, $depth) = @_;
        die 'independent census bound' if $depth > $plan->{limits}{depth} || keys(%nodes) >= $plan->{limits}{nodes};
        my @s = lstat("$ROOT/$path");
        die 'independent ownership' unless @s && $s[0] == (stat($ROOT))[0] && $s[4] == $<;
        my $node = {device => $s[0], inode => $s[1], mode => $s[2] & 07777, uid => $s[4]};
        $nodes{$path} = $node;
        if (S_ISDIR($s[2])) {
            die 'directory permissions' unless $node->{mode} == 0700;
            $node->{kind} = 'directory';
            opendir(my $dir, "$ROOT/$path") or die $!;
            my @names = sort grep { $_ ne '.' && $_ ne '..' } readdir($dir);
            closedir($dir) or die $!;
            die 'directory width' if @names > $plan->{limits}{nodes};
            $walk->("$path/$_", $depth + 1) for @names;
        } else {
            die 'independent type' unless S_ISREG($s[2]);
            my $bytes = read_bytes($path, $plan->{limits}{fixture_file_bytes});
            @$node{qw(kind links size_bytes sha256)} = ('file', $s[3], length($bytes), sha256_hex($bytes));
        }
        my @after = lstat("$ROOT/$path");
        die 'independent node changed' unless join(':', @s[0,1,2,3,4,7,9,10]) eq join(':', @after[0,1,2,3,4,7,9,10]);
    };
    for my $path ((map { $_->{root} } @{$plan->{cases}}), @$plan{qw(workspace store)}) {
        if (lstat("$ROOT/$path")) { $walk->($path, 0); }
        else { die 'absence error' unless $!{ENOENT}; push @absent, $path; }
    }
    my $total = 0; $total += $_->{size_bytes} // 0 for values %nodes;
    die 'independent aggregate bound' if $total > $plan->{limits}{total_fixture_bytes};
    return {nodes => \%nodes, absent => \@absent};
}
