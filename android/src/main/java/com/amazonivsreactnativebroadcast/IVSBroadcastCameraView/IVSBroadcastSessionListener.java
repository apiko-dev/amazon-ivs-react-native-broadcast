package com.amazonivsreactnativebroadcast.IVSBroadcastCameraView;

import com.amazonaws.ivs.broadcast.*;
import com.facebook.react.bridge.WritableMap;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.facebook.react.bridge.Arguments;

@FunctionalInterface
interface RunnableCallback {
    void run(String eventName, @Nullable WritableMap eventPayload);
}

public class IVSBroadcastSessionListener {
    public BroadcastSession.Listener broadcastListener;

    IVSBroadcastSessionListener(RunnableCallback runnable) {
        broadcastListener =
                new BroadcastSession.Listener() {
                    @Override
                    public void onStateChanged(@NonNull BroadcastSession.State state) {
                        WritableMap eventPayload = Arguments.createMap();
                        eventPayload.putString("stateStatus", state.toString());

                        runnable.run(IVSBroadcastCameraView.Events.ON_BROADCAST_STATE_CHANGED.toString(), eventPayload);
                    }

                    @Override
                    public void onError(@NonNull BroadcastException exception) {
                        int code = exception.getCode();
                        String detail = exception.getDetail();
                        String source = exception.getSource();
                        boolean isFatal = exception.isFatal();
                        String type = exception.getError().name();

                        WritableMap eventPayload = Arguments.createMap();
                        WritableMap broadcastException = Arguments.createMap();

                        broadcastException.putInt("code", code);
                        broadcastException.putString("detail", detail);
                        broadcastException.putString("source", source);
                        broadcastException.putBoolean("isFatal", isFatal);
                        broadcastException.putString("type", type);

                        eventPayload.putMap("exception", broadcastException);

                        runnable.run(IVSBroadcastCameraView.Events.ON_BROADCAST_ERROR.toString(), eventPayload);
                    }

                    @Override
                    public void onBroadcastQualityChanged(double quality) {
                        WritableMap eventPayload = Arguments.createMap();
                        eventPayload.putDouble("quality", quality);

                        runnable.run(IVSBroadcastCameraView.Events.ON_BROADCAST_QUALITY_CHANGED.toString(), eventPayload);
                    }

                    @Override
                    public void onNetworkHealthChanged(double health) {
                        WritableMap eventPayload = Arguments.createMap();
                        eventPayload.putDouble("networkHealth", health);

                        runnable.run(IVSBroadcastCameraView.Events.ON_NETWORK_HEALTH_CHANGED.toString(), eventPayload);
                    }

                    @Override
                    public void onAudioStats(double peak, double rms) {
                        WritableMap eventPayload = Arguments.createMap();
                        WritableMap audioStats = Arguments.createMap();

                        audioStats.putDouble("peak", peak);
                        audioStats.putDouble("rms", rms);

                        eventPayload.putMap("audioStats", audioStats);

                        runnable.run(IVSBroadcastCameraView.Events.ON_BROADCAST_AUDIO_STATS.toString(), eventPayload);
                    }
                };
    }
}
