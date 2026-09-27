package GroupWitness;
use strict;
use warnings;
use DynaLoader ();
use JSON::PP ();
use Time::HiRes qw(clock_gettime CLOCK_MONOTONIC);
use FSM::Support::ProcessSupervisor ();

my ($library_handle, $sink, $real_call);
my $sequence = 0;
my $json = JSON::PP->new->canonical;
my $row_limit = 4096;
my $byte_limit = 1_048_576;
my $record_error;
our $label = 'unlabelled';

sub load_context {
    my ($class, $path) = @_;
    die "native context already loaded\n" if $library_handle;
    $library_handle = DynaLoader::dl_load_file($path, 0)
        or die DynaLoader::dl_error();
    my $symbol = DynaLoader::dl_find_symbol($library_handle, 'witness_context')
        or die DynaLoader::dl_error();
    DynaLoader::dl_install_xsub('GroupWitness::context', $symbol, __FILE__);
}

sub record {
    my ($value) = @_;
    my $saved_errno = 0 + $!;
    my $encoded = $json->encode($value) . "\n";
    my @state = stat($sink);
    die "witness record exceeds capture envelope\n"
        unless length($encoded) <= $row_limit && @state
            && $state[7] + length($encoded) <= $byte_limit;
    # Each selected fixture has only its parent and one live child writing.
    # One O_APPEND write preserves each row; the verifier rejects partial,
    # missing, excess or malformed capture instead of admitting it.
    my $written = syswrite($sink, $encoded);
    die "witness record write failed\n"
        unless defined($written) && $written == length($encoded);
    $! = $saved_errno;
    return 1;
}

sub install {
    my ($class, $handle) = @_;
    die "native context not loaded\n" unless $library_handle;
    die "witness already installed\n" if $real_call;
    $sink = $handle;
    $real_call = \&FSM::Support::ProcessSupervisor::setpgid;
    no warnings 'redefine';
    *FSM::Support::ProcessSupervisor::setpgid = sub {
        my @arguments = @_;
        my $incoming_errno = 0 + $!;
        my $before = context($arguments[0]);
        my $start_ns = int(clock_gettime(CLOCK_MONOTONIC) * 1_000_000_000);
        $! = $incoming_errno;
        my $result = $real_call->(@arguments);
        my $native_errno = 0 + $!;
        my $end_ns = int(clock_gettime(CLOCK_MONOTONIC) * 1_000_000_000);
        my $after = context($arguments[0]);
        my $entry = {
            event => 'setpgid', label => $label, pid => $$, sequence => ++$sequence,
            arguments => \@arguments, result => $result, errno => $native_errno,
            incoming_errno => $incoming_errno,
            start_ns => $start_ns, end_ns => $end_ns,
            before => $before, after => $after,
        };
        eval { record($entry); 1 } or do {
            $record_error = $@ || 'unclassified witness capture failure';
            warn $record_error;
        };
        $! = $native_errno;
        return $result;
    };
}

sub capture_error { return $record_error }
1;
