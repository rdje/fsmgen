#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::ExtensionContract qw(build_extension_contract);
use FSM::Support::HDLGeneratorFacadeContract qw(build_hdl_generator_facade_contract);
use FSM::Support::ReportCommandContract qw(
    build_report_command_contract
    report_command_presence_keys
);

my $extension_module = 'FSM::BoundaryAudit::TraceExtension';
my $extension_marker = 'command-boundary-trace-extension';
my $test_env_key = 'FSMGEN_EXTENSION_TRACE_FILE';
my $tempdir = tempdir(CLEANUP => 1);
my $extension_lib = File::Spec->catdir($tempdir, 'lib');
my $source_path = File::Spec->catfile($tempdir, 'command_boundary.fsm');
my $config_path = File::Spec->catfile($tempdir, 'extensions.fsmext');

write_fixture($source_path);
write_trace_extension($extension_lib);
write_file($config_path, "module $extension_module\n");

subtest 'typed extension loading is advertised by typed_extensions, not the facade' => sub {
    my @views = (
        {
            label => 'direct contracts',
            typed_extensions => build_extension_contract(),
            facade => build_hdl_generator_facade_contract(),
        },
        {
            label => 'in-process capability manifest',
            typed_extensions => build_capability_manifest()->{embedding}{typed_extensions},
            facade => build_capability_manifest()->{embedding}{hdl_generator_facade},
        },
        {
            label => 'CLI capability manifest',
            typed_extensions => run_capability_manifest('--capability-manifest')->{embedding}{typed_extensions},
            facade => run_capability_manifest('--capability-manifest')->{embedding}{hdl_generator_facade},
        },
        {
            label => 'CLI alias capability manifest',
            typed_extensions => run_capability_manifest('--emit-capability-manifest')->{embedding}{typed_extensions},
            facade => run_capability_manifest('--emit-capability-manifest')->{embedding}{hdl_generator_facade},
        },
    );

    for my $view (@views) {
        assert_typed_extension_loading_entrypoints(
            $view->{typed_extensions},
            "$view->{label} typed extension contract",
        );
        assert_facade_excludes_module_and_config_loading(
            $view->{facade},
            "$view->{label} facade contract",
        );
    }
};

subtest 'semantic JSON command shell does not absorb extension-loading options' => sub {
    my $command_contract = build_report_command_contract();
    assert_command_contract_excludes_extension_loading(
        $command_contract,
        'direct report command contract',
    );

    for my $case (
        {
            label => 'module-loaded extension',
            options => ['--extension-module', $extension_module],
            forbidden_strings => [$extension_module, $extension_marker],
        },
        {
            label => 'config-loaded extension',
            options => ['--extension-config', $config_path],
            forbidden_strings => [$extension_module, $extension_marker, $config_path],
        },
    ) {
        my $trace_path = File::Spec->catfile($tempdir, "$case->{label}.trace");
        $trace_path =~ s/\s+/_/g;
        my $decoded = run_semantic_json_with_extension(
            $source_path,
            $case->{options},
            $trace_path,
        );

        assert_trace_file_records_hook(
            $trace_path,
            "$case->{label} semantic export",
        );
        assert_report_command_payload(
            $decoded->{command},
            "$case->{label} semantic JSON command",
        );
        ok(
            $decoded->{success},
            "$case->{label} semantic JSON succeeds",
        );
        ok(
            strict_json_encode_ok($decoded),
            "$case->{label} semantic JSON remains strict JSON-encodable",
        );
        is(
            scalar(@{$decoded->{diagnostics} || []}),
            0,
            "$case->{label} semantic JSON stays diagnostic-clean",
        );
        ok(
            !$decoded->{generated_output}{emitted},
            "$case->{label} semantic JSON does not emit HDL",
        );
        assert_no_extension_loading_leak(
            $decoded,
            "$case->{label} semantic JSON",
            $case->{forbidden_strings},
        );
    }
};

done_testing();

sub assert_typed_extension_loading_entrypoints {
    my ($contract, $label) = @_;
    my $entrypoints = $contract->{entrypoints} || {};

    like(
        $entrypoints->{programmatic_modules} || '',
        qr/extension_modules/s,
        "$label owns programmatic module loading",
    );
    like(
        $entrypoints->{programmatic_config_files} || '',
        qr/extension_config_files/s,
        "$label owns programmatic config-file loading",
    );
    like(
        $entrypoints->{cli_modules} || '',
        qr/--extension-module/s,
        "$label owns CLI module loading",
    );
    like(
        $entrypoints->{cli_config_files} || '',
        qr/--extension-config/s,
        "$label owns CLI config-file loading",
    );
    is(
        $contract->{extension_object_contract}{config_line_shape},
        'module Module::Name',
        "$label owns extension config line shape",
    );
}

sub assert_facade_excludes_module_and_config_loading {
    my ($contract, $label) = @_;

    my @facade_names = (
        @{$contract->{public_constructor_option_names} || []},
        @{$contract->{core_constructor_option_names} || []},
        @{$contract->{direct_extension_option_names} || []},
        flatten_family_map($contract->{constructor_option_family_map}),
    );

    assert_list_excludes(
        \@facade_names,
        [qw(extension_modules extension_config_files)],
        "$label constructor option families",
    );
    ok(
        !$contract->{object_injection_args_public},
        "$label keeps lower-level loading/injection args non-public",
    );
}

sub assert_command_contract_excludes_extension_loading {
    my ($contract, $label) = @_;

    is_deeply(
        $contract->{public_presence_keys},
        report_command_presence_keys(),
        "$label publishes the shared command presence keys",
    );
    assert_list_excludes(
        $contract->{public_presence_keys},
        [qw(extension_module extension_modules extension_config extension_config_files)],
        "$label public presence keys",
    );
}

