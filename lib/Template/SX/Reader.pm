use MooseX::Declare;

class Template::SX::Reader {

    method read (Str $string) {

        require Template::SX::Reader::Stream;
        my $stream = Template::SX::Reader::Stream->new(content => $string);

        require Template::SX::Document;
        my $doc = Template::SX::Document->new_from_stream($stream);

        return $doc;
    }
}
