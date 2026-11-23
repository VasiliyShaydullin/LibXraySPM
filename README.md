# VlessSPM

Swift Package wrapper for libXray v26.11.9.

## Installation

Add `https://github.com/VasiliyShaydullin/LibXraySPM.git` in Xcode and select
version `26.11.9`. The binary artifact is distributed via GitHub Releases.

## Usage

```swift
import VlessSPM

let version = try VlessSPM.version()
let result = try VlessSPM.run(xrayJson: configJSON)
if !result.success {
    print(result.error ?? "Failed to start Xray")
}
let stopped = try VlessSPM.stop()
```

`LibXraySPM` and `VlessSPM` refer to the same API. Responses use the upstream
JSON envelope (`success`, `data`, `error`); check `success` for operation
failures. Errors thrown by the wrapper indicate encoding, decoding or bridge
failures. `freePorts` throws for an unsuccessful operation.

Other API v3 methods can be called with a custom `Encodable` payload and
`Decodable` response:

```swift
struct TextPayload: Encodable { let text: String }
struct Subscription: Decodable { let text: String }

let response = try VlessSPM.invoke(
    method: "decodeSubscriptionText",
    payload: TextPayload(text: subscription),
    dataType: Subscription.self
)
```

`invoke(_:)` also accepts and returns raw JSON envelopes. See the
[upstream API documentation](https://github.com/XTLS/libXray/tree/v26.11.9#api)
for supported methods, payloads, response shapes and size limits.

## Migration from 25.12.8

This is a breaking API update: responses are no longer Base64 encoded.
`run` and `test` accept the configuration JSON itself, not a file path; read
the file in the application and set asset paths and other runtime options in
the configuration's root `env` object. `maxMemory` is no longer an argument.
Use `pingBatch` instead of `ping`. `queryStats` was removed upstream; configure
the Xray metrics endpoint and query `/debug/vars` over HTTP instead. Share-link
conversion is available through `invoke` with the API v3 payloads.

Only one independently built Go runtime may be loaded per process; do not
combine this artifact with another Go or gomobile library in the same process.
