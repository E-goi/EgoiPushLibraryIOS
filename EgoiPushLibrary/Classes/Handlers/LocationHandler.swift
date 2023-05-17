//
//  LocationHandler.swift
//  EgoiPushLibrary
//
//  Created by João Silva on 15/01/2021.
//

import CoreLocation

class LocationHandler: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var runningTimers: [String: Timer] = [:]
    private var regionsMonitored: [String: CLCircularRegion] = [:]
    
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
    
    @available(iOS 14.0, *)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .notDetermined:
            break
            
        case .authorizedAlways:
            manager.allowsBackgroundLocationUpdates = true
            manager.showsBackgroundLocationIndicator = true
            break
            
        case .restricted, .denied:
            manager.stopUpdatingLocation()
            manager.allowsBackgroundLocationUpdates = false
            manager.showsBackgroundLocationIndicator = false
            break
            
        @unknown default:
            manager.stopUpdatingLocation()
            manager.allowsBackgroundLocationUpdates = false
            manager.showsBackgroundLocationIndicator = false
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if #unavailable(iOS 14.0) {
            switch status {
            case .authorizedWhenInUse, .notDetermined:
                break
                
            case .authorizedAlways:
                manager.allowsBackgroundLocationUpdates = true
                manager.showsBackgroundLocationIndicator = true
                break
                
            case .restricted, .denied:
                manager.stopUpdatingLocation()
                manager.allowsBackgroundLocationUpdates = false
                manager.showsBackgroundLocationIndicator = false
                break
                
            @unknown default:
                manager.stopUpdatingLocation()
                manager.allowsBackgroundLocationUpdates = false
                manager.showsBackgroundLocationIndicator = false
            }
        }
    }
    
    /// Handle the trigger of a geofence
    /// - Parameters:
    ///   - manager: The instance of the location manager
    ///   - region: The region that got triggered
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let region = region as? CLCircularRegion else {
            print("Unkown region triggered.")
            return
        }
        
        guard let notification = EgoiPushLibrary.shared.getPendingNotification(identifier: region.identifier) else {
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
        
        stopMonitoringRegion(region: region)
        EgoiPushLibrary.shared.fireNotification(key: region.identifier)
    }
    
    /// Validate if the user is inside of the the region created during the geofence created
    /// - Parameter region: The target region
    /// - Returns: True or False
    private func insideRegion(region: CLCircularRegion) -> Bool {
        guard let location = locationManager.location?.coordinate else {
            return false
        }
        
        let currentLocation: CLLocation = CLLocation(latitude: CLLocationDegrees(location.latitude), longitude: CLLocationDegrees(location.longitude))
        let targetLocation: CLLocation = CLLocation(latitude: CLLocationDegrees(region.center.latitude), longitude: CLLocationDegrees(region.center.longitude))
        let distance = currentLocation.distance(from: targetLocation)
        
        return distance.isLessThanOrEqualTo(region.radius)
    }
    
    /// Create a region based on the specified coordinates.
    /// - Parameters:
    ///   - latitude: The latitude of the region's center.
    ///   - longitude: The longitude of the region's center.
    ///   - radius: The radius of the region.
    ///   - identifier: The identifier of the region.
    /// - Returns:A region with the center at the given coordinates.
    func createRegionAtCoordinates(_ latitude: Double, _ longitude: Double, _ radius: Double, _ identifier: String) -> CLCircularRegion {
        let center = CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
        let region = CLCircularRegion(center: center, radius: CLLocationDistance(radius), identifier: identifier)
        region.notifyOnEntry = true
        region.notifyOnExit = false
        
        return region
    }
    
    /// Start monitoring a region.
    /// - Parameters:
    ///   - region: The region to be monitored.
    ///   - duration: The duration of the region. (optional)
    func monitorRegion(region: CLCircularRegion, duration: Int? = nil) {
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
            print("Monitoring not available.")
            return
        }
        
        if insideRegion(region: region) {
            EgoiPushLibrary.shared.fireNotification(key: region.identifier)
        } else {
            locationManager.startUpdatingLocation()
            locationManager.startMonitoring(for: region)
            regionsMonitored[region.identifier] = region
            
            if let duration = duration, duration > 0 {
                startTimer(duration, region)
            }
            
            print("Geofence \(region.identifier) created.")
        }
    }
    
    /// Stop monitoring the specified region.
    /// - Parameters:
    ///   - region: The region to stop monitoring.
    private func stopMonitoringRegion(region: CLCircularRegion) {
        locationManager.stopMonitoring(for: region)
        regionsMonitored.removeValue(forKey: region.identifier)
        
        if regionsMonitored.isEmpty {
            locationManager.stopUpdatingLocation()
        }
        
        print("Geofence \(region.identifier) removed.")
        stopTimer(identifier: region.identifier)
    }
    
    /// Start a timer for the specified region.
    /// - Parameters:
    ///   - duration: The duration of the timer in seconds.
    ///   - region: The region that will be associated with the timer.
    private func startTimer(_ duration: Int, _ region: CLCircularRegion) {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .second, value: duration / 1000, to: Date())
        
        guard let date = date else {
            print("Invalid date format.")
            return
        }
        
        let timer = Timer(fireAt: date, interval: 0, target: self, selector: #selector(stopMonitoringRegionFromTimer), userInfo: region, repeats: false)
        RunLoop.current.add(timer, forMode: .common)
        runningTimers[region.identifier] = timer
    }
    
    /// Stop a timer with the specified identifier.
    /// - Parameters:
    ///   - identifier: The identifier of the timer to be stopped.
    private func stopTimer(identifier: String) {
        guard let timer = runningTimers[identifier] else {
            print("Timer with identifier \(identifier) not found.")
            return
        }
        
        timer.invalidate()
        runningTimers.removeValue(forKey: identifier)
        print("Timer with identifier \(identifier) removed.")
    }
    
    /// Stop monitoring a region when the associated timer ends.
    /// - Parameters:
    ///    - timer: The timer that ended.
    @objc
    private func stopMonitoringRegionFromTimer(timer: Timer) {
        guard let region = timer.userInfo as? CLCircularRegion else {
            print("Invalid region.")
            return
        }
        
        stopMonitoringRegion(region: region)
    }
}
