//
//  LWDeckViewController.swift
//  LWDeckViewController
//
//  Created by lailingwei on 16/5/20.
//  Copyright © 2016年 lailingwei. All rights reserved.
//

import UIKit


private let kOffsetScale: CGFloat = 0.75                        // 侧栏偏移比例
private let kAnimationDuration: NSTimeInterval = 0.25           // 开关侧栏动画时间
private let kMainViewTransformScale: CGFloat = 0.85             // Scale式架构时，主页缩放比例
private let kMaskViewAlpha: CGFloat = 0.6                       // 遮罩视图最小透明度


/**
 抽屉式架构类型
 
 - Default: 默认类型
 - Scale:   主视图会根据偏移量自动缩放
 - Cover:   遮罩覆盖式
 */
@objc enum LWDeckDrawerType: Int {
    case Default    = 1
    case Scale      = 2
    case Cover      = 3
}


/**
 抽屉式架构状态类型
 
 - Collapsed:         关闭状态
 - LeftPanelExpanded: 左侧栏打开状态
 */
private enum LWDeckDrawerState: Int {
    case Collapsed          = 1
    case LeftPanelExpanded  = 2
}


class LWDeckViewController: UIViewController {

    
    private var type: LWDeckDrawerType = .Default
    private var mainVC: UIViewController!
    private var leftVC: UIViewController!
    
    private var panEnabled: Bool = true
    private var currentState: LWDeckDrawerState = .Collapsed {
        didSet {
            switch currentState {
            case .Collapsed:
                self.mainVC.view.layer.shadowOpacity = 0.0
            default:
                self.mainVC.view.layer.shadowOpacity = 0.3
            }
        }
    }
    
