import MediaPlayer
import AVFoundation

/// Manages Now Playing info for Control Center / Lock Screen integration
final class NowPlayingManager {
    static let shared = NowPlayingManager()
    private let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    private var nowPlayingInfo: [String: Any] = [:]

    private init() {
        setupRemoteCommandCenter()
    }

    private func setupRemoteCommandCenter() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.isEnabled = true
        center.pauseCommand.isEnabled = true
        center.playCommand.addTarget { [weak self] _ in
            self?.handlePlay()
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            self?.handlePause()
            return .success
        }
    }

    func updateNowPlaying(title: String, artist: String, duration: TimeInterval, isPlaying: Bool) {
        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyArtist] = artist
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0.0
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }

    func updatePlaybackState(isPlaying: Bool) {
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }

    private func handlePlay() {
        NotificationCenter.default.post(name: .init("NowPlayingPlay"), object: nil)
    }

    private func handlePause() {
        NotificationCenter.default.post(name: .init("NowPlayingPause"), object: nil)
    }
}
