use strict;
use warnings;
use Test::Base;
use IO::Scalar;

eval q{ use HTTP::MobileAttribute; use HTML::StickyQuery::DoCoMoGUID };
plan skip_all => "HTML::StickyQuery::DoCoMoGUID is not installed" if $@;

plan tests => 2 * blocks;

use HTTP::Engine;
use HTTP::Engine::Middleware;
use HTTP::Engine::Response;
use HTTP::Request;
HTTP::MobileAttribute->load_plugins('IS');

filters( {
    input    => qw/ yaml /,
    expected => qw/ chomp /,
} );

run {
    my $block = shift;

    my $mw = HTTP::Engine::Middleware->new({ method_class => 'HTTP::Engine::Request' });
    $mw->install( 'HTTP::Engine::Middleware::DoCoMoGUID', 'HTTP::Engine::Middleware::MobileAttribute' );

    my $code = sub {
        my $req = shift;
        $req->user_agent($block->input->{ua});
        HTTP::Engine::Response->new(
            content_type => 'text/html',
            body         => $block->input->{html},
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
ua: DoCoMo/1.0/D501i
html: <a href="/foo">bar</a>
--- expected
<a href="/foo?guid=ON">bar</a>

===
--- input
ua: DoCoMo/1.0/D501i
html: <a href="http://192.168.1.3/?page=1">&lt; 2008-05-18</a>
--- expected
<a href="http://192.168.1.3/?page=1">&lt; 2008-05-18</a>

===
--- input
ua: DoCoMo/1.0/D501i
html: <form action="/foo">
--- expected
<form action="/foo"><input type="hidden" name="guid" value="ON" />

=== 
--- input
ua: KDDI-SN31 UP.Browser/6.2.0.7.3.129 (GUI) MMP/2.0
html: <a href="/foo">bar</a>
--- expected
<a href="/foo">bar</a>

