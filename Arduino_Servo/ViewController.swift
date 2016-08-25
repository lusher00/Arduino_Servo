//
//  ViewController.swift
//  Arduino_Servo
//
//  Created by Owen L Brown on 9/24/14.
//  Copyright (c) 2014 Razeware LLC. All rights reserved.
//

import UIKit
import Foundation

let viewControllerSharedInstance = ViewController()

class ViewController: UIViewController {
    
    @IBOutlet weak var textBox: UITextField!
    @IBOutlet weak var connectionStatusLabel : UILabel!
    var myImageView: UIImageView!
    @IBOutlet var myScrollView: UIScrollView!
    
    
    
    var timerTXDelay: NSTimer?
    var allowTX = true
    var lastPosition: UInt8 = 255
    var dataIn = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //let imageRect = CGRectMake(self.view.frame.width / 2 - 100, self.view.frame.height / 2, 200, 200)

        let image = UIImage.init(named:"horizon")!
        
        self.myImageView = UIImageView.init()
        self.myImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        self.myImageView.contentMode = UIViewContentMode.Center
        self.myImageView.clipsToBounds = true
        self.myImageView.image = image
        
        
        //self.myScrollView = UIScrollView(frame: CGRectMake(self.view.frame.width / 2 - 100, self.view.frame.height / 2, 200, 200))
        self.myScrollView = UIScrollView(frame: CGRectMake(0, 0, image.size.width, 200))
        self.myScrollView.contentSize = CGSize(width: image.size.width, height: image.size.height)
        
        
        
        self.myScrollView.center = self.view.center
        
        self.myScrollView.contentOffset = CGPoint(x: (image.size.width / 2) - (self.myScrollView.frame.width / 2),
                                                  y: (image.size.height / 2) - (self.myScrollView.frame.height / 2))
        self.myScrollView.backgroundColor = UIColor.blackColor()
        //self.myScrollView.contentOffset = CGPoint(x: 0, y: 0)
        self.myScrollView.addSubview(self.myImageView)
        self.view.addSubview(self.myScrollView)
        
        /////////
        
        
        self.connectionStatusLabel.text = "Disconnected"
        self.connectionStatusLabel.textColor = UIColor.redColor()
        
        self.textBox.font = UIFont(name: self.textBox.font!.fontName, size: 8)
        
        // Watch Bluetooth connection
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.connectionChanged(_:)), name: BLEServiceChangedStatusNotification, object: nil)
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.dataReceived(_:)), name: BLEDataChangedStatusNotification, object: nil)
        
        
        // Start the Bluetooth discovery process
        btDiscoverySharedInstance
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: BLEServiceChangedStatusNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.stopTimerTXDelay()
    }
    
    func connectionChanged(notification: NSNotification) {
        // Connection status changed. Indicate on GUI.
        let userInfo = notification.userInfo as! [String: Bool]
        
        dispatch_async(dispatch_get_main_queue(), {
            // Set image based on connection status
            if let isConnected: Bool = userInfo["isConnected"] {
                if isConnected {
                    self.connectionStatusLabel.text = "Connected"
                    self.connectionStatusLabel.textColor = UIColor.greenColor()
                } else {
                    self.connectionStatusLabel.text = "Disconnected"
                    self.connectionStatusLabel.textColor = UIColor.redColor()
                }
            }
        });
    }
    
    func dataReceived(notification: NSNotification){
        let userInfo = notification.userInfo as! [String: String]
        
        dispatch_async(dispatch_get_main_queue(), {
            // Set image based on connection status
            if let data: String = userInfo["data"] {
                
                self.dataIn += data
                
                if(self.dataIn.containsString("\r\n")){
                    var dataArray = self.dataIn.characters.split{$0 == "\r\n"}.map(String.init)
                    
                    self.textBox.text = dataArray[0]
                    
                    //print(self.handleData(dataArray[0]))
                    
                    
                    if(dataArray.count > 1)
                    {
                        self.dataIn = dataArray[1]
                    }
                    else
                    {
                        self.dataIn = ""
                    }
                }
                
            }
        });
    }
    
    func handleData(data: String) -> Double
    {
        let dataArray = data.characters.split{$0 == ";"}.map(String.init)
        
        let angle = Double(dataArray[2])
        
        return angle!
    }
    
    func sendPosition(position: UInt8) {
        // Valid position range: 0 to 180
        
        if !self.allowTX {
            return
        }
        
        // Validate value
        if position == lastPosition {
            return
        }
        else if ((position < 0) || (position > 180)) {
            return
        }
        
        // Send position to BLE Shield (if service exists and is connected)
        if let bleService = btDiscoverySharedInstance.bleService {
            bleService.writePosition(position)
            lastPosition = position;
            
            // Start delay timer
            self.allowTX = false
            if timerTXDelay == nil {
                timerTXDelay = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(ViewController.timerTXDelayElapsed), userInfo: nil, repeats: false)
            }
        }
    }
    
    func timerTXDelayElapsed() {
        self.allowTX = true
        self.stopTimerTXDelay()
        
        // Send current slider position
        //self.sendPosition(UInt8(self.positionSlider.value))
    }
    
    func stopTimerTXDelay() {
        if self.timerTXDelay == nil {
            return
        }
        
        timerTXDelay?.invalidate()
        self.timerTXDelay = nil
    }
    
    func update(str: String){
        textBox.text = str
    }
    
}

