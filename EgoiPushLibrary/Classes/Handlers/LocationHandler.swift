//
//  LocationHandler.swift
//  EgoiPushLibrary
//
//  Created by João Silva on 15/01/2021.
//

import CoreLocation

class LocationHandler: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let pendingTimers = NSMutableDictionary()
    
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
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingLocation()
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
                
                if let duration = message.data.geo.duration {
                    let calendar = Calendar.current
                    let date = calendar.date(byAdding: .second, value: duration / 1000, to: Date())
                    
                    guard let dt = date else {
                        print("Invalid target date")
                        return
                    }
                    
                    guard let hash = message.data.messageHash else {
                        print("Invalid campaign hashcode")
                        return
                    }
                    
                    let context: [String: Any] = [
                        "region": wrappedRegion,
                        "identifier": hash
                    ]
                    
                    let timer = Timer(fireAt: dt, interval: 0, target: self, selector: #selector(stopGeofenceFromTimer), userInfo: context, repeats: false)
                    
                    RunLoop.current.add(timer, forMode: .common)
                    
                    pendingTimers.setValue(timer, forKey: hash)
                }
            }
        }
    }
    
    @objc private func stopGeofenceFromTimer(timer: Timer) {
        let context = timer.userInfo as? [String: Any]
        
        guard let ctx = context else {
            print("Invalid timer context")
            return
        }
        
        guard let region = ctx["region"] as? CLRegion else {
            print("Invalid region")
            return
        }
        
        guard let identifier = ctx["identifier"] as? String else {
            print("Invalid timer identifier")
            return
        }
        
        killGeofence(region: region)
        
        pendingTimers.removeObject(forKey: identifier)
        EgoiPushLibrary.shared.deletePendingNotification(key: identifier)
    }
    
    private func killGeofence(region: CLRegion) {
        locationManager.stopMonitoring(for: region)
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
            
            guard let notification = EgoiPushLibrary.shared.getPendingNotification(identifier: identifier) else {
                print("Notification not found for current region.")
                return
            }
            
            if let periodStart = notification.data.geo.periodStart,
               let periodEnd = notification.data.geo.periodEnd,
               periodStart != "",
               periodEnd != ""
            {
                let periodStartSplit = periodStart.split(separator: ":")
                let periodEndSplit = periodEnd.split(separator: ":")

                let date = Date()

                guard let startHour = Int(periodStartSplit[0]),
                      let startMinute = Int(periodStartSplit[1]),
                      let startDate = Calendar.current.date(bySettingHour: startHour, minute: startMinute, second: 0, of: date),
                      let endHour = Int(periodEndSplit[0]),
                      let endMinute = Int(periodEndSplit[1]),
                      let endDate = Calendar.current.date(bySettingHour: endHour, minute: endMinute, second: 0, of: date),
                      date >= startDate,
                      date <= endDate
                else {
                    print("Outside defined period.")
                    return
                }
            }
            
            if let timer = pendingTimers[identifier] as? Timer {
                timer.invalidate()
                pendingTimers.removeObject(forKey: identifier)
            }
            
            killGeofence(region: region)
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
