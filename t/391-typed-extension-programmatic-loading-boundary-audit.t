#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::ExtensionContract qw(build_extension_contract);
use FSM::Support::HDLGeneratorFacadeContract qw(build_hdl_generator_facade_contract);

my $extension_module = 'FSM::BoundaryAudit::ProgrammaticLoaderProbe';
my $tempdir = tempdir(CLEANUP => 1);
my $extension_lib = File::Spec->catdir($tempdir, 'lib');
my $source_path = File::Spec->catfile($tempdir, 'programmatic_loader_root.fsm');
my $config_path = File::Spec->catfile($tempdir, 'extensions.fsmext');

write_extension_module($extension_lib);
write_direct_fixture($source_path);
write_file($config_path, "module $extension_module\n");

unshift @INC, $extension_lib;

subtest 'typed extension contract owns programmatic module and config loading' => sub {
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
        assert_facade_excludes_programmatic_loader_args(
            $view->{facade},
            "$view->{label} facade contract",
        );
    }
};

subtest 'programmatic extension_modules loading dispatches typed hooks in-process' => sub {
    my $result = run_pipeline(
        extension_modules => [$extension_module],
    );

    assert_loader_result(
        $result,
        'extension_modules',
    );

    my $plain_result = run_pipeline();
    ok(
        !exists $plain_result->{programmatic_loader_audit_markers},
        'a facade object without programmatic module loading receives no loader marker',
    );
};

subtest 'programmatic extension_config_files loading dispatches typed hooks in-process' => sub {
    my $result = run_pipeline(
        extension_config_files => [$config_path],
    );

    assert_loader_result(
        $result,
        'extension_config_files',
    );
};

done_testing();

sub assert_typed_extension_loading_entrypoints {
    my ($contract, $label) = @_;
    my $entrypoints = $contract->{entrypoints} || {};

    like(
        $entrypoints->{programmatic_modules} || '',
        qr/extension_modules/s,
        "$label advertises programmatic module-name loading",
    );
    like(
        $entrypoints->{programmatic_config_files} || '',
        qr/extension_config_files/s,
        "$label advertises programmatic config-file loading",
    );
    is(
        $contract->{extension_object_contract}{config_line_shape},
        'module Module::Name',
        "$label advertises the config-file line shape",
    );
}

sub assert_facade_excludes_programmatic_loader_args {
    my ($contract, $label) = @_;

    my @facade_names = (
        @{$contract->{public_constructor_option_names} || []},
        @{$contract->{core_constructor_option_names} || []},
        @{$contract->{compatibility_constructor_option_names} || []},
        @{$contract->{direct_extension_option_names} || []},
        flatten_family_map($contract->{constructor_option_family_map}),
    );

    assert_list_excludes(
        \@facade_names,
        [qw(extension_modules extension_config_files)],
        "$label constructor option families",
    );
}

sub assert_loader_result {
    my ($result, $label) = @_;

    is(
        $result->{module_info}{module_name},
        'programmatic_loader_root',
        "$label still returns the generated module result",
    );
    like(
        $result->{hdl_code},
        qr/\bmodule\s+programmatic_loader_root\b/s,
        "$label still returns generated HDL",
    );

    my $markers = $result->{programmatic_loader_audit_markers};
    is(ref($markers), 'ARRAY', "$label returns loader audit markers");
    is(scalar(@{$markers || []}), 1, "$label runs one loaded extension object");

    my $marker = $markers->[0] || {};
    is($marker->{module_name}, $extension_module, "$label marker names the loaded module");
    is($marker->{parse_source_kind}, 'fsm', "$label parse hook sees fsm source kind");
    is($marker->{result_source_kind}, 'fsm', "$label result hook sees fsm source kind");
    is($marker->{target_language}, 'systemverilog', "$label hook context sees target language");
    is_deeply(
        $marker->{stages},
        [qw(after_parse_source after_generate_result)],
        "$label dispatches parse and result hooks in order",
    );
}

sub run_pipeline {
    my (%extra_args) = @_;
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        strict_mode => 1,
        quiet => 1,
        %extra_args,
    );

    return $pipeline->generate_hdl_from_file($source_path);
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

sub flatten_family_map {
    my ($map) = @_;
    return () unless ref($map) eq 'HASH';

    my @values;
    for my $family (sort keys %{$map}) {
        push @values, @{$map->{$family} || []};
    }

    return @values;
}

sub write_extension_module {
    my ($lib_root) = @_;
    my $module_dir = File::Spec->catdir($lib_root, qw(FSM BoundaryAudit));
    my $module_path = File::Spec->catfile($module_dir, 'ProgrammaticLoaderProbe.pm');

    make_path($module_dir);
    write_file(
        $module_path,
        <<'PERL'
package FSM::BoundaryAudit::ProgrammaticLoaderProbe;

use strict;
use warnings;

sub new {
    my ($class) = @_;
    return bless {
        stages => [],
    }, $class;
}

sub after_parse_source {
    my ($self, $context) = @_;
    push @{$self->{stages}}, $context->stage;
    $self->{parse_source_kind} = $context->source_info->{kind};
}

sub after_generate_result {
    my ($self, $context) = @_;
    push @{$self->{stages}}, $context->stage;
    push @{$context->result->{programmatic_loader_audit_markers}}, {
        module_name => __PACKAGE__,
        parse_source_kind => $self->{parse_source_kind},
        result_source_kind => $context->source_info->{kind},
        target_language => $context->target_language,
        stages => [@{$self->{stages}}],
    };
}

1;
PERL
    );
}

sub write_direct_fixture {
    my ($path) = @_;
    write_file(
        $path,
        <<'FSM'
(?fsm:programmatic_loader_root
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

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $contents or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
