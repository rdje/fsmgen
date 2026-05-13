package FSM::Support::DocumentationHints;

use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(
    package_boundary_hint
    package_boundary_sentence
    strict_mode_boundary_hint
    strict_mode_boundary_sentence
    supported_boundary_hint
    supported_boundary_sentence
);

sub supported_boundary_sentence {
    return 'See docs/book/src/90-reference-map.md for the current supported boundary and owning chapter map.';
}

sub strict_mode_boundary_sentence {
    return 'See docs/book/src/10-errors-strict-mode-and-troubleshooting.md for the current strict-mode boundary.';
}

sub package_boundary_sentence {
    return 'See docs/book/src/04-symbols-types-and-imports.md and docs/book/src/07-packages-and-sharing.md for the current package boundary.';
}

sub supported_boundary_hint {
    return supported_boundary_sentence() . "\n";
}

sub strict_mode_boundary_hint {
    return strict_mode_boundary_sentence() . "\n";
}

sub package_boundary_hint {
    return package_boundary_sentence() . "\n";
}

1;
