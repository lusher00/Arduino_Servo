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
    var Photo: UIImageView!
    @IBOutlet var scroll: UIScrollView!

    
    var timerTXDelay: NSTimer?
    var allowTX = true
    var lastPosition: UInt8 = 255
    var dataIn = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        /////////
        //var imageRect: CGRect
        //self.Photo = NSImageView.init()
        //self.Photo = UIImageView(frame: CGRectMake(0.0, 0.0, 350.0, 720.0))
        //self.Photo.image = UIImage.init(named:"horizon")
        
        //imageRect = CGRectMake(0.0, 0.0, self.Photo.image!.size.width, self.Photo.image!.size.height)
        //print(imageRect)
        //self.Photo = NSImageView(frame: imageRect)
        //self.Photo..setBoundsSize(CGSize(width: imageRect.width, height: imageRect.height))
        //self.Photo.imageScaling = NSImageScaling.ScaleNone
        //self.Photo.imageAlignment = NSImageAlignment.AlignCenter
        
        
        
        
        //self.scroll.frame = imageRect//(CGRectMake(x: 0, y: 0, w: imageRect.width, h: imageRect.width))
        //self.scroll.hasVerticalScroller = true
        //self.scroll.hasHorizontalScroller = false
        //self.Photo.setFrameSize(CGSize(width: imageRect.width,height: imageRect.width))
        //self.scroll.documentView = self.Photo
        
        //scrollView!.documentView = toolsView
        //let scrollLocation = NSPoint(x: 0, y: 185)
        //scroll.contentView.scrollToPoint(scrollLocation)
        //scroll.reflectScrolledClipView(leftScrollView!.contentView)

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

