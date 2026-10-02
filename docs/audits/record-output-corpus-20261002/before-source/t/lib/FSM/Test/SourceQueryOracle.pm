package FSM::Test::SourceQueryOracle;

use strict;
use warnings;
use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(source_query_semantic_errors source_query_envelope_errors);
my $json = JSON::PP->new->canonical->allow_nonref;

# Independent expectations come from the public contracts and authored fixtures,
# never from another transport's report or the compiler's implementation.
sub source_query_semantic_errors {
    my ($args) = @_;
    my ($row, $kind, $report) = @$args{qw(row query_kind report)};
    my @errors;
    return ['report must be an object'] unless ref($report) eq 'HASH';
    my %queries = (fsm => [qw(check semantic)], vial => [qw(check semantic inspection)],
        map {$_ => [qw(check semantic schedule)]} qw(isf ppif axi apb ahb));
    return ['unregistered source/query family'] unless exists($queries{$row->{file_kind}})
        && grep {$_ eq $kind} @{$queries{$row->{file_kind}}};
    my $failed = exists $args->{expected_diagnostic};
    my $checked = $report;
    if ($row->{file_kind} eq 'vial') {
        my $version = $row->{language_version};
        return ['unregistered VIAL language version']
            unless defined($version) && !ref($version) && $version =~ /\A[12]\z/;
        if ($kind eq 'inspection') {
            _check(\@errors, $report, '/schema', 'fsmgen.vial_source_inspection.v1');
            _check(\@errors, $report, '/schema_version', 1);
            _check(\@errors, $report, '/success', $failed ? JSON::PP::false : JSON::PP::true);
            if ($failed) { _check(\@errors, $report, '/inspection', undef) }
            else { _vial_detail(\@errors, $report, $row, $args->{source_sha256}) }
            my ($found, $value) = _lookup($report, '/check_result');
            return [@errors, 'missing inspection check_result'] unless $found && ref($value) eq 'HASH';
            $checked = $value;
        }
        _check(\@errors, $checked, '/schema', "fsmgen.vial_tool_result.v$version");
        _check(\@errors, $checked, '/schema_version', 0 + $version);
        _check(\@errors, $checked, '/action', 'check');
        _check(\@errors, $checked, '/implementation/component', 'FSM::VIAL::Tool');
        if ($failed) { _check(\@errors, $checked, '/semantic_report', undef) }
        else {
            _check(\@errors, $checked, '/source_identities/0/source_name', $row->{source_id});
            _check(\@errors, $checked, '/source_identities/0/content_sha256', $args->{source_sha256});
        }
    } elsif ($kind eq 'schedule') {
        # Broad schedule shape/provenance is guarded by T1884. These are exact
        # source-authored witnesses for metadata absent from normalized RTL.
        _schedule_detail(\@errors, $report, $row->{source_id});
        return \@errors;
    } else {
        my $semantic = $kind eq 'semantic';
        _check(\@errors, $report, $semantic ? '/normalized_semantic_schema_version' : '/check_schema_version', 1);
        _check(\@errors, $report, '/producer/name', 'FSMGen');
        _check(\@errors, $report, '/producer/report_source', $semantic
            ? 'FSM::Support::NormalizedSemanticReport' : 'FSM::Support::CheckDiagnostics');
        _check(\@errors, $report, '/source/resolved_path', $row->{source_id});
        _check(\@errors, $report, '/command/mode', $semantic ? 'semantic_export' : 'check');
        _check(\@errors, $report, '/command/strict_mode', JSON::PP::true);
        _check(\@errors, $report, '/generated_output/emitted', JSON::PP::false);
        unless ($failed) {
            my $module = $row->{expectations}{expected_top_name} // $row->{expectations}{expected_module_name};
            push @errors, 'missing independent catalog module expectation' unless defined $module;
            _check(\@errors, $report, $semantic ? '/semantic/module/name' : '/result/module_name', $module);
            if ($semantic) {
                my $root = $row->{expectations}{expected_semantic_source_root_kind}
                    // ($row->{source_kind} eq 'composition' ? 'top' : $row->{source_kind});
                _check(\@errors, $report, '/semantic/module/source_root_kind', $root);
                _check(\@errors, $report, '/semantic/forward_ir/intent_hir/module_name', $module);
                _check(\@errors, $report, '/semantic/forward_ir/structural_rtl_ir/module_name', $module);
            }
        }
    }
    _check(\@errors, $checked, '/success', $failed ? JSON::PP::false : JSON::PP::true);
    if ($failed) {
        _check(\@errors, $checked, '/diagnostics/0/code', $args->{expected_diagnostic});
        _check(\@errors, $report, '/diagnostics/0/code', $args->{expected_diagnostic});
    } else {
        _check(\@errors, $checked, '/diagnostics', []);
        _check(\@errors, $report, '/diagnostics', []);
    }
    return \@errors;
}

