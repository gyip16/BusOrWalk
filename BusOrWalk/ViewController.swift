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
    var pickerDataSource = [String]()
    
    @IBOutlet weak var BusStopNumber: UITextField!
    @IBOutlet weak var NextBusEtaDisplay: UILabel!
    @IBOutlet weak var BusNumber: UITextField!
    @IBOutlet weak var BusNumberPick: UIPickerView!
    
    /* Translink API Key*/
    let apikey = "da7U5YMtuSBla2QK3msq";
    let httpsStopRequests = "https://api.translink.ca/rttiapi/v1/stops/";
    let httpsStopEstimate = "/estimates"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.BusNumberPick.dataSource = self;
        self.BusNumberPick.delegate = self;
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    
    /* When Starting Bus Stop Text Field has been edited */
    @IBAction func BusStopChange(_ sender: UITextField) {
        //NextBusEtaDisplay.text = "531";
        
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
                        self.pickerDataSource = json["Routes"].stringValue.components(separatedBy: ", ")
                    
                    
                case .failure(let error):
                    print(error)
                    self.pickerDataSource = [String]();
                }
            }
        } else {
            self.pickerDataSource = [""]
        }
        
        
    }
    @IBAction func BusNumberPicker(_ sender: Any) {
        //self.pickerDataSource = ["321", "345", "394", "375", "351"]
        BusNumberPick.reloadAllComponents()
        BusNumberPick.isHidden = false;
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerDataSource.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerDataSource[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int,
                    inComponent component: Int) {
        BusNumber.text = pickerDataSource[row]
        BusNumberPick.isHidden = true;
        
        let parameters: Parameters = [
            "apikey" : apikey,
            "timeframe": 120,
            "count": 1,
            "routeNo" : pickerDataSource[row]
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
                    
                case .failure(let error):
                    print(error)
                }
        }
        
    }
}


