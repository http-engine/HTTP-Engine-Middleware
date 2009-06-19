use strict;
use warnings;
use lib '.';
use Test::Base;

eval q{ use MIME::Types };
plan skip_all => "MIME::Types is not installed" if $@;
eval q{ use Path::Class };
plan skip_all => "Path::Class is not installed" if $@;
eval q( { package foo; use Any::Moose;use Any::Moose 'X::Types::Path::Class' } );
plan skip_all => "Mo[ou]seX::Types::Path::Class is not installed" if $@;

plan tests => 15 * blocks;

use HTTP::Engine;
use HTTP::Engine::Middleware;
use HTTP::Engine::Response;
use HTTP::Date ();
use HTTP::Request;

sub run_tests {
    my($block, $mw) = @_;

    my $request = HTTP::Request->new(
        GET => $block->uri
    );

    my $response = HTTP::Engine->new(
        interface => {
            module          => 'Test',
            request_handler => $mw->handler( sub { HTTP::Engine::Response->new( body => 'dynamic' ) } ),
        },
    )->run($request);

    is $response->code, $block->code, 'status code';
    is $response->content_type, $block->content_type, 'content type';
    my $body = $block->body;
    like $response->content, qr/$body/, 'body';

    if ($block->last_modified) {
        like(HTTP::Date::str2time($response->header('Last-Modified')), qr/\A[0-9]{9,10}\z/, 'send Last-Modified header');
    } else {
        ok(!$response->header('Last-Modified'), 'not send Last-Modified header');
    }
}

run {
    my $block = shift;

    my @config = (
        'HTTP::Engine::Middleware::Static' => {
            regexp  => qr{^(/(?:css|js|img)/(?!dynamic).+|/manual/.*|/robots\.txt|/null\.html)$},
            docroot => Path::Class::Dir->new('t', 'htdocs'),
            directory_index => 'index.html',
        },
    );

    my $mw = HTTP::Engine::Middleware->new;
    $mw->install(@config);
    ok scalar(@{ $mw->middlewares }), 'firast instance';

    run_tests($block, $mw);

    my $mw2 = HTTP::Engine::Middleware->new;
    $mw2->install(@config);
    ok scalar(@{ $mw2->middlewares }), 'create multi instance';

    run_tests($block, $mw2);

    my @config2 = (
        'HTTP::Engine::Middleware::Static' => {
            regexp  => '(/(?:css|js|img)/(?!dynamic).+|/manual/.*|/robots\.txt)$',
            docroot => Path::Class::Dir->new('t', 'htdocs')->stringify,
            directory_index => 'index.html',
        },
    );

    my $mw3 = HTTP::Engine::Middleware->new;
    $mw3->install(@config2);
    ok scalar(@{ $mw3->middlewares }), 'firast instance';

    run_tests($block, $mw3);
};


__END__

=== dynamic
--- uri: http://localhost/
--- last_modified: 0
--- content_type: text/html
--- body: dynamic
--- code: 200

=== robots
--- uri: http://localhost/robots.txt
--- last_modified: 1
--- content_type: text/plain
--- body: robots.txt here
--- code: 200

=== directory index
--- uri: http://localhost/manual/
--- last_modified: 1
--- content_type: text/html
--- body: index.html
--- code: 200

=== css
--- uri: http://localhost/css/mobile.css
--- last_modified: 1
--- content_type: text/css
--- body: .mobile { display: none; }
--- code: 200

=== not found
--- uri: http://localhost/css/unknown.css
--- last_modified: 0
--- content_type: text/html
--- body: not found
--- code: 404

=== directory traversal
--- uri: http://localhost/css/../../Makefile.PL
--- last_modified: 0
--- content_type: text/html
--- body: forbidden
--- code: 403

=== directory traversal real path
--- uri: http://localhost/css/../../../Makefile.PL
--- last_modified: 0
--- content_type: text/html
--- body: forbidden
--- code: 403

=== handle backend
--- uri: http://localhost/css/dynamic-unknown.css
--- last_modified: 0
--- content_type: text/html
--- body: dynamic
--- code: 200

=== null
--- uri: http://localhost/null.html
--- last_modified: 0
--- content_type: text/html
--- body: \A\z
--- code: 200
