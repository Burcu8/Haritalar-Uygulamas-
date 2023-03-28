//
//  ViewController.swift
//  haritalarUygulaması
//
//  Created by Burcu Kamilçelebi on 8.03.2023.
//

import UIKit
import MapKit
import CoreLocation
import CoreData


class MapsViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var notTextField: UITextField!
    @IBOutlet weak var isimTextField: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    
    // konum yöneticisi oluşturuyoruz
    var locationManager = CLLocationManager()
    var secilenLatitude = Double()
    var secilenLongitude = Double()
    
    var secilenIsim = ""
    var secilenId : UUID?

    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()  //izin almak
        locationManager.startUpdatingLocation()  //konumu güncellemeye başla
        
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(konumSec(gestureRecognizer: )))
        gestureRecognizer.minimumPressDuration = 2 // kullanıcı kaç saniye bassın
        mapView.addGestureRecognizer(gestureRecognizer) // basılan yere eklesin
        
        if secilenIsim != "" {
            // coredatadan verileri çek
            if let uuidString = secilenId?.uuidString {
                
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext
                
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Yer")
                fetchRequest.predicate = NSPredicate(format: "id = %@", uuidString)
                fetchRequest.returnsObjectsAsFaults = false
                
                do {
                    let sonuclar = try context.fetch(fetchRequest)
                    
                    if sonuclar.count > 0 {
                        for sonuc in sonuclar as! [NSManagedObject] {
                            
                            if let isim = sonuc.value(forKey: "isim") as? String{
                                annotationTitle = isim
                                
                                if let not = sonuc.value(forKey: "not") as? String{
                                    annotationSubtitle = not
                                    
                                    if let latitude = sonuc.value(forKey: "latitude") as? Double {
                                        annotationLatitude = latitude
                                        
                                        if let longitude = sonuc.value(forKey: "longitude") as? Double {
                                            annotationLongitude = longitude
                                            
                                            let annotation = MKPointAnnotation()
                                            annotation.title = annotationTitle
                                            annotation.subtitle = annotationSubtitle
                                            let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                            annotation.coordinate = coordinate
                                            
                                            mapView.addAnnotation(annotation)
                                            isimTextField.text = annotationTitle
                                            notTextField.text = annotationSubtitle
                                            
                                            // isim varsa durduruyoruz.
                                            locationManager.stopUpdatingLocation()
                                            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                            let region = MKCoordinateRegion(center: coordinate, span: span)
                                            mapView.setRegion(region, animated: true)
                                        }
                                    }
                                }
                            }
                        }
                        
                    }
                } catch {
                    print("hata")
                }
            }
            
        }else {
            //yeni veri eklemeye geldi
        }
        
    }
    
    @IBAction func kaydetTiklandi(_ sender: Any) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let yeniYer = NSEntityDescription.insertNewObject(forEntityName: "Yer", into: context)
        
        yeniYer.setValue(isimTextField.text, forKey: "isim")
        yeniYer.setValue(notTextField.text, forKey: "not")
        yeniYer.setValue(secilenLatitude, forKey: "latitude")
        yeniYer.setValue(secilenLongitude, forKey: "longitude")
        yeniYer.setValue(UUID(), forKey: "id")
        
        do {
            try context.save()
            print("kayıt edildi")
        } catch {
            print("hata var ")
        }
        
        // kaydete bastıktan sonra listeye döndürüyor.
        NotificationCenter.default.post(name: NSNotification.Name("yeniYerOlusturuldu"), object: nil)
        navigationController?.popViewController(animated: true)
    }
    // anotasyon döndürmek için.
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let reuseId = "benimAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
        
        if pinView == nil {
            
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true // oluşturduğumuz anotasyon ekstra bir şey gösterebilir mi?
            pinView?.tintColor = .red
            
            // buton oluştur ve anotasyonu içerisinde göster.
            let button = UIButton(type: .detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
            
            
        }else {
            pinView?.annotation = annotation
        }
        return pinView
    }
    
    //gösterdiğimiz butonun üstüne tıklanınca ne olacak.
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if secilenIsim != "" {
            
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarkDizisi, hata) in
                
                if let placemarks = placemarkDizisi {
                    if placemarks.count > 0 {
                        
                        //harita ögesi oluşturduk
                        let yeniPlacemark = MKPlacemark(placemark: placemarks[0]) // ilk elemanı getir
                        let item = MKMapItem(placemark: yeniPlacemark)
                        item.name = self.annotationTitle
                        
                        
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving] // ilk hangisini baz alıcak onu seçiyoruz.
                        item.openInMaps(launchOptions: launchOptions) // yukardakini haritada aç diyoruz.
                        
                    }
                }
            
            }
            
        }
    }
    
    @objc func konumSec(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            
            let dokunulanNokta = gestureRecognizer.location(in: mapView)
            let dokunulanKoordinat = mapView.convert(dokunulanNokta, toCoordinateFrom:mapView)
            
            secilenLatitude = dokunulanKoordinat.latitude
            secilenLongitude = dokunulanKoordinat.longitude
            
            // işaretleme kısmı, pin oluşuyor.
            let annotation = MKPointAnnotation()
            annotation.coordinate = dokunulanKoordinat
            annotation.title = isimTextField.text
            annotation.subtitle = notTextField.text
            mapView.addAnnotation(annotation)
            
            
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
       //print(locations[0].coordinate.latitude)
        //print(locations[0].coordinate.longitude)
        
        if secilenIsim == "" {
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)      // seçtiğimiz yeri ne kadar büyük ya da küçük görüyoruz o değişecek
            let region = MKCoordinateRegion(center: location, span: span) //merkezi konum
            mapView.setRegion(region, animated: true)
        }
        
       
    }

}

