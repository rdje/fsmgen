use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin", "$Bin/../../../t/lib", "$Bin/../../../perl",
    "$Bin/../native-proxy-runtime-retirement-20260910",
    "$Bin/../native-proxy-image-custody-20260910",
    "$Bin/../native-proxy-image-coordination-20260910";
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use Fcntl qw(O_WRONLY O_CREAT O_EXCL O_APPEND O_NOFOLLOW S_ISDIR);
use JSON::PP ();
use FSM::Test::RustProxyFixture qw(prepare_rust_proxy);
use PrivateWorkspace;
use CompilerProfile;

my $ROOT = abs_path("$Bin/../../..");
my $JSON = JSON::PP->new->canonical->ascii;
my ($PLAN, $OUT, $sequence, $journal_bytes) = (undef, undef, 0, 0);

sub read_json {
    my ($path, $limit) = @_;
    open(my $fh, '<', $path) or die "cannot read admission input: $!\n";
    binmode($fh);
    my $count = read($fh, my $raw, $limit + 1);
    die "admission input exceeds bound\n" unless defined($count) && $count <= $limit;
    close($fh) or die "cannot close admission input: $!\n";
    return $JSON->decode($raw);
}

sub exclusive {
    my ($path, $raw, $mode) = @_;
    sysopen(my $fh, $path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, $mode)
        or die "exclusive profile output failed: $!\n";
    binmode($fh);
    print {$fh} $raw or die "profile output write failed: $!\n";
    close($fh) or die "profile output close failed: $!\n";
}

sub journal {
    my ($event, %fields) = @_;
    my $raw = $JSON->encode({sequence => ++$sequence, event => $event, %fields}) . "\n";
    die "profile journal byte ceiling\n" if $journal_bytes + length($raw) > $PLAN->{evidence_limits}{journal_bytes};
    sysopen(my $fh, "$OUT/journal.jsonl", O_WRONLY | O_APPEND | O_NOFOLLOW)
        or die "profile journal open failed: $!\n";
    binmode($fh);
    print {$fh} $raw or die "profile journal write failed: $!\n";
    close($fh) or die "profile journal close failed: $!\n";
    $journal_bytes += length($raw);
}

sub census {
    my ($workspace) = @_;
    my (@nodes, $total);
    $total = 0;
    my $ok = eval { NativeProxyPrivateWorkspace::_walk($workspace, 0, \@nodes, \$total); 1 };
    my $error = $@;
    $error =~ s/\Q$ROOT\E/./g;
    return {ok => $ok ? 1 : 0, error => substr($error, 0, 2048), nodes => \@nodes, file_bytes => $total};
}

