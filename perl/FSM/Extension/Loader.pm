package FSM::Extension::Loader;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(blessed);
use feature qw(signatures);
no warnings 'experimental::signatures';

sub new ($class, %args) {
    return bless {}, $class;
}

sub module_names_from_config_files ($self, $config_paths) {
    confess "FSM::Extension::Loader expects an array reference of config file paths"
        unless ref($config_paths) eq 'ARRAY';

    my @module_names;
    for my $config_path (@$config_paths) {
        push @module_names, @{$self->module_names_from_config_file($config_path)};
    }

    return \@module_names;
}

sub module_names_from_config_file ($self, $config_path) {
    confess "FSM::Extension::Loader requires non-empty extension config paths"
        unless defined($config_path) && $config_path ne '';
    confess "Extension config file not found: $config_path"
        unless -f $config_path;

    open my $fh, '<', $config_path
        or confess "Cannot open extension config file '$config_path': $!";

    my @module_names;
    my $line_number = 0;
    while (my $line = <$fh>) {
        $line_number++;
        chomp $line;
        $line =~ s/\r\z//;

        next if $line =~ /^\s*(?:#.*)?$/;

        if ($line =~ /^\s*module\s+([A-Za-z_]\w*(?:::\w+)*)\s*(?:#.*)?$/) {
            push @module_names, $1;
            next;
        }

        confess "Invalid extension config line at '$config_path' line $line_number: ".
            "expected 'module Module::Name'";
    }

    close $fh
        or confess "Cannot close extension config file '$config_path': $!";

    return \@module_names;
}

sub load_modules ($self, $module_names) {
    confess "FSM::Extension::Loader expects an array reference of module names"
        unless ref($module_names) eq 'ARRAY';

    my @extensions;
    for my $module_name (@$module_names) {
        confess "FSM::Extension::Loader requires non-empty extension module names"
            unless defined($module_name) && $module_name ne '';
        confess "FSM::Extension::Loader rejects invalid extension module name '$module_name'"
            unless $module_name =~ /\A[A-Za-z_]\w*(?:::\w+)*\z/;

        my $loaded = eval "require $module_name; 1";
        confess "Unable to load extension module '$module_name': $@"
            unless $loaded;

        confess "Extension module '$module_name' must provide new()"
            unless $module_name->can('new');

        my $extension = eval { $module_name->new() };
        confess "Extension module '$module_name' failed to instantiate via new(): $@"
            if $@;
        confess "Extension module '$module_name' did not return a blessed object from new()"
            unless blessed($extension);

        push @extensions, $extension;
    }

    return \@extensions;
}

1;
