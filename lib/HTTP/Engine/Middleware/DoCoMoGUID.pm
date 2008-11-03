package HTTP::Engine::Middleware::DoCoMoGUID;
use Moose;
use Scalar::Util qw/blessed/;
use HTML::StickyQuery;

sub wrap {
    my ($class, $next) = @_;
    
    sub {
        my $req = shift;

        my $res = $next->($req);

        if (   $res->status == 200
            && $res->content_type =~ /html/
            && not blessed $res->body
            && $res->body )
        {
            my $body = $res->body;
            $res->body(
                sub {
                    my $guid = HTML::StickyQuery->new(
                        'abs' => 1,
                    );
                    $guid->sticky(
                        scalarref => \$body,
                        param     => { guid => 'ON' },
                    );
                }->()
            );
        }

        $res;
    }
}

1;
