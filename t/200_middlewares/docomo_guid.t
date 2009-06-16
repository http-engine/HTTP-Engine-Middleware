use strict;
use warnings;
use Test::Base;
use IO::Scalar;

eval q{ use HTML::StickyQuery };
plan skip_all => "HTML::StickyQuery is not installed" if $@;

plan tests => 2 * blocks;

use HTTP::Engine;
use HTTP::Engine::Middleware;
use HTTP::Engine::Response;
use HTTP::Request;

filters( { expected => qw/ chomp /, } );

run {
    my $block = shift;

    my $mw = HTTP::Engine::Middleware->new;
    $mw->install( 'HTTP::Engine::Middleware::DoCoMoGUID', );

    my $code = sub {
        my $req = shift;
        HTTP::Engine::Response->new(
            content_type => 'text/html',
            body         => $block->input,
        );
    };

    my $response = HTTP::Engine->new(
        interface => {
            module          => 'Test',
            request_handler => $mw->handler($code),
        },
    )->run( HTTP::Request->new( GET => '/' ) );

    is $response->content, $block->expected;

    tie *STDERR, 'IO::Scalar', \my $err;
    $response = HTTP::Engine->new(
        interface => {
            module          => 'Test',
            request_handler => $mw->handler(sub {}),
        },
    )->run( HTTP::Request->new( GET => '/' ) );
    untie *STDERR;
    like $err, qr/You should return instance of HTTP::Engine::Response./, 'You should return instance of HTTP::Engine::Response.';
};

__END__

=== 
--- input
<a href="/foo">bar</a>
--- expected
<a href="/foo?guid=ON">bar</a>

===
--- input
<a href="http://192.168.1.3/?page=1">&lt; 2008-05-18</a>
--- expected
<a href="http://192.168.1.3/?page=1">&lt; 2008-05-18</a>

===
--- input
<form action="/foo">
--- expected
<form action="/foo"><input type="hidden" name="guid" value="ON" />
