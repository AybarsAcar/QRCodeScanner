//
//  CameraView.swift
//  QRScanner
//
//  Created by Aybars Acar on 17/4/2023.
//

import SwiftUI
import AVKit

/// Uses AVCaptureVideoPreviewLayer
struct CameraView: UIViewRepresentable {
  
  var frameSize: CGSize
  
  // camera session
  @Binding var session: AVCaptureSession
  
  func makeUIView(context: Context) -> UIView {
    // define camer frame size
    let view = UIViewType(frame: CGRect(origin: .zero, size: frameSize))
    view.backgroundColor = .clear
    
    let cameraLayer = AVCaptureVideoPreviewLayer(session: session)
    cameraLayer.frame = CGRect(origin: .zero, size: frameSize)
    cameraLayer.videoGravity = .resizeAspectFill
    cameraLayer.masksToBounds = true
    
    view.layer.addSublayer(cameraLayer)
    
    return view
  }
  
  func updateUIView(_ uiView: UIViewType, context: Context) {
    
  }
}
