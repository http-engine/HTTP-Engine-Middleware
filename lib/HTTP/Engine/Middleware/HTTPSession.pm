package HTTP::Engine::Middleware::HTTPSession;
use HTTP::Engine::Middleware;
use Scalar::Util qw/blessed/;
use MouseX::Types -declare => [qw/State Store/];

subtype State,
    as 'CodeRef';
coerce State,
    from 'Object',
        via {
            my $x = $_;
            sub { $x }
        };
coerce State,
    from 'HashRef',
        via {
            my $klass = $_->{class};
            $klass = $klass =~ s/^\+// ? $klass : "HTTP::Session::State::${klass}";
            Mouse::load_class($klass);
            my $obj = $klass->new( $_->{args} );
            sub { $obj };
        };

subtype Store,
    as 'CodeRef';
coerce Store,
    from 'Object',
        via {
            my $x = $_;
            sub { $x }
        };
coerce Store,
    from 'HashRef',
        via {
            my $klass = $_->{class};
            $klass = $klass =~ s/^\+// ? $klass : "HTTP::Session::Store::${klass}";
            Mouse::load_class($klass);
            $klass->new( $_->{args} );
            my $obj = $klass->new( $_->{args} );
            sub { $obj };
        };

has 'state' => (
    is     => 'ro',
    isa    => State,
    coerce => 1,
);

has 'store' => (
    is     => 'ro',
    isa    => Store,
    coerce => 1,
);

my $SESSION;

middleware_method 'session' => sub {
    $SESSION
};

before_handle {
    my ($c, $self, $req) = @_;
    $SESSION = HTTP::Session->new(
        state   => $self->state->(),
        store   => $self->store->(),
        request => $req,
    );
    $req;
};

after_handle {
    my ($c, $self, $req, $res) = @_;
    $SESSION->response_filter($res);
    $SESSION->finalize();
    $res;
};

__MIDDLEWARE__
