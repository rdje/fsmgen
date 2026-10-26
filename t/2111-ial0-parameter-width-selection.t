use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use File::Temp qw(tempdir tempfile);
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::RegressionCorpus qw(regression_corpus_entries);
use FSM::Support::CheckDiagnostics qw(build_check_failure_report);

my $json = JSON::PP->new->canonical;
my $fixture = 't/corpus/direct_size_parameter_selection.fsm';
my $missing = 't/corpus/direct_size_parameter_selection_missing.fsm';
my $tempdir = tempdir(CLEANUP => 1);

subtest 'explicit selection keeps parameter, constant and type namespaces distinct' => sub {
    my $raw = Lispish::multi($fixture);
    my $before = $json->encode($raw);
    my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
    my $module = eval {$adapter->parse_fsm($raw)};
    ok($module, 'actual source with explicit parameter width selection parses') or diag($@);
    return unless $module;
    my %expected = (BARE => 4, SCALAR => 8, SELECTED => 16, ALIASED => 16,
        DERIVED_WIDTH => 17, NESTED => 24, LITERAL => 8);
    for my $name (sort keys %expected) {
        is($adapter->{signal_manager}->get_signal($name)->width, $expected{$name}, "$name selects its declared namespace/default");
    }
    is($json->encode($raw), $before, 'complete original frontend caller is unchanged');
    my $signal = $adapter->{signal_manager}->get_signal('SELECTED');
    is($json->encode($signal->declared_width_source),
        '{"expression":["param",["W"]],"resolved_width":16,"signal":"SELECTED"}',
        'Core signal keeps the explicit selector tree and original signal identity');
    my $params = $json->encode($module->parameters);
    my $payload = $adapter->{signal_manager}->resolve_declared_parameter_payload('W');
    is_deeply($payload, {kind => 'scalar', payload => '16'}, 'selected payload comes only from the real parameter');
    $payload->{payload} = 'WRONG';
    is_deeply($adapter->{signal_manager}->resolve_declared_parameter_payload('W'),
        {kind => 'scalar', payload => '16'}, 'parameter payload accessor is detached');
    is($json->encode($module->parameters), $params, 'payload mutation cannot alter module defaults');
    is($module->parameter_default_sources->{ALIAS}{references}[0]{parameter}, 'W',
        'authored alias identity remains available beside default evaluation');
};

subtest 'wrong shape, missing namespace and non-scalar defaults fail closed' => sub {
    for my $case (
        ['(param)', qr/requires exactly one declared parameter name/],
        ['(param W EXTRA)', qr/requires exactly one declared parameter name/],
        ['(param (+ W 1))', qr/requires exactly one declared parameter name/],
        ['(param W.member)', qr/requires exactly one declared parameter name/],
        ['(param W[0])', qr/requires exactly one declared parameter name/],
        ['(param ONLY_STATIC)', qr/references unknown declared parameter 'ONLY_STATIC'/],
        ['(param ONLY_TYPE)', qr/references unknown declared parameter 'ONLY_TYPE'/],
        ['(param MISSING)', qr/references unknown declared parameter 'MISSING'/],
        ['(param GROUP)', qr/resolved to aggregate payload kind 'list', not a scalar integer/],
        ['(param ZERO)', qr/must resolve to a positive integer width/],
        ['(param NEGATIVE)', qr/must resolve to a positive integer width/],
        ['(/ (param W) 0)', qr/divides by zero in a width expression/],
    ) {
        my $text = '(?fsm:invalid_parameter_width (+constants (ONLY_STATIC 8))'
            .' (+types (type ONLY_TYPE (bits 4))) (+params (W 16) (EXTRA 8) (GROUP (4 8)) (ZERO 0) (NEGATIVE -1))'
            .' (+size (OUT '.$case->[0].')) (idle (= (OUT 0))))';
        my $ok = eval {parse_text($text); 1};
        ok(!$ok, "$case->[0] is refused"); like($@, $case->[1], 'refusal identifies the actual boundary');
    }
    my $ok = eval {parse_text('(?fsm:wrong_slot (+params (W 16) (VALUE (param W))))'); 1};
    ok(!$ok, 'param selection is not a general parameter-default expression operator');
};

subtest 'published language and corpus metadata describe this bounded admission' => sub {
    my $manifest = build_capability_manifest();
    ok(grep($_ eq '+size (param NAME) explicitly selects a declared scalar parameter default',
        @{$manifest->{language_surface}{declarations}{width_declarations}}), 'manifest advertises explicit width selection');
    my %entries = map {$_->{id} => $_} regression_corpus_entries();
    my $success = $entries{'feature.direct_size_parameter_selection'};
    my $failure = $entries{'contract.direct_size_parameter_selection_missing'};
    is($success && $success->{relpath}, $fixture, 'accepted source owns a supported corpus row');
    is($failure && $failure->{relpath}, $missing, 'namespace borrowing refusal owns a corpus row');
    my $ok = eval {FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(Lispish::multi($missing)); 1};
    ok(!$ok, 'a same-named constant and type cannot supply an absent parameter');
    my $error = $@;
    if ($failure) {
        like($error, $failure->{expected_error_pattern}, 'actual refusal matches the registered contract');
        my $report = build_check_failure_report(source_file => $missing, error => $error, strict_mode => 1);
        is($report->{diagnostics}[0]{code}, 'FSMGEN_LANGUAGE_UNKNOWN_SIZE_SYMBOL', 'actual classifier preserves the stable unknown-width-symbol code');
    }
};

done_testing();

sub parse_text {
    my ($text) = @_;
    my ($fh, $path) = tempfile(DIR => $tempdir, SUFFIX => '.fsm');
    print {$fh} $text, "\n" or die $!; close $fh or die $!;
    return FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(Lispish::multi($path));
}
