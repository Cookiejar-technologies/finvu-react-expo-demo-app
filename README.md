# React Native Wrapper 

## Overview

This repository contains code to create a wrapper/ bridge between Finvu Native SDK and React Native EXPO app, used for both Android and iOS platform.
### Setup

1. Clone the repository:
```
git clone https://github.com/LastbyteSolutions/finvu-react-expo-demo-app
```
2. Navigate to below path and run following:
```
cd finvu_react_native_sdk/example
npm install
```
3. Run Android:
```
npx expo run:android
```
4. Run iOS:
```
npx expo run:ios
```

### Description

###### Project will have android and ios directories, so we did the following to integrate Native Modules.
1. In React Native code add this files if not already- index.ts:
```
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
```
2. Finvu.Types.ts:
```
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
```
3. FinvuModule.ts:
```
import { requireNativeModule } from 'expo-modules-core';

// It loads the native module object from the JSI or falls back to
// the bridge module (from NativeModulesProxy) if the remote debugger is on.
export default requireNativeModule('Finvu');
```
4. Android, in project level build.gradle we add this:
```
maven {
    url 'https://maven.pkg.github.com/Cookiejar-technologies/finvu_flutter_sdk'
    credentials {
        username = "USER_NAME"
        password = "USER_TOKEN"
    }
}
```
5. in app level build.gradle we add:
```
implementation("com.finvu.android:client:1.0.0")
implementation("com.finvu.android:core:1.0.0")
```
6. In Android package we add the followig file - FinvuModule.kt:
```
class FinvuModule : Module() {

  data class FinvuClientConfig(
    override val finvuEndpoint: String,
    override val certificatePins: List<String>?
  ) : FinvuConfig

  private val sdkInstance: FinvuManager = FinvuManager.shared

  override fun definition() = ModuleDefinition {
    Name("Finvu")
    Constants(
      // Add any constants here if needed
    )

    Events("onConnectionStatusChange", "onLoginOtpReceived", "onLoginOtpVerified")

    Function("initializeWith") { config: Map<String, Any> ->
      try {
        val finvuEndpoint = config["finvuEndpoint"] as? String ?: throw IllegalArgumentException("finvuEndpoint is required")
        val certificatePins = (config["certificatePins"] as? List<*>)?.map { it.toString() }

        val finvuClientConfig = FinvuClientConfig(finvuEndpoint, certificatePins)
        sdkInstance.initializeWith(finvuClientConfig)
        "Initialized successfully"
      } catch (e: Exception) {
        e.printStackTrace()
        throw RuntimeException("INITIALIZATION_ERROR", e)
      }
    }

    AsyncFunction("connect") {
      sdkInstance.connect { result ->
          if (result.isSuccess) {
            sendEvent("onConnectionStatusChange", mapOf("status" to "Connected successfully"))
          } else {
            val exception = result.exceptionOrNull() as? FinvuException
            if (exception != null) {
              val errorCode = when (exception.code) {
                FinvuErrorCode.SSL_PINNING_FAILURE_ERROR.code -> "SSL_PINNING_FAILURE_ERROR"
                else -> "UNKNOWN_ERROR"
              }
              sendEvent("onConnectionStatusChange", mapOf("status" to errorCode))
              throw RuntimeException(errorCode)
            } else {
              sendEvent("onConnectionStatusChange", mapOf("status" to "UNKNOWN_ERROR"))
              throw RuntimeException("UNKNOWN_ERROR")
            }
          }
      }
    }

    AsyncFunction("loginWithUsernameOrMobileNumber") { username: String, mobileNumber: String, consentHandleId: String,promise: Promise ->
      try {
        sdkInstance.loginWithUsernameOrMobileNumber(username, mobileNumber, consentHandleId) { result ->
            if (result.isSuccess) {
              val reference = result.getOrNull()?.reference
              promise.resolve(mapOf("reference" to reference))
            } else {
              val exception = result.exceptionOrNull() as? FinvuException
              val errorCode = exception?.code ?: "UNKNOWN_ERROR"
              promise.reject(errorCode.toString(), exception?.message, null)
              //sendEvent("onLoginOtpReceived", mapOf("status" to errorCode))
              //throw RuntimeException(errorCode.toString())
            }
          }
      } catch (e: Exception) {
        e.printStackTrace()
        throw RuntimeException("CONNECT_ERROR", e)
      }
    }

    AsyncFunction("verifyLoginOtp") { otp: String, otpReference: String, promise: Promise ->
      try {
        sdkInstance.verifyLoginOtp(otp, otpReference) { result ->
            if (result.isSuccess) {
              val userId = result.getOrNull()?.userId
              promise.resolve(mapOf("userId" to userId))
            } else {
              val exception = result.exceptionOrNull() as? FinvuException
              val errorCode = exception?.code ?: "UNKNOWN_ERROR"
              promise.reject(errorCode.toString(), exception?.message,null)
              throw RuntimeException(errorCode.toString())
            }
        }
      } catch (e: Exception) {
        e.printStackTrace()
        throw RuntimeException("CONNECT_ERROR", e)
      }
    }
  }
}
```
7. Similarly now for iOS in PodFile add this:
```
pod 'FinvuSDK' , :git => 'https://github.com/Cookiejar-technologies/finvu_ios_sdk.git'
```
8. add FinvuModule.swift
```
import ExpoModulesCore
import FinvuSDK

class FinvuClientConfig: FinvuConfig {
    var finvuEndpoint: URL
    var certificatePins: [String]?
    
    public init(finvuEndpoint: URL, certificatePins: [String]?) {
        self.finvuEndpoint = finvuEndpoint
        self.certificatePins = certificatePins ?? []
    }
}

public class FinvuModule: Module {
    private let sdkInstance = FinvuManager.shared

    public func definition() -> ModuleDefinition {
        Name("Finvu")
        
        Events("onConnectionStatusChange", "onLoginOtpReceived", "onLoginOtpVerified")

        Function("initializeWith") { (config: [String: Any]) -> String in
            do {
                guard let finvuEndpointString = config["finvuEndpoint"] as? String,
                      let finvuEndpoint = URL(string: finvuEndpointString) else {
                    throw NSError(domain: "FinvuModule", code: -1, userInfo: [NSLocalizedDescriptionKey: "finvuEndpoint is required and must be a valid URL"])
                }
                
                let certificatePins = (config["certificatePins"] as? [String])
                let finvuClientConfig = FinvuClientConfig(finvuEndpoint: finvuEndpoint, certificatePins: certificatePins)
                
                sdkInstance.initializeWith(config: finvuClientConfig)
                return "Initialized successfully"
            } catch {
                print(error)
                throw NSError(domain: "FinvuModule", code: -1, userInfo: [NSLocalizedDescriptionKey: "INITIALIZATION_ERROR"])
            }
        }

        AsyncFunction("connect") { (promise: Promise) in
            sdkInstance.connect { error in
                DispatchQueue.main.async {
                    if let error = error as NSError? {
                        // Convert NSError to React Native error
                        let errorCode: String
                        // Map NSError codes to custom error codes if needed
                        switch error.code {
                        case 1001: // Replace with specific error codes if applicable
                            errorCode = "SPECIFIC_ERROR_CODE"
                        default:
                            errorCode = "UNKNOWN_ERROR"
                        }
                        self.sendEvent("onConnectionStatusChange", ["status": errorCode])
                        promise.reject(errorCode, error.localizedDescription)
                    } else {
                        // No error means success
                        self.sendEvent("onConnectionStatusChange", ["status": "Connected successfully"])
                        promise.resolve(["status": "Connected successfully"])
                    }
                }
            }
        }

        AsyncFunction("loginWithUsernameOrMobileNumber") { (username: String, mobileNumber: String, consentHandleId: String, promise: Promise) in
            sdkInstance.loginWith(username: username, mobileNumber: mobileNumber, consentHandleId: consentHandleId) { result, error in
                DispatchQueue.main.async {
                    if let error = error as NSError? {
                        // Convert NSError to React Native error
                        let errorCode: String
                        // Map NSError codes to custom error codes if needed
                        switch error.code {
                        case 1001: // Replace with specific error codes if applicable
                            errorCode = "SPECIFIC_ERROR_CODE"
                        default:
                            errorCode = "UNKNOWN_ERROR"
                        }
                        promise.reject(errorCode, error.localizedDescription)
                    } else if let result = result {
                        // Handle successful login
                        let reference = result.reference
                        promise.resolve(["reference": reference])
                    } else {
                        // Handle case where there is no result and no error
                        promise.reject("UNKNOWN_ERROR", "An unknown error occurred.")
                    }
                }
            }
        }

                                  
        AsyncFunction("verifyLoginOtp") { (otp: String, otpReference: String, promise: Promise) in
            sdkInstance.verifyLoginOtp(otp: otp, otpReference: otpReference) { result, error in
                DispatchQueue.main.async {
                    if let error = error as NSError? {
                        // Convert NSError to React Native error
                        let errorCode: String
                        // Map NSError codes to custom error codes if needed
                        switch error.code {
                        case 1001: // Replace with specific error codes if applicable
                            errorCode = "SPECIFIC_ERROR_CODE"
                        default:
                            errorCode = "UNKNOWN_ERROR"
                        }
                        promise.reject(errorCode, error.localizedDescription)
                    } else if let result = result {
                        // Handle successful OTP verification
                        let userId = result.userId
                        promise.resolve(["userId": userId])
                    } else {
                        // Handle case where there is no result and no error
                        promise.reject("UNKNOWN_ERROR", "An unknown error occurred.")
                    }
                }
            }
        }
    }
}
```
9. Now in Finvu.podspec add this line:
```
  s.dependency 'FinvuSDK'
```
10. Now run pod install in ios directory.
11. Run the app with above Run Commands.
