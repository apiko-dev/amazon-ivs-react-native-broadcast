import React, { useState } from 'react';

import IVSBroadcastCameraView from 'amazon-ivs-react-native-broadcast';

const VIDEO_CONFIG = {
  width: 1920,
  height: 1080,
  bitrate: 8500000,
  targetFrameRate: 60,
  keyframeInterval: 2,
  isBFrames: true,
  isAutoBitrate: true,
  maxBitrate: 8500000,
  minBitrate: 1500000,
};

export default function App() {
  const [canDisplay, setCanDisplay] = useState(true);

  return canDisplay && <IVSBroadcastCameraView videoConfig={VIDEO_CONFIG} />;
}
