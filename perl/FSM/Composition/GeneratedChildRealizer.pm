package FSM::Composition::GeneratedChildRealizer;

=head1 NAME

FSM::Composition::GeneratedChildRealizer - Realizer for generated composition children

=head1 DESCRIPTION

Owns the active C<?fsmc> and C<?dtc> realization family for composition. This
package resolves embedded or external child sources, validates the resolved
root kind, compiles the child through the current pipeline callbacks, and
returns normalized L<FSM::Composition::RealizedInstance> records for the
composition planners.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

use File::Basename qw(dirname);
use File::Spec;
use FSM::Backend::GeneratedModuleEmitter;
use FSM::Composition::InterfacePortBuilder;
use FSM::Composition::RealizedInstance;
use FSM::Composition::SharedDatapathSupport;
use FSM::IR::IntentHIRBuilder;
use FSM::IR::StructuralRTLIRBuilder;
use FSM::Pipeline::GeneratedModuleInfoBuilder;
use FSM::Pipeline::SourceFrontend;

sub realize_fsmc_child_instance ($class, %args) {
    my $pipeline = $args{pipeline}
        or confess "GeneratedChildRealizer requires a pipeline";
    my $instance = $args{instance}
        or confess "GeneratedChildRealizer requires an instance";
    my $composition_spec = $args{composition_spec}
        or confess "GeneratedChildRealizer requires a composition_spec";
    my $fsm_file = $args{fsm_file}
        or confess "GeneratedChildRealizer requires an fsm_file";
    my $header = $args{header}
        or confess "GeneratedChildRealizer requires a header";

    my $source_name = $instance->source_name;
    my $child_ast = $composition_spec->embedded_fsm_sources->{$source_name};
    my $child_source_path;
    my $child_source_info;

    unless ($child_ast) {
        ($child_ast, $child_source_path, $child_source_info) =
            $class->load_external_fsmc_child_source(
                pipeline => $pipeline,
                source_name => $source_name,
                fsm_file => $fsm_file,
                header => $header,
                source_path_resolver => $args{source_path_resolver},
            );
    }

    return $class->_realize_generated_child(
        pipeline => $pipeline,
        instance => $instance,
        fsm_file => $fsm_file,
        source_name => $source_name,
        child_ast => $child_ast,
        child_kind => 'fsmc',
        declared_child_kind => '?fsmc',
        child_source_path => $child_source_path,
        add_shared_datapath_source_exports => 1,
    );
}

sub realize_dtc_child_instance ($class, %args) {
    my $pipeline = $args{pipeline}
        or confess "GeneratedChildRealizer requires a pipeline";
    my $instance = $args{instance}
        or confess "GeneratedChildRealizer requires an instance";
    my $composition_spec = $args{composition_spec}
        or confess "GeneratedChildRealizer requires a composition_spec";
    my $fsm_file = $args{fsm_file}
        or confess "GeneratedChildRealizer requires an fsm_file";
    my $header = $args{header}
        or confess "GeneratedChildRealizer requires a header";

    my $source_name = $instance->source_name;
    my $child_ast = $composition_spec->embedded_dt_sources->{$source_name};
    my $child_source_path;

    unless ($child_ast) {
        ($child_ast, $child_source_path) = $class->load_external_dtc_child_source(
            pipeline => $pipeline,
            source_name => $source_name,
            fsm_file => $fsm_file,
            header => $header,
            source_path_resolver => $args{source_path_resolver},
        );
    }

    return $class->_realize_generated_child(
        pipeline => $pipeline,
        instance => $instance,
        fsm_file => $fsm_file,
        source_name => $source_name,
        child_ast => $child_ast,
        child_kind => 'dtc',
        declared_child_kind => '?dtc',
        child_source_path => $child_source_path,
        add_shared_datapath_source_exports => 0,
    );
}

sub load_external_fsmc_child_source ($class, %args) {
    return $class->_load_external_generated_child_source(
        %args,
        child_kind => '?fsmc',
        expected_root_kind => 'fsm',
    );
}

sub load_external_dtc_child_source ($class, %args) {
    return $class->_load_external_generated_child_source(
        %args,
        child_kind => '?dtc',
        expected_root_kind => 'dt',
    );
}

