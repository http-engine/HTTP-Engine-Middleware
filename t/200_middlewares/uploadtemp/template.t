use t::200_middlewares::uploadtemp::base;
use Test::More tests => 4;

my $base_tmp   = quotemeta(File::Spec->tmpdir);
my $upload_tmpdir;
my $he = new_engine {
    my $req = shift;
    $upload_tmpdir = $req->request_builder->upload_tmp;
    if ($req->method eq 'post') {
        ok(-f $req->upload('upfile')->tempname, 'upload file');
    }
} {
    template => 'TESTTMPDIR_XXXXXXXX',
};

$he->run(
    POST 'http://example.com/',
    Content_Type => 'form-data',
    Content      => [
        upfile => ['README'],
    ],
);
unlike($upload_tmpdir, qr{\A$base_tmp}, 'base tmpdir');
like($upload_tmpdir, qr{TESTTMPDIR_}, 'use template');
ok(-d $upload_tmpdir, 'alive tmpdir');

ok(rmtree($upload_tmpdir, 0), 'rmtree');
