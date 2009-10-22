use MooseX::Declare;

class Template::SX::Document::Quote {

    use Template::SX::Constants qw( :all );
    use Template::SX::Types     qw( :all );

    my %QuoteType = (
        q(`),   'quasiquote',
        q('),   'quote',
        q(,),   'unquote',
        q(,@),  'unquote-splicing',
    );

    method new_from_stream (ClassName $class: Object $doc, Object $stream, Str $value, Location $loc) {

        require Template::SX::Document::Cell::Application;
        require Template::SX::Document::Bareword;

        my $contained_token = $stream->next_token;
        my $contained_node  = $doc->new_node_from_stream($stream, $contained_token);
        my $identifier_node = Template::SX::Document::Bareword->new(
            value       => $QuoteType{ $value },
            location    => $loc,
        );

        return Template::SX::Document::Cell::Application->new(
            nodes       => [$identifier_node, $contained_node],
            location    => $loc,
        );
    }
}
