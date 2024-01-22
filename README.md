# MUSAP iOS Library

MUSAP (Multiple SSCDs with Unified Signature API) is an iOS library designed to simplify the integration of multiple Secure Signature Creation Devices (SSCD) with a unified signature API.
It provides a set of tools and utilities to streamline the implementation of secure signature creation mechanisms in Android applications.

## Features
* **Multiple SSCD Integration**: MUSAP simplifies the integration of multiple Secure Signature Creation Devices into your iOS application.
* **Unified Signature API**: Utilize a unified API for signature operations, abstracting the complexities of individual SSCD implementations.
* **Secure Signature Creation**: Implement secure and standardized methods for creating digital signatures within your application.
* **Customizable**: MUSAP is designed with flexibility in mind, allowing developers to customize and extend its functionality according to specific project requirements.

## Installing

To integrate MUSAP into your iOS project, follow these steps:

1. Add the following dependency to your app's build.gradle file:

```gradle
    implementation (files("libs/musap-[version].aar"))
```

2. Add the following dependencies required by the MUSAP library:
```gradle
    implementation("com.squareup.okhttp3:okhttp:4.10.0")
    implementation("com.google.code.gson:gson:2.8.8")
    implementation ("org.slf4j:slf4j-api:2.0.7")
    implementation("org.bouncycastle:bcpkix-jdk15to18:1.71")
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    implementation("com.google.firebase:firebase-messaging")
```

## Usage

### Enabling an SSCD

Call `MusapClient.init()` and `MusapClient.enableSscd()`

```java
public class MyApplication extends Application {

    @Override
    public void onCreate() {
        super.onCreate();
        MusapClient.init(this);
        MusapClient.enableSscd(new AndroidKeystoreSscd(this));
        MusapClient.enableSscd(new YubiKeySscd(this));
    }
}

```

### Generating a key

Create a key generation request and call `MusapClient.generateKey()`. The key generation result is delivered asynchronously through the given callback.

```java
KeyGenReq req = new KeyGenReqBuilder()
        .setActivity(this.getActivity())
        .setView(this.getView())
        .setAlias("my key")
        .setKeyAlgorithm(KeyAlgorithm.RSA_2K)
        .createKeyGenReq();

MusapClient.generateKey(sscd, req, new MusapCallback<MusapKey>() {
    @Override
    public void onSuccess(MusapKey result) {
        MLog.d("Successfully generated key " + alias);
    }

    @Override
    public void onException(MusapException e) {
        MLog.e("Failed to generate key " + alias, e);
    }
});

```

### Signing

Select a key, create a signature request and a `MusapSigner`. Finally call `MusapSigner.sign()`. The signature result is delivered asynchronously through the given callback.

```java
MusapKey       key = MusapClient.getKeyByUri(keyuri);
SignatureReq   req = new SignatureReqBuilder().setKey(key).setData(data).setActivity(this.getActivity()).createSignatureReq();
MusapSigner signer = new MusapSigner(key, this.getActivity());

try {
    signer.sign(data, new MusapCallback<MusapSignature>() {
        @Override
        public void onSuccess(MusapSignature mSig) {
            String signatureStr = mSig.getB64Signature();
            MLog.d("Signature successful: " + signatureStr);
        }

        @Override
        public void onException(MusapException e) {
            MLog.e("Failed to sign", e.getCause());
        }
    });
} catch (MusapException e) {
    MLog.e("Failed to sign", e.getCause());
}

```

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.


