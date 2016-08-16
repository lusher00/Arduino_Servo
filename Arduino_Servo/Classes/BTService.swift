//
//  BTService.swift
//  Arduino_Servo
//
//  Created by Owen L Brown on 10/11/14.
//  Copyright (c) 2014 Razeware LLC. All rights reserved.
//

import Foundation
import CoreBluetooth

/* Services & Characteristics UUIDs */
//let BLEServiceUUID = CBUUID(string: "7FDF3A46-97BA-6AE2-5C01-79E63A554915")
let BLEServiceUUID = CBUUID(string: "FFE0")

let PositionCharUUID = CBUUID(string: "FFE1")
let BLEServiceChangedStatusNotification = "kBLEServiceChangedStatusNotification"
let BLEDataChangedStatusNotification = "kBLEDataChangedStatusNotification"

class BTService: NSObject, CBPeripheralDelegate {
    var peripheral: CBPeripheral?
    var positionCharacteristic: CBCharacteristic?
    
    init(initWithPeripheral peripheral: CBPeripheral) {
        super.init()
        
        self.peripheral = peripheral
        self.peripheral?.delegate = self
    }
    
    deinit {
        self.reset()
    }
    
    func startDiscoveringServices() {
        self.peripheral?.discoverServices([BLEServiceUUID])
    }
    
    func reset() {
        if peripheral != nil {
            peripheral = nil
        }
        
        // Deallocating therefore send notification
        self.sendBTServiceNotificationWithIsBluetoothConnected(false)
    }
    
    // Mark: - CBPeripheralDelegate
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        let uuidsForBTService: [CBUUID] = [PositionCharUUID]
        
        if (peripheral != self.peripheral) {
            // Wrong Peripheral
            return
        }
        
        if (error != nil) {
            return
        }
        
        if ((peripheral.services == nil) || (peripheral.services!.count == 0)) {
            // No Services
            return
        }
        
        for service in peripheral.services! {
            if service.UUID == BLEServiceUUID {
                peripheral.discoverCharacteristics(uuidsForBTService, forService: service)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        if (peripheral != self.peripheral) {
            // Wrong Peripheral
            return
        }
        
        if (error != nil) {
            return
        }
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.UUID == PositionCharUUID {
                    self.positionCharacteristic = (characteristic)
                    peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                    
                    // Send notification that Bluetooth is connected and all required characteristics are discovered
                    self.sendBTServiceNotificationWithIsBluetoothConnected(true)
                }
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?)
    {
        if characteristic.UUID == PositionCharUUID
        {
            //var data = characteristic.value
            //var values = [UInt8](count:data.length, repeatedValue:0)
            //data.getBytes(&values, length:data.length)
            
            //print(String(characteristic.value))
            //print("received data")
            //print(characteristic.value?.description)
            let str = NSString(data: characteristic.value!, encoding: NSUTF8StringEncoding) as? String
            
            //viewControllerSharedInstance.update("Hello World")
            
            sendBTServiceNotificationWithData(str!)
            
            print(str)
        }
    }
    
    // Mark: - Private
    
    func writePosition(position: UInt8) {
        // See if characteristic has been discovered before writing to it
        if let positionCharacteristic = self.positionCharacteristic {
            // Need a mutable var to pass to writeValue function
            var positionValue = position
            let data = NSData(bytes: &positionValue, length: sizeof(UInt8))
            self.peripheral?.writeValue(data, forCharacteristic: positionCharacteristic, type: CBCharacteristicWriteType.WithResponse)
        }
    }
    
    func sendBTServiceNotificationWithIsBluetoothConnected(isBluetoothConnected: Bool) {
        let connectionDetails = ["isConnected": isBluetoothConnected]
        NSNotificationCenter.defaultCenter().postNotificationName(BLEServiceChangedStatusNotification, object: self, userInfo: connectionDetails)
    }
    
    func sendBTServiceNotificationWithData(data: String) {
        let connectionDetails = ["data": data]
        NSNotificationCenter.defaultCenter().postNotificationName(BLEDataChangedStatusNotification, object: self, userInfo: connectionDetails)
    }
    
    
}