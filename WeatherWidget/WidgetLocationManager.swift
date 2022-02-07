//
//  WidgetLocationManager.swift
//  WeatherWidgetExtension
//
//  Created by Steve on 6/2/2022.
//

import Foundation
import CoreLocation
import WidgetKit

class WidgetLocationManager: NSObject, CLLocationManagerDelegate {
    var locationManager = CLLocationManager()
        var location: CLLocation?
        
        override init() {
            super.init()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
            WidgetCenter.shared.reloadAllTimelines()
        }
        
        func requestUpdate(_ completion: @escaping () -> Void) {
            self.locationManager.requestWhenInUseAuthorization()
            self.locationManager.startUpdatingLocation()
            WidgetCenter.shared.reloadAllTimelines()
        }
        
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let location = locations.last else { return }
            self.location = location
        }
        
        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            print(error.localizedDescription)
        }
}
