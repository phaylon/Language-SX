use MooseX::Declare;

role Template::SX::Inflator::Trait::QuoteState {

    use Template::SX::Types     qw( QuoteState );
    use MooseX::Types::Moose    qw( Undef );

    has quote_state => (
        is          => 'ro',
        isa         => QuoteState | Undef,
    );

    method clone_with_quote_state (QuoteState $state) {

        return $self->meta->clone_object($self, quote_state => $state);
    }

    method clone_without_quote_state () {

        return $self->meta->clone_object($self, quote_state => undef);
    }
}
