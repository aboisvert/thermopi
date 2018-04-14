
Compiling
=========

```sh
nim js src/thermopi_web.nim
```

The following defines are available:

`-d:stubs` Stubs out web endpoints (requires no server); good for quick, lightweight development.

`-d:local` Instructs the client to connect to `http://localhost:8080/api` (testing) instead of `http://thermopi:8080/api` (production) for API services.   Use this if your server is running locally.

