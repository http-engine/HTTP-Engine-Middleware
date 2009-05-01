use t::200_middlewares::uploadtemp::base;
use Test::More tests => 6;

my $base_tmp   = quotemeta(File::Spec->tmpdir);
my $upload_tmpdir;
do {
    my $he = new_engine {
        my $req = shift;
        $upload_tmpdir = $req->request_builder->upload_tmp;
        if ($req->method eq 'post') {
            ok(-f $req->upload('upfile')->tempname, 'upload file');
        }
    } {
        keepalive => 1
    };

    $he->run(
        GET 'http://example.com/',
    );
    ok(-d $upload_tmpdir, 'alive tmpdir');

    $he->run(
        POST 'http://example.com/',
        Content_Type => 'form-data',
        Content      => [
            upfile => ['README'],
        ],
    );
    like($upload_tmpdir, qr{\A$base_tmp}, 'base tmpdir');
    ok(-d $upload_tmpdir, 'alive tmpdir');
    my $first_tmpdir = $upload_tmpdir;

    $he->run(
        POST 'http://example.com/',
        Content_Type => 'form-data',
        Content      => [
            upfile => ['Makefile.PL'],
        ],
    );
    is($upload_tmpdir, $first_tmpdir, 'recycle tmpdir');
};
ok(-d $upload_tmpdir, 'alive tmpdir out of scop');
ok(rmtree($upload_tmpdir, 0), 'rmtree');