sub resolve_external_generated_child_source_path ($class, %args) {
    my $pipeline = $args{pipeline};
    my $source_name = $args{source_name}
        or confess "GeneratedChildRealizer requires a source_name";
    my $fsm_file = $args{fsm_file}
        or confess "GeneratedChildRealizer requires an fsm_file";
    my $header = $args{header}
        or confess "GeneratedChildRealizer requires a header";
    my $child_kind = $args{child_kind}
        or confess "GeneratedChildRealizer requires a child_kind";
    my $source_path_resolver = $args{source_path_resolver}
        || ($pipeline ? $pipeline->{source_path_resolver} : undef)
        or confess "GeneratedChildRealizer requires a source_path_resolver";

    my @preferred_dirs;
    push @preferred_dirs, dirname($fsm_file) if defined($fsm_file) && $fsm_file =~ m{/};

    my @search_dirs = @{
        $source_path_resolver->normalized_search_paths(
            preferred_dirs => \@preferred_dirs,
            include_cwd => 1,
        )
    };

    my @candidates;
    if (File::Spec->file_name_is_absolute($source_name)) {
        push @candidates, $source_name;
        push @candidates, "$source_name.fsm" unless $source_name =~ /\.fsm$/i;
    } elsif ($source_name =~ m{/}) {
        for my $dir (@search_dirs) {
            push @candidates, File::Spec->catfile($dir, $source_name);
            push @candidates, File::Spec->catfile($dir, "$source_name.fsm")
                unless $source_name =~ /\.fsm$/i;
        }
    } else {
        my $target_filename = $source_name =~ /\.fsm$/i ? $source_name : "$source_name.fsm";
        push @candidates, map { File::Spec->catfile($_, $target_filename) } @search_dirs;
    }

    my %seen;
    my @searched_paths = grep { !$seen{$_}++ } @candidates;
    for my $candidate (@searched_paths) {
        return ($candidate, \@search_dirs, \@searched_paths) if -f $candidate;
    }

    my $family_label = $child_kind eq '?dtc'
        ? "standalone-DT child source"
        : "child FSM source";
    confess
        "Composition source '$header' in '$fsm_file' declares '$child_kind' child '$source_name', ".
        "but child-source resolution is blocked because no active $family_label was found either embedded in the same file or in an external '.fsm' file. ".
        "Search roots: ".join(', ', @search_dirs).". ".
        "Searched locations: ".join(', ', @searched_paths).". ".
        "The active composition contract currently allows generated child instances to realize embedded sources or external '.fsm' module files found beside the composition source, through repeated '--path DIR' roots, through 'FSMLIB', or in the current directory. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
}

sub augment_generated_child_hdl_with_shared_datapath_exports ($class, $hdl_code, $exports) {
    return $hdl_code unless defined($hdl_code) && length($hdl_code);
    return $hdl_code unless @{$exports || []};

    my @port_lines = map {
        "  output  wire " . $_->{port_name}
    } @{$exports || []};

    my $patched = $hdl_code;
    my $port_block = join(",\n", @port_lines);
    my $header_replaced = ($patched =~ s/\n\);\n\n/\n,\n$port_block\n\);\n\n/s);
    confess("Failed to inject shared-datapath export ports into generated child HDL\n")
        unless $header_replaced;

    my $assign_block = "\n  // Shared-datapath source-enable exports\n"
        . join('', map {
            "  assign " . $_->{port_name} . " = " . $_->{source_signal} . ";\n"
        } @{$exports || []});

    my $endmodule_replaced = ($patched =~ s/\nendmodule\s*\z/$assign_block . "endmodule\n"/se);
    confess("Failed to inject shared-datapath export assignments into generated child HDL\n")
        unless $endmodule_replaced;

    return $patched;
}

