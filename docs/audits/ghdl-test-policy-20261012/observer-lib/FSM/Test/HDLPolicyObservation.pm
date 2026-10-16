package FSM::Test::HDLPolicyObservation;
use strict;
use warnings;
use Fcntl qw(O_CREAT O_EXCL O_WRONLY);
use File::Basename qw(basename);
use JSON::PP ();
use FSM::Test::HDLBehaviorRuntime ();

# Qualification-only observation of the unchanged admitted call and return.
# The production/test adapter keeps its normal interface and result identity.
my $original = \&FSM::Test::HDLBehaviorRuntime::_execute;
my $sequence = 0;
{
    no warnings qw(redefine once);
    *FSM::Test::HDLBehaviorRuntime::_execute = sub {
        my ($profile, $stage, $workspace, $argv, $cwd) = @_;
        my @command = @$argv;
        my $result = $original->(@_);
        my $folder = $ENV{FSMGEN_HDL_POLICY_OBSERVATION};
        die 'invalid qualification observation directory'
            unless defined($folder) && !ref($folder)
                && $folder =~ m{\A\.artifacts/ghdl-test-policy-20261012/native/[a-z0-9-]+\z}
                && -d $folder;
        my $test = basename($0);
        die 'invalid qualification test identity' unless $test =~ /\A[0-9a-z.-]+\z/;
        my $name = sprintf('%s/%s-%d-%04d.json', $folder, $test, $$, ++$sequence);
        sysopen my $stream, $name, O_WRONLY | O_CREAT | O_EXCL, 0600 or die $!;
        binmode $stream;
        print {$stream} JSON::PP->new->canonical->utf8->encode({
            observer => 'qualification-only admitted call/return',
            test => $test, test_pid => $$, sequence => $sequence,
            profile => $profile, stage => $stage, argv => \@command,
            workspace => $workspace, cwd => defined($cwd) ? $cwd : $workspace,
            native => $result,
        }), "\n" or die $!;
        close $stream or die $!;
        return $result;
    };
}
1;
