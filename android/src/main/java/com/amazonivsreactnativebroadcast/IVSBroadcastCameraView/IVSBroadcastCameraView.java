package com.amazonivsreactnativebroadcast.IVSBroadcastCameraView;

import android.view.View;
import android.widget.LinearLayout;

import androidx.annotation.Nullable;

import com.amazonaws.ivs.broadcast.BroadcastSession;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.LifecycleEventListener;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.events.RCTEventEmitter;

public class IVSBroadcastCameraView extends LinearLayout implements LifecycleEventListener {
      public enum Events {
        ON_BROADCAST_STATE_CHANGED("onBroadcastStateChanged"),
        ON_BROADCAST_ERROR("onBroadcastError"),
        ON_BROADCAST_QUALITY_CHANGED("onBroadcastQualityChanged"),
        ON_BROADCAST_AUDIO_STATS("onBroadcastAudioStats"),
        ON_IS_BROADCAST_READY("onIsBroadcastReady"),
        ON_NETWORK_HEALTH_CHANGED("onNetworkHealthChanged"),
        ON_ERROR("onError");

        private String title;

        Events(String title) {
            this.title = title;
        }

        @Override
        public String toString() {
            return title;
        }
    }

    private String STREAM_KEY;
    private String RTMPS_URL;
    private String SESSION_LOG_LEVEL;
    private IVSBroadcastSessionService ivsBroadcastSession;

    private void addCameraPreview(View preview) {
        preview.layout(0, 0, getRight(), getBottom());
        addView(preview);
    }

    private void sendEvent(String eventName, @Nullable WritableMap eventPayload) {
        ThemedReactContext reactContext = (ThemedReactContext) super.getContext();
        RCTEventEmitter eventEmitter = reactContext.getJSModule(RCTEventEmitter.class);
        eventEmitter.receiveEvent(getId(), eventName, eventPayload);
    }

    private void sendErrorEvent(String errorMessage) {
        WritableMap eventPayload = Arguments.createMap();
        eventPayload.putString("message", errorMessage);

        sendEvent(Events.ON_ERROR.toString(), eventPayload);
    }

    private void initBroadcastSession() {
        if (ivsBroadcastSession.isInitialized()) return;

        try {
            BroadcastSession.Listener broadcastListener = new IVSBroadcastSessionListener(this::sendEvent).broadcastListener;
            ivsBroadcastSession.setListener(broadcastListener);

            // Creates instance of IVS broadcast session
            ivsBroadcastSession.init();

            ivsBroadcastSession.setSessionLogLevel(SESSION_LOG_LEVEL);
            // Receive camera preview asynchronously to ensure that all devices have been attached
            ivsBroadcastSession.getCameraPreviewAsync((cameraPreview) -> {
                addCameraPreview(cameraPreview);

                WritableMap eventPayload = Arguments.createMap();
                eventPayload.putBoolean("isReady", ivsBroadcastSession.isReady());
                sendEvent(Events.ON_IS_BROADCAST_READY.toString(), eventPayload);
            });
        } catch (RuntimeException error) {
            sendErrorEvent(error.toString());
        }
    }

    public IVSBroadcastCameraView(ThemedReactContext reactContext) {
        super(reactContext);
        reactContext.addLifecycleEventListener(this);
        ivsBroadcastSession = new IVSBroadcastSessionService(reactContext);
    }

    protected void start() {
        if (RTMPS_URL != null && STREAM_KEY != null) {
            try {
                ivsBroadcastSession.start(RTMPS_URL, STREAM_KEY);
            } catch (RuntimeException error) {
                sendErrorEvent(error.toString());
            }
        } else {
            throw new RuntimeException("'rtmpsUrl' and 'streamKey' props are required!");
        }
    }

    protected void stop() {
        ivsBroadcastSession.stop();
    }

    protected void swapCamera() {
        try {
            ivsBroadcastSession.swapCamera((cameraPreview) -> {
                removeAllViews(); // Remove the current preview view since the device will be changing
                addCameraPreview(cameraPreview);
            });
        } catch (RuntimeException error) {
            sendErrorEvent(error.toString());
        }
    }

    protected void cleanUp() {
        removeAllViews();
        ivsBroadcastSession.releaseResources();
    }

    protected void setIsCameraPreviewMirrored(boolean isCameraPreviewMirrored) {
        ivsBroadcastSession.setIsCameraPreviewMirrored(isCameraPreviewMirrored);
    }

    protected void setCameraPosition(String cameraPosition) {
        ivsBroadcastSession.setCameraPosition(cameraPosition);
    }

    protected void setCameraPreviewAspectMode(String cameraPreviewAspectMode) {
        ivsBroadcastSession.setCameraPreviewAspectMode(cameraPreviewAspectMode);
    }

    protected void setRtmpsUrl(String rtmpsUrl) {
        RTMPS_URL = rtmpsUrl;
    }

    protected void setStreamKey(String streamKey) {
        STREAM_KEY = streamKey;
    }

    protected void setSessionLogLevel(String sessionLogLevel) {
        SESSION_LOG_LEVEL = sessionLogLevel;
    }

    protected void setLogLevel(String logLevel) {
        ivsBroadcastSession.setLogLevel(logLevel);
    }

    protected void setVideoConfig(ReadableMap videoConfig) {
        ivsBroadcastSession.setVideoConfig(videoConfig);
    }

    protected void setAudioConfig(ReadableMap audioConfig) {
        ivsBroadcastSession.setAudioConfig(audioConfig);
    }

    @Override
    public void onHostResume() {}

    @Override
    public void onHostPause() {}

    @Override
    public void onHostDestroy() {
        cleanUp();
    }

    @Override
    protected void onAttachedToWindow() {
        super.onAttachedToWindow();
        initBroadcastSession();
    }
}
