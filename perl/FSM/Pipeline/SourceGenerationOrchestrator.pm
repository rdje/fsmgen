package FSM::Pipeline::SourceGenerationOrchestrator;

=head1 NAME

FSM::Pipeline::SourceGenerationOrchestrator - Orchestrator for top-level source-file generation

=head1 DESCRIPTION

Owns the bounded top-level file/source orchestration that was still inline in
C<FSM::Pipeline::HDLGenerator>. This package parses one source file, classifies
its root kind, dispatches into the direct-root or composition generation
orchestrator, runs the extension hooks around that generation, and returns the
final bounded result surface consumed by the outer pipeline facade.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Composition::GenerationOrchestrator;
use FSM::Debug;
use FSM::Extension::Context;
use FSM::Pipeline::DirectGenerationOrchestrator;
use FSM::Pipeline::SourceFrontend;

sub generate_from_file ($class, %args) {
    my $pipeline = $args{pipeline}
        or confess "SourceGenerationOrchestrator requires a pipeline";
    my $fsm_file = $args{fsm_file}
        or confess "SourceGenerationOrchestrator requires an fsm_file";

    fsm_trace_enter("Generate HDL from file '$fsm_file'", 1);
    fsm_debug("Starting HDL generation pipeline for: $fsm_file", 1);

    my $raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
        fsm_file => $fsm_file,
        debug_level => ($pipeline->{debug_level} // 0),
    );
    my $source_info = FSM::Pipeline::SourceFrontend->classify_source_ast($raw_ast);

    if (($source_info->{kind} // 'unknown') eq 'unknown'
        && defined($source_info->{header})
        && $source_info->{header} =~ /^\?[A-Za-z_][\w-]*:/) {
        my $header = $source_info->{header};
        confess
            "Unsupported top-level source '$header'. "
          . "The active pipeline supports '?fsm:name', '?dt:name', '?mod:name', '?module:name', '+fsm', and '?top:name'. "
          . "Other tagged source kinds such as '?define:' are out of active support. "
          . "See docs/USER_GUIDE.md for the current supported boundary.\n";
    }

    if ($source_info->{kind} && $source_info->{kind} eq 'composition') {
        $source_info->{composition_spec} = FSM::Pipeline::SourceFrontend->parse_composition_source(
            raw_ast => $raw_ast,
            debug_level => ($pipeline->{debug_level} // 0),
        );
    }

    my $parse_context = FSM::Extension::Context->new(
        stage => 'after_parse_source',
        pipeline => $pipeline,
        source_path => $fsm_file,
        target_language => $pipeline->{target_language},
        source_info => $source_info,
        raw_ast => $raw_ast,
    );
    $pipeline->{extension_registry}->after_parse_source($parse_context);

    my $result;
    if ($source_info->{kind} && $source_info->{kind} eq 'composition') {
        $result = FSM::Composition::GenerationOrchestrator->generate_from_source(
            pipeline => $pipeline,
            source_info => $source_info,
            raw_ast => $raw_ast,
            fsm_file => $fsm_file,
        );
    }
    else {
        $result = FSM::Pipeline::DirectGenerationOrchestrator->generate_from_source(
            pipeline => $pipeline,
            raw_ast => $raw_ast,
            source_info => $source_info,
        );
    }

    my $result_context = FSM::Extension::Context->new(
        stage => 'after_generate_result',
        pipeline => $pipeline,
        source_path => $fsm_file,
        target_language => $pipeline->{target_language},
        source_info => $source_info,
        result => $result,
    );
    $pipeline->{extension_registry}->after_generate_result($result_context);

    fsm_debug("HDL generation pipeline completed successfully", 1);
    fsm_trace_exit("HDL generation complete for '$fsm_file'", 1);
    return $result;
}

1;

__END__

=head1 METHODS

=head2 generate_from_file

Builds the bounded top-level generation result surface from one source file by
parsing the file, classifying the source kind, dispatching into the direct-root
or composition generation orchestrator, and running the surrounding extension
hooks.

=cut