sub _realize_generated_child ($class, %args) {
    my $pipeline = $args{pipeline}
        or confess "GeneratedChildRealizer requires a pipeline";
    my $instance = $args{instance}
        or confess "GeneratedChildRealizer requires an instance";
    my $fsm_file = $args{fsm_file}
        or confess "GeneratedChildRealizer requires an fsm_file";
    my $source_name = $args{source_name}
        or confess "GeneratedChildRealizer requires a source_name";
    my $child_ast = $args{child_ast}
        or confess "GeneratedChildRealizer requires a child_ast";
    my $child_kind = $args{child_kind}
        or confess "GeneratedChildRealizer requires a child_kind";
    my $declared_child_kind = $args{declared_child_kind}
        or confess "GeneratedChildRealizer requires a declared_child_kind";

    return $class->_with_generated_child_source_context(
        fsm_file => $fsm_file,
        source_name => $source_name,
        declared_child_kind => $declared_child_kind,
        child_source_path => $args{child_source_path},
        code => sub {
            FSM::Pipeline::SourceFrontend->enforce_strict_generated_child_source_boundary(
                raw_ast => $child_ast,
                strict_mode => ($pipeline->{strict_mode} // 0),
                declared_child_kind => $declared_child_kind,
                source_label => $source_name,
            );

            my $child_module = FSM::Pipeline::SourceFrontend->create_fsm_module(
                raw_ast => $child_ast,
                debug_level => ($pipeline->{debug_level} // 0),
                strict_mode => ($pipeline->{strict_mode} // 0),
                source_label => $source_name,
            );
            my $child_intent_hir = FSM::IR::IntentHIRBuilder->build_from_fsm_module(
                fsm_module => $child_module,
            );
            my $child_module_info = FSM::Pipeline::GeneratedModuleInfoBuilder->build_from_fsm_module(
                fsm_module => $child_module,
                intent_hir => $child_intent_hir,
            );
            my $backend_result = FSM::Backend::GeneratedModuleEmitter->emit_from_fsm_module(
                fsm_module => $child_module,
                target_language => ($pipeline->{target_language} // 'systemverilog'),
                debug_level => ($pipeline->{debug_level} // 0),
            );
            $pipeline->{hdl_generator} = $backend_result->{hdl_generator};
            FSM::Pipeline::GeneratedModuleInfoBuilder->enrich_with_generated_analysis(
                module_info => $child_module_info,
                fsm_module => $child_module,
                target_language => ($pipeline->{target_language} // 'systemverilog'),
                hdl_generator => $pipeline->{hdl_generator},
            );
            my $child_structural_rtl_ir = FSM::IR::StructuralRTLIRBuilder->build_from_generated_module_info(
                module_info => $child_module_info,
                fsm_module => $child_module,
                target_language => ($pipeline->{target_language} // 'systemverilog'),
            );
            $child_module_info->{structural_rtl_ir} = $child_structural_rtl_ir->as_hashref;
            my $child_hdl_code = FSM::Backend::GeneratedModuleEmitter->augment_with_standalone_dt_assertions(
                hdl_code => $backend_result->{hdl_code},
                module_info => $child_module_info,
                target_language => ($pipeline->{target_language} // 'systemverilog'),
            );

            if ($args{add_shared_datapath_source_exports}) {
                my $shared_datapath_source_exports = FSM::Composition::SharedDatapathSupport->build_source_export_metadata(
                    FSM::Pipeline::GeneratedModuleInfoBuilder->output_drive_families_from_module_info($child_module_info),
                );
                $child_module_info->{shared_datapath_source_export_count} = scalar(@$shared_datapath_source_exports);
                $child_module_info->{shared_datapath_source_exports} = $shared_datapath_source_exports;
                $child_hdl_code = $class->augment_generated_child_hdl_with_shared_datapath_exports(
                    $child_hdl_code,
                    $shared_datapath_source_exports,
                );
            }

            my $child_interface_ports = FSM::Composition::InterfacePortBuilder->build_realized_child_interface_ports($child_module_info);

            return FSM::Composition::RealizedInstance->new(
                kind => $child_kind,
                instance_name => ($instance->name // $child_module->name),
                module_name => $child_module->name,
                source_name => $source_name,
                interface_ports => $child_interface_ports,
                module_info => $child_module_info,
                hdl_code => $child_hdl_code,
            );
        },
    );
}

sub _load_external_generated_child_source ($class, %args) {
    my $pipeline = $args{pipeline}
        or confess "GeneratedChildRealizer requires a pipeline";
    my $source_name = $args{source_name}
        or confess "GeneratedChildRealizer requires a source_name";
    my $fsm_file = $args{fsm_file}
        or confess "GeneratedChildRealizer requires an fsm_file";
    my $header = $args{header}
        or confess "GeneratedChildRealizer requires a header";
    my $child_kind = $args{child_kind}
        or confess "GeneratedChildRealizer requires a child_kind";
    my $expected_root_kind = $args{expected_root_kind}
        or confess "GeneratedChildRealizer requires an expected_root_kind";

    my ($child_source_path) = $class->_with_generated_child_source_context(
        fsm_file => $fsm_file,
        source_name => $source_name,
        declared_child_kind => $child_kind,
        expected_child_source_file => $class->_expected_child_source_file($source_name),
        code => sub {
            return $class->resolve_external_generated_child_source_path(%args);
        },
    );
    my ($child_ast, $child_source_info) = $class->_with_generated_child_source_context(
        fsm_file => $fsm_file,
        source_name => $source_name,
        declared_child_kind => $child_kind,
        child_source_path => $child_source_path,
        code => sub {
            my $child_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
                fsm_file => $child_source_path,
                debug_level => ($pipeline->{debug_level} // 0),
            );
            my $child_source_info = FSM::Pipeline::SourceFrontend->classify_source_ast($child_ast);
            return ($child_ast, $child_source_info);
        },
    );
    my $child_root_kind = $child_source_info->{kind} // 'unknown';
    return ($child_ast, $child_source_path, $child_source_info) if $child_root_kind eq $expected_root_kind;

    my $child_header = $child_source_info->{header} // 'unknown root';
    my $kind_note = $class->_wrong_kind_note($child_kind, $child_root_kind);

    return $class->_with_generated_child_source_context(
        fsm_file => $fsm_file,
        source_name => $source_name,
        declared_child_kind => $child_kind,
        child_source_path => $child_source_path,
        code => sub {
            confess
                "Composition source '$header' in '$fsm_file' resolves '$child_kind' child '$source_name' to '$child_source_path', ".
                "but child-source realization is blocked because that resolved file is not an active "
                    . ($expected_root_kind eq 'dt' ? 'standalone-DT child source' : 'FSM child source')
                    . " (detected root '$child_header'). ".
                $kind_note." ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
        },
    );
}

sub _with_generated_child_source_context ($class, %args) {
    my $fsm_file = $args{fsm_file}
        or confess "GeneratedChildRealizer requires an fsm_file";
    my $source_name = $args{source_name}
        or confess "GeneratedChildRealizer requires a source_name";
    my $declared_child_kind = $args{declared_child_kind}
        or confess "GeneratedChildRealizer requires a declared_child_kind";
    my $code_ref = $args{code}
        or confess "GeneratedChildRealizer requires a code callback";

    my @result = eval { $code_ref->() };
    if (!$@) {
        return wantarray ? @result : $result[0];
    }

    my $error = $@;
    die $error if ref($error);
    die $error if $error =~ /(?:^|\n)(?:Source file|Expected child source file):\s+'/s;

    my $message = '';
    if (defined($args{child_source_path}) && length($args{child_source_path})) {
        $message .= "Source file: '$args{child_source_path}'\n";
        if ($args{child_source_path} ne $fsm_file) {
            $message .= "Parent composition source: '$fsm_file'\n";
        }
    }
    else {
        $message .= "Source file: '$fsm_file'\n";
        if (defined($args{expected_child_source_file}) && length($args{expected_child_source_file})) {
            $message .= "Expected child source file: '$args{expected_child_source_file}'\n";
        }
    }
    $message .= "Generated child source: '$declared_child_kind' '$source_name'\n";

    die $message.$error;
}

sub _expected_child_source_file ($class, $source_name) {
    return $source_name if $source_name =~ /\.fsm$/i;
    return "$source_name.fsm";
}

sub _wrong_kind_note ($class, $child_kind, $child_root_kind) {
    if ($child_kind eq '?fsmc') {
        return $child_root_kind eq 'dt'
            ? "Standalone '?dt:name' roots are shipped as composition children, but '?fsmc' specifically requires an FSM child source. Use '?dtc' for standalone-DT children instead."
            : "The active composition child-FSM contract expects embedded or external child sources rooted at '?fsm:name' or legacy '+fsm' only.";
    }

    return $child_root_kind eq 'fsm'
        ? "FSM child roots are shipped as composition children, but '?dtc' specifically requires a standalone-DT child source. Use '?fsmc' for FSM children instead."
        : "The active standalone-DT composition contract currently expects '?dt:name', '?mod:name', or '?module:name' child roots for '?dtc'.";
}

1;

__END__

=head1 METHODS

=head2 realize_fsmc_child_instance

Realizes one C<?fsmc> composition child from either an embedded or external
FSM child source and returns a normalized
L<FSM::Composition::RealizedInstance>.

=head2 realize_dtc_child_instance

Realizes one C<?dtc> composition child from either an embedded or external
standalone-DT child source and returns a normalized
L<FSM::Composition::RealizedInstance>.

=head2 load_external_fsmc_child_source

Loads and validates an external C<?fsmc> child source, ensuring the resolved
root is an active FSM child source.

=head2 load_external_dtc_child_source

Loads and validates an external C<?dtc> child source, ensuring the resolved
root is an active standalone-DT child source.

=head2 resolve_external_generated_child_source_path

Resolves one generated-child source name onto the active external C<.fsm>
search contract and returns the chosen path plus the search diagnostics.

=head2 augment_generated_child_hdl_with_shared_datapath_exports

Injects the current shared-datapath source-export ports and assignments into
one generated child HDL module payload.

=head2 _realize_generated_child

Internal helper that runs the shared generated-child compilation pipeline and
builds the realized-child runtime carrier.

=head2 _load_external_generated_child_source

Internal helper that loads one external generated-child source and checks its
resolved root kind against the expected child family.

=head2 _wrong_kind_note

Returns the family-specific guidance text used when a resolved generated-child
source has the wrong top-level root kind.

=cut
