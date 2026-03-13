import UIKit

class MainViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the main interface with tab bar controller
        setupTabNavigation()
    }
    
    private func setupTabNavigation() {
        // Create tab bar controller
        let tabBarController = UITabBarController()
        
        // Translation tab
        let translationVC = TranslationViewController()
        let translationNav = UINavigationController(rootViewController: translationVC)
        translationNav.tabBarItem = UITabBarItem(title: "Translate", image: UIImage(systemName: "bubble.left.and.bubble.right"), tag: 0)
        
        // Offline mode tab
        let offlineVC = OfflineModeViewController()
        let offlineNav = UINavigationController(rootViewController: offlineVC)
        offlineNav.tabBarItem = UITabBarItem(title: "Offline", image: UIImage(systemName: "moon.fill"), tag: 1)
        
        // Set view controllers
        tabBarController.setViewControllers([translationNav, offlineNav], animated: false)
        
        // Set as root view controller
        self.view.addSubview(tabBarController.view)
        self.addChild(tabBarController)
        tabBarController.didMove(toParent: self)
    }
}