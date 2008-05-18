package HTTP::Engine::Middleware::DoCoMoGUID;
use Moose;
use Scalar::Util qw/blessed/;
use HTML::StickyQuery::DoCoMoGUID;

sub wrap {
    my ($next, $c) = @_;
    
    $next->($c);

    if (   $c->res->status == 200
        && $c->res->content_type =~ /html/
        && not blessed $c->res->body
        && $c->res->body )
    {
        $c->res->body(
            do {
                my $guid = HTML::StickyQuery::DoCoMoGUID->new;
                $guid->sticky( scalarref => \($c->res->body) );
            }
        );
    }
}

1;
