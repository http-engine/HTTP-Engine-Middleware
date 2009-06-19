package HTTP::Engine::Middleware::DoCoMoGUID;
use HTTP::Engine::Middleware;
use Scalar::Util ();
use HTML::StickyQuery::DoCoMoGUID;

after_handle {
    my ( $c, $self, $req, $res ) = @_;

    if ( $res && $res->status == 200
        && $res->content_type =~ /html/
        && not( Scalar::Util::blessed( $res->body ) )
        && $req->mobile_attribute->is_docomo
        && $res->body )
    {
        my $body = $res->body;
        $res->body(
            do {
                my $guid = HTML::StickyQuery::DoCoMoGUID->new;
                $guid->sticky(
                    scalarref => \$body,
                );
            }
        );
    }

    $res;
};

__MIDDLEWARE__

__END__

=head1 NAME

HTTP::Engine::Middleware::DoCoMoGUID - append guid=ON on each anchor tag and form action

=head1 SYNOPSIS

This module appends ?guid=ON on each anchor tag and form action
This feature is needed by Japanese mobile web site developers.

=head1 AUTHORS

tokuhirom

yappo

nekokak

=head1 SEE ALSO

L<HTML::StickyQuery::DoCoMoGUID>

=cut
