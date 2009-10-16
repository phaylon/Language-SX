use MooseX::Declare;

class Template::SX::Library::Core extends Template::SX::Library::Group {
    use CLASS;

    CLASS->add_sublibrary($_->new) for map { Class::MOP::load_class($_); $_ } qw(
        Template::SX::Library::Math
    );
}
