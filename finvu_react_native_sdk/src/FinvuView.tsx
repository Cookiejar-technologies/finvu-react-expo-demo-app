import { requireNativeViewManager } from 'expo-modules-core';
import * as React from 'react';

import { FinvuViewProps } from './Finvu.types';

const NativeView: React.ComponentType<FinvuViewProps> =
  requireNativeViewManager('Finvu');

export default function FinvuView(props: FinvuViewProps) {
  return <NativeView {...props} />;
}
