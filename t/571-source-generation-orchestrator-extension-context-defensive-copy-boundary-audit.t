#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;
use FSM::Pipeline::SourceGenerationOrchestrator;

{
    package Test::SourceGenerationContextMutatingExtension;

    use strict;
    use warnings;

    sub new {
        my ($class) = @_;
        return bless {
            parse_snapshot => undef,
            result_snapshot => undef,
        }, $class;
    }

    sub after_parse_source {
        my ($self, $context) = @_;
        my $source_info = $context->source_info;
        my $raw_ast = $context->raw_ast;

        $self->{parse_snapshot} = {
            kind => $source_info->{kind},
            header => $source_info->{header},
            package_import_names => [@{$source_info->{package_import_names} || []}],
        };

        $source_info->{kind} = 'composition';
        $source_info->{header} = '?top:mutated_by_parse_hook';
        $source_info->{package_import_names} = ['mutated_by_parse_hook'];
        $source_info->{package_import_count} = 1;
        $source_info->{metadata} = {
            labels => ['mutated_by_parse_hook'],
        };
        $raw_ast->[0] = '?top:mutated_by_parse_hook' if ref($raw_ast) eq 'ARRAY';
    }

    sub after_generate_result {
        my ($self, $context) = @_;
        my $source_info = $context->source_info;

        $self->{result_snapshot} = {
            kind => $source_info->{kind},
            header => $source_info->{header},
            package_import_names => [@{$source_info->{package_import_names} || []}],
        };

        $source_info->{kind} = 'package';
        $source_info->{header} = '?pkg:mutated_by_result_hook';
        $source_info->{package_import_names} = ['mutated_by_result_hook'];
        $source_info->{package_import_count} = 1;
        $source_info->{metadata} = {
            labels => ['mutated_by_result_hook'],
        };

        $context->result->{extension_result_hook_marker} = {
            seen_kind => $self->{result_snapshot}{kind},
            seen_header => $self->{result_snapshot}{header},
        };
    }

    sub parse_snapshot {
        my ($self) = @_;
        return $self->{parse_snapshot};
    }

    sub result_snapshot {
        my ($self) = @_;
        return $self->{result_snapshot};
    }
}

subtest 'source generation extension contexts snapshot source_info and raw_ast but keep result live' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'source_generation_context_boundary.fsm');
    write_file(
        $fsm_path,
        <<'FSM'
(?dt:source_generation_context_boundary
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

    my $extension = Test::SourceGenerationContextMutatingExtension->new;
    my $result = FSM::Pipeline::SourceGenerationOrchestrator->generate_from_file(
        pipeline => new_pipeline($extension),
        fsm_file => $fsm_path,
    );

    is($extension->parse_snapshot->{kind}, 'dt', 'parse hook sees the original direct-root source kind');
    is(
        $extension->parse_snapshot->{header},
        '?dt:source_generation_context_boundary',
        'parse hook sees the original direct-root source header',
    );
    is_deeply(
        $extension->parse_snapshot->{package_import_names},
        [],
        'parse hook sees the original package-import summary',
    );
    is($extension->result_snapshot->{kind}, 'dt', 'result hook sees the original source kind');
    is(
        $extension->result_snapshot->{header},
        '?dt:source_generation_context_boundary',
        'result hook sees the original source header',
    );

    is($result->{fsm_module}->name, 'source_generation_context_boundary', 'generation still targets the original module name');
    is($result->{raw_ast}[0][0], '?dt:source_generation_context_boundary', 'parse-context raw_ast mutation cannot contaminate live generation input');
    is($result->{source_info}{kind}, 'dt', 'returned result source_info keeps the original kind');
    is(
        $result->{source_info}{header},
        '?dt:source_generation_context_boundary',
        'returned result source_info keeps the original header',
    );
    is_deeply($result->{source_info}{package_import_names}, [], 'returned result source_info keeps its owned package-import summary');
    is($result->{source_info}{package_import_count}, 0, 'returned result source_info keeps its owned package-import count');
    ok(!exists($result->{source_info}{metadata}), 'source_info accessor mutation does not leak extension metadata into the result');
    is_deeply(
        $result->{extension_result_hook_marker},
        {
            seen_kind => 'dt',
            seen_header => '?dt:source_generation_context_boundary',
        },
        'result hook still mutates the live result through the intended result accessor',
    );
};

done_testing();

sub new_pipeline {
    my ($extension) = @_;
    return FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
        extensions => [$extension],
    );
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
