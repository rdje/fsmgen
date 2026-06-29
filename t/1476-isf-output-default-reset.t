#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

my $fixture = <<'ISF';
(actor output_default_reset_probe
  (clock clk)
  (reset (rst_n active_low async))
  (watchdog 32)

  (interface
    (input start)
    (output ready (reset 1) (default 1))
    (output error (reset 0) (default 0))
    (output data (width 8) (reset 0) (default 0)))

  (storage
    (var done_q (width 1) (reset 0)))

  (drive busy
    (ready 0)
    (error 0)
    (data 0))

  (drive complete_ok
    (ready 1)
    (error 0)
    (data 42))

  (transaction main
    (on start)
    (drive busy)
    (drive complete_ok)
    (complete done_q)))
ISF

sub parse_fixture {
    return FSM::Adapter::ISF->new()->parse_source($fixture, 'output_default_reset_probe.isf');
}

subtest 'parser records output reset/default metadata' => sub {
    my $actor = parse_fixture();
    my %outputs = map { $_->{name} => $_ } @{$actor->{interface}{outputs}};

    is($outputs{ready}{reset_value}, 1, 'parser records scalar output reset value');
    is($outputs{ready}{default_value}, 1, 'parser records scalar output default value');
    is($outputs{error}{reset_value}, 0, 'parser records zero output reset value');
    is($outputs{data}{width}, 8, 'parser preserves explicit width');
    is($outputs{data}{default_value}, 0, 'parser records vector output default value');
};

subtest 'lowering emits reset metadata and idle defaults' => sub {
    my $actor = parse_fixture();
    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'output_default_reset_probe.fsm'};
    ok(defined $fsm, 'scheduler emits generated .fsm');

    like($fsm, qr/\(ready 1 \(reset 1\)\)/, 'generated .fsm carries output ready reset metadata');
    like($fsm, qr/\(error 1 \(reset 0\)\)/, 'generated .fsm carries output error reset metadata');
    like($fsm, qr/\(data 8 \(reset 0\)\)/, 'generated .fsm carries output data reset metadata');
    like($fsm, qr/\(main_idle_0\s+\(<- \(data> 0\)\)\s+\(<- \(error> 0\)\)\s+\(<- \(ready> 1\)\)/s,
        'generated .fsm drives output defaults in the transaction idle state');
    like($fsm, qr/\(<- \(ready> 0\) <busy_start\)/, 'explicit named drive still lowers for ready');
    like($fsm, qr/\(<- \(data> 42\) <complete_ok_start\)/, 'explicit named drive still lowers for data');
};

subtest 'SystemVerilog output includes reset and idle assignments' => sub {
    my $tmp = tempdir(CLEANUP => 1);
    my $isf_path = File::Spec->catfile($tmp, 'output_default_reset_probe.isf');
    my $sv_path = File::Spec->catfile($tmp, 'output_default_reset_probe.sv');

    open my $fh, '>', $isf_path or die "cannot write $isf_path: $!";
    print {$fh} $fixture;
    close $fh or die "cannot close $isf_path: $!";

    my ($ok, $err, undef, undef, $stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--output', $sv_path, $isf_path],
        verbose => 0,
    );
    ok($ok, 'CLI generates SystemVerilog for output default/reset fixture')
        or diag(join('', @$stderr), $err // '');

    open my $sv_fh, '<', $sv_path or die "cannot read $sv_path: $!";
    my $sv = do { local $/; <$sv_fh> };
    close $sv_fh or die "cannot close $sv_path: $!";

    like($sv, qr/ready\s*<=\s*1['`]?h1|ready\s*<=\s*1'b1|ready\s*<=\s*1;/,
        'SystemVerilog includes ready reset/default high assignment');
    like($sv, qr/data\s*<=\s*8['`]?h0|data\s*<=\s*8'b0+|data\s*<=\s*0;/,
        'SystemVerilog includes data reset/default zero assignment');
};

subtest 'malformed output reset/default metadata fails closed' => sub {
    my @cases = (
        [
            'input_default',
            '(actor bad (interface (input din (default 0))) (transaction main (on din)))',
            qr/interface input 'din' cannot specify output 'default' metadata/,
        ],
        [
            'malformed_default',
            '(actor bad (interface (input start) (output ready (default))) (transaction main (on start)))',
            qr/interface output 'ready' default requires '\(default V\)'/,
        ],
        [
            'negative_reset',
            '(actor bad (interface (input start) (output ready (reset -1))) (transaction main (on start)))',
            qr/interface output 'ready' reset requires '\(reset V\)'/,
        ],
        [
            'too_wide_reset',
            '(actor bad (interface (input start) (output ready (width 1) (reset 2))) (transaction main (on start)))',
            qr/interface output 'ready' reset value 2 does not fit in 1 bit/,
        ],
        [
            'duplicate_reset',
            '(actor bad (interface (input start) (output ready (reset 0) (reset 1))) (transaction main (on start)))',
            qr/interface port 'ready' has duplicate 'reset' option/,
        ],
        [
            'unresolved_width_default',
            '(actor bad (interface (input start) (output data (width WIDTH) (default 0))) (transaction main (on start)))',
            qr/interface output 'data' output reset\/default metadata requires a resolved positive integer width/,
        ],
        [
            'type_referenced_default',
            '(actor bad (types (type word (bits 8))) (interface (input start) (output data (type word) (default 0))) (transaction main (on start)))',
            qr/interface output 'data' output reset\/default metadata requires a resolved positive integer width; '\(type \.\.\.\)' outputs remain deferred/,
        ],
    );

    for my $case (@cases) {
        my ($name, $source, $pattern) = @$case;
        my $ok = eval {
            FSM::Adapter::ISF->new()->parse_source($source, "$name.isf");
            1;
        };
        ok(!$ok, "$name rejected");
        like($@, $pattern, "$name diagnostic is targeted");
    }
};

done_testing;
