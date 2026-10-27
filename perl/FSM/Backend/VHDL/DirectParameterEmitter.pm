package FSM::Backend::VHDL::DirectParameterEmitter;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(blessed);
use feature qw(signatures);
no warnings 'experimental::signatures';
use FSM::ParameterDefaultEnvironmentSupport;
use FSM::Backend::VHDL::ParameterBindingEmitter;

sub _identifier ($name) {
    return FSM::Backend::VHDL::ParameterBindingEmitter->validate_identifier($name);
}

sub _target_namespace ($module,$parameters,$namespace) {
    confess "Direct VHDL generic preparation requires an actual target namespace\n"
        unless ref($namespace) eq 'HASH' && ref($namespace->{identifier_map}) eq 'HASH'
            && ref($namespace->{parameter_names}) eq 'ARRAY';
    my $mapping=$namespace->{identifier_map};
    my $module_name=$module->name;
    confess "Direct VHDL generic module identity requires a scalar source name\n"
        unless defined($module_name) && !ref($module_name);
    my $actual_module=_identifier($namespace->{module_name});
    confess "Direct VHDL generic module mapping does not match the actual module identity\n"
        unless ($mapping->{$module_name} // $module_name) eq $actual_module;
    my %reserved=map {$_=>'generated type'} qw(natural std_logic std_logic_vector signed);
    $reserved{lc($actual_module)}='module';
    for my $bucket (qw(ports signals constants types)) {
        confess "Direct VHDL generic namespace requires '$bucket' as an array\n" unless ref($namespace->{$bucket}) eq 'ARRAY';
        for my $raw (@{$namespace->{$bucket}}) {
            my $name=_identifier($raw);
            confess "Direct VHDL target '$name' collides with $reserved{lc($name)}\n" if exists($reserved{lc($name)});
            $reserved{lc($name)}=$bucket;
        }
    }
    my %targets;
    for my $source (sort keys %$parameters) {
        my $target=_identifier($mapping->{$source} // $source);
        confess "Direct VHDL generic '$source' collides with target $reserved{lc($target)}\n"
            if exists($reserved{lc($target)});
        $reserved{lc($target)}='parameter';
        $targets{$source}=$target;
    }
    my %emitted;
    for my $name (@{$namespace->{parameter_names}}) {
        _identifier($name);
        confess "Direct VHDL target has duplicate parameter membership\n" if $emitted{$name}++;
    }
    confess "Direct VHDL emitted parameter membership does not match the source mapping\n"
        unless keys(%emitted)==keys(%targets) && !grep {!exists($emitted{$_})} values %targets;
    return \%targets;
}

sub lower_declarations ($class,%args) {
    my $language=$args{target_language} // 'vhdl';
    confess "Direct generic preparation requires a VHDL target\n" unless !ref($language) && lc($language) eq 'vhdl';
    my $module=$args{fsm_module};
    confess "Direct VHDL generic preparation requires a Core module\n"
        unless blessed($module) && $module->can('parameters') && $module->can('parameter_default_sources')
            && $module->can('parameter_default_bindings') && $module->can('name');
    my ($parameters,$sources,$bindings)=($module->parameters,$module->parameter_default_sources,$module->parameter_default_bindings);
    confess "Direct VHDL generic preparation requires captured maps\n"
        unless ref($parameters) eq 'HASH' && ref($sources) eq 'HASH' && ref($bindings) eq 'HASH';
    my $targets=_target_namespace($module,$parameters,$args{target_namespace});
    unless (keys(%$sources) || keys(%$bindings)) {
        my @names=@{$args{target_namespace}{parameter_names}};
        return {profile=>'legacy_static',source_scope=>undef,parameter_order=>\@names,
            static_parameters=>[ @names ],natural_declarations=>[]};
    }
    my $proof=FSM::ParameterDefaultEnvironmentSupport->prove_binding_observations(
        parameters=>$parameters,sources=>$sources,bindings=>$bindings);
    my $environment=$proof->{environment};
    my (%related,%dependencies);
    for my $name (@{$environment->{declaration_order}}) {
        my $references=$proof->{reference_observations}{$name};
        $related{$name}=1 if @$references;
        for my $reference (@$references) {
            $related{$reference->{parameter}}=1;
            $dependencies{$name}{$reference->{parameter}}=1;
        }
    }
    my $natural_environment={scope=>$environment->{scope},parameters=>{map {$_=>$parameters->{$_}} keys %related},
        declaration_order=>[grep {$related{$_}} @{$environment->{declaration_order}}]};
    my %natural;
    for my $name (@{$natural_environment->{declaration_order}}) {
        confess "Direct VHDL related parameter '$name' renaming is unsupported\n" unless $targets->{$name} eq $name;
        _identifier($name);
        my $info=$parameters->{$name};
        confess "Direct VHDL natural generic '$name' requires a scalar declaration\n" unless ($info->{value_kind} // '') eq 'scalar';
        if (exists($info->{value_type_spec})) {
            my $type=$info->{value_type_spec};
            confess "Direct VHDL natural generic '$name' has unsupported scalar type evidence\n"
                unless ref($type) eq 'HASH' && ($type->{kind} // '') =~ /\A(?:bit|bits)\z/;
        }
        FSM::Backend::VHDL::ParameterBindingEmitter->validate_integer_payload($info->{value_payload});
        my $lowered=FSM::Backend::VHDL::ParameterBindingEmitter->lower_expression(
            environment=>$natural_environment,binding=>$bindings->{$name});
        my $references=$proof->{reference_observations}{$name};
        my $actual=$lowered->{parameter_references};
        confess "Direct VHDL generic '$name' changes proved reference observations\n"
            unless @$actual==@$references && !grep {$actual->[$_] ne $references->[$_]{parameter}} 0..$#$references;
        $natural{$name}={name=>$targets->{$name},type=>'natural',default_text=>$lowered->{text},parameter_references=>$actual};
    }
    my (%done,@ordered);
    my $order=$environment->{declaration_order};
    while (@ordered<@$order) {
        my $next;
        for my $name (@$order) {
            next if $done{$name} || grep {!$done{$_}} keys %{$dependencies{$name} // {}};
            $next=$name;last;
        }
        confess "Direct VHDL generic defaults have a dependency cycle\n" unless defined($next);
        push @ordered,$next;$done{$next}=1;
    }
    return {profile=>!keys(%related)?'static':keys(%related)==keys(%$parameters)?'natural':'mixed',
        source_scope=>{%{$environment->{scope}}},parameter_order=>[map {$targets->{$_}} @ordered],
        static_parameters=>[map {$targets->{$_}} grep {!$related{$_}} @ordered],
        natural_declarations=>[map {$natural{$_}} grep {$related{$_}} @ordered]};
}

1;

=head1 NAME

FSM::Backend::VHDL::DirectParameterEmitter - Prepare captured direct generic profiles against actual target names

=head1 DESCRIPTION

C<lower_declarations> consumes C<fsm_module>, a VHDL C<target_language> and an
explicit C<target_namespace> from the backend conversion/planning boundary. The
namespace names the normalized C<module_name>, C<parameter_names>, the original
to-target C<identifier_map>, and C<ports>, C<signals>, C<constants>, C<types>
name arrays. It validates complete parameter membership and case-insensitive
target collisions, including generated primitive type names. These inputs are
a contract, not an attestation of caller-constructed target provenance.

Complete canonical observation proof selects every dependent declaration and
its referenced roots for natural-valued preparation through the shared VHDL
renderer. Actual references, never equal numbers, choose this subset. Unrelated
static literal/vector declarations retain their existing converter path,
including generated identifier normalization. Related source identifiers must
already be valid VHDL names and retain identity in the target mapping. Physical
module names remain separate from captured lexical source ownership.

The detached result contains C<profile> (static, natural, mixed or
legacy_static), C<source_scope>, dependency-ordered target C<parameter_order>,
C<static_parameters> and C<natural_declarations>. Existing alphabetical ties
remain stable. Plain natural arithmetic retains per-intermediate legality;
unsupported typed/sized/bitwise/aggregate/path relationships, stale bindings,
cycles and namespace mismatches refuse. Legacy programmatic declarations gain
no invented source scope. Caller records remain read-only.

The direct VHDL generator consumes this private plan through its source-aware
conversion boundary and supplies the actual normalized target namespace. The
standalone raw-text converter retains its existing static contract. No
native/API/MCP report schema changes. External overrides and full
runtime/transport qualification remain separately owned.

=cut
