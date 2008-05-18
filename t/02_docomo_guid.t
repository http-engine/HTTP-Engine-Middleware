use strict;
use warnings;
use utf8;
use lib '.';
use Test::Base;
eval q{ use HTTP::Engine middlewares => ['+HTTP::Engine::Middleware::DoCoMoGUID'] };
plan skip_all => "some depended module is not installed.: $@" if $@;

plan tests => 1*blocks;

use Encode;
use URI;

run {
    my $block = shift;

    my $response = HTTP::Engine->new(
        interface => {
            module => 'Test',
            request_handler => sub {
                my $c = shift;
                $c->res->content_type('text/html');
                $c->res->body($block->input);
            },
        },
    )->run(HTTP::Request->new( GET => '/' ));

    is $response->content, $block->expected;
};

__END__

=== 
--- input
<a href="/foo">bar</a>
--- expected: <a href="/foo?guid=ON">bar</a>

