import SwiftUI
import AVFoundation

public struct ScanDocCameraView: UIViewControllerRepresentable {

    public init() {
        
    }

    public func makeUIViewController(context: Context) -> UIViewController {
        CameraViewController(scanDocSDK: ScanDocAPI.shared)
    }

    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {

    }

    public static func dismantleUIViewController(_ uiViewController: UIViewController, coordinator: ()) {
        (uiViewController as? CameraViewController)?.dismiss()
    }
}

fileprivate class CameraViewController: UIViewController {
    
    private let scanDocSDK: ScanDocAPI
    private lazy var session = AVCaptureSession()
    private lazy var movieOutput = AVCaptureVideoDataOutput()
    private lazy var context = CIContext()
    private lazy var serialDispatchQueue = DispatchQueue(label: String(describing: ScanDocCameraView.self),
                                                         qos: .userInitiated)
    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspect

        return previewLayer
    }()

    init(scanDocSDK: ScanDocAPI) {
        self.scanDocSDK = scanDocSDK
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        serialDispatchQueue.async { [weak self] in
            self?.addVideoInput()
            self?.addVideoOutput()
            self?.session.startRunning()
            self?.startRecording()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
        let deviceOrientation = UIDevice.current.orientation
        switch deviceOrientation {
        case .landscapeLeft:
            previewLayer.connection?.videoOrientation = .landscapeRight
        case .landscapeRight:
            previewLayer.connection?.videoOrientation = .landscapeLeft
        case .portraitUpsideDown:
            previewLayer.connection?.videoOrientation = .portraitUpsideDown
        case .portrait:
            previewLayer.connection?.videoOrientation = .portrait
        default:
            previewLayer.connection?.videoOrientation = .portrait
        }
    }

    func dismiss() {
        stopRecording()
        session.stopRunning()
    }
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
                
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return
        }
        let uiImage = UIImage(cgImage: cgImage)
        
//        print("Sending image to API. Size: \(uiImage.size), scale: \(uiImage.scale)")
        scanDocSDK.onImageFromCamera(image: uiImage)
    }
}

private extension CameraViewController {

    func addVideoInput() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: device) else { return }
        if session.canAddInput(input) {
            if device.isFocusModeSupported(.continuousAutoFocus) {
                try? device.lockForConfiguration()
                device.focusMode = .continuousAutoFocus
                device.unlockForConfiguration()
            }
            session.addInput(input)
        }
    }

    func addVideoOutput() {
        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
        }
    }

    func startRecording() {
        movieOutput.setSampleBufferDelegate(self, queue: serialDispatchQueue)
    }
    
    func stopRecording() {
        movieOutput.setSampleBufferDelegate(nil, queue: nil)
    }
}
