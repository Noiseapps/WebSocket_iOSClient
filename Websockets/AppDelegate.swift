import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let rootController = ViewController()
        let navController = UINavigationController(rootViewController: rootController)
        navController.navigationBar.barTintColor = UIColor.blue
        navController.navigationBar.tintColor = UIColor.white
        navController.navigationBar.isTranslucent = false
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window!.rootViewController = navController
        self.window!.makeKeyAndVisible()
        return true
    }


}

