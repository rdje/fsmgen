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

subtest 'actor-local scalar type aliases lower to reviewable .fsm declarations' => sub {
    my $actor = parse_source(<<'ISF', 'local-scalar-types.isf');
(actor typed_scalar
  (types
    (type byte (bits 8))
    (type flag bit))
  (enums
    (mode (IDLE 0) (BUSY 1)))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input data_in (type byte))
    (output data_out (type byte)))
  (storage
    (var accum (type byte)))
  (transaction main
    (ports
      (input payload (type byte))
      (output done_flag (type flag)))
    (on start)
    (set accum data_in)
    (set data_out accum)))
ISF

    is($actor->{interface}{inputs}[1]{width}, 8, 'local scalar type resolves input width');
    is($actor->{interface}{outputs}[0]{width}, 8, 'local scalar type resolves output width');
    is($actor->{storage}[0]{width}, 8, 'local scalar type resolves storage width');
    is($actor->{transactions}[0]{ports}{inputs}[0]{width}, 8, 'local scalar type resolves transaction input width');
    is($actor->{transactions}[0]{ports}{outputs}[0]{width}, 1, 'local bit alias resolves transaction output width');

    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'typed_scalar.fsm'};
    like($fsm, qr/\(\+types\s+\(type byte \(bits 8\)\)\s+\(type flag bit\)\s+\)/s,
        'scheduled .fsm emits actor-local +types block');
    like($fsm, qr/\(\+enums\s+\(mode \(IDLE 0\) \(BUSY 1\)\)\s+\)/s,
        'scheduled .fsm preserves actor-local +enums declaration artifacts');
    like($fsm, qr/\(\+size[\s\S]*\(data_in byte\)[\s\S]*\(data_out byte\)[\s\S]*\(accum byte\)[\s\S]*\(done_flag flag\)[\s\S]*\(payload byte\)/,
        'scheduled .fsm preserves type aliases in +size review artifact');
};

subtest 'package scalar type aliases are resolved and embedded for CLI HDL generation' => sub {
    my $dir = tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($dir, 'shared.fsm'), <<'FSM');
(?pkg:shared
  (+types
    (type byte (bits 8)))
)
FSM
    my $isf_path = File::Spec->catfile($dir, 'uses_shared_type.isf');
    write_file($isf_path, <<'ISF');
(actor uses_shared_type
  (imports
    (package shared))
  (clock clk)
  (reset rst)
  (interface
    (input start)
    (input data_in (type shared.byte))
    (output data_out (type shared.byte)))
  (transaction main
    (on start)
    (set data_out data_in)))
ISF

    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_path);
    is($actor->{interface}{inputs}[1]{width}, 8, 'package scalar type resolves input width');
    is($actor->{interface}{outputs}[0]{width}, 8, 'package scalar type resolves output width');

    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{'uses_shared_type.fsm'};
    like($fsm, qr/\(\+import\s+shared\s+\)/s, 'scheduled .fsm emits package import');
    like($fsm, qr/\(\+size[\s\S]*\(data_in shared\.byte\)[\s\S]*\(data_out shared\.byte\)/,
        'scheduled .fsm preserves package-qualified type aliases in +size');
    like($fsm, qr/\(\?pkg:shared[\s\S]*\(\+types[\s\S]*\(type byte \(bits 8\)\)/,
        'scheduled .fsm embeds imported package root for self-contained CLI generation');

    my $hdl_path = File::Spec->catfile($dir, 'uses_shared_type.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--output', $hdl_path, $isf_path],
    );
    ok($success, 'CLI HDL generation succeeds for package-backed ISF type alias');
    is(join('', @{$stderr_buf || []}), '', 'CLI keeps stderr clean for package-backed type alias');
    ok(-s $hdl_path, 'CLI writes HDL for package-backed type alias');
};

subtest 'scalar type alias diagnostics fail closed' => sub {
    assert_parse_rejected(
        <<'ISF',
(actor unknown_type
  (clock clk)
  (reset rst)
  (interface
    (input data (type missing_t)))
  (transaction main))
ISF
        qr/interface port 'data' references unknown type 'missing_t'/,
        'unknown type reference',
    );

    assert_parse_rejected(
        <<'ISF',
(actor aggregate_type
  (types
    (type pair_t (list bit bit)))
  (clock clk)
  (reset rst)
  (interface
    (input data (type pair_t)))
  (transaction main))
ISF
        qr/interface port 'data' references aggregate type 'pair_t'/,
        'aggregate type reference rejected in scalar slice',
    );

    assert_parse_rejected(
        <<'ISF',
(actor width_type_conflict
  (types
    (type byte (bits 8)))
  (clock clk)
  (reset rst)
  (interface
    (input data (width 8) (type byte)))
  (transaction main))
ISF
        qr/interface port 'data' cannot specify both '\(width \.\.\.\)' and '\(type \.\.\.\)'/,
        'width and type are mutually exclusive',
    );

    assert_parse_rejected(
        <<'ISF',
(actor package_alias
  (imports
    (package shared as s))
  (clock clk)
  (reset rst)
  (interface
    (input start))
  (transaction main))
ISF
        qr/package imports require '\(package NAME\)'/,
        'package import aliases are not accepted in the first contract',
    );
};

done_testing();

sub parse_source {
    my ($source, $label) = @_;
    return FSM::Adapter::ISF->new()->parse_source($source, $label);
}

sub assert_parse_rejected {
    my ($source, $regex, $label) = @_;
    my $ok = eval {
        parse_source($source, "$label.isf");
        1;
    };
    ok(!$ok, "$label is rejected");
    like($@, $regex, "$label diagnostic");
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "open $path: $!";
    print {$fh} $content;
    close $fh or die "close $path: $!";
    return $path;
}
