package FSM::Support::DocumentationSection;

use strict;
use warnings;

use Exporter 'import';

use FSM::Support::DocumentationContract qw(build_documentation_contract);

our @EXPORT_OK = qw(
    build_documentation_section
);

sub build_documentation_section {
    return {
        human_contract => [
            'docs/book/src/SUMMARY.md',
            'docs/book/src/90-reference-map.md',
            'docs/book/src/10-errors-strict-mode-and-troubleshooting.md',
            'docs/USER_GUIDE.md',
            'docs/REGRESSION_CORPUS.md',
        ],
        downstream_alignment => [
            'docs/SPECFORGE_FEEDBACK_RESPONSE.md',
        ],
        section_contract => build_documentation_contract(),
    };
}

1;
