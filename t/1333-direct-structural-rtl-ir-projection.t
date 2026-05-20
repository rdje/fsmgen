#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'direct roots expose a bounded structural_rtl_ir port projection' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_structural_projection_guard.fsm');

    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_structural_projection_guard
  (+system
    (clock clk)
    (asreset rst_n)
  )
  (+size
    (request 1)
    (payload 8)
    (ready 1)
    (data_out 8)
  )
  (idle
    (<request
      (ready> <= 1)
      (data_out> <= payload)
    )
  )
)
FSM
    );

    my $result = generate_result($fsm_path);
    my $module_info = $result->{module_info};
    my $structural = $result->{structural_rtl_ir};

    ok($structural, 'direct generation returns a top-level structural_rtl_ir projection');
    is_deeply(
        $module_info->{structural_rtl_ir},
        $structural,
        'direct module_info mirrors the same serialized structural_rtl_ir projection',
    );

    is($structural->{module_name}, 'direct_structural_projection_guard', 'structural_rtl_ir preserves module name');
    is($structural->{source_root_kind}, 'fsm', 'structural_rtl_ir preserves direct root kind');
    is($structural->{target_language}, 'systemverilog', 'structural_rtl_ir preserves target language');

    my $expected_ports = expected_ports_from_module_info($module_info);
    my $actual_ports = {
        map {
            $_->{name} => {
                direction => $_->{direction},
                width => $_->{width},
                signed => $_->{signed} // 0,
                type => $_->{type},
            }
        } @{$structural->{ports} || []}
    };

    is_deeply(
        $actual_ports,
        $expected_ports,
        'direct structural_rtl_ir ports match generated module_info signal analysis plus system contract',
    );
    is($structural->{port_count}, scalar(keys %$expected_ports), 'direct structural_rtl_ir port_count matches expected ports');

    my $header = extract_module_header($result->{hdl_code});
    for my $port_name (sort keys %$expected_ports) {
        like(
            $header,
            qr/\b\Q$port_name\E\b/,
            "generated HDL module header includes structural port $port_name",
        );
    }

    is_deeply($structural->{nets}, [], 'direct structural_rtl_ir does not claim direct internal nets yet');
    is_deeply($structural->{instances}, [], 'direct structural_rtl_ir does not claim direct instances yet');
    is_deeply($structural->{declared_links}, [], 'direct structural_rtl_ir does not claim direct declared links yet');
    is_deeply($structural->{resolved_links}, [], 'direct structural_rtl_ir does not claim direct resolved links yet');
    is_deeply(
        $structural->{auxiliary_assignments},
        [],
        'direct structural_rtl_ir does not claim direct auxiliary assignments yet',
    );
    is($structural->{net_count}, 0, 'direct structural_rtl_ir net_count remains zero');
    is($structural->{instance_count}, 0, 'direct structural_rtl_ir instance_count remains zero');
    is($structural->{declared_link_count}, 0, 'direct structural_rtl_ir declared_link_count remains zero');
    is($structural->{resolved_link_count}, 0, 'direct structural_rtl_ir resolved_link_count remains zero');
    is($structural->{auxiliary_assignment_count}, 0, 'direct structural_rtl_ir auxiliary_assignment_count remains zero');
};

done_testing();

sub expected_ports_from_module_info {
    my ($module_info) = @_;
    my %ports;

    for my $bucket (
        [ inputs => 'input' ],
        [ outputs => 'output' ],
    ) {
        my ($analysis_key, $direction) = @$bucket;
        for my $entry (@{$module_info->{signal_analysis}{$analysis_key} || []}) {
            my $name = $entry->{name};
            next unless defined($name) && length($name);
            my $signal = ref($module_info->{signals}) eq 'HASH'
                ? $module_info->{signals}{$name}
                : undef;
            $ports{$name} = {
                direction => $direction,
                width => $entry->{width} || 1,
                signed => (ref($signal) && $signal->can('signed') && $signal->signed) ? 1 : 0,
                type => (ref($signal) && $signal->can('type')) ? $signal->type : undef,
            };
        }
    }

    my $system_contract = $module_info->{system_contract} || {};
    if (($module_info->{requires_implicit_system_ports} || $module_info->{explicit_system_contract})
        && defined($system_contract->{clock}) && length($system_contract->{clock})
        && !exists $ports{$system_contract->{clock}}) {
        $ports{$system_contract->{clock}} = {
            direction => 'input',
            width => 1,
            signed => 0,
            type => 'clock',
        };
    }
    if (($module_info->{requires_implicit_system_ports} || $module_info->{explicit_system_contract})
        && defined($system_contract->{reset}) && length($system_contract->{reset})
        && !exists $ports{$system_contract->{reset}}) {
        $ports{$system_contract->{reset}} = {
            direction => 'input',
            width => 1,
            signed => 0,
            type => 'reset',
        };
    }

    return \%ports;
}

sub extract_module_header {
    my ($hdl_code) = @_;
    my ($header) = ($hdl_code || '') =~ /(module\s+direct_structural_projection_guard\s*\(.*?\n\);)/s;
    ok(defined $header, 'generated HDL contains the direct module header');
    return defined($header) ? $header : '';
}

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
