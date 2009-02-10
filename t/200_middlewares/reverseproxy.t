use strict;
use warnings;
use Test::Base;
use HTTP::Engine;
use HTTP::Engine::Middleware;
use HTTP::Request;
use HTTP::Headers;

filters { input => [qw/yaml/] };

plan tests => 25;

run {
    my $block = shift;
    local %ENV = ();
    $ENV{REMOTE_ADDR}    = '127.0.0.1';
    $ENV{REQUEST_METHOD} = 'GET';
    $ENV{SERVER_PORT}    = 80;
    $ENV{HTTP_HOST}      = 'example.com';
    $ENV{QUERY_STRING}   = 'foo=bar';
    $ENV{HTTPS}          = delete $block->input->{https} if $block->input->{https};

    my $mw = HTTP::Engine::Middleware->new;
    $mw->install( 'HTTP::Engine::Middleware::ReverseProxy', );

    my $headers = HTTP::Headers->new;
    $headers->header( %{ $block->input } );

    # $headers->header(HOST => 'example.com:80');
    HTTP::Engine->new(
        interface => {
            module          => 'Test',
            request_handler => $mw->handler(
                sub {
                    my $req = shift;

                    for my $attr (qw/secure address/) {
                        if ( $block->$attr ) {
                            is( $req->$attr, $block->$attr,
                                $block->name . " of $attr" );
                        }
                    }
                    for my $url (qw/uri base /) {
                        if ( $block->$url ) {
                            is( $req->$url->as_string, $block->$url,
                                $block->name . " of $url" );
                        }
                    }

                    HTTP::Engine::Response->new( body => 'OK' );
                }
            ),
        },
        )->run(
        HTTP::Request->new( GET => 'http://example.com/?foo=bar', $headers ),
        env => \%ENV
        );
};

__END__

=== with https
--- input
x-forwarded-https: on
--- secure: 1
--- base: https://example.com:80/
--- uri:  https://example.com:80/?foo=bar

=== without https
--- input
x-forwarded-https: off
--- secure: 0
--- base: http://example.com/
--- uri:  http://example.com/?foo=bar

===
--- input
dummy: 1
--- secure: 0
--- base: http://example.com/
--- uri: http://example.com/?foo=bar

=== https with HTTP_X_FORWARDED_PROTO
--- input
x-forwarded-proto: https
--- secure: 1
--- base: https://example.com:80/
--- uri:  https://example.com:80/?foo=bar

=== with HTTP_X_FORWARDED_FOR
--- input
x-forwarded-for: 192.168.3.2
--- address: 192.168.3.2
--- base: http://example.com/
--- uri:  http://example.com/?foo=bar

=== with HTTP_X_FORWARDED_HOST
--- input
x-forwarded-host: 192.168.1.2:5235
--- base: http://192.168.1.2:5235/
--- uri:  http://192.168.1.2:5235/?foo=bar

=== default port with HTTP_X_FORWARDED_HOST
--- input
x-forwarded-host: 192.168.1.2
--- base: http://192.168.1.2/
--- uri:  http://192.168.1.2/?foo=bar

=== default https port with HTTP_X_FORWARDED_HOST
--- input
x-forwarded-https: on
x-forwarded-host: 192.168.1.2
--- base: https://192.168.1.2/
--- uri:  https://192.168.1.2/?foo=bar

=== default port with HOST
--- input
host: 192.168.1.2
--- base: http://192.168.1.2/
--- uri:  http://192.168.1.2/?foo=bar

=== default https port with HOST
--- input
host: 192.168.1.2
https: ON
--- base: https://192.168.1.2/
--- uri:  https://192.168.1.2/?foo=bar

=== with HTTP_X_FORWARDED_HOST and HTTP_X_FORWARDED_PORT
--- input
x-forwarded-host: 192.168.1.5
x-forwarded-port: 1984
--- base: http://192.168.1.5:1984/
--- uri:  http://192.168.1.5:1984/?foo=bar

