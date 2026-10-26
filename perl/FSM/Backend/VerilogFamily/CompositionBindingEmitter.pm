package FSM::Backend::VerilogFamily::CompositionBindingEmitter;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Backend::VerilogFamily::ParameterBindingEmitter;

sub lower_expression ($class, %args) {
    my $language = $args{target_language} // 'systemverilog';
    confess "Composition binding renderer requires a Verilog-family target\n"
        unless !ref($language) && $language =~ /\A(?:systemverilog|sv|verilog|v)\z/;
    my $environment = $args{environment};
    confess "Composition binding renderer requires a resolved environment\n"
        unless ref($environment) eq 'HASH'
            && ref($environment->{parameters}) eq 'HASH'
            && ref($environment->{declaration_order}) eq 'ARRAY';
    my $scope = $environment->{scope};
    confess "Composition binding renderer requires an explicit composition-top scope\n"
        unless ref($scope) eq 'HASH' && ($scope->{kind} // '') eq 'composition_top'
            && defined($scope->{owner}) && !ref($scope->{owner}) && length($scope->{owner});
    return FSM::Backend::VerilogFamily::ParameterBindingEmitter->lower_expression(
        binding => $args{binding}, environment => $environment, target_language => $language);
}

1;

=head1 NAME

FSM::Backend::VerilogFamily::CompositionBindingEmitter - Composition-scoped canonical scalar rendering

=head1 DESCRIPTION

C<lower_expression> retains the Verilog-family target, resolved environment and
explicit composition-top scope contract before delegating the canonical scalar
walk to L<FSM::Backend::VerilogFamily::ParameterBindingEmitter>. Its existing
composition diagnostics and target profiles remain unchanged.

Actual names, static payloads, canonical operator structure and ordered repeated
references remain distinct from validation caches. Aggregate/path/raw-text and
recursive-tree profiles still refuse. Caller inputs and returned dependency
ownership retain the shared helper's contract. Declaration ordering and target
namespaces remain owned by L<FSM::Backend::VerilogFamily::CompositionParameterEmitter>.
This wrapper does not widen source admission or integrate direct-module headers.

=cut
