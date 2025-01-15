# React Native Wrapper 

## Overview
This repository contains a demo app to demonstrate integrating the Finvu SDKs (iOS and Android) into a React Native EXPO app using a wrapper/ bridge.

## Prerequisites
1. React Native EXPO app
2. Android
    1. Min SDK version supported is 24
    2. Min kotlin version supported is 1.9.0
3. iOS
    1. Min iOS version supported is iOS 13

### Integration
1. Create expo module
```
npx create-expo-module --local

The local module will be created in the modules directory in the root of your project. Learn more: https://expo.fyi/expo-module-local-autolinking.md

✔ What is the name of the local module? … finvu
✔ What is the native module name? … Finvu
✔ What is the Android package name? … expo.modules.finvu

✔ Downloaded module template from npm
✔ Created the module from template files

✅ Successfully created Expo module in modules/finvu

You can now import this module inside your application.
For example, you can add this line to your App.js or App.tsx file:
import { hello } from './modules/finvu';
```
2. Android setup
    1. Our Android SDK binaries are hosted as github packages that are accessible publicly. Add the following repository to your project level `build.gradle` file. Note that you need to provide some github credentials. [Check here](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#creating-a-personal-access-token-classic) on steps to create `USER_PAT`
        ```
        maven {
            url 'https://maven.pkg.github.com/Cookiejar-technologies/finvu_android_sdk'
            credentials {
                username = "USER_NAME"
                password = "USER_PAT" 
            }
        }
        ```
    2. In `modules/finvu/android/build.gradle` we add:
        ```sh
        implementation("com.finvu.android:client-sdk:1.0.1")
        implementation("com.finvu.android:core-sdk:1.0.1")
        ```
 
3. iOS setup
    1. Similarly now for iOS in `example/ios/PodFile` add this:
        ```sh
        pod 'FinvuSDK' , :git => 'https://github.com/Cookiejar-technologies/finvu_ios_sdk.git'
        ```

    2. Now in the `modules/finvu/ios/Finvu.podspec` file add this line:
        ```sh
        s.dependency 'FinvuSDK'
        ```

    3. install pods in ios directory 
        ```sh
        cd example/ios
        pod install
        ```
4. React Native Bridge
    1. Following code is added in `index.ts`
        ```sh
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
        ```sh
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
        ```sh
        import { requireNativeModule } from 'expo-modules-core';
        
        // It loads the native module object from the JSI or falls back to
        // the bridge module (from NativeModulesProxy) if the remote debugger is on.
        export default requireNativeModule('Finvu');
        ```

5. Add following code to `modules/finvu/android/src/main/java/expo/modules/finvu/FinvuModule.kt` file
    ```sh
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
6. Similarly add following code to `modules/finvu/ios/FinvuModule.swift` file:
    ```sh
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
7. Now run pod install in ios directory.
    ```sh
    cd example/ios
    pod install
    ```
8. Run the app with:
    ```sh
    npx expo run:android //for android
    npx expo run:ios //for ios
    ```
