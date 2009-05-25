use strict;
use warnings;
use lib '.';
use Test::Base;

eval q{ use MIME::Types };
plan skip_all => "MIME::Types is not installed" if $@;
eval q{ use Path::Class };
plan skip_all => "Path::Class is not installed" if $@;
eval q( { package foo; use Any::Moose;use Any::Moose 'X::Types::Path::Class' } );
plan skip_all => "Mo[ou]seX::Types::Path::Class is not installed" if $@;

plan tests => 8 * (blocks() - 1);

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

    if ($block->name !~ /without directory_index/) {
        my @config = (
            'HTTP::Engine::Middleware::Static' => {
                docroot         => Path::Class::Dir->new('t', 'htdocs'),
                directory_index => 'index.html',
                is_404_handler  => 0,
                regexp          => qr{/.*},
            },
        );

        my $mw = HTTP::Engine::Middleware->new;
        $mw->install(@config);
        ok scalar(@{ $mw->middlewares }), 'firast instance';

        run_tests($block, $mw);
    }

    if ($block->name !~ /with directory_index/) {
        my @config = (
            'HTTP::Engine::Middleware::Static' => {
                docroot         => Path::Class::Dir->new('t', 'htdocs'),
                is_404_handler  => 0,
                regexp          => qr{/.*},
            },
        );

        my $mw = HTTP::Engine::Middleware->new;
        $mw->install(@config);
        ok scalar(@{ $mw->middlewares }), 'firast instance';

        run_tests($block, $mw);
    }
};


__END__

=== directory index (with directory_index)
--- uri: http://localhost/
--- content_type: text/html
--- body: index page
--- code: 200

=== directory index (without directory_index)
--- uri: http://localhost/
--- content_type: text/html
--- body: dynamic
--- code: 200

=== directory doesn't have directory_index handled by dynamic
--- uri: http://localhost/css/
--- content_type: text/html
--- body: dynamic
--- code: 200

=== normal file
--- uri: http://localhost/css/mobile.css
--- content_type: text/css
--- body: .mobile { display: none; }
--- code: 200

=== normal file doesn't exists
--- uri: http://localhost/css/not_found.css
--- content_type: text/html
--- body: dynamic
--- code: 200

=== normal file doesn't exists
--- uri: http://localhost/other_path.txt
--- content_type: text/html
--- body: dynamic
--- code: 200

=== directory doesn't exists
--- uri: http://localhost/directory/does/not/exists
--- content_type: text/html
--- body: dynamic
--- code: 200

