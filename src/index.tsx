import {
  requireNativeComponent,
  UIManager,
  Platform,
  ViewStyle,
} from 'react-native';

const LINKING_ERROR =
  `The package 'amazon-ivs-react-native-broadcast' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo managed workflow\n';

type AmazonIvsReactNativeBroadcastProps = {
  color: string;
  style: ViewStyle;
};

const ComponentName = 'AmazonIvsReactNativeBroadcastView';

export const AmazonIvsReactNativeBroadcastView =
  UIManager.getViewManagerConfig(ComponentName) != null
    ? requireNativeComponent<AmazonIvsReactNativeBroadcastProps>(ComponentName)
    : () => {
        throw new Error(LINKING_ERROR);
      };
