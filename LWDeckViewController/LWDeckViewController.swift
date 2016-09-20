//
//  LWDeckViewController.swift
//  LWDeckViewController
//
//  Created by lailingwei on 16/5/20.
//  Copyright © 2016年 lailingwei. All rights reserved.
//
//  Github: https://github.com/llwei/LWDeckViewController

import UIKit


private let kOffsetScale: CGFloat = 0.75                        // 侧栏偏移比例
private let kAnimationDuration: TimeInterval = 0.25           // 开关侧栏动画时间
private let kMainViewTransformScale: CGFloat = 0.85             // Scale式架构时，主页缩放比例
private let kMaskViewAlpha: CGFloat = 0.6                       // Cover式架构时，遮罩视图最小透明度


/**
 抽屉式架构类型
 
 - Default: 默认类型
 - Scale:   主视图会根据偏移量自动缩放
 - Cover:   遮罩覆盖式
 */
@objc enum LWDeckDrawerType: Int {
    case `default`    = 1
    case scale      = 2
    case cover      = 3
}


/**
 抽屉式架构状态类型
 
 - Collapsed:         关闭状态
 - LeftPanelExpanded: 左侧栏打开状态
 */
private enum LWDeckDrawerState: Int {
    case collapsed          = 1
    case leftPanelExpanded  = 2
}


class LWDeckViewController: UIViewController {
    
    fileprivate var type: LWDeckDrawerType = .default
    fileprivate var mainVC: UIViewController!
    fileprivate var leftVC: UIViewController!
    
    fileprivate var panEnabled: Bool = true
    fileprivate var tapEnabled: Bool = true
    fileprivate var currentState: LWDeckDrawerState = .collapsed {
        didSet {
            switch currentState {
            case .collapsed:
                self.mainVC.view.layer.shadowOpacity = 0.0
            default:
                self.mainVC.view.layer.shadowOpacity = 0.3
            }
        }
    }
    
