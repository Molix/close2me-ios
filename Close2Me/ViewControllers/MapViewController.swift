//
//  MapViewController.swift
//  Close2Me
//
//  Created by Ale MQ on 30/4/18.
//  Copyright © 2018 Ale MQ. All rights reserved.
//

import MapKit
import CoreLocation


class MapViewController : UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var userName: UILabel!
    var locationManager: CLLocationManager!
    var lastValidUserLocation: CLLocation!
    var initialMapRegionSet: Bool = false
    let annotation = MKPointAnnotation()
    var allAnnotations = [userInfo]()
    
    var userData: NSDictionary?
    var updateTimer: Timer!
    var firstLocationDone: Bool = false
    
    let queryService = APIUtils()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.userName.text = UserDefaults.standard.string(forKey: Constants.Preferences.UserName) ?? ""
        if (CLLocationManager.locationServicesEnabled())
        {
            locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
            locationManager.distanceFilter = kCLDistanceFilterNone
            mapView.showsUserLocation = true
            self.mapView.addAnnotation(self.annotation)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateUserLocation), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        updateTimer.invalidate()
    }
    
    @objc func updateUserLocation()
    {
        if self.userData?[Constants.Model.UserId] as? String != "",
            self.firstLocationDone {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.queryService.sendUserData(userData: (self?.userData)!) { (usersInfo) -> Void in
                    for annotation: userInfo in (self?.allAnnotations)! {
                        if(!usersInfo.contains(where: {$0.userId == annotation.userId})) {
                            let annotationIndex = self?.allAnnotations.index(where: { $0.userId == annotation.userId })
                            self?.allAnnotations.remove(at: annotationIndex!)
                            DispatchQueue.main.async { [weak self] in
                                self?.mapView.view(for: annotation)
                                // Fade Out user out of Ratio
                                UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
                                    let annotationView = self?.mapView.view(for: annotation)
                                    annotationView?.alpha = 0
                                }, completion: {
                                    (finished: Bool) -> Void in
                                    self?.mapView.removeAnnotation(annotation)
                                })
                            }
                        }
                    }
                    for userInfo: userInfo in usersInfo {
                        if let userId = userInfo.userId,
                            userInfo.userName != nil {
                            print("Todo Bien!")
                            let annotationCoordinate = CLLocationCoordinate2D(latitude: userInfo.coordinate.latitude, longitude: userInfo.coordinate.longitude)
                            if (!((self?.allAnnotations.contains(where: {$0.userId == userId}))!)) {
                                // Add new annotation
                                userInfo.title = userInfo.userName
                                self?.allAnnotations.append(userInfo)
                                DispatchQueue.main.async { [weak self] in
                                    // Fade In user inside Ratio
                                    self?.mapView.addAnnotation(userInfo)
                                    let annotationView = self?.mapView.view(for: userInfo)
                                    annotationView?.alpha = 0
                                    UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseIn, animations: {
                                        annotationView?.alpha = 1.0;
                                    }, completion: nil)
                                }
                            }
                            else {
                                let annotationIndex = self?.allAnnotations.index(where: { $0.userId == userId })
                                // Update annotation data
                                print("Actualizando a \(self?.allAnnotations[annotationIndex!].userName ?? "Desconocido")")
                                DispatchQueue.main.async { [weak self] in
                                    if annotationIndex! < (self?.allAnnotations.count)! {
                                        self?.allAnnotations[annotationIndex!].coordinate = annotationCoordinate
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func updateUserRadiusPosition()
    {
        self.mapView.removeOverlays(self.mapView.overlays)
        let userRadius = MKCircle(center: self.lastValidUserLocation.coordinate, radius: 500)
        self.mapView.add(userRadius)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            let circle = MKCircleRenderer(overlay: overlay)
            circle.fillColor = UIColor(red: 1.0, green: 1.0, blue: 0, alpha: 0.1)
            return circle
        } else {
            return MKPolylineRenderer()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        let center = CLLocationCoordinate2D(latitude: (location?.coordinate.latitude)!, longitude: (location?.coordinate.longitude)!)
        if !self.initialMapRegionSet {
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            self.mapView.setRegion(region, animated: true)
            self.initialMapRegionSet = true
        }
        self.lastValidUserLocation = location
        if !self.firstLocationDone {
            self.firstLocationDone = true
        }
        self.userData = [
            Constants.Model.UserId: UserDefaults.standard.string(forKey: Constants.Preferences.UserId) ?? "",
            Constants.Model.UserLatitude: location?.coordinate.latitude ?? 0.00,
            Constants.Model.UserLongitude: location?.coordinate.longitude ?? 0.00,
            Constants.Model.UserDesiredRatio: 500.00
        ]
        updateUserRadiusPosition()
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // Don't want to show a custom image if the annotation is the user's location.
        guard !(annotation is MKUserLocation) else {
            return nil
        }
        
        // Better to make this class property
        let annotationIdentifier = "AnnotationIdentifier"
        
        var annotationView: MKAnnotationView?
        if let dequeuedAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) {
            annotationView = dequeuedAnnotationView
            annotationView?.annotation = annotation
        }
        else {
            let av = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
//            av.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            annotationView = av
        }
        
        if let annotationView = annotationView {
            // Configure your annotation view here
            annotationView.canShowCallout = true
            annotationView.image = UIImage(named: "overHead")
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print("Altitude:", mapView.camera.altitude)
    }
    
    @IBAction func goToMe(_ sender: Any) {
        let center = CLLocationCoordinate2D(latitude: (self.lastValidUserLocation?.coordinate.latitude)!, longitude: (self.lastValidUserLocation?.coordinate.longitude)!)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        self.mapView.setRegion(region, animated: true)
    }
}
