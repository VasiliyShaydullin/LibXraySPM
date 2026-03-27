# VlessSPM

Swift Package wrapper for `Vless.xcframework`.

## Installation

Add the package in Xcode with:

```text
https://github.com/VasiliyShaydullin/LibXraySPM.git
```

Use branch:

```text
vless-spm
```

Or use the release tag:

```text
25.12.8-vless.1
```

## Usage

Import the package:

```swift
import VlessSPM
```

The public interface is kept compatible with the previous wrapper:

```swift
let response = try LibXraySPM.run(
    datDir: datDir,
    configPath: configPath,
    maxMemory: nil
)
```

You can also use the new package-facing alias:

```swift
let response = try VlessSPM.run(
    datDir: datDir,
    configPath: configPath,
    maxMemory: nil
)
```

## Notes

- Package product name: `VlessSPM`
- Binary artifact is distributed via GitHub Releases
- Existing `LibXraySPM` API names remain available for compatibility
