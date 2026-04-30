import UIKit

class MainViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupTabNavigation()
    }

    private func setupTabNavigation() {
        let tabBarController = UITabBarController()

        let translationVC = TranslationViewController()
        let translationNav = UINavigationController(rootViewController: translationVC)
        translationNav.tabBarItem = UITabBarItem(title: "Translate", image: UIImage(systemName: "bubble.left.and.bubble.right"), tag: 0)

        let offlineVC = OfflineModeViewController()
        let offlineNav = UINavigationController(rootViewController: offlineVC)
        offlineNav.tabBarItem = UITabBarItem(title: "Offline", image: UIImage(systemName: "moon.fill"), tag: 1)

        tabBarController.setViewControllers([translationNav, offlineNav], animated: false)
        addChild(tabBarController)
        view.addSubview(tabBarController.view)
        tabBarController.didMove(toParent: self)
    }
}
