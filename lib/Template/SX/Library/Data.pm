use MooseX::Declare;

class Template::SX::Library::Data extends Template::SX::Library::Group {
    use CLASS;

    CLASS->add_sublibrary($_->new) for map { Class::MOP::load_class($_); $_ } qw(
        Template::SX::Library::Data::Common
        Template::SX::Library::Data::Numbers
    );
}

