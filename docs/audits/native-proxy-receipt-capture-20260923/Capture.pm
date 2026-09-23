package NativeProxyReceiptCapture;

use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use Fcntl qw(O_RDONLY O_WRONLY O_CREAT O_EXCL O_NOFOLLOW);
use File::Basename qw(dirname);
use IO::Handle ();
use JSON::PP ();
use Scalar::Util qw(refaddr);
use FSM::ProjectDataLocality qw(ensure_project_artifact_dir repository_root);
use FSM::Test::RustProxyFixture ();
use FSM::Test::ProcessSupervisor ();
use Admission;
use ReceiptAdapter;
use CompilerProfile;

my $JSON = JSON::PP->new->canonical->ascii->pretty;
my $ROOT = repository_root();

sub _output_parts { return qw(tmp compiler-receipt-capture-20260923); }
sub _workspace_relative {
    return '.artifacts/tmp/process-supervisor-tests/fsmgen-CompilerReceipt20260923';
}

sub _write_once {
    my ($path, $record) = @_;
    my $bytes = $JSON->encode(_portable($record));
    # Evidence paths are portable. Installed tool/SDK paths are explicit
    # read-only dependencies; the generated proxy is never executed here.
    die "capture record exceeds its bound\n" if length($bytes) > 131_072;
    sysopen(my $fh, $path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0600)
        or die "cannot exclusively create capture record: $!\n";
    binmode($fh);
    print {$fh} $bytes or die "cannot write capture record: $!\n";
    $fh->flush or die "cannot flush capture record: $!\n";
    $fh->sync or die "cannot sync capture record: $!\n";
    close($fh) or die "cannot close capture record: $!\n";
    # Flush the record entry and any newly created ancestor entries as well.
    my $directory_path = dirname($path);
    while (1) {
        die "capture directory escaped repository\n"
            unless $directory_path eq $ROOT || index($directory_path, "$ROOT/") == 0;
        sysopen(my $directory, $directory_path, O_RDONLY | O_NOFOLLOW)
            or die "cannot open capture directory for sync: $!\n";
        $directory->sync or die "cannot sync capture directory: $!\n";
        close($directory) or die "cannot close capture directory: $!\n";
        last if $directory_path eq $ROOT;
        $directory_path = dirname($directory_path);
    }
}

sub _portable {
    my ($value) = @_;
    return {map { $_ => _portable($value->{$_}) } keys %$value} if ref($value) eq 'HASH';
    return [map { _portable($_) } @$value] if ref($value) eq 'ARRAY';
    return '.' if defined($value) && !ref($value) && $value eq $ROOT;
    return $value unless defined($value) && !ref($value) && index($value, "$ROOT/") >= 0;
    $value =~ s{\Q$ROOT/\E}{}g;
    return $value;
}

sub _plan {
    my ($revision) = @_;
    return {
        source_revision => $revision, execution => 'closed', permit => 'unissued',
        sealed_return => NativeProxyReceiptAdmission::sealed_return_name(),
        roles => NativeProxyReceiptAdmission::required_roles(),
        private_fields => NativeProxyReceiptAdmission::required_private_fields(),
        replay_original => 0, replay_proxy => 0, live_collector => 0,
    };
}

sub _source_identity {
    my %pins;
    for my $path (
        'docs/audits/native-proxy-receipt-capture-20260923/Capture.pm',
        'docs/audits/native-proxy-receipt-capture-20260923/capture.pl',
        'docs/audits/native-proxy-receipt-admission-20260922/Admission.pm',
        'docs/audits/native-proxy-receipt-adapter-20260922/ReceiptAdapter.pm',
        'docs/audits/native-proxy-compiler-census-policy-admission-20260913/CompilerProfile.pm',
        'perl/FSM/Support/ProcessSupervisor.pm',
        'perl/FSM/ProjectDataLocality.pm',
        't/lib/FSM/Test/ProcessSupervisor.pm',
        't/lib/FSM/Test/RustProxyFixture.pm',
        't/fixtures/rust-tool-proxy.c',
    ) {
        open(my $fh, '<:raw', "$ROOT/$path") or die "cannot read capture source $path: $!\n";
        my $bytes = do { local $/; <$fh> };
        close($fh) or die "cannot close capture source: $!\n";
        $pins{$path} = sha256_hex($bytes);
    }
    return \%pins;
}

