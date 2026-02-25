import AVFoundation
import SwiftUI
import UIKit
import VisionKit

struct QRCodeScannerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onScan: (String) -> Void

    @State private var inlineMessage = "Place the QR code inside the scan frame"

    var body: some View {
        NavigationStack {
            ZStack {
                if DataScannerViewController.isSupported, DataScannerViewController.isAvailable {
                    LiveScannerView(
                        onScan: { value in
                            onScan(value)
                            dismiss()
                        },
                        onError: { message in
                            inlineMessage = message
                        }
                    )
                    .ignoresSafeArea()
                } else {
                    unsupportedView
                }
            }
            .navigationTitle("Scan QR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Text(inlineMessage)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial)
            }
        }
    }

    private var unsupportedView: some View {
        VStack(spacing: 14) {
            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 42))
                .foregroundStyle(Color.blue)
            Text("This device does not support real-time QR scanning")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.primary)
            Button {
                guard let text = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
                    inlineMessage = "No valid address in clipboard"
                    return
                }
                onScan(text)
                dismiss()
            } label: {
                Text("Paste from Clipboard")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .foregroundStyle(.white)
                    .background(Color.blue, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .padding(20)
    }
}

private struct LiveScannerView: UIViewControllerRepresentable {
    let onScan: (String) -> Void
    let onError: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan, onError: onError)
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        controller.delegate = context.coordinator
        context.coordinator.prepare(controller: controller)
        return controller
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context _: Context) {}

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        private let onScan: (String) -> Void
        private let onError: (String) -> Void
        private weak var controller: DataScannerViewController?
        private var didScan = false

        init(onScan: @escaping (String) -> Void, onError: @escaping (String) -> Void) {
            self.onScan = onScan
            self.onError = onError
        }

        func prepare(controller: DataScannerViewController) {
            self.controller = controller
            Task { @MainActor in
                await requestCameraPermissionAndStart()
            }
        }

        @MainActor
        private func requestCameraPermissionAndStart() async {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            switch status {
            case .authorized:
                startScanning()
            case .notDetermined:
                let granted = await requestVideoPermission()
                if granted {
                    startScanning()
                } else {
                    onError("Camera permission not granted, cannot scan QR code")
                }
            case .denied, .restricted:
                onError("Enable camera permission in system settings")
            @unknown default:
                onError("Unable to access camera")
            }
        }

        @MainActor
        private func startScanning() {
            guard let controller else { return }
            do {
                try controller.startScanning()
            } catch {
                onError("Failed to start QR scan, please retry")
            }
        }

        private func requestVideoPermission() async -> Bool {
            await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    continuation.resume(returning: granted)
                }
            }
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems _: [RecognizedItem]) {
            guard !didScan else { return }
            for item in addedItems {
                guard case let .barcode(barcode) = item else { continue }
                guard let payload = barcode.payloadStringValue?.trimmingCharacters(in: .whitespacesAndNewlines), !payload.isEmpty else { continue }
                didScan = true
                dataScanner.stopScanning()
                onScan(payload)
                return
            }
        }

        func dataScanner(_: DataScannerViewController, becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable) {
            onError(error.localizedDescription)
        }
    }
}
