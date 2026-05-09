#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'facade extension_modules are loaded from the constructor-time module list snapshot' => sub {
    my $fixture = make_extension_module_fixture();
    local @INC = ($fixture->{extension_lib}, @INC);

    my $extension_modules = [$fixture->{module_a}];
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        strict_mode => 1,
        quiet => 1,
        extension_modules => $extension_modules,
    );

    $extension_modules->[0] = $fixture->{module_b};
    push @$extension_modules, $fixture->{module_c};

    my $result = $pipeline->generate_hdl_from_file($fixture->{source_path});
    is_deeply(
        $result->{extension_modules_alias_markers},
        ['module_a'],
        'generation dispatches only modules loaded from the constructor-time extension_modules list',
    );

    my $plain_result = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        strict_mode => 1,
        quiet => 1,
    )->generate_hdl_from_file($fixture->{source_path});
    ok(
        !exists $plain_result->{extension_modules_alias_markers},
        'a facade object without extension_modules receives no module-list marker',
    );
};

done_testing();

sub make_extension_module_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $extension_lib = File::Spec->catdir($tempdir, 'lib');
    my $source_path = File::Spec->catfile($tempdir, 'extension_modules_alias_root.fsm');
    my %module = (
        module_a => 'FSM::BoundaryAudit::ExtensionModulesAliasA',
        module_b => 'FSM::BoundaryAudit::ExtensionModulesAliasB',
        module_c => 'FSM::BoundaryAudit::ExtensionModulesAliasC',
    );

    for my $label (sort keys %module) {
        write_extension_module($extension_lib, $module{$label}, $label);
    }
    write_direct_fixture($source_path);

    return {
        extension_lib => $extension_lib,
        source_path => $source_path,
        module_a => $module{module_a},
        module_b => $module{module_b},
        module_c => $module{module_c},
    };
}

sub write_extension_module {
    my ($lib_root, $module_name, $label) = @_;
    my @parts = split /::/, $module_name;
    my $file_name = pop @parts;
    my $module_dir = File::Spec->catdir($lib_root, @parts);
    my $module_path = File::Spec->catfile($module_dir, "$file_name.pm");

    make_path($module_dir);
    write_file(
        $module_path,
        <<"PERL"
package $module_name;

use strict;
use warnings;

sub new {
    my (\$class) = \@_;
    return bless {}, \$class;
}

sub after_generate_result {
    my (\$self, \$context) = \@_;
    push \@{\$context->result->{extension_modules_alias_markers}}, '$label';
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
(?fsm:extension_modules_alias_root
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
