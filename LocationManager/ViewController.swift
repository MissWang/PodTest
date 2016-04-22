//
//  ViewController.swift
//  LocationManager
//
//  Created by wangxinyan on 16/4/15.
//  Copyright © 2016年 us.nonda. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let requestNormal = LocationRequest.normalRequest()
        requestNormal.setLocateCallback({ (location, error) in
            print("\(location) startTime:\(requestNormal.startTime)")
        })
        LocationManager.share().addRequest(requestNormal)
        
        let requestNavigation = LocationRequest.navigationRequest()
        requestNavigation.setLocateCallback({ (location, error) in
            print("\(location)")
        })
        LocationManager.share().addRequest(requestNavigation)
        
        let requestHeading = LocationRequest.headingRequest()
        requestHeading.setHeadCallback { (heading) in
            print("\(heading)")
        }
        LocationManager.share().addRequest(requestHeading)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

