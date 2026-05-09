#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

{
    package Test::StatefulContextSnapshotExtension;

    use strict;
    use warnings;

    sub new {
        my ($class) = @_;
        return bless {
            parse_headers => [],
            result_headers => [],
            raw_headers => [],
        }, $class;
    }

    sub after_parse_source {
        my ($self, $context) = @_;
        my $source_info = $context->source_info;
        my $raw_ast = $context->raw_ast;

        push @{$self->{parse_headers}}, $source_info->{header};
        push @{$self->{raw_headers}}, $raw_ast->[0][0];

        $source_info->{header} = '?dt:mutated_parse_context_header';
        $source_info->{metadata} = { labels => ['mutated_parse_context'] };
        $raw_ast->[0][0] = '?dt:mutated_parse_context_raw_ast';
    }

    sub after_generate_result {
        my ($self, $context) = @_;
        my $source_info = $context->source_info;

        push @{$self->{result_headers}}, $source_info->{header};

        $source_info->{header} = '?dt:mutated_result_context_header';
        $source_info->{metadata} = { labels => ['mutated_result_context'] };
        $context->result->{extension_context_snapshot_call_count} = scalar(@{$self->{result_headers}});
    }

    sub parse_headers { return $_[0]->{parse_headers} }
    sub result_headers { return $_[0]->{result_headers} }
    sub raw_headers { return $_[0]->{raw_headers} }
}

subtest 'stateful facade reuse builds fresh extension context snapshots per generation' => sub {
    my $dt_path = write_dt_fixture();
    my $extension = Test::StatefulContextSnapshotExtension->new;
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
        extensions => [$extension],
    );

    my $first = $pipeline->generate_hdl_from_file($dt_path);
    my $second = $pipeline->generate_hdl_from_file($dt_path);

    is_deeply(
        $extension->parse_headers,
        [
            '?dt:stateful_extension_context_alias_top',
            '?dt:stateful_extension_context_alias_top',
        ],
        'parse hook sees fresh source_info headers across facade reuse',
    );
    is_deeply(
        $extension->raw_headers,
        [
            '?dt:stateful_extension_context_alias_top',
            '?dt:stateful_extension_context_alias_top',
        ],
        'parse hook sees fresh raw_ast headers across facade reuse',
    );
    is_deeply(
        $extension->result_headers,
        [
            '?dt:stateful_extension_context_alias_top',
            '?dt:stateful_extension_context_alias_top',
        ],
        'result hook sees fresh source_info headers across facade reuse',
    );
    is(
        $first->{raw_ast}[0][0],
        '?dt:stateful_extension_context_alias_top',
        'first result raw_ast is not contaminated by extension context snapshot mutation',
    );
    is(
        $second->{source_info}{header},
        '?dt:stateful_extension_context_alias_top',
        'second result source_info is not contaminated by prior extension context mutation',
    );
    is($first->{extension_context_snapshot_call_count}, 1, 'first result hook still mutates the live result');
    is($second->{extension_context_snapshot_call_count}, 2, 'second result hook still mutates the live result');
};

done_testing();

sub write_dt_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $dt_path = File::Spec->catfile($tempdir, 'stateful_extension_context_alias_top.fsm');
    write_file(
        $dt_path,
        <<'FSM'
(?dt:stateful_extension_context_alias_top
  (+size
    (trigger 1)
    (serial_out 1)
  )
  (-route
    (serial_out> = trigger)
  )
)
FSM
    );
    return $dt_path;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
