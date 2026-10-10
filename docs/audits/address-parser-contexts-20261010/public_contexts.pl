use strict;
use warnings;
use lib 'perl';
use JSON::PP;
use Scalar::Util qw(blessed refaddr);
use FSM::Adapter::ISF;

# Own-source instrumentation through the public parser. Historical holders in
# this probe are observer-only, not original active source locals.
my $json = JSON::PP->new->canonical;
my $request = do { local $/; $json->decode(<STDIN>) };
die 'complete original record source required' unless ref($request) eq 'HASH' && defined $request->{source};
my %allowed = map { $_ => 1 } qw(FSM::Adapter::ISF FSM::Adapter::ISF::Parser FSM::Adapter::ISF::LispishAdapter);

sub graph {
    my ($value, $seen, $classes, $path) = @_;
    return $value unless ref($value);
    my $class = blessed($value);
    die 'non-own object outside context source graph' if $class && !$allowed{$class};
    my $kind = $class ? 'HASH' : ref($value);
    die 'non-plain context source node' unless $kind eq 'HASH' || $kind eq 'ARRAY';
    my $address = refaddr($value);
    return ['reference', $seen->{$address}] if exists $seen->{$address};
    $seen->{$address} = $path;
    $classes->{$path} = $class if $class;
    if ($kind eq 'HASH') {
        my %out;
        for my $key (sort keys %$value) {
            my $escaped = $key; $escaped =~ s/~/~0/g; $escaped =~ s{/}{~1}g;
            $out{$key} = graph($value->{$key}, $seen, $classes, "$path/$escaped");
        }
        return ['hash', \%out];
    }
    return ['array', [map { graph($value->[$_], $seen, $classes, "$path/$_") } 0 .. $#$value]];
}

sub checkpoint {
    my ($items) = @_;
    my %classes;
    return {graph => graph($items, {}, \%classes, ''), classes => \%classes};
}

my $facade = FSM::Adapter::ISF->new;
my ($ast, $actor, $final);
my (@contexts, @scopes, @samples, @references, @copies, @steps, @active_args, @call_args);
my @installations;
my %canonical = (
    context => ['FSM::Support::ISFRecordPortScopes', 'record_context_scope'],
    scope => ['FSM::Support::ISFRecordPortValues', 'record_value_scope'],
    samples => ['FSM::Support::ISFRecordPortSamples', 'record_transaction_samples'],
    reference => ['FSM::Support::ISFRecordPortValues', 'record_value_reference'],
);
my %aliases = (
    context => [qw(FSM::Support::ISFRecordPortScopes FSM::Support::ISFRecordPortContexts FSM::Support::ISFRecordPortSamples)],
    scope => [qw(FSM::Support::ISFRecordPortValues FSM::Support::ISFRecordPortScopes FSM::Support::ISFRecordPortContexts FSM::Support::ISFRecordPortSamples)],
    samples => [qw(FSM::Support::ISFRecordPortSamples FSM::Support::ISFRecordPortContexts)],
    reference => [qw(FSM::Support::ISFRecordPortValues FSM::Support::ISFRecordPortContexts FSM::Support::ISFRecordPortSamples)],
);
my %outputs = (context => \@contexts, scope => \@scopes, samples => \@samples, reference => \@references);
for my $kind (qw(context scope samples reference)) {
    my ($package, $name) = @{$canonical{$kind}};
    my $operation = $package->can($name);
    die 'missing original own context operation' unless $operation;
    my $wrapped = sub {
        my @args = @_;
        my $position = @{$outputs{$kind}};
        push @{$outputs{$kind}}, undef;
        push @call_args, {kind => $kind, index => $position, arguments => \@args};
        push @steps, {kind => $kind, index => $position, boundary => 'entry',
            %{checkpoint([$facade, $ast, $actor, \@args])}};
        my $result = $operation->(@_);
        $outputs{$kind}[$position] = $result;
        push @steps, {kind => $kind, index => $position, boundary => 'return',
            %{checkpoint([$facade, $ast, $actor, \@args, $result])}};
        return $result;
    };
    push @installations, map { [$_ . '::' . $name, $wrapped] } @{$aliases{$kind}};
}
for my $module (qw(Scopes Values Metadata)) {
    my $package = $module eq 'Metadata' ? 'FSM::Support::ISFInterfacePortMetadata'
                                       : 'FSM::Support::ISFRecordPort' . $module;
    my $operation = $package->can('dclone');
    die 'missing original own imported copy boundary' unless $operation;
    my $wrapped = sub ($) {
        my $input = $_[0];
        my $position = @copies;
        push @copies, {module => $module, input => $input, result => undef};
        push @steps, {kind => 'private-copy', index => $position, module => $module, boundary => 'entry',
            %{checkpoint([$facade, $ast, $actor, $input])}};
        my $result = $operation->(@_); # Published provider boundary, implementation opaque.
        $copies[$position]{result} = $result;
        push @steps, {kind => 'private-copy', index => $position, module => $module, boundary => 'return',
            %{checkpoint([$facade, $ast, $actor, $input, $result])}};
        return $result;
    };
    push @installations, [$package . '::dclone', $wrapped];
}
for my $position (0 .. 2) {
    my $name = (qw(_clauses _assignment _reference))[$position];
    my $operation = FSM::Support::ISFRecordPortContexts->can($name);
    my $wrapped = sub {
        $active_args[$position] = [@_];
        return $operation->(@_);
    };
    push @installations, ['FSM::Support::ISFRecordPortContexts::' . $name, $wrapped];
}
my $build = FSM::Adapter::ISF::Parser->can('_build_actor');
my $typed = FSM::Adapter::ISF::Parser->can('_finalize_actor_type_references');
my $require = FSM::Support::ISFRecordPortContexts->can('_require');
push @installations, ['FSM::Adapter::ISF::Parser::_build_actor', sub {
    $ast = $_[1]; return $build->(@_);
}], ['FSM::Adapter::ISF::Parser::_finalize_actor_type_references', sub {
    $actor = $_[1]; return $typed->(@_);
}], ['FSM::Support::ISFRecordPortContexts::_require', sub {
    if (!$_[0] && defined($_[1]) && $_[1] =~ /record output field writes are not yet admitted/) {
        die 'duplicate final context checkpoint' if $final;
        $final = checkpoint([$facade, $ast, $actor, \@contexts, \@scopes, \@samples,
                             \@references, \@copies, \@active_args, \@call_args]);
    }
    return $require->(@_);
}];
my ($accepted, $error);
my $install;
$install = sub {
    my ($index) = @_;
    if ($index == @installations) {
        $accepted = eval { $facade->parse_source($request->{source}, 'still-refused.isf'); 1 };
        $error = $@;
        return;
    }
    my ($name, $wrapped) = @{$installations[$index]};
    no strict 'refs'; no warnings 'redefine';
    local *{$name} = $wrapped;
    return $install->($index + 1);
};
$install->(0);
undef $install;
die 'complete source context refusal required' if $accepted || !$final || !length($error);
print $json->encode({source => $request->{source}, parse_index => 2,
    primary => (split(/\n/, $error))[0], steps => \@steps, final => $final,
    scope => 'Fresh own-source context construction and published-copy checkpoints; retained probe intermediates are observer-only. Only primary refusal text is emitted. Original native identity/payload/flags and provider implementation remain unmeasured.'}), "\n";
