package CurrentStackSampler;
use strict;
use warnings;
use JSON::PP ();
use Time::HiRes ();
my $owner_pid = $$;
my $busy = 0;
my $encoder = JSON::PP->new->canonical->ascii;
open my $out, '>', $ENV{FSMGEN_STACK_SAMPLE_OUTPUT} or die "Cannot open owned stack samples: $!";
$SIG{ALRM} = sub {
    local $@; local $!; local $?;
    return if $$ != $owner_pid || $busy;
    $busy = 1;
    my @frames;
    for my $depth (0 .. 63) {
        my @frame = caller($depth);
        last unless @frame;
        push @frames, {package => $frame[0], file => $frame[1], line => $frame[2], subroutine => $frame[3]};
    }
    my $text = $encoder->encode({pid => $$, wall_time => Time::HiRes::time(), frames => \@frames}) . "\n";
    syswrite($out, $text) == length($text) or die "Cannot retain stack sample: $!";
    $busy = 0;
};
Time::HiRes::ualarm(250000, 250000);
END { Time::HiRes::ualarm(0) if $$ == $owner_pid; }
1;
