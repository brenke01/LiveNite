//
//  PostCommentController.swift
//  LiveNite
//
//  Created by Kevin  on 6/21/16.
//  Copyright © 2016 LiveNite. All rights reserved.
//

import Foundation

class PostCommentController: UIViewController,  UINavigationControllerDelegate,  UIScrollViewDelegate,  UITextFieldDelegate {
    
    @IBOutlet weak var navBar: UINavigationBar!
    var imageID = "";
    var userName = "";
    
    override func viewDidLoad() {
        let navBarBGImage = UIImage(named: "Navigation_Bar_Gold")
        navBar.setBackgroundImage(navBarBGImage, forBarMetrics: .Default)
        navBar.topItem!.title = " Post Comment"
        super.viewDidLoad()
        
    }
}