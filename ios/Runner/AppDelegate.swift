import UIKit
import Flutter
import Branch

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        
        // Configure Branch
        Branch.getInstance().initSession(launchOptions: launchOptions) { (params, error) in
            // Handle deep link parameters (if any)
            if let error = error {
                print("Branch initialization error: \(error.localizedDescription)")
            } else if let params = params as? [String: Any] {
                print("Branch initialization successful with parameters: \(params)")
                // Handle deep link data here
                self.handleDeepLink(params)
            }
        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return Branch.getInstance().application(app, open: url, options: options)
    }

    override func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        return Branch.getInstance().continue(userActivity)
    }
    
    private func handleDeepLink(_ params: [String: Any]) {
        // Send deep link data to Flutter
        guard let controller = window?.rootViewController as? FlutterViewController else {
            return
        }
        let channel = FlutterMethodChannel(name: "com.49nft.app/branch_deeplink", binaryMessenger: controller.binaryMessenger)
        channel.invokeMethod("handleDeepLink", arguments: params)
    }
}