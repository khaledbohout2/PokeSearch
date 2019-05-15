//
//  ViewController.swift
//  PokeSearch
//
//  Created by Khaled Bohout on 2/16/19.
//  Copyright © 2019 Khaled Bohout. All rights reserved.
//

import UIKit
import FirebaseDatabase

class ViewController: UIViewController,MKMapViewDelegate,CLLocationManagerDelegate {
    
    @IBOutlet weak var mapview: MKMapView!
    var locationmanager = CLLocationManager()
    var maphadcenteredonce = false
    var geoFire:GeoFire!
    var geofireref:DatabaseReference!
    let annoIdentifier = "Pokemon"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapview.delegate = self
        mapview.userTrackingMode = MKUserTrackingMode.follow
        
        //reference to database
        geofireref = Database.database().reference()
        geoFire = GeoFire(firebaseRef: geofireref)
        
        /*locationmanager.delegate = self
        locationmanager.desiredAccuracy = kCLLocationAccuracyBest
        locationmanager.requestWhenInUseAuthorization()
        locationmanager.startUpdatingLocation()
        locationmanager.startMonitoringSignificantLocationChanges()*/
    }
    override func viewDidAppear(_ animated: Bool) {
        locationauthstatus()
    }
    
    func locationauthstatus(){
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse{
            mapview.showsUserLocation = true
        }
        else{
            locationmanager.requestWhenInUseAuthorization()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
      //  locationmanager = manager
        
        if status == .authorizedWhenInUse{
            mapview.showsUserLocation = true
        }
    }
    
    func centermaponlocation(location:CLLocation){
        let coordinateregion = MKCoordinateRegion.init(center: location.coordinate,latitudinalMeters: 2000,longitudinalMeters: 2000)
        mapview.setRegion(coordinateregion, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        
        if let loc = userLocation.location{
            
            if !maphadcenteredonce{
                
                centermaponlocation(location: loc)
                maphadcenteredonce = true
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        var annotationview:MKAnnotationView?
        
        if annotation.isKind(of: MKUserLocation.self){
            
            annotationview = MKAnnotationView(annotation: annotation, reuseIdentifier: "User")
            annotationview?.image = UIImage(named: "ash")
        }
        else if let annodeq = mapView.dequeueReusableAnnotationView(withIdentifier: annoIdentifier){
            annotationview = annodeq
            annotationview?.annotation = annotation
        }
        else{
            let av = MKAnnotationView(annotation: annotation, reuseIdentifier: annoIdentifier)
            av.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            annotationview = av
        }
        
        if let annotationview = annotationview , let anno = annotation as? PokeAnntation
        {
            annotationview.canShowCallout = true
            annotationview.image = UIImage(named: "\(anno.pokemonNumber)")
            let btn = UIButton()
            btn.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            btn.setImage(UIImage(named: "map"), for: .normal)
            annotationview.rightCalloutAccessoryView = btn
        }
        
        return annotationview
    }

    func createSighting(forlocation location:CLLocation,withpokemon pokeid:Int)
    {
        geoFire.setLocation(location,forKey: "\(pokeid)")
    }
    
    func showSightsOnMap(location:CLLocation){
        
        let circleQuery = geoFire?.query(at: location, withRadius: 2.5)
        _ = circleQuery?.observe(GFEventType.keyEntered, with: { (key, location) in
                let anno = PokeAnntation(coordinate: location.coordinate, pokemonNumber:Int(key)!)
            self.mapview.addAnnotation(anno)
            
        })
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        
        let loc = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        showSightsOnMap(location: loc)
    
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if let anno = view.annotation as? PokeAnntation{
            let place = MKPlacemark(coordinate: anno.coordinate)
            let destination = MKMapItem(placemark: place)
            destination.name = "Pokemon Sighting"
            let regionDistance: CLLocationDistance = 1000
            let regionSpan = MKCoordinateRegion(center: anno.coordinate, latitudinalMeters: regionDistance, longitudinalMeters: regionDistance)
            
            let options = [MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center), MKLaunchOptionsMapSpanKey:  NSValue(mkCoordinateSpan: regionSpan.span), MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving] as [String : Any]
            
            MKMapItem.openMaps(with: [destination], launchOptions: options)
        }
    }

    @IBAction func spotrandompokemon(_ sender: Any) {
        
        let loc = CLLocation(latitude: mapview.centerCoordinate.latitude, longitude: mapview.centerCoordinate.longitude)
        
        let rand = arc4random_uniform(151) + 1
        
        createSighting(forlocation: loc, withpokemon: Int(rand))
    }
}

