#!/usr/bin/env perl
use strict;
use warnings;
our $FORBIDDEN = 0;
BEGIN {
    *CORE::GLOBAL::fork = sub { ++$FORBIDDEN; die "unadmitted worker fork\n"; };
    *CORE::GLOBAL::system = sub { ++$FORBIDDEN; die "unadmitted worker system command\n"; };
}
use FindBin;
use lib $FindBin::Bin, "$FindBin::Bin/../../../perl", "$FindBin::Bin/../../../t/lib",
    map { "$FindBin::Bin/../$_" } qw(native-proxy-image-custody-20260910
        native-proxy-image-coordination-20260910 native-proxy-image-publication-20260910
        native-proxy-runtime-records-20260910 native-proxy-runtime-census-20260910
        native-proxy-runtime-acquisition-20260910 native-proxy-runtime-retirement-20260910
        native-proxy-image-maintenance-20260910 native-proxy-cleanup-receipts-20260910
        native-proxy-observation-records-20260910 native-proxy-observation-acquisition-20260910
        native-proxy-observation-archive-records-20260911 native-proxy-observation-archive-20260911
        native-proxy-observation-work-records-20260911 native-proxy-observation-archive-release-20260911);
use Digest::SHA qw(sha256_hex);
use Cwd qw(abs_path);
use JSON::PP ();
use Time::HiRes qw(alarm);
use FSM::ProjectDataLocality qw(repository_root);
use FSM::Test::RustProxyFixture ();
BEGIN { *CORE::GLOBAL::exec = sub { ++$FORBIDDEN; die "unadmitted worker exec\n"; }; }
use Coordination;
use ReferenceAcquisition;
use RuntimeRetirement;
use ImageMaintenance;
use ObservationAcquisition;
use ObservationArchive;
use ObservationRelease;
use WorkRecord;
use Protocol;
use WorkerIO;
use Wire;

my $ROOT = repository_root();
my $BASE = 'docs/audits/native-proxy-populated-worker-protocol-20260913';
my $OUTPUT = '.artifacts/logs/native-proxy-populated-workers-20260913';
my $JSON = JSON::PP->new->canonical->ascii;
my $IO;

sub source_bytes {
    my ($relative) = @_;
    NativeProxyImageCustody::_relative_path($relative);
    my ($bytes) = FSM::Test::RustProxyFixture::_read_file("$ROOT/$relative", 0);
    return $bytes;
}