    private lazy var maskView: UIView = {
        let lazyMaskView = UIView(frame: CGRectZero)
        lazyMaskView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.0)
        lazyMaskView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add tap recognizer
        let tapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                          action: #selector(LWDeckViewController.handleMaskViewTapGestrue(_:)))
        lazyMaskView.addGestureRecognizer(tapGestureRecognizer)
        return lazyMaskView
    }()
    
    
    // MARK: - Life cycle
    
    private override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMainViewController()
        setupLeftViewController()
    }
 
    private func setupMainViewController() {
     
        // Add mainVC
        mainVC.view.layer.shadowOffset = CGSizeZero
        addChildViewController(mainVC)
        view.addSubview(mainVC.view)
        view.bringSubviewToFront(mainVC.view)
        mainVC.didMoveToParentViewController(self)
        
        // Add pan recognizer
        let panGestureRecognizer = UIPanGestureRecognizer(target: self,
                                                          action: #selector(LWDeckViewController.handleMainViewPanGesture(_:)))
        mainVC.view.userInteractionEnabled = true
        mainVC.view.addGestureRecognizer(panGestureRecognizer)
    }
    
    private func setupLeftViewController() {
        
        // Add LeftVC
        addChildViewController(leftVC)
        leftVC.didMoveToParentViewController(self)
    }
    
    deinit {
        print("\(NSStringFromClass(LWDeckViewController.self)).deinit")
    }
    
    
    // MARK: - Target actions
    
    func handleMainViewPanGesture(sender: UIPanGestureRecognizer) {
        
        guard panEnabled else { return }
        
        let position = sender.translationInView(view).x
        
        // 该移动的视图
        let offsetView = type == .Cover ? leftVC.view : mainVC.view
        let offsetCenterX = type == .Cover ? -mainViewWidth() : 0
        // .Default式架构，侧栏添加位移动画
        let defaultTypeLeftView: UIView? = type == .Default ? leftVC.view : nil
        
        
        switch sender.state {
        case .Began:
            if currentState == .Collapsed {
                switch type {
                case .Cover:
                    // Add maskView
                    view.insertSubview(maskView, aboveSubview: mainVC.view)
                    view.addConstraints(maskHConstraints())
                    view.addConstraints(maskVConstraints())
                    
                    // Add leftView
                    view.insertSubview(leftVC.view, aboveSubview: maskView)
                    leftVC.view.center.x = -mainViewWidth() / 2
                    
                case .Default, .Scale:
                    // Add leftView
                    view.insertSubview(leftVC.view, belowSubview: mainVC.view)
                }
            }
            
        case .Changed:
            // 设置目标中心位置
            var targetOffsetCenterX: CGFloat = 0
            // .Default
            var defaultTypeLeftViewTargetPosition: CGFloat = 0
            switch currentState {
            case .Collapsed:
                targetOffsetCenterX = view.center.x + offsetCenterX + position
                defaultTypeLeftViewTargetPosition = view.center.x - mainViewWidth() * (1 - kOffsetScale) * (1 - position / (mainViewWidth() * kOffsetScale))
            case .LeftPanelExpanded:
                targetOffsetCenterX = view.center.x + offsetCenterX + (mainViewWidth() * kOffsetScale) + position
                defaultTypeLeftViewTargetPosition = view.center.x + position * (1 - kOffsetScale) * mainViewWidth() / (mainViewWidth() * kOffsetScale)
            }
            
            // 超出范围时处理
            if targetOffsetCenterX > view.center.x + offsetCenterX + (mainViewWidth() * kOffsetScale) {
                targetOffsetCenterX = view.center.x + offsetCenterX + (mainViewWidth() * kOffsetScale)
            } else if targetOffsetCenterX < view.center.x {
                targetOffsetCenterX = view.center.x
            }
            
            if defaultTypeLeftViewTargetPosition > view.center.x  {
                defaultTypeLeftViewTargetPosition = view.center.x
            } else if defaultTypeLeftViewTargetPosition < view.center.x - mainViewWidth() * (1 - kOffsetScale) {
                defaultTypeLeftViewTargetPosition = view.center.x - mainViewWidth() * (1 - kOffsetScale)
            }
            
            // 主偏移视图进行偏移
            offsetView.center.x = targetOffsetCenterX
            // .Default
            print(defaultTypeLeftViewTargetPosition)
            defaultTypeLeftView?.center.x = defaultTypeLeftViewTargetPosition
            
        case .Ended:
            // 确定展开、闭合
            animateLeftPanelShouldExpand(offsetView.center.x >= view.center.x + (mainViewWidth() * kOffsetScale) / 2)
            
        default:
            break
        }
    
    }
    
    
    func handleMaskViewTapGestrue(sender: UITapGestureRecognizer) {
        guard currentState == .LeftPanelExpanded else { return }
        animateLeftPanelShouldExpand(false)
    }
    

    // MARK: - Helper methods
    
    /**动画开关侧栏*/
    private func animateLeftPanelShouldExpand(shouldExpand: Bool) {
    
        if shouldExpand {
            // 显示侧栏
            var targetPosition: CGFloat!
            switch type {
            case .Default, .Scale:
                targetPosition = mainViewWidth() * kOffsetScale
            case .Cover:
                targetPosition = mainViewWidth() * kOffsetScale
            }
            
            // 动画将偏移视图进行移动
            animateOffsetViewXPosition(toTargetPosition: targetPosition,
                                       completion: { (finished) in
                                            self.currentState = .LeftPanelExpanded
            })
            
        } else {
            // 关闭侧栏
            
            animateOffsetViewXPosition(toTargetPosition: 0,
                                       completion: { (finished) in
                                        
                                            self.currentState = .Collapsed
                                            self.leftVC.view.removeFromSuperview()
                                            if self.type == .Cover {
                                                self.maskView.removeFromSuperview()
                                            }
            })
            
        }
    }
    
    /**动画将偏移视图进行移动*/
    private func animateOffsetViewXPosition(toTargetPosition position: CGFloat,
                                                             completion: ((finished: Bool) -> Void)?) {
        
        let offsetView = type == .Cover ? leftVC.view : mainVC.view
        let offsetCenterX = type == .Cover ? -mainViewWidth() : 0
        
        // .Default式架构，侧栏添加位移动画
        let defaultTypeLeftView: UIView? = type == .Default ? leftVC.view : nil
        
        // .Scale式，主视图添加缩放动画
        let scaleTypeMainView: UIView? = type == .Scale ? mainVC.view : nil
        scaleTypeMainView?.transform = position == 0 ? CGAffineTransformMakeScale(kMainViewTransformScale, kMainViewTransformScale) : CGAffineTransformIdentity
        var scaleTypeMainViewTargetTransform = position == 0 ? CGAffineTransformIdentity : CGAffineTransformMakeScale(kMainViewTransformScale, kMainViewTransformScale)
        if position != 0 {
            let offset = -mainViewWidth() * (1 - kMainViewTransformScale) / 2
            scaleTypeMainViewTargetTransform = CGAffineTransformTranslate(scaleTypeMainViewTargetTransform, offset, 0)
        }
        
        // .Cover式，遮罩视图动画更改透明度
        let theMaskView: UIView? = type == .Cover ? maskView : nil
        theMaskView?.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(position == 0 ? kMaskViewAlpha : 0.0)
        
        // 动画显示
        UIView.animateWithDuration(kAnimationDuration,
                                   delay: 0.0,
                                   options: .CurveEaseOut,
                                   animations: {
                                    
                                    offsetView.center.x = self.view.center.x + offsetCenterX + position
                                    
                                    // .Default式架构，侧栏添加位移动画
                                    defaultTypeLeftView?.center.x = self.view.center.x - (position == 0 ? self.mainViewWidth() * (1 - kOffsetScale) : 0)
                                    
                                    // .Scale式，主视图添加缩放动画
                                    scaleTypeMainView?.transform = scaleTypeMainViewTargetTransform
                                    
                                    // .Cover式，遮罩视图动画更改透明度
                                    theMaskView?.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(position == 0 ? 0.0 : kMaskViewAlpha)
                                    
            }, completion: completion)
    }
 
    
    // MARK: - Helper for calculate
    
    private func mainViewWidth() -> CGFloat {
        return mainVC.view.bounds.size.width
    }
    
    
    // MARK: - MaskView Constrainst
    
    private func maskHConstraints() -> [NSLayoutConstraint] {
        return  NSLayoutConstraint.constraintsWithVisualFormat("H:|[_maskView]|",
                                                               options: .DirectionLeadingToTrailing,
                                                               metrics: nil,
                                                               views: ["_maskView" : maskView])
    }
    
    private func maskVConstraints() -> [NSLayoutConstraint] {
        return  NSLayoutConstraint.constraintsWithVisualFormat("V:|[_maskView]|",
                                                               options: .DirectionLeadingToTrailing,
                                                               metrics: nil,
                                                               views: ["_maskView" : maskView])
    }
    
}


