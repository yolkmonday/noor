import Foundation
import AVFoundation
import Combine
import os.log

@MainActor
final class AzanService: NSObject, ObservableObject {
    static let shared = AzanService()
    private static let logger = Logger(subsystem: "com.noor.app", category: "AzanService")

    @Published var selectedAzanId: String {
        didSet {
            UserDefaults.standard.set(selectedAzanId, forKey: "selectedAzanId")
        }
    }

    /// True while a full azan (not preview) is playing
    @Published private(set) var isPlaying = false

    /// Called when a full azan finishes playing on its own (not stopped manually)
    var onFinishPlaying: (() -> Void)?

    private var audioPlayer: AVAudioPlayer?

    private override init() {
        let saved = UserDefaults.standard.string(forKey: "selectedAzanId") ?? "silent"
        selectedAzanId = saved
        super.init()

        // Migrate away from an id that no longer has a bundled sound
        // (e.g. leftover from the old remote-download azan list)
        if saved != "silent" && !isAvailable(saved) {
            let fallback = AzanOption.all.first(where: { !$0.isSilent && isAvailable($0.id) })?.id ?? "silent"
            Self.logger.info("selectedAzanId '\(saved)' no longer bundled, migrating to '\(fallback)'")
            selectedAzanId = fallback
        }
    }

    // MARK: - Bundled Resource

    private func bundledURL(for azanId: String) -> URL? {
        Bundle.main.url(forResource: azanId, withExtension: "mp3")
    }

    func isAvailable(_ azanId: String) -> Bool {
        if azanId == "silent" { return true }
        return bundledURL(for: azanId) != nil
    }

    // MARK: - Playback

    /// Play the full azan track (used for actual prayer notifications)
    func play(_ azanId: String? = nil) {
        let id = azanId ?? selectedAzanId
        guard id != "silent" else { return }
        guard let url = bundledURL(for: id) else {
            Self.logger.error("Azan resource not found in bundle: \(id)")
            return
        }

        do {
            audioPlayer?.stop()
            audioPlayer = nil
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.prepareToPlay()
            player.play()
            audioPlayer = player
            isPlaying = true
        } catch {
            Self.logger.error("Failed to play azan: \(error.localizedDescription)")
        }
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
    }

    func preview(_ azanId: String) {
        // Play a few seconds for preview only, doesn't affect isPlaying/popup state
        guard azanId != "silent", let url = bundledURL(for: azanId) else { return }

        do {
            audioPlayer?.stop()
            let previewPlayer = try AVAudioPlayer(contentsOf: url)
            previewPlayer.delegate = nil
            previewPlayer.prepareToPlay()
            previewPlayer.play()
            audioPlayer = previewPlayer
        } catch {
            Self.logger.error("Failed to preview azan: \(error.localizedDescription)")
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            self?.audioPlayer?.stop()
            self?.audioPlayer = nil
        }
    }

    // MARK: - Selection

    func select(_ azanId: String) {
        guard isAvailable(azanId) else { return }
        selectedAzanId = azanId
    }

    var selectedOption: AzanOption? {
        AzanOption.all.first { $0.id == selectedAzanId }
    }
}

// MARK: - AVAudioPlayerDelegate

extension AzanService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            guard self.audioPlayer === player else { return }
            self.audioPlayer = nil
            self.isPlaying = false
            self.onFinishPlaying?()
        }
    }
}
