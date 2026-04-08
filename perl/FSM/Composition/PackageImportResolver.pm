package FSM::Composition::PackageImportResolver;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Composition::PortWidthResolver;
use FSM::Package::ImportResolver;

sub resolve_imports ($class, %args) {
    my $composition_spec = $args{composition_spec}
        or confess "PackageImportResolver requires a composition_spec";
    my $fsm_file = $args{fsm_file}
        or confess "PackageImportResolver requires an fsm_file";
    my $source_path_resolver = $args{source_path_resolver}
        or confess "PackageImportResolver requires a source_path_resolver";

    my $top = $composition_spec->top
        or confess "PackageImportResolver requires a composition top";
    my $package_imports = $top->package_imports || [];
    my $top_symbols = $top->top_symbols
        or confess "PackageImportResolver requires top symbols";

    my $resolved_packages = FSM::Package::ImportResolver->resolve_imports(
        package_imports => $package_imports,
        embedded_package_sources => ($composition_spec->embedded_package_sources || {}),
        fsm_file => $fsm_file,
        source_path_resolver => $source_path_resolver,
        owner_label => "Composition source '?top:" . $top->name . "' in '$fsm_file'",
        debug_level => ($args{debug_level} // 0),
        docs_hint => " See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n",
    );

    for my $package_name (@$package_imports) {
        my $package_spec = $resolved_packages->{$package_name} or next;
        $top_symbols->import_package($package_name, $package_spec->symbols);
    }

    $top_symbols->finalize_imported_type_aliases
        if $top_symbols->can('finalize_imported_type_aliases');

    FSM::Composition::PortWidthResolver->resolve_declared_port_widths(
        top => $top,
        docs_hint => " See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md",
    );

    return $resolved_packages;
}

1;
