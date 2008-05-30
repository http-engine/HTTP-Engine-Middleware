use strict;
use warnings;
use lib '.';
use Test::Base;
eval q{ use Data::Visitor::Encode };
plan skip_all => "Data::Visitor::Encode is not installed" if $@;
eval q{ use HTTP::Engine middlewares => ['+HTTP::Engine::Middleware::Encode'] };
plan skip_all => "HTTP::Engine is not installed: $@" if $@;

plan tests => 3*blocks;

use Encode;
use URI;

filters {
    params => [qw/eval/],
};

run {
    my $block = shift;

    my $request = HTTP::Request->new( GET => $block->uri, ['Content-Type' => $block->content_type] );

    my $response = HTTP::Engine->new(
        interface => {
            module => 'Test',
            request_handler => sub {
                my $c = shift;
                ok Encode::is_utf8($c->req->params->{'nite'});
                is_deeply $c->req->params, $block->params, $block->name;
                $c->res->body('OK!');
            },
        },
    )->run($request);

    is $response->content, 'OK!';
};

__END__

=== ascii
--- uri: http://localhost/?nite=nipotan
--- content_type: text/plain;charset=ascii
--- params : {nite => 'nipotan'}

=== utf-8
--- uri: http://localhost/?nite=%E3%81%97%E3%83%BC%E3%81%88%E3%81%99%E3%81%88%E3%81%99
--- content_type : text/plain; charset=utf-8
--- params: { nite => "\x{3057}\x{30fc}\x{3048}\x{3059}\x{3048}\x{3059}" }

=== euc-jp
--- uri: http://localhost/?nite=%A4%B7%A1%BC%A4%A8%A4%B9%A4%A8%A4%B9
--- content_type: text/plain; charset=euc-jp
--- params: { nite => "\x{3057}\x{30fc}\x{3048}\x{3059}\x{3048}\x{3059}" }

