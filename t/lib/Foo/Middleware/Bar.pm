package Foo::Middleware::Bar;
use HTTP::Engine::Middleware;

has 'key' => (
    is => 'rw',
);

before_handle {
    my($self, $req) = @_;
    $req->header( 'X-Key' => $self->key );
    $req;
};

after_handle {
    my($self, $req, $res) = @_;
    $res->body( $res->body . ', key=' . $self->key );
    $res;
};

__MIDDLEWARE__
