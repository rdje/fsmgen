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

    my %nets_by_name = map { $_->{name} => $_ } @{$structural->{nets} || []};
    is_deeply(
        [sort keys %nets_by_name],
        [qw(data_out_q ready_q)],
        'direct structural_rtl_ir projects direct mux-helper declaration nets',
    );
    is_deeply(
        $nets_by_name{data_out_q},
        {
            name => 'data_out_q',
            width => 8,
            signed => 0,
            source => undef,
            targets => [],
        },
        'direct structural_rtl_ir records the data_out_q helper declaration net',
    );
    is_deeply(
        $nets_by_name{ready_q},
        {
            name => 'ready_q',
            width => 1,
            signed => 0,
            source => undef,
            targets => [],
        },
        'direct structural_rtl_ir records the ready_q helper declaration net',
    );
    like($result->{hdl_code}, qr/\breg\s+\[7:0\]\s+data_out_q;/, 'generated HDL declares the data_out_q helper net');
    like($result->{hdl_code}, qr/\breg\s+ready_q;/, 'generated HDL declares the ready_q helper net');
    is_deeply($structural->{instances}, [], 'direct structural_rtl_ir does not claim direct instances yet');
    is_deeply($structural->{declared_links}, [], 'direct structural_rtl_ir does not claim direct declared links yet');
    is_deeply($structural->{resolved_links}, [], 'direct structural_rtl_ir does not claim direct resolved links yet');
    is_deeply(
        $structural->{auxiliary_assignments},
        [],
        'direct structural_rtl_ir does not claim direct auxiliary assignments yet',
    );
    is($structural->{net_count}, 2, 'direct structural_rtl_ir net_count matches projected helper declarations');
    is($structural->{instance_count}, 0, 'direct structural_rtl_ir instance_count remains zero');
    is($structural->{declared_link_count}, 0, 'direct structural_rtl_ir declared_link_count remains zero');
    is($structural->{resolved_link_count}, 0, 'direct structural_rtl_ir resolved_link_count remains zero');
    is($structural->{auxiliary_assignment_count}, 0, 'direct structural_rtl_ir auxiliary_assignment_count remains zero');
};

subtest 'direct structural_rtl_ir projects typed internal storage declaration nets' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_structural_internal_net_guard.fsm');

    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_structural_internal_net_guard
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+types
    (type signed_byte (four_state (signed (bits 8))))
  )
  (+size
    (OUT signed_byte)
    (IN signed_byte)
    (FLAG 1)
  )
  (idle
    (OUT <= IN)
    (-> run)
  )
  (run
    (FLAG = 1)
  )
)
FSM
    );

    my $result = generate_result($fsm_path);
    my $structural = $result->{structural_rtl_ir};
    my %nets_by_name = map { $_->{name} => $_ } @{$structural->{nets} || []};

    is_deeply(
        [sort keys %nets_by_name],
        [qw(FLAG OUT OUT_q)],
        'direct structural_rtl_ir projects internal storage and helper declarations',
    );
    is_deeply(
        $nets_by_name{FLAG},
        {
            name => 'FLAG',
            width => 1,
            signed => 0,
            source => undef,
            targets => [],
        },
        'direct structural_rtl_ir records the single-bit internal storage declaration',
    );
    is_deeply(
        {
            name => $nets_by_name{OUT}{name},
            width => $nets_by_name{OUT}{width},
            signed => $nets_by_name{OUT}{signed},
            source => $nets_by_name{OUT}{source},
            targets => $nets_by_name{OUT}{targets},
            state_model => $nets_by_name{OUT}{state_model},
            declared_type_name => $nets_by_name{OUT}{declared_type_name},
            declared_type_spec => $nets_by_name{OUT}{declared_type_spec},
        },
        {
            name => 'OUT',
            width => 8,
            signed => 1,
            source => undef,
            targets => [],
            state_model => 'four_state',
            declared_type_name => 'signed_byte',
            declared_type_spec => {
                kind => 'bits',
                signed => 1,
                state_model => 'four_state',
                width => 8,
            },
        },
        'direct structural_rtl_ir preserves typed metadata on internal storage nets',
    );
    is_deeply(
        {
            name => $nets_by_name{OUT_q}{name},
            width => $nets_by_name{OUT_q}{width},
            signed => $nets_by_name{OUT_q}{signed},
            source => $nets_by_name{OUT_q}{source},
            targets => $nets_by_name{OUT_q}{targets},
            state_model => $nets_by_name{OUT_q}{state_model},
            declared_type_name => $nets_by_name{OUT_q}{declared_type_name},
            declared_type_spec => $nets_by_name{OUT_q}{declared_type_spec},
        },
        {
            name => 'OUT_q',
            width => 8,
            signed => 1,
            source => undef,
            targets => [],
            state_model => 'four_state',
            declared_type_name => 'signed_byte',
            declared_type_spec => {
                kind => 'bits',
                signed => 1,
                state_model => 'four_state',
                width => 8,
            },
        },
        'direct structural_rtl_ir preserves typed metadata on helper nets',
    );
    ok(!exists $nets_by_name{idle_en}, 'direct structural_rtl_ir does not claim generated enable wires in this slice');
    is($structural->{net_count}, 3, 'direct structural_rtl_ir net_count matches internal storage/helper declarations');
    is_deeply($structural->{instances}, [], 'direct structural_rtl_ir still does not claim direct instances');
    is_deeply($structural->{declared_links}, [], 'direct structural_rtl_ir still does not claim direct declared links');
    is_deeply($structural->{resolved_links}, [], 'direct structural_rtl_ir still does not claim direct resolved links');
    is_deeply($structural->{auxiliary_assignments}, [], 'direct structural_rtl_ir still does not claim direct assignments');
    like($result->{hdl_code}, qr/\blogic\s+signed\s+\[7:0\]\s+OUT;/, 'generated HDL declares the typed internal storage net');
    like($result->{hdl_code}, qr/\blogic\s+signed\s+\[7:0\]\s+OUT_q;/, 'generated HDL declares the typed helper net');
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
