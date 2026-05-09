package FSM::Support::SerializableGenerationResultSnapshot;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_serializable_generation_result_snapshot
    build_serializable_generation_result_snapshot_contract
    serializable_generation_result_snapshot_contract_source
    serializable_generation_result_snapshot_public_top_level_keys
    serializable_generation_result_snapshot_summary_keys
);

sub serializable_generation_result_snapshot_contract_source {
    return 'FSM::Support::SerializableGenerationResultSnapshot';
}

sub build_serializable_generation_result_snapshot_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => serializable_generation_result_snapshot_contract_source(),
        object_name => 'generation_result_snapshot',
        report_source => serializable_generation_result_snapshot_contract_source(),
        entrypoints => {
            in_process => [
                'FSM::Support::SerializableGenerationResultSnapshot::build_serializable_generation_result_snapshot(result => $result)',
            ],
        },
        public_top_level_presence_keys => serializable_generation_result_snapshot_public_top_level_keys(),
        summary_keys => serializable_generation_result_snapshot_summary_keys(),
        json_safe_as_whole => JSON::PP::true,
        raw_result_object_exported => JSON::PP::false,
        guidance => [
            'Use this snapshot for bounded HDLGenerator result inspection instead of treating the raw result hash as a JSON API.',
            'The snapshot records key presence, stable scalar summaries, semantic-layer presence, raw compatibility-shell presence, and generated HDL size metadata.',
            'Raw AST, CoreAST, package-spec, and composition objects remain in-process implementation details and are represented only by presence/class metadata.',
        ],
    };
}

sub build_serializable_generation_result_snapshot {
    my (%args) = @_;
    my $result = $args{result} || {};
    $result = {} unless ref($result) eq 'HASH';

    my $module_info = _hash_value($result->{module_info});
    my $source_info = _hash_value($result->{source_info});
    my $statistics = _hash_value($result->{statistics});
    my $hdl_code = $result->{hdl_code};

    return {
        generation_result_snapshot_schema_version => 1,
        report_source => serializable_generation_result_snapshot_contract_source(),
        contract_source => serializable_generation_result_snapshot_contract_source(),
        present => JSON::PP::true,
        summary => {
            module_name => _first_defined($module_info->{module_name}, _hash_value($result->{intent_hir})->{module_name}),
            source_root_kind => _first_defined($module_info->{source_root_kind}, $source_info->{kind}),
            target_language => _first_defined(
                _hash_value($result->{lowered_rtl_ir})->{target_language},
                _hash_value($result->{structural_rtl_ir})->{target_language},
                'systemverilog',
            ),
            hdl_code_present => _bool(defined($hdl_code) && length($hdl_code)),
            hdl_code_length => defined($hdl_code) ? length($hdl_code) : 0,
            hdl_code_line_count => defined($hdl_code) && length($hdl_code)
                ? scalar(split /\n/, $hdl_code)
                : 0,
            module_signal_count => _first_defined($module_info->{signal_count}, 0),
            module_state_count => _first_defined($module_info->{state_count}, 0),
            composition_child_count => _first_defined($module_info->{composition_child_count}, 0),
        },
        top_level_keys => [sort keys %$result],
        stable_summary_presence => {
            source_info => _bool(ref($result->{source_info}) eq 'HASH'),
            module_info => _bool(ref($result->{module_info}) eq 'HASH'),
            statistics => _bool(ref($result->{statistics}) eq 'HASH'),
        },
        semantic_layer_presence => {
            intent_hir => _bool(ref($result->{intent_hir}) eq 'HASH'),
            lowered_rtl_ir => _bool(ref($result->{lowered_rtl_ir}) eq 'HASH'),
            structural_rtl_ir => _bool(ref($result->{structural_rtl_ir}) eq 'HASH'),
        },
        raw_shell_presence => {
            composition_spec => _presence_class($result->{composition_spec}),
            composition_plan => _presence_class($result->{composition_plan}),
            composition_report => _presence_class($result->{composition_report}),
            fsm_module => _presence_class($result->{fsm_module}),
            raw_ast => _presence_class($result->{raw_ast}),
            resolved_package_imports => _presence_class($result->{resolved_package_imports}),
        },
        source_summary => {
            header => $source_info->{header},
            kind => $source_info->{kind},
            package_import_count => _first_defined($source_info->{package_import_count}, 0),
            package_import_names => _array_of_scalars($source_info->{package_import_names}),
        },
        statistics_summary => {
            intermediate_signals => _first_defined($statistics->{intermediate_signals}, 0),
            global_expressions => _first_defined($statistics->{global_expressions}, 0),
            factoring_enabled => _bool($statistics->{factoring_enabled}),
        },
    };
}

sub serializable_generation_result_snapshot_public_top_level_keys {
    return [
        qw(
            generation_result_snapshot_schema_version
            report_source
            contract_source
            present
            summary
            top_level_keys
            stable_summary_presence
            semantic_layer_presence
            raw_shell_presence
            source_summary
            statistics_summary
        ),
    ];
}

sub serializable_generation_result_snapshot_summary_keys {
    return [
        qw(
            module_name
            source_root_kind
            target_language
            hdl_code_present
            hdl_code_length
            hdl_code_line_count
            module_signal_count
            module_state_count
            composition_child_count
        ),
    ];
}

sub _hash_value {
    my ($value) = @_;
    return ref($value) eq 'HASH' ? $value : {};
}

sub _presence_class {
    my ($value) = @_;
    return {
        present => _bool(defined $value),
        value_ref => ref($value) || undef,
    };
}

sub _array_of_scalars {
    my ($value) = @_;
    return [] unless ref($value) eq 'ARRAY';
    return [map { defined($_) && !ref($_) ? $_ : undef } @$value];
}

sub _first_defined {
    for my $value (@_) {
        return $value if defined $value;
    }
    return undef;
}

sub _bool {
    my ($value) = @_;
    return $value ? JSON::PP::true : JSON::PP::false;
}

1;
