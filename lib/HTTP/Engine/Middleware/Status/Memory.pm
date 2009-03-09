package HTTP::Engine::Middleware::Status::Memory;
use Any::Moose;
extends 'HTTP::Engine::Middleware::Status::Base';

use B::TerseSize;
use Devel::Symdump;

has '+name' => (
    default => 'Memory',
);

sub render {
    my($self, %args) = @_;

    my $stab = Devel::Symdump->rnew("main");
    my %size;
    for my $package ("main", $stab->packages) {
        my($subs, $opcount, $opsize) = B::TerseSize::package_size($package);
        $size{$package} = $opsize;
    }

    my $table = "<table>\n";
    for my $package (sort {$size{$b}<=>$size{$a}} keys %size) {
        $table .= sprintf "<tr><td>%-24s</td><td>%8d [KB]</tr>\n", $package, $size{$package} / 1024 ;
    }
    $table .= "</table>\n";

    $table;
}

__PACKAGE__->meta->make_immutable;
1;

