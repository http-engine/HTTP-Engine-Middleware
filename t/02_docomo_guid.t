use strict;
use warnings;
use utf8;
use lib '.';
use Test::Base;
eval q{ use HTTP::Engine };
plan skip_all => "some depended module is not installed.: $@" if $@;

plan tests => 1*blocks;

use Encode;
use URI;
use HTTP::Request;
use HTTP::Engine::Response;
use HTTP::Engine::Middleware::DoCoMoGUID;

filters({
    expected  => qw/ chomp /,
});

run {
    my $block = shift;

    my $code = sub {
        my $req = shift;
        HTTP::Engine::Response->new(
          content_type  => 'text/html',
          body          => $block->input,
        );
    };

    my $response = HTTP::Engine->new(
        interface => {
            module => 'Test',
            request_handler => HTTP::Engine::Middleware::DoCoMoGUID->wrap($code),
        },
    )->run(HTTP::Request->new( GET => '/' ));

    is $response->content, $block->expected;
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
<a href="http://192.168.1.3/?page=1&amp;guid=ON">&lt; 2008-05-18</a>
