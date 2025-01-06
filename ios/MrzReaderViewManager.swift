import Foundation
import React
import SwiftUI
import QKMRZScanner

@objc(MrzReaderViewManager)
class MrzReaderViewManager: RCTViewManager, QKMRZScannerViewDelegate {
  @IBOutlet weak var mrzScannerView: QKMRZScannerView!
  @objc var onMRZRead: RCTDirectEventBlock? = nil

  override func viewDidLoad() {
    super.viewDidLoad()
    mrzScannerView.delegate = self
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    mrzScannerView.startScanning()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    mrzScannerView.stopScanning()
  }
  
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
    let birthDate = dateFormatter.string(from: scanResult.birthDate).suffix(from: 2)
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

  func mrzScannerView(_ mrzScannerView: QKMRZScannerView, didFind scanResult: QKMRZScanResult) {
    print(scanResult)
    guard let onMRZRead = onMRZRead else {
      return
    }

    let expiryDate = dateFormatter.string(from)

    onMRZRead(buildTempMrz(scanResult))
  }

  override func view() -> (MrzReaderView) {
    return MrzReaderView()
  }

  @objc override static func requiresMainQueueSetup() -> Bool {
    return false
  }

  @objc override func supportedEvents() -> [String]! {
    //Event names
    return ["onMRZRead"]
  }
}

class MrzReaderView : QKMRZScannerView {

  @objc var docType: String = "" {
    didSet {
      self.docType = docType
    }
  }

  @objc var cameraSelector: String = "" {
    didSet {
      self.cameraSelector = cameraSelector
    }
  }
}
