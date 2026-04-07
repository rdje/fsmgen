package FSM::Package::SignalManagerProjectionSupport;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Adapter::FSMGenFull::ExpressionBuilder;

sub project_symbols_into_signal_manager ($class, %args) {
    my $signal_manager = $args{signal_manager}
        or confess "SignalManagerProjectionSupport requires a signal_manager";
    my $symbols = $args{symbols}
        or confess "SignalManagerProjectionSupport requires symbols";

    my $namespace_prefix = $args{namespace_prefix} // '';
    my $expression_builder = $args{expression_builder} // FSM::Adapter::FSMGenFull::ExpressionBuilder->new(
        debug => ($args{debug_level} // 0) > 0,
        signal_manager => $signal_manager,
    );

    my $qualify = sub ($name) {
        return $name unless length $namespace_prefix;
        return $namespace_prefix . '.' . $name;
    };

    my $aggregate_paths = $symbols->constant_aggregate_paths || {};
    for my $aggregate_path (sort keys %$aggregate_paths) {
        $signal_manager->store_aggregate_symbol(
            $qualify->($aggregate_path),
            $symbols->resolve_payload($aggregate_path),
        );
    }

    my $scalar_leaves = $symbols->constant_scalar_leaves || {};
    for my $constant_name (sort keys %$scalar_leaves) {
        my $payload = $scalar_leaves->{$constant_name};
        my $literal_expr = $expression_builder->parse_scalar_expression($payload);
        $signal_manager->store_constant($qualify->($constant_name), $literal_expr);
    }

    for my $enum_name (sort keys %{ $symbols->enums || {} }) {
        my $members = $symbols->enums->{$enum_name} || {};
        $signal_manager->store_enum($enum_name, $members)
            unless length $namespace_prefix;

        for my $member_name (sort keys %$members) {
            my $payload = $members->{$member_name};
            my $literal_expr = $expression_builder->parse_scalar_expression($payload);
            $signal_manager->store_constant(
                $qualify->($enum_name . '.' . $member_name),
                $literal_expr,
            );
        }
    }

    return $signal_manager;
}

1;
