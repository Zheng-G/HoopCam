//
//  EventsViewController.swift
//  HoopsCam
//
//  Created by Dinesh Nambisan on 3/2/18.
//  Copyright © 2018 lieyunye. All rights reserved.
//

import UIKit

class EventsViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView.tag == 1 {
            return pickerDataLeft.count
        } else {
            return pickerDataRight.count
        }
    }
    

    @IBOutlet weak var ballEvent: UISegmentedControl!
    
    @IBOutlet weak var pickerJerseyLeft: UIPickerView!
    @IBOutlet weak var pickerJerseyRight: UIPickerView!
    
    var pickerDataLeft: [String] = [String]()
    var pickerDataRight: [String] = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        pickerDataLeft = ["", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
        pickerDataRight = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
        
        self.pickerJerseyLeft.delegate = self
        self.pickerJerseyLeft.dataSource = self
        self.pickerJerseyRight.delegate = self
        self.pickerJerseyRight.dataSource = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView.tag == 1 {
            return pickerDataLeft[row]
        } else {
            return pickerDataRight[row]
        }
        
    }

    @IBAction func btnDonePressed(_ sender: Any) {
        let jerseyNumber = "\(pickerDataLeft[pickerJerseyLeft.selectedRow(inComponent: 0)])\(pickerDataRight[pickerJerseyRight.selectedRow(inComponent: 0)])"
        print(jerseyNumber)
    }
    
    @IBAction func back(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}
