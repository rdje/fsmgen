#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw/ tempdir /;
use FindBin;
use JSON::PP;
use Cwd qw(abs_path);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::Pipeline::HDLGenerator;
use FSM::HDL::FlattenedDT;

my $tempdir = tempdir(CLEANUP => 1);

subtest 'empty +size remains a supported legacy no-op' => sub {
    my $fsm_module = parse_success(<<'FSM');
(?fsm:empty_size_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size)
  (+size
    (OUT 1)
    (IN 1)
  )
  (idle
    (OUT <= IN)
  )
)
FSM

    ok($fsm_module, 'FSM with empty +size parses successfully');
    my $hdl = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
    like($hdl, qr/module\s+empty_size_contract\b/s, 'empty +size fixture still generates HDL');
};

subtest 'malformed +size payload entries are rejected explicitly' => sub {
    my $error = parse_failure(<<'FSM');
(?fsm:bad_size_payload
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size BROKEN)
  (idle
    (OUT <= 1)
  )
)
FSM

    like($error, qr/Malformed '\+size' entry/, 'malformed +size payload gets a targeted entry diagnostic');
};

subtest 'malformed +size entries are rejected explicitly' => sub {
    my $shape_error = parse_failure(<<'FSM');
(?fsm:bad_size_entry_shape
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (A)
  )
  (idle
    (OUT <= 1)
  )
)
FSM

    like($shape_error, qr/Malformed '\+size' entry/, 'short +size entry shape gets a targeted diagnostic');

    my $width_error = parse_failure(<<'FSM');
(?fsm:bad_size_entry_width
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (A 0)
  )
  (idle
    (OUT <= 1)
  )
)
FSM

    like($width_error, qr/Malformed '\+size' entry for signal 'A'/, 'non-positive width gets a targeted diagnostic');
};

