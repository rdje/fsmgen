#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;
use FSM::Support::ExtensionContract qw(build_extension_contract);
use FSM::Support::HDLGeneratorFacadeContract qw(
    build_hdl_generator_facade_contract
    hdl_generator_facade_public_constructor_option_names
);

{
    package Test::FacadeExtensionBoundaryRecorder;

    use strict;
    use warnings;

    sub new {
        my ($class, $label) = @_;
        return bless {
            label => $label,
            parse_calls => [],
            result_calls => [],
        }, $class;
    }

    sub after_parse_source {
        my ($self, $context) = @_;
        push @{$self->{parse_calls}}, {
            label => $self->{label},
            stage => $context->stage,
            source_kind => $context->source_info->{kind},
            target_language => $context->target_language,
            source_path => $context->source_path,
        };
    }

    sub after_generate_result {
        my ($self, $context) = @_;
        push @{$self->{result_calls}}, {
            label => $self->{label},
            stage => $context->stage,
            source_kind => $context->source_info->{kind},
            target_language => $context->target_language,
            module_name => $context->result->{module_info}{module_name},
        };

        push @{$context->result->{facade_extension_audit_markers}}, {
            label => $self->{label},
            call_index => scalar(@{$self->{result_calls}}),
            target_language => $context->target_language,
            module_name => $context->result->{module_info}{module_name},
        };
    }

    sub parse_calls { return shift->{parse_calls} }
    sub result_calls { return shift->{result_calls} }
}

subtest 'facade contract advertises direct extension-object injection as public' => sub {
    my $facade_contract = build_hdl_generator_facade_contract();
    my $extension_contract = build_extension_contract();

    ok(
        contains_value(
            $facade_contract->{public_constructor_option_names},
            'extensions',
        ),
        'emitted facade contract includes extensions in public constructor options',
    );
    ok(
        contains_value(
            hdl_generator_facade_public_constructor_option_names(),
            'extensions',
        ),
        'builder-owned public constructor list includes extensions',
    );
    ok(
        contains_value(
            $facade_contract->{constructor_option_family_map}{direct_extension_option_names},
            'extensions',
        ),
        'grouped direct-extension constructor family includes extensions',
    );
    ok(
        $extension_contract->{extension_object_contract}{must_be_blessed_object},
        'typed-extension contract says direct extension objects must be blessed',
    );
    ok(
        $extension_contract->{extension_object_contract}{must_provide_supported_hook_method},
        'typed-extension contract says direct extension objects must expose a supported hook method',
    );
};

subtest 'facade extensions option rejects non-blessed constructor values' => sub {
    my ($ok, $error) = eval_new_pipeline(
        extensions => ['FSM::NotAnObject'],
    );

    ok(!$ok, 'constructor rejects a non-blessed extension value');
    like(
        $error,
        qr/accepts only blessed extension objects/s,
        'constructor failure names the blessed-object boundary',
    );
};

subtest 'facade extensions option dispatches injected objects in order' => sub {
    my $source_path = make_direct_fixture();
    my $first = Test::FacadeExtensionBoundaryRecorder->new('first');
    my $second = Test::FacadeExtensionBoundaryRecorder->new('second');

    my $pipeline = new_pipeline(
        extensions => [$first, $second],
    );
    my $result = $pipeline->generate_hdl_from_file($source_path);

    is_deeply(
        marker_labels($result),
        [qw(first second)],
        'result hook mutations preserve direct extension-object dispatch order',
    );
    is(scalar(@{$first->parse_calls}), 1, 'first extension parse hook ran once');
    is(scalar(@{$second->parse_calls}), 1, 'second extension parse hook ran once');
    is(scalar(@{$first->result_calls}), 1, 'first extension result hook ran once');
    is(scalar(@{$second->result_calls}), 1, 'second extension result hook ran once');
    is(
        $first->parse_calls->[0]{stage},
        'after_parse_source',
        'parse hook receives the advertised parse stage',
    );
    is(
        $second->result_calls->[0]{stage},
        'after_generate_result',
        'result hook receives the advertised result stage',
    );
    is(
        $result->{module_info}{module_name},
        'facade_extension_object_root',
        'generation still returns the expected direct module result',
    );
};

subtest 'facade extensions option stays scoped to each facade object' => sub {
    my $source_path = make_direct_fixture();
    my $systemverilog_extension = Test::FacadeExtensionBoundaryRecorder->new('systemverilog_only');
    my $verilog_extension = Test::FacadeExtensionBoundaryRecorder->new('verilog_only');

    my $systemverilog_result = new_pipeline(
        target_language => 'systemverilog',
        extensions => [$systemverilog_extension],
    )->generate_hdl_from_file($source_path);

    is_deeply(
        marker_labels($systemverilog_result),
        ['systemverilog_only'],
        'first facade object returns only its own extension marker',
    );
    is(
        $systemverilog_extension->result_calls->[0]{target_language},
        'systemverilog',
        'first extension context receives the first facade target language',
    );
    is(
        scalar(@{$verilog_extension->result_calls}),
        0,
        'extension not injected into the first facade object does not run there',
    );

    my $verilog_result = new_pipeline(
        target_language => 'verilog',
        extensions => [$verilog_extension],
    )->generate_hdl_from_file($source_path);

    is_deeply(
        marker_labels($verilog_result),
        ['verilog_only'],
        'second facade object returns only its own extension marker',
    );
    is(
        $verilog_extension->result_calls->[0]{target_language},
        'verilog',
        'second extension context receives the second facade target language',
    );
    is(
        scalar(@{$systemverilog_extension->result_calls}),
        1,
        'first facade extension object is not called again by the second facade object',
    );
};

done_testing();

sub make_direct_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $source_path = File::Spec->catfile($tempdir, 'facade_extension_object_root.fsm');

    write_file(
        $source_path,
        <<'FSM'
(?fsm:facade_extension_object_root
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

    return $source_path;
}

sub eval_new_pipeline {
    my (%extra_args) = @_;
    my $pipeline;
    my $ok = eval {
        $pipeline = new_pipeline(%extra_args);
        1;
    };
    my $error = $@ unless $ok;

    return ($ok, $error, $pipeline);
}

sub new_pipeline {
    my (%extra_args) = @_;
    my %args = (
        debug_level => 0,
        target_language => 'systemverilog',
        strict_mode => 1,
        quiet => 1,
    );
    $args{$_} = $extra_args{$_} for keys %extra_args;

    return FSM::Pipeline::HDLGenerator->new(%args);
}

sub marker_labels {
    my ($result) = @_;
    my @labels = map { $_->{label} } @{$result->{facade_extension_audit_markers} || []};
    return \@labels;
}

sub contains_value {
    my ($values, $wanted) = @_;
    return 0 unless ref($values) eq 'ARRAY';

    for my $value (@{$values}) {
        return 1 if defined($value) && $value eq $wanted;
    }

    return 0;
}

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $contents or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
