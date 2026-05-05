package FSM::Test::DefensiveCopyAudit;

use strict;
use warnings;

use Exporter 'import';
use Test::More ();

our @EXPORT_OK = qw(
    assert_contract_module_defensive_copies
    contains_sentinel
    mutate_structure
);

sub assert_contract_module_defensive_copies {
    my (%args) = @_;
    my $module = $args{module} || die 'module is required';
    my $sentinel = $args{sentinel} || '__fsmgen_defensive_copy_audit__';

    eval "require $module; 1" or die $@;

    no strict 'refs';
    my @exports = @{"${module}::EXPORT_OK"};
    use strict 'refs';

    my @builders = grep { /^build_.*_contract$/ } @exports;
    Test::More::is(scalar(@builders), 1, "$module exports exactly one build_*_contract helper");
    return unless @builders == 1;

    my $builder_name = $builders[0];
    no strict 'refs';
    my $builder = \&{"${module}::$builder_name"};
    use strict 'refs';

    Test::More::subtest "$module contract builder returns fresh nested structures" => sub {
        my $first = $builder->();
        mutate_structure($first, $sentinel);

        my $second = $builder->();
        Test::More::ok(!contains_sentinel($second, $sentinel), 'fresh contract is not affected by prior caller mutation');
    };

    my @helper_names = grep {
        $_ ne $builder_name && $_ !~ /_contract_source\z/
    } @exports;

    Test::More::subtest "$module helper builders return fresh nested structures" => sub {
        Test::More::ok(@helper_names, "$module exports helper builders to audit");

        for my $helper_name (@helper_names) {
            no strict 'refs';
            my $helper = \&{"${module}::$helper_name"};
            use strict 'refs';

            my $first = $helper->();
            Test::More::ok(ref($first), "$helper_name returns a mutable structure");
            next unless ref($first);

            mutate_structure($first, $sentinel);

            my $second = $helper->();
            Test::More::ok(!contains_sentinel($second, $sentinel), "$helper_name returns fresh nested structures");
        }
    };
}

sub mutate_structure {
    my ($value, $sentinel) = @_;
    return unless ref($value);

    if (ref($value) eq 'ARRAY') {
        push @{$value}, $sentinel;
        mutate_structure($_, $sentinel) for @{$value};
        return;
    }

    if (ref($value) eq 'HASH') {
        $value->{$sentinel} = $sentinel;
        mutate_structure($_, $sentinel) for values %{$value};
        return;
    }

    return;
}

sub contains_sentinel {
    my ($value, $sentinel) = @_;
    return 1 if defined($value) && !ref($value) && $value eq $sentinel;
    return 0 unless ref($value);

    if (ref($value) eq 'ARRAY') {
        for my $entry (@{$value}) {
            return 1 if contains_sentinel($entry, $sentinel);
        }
        return 0;
    }

    if (ref($value) eq 'HASH') {
        return 1 if exists($value->{$sentinel});
        for my $entry (values %{$value}) {
            return 1 if contains_sentinel($entry, $sentinel);
        }
        return 0;
    }

    return 0;
}

1;
