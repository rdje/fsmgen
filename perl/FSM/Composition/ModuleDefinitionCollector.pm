package FSM::Composition::ModuleDefinitionCollector;

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

# A realized instance owns bindings and provenance; its emitted module may be
# shared. Compare complete generated definitions before omitting a repeated one.
sub collect ($class, %args) {
    my $vhdl = ($args{target_language} // '') eq 'vhdl';
    my $key_for = sub ($name) { return $vhdl ? lc($name) : $name };
    my $top_name = $args{top_name};
    my %definitions;
    my @segments;
    for my $instance (@{$args{instances} || []}) {
        my $hdl = $instance->hdl_code;
        next unless defined($hdl) && length($hdl);
        my $name = $instance->module_name;
        my $instance_name = $instance->instance_name // 'unknown';
        die "Generated child '$instance_name' has HDL without a module identity\n"
            unless defined($name) && !ref($name) && length($name);
        my $key = $key_for->($name);
        die "Generated child '$instance_name' module '$name' conflicts with composition top '$top_name'\n"
            if defined($top_name) && $key eq $key_for->($top_name);
        my $definition = _comparison_definition($hdl);
        if (my $previous = $definitions{$key}) {
            die "Generated module '$name' has conflicting definitions for instances '$previous->{instance}' and '$instance_name'\n"
                unless $definition eq $previous->{definition};
            next;
        }
        $definitions{$key} = {instance => $instance_name, definition => $definition};
        push @segments, $hdl;
    }
    return \@segments;
}

sub _comparison_definition ($hdl) {
    # Ignore only ScaffoldEmitter's known informational header timestamp. Keep
    # every other byte significant, including arbitrary Date comments elsewhere.
    $hdl =~ s{\A(//[=]+\n// Flattened Decision Tree FSM: [^\n]+\n// Generated using Enable-based Methodology with WEN/EN Signals\n)// Date: [^\n]*\n}{$1};
    return $hdl;
}

1;
