//
//  ViewController.swift
//  BusOrWalk
//
//  Created by Etome on 2017-10-19.
//  Copyright © 2017 Etome. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    //var pickerDataSource = ["321", "345", "394", "375", "351"]
    var pickerBusDataSource = [String]()
    var lat = 0.0;
    var longi = 0.0;
    var pick = 0;
    
    @IBOutlet weak var BusStopNumber: UITextField!
    @IBOutlet weak var NextBusEtaDisplay: UILabel!
    @IBOutlet weak var BusNumber: UITextField!
    @IBOutlet weak var BusNumberPick: UIPickerView!
    @IBOutlet weak var DestStop: UITextField!
    
    /* Translink API Key*/
    let apikey = "da7U5YMtuSBla2QK3msq";
    let httpsStopRequests = "https://api.translink.ca/rttiapi/v1/stops/";
    let httpsStopAreaRequests = "https://api.translink.ca/rttiapi/v1/stops"
    let httpsStopEstimate = "/estimates"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.BusNumberPick.dataSource = self;
        self.BusNumberPick.delegate = self;
        disableBothStopField()
        self.hideKeyboardOnTap(#selector(self.dismissKeyboard))
        checkNetwork()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func BusStopEdit(_ sender: Any) {
        disableBothStopField()
    }
    
    /* When Starting Bus Stop Text Field has been edited */
    @IBAction func BusStopChange(_ sender: UITextField) {
        //NextBusEtaDisplay.text = "531";
        
        if(checkNetwork()) {
            
            let parameters: Parameters = [
                "apikey" : apikey
            ]
            
            let headers: HTTPHeaders = [
                "Accept": "application/json"
            ]
            
            
            if(!BusStopNumber.text!.isEmpty) {
                Alamofire.request(httpsStopRequests
                    + BusStopNumber.text!, parameters: parameters, headers: headers).validate().responseJSON { response in
                    switch response.result {
                    case .success(let value):
                            let json = JSON(value)
                            //print("Stop Number Data: \(json)")
                            self.lat = json["Latitude"].doubleValue
                            self.longi = json["Longitude"].doubleValue
                            self.pickerBusDataSource = json["Routes"].stringValue.components(separatedBy: ", ")
                            self.enableBusStopField()
                    case .failure(let error):
                        print("busstopchange \(error)")
                        self.pickerBusDataSource = [String]();
                    }
                }
            } else {
                self.pickerBusDataSource = [""]
            }
        }
        
    }
    
    /* when BusNumber field is selected */
    @IBAction func BusNumberPicker(_ sender: Any) {
        //self.pickerDataSource = ["321", "345", "394", "375", "351"]
        BusNumberPick.reloadAllComponents()
        BusNumberPick.isHidden = false;
        pick = 0
    }
    @IBAction func DestStopPicker(_ sender: Any) {
        BusNumberPick.reloadAllComponents()
        BusNumberPick.isHidden = false;
        pick = 1
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerBusDataSource.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerBusDataSource[row]
    }
    
    /* when bus number picked in picker or when Destination number picked in picker */
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int,
                    inComponent component: Int) {
        if(checkNetwork()) {
            let selectedvalue = Int(pickerBusDataSource[row])
            if (pick == 0) {
                BusNumber.text = pickerBusDataSource[row]
                BusNumberPick.isHidden = true;
                
                let parameters: Parameters = [
                    "apikey" : apikey,
                    "timeframe": 1440,
                    "count": 1,
                    "routeNo" : pickerBusDataSource[row]
                ]
                
                let headers: HTTPHeaders = [
                    "Accept": "application/json"
                ]
                
                Alamofire.request(httpsStopRequests
                    + BusStopNumber.text! + httpsStopEstimate, parameters: parameters, headers: headers).validate().responseJSON { response in
                        switch response.result {
                        case .success(let value):
                            let json = JSON(value)
                            self.NextBusEtaDisplay.text = json[0]["Schedules"][0]["ExpectedLeaveTime"].stringValue
                            
                            let parameters: Parameters = [
                                "apikey" : self.apikey,
                                "lat": self.lat,
                                "long": self.longi,
                                "routeNo" : self.pickerBusDataSource[row],
                                "radius": 2000
                            ]
                            
                            let headers: HTTPHeaders = [
                                "Accept": "application/json"
                            ]
                            
                            Alamofire.request(self.httpsStopAreaRequests, parameters: parameters, headers: headers).validate().responseJSON { response in
                                    switch response.result {
                                    case .success(let value):
                                        let json = JSON(value)
                                        var destarr = [String]()
                                        for (index, object) in json {
                                            destarr.append(object["StopNo"].stringValue)
                                        }
                                        //print("Stop Area: \(json)")
                                        self.pickerBusDataSource = destarr
                                        self.enableDestStopField()
                                    case .failure(let error):
                                        print(error)
                                    }
                            }
                            
                        case .failure(let error):
                            print(error)
                        }
                }
            } else {
                BusNumberPick.isHidden = true;
                let parameters: Parameters = [
                    "apikey" : apikey
                ]
                
                let headers: HTTPHeaders = [
                    "Accept": "application/json"
                ]
                
                Alamofire.request(httpsStopRequests
                    + "\(selectedvalue!)", parameters: parameters, headers: headers).validate().responseJSON { response in
                        switch response.result {
                        case .success(let value):
                            let json = JSON(value)
                            print("Stop Number Data: \(json)")
                            self.lat = json["Latitude"].doubleValue
                            self.longi = json["Longitude"].doubleValue
                            self.DestStop.text! = json["StopNo"].stringValue
                        case .failure(let error):
                            print(error)
                            self.pickerBusDataSource = [String]();
                        }
                }
            }
        }
    }
    
    func disableBusStopField() {
        BusNumber.text! = ""
        BusNumber.isUserInteractionEnabled = false;
        BusNumber.backgroundColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
    }
    func disableDestStopField() {
        DestStop.text! = ""
        DestStop.isUserInteractionEnabled = false;
        DestStop.backgroundColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
    }
    
    func disableBothStopField() {
        disableBusStopField()
        disableDestStopField()
    }
    
    func enableBusStopField() {
        BusNumber.isUserInteractionEnabled = true;
        BusNumber.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    }
    
    func enableDestStopField() {
        DestStop.isUserInteractionEnabled = true;
        DestStop.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    }
    
    func checkNetwork() -> Bool {
        if Reachability.isConnectedToNetwork(){
            print("Internet Connection Available!")
            return true
        }else{
            print("Internet Connection not Available!")
            NextBusEtaDisplay.text! = ""
            disableBothStopField()
            let alertController = UIAlertController(title: "No Network", message: "No internet connection found. Please try again later.", preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alertController.addAction(defaultAction)
            present(alertController, animated: true, completion: nil)
            return false
        }
    }
}

extension UIViewController {
    func hideKeyboardOnTap(_ selector: Selector) {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: selector)
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
}

