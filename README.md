# MUSAP iOS Library

MUSAP (Multiple SSCDs with Unified Signature API) is an iOS library designed to simplify the integration of multiple Secure Signature Creation Devices (SSCD) with a unified signature API.
It provides a set of tools and utilities to streamline the implementation of secure signature creation mechanisms in Android applications.

## Features
* **Multiple SSCD Integration**: MUSAP simplifies the integration of multiple Secure Signature Creation Devices into your iOS application.
* **Unified Signature API**: Utilize a unified API for signature operations, abstracting the complexities of individual SSCD implementations.
* **Secure Signature Creation**: Implement secure and standardized methods for creating digital signatures within your application.
* **Customizable**: MUSAP is designed with flexibility in mind, allowing developers to customize and extend its functionality according to specific project requirements.

### Reference implementation app

We have a reference implementation app available that serves as an example on how to use the library.
You can find the app project from https://github.com/methics/MUSAP-Demo-App-iOS

## Installing

To integrate MUSAP into your iOS project, follow these steps:

1. Open your Xcode project.

2. Go to "File" > "Swift Packages" > "Add Package Dependency..."

3. Enter the URL for musap-ios, which is https://github.com/methics/musap-ios

4. Choose the version or branch you want to use.

5. Click "Next" and then "Finish."          


## Usage

### Enabling an SSCD

Call `MusapClient.enableSscd()`

```swift
import SwiftUI
import musap_ios

@main
struct MyApp: App {

    init() {
        // Enable SSCDs. For example YubikeySscd
        MusapClient.enableSscd(sscd: YubikeySscd())
    }

    var body: some Scene {
        WindowGroup {
            NavigationTabView()
        }
    }
}


MusapClient.enableSscd(sscd: YubikeySscd())

```

### Generating a key

Create a key generation request and call `MusapClient.generateKey()`. The key generation result is delivered asynchronously through the given callback.

```swift
let sscdImplementation = YubikeySscd()
let keyAlgo            = KeyAlgorithm(primitive: KeyAlgorithm.PRIMITIVE_EC, bits: 384)
let keyGenReq          = KeyGenReq(keyAlias: self.keyAlias, role: "personal", keyAlgorithm: keyAlgo)

Task {

await MusapClient.generateKey(sscd: sscdImplementation, req: keyGenReq) {
    result in


    switch result {
    case .success(let musapKey):
        print("Success! Keyname: \(String(describing: musapKey.getKeyAlias()))")
        print("Musap Key:        \(String(describing: musapKey.getPublicKey()?.getPEM()))")

        print("isEC? \(String(describing: musapKey.getAlgorithm()?.isEc()))")
        print("isRSA? \(String(describing: musapKey.getAlgorithm()?.isRsa()))")
        print("Bits: \(String(describing: musapKey.getAlgorithm()?.bits))")

    case .failure(let error):
        print("ERROR: \(error.errorCode)")
        print(error.localizedDescription)
        self.errorMessage = "Error creating musap key"
        self.isErrorPopupVisible = true
    }
}
}

```

### Signing

Select a key, create a signature request and a `MusapSigner`. Finally call `MusapSigner.sign()`. The signature result is delivered asynchronously through the given callback.

```swift
let algo = SignatureAlgorithm(algorithm: .ecdsaSignatureMessageX962SHA256)
let signatureFormat = SignatureFormat("RAW")

let sigReq = SignatureReq(key: musapKey, data: data, algorithm: algo, format: signatureFormat, displayText: "Display text", attributes: [SignatureAttribute(name: "someKey", value: "SomeValue")])


Task {
    await MusapClient.sign(req: sigReq) { result in

        switch result {
        case .success(let musapSignature):
            print("Success!")
            print(" B64 signature: \(musapSignature.getB64Signature()) ")
            base64Signature = musapSignature.getB64Signature()
        case .failure(let error):
            print("ERROR: \(error.localizedDescription)")
        }
    }

}
```

### Get enabled SSCDs
```swift
guard let enabledSscds = MusapClient.listEnabledSscds() else {
    print("No enabled SSCDs")
    return
}

for sscd in enabledSscds {
    // Get SSCD name so we can display it in a list
    guard let sscdName = sscd.getSscdInfo().sscdName else {
        print("No name for sscd ")
        continue
    }
    print("SSCD: \(sscdName)")

    enabledSscdList.append(sscd.getSscdInfo())
}
```

### Get active SSCDs

```swift
let activeSscds = MusapClient.listActiveSscds()

for sscd in activeSscds {
    // get something from sscd, like name to display in a list
    guard let sscdName = sscd.sscdName else {
        print("SSCD does not have a name set")
        continue
    }

    activeSscdList.append(sscd)
}

```


## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.


