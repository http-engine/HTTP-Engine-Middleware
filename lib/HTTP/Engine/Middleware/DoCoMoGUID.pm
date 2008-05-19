package HTTP::Engine::Middleware::DoCoMoGUID;
use Moose;
use Scalar::Util qw/blessed/;
use HTML::StickyQuery;

sub wrap {
    my ($next, $c) = @_;
    
    $next->($c);

    if (   $c->res->status == 200
        && $c->res->content_type =~ /html/
        && not blessed $c->res->body
        && $c->res->body )
    {
        my $body = $c->res->body;
        $c->res->body(
            do {
                my $guid = HTML::StickyQuery->new(
                    'abs' => 1,
                );
                $guid->sticky(
                    scalarref => \$body,
                    param     => { guid => 'ON' },
                );
            }
        );
    }
}

1;
