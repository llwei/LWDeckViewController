# LWDeckViewController
1、左向侧滑（LWDeckDrawerType.Default）
2、左向缩放侧滑（LWDeckDrawerType.Scale）
3、覆盖式左抽屉侧滑（LWDeckDrawerType.Cover）


一、初始化方法，通过改变 drawerType 来初始化你想要的样式

    class AppDelegate: UIResponder, UIApplicationDelegate {

        var window: UIWindow?
        var deckVC: LWDeckViewController?

        func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let mainVC = storyboard.instantiateViewControllerWithIdentifier("NavigationController") as! UINavigationController
            let leftVC = storyboard.instantiateViewControllerWithIdentifier("PanelTableViewController") as! PanelTableViewController

            deckVC = LWDeckViewController(drawerType: .Default,
                                          mainViewController: mainVC,
                                          leftViewController: leftVC)
            window?.rootViewController = deckVC

            return true
        }
    }


二、其他可能用到的功能 

    // 获取主视图
    let vc1 = deckVC.mainViewController()
    // 获取侧边视图
    let vc2 = deckVC.leftViewController()
    // 判断当前是否是闭合状态
    deckVC.isCollapsed()
    // 滑动手势开关
    deckVC.setPanGestureEnabled(true)
    // 展开
    deckVC.expandLeftPanel()
    // 闭合
    deckVC.collapsePanel()
    
