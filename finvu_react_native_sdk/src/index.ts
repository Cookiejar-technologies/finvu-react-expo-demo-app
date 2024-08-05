import { EventEmitter, NativeModulesProxy, Subscription } from 'expo-modules-core';
import FinvuModule from './FinvuModule';
import { FinvuConfig } from './Finvu.types';

export async function initializeWith(config: FinvuConfig) {
  try {
    console.log('Result inside before calling initializeWith');
    await FinvuModule.initializeWith(config);
    console.log('Initialized successfully');
  } catch (e) {
    console.error(e);
  }
}

export async function connect() {
  try {
    console.log('Result inside before calling connect');
    const result = await FinvuModule.connect();
    console.log('Result inside: ' + result);
    return result;
  } catch (e) {
    console.error(e);
  }
}

export async function loginWithUsernameOrMobileNumber(username: string, mobileNumber: string, consentHandleId: string) {
  try {
    console.log('Calling login');
    const result = await FinvuModule.loginWithUsernameOrMobileNumber(username, mobileNumber, consentHandleId);
    console.log('Logged Request: ' + result.reference);
    return result;
  } catch (e) {
    console.error(e);
  }
}

export async function verifyLoginOtp(otp: string, otpReference: string) {
  try {
    console.log('Calling verify');
    const result = await FinvuModule.verifyLoginOtp(otp, otpReference);
    console.log('Logged In with userId : ' + result.userId);
    return result;
  } catch (e) {
    console.error(e);
  }
}

const emitter = new EventEmitter(FinvuModule ?? NativeModulesProxy.Finvu);

export function addChangeListener(listener: (event: any) => void): Subscription {
  return emitter.addListener('onChange', listener);
}