sub execute {
    die "exact compiler-census invocation required\n" unless @ARGV == 1 && $ARGV[0] eq '--execute-admitted';
    $PLAN = read_json("$Bin/plan.json", 65536);
    $OUT = "$ROOT/$PLAN->{output}";
    die "normal-user Perl identity required\n" unless $< > 0 && $< == $> && abs_path($^X) eq '/usr/bin/perl';
    chdir($ROOT) or die "cannot enter repository\n";
    umask(0077);
    local $SIG{ALRM} = sub { die "non-compiler profile phase exceeded its fixed wall\n"; };
    alarm(30);
    # This read-only preflight emits no permit and must finish before consuming
    # the existing permit. It rechecks committed sources and installed inputs.
    my ($python) = grep { $_->{role} eq 'python' } @{$PLAN->{runtime_interpreters}};
    system($python->{path}, '-B', "$Bin/admission.py", 'check-run') == 0
        or die "committed compiler admission preflight failed\n";
    my $permit = read_json("$OUT/permit.json", 65536);
    exclusive("$OUT/run-start.json", $JSON->encode({permit => $permit, pid => $$, uid => $<}) . "\n", 0600);
    exclusive("$OUT/journal.jsonl", '', 0600);
    my $selection = FSM::Test::RustProxyFixture::_selection();
    die "current fixed native selection differs\n" unless $JSON->encode($selection) eq $JSON->encode($PLAN->{selection});
    journal('start', selection => $selection, compiler_invocations => 0);
    my $original = \&FSM::Test::RustProxyFixture::supervise_process;
    my $invocations = 0;
    for my $case (@{$PLAN->{cases}}) {
        alarm(30);
        my $workspace = $case->{workspace};
        journal('workspace_intent', workspace => $workspace, mode => $case->{mode});
        mkdir("$ROOT/$workspace", 0700) or die "cannot exclusively create fixed workspace: $!\n";
        my $owned = NativeProxyPrivateWorkspace::_node($workspace);
        journal('workspace_owned', workspace => $workspace, node => $owned);
        my ($receipt, $prepared);
        {
            no warnings 'redefine';
            local *FSM::Test::RustProxyFixture::supervise_process = sub {
                my %request = @_;
                die "compiler invocation budget exceeded\n" if ++$invocations > 2 || defined($receipt);
                NativeProxyCompilerProfile::validate_request(\%request, \%ENV, $ROOT, $workspace, $selection);
                my $before = census($workspace);
                journal('before_compiler', workspace => $workspace, capture => $before);
                die "pre-compiler census failed\n" unless $before->{ok};
                # The original supervisor owns its child until its own terminal
                # outcome; never interrupt that custody with our phase alarm.
                alarm(0);
                my $result;
                ($result, $receipt) = NativeProxyCompilerProfile::observe(
                    $original, \%request, \%ENV, $ROOT, $workspace, $selection);
                alarm(30);
                journal('compiler_settled', workspace => $workspace, receipt => $receipt);
                die "original compiler custody did not settle\n" unless $receipt->{settled};
                return $result;
            };
            $prepared = prepare_rust_proxy("$ROOT/$workspace", $case->{mode});
        }
        journal('prepared', workspace => $workspace, result => $prepared);
        unless ($prepared->{ok} && defined($receipt) && $receipt->{settled}) {
            journal('failed_preparation_profile', workspace => $workspace, capture => census($workspace))
                if defined($receipt) && $receipt->{settled};
            die "first native compiler preparation failed; retain workspace\n";
        }
        my $compiler = census($workspace);
        my %failed_capture = $compiler->{ok} ? () : (failed_capture => $compiler);
        journal('compiler_profile', workspace => $workspace, ok => $compiler->{ok}, error => $compiler->{error},
                nodes_sha256 => sha256_hex($JSON->encode(NativeProxyCompilerProfile::metadata_projection($compiler))),
                nodes_count => scalar(@{$compiler->{nodes}}), file_bytes => $compiler->{file_bytes}, %failed_capture);
        die "compiler profile incomplete\n" unless $compiler->{ok};
        journal('controlled_roles_intent', workspace => $workspace);
        exclusive("$ROOT/$workspace/$PLAN->{wrapper}{path_suffix}", pack('H*', $PLAN->{wrapper}{bytes_hex}), 0700);
        chmod($PLAN->{wrapper}{mode}, "$ROOT/$workspace/$PLAN->{wrapper}{path_suffix}") == 1
            or die "cannot set exact wrapper mode\n";
        symlink($PLAN->{cargo_role}{relative_target}, "$ROOT/$workspace/$PLAN->{cargo_role}{path_suffix}")
            or die "cannot create controlled relative Cargo link: $!\n";
        my $final = census($workspace);
        journal('complete_profile', workspace => $workspace, capture => $final);
        die "complete profile incomplete\n" unless $final->{ok};
    }
    journal('finished', compiler_invocations => $invocations, proxy_invocations => 0, wrapper_invocations => 0);
    alarm(0);
}

my $ok = eval { execute(); 1 };
my $error = $@;
alarm(0);
unless ($ok) {
    $error =~ s/\Q$ROOT\E/./g;
    $error = substr($error, 0, 2048);
    # Failure recording never removes a workspace or grants another launch.
    eval { journal('failed', error => $error) } if defined($OUT) && -f "$OUT/journal.jsonl";
    print STDERR $error;
    exit 1;
}
exit 0;
