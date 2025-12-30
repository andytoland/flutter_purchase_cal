import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let mapChannel = FlutterMethodChannel(name: "com.example.flutter_purchase_calc/maps",
                                              binaryMessenger: controller.binaryMessenger)
    mapChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "setGoogleMapsApiKey" {
        if let args = call.arguments as? [String: Any],
           let key = args["key"] as? String {
             GMSServices.provideAPIKey(key)
             result("Key set")
        } else {
             result(FlutterError(code: "INVALID_ARGUMENT", message: "Key is missing", details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    })
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
