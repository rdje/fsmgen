package FSM::Test::ProcessSupervisor;

use strict;
use warnings;

use Exporter qw(import);
use FSM::Support::ProcessSupervisor ();

our @EXPORT_OK = qw(
    process_failure
    repository_contained_path
    repository_root
    supervise_process
    validate_argument_vector
);

sub process_failure {
    return FSM::Support::ProcessSupervisor::process_failure(@_);
}

sub repository_contained_path {
    return FSM::Support::ProcessSupervisor::repository_contained_path(@_);
}

sub repository_root {
    return FSM::Support::ProcessSupervisor::repository_root(@_);
}

sub supervise_process {
    return FSM::Support::ProcessSupervisor::supervise_process(@_);
}

sub sealed_supervise_process {
    return FSM::Support::ProcessSupervisor::supervise_process(
        @_, private_job => 1,
    );
}

sub sealed_finished_job {
    return FSM::Support::ProcessSupervisor::sealed_finished_job(
        'FSM::Test::ProcessSupervisor', @_,
    );
}

sub validate_argument_vector {
    return FSM::Support::ProcessSupervisor::validate_argument_vector(@_);
}

1;
