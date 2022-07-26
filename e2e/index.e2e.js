/* eslint-env detox/detox, jest */

beforeAll(async () => {
  await device.launchApp();
});

beforeEach(async () => {
  await device.reloadReactNative();
});

it('Primary container visible', async () => {
  await expect(element(by.id('primary-container'))).toBeVisible();
});
