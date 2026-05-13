#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::HDL::FlattenedDT;
use FSM::Pipeline::SourceFrontend;
use FSM::Scheduler::ISF;

my $source = <<'ISF';
(actor rule_shorthand
  (clock clk)
  (reset (rst_n async active_low))
  (interface
    (input ready)
    (output valid)
    (output shadow_valid)
    (output done))
  (transaction main_transfer
    (on main_transfer_start)
    (complete done))
  (rule always_ready ready
    (valid 1)
    (trigger main_transfer))
  (rule legacy_ready
    (when ready)
    (shadow_valid 1)))
ISF

my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'rule-shorthand.isf');
my %rule_by_name = map { $_->{name} => $_ } @{$actor->{rules}};

is_deeply(
    $rule_by_name{always_ready}{when},
    ['when', 'ready'],
    'shorthand scalar rule guard normalizes into the public when field',
);
is(
    scalar(@{$rule_by_name{always_ready}{actions}}),
    2,
    'shorthand scalar rule guard is not retained as an action',
);
ok(
    (grep { ref($_) eq 'ARRAY' && $_->[0] eq 'trigger' } @{$rule_by_name{always_ready}{actions}}),
    'shorthand guarded rule keeps trigger action',
);
is_deeply(
    $rule_by_name{legacy_ready}{when},
    ['when', 'ready'],
    'long-form rule guard still normalizes into the same public when field',
);

my $result = FSM::Scheduler::ISF->new()->lower($actor);
my $fsm = $result->{files}{'rule_shorthand.fsm'};

like(
    $fsm,
    qr/\(-always_ready\s+\(<ready\s+\(<- \(valid 1\)\)\s+\(<1 \(main_transfer_start 1\)\)\s+\)\s+\)/s,
    'shorthand guarded rule lowers to the same factored guard block',
);
like(
    $fsm,
    qr/\(-legacy_ready\s+\(<ready\s+\(<- \(shadow_valid 1\)\)\s+\)\s+\)/s,
    'long-form guarded rule remains supported',
);

my $tempdir = tempdir(CLEANUP => 1);
my $fsm_path = File::Spec->catfile($tempdir, 'rule_shorthand.fsm');
write_file($fsm_path, $fsm);

my $raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
    fsm_file => $fsm_path,
    debug_level => 0,
);
my $fsm_module = FSM::Pipeline::SourceFrontend->create_fsm_module(
    raw_ast => $raw_ast,
    debug_level => 0,
);
ok($fsm_module, 'scheduled .fsm from shorthand rule parses through the normal .fsm frontend');

my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
like($hdl, qr/\bmodule\s+rule_shorthand\b/, 'shorthand rule reaches HDL generation');

my $duplicate_guard = <<'ISF';
(actor bad_rule_guard
  (clock clk)
  (interface
    (input ready)
    (input other)
    (output valid))
  (rule duplicate ready
    (when other)
    (valid 1)))
ISF

my $ok = eval {
    FSM::Adapter::ISF->new()->parse_source($duplicate_guard, 'bad-rule-guard.isf');
    1;
};
ok(!$ok, 'rule rejects mixed shorthand and long-form guards');
like(
    $@,
    qr/rule 'duplicate' accepts only one guard condition/,
    'duplicate rule guard diagnostic is targeted',
);

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
