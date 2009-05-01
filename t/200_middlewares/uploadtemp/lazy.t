use t::200_middlewares::uploadtemp::base;
use Test::More tests => 9;

my $base_tmp   = quotemeta(File::Spec->tmpdir);
my $upload_tmpdir;
do {
    my $he = new_engine {
        my $req = shift;
        $upload_tmpdir = $req->request_builder->upload_tmp;
        if ($req->method eq 'POST') {
            ok(-f $req->upload('upfile')->tempname, 'upload file');
        }
    } {
        lazy => 1,
        cleanup => 1,
    };

    $he->run(
        GET 'http://example.com/',
    );
    ok(!$upload_tmpdir->tempdir, 'not alive tmpdir');

    $he->run(
        POST 'http://example.com/',
        Content_Type => 'form-data',
        Content      => [
            upfile => ['README'],
        ],
    );
    ok($upload_tmpdir->tempdir, 'alive tmpdir');
    like($upload_tmpdir, qr{\A$base_tmp}, 'base tmpdir');
    ok(-d $upload_tmpdir, 'alive tmpdir created');
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

END {
    # cleanup by File::Temp's END block
    ok(!-d $upload_tmpdir, 'not alive tmpdir');
    ok(!rmtree("$upload_tmpdir", 0), 'rmtree'); # $upload_tmpdir is HTTP::Engine::Middleware::UploadTemp::LazyObject object
}
