//
//  QRScannerDelegate.swift
//  QRScanner
//
//  Created by Aybars Acar on 8/5/2023.
//

import SwiftUI
import AVKit

class QRScannerDelegate: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
  
  @Published private(set) var scannedCode: String?
  
  func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
    
    if let metaObject = metadataObjects.first {
      
      guard let readableObject = metaObject as? AVMetadataMachineReadableCodeObject else {
        return
      }
      
      guard let code = readableObject.stringValue else {
        return
      }

      print(code)
      scannedCode = code
    }
  }
  
  func clearScannedCode() {
    scannedCode = nil
  }
}
