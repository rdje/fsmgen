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

use FSM::Extension::Context;
use FSM::Pipeline::HDLGenerator;
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::ExtensionContract qw(
    build_extension_contract
    extension_contract_context_accessors
);

{
    package Test::ContextAccessorBoundaryRecorder;

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
        push @{$self->{parse_records}}, main::snapshot_context($context);
    }

    sub after_generate_result {
        my ($self, $context) = @_;
        push @{$self->{result_records}}, main::snapshot_context($context);
    }

    sub parse_records { return shift->{parse_records} }
    sub result_records { return shift->{result_records} }
}

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $tempdir = tempdir(CLEANUP => 1);
my $direct_path = File::Spec->catfile($tempdir, 'context_accessor_direct.fsm');
my $composition_path = File::Spec->catfile($tempdir, 'context_accessor_top.fsm');

write_direct_fixture($direct_path);
write_composition_fixture($composition_path);

subtest 'typed-extension manifests publish stable context accessor names' => sub {
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
            $contract->{stable_context_accessor_names},
            "$label marks context accessor names stable for this schema version",
        );
        is_deeply(
            sorted($contract->{context_accessors}),
            sorted(extension_contract_context_accessors()),
            "$label context_accessors match the builder-owned list",
        );
        is_deeply(
            sorted($contract->{name_family_map}{context_accessors}),
            sorted($contract->{context_accessors}),
            "$label grouped name_family_map republishes the same context accessor list",
        );
        assert_hook_accessor_subset(
            $contract,
            "$label hook-specific context accessors",
        );
        assert_list_excludes(
            $contract->{context_accessors},
            [qw(config diagnostics logger metadata trace_sink emit_report)],
            "$label advertised context accessors",
        );
    }
};

subtest 'Context implementation exposes exactly the advertised explicit accessors' => sub {
    my $implemented = context_sub_names_from_source();

    is_deeply(
        sorted($implemented),
        sorted(extension_contract_context_accessors()),
        'FSM::Extension::Context explicit accessor methods match the contract list',
    );
    can_ok('FSM::Extension::Context', @{extension_contract_context_accessors()});

    for my $extra (qw(config diagnostics logger metadata trace_sink emit_report)) {
        ok(
            !UNIVERSAL::can('FSM::Extension::Context', $extra),
            "FSM::Extension::Context does not expose unadvertised accessor $extra",
        );
    }
};

subtest 'live direct and composition hook contexts carry only the stable accessor surface' => sub {
    my $recorder = Test::ContextAccessorBoundaryRecorder->new();
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        strict_mode => 1,
        quiet => 1,
        extensions => [$recorder],
    );

    my $direct_result = $pipeline->generate_hdl_from_file($direct_path);
    is(
        $direct_result->{module_info}{module_name},
        'context_accessor_direct',
        'direct fixture generated successfully',
    );

    my $composition_result = $pipeline->generate_hdl_from_file($composition_path);
    is(
        $composition_result->{module_info}{module_name},
        'context_accessor_top',
        'composition fixture generated successfully',
    );

    is(scalar(@{$recorder->parse_records}), 2, 'parse hook captured one context per source kind');
    is(scalar(@{$recorder->result_records}), 2, 'result hook captured one context per source kind');

    assert_context_record(
        $recorder->parse_records->[0],
        {
            label => 'direct parse context',
            stage => 'after_parse_source',
            source_kind => 'fsm',
            module_name => undef,
            raw_ast_ref => 'ARRAY',
            result_ref => '',
            source_file => 'context_accessor_direct.fsm',
        },
    );
    assert_context_record(
        $recorder->result_records->[0],
        {
            label => 'direct result context',
            stage => 'after_generate_result',
            source_kind => 'fsm',
            module_name => 'context_accessor_direct',
            raw_ast_ref => '',
            result_ref => 'HASH',
            source_file => 'context_accessor_direct.fsm',
        },
    );
    assert_context_record(
        $recorder->parse_records->[1],
        {
            label => 'composition parse context',
            stage => 'after_parse_source',
            source_kind => 'composition',
            module_name => undef,
            raw_ast_ref => 'ARRAY',
            result_ref => '',
            source_file => 'context_accessor_top.fsm',
        },
    );
    assert_context_record(
        $recorder->result_records->[1],
        {
            label => 'composition result context',
            stage => 'after_generate_result',
            source_kind => 'composition',
            module_name => 'context_accessor_top',
            raw_ast_ref => '',
            result_ref => 'HASH',
            source_file => 'context_accessor_top.fsm',
        },
    );
};

