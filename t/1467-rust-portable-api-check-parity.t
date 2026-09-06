#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json);
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use lib File::Spec->catdir($FindBin::Bin, 'lib');
use FSM::Test::RustParityRuntime qw(run_rust_parity);

my $result = run_rust_parity();
ok($result->{ok}, 'bounded Rust parity stages succeed') or do {
    for my $stage (@{$result->{stages}}) {
        diag("$stage->{stage}: $stage->{status}: $stage->{diagnostic}");
        diag(substr($stage->{stderr}, 0, 4096)) if length $stage->{stderr};
    }
    done_testing();
    exit 1;
};
my %stage = map { $_->{stage} => $_ } @{$result->{stages}};
my $perl_oracle = stage_json($stage{perl_oracle});
my $rust_projection = stage_json($stage{rust_execution});

is_deeply(
    parity_projection($rust_projection),
    parity_projection($perl_oracle),
    'Rust direct .fsm check projection matches the normalized Perl oracle fields',
);

done_testing();

sub stage_json {
    my ($stage) = @_;
    my $decoded = eval { decode_json($stage->{stdout}) };
    ok(ref($decoded) eq 'HASH', "$stage->{stage} emits a JSON object")
        or do {
            diag($@) if $@;
            diag(substr($stage->{stdout}, 0, 4096));
            done_testing();
            exit 1;
        };

    return $decoded;
}

sub parity_projection {
    my ($decoded) = @_;

    return {
        check_schema_version => $decoded->{check_schema_version},
        success => json_bool($decoded->{success}),
        diagnostics => scalar @{$decoded->{diagnostics} || []},
        source => {
            input_leaf => source_leaf($decoded->{source}{input}),
        },
        result => {
            module_name => $decoded->{result}{module_name},
            state_count => $decoded->{result}{state_count},
            signal_count => $decoded->{result}{signal_count},
            composition_child_count => $decoded->{result}{composition_child_count},
        },
        generated_output => {
            emitted => json_bool($decoded->{generated_output}{emitted}),
        },
        support_accounting => {
            matched => json_bool($decoded->{support_accounting}{matched}),
            entry_id => $decoded->{support_accounting}{entry_id},
            family => $decoded->{support_accounting}{family},
            coverage => $decoded->{support_accounting}{coverage},
            classification => $decoded->{support_accounting}{classification},
            source_kind => $decoded->{support_accounting}{source_kind},
            strict_supported => json_bool($decoded->{support_accounting}{strict_supported}),
        },
    };
}

sub json_bool {
    my ($value) = @_;
    return $value ? 1 : 0;
}

sub source_leaf {
    my ($path) = @_;
    my (undef, undef, $file) = File::Spec->splitpath($path || '');
    return $file;
}
