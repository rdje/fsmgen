#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::GenerationOrchestrator;
use FSM::Pipeline::HDLGenerator;
use FSM::Pipeline::SourceFrontend;

subtest 'composition generation statistics are returned from a caller-owned seed snapshot' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'composition_statistics_seed_alias_top.fsm');
    write_file(
        $composition_path,
        <<'FSM'
(?top:composition_statistics_seed_alias_top
  (?ports:public_io
    clk
    rstn
    select
    output_data>8
  )
  (?fsmc:producer producer_src)
)

(?fsm:producer_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (select 1)
    (output_data 8)
  )
  (IDLE
    (<select==1'b0
      (<= (output_data> 8'1))
    )
  )
)
FSM
    );

    my $raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
        fsm_file => $composition_path,
        debug_level => 0,
    );
    my $source_info = FSM::Pipeline::SourceFrontend->classify_source_ast($raw_ast);
    my $statistics_seed = {
        intermediate_signals => 2,
        global_expressions => 1,
        reused_expressions => [
            {
                name => 'seed_expr',
                contributors => ['seed_a'],
            },
        ],
        raw_backend => {
            nested => ['seed_value'],
        },
    };

    my $result = FSM::Composition::GenerationOrchestrator->generate_from_source(
        pipeline => new_pipeline(),
        raw_ast => $raw_ast,
        source_info => $source_info,
        fsm_file => $composition_path,
        statistics_seed => $statistics_seed,
    );

    is(
        $result->{statistics}{intermediate_signals},
        2,
        'composition statistics preserve scalar seed fields',
    );
    is_deeply(
        $result->{statistics}{reused_expressions},
        [
            {
                name => 'seed_expr',
                contributors => ['seed_a'],
            },
        ],
        'composition statistics preserve nested seed arrays',
    );
    is_deeply(
        $result->{statistics}{raw_backend},
        {
            nested => ['seed_value'],
        },
        'composition statistics preserve nested seed hashes',
    );

    $result->{statistics}{reused_expressions}[0]{name} = 'mutated_result_expr';
    $result->{statistics}{reused_expressions}[0]{contributors}[0] = 'mutated_result_contributor';
    $result->{statistics}{raw_backend}{nested}[0] = 'mutated_result_value';

    is(
        $statistics_seed->{reused_expressions}[0]{name},
        'seed_expr',
        'mutating returned statistics expression metadata does not contaminate caller seed',
    );
    is(
        $statistics_seed->{reused_expressions}[0]{contributors}[0],
        'seed_a',
        'mutating returned statistics nested arrays does not contaminate caller seed',
    );
    is(
        $statistics_seed->{raw_backend}{nested}[0],
        'seed_value',
        'mutating returned statistics nested hashes does not contaminate caller seed',
    );

    $statistics_seed->{reused_expressions}[0]{name} = 'mutated_seed_expr';
    $statistics_seed->{reused_expressions}[0]{contributors}[0] = 'mutated_seed_contributor';
    $statistics_seed->{raw_backend}{nested}[0] = 'mutated_seed_value';

    is(
        $result->{statistics}{reused_expressions}[0]{name},
        'mutated_result_expr',
        'mutating caller seed after generation does not contaminate returned statistics expression metadata',
    );
    is(
        $result->{statistics}{reused_expressions}[0]{contributors}[0],
        'mutated_result_contributor',
        'mutating caller seed after generation does not contaminate returned statistics nested arrays',
    );
    is(
        $result->{statistics}{raw_backend}{nested}[0],
        'mutated_result_value',
        'mutating caller seed after generation does not contaminate returned statistics nested hashes',
    );
};

done_testing();

sub new_pipeline {
    return FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );
}

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $contents or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
