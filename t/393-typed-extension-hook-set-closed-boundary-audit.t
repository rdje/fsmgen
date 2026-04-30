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
    extension_contract_hook_names
);

{
    package Test::ClosedHookSetExtension;

    use strict;
    use warnings;

    sub new {
        return bless {
            expected_calls => [],
            unexpected_calls => [],
        }, shift;
    }

    sub after_parse_source {
        my ($self, $context) = @_;
        push @{$self->{expected_calls}}, {
            stage => $context->stage,
            source_kind => $context->source_info->{kind},
            result_available => $context->result ? 1 : 0,
        };
    }

    sub after_generate_result {
        my ($self, $context) = @_;
        push @{$self->{expected_calls}}, {
            stage => $context->stage,
            source_kind => $context->source_info->{kind},
            result_available => $context->result ? 1 : 0,
        };
        $context->result->{closed_hook_set_markers} = [@{$self->{expected_calls}}];
    }

    sub before_parse_source { return shift->_unexpected_hook('before_parse_source') }
    sub parse_source { return shift->_unexpected_hook('parse_source') }
    sub before_generate_result { return shift->_unexpected_hook('before_generate_result') }
    sub after_emit_hdl { return shift->_unexpected_hook('after_emit_hdl') }
    sub on_result { return shift->_unexpected_hook('on_result') }

    sub expected_calls { return shift->{expected_calls} }
    sub unexpected_calls { return shift->{unexpected_calls} }

    sub _unexpected_hook {
        my ($self, $hook_name) = @_;
        push @{$self->{unexpected_calls}}, $hook_name;
        die "Unexpected closed hook-set dispatch for $hook_name";
    }
}

my $tempdir = tempdir(CLEANUP => 1);
my $direct_path = File::Spec->catfile($tempdir, 'closed_hook_set_direct.fsm');
my $composition_path = File::Spec->catfile($tempdir, 'closed_hook_set_top.fsm');

write_direct_fixture($direct_path);
write_composition_fixture($composition_path);

subtest 'typed-extension manifests publish a closed hook set for this schema version' => sub {
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
            contract => run_capability_manifest('--capability-manifest')->{embedding}{typed_extensions},
        },
        {
            label => 'CLI alias capability manifest typed-extension contract',
            contract => run_capability_manifest('--emit-capability-manifest')->{embedding}{typed_extensions},
        },
    );

    for my $view (@views) {
        my $contract = $view->{contract};
        my $label = $view->{label};

        ok(
            $contract->{hook_set_closed_for_schema_version},
            "$label marks the hook set closed for schema version 1",
        );
        is_deeply(
            sorted($contract->{hook_names}),
            sorted(extension_contract_hook_names()),
            "$label hook_names match the builder-owned hook list",
        );
        is_deeply(
            sorted([keys %{$contract->{hooks} || {}}]),
            sorted($contract->{hook_names}),
            "$label detailed hook map has no extra hook names",
        );
        assert_list_excludes(
            $contract->{hook_names},
            [qw(before_parse_source parse_source before_generate_result after_emit_hdl on_result)],
            "$label advertised hook names",
        );
    }
};

subtest 'direct generation dispatches only the advertised hook names' => sub {
    my $extension = Test::ClosedHookSetExtension->new();
    my $result = run_pipeline(
        source_path => $direct_path,
        extension => $extension,
    );

    is(
        $result->{module_info}{module_name},
        'closed_hook_set_direct',
        'direct generation still succeeds with extra hook-shaped methods present',
    );
    is_deeply(
        $result->{closed_hook_set_markers},
        [
            {
                stage => 'after_parse_source',
                source_kind => 'fsm',
                result_available => 0,
            },
            {
                stage => 'after_generate_result',
                source_kind => 'fsm',
                result_available => 1,
            },
        ],
        'direct generation dispatches exactly the two advertised hook stages',
    );
    is_deeply(
        $extension->unexpected_calls,
        [],
        'direct generation ignores extra hook-shaped methods',
    );
};

subtest 'composition generation dispatches only the advertised hook names' => sub {
    my $extension = Test::ClosedHookSetExtension->new();
    my $result = run_pipeline(
        source_path => $composition_path,
        extension => $extension,
    );

    is(
        $result->{module_info}{module_name},
        'closed_hook_set_top',
        'composition generation still succeeds with extra hook-shaped methods present',
    );
    is_deeply(
        $result->{closed_hook_set_markers},
        [
            {
                stage => 'after_parse_source',
                source_kind => 'composition',
                result_available => 0,
            },
            {
                stage => 'after_generate_result',
                source_kind => 'composition',
                result_available => 1,
            },
        ],
        'composition generation dispatches exactly the two advertised hook stages',
    );
    is_deeply(
        $extension->unexpected_calls,
        [],
        'composition generation ignores extra hook-shaped methods',
    );
};

done_testing();

sub run_pipeline {
    my (%args) = @_;
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        strict_mode => 1,
        quiet => 1,
        extensions => [$args{extension}],
    );

    return $pipeline->generate_hdl_from_file($args{source_path});
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

sub assert_list_excludes {
    my ($values, $forbidden, $label) = @_;
    my %present = map { $_ => 1 } @{$values || []};

    for my $name (@{$forbidden || []}) {
        ok(!$present{$name}, "$label excludes $name");
    }
}

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}

sub write_direct_fixture {
    my ($path) = @_;
    write_file(
        $path,
        <<'FSM'
(?fsm:closed_hook_set_direct
  (+system
    (clock clk)
    (sreset rst)
  )
  (+size
    (OUT 1)
  )
  (idle
    (= (OUT 1))
  )
)
FSM
    );
}

sub write_composition_fixture {
    my ($path) = @_;
    write_file(
        $path,
        <<'FSM'
(?top:closed_hook_set_top
  (?ports:public_io
    clk
    rst
    output_data>8
  )
  (?fsmc:child closed_hook_set_child)
)

(?fsm:closed_hook_set_child
  (+system
    (clock clk)
    (sreset rst)
  )
  (+size
    (output_data 8)
  )
  (idle
    (<= (output_data> 8'1))
  )
)
FSM
    );
}

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $contents or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
