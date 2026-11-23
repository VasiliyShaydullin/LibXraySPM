# VlessSPM

Swift Package wrapper for libXray v26.11.9.

## Installation

Add `https://github.com/VasiliyShaydullin/LibXraySPM.git` in Xcode and select
the `vless-spm` branch for the platform declarations and API described below.
The existing `26.11.9` tag predates these changes. The binary artifact is
distributed via GitHub Releases.

## Supported platforms

- iOS 15+ (arm64 devices; arm64 and x86_64 simulators)
- macOS 13+ (arm64 and x86_64)
- tvOS 17+ (arm64 devices; arm64 and x86_64 simulators)

The supplied XCFramework does not include Mac Catalyst, watchOS or visionOS
binary slices.

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

`decodeSubscriptionText` unwraps optional Age-encrypted subscription text;
`convertShareLinks` parses links or subscriptions into an object containing
`outbounds`, decoded into a caller-supplied type. To retain fields your type
doesn't model, use raw `invoke(_:)` instead. `convertXrayJsonToShareLinks`
returns the generated links. Check `success` and `error` for each operation.

```swift
struct Outbounds: Decodable {
    struct Outbound: Decodable {
        let `protocol`: String
        let tag: String?
    }
    let outbounds: [Outbound]
}

let subscription = try VlessSPM.decodeSubscriptionText(text, ageSecretKey: nil)
let config = try VlessSPM.convertShareLinks(text, dataType: Outbounds.self)
let links = try VlessSPM.convertXrayJsonToShareLinks(configJSON)
```

`pingBatch` accepts one to five configurations, a positive timeout in seconds
and an absolute HTTP(S) URL. It is synchronous: run it off the main thread.
The top-level success only means the batch was accepted; inspect each result's
`success`, `delay` (milliseconds) and `error`. Xray must be stopped before
`pingBatch` or `test`; these methods use a temporary instance. Ping uses only
the `outbounds` from each configuration and ignores its other root fields.

Other API v3 methods can be called with a custom `Encodable` payload and
`Decodable` response:

```swift
struct KeyPairRequest: Encodable { let keyType: String }
struct KeyPair: Decodable {
    let secretKey: String
    let publicKey: String
}

let response = try VlessSPM.invoke(
    method: "generateAgeKeyPair",
    payload: KeyPairRequest(keyType: "x25519"),
    dataType: KeyPair.self
)
```

Store the secret key securely; never log it or send it to a server.

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
conversion uses the API v3 payload and response shapes.

Only one independently built Go runtime may be loaded per process; do not
combine this artifact with another Go or gomobile library in the same process.
