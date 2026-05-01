#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::HDLGeneratorFacadeContract qw(build_hdl_generator_facade_contract);

subtest 'manifests advertise source_search_paths as a list-shaped public facade option' => sub {
    my @views = (
        {
            label => 'direct facade contract',
            facade => build_hdl_generator_facade_contract(),
        },
        {
            label => 'in-process capability manifest',
            facade => build_capability_manifest()->{embedding}{hdl_generator_facade},
        },
        {
            label => 'CLI capability manifest',
            facade => run_capability_manifest('--capability-manifest')
                ->{embedding}{hdl_generator_facade},
        },
        {
            label => 'CLI alias capability manifest',
            facade => run_capability_manifest('--emit-capability-manifest')
                ->{embedding}{hdl_generator_facade},
        },
    );

    for my $view (@views) {
        my $facade = $view->{facade};
        my $label = $view->{label};

        ok(
            contains_value($facade->{public_constructor_option_names}, 'source_search_paths'),
            "$label advertises source_search_paths as public",
        );
        ok(
            contains_value(
                $facade->{constructor_option_family_map}{core_constructor_option_names},
                'source_search_paths',
            ),
            "$label groups source_search_paths with core constructor options",
        );
        is(
            $facade->{constructor_option_shape_map}{source_search_paths},
            'array reference of filesystem search roots',
            "$label advertises the source_search_paths array-ref shape",
        );
    }
};

subtest 'HDLGenerator rejects scalar source_search_paths before SourcePathResolver dereference' => sub {
    my $error = capture_exception(sub {
        FSM::Pipeline::HDLGenerator->new(
            debug_level => 0,
            target_language => 'systemverilog',
            quiet => 1,
            source_search_paths => 't/corpus',
        );
    });

    like(
        $error,
        qr/FSM::Pipeline::HDLGenerator expects 'source_search_paths' to be an array reference/s,
        'scalar source_search_paths receives a targeted facade constructor diagnostic',
    );
    unlike(
        $error,
        qr/Can't use .* as an ARRAY ref|strict refs/s,
        'scalar source_search_paths does not leak raw Perl dereference fallout',
    );
};

subtest 'HDLGenerator rejects hashref source_search_paths before SourcePathResolver dereference' => sub {
    my $error = capture_exception(sub {
        FSM::Pipeline::HDLGenerator->new(
            debug_level => 0,
            target_language => 'systemverilog',
            quiet => 1,
            source_search_paths => { root => 't/corpus' },
        );
    });

    like(
        $error,
        qr/FSM::Pipeline::HDLGenerator expects 'source_search_paths' to be an array reference/s,
        'hashref source_search_paths receives a targeted facade constructor diagnostic',
    );
    unlike(
        $error,
        qr/Can't use .* as an ARRAY ref|strict refs/s,
        'hashref source_search_paths does not leak raw Perl dereference fallout',
    );
};

subtest 'HDLGenerator still accepts array-ref source_search_paths' => sub {
    my $pipeline = eval {
        FSM::Pipeline::HDLGenerator->new(
            debug_level => 0,
            target_language => 'systemverilog',
            quiet => 1,
            source_search_paths => ['t/corpus'],
        );
    };
    my $error = $@;

    ok($pipeline, 'array-ref source_search_paths constructs a facade object')
        or diag($error);
    isa_ok($pipeline, 'FSM::Pipeline::HDLGenerator');
};

done_testing();

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

sub capture_exception {
    my ($code) = @_;
    my $ok = eval {
        $code->();
        1;
    };

    return '' if $ok;
    return $@ || 'unknown error';
}