done_testing();

sub snapshot_context {
    my ($context) = @_;

    my %snapshot = (
        accessor_names => extension_contract_context_accessors(),
    );
    for my $accessor (@{extension_contract_context_accessors()}) {
        my $value = $context->$accessor();
        $snapshot{$accessor} = summarize_context_value($accessor, $value);
    }

    return \%snapshot;
}

sub summarize_context_value {
    my ($accessor, $value) = @_;
    return {
        ref => ref($value) || '',
        value => $value,
    } if $accessor =~ /\A(?:stage|source_path|target_language)\z/;

    return {
        ref => ref($value) || '',
        class => ref($value) || '',
    } if $accessor eq 'pipeline';

    return {
        ref => ref($value) || '',
        kind => (ref($value) eq 'HASH' ? $value->{kind} : undef),
    } if $accessor eq 'source_info';

    return {
        ref => ref($value) || '',
    } if $accessor eq 'raw_ast';

    return {
        ref => ref($value) || '',
        module_name => (
            ref($value) eq 'HASH'
                ? $value->{module_info}{module_name}
                : undef
        ),
    } if $accessor eq 'result';

    die "Unexpected context accessor '$accessor'";
}

sub assert_context_record {
    my ($record, $expected) = @_;
    my $label = $expected->{label};

    is_deeply(
        sorted($record->{accessor_names}),
        sorted(extension_contract_context_accessors()),
        "$label records the advertised context accessor set",
    );
    is($record->{stage}{value}, $expected->{stage}, "$label carries stage");
    is($record->{pipeline}{class}, 'FSM::Pipeline::HDLGenerator', "$label carries pipeline object");
    like(
        $record->{source_path}{value},
        qr/\Q$expected->{source_file}\E\z/,
        "$label carries source path",
    );
    is($record->{target_language}{value}, 'systemverilog', "$label carries target language");
    is($record->{source_info}{kind}, $expected->{source_kind}, "$label carries source kind");
    is($record->{raw_ast}{ref}, $expected->{raw_ast_ref}, "$label raw_ast availability matches stage");
    is($record->{result}{ref}, $expected->{result_ref}, "$label result availability matches stage");
    is($record->{result}{module_name}, $expected->{module_name}, "$label result module name matches stage");
}

sub assert_hook_accessor_subset {
    my ($contract, $label) = @_;
    my %public = map { $_ => 1 } @{$contract->{context_accessors} || []};
    my $hooks = $contract->{hooks} || {};

    for my $hook_name (sort keys %{$hooks}) {
        for my $accessor (@{$hooks->{$hook_name}{context_accessors} || []}) {
            ok(
                $public{$accessor},
                "$label: $hook_name accessor $accessor is in the public context accessor list",
            );
        }
    }
}

sub assert_list_excludes {
    my ($values, $forbidden, $label) = @_;
    my %present = map { $_ => 1 } @{$values || []};

    for my $name (@{$forbidden || []}) {
        ok(!$present{$name}, "$label excludes $name");
    }
}

sub context_sub_names_from_source {
    my $path = File::Spec->catfile(
        $repo_root,
        qw(perl FSM Extension Context.pm),
    );
    open my $fh, '<', $path or die "Cannot open $path: $!";
    my $source = do { local $/; <$fh> };
    close $fh or die "Cannot close $path: $!";

    my @sub_names = grep { $_ ne 'new' } ($source =~ /^sub\s+([A-Za-z_][A-Za-z0-9_]*)\b/mg);
    return \@sub_names;
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

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}

sub write_direct_fixture {
    my ($path) = @_;
    write_file(
        $path,
        <<'FSM'
(?fsm:context_accessor_direct
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
(?top:context_accessor_top
  (?ports:public_io
    clk
    rst
    output_data>8
  )
  (?fsmc:child context_accessor_child)
)

(?fsm:context_accessor_child
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
