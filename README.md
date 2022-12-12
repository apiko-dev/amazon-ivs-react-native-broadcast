# **Amazon IVS React Native Broadcast**

A React Native wrapper for the Amazon IVS iOS and Android broadcast SDKs.

[![npm version](https://badge.fury.io/js/amazon-ivs-react-native-broadcast.svg)](https://www.npmjs.com/package/amazon-ivs-react-native-broadcast)
[![npm](https://img.shields.io/npm/dt/amazon-ivs-react-native-broadcast.svg)](https://www.npmjs.com/package/amazon-ivs-react-native-broadcast)
[![MIT](https://img.shields.io/dub/l/vibe-d.svg)](https://opensource.org/licenses/MIT)
[![Platform - Android](https://img.shields.io/badge/platform-Android-3ddc84.svg?style=flat&logo=android)](https://www.android.com)
[![Platform - iOS](https://img.shields.io/badge/platform-iOS-000.svg?style=flat&logo=apple)](https://developer.apple.com/ios)

⚠️ _Note that the current module implementation doesn't support full functionality provided by Amazon IVS iOS and Android broadcast SDKs._

⚠️ _Apps using `amazon-ivs-react-native-broadcast` must target **iOS 11** and **Android 12 (API 31)**._

---

👉 [Read more](https://docs.aws.amazon.com/ivs/latest/userguide/broadcast.html) about broadcasting to Amazon IVS.

👉 [See](https://docs.aws.amazon.com/ivs/latest/userguide/streaming-config.html) Amazon IVS streaming configuration guideline.

## Installation

```sh
$ yarn add amazon-ivs-react-native-broadcast
# --- or ---
$ npm install amazon-ivs-react-native-broadcast
$ cd ios && pod install && cd ..
```

# `IVSBroadcastCameraView` component

Allows consumers to stream video from an active phone camera.

## ⚠️ Requirements

An application must request permission to access the user’s camera and microphone. This isn't specific to the component but required for any application that needs access to the cameras and microphones.

#### **iOS**

Add `NSCameraUsageDescription` and `NSMicrophoneUsageDescription` keys to the `Info.plist` file:

```xml
...
<key>NSCameraUsageDescription</key>
<string>In order to stream your awesome video, allow access to camera please</string>
<key>NSMicrophoneUsageDescription</key>
<string>In order to stream your awesome audio, allow access to microphone please</string>
...
```

#### **Android**

Add `CAMERA` and `RECORD_AUDIO` permissions to the `AndroidManifest.xml` file:

```xml
...
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
...
```

> ⚠️ _On devices before SDK version 23, the permissions are automatically granted if they appear in the manifest, so check should always result to `true` and request should always resolve to `PermissionsAndroid.RESULTS.GRANTED`, however if your app is installed on a device that runs Android 6.0 or higher, **you must request** the \_dangerous permissions_ at runtime manually.\_

Example of requesting Android dangerous permissions at runtime could be found in the [`./example/src/index.android.tsx`](./example/src/index.android.tsx) file.

## API

|                                      Props                                       |            Type            | iOS | Android |
| :------------------------------------------------------------------------------: | :------------------------: | :-: | :-----: |
|                [`rtmpsUrl`](./docs/api-documentation.md#rtmpsurl)                |         `string?`          | ✅  |   ✅    |
|               [`streamKey`](./docs/api-documentation.md#streamkey)               |         `string?`          | ✅  |   ✅    |
|     [`configurationPreset`](./docs/api-documentation.md#configurationpreset)     |   `ConfigurationPreset?`   | ✅  |   ✅    |
|             [`videoConfig`](./docs/api-documentation.md#videoconfig)             |      `IVideoConfig?`       | ✅  |   ✅    |
|             [`audioConfig`](./docs/api-documentation.md#audioconfig)             |      `IAudioConfig?`       | ✅  |   ✅    |
|                [`logLevel`](./docs/api-documentation.md#loglevel)                |        `LogLevel?`         | ✅  |   ✅    |
|         [`sessionLogLevel`](./docs/api-documentation.md#sessionloglevel)         |        `LogLevel?`         | ✅  |   ✅    |
| [`cameraPreviewAspectMode`](./docs/api-documentation.md#camerapreviewaspectmode) | `CameraPreviewAspectMode?` | ✅  |   ✅    |
| [`isCameraPreviewMirrored`](./docs/api-documentation.md#iscamerapreviewmirrored) |         `boolean?`         | ✅  |   ✅    |
|          [`cameraPosition`](./docs/api-documentation.md#cameraposition)          |     `CameraPosition?`      | ✅  |   ✅    |
|                 [`isMuted`](./docs/api-documentation.md#ismuted)                 |         `boolean?`         | ✅  |   ✅    |

|                                             Handlers                                             |                                   Type                                    | iOS | Android |
| :----------------------------------------------------------------------------------------------: | :-----------------------------------------------------------------------: | :-: | :-----: |
|                         [`onError`](./docs/api-documentation.md#onerror)                         |                      `(errorMessage: string): void?`                      | ✅  |   ✅    |
|                [`onBroadcastError`](./docs/api-documentation.md#onbroadcasterror)                |                 `(error: IBroadcastSessionError): void?`                  | ✅  |   ✅    |
|              [`onIsBroadcastReady`](./docs/api-documentation.md#onisbroadcastready)              |                        `(isReady: boolean): void?`                        | ✅  |   ✅    |
|           [`onBroadcastAudioStats`](./docs/api-documentation.md#onbroadcastaudiostats)           |                    `(audioStats: IAudioStats): void?`                     | ✅  |   ✅    |
|         [`onBroadcastStateChanged`](./docs/api-documentation.md#onbroadcaststatechanged)         | `(stateStatus: StateStatusUnion, metadata?: StateChangedMetadata): void?` | ✅  |   ✅    |
| [`onTransmissionStatisticsChanged`](./docs/api-documentation.md#ontransmissionstatisticschanged) |        `(transmissionStatistics: ITransmissionStatistics): void?`         | ✅  |   ✅    |
|       [`onAudioSessionInterrupted`](./docs/api-documentation.md#onaudiosessioninterrupted)       |                                `(): void?`                                | ✅  |   🚫    |
|           [`onAudioSessionResumed`](./docs/api-documentation.md#onaudiosessionresumed)           |                                `(): void?`                                | ✅  |   🚫    |
|         [`onMediaServicesWereLost`](./docs/api-documentation.md#onmediaserviceswerelost)         |                                `(): void?`                                | ✅  |   🚫    |
|        [`onMediaServicesWereReset`](./docs/api-documentation.md#onmediaserviceswerereset)        |                                `(): void?`                                | ✅  |   🚫    |

|                   Methods                    |                  Type                  | iOS | Android |
| :------------------------------------------: | :------------------------------------: | :-: | :-----: |
| [`start`](./docs/api-documentation.md#start) | `(options?: StartMethodOptions): void` | ✅  |   ✅    |
|  [`stop`](./docs/api-documentation.md#stop)  |               `(): void`               | ✅  |   ✅    |

👉 Read more detailed [API documentation](docs/api-documentation.md).

👉 [iOS](https://docs.aws.amazon.com/ivs/latest/userguide/broadcast-ios.html#broadcast-ios-issues) and [Android](https://docs.aws.amazon.com/ivs/latest/userguide/broadcast-android.html#broadcast-android-issues) known issues and workarounds.

## Usage

A complex usage could be found in the [`./example/src/App.tsx`](./example/src/App.tsx) file or just go to the [`./example`](./example/) folder and read _Setting up and running application_ section how to set up and run the example app to see `IVSBroadcastCameraView` component in action.

---

## License

[MIT](LICENSE)

## Credits

This project has been built and is maintained thanks to the support from [Apiko](https://apiko.com/).

<img alt="Apiko" src="./assets/ApikoLogo.png"/>
