use strict;
use warnings;
use lib '.';
use Test::Base;

eval q{ use MIME::Types };
plan skip_all => "MIME::Types is not installed" if $@;
eval q{ use Path::Class };
plan skip_all => "Path::Class is not installed" if $@;
eval q{ use MouseX::Types::Path::Class };
plan skip_all => "MouseX::Types::Path::Class is not installed" if $@;

plan tests => 12 * blocks;

use HTTP::Engine;
use HTTP::Engine::Middleware;
use HTTP::Engine::Response;
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
}

run {
    my $block = shift;

    my @config = (
        'HTTP::Engine::Middleware::Static' => {
            regexp  => qr{^(/css/(?!dynamic).+|/robots\.txt)$},
            regexp  => qr{^(/(?:css|js|img)/(?!dynamic).+|/manual/.*|/robots\.txt)$},
            docroot => Path::Class::Dir->new('t', 'htdocs'),
            directory_index => 'index.html',
        },
    );

    my $mw = HTTP::Engine::Middleware->new;
    ok $mw->install(@config), 'firast instance';

    run_tests($block, $mw);

    my $mw2 = HTTP::Engine::Middleware->new;
    ok $mw2->install(@config), 'create multi instance';

    run_tests($block, $mw2);

    my @config2 = (
        'HTTP::Engine::Middleware::Static' => {
            regexp  => '(/(?:css|js|img)/(?!dynamic).+|/manual/.*|/robots\.txt)$',
            docroot => Path::Class::Dir->new('t', 'htdocs')->stringify,
            directory_index => 'index.html',
        },
    );

    my $mw3 = HTTP::Engine::Middleware->new;
    ok $mw3->install(@config2), 'firast instance';

    run_tests($block, $mw3);
};


__END__

=== dynamic
--- uri: http://localhost/
--- content_type: text/html
--- body: dynamic
--- code: 200

=== robots
--- uri: http://localhost/robots.txt
--- content_type: text/plain
--- body: robots.txt here
--- code: 200

=== directory index
--- uri: http://localhost/manual/
--- content_type: text/html
--- body: index.html
--- code: 200

=== css
--- uri: http://localhost/css/mobile.css
--- content_type: text/css
--- body: .mobile { display: none; }
--- code: 200

=== not found
--- uri: http://localhost/css/unknown.css
--- content_type: text/html
--- body: not found
--- code: 404

=== directory traversal
--- uri: http://localhost/css/../../Makefile.PL
--- content_type: text/html
--- body: forbidden
--- code: 403

=== handle backend
--- uri: http://localhost/css/dynamic-unknown.css
--- content_type: text/html
--- body: dynamic
--- code: 200
