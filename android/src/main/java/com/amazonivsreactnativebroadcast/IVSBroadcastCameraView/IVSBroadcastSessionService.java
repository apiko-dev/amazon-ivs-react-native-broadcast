package com.amazonivsreactnativebroadcast.IVSBroadcastCameraView;

import com.amazonaws.ivs.broadcast.*;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.uimanager.ThemedReactContext;

@FunctionalInterface
interface CameraPreviewHandler {
  void run(ImagePreviewView cameraPreview);
}

// Guide: https://docs.aws.amazon.com/ivs/latest/userguide//broadcast-android.html
public class IVSBroadcastSessionService {
  private ThemedReactContext mReactContext;

  private boolean isInitialized = false;

  private boolean isInitialMuted = false;
  private Device.Descriptor.Position initialCameraPosition = Device.Descriptor.Position.BACK;
  private boolean isCameraPreviewMirrored = false;
  private BroadcastConfiguration.AspectMode cameraPreviewAspectMode = BroadcastConfiguration.AspectMode.NONE;
  private BroadcastConfiguration.LogLevel sessionLogLevel = BroadcastConfiguration.LogLevel.ERROR;

  private Device.Descriptor attachedCameraDescriptor;
  private Device.Descriptor attachedMicrophoneDescriptor;

  private BroadcastSession broadcastSession;
  private BroadcastSession.Listener broadcastSessionListener;
  private BroadcastConfiguration config = new BroadcastConfiguration();

  private void checkBroadcastSessionOrThrow() {
    if (broadcastSession == null || !isInitialized) {
      throw new RuntimeException("Broadcast session is not initialized.");
    }
  }

  private BroadcastConfiguration.LogLevel getLogLevel(String logLevelName) {
    switch (logLevelName) {
      case "debug": {
        return BroadcastConfiguration.LogLevel.DEBUG;
      }
      case "error": {
        return BroadcastConfiguration.LogLevel.ERROR;
      }
      case "info": {
        return BroadcastConfiguration.LogLevel.INFO;
      }
      case "warning": {
        return BroadcastConfiguration.LogLevel.WARNING;
      }
      default: {
        throw new RuntimeException("Does not support log level: " + logLevelName);
      }
    }
  }

  private BroadcastConfiguration.AspectMode getAspectMode(String aspectModeName) {
    switch (aspectModeName) {
      case "fit": {
        return BroadcastConfiguration.AspectMode.FIT;
      }
      case "fill": {
        return BroadcastConfiguration.AspectMode.FILL;
      }
      case "none": {
        return BroadcastConfiguration.AspectMode.NONE;
      }
      default: {
        throw new RuntimeException("Does not support aspect mode: " + aspectModeName);
      }
    }
  }

  private Device.Descriptor.Position getCameraPosition(String cameraPositionName) {
    switch (cameraPositionName) {
      case "front": {
        return Device.Descriptor.Position.FRONT;
      }
      case "back": {
        return Device.Descriptor.Position.BACK;
      }
      default: {
        throw new RuntimeException("Does not support camera position: " + cameraPositionName);
      }
    }
  }

  private ImagePreviewView getCameraPreview() {
    ImagePreviewView preview = broadcastSession.getPreviewView(cameraPreviewAspectMode);
    preview.setMirrored(isCameraPreviewMirrored);

    return preview;
  }

  private Device.Descriptor[] getInitialDeviceDescriptorList() {
    return initialCameraPosition == Device.Descriptor.Position.BACK
      ? Presets.Devices.BACK_CAMERA(mReactContext)
      : Presets.Devices.FRONT_CAMERA(mReactContext);
  }

  private void swapCameraAsync(CameraPreviewHandler callback) {
    checkBroadcastSessionOrThrow();

    broadcastSession.awaitDeviceChanges(() -> {
      for (Device.Descriptor deviceDescriptor : broadcastSession.listAvailableDevices(mReactContext)) {
        if (deviceDescriptor.type == Device.Descriptor.DeviceType.CAMERA && deviceDescriptor.position != attachedCameraDescriptor.position) {
          broadcastSession.exchangeDevices(attachedCameraDescriptor, deviceDescriptor, newCamera -> {
            attachedCameraDescriptor = newCamera.getDescriptor();
            callback.run(getCameraPreview());
          });
        }
      }
    });
  }

  private void muteAsync(boolean isMuted) {
    broadcastSession.awaitDeviceChanges(() -> {
      for (Device device : broadcastSession.listAttachedDevices()) {
        Device.Descriptor deviceDescriptor = device.getDescriptor();
        if (deviceDescriptor.type == Device.Descriptor.DeviceType.MICROPHONE && deviceDescriptor.urn.equals(attachedMicrophoneDescriptor.urn)) {
          Float gain = isMuted ? 0.0F : 1.0F;
          ((AudioDevice) device).setGain(gain);
          break;
        }
      }
    });
  }

  private void postInitialization() {
    broadcastSession.setLogLevel(sessionLogLevel);
    if (isInitialMuted) {
      muteAsync(isInitialMuted);
    }
  }

