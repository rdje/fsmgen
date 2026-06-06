package FSM::Composition::GenerationOrchestrator;

=head1 NAME

FSM::Composition::GenerationOrchestrator - Orchestrator for bounded composition generation

=head1 DESCRIPTION

Owns the remaining bounded composition generation orchestration that was still
inline in the mixed pipeline coordinator. This package takes an already-parsed
composition source, drives plan construction plus forward-IR assembly, emits
the structural top HDL text, and returns the bounded composition result
surface consumed by the outer pipeline.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';
use Storable qw(dclone);

use FSM::Backend::GeneratedModuleEmitter;
use FSM::Backend::VHDL::StructuralRTLIREmitter;
use FSM::Backend::VerilogFamily::StructuralRTLIREmitter;
use FSM::Composition::ChildExportBuilder;
use FSM::Composition::PackageImportResolver;
use FSM::Composition::PlanBuilder;
use FSM::Composition::ProvenanceReportBuilder;
use FSM::Composition::ResultMetadataBuilder;
use FSM::IR::IntentHIRBuilder;
use FSM::IR::LoweredRTLIRBuilder;
use FSM::IR::StructuralRTLIRBuilder;
use FSM::Pipeline::SourceFrontend;

sub generate_from_source ($class, %args) {
    my $pipeline = $args{pipeline}
        or confess "GenerationOrchestrator requires a pipeline";
    my $fsm_file = $args{fsm_file}
        or confess "GenerationOrchestrator requires an fsm_file";
    my $source_info = _clone($args{source_info} || {});
    my $raw_ast = $args{raw_ast};
    my $target_language = $args{target_language} // ($pipeline->{target_language} // 'systemverilog');
    my $header = $args{header} // ($source_info->{header} // '?top:name');
    my $composition_spec = $args{composition_spec}
        || $source_info->{composition_spec}
        || FSM::Pipeline::SourceFrontend->parse_composition_source(
            raw_ast => $raw_ast,
            debug_level => ($pipeline->{debug_level} // 0),
        );
    my $source_path_resolver = $args{source_path_resolver} // $pipeline->{source_path_resolver};
    my $rtl_interface_loader = $args{rtl_interface_loader} // $pipeline->{rtl_interface_loader};
    my $statistics_seed = $args{statistics_seed}
        // FSM::Backend::GeneratedModuleEmitter->statistics_from_generator(undef);

    $source_info->{composition_spec} = _clone($composition_spec);

    my $resolved_package_imports = $args{resolved_package_imports}
        || $source_info->{resolved_package_imports}
        || FSM::Composition::PackageImportResolver->resolve_imports(
            composition_spec => $composition_spec,
            fsm_file => $fsm_file,
            source_path_resolver => $source_path_resolver,
            debug_level => ($pipeline->{debug_level} // 0),
        );

    my $composition_plan = FSM::Composition::PlanBuilder->build_plan(
        pipeline => $pipeline,
        composition_spec => $composition_spec,
        fsm_file => $fsm_file,
        header => $header,
        target_language => $target_language,
        source_path_resolver => $source_path_resolver,
        rtl_interface_loader => $rtl_interface_loader,
    );
    my $structural_rtl_ir = FSM::IR::StructuralRTLIRBuilder->build_from_composition_plan(
        $composition_plan,
        $target_language,
    );
    my $composition_child_exports = FSM::Composition::ChildExportBuilder->build_child_exports(
        composition_plan => $composition_plan,
        structural_rtl_ir => $structural_rtl_ir,
        target_language => $target_language,
    );
    my $generated_child_exports = FSM::Composition::ChildExportBuilder->build_generated_child_exports(
        composition_child_exports => $composition_child_exports,
    );
    my $standalone_dt_child_exports = FSM::Composition::ChildExportBuilder->build_standalone_dt_child_exports(
        composition_child_exports => $composition_child_exports,
    );
    my $intent_hir = FSM::IR::IntentHIRBuilder->build_from_composition_plan(
        composition_plan => $composition_plan,
        composition_child_exports => $composition_child_exports,
        generated_child_exports => $generated_child_exports,
        standalone_dt_child_exports => $standalone_dt_child_exports,
        structural_rtl_ir => $structural_rtl_ir,
        target_language => $target_language,
    );
    my $composition_report = FSM::Composition::ProvenanceReportBuilder->build_report(
        composition_plan => $composition_plan,
        structural_rtl_ir => $structural_rtl_ir,
        intent_hir => $intent_hir,
        target_language => $target_language,
    );
    my $lowered_rtl_ir = FSM::IR::LoweredRTLIRBuilder->build_from_composition_plan(
        composition_plan => $composition_plan,
        structural_rtl_ir => $structural_rtl_ir,
        intent_hir => $intent_hir,
        target_language => $target_language,
    );

    my @child_segments = grep { defined && length } map { $_->hdl_code } @{$composition_plan->instances};
    my @segments = @child_segments;
    if (($target_language // '') eq 'vhdl') {
        confess
            "Composition target support is blocked because generated-child VHDL composition is outside the bounded VHDL structural-top leaves. ".
            "Target language 'vhdl' is not implemented for this composition shape yet. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            if @child_segments
                && !_is_bounded_standalone_dt_vhdl_top($composition_plan)
                && !_is_bounded_generated_fsm_c2_vhdl_top($composition_plan)
                && !_is_bounded_apb_c4_vhdl_top($composition_plan);
        push @segments, FSM::Backend::VHDL::StructuralRTLIREmitter->emit_module($structural_rtl_ir);
    } else {
        push @segments, FSM::Backend::VerilogFamily::StructuralRTLIREmitter->emit_module($structural_rtl_ir);
    }
    my $hdl_code = join("\n\n", grep { defined && length } @segments) . "\n";

    my $module_info = FSM::Composition::ResultMetadataBuilder->build_module_info(
        composition_plan => $composition_plan,
        composition_report => $composition_report,
        composition_child_exports => $composition_child_exports,
        generated_child_exports => $generated_child_exports,
        standalone_dt_child_exports => $standalone_dt_child_exports,
        intent_hir => $intent_hir,
        lowered_rtl_ir => $lowered_rtl_ir,
        structural_rtl_ir => $structural_rtl_ir,
    );
    my $statistics = FSM::Composition::ResultMetadataBuilder->build_statistics(
        composition_plan => $composition_plan,
        composition_report => $composition_report,
        intent_hir => $intent_hir,
        lowered_rtl_ir => $lowered_rtl_ir,
        structural_rtl_ir => $structural_rtl_ir,
        statistics_seed => $statistics_seed,
    );

    return {
        fsm_module => undef,
        composition_spec => $composition_spec,
        composition_plan => $composition_plan,
        composition_report => $composition_report,
        intent_hir => $intent_hir->as_hashref,
        lowered_rtl_ir => $lowered_rtl_ir->as_hashref,
        structural_rtl_ir => $structural_rtl_ir->as_hashref,
        module_info => $module_info,
        hdl_code => $hdl_code,
        statistics => $statistics,
        resolved_package_imports => _clone($resolved_package_imports),
        raw_ast => _clone($raw_ast),
        source_info => $source_info,
    };
}
sub _clone ($value) {
    return undef unless defined $value;
    return [map { _clone($_) } @$value] if ref($value) eq 'ARRAY';
    return {map { $_ => _clone($value->{$_}) } keys %$value} if ref($value) eq 'HASH';
    return dclone($value) if ref($value);
    return $value;
}

sub _is_bounded_standalone_dt_vhdl_top ($composition_plan) {
    my @instances = @{$composition_plan->instances || []};
    return 0 unless @instances == 1;
    return 0 unless ($instances[0]->kind // '') eq 'dtc';
    return 0 if @{$composition_plan->nets || []};
    return 0 if @{$composition_plan->auxiliary_assignments || []};
    return 0 unless _has_only_supported_standalone_dt_generic_overrides($instances[0]);
    return 1;
}

sub _has_only_supported_standalone_dt_generic_overrides ($instance) {
    for my $override (@{$instance->parameter_overrides || []}) {
        my $kind = $override->{value_kind} // 'scalar';
        my $is_scalar = $kind eq 'scalar';
        my $is_packed_list = $kind eq 'list';
        return 0 unless $is_scalar || $is_packed_list;

        my $value = $override->{value_text};
        return 0 unless defined($value);
        next if $is_scalar && $value =~ /\A-?\d+\z/;
        next if $is_scalar && $value =~ /\A\(\s*-?\d+(?:\s+[-+*\/]\s+-?\d+)+\s*\)\z/;
        next if $is_scalar
            && _is_metadata_backed_scalar_one_bit_generic_override($override)
            && _is_supported_one_bit_sized_bitstring_literal($value);
        next if $is_scalar
            && _is_metadata_backed_scalar_multi_bit_generic_override($override)
            && _is_supported_multi_bit_sized_bitstring_literal($value);
        next if $is_packed_list
            && _is_metadata_backed_packed_list_generic_override($override)
            && _is_supported_multi_bit_sized_bitstring_literal($value);
        return 0;
    }
    return 1;
}

sub _is_metadata_backed_scalar_one_bit_generic_override ($override) {
    return 0 unless ($override->{value_kind} // 'scalar') eq 'scalar';
    return 0 unless ($override->{declaration_default_value_kind} // '') eq 'scalar';
    return 0
        unless defined $override->{declaration_default_value_width}
        && $override->{declaration_default_value_width} =~ /\A\d+\z/
        && $override->{declaration_default_value_width} == 1;
    return 0
        unless defined $override->{value_width}
        && $override->{value_width} =~ /\A\d+\z/
        && $override->{value_width} == 1;
    return 1;
}

sub _is_metadata_backed_scalar_multi_bit_generic_override ($override) {
    return 0 unless ($override->{value_kind} // 'scalar') eq 'scalar';
    return 0 unless ($override->{declaration_default_value_kind} // '') eq 'scalar';
    return 0
        unless defined $override->{declaration_default_value_width}
        && $override->{declaration_default_value_width} =~ /\A\d+\z/;
    return 0
        unless defined $override->{value_width}
        && $override->{value_width} =~ /\A\d+\z/;

    my $decl_width = $override->{declaration_default_value_width} + 0;
    my $value_width = $override->{value_width} + 0;
    return 0 unless $decl_width > 1;
    return $decl_width == $value_width ? 1 : 0;
}

sub _is_metadata_backed_packed_list_generic_override ($override) {
    return 0 unless ($override->{value_kind} // '') eq 'list';
    return 0 unless ($override->{declaration_default_value_kind} // '') eq 'list';
    return 0
        unless defined $override->{declaration_default_value_width}
        && $override->{declaration_default_value_width} =~ /\A\d+\z/;
    return 0
        unless defined $override->{value_width}
        && $override->{value_width} =~ /\A\d+\z/;

    my $decl_width = $override->{declaration_default_value_width} + 0;
    my $value_width = $override->{value_width} + 0;
    return 0 unless $decl_width > 1;
    return $decl_width == $value_width ? 1 : 0;
}

sub _is_bounded_generated_fsm_c2_vhdl_top ($composition_plan) {
    return 0 unless ($composition_plan->lane // '') eq 'C2';
    my @instances = @{$composition_plan->instances || []};
    my @nets = @{$composition_plan->nets || []};
    my @ports = @{$composition_plan->ports || []};
    return 0 unless @instances == 2;
    return 0 unless @nets == 3;
    return 0 unless @ports == 3;
    return 0 if @{$composition_plan->auxiliary_assignments || []};

    for my $instance (@instances) {
        return 0 unless ($instance->kind // '') eq 'fsmc';
        return 0 unless _has_only_supported_generated_fsm_generic_overrides($instance);
    }

    for my $entry (@nets, @ports) {
        my $width = ref($entry) eq 'HASH' ? ($entry->{width} // 0) : $entry->width;
        return 0 unless $width == 1;
    }

    return 1;
}

sub _is_bounded_apb_c4_vhdl_top ($composition_plan) {
    return 0 unless ($composition_plan->lane // '') eq 'C4';
    my @instances = @{$composition_plan->instances || []};
    my @nets = @{$composition_plan->nets || []};
    my @ports = @{$composition_plan->ports || []};
    return 0 unless @instances == 2;
    return 0 unless @nets == 31;
    return 0 unless @ports == 11;
    return 0 if @{$composition_plan->auxiliary_assignments || []};

    my %expected_instance_module = (
        requester => 'apb_requester',
        completer => 'apb_completer',
    );
    for my $instance (@instances) {
        my $name = $instance->instance_name // '';
        return 0 unless ($instance->kind // '') eq 'fsmc';
        return 0 unless ($expected_instance_module{$name} // '') eq ($instance->module_name // '');
        return 0 if @{$instance->parameter_overrides || []};
        delete $expected_instance_module{$name};
    }
    return 0 if keys %expected_instance_module;

    return 0 unless _entries_match_widths(
        \@ports,
        {
            clk => 1,
            rst_n => 1,
            start => 1,
            req_write => 1,
            req_addr => 32,
            req_wdata => 32,
            wait_cycles => 4,
            busy => 1,
            done => 1,
            last_error => 1,
            last_read_data => 32,
        },
    );

    return 0 unless _entries_match_widths(
        \@nets,
        {
            comp_link_completer_PRDATA => 32,
            comp_link_completer_PREADY => 1,
            comp_link_completer_PSLVERR => 1,
            comp_link_requester_PADDR => 32,
            comp_link_requester_PENABLE => 1,
            comp_link_requester_PSEL => 1,
            comp_link_requester_PWDATA => 32,
            comp_link_requester_PWRITE => 1,
            shared_dp_unused_requester_shared_dp_export_paddr_32_h0_en => 1,
            shared_dp_unused_requester_shared_dp_export_paddr_addr_q_en => 1,
            shared_dp_unused_requester_shared_dp_export_penable_0_en => 1,
            shared_dp_unused_requester_shared_dp_export_penable_1_en => 1,
            shared_dp_unused_requester_shared_dp_export_psel_0_en => 1,
            shared_dp_unused_requester_shared_dp_export_psel_1_en => 1,
            shared_dp_unused_requester_shared_dp_export_pwdata_32_h0_en => 1,
            shared_dp_unused_requester_shared_dp_export_pwdata_wdata_q_en => 1,
            shared_dp_unused_requester_shared_dp_export_pwrite_0_en => 1,
            shared_dp_unused_requester_shared_dp_export_pwrite_write_q_en => 1,
            shared_dp_unused_requester_shared_dp_export_busy_0_en => 1,
            shared_dp_unused_requester_shared_dp_export_busy_1_en => 1,
            shared_dp_unused_requester_shared_dp_export_done_0_en => 1,
            shared_dp_unused_requester_shared_dp_export_done_1_en => 1,
            shared_dp_unused_requester_shared_dp_export_last_error_0_en => 1,
            shared_dp_unused_requester_shared_dp_export_last_error_pslverr_en => 1,
            shared_dp_unused_requester_shared_dp_export_last_read_data_prdata_en => 1,
            shared_dp_unused_completer_shared_dp_export_prdata_32_h0_en => 1,
            shared_dp_unused_completer_shared_dp_export_prdata_reg_data_q_en => 1,
            shared_dp_unused_completer_shared_dp_export_pready_0_en => 1,
            shared_dp_unused_completer_shared_dp_export_pready_1_en => 1,
            shared_dp_unused_completer_shared_dp_export_pslverr_0_en => 1,
            shared_dp_unused_completer_shared_dp_export_pslverr_1_en => 1,
        },
    );

    return 1;
}

sub _entries_match_widths ($entries, $expected_widths) {
    my %remaining = %$expected_widths;
    return 0 unless @$entries == keys %remaining;

    for my $entry (@$entries) {
        my $name = ref($entry) eq 'HASH' ? ($entry->{name} // '') : $entry->name;
        my $width = ref($entry) eq 'HASH' ? ($entry->{width} // 0) : $entry->width;
        return 0 unless exists $remaining{$name};
        return 0 unless $width == $remaining{$name};
        delete $remaining{$name};
    }

    return keys(%remaining) == 0 ? 1 : 0;
}

sub _has_only_supported_generated_fsm_generic_overrides ($instance) {
    my @overrides = @{$instance->parameter_overrides || []};
    for my $override (@overrides) {
        my $kind = $override->{value_kind} // 'scalar';
        my $is_scalar = $kind eq 'scalar';
        my $is_packed_aggregate = $kind eq 'list' || $kind eq 'map';
        return 0 unless $is_scalar || $is_packed_aggregate;

        my $value = $override->{value_text};
        return 0 unless defined($value);
        next if $is_scalar && $value =~ /\A-?\d+\z/;
        next if $is_scalar && _is_scalar_integer_expression($value);
        next if _is_supported_generated_fsm_sized_bitstring_literal(
            $value,
            allow_one_bit => $is_scalar,
        );
        return 0;
    }
    return 1;
}

sub _is_scalar_integer_expression ($value) {
    return $value =~ /\A\(\s*-?\d+(?:\s+[-+*\/]\s+-?\d+)+\s*\)\z/ ? 1 : 0;
}

sub _is_supported_generated_fsm_sized_bitstring_literal ($value, %opts) {
    return 0
        unless $value =~ /\A([1-9][0-9]*)'([bBhH])([0-9A-Fa-f_xXzZ]+)\z/;

    my ($width, $base, $digits) = ($1 + 0, lc($2), $3);
    return 0 if $width <= 1 && !$opts{allow_one_bit};
    return 0 if $digits =~ /[xz]/i;

    $digits =~ s/_//g;
    my $bit_count = $base eq 'b'
        ? _binary_bit_count($digits)
        : _hex_bit_count($digits);
    return 0 unless defined $bit_count;
    return $bit_count <= $width ? 1 : 0;
}

sub _is_supported_one_bit_sized_bitstring_literal ($value) {
    return 0
        unless $value =~ /\A1'([bBhH])([0-9A-Fa-f_xXzZ]+)\z/;

    my ($base, $digits) = (lc($1), $2);
    return 0 if $digits =~ /[xz]/i;

    $digits =~ s/_//g;
    my $bit_count = $base eq 'b'
        ? _binary_bit_count($digits)
        : _hex_bit_count($digits);
    return 0 unless defined $bit_count;
    return $bit_count <= 1 ? 1 : 0;
}

sub _is_supported_multi_bit_sized_bitstring_literal ($value) {
    return 0
        unless $value =~ /\A([1-9][0-9]*)'([bBhH])([0-9A-Fa-f_xXzZ]+)\z/;

    my ($width, $base, $digits) = ($1 + 0, lc($2), $3);
    return 0 unless $width > 1;
    return 0 if $digits =~ /[xz]/i;

    $digits =~ s/_//g;
    my $bit_count = $base eq 'b'
        ? _binary_bit_count($digits)
        : _hex_bit_count($digits);
    return 0 unless defined $bit_count;
    return $bit_count <= $width ? 1 : 0;
}

sub _binary_bit_count ($digits) {
    return undef unless $digits =~ /\A[01]+\z/;
    return length($digits);
}

sub _hex_bit_count ($digits) {
    return undef unless $digits =~ /\A[0-9A-Fa-f]+\z/;

    my %hex_to_bits = (
        0 => '0000',
        1 => '0001',
        2 => '0010',
        3 => '0011',
        4 => '0100',
        5 => '0101',
        6 => '0110',
        7 => '0111',
        8 => '1000',
        9 => '1001',
        a => '1010',
        b => '1011',
        c => '1100',
        d => '1101',
        e => '1110',
        f => '1111',
    );

    my $bits = join '', map { $hex_to_bits{lc($_)} } split //, $digits;
    $bits =~ s/\A0+(?=.)//;
    return length($bits);
}

1;

__END__

=head1 METHODS

=head2 generate_from_source

Builds the bounded composition generation result surface from parsed source
inputs, driving plan construction, forward-IR assembly, structural HDL
emission, and result-metadata assembly.

=cut
