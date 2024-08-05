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
