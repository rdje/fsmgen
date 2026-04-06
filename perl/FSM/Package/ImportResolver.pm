package FSM::Package::ImportResolver;

=head1 NAME

FSM::Package::ImportResolver - Shared semantic package import resolver

=head1 DESCRIPTION

Owns the bounded semantic package import lane shared by composition tops and
direct generated roots. This package resolves named package imports from
embedded C<?pkg:name> roots or external searchable C<.fsm> files and returns
typed L<FSM::Package::Spec> records for later symbol injection.

=cut

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
    my $package_imports = $args{package_imports}
        or confess "Package::ImportResolver requires package_imports";
    my $embedded_package_sources = $args{embedded_package_sources} || {};
    my $source_path_resolver = $args{source_path_resolver}
        or confess "Package::ImportResolver requires a source_path_resolver";

    my $parser = FSM::Package::Parser->new(
        debug => ($args{debug_level} // 0) > 0,
    );

    my %resolved_packages;
    for my $package_name (@$package_imports) {
        next if exists $resolved_packages{$package_name};

        $resolved_packages{$package_name} = $class->_resolve_one_package_import(
            parser => $parser,
            embedded_package_sources => $embedded_package_sources,
            source_path_resolver => $source_path_resolver,
            package_name => $package_name,
            fsm_file => $args{fsm_file},
            owner_label => ($args{owner_label} // 'Source'),
            docs_hint => ($args{docs_hint} // ''),
        );
    }

    return \%resolved_packages;
}

sub _resolve_one_package_import ($class, %args) {
    my $parser = $args{parser}
        or confess "Package::ImportResolver requires a parser";
    my $embedded_package_sources = $args{embedded_package_sources} || {};
    my $package_name = $args{package_name}
        or confess "Package::ImportResolver requires a package_name";

    if (my $embedded_ast = $embedded_package_sources->{$package_name}) {
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
        "$args{owner_label} imports package '$package_name' from '$package_path', "
      . "but package-source root support is blocked because that file does not use a '?pkg:package_name' root. "
      . "Observed root: '$header'. "
      . "Search roots: ".join(', ', @$search_dirs).". "
      . "Searched locations: ".join(', ', @$searched_paths)."."
      . $class->_formatted_docs_hint($args{docs_hint})
        unless defined($header) && $header =~ /^\?pkg:/;

    my $package_spec = $parser->parse_source($raw_ast);
    confess
        "$args{owner_label} imports package '$package_name' from '$package_path', "
      . "but package-name matching is blocked because that file declares '?pkg:".$package_spec->name."' instead of '?pkg:$package_name'. "
      . "Package imports currently require the imported package name and the package root name to match exactly."
      . $class->_formatted_docs_hint($args{docs_hint})
        unless $package_spec->name eq $package_name;

    return $package_spec;
}

sub resolve_external_package_source_path ($class, %args) {
    my $source_path_resolver = $args{source_path_resolver}
        or confess "Package::ImportResolver requires a source_path_resolver";
    my $package_name = $args{package_name}
        or confess "Package::ImportResolver requires a package_name";

    my @preferred_dirs;
    if (defined($args{fsm_file}) && length($args{fsm_file}) && $args{fsm_file} =~ m{/}) {
        push @preferred_dirs, dirname($args{fsm_file});
    }

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
        "$args{owner_label} imports package '$package_name', "
      . "but package-source resolution is blocked because no active '?pkg:$package_name' source was found either embedded in the same file or in an external '.fsm' file. "
      . "Search roots: ".join(', ', @search_dirs).". "
      . "Searched locations: ".join(', ', @searched_paths).". "
      . "The semantic package lane currently resolves package sources beside the current source, through repeated '--path DIR' roots, through 'FSMLIB', or in the current directory."
      . $class->_formatted_docs_hint($args{docs_hint});
}

sub _formatted_docs_hint ($class, $docs_hint) {
    return "\n" unless defined($docs_hint) && length($docs_hint);
    return $docs_hint =~ /\n\z/ ? $docs_hint : "$docs_hint\n";
}

1;

__END__

=head1 METHODS

=head2 resolve_imports

Resolves one bounded package-import list into typed L<FSM::Package::Spec>
records using embedded package roots first and then the normal external source
search roots.

=head2 resolve_external_package_source_path

Searches the active package import roots for one external package source file
named C<package_name.fsm>.

=cut
