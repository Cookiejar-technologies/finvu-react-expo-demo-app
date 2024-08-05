package com.finvu

import com.finvu.android.FinvuManager
import com.finvu.android.publicInterface.FinvuErrorCode
import com.finvu.android.publicInterface.FinvuException
import com.finvu.android.utils.FinvuConfig
import expo.modules.kotlin.Promise
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
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
