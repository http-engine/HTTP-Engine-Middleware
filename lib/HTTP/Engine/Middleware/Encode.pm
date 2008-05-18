package HTTP::Engine::Middleware::Encode;
use Moose;

use Data::Visitor::Encode;

sub wrap {
    my ($next, $c) = @_;

    if (($c->req->headers->header('Content-Type')||'') =~ /charset=(.+);?$/) {
        # decode parameters
        my $encoding = $1;
        my $dve = Data::Visitor::Encode->new;
        $c->req->query_parameters($dve->decode($encoding, $c->req->query_parameters));
        $c->req->body_parameters($dve->decode($encoding, $c->req->body_parameters));
        $c->req->parameters($dve->decode($encoding, $c->req->parameters));
    }

    $next->($c);
}


1;
