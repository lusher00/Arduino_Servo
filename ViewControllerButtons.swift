//
//  ViewControllerButtons.swift
//  Arduino_Servo
//
//  Created by Ryan Lush on 10/10/16.
//  Copyright © 2016 Razeware LLC. All rights reserved.
//

import UIKit

class ViewControllerButtons: UIViewController {
    @IBOutlet weak var send: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func sendPosition(_ position: UInt8) {

        // Send position to BLE Shield (if service exists and is connected)
        if let bleService = btDiscoverySharedInstance.bleService
        {
            bleService.writePosition(position)
        }
    }
    
    @IBAction func send(_ sender: AnyObject) {
        sendPosition(0)
    }
    
    // MARK: - Navigation

    /*
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
