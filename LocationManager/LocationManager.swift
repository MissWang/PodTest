//
//  LocationManager.swift
//  LocationManager
//
//  Created by wangxinyan on 16/4/15.
//  Copyright © 2016年 us.nonda. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

let kNotificationLocationChangeStatus = "kNotificationLocationChangeStatus"

class LocationManager: NSObject, CLLocationManagerDelegate {
    
    var locationManager = CLLocationManager()
    var requests = [LocationRequest]()
    var backgroundTaskIdentifier = UIBackgroundTaskInvalid
    var authorizationStatus = CLAuthorizationStatus.NotDetermined
    class func share() -> LocationManager{
        struct StructLocationManager {
            static var locationManager:LocationManager!
            static var predicate = dispatch_once_t()
        }
        dispatch_once(&StructLocationManager.predicate) { 
            StructLocationManager.locationManager = LocationManager()
        }
        return StructLocationManager.locationManager
    }
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        if #available(iOS 9.0, *) {
            locationManager.allowsBackgroundLocationUpdates = true
        }
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(appWillResignActive), name: UIApplicationWillResignActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplicationDidBecomeActiveNotification, object: nil)
    }
    
    func appWillResignActive(){
        synchronized(requests) { 
            for request in self.requests {
                if request.type != .NormalRequest {
                    request.disableByManager = true
                }
            }
        }
        checkLocationStatus()
    }
    
    func appDidBecomeActive(){
        synchronized(requests) { 
            for request in self.requests {
                if request.type != .NormalRequest {
                    request.disableByManager = false
                }
            }
        }
        checkLocationStatus()
    }
    
    func addRequest(request:LocationRequest){
        //background
        
        if UIApplication.sharedApplication().applicationState == .Background {
            if backgroundTaskIdentifier == UIBackgroundTaskInvalid {
                backgroundTaskIdentifier = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({
                })
            }
            
            if request.type != .NormalRequest {
                request.disableByManager = true
            }
        }
        askForAuthority()
        
        synchronized(requests) {
            self.requests.append(request)
        }

        switch request.type {
        case .NormalRequest:
            dispatch_async(dispatch_get_main_queue(), {
                NSTimer.scheduledTimerWithTimeInterval(request.timeInterval, target: self, selector: #selector(self.timeEndUp), userInfo: request, repeats: false)
            })
        case .HeadingRequest:
            break
        case .NavigationRequest:
            break
        }
        
        checkLocationStatus()
    }
    
    func addRequests(requests:[LocationRequest]){
        for request in requests {
            addRequest(request)
        }
    }
    
    func removeRequest(request:LocationRequest){
        synchronized(requests) { 
            if let index = self.requests.indexOf(request) {
                self.requests.removeAtIndex(index)
            }
        }
        checkLocationStatus()
    }
    
    func timeEndUp(timer:NSTimer){
        let request = timer.userInfo as! LocationRequest
        synchronized(requests) { 
            if self.requests.contains(request) {
                if request.location != nil {
                    request.locationCallback?(location:request.location, error: nil)
                } else {
                    request.locationCallback?(location:nil, error: NSError(domain: "LocationManagerFailed", code: 1, userInfo: nil))
                }
                self.removeRequest(request)
            }
        }
    }
    
    func sendAllReply(){
        let allRequests = requests
        synchronized(requests) { 
            for request in allRequests {
                if request.type == .NavigationRequest {
                    request.locationCallback?(location:request.location,error:nil)
                }
                else if request.type == .NormalRequest {
                    if request.alreadyHaveBestLocation() {
                        request.locationCallback?(location:request.location!,error:nil)
                        self.removeRequest(request)
                    }
                }
            }
        }
    }
    
    func checkLocationStatus(){
        
        var needLocation = false, needHeading = false
        synchronized(requests) {
            if self.requests.count == 0 {
                self.enterLowMode()
                return //
            }
            for request in self.requests {
                if request.isActive && !request.disableByManager {
                    if request.type == .HeadingRequest {
                        needHeading = true
                    } else {
                        needLocation = true
                    }
                }
            }
        }
        
        if needLocation {
            dispatch_async(dispatch_get_main_queue(), { 
                self.locationManager.startUpdatingLocation()
            })
        }
        if needHeading {
            dispatch_async(dispatch_get_main_queue(), { 
                self.locationManager.startUpdatingHeading()
            })
        }
        if !needLocation && !needHeading {
            enterLowMode()
        }
    }
    
    func enterLowMode(){
        dispatch_async(dispatch_get_main_queue()) { 
            self.locationManager.stopUpdatingHeading()
            self.locationManager.stopUpdatingLocation()
        }
        
        if backgroundTaskIdentifier != UIBackgroundTaskInvalid {
            //Delay 5 seconds to save location.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC * 5)), dispatch_get_main_queue()) {
                UIApplication.sharedApplication().endBackgroundTask(self.backgroundTaskIdentifier)
                self.backgroundTaskIdentifier = UIBackgroundTaskInvalid
            }
        }
    }
    
    func askForAuthority(){
        if locationManager.respondsToSelector(#selector(locationManager.requestAlwaysAuthorization)) {
            locationManager.requestAlwaysAuthorization()
        }
    }

    
    func synchronized(lock:AnyObject,f:()->()){
        objc_sync_enter(lock)
        f()
        objc_sync_exit(lock)
    }
    
    //MARK: - CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        synchronized(requests) { 
            if self.requests.count == 0 {
                return
            }
            for request in self.requests {
                for location in locations {
                    if request.type != .HeadingRequest {
                        if request.accept(location) {
                            request.location = location
                        }
                    }
                    
                    if request.type == .NormalRequest {
                        if request.latestLocation == nil {
                            request.latestLocation = location
                        } else if request.latestLocation!.horizontalAccuracy >= location.horizontalAccuracy {
                            request.latestLocation = location
                        }
                    }
                }
            }
        }
        
        sendAllReply()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        synchronized(requests) { 
            for request in self.requests {
                if request.type == .HeadingRequest {
                    request.headingCallback?(heading:newHeading)
                }
            }
        }
    }
    
    func locationManagerShouldDisplayHeadingCalibration(manager: CLLocationManager) -> Bool {
        if manager.heading == nil {return true}
        if manager.heading!.headingAccuracy < 0 {return true}
        if manager.heading!.headingAccuracy > 20 {return true}
        return false
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        authorizationStatus = status
        if status == .AuthorizedAlways {
            checkLocationStatus()
        }
        NSNotificationCenter.defaultCenter().postNotificationName(kNotificationLocationChangeStatus, object: nil)
    }
}