  private void saveInitialDevices(@NonNull Device.Descriptor[] deviceDescriptors) {
    for (Device.Descriptor deviceDescriptor : deviceDescriptors) {
      if (deviceDescriptor.type == Device.Descriptor.DeviceType.CAMERA) {
        attachedCameraDescriptor = deviceDescriptor;
      } else if (deviceDescriptor.type == Device.Descriptor.DeviceType.MICROPHONE) {
        attachedMicrophoneDescriptor = deviceDescriptor;
      }
    }
  }

  public IVSBroadcastSessionService(ThemedReactContext reactContext) {
    mReactContext = reactContext;
  }

  public void init() {
    if (isInitialized) return;

    broadcastSession = new BroadcastSession(
      mReactContext,
      broadcastSessionListener,
      config,
      getInitialDeviceDescriptorList()
    );
    isInitialized = true;

    saveInitialDevices(getInitialDeviceDescriptorList());
    postInitialization();
  }

  public void releaseResources() {
    checkBroadcastSessionOrThrow();
    broadcastSession.release();
  }

  public boolean isInitialized() {
    return isInitialized;
  }

  public boolean isReady() {
    checkBroadcastSessionOrThrow();
    return broadcastSession.isReady();
  }

  public void start(@Nullable String ivsRTMPSUrl, @Nullable String ivsStreamKey) {
    checkBroadcastSessionOrThrow();
    broadcastSession.start(ivsRTMPSUrl, ivsStreamKey);
  }

  public void stop() {
    checkBroadcastSessionOrThrow();
    broadcastSession.stop();
  }

  @Deprecated
  public void swapCamera(CameraPreviewHandler callback) {
    swapCameraAsync(callback);
  }

  public void getCameraPreviewAsync(CameraPreviewHandler callback) {
    checkBroadcastSessionOrThrow();
    broadcastSession.awaitDeviceChanges(() -> {
      callback.run(getCameraPreview());
    });
  }

  public void setCameraPosition(String cameraPositionName, CameraPreviewHandler callback) {
    if (isInitialized) {
      swapCameraAsync(callback);
    } else {
      initialCameraPosition = getCameraPosition(cameraPositionName);
    }
  }

  public void setCameraPreviewAspectMode(String cameraPreviewAspectModeName, CameraPreviewHandler callback) {
    cameraPreviewAspectMode = getAspectMode(cameraPreviewAspectModeName);
    if (isInitialized) {
      getCameraPreviewAsync(callback);
    }
  }

  public void setIsCameraPreviewMirrored(boolean isPreviewMirrored, CameraPreviewHandler callback) {
    isCameraPreviewMirrored = isPreviewMirrored;
    if (isInitialized) {
      getCameraPreviewAsync(callback);
    }
  }

  public void setIsMuted(boolean isMuted) {
    if (isInitialized) {
      checkBroadcastSessionOrThrow();
      muteAsync(isMuted);
    } else {
      isInitialMuted = isMuted;
    }

  }

  public void setSessionLogLevel(String sessionLogLevelName) {
    sessionLogLevel = getLogLevel(sessionLogLevelName);
  }

  public void setLogLevel(String logLevel) {
    config = config.changing($ -> {
      $.logLevel = getLogLevel(logLevel);
      return $;
    });
  }

  public void setListener(BroadcastSession.Listener broadcastListener) {
    broadcastSessionListener = broadcastListener;
  }

  public void setVideoConfig(ReadableMap videoConfig) {
    if (videoConfig.hasKey("width")
      && videoConfig.hasKey("height")
      && videoConfig.hasKey("bitrate")
      && videoConfig.hasKey("targetFrameRate")
      && videoConfig.hasKey("keyframeInterval")
    ) {
      config = config.changing($ -> {
        if (videoConfig.hasKey("isBFrames")) {
          $.video.setUseBFrames(videoConfig.getBoolean("isBFrames"));
        }
        if (videoConfig.hasKey("isAutoBitrate")) {
          $.video.setUseAutoBitrate(videoConfig.getBoolean("isAutoBitrate"));
        }
        if (videoConfig.hasKey("maxBitrate")) {
          $.video.setMaxBitrate(videoConfig.getInt("maxBitrate"));
        }
        if (videoConfig.hasKey("minBitrate")) {
          $.video.setMinBitrate(videoConfig.getInt("minBitrate"));
        }

        $.video.setSize(videoConfig.getInt("width"), videoConfig.getInt("height"));
        $.video.setInitialBitrate(videoConfig.getInt("bitrate"));
        $.video.setTargetFramerate(videoConfig.getInt("targetFrameRate"));
        $.video.setKeyframeInterval(videoConfig.getInt("keyframeInterval"));

        return $;
      });
    } else {
      // https://docs.aws.amazon.com/ivs/latest/userguide/streaming-config.html
      throw new RuntimeException("'width', 'height', 'bitrate', 'keyframeInterval', 'targetFrameRate' are required since they are interrelated.");
    }
  }

  public void setAudioConfig(ReadableMap audioConfig) {
    config = config.changing($ -> {
      if (audioConfig.hasKey("bitrate")) {
        $.audio.setBitrate(audioConfig.getInt("bitrate"));
      }
      if (audioConfig.hasKey("channels")) {
        $.audio.setChannels(audioConfig.getInt("channels"));
      }
      return $;
    });
  }
}
