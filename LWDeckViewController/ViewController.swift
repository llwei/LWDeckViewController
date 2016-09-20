//
//  ViewController.swift
//  LWDeckViewController
//
//  Created by lailingwei on 16/5/19.
//  Copyright © 2016年 lailingwei. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    @IBAction func leftBarItemWasTaped(_ sender: UIBarButtonItem) {
        
        if let deckVC = (UIApplication.shared.delegate as! AppDelegate).deckVC {
            deckVC.isCollapsed() ? deckVC.expandLeftPanel() : deckVC.collapsePanel()
        }
    }

}

