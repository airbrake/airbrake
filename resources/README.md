Airbrake Resources
==================

Airbrake has an SSL mode available to paying plans. SSL Certificate Authority (CA) certificates are not kept current by default on many environments. When CA certs are stale, Airbrake cannot verify Airbrake's production SSL cert and error reports fail. To avoid this, we now package local CA certs. The production of these certs is detailed here.

Building ca-bundle.crt
----------------------

From https://gist.github.com/996292.

If you want to use curl or net-http/open-uri to access https resources, you will often (always?) get an error, because they don't have the large number of root certificates installed that web browsers have.

You can manually install the root certs, but first you have to get them from somewhere. [This article](http://notetoself.vrensk.com/2008/09/verified-https-in-ruby/) gives a nice description of how to do that. The [source of the cert files](http://curl.haxx.se/ca/cacert.pem) it points to is hosted by the curl project, who kindly provide it in the .pem format.

**problem:** Sadly, ironically, and comically, it's not possible to access that file via https! Luckily, the awesome curl project does provide us with the script that they use to produce the file, so we can do it securely ourselves. Here's how.

1. `git clone https://github.com/bagder/curl.git`
2. `cd curl/lib`
3. edit `mk-ca-bundle.pl` and change:

    ```perl
    my $url = 'http://mxr.mozilla.org/mozilla/source/security/nss/lib/ckfw/builtins/certdata.txt?raw=1';
    ```

    to

    ```perl
    my $url = 'https://mxr.mozilla.org/mozilla/source/security/nss/lib/ckfw/builtins/certdata.txt?raw=1';
    ```

    (change `http` to `https`)
4. `./mk-ca-bundle.pl`

Ta da!
