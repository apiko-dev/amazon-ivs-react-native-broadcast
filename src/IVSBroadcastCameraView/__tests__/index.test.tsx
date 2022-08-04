import React, { createRef } from 'react';
import { Platform, UIManager } from 'react-native';
import {
  render,
  screen,
  fireEvent,
  cleanup,
} from '@testing-library/react-native';

import type {
  IEventHandlers,
  INativeEventHandlers,
  ExtractComponentProps,
  IIVSBroadcastCameraView,
} from '../IVSBroadcastCameraView.types';
import { Command } from '../IVSBroadcastCameraView.types';
import IVSBroadcastCameraView, {
  NATIVE_VIEW_NAME,
  getCommandIdByPlatform,
} from '../IVSBroadcastCameraView';

type IVSBroadcastCameraViewPartialProps = Partial<
  ExtractComponentProps<typeof IVSBroadcastCameraView>
>;

const { Start, Stop, SwapCamera } = Command;

function nativeSyntheticEventFactory<TName extends keyof INativeEventHandlers>(
  nativeEvent?: Parameters<
    NonNullable<INativeEventHandlers[TName]>
  >[number]['nativeEvent']
) {
  return {
    nativeSyntheticEvent: {
      nativeEvent,
    },
  };
}

const renderIVSBroadcastCameraView = (
  props: IVSBroadcastCameraViewPartialProps = {}
) => render(<IVSBroadcastCameraView rtmpsUrl="" streamKey="" {...props} />);

const getIVSBroadcastCameraView = async (
  props: IVSBroadcastCameraViewPartialProps = {}
) => {
  renderIVSBroadcastCameraView(props);
  return screen.findByTestId(NATIVE_VIEW_NAME);
};

async function testEventHandler<TName extends keyof IEventHandlers>(
  eventHandlerName: TName,
  nativeSyntheticEvent: Partial<
    Parameters<NonNullable<INativeEventHandlers[TName]>>[number]
  >,
  nativeEvent: Parameters<NonNullable<IEventHandlers[TName]>>[number]
) {
  const mockEventHandler = jest.fn();
  const ivsBroadcastCameraViewInstance = await getIVSBroadcastCameraView({
    [eventHandlerName]: mockEventHandler,
  });

  fireEvent(
    ivsBroadcastCameraViewInstance,
    eventHandlerName,
    nativeSyntheticEvent
  );
  nativeEvent
    ? expect(mockEventHandler).toHaveBeenCalledWith(nativeEvent)
    : expect(mockEventHandler).toHaveBeenCalled();
}

afterEach(() => {
  cleanup();
});

jest.mock('react-native', () => {
  const ReactNative = jest.requireActual('react-native');

  ReactNative.Platform.OS = 'ios';
  ReactNative.UIManager.getViewManagerConfig = () => {
    return {
      Commands: {
        START: 0,
      },
    };
  };

  return ReactNative;
});

describe('getCommandIdByPlatform function works as expected', () => {
  it('iOS platform', () => {
    expect(getCommandIdByPlatform(Start)).toBe(0);
  });

  it('Android platform', () => {
    Platform.OS = 'android';
    expect(getCommandIdByPlatform(Start)).toBe(Start);
  });
});

describe('IVSBroadcastCameraView component', () => {
  test('Defined', async () => {
    const broadcastCameraView = await getIVSBroadcastCameraView();
    expect(broadcastCameraView).toBeDefined();
  });

  test('Matched', () => {
    const ivsBroadcastCameraViewTree = renderIVSBroadcastCameraView().toJSON();
    expect(ivsBroadcastCameraViewTree).toMatchSnapshot();
  });
});

describe('Event handlers work as expected', () => {
  test.each([
    {
      eventHandlerName: 'onError' as const,
      ...nativeSyntheticEventFactory<'onError'>({ message: 'error message' }),
    },
    {
      eventHandlerName: 'onIsBroadcastReady' as const,
      ...nativeSyntheticEventFactory<'onIsBroadcastReady'>({ isReady: true }),
    },
    {
      eventHandlerName: 'onBroadcastAudioStats' as const,
      ...nativeSyntheticEventFactory<'onBroadcastAudioStats'>({
        audioStats: {
          peak: 100,
          rms: 100,
        },
      }),
    },
    {
      eventHandlerName: 'onBroadcastStateChanged' as const,
      ...nativeSyntheticEventFactory<'onBroadcastStateChanged'>({
        stateStatus: 'CONNECTED',
      }),
    },
    {
      eventHandlerName: 'onBroadcastQualityChanged' as const,
      ...nativeSyntheticEventFactory<'onBroadcastQualityChanged'>({
        quality: 1,
      }),
    },
    {
      eventHandlerName: 'onNetworkHealthChanged' as const,
      ...nativeSyntheticEventFactory<'onNetworkHealthChanged'>({
        networkHealth: 1,
      }),
    },
    {
      eventHandlerName: 'onAudioSessionInterrupted' as const,
      ...nativeSyntheticEventFactory<'onAudioSessionInterrupted'>(),
    },
    {
      eventHandlerName: 'onAudioSessionResumed' as const,
      ...nativeSyntheticEventFactory<'onAudioSessionResumed'>(),
    },
    {
      eventHandlerName: 'onMediaServicesWereLost' as const,
      ...nativeSyntheticEventFactory<'onMediaServicesWereLost'>(),
    },
    {
      eventHandlerName: 'onMediaServicesWereReset' as const,
      ...nativeSyntheticEventFactory<'onMediaServicesWereReset'>(),
    },
  ])(
    '$eventHandlerName',
    async ({ eventHandlerName, nativeSyntheticEvent }) => {
      const { nativeEvent } = nativeSyntheticEvent;

      await testEventHandler(
        eventHandlerName,
        nativeSyntheticEvent,
        nativeEvent ? Object.values(nativeEvent)[0] : undefined
      );
    }
  );

  test('onBroadcastError', async () => {
    const errorCode = 1;
    const errorBasePayload = {
      type: 'type',
      isFatal: true,
      detail: 'detail',
      source: 'source',
    };

    await testEventHandler(
      'onBroadcastError',
      {
        nativeEvent: {
          exception: {
            code: errorCode,
            ...errorBasePayload,
          },
        },
      },
      {
        code: String(errorCode),
        ...errorBasePayload,
      }
    );
  });
});

describe('Static methods work as expected', () => {
  const mockCommandFn = jest.fn();
  UIManager.dispatchViewManagerCommand = mockCommandFn;

  const ivsBroadcastCameraViewRef = createRef<IIVSBroadcastCameraView>();

  test.each([
    { methodName: 'start' as const, calledWithSecondArg: Start },
    { methodName: 'stop' as const, calledWithSecondArg: Stop },
    /**
     * @deprecated in favor of 'cameraPosition' prop.
     */
    { methodName: 'swapCamera' as const, calledWithSecondArg: SwapCamera },
  ])('$method', ({ methodName, calledWithSecondArg }) => {
    Platform.OS = 'android';

    renderIVSBroadcastCameraView({ ref: ivsBroadcastCameraViewRef });

    mockCommandFn.mockClear();
    ivsBroadcastCameraViewRef.current?.[methodName]();

    expect(mockCommandFn).toHaveBeenCalled();

    const secondArg = mockCommandFn.mock.calls[0][1];
    expect(secondArg).toBe(calledWithSecondArg);
  });
});
