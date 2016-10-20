//
//  ProfileController.swift
//  LiveNite
//
//  Created by Kevin on 3/1/16.
//  Copyright © 2016 LiveNite. All rights reserved.
//



class ProfileController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate,  UICollectionViewDelegateFlowLayout, CLLocationManagerDelegate{
    
    
    
   
    
    
    var locations = 0
    var locationUpdated = false
    var toggleState = 0
    var hotToggle = 0
    var profileMenu = UIView()
    var accessToken = ""
    var userID = ""
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.view.isHidden = false
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

    }
}