sub assert_report_command_payload {
    my ($command, $label) = @_;

    ok(ref($command) eq 'HASH', "$label is a hash");
    return unless ref($command) eq 'HASH';

    is_deeply(
        [sort keys %$command],
        [sort @{report_command_presence_keys()}],
        "$label keeps only the report-command public keys",
    );
    is($command->{mode}, 'semantic_export', "$label records semantic export mode");
    ok($command->{json}, "$label records JSON emission");
    ok($command->{strict_mode}, "$label records strict mode");
    is($command->{target_language}, 'systemverilog', "$label records target language");
}

sub assert_no_extension_loading_leak {
    my ($payload, $label, $forbidden_strings) = @_;

    for my $key (qw(extension_marker extension_module extension_modules extension_config extension_config_files)) {
        ok(
            !contains_key_recursive($payload, $key),
            "$label does not expose key '$key'",
        );
    }

    for my $needle (@{$forbidden_strings || []}) {
        ok(
            !contains_string_recursive($payload, $needle),
            "$label does not expose '$needle'",
        );
    }
}

sub assert_trace_file_records_hook {
    my ($trace_path, $label) = @_;

    ok(-e $trace_path, "$label wrote an extension trace file");
    my $trace = slurp($trace_path);
    like(
        $trace,
        qr/after_generate_result\|fsm\|command_boundary/s,
        "$label actually ran the extension result hook",
    );
}

sub run_semantic_json_with_extension {
    my ($path, $extension_options, $trace_path) = @_;

    local $ENV{$test_env_key} = $trace_path;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => [
            $^X,
            '-I', $extension_lib,
            './bin/fsmgen',
            '--strict',
            '--emit-semantic-json',
            @{$extension_options || []},
            $path,
        ],
    );

    ok($success, "semantic JSON export succeeds for $path");
    is(join('', @{$stderr_buf || []}), '', "semantic JSON export keeps stderr clean for $path");

    return decode_json(join('', @{$stdout_buf || []}));
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

sub flatten_family_map {
    my ($family_map) = @_;
    my @values;
    return @values unless ref($family_map) eq 'HASH';

    for my $value (values %$family_map) {
        push @values, @$value
            if ref($value) eq 'ARRAY';
    }

    return @values;
}

sub assert_list_excludes {
    my ($values, $forbidden, $label) = @_;
    my %seen = map { $_ => 1 } @{$values || []};

    for my $name (@{$forbidden || []}) {
        ok(!$seen{$name}, "$label excludes $name");
    }
}

sub strict_json_encode_ok {
    my ($value) = @_;
    return eval {
        encode_json($value);
        1;
    } ? 1 : 0;
}

sub contains_key_recursive {
    my ($value, $target_key) = @_;
    return 0 unless ref($value);

    if (ref($value) eq 'HASH') {
        for my $key (keys %$value) {
            return 1 if $key eq $target_key;
            return 1 if contains_key_recursive($value->{$key}, $target_key);
        }
        return 0;
    }

    if (ref($value) eq 'ARRAY') {
        for my $child (@$value) {
            return 1 if contains_key_recursive($child, $target_key);
        }
        return 0;
    }

    return 0;
}

sub contains_string_recursive {
    my ($value, $needle) = @_;
    return 0 unless defined $value;

    if (!ref($value)) {
        return index($value, $needle) >= 0 ? 1 : 0;
    }

    if (ref($value) eq 'HASH') {
        for my $key (keys %$value) {
            return 1 if index($key, $needle) >= 0;
            return 1 if contains_string_recursive($value->{$key}, $needle);
        }
        return 0;
    }

    if (ref($value) eq 'ARRAY') {
        for my $child (@$value) {
            return 1 if contains_string_recursive($child, $needle);
        }
        return 0;
    }

    return 0;
}

sub write_fixture {
    my ($path) = @_;
    write_file(
        $path,
        <<'FSM'
(?fsm:command_boundary
  (+system
    (clock clk)
    (sreset reset)
  )
  (-state0
    (<= (OUT 1))
  )
  (+size
    (OUT 1)
  )
)
FSM
    );
}

sub write_trace_extension {
    my ($lib_root) = @_;
    my $module_dir = File::Spec->catdir($lib_root, qw(FSM BoundaryAudit));
    make_path($module_dir);

    my $module_path = File::Spec->catfile($module_dir, 'TraceExtension.pm');
    write_file(
        $module_path,
        <<"PERL"
package $extension_module;

use strict;
use warnings;

sub new {
    my (\$class) = \@_;
    return bless {}, \$class;
}

sub after_generate_result {
    my (\$self, \$context) = \@_;
    my \$trace_path = \$ENV{$test_env_key}
        or die '$test_env_key is required for the boundary audit extension';

    open my \$fh, '>>', \$trace_path
        or die "Cannot open \$trace_path for write: \$!";
    print {\$fh} join(
        '|',
        'after_generate_result',
        \$context->source_info->{kind},
        \$context->result->{module_info}{module_name},
    ), "\\n";
    close \$fh or die "Cannot close \$trace_path: \$!";

    \$context->result->{extension_marker} = {
        marker => '$extension_marker',
        module_name => '$extension_module',
    };
    \$context->result->{hdl_code} .= "\\n// $extension_marker\\n"
        if defined \$context->result->{hdl_code};
}

1;
PERL
    );
}

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $contents or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot open $path: $!";
    local $/ = undef;
    my $content = <$fh>;
    close $fh or die "Cannot close $path: $!";
    return $content;
}
