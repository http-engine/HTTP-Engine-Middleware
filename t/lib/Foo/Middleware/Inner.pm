package Foo::Middleware::Inner;
use HTTP::Engine::Middleware;

after_handle {
    my($c, $self, $req, $res) = @_;
    $res->body( 'ok' );
    $res;
};

__MIDDLEWARE__