sub source_query_envelope_errors {
    my ($args) = @_;
    my ($row, $kind, $result) = @$args{qw(row query_kind result)};
    my @errors;
    return ['tool result must be an object'] unless ref($result) eq 'HASH';
    _check(\@errors, $result, '/isError', $args->{expected_failure} ? JSON::PP::true : JSON::PP::false);
    my ($found, $payload) = _lookup($result, '/structuredContent');
    return [@errors, 'missing structuredContent'] unless $found && ref($payload) eq 'HASH';
    _check(\@errors, $payload, '/source_id', $row->{source_id});
    _check(\@errors, $payload, '/source_path', $row->{source_id});
    _check(\@errors, $payload, '/query_kind', $kind);
    my %shape = (check => 'bin/fsmgen --strict --check --json <source>',
        semantic => 'bin/fsmgen --strict --emit-semantic-json <source>',
        schedule => 'bin/fsmgen --emit-schedule-json <source>');
    my $provenance = {contract_source => 'FSM::Support::SemanticIntrospectionMCPAdapter',
        transport => 'jsonrpc_stdio', read_only => JSON::PP::true, shell_access => JSON::PP::false,
        workspace_root_policy => 'caller_configured_root_not_returned', source_identity => 'workspace_relative',
        command_shape => $shape{$kind}};
    if ($row->{file_kind} eq 'vial') {
        $provenance->{command_shape} = undef;
        $provenance->{api_entrypoint} = 'FSM::VIAL::Tool::'.($kind eq 'inspection' ? 'inspect' : 'check').'_vial_source_file';
        $provenance->{language_version} = $row->{language_version};
    }
    _check(\@errors, $payload, '/adapter_provenance', $provenance);
    my ($has_report, $report) = _lookup($payload, '/report');
    push @errors, 'missing report object' unless $has_report && ref($report) eq 'HASH';
    my ($has_text, $text) = _lookup($result, '/content/0/text');
    my $decoded = eval {$json->decode($text // '')};
    push @errors, 'text and structured payload differ' if !$has_text || $@ || !_equal($decoded, $payload);
    return \@errors;
}

sub _schedule_detail {
    my ($errors, $report, $source) = @_;
    if ($source eq 'isf/storage_fields.isf') {
        my ($found, $storage) = _lookup($report, '/inferred_storage');
        my @control = $found && ref($storage) eq 'ARRAY'
            ? grep {ref($_) eq 'HASH' && ($_->{name} // '') eq 'control'} @$storage : ();
        if (@control != 1) { push @$errors, 'inferred_storage/control must occur exactly once'; return }
        _check($errors, $control[0], '/width', 8);
        _check($errors, $control[0], '/kind', 'register');
        _check($errors, $control[0], '/role', 'actor_storage');
        _check($errors, $control[0], '/fields', [
            {name => 'mode', msb => 7, lsb => 5, width => 3, access => 'rw', reset => 5,
                enum => [{name => 'IDLE', value => 0}, {name => 'RUN', value => 5}]},
            {name => 'prio', msb => 4, lsb => 2, width => 3, access => 'rw'},
            {name => 'enable', msb => 0, lsb => 0, width => 1, access => 'rw', reset => 1,
                enum => [{name => 'OFF', value => 0}, {name => 'ON', value => 1}]},
        ]);
    }
    if ($source eq 'isf/verification_observation_metadata.isf') {
        _check($errors, $report, '/verification_observations', [{name => 'link_rx', role => 'passive_monitor',
            clock => 'clk', reset => {name => 'rst_n', kind => 'async', polarity => 'active_low'},
            signals => [{name => 'valid', direction => 'input', width => 1},
                {name => 'ready', direction => 'output', width => 1}, {name => 'data', direction => 'input', width => 8}]}]);
    }
}

sub _vial_detail {
    my ($errors, $report, $row, $sha) = @_;
    _check($errors, $report, '/inspection/schema', 'fsmgen.vial_source_semantics.v1');
    _check($errors, $report, '/inspection/schema_version', 1);
    _check($errors, $report, '/inspection/language_version', $row->{language_version});
    _check($errors, $report, '/inspection/root_source/source_name', $row->{source_id});
    _check($errors, $report, '/inspection/root_source/content_sha256', $sha);
    my $package = 'ahb_subordinate_base_output_arbitration';
    my %sources = map { ("vial/${package}${_}.vial" => 1) } ('', '_v2', '_lifecycle_v2');
    unless ($sources{$row->{source_id}}) { push @$errors, 'unregistered authored VIAL source oracle'; return }
    my $p = '/inspection/packages/0';
    my $f = "$p/fixtures/0";
    my $fixture = "$package\::fixture::base_output_arbitration";
    my $domain = "$fixture\::domain::bus";
    _check($errors, $report, "$p/name", $package);
    _check($errors, $report, "$f/scenarios/0/actions/0/kind", 'reset');
    _check($errors, $report, "$f/scenarios/0/actions/0/cycles", 3);
    _check($errors, $report, "$f/scenarios/0/actions/0/domain_id", $domain);
    _check($errors, $report, "$p/models/0/rules/0/assignments/0/expression/op", '+');
    _check($errors, $report, "$p/models/0/rules/0/assignments/0/expression/operands/1/value/value_decimal", '1');
    _check($errors, $report, "$p/scoreboards/0/capacity", 4);
    _check($errors, $report, "$f/instances/model_instances/0/name", 'accepts');
    _check($errors, $report, "$f/instances/model_instances/1/name", 'completions');
    _check($errors, $report, "$f/faults/0/transaction_binding_id", "$fixture\::transaction_binding::write");
    _check($errors, $report, "$f/faults/0/field_name", 'size');
    _check($errors, $report, "$f/faults/0/substitute/value/value_bits", '7');
    my ($found, $families) = _lookup($report, "$p/intent_families");
    unless ($found && ref($families) eq 'ARRAY') { push @$errors, 'missing intent_families'; return }
    unless ($row->{source_id} =~ /_lifecycle_v2\.vial\z/) {
        _check($errors, $report, "$p/intent_families", []);
        return;
    }
    push @$errors, 'lifecycle fixture requires exactly its authored family' unless @$families == 1;
    my $family = "$p/intent_families/0";
    _check($errors, $report, "$family/family_id", 'lifecycle_control');
    _check($errors, $report, "$family/revision", 1);
    my ($has_nodes, $nodes) = _lookup($report, "$family/nodes");
    unless ($has_nodes && ref($nodes) eq 'ARRAY') { push @$errors, 'missing lifecycle nodes'; return }
    my @kinds = qw(dependency dependency service readiness stimulus_start completion drain shutdown finalize deadline deadline failure);
    push @$errors, 'unregistered or incomplete lifecycle node kinds' unless _equal(
        [map {ref($_) eq 'HASH' ? $_->{node_kind} : undef} @$nodes], \@kinds);
    my $flow = "$package\::package::$package\::intent_family::lifecycle_control::lifecycle::fixture_flow";
    my $dependency = sub {_condition('dependency_satisfied', "$flow\::dependency::$_[0]")};
    my $all = sub {_condition('all', undef, undef, [@_])};
    _check($errors, $report, "$family/nodes/1/payload/condition", _condition('reset_inactive', undef, $domain));
    _check($errors, $report, "$family/nodes/2/payload/detail/cancellation", 'cooperative');
    _check($errors, $report, "$family/nodes/2/payload/detail/start_condition", $all->(
        _condition('configured'), $dependency->('configured_gate'), $dependency->('reset_gate')));
    _check($errors, $report, "$family/nodes/3/payload/condition", $all->(
        $dependency->('configured_gate'), $dependency->('reset_gate'),
        _condition('service_ready', "$flow\::service::background::milestone::ready")));
    for my $deadline ([9, 1024, 'finalize::finalized'], [10, 32, 'readiness::ready']) {
        my ($index, $cycles, $until) = @$deadline;
        _check($errors, $report, "$family/nodes/$index/payload/detail", {
            from => _condition('lifecycle_entered', "$flow\::milestone::entered"),
            until => _condition('lifecycle_point', "$flow\::$until"),
            max_cycles => $cycles, last_cycle_inclusive => JSON::PP::true});
    }
    _check($errors, $report, "$family/nodes/11/payload/detail", {
        disposition => 'fail', cleanup => 'finalize', cleanup_max_cycles => 256, diagnostics => 'all'});
}

sub _condition {+{kind => $_[0], reference_id => $_[1], domain_id => $_[2], operands => $_[3] // []}}
sub _check {
    my ($errors, $value, $path, $expected) = @_;
    my ($found, $actual) = _lookup($value, $path);
    push @$errors, "$path ".($found ? 'differs from authored/public expectation' : 'is missing')
        unless $found && _equal($actual, $expected);
}
sub _equal {
    my ($a, $b) = @_;
    my $equal = eval {$json->encode($a) eq $json->encode($b)};
    return !$@ && $equal;
}
sub _lookup {
    my ($value, $path) = @_;
    for my $part (split m{/}, substr($path, 1)) {
        if (ref($value) eq 'HASH' && exists $value->{$part}) { $value = $value->{$part} }
        elsif (ref($value) eq 'ARRAY' && $part =~ /\A(?:0|[1-9][0-9]*)\z/ && $part <= $#$value) { $value = $value->[$part] }
        else { return (0, undef) }
    }
    return (1, $value);
}
1;
