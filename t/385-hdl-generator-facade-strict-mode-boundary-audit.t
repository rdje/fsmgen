#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;
use FSM::Support::HDLGeneratorFacadeContract qw(
    build_hdl_generator_facade_contract
    hdl_generator_facade_public_constructor_option_names
);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');

subtest 'facade contract advertises strict_mode as a public constructor option' => sub {
    my $contract = build_hdl_generator_facade_contract();

    ok(
        contains_value(
            $contract->{public_constructor_option_names},
            'strict_mode',
        ),
        'emitted facade contract includes strict_mode in public constructor options',
    );
    ok(
        contains_value(
            hdl_generator_facade_public_constructor_option_names(),
            'strict_mode',
        ),
        'builder-owned public constructor list includes strict_mode',
    );
    ok(
        contains_value(
            $contract->{constructor_option_family_map}{core_constructor_option_names},
            'strict_mode',
        ),
        'grouped core constructor family includes strict_mode',
    );
};

subtest 'facade strict_mode option enforces the strict assignment boundary at runtime' => sub {
    my $legacy_path = repo_file('t/corpus/legacy_infix_assignment.fsm');
    my $canonical_path = repo_file('t/corpus/direct_assignment_pair_form.fsm');

    my $default_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );
    my $compat_result = $default_pipeline->generate_hdl_from_file($legacy_path);

    is($compat_result->{source_info}{kind}, 'fsm', 'default facade still classifies the legacy fixture');
    like(
        $compat_result->{hdl_code},
        qr/\bmodule\s+legacy_infix_assignment\b/s,
        'default facade still compiles infix-assignment compatibility residue',
    );

    my $strict_pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
        strict_mode => 1,
    );
    my $strict_error = capture_exception(sub {
        $strict_pipeline->generate_hdl_from_file($legacy_path);
    });

    like(
        $strict_error,
        qr/Source file:\s+'\Q$legacy_path\E'/s,
        'strict facade failure keeps source-file context',
    );
    like(
        $strict_error,
        qr/Strict mode rejects infix assignment '\(OUT = SRC\)'/s,
        'strict facade rejects the first infix-assignment compatibility form',
    );
    like(
        $strict_error,
        qr/Use the canonical pair form '\(= \(OUT SRC\)\)'/s,
        'strict facade surfaces the canonical pair-form hint',
    );

    my $canonical_result = $strict_pipeline->generate_hdl_from_file($canonical_path);
    like(
        $canonical_result->{hdl_code},
        qr/\bmodule\s+direct_assignment_pair_form\b/s,
        'same strict facade object still accepts the canonical pair-form fixture',
    );
};

done_testing();

sub repo_file {
    my ($relpath) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relpath);
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
