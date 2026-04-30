import Foundation
import AVFoundation
import Combine
import os.log

enum AzanDownloadState {
    case notDownloaded
    case downloading(progress: Double)
    case downloaded
    case failed(Error)
}

@MainActor
final class AzanService: ObservableObject {
    static let shared = AzanService()
    private static let logger = Logger(subsystem: "com.noor.app", category: "AzanService")
    private static let downloadTimeoutSeconds: TimeInterval = 60

    @Published var downloadStates: [String: AzanDownloadState] = [:]
    @Published var selectedAzanId: String {
        didSet {
            UserDefaults.standard.set(selectedAzanId, forKey: "selectedAzanId")
        }
    }
    @Published var azanEnabled: Bool {
        didSet {
            UserDefaults.standard.set(azanEnabled, forKey: "azanEnabled")
        }
    }

    private var audioPlayer: AVAudioPlayer?
    private var downloadTasks: [String: URLSessionDownloadTask] = [:]

    private lazy var downloadSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = Self.downloadTimeoutSeconds
        config.timeoutIntervalForResource = Self.downloadTimeoutSeconds * 2
        return URLSession(configuration: config)
    }()

    private init() {
        selectedAzanId = UserDefaults.standard.string(forKey: "selectedAzanId") ?? "silent"
        azanEnabled = UserDefaults.standard.bool(forKey: "azanEnabled")

        // Check which files are already downloaded
        checkDownloadedFiles()
    }

    // MARK: - Directory Management

    private var azanDirectory: URL {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            fatalError("Application Support directory not available")
        }
        let dir = appSupport.appendingPathComponent("Noor/azan", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func localURL(for azanId: String) -> URL {
        azanDirectory.appendingPathComponent("\(azanId).mp3")
    }

    // MARK: - Download State

    func checkDownloadedFiles() {
        for option in AzanOption.all {
            if option.isSilent {
                downloadStates[option.id] = .downloaded
            } else {
                let localPath = localURL(for: option.id)
                if FileManager.default.fileExists(atPath: localPath.path) {
                    downloadStates[option.id] = .downloaded
                } else {
                    downloadStates[option.id] = .notDownloaded
                }
            }
        }
    }

    func isDownloaded(_ azanId: String) -> Bool {
        if azanId == "silent" { return true }
        if case .downloaded = downloadStates[azanId] {
            return true
        }
        return false
    }

    // MARK: - Download

    func download(_ option: AzanOption) async {
        guard !option.isSilent else { return }
        guard let url = URL(string: option.downloadURL) else { return }

        downloadStates[option.id] = .downloading(progress: 0)

        do {
            let (tempURL, _) = try await downloadSession.download(from: url)
            let localPath = localURL(for: option.id)

            // Remove existing if any
            try? FileManager.default.removeItem(at: localPath)

            // Move downloaded file
            try FileManager.default.moveItem(at: tempURL, to: localPath)

            downloadStates[option.id] = .downloaded
            Self.logger.info("Azan downloaded: \(option.id)")
        } catch {
            downloadStates[option.id] = .failed(error)
            Self.logger.error("Failed to download azan \(option.id): \(error.localizedDescription)")
        }
    }

    func cancelDownload(_ azanId: String) {
        downloadTasks[azanId]?.cancel()
        downloadTasks[azanId] = nil
        downloadStates[azanId] = .notDownloaded
    }

    func deleteDownload(_ azanId: String) {
        let localPath = localURL(for: azanId)
        try? FileManager.default.removeItem(at: localPath)
        downloadStates[azanId] = .notDownloaded

        // Reset selection if deleted
        if selectedAzanId == azanId {
            selectedAzanId = "silent"
        }
    }

    // MARK: - Playback

    func play(_ azanId: String? = nil) {
        let id = azanId ?? selectedAzanId
        guard id != "silent" else { return }

        let localPath = localURL(for: id)
        guard FileManager.default.fileExists(atPath: localPath.path) else { return }

        do {
            audioPlayer?.stop()
            audioPlayer = nil
            audioPlayer = try AVAudioPlayer(contentsOf: localPath)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            Self.logger.error("Failed to play azan: \(error.localizedDescription)")
        }
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
    }

    func preview(_ azanId: String) {
        // Play a few seconds for preview
        play(azanId)

        // Stop after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            self?.stop()
        }
    }

    // MARK: - Selection

    func select(_ azanId: String) {
        guard isDownloaded(azanId) else { return }
        selectedAzanId = azanId
    }

    var selectedOption: AzanOption? {
        AzanOption.all.first { $0.id == selectedAzanId }
    }
}
