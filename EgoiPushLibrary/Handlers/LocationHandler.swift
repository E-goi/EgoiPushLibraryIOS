//
//  LocationHandler.swift
//  EgoiPushLibrary
//
//  Created by João Silva on 15/01/2021.
//

import CoreLocation

class LocationHandler: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        
        locationManager.delegate = self
    }
    
    /// Request access to location when app is in foreground
    func requestForegroundAccess() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// Request access to location when app is in background
    func requestBackgroundAccess() {
        locationManager.requestAlwaysAuthorization()
    }
    
    /// Handle user response to location access request
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    /// Creates a geofence
    /// - Parameter message: The message used to create the geofence
    func createGeofence(message: EGoiMessage) {
        if isMonitoringAvailable() {
            let region = createRegion(message)
            
            guard let wrappedRegion = region else {
                return
            }
            
            if insideRegion(region: wrappedRegion) {
                EgoiPushLibrary.shared.fireNotification(key: message.data.messageHash!)
            } else {
                locationManager.startMonitoring(for: wrappedRegion)
            }
        }
    }
    
    /// Validate if the monitoring of geofences is available
    /// - Returns: True or False
    func isMonitoringAvailable() -> Bool {
        return CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self)
    }
    
    /// Handle the trigger of a geofence
    /// - Parameters:
    ///   - manager: The instance of the location manager
    ///   - region: The region that got triggered
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let region = region as? CLCircularRegion {
            let identifier = region.identifier
            
            EgoiPushLibrary.shared.fireNotification(key: identifier)
        }
    }
    
    /// Validate if the user is inside of the the region created during the geofence created
    /// - Parameter region: The target region
    /// - Returns: True or False
    private func insideRegion(region: CLCircularRegion) -> Bool {
        if let location = locationManager.location?.coordinate {
            
            let currentLocation: CLLocation = CLLocation(latitude: CLLocationDegrees(location.latitude), longitude: CLLocationDegrees(location.longitude))
            
            let targetLocation: CLLocation = CLLocation(latitude: CLLocationDegrees(region.center.latitude), longitude: CLLocationDegrees(region.center.longitude))
            
            let distance = currentLocation.distance(from: targetLocation)
            
            return distance.isLessThanOrEqualTo(region.radius)
        }
        
        return false
    }
    
    /// Creates a region to add to a geofence
    /// - Parameter message: The message used to create the region
    /// - Returns: The region
    private func createRegion(_ message: EGoiMessage) -> CLCircularRegion? {
        let geo = message.data.geo
        
        guard let latitude = geo.latitude else {
            return nil
        }
        
        guard let longitude = geo.longitude else {
            return nil
        }
        
        guard let radius = geo.radius else {
            return nil
        }
        
        let center = CLLocationCoordinate2DMake(CLLocationDegrees(latitude), CLLocationDegrees(longitude))
        
        let region = CLCircularRegion(center: center, radius: CLLocationDistance(radius), identifier: message.data.messageHash!)
        
        region.notifyOnExit = false
        region.notifyOnEntry = true
        
        return region
    }
}
