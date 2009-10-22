use MooseX::Declare;

role Template::SX::Document::Locatable {

    use Template::SX::Types qw( Location );

    has location => (
        is          => 'rw',
        isa         => Location,
        required    => 1,
    );
};
