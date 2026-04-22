package FSM::Support::EmbeddingSection;

use strict;
use warnings;

use Exporter 'import';

use FSM::Support::CompositionReportContract qw(build_composition_report_contract);
use FSM::Support::EmbeddingContract qw(build_embedding_contract);
use FSM::Support::ExtensionContract qw(build_extension_contract);
use FSM::Support::HDLGeneratorResultContract qw(build_hdl_generator_result_contract);

our @EXPORT_OK = qw(
    build_embedding_section
);

sub build_embedding_section {
    return {
        composition_report => build_composition_report_contract(),
        hdl_generator_result => build_hdl_generator_result_contract(),
        typed_extensions => build_extension_contract(),
        section_contract => build_embedding_contract(),
    };
}

1;
