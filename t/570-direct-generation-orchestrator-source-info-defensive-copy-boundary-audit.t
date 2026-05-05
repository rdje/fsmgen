#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::DirectGenerationOrchestrator;
use FSM::Pipeline::HDLGenerator;
use FSM::Pipeline::SourceFrontend;

subtest 'direct generation snapshots caller-supplied source_info before package summary enrichment' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_source_info_copy_root.fsm');
    write_file(
        $fsm_path,
        <<'FSM'
(?dt:direct_source_info_copy_root
  (-route
    (serial_out> = trigger)
  )
  (+size
    (trigger 1)
    (serial_out 1)
  )
)
FSM
    );

    my $raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
        fsm_file => $fsm_path,
        debug_level => 0,
    );
    my $source_info = FSM::Pipeline::SourceFrontend->classify_source_ast($raw_ast);
    $source_info->{package_import_names} = ['caller_preexisting'];
    $source_info->{package_import_count} = 1;
    $source_info->{metadata} = {
        labels => ['caller_owned'],
    };

    my $result = FSM::Pipeline::DirectGenerationOrchestrator->generate_from_source(
        pipeline => new_pipeline(),
        raw_ast => $raw_ast,
        source_info => $source_info,
    );

    is_deeply(
        $source_info,
        {
            kind => 'dt',
            header => '?dt:direct_source_info_copy_root',
            package_import_names => ['caller_preexisting'],
            package_import_count => 1,
            metadata => {
                labels => ['caller_owned'],
            },
        },
        'direct generation does not mutate caller source_info while adding result package-import summary fields',
    );

    $result->{source_info}{metadata}{labels}[0] = 'mutated';
    is(
        $source_info->{metadata}{labels}[0],
        'caller_owned',
        'returned direct-generation source_info does not alias nested caller metadata',
    );
    is_deeply(
        $result->{source_info}{package_import_names},
        [],
        'direct-generation result still owns the package-import names summary',
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