// MARK: - Public methods

extension LWDeckViewController {
    
    
    convenience init(drawerType type: LWDeckDrawerType,
                                mainViewController: UIViewController,
                                leftViewController: UIViewController) {
        self.init(nibName: nil, bundle: nil)
     
        self.type = type
        self.mainVC = mainViewController
        self.leftVC = leftViewController
    }
    
    func mainViewController() -> UIViewController {
        return mainVC
    }
    
    func leftViewController() -> UIViewController {
        return leftVC
    }
    
    /**当前是否已关闭侧栏*/
    func isCollapsed() -> Bool {
        return currentState == .Collapsed
    }
    
    /**
     打开左侧栏
     */
    func expandLeftPanel() {
        guard currentState != .LeftPanelExpanded else { return }
        
        switch type {
        case .Cover:
            // Add maskView
            view.insertSubview(maskView, aboveSubview: mainVC.view)
            view.addConstraints(maskHConstraints())
            view.addConstraints(maskVConstraints())
            
            // Add leftView
            view.insertSubview(leftVC.view, aboveSubview: maskView)
            leftVC.view.center.x = -mainViewWidth() / 2
            
        case .Default, .Scale:
            // Add leftView
            view.insertSubview(leftVC.view, belowSubview: mainVC.view)
            
            // .Default
            leftVC.view.center.x = view.center.x - (1 - kOffsetScale) * mainViewWidth()
        }
        
        animateLeftPanelShouldExpand(true)
    }

    /**
     关闭侧栏
     */
    func collapsePanel() {
        guard currentState != .Collapsed else { return }
        
        animateLeftPanelShouldExpand(false)
    }
    
    /**
     设置手势开关
     */
    func setPanGestureEnabled(enabled: Bool) {
        panEnabled = enabled
    }
    
}







