package FSM::Composition::PlanBuilder;

=head1 NAME

FSM::Composition::PlanBuilder - Builder for bounded composition plan orchestration

=head1 DESCRIPTION

Owns the remaining bounded composition-plan orchestration family for the active
lanes. This package coordinates child realization, top-port inference gating,
lane selection, and shared-datapath plan augmentation while delegating the
lane-specific wiring work to the narrower C1 and linked-plan builders.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Composition::C1PlanBuilder;
use FSM::Composition::DeclaredByNameLinkBuilder;
use FSM::Composition::GeneratedChildRealizer;
use FSM::Composition::LinkedPlanBuilder;
use FSM::Composition::PortsBlock;
use FSM::Composition::RTLChildRealizer;
use FSM::Composition::SharedDatapathCandidateBuilder;
use FSM::Composition::SharedDatapathSupport;
use FSM::Composition::TopPortInferenceBuilder;

sub build_plan ($class, %args) {
    my $pipeline = $args{pipeline}
        or confess "PlanBuilder requires a pipeline";
    my $composition_spec = $args{composition_spec}
        or confess "PlanBuilder requires a composition_spec";
    my $fsm_file = $args{fsm_file}
        or confess "PlanBuilder requires an fsm_file";
    my $header = $args{header} // '?top:name';
    my $target_language = $args{target_language} // ($pipeline->{target_language} // 'systemverilog');
    my $source_path_resolver = $args{source_path_resolver} // $pipeline->{source_path_resolver};
    my $rtl_interface_loader = $args{rtl_interface_loader} // $pipeline->{rtl_interface_loader};

    $class->assert_supported_target(
        target_language => $target_language,
        fsm_file => $fsm_file,
        header => $header,
    );

    my $top = $composition_spec->top;
    my @instances = @{$top->instances || []};
    my @ports_blocks = @{$top->ports_blocks || []};
    my @wiring_blocks = @{$top->wiring_blocks || []};

    confess
        "Composition source '$header' in '$fsm_file' is recognized and parsed into typed composition IR, ".
        "but composition lane entry is blocked because the current active composition lanes require at least one child instance such as '?fsmc', '?dtc', or '?rtl'. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
        unless @instances;

    $class->assert_vhdl_structural_top_candidate(
        target_language => $target_language,
        fsm_file => $fsm_file,
        header => $header,
        instances => \@instances,
        wiring_blocks => \@wiring_blocks,
    );

    my @realized_instances = @{$class->realize_instances(
        pipeline => $pipeline,
        composition_spec => $composition_spec,
        instances => \@instances,
        fsm_file => $fsm_file,
        header => $header,
        source_path_resolver => $source_path_resolver,
        rtl_interface_loader => $rtl_interface_loader,
        target_language => $target_language,
    )};

    my $is_single_child_passthrough = @realized_instances == 1 && !@wiring_blocks;
    my $allows_implicit_explicit_link_ports =
        !$is_single_child_passthrough
        && @wiring_blocks
        && (
            @ports_blocks == 0
            || (@ports_blocks == 1 && !(scalar(@{$ports_blocks[0]->ports || []})))
        );
    my $allows_implicit_c1_ports =
        $is_single_child_passthrough
        && (
            @ports_blocks == 0
            || (@ports_blocks == 1 && !(scalar(@{$ports_blocks[0]->ports || []})))
        );

    confess
        "Composition source '$header' in '$fsm_file' is recognized and parsed into typed composition IR, ".
        "but composition shape is blocked because the current active composition lanes require exactly one explicit '?ports' block, ".
        "except that the single-child passthrough C1 lane and the explicit-link C2/C3 lanes may now infer the top interface when '?ports' is omitted or empty. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
        unless @ports_blocks <= 1;

    my $ports_block = $ports_blocks[0];
    my @ports = $ports_block ? @{$ports_block->ports || []} : ();

    if (!$allows_implicit_c1_ports && !$allows_implicit_explicit_link_ports) {
        confess
            "Composition source '$header' in '$fsm_file' is recognized and parsed into typed composition IR, ".
            "but composition shape is blocked because the current active composition lanes require exactly one explicit '?ports' block. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless @ports_blocks == 1;

        confess
            "Composition source '$header' in '$fsm_file' is recognized and parsed into typed composition IR, ".
            "but composition shape is blocked because the current active composition lanes require '?ports' to declare at least one explicit top port, ".
            "except that the single-child passthrough C1 lane and the explicit-link C2/C3 lanes may now infer the top interface when '?ports' is omitted or empty. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless @ports;
    }

    my $rtl_instance_count = scalar(grep { $_->kind eq 'rtl' } @realized_instances);
    my $generated_instance_count = scalar(grep { $class->is_generated_child_kind($_->kind) } @realized_instances);
    my $declared_by_name_port_count = scalar(grep { ($_->binding_mode || 'explicit') eq 'connect_by_name' } @ports);

    if (!$declared_by_name_port_count && !$is_single_child_passthrough) {
        @ports = @{FSM::Composition::TopPortInferenceBuilder->augment_ports(
            ports => \@ports,
            wiring_blocks => \@wiring_blocks,
            realized_instances => \@realized_instances,
            fsm_file => $fsm_file,
            header => $header,
        )};
    }

    if (@ports && (!$ports_block || scalar(@{$ports_block->ports || []}) != scalar(@ports))) {
        $ports_block = FSM::Composition::PortsBlock->new(
            name => ($ports_block ? $ports_block->name : undef),
            ports => \@ports,
            raw_ast => ($ports_block ? $ports_block->raw_ast : undef),
        );
    }

    if ($declared_by_name_port_count > 0) {
        return $class->build_c4_plan(
            composition_spec => $composition_spec,
            top => $top,
            ports_block => $ports_block,
            ports => \@ports,
            wiring_blocks => \@wiring_blocks,
            realized_instances => \@realized_instances,
            generated_instance_count => $generated_instance_count,
            rtl_instance_count => $rtl_instance_count,
            fsm_file => $fsm_file,
            header => $header,
            target_language => $target_language,
        );
    }

    if (@realized_instances == 1 && !@wiring_blocks) {
        return FSM::Composition::C1PlanBuilder->build_plan(
            composition_spec => $composition_spec,
            ports_block => $ports_block,
            ports => \@ports,
            realized_instance => $realized_instances[0],
            fsm_file => $fsm_file,
            header => $header,
        );
    }

    if ($rtl_instance_count > 0) {
        return $class->build_c3_plan(
            composition_spec => $composition_spec,
            top => $top,
            ports_block => $ports_block,
            ports => \@ports,
            wiring_blocks => \@wiring_blocks,
            realized_instances => \@realized_instances,
            rtl_instance_count => $rtl_instance_count,
            fsm_file => $fsm_file,
            header => $header,
            target_language => $target_language,
        );
    }

    return $class->build_c2_plan(
        composition_spec => $composition_spec,
        top => $top,
        ports_block => $ports_block,
        ports => \@ports,
        wiring_blocks => \@wiring_blocks,
        realized_instances => \@realized_instances,
        fsm_file => $fsm_file,
        header => $header,
        target_language => $target_language,
    );
}

