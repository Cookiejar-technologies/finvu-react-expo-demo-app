export type ChangeEventPayload = {
  value: string;
};

export type FinvuViewProps = {
  name: string;
};


export type FinvuConfig ={
  finvuEndpoint: string;
  certificatePins?: string[];
}
