# **Types**

### Reference documentation

👉 [iOS SDK](https://aws.github.io/amazon-ivs-broadcast-docs/1.5.1/ios/index.html)

👉 [Android SDK](https://aws.github.io/amazon-ivs-broadcast-docs/1.5.0/android/reference/com/amazonaws/ivs/broadcast/package-summary.html)

## `ConfigurationPreset`

Amazon IVS supports two channel types. Channel type determines the allowable resolution and bitrate.

|    Type    | Description                                                                                                                                                                                                                                                                                                              |
| :--------: | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `standard` | Multiple qualities are generated from the original input, to automatically give viewers the best experience for their devices and network conditions. Resolution can be up to `1080p` and bitrate can be up to `8.5 Mbps`. Audio is transcoded only for renditions `360p` and below; above that, audio is passed through |
|  `basic`   | Amazon IVS delivers the original input to viewers. The viewer’s video-quality choice is limited to the original input. Resolution can be up to `480p` and bitrate can be up to `1.5 Mbps`                                                                                                                                |

```ts
type ConfigurationPreset =
  | 'standardPortrait'
  | 'standardLandscape'
  | 'basicPortrait'
  | 'basicLandscape';
```

|        Value        | Description                                                   |
| :-----------------: | ------------------------------------------------------------- |
| `standardPortrait`  | A preset appropriate for streaming basic content in Portrait  |
| `standardLandscape` | A preset appropriate for streaming basic content in Landscape |
|   `basicPortrait`   | A preset that is usable with the Basic channel type           |
|  `basicLandscape`   | A preset that is usable with the Basic channel type           |

## `IVideoConfig`

```ts
interface IVideoConfig {
  readonly width?: number;
  readonly height?: number;
  readonly bitrate?: number;
  readonly targetFrameRate?: number;
  readonly keyframeInterval?: KeyframeInterval;
  readonly isBFrames?: boolean;
  readonly isAutoBitrate?: boolean;
  readonly maxBitrate?: number;
  readonly minBitrate?: number;
}
```

|        Key         |                   Type                   |        Range         |   Platform   | Description                                                                                                                                                                                 |
| :----------------: | :--------------------------------------: | :------------------: | :----------: | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|      `width`       |                `number?`                 |    `160` - `1920`    | iOS, Android | The width of the output video stream                                                                                                                                                        |
|      `height`      |                `number?`                 |    `160` - `1920`    | iOS, Android | The height of the output video stream                                                                                                                                                       |
|     `bitrate`      |                `number?`                 | `100000` - `8500000` | iOS, Android | Initial bitrate for the output video stream                                                                                                                                                 |
| `targetFrameRate`  |                `number?`                 |     `10` - `60`      | iOS, Android | The target framerate of the output video stream                                                                                                                                             |
| `keyframeInterval` | [`KeyframeInterval?`](#keyframeinterval) |      `1` - `5`       | iOS, Android | The keyframe interval for the output video stream                                                                                                                                           |
|    `isBFrames`     |                `boolean?`                |          -           | iOS, Android | Whether the output video stream uses B (Bidirectional predicted picture) frames                                                                                                             |
|  `isAutoBitrate`   |                `boolean?`                |          -           | iOS, Android | Whether the output video stream will automatically adjust the bitrate based on network conditions. Use `minBitrate` and `maxBitrate` values to specify the bounds when this value is `true` |
|    `maxBitrate`    |                `number?`                 | `100000` - `8500000` | iOS, Android | The maximum bitrate for the output video stream                                                                                                                                             |
|    `minBitrate`    |                `number?`                 | `100000` - `8500000` | iOS, Android | The minimum bitrate for the output video stream                                                                                                                                             |

⚠️ _The `width` and `height` are interrelated and thus can not be used separately._

⚠️ _The `width` and `height` must both be between `160` and `1920`, and the maximum total number of pixels is `2,073,600.` So the smallest size is `160x160`, and the largest is either `1080x1920` or `1920x1080`. However something like `1920x1200` would not be worked. `1280x180` however is supported._

## `KeyframeInterval`

```ts
type KeyframeInterval = 1 | 2 | 3 | 4 | 5;
```

## `IAudioConfig`

```ts
interface IAudioConfig {
  readonly bitrate?: number;
  readonly channels?: AudioChannel;
  readonly audioSessionStrategy?: AudioSessionStrategy;
  readonly quality?: AudioQuality;
}
```

|          Key           |                           Type                            |       Range        |   Platform   | Description                                                                        |
| :--------------------: | :-------------------------------------------------------: | :----------------: | :----------: | ---------------------------------------------------------------------------------- |
|       `bitrate`        |                         `number?`                         | `64000` - `160000` | iOS, Android | The average bitrate for the final output audio stream                              |
|       `channels`       |             [`AudioChannel?`](#audiochannel)              |         -          | iOS, Android | The number of channels for the output audio stream                                 |
| `audioSessionStrategy` | [`AudioSessionStrategy?`](#audiosessionstrategy-ios-only) |         -          |     iOS      | A value representing how the broadcast session will interact with `AVAudioSession` |
|       `quality`        |         [`AudioQuality?`](#audioquality-ios-only)         |         -          |     iOS      | The quality of the audio encoding                                                  |

## `AudioChannel`

```ts
type AudioChannel = 1 | 2;
```

| Value | Description          |
| :---: | -------------------- |
|  `1`  | Mono audio channel   |
|  `2`  | Stereo audio channel |

## `AudioSessionStrategy` (iOS only)

```ts
type AudioSessionStrategy =
  | 'recordOnly'
  | 'playAndRecord'
  | 'playAndRecordDefaultToSpeaker'
  | 'noAction';
```

|              Value              | Description                                                                                                                                                                                      |
| :-----------------------------: | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
|          `recordOnly`           | Controls `AVAudioSession` completely and will set the category to `record`. There is a known issue with the `recordOnly` category and AirPods. Use `playAndRecord` category to make AirPods work |
|         `playAndRecord`         | Controls `AVAudioSession` completely and will set the category to `playAndRecord`                                                                                                                |
| `playAndRecordDefaultToSpeaker` | Controls the `AVAudioSession` completely and will set the category to `playAndRecord`. On devices with both handset and speaker, the speaker will be preferred                                   |
|           `noAction`            | Does not control `AVAudioSession` at all. If this strategy is selected, only custom audio sources will be allowed. Microphone based sources will not be returned or added by any APIs            |

⚠️ _AirPods do not record any audio if the `audioSessionStrategy` is set to `recordOnly`. By default, the `playAndRecord` value is used, so this issue manifests only if the value is changed to `recordOnly`._

## `AudioQuality` (iOS only)

```ts
type AudioQuality = 'minimum' | 'low' | 'medium' | 'high' | 'maximum';
```

⚠️ _Reducing the audio `quality` can have a large impact on CPU usage._

## `LogLevel`

```ts
type LogLevel = 'debug' | 'error' | 'info' | 'warning';
```

|   Value   | Description                                   |
| :-------: | --------------------------------------------- |
|  `debug`  | Debugging messages, potentially quite verbose |
|  `error`  | Error conditions and faults                   |
|  `info`   | Informational messages                        |
| `warning` | Warning messages                              |

## `CameraPreviewAspectMode`

```ts
type CameraPreviewAspectMode = 'fit' | 'fill' | 'none';
```

| Value  | Description                                                                                                                                                           |
| :----: | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `fit`  | Will fit the entire image within the bounding area while maintaining the correct aspect ratio. in practice this means that there will be letterboxing or pillarboxing |
| `fill` | Will fill the bounding area with the image while maintaining the aspect ratio. in practice this means that the image will likely be cropped                           |
| `none` | Will simply fill the bounding area with the image, disregarding the aspect ratio                                                                                      |

## `CameraPosition`

```ts
type CameraPosition = 'front' | 'back';
```

|  Value  | Description                                                 |
| :-----: | ----------------------------------------------------------- |
| `front` | The input device is located on the front of the host device |
| `back`  | The input device is located on the back of the host device  |

## `StateStatusUnion`

```ts
type StateStatusUnion =
  | 'INVALID'
  | 'DISCONNECTED'
  | 'CONNECTING'
  | 'CONNECTED'
  | 'ERROR';
```

|     Value      | Description                                                                                                         |
| :------------: | ------------------------------------------------------------------------------------------------------------------- |
|   `INVALID`    | The session is invalid. This is the initial state after creating a session but before starting a stream             |
| `DISCONNECTED` | The session has disconnected. After stopping a stream the session should return to this state unless it has errored |
|  `CONNECTING`  | The session is connecting to the ingest server                                                                      |
|  `CONNECTED`   | The session has connected to the ingest server and is currently sending data                                        |
|    `ERROR`     | The session has had an error                                                                                        |

## `IBroadcastSessionError`

```ts
interface IBroadcastSessionError {
  readonly code: string;
  readonly type: string;
  readonly source: string;
  readonly detail: string;
  readonly isFatal: boolean;
  readonly sessionId: string;
}
```

|     Key     | Description                                                                              |
| :---------: | ---------------------------------------------------------------------------------------- |
| `sessionId` | The unique `ID` of the broadcast session. It is updated every time the stream is stopped |

👉 See iOS `code` [enumeration](https://aws.github.io/amazon-ivs-broadcast-docs/1.2.0/ios/Enums/IVSBroadcastError.html#/c:@E@IVSBroadcastError@IVSBroadcastErrorDeviceExchangeIncompatibleTypes).

👉 See Android `type` [enumeration](https://aws.github.io/amazon-ivs-broadcast-docs/1.2.1/android/reference/com/amazonaws/ivs/broadcast/ErrorType.html).

## `IAudioStats`

```ts
interface IAudioStats {
  readonly peak: number;
  readonly rms: number;
}
```

|  Key   |    Range     | Description                     |
| :----: | :----------: | ------------------------------- |
| `peak` | `-100` - `0` | Audio Peak over the time period |
| `rms`  | `-100` - `0` | Audio RMS over the time period  |

A value of `-100` means silent.

## `StartMethodOptions`

```ts
type StartMethodOptions = {
  readonly rtmpsUrl?: string;
  readonly streamKey?: string;
};
```

|     Key     | Description                                   |
| :---------: | --------------------------------------------- |
| `rtmpsUrl`  | [rtmpsUrl](./api-documentation.md#rtmpsurl)   |
| `streamKey` | [streamKey](./api-documentation.md#streamkey) |

## `StateChangedMetadata`

```ts
type StateChangedMetadata = IConnectedStateMetadata;
```

##### `IConnectedStateMetadata`

```ts
interface IConnectedStateMetadata {
  sessionId: string;
}
```

|    Value    | Description                                                                              |
| :---------: | ---------------------------------------------------------------------------------------- |
| `sessionId` | The unique `ID` of the broadcast session. It is updated every time the stream is stopped |

## `ITransmissionStatistics`

```ts
interface ITransmissionStatistics {
  rtt: number;
  recommendedBitrate: number;
  measuredBitrate: number;
  networkHealth: NetworkHealth;
  broadcastQuality: BroadcastQuality;
}
```

|                  Value                  | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| :-------------------------------------: | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|                  `rtt`                  | The current average round trip time for network packets (not image or audio samples)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
|          `recommendedBitrate`           | The bitrate currently recommended by the SDK. Depending on network conditions, the SDK may recommend a higher or lower bitrate to preserve the stability of the broadcast, within the constraints of the minimum, maximum, and initial bitrates configured by the application in BroadcastConfiguration                                                                                                                                                                                                                                                                                                                                                                                                              |
|            `measuredBitrate`            | The current measured average sending bitrate. Note that the device’s video encoder is often unable to match exactly the SDK’s recommended bitrate. There can be some delay between the SDK’s recommended bitrate and the video encoder responding to the recommendation                                                                                                                                                                                                                                                                                                                                                                                                                                              |
|    [`NetworkHealth`](#networkhealth)    | Represents the current health of the network. `BAD` means the network is struggling to keep up and the broadcast may be experiencing latency spikes. The SDK may also reduce the quality of the broadcast on low values in order to keep it stable, depending on the minimum allowed bitrate in the broadcast configuration. A value of `EXCELLENT` means the network is easily able to keep up with the current demand and the SDK will be trying to increase the broadcast quality over time, depending on the maximum allowed bitrate. Values like `MEDIUM` or `LOW` are not necessarily bad, it just means the network is being saturated, but it is still able to keep up. The broadcast is still likely stable |
| [`BroadcastQuality`](#broadcastquality) | Represents the quality of the stream based on the bitrate minimum and maximum provided on session configuration. If the video configuration looks like: initial bitrate = 1000 kbps minimum bitrate = 300 kbps maximum bitrate = 5,000 kbps It will be expected that a nearMinimum quality is provided to this callback initially, since the initial bitrate is much closer to the minimum allowed bitrate than the maximum. If network conditions are good, the quality should improve over time towards nearMaximum                                                                                                                                                                                                |

⚠️ _**Measured** versus **recommended** bitrate behavior can vary significantly between platforms._

##### `NetworkHealth`

```ts
type NetworkHealth = 'EXCELLENT' | 'HIGH' | 'MEDIUM' | 'LOW' | 'BAD';
```

|     Key     | Description                                                                                            |
| :---------: | ------------------------------------------------------------------------------------------------------ |
| `EXCELLENT` | The network is easily able to keep up with the current broadcast                                       |
|   `HIGH`    | The network keeping up with the broadcast well but the connection is not perfect                       |
|  `MEDIUM`   | The network is experiencing some congestion but it can still keep up with the correct quality          |
|    `LOW`    | The network is struggling to keep up with the current video quality and may reduce quality             |
|    `BAD`    | The network can not keep up with the current video quality and will be reducing the quality if allowed |

##### `BroadcastQuality`

```ts
type BroadcastQuality =
  | 'NEAR_MAXIMUM'
  | 'HIGH'
  | 'MEDIUM'
  | 'LOW'
  | 'NEAR_MINIMUM';
```

|      Key       | Description                                                                                                      |
| :------------: | ---------------------------------------------------------------------------------------------------------------- |
| `NEAR_MAXIMUM` | Bitrate is near the maximum allowed (the configured maximum bitrate)                                             |
|     `HIGH`     | The broadcast is at a high quality relative to the provided bounds                                               |
|    `MEDIUM`    | The broadcast is at a medium quality relative to the provided bounds                                             |
|     `LOW`      | The broadcast is at a low quality relative to the provided bounds                                                |
| `NEAR_MINIMUM` | Stream is near the lowest possible quality (the configured minimum bitrate), or streaming is not possible at all |
