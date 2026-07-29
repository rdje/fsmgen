#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use FindBin;
use File::Spec;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::FailureReportBuilder;

subtest 'failure report builder extracts child-header failures' => sub {
    my $report = FSM::Composition::FailureReportBuilder->build_report(
        "Composition source '?top:unsupported_child_failure_summary_top' contains child '?bogus:child', ".
        "but composition child kind support is blocked because the active composition parser currently accepts only '?fsmc', '?dtc', '?rtl', '?ports', '?wiring', '+constants', '+enums', and '+import'. ".
        "See docs/COMPOSITION_SCOPE.md.\n",
    );

    ok($report, 'builder returns a blocked failure report');
    is($report->{top_name}, 'unsupported_child_failure_summary_top', 'builder keeps the top name');
    ok(!defined($report->{construct}), 'builder does not invent a construct for unsupported child headers');
    is($report->{context_label}, 'Child', 'builder classifies child-header context');
    is($report->{context_value}, "'?bogus:child'", 'builder keeps the child header as context');
    is($report->{blocked_boundary}, 'composition child kind support', 'builder keeps the blocked boundary');
    is($report->{blocked_boundary_label}, 'child kind support', 'builder derives the concise boundary label');
    is(
        $report->{blocked_reason},
        "the active composition parser currently accepts only '?fsmc', '?dtc', '?rtl', '?ports', '?wiring', '+constants', '+enums', and '+import'",
        'builder keeps the concise blocked reason',
    );
};

subtest 'failure report builder extracts generated-child source artifacts' => sub {
    my $report = FSM::Composition::FailureReportBuilder->build_report(
        "Composition source '?top:wiring_top' resolves '?fsmc' child 'left' to 'fixtures/left.fsm', ".
        "but generated child source resolution is blocked because the resolved file is not a supported FSM child source. ".
        "See docs/COMPOSITION_SCOPE.md.\n",
    );

    ok($report, 'builder returns a blocked failure report for generated-child source failures');
    is($report->{top_name}, 'wiring_top', 'builder keeps the top name');
    is($report->{construct}, '?fsmc', 'builder infers the construct from the generated child source family');
    is($report->{artifact_label}, 'Child source file', 'builder extracts the child source file label');
    is($report->{artifact_value}, "'fixtures/left.fsm'", 'builder extracts the child source file value');
    is($report->{context_label}, 'Child', 'builder keeps the child context that accompanied the source resolution');
    is($report->{context_value}, "'left'", 'builder formats the child context');
    is($report->{blocked_boundary}, 'generated child source resolution', 'builder keeps the generated-child boundary');
    is($report->{blocked_boundary_label}, 'generated child source resolution', 'builder keeps the concise generated-child boundary label');
    is(
        $report->{blocked_reason},
        "the resolved file is not a supported FSM child source",
        'builder keeps the concise generated-child reason',
    );
};

subtest 'failure report builder extracts explicit-link endpoint context' => sub {
    my $report = FSM::Composition::FailureReportBuilder->build_report(
        "Composition source '?top:wiring_top' references child endpoint 'uart_tx.missing_port', ".
        "but explicit link endpoint resolution is blocked because instance 'uart_tx' has no port named 'missing_port'. ".
        "See docs/COMPOSITION_SCOPE.md.\n",
    );

    ok($report, 'builder returns a blocked failure report for explicit-link endpoint failures');
    is($report->{top_name}, 'wiring_top', 'builder keeps the top name');
    is($report->{construct}, '?wiring', 'builder infers the explicit-link construct');
    is($report->{context_label}, 'Child endpoint', 'builder extracts child endpoint context');
    is($report->{context_value}, "'uart_tx.missing_port'", 'builder formats the child endpoint context');
    is($report->{blocked_boundary}, 'explicit link endpoint resolution', 'builder keeps the explicit-link boundary');
    is($report->{blocked_boundary_label}, 'explicit link endpoint resolution', 'builder keeps the concise explicit-link boundary label');
    is(
        $report->{blocked_reason},
        "instance 'uart_tx' has no port named 'missing_port'",
        'builder keeps the concise explicit-link reason',
    );
};

done_testing();
