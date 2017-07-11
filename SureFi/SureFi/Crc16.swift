//
//  Crc16.swift
//  SureFi
//
//  Created by John Robinson on 5/18/17.
//  Copyright © 2017 Tracy. All rights reserved.
//

import Foundation


class CRC16 {
    private var crcTable: [UInt16] = [0x0000, 0x1021, 0x2042, 0x3063, 0x4084, 0x50a5, 0x60c6, 0x70e7,
                                   0x8108, 0x9129, 0xa14a, 0xb16b, 0xc18c, 0xd1ad, 0xe1ce, 0xf1ef]

    /// Seed, You should change this seed.
    private let gPloy = 0x0000
    
    init() {
        //computeCrcTable()
    }
    
    func getCRCResult (data: [UInt8]) -> UInt16 {
        let crc = getCrc(data: data)
        return crc
    }
    
    private func getCrcOfByte(aByte: Int) -> Int {
        var value = aByte << 8
        for _ in 0 ..< 8 {
            if (value & 0x8000) != 0 {
                value = (value << 1) ^ gPloy
            }else {
                value = value << 1
            }
        }
        value = value & 0xFFFF //get low 16 bit value
        
        return value
    }
    
    private func getCrc(data: [UInt8]) -> UInt16 {
        var crc: UInt16 = 0
        var k:UInt16 = 0
        let dataInt: [Int] = data.map{Int( $0) }
        
        let length = data.count
        
        for i in 0 ..< length {
            
            k = (crc >> 12) ^ UInt16(dataInt[i]/16)
            crc = crcTable[Int(k & 0x0F)] ^ (crc << 4)
            k = (crc >> 12) ^ UInt16(dataInt[i])
            crc = crcTable[Int(k & 0x0F)] ^ (crc << 4)
        }
        return UInt16(crc)
    }
    
}
