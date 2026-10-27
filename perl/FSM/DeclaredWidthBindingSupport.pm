package FSM::DeclaredWidthBindingSupport;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(blessed);
use feature qw(signatures);
no warnings 'experimental::signatures';
use JSON::PP ();
use FSM::WidthExpressionSupport;
use FSM::ParameterDeclarationSupport;
use FSM::ParameterValueSupport;
use FSM::Support::HDLInstanceIdentifierPolicy;

sub prove_signal ($class, %args) {
    my $signal = $args{signal};
    confess "Direct declared-width proof requires a Core Signal\n"
        unless blessed($signal) && $signal->isa('FSM::CoreAST::Signal');
    my $capture = $signal->declared_width_binding;
    confess "Direct declared-width proof requires a coherent captured Signal binding\n"
        unless defined $capture;
    my $json = JSON::PP->new->canonical;
    my $data = eval {$json->decode($json->encode({capture => $capture, environment => $args{environment}}))};
    confess "Direct declared-width proof requires JSON-safe acyclic records: $@" if $@;
    $capture = $data->{capture};
    my $environment = $data->{environment};
    my $scope = ref($environment) eq 'HASH' ? $environment->{scope} : undef;
    confess "Direct declared-width proof requires the matching original direct-module scope\n"
        unless ref($scope) eq 'HASH' && join(',', sort keys %$scope) eq 'kind,owner'
            && !ref($scope->{kind}) && ($scope->{kind} // '') eq 'direct_module'
            && defined($scope->{owner}) && !ref($scope->{owner}) && length($scope->{owner})
            && $json->encode($scope) eq $json->encode($capture->{scope});
    confess "Direct declared-width proof requires a complete declared parameter environment\n"
        unless ref($environment->{parameters}) eq 'HASH' && ref($environment->{declaration_order}) eq 'ARRAY';
    my %declared;
    for my $name (@{$environment->{declaration_order}}) {
        confess "Direct declared-width proof has invalid declared parameter membership\n"
            unless FSM::Support::HDLInstanceIdentifierPolicy->is_simple_identifier($name)
                && exists($environment->{parameters}{$name}) && !$declared{$name}++
                && ref($environment->{parameters}{$name}) eq 'HASH'
                && ref($environment->{parameters}{$name}{value_payload}) eq 'HASH';
    }
    confess "Direct declared-width proof has incomplete declared parameter membership\n"
        unless keys(%declared) == keys(%{$environment->{parameters}});
    my $context = {environment => $environment, observations => $capture->{observations},
        cursor => 0, parameters => [], json => $json};
    my $evaluator = FSM::WidthExpressionSupport->new(
        resolve_symbol_observation => sub ($token) {
            return _take_observation($context, 'symbol', $token);
        },
        resolve_parameter_payload => sub ($token) {
            return _take_observation($context, 'parameter', $token)->{value_payload};
        },
    );
    # This is consistency proof of the captured walk, using frozen selections
    # only. No live symbol resolver may reclassify a token or infer a namespace.
    my $observed = $evaluator->capture_positive_width_expression(
        $capture->{expression}, "Direct declared-width proof for '$capture->{signal}'");
    confess "Direct declared-width proof has unused lookup observations\n"
        unless $context->{cursor} == @{$capture->{observations}};
    my $expected = {map {$_ => $capture->{$_}} qw(width binding observations)};
    confess "Direct declared-width proof does not match captured source structure or selected default\n"
        unless $json->encode($observed) eq $json->encode($expected);
    return $json->decode($json->encode({capture => $capture,
        parameter_references => $context->{parameters},
        has_parameter_references => @{$context->{parameters}} ? 1 : 0}));
}

sub _take_observation ($context, $lookup, $token) {
    my $observation = $context->{observations}[$context->{cursor}++];
    confess "Direct declared-width proof lookup sequence does not match '$token'\n"
        unless ref($observation) eq 'HASH' && !ref($observation->{lookup})
            && ($observation->{lookup} // '') eq $lookup
            && defined($observation->{token}) && !ref($observation->{token})
            && $observation->{token} eq $token;
    my %selected = %$observation;
    delete $selected{lookup};
    confess "Direct declared-width proof parameter lookup cannot borrow another namespace\n"
        if $lookup eq 'parameter' && ($selected{kind} // '') ne 'parameter';
    if (($selected{kind} // '') eq 'parameter') {
        my $parameters = $context->{environment}{parameters};
        my $reference = FSM::ParameterDeclarationSupport->declared_reference($parameters, $token);
        confess "Direct declared-width proof requires the actual declared parameter selection '$token'\n"
            unless $reference && defined($selected{parameter}) && !ref($selected{parameter})
                && defined($selected{suffix}) && !ref($selected{suffix})
                && $reference->{parameter} eq $selected{parameter} && $reference->{suffix} eq $selected{suffix};
        my $payload = FSM::ParameterValueSupport->resolve_payload_path(
            $parameters->{$reference->{parameter}}{value_payload}, $reference->{suffix});
        confess "Direct declared-width proof has a stale selected parameter payload for '$token'\n"
            unless $context->{json}->encode($payload) eq $context->{json}->encode($selected{value_payload});
        push @{$context->{parameters}}, {lookup => $lookup, %$reference};
    }
    # Canonical capture validates the remaining closed observation shape and
    # selected payload. Nested evaluation consumes its own exact next records.
    return \%selected;
}

1;

=head1 NAME

FSM::DeclaredWidthBindingSupport - Frozen-observation consistency proof for actual direct width captures

=head1 DESCRIPTION

C<prove_signal> consumes an actual Core C<signal> with a coherent public
C<declared_width_binding> and a prepared direct C<environment> containing source
C<scope>, complete C<declaration_order> and declared C<parameters>. Inputs are
detached as plain acyclic JSON before validation.

The canonical width capture walk re-derives the recorded source structure using
strict frozen observations. Entrypoint, token, kind, order, nested payload walks,
binding structure and selected default width must match completely. No live
namespace resolver runs, and equal values never choose parameter ancestry.
Selected parameter root/path identities and payloads must match the explicit
declaration environment through existing declaration/path helpers. Static
selections remain pinned even beside same-named parameters.

Returns detached C<capture>, ordered C<parameter_references> (lookup, parameter,
token, suffix) and numeric C<has_parameter_references>. Nested/repeated actual
lookups remain distinct. Missing coherent captures, foreign scope, malformed
membership, cycles, changed observations/source structure/defaults and stale
selected payloads refuse. Caller data and physical names do not supply scope;
results retain neither Signal nor caller environment.

Canonical producer authorship and full declaration/target provenance remain
caller obligations. This proves internal capture consistency, not authenticity
of arbitrary caller-made records, target legality or a symbolic range profile.
Target adaptation, module plans, source/declaration activation and complete
compiler/override/runtime qualification remain separate work.

=cut
