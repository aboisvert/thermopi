
Compiling
=========

```sh
nim js src/thermopi_web.nim
```

The following defines are available:

`-d:stubs` Stubs out web endpoints (requires no server); good for quick, lightweight development.

`-d:local` Instructs the client to connect to `http://localhost:8080/api` (testing) instead of `http://thermopi:8080/api` (production) for API services.   Use this if your server is running locally.


Web Serving
===========

The [server](../server) is written such that it runs within the checked-out Git repository structure.

The server maps the following paths:

* `/` to `../web/src/thermopi.html` for the main page.  (This is a single-page app)

* `/static/...` to `../web/src`   (The `src/static` symlink exists to fake the server's route mapping so you can develop the `web` component without a server.)

* `/nimcache/...` to `../web/src/nimcache` where the Nim-compiled javascript can be found.


See [routes.nim](../server/src/routes.nim) in the server for details.