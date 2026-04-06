package FSM::Composition::PackageImportResolver;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

use File::Basename qw(dirname);
use File::Spec;
use FSM::Package::Parser;
use FSM::Pipeline::SourceFrontend;

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

    my $parser = FSM::Package::Parser->new(
        debug => ($args{debug_level} // 0) > 0,
    );

    my %resolved_packages;
    for my $package_name (@$package_imports) {
        next if exists $resolved_packages{$package_name};

        my $package_spec = $class->_resolve_one_package_import(
            parser => $parser,
            composition_spec => $composition_spec,
            fsm_file => $fsm_file,
            source_path_resolver => $source_path_resolver,
            package_name => $package_name,
            top_name => $top->name,
        );

        $top_symbols->import_package($package_name, $package_spec->symbols);
        $resolved_packages{$package_name} = $package_spec;
    }

    return \%resolved_packages;
}

sub _resolve_one_package_import ($class, %args) {
    my $parser = $args{parser}
        or confess "PackageImportResolver requires a parser";
    my $composition_spec = $args{composition_spec}
        or confess "PackageImportResolver requires a composition_spec";
    my $package_name = $args{package_name}
        or confess "PackageImportResolver requires a package_name";

    if (my $embedded_ast = $composition_spec->embedded_package_sources->{$package_name}) {
        return $parser->parse_package_root($embedded_ast);
    }

    my ($package_path, $search_dirs, $searched_paths) = $class->resolve_external_package_source_path(%args);
    my $raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
        fsm_file => $package_path,
        debug_level => 0,
    );
    my $source_info = FSM::Pipeline::SourceFrontend->classify_source_ast($raw_ast);
    my $header = $source_info->{header} // 'unknown';

    confess
        "Composition source '?top:$args{top_name}' in '$args{fsm_file}' imports package '$package_name' from '$package_path', ".
        "but package-source root support is blocked because that file does not use a '?pkg:package_name' root. ".
        "Observed root: '$header'. ".
        "Search roots: ".join(', ', @$search_dirs).". ".
        "Searched locations: ".join(', ', @$searched_paths).".\n"
        unless defined($header) && $header =~ /^\?pkg:/;

    my $package_spec = $parser->parse_source($raw_ast);
    confess
        "Composition source '?top:$args{top_name}' in '$args{fsm_file}' imports package '$package_name' from '$package_path', ".
        "but package-name matching is blocked because that file declares '?pkg:".$package_spec->name."' instead of '?pkg:$package_name'. ".
        "Package imports currently require the imported package name and the package root name to match exactly.\n"
        unless $package_spec->name eq $package_name;

    return $package_spec;
}

sub resolve_external_package_source_path ($class, %args) {
    my $source_path_resolver = $args{source_path_resolver}
        or confess "PackageImportResolver requires a source_path_resolver";
    my $package_name = $args{package_name}
        or confess "PackageImportResolver requires a package_name";
    my $fsm_file = $args{fsm_file}
        or confess "PackageImportResolver requires an fsm_file";
    my $top_name = $args{top_name}
        or confess "PackageImportResolver requires a top_name";

    my @preferred_dirs;
    push @preferred_dirs, dirname($fsm_file) if defined($fsm_file) && $fsm_file =~ m{/};

    my @search_dirs = @{
        $source_path_resolver->normalized_search_paths(
            preferred_dirs => \@preferred_dirs,
            include_cwd => 1,
        )
    };

    my $target_filename = "$package_name.fsm";
    my @searched_paths = map { File::Spec->catfile($_, $target_filename) } @search_dirs;

    for my $candidate (@searched_paths) {
        return ($candidate, \@search_dirs, \@searched_paths) if -f $candidate;
    }

    confess
        "Composition source '?top:$top_name' in '$fsm_file' imports package '$package_name', ".
        "but package-source resolution is blocked because no active '?pkg:$package_name' source was found either embedded in the same file or in an external '.fsm' file. ".
        "Search roots: ".join(', ', @search_dirs).". ".
        "Searched locations: ".join(', ', @searched_paths).". ".
        "The first semantic package lane currently resolves package sources beside the composition source, through repeated '--path DIR' roots, through 'FSMLIB', or in the current directory.\n";
}

1;
