package Foo::Middleware::Outer;
use HTTP::Engine::Middleware;

my $param;
middleware_method 'before' => sub { $param };

before_handle {
    my($c, $self, $req) = @_;
    $param = $req->param('param');
    $req;
};

__MIDDLEWARE__
