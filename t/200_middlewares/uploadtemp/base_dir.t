use t::200_middlewares::uploadtemp::base;
use Test::More tests => 5;

use File::Temp 'tempdir';

my $base_tmp   = tempdir('BASE_TMP_XXXX', CLEANUP => 1);
my $upload_tmpdir;
do {
    my $he = new_engine {
        my $req = shift;
        $upload_tmpdir = $req->request_builder->upload_tmp;
        if ($req->method eq 'POST') {
            ok(-f $req->upload('upfile')->tempname, 'upload file');
        }
    } {
        base_dir => $base_tmp
    };
    $he->run(
        POST 'http://example.com/',
        Content_Type => 'form-data',
        Content      => [
            upfile => ['README'],
        ],
    );
    like($upload_tmpdir, qr{\A$base_tmp}, 'base tmpdir');
    like($upload_tmpdir, qr{BASE_TMP_}, 'use template');
    ok(-d $upload_tmpdir, 'alive tmpdir');
};
ok(rmtree($upload_tmpdir, 0), 'rmtree');
