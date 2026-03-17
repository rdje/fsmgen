#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use Lispish;
use FSM::Composition::Parser;
use FSM::Pipeline::HDLGenerator;
use FSM::Composition::Plan;

subtest 'parser tags declared top ports and explicit toplinks with provenance' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $path = File::Spec->catfile($tempdir, 'declared_metadata_top.fsm');

    write_file(
        $path,
        <<'FSM'
(?top:declared_metadata_top
  (?ports:public_io
    payload_in<8
    =result_data>8
  )
  (?dtc:producer producer_src)
  (?dtc:consumer consumer_src)
  (?toplink:wiring
    /producer.mid/consumer.mid/
  )
)

(?dt:producer_src
  (-route
    (mid> = payload_in)
  )
  (+size
    (payload_in 8)
    (mid 8)
  )
)

(?dt:consumer_src
  (-route
    (result_data> = mid)
  )
  (+size
    (mid 8)
    (result_data 8)
  )
)
FSM
    );

    my $parser = FSM::Composition::Parser->new;
    my $spec = $parser->parse_source(scalar Lispish::multi($path));

    my @ports = @{$spec->top->ports_blocks->[0]->ports};
    is($ports[0]->origin_kind, 'declared_explicit_port', 'plain explicit top port records declared-explicit provenance');
    is($ports[1]->origin_kind, 'declared_connect_by_name_port', 'by-name top port records declared connect-by-name provenance');
    is($spec->top->toplinks->[0]->links->[0]->origin_kind, 'declared_explicit_toplink', 'explicit toplink records declared-explicit provenance');
};

subtest 'C1 omitted ports surface inferred passthrough provenance' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $path = File::Spec->catfile($tempdir, 'c1_inferred_metadata_top.fsm');

    write_file(
        $path,
        <<'FSM'
(?top:c1_inferred_metadata_top
  (?dtc:child child_src)
)

(?dt:child_src
  (-route
    (result_data> = payload_in)
  )
  (+size
    (payload_in 8)
    (result_data 8)
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $result = $pipeline->generate_hdl_from_file($path);

    isa_ok($result->{composition_plan}, 'FSM::Composition::Plan');
    is($result->{composition_plan}->lane, 'C1', 'single child still plans through C1');
    is_deeply(
        [map { $_->origin_kind } @{$result->{composition_plan}->ports}],
        ['inferred_c1_passthrough_port', 'inferred_c1_passthrough_port'],
        'C1 inferred top ports expose passthrough provenance',
    );
    is_deeply(
        [map { $_->origin_kind } @{$result->{composition_plan}->resolved_links}],
        ['inferred_c1_passthrough_link', 'inferred_c1_passthrough_link'],
        'C1 resolved links expose passthrough provenance',
    );
};

subtest 'explicit-link omitted ports expose explicit-toplink and undeclared-port provenance' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $path = File::Spec->catfile($tempdir, 'explicit_toplink_metadata_top.fsm');

    write_file(
        $path,
        <<'FSM'
(?top:explicit_toplink_metadata_top
  (?dtc:producer producer_src)
  (?dtc:consumer consumer_src)
  (?toplink:wiring
    /start/producer.go/
    /start/consumer.go/
    /producer.payload/consumer.payload/
    /consumer.result_data/status/
  )
)

(?dt:producer_src
  (-route
    (<go
      (payload> = 8'5)
    )
  )
  (+size
    (go 1)
    (payload 8)
  )
)

(?dt:consumer_src
  (-route
    (<go
      (result_data> = payload)
    )
  )
  (+size
    (go 1)
    (payload 8)
    (result_data 8)
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $result = $pipeline->generate_hdl_from_file($path);
    my %ports = map { $_->name => $_ } @{$result->{composition_plan}->ports};
    my %resolved_link_origins;
    $resolved_link_origins{$_->origin_kind}++ for @{$result->{composition_plan}->resolved_links};

    is($ports{start}->origin_kind, 'inferred_explicit_toplink_port', 'renamed top input inferred from explicit toplink carries explicit-toplink provenance');
    is($ports{status}->origin_kind, 'inferred_explicit_toplink_port', 'renamed top output inferred from explicit toplink carries explicit-toplink provenance');
    is($resolved_link_origins{declared_explicit_toplink} || 0, 4, 'resolved link set preserves explicit toplink provenance across all explicit links');
};

subtest 'resolved links expose convention and override provenance in explicit-link C2' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $convention_path = File::Spec->catfile($tempdir, 'plain_port_metadata_top.fsm');
    my $reexport_path = File::Spec->catfile($tempdir, 'reexport_metadata_top.fsm');

    write_file(
        $convention_path,
        <<'FSM'
(?top:plain_port_metadata_top
  (?ports:public_io
    payload_in<8
    result_data>8
  )
  (?dtc:producer producer_src)
  (?dtc:consumer consumer_src)
  (?toplink:wiring
    /producer.mid/consumer.mid/
  )
)

(?dt:producer_src
  (-route
    (mid> = payload_in)
  )
  (+size
    (payload_in 8)
    (mid 8)
  )
)

(?dt:consumer_src
  (-route
    (result_data> = (+ mid payload_in))
  )
  (+size
    (payload_in 8)
    (mid 8)
    (result_data 8)
  )
)
FSM
    );

    write_file(
        $reexport_path,
        <<'FSM'
(?top:reexport_metadata_top
  (?ports:public_io
    go
    payload>8
  )
  (?dtc:producer producer_src)
  (?dtc:consumer consumer_src)
  (?toplink:wiring
    /go/producer.go/
    /go/consumer.go/
  )
)

(?dt:producer_src
  (-route
    (<go
      (payload> = 8'3)
    )
  )
  (+size
    (go 1)
    (payload 8)
  )
)

(?dt:consumer_src
  (-route
    (<go
      (sink> = payload)
    )
  )
  (+size
    (go 1)
    (payload 8)
    (sink 8)
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );

    my $convention_result = $pipeline->generate_hdl_from_file($convention_path);
    my %convention_link_origins;
    $convention_link_origins{$_->origin_kind}++ for @{$convention_result->{composition_plan}->resolved_links};
    my %convention_ports = map { $_->name => $_ } @{$convention_result->{composition_plan}->ports};

    is($convention_ports{payload_in}->origin_kind, 'declared_explicit_port', 'plain explicit top input stays declared in the plan');
    is($convention_ports{result_data}->origin_kind, 'declared_explicit_port', 'plain explicit top output stays declared in the plan');
    is($convention_link_origins{declared_explicit_toplink} || 0, 1, 'explicit child-to-child wiring keeps explicit-toplink provenance');
    is($convention_link_origins{inferred_plain_explicit_top_input_link} || 0, 2, 'plain explicit top-input fanout links expose convention provenance');
    is($convention_link_origins{inferred_plain_explicit_top_output_link} || 0, 1, 'plain explicit top-output adoption exposes convention provenance');

    my $reexport_result = $pipeline->generate_hdl_from_file($reexport_path);
    my %reexport_link_origins;
    $reexport_link_origins{$_->origin_kind}++ for @{$reexport_result->{composition_plan}->resolved_links};

    is($reexport_link_origins{inferred_internal_carrier_reexport_link} || 0, 1, 'top-output adoption of an inferred internal carrier records override provenance');
    is($reexport_link_origins{inferred_internal_carrier_link} || 0, 1, 'internal carrier fanout to consumers records internal-carrier provenance');
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
