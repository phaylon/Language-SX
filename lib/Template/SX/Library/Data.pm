use MooseX::Declare;

class Template::SX::Library::Data extends Template::SX::Library::Group {
    use MooseX::ClassAttribute;
    use CLASS;

    class_has '+sublibraries';

    CLASS->add_sublibrary($_->new) for map { Class::MOP::load_class($_); $_ } qw(
        Template::SX::Library::Data::Common
        Template::SX::Library::Data::Functions
        Template::SX::Library::Data::Hashes
        Template::SX::Library::Data::Lists
        Template::SX::Library::Data::Numbers
        Template::SX::Library::Data::Pairs
        Template::SX::Library::Data::Strings
    );
}

