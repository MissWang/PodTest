//
//  LocationRequest.swift
//  LocationManager
//
//  Created by wangxinyan on 16/4/15.
//  Copyright © 2016年 us.nonda. All rights reserved.
//

import Foundation
import CoreLocation

public enum LocationRequestType {
    case NormalRequest
    case NavigationRequest
    case HeadingRequest
}

public typealias LocationCallback = (location:CLLocation?,error:NSError?) -> Void
public typealias HeadingCallback = (heading:CLHeading) -> Void

@objc

public class LocationRequest: NSObject {
    var bestAccuracy:CLLocationAccuracy = 0  //for NormalRequest
    var worstAccuracy:CLLocationAccuracy = 0  //for NormalRequest
    var type:LocationRequestType
    var timeInterval:NSTimeInterval = 0
    var isActive = true
    var disableByManager = false
    var location:CLLocation?
    public var startTime = NSDate()
    public var headingCallback:HeadingCallback?
    public var locationCallback:LocationCallback?
    public var latestLocation:CLLocation?
    
    public func setLocateCallback(callback:LocationCallback){
        locationCallback = callback
    }
    
    public func setHeadCallback(callback:HeadingCallback){
        headingCallback = callback
    }
    
    public class func normalRequest() -> LocationRequest{
        return LocationRequest(type: .NormalRequest, timeInterval: 20,bestAccuracy: 5, worstAccuracy: 30)
    }
    
    public class func navigationRequest() -> LocationRequest {
        return LocationRequest(type: .NavigationRequest)
    }
    
    public class func headingRequest() -> LocationRequest {
        return LocationRequest(type: .HeadingRequest)
    }
    
    init(type:LocationRequestType){
        self.type = type
    }
    
    public init(type:LocationRequestType, timeInterval:NSTimeInterval, bestAccuracy:CLLocationAccuracy, worstAccuracy:CLLocationAccuracy) {
        self.type = type
        self.timeInterval = timeInterval
        self.bestAccuracy = bestAccuracy
        self.worstAccuracy = worstAccuracy
    }
    
    func accept(location:CLLocation) -> Bool {
        if type == .NavigationRequest {
            return true
        }
        
        if startTime.timeIntervalSinceDate(location.timestamp) > self.timeInterval {
            return false
        }
        
        if location.horizontalAccuracy > worstAccuracy {
            return false
        }
        
        if location.horizontalAccuracy > worstAccuracy {
            return false
        }
        
        if self.location != nil && location.horizontalAccuracy >= self.location!.horizontalAccuracy {
            return false
        }
        
        return true
    }
    
    func alreadyHaveBestLocation() -> Bool {
        return location != nil && location!.horizontalAccuracy <= bestAccuracy
    }
}