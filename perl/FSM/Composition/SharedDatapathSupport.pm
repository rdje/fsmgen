package FSM::Composition::SharedDatapathSupport;

=head1 NAME

FSM::Composition::SharedDatapathSupport - Shared-datapath naming and runtime support helpers

=head1 DESCRIPTION

Owns the bounded shared-datapath support family used by the active composition
lanes. This includes deterministic helper-signal naming, shared-datapath
assertion metadata and rendering, generated-child source-export metadata, and
runtime augmentation of a composition plan once candidate metadata already
exists.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Composition::Net;
use FSM::IR::StructuralRTLIR::ConnectionExpr qw(
    binding_signal_summaries_by_port
    ensure_signal_ref_binding
    set_signal_ref_binding
);

sub clean_enable_name_token ($class, $name) {
    $name = lc($name // '');
    $name =~ s/[^a-zA-Z0-9_]/_/g;
    $name =~ s/__+/_/g;
    $name =~ s/^_+//;
    $name =~ s/_+$//;

    if ($name eq '0') {
        return '0';
    } elsif ($name eq '1') {
        return '1';
    }

    $name =~ s/^(\d)/_$1/;
    return $name;
}

sub value_enable_name ($class, $signal_name, $rhs_value) {
    my $clean_signal = $class->clean_enable_name_token($signal_name);
    my $clean_rhs = $class->clean_enable_name_token($rhs_value);
    return "${clean_signal}_${clean_rhs}_shared_en";
}

sub export_port_name ($class, $family_enable_signal) {
    my $clean_signal = $class->clean_enable_name_token($family_enable_signal);
    return "shared_dp_export_${clean_signal}";
}

sub source_value_enable_name ($class, $instance_name, $signal_name, $rhs_value) {
    my $clean_instance = $class->clean_enable_name_token($instance_name || 'child');
    my $clean_signal = $class->clean_enable_name_token($signal_name);
    my $clean_rhs = $class->clean_enable_name_token($rhs_value);
    return "${clean_instance}_${clean_signal}_${clean_rhs}_src_en";
}

sub target_enable_name ($class, $signal_name) {
    my $clean_signal = $class->clean_enable_name_token($signal_name);
    return "${clean_signal}_shared_en";
}

sub lifted_next_name ($class, $signal_name) {
    my $clean_signal = $class->clean_enable_name_token($signal_name);
    return "${clean_signal}_shared_next";
}

sub lifted_register_name ($class, $signal_name) {
    my $clean_signal = $class->clean_enable_name_token($signal_name);
    return "${clean_signal}_shared_q";
}

sub lifted_comb_name ($class, $signal_name) {
    my $clean_signal = $class->clean_enable_name_token($signal_name);
    return "${clean_signal}_shared_comb";
}

sub raw_source_name ($class, $instance_name, $signal_name) {
    my $clean_instance = $class->clean_enable_name_token($instance_name || 'child');
    my $clean_signal = $class->clean_enable_name_token($signal_name);
    return "shared_dp_raw_${clean_instance}_${clean_signal}";
}

sub same_value_conflict_name ($class, $signal_name, $rhs_value) {
    my $clean_signal = $class->clean_enable_name_token($signal_name);
    my $clean_rhs = $class->clean_enable_name_token($rhs_value);
    return "${clean_signal}_${clean_rhs}_multi_src_conflict";
}

sub multi_value_conflict_name ($class, $signal_name) {
    my $clean_signal = $class->clean_enable_name_token($signal_name);
    return "${clean_signal}_multi_value_conflict";
}

sub assertion_metadata ($class, $result_signal, $input_enable_signals) {
    my @inputs = grep {
        defined($_) && length($_)
    } @{$input_enable_signals || []};

    return {
        kind => 'onehot0',
        result_signal => $result_signal,
        input_count => scalar(@inputs),
        input_enable_signals => \@inputs,
    };
}

sub assertion_runtime_lines ($class, $target_language, $candidate) {
    return () unless ($target_language || '') =~ /^(?:systemverilog|sv)$/;
    return () unless ref($candidate) eq 'HASH';

    my @assertion_lines;
    my $signal_name = $candidate->{signal_name} || 'unknown_signal';

    for my $family (@{$candidate->{aggregate_enable_families} || []}) {
        next unless ref($family) eq 'HASH';
        my $assertion = $family->{same_value_assertion} || {};
        next unless ($assertion->{input_count} || 0) > 1;
        my $result_signal = $assertion->{result_signal} || next;
        my $rhs_value = $family->{rhs_value} // 'unknown_value';

        push @assertion_lines,
            "      assert (!$result_signal)"
                . qq{ else \$error("shared-datapath same-value conflict: $signal_name $rhs_value");};
    }

    my $multi_value_assertion = $candidate->{multi_value_assertion} || {};
    if (($multi_value_assertion->{input_count} || 0) > 1) {
        my $result_signal = $multi_value_assertion->{result_signal} || '';
        if (length $result_signal) {
            push @assertion_lines,
                "      assert (!$result_signal)"
                    . qq{ else \$error("shared-datapath multi-value conflict: $signal_name");};
        }
    }

    return () unless @assertion_lines;

    return (
        "    `ifndef SYNTHESIS",
        "    always_comb begin",
        @assertion_lines,
        "    end",
        "    `endif",
    );
}

sub or_expression ($class, $input_enable_signals) {
    my @inputs = grep {
        defined($_) && length($_)
    } @{$input_enable_signals || []};

    return "1'b0" unless @inputs;
    return $inputs[0] if @inputs == 1;
    return join(' | ', @inputs);
}

sub conflict_expression ($class, $input_enable_signals) {
    my @inputs = grep {
        defined($_) && length($_)
    } @{$input_enable_signals || []};

    return "1'b0" if @inputs < 2;

    my @pairs;
    for my $i (0 .. $#inputs - 1) {
        for my $j ($i + 1 .. $#inputs) {
            push @pairs, "($inputs[$i] & $inputs[$j])";
        }
    }

    return join(' | ', @pairs);
}

sub build_source_export_metadata ($class, $output_drive_families) {
    my %seen;
    my @exports;

    for my $drive_family (@{$output_drive_families || []}) {
        next unless ref($drive_family) eq 'HASH';
        my $signal_name = $drive_family->{signal_name} || next;

        for my $rhs_family (@{$drive_family->{rhs_enable_families} || []}) {
            next unless ref($rhs_family) eq 'HASH';
            my $family_enable_signal = $rhs_family->{family_enable_signal} || next;
            my $rhs_value = $rhs_family->{rhs_value};
            my $key = join "\x1E", $signal_name, ($rhs_value // ''), $family_enable_signal;
            next if $seen{$key}++;

            push @exports, {
                signal_name => $signal_name,
                rhs_value => $rhs_value,
                source_signal => $family_enable_signal,
                port_name => $class->export_port_name($family_enable_signal),
            };
        }
    }

    @exports = sort {
        ($a->{signal_name} // '') cmp ($b->{signal_name} // '')
            ||
        (($a->{rhs_value} // '') cmp ($b->{rhs_value} // ''))
            ||
        (($a->{port_name} // '') cmp ($b->{port_name} // ''))
    } @exports;

    return \@exports;
}

sub system_signal_names ($class, $composition_plan) {
    return _composition_system_signal_names($composition_plan);
}

sub augment_plan ($class, %args) {
    my $composition_plan = $args{composition_plan};
    my $shared_datapath_candidates = $args{shared_datapath_candidates} || [];
    my $target_language = $args{target_language} // 'systemverilog';

    return $composition_plan unless $composition_plan;

    my $nets = $composition_plan->{nets} ||= [];
    $composition_plan->{auxiliary_assignments} ||= [];
    return $composition_plan unless @{$shared_datapath_candidates || []};

    my %needed_exports;
    for my $candidate (@{$shared_datapath_candidates || []}) {
        next unless ref($candidate) eq 'HASH';
        my $signal_name = $candidate->{signal_name} || next;

        for my $family (@{$candidate->{aggregate_enable_families} || []}) {
            next unless ref($family) eq 'HASH';
            my $rhs_value = $family->{rhs_value};

            for my $contributor (@{$family->{contributors} || []}) {
                next unless ref($contributor) eq 'HASH';
                my $endpoint = $contributor->{endpoint} || '';
                my ($instance_name) = $endpoint =~ /^(\w+)\./;
                next unless defined $instance_name;
                $needed_exports{join "\x1E", $instance_name, $signal_name, ($rhs_value // '')} = 1;
            }
        }
    }

    for my $instance (@{$composition_plan->{instances} || []}) {
        next unless ($instance->kind || '') eq 'fsmc';

        for my $export (@{$instance->module_info->{shared_datapath_source_exports} || []}) {
            next unless ref($export) eq 'HASH';
            my $signal_name = $export->{signal_name} || next;
            my $rhs_value = $export->{rhs_value};
            next unless $needed_exports{join "\x1E", $instance->instance_name, $signal_name, ($rhs_value // '')};
            my $source_enable_signal = $class->source_value_enable_name(
                $instance->instance_name,
                $signal_name,
                $rhs_value,
            );

            _ensure_composition_net($nets, $source_enable_signal, 1);
            _ensure_instance_port_binding($instance, $export->{port_name}, $source_enable_signal);
        }
    }

    my @helper_assignments;
    my @assertion_sections;
    my @lifted_runtime_sections;
    my ($clock_name, $reset_name) = $class->system_signal_names($composition_plan);
    my %instances_by_name = map {
        (($_->instance_name || '') => $_)
    } @{$composition_plan->{instances} || []};

    for my $candidate (@{$shared_datapath_candidates || []}) {
        next unless ref($candidate) eq 'HASH';

        _ensure_composition_net($nets, $candidate->{aggregate_target_enable_signal}, 1);
        _ensure_composition_net($nets, $candidate->{multi_value_conflict_signal}, 1);

        my @aggregate_value_enables;
        for my $family (@{$candidate->{aggregate_enable_families} || []}) {
            next unless ref($family) eq 'HASH';
            my $aggregate_enable_signal = $family->{aggregate_enable_signal} || next;
            my @source_enable_signals = map {
                $_->{source_enable_signal}
            } grep {
                ref($_) eq 'HASH'
            } @{$family->{contributors} || []};

            _ensure_composition_net($nets, $aggregate_enable_signal, 1);
            _ensure_composition_net($nets, $family->{same_value_conflict_signal}, 1);

            push @aggregate_value_enables, $aggregate_enable_signal;
            push @helper_assignments,
                "  assign $aggregate_enable_signal = " . $class->or_expression(\@source_enable_signals) . ";",
                "  assign $family->{same_value_conflict_signal} = " . $class->conflict_expression(\@source_enable_signals) . ";";
        }

        push @helper_assignments,
            "  assign $candidate->{aggregate_target_enable_signal} = " . $class->or_expression(\@aggregate_value_enables) . ";",
            "  assign $candidate->{multi_value_conflict_signal} = " . $class->conflict_expression(\@aggregate_value_enables) . ";";

        my @candidate_assertion_lines = $class->assertion_runtime_lines($target_language, $candidate);
        push @assertion_sections, @candidate_assertion_lines if @candidate_assertion_lines;

        my %planned_reexports = map { ($_ => 1) } @{$candidate->{planned_reexport_top_output_signals} || []};
        my %preserved_top_outputs = map { ($_ => 1) } @{$candidate->{top_output_signals} || []};
        my $runtime_mode =
            (($candidate->{storage_class} || '') eq 'registered')
            && (($candidate->{peer_read_policy} || '') eq 'registered_loopback')
            && ($candidate->{loopback_allowed} || 0)
            && defined($candidate->{reset_value}) && length($candidate->{reset_value})
            && defined($clock_name) && length($clock_name)
            && defined($reset_name) && length($reset_name)
                ? (%planned_reexports
                    ? 'registered_shared_reexport'
                    : 'registered_shared_internal')
            : (($candidate->{storage_class} || '') eq 'registered')
                && !($candidate->{peer_input_count} || 0)
                && scalar(keys %preserved_top_outputs) > 1
                && defined($candidate->{reset_value}) && length($candidate->{reset_value})
                && defined($clock_name) && length($clock_name)
                && defined($reset_name) && length($reset_name)
                    ? 'registered_shared_public_fanout'
            : (($candidate->{storage_class} || '') eq 'combinational')
                && (($candidate->{peer_read_policy} || '') eq 'top_output_only')
                && %preserved_top_outputs
                    ? 'combinational_shared_reexport'
            : (($candidate->{storage_class} || '') eq 'combinational')
                && !($candidate->{peer_input_count} || 0)
                && scalar(keys %preserved_top_outputs) > 1
                    ? 'combinational_shared_public_fanout'
            : (($candidate->{storage_class} || '') eq 'combinational')
                && (($candidate->{peer_read_policy} || '') eq 'top_local_only')
                    ? 'combinational_shared_internal'
                    : '';
        my $can_lift_runtime = length($runtime_mode) ? 1 : 0;

        next unless $can_lift_runtime;

        my $signal_name = $candidate->{signal_name} || next;
        my $width = $candidate->{width} || 1;
        my $lifted_next_signal = $class->lifted_next_name($signal_name);
        my $lifted_register_signal = $class->lifted_register_name($signal_name);
        my $lifted_comb_signal = $class->lifted_comb_name($signal_name);
        my $width_decl = $width > 1 ? sprintf("[%d:0] ", $width - 1) : '';

        $candidate->{lifted_runtime_kind} = $runtime_mode;
        my @runtime_lines;
        if ($runtime_mode eq 'combinational_shared_reexport'
            || $runtime_mode eq 'combinational_shared_internal'
            || $runtime_mode eq 'combinational_shared_public_fanout')
        {
            $candidate->{lifted_runtime_signal} = $lifted_comb_signal;
            @runtime_lines = (
                "    logic ${width_decl}${lifted_comb_signal};",
                "",
                "    always_comb begin",
                "      ${lifted_comb_signal} = 1'b0;",
            );

            for my $family (@{$candidate->{aggregate_enable_families} || []}) {
                next unless ref($family) eq 'HASH';
                my $aggregate_enable_signal = $family->{aggregate_enable_signal} || next;
                my $rhs_value = $family->{rhs_value} // next;
                push @runtime_lines,
                    "      if ($aggregate_enable_signal) begin",
                    "        ${lifted_comb_signal} = $rhs_value;",
                    "      end";
            }

            push @runtime_lines, "    end";
        } else {
            $candidate->{lifted_runtime_next_signal} = $lifted_next_signal;
            $candidate->{lifted_runtime_signal} = $lifted_register_signal;
            $candidate->{lifted_runtime_reset_value} = $candidate->{reset_value};

            @runtime_lines = (
                "    logic ${width_decl}${lifted_next_signal};",
                "    logic ${width_decl}${lifted_register_signal};",
                "",
                "    always_comb begin",
                "      ${lifted_next_signal} = ${lifted_register_signal};",
            );

            for my $family (@{$candidate->{aggregate_enable_families} || []}) {
                next unless ref($family) eq 'HASH';
                my $aggregate_enable_signal = $family->{aggregate_enable_signal} || next;
                my $rhs_value = $family->{rhs_value} // next;
                push @runtime_lines,
                    "      if ($aggregate_enable_signal) begin",
                    "        ${lifted_next_signal} = $rhs_value;",
                    "      end";
            }

            push @runtime_lines,
                "    end",
                "",
                "    always_ff @(posedge $clock_name or negedge $reset_name) begin",
                "      if (!$reset_name) begin",
                "        ${lifted_register_signal} <= $candidate->{reset_value};",
                "      end else begin",
                "        ${lifted_register_signal} <= ${lifted_next_signal};",
                "      end",
                "    end";
        }

        for my $contributor (@{$candidate->{contributors} || []}) {
            next unless ref($contributor) eq 'HASH';
            my ($instance_name, $port_name) = ($contributor->{endpoint} || '') =~ /^(\w+)\.(\w+)$/;
            next unless defined($instance_name) && defined($port_name);
            my $instance = $instances_by_name{$instance_name} || next;
            my $raw_signal = $class->raw_source_name($instance_name, $signal_name);
            _ensure_composition_net($nets, $raw_signal, $width);
            _set_instance_port_binding($instance, $port_name, $raw_signal);
        }

        for my $peer_input (@{$candidate->{peer_input_endpoints} || []}) {
            next unless ref($peer_input) eq 'HASH';
            my ($instance_name, $port_name) = ($peer_input->{endpoint} || '') =~ /^(\w+)\.(\w+)$/;
            next unless defined($instance_name) && defined($port_name);
            my $instance = $instances_by_name{$instance_name} || next;
            my $lifted_signal = ($runtime_mode eq 'combinational_shared_reexport'
                || $runtime_mode eq 'combinational_shared_internal'
                || $runtime_mode eq 'combinational_shared_public_fanout')
                ? $lifted_comb_signal
                : $lifted_register_signal;
            _set_instance_port_binding($instance, $port_name, $lifted_signal);
        }

        if ($runtime_mode eq 'registered_shared_reexport') {
            for my $top_output_signal (sort keys %planned_reexports) {
                push @runtime_lines, "    assign $top_output_signal = $lifted_register_signal;";
            }
        }

        if ($runtime_mode eq 'registered_shared_public_fanout') {
            for my $top_output_signal (sort keys %preserved_top_outputs) {
                push @runtime_lines, "    assign $top_output_signal = $lifted_register_signal;";
            }
        }

        if ($runtime_mode eq 'combinational_shared_reexport'
            || $runtime_mode eq 'combinational_shared_public_fanout')
        {
            for my $top_output_signal (sort keys %preserved_top_outputs) {
                push @runtime_lines, "    assign $top_output_signal = $lifted_comb_signal;";
            }
        }

        push @lifted_runtime_sections, @runtime_lines;
    }

    my @auxiliary_lines;
    push @auxiliary_lines, @helper_assignments if @helper_assignments;
    if (@assertion_sections) {
        push @auxiliary_lines, "" if @auxiliary_lines;
        push @auxiliary_lines, @assertion_sections;
    }
    if (@lifted_runtime_sections) {
        push @auxiliary_lines, "" if @auxiliary_lines;
        push @auxiliary_lines, @lifted_runtime_sections;
    }

    $composition_plan->{auxiliary_assignments} = \@auxiliary_lines;
    $composition_plan->{shared_datapath_candidates} = $shared_datapath_candidates;
    return $composition_plan;
}

sub _ensure_composition_net ($nets, $name, $width = 1) {
    return unless defined($name) && length($name);
    return if grep { ($_->name || '') eq $name } @{$nets || []};

    push @{$nets || []}, FSM::Composition::Net->new(
        name => $name,
        width => $width,
        source => undef,
        targets => [],
    );
}

sub _ensure_instance_port_binding ($instance, $port_name, $signal_name) {
    return unless $instance && defined($port_name) && length($port_name);
    return unless defined($signal_name) && length($signal_name);

    $instance->{port_bindings} ||= [];
    ensure_signal_ref_binding($instance->{port_bindings}, $port_name, $signal_name);
}

sub _set_instance_port_binding ($instance, $port_name, $signal_name) {
    return unless $instance && defined($port_name) && length($port_name);
    return unless defined($signal_name) && length($signal_name);

    $instance->{port_bindings} ||= [];
    set_signal_ref_binding($instance->{port_bindings}, $port_name, $signal_name);
}

sub _composition_system_signal_names ($composition_plan) {
    my ($clock_name, $reset_name);
    for my $port (@{$composition_plan->ports || []}) {
        my $type = $port->type || '';
        $clock_name ||= $port->name if $type eq 'clock';
        $reset_name ||= $port->name if $type eq 'reset';
    }

    if ((!defined($clock_name) || !length($clock_name)) || (!defined($reset_name) || !length($reset_name))) {
        for my $instance (@{$composition_plan->instances || []}) {
            my $bindings = binding_signal_summaries_by_port($instance->port_bindings);

            for my $port (@{$instance->interface_ports || []}) {
                my $binding = $bindings->{$port->name} || next;
                my $bound_signal = $binding->{bound_signal} || next;
                next unless length($bound_signal);
                my $type = $port->type || '';
                $clock_name ||= $bound_signal if $type eq 'clock';
                $reset_name ||= $bound_signal if $type eq 'reset';
            }
        }
    }

    return ($clock_name, $reset_name);
}

1;

__END__

=head1 METHODS

=head2 clean_enable_name_token

Normalizes a value into the bounded shared-datapath helper-signal token form
used by runtime-generated signal names.

=head2 value_enable_name

Returns the aggregate per-value enable signal name for one shared datapath
signal and one RHS value family.

=head2 export_port_name

Returns the generated child export-port name for one shared-datapath family
enable signal.

=head2 source_value_enable_name

Returns the per-child source-enable helper signal name for one contributing
instance and one RHS value family.

=head2 target_enable_name

Returns the aggregate whole-target enable signal name for a shared datapath
signal family.

=head2 lifted_next_name

Returns the lifted next-value signal name for a registered shared runtime.

=head2 lifted_register_name

Returns the lifted shared register signal name for a registered shared
runtime.

=head2 lifted_comb_name

Returns the lifted combinational carrier signal name for a combinational
shared runtime.

=head2 raw_source_name

Returns the private raw contributor signal name used when contributor outputs
are rebound away from public child ports during runtime lifting.

=head2 same_value_conflict_name

Returns the per-value same-source conflict signal name for one shared signal
and RHS value family.

=head2 multi_value_conflict_name

Returns the whole-target multi-value conflict signal name for one shared
signal family.

=head2 assertion_metadata

Builds the bounded onehot0-style assertion metadata used by shared-datapath
candidate families.

=head2 assertion_runtime_lines

Renders the bounded non-synthesis assertion block for one shared-datapath
candidate when the target language supports it.

=head2 or_expression

Builds the bounded disjunction expression over one list of helper enable
signals.

=head2 conflict_expression

Builds the bounded pairwise-conflict expression over one list of helper enable
signals.

=head2 build_source_export_metadata

Projects generated-child shared-datapath source-export metadata from one list
of lowered output-drive families.

=head2 system_signal_names

Recovers the active clock and reset signal names for a composition plan from
top ports first and child system bindings as a fallback.

=head2 augment_plan

Mutates a composition plan with the bounded shared-datapath runtime support
surface once candidate metadata already exists, including helper nets,
binding rewrites, assertion sections, and lifted runtime sections.

=head2 _ensure_composition_net

Adds one helper net to a plan only when that helper net is not already
present.

=head2 _ensure_instance_port_binding

Ensures one instance binding exists for a port without replacing an already
present structured binding.

=head2 _set_instance_port_binding

Forces one instance binding to a new signal-ref target, replacing any older
binding for that port.

=cut
