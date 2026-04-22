package FSM::Support::BackendValidationSection;

use strict;
use warnings;

use Exporter 'import';

use FSM::Support::BackendValidationContract qw(build_backend_validation_contract);
use FSM::Support::HDLExternalValidationContract qw(build_hdl_external_validation_contract);

our @EXPORT_OK = qw(
    build_manifest_systemverilog_external_surface
    build_backend_validation_section
);

sub build_backend_validation_section {
    return {
        systemverilog_external => build_manifest_systemverilog_external_surface(),
        section_contract => build_backend_validation_contract(),
    };
}

sub build_manifest_systemverilog_external_surface {
    return {
        %{build_hdl_external_validation_contract()},
        regression_smoke => 't/308-systemverilog-external-validation.t',
    };
}

1;
