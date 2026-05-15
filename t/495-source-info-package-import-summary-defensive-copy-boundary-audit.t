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
use FSM::Pipeline::SourceFrontend;
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::HDLGeneratorResultContract qw(build_hdl_generator_result_contract);
use FSM::Support::HDLGeneratorSourceInfoContract qw(build_hdl_generator_source_info_contract);
use Lispish;

my $audit_test = 't/495-source-info-package-import-summary-defensive-copy-boundary-audit.t';
my $copy_policy = 'package_import_names is a fresh caller-owned array on each returned source_info object';

subtest 'source_info contracts publish the package-import summary copy policy' => sub {
    my @views = (
        {
            label => 'direct source_info contract',
            policy => build_hdl_generator_source_info_contract()->{package_import_summary_copy_policy},
        },
        {
            label => 'direct HDLGenerator result contract',
            policy => build_hdl_generator_result_contract()->{source_info_package_import_summary_copy_policy},
        },
        {
            label => 'in-process capability manifest HDLGenerator result contract',
            policy => build_capability_manifest()->{embedding}{hdl_generator_result}{source_info_package_import_summary_copy_policy},
        },
        {
            label => 'CLI capability manifest HDLGenerator result contract',
            policy => run_capability_manifest('--capability-manifest')
                ->{embedding}{hdl_generator_result}{source_info_package_import_summary_copy_policy},
        },
        {
            label => 'CLI alias capability manifest HDLGenerator result contract',
            policy => run_capability_manifest('--emit-capability-manifest')
                ->{embedding}{hdl_generator_result}{source_info_package_import_summary_copy_policy},
        },
    );

    for my $view (@views) {
        is($view->{policy}, $copy_policy, "$view->{label} advertises the copy policy");
    }

    ok(
        contains_value(build_hdl_generator_result_contract()->{tested_by}, $audit_test),
        'HDLGenerator result contract lists this source_info copy audit in tested_by provenance',
    );
};

subtest 'source frontend classification returns fresh package-import summary arrays' => sub {
    my $direct_raw_ast = direct_raw_ast();
    my $composition_raw_ast = composition_raw_ast();

    for my $case (
        {
            label => 'direct root',
            raw_ast => $direct_raw_ast,
        },
        {
            label => 'composition root',
            raw_ast => $composition_raw_ast,
        },
    ) {
        my $first = FSM::Pipeline::SourceFrontend->classify_source_ast($case->{raw_ast});
        push @{$first->{package_import_names}}, 'mutated_after_classification';
        $first->{package_import_count} = 99;

        my $second = FSM::Pipeline::SourceFrontend->classify_source_ast($case->{raw_ast});
        is_deeply(
            package_import_summary($second),
            {
                package_import_count => 2,
                package_import_names => [qw(shared_local shared_external)],
            },
            "$case->{label} classification returns a fresh package-import summary",
        );
    }
};

subtest 'HDLGenerator results return fresh source_info package-import summaries across calls' => sub {
    my ($direct_path, $composition_path, $libdir) = write_package_import_fixtures();

    for my $case (
        {
            label => 'direct result',
            path => $direct_path,
        },
        {
            label => 'composition result',
            path => $composition_path,
        },
    ) {
        my $pipeline = FSM::Pipeline::HDLGenerator->new(
            debug_level => 0,
            target_language => 'systemverilog',
            strict_mode => 1,
            quiet => 1,
            source_search_paths => [$libdir],
        );

        my $first = $pipeline->generate_hdl_from_file($case->{path});
        push @{$first->{source_info}{package_import_names}}, 'mutated_after_generation';
        $first->{source_info}{package_import_count} = 99;

        my $second = $pipeline->generate_hdl_from_file($case->{path});
        is_deeply(
            package_import_summary($second->{source_info}),
            {
                package_import_count => 2,
                package_import_names => [qw(shared_local shared_external)],
            },
            "$case->{label} returns a fresh source_info package-import summary",
        );
    }
};

done_testing();

sub direct_raw_ast {
    my $source = direct_source();
    return Lispish::multi(\$source);
}

sub direct_source {
    return <<'FSM';
(?fsm:source_info_direct_imports
  (+import shared_local shared_external)
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (OUT 8)
  )
  (idle
    (= (OUT shared_external.RESET_BYTE))
  )
)

(?pkg:shared_local
  (+constants
    (BUSY 1)
  )
)
FSM
}

sub composition_raw_ast {
    my $source = composition_source();
    return Lispish::multi(\$source);
}

sub composition_source {
    return <<'FSM';
(?top:source_info_composition_imports
  (+import shared_local shared_external)
  (?ports:public_io
    shared_out>8
  )
  (?rtl:uart_tx)
  (?wiring:wiring
    /=shared_external.RESET_BYTE/shared_out/
    /=shared_local.mode.BUSY/uart_tx.enable/
  )
)

(?pkg:shared_local
  (+enums
    (mode
      (IDLE 0)
      (BUSY 1)
    )
  )
)

(?rtlif:uart_tx
  enable<1:data
)
FSM
}

sub write_package_import_fixtures {
    my $tempdir = tempdir(CLEANUP => 1);
    my $libdir = File::Spec->catdir($tempdir, 'pkg_lib');
    mkdir $libdir or die "Cannot create $libdir: $!";

    my $package_path = File::Spec->catfile($libdir, 'shared_external.fsm');
    my $direct_path = File::Spec->catfile($tempdir, 'source_info_direct_imports.fsm');
    my $composition_path = File::Spec->catfile($tempdir, 'source_info_composition_imports.fsm');

    write_file(
        $package_path,
        <<'FSM'
(?pkg:shared_external
  (+constants
    (RESET_BYTE 8'hA5)
  )
)
FSM
    );
    write_file($direct_path, direct_source());
    write_file($composition_path, composition_source());

    return ($direct_path, $composition_path, $libdir);
}

sub package_import_summary {
    my ($source_info) = @_;
    return {
        package_import_count => $source_info->{package_import_count},
        package_import_names => $source_info->{package_import_names},
    };
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
        return 1 if defined($value) && !ref($value) && $value eq $wanted;
    }

    return 0;
}

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "Cannot open $path: $!";
    print {$fh} $contents;
    close $fh or die "Cannot close $path: $!";
}
