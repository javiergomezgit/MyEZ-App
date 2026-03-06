//
//  ZipCodeProvider.swift
//  MyEZ
//
//  Created by Codex on 3/6/26.
//

import Foundation
import CoreLocation

final class ZipCodeProvider: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var completion: ((String?) -> Void)?
    private var didComplete = false

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestZipCode(completion: @escaping (String?) -> Void) {
        self.completion = completion
        didComplete = false

        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            complete(with: nil)
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        @unknown default:
            complete(with: nil)
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .restricted, .denied:
            complete(with: nil)
        case .notDetermined:
            break
        @unknown default:
            complete(with: nil)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            complete(with: nil)
            return
        }

        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            let zip = placemarks?.first?.postalCode
            self?.complete(with: zip)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        complete(with: nil)
    }

    private func complete(with zip: String?) {
        guard !didComplete else { return }
        didComplete = true
        DispatchQueue.main.async { [completion] in
            completion?(zip)
        }
    }
}
