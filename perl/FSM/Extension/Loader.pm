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