sub bootstrap {
    die "expected one fixed case and role\n" unless @ARGV == 2;
    my ($case_name, $role) = @ARGV;
    die "worker must be a normal-user session leader\n" unless $< != 0 && $> == $< && getpgrp(0) == $$;
    my $contract_bytes = source_bytes("$BASE/contract.json");
    my $contract = $JSON->decode($contract_bytes);
    die "worker output namespace differs\n" unless $contract->{output} eq $OUTPUT;
    my @cases = grep { $_->{name} eq $case_name } @{$contract->{cases}};
    die "undeclared case or role\n" unless @cases == 1 && exists($cases[0]{roles}{$role});
    $IO = NativeProxyPopulatedWorkerIO->new($ROOT, $contract, $cases[0], $role);

    # Final admission owns these exact canonical files. This worker has no
    # issuer and cannot execute merely because its source contract is present.
    my $start = $IO->read_start();
    NativeProxyPopulatedWire::fields($start, qw(schema source_revision controller_pid worker_authority_sha256));
    die "execution marker is not owned by this parent\n"
        unless $start->{schema} eq 'fsmgen.inactive_populated_run_start.v1'
            && NativeProxyPopulatedWire::integer($start->{controller_pid}) == getppid();
    my $authority = $IO->read_sealed("$OUTPUT/worker-authority.json", 65536, $start->{worker_authority_sha256});
    NativeProxyPopulatedWire::fields($authority,
        qw(schema source_revision controller_pid contract_sha256 source_pins worker_wall_seconds output));
    die "worker authority differs from its committed execution marker\n"
        unless $authority->{schema} eq 'fsmgen.inactive_populated_worker_authority.v1'
            && $authority->{source_revision} eq $start->{source_revision}
            && $authority->{source_revision} =~ /\A[0-9a-f]{40}\z/
            && NativeProxyPopulatedWire::integer($authority->{controller_pid}) == getppid()
            && $authority->{contract_sha256} eq sha256_hex($contract_bytes) && $authority->{output} eq $OUTPUT
            && NativeProxyPopulatedWire::integer($authority->{worker_wall_seconds}) == $contract->{protocol}{worker_wall_seconds};
    die "expected finite project-source closure\n" unless ref($authority->{source_pins}) eq 'ARRAY'
        && @{$authority->{source_pins}} >= 5 && @{$authority->{source_pins}} <= 128;
    my %pins;
    for my $pin (@{$authority->{source_pins}}) {
        NativeProxyPopulatedWire::fields($pin, qw(path size_bytes sha256));
        die "duplicate source authority\n" if $pins{$pin->{path}}++;
        NativeProxyPopulatedWire::integer($pin->{size_bytes});
        NativeProxyPopulatedWire::digest($pin->{sha256});
        my $bytes = source_bytes($pin->{path});
        die "worker source differs from admitted bytes\n"
            unless length($bytes) == $pin->{size_bytes} && sha256_hex($bytes) eq $pin->{sha256};
    }
    die "worker source closure omits its entrypoints\n"
        if grep { !$pins{"$BASE/$_"} } qw(worker.pl contract.json Wire.pm Protocol.pm WorkerIO.pm);
    for my $loaded (values %INC) {
        my $absolute = abs_path($loaded);
        die "loaded module path cannot be resolved\n" unless defined($absolute);
        next unless index($absolute, "$ROOT/") == 0;
        my $relative = substr($absolute, length($ROOT) + 1);
        die "loaded project module is absent from source authority\n" unless $pins{$relative};
    }
    $SIG{ALRM} = sub { die "fixed worker wall expired\n"; };
    alarm($contract->{protocol}{worker_wall_seconds});
    $IO->_emit('ready');
    my $command = $IO->_expect('admit', undef);
    my $activation = $IO->read_sealed($cases[0]{activation_path},
        $contract->{protocol}{activation_bytes}, $command->{activation_sha256});
    my $birth = $activation->{births}{$role};
    die "activation native child differs\n" unless ref($birth) eq 'HASH'
        && $birth->{pid} == $$ && $birth->{ppid} == getppid() && $birth->{uid} == $> && $birth->{ruid} == $<;
    my $protocol = NativeProxyPopulatedProtocol->new($contract, $case_name, $role, $activation, $authority->{source_revision});
    while (my $step = $protocol->next_step()) {
        my $payload = $IO->_expect('step', $step);
        my $packet = $step->{operation} =~ /\Aadopt_(?:runtime|observation)\z/
            ? $IO->read_sealed($cases[0]{handoff_path}, $contract->{protocol}{handoff_bytes}, $payload->{handoff_sha256}) : undef;
        my $result = $IO->operation($protocol, $step, $packet);
        $IO->_emit('result', %$result);
    }
    $IO->_expect('finish', undef);
    die "worker attempted a forbidden process operation\n" if $FORBIDDEN;
    $IO->_emit('finished', %{$protocol->finish()}, forbidden_process_attempts => $FORBIDDEN);
    alarm(0);
    return;
}

my ($ok, $first_error);
{
    no warnings 'redefine';
    local *FSM::Test::RustProxyFixture::supervise_process = sub { ++$FORBIDDEN; die "unadmitted compiler\n"; };
    local *FSM::Test::ProcessSupervisor::supervise_process = sub { ++$FORBIDDEN; die "unadmitted subprocess supervisor\n"; };
    $ok = eval { bootstrap(); 1 };
    $first_error = $@;
}
unless ($ok) {
    eval { $IO->_emit('failure', error => $first_error, lock => $IO->{last_lock},
                     forbidden_process_attempts => $FORBIDDEN) } if defined($IO);
    print STDERR $first_error;
    exit 1;
}
exit 0;