subtest '+size width entries accept constant-expression values' => sub {
    my ($fsm_module, $adapter) = parse_success_with_adapter(<<'FSM');
(?fsm:size_expression_contract
  (+system
    (clock clk)
    (sreset reset)
  )
  (+constants
    (BASE_W 2)
    (INC_W 1)
    (WIDTHS (4 8))
  )
  (+enums
    (width_e
      (FLAG 1)
    )
  )
  (+params
    (PARAM_W (+ BASE_W INC_W))
    (PARAM_DEC_W (+ 0d10 -2))
  )
  (+size
    (A (+ BASE_W INC_W))
    (B (+ PARAM_W width_e.FLAG))
    (C WIDTHS[1])
    (D 0x4)
    (E (and 7 3))
    (F PARAM_DEC_W)
    (G (+ 8'sd9 8'sd-1))
    (H (+ 'h8 0d1))
  )
  (idle
    (A <= 1)
    (B <= A)
    (C <= B)
    (D <= C)
    (E <= A)
    (F <= C)
    (G <= F)
    (H <= G)
  )
)
FSM

    ok($fsm_module, 'FSM with expression-backed +size widths parses successfully');
    is($adapter->{signal_manager}->get_signal('A')->width, 3, '+size resolves nested constant arithmetic');
    is($adapter->{signal_manager}->get_signal('B')->width, 4, '+size resolves params and enum leaves');
    is($adapter->{signal_manager}->get_signal('C')->width, 8, '+size resolves aggregate scalar leaves');
    is($adapter->{signal_manager}->get_signal('D')->width, 4, '+size resolves unsized hex literal widths');
    is($adapter->{signal_manager}->get_signal('E')->width, 3, '+size resolves Lisp-ish bitwise aliases');
    is($adapter->{signal_manager}->get_signal('F')->width, 8, '+size resolves 0d literals and negative terms through scalar params');
    is($adapter->{signal_manager}->get_signal('G')->width, 8, '+size resolves direct signed based negative terms');
    is($adapter->{signal_manager}->get_signal('H')->width, 9, '+size resolves unsized SV and prefixed decimal literals directly');
};

subtest 'pipeline and CLI do not emit HDL for malformed +size sections' => sub {
    my $fsm_path = write_fsm('bad_size_cli.fsm', <<'FSM');
(?fsm:bad_size_cli
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size BROKEN)
  (idle
    (OUT <= 1)
  )
)
FSM

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug => 0,
    );
    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($fsm_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;
    ok($pipeline_error, 'pipeline rejects malformed +size payload');
    like($pipeline_error, qr/Malformed '\+size' entry/, 'pipeline surfaces the explicit +size boundary');

    my $out_path = File::Spec->catfile($tempdir, 'bad_size_cli.sv');
    my $success = system($^X, '-I', 'perl', 'bin/fsmgen', '--output', $out_path, $fsm_path) == 0;
    ok(!$success, 'CLI rejects malformed +size payload');
    ok(!-e $out_path, 'CLI does not emit output for malformed +size payload');
};

subtest 'authored size expressions retain detached source declarations' => sub {
    my $source = <<'FSM';
(?fsm:size_source_contract
  (+system (clock clk) (sreset rstn))
  (+params (W 8) (ALIAS W) (OTHER 8) (word_t 16))
  (+types (type word_t (bits 8)))
  (+size
    (PARAM_WIDTH W)
    (ALIAS_WIDTH ALIAS)
    (OTHER_WIDTH OTHER)
    (NESTED_WIDTH (+ W (* 1 2)))
    (LITERAL_EXPR (add 8 0))
    (HEX_WIDTH 0x8)
    (RM_WIDTH W) (MR_WIDTH ALIAS)
    (RESET_WIDTH (+ W 0) (reset 3))
    (SCALAR_NAMESPACE (+ word_t 0))
    (TYPE_WIDTH word_t)
    (LITERAL_WIDTH 8))
  (idle
    (PARAM_WIDTH <= 0) (ALIAS_WIDTH <= 0) (OTHER_WIDTH <= 0)
    (NESTED_WIDTH <= 0) (LITERAL_EXPR <= 0) (HEX_WIDTH <= 0)
    (RESET_WIDTH <= 0) (SCALAR_NAMESPACE <= 0)
    (RM_WIDTH <-= 0) (MR_WIDTH <=- 0)
    (TYPE_WIDTH <= 0) (LITERAL_WIDTH <= 0)))
FSM
    my ($module, $adapter) = parse_success_with_adapter($source);
    my $manager = $adapter->{signal_manager};
    my $json = JSON::PP->new->canonical;
    my @rows = (
        ['PARAM_WIDTH', 'W', 8], ['ALIAS_WIDTH', 'ALIAS', 8], ['OTHER_WIDTH', 'OTHER', 8],
        ['NESTED_WIDTH', ['+', ['W', ['*', ['1', '2']]]], 10],
        ['LITERAL_EXPR', ['add', ['8', '0']], 8], ['HEX_WIDTH', '0x8', 8],
        ['RESET_WIDTH', ['+', ['W', '0']], 8],
        ['SCALAR_NAMESPACE', ['+', ['word_t', '0']], 16],
        ['RM_WIDTH', 'W', 8], ['MR_WIDTH', 'ALIAS', 8],
    );
    for my $row (@rows) {
        my ($name, $expression, $width) = @$row;
        my $signal = $manager->get_signal($name);
        is($json->encode(width_source($signal)),
            $json->encode({signal => $name, expression => $expression, resolved_width => $width}),
            "$name keeps exact authored tokens beside its resolved declaration width");
        is($signal->width, $width, "$name keeps its existing numeric default");
    }
    for my $row (['next_RM_WIDTH', 'RM_WIDTH', 'W'], ['MR_WIDTH_r', 'MR_WIDTH', 'ALIAS']) {
        my ($name, $parent, $expression) = @$row;
        is($json->encode(width_source($manager->get_signal($name))),
            $json->encode({signal => $parent, expression => $expression, resolved_width => 8}),
            "$name inherits an earlier declaration through actual auxiliary creation");
    }
    is(width_source($manager->get_signal('TYPE_WIDTH')), undef, 'named type keeps its separate source contract');
    is($manager->get_signal('TYPE_WIDTH')->declared_type_name, 'word_t', 'bare token still selects the named type');
    is(width_source($manager->get_signal('LITERAL_WIDTH')), undef, 'decimal literal has no invented expression dependency');
    is($manager->get_signal('RESET_WIDTH')->get_attribute('reset_value'), '3', 'reset marker stays separate from the width expression');

    # Compare a fresh complete module with only the private source descriptors
    # removed before generation. Metadata must not change resolved default HDL.
    my ($plain_module, $plain_adapter) = parse_success_with_adapter($source);
    delete $_->{_declared_width_source} for values %{$plain_adapter->{signal_manager}{signal_registry}};
    is_deeply($manager->get_signal_summary, $plain_adapter->{signal_manager}->get_signal_summary,
        'complete existing signal summaries remain exact');
    is(FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($module),
        FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($plain_module),
        'complete actual default HDL is unchanged by source descriptors');

    # Exercise the live late-declaration path for already-created rm/mr helpers.
    $manager->register_signal($_, width => 1, is_aux_output => 1) for qw(next_MANUAL MANUAL_r);
    my $size = ['+size', [['MANUAL', ['+', ['W', '0']]]]];
    my $before = $json->encode($size);
    $adapter->{parser}->parse_size_section($size);
    for my $name (qw(MANUAL next_MANUAL MANUAL_r)) {
        is($json->encode(width_source($manager->get_signal($name))),
            $json->encode({signal => 'MANUAL', expression => ['+', ['W', '0']], resolved_width => 8}),
            "$name retains the original source declaration, not an invented helper source");
    }
    is($json->encode($size), $before, 'caller expression and primitive kinds remain exact');
    my $copy = width_source($manager->get_signal('MANUAL'));
    if ($copy) {
        $copy->{expression}[1][0] = 'WRONG';
        is(width_source($manager->get_signal('MANUAL'))->{expression}[1][0], 'W', 'getter returns detached source data');
        $manager->get_signal('MANUAL')->{_declared_width_source}{expression}[1][0] = 'MUTATED';
        is(width_source($manager->get_signal('next_MANUAL'))->{expression}[1][0], 'W', 'auxiliary source containers are detached');
        is($json->encode($size), $before, 'signal mutation cannot change caller tokens');
    }
    $adapter->{parser}->parse_size_section(['+size', [['MANUAL', '8'], ['next_MANUAL', 'word_t']]]);
    is(width_source($manager->get_signal('MANUAL')), undef, 'literal re-declaration clears stale expression provenance');
    is(width_source($manager->get_signal('next_MANUAL')), undef, 'typed re-declaration clears stale expression provenance');
    is(width_source($manager->register_signal('INFERRED', width => 8)), undef, 'inference cannot invent a source declaration');

    if (defined $ENV{FSMGEN_SIZE_SOURCE_CAPTURE}) {
        open my $out, '>:raw', $ENV{FSMGEN_SIZE_SOURCE_CAPTURE} or die $!;
        my $root = abs_path(File::Spec->catdir($FindBin::Bin, '..'));
        print {$out} $json->encode({source => $source, rows => \@rows, summary => $manager->get_signal_summary,
            records => {map {$_ => width_source($manager->get_signal($_))} $manager->get_all_signal_names},
            loaded => {map {$_ => File::Spec->abs2rel(abs_path($INC{$_}), $root)}
                qw(FSM/CoreAST.pm FSM/Adapter/FSMGenFull/Parser.pm FSM/Adapter/FSMGenFull/SignalManager.pm)}}), "\n" or die $!;
        close $out or die $!;
    }
};

done_testing();

sub width_source {
    my ($signal) = @_;
    return $signal->can('declared_width_source') ? $signal->declared_width_source : undef;
}

sub parse_success {
    my ($fsm_text) = @_;
    my $fsm_path = write_fsm('parse_success_' . int(rand(1_000_000)) . '.fsm', $fsm_text);
    my $raw_ast = Lispish::multi($fsm_path);
    my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
    return $adapter->parse_fsm($raw_ast);
}

sub parse_success_with_adapter {
    my ($fsm_text) = @_;
    my $fsm_path = write_fsm('parse_success_' . int(rand(1_000_000)) . '.fsm', $fsm_text);
    my $raw_ast = Lispish::multi($fsm_path);
    my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
    my $module = $adapter->parse_fsm($raw_ast);
    return ($module, $adapter);
}

sub parse_failure {
    my ($fsm_text) = @_;
    my $fsm_path = write_fsm('parse_failure_' . int(rand(1_000_000)) . '.fsm', $fsm_text);
    my $raw_ast = Lispish::multi($fsm_path);
    my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);

    my $error = eval {
        $adapter->parse_fsm($raw_ast);
        undef;
    };
    $error = $@ if !$error;
    ok($error, "parse fails for generated fixture");
    return $error;
}

sub write_fsm {
    my ($filename, $content) = @_;
    my $path = File::Spec->catfile($tempdir, $filename);
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
    return $path;
}
