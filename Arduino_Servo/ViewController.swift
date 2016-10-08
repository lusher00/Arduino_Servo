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
    
    
    
    var timerTXDelay: Timer?
    var allowTX = true
    var lastPosition: UInt8 = 255
    var dataIn = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        #if false

            let view: UIView = UIView.init(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
            let scrollView = UIScrollView.init(frame: view.bounds)
            view.addSubview(scrollView)
            let backImage: UIImage = fromColor(UIColor.red, size: CGSize(width: 1000, height: 1000))
            let backImageView: UIImageView = UIImageView.init(image: backImage)
            scrollView.addSubview(backImageView)
            scrollView.contentSize = CGSize.init(width: backImage.size.width, height: backImage.size.height)
            
            let frontImage: UIImage = fromColor(UIColor.blue, size: CGSize(width: 100, height: 100))
            let layer: CALayer = CALayer.init()
            layer.frame = CGRect.init(x: view.center.x - 50, y: view.center.y - 50, width: 100, height: 100)
            layer.contents = frontImage.cgImage
            view.layer.addSublayer(layer)
            
            self.view.addSubview(view)
        
        #else
            
            let image = UIImage.init(named:"horizon")!
            
            self.myImageView = UIImageView.init()
            self.myImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
            self.myImageView.contentMode = UIViewContentMode.center
            self.myImageView.clipsToBounds = true
            self.myImageView.image = image
            
            self.myScrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: image.size.width, height: 200))
            self.myScrollView.contentSize = CGSize(width: image.size.width, height: image.size.height)
            self.myScrollView.center = self.view.center
            // 20 pts = 5deg or 1deg = 4pts
            self.myScrollView.contentOffset = CGPoint(x: (image.size.width - self.myScrollView.frame.width) / 2,
                                                      y: (image.size.height - self.myScrollView.frame.height) / 2)
            self.myScrollView.backgroundColor = UIColor.black
            self.myScrollView.addSubview(self.myImageView)
            self.view.addSubview(self.myScrollView)

        #endif
        
        self.connectionStatusLabel.text = "Disconnected"
        self.connectionStatusLabel.textColor = UIColor.red
        
        self.textBox.font = UIFont(name: self.textBox.font!.fontName, size: 8)
        
        // Watch Bluetooth connection
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.connectionChanged(_:)), name: NSNotification.Name(rawValue: BLEServiceChangedStatusNotification), object: nil)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.dataReceived(_:)), name: NSNotification.Name(rawValue: BLEDataChangedStatusNotification), object: nil)
        
        
        // Start the Bluetooth discovery process
        btDiscoverySharedInstance
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: BLEServiceChangedStatusNotification), object: nil)
    }
    
    
    

    
    
    func fromColor(_ color: UIColor, size: CGSize) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.stopTimerTXDelay()
    }
    
    func connectionChanged(_ notification: Notification) {
        // Connection status changed. Indicate on GUI.
        let userInfo = (notification as NSNotification).userInfo as! [String: Bool]
        
        DispatchQueue.main.async(execute: {
            // Set image based on connection status
            if let isConnected: Bool = userInfo["isConnected"] {
                if isConnected {
                    self.connectionStatusLabel.text = "Connected"
                    self.connectionStatusLabel.textColor = UIColor.green
                } else {
                    self.connectionStatusLabel.text = "Disconnected"
                    self.connectionStatusLabel.textColor = UIColor.red
                }
            }
        });
    }
    
    func dataReceived(_ notification: Notification){
        let userInfo = (notification as NSNotification).userInfo as! [String: String]
        
        DispatchQueue.main.async(execute: {
            // Set image based on connection status
            if let data: String = userInfo["data"] {
                
                self.dataIn += data
                
                if(self.dataIn.contains("\r\n")){
                    var dataArray = self.dataIn.characters.split{$0 == "\r\n"}.map(String.init)
                    
                    self.textBox.text = dataArray[0]
                    
                    print(self.handleData(dataArray[0]))
                    
                    
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
    
    func handleData(_ data: String) -> Double
    {
        let dataArray = data.characters.split{$0 == ";"}.map(String.init)
        
        if let angle = Double(dataArray[2]){
            return angle
        } else {
            return 0.0
        }
        
    }
    
    func sendPosition(_ position: UInt8) {
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
                timerTXDelay = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(ViewController.timerTXDelayElapsed), userInfo: nil, repeats: false)
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
    
    func update(_ str: String){
        textBox.text = str
    }
    
}

