#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw/ tempdir /;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;

my $tempdir = tempdir(CLEANUP => 1);
my $fsm_path = File::Spec->catfile($tempdir, 'assignment_intent_snapshot.fsm');

write_file($fsm_path, <<'FSM');
(?fsm:assignment_intent_phase1
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (A <- B)
    (C <= D)
    (E = F)
    (G> = H)
    (I <-= J)
    (K <=+ L)
    (P1 <3 1)
    (P0 <2 0)
  )
  (+size
    (A 8)
    (B 8)
    (C 8)
    (D 8)
    (E 1)
    (F 1)
    (G 1)
    (H 1)
    (I 8)
    (J 8)
    (K 8)
    (L 8)
    (P1 1)
    (P0 1)
  )
)
FSM

my $raw_ast = Lispish::multi($fsm_path);
my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
my $fsm_module = $adapter->parse_fsm($raw_ast);
ok($fsm_module, 'parsed snapshot FSM module');

my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
ok($hdl && $hdl ne '', 'generated HDL for snapshot comparison');

my $ports_snippet = extract_required(
    $hdl,
    qr/(module assignment_intent_phase1\s*\(.*?\n\);)/s,
    'module ports snippet'
);
my $rm_snippet = extract_required(
    $hdl,
    qr/(  \/\/ Unified Multiplexer for LHS: I\n.*?)(?=\n  \/\/ Unified Multiplexer for LHS: K\n)/s,
    'rm snippet'
);
my $mr_snippet = extract_required(
    $hdl,
    qr/(  \/\/ Unified Multiplexer for LHS: K\n.*?)(?=\n  \/\/ Unified Multiplexer for LHS: P0\n)/s,
    'mr snippet'
);
my $p0_snippet = extract_required(
    $hdl,
    qr/(  \/\/ Unified Multiplexer for LHS: P0\n.*?)(?=\n  \/\/ Unified Multiplexer for LHS: P1\n)/s,
    'p0 snippet'
);
my $p1_snippet = extract_required(
    $hdl,
    qr/(  \/\/ Unified Multiplexer for LHS: P1\n.*?)(?=\nendmodule\n)/s,
    'p1 snippet'
);

is(
    normalize_text($ports_snippet),
    normalize_text(read_file(File::Spec->catfile($FindBin::Bin, 'golden', 'assignment_intent_phase1.ports.sv.golden'))),
    'golden snapshot: module ports include expected rm/mr exposed outputs'
);
is(
    normalize_text($rm_snippet),
    normalize_text(read_file(File::Spec->catfile($FindBin::Bin, 'golden', 'assignment_intent_phase1.rm.sv.golden'))),
    'golden snapshot: rm (<-=) block emits next_* exposure behavior'
);
is(
    normalize_text($mr_snippet),
    normalize_text(read_file(File::Spec->catfile($FindBin::Bin, 'golden', 'assignment_intent_phase1.mr.sv.golden'))),
    'golden snapshot: mr (<=+) block emits *_r exposure behavior'
);
is(
    normalize_text($p0_snippet),
    normalize_text(read_file(File::Spec->catfile($FindBin::Bin, 'golden', 'assignment_intent_phase1.p0.sv.golden'))),
    'golden snapshot: pN (<2 0) block emits exact Q+N delayed negative pulse'
);
is(
    normalize_text($p1_snippet),
    normalize_text(read_file(File::Spec->catfile($FindBin::Bin, 'golden', 'assignment_intent_phase1.p1.sv.golden'))),
    'golden snapshot: pN (<3 1) block emits exact Q+N delayed positive pulse'
);

done_testing();

sub extract_required {
    my ($text, $pattern, $label) = @_;
    my ($match) = $text =~ $pattern;
    ok(defined $match, "extracts $label");
    return defined($match) ? $match : '';
}

sub normalize_text {
    my ($text) = @_;
    $text //= '';
    $text =~ s/\r\n/\n/g;
    $text =~ s/[ \t]+$//mg;
    $text =~ s/\n+\z/\n/s;
    $text .= "\n" unless $text =~ /\n\z/;
    return $text;
}

sub read_file {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot open $path: $!";
    local $/ = undef;
    my $content = <$fh>;
    close $fh or die "Cannot close $path: $!";
    return $content;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