sub assert_supported_target ($class, %args) {
    my $target_language = $args{target_language} // '';
    my $fsm_file = $args{fsm_file};
    my $header = $args{header};

    return if $target_language =~ /^(?:systemverilog|sv|verilog|v|vhdl)$/;

    confess
        "Composition source '$header' in '$fsm_file' is recognized and parsed into typed composition IR, ".
        "but composition target support is blocked because the current active composition lanes only emit SystemVerilog/Verilog tops. ".
        "Target language '$target_language' is not implemented for composition yet. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
}

sub assert_vhdl_structural_top_candidate ($class, %args) {
    my $target_language = $args{target_language} // '';
    return unless $target_language eq 'vhdl';

    my $instances = $args{instances} || [];
    my $wiring_blocks = $args{wiring_blocks} || [];
    my $fsm_file = $args{fsm_file};
    my $header = $args{header};

    my @non_rtl = grep { ($_->kind // '') ne 'rtl' } @$instances;
    my $non_rtl_reason = _vhdl_non_rtl_instance_reason(\@non_rtl);
    $class->_confess_vhdl_composition_shape_blocked(
        fsm_file => $fsm_file,
        header => $header,
        reason => $non_rtl_reason,
    ) if @non_rtl;

    $class->_confess_vhdl_composition_shape_blocked(
        fsm_file => $fsm_file,
        header => $header,
        reason => "the first structural-top leaf requires exactly one external '?rtl' instance",
    ) unless @$instances == 1;

    $class->_confess_vhdl_composition_shape_blocked(
        fsm_file => $fsm_file,
        header => $header,
        reason => "the first structural-top leaf requires explicit literal/concat '?wiring'",
    ) unless @$wiring_blocks;
}

sub _confess_vhdl_composition_shape_blocked ($class, %args) {
    my $fsm_file = $args{fsm_file};
    my $header = $args{header};
    my $reason = $args{reason} // 'shape is outside the first structural-top leaf';

    confess
        "Composition source '$header' in '$fsm_file' is recognized and parsed into typed composition IR, ".
        "but composition target support is blocked because the current active VHDL composition leaf only emits the bounded C3 external-RTL literal/concat structural top. ".
        "Target language 'vhdl' is not implemented for this composition shape yet: $reason. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
}

sub _vhdl_non_rtl_instance_reason ($instances) {
    my %kind = map { (($_->kind // '') => 1) } @$instances;
    return "standalone-DT child composition VHDL is outside the first structural-top leaf"
        if $kind{dtc} && !($kind{fsmc});
    return "generated-child and standalone-DT child composition VHDL are outside the first structural-top leaf"
        if $kind{dtc} && $kind{fsmc};
    return "generated-child composition VHDL is outside the first structural-top leaf";
}

sub realize_instances ($class, %args) {
    my $pipeline = $args{pipeline}
        or confess "PlanBuilder::realize_instances requires a pipeline";
    my $composition_spec = $args{composition_spec}
        or confess "PlanBuilder::realize_instances requires a composition_spec";
    my $instances = $args{instances} || [];
    my $fsm_file = $args{fsm_file}
        or confess "PlanBuilder::realize_instances requires an fsm_file";
    my $header = $args{header} // '?top:name';
    my $source_path_resolver = $args{source_path_resolver} // $pipeline->{source_path_resolver};
    my $rtl_interface_loader = $args{rtl_interface_loader} // $pipeline->{rtl_interface_loader};

    my @realized_instances;
    for my $instance (@$instances) {
        if ($instance->kind eq 'fsmc') {
            push @realized_instances, FSM::Composition::GeneratedChildRealizer->realize_fsmc_child_instance(
                pipeline => $pipeline,
                instance => $instance,
                composition_spec => $composition_spec,
                fsm_file => $fsm_file,
                header => $header,
                source_path_resolver => $source_path_resolver,
            );
            next;
        }

        if ($instance->kind eq 'dtc') {
            push @realized_instances, FSM::Composition::GeneratedChildRealizer->realize_dtc_child_instance(
                pipeline => $pipeline,
                instance => $instance,
                composition_spec => $composition_spec,
                fsm_file => $fsm_file,
                header => $header,
                source_path_resolver => $source_path_resolver,
            );
            next;
        }

        if ($instance->kind eq 'rtl') {
            push @realized_instances, FSM::Composition::RTLChildRealizer->realize_rtl_child_instance(
                rtl_interface_loader => $rtl_interface_loader,
                instance => $instance,
                composition_spec => $composition_spec,
                fsm_file => $fsm_file,
                target_language => $args{target_language},
            );
            next;
        }

        confess
            "Composition source '$header' in '$fsm_file' uses unsupported child kind '".$instance->kind."'. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
    }

    return \@realized_instances;
}

sub is_generated_child_kind ($class, $kind) {
    return $kind eq 'fsmc' || $kind eq 'dtc';
}

sub build_c2_plan ($class, %args) {
    my $realized_instances = $args{realized_instances} || [];
    my $fsm_file = $args{fsm_file};
    my $header = $args{header};

    confess
        "Composition source '$header' in '$fsm_file' is recognized and parsed into typed composition IR, ".
        "but C2 lane selection is blocked because the current active C2 lane requires at least two generated child instances such as '?fsmc' or '?dtc'. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
        unless @$realized_instances >= 2;

    confess
        "Composition source '$header' in '$fsm_file' mixes '?rtl' children into the generated-child-only C2 lane. ".
        "The active mixed external-RTL lane is C3 instead. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
        if grep { !$class->is_generated_child_kind($_->kind) } @$realized_instances;

    my $composition_plan = FSM::Composition::LinkedPlanBuilder->build_from_wiring_blocks(
        lane => 'C2',
        composition_spec => $args{composition_spec},
        top => $args{top},
        ports_block => $args{ports_block},
        ports => $args{ports},
        wiring_blocks => $args{wiring_blocks},
        realized_instances => $realized_instances,
        fsm_file => $fsm_file,
        header => $header,
        target_language => $args{target_language},
    );
    return $class->augment_with_shared_datapath(
        composition_plan => $composition_plan,
        target_language => $args{target_language},
    );
}

sub build_c3_plan ($class, %args) {
    my $rtl_instance_count = $args{rtl_instance_count} || 0;
    my $realized_instances = $args{realized_instances} || [];
    my $fsm_file = $args{fsm_file};
    my $header = $args{header};

    confess
        "Composition source '$header' in '$fsm_file' is recognized and parsed into typed composition IR, ".
        "but the current active C3 lane requires at least one '?rtl' child and otherwise allows any number of generated children ('?fsmc' or '?dtc') beside those external RTL children. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
        unless $rtl_instance_count >= 1;

    my $composition_plan = FSM::Composition::LinkedPlanBuilder->build_from_wiring_blocks(
        lane => 'C3',
        composition_spec => $args{composition_spec},
        top => $args{top},
        ports_block => $args{ports_block},
        ports => $args{ports},
        wiring_blocks => $args{wiring_blocks},
        realized_instances => $realized_instances,
        fsm_file => $fsm_file,
        header => $header,
        target_language => $args{target_language},
    );
    return $class->augment_with_shared_datapath(
        composition_plan => $composition_plan,
        target_language => $args{target_language},
    );
}

sub build_c4_plan ($class, %args) {
    my $ports = $args{ports} || [];
    my $realized_instances = $args{realized_instances} || [];
    my $generated_instance_count = $args{generated_instance_count} || 0;
    my $rtl_instance_count = $args{rtl_instance_count} || 0;
    my $fsm_file = $args{fsm_file};
    my $header = $args{header};

    my $declared_by_name_port_count = scalar(grep { ($_->binding_mode || 'explicit') eq 'connect_by_name' } @$ports);
    confess
        "Composition source '$header' in '$fsm_file' requests declared connect-by-name, ".
        "but the current active C4 lane requires at least one '=port' declaration inside '?ports'. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
        unless $declared_by_name_port_count;

    confess
        "Composition source '$header' in '$fsm_file' requests declared connect-by-name, ".
        "but the current active C4 lane requires at least one realized child instance. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
        unless @$realized_instances >= 1;

    confess
        "Composition source '$header' in '$fsm_file' requests declared connect-by-name, ".
        "but the current active C4 lane only extends the already shipped child-realization sets: ".
        "one or more generated children ('?fsmc' / '?dtc'), one or more '?rtl' children, or any mixture of those generated and external RTL children. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
        unless ($generated_instance_count >= 1)
            || ($rtl_instance_count >= 1);

    my @links = map { @{$_->links || []} } @{$args{wiring_blocks} || []};
    push @links, @{FSM::Composition::DeclaredByNameLinkBuilder->build_links(
        ports => $ports,
        realized_instances => $realized_instances,
        fsm_file => $fsm_file,
        header => $header,
    )};

    my $composition_plan = FSM::Composition::LinkedPlanBuilder->build_plan(
        lane => 'C4',
        composition_spec => $args{composition_spec},
        top => $args{top},
        ports_block => $args{ports_block},
        ports => $ports,
        links => \@links,
        realized_instances => $realized_instances,
        fsm_file => $fsm_file,
        header => $header,
        target_language => $args{target_language},
    );
    return $class->augment_with_shared_datapath(
        composition_plan => $composition_plan,
        target_language => $args{target_language},
    );
}

sub augment_with_shared_datapath ($class, %args) {
    my $composition_plan = $args{composition_plan}
        or confess "PlanBuilder::augment_with_shared_datapath requires a composition_plan";
    my $target_language = $args{target_language} // 'systemverilog';

    return FSM::Composition::SharedDatapathSupport->augment_plan(
        composition_plan => $composition_plan,
        shared_datapath_candidates => FSM::Composition::SharedDatapathCandidateBuilder->candidates_for_plan(
            composition_plan => $composition_plan,
            target_language => $target_language,
        ),
        target_language => $target_language,
    );
}

1;

__END__

=head1 METHODS

=head2 build_plan

Builds the bounded composition plan for one typed composition source,
including child realization dispatch, top-port inference gating, lane
selection, and shared-datapath augmentation.

=head2 assert_supported_target

Checks that the requested backend target is inside the currently supported
composition target family.

=head2 realize_instances

Realizes the declared `?fsmc`, `?dtc`, and `?rtl` children into normalized
L<FSM::Composition::RealizedInstance> carriers using the active child-specific
realizer packages.

=head2 is_generated_child_kind

Returns true when a realized child kind belongs to the generated-child family
used by the bounded `C2` lane.

=head2 build_c2_plan

Builds the generated-child-only explicit-link `C2` lane and applies the
bounded shared-datapath augmentation pass.

=head2 build_c3_plan

Builds the mixed external-RTL `C3` explicit-link lane and applies the bounded
shared-datapath augmentation pass.

=head2 build_c4_plan

Builds the declared connect-by-name `C4` lane and applies the bounded
shared-datapath augmentation pass.

=head2 augment_with_shared_datapath

Applies shared-datapath candidate discovery plus runtime plan augmentation to
an already-built composition plan.

=cut
