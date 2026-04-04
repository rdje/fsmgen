#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;
use FSM::Pipeline::SourceFrontend;

subtest 'source frontend rebuilds the bounded direct-root parsing and semantic-module surface' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'source_frontend_direct_root.fsm');

    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:source_frontend_direct_root
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-idle
    (ready> <= 1)
  )
  (+size
    (ready 1)
  )
)
FSM
    );

    my $frontend_raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
        fsm_file => $fsm_path,
        debug_level => 0,
    );
    my $frontend_source_info = FSM::Pipeline::SourceFrontend->classify_source_ast($frontend_raw_ast);
    my $frontend_module = FSM::Pipeline::SourceFrontend->create_fsm_module(
        raw_ast => $frontend_raw_ast,
        debug_level => 0,
    );
    my $pipeline = new_pipeline();
    my $pipeline_result = $pipeline->generate_hdl_from_file($fsm_path);

    is_deeply(
        $frontend_raw_ast,
        $pipeline_result->{raw_ast},
        'source frontend parses the same raw AST surface the pipeline later carries',
    );
    is_deeply(
        $frontend_source_info,
        $pipeline_result->{source_info},
        'source frontend classifies the same direct-root source shape the pipeline later carries',
    );
    is_deeply(
        fsm_module_snapshot($frontend_module),
        fsm_module_snapshot($pipeline_result->{fsm_module}),
        'source frontend builds the same bounded semantic module surface the pipeline later carries',
    );
};

subtest 'source frontend rebuilds the bounded composition parsing surface' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'source_frontend_composition_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:source_frontend_composition_top
  (?ports:public_io
    trigger
    serial_out>
  )
  (?dtc:producer producer_src)
  (?rtl:uart_tx)
  (?toplink:wiring
    /trigger/producer.trigger/
    /producer.serial_payload/uart_tx.data_in/
    /uart_tx.serial_out/serial_out/
  )
)

(?dt:producer_src
  (-route
    (<trigger
      (serial_payload> = 8'1)
    )
    (<!trigger
      (serial_payload> = 8'0)
    )
  )
  (+size
    (trigger 1)
    (serial_payload 8)
  )
)

(?rtlif:uart_tx
  core_clk:clock
  rst_async_n:reset
  data_in<8:data
  serial_out>:data
)
FSM
    );

    my $frontend_raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
        fsm_file => $composition_path,
        debug_level => 0,
    );
    my $frontend_source_info = FSM::Pipeline::SourceFrontend->classify_source_ast($frontend_raw_ast);
    my $frontend_spec = FSM::Pipeline::SourceFrontend->parse_composition_source(
        raw_ast => $frontend_raw_ast,
        debug_level => 0,
    );
    my $pipeline = new_pipeline();
    my $pipeline_result = $pipeline->generate_hdl_from_file($composition_path);

    is_deeply(
        $frontend_raw_ast,
        $pipeline_result->{raw_ast},
        'source frontend parses the same composition raw AST surface the pipeline later carries',
    );
    is_deeply(
        source_info_snapshot($frontend_source_info),
        source_info_snapshot($pipeline_result->{source_info}),
        'source frontend classifies the same composition source shape the pipeline later carries',
    );
    is_deeply(
        composition_spec_snapshot($frontend_spec),
        composition_spec_snapshot($pipeline_result->{composition_spec}),
        'source frontend builds the same bounded composition spec surface the pipeline later carries',
    );
};

subtest 'source frontend preserves brace-grouped explicit toplink tokens before composition parsing' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'source_frontend_nested_toplink_top.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:source_frontend_nested_toplink_top
  (?ports:public_io
    header_bus<3
    status_bus<2
    payload_bus<4
    packed_status>10
  )
  (?rtl:uart_tx)
  (?toplink:wiring
    /header_bus,{status_bus[0],=0b1_0},{payload_bus[3:2],payload_bus[1:0]}/packed_status/
    /header_bus,{status_bus[0],=0b1_0},{payload_bus[3:2],payload_bus[1:0]}/uart_tx.data_in/
  )
)