sub _snapshot {
    my ($job, $plan, $token) = @_;
    die "sealed compiler returned no private job\n" unless ref($job) eq 'HASH';
    my $observation = $job->{receipt_observation};
    my $shared = ref($observation) eq 'HASH' && ref($job->{cleanup}) eq 'HASH'
        && ref($observation->{cleanup}) eq 'HASH'
        && refaddr($job->{cleanup}) == refaddr($observation->{cleanup})
        && refaddr($job->{cleanup}) == ($observation->{cleanup_identity} // -1);
    my $raw = $job->{leader_status};
    my $result = $job->{result};
    my $wait_matches = defined($raw) && ref($result) eq 'HASH'
        && defined($result->{signal}) && $result->{signal} == ($raw & 127)
        && (($raw & 127) ? !defined($result->{exit_code})
            : defined($result->{exit_code}) && $result->{exit_code} == ($raw >> 8));
    return {
        schema => 'fsmgen.compiler_receipt_capture.v1',
        private_state => {map { $_ => $job->{$_} }
            qw(phase stage pid birth_sec birth_usec leader_status leader_reaped cleanup)},
        observation => $observation, result => $result,
        review => {
            original_cleanup_shared => $shared ? 1 : 0,
            raw_wait_matches => $wait_matches ? 1 : 0,
            finished_job_accepted => NativeProxyReceiptAdmission::execution_allowed($plan, $token, $job) ? 1 : 0,
            receipt_bound => NativeProxyReceiptAdapter::receipts_bound([$observation], {closed => 1}) ? 1 : 0,
        },
        scope => 'Direct supervised fork and wait; birth is the supervisor wall-clock observation, not kernel birth authentication. Serialized cleanup identity is evidence, not reusable authority.',
    };
}

sub run_capture {
    local $SIG{ALRM} = sub { die "non-compiler capture phase exceeded its wall\n"; };
    my $result;
    my $ok = eval { alarm(30); $result = _run_capture(@_); 1 };
    my $error = $@;
    alarm(0);
    die $error unless $ok;
    return $result;
}

sub _run_capture {
    my ($revision) = @_;
    die "one clean source revision is required\n"
        unless @_ == 1 && defined($revision) && !ref($revision) && $revision =~ /\A[0-9a-f]{40}\z/;
    my $selection = FSM::Test::RustProxyFixture::_selection();
    die "the fixed native compiler profile is unavailable\n"
        unless $selection->{implementation} eq 'native';
    my $out = ensure_project_artifact_dir(_output_parts());
    my $workspace = _workspace_relative();
    my $plan = _plan($revision);
    # The caller independently proves clean Git/HEAD before invocation. These
    # pins record the actual local bytes without inventing a Git-state oracle.
    _write_once("$out/attempt.json", {
        schema => 'fsmgen.compiler_receipt_attempt.v1', plan => $plan,
        source_files => _source_identity(), selection => $selection,
        workspace => $workspace, mode => 'proxy_nonzero',
        revision_authority => 'Caller clean-Git preflight; source_files are captured bytes.',
    });
    my $token = NativeProxyReceiptAdmission::issue_permit($plan)
        or die "compiler permit issue refused\n";
    NativeProxyReceiptAdmission::consume_permit($plan, $token)
        or die "compiler permit consume refused\n";
    ensure_project_artifact_dir(qw(tmp process-supervisor-tests));
    my ($absolute, $error) = FSM::Test::ProcessSupervisor::repository_contained_path($workspace);
    die "invalid compiler workspace: $error\n" if defined $error;
    mkdir($absolute, 0700) or die "cannot exclusively create compiler workspace: $!\n";
    my ($first, $calls);
    my $prepared;
    {
        no warnings 'redefine';
        local *FSM::Test::RustProxyFixture::supervise_process = sub {
            my %request = @_;
            die "compiler invocation budget exceeded\n" if ++$calls > 1;
            die "compiler request differs from the fixed fixture\n"
                unless $JSON->encode(\%request) eq $JSON->encode(
                    NativeProxyCompilerProfile::expected_request($ROOT, $workspace, $selection));
            die "compiler environment differs from the fixed fixture\n"
                unless $JSON->encode(\%ENV) eq $JSON->encode(
                    NativeProxyCompilerProfile::expected_environment($ROOT, $workspace, $selection));
            NativeProxyReceiptAdmission::begin_compiler_capture($plan, $token)
                or die "compiler launch grant refused\n";
            _write_once("$out/launch.json", {request => \%request, environment => {%ENV}});
            # Never interrupt the supervisor's custody with our phase alarm.
            alarm(0);
            my $job = FSM::Test::ProcessSupervisor::sealed_supervise_process(
                %request, environment => {%ENV},
            );
            alarm(30);
            $first = _snapshot($job, $plan, $token);
            _write_once("$out/first-state.json", $first);
            die "first compiler receipt did not settle\n"
                if grep { !$first->{review}{$_} } keys %{$first->{review}};
            return $job->{result};
        };
        $prepared = FSM::Test::RustProxyFixture::prepare_rust_proxy($absolute, 'proxy_nonzero');
    }
    _write_once("$out/preparation.json", $prepared);
    alarm(0);
    die "first compiler capture failed; retain its evidence and workspace\n"
        unless $prepared->{ok} && defined($first)
            && !grep { !$first->{review}{$_} } keys %{$first->{review}};
    return $first;
}

1;
