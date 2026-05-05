#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::CoreAST;

subtest 'Assignment metadata summaries are stored and returned as owned copies' => sub {
    my $target_signal = FSM::CoreAST::Signal->new(name => 'OUT');
    my $target = FSM::CoreAST::SignalRef->new($target_signal);
    my $source = FSM::CoreAST::Literal->new('1');

    my $timing_semantics = {
        clock_domain => 'clk',
        reset => {
            name => 'rst_n',
            active_level => 0,
        },
    };
    my $assignment_intent = {
        register_style => 'input_named',
        lhs_binding => 'flop_d_input',
        nested_flags => {
            immediate_visibility => 'same_cycle_on_d_input',
        },
    };
    my $source_provenance = {
        raw_operator => '<=',
        source_tokens => ['OUT', '<=', '1'],
    };

    my $assignment = FSM::CoreAST::Assignment->new(
        target => $target,
        source => $source,
        assignment_type => 'register',
        timing_semantics => $timing_semantics,
        assignment_intent => $assignment_intent,
        source_provenance => $source_provenance,
    );

    $timing_semantics->{reset}{name} = 'mutated_reset';
    $assignment_intent->{nested_flags}{immediate_visibility} = 'mutated_visibility';
    push @{$source_provenance->{source_tokens}}, 'mutated_token';

    is_deeply(
        $assignment->timing_semantics,
        {
            clock_domain => 'clk',
            reset => {
                name => 'rst_n',
                active_level => 0,
            },
        },
        'constructor timing metadata is isolated from caller mutation',
    );
    is(
        $assignment->register_style,
        'input_named',
        'register_style reads the stored assignment intent directly',
    );
    is(
        $assignment->operator_symbol,
        '<=',
        'operator_symbol still resolves from normalized internal intent',
    );
    is(
        $assignment->assignment_intent->{nested_flags}{immediate_visibility},
        'same_cycle_on_d_input',
        'constructor assignment intent metadata is isolated from caller mutation',
    );
    is_deeply(
        $assignment->source_provenance->{source_tokens},
        ['OUT', '<=', '1'],
        'constructor source provenance metadata is isolated from caller mutation',
    );

    my $timing_view = $assignment->timing_semantics;
    my $intent_view = $assignment->assignment_intent;
    my $provenance_view = $assignment->source_provenance;

    $timing_view->{reset}{active_level} = 1;
    $intent_view->{nested_flags}{immediate_visibility} = 'mutated_again';
    $provenance_view->{source_tokens}[0] = 'MUTATED';

    is(
        $assignment->timing_semantics->{reset}{active_level},
        0,
        'timing_semantics returns a fresh nested metadata snapshot',
    );
    is(
        $assignment->assignment_intent->{nested_flags}{immediate_visibility},
        'same_cycle_on_d_input',
        'assignment_intent returns a fresh nested metadata snapshot',
    );
    is_deeply(
        $assignment->source_provenance->{source_tokens},
        ['OUT', '<=', '1'],
        'source_provenance returns a fresh nested metadata snapshot',
    );
};

done_testing();