(?rtlif:uart_tx
  data_in<10:data
)
FSM
    );

    my $frontend_raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
        fsm_file => $composition_path,
        debug_level => 0,
    );
    my $frontend_spec = FSM::Pipeline::SourceFrontend->parse_composition_source(
        raw_ast => $frontend_raw_ast,
        debug_level => 0,
    );
    my $pipeline = new_pipeline();
    my $pipeline_result = $pipeline->generate_hdl_from_file($composition_path);

    is_deeply(
        composition_toplink_tokens($frontend_raw_ast),
        [
            '/header_bus,{status_bus[0],=0b1_0},{payload_bus[3:2],payload_bus[1:0]}/packed_status/',
            '/header_bus,{status_bus[0],=0b1_0},{payload_bus[3:2],payload_bus[1:0]}/uart_tx.data_in/',
        ],
        'source frontend keeps brace-grouped raw toplink tokens intact in the raw AST',
    );

    is_deeply(
        [map { $_->source } @{$frontend_spec->top->toplinks->[0]->links}],
        [
            'header_bus,{status_bus[0],=0b1_0},{payload_bus[3:2],payload_bus[1:0]}',
            'header_bus,{status_bus[0],=0b1_0},{payload_bus[3:2],payload_bus[1:0]}',
        ],
        'source frontend keeps brace-grouped toplink sources intact when it builds the composition spec',
    );

    is_deeply(
        [map { $_->source } @{$pipeline_result->{composition_spec}->top->toplinks->[0]->links}],
        [
            'header_bus,{status_bus[0],=0b1_0},{payload_bus[3:2],payload_bus[1:0]}',
            'header_bus,{status_bus[0],=0b1_0},{payload_bus[3:2],payload_bus[1:0]}',
        ],
        'pipeline keeps brace-grouped toplink sources intact on the carried composition spec surface',
    );

    like(
        $pipeline_result->{hdl_code},
        qr/assign packed_status = \{header_bus, \{status_bus\[0\], 2'b10\}, \{payload_bus\[3:2\], payload_bus\[1:0\]\}\};/,
        'pipeline emits nested concat grouping after the preserved raw toplink token reaches composition lowering',
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

sub fsm_module_snapshot {
    my ($fsm_module) = @_;
    return {
        name => $fsm_module->name,
        source_root_kind => $fsm_module->source_root_kind,
        explicit_system_contract => $fsm_module->explicit_system_contract,
        requires_implicit_system_ports => $fsm_module->requires_implicit_system_ports,
        state_count => scalar(@{$fsm_module->states || []}),
        signal_names => [sort keys %{$fsm_module->signals || {}}],
        parameter_names => [sort keys %{$fsm_module->parameters || {}}],
    };
}

sub composition_spec_snapshot {
    my ($composition_spec) = @_;
    my $top = $composition_spec->top;
    return {
        top_name => $top->name,
        instance_count => scalar(@{$top->instances || []}),
        ports_block_count => scalar(@{$top->ports_blocks || []}),
        toplink_count => scalar(@{$top->toplinks || []}),
        ports_per_block => [map { scalar(@{$_->ports || []}) } @{$top->ports_blocks || []}],
        embedded_fsm_sources => [sort keys %{$composition_spec->embedded_fsm_sources || {}}],
        embedded_dt_sources => [sort keys %{$composition_spec->embedded_dt_sources || {}}],
    };
}

sub source_info_snapshot {
    my ($source_info) = @_;
    return {
        kind => $source_info->{kind},
        header => $source_info->{header},
        root_index => $source_info->{root_index},
        composition_root_count => $source_info->{composition_root_count},
    };
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

sub composition_toplink_tokens {
    my ($raw_ast) = @_;
    my @tokens;
    _collect_toplink_tokens($raw_ast, \@tokens);
    return \@tokens;
}

sub _collect_toplink_tokens {
    my ($node, $tokens) = @_;
    return unless ref($node) eq 'ARRAY';

    if (@$node >= 2 && !ref($node->[0]) && ($node->[0] // '') =~ /^\?toplink:/ && ref($node->[1]) eq 'ARRAY') {
        push @$tokens, grep { defined($_) && !ref($_) && m{^/.+/.+/$} } @{$node->[1]};
    }

    for my $item (@$node) {
        _collect_toplink_tokens($item, $tokens) if ref($item) eq 'ARRAY';
    }
}
