#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use Scalar::Util qw(refaddr);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'composition generation separates provenance report result mirrors' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'composition_provenance_alias_top.fsm');
    write_file(
        $composition_path,
        <<'FSM'
(?top:composition_provenance_alias_top
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

    my $result = generate_result($composition_path);
    my $report = $result->{composition_report};
    my $module_provenance = $result->{module_info}{composition_provenance};
    my $statistics_provenance = $result->{statistics}{composition_provenance};

    is_deeply(
        $module_provenance,
        $report,
        'module_info provenance starts equivalent to the top-level composition_report',
    );
    is_deeply(
        $statistics_provenance,
        $report,
        'statistics provenance starts equivalent to the top-level composition_report',
    );
    isnt(
        refaddr($module_provenance),
        refaddr($report),
        'module_info provenance does not reuse the top-level composition_report hash',
    );
    isnt(
        refaddr($statistics_provenance),
        refaddr($report),
        'statistics provenance does not reuse the top-level composition_report hash',
    );

    $report->{port_origin_counts}{declared_explicit_port} = 99;
    $report->{resolved_links}[0]{source_context}{endpoint} = 'mutated.top';

    is(
        $module_provenance->{port_origin_counts}{declared_explicit_port},
        4,
        'mutating top-level composition_report counts does not contaminate module_info provenance',
    );
    is(
        $statistics_provenance->{port_origin_counts}{declared_explicit_port},
        4,
        'mutating top-level composition_report counts does not contaminate statistics provenance',
    );
    is(
        $module_provenance->{resolved_links}[0]{source_context}{endpoint},
        'clk',
        'mutating top-level composition_report nested link context does not contaminate module_info provenance',
    );
    is(
        $statistics_provenance->{resolved_links}[0]{source_context}{endpoint},
        'clk',
        'mutating top-level composition_report nested link context does not contaminate statistics provenance',
    );

    my $second_result = generate_result($composition_path);
    $second_result->{module_info}{composition_provenance}{port_origin_counts}{declared_explicit_port} = 77;
    $second_result->{module_info}{composition_provenance}{resolved_links}[0]{source_context}{endpoint}
        = 'mutated.module_info';

    is(
        $second_result->{composition_report}{port_origin_counts}{declared_explicit_port},
        4,
        'mutating module_info provenance counts does not contaminate top-level composition_report',
    );
    is(
        $second_result->{statistics}{composition_provenance}{port_origin_counts}{declared_explicit_port},
        4,
        'mutating module_info provenance counts does not contaminate statistics provenance',
    );
    is(
        $second_result->{composition_report}{resolved_links}[0]{source_context}{endpoint},
        'clk',
        'mutating module_info provenance nested link context does not contaminate top-level composition_report',
    );
    is(
        $second_result->{statistics}{composition_provenance}{resolved_links}[0]{source_context}{endpoint},
        'clk',
        'mutating module_info provenance nested link context does not contaminate statistics provenance',
    );

    my $third_result = generate_result($composition_path);
    $third_result->{statistics}{composition_provenance}{port_origin_counts}{declared_explicit_port} = 55;
    $third_result->{statistics}{composition_provenance}{resolved_links}[0]{source_context}{endpoint}
        = 'mutated.statistics';

    is(
        $third_result->{composition_report}{port_origin_counts}{declared_explicit_port},
        4,
        'mutating statistics provenance counts does not contaminate top-level composition_report',
    );
    is(
        $third_result->{module_info}{composition_provenance}{port_origin_counts}{declared_explicit_port},
        4,
        'mutating statistics provenance counts does not contaminate module_info provenance',
    );
    is(
        $third_result->{composition_report}{resolved_links}[0]{source_context}{endpoint},
        'clk',
        'mutating statistics provenance nested link context does not contaminate top-level composition_report',
    );
    is(
        $third_result->{module_info}{composition_provenance}{resolved_links}[0]{source_context}{endpoint},
        'clk',
        'mutating statistics provenance nested link context does not contaminate module_info provenance',
    );
};

done_testing();

sub generate_result {
    my ($path) = @_;
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );
    return $pipeline->generate_hdl_from_file($path);
}

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $contents or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
