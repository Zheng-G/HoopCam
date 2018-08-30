//
//  SettingViewController.swift
//  HoopsCam
//
//  Created by Hans on 26/02/2018.
//  Copyright (c) 2018 Fresh Green. All rights reserved.
//


import UIKit
import CoreLocation


class SettingViewController: UIViewController,  CLLocationManagerDelegate ,  UIPopoverPresentationControllerDelegate{

 var locationManager = CLLocationManager()
    
    @IBOutlet weak var txtHomeName: UITextField!
    @IBOutlet weak var txtOpponentName: UITextField!
    
   
    
    @IBOutlet weak var txtHomeInitials: UITextField!
    @IBOutlet weak var txtOpponentInitials: UITextField!
    
    
    @IBOutlet weak var bthHomeColor: UIButton!
    @IBOutlet weak var btnOpponentColor: UIButton!
    
    @IBOutlet weak var txtLocation: UITextField!
    
    @IBOutlet weak var switchHalves: UISwitch!

    var colorPicker  : SwiftHSVColorPicker?
    
    func CGRectMake(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        colorPicker = SwiftHSVColorPicker(frame: CGRectMake(700, 350, 250, 300))
        self.view.addSubview(colorPicker!)
        colorPicker?.setViewColor(UIColor.white)
    }

   
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    
    
    
    @IBAction func btnHomeColorPressed(_ sender: Any) {
        
        let selectedColor = colorPicker?.color
        bthHomeColor.backgroundColor = selectedColor
        
    }
    
    
    @IBAction func btnOpponentColorPressed(_ sender: Any) {
        let selectedColor = colorPicker?.color
        btnOpponentColor.backgroundColor = selectedColor
        
    }
    // Override the iPhone behavior that presents a popover as fullscreen
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        // Return no adaptive presentation style, use default presentation behaviour
        return .none
    }
    
    @IBAction func select4K(_ sender: UISwitch) {
        g_recording4K = sender.isOn;
    }
    
    @IBAction func done(_ sender: Any) {
        //(navigationController?.viewControllers[(navigationController?.viewControllers.count)! - 2] as? RecordViewController)?.changeCover(tf_title.text!)
       
        g_colorHome = bthHomeColor.backgroundColor!
        g_colorOpponent = btnOpponentColor.backgroundColor!
        
        g_homeName = txtHomeName.text!
        g_homeNameShort = txtHomeInitials.text!
        g_opponentName = txtOpponentName.text!
        g_opponentNameShort = txtOpponentInitials.text!
        
        if (switchHalves.isOn) {
            g_isPeriodHalves = true
        }
        else {
            g_isPeriodHalves = false
        }

        
        g_mainTitleText = "\(g_homeName)" + " vs " + "\(g_opponentName)"
        
        let date : Date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale(identifier: "en_US")
        
        
        g_secondTitleText = dateFormatter.string(from: date)
        
        dateFormatter.dateFormat = "yyyy-MM-dd"
        g_videoFileName = dateFormatter.string(from: date)
        g_videoFileName = g_videoFileName + "-" + g_homeNameShort + "-" + g_opponentNameShort + ".mp4"
        
        print("Output file name will be \(g_videoFileName)")
        
        g_thirdTitleText = g_locationAddressStr
         (navigationController?.viewControllers[(navigationController?.viewControllers.count)! - 2] as? RecordViewController)?.changeTeamNamesColor()
        navigationController?.popViewController(animated: true)
    }
    
    
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let currentLocation: CLLocation = locations[0]
        //print(locations)
        let latitude = currentLocation.coordinate.latitude
        let longitude = currentLocation.coordinate.longitude
        // http://maps.google.com/?q=<lat>,<lng>
        //g_googleLocationUrl = "http://maps.google.com/?q=" + "\(latitude)," + "\(longitude)";
        
        //print(g_googleLocationUrl)
        getLocationAddress(currentLocation)
    }
    
    func getLocationAddress(_ location:CLLocation) {
        let geocoder = CLGeocoder()
        
        
        
        
        geocoder.reverseGeocodeLocation(location, completionHandler: {(placemarks, error)->Void in
            
            
            if ((error == nil) && (placemarks!.count > 0)) {
                let placemark : CLPlacemark = placemarks![0]
                
                
                
                if placemark.subThoroughfare != nil {
                    g_locationAddressStr = placemark.subThoroughfare! + " "
                    //print("subThoroughfare: \(placemark.subThoroughfare!)\n")
                }
                if placemark.thoroughfare != nil {
                    g_locationAddressStr = g_locationAddressStr + placemark.thoroughfare! + ", "
                    //print("thoroughfare: \(placemark.thoroughfare!)\n")
                }
                if placemark.locality != nil {
                    g_locationAddressStr = g_locationAddressStr + placemark.locality! + ", "
                    //print("locality: \(placemark.locality!)\n")
                }
                if placemark.administrativeArea != nil {
                    g_locationAddressStr = g_locationAddressStr + placemark.administrativeArea! + " "
                    //print("administrativeArea: \(placemark.administrativeArea!)\n")
                }
                if placemark.postalCode != nil {
                    g_locationAddressStr = g_locationAddressStr + placemark.postalCode! + " "
                    //print("postalCode: \(placemark.postalCode!)\n")
                }
                
                self.txtLocation.text = g_locationAddressStr
                //print(g_locationAddressStr)
                self.locationManager.startUpdatingLocation()
            }
        })
    }
}
