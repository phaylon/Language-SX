#!/usr/bin/env perl
use strict;
use warnings;

use Language::SX;
use Language::SX::Renderer::Plain;
use Benchmark qw( timethis );
use Data::Dump qw( pp );

my $sx   = Language::SX->new(document_traits => [qw( CompileTidy )]);
my $doc  = $sx->read(string => join("\n", <DATA>));
my $tree = $doc->run(
    vars    => { 
        title       => 'Test Title',
        'js-uri'    => 'http://example.com/js',
    },
);

my $ren  = Language::SX::Renderer::Plain->new_with_traits();

pp $ren->render($tree);

DB::enable_profile() if $ENV{NYTPROF};

#warn "BENCHMARK RENDER\n";
#timethis 20_000, sub { $ren->render($tree) }
#    if $ENV{BENCHMARK};

warn "BENCHMARK FULL\n";
timethis 10_000, sub { $ren->render($doc->run(vars => { title => 'X', 'js-uri' => 'Y' })) }
    if $ENV{BENCHMARK};

DB::disable_profile() if $ENV{NYTPROF};

__DATA__

(define (head-section title)
  `(head
    (title ,title)
    (script { src ,js-uri type "text/javascript" })))

(define (content-wrapper title . body)
  `(div { id "content" }
    (h1 ,title)
    (div { id "main" }
      ,@body)))


`(html
  ,(head-section title)
  ,(content-wrapper title
    `(p "Hello & World!")))
