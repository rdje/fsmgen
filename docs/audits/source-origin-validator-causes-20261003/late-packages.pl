{
    package FSM::Test::LibraryLateTargetMutation;
    use parent 'FSM::Test::SameSourceLibraryOriginParser';
    sub _finalize_actor_crossings {
        my ($self, $actor, @args) = @_;
        my $result = $self->SUPER::_finalize_actor_crossings($actor, @args);
        $actor->{transactions}[0]{clauses}[0][1] = 'start';
        return $result;
    }
}
{
    package FSM::Test::DocumentSelectedFormMutation;
    use parent -norequire, 'FSM::Test::LibraryDocumentOriginAuthority::Parser';
    sub _parse_library_form {
        my ($self, $form, @args) = @_;
        $form->[1] = 'forged.library';
        return $self->SUPER::_parse_library_form($form, @args);
    }
    package FSM::Test::DocumentLateCloneMutation;
    use parent -norequire, 'FSM::Test::LibraryDocumentOriginAuthority::Parser';
    sub _finalize_actor_crossings {
        my ($self, $actor, @args) = @_;
        my $result = $self->SUPER::_finalize_actor_crossings($actor, @args);
        if ($self->{mutation} eq 'target') {
            $actor->{library_uses}[0]{actor}{transactions}[0]{clauses}[0][1] = 'forged_guard';
        } elsif ($self->{mutation} eq 'instance') {
            $actor->{library_uses}[0]{instance} = 'forged_instance';
        } elsif ($self->{mutation} eq 'coverage') {
            pop @{$actor->{library_uses}};
        } elsif ($self->{mutation} eq 'parameter_kind') {
            $actor->{library_uses}[0]{parameter_overrides}[0]{value} = 2;
        } else {die 'unknown finalization control'}
        return $result;
    }
}
{
    package FSM::Test::ATLLateOriginMutation;
    use parent -norequire, 'FSM::Test::ATLDocumentOriginAuthority::Parser';
    sub _finalize_actor_crossings {
        my ($self, $actor, @args) = @_;
        my $result = $self->SUPER::_finalize_actor_crossings($actor, @args);
        if ($self->{mutation} eq 'target') {
            $actor->{_atl_actor_type_resolutions}{first_node}{actor}{transactions}[0]{clauses}[0][1] = 'forged_guard';
        } elsif ($self->{mutation} eq 'declaration') {
            $actor->{actor_network}{instances}[0]{name} = 'forged_instance';
        } elsif ($self->{mutation} eq 'coverage') {
            delete $actor->{_atl_actor_type_resolutions}{first_node};
        } else {die 'unknown late ATL mutation'}
        return $result;
    }
}
1;
