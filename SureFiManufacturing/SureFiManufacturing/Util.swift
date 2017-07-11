 //
 //  Util.swift
 //  SureFi Config
 //
 //  Created by John Robinson on 10/21/16.
 //  Copyright © 2016 Sure-Fi. All rights reserved.
 //
 
 import Foundation
 import UIKit
 
 class Util: NSObject {
    
    func callNumber(phoneNumber:String) -> Bool {
        
        var callNumber = phoneNumber
        let values = ["(":"",")":"","-":""," ":"","ext":";"]
        for (key, value) in values {
            callNumber = callNumber.replacingOccurrences(of: key, with: value)
        }
        
        if let phoneCallURL:URL = URL(string: "tel://\(callNumber)") {
            let application:UIApplication = UIApplication.shared
            if (application.canOpenURL(phoneCallURL)) {
                application.open(phoneCallURL, options: [:], completionHandler: nil)
                return true
            }
        }
        return false
    }
    
    func convertCSVContent(content: String) -> [[String:String]] {
        
        var  data:[[String:String]] = []
        var  columnTitles:[String] = []
        
        let rows = cleanCSVRows(content: content).components(separatedBy: "\n")
        if rows.count > 0 {
            data = []
            columnTitles = getCSVStringFieldsForRow(row: rows.first!,delimiter:",")
            for row in rows{
                let fields = getCSVStringFieldsForRow(row: row,delimiter: ",")
                if fields.count != columnTitles.count {continue}
                var dataRow = [String:String]()
                for (index,field) in fields.enumerated(){
                    let fieldName = columnTitles[index]
                    dataRow[fieldName] = field
                }
                data += [dataRow]
            }
        } else {
            print("No data in file")
        }
        return data
        
    }
    
    func cleanCSVRows(content:String)->String{
        var cleanFile = content
        cleanFile = cleanFile.replacingOccurrences(of: "\r", with: "\n")
        cleanFile = cleanFile.replacingOccurrences(of:"\n\n", with: "\n")
        return cleanFile
    }
    
    func getCSVStringFieldsForRow(row:String, delimiter:String)-> [String]{
        return row.components(separatedBy: delimiter)
    }
    
    func getDaysDispFromDaysString(daysString: String) -> String {
        
        if daysString == "0000000" {
            return "Never"
        }
        if daysString == "1111111" {
            return "Everyday"
        }
        if daysString == "0000011" {
            return "on Weekends"
        }
        if daysString == "1111100" {
            return "on Weekdays"
        }
        
        var daysArray = [String]()
        if daysString[0] == "1" {
            daysArray.append("Mon")
        }
        if daysString[1] == "1" {
            daysArray.append("Tues")
        }
        if daysString[2] == "1" {
            daysArray.append("Wed")
        }
        if daysString[3] == "1" {
            daysArray.append("Thur")
        }
        if daysString[4] == "1" {
            daysArray.append("Fri")
        }
        if daysString[5] == "1" {
            daysArray.append("Sat")
        }
        if daysString[6] == "1" {
            daysArray.append("Sun")
        }
        
        let returnString = "on \(daysArray.joined(separator: ", "))";
        return returnString
    }
    
    func translateAccessRestrictions(startTime: Int, endTime: Int, startDate: String, endDate: String, daysOfWeek: String) -> String {
        
        var result = "Available "
        if startTime < 0 && endTime < 0 {
            result = "\(result)all day "
        } else {
            if startTime >= 0 {
                result = "\(result)from \(getTimeStrFromInt(time: startTime)) "
            }
            if endTime >= 0 {
                result = "\(result)until \(getTimeStrFromInt(time: endTime)) "
            }
        }
        result = "\(result)\(getDaysDispFromDaysString(daysString: daysOfWeek))"
        
        if startDate != "" || endDate != "" {
            if startDate != "" {
                result = "\(result) from \(getDateStringFromJSDate(srcString: startDate))"
            }
            if endDate != "" {
                result = "\(result) thru \(getDateStringFromJSDate(srcString: endDate))"
            }
        }
        
        return result
    }
    
    func getDateStringFromJSDate(srcString: String) -> String {
        
        var dateStr = srcString
        if dateStr.length > 10 {
            dateStr = srcString.substring(to: 10)
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.date(from: dateStr)
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        return dateFormatter.string(from: date!)
    }
    
    func getTimeStrFromInt(time: Int) -> String {
        
        var srcTime = time
        while srcTime > 1440 {
            srcTime -= 1440
        }
        
        if time == -1 {
            return "Any Time"
        }
        
        if srcTime == 0 || srcTime == 1440 {
            return "Midnight"
        }
        if srcTime == 720 {
            return "Noon"
        }
        var ampm = "AM"
        var hours = srcTime/60
        if hours >= 12 {
            if hours > 12 {
                hours -= 12
            }
            ampm = "PM"
        }
        let minutes = srcTime%60
        
        var returnString = "\(hours)"
        if minutes != 0 {
            returnString = "\(returnString):\(String(format: "%02d", minutes))"
        }
        returnString = "\(returnString) \(ampm)"
        return returnString
    }
    
    func randomString(length: Int, letters: String="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789") -> String {
        
        let len = UInt32(letters.length)
        
        var randomString: String = ""
        
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            let nextChar = letters[Int(rand)]
            randomString.append(nextChar)
        }
        return randomString
    }
    
    func drawTextFieldBox(textField: UITextField) {
        
        let border = CALayer()
        let width = CGFloat(1.0)
        border.borderColor = UIColor.darkGray.cgColor
        border.frame = CGRect(x: 0, y: textField.frame.size.height - width, width:  textField.frame.size.width, height: textField.frame.size.height)
        
        border.borderWidth = width
        textField.layer.addSublayer(border)
        textField.layer.masksToBounds = true
        
    }
    
    func setGradientBackground(view: UIView) {
        
        let gradient: CAGradientLayer = CAGradientLayer()
        
        let darkBlueColor = UIColor(red: 18/256, green: 83/256, blue: 138/256, alpha: 1)
        let lightBlueColor = UIColor(red: 156/256, green: 195/256, blue: 228/256, alpha: 1)
        
        gradient.colors = [darkBlueColor.cgColor, lightBlueColor.cgColor]
        gradient.locations = [0.0 , 1.0]
        gradient.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradient.endPoint = CGPoint(x: 0.0, y: 1.0)
        gradient.frame = CGRect(x: 0.0, y: 0.0, width: view.frame.size.width, height: view.frame.size.height)
        
        view.layer.insertSublayer(gradient, at: 0)
        
    }
    
    func validatePassword(password: String) -> (Bool,Int) {
        
        let len: Int = password.characters.count
        var strength: Int = 0
        
        switch len {
        case 0...5:
            return (false,0)
        case 6...8:
            strength += 1
        default:
            strength += 2
        }
        
        // Upper case, Lower case, Number & Symbols
        let patterns = ["^(?=.*[A-Z]).*$", "^(?=.*[a-z]).*$", "^(?=.*[0-9]).*$", "^(?=.*[!@#%&-_=:;\"'<>,`~\\*\\?\\+\\[\\]\\(\\)\\{\\}\\^\\$\\|\\\\\\.\\/]).*$"]
        
        for pattern in patterns {
            
            if password.range(of: pattern, options: .regularExpression) != nil {
                strength += 1
            }
        }
        return (true,strength)
    }
 }
 
 extension Int {
    var toBinaryString: String { return String(self, radix: 2) }
    var toHexaString:   String { return String(self, radix: 16) }
 }
 
 extension String {
    
    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }
    
    var length: Int {
        return self.characters.count
    }
    
    func substring(from: Int) -> String {
        return self[Range(min(from, length) ..< length)]
    }
    
    func substring(to: Int) -> String {
        return self[Range(0 ..< max(0, to))]
    }
    
    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return self[Range(start ..< end)]
    }
    
    subscript (i: Int) -> Character {
        return self[index(startIndex, offsetBy: i)]
    }
    
    func capitalizingFirstLetter() -> String {
        let first = String(characters.prefix(1)).capitalized
        let other = String(characters.dropFirst())
        return first + other
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
    
    func capitalizingFirstLetters() -> String {
        
        var outWords: [String] = []
        let words = String(characters).components(separatedBy: " ")
        for word in words {
            var temp = word
            temp.capitalizeFirstLetter()
            outWords.append(temp)
        }
        return outWords.joined(separator: " ")
    }
    
    mutating func capitalizeFirstLetters() {
        self = self.capitalizingFirstLetters()
    }
    
    func deleteLastComponent() -> String {
        
        let str = self
        if !str.isEmpty {
            let components = str.characters.split(separator: "/")
            let head = components.dropLast(1).map(String.init).joined(separator: "/")
            return head
        } else {
            return ""
        }
    }
    func getLastComponent() -> String {
        
        let str = self
        if !str.isEmpty {
            let components = str.characters.split(separator: "/")
            let words = components.count-1
            let tail = components.dropFirst(words).map(String.init)[0]
            return tail
        } else {
            return ""
        }
    }
    
    func replace( _ index: Int, _ newChar: Character) -> String {
        var chars = Array(self.characters)     // gets an array of characters
        chars[index] = newChar
        let modifiedString = String(chars)
        return modifiedString
    }
    
    func dataFromHexString() -> NSData? {
        guard let chars = cString(using: String.Encoding.utf8) else { return nil}
        var i = 0
        let length = characters.count
        
        let data = NSMutableData(capacity: length/2)
        var byteChars: [CChar] = [0, 0, 0]
        
        var wholeByte: CUnsignedLong = 0
        
        while i < length {
            byteChars[0] = chars[i]
            i+=1
            byteChars[1] = chars[i]
            i+=1
            wholeByte = strtoul(byteChars, nil, 16)
            data?.append(&wholeByte, length: 1)
        }
        
        return data
    }
    
    func isValidEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: self)
    }
    
    func getPasswordStrength() -> Int? {
        return 0
    }
    
    func getMD5() -> Data {
        let messageData = self.data(using:.utf8)!
        var digestData = Data(count: Int(CC_MD5_DIGEST_LENGTH))
        
        _ = digestData.withUnsafeMutableBytes {digestBytes in
            messageData.withUnsafeBytes {messageBytes in
                CC_MD5(messageBytes, CC_LONG(messageData.count), digestBytes)
            }
        }
        
        return digestData
    }
    
    func leftPadding(toLength: Int, withPad character: Character) -> String {
        let newLength = self.characters.count
        if newLength < toLength {
            return String(repeatElement(character, count: toLength - newLength)) + self
        } else {
            return self.substring(from: index(self.startIndex, offsetBy: newLength - toLength))
        }
    }
    
    func slice(from: String, to: String) -> String? {
        
        return (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                substring(with: substringFrom..<substringTo)
            }
        }
    }
    
    var digits: String {
        return components(separatedBy: CharacterSet.decimalDigits.inverted)
            .joined()
    }
    
    var drop0xPrefix:          String { return hasPrefix("0x") ? String(characters.dropFirst(2)) : self }
    var drop0bPrefix:          String { return hasPrefix("0b") ? String(characters.dropFirst(2)) : self }
    var hexaToDecimal:            Int { return Int(drop0xPrefix, radix: 16) ?? 0 }
    var hexaToBinaryString:    String { return String(hexaToDecimal, radix: 2) }
    var decimalToHexaString:   String { return String(Int(self) ?? 0, radix: 16) }
    var decimalToBinaryString: String { return String(Int(self) ?? 0, radix: 2) }
    var binaryToDecimal:          Int { return Int(drop0bPrefix, radix: 2) ?? 0 }
    var binaryToHexaString:    String { return String(binaryToDecimal, radix: 16) }
 }
 
 extension UINavigationController {
    func pop(animated: Bool) {
        _ = self.popViewController(animated: animated)
    }
    
    func popToRoot(animated: Bool) {
        _ = self.popToRootViewController(animated: animated)
    }
 }
 
 extension Data {
    func hexStringFromData() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
    
    func crc16() -> UInt16 {
        
        let byteArray = [UInt8](self)
        let crcController = CRC16()
        let crc = crcController.getCRCResult(data: byteArray)
        return crc;
    }
 }
 
 extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    var endOfDay: Date? {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)
    }
    
    var unixTimestamp: String? {
        let timestamp = timeIntervalSince1970
        return String(Int(timestamp))
    }
 }
 
 extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        let newRed = CGFloat(red)/255
        let newGreen = CGFloat(green)/255
        let newBlue = CGFloat(blue)/255
        
        self.init(red: newRed, green: newGreen, blue: newBlue, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
    
    static let darkGreen = UIColor(red: 0x00, green: 0x99, blue: 0x00)
    static let paleBlue = UIColor(red: 0xAD, green: 0xD8, blue: 0xE6)
 }
 
 extension UIView {
    func rotateDegrees(duration: CFTimeInterval = 1.0, degrees: Double = 360.0, completionDelegate: AnyObject? = nil) {
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fromValue = 0.0
        rotateAnimation.toValue = CGFloat(Double.pi * 2.0 * degrees / 360.0)
        rotateAnimation.duration = duration
        
        if let delegate: AnyObject = completionDelegate {
            rotateAnimation.delegate = delegate as? CAAnimationDelegate
        }
        self.layer.add(rotateAnimation, forKey: nil)
    }
 }
 
 class PaddingLabel: UILabel {
    
    @IBInspectable var topInset: CGFloat = 5.0
    @IBInspectable var bottomInset: CGFloat = 5.0
    @IBInspectable var leftInset: CGFloat = 5.0
    @IBInspectable var rightInset: CGFloat = 5.0
    
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
    }
    
    override var intrinsicContentSize: CGSize {
        get {
            var contentSize = super.intrinsicContentSize
            contentSize.height += topInset + bottomInset
            contentSize.width += leftInset + rightInset
            return contentSize
        }
    }
 }
