#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::ExtensionContract qw(
    build_extension_contract
    extension_contract_supported_source_kinds
);

my $audit_test = 't/425-typed-extension-dt-source-kind-contract-audit.t';
my $tempdir = tempdir(CLEANUP => 1);

{
    package Test::TypedExtensionDTSourceKindRecorder;

    use strict;
    use warnings;

    sub new {
        return bless {
            parse_records => [],
            result_records => [],
        }, shift;
    }

    sub after_parse_source {
        my ($self, $context) = @_;
        push @{$self->{parse_records}}, {
            stage => $context->stage,
            source_kind => $context->source_info->{kind},
            raw_ast_ref => ref($context->raw_ast) || '',
            result_ref => ref($context->result) || '',
        };
    }

    sub after_generate_result {
        my ($self, $context) = @_;
        push @{$self->{result_records}}, {
            stage => $context->stage,
            source_kind => $context->source_info->{kind},
            raw_ast_ref => ref($context->raw_ast) || '',
            result_ref => ref($context->result) || '',
            module_name => $context->result->{module_info}{module_name},
        };
    }

    sub parse_records { return shift->{parse_records} }
    sub result_records { return shift->{result_records} }
}

subtest 'typed-extension manifests advertise dt as a bounded hook source kind' => sub {
    my @views = (
        {
            label => 'direct typed-extension contract',
            contract => build_extension_contract(),
        },
        {
            label => 'in-process capability manifest typed-extension contract',
            contract => build_capability_manifest()->{embedding}{typed_extensions},
        },
        {
            label => 'CLI capability manifest typed-extension contract',
            contract => run_capability_manifest('--capability-manifest')
                ->{embedding}{typed_extensions},
        },
        {
            label => 'CLI alias capability manifest typed-extension contract',
            contract => run_capability_manifest('--emit-capability-manifest')
                ->{embedding}{typed_extensions},
        },
    );

    for my $view (@views) {
        my $contract = $view->{contract};
        my $label = $view->{label};

        is_deeply(
            sorted($contract->{supported_source_kinds}),
            sorted(extension_contract_supported_source_kinds()),
            "$label source-kind list matches the builder-owned list",
        );
        ok(
            contains_value($contract->{supported_source_kinds}, 'dt'),
            "$label advertises dt as a typed-extension hook source kind",
        );
        ok(
            contains_value($contract->{name_family_map}{supported_source_kinds}, 'dt'),
            "$label grouped name_family_map includes dt",
        );
        ok(
            contains_value($contract->{tested_by}, $audit_test),
            "$label lists this dt source-kind audit in tested_by provenance",
        );
    }
};

subtest 'live dt roots dispatch parse and result contexts with source kind dt' => sub {
    my $dt_path = write_dt_fixture();
    my $recorder = Test::TypedExtensionDTSourceKindRecorder->new();
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        strict_mode => 1,
        quiet => 1,
        extensions => [$recorder],
    );

    my $result = $pipeline->generate_hdl_from_file($dt_path);
    is($result->{source_info}{kind}, 'dt', 'pipeline preserves dt source kind');
    is($result->{module_info}{module_name}, 'typed_extension_dt_source_kind', 'dt root generated successfully');

    is_deeply(
        $recorder->parse_records,
        [
            {
                stage => 'after_parse_source',
                source_kind => 'dt',
                raw_ast_ref => 'ARRAY',
                result_ref => '',
            },
        ],
        'parse hook receives a dt context with raw_ast and no result',
    );
    is_deeply(
        $recorder->result_records,
        [
            {
                stage => 'after_generate_result',
                source_kind => 'dt',
                raw_ast_ref => '',
                result_ref => 'HASH',
                module_name => 'typed_extension_dt_source_kind',
            },
        ],
        'result hook receives a dt context with result and no raw_ast',
    );
};

done_testing();

sub write_dt_fixture {
    my $path = File::Spec->catfile($tempdir, 'typed_extension_dt_source_kind.fsm');
    write_file($path, <<'FSM');
(?dt:typed_extension_dt_source_kind
  (+size
    (DATA_IN 8)
    (DATA_OUT 8)
  )
  (-route
    (= (DATA_OUT DATA_IN))
  )
)
FSM
    return $path;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

sub run_capability_manifest {
    my ($mode) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', $mode],
    );

    ok($success, "$mode succeeds");
    is(join('', @{$stderr_buf || []}), '', "$mode keeps stderr clean");

    return decode_json(join('', @{$stdout_buf || []}));
}

sub contains_value {
    my ($values, $wanted) = @_;
    return 0 unless ref($values) eq 'ARRAY';

    for my $value (@{$values}) {
        return 1 if defined($value) && $value eq $wanted;
    }

    return 0;
}

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}
