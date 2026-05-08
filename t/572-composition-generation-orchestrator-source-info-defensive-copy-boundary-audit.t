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

subtest 'composition generation snapshots caller-supplied source_info before result enrichment' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'composition_source_info_copy_top.fsm');
    write_file(
        $composition_path,
        <<'FSM'
(?top:composition_source_info_copy_top
  (?ports:public_io
    clk
    rstn
    output_data>8
  )
  (?fsmc:child child_src)
)

(?fsm:child_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-idle
    (output_data> <= 8'1)
  )
  (+size
    (output_data 8)
  )
)
FSM
    );

    my $raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
        fsm_file => $composition_path,
        debug_level => 0,
    );
    my $source_info = FSM::Pipeline::SourceFrontend->classify_source_ast($raw_ast);
    $source_info->{metadata} = {
        labels => ['caller_owned'],
    };

    my $result = FSM::Composition::GenerationOrchestrator->generate_from_source(
        pipeline => new_pipeline(),
        raw_ast => $raw_ast,
        source_info => $source_info,
        fsm_file => $composition_path,
    );

    is_deeply(
        $source_info,
        {
            kind => 'composition',
            header => '?top:composition_source_info_copy_top',
            package_import_names => [],
            package_import_count => 0,
            metadata => {
                labels => ['caller_owned'],
            },
        },
        'composition generation does not mutate caller source_info while adding internal result payloads',
    );

    ok($result->{source_info}{composition_spec}, 'composition-generation result still carries its internal composition_spec');
    $result->{source_info}{metadata}{labels}[0] = 'mutated';
    is(
        $source_info->{metadata}{labels}[0],
        'caller_owned',
        'returned composition-generation source_info does not alias nested caller metadata',
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
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
