use strict;
use warnings;
use lib '.';
use Test::Base;
eval q{ use HTTP::Request::Common };
plan skip_all => "HTTP::Request is not installed" if $@;
eval q{ use HTTP::Engine };
plan skip_all => "HTTP::Engine is not installed: $@" if $@;

eval q{ use HTTP::Engine::Middleware };

plan tests => 2 * blocks;

use URI;

filters { post_params => [qw/eval/], };

run {
    my $block = shift;

    my $mw = HTTP::Engine::Middleware->new;
    $mw->install( 'HTTP::Engine::Middleware::OverloadPost', );
    my $request = HTTP::Request::Common::POST( $block->uri, $block->post_params );
    my $do_test = sub {
        my $req = shift;
        is $req->method, 'DELETE';
        HTTP::Engine::Response->new( body => 'OK' );
    };

    my $response = HTTP::Engine->new(
        interface => {
            module          => 'Test',
            request_handler => $mw->handler($do_test),
        },
    )->run($request);

    is $response->content, 'OK';
};

__END__

=== _method
--- uri: http://localhost/
--- post_params : [ '_method' => 'DELETE' ]

=== x-tunneled-method
--- uri: http://localhost/
--- post_params : [ 'x-tunneled-method' => 'DELETE' ]