    fileprivate lazy var maskView: UIView = {
        let lazyMaskView = UIView(frame: CGRect.zero)
        lazyMaskView.backgroundColor = UIColor.black.withAlphaComponent(0.0)
        lazyMaskView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add tap recognizer
        let tapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                          action: #selector(LWDeckViewController.handleTapGestrue(_:)))
        lazyMaskView.addGestureRecognizer(tapGestureRecognizer)
        return lazyMaskView
    }()
    
    
    fileprivate lazy var coverPanGesture: UIPanGestureRecognizer? = {
        if self.type == .cover {
            // Add pan recognizer
            let panGestureRecognizer = UIPanGestureRecognizer(target: self,
                                                              action: #selector(LWDeckViewController.handleMainViewPanGesture(_:)))
            self.leftVC.view.isUserInteractionEnabled = true
            self.leftVC.view.addGestureRecognizer(panGestureRecognizer)
            return panGestureRecognizer
        }
        return nil
    }()
    
    
    // MARK: - Life cycle
    
    fileprivate override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
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
 
    fileprivate func setupMainViewController() {
     
        // Add mainVC
        mainVC.view.layer.shadowOffset = CGSize.zero
        addChildViewController(mainVC)
        view.addSubview(mainVC.view)
        view.bringSubview(toFront: mainVC.view)
        mainVC.didMove(toParentViewController: self)
        
        // Add pan recognizer
        let panGestureRecognizer = UIPanGestureRecognizer(target: self,
                                                          action: #selector(LWDeckViewController.handleMainViewPanGesture(_:)))
        mainVC.view.isUserInteractionEnabled = true
        mainVC.view.addGestureRecognizer(panGestureRecognizer)
    }
    
    fileprivate func setupLeftViewController() {
        
        // Add LeftVC
        addChildViewController(leftVC)
        leftVC.didMove(toParentViewController: self)
    }
    
    deinit {
        print("\(NSStringFromClass(LWDeckViewController.self)).deinit")
    }
    
    
    // MARK: - Target actions
    
    func handleMainViewPanGesture(_ sender: UIPanGestureRecognizer) {
        
        guard panEnabled else { return }
        
        let position = sender.translation(in: view).x
        
        // 该移动的视图
        let offsetView = type == .cover ? leftVC.view : mainVC.view
        let offsetCenterX = type == .cover ? -mainViewWidth() : 0
        
        switch sender.state {
        case .began:
            // 如果初始为闭合状态，则把响应的视图添加上去
            if currentState == .collapsed {
                switch type {
                case .cover:
                    // Add maskView
                    maskView.frame = view.bounds
                    view.insertSubview(maskView, aboveSubview: mainVC.view)
                    view.addConstraints(maskHConstraints())
                    view.addConstraints(maskVConstraints())
                    
                    // Add leftView
                    leftVC.view.frame = view.bounds
                    view.insertSubview(leftVC.view, aboveSubview: maskView)
                    leftVC.view.center.x = -mainViewWidth() / 2
                    
                case .default, .scale:
                    // Add leftView
                    leftVC.view.frame = view.bounds
                    view.insertSubview(leftVC.view, belowSubview: mainVC.view)
                    
                    maskView.frame = mainVC.view.bounds
                    mainVC.view.addSubview(maskView)
                    mainVC.view.addConstraints(maskHConstraints())
                    mainVC.view.addConstraints(maskVConstraints())
                }
            } else {
                setTapGestureEnabled(false)
            }
            
        case .changed:
            // 设置目标中心位置
            var targetOffsetCenterX: CGFloat = 0
            var defaultTypeLeftViewTargetPosition: CGFloat = 0
            var scaleTypeMainViewTransformScale: CGFloat = 1.0
            var coverTypeMaskAlphaScale: CGFloat = 0.0
            
            switch currentState {
            case .collapsed:
                targetOffsetCenterX = view.center.x + offsetCenterX + position
                defaultTypeLeftViewTargetPosition = view.center.x - mainViewWidth() * (1 - kOffsetScale) * (1 - position / (mainViewWidth() * kOffsetScale))
                scaleTypeMainViewTransformScale = kMainViewTransformScale + (1 - kMainViewTransformScale) * (1 - position / (mainViewWidth() * kOffsetScale))
                coverTypeMaskAlphaScale = position / (mainViewWidth() * kOffsetScale)
            case .leftPanelExpanded:
                targetOffsetCenterX = view.center.x + offsetCenterX + (mainViewWidth() * kOffsetScale) + position
                defaultTypeLeftViewTargetPosition = view.center.x + position * (1 - kOffsetScale) * mainViewWidth() / (mainViewWidth() * kOffsetScale)
                scaleTypeMainViewTransformScale = kMainViewTransformScale + (1 - kMainViewTransformScale) * (-position / (mainViewWidth() * kOffsetScale))
                coverTypeMaskAlphaScale = 1 + position / (mainViewWidth() * kOffsetScale)
            }
            
            // 超出范围时处理
            if targetOffsetCenterX > view.center.x + offsetCenterX + (mainViewWidth() * kOffsetScale) {
                targetOffsetCenterX = view.center.x + offsetCenterX + (mainViewWidth() * kOffsetScale)
            } else if targetOffsetCenterX < view.center.x + offsetCenterX {
                targetOffsetCenterX = view.center.x + offsetCenterX
            }
            if defaultTypeLeftViewTargetPosition > view.center.x  {
                defaultTypeLeftViewTargetPosition = view.center.x
            } else if defaultTypeLeftViewTargetPosition < view.center.x - mainViewWidth() * (1 - kOffsetScale) {
                defaultTypeLeftViewTargetPosition = view.center.x - mainViewWidth() * (1 - kOffsetScale)
            }
            if scaleTypeMainViewTransformScale > 1.0 {
                scaleTypeMainViewTransformScale = 1.0
            } else if scaleTypeMainViewTransformScale < kMainViewTransformScale {
                scaleTypeMainViewTransformScale = kMainViewTransformScale
            }
            if coverTypeMaskAlphaScale > 1 {
                coverTypeMaskAlphaScale = 1
            } else if coverTypeMaskAlphaScale < 0 {
                coverTypeMaskAlphaScale = 0
            }
            var transform = CGAffineTransform(scaleX: scaleTypeMainViewTransformScale, y: scaleTypeMainViewTransformScale)
            let offset = -mainViewWidth() * (1 - scaleTypeMainViewTransformScale) / 2
            transform = transform.translatedBy(x: offset, y: 0)
            
            // 进行视图偏移
            offsetView?.center.x = targetOffsetCenterX
            defaultTypeLeftView()?.center.x = defaultTypeLeftViewTargetPosition
            scaleTypeMainView()?.transform = transform
            coverMaskView()?.backgroundColor = UIColor.black.withAlphaComponent(kMaskViewAlpha * coverTypeMaskAlphaScale)
            
        case .ended:
            // 确定展开、闭合
            animateLeftPanelShouldExpand((offsetView?.center.x)! >= view.center.x + offsetCenterX + (mainViewWidth() * kOffsetScale) / 2)
            
        default:
            break
        }
    
    }
    
    
    func handleTapGestrue(_ sender: UITapGestureRecognizer) {
        guard currentState == .leftPanelExpanded && tapEnabled == true else { return }
        animateLeftPanelShouldExpand(false)
    }
    

    // MARK: - Animation
    
    /**动画开关侧栏*/
    fileprivate func animateLeftPanelShouldExpand(_ shouldExpand: Bool) {
    
        if shouldExpand {
            // 显示侧栏
            var targetPosition: CGFloat!
            switch type {
            case .default, .scale:
                targetPosition = mainViewWidth() * kOffsetScale
                
            case .cover:
                targetPosition = mainViewWidth() * kOffsetScale
            }
            
            // 动画将偏移视图进行移动
            animateOffsetViewXPosition(toTargetPosition: targetPosition,
                                       completion: { (finished) in
                                        self.currentState = .leftPanelExpanded
                                        
                                        if self.type == .cover {
                                            self.coverPanGesture?.isEnabled = true
                                        }
                                        self.setTapGestureEnabled(true)
            })
            
        } else {
            // 关闭侧栏
            animateOffsetViewXPosition(toTargetPosition: 0,
                                       completion: { (finished) in
                                        
                                        self.currentState = .collapsed
                                        self.leftVC.view.removeFromSuperview()
                                        if self.type == .cover {
                                            self.coverPanGesture?.isEnabled = false
                                        }
                                        self.maskView.removeFromSuperview()
            })
            
        }
    }
    
    /**动画将偏移视图进行移动*/
    fileprivate func animateOffsetViewXPosition(toTargetPosition position: CGFloat,
                                                             completion: ((_ finished: Bool) -> Void)?) {
        
        let offsetView = type == .cover ? leftVC.view : mainVC.view
        let offsetCenterX = type == .cover ? -mainViewWidth() : 0
        
        // .Scale式，主视图添加缩放动画
        var scaleTypeMainViewTargetTransform = position == 0 ? CGAffineTransform.identity : CGAffineTransform(scaleX: kMainViewTransformScale, y: kMainViewTransformScale)
        if position != 0 {
            let offset = -mainViewWidth() * (1 - kMainViewTransformScale) / 2
            scaleTypeMainViewTargetTransform = scaleTypeMainViewTargetTransform.translatedBy(x: offset, y: 0)
        }
        
        // 动画显示
        UIView.animate(withDuration: kAnimationDuration,
                                   delay: 0.0,
                                   options: .curveEaseOut,
                                   animations: {
                                    
                                    offsetView?.center.x = self.view.center.x + offsetCenterX + position
                                    
                                    // .Default式架构，侧栏添加位移动画
                                    self.defaultTypeLeftView()?.center.x = self.view.center.x - (position == 0 ? self.mainViewWidth() * (1 - kOffsetScale) : 0)
                                    
                                    // .Scale式，主视图添加缩放动画
                                    self.scaleTypeMainView()?.transform = scaleTypeMainViewTargetTransform
                                    
                                    // .Cover式，遮罩视图动画更改透明度
                                    self.coverMaskView()?.backgroundColor = UIColor.black.withAlphaComponent(position == 0 ? 0.0 : kMaskViewAlpha)
                                    
            }, completion: completion)
    }
 
    
   
    
}


// MARK: - Private methods

extension LWDeckViewController {
    
    
    fileprivate func mainViewWidth() -> CGFloat {
        return UIScreen.main.bounds.size.width
    }
    
    // .Default式架构，侧栏添加位移动画
    fileprivate func defaultTypeLeftView() -> UIView? {
        return type == .default ? leftVC.view : nil
    }
    
    // .Scale式，主视图添加缩放动画
    fileprivate func scaleTypeMainView() -> UIView? {
        return type == .scale ? mainVC.view : nil
    }
    
    // .Cover式，遮罩视图动画更改透明度
    fileprivate func coverMaskView() -> UIView? {
        return type == .cover ? maskView : nil
    }

    
    fileprivate func maskHConstraints() -> [NSLayoutConstraint] {
        return  NSLayoutConstraint.constraints(withVisualFormat: "H:|[_maskView]|",
                                                               options: NSLayoutFormatOptions(),
                                                               metrics: nil,
                                                               views: ["_maskView" : maskView])
    }
    
    fileprivate func maskVConstraints() -> [NSLayoutConstraint] {
        return  NSLayoutConstraint.constraints(withVisualFormat: "V:|[_maskView]|",
                                                               options: NSLayoutFormatOptions(),
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
        return currentState == .collapsed
    }
    
    /**
     打开左侧栏
     */
    func expandLeftPanel() {
        guard currentState == .collapsed else { return }
        
        switch type {
        case .cover:
            // Add maskView
            maskView.frame = view.bounds
            view.insertSubview(maskView, aboveSubview: mainVC.view)
            view.addConstraints(maskHConstraints())
            view.addConstraints(maskVConstraints())
            coverMaskView()?.backgroundColor = UIColor.black.withAlphaComponent(0.0)
            
            // Add leftView
            leftVC.view.frame = view.bounds
            view.insertSubview(leftVC.view, aboveSubview: maskView)
            leftVC.view.center.x = -mainViewWidth() / 2
            
        case .default:
            // Add leftView
            leftVC.view.frame = view.bounds
            view.insertSubview(leftVC.view, belowSubview: mainVC.view)
            leftVC.view.center.x = view.center.x - (1 - kOffsetScale) * mainViewWidth()
            
            // Add maskView
            maskView.frame = mainVC.view.bounds
            mainVC.view.addSubview(maskView)
            mainVC.view.addConstraints(maskHConstraints())
            mainVC.view.addConstraints(maskVConstraints())
            
        case .scale:
            // Add leftView
            leftVC.view.frame = view.bounds
            view.insertSubview(leftVC.view, belowSubview: mainVC.view)
            leftVC.view.center.x = view.center.x
            
            // Add maskView
            maskView.frame = mainVC.view.bounds
            mainVC.view.addSubview(maskView)
            mainVC.view.addConstraints(maskHConstraints())
            mainVC.view.addConstraints(maskVConstraints())
        }
        
        animateLeftPanelShouldExpand(true)
    }

    /**
     关闭侧栏
     */
    func collapsePanel() {
        guard currentState == .leftPanelExpanded else { return }
        
        animateLeftPanelShouldExpand(false)
    }
    
    /**
     设置滑动手势开关
     */
    func setPanGestureEnabled(_ enabled: Bool) {
        panEnabled = enabled
    }
    
    /**
     设置点击手势开关
     */
    func setTapGestureEnabled(_ enabled: Bool) {
        tapEnabled = enabled
    }
    
    
}







