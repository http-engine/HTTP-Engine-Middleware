use strict;
use warnings;
use Test::Base;

plan tests => 2 * blocks;

use HTTP::Engine;
use HTTP::Engine::Middleware;
use HTTP::Request::Common;

filters { post_params => [qw/eval/], };

run {
    my $block = shift;

    my $mw = HTTP::Engine::Middleware->new;
    $mw->install( 'HTTP::Engine::Middleware::MethodOverride', );
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


