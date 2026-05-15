use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'perl';

use FSM::Pipeline::HDLGenerator;

subtest 'plain explicit top-input convention failures say the convention is blocked' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'blocked_plain_input_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:blocked_plain_input_top
  (?ports:public_io
    foo<8
  )
  (?dtc:producer producer_src)
  (?dtc:consumer consumer_src)
  (?wiring:wiring
    /producer.bridge/consumer.bridge/
  )
)

(?dt:producer_src
  (-route
    (foo> = 8'3)
    (bridge> = 8'1)
  )
  (+size
    (foo 8)
    (bridge 8)
  )
)

(?dt:consumer_src
  (-route
    (sink> = (+ foo bridge))
  )
  (+size
    (foo 8)
    (bridge 8)
    (sink 8)
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $exception = eval {
        $pipeline->generate_hdl_from_file($composition_path);
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/declares top input 'foo'.*same-name top-input convention is blocked because same-name child endpoints include incompatible directions/s,
        'plain explicit top-input failure now says same-name convention is blocked',
    );
    like(
        $exception,
        qr/producer\.foo\[output, width=8\], consumer\.foo\[input, width=8\]/s,
        'plain explicit top-input blocked diagnostic still lists the conflicting endpoints',
    );
};

subtest 'plain explicit top-output convention failures say the convention is blocked' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'blocked_plain_output_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:blocked_plain_output_top
  (?ports:public_io
    go
    shared_status>8
  )
  (?dtc:left left_src)
  (?dtc:right right_src)
  (?wiring:wiring
    /go/left.go/
    /go/right.go/
  )
)

(?dt:left_src
  (-route
    (<go
      (shared_status> = 8'1)
    )
  )
  (+size
    (go 1)
    (shared_status 8)
  )
)

(?dt:right_src
  (-route
    (<go
      (shared_status> = 8'2)
    )
  )
  (+size
    (go 1)
    (shared_status 8)
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $exception = eval {
        $pipeline->generate_hdl_from_file($composition_path);
        undef;
    };
    $exception = $@;

    like(
        $exception,
        qr/declares top output 'shared_status'.*same-name top-output convention is blocked because several same-name child outputs remain top-facing/s,
        'plain explicit top-output failure now says same-name convention is blocked',
    );
    like(
        $exception,
        qr/left\.shared_status\[output, width=8\], right\.shared_status\[output, width=8\]/s,
        'plain explicit top-output blocked diagnostic still lists the competing child outputs',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} $content;
    close $fh or die "Unable to close $path: $!";
}
