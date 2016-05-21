//
//  PanelTableViewController.swift
//  LWDeckViewController
//
//  Created by lailingwei on 16/5/20.
//  Copyright © 2016年 lailingwei. All rights reserved.
//

import UIKit

class PanelTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        print("panel will appear")
    }
    
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillAppear(animated)
        print("panel will disappear")
    }
    

    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
