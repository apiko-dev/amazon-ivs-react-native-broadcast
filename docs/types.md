# **Types**

## `IVideoConfig`

| Key | Type | Range | Description |
| :---: | :---: | :---: | --- |
| `width` | `number` | `160` - `1920` | The width of the output video stream |
| `height` | `number` | `160` - `1920` | The height of the output video stream |
| `bitrate` | `number` | `100000` - `8500000` | Initial bitrate for the output video stream |
| `targetFrameRate` | `number` | `10` - `60`| The target framerate of the output video stream |
| `keyframeInterval` | `number` | `1` - `5` | The keyframe interval for the output video stream |
| `isBFrames` | `boolean?` | | Whether the output video stream uses B (Bidirectional predicted picture) frames |
| `isAutoBitrate` | `boolean?` | | Whether the output video stream will automatically adjust the bitrate based on network conditions. Use `minBitrate` and `maxBitrate` values to specify the bounds when this value is `true` |
| `maxBitrate` | `number?` | `100000` - `8500000` | The maximum bitrate for the output video stream |
| `minBitrate` | `number?` | `100000` - `8500000` | The minimum bitrate for the output video stream |

⚠️ _The `width` and `height` must both be between `160` and `1920`, and the maximum total number of pixels is `2,073,600.` So the smallest size is `160x160`, and the largest is either `1080x1920` or `1920x1080`. However something like `1920x1200` would not be worked. `1280x180` however is supported._

⚠️ _Bitrate, FPS, and resolution are interrelated that's why they are mandatory when `videoConfig` prop is in use._

## `IAudioConfig`
| Key | Type | Range | Platform | Description |
| :---: | :---: | :---: | :---: | --- |
| `bitrate` | `number?` | `64000` - `160000` | iOS, Android | The average bitrate for the final output audio stream |
| `channels` | [`AudioChannel?`](#audiochannel) | | iOS, Android | The number of channels for the output audio stream |
| `audioSessionStrategy` | [`AudioSessionStrategy?`](#audiosessionstrategy-ios-only) | | iOS | A value representing how the broadcast session will interact with `AVAudioSession`. |
| `quality` | [`AudioQuality?`](#audioquality-ios-only) | | iOS | The quality of the audio encoding. |

⚠️ _AirPods do not record any audio if the `audioSessionStrategy` is set to `recordOnly`. By default, the `playAndRecord` value is used, so this issue manifests only if the value is changed to `recordOnly`._

⚠️ _Reducing the audio `quality` can have a large impact on CPU usage._

## `AudioChannel`

```ts
type AudioChannel = 1 | 2;
```
| Value | Description |
| :---: | --- |
| `1` | Mono audio channel |
| `2` | Stereo audio channel |

## `AudioSessionStrategy` (iOS only)

```ts
type AudioSessionStrategy = 'recordOnly' | 'playAndRecord' | 'noAction';
```
| Value | Description |
| :---: | --- |
| `recordOnly` | Controls `AVAudioSession` completely and will set the category to `record`. There is a known issue with the `recordOnly` category and AirPods. Use `playAndRecord` category to make AirPods work. |
| `playAndRecord` | Controls `AVAudioSession` completely and will set the category to `playAndRecord`. |
| `noAction` | Does not control `AVAudioSession` at all. If this strategy is selected, only custom audio sources will be allowed. Microphone based sources will not be returned or added by any APIs. |

## `AudioQuality` (iOS only)

```ts
type AudioQuality = 'minimum' | 'low' | 'medium' | 'high' | 'maximum';
```

## `LogLevel`

```ts
type LogLevel = 'debug' | 'error' | 'info' | 'warning';
```

| Value | Description |
| :---: | --- |
| `debug` | Debugging messages, potentially quite verbose |
| `error` | Error conditions and faults |
| `info` | Informational messages |
| `warning` | Warning messages |

## `CameraPreviewAspectMode`

```ts
type CameraPreviewAspectMode = 'fit' | 'fill' | 'none';
```

| Value | Description |
| :---: | --- |
| `fit` | Will fit the entire image within the bounding area while maintaining the correct aspect ratio. in practice this means that there will be letterboxing or pillarboxing |
| `fill` | Will fill the bounding area with the image while maintaining the aspect ratio. in practice this means that the image will likely be cropped |
| `none` | Will simply fill the bounding area with the image, disregarding the aspect ratio |

## `CameraPosition`

```ts
type CameraPosition = 'front' | 'back';
```

| Value | Description |
| :---: | --- |
| `front` | The input device is located on the front of the host device |
| `back` | The input device is located on the back of the host device |

## `StateStatusUnion`

```ts
type StateStatusUnion = "INVALID" | "DISCONNECTED" | "CONNECTING" | "CONNECTED" | "ERROR"
```

| Value | Description |
| :---: | --- |
| `INVALID` | The session is invalid. This is the initial state after creating a session but before starting a stream |
| `DISCONNECTED` | The session has disconnected. After stopping a stream the session should return to this state unless it has errored |
| `CONNECTING` | The session is connecting to the ingest server |
| `CONNECTED` | The session has connected to the ingest server and is currently sending data |
| `ERROR` | The session has had an error |

## `IBroadcastSessionError`

```ts
interface IBroadcastSessionError {
  readonly code: string;
  readonly type: string;
  readonly source: string;
  readonly detail: string;
  readonly isFatal: boolean;
}
```

👉 See iOS `code` [enumeration](https://aws.github.io/amazon-ivs-broadcast-docs/1.2.0/ios/Enums/IVSBroadcastError.html#/c:@E@IVSBroadcastError@IVSBroadcastErrorDeviceExchangeIncompatibleTypes).

👉 See Android `type` [enumeration](https://aws.github.io/amazon-ivs-broadcast-docs/1.2.1/android/reference/com/amazonaws/ivs/broadcast/ErrorType.html).

## `IAudioStats`

| Key | Type | Range | Description |
| :---: | :---: | :---: | --- |
| `peak` | `number?` | `-100` - `0` | Audio Peak over the time period |
| `rms` | `number?` | `-100` - `0` | Audio RMS over the time period |

A value of `-100` means silent.