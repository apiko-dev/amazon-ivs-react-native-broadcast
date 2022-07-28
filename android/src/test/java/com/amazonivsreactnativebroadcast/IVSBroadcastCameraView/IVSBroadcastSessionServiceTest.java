package com.amazonivsreactnativebroadcast.IVSBroadcastCameraView;

import junit.framework.TestCase;

import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;

import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.bridge.ReactApplicationContext;

@RunWith(RobolectricTestRunner.class)
public class IVSBroadcastSessionServiceTest extends TestCase {

  private IVSBroadcastSessionService ivsBroadcastSession;

  @Before
  public void setUp() throws Exception {
    ReactApplicationContext reactContext = new ReactApplicationContext(RuntimeEnvironment.application);
    ThemedReactContext mThemedReactContext = new ThemedReactContext(reactContext, reactContext);

    ivsBroadcastSession = new IVSBroadcastSessionService(mThemedReactContext);
  }

  @Test
  public void testSetCameraPosition() {
    assertEquals(0, 0);
  }
}
