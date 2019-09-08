//
//  FilteredCamera.swift
//  Photolyze
//
//  Created by Mac on 06.09.2019.
//  Copyright © 2019 Lammax. All rights reserved.
//

import UIKit
import AVFoundation

protocol FilteredCameraDelegate {
    func filteredCamera(didUpdate image: CIImage)
}

class FilteredCamera: NSObject {
    
    //static let sharedInstance = FilteredCamera()
    
    var delegate: FilteredCameraDelegate?
    
    private var captureSession = AVCaptureSession()
    private var backCamera: AVCaptureDevice?
    private var frontCamera: AVCaptureDevice?
    private var currentCamera: AVCaptureDevice?
    
    private var photoOutput: AVCapturePhotoOutput?
    private var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    
    private let context = CIContext()
    
    // MARK: GLOBAL
    
    init(externalView: UIView? = nil) {
        super.init()
        
        self.setupCaptureSession()
        self.setupDevice()
        self.setupInputOutput()
        self.setupCorrectFramerate(currentCamera: currentCamera!) // will default to 30fps unless stated otherwise
        self.setupPreviewLayer(view: externalView)
        self.setupDelegate()
        self.startRunningCaptureSession()
    }
    
    // MARK: PRIVATE
    
    private func setupCaptureSession() {
        // should support anything up to 1920x1080 res, incl. 240fps @ 720p
        captureSession.sessionPreset = AVCaptureSession.Preset.high
    }
    
    private func setupDevice() {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
        let devices = deviceDiscoverySession.devices
        
        for device in devices {
            if device.position == AVCaptureDevice.Position.back {
                backCamera = device
            }
            else if device.position == AVCaptureDevice.Position.front {
                frontCamera = device
            }
        }
        
        currentCamera = backCamera
    }
    
    private func setupInputOutput() {
        
        let activateCamera = {
            do {
                let captureDeviceInput = try AVCaptureDeviceInput(device: self.currentCamera!)
                self.captureSession.addInput(captureDeviceInput)
                self.photoOutput?.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])], completionHandler: nil)
            } catch {
                print(error)
            }
        }
        
        if AVCaptureDevice.authorizationStatus(for: AVMediaType.video) != .authorized {
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler:{ (authorized) in
                DispatchQueue.main.async
                    {
                        if authorized {
                            activateCamera()
                        }
                }
            })
        } else {
            activateCamera()
        }
    }
    
    private func setupCorrectFramerate(currentCamera: AVCaptureDevice) {
        for vFormat in currentCamera.formats {
            var ranges = vFormat.videoSupportedFrameRateRanges as [AVFrameRateRange]
            let frameRates = ranges[0]
            
            do {
                //set to 240fps - available types are: 30, 60, 120 and 240 and custom
                // lower framerates cause major stuttering
                if frameRates.maxFrameRate == 240 {
                    try currentCamera.lockForConfiguration()
                    currentCamera.activeFormat = vFormat as AVCaptureDevice.Format
                    //for custom framerate set min max activeVideoFrameDuration to whatever you like, e.g. 1 and 180
                    currentCamera.activeVideoMinFrameDuration = frameRates.minFrameDuration
                    currentCamera.activeVideoMaxFrameDuration = frameRates.maxFrameDuration
                }
            }
            catch {
                print("Could not set active format")
                print(error)
            }
        }
    }
    
    private func setupPreviewLayer(view: UIView?) {
        guard let view = view else { fatalError("No view for camera!") }
        
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraPreviewLayer?.connection?.videoOrientation = transformOrientation(orientation: UIDevice.current.orientation)
        cameraPreviewLayer?.frame = view.frame
        
        //set preview in background, allows for elements to be placed in the foreground
        view.layer.insertSublayer(cameraPreviewLayer!, at: 0)
    }
    
    private func setupDelegate() {
       // let videoOutput = AVCaptureVideoDataOutput()
        //videoOutput.setSampleBufferDelegate(self as AVCaptureVideoDataOutputSampleBufferDelegate, queue: DispatchQueue.main)
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self as AVCaptureVideoDataOutputSampleBufferDelegate, queue: DispatchQueue.main)
        if self.captureSession.canAddOutput(videoOutput) {
            self.captureSession.addOutput(videoOutput)
        }
    }
    
    private func startRunningCaptureSession() {
        captureSession.startRunning()
        backCamera?.unlockForConfiguration()
    }
    
    private func transformOrientation(orientation: UIDeviceOrientation) -> AVCaptureVideoOrientation {
        switch orientation {
        case .landscapeRight:       return .landscapeLeft
        case .landscapeLeft:        return .landscapeRight
        case .portrait:             return .portrait
        case .portraitUpsideDown:   return .portraitUpsideDown
        default:
            return .portrait
        }
    }
    
}

extension FilteredCamera: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            let cameraImage = CIImage(cvImageBuffer: pixelBuffer)
            self.delegate?.filteredCamera(didUpdate: cameraImage)
        } else {
            print("No pixelBuffer")
        }
        
    }
    
}
