use t::200_middlewares::uploadtemp::base;
use Test::More tests => 7;

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
        keepalive => 0,
    };

    $he->run(
        GET 'http://example.com/',
    );
    ok(!-d $upload_tmpdir, 'not alive tmpdir');

    $he->run(
        POST 'http://example.com/',
        Content_Type => 'form-data',
        Content      => [
            upfile => ['README'],
        ],
    );
    like($upload_tmpdir, qr{\A$base_tmp}, 'base tmpdir');
    ok(!-d $upload_tmpdir, 'not alive tmpdir');
    my $first_tmpdir = $upload_tmpdir;

    $he->run(
        POST 'http://example.com/',
        Content_Type => 'form-data',
        Content      => [
            upfile => ['Makefile.PL'],
        ],
    );
    isnt($upload_tmpdir, $first_tmpdir, 'not recycle tmpdir');
};
ok(!rmtree($upload_tmpdir, 0), 'rmtree');
