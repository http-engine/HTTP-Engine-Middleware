package Foo::Middleware::Middle;
use HTTP::Engine::Middleware;

outer_middleware 'Foo::Middleware::Outer';
inner_middleware 'Foo::Middleware::Inner';

before_handle {
    my($c, $self, $req) = @_;
    $req->header( 'X-Middle' => $c->method_class->before );
    $req;
};

after_handle {
    my($c, $self, $req, $res) = @_;
    $res->body( 'from inner (' . $res->body . ')' ) if $res->body eq 'ok';
    $res;
};

__MIDDLEWARE__
