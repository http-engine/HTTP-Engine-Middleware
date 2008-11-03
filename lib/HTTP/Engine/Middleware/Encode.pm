package HTTP::Engine::Middleware::Encode;
use Moose;

use Data::Visitor::Encode;

sub wrap {
    my ($class, $next) = @_;

    sub {
        my $req = shift;
        if (($req->headers->header('Content-Type')||'') =~ /charset=(.+);?$/) {
            # decode parameters
            my $encoding = $1;
            for my $method (qw/params query_params body_params/) {
                $req->$method( Data::Visitor::Encode->decode($encoding, $req->$method) );
            }

            $next->($req);
        }
    };
}

1;
