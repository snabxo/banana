import Combine
import SwiftUI
import AVFoundation

struct CameraView: View {
    let onImageCaptured: (UIImage) -> Void
    
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var viewModel = CameraViewModel()
    @State private var showingPreview = false
    @State private var capturedImage: UIImage?
    
    var body: some View {
        ZStack {
            // Camera Preview
            CameraPreview(session: viewModel.session)
                .ignoresSafeArea()
            
            // Camera Controls Overlay
            VStack {
                // Top Bar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    
                    Spacer()
                    
                    Button {
                        viewModel.toggleFlash()
                    } label: {
                        Image(systemName: viewModel.flashMode == .on ? "bolt.fill" : "bolt.slash.fill")
                            .font(.title2)
                            .foregroundColor(viewModel.flashMode == .on ? .yellow : .white)
                            .padding()
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                }
                .padding()
                
                Spacer()
                
                // Bottom Controls
                HStack(spacing: 60) {
                    // Gallery Button
                    Button {
                        // Switch to photo picker
                        dismiss()
                    } label: {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    
                    // Capture Button
                    Button {
                        viewModel.capturePhoto { image in
                            if let image = image {
                                capturedImage = image
                                showingPreview = true
                            }
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 70, height: 70)
                            
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                                .frame(width: 80, height: 80)
                        }
                    }
                    .disabled(viewModel.isCapturing)
                    
                    // Flip Camera Button
                    Button {
                        viewModel.flipCamera()
                    } label: {
                        Image(systemName: "camera.rotate")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                }
                .padding(.bottom, 40)
            }
            
            // Permission Denied Overlay
            if viewModel.showPermissionAlert {
                VStack(spacing: AppTheme.spacingL) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                    
                    Text("Camera Access Required")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Text("Please enable camera access in Settings to take product photos")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal)
                    
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("Open Settings")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(AppTheme.cornerRadiusM)
                    }
                    .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
            }
        }
        .sheet(isPresented: $showingPreview) {
            if let image = capturedImage {
                ImagePreviewView(image: image) { shouldSave in
                    if shouldSave {
                        onImageCaptured(image)
                    } else {
                        capturedImage = nil
                        showingPreview = false
                    }
                }
            }
        }
        .onAppear {
            viewModel.checkPermissions()
        }
        .onDisappear {
            viewModel.stopSession()
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        context.coordinator.previewLayer = previewLayer
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.previewLayer?.frame = uiView.bounds
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}

struct ImagePreviewView: View {
    let image: UIImage
    let onDecision: (Bool) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Retake") {
                        onDecision(false)
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Use Photo") {
                        onDecision(true)
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .bold()
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

@MainActor
class CameraViewModel: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    @Published var isCapturing = false
    @Published var showPermissionAlert = false
    
    private var photoOutput = AVCapturePhotoOutput()
    private var currentCamera: AVCaptureDevice.Position = .back
    private var captureCompletion: ((UIImage?) -> Void)?
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCamera()
                    } else {
                        self?.showPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            showPermissionAlert = true
        @unknown default:
            showPermissionAlert = true
        }
    }
    
    private func setupCamera() {
        session.beginConfiguration()
        
        // Remove existing inputs
        session.inputs.forEach { session.removeInput($0) }
        
        // Add camera input
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCamera),
              let input = try? AVCaptureDeviceInput(device: device) else {
            session.commitConfiguration()
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        // Add photo output
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.maxPhotoQualityPrioritization = .quality
        }
        
        session.commitConfiguration()
        
        // Start session on background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        guard !isCapturing else { return }
        
        isCapturing = true
        captureCompletion = completion
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = flashMode
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func flipCamera() {
        currentCamera = currentCamera == .back ? .front : .back
        setupCamera()
    }
    
    func toggleFlash() {
        flashMode = flashMode == .off ? .on : .off
    }
    
    func stopSession() {
        if session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.stopRunning()
            }
        }
    }
}

extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            Task { @MainActor in
                self.captureCompletion?(nil)
                self.isCapturing = false
            }
            return
        }
        
        Task { @MainActor in
            self.captureCompletion?(image)
            self.isCapturing = false
        }
    }
}

#Preview {
    CameraView { _ in }
}
