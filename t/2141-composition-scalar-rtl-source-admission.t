use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use IPC::Cmd qw(run);
use FSM::Pipeline::HDLGenerator;
use FSM::ProjectDataLocality qw(create_project_tempdir);
use FSM::Support::CompositionParameterContract qw(build_composition_parameter_contract);
use FSM::Support::RegressionCorpus qw(regression_corpus_entries);

my $path = 't/corpus/composition_scalar_rtl_parameters.fsm';
open my $input, '<', $path or die $!;
my $source = do {local $/; <$input>}; close $input or die $!;
my $json = JSON::PP->new->canonical;
my %capture;
sub pipeline {
    FSM::Pipeline::HDLGenerator->new(debug_level => 0, quiet => 1,
        strict_mode => 1, target_language => $_[0]);
}

subtest 'actual fixed-interface RTL source preserves top and child configuration' => sub {
    for my $language (qw(systemverilog verilog vhdl)) {
        my $result = eval {pipeline($language)->generate_hdl_from_file($path)};
        ok($result, "$language source generates") or do {diag($@); next};
        my $plan = $result->{composition_plan};
        is($plan->lane, 'C3', "$language uses the actual explicit-link lane");
        is_deeply($plan->parameter_environment->{declaration_order}, [qw(COPY WIDTH SAME TOTAL)],
            "$language environment retains authored order");
        my $actuals = $plan->instances->[0]->parameter_overrides;
        is_deeply([map {[$_->{name}, $_->{binding_expression}{parameter}]} @$actuals],
            [['COUNT', 'TOTAL'], ['OTHER', 'SAME']], "$language actuals retain selected identities");
        my $hdl = $result->{hdl_code};
        $capture{targets}{$language} = {hdl => $hdl, environment => $plan->parameter_environment,
            actuals => $actuals};
        if ($language eq 'vhdl') {
            like($hdl, qr/WIDTH : natural := 16;\s+COPY : natural := WIDTH;\s+SAME : natural := 16;\s+TOTAL : natural := \(COPY \+ 2\)/s,
                'VHDL emits complete canonical defaults in dependency order');
            like($hdl, qr/COUNT => TOTAL,\s+OTHER => SAME/s, 'VHDL forwards actual names rather than cached values');
        } else {
            like($hdl, qr/parameter WIDTH = 16,\s+parameter COPY = WIDTH,\s+parameter SAME = 16,\s+parameter TOTAL = \(COPY \+ 2\)/s,
                "$language emits complete canonical defaults in dependency order");
            like($hdl, qr/\.COUNT\(TOTAL\),\s+\.OTHER\(SAME\)/s, "$language forwards actual names rather than cached values");
        }
        my ($ok, $error, undef, $stdout, $stderr) = run(command => [
            './bin/fsmgen', '--quiet', '--strict', '--language', $language, '--check', '--json', $path]);
        ok($ok, "$language native strict check succeeds") or diag($error, join('', @$stderr));
        my $report = eval {$json->decode(join('', @$stdout))};
        ok($report && $report->{success}, "$language native report records successful source admission");
    }
};

subtest 'native semantic query retains the actual composition environment' => sub {
    my ($ok, $error, undef, $stdout, $stderr) = run(command => [
        './bin/fsmgen', '--quiet', '--strict', '--emit-semantic-json', $path]);
    ok($ok, 'native strict semantic query succeeds') or diag($error, join('', @$stderr));
    my $report = eval {$json->decode(join('', @$stdout))};
    ok($report && $report->{success}, 'native semantic report records success');
    return unless $report && $report->{success};
    my $semantic = $report->{semantic};
    my @environments = ($semantic->{forward_ir}{intent_hir}{parameter_environment},
        $semantic->{forward_ir}{structural_rtl_ir}{parameter_environment},
        $semantic->{composition}{plan_snapshot}{parameter_environment});
    for my $environment (@environments) {
        is_deeply($environment->{scope}, {kind => 'composition_top', owner => 'composition_scalar_rtl_parameters'},
            'actual source owns each advertised environment');
        is_deeply($environment->{declaration_order}, [qw(COPY WIDTH SAME TOTAL)],
            'actual authored declaration order survives public export');
    }
    is_deeply($environments[1], $environments[0], 'complete structural and intent environments agree');
    is_deeply($environments[2], $environments[0], 'complete plan snapshot and intent environments agree');
    $capture{semantic} = $report;
};

subtest 'actual source refuses mutable interfaces and unqualified profiles' => sub {
    my $dir = create_project_tempdir(purpose => 'scalar-rtl-source-admission');
    for my $case (
        ['generated', 'systemverilog', sub {$_[0] =~ s/\?rtl:u_leaf \(module scalar_leaf\)/?fsmc:u_leaf scalar_leaf/}, qr/generated child 'u_leaf'.*generic interface preservation/],
        ['mutable width', 'systemverilog', sub {$_[0] =~ s/drive<1/(input drive (width (param WIDTH)))/}, qr/port 'drive'.*parameter-dependent width/],
        ['VHDL sized default', 'vhdl', sub {$_[0] =~ s/\(WIDTH 16\)/(WIDTH 8'h10)/}, qr/VHDL.*(?:integer|decimal|literal)/i],
    ) {
        my ($label, $language, $change, $pattern) = @$case;
        my $text = $source; $change->($text);
        isnt($text, $source, "$label control changes actual source");
        my $file = "$dir/control.fsm";
        open my $out, '>', $file or die $!; print {$out} $text; close $out or die $!;
        my $ok = eval {pipeline($language)->generate_hdl_from_file($file); 1};
        ok(!$ok, "$label refuses before returning an artifact");
        like($@, $pattern, "$label names the actual unsupported boundary");
        if ($language eq 'systemverilog') {
            my ($success, undef, undef, $stdout) = run(command => [
                './bin/fsmgen', '--quiet', '--strict', '--check', '--json', $file]);
            ok(!$success, "$label native source query refuses");
            my $report = $json->decode(join('', @$stdout));
            is($report->{diagnostics}[0]{code}, 'FSMGEN_COMPOSITION_TOP_PARAMETER_LOWERING',
                "$label native refusal retains the classified code");
        }
    }
};

subtest 'discovery and representative corpus name the bounded source profile' => sub {
    my $contract = build_composition_parameter_contract();
    is_deeply($contract->{fixed_interface_rtl_source}, {
        targets => [qw(systemverilog sv verilog v vhdl)],
        source_admission => JSON::PP::true, scalar_top_defaults => JSON::PP::true,
        scalar_child_actuals => JSON::PP::true, generated_children => JSON::PP::false,
        parameter_dependent_interfaces => JSON::PP::false,
        external_override_legality => JSON::PP::false,
    }, 'exact discovery describes source support and outstanding qualification');
    my ($entry) = grep {$_->{relpath} eq $path} regression_corpus_entries();
    ok($entry && $entry->{classification} eq 'supported_smoke' && $entry->{strict_supported},
        'representative source has strict-supported corpus ownership');
};

done_testing;
if (my $out_path = $ENV{FSMGEN_SOURCE_ADMISSION_CAPTURE}) {
    open my $out, '>', $out_path or die $!;
    print {$out} $json->encode(\%capture), "\n" or die $!;
    close $out or die $!;
}
