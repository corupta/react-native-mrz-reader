import Foundation
import React
import SwiftUI
import QKMRZScanner

@objc(MrzReaderViewManager)
class MrzReaderViewManager: RCTViewManager {

  override func view() -> (MrzReaderView) {
    return MrzReaderView()
  }

  @objc override static func requiresMainQueueSetup() -> Bool {
    return false
  }
}

 class MrzReaderView : UIView, QKMRZScannerViewDelegate {
   private var scannerView: QKMRZScannerView!
   
   func calcCheckDigit(_ value: String) -> String {
     let uppercaseLetters = CharacterSet.uppercaseLetters
     let digits = CharacterSet.decimalDigits
     let weights = [7, 3, 1]
     var total = 0
     
     for (index, character) in value.enumerated() {
       let unicodeScalar = character.unicodeScalars.first!
       let charValue: Int
       
       if uppercaseLetters.contains(unicodeScalar) {
         charValue = Int(10 + unicodeScalar.value) - 65
       }
       else if digits.contains(unicodeScalar) {
         charValue = Int(String(character))!
       }
       else if character == "<" {
         charValue = 0
       }
       else {
         return "<"
       }
       
       total += (charValue * weights[index % 3])
     }
     total = total % 10
     return String(total)
   }

   fileprivate let dateFormatter: DateFormatter = {
     let formatter = DateFormatter()
     formatter.dateFormat = "yyyyMMdd"
     formatter.locale = Locale(identifier: "en_US_POSIX")
     formatter.timeZone = TimeZone(abbreviation: "GMT+0:00")
     return formatter
   }()

   func buildTempMrz(scanResult: QKMRZScanResult) {
     let documentNumber = scanResult.documentNumber
     let birthDate = dateFormatter.string(from: scanResult.birthdate).suffix(from: 2)
     let expiryDate = dateFormatter.string(from: scanResult.expiryDate).suffix(from: 2)
     
     var mrz: String = "P<NNN<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<" +
       documentNumber + calcCheckDigit(documentNumber) +
       "NNN" /* nationality */ +
       birthDate + calcCheckDigit(birthDate) +
       "<" /* sex */ +
       expiryDate + calcCheckDigit(expiryDate)
       + "<<<<<<<<<<<<<<<<" /* optional data */ + "<" /* check digit for optional data */
     mrz = mrz + calcCheckDigit(mrz) /* check digit for overall */
     return mrz
   }
   
   @objc var onMRZRead: RCTDirectEventBlock? = nil

   func mrzScannerView(_ mrzScannerView: QKMRZScannerView, didFind scanResult: QKMRZScanResult) {
     print(scanResult)
     guard let onMRZRead = onMRZRead else {
       return
     }

     let expiryDate = dateFormatter.string(from)

     onMRZRead(buildTempMrz(scanResult))
     
     
     /*if let bridge = self.bridge as? RCTEventDispatcher {
       bridge.sendAppEvent(withName: "onMRZScanned", body: [
           "mrzText": scanResult.mrzText ?? "",
           "documentType": scanResult.documentType,
           "countryCode": scanResult.countryCode
       ])
     }*/
   }
   
   override func didMoveToWindow() {
       super.didMoveToWindow()
     if self.window != nil {
       // Start scanning when the view is visible
       scannerView.startScanning()
     } else {
       // Stop scanning when the view is no longer visible
       scannerView.stopScanning()
     }
   }
   
   override init(frame: CGRect) {
     super.init(frame: frame)
     initializeScanner()
   }
   
   required init?(coder: NSCoder) {
     super.init(coder: coder)
     initializeScanner()
   }
   
   private func initializeScanner() {
     scannerView = QKMRZScannerView(frame: self.bounds)
     scannerView.delegate = self
     scannerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
     self.addSubview(scannerView)
   }
 }
 
