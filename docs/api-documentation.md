# **API Documentation**

## `IVSBroadcastCameraView` component

### _**Props**_

#### `style` ๐

Style of `IVSBroadcastCameraView` component. 

| Type | Required | Platform |
| :---: | :---: | :---: |
| `StyleProp<ViewStyle>` | No | iOS, Android |

#### `testID` ๐

Used to locate `IVSBroadcastCameraView` component in the end-to-end tests.

| Type | Required | Platform |
| :---: | :---: | :---: |
| `string` | No | iOS, Android |

#### `rtmpsUrl` ๐

The RTMPS endpoint provided by IVS.

| Type | Required | Platform |
| :---: | :---: | :---: |
| `string` | Yes | iOS, Android |

#### `streamKey` ๐

The broadcasterโs stream key that has been provided by IVS.

| Type | Required | Platform |
| :---: | :---: | :---: |
| `string` | Yes | iOS, Android |

#### `videoConfig` ๐

A configuration object describing the desired format of the final output Video stream.

โ ๏ธ _Changing any properties on this object after providing it to `IVSBroadcastCameraView` component will not have any effect. A copy of the configuration is made and kept internally._

| Type | Required | Platform |
| :---: | :---: | :---: |
| [`IVideoConfig`](./types.md#ivideoconfig) | No | iOS, Android |

_**Default video config:**_
| Key | Value |
| :---: | :---: |
| `width` | `720` |
| `height` | `1280` |
| `bitrate` | `2100000` |
| `targetFrameRate` | `30` |
| `keyframeInterval` | `2` |
| `isBFrames` | `true` |
| `isAutoBitrate` | `true` |
| `maxBitrate` | `6000000` |
| `minBitrate` | `300000` |

#### `audioConfig` ๐

A configuration object describing the desired format of the final output Audio stream.

โ ๏ธ _Changing any properties on this object after providing it to `IVSBroadcastCameraView` component will not have any effect. A copy of the configuration is made and kept internally._

| Type | Required | Platform |
| :---: | :---: | :---: |
| [`IAudioConfig`](./types.md#iaudioconfig) | No | iOS, Android |

_**Default audio config:**_
| Key | Value |
| :---: | :---: |
| `bitrate` | `96000` |
| `channels` | `2` |
| `audioSessionStrategy` | `playAndRecord` |
| `quality` | `medium` |

#### `logLevel` ๐

 In order to catch logs at a more granular level than `Error` during the initialization process, use this property instead of the [`sessionLogLevel`](#sessionloglevel-%F0%9F%93%8C).
 
| Type | Required | Platform | Default value |
| :---: | :---: | :---: | :---: |
| [`LogLevel`](./types.md#loglevel) | No | iOS, Android | `error` |

#### `sessionLogLevel` ๐

Logging level for the broadcast session.

| Type | Required | Platform | Default value |
| :---: | :---: | :---: | :---: |
| [`LogLevel`](./types.md#loglevel) | No | iOS, Android | `error` |

#### `cameraPreviewAspectMode` ๐

 Determines how view's aspect ratio will be maintained.
 
| Type | Required | Platform | Default value |
| :---: | :---: | :---: | :---: |
| [`CameraPreviewAspectMode`](./types.md#camerapreviewaspectmode) | No | iOS, Android | `none` |

#### `isCameraPreviewMirrored` ๐

Flips the camera preview horizontally.

| Type | Required | Platform | Default value |
| :---: | :---: | :---: | :---: |
| `boolean` | No | iOS, Android | `false` |

#### `cameraPosition` ๐

The position of the input device relative to the host device.

| Type | Required | Platform | Default value |
| :---: | :---: | :---: | :---: |
| [`CameraPosition`](./types.md#cameraposition) | No | iOS, Android | `back` |

### _**Handlers**_

#### `onError` ๐

 Indicates that module' internal error occurred.

| Type | Required | Platform |
| :---: | :---: | :---: |
| `onError(errorMessage: string): void` | No | iOS, Android |
 
#### `onBroadcastError` ๐

Indicates that broadcast session error occurred. Errors may or may not be fatal. In the case of a fatal error the broadcast session moves into `DISCONNECTED` [state status](./types.md#statestatusunion).

| Type | Required | Platform |
| :---: | :---: | :---: |
| `onBroadcastError(error: IBroadcastSessionError): void` | No | iOS, Android |

๐ See [`IBroadcastSessionError`](./types.md#ibroadcastsessionerror) type.

#### `onIsBroadcastReady` ๐

Fires(once) when initialization (including adding camera preview to the view hierarchy) is done.

| Type | Required | Platform |
| :---: | :---: | :---: |
| `onIsBroadcastReady(isReady: boolean): void` | No | iOS, Android |

#### `onBroadcastAudioStats` ๐

Periodically called with audio `peak` and `rms` in `dBFS`.

| Type | Required | Platform |
| :---: | :---: | :---: |
| `onBroadcastAudioStats(audioStats: IAudioStats): void` | No | iOS, Android |

๐ See [`IAudioStats`](./types.md#iaudiostats) type.

#### `onBroadcastStateChanged` ๐

Indicates that the broadcast state changed.

| Type | Required | Platform |
| :---: | :---: | :---: |
| `onBroadcastStateChanged(stateStatus: StateStatusUnion): void` | No | iOS, Android |

๐ See [`StateStatusUnion`](./types.md#statestatusunion) type.

#### `onBroadcastQualityChanged` ๐

Represents the quality of the stream.

`quality` is a number between `0` and `1` that represents the quality of the stream based on minimum and maximum bitrate provided in the [`videoConfig`](#videoconfig-%F0%9F%93%8C). `0` means the stream is at the lowest possible quality, or streaming is not possible at all. `1` means the bitrate is near the maximum allowed.

| Type | Required | Platform |
| :---: | :---: | :---: |
| `onBroadcastQualityChanged(quality: number): void` | No | iOS, Android |

#### `onNetworkHealthChanged` ๐

Provides updates when the instantaneous quality of the network changes. It can be used to provide feedback about when the broadcast might have temporary disruptions.

`networkHealth` is a number between `0` and `1` that represents the current health of the network. `0` means the network is struggling to keep up and the broadcast may be experiencing latency spikes. The SDK may also reduce the quality of the broadcast on low values in order to keep it stable, depending on the minimum allowed bitrate in the [`videoConfig`](#videoconfig-%F0%9F%93%8C). A value of `1` means the network is easily able to keep up with the current demand and the SDK will be trying to increase the broadcast quality over time, depending on the maximum allowed bitrate. Lower values like `0.5` are not necessarily bad, it just means the network is being saturated, but it is still able to keep up.

| Type | Required | Platform |
| :---: | :---: | :---: |
| `onNetworkHealthChanged(networkHealth: number): void` | No | iOS, Android |

#### `onAudioSessionInterrupted` ๐

Indicates that audio session has been interrupted.

| Type | Required | Platform |
| :---: | :---: | :---: |
| `onAudioSessionInterrupted(): void` | No | iOS |

โ ๏ธ _There are several scenarios where the SDK may not have exclusive access to audio-input hardware. Some example scenarios that you need to handle are:_
* _User receives a phone call or FaceTime call_
* _User activates Siri_

#### `onAudioSessionResumed` ๐

Indicates that audio session has been resumed (after interrupted).

| Type | Required | Platform |
| :---: | :---: | :---: |
| `onAudioSessionResumed(): void` | No | iOS |

#### `onMediaServicesWereLost` ๐

>_In very rare cases, the entire media subsystem on an iOS device will crash. In this scenario, the SDK can no longer broadcast._

Indicates that the media server services are terminated.
Respond by stopping and completely deallocating broadcast session. All internal components used by the broadcast session will be invalidated.

| Type | Required | Platform |
| :---: | :---: | :---: |
| `onMediaServicesWereLost(): void` | No | iOS |

#### `onMediaServicesWereReset` ๐

Indicates that the media server services are reset.
Respond by notifying consumers that they can broadcast again. Depending on the case, you may be able to automatically start broadcasting again at this point.

| Type | Required | Platform |
| :---: | :---: | :---: |
| `onMediaServicesWereReset(): void` | No | iOS |

### _**Methods**_

#### `start` ๐

Start the configured broadcast session.

| Type | Required | Platform |
| :---: | :---: | :---: |
| `(): void` | No | iOS, Android |

#### `stop` ๐

Stop the broadcast session, but do not deallocate resources.

| Type | Required | Platform |
| :---: | :---: | :---: |
| `(): void` | No | iOS, Android |

โ ๏ธ _Stopping the stream happens asynchronously while the SDK attempts to gracefully end the broadcast. Observe state changes to know when a new stream could be started._

#### `swapCamera` ๐

Swap back camera to front camera and vice versa.

| Type | Required | Platform |
| :---: | :---: | :---: |
| `(): void` | No | iOS, Android |