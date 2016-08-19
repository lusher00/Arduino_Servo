//: Playground - noun: a place where people can play

import UIKit


var dataProcessed = String()
var dataIn = String()

dataIn += "90.00; 1.232; 3.456; 1."
var dataArray = dataIn.characters.split{$0 == "\r\n"}.map(String.init)

if(dataArray.count > 1)
{
    dataProcessed = dataArray[0]
    dataIn = dataArray[1]
}

dataIn += "011\r\n 1.234; 3.456; 5.678"
dataArray = dataIn.characters.split{$0 == "\r\n"}.map(String.init)

if(dataArray.count > 1)
{
    dataProcessed = dataArray[0]
    dataIn = dataArray[1]
}

dataIn += "; 1.311\r\n 1.234; 3.456; 5.678"
dataArray = dataIn.characters.split{$0 == "\r\n"}.map(String.init)

if(dataArray.count > 1)
{
    dataProcessed = dataArray[0]
    dataIn = dataArray[1]
}










