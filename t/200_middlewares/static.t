use strict;
use warnings;
use lib '.';
use Test::Base;

eval q{ use MIME::Types };
plan skip_all => "MIME::Types is not installed" if $@;
eval q{ use Path::Class };
plan skip_all => "Path::Class is not installed" if $@;

plan tests => 3 * blocks;

use HTTP::Engine;
use HTTP::Engine::Middleware;
use HTTP::Engine::Response;
use HTTP::Request;
use Path::Class;

run {
    my $block = shift;

    my $mw = HTTP::Engine::Middleware->new;
    $mw->install(
        'HTTP::Engine::Middleware::Static' => {
            path => [
                '/static/' => Path::Class::Dir->new(qw/ t htdocs /),
                '/dist/'   => Path::Class::Dir->new(qw/ . /),
                '/lib/'    => Path::Class::Dir->new(qw/ . lib HTTP Engine /),
                '/t'       => Path::Class::Dir->new(qw/ . t 100 /),
                '/htdocs/' => Path::Class::Dir->new(qw/ . t htdocs /),
            ],
        },
    );

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
};


__END__

=== dynamic
--- uri: http://localhost/
--- content_type: text/html
--- body: dynamic
--- code: 200

=== dist
--- uri: http://localhost/dist/Makefile.PL
--- content_type: application/x-perl
--- body: use inc::Module::Install
--- code: 200

=== dist not found
--- uri: http://localhost/dist/notfound.html
--- content_type: text/html
--- body: not found
--- code: 404

=== lib
--- uri: http://localhost/lib/Middleware.pm
--- content_type: application/x-pagemaker
--- body: package HTTP::Engine::Middleware;
--- code: 200

=== lib 2
--- uri: http://localhost/lib/Middleware/Static.pm
--- content_type: application/x-pagemaker
--- body: package HTTP::Engine::Middleware::Static;
--- code: 200

=== lib not found
--- uri: http://localhost/lib/notfound.html
--- content_type: text/html
--- body: not found
--- code: 404

=== t/100 3
--- uri: http://localhost/t_core/wrap.t
--- content_type: application/x-troff
--- body: \$req\-\>header\(\'X-Key\'\)
--- code: 200

=== t/100 not found
--- uri: http://localhost/t_base.txt
--- content_type: text/html
--- body: not found
--- code: 404

=== index
--- uri: http://localhost/htdocs/
--- content_type: text/html
--- body: index page
--- code: 200
