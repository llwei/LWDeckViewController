//
//  AppDelegate.swift
//  LWDeckViewController
//
//  Created by lailingwei on 16/5/19.
//  Copyright © 2016年 lailingwei. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var deckVC: LWDeckViewController?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let mainVC = storyboard.instantiateViewController(withIdentifier: "NavigationController") as! UINavigationController
        let leftVC = storyboard.instantiateViewController(withIdentifier: "PanelTableViewController") as! PanelTableViewController
        
        deckVC = LWDeckViewController(drawerType: .default,
                                      mainViewController: mainVC,
                                      leftViewController: leftVC)
        window?.rootViewController = deckVC
        
//        // 获取主视图
//        let vc1 = deckVC.mainViewController()
//        // 获取侧边视图
//        let vc2 = deckVC.leftViewController()
//        // 滑动手势开关
//        deckVC.setPanGestureEnabled(true)
//        // 展开
//        deckVC.expandLeftPanel()
//        // 闭合
//        deckVC.collapsePanel()
//        // 判断当前是否是闭合状态
//        deckVC.isCollapsed()
        
        return true
    }
}

