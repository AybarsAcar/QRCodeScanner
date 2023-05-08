//
//  ScannerView.swift
//  QRScanner
//
//  Created by Aybars Acar on 17/4/2023.
//

import SwiftUI
import AVKit

struct ScannerView: View {
  
  @Environment(\.openURL) private var openURL
  
  @State private var scanning = false
  @State private var session = AVCaptureSession()
  @State private var cameraPermission: Permission = .idle
  
  // QR Scanner AV Output
  @State private var qrOutput = AVCaptureMetadataOutput()
  
  // Error properties
  @State private var errorMessage = ""
  @State private var showError = false
  
  // Camera QR Output Deletage
  @State private var qrDelegate = QRScannerDelegate()
  
  @State private var code = ""
  
  var body: some View {
    VStack(spacing: 8) {
      Button {
        
      } label: {
        Image(systemName: "xmark")
          .font(.title3)
          .foregroundColor(Color.theme.main)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      
      Text("Place the QR code inside the area")
        .font(.title3)
        .foregroundColor(.black.opacity(0.8))
        .padding(.top, 20)
      
      Text("Scanning will start automatically")
        .font(.callout)
        .foregroundColor(.gray)
      
      GeometryReader { proxy in
        let size = proxy.size
        
        ZStack {
          
          CameraView(frameSize: CGSize(width: size.width, height: size.width), session: $session)
            .scaleEffect(0.97)
          
          ForEach(0...4, id: \.self) { index in
            RoundedRectangle(cornerRadius: 2, style: .circular)
              .trim(from: 0.61, to: 0.64)
              .stroke(Color.theme.main, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
              .rotationEffect(.degrees(90 * Double(index)))
          }
        }
        .frame(width: size.width, height: size.width)

        // Scanner Animation
        .overlay(alignment: .top, content: {
          Rectangle()
            .fill(Color.theme.main)
            .frame(height: 2.5)
            .shadow(color: .black.opacity(0.8), radius: 8, x: 0, y: scanning ? 15 : -15)
            .offset(y: scanning ? size.width : 0)
        })
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        
      }
      .padding(.horizontal, 45)
      
      Spacer(minLength: 15)
      
      Button {
        if !session.isRunning && cameraPermission == .approved {
          reactivateCamera()
          activateScannerAnimation()
        }
      } label: {
        Image(systemName: "qrcode.viewfinder")
          .font(.largeTitle)
          .foregroundColor(.gray)
      }
      
      Spacer(minLength: 45)
      
    }
    .padding(15)
    .onAppear(perform: checkCameraPermission)
    .alert(errorMessage, isPresented: $showError) {
      if cameraPermission == .denied {
        Button("Settings") {
          if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            // opening app settings
            openURL(settingsURL)
          }
        }
        
        Button("Cancel", role: .cancel) {
          
        }
      }
    }
    .onChange(of: qrDelegate.scannedCode) { newValue in
      if let scannedCode = newValue {
        code = scannedCode
        
        // when the first code is available stop scanning
        session.stopRunning()
        
        // stop scanning animation
        deActivateScannerAnimation()
        
        // clearing the data on delegate
        qrDelegate.clearScannedCode()
      }
    }
  }
}

private extension ScannerView {
  
  func reactivateCamera() {
    DispatchQueue.global(qos: .background).async {
      session.startRunning()
    }
  }
  
  func activateScannerAnimation() {
    withAnimation(.easeInOut(duration: 0.85).delay(0.1).repeatForever(autoreverses: true)) {
      scanning = true
    }
  }
  
  func deActivateScannerAnimation() {
    withAnimation(.easeInOut(duration: 0.85)) {
      scanning = false
    }
  }
  
  /// Checking Camera Permissions
  func checkCameraPermission() {
    Task {
      switch AVCaptureDevice.authorizationStatus(for: .video) {
        
      case .notDetermined:
        // request camera permission
        if await AVCaptureDevice.requestAccess(for: .video) {
          // permission granted
          cameraPermission = .approved
          setupCamera()
        } else {
          // permission denied
          cameraPermission = .denied
          presentError("Please provide access to camera for scanning qr codes")
        }
        
      case .denied, .restricted:
        cameraPermission = .denied
        presentError("Please provide access to camera for scanning qr codes")
        
      case .authorized:
        cameraPermission = .approved
        if session.inputs.isEmpty {
          // new setup
          setupCamera()
        } else {
          // already existing one
          session.startRunning()
        }
        
      @unknown default:
        break
      }
    }
  }
  
  /// Setting Up Camera
  func setupCamera() {
    do {
      // Finding Back Camera
      guard let device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices.first else {
        presentError("Camera is not working!")
        return
      }
      
      // Camera Input
      let input = try AVCaptureDeviceInput(device: device)
      
      // for extra safety
      // Checking whetehr input & outpu can be added to the session
      guard session.canAddInput(input), session.canAddOutput(qrOutput) else {
        presentError("Camera is not working!")
        return
      }
      
      // adding input and output to Camera Session
      session.beginConfiguration()
      session.addInput(input)
      session.addOutput(qrOutput)
      
      // setting output config to read QR codes
      qrOutput.metadataObjectTypes = [.qr]
      
      // adding delegate to retrieve teh fetched qr code from camera
      qrOutput.setMetadataObjectsDelegate(qrDelegate, queue: .main)
      
      session.commitConfiguration()
      
      // Note sesion must be started on Background thread
      DispatchQueue.global(qos: .background).async {
        session.startRunning()
      }
      activateScannerAnimation()
      
    } catch {
      presentError(error.localizedDescription)
    }
  }
  
  /// Presenting Error
  func presentError(_ message: String) {
    errorMessage = message
    showError.toggle()
  }
}

struct ScannerView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
 
