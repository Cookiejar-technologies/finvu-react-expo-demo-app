import * as React from 'react';

import { FinvuViewProps } from './Finvu.types';

export default function FinvuView(props: FinvuViewProps) {
  return (
    <div>
      <span>{props.name}</span>
    </div>
  );
}
