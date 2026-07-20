import AVFoundation

/// Plays the synthesized coin-toss and reveal sounds. Respects the "soundEnabled" setting.
final class SoundPlayer {
    static let shared = SoundPlayer()

    private var players: [String: AVAudioPlayer] = [:]

    private init() {
        // Ambient: never interrupts the user's music/podcasts.
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
    }

    private var enabled: Bool {
        // Default ON when the key has never been set.
        UserDefaults.standard.object(forKey: "soundEnabled") == nil
            || UserDefaults.standard.bool(forKey: "soundEnabled")
    }

    private func play(_ name: String) {
        guard enabled,
              let url = Bundle.main.url(forResource: name, withExtension: "wav") else { return }
        if let cached = players[name] {
            cached.currentTime = 0
            cached.play()
            return
        }
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.prepareToPlay()
        players[name] = player
        player.play()
    }

    func playToss() { play("coin_toss") }
    func playReveal() { play("reveal") }
    func playBrush() { play("brush") }
}

/// Looping meditation music while the incense burns.
/// Uses .ambient + mixWithOthers: respects the ring/silent switch (no sound
/// when the phone is muted) and never interrupts the user's own audio.
/// Playback pauses in the background; RootView resumes it on return while
/// the incense is still burning.
final class IncenseMusicPlayer {
    static let shared = IncenseMusicPlayer()

    private var player: AVAudioPlayer?
    private var stopWork: DispatchWorkItem?

    private init() {}

    private var enabled: Bool {
        UserDefaults.standard.object(forKey: "incenseMusicEnabled") == nil
            || UserDefaults.standard.bool(forKey: "incenseMusicEnabled")
    }

    var isPlaying: Bool { player?.isPlaying ?? false }

    /// Idempotent: safe to call on every appear while burning.
    func startIfNeeded(remaining: TimeInterval) {
        guard enabled, remaining > 2, player?.isPlaying != true,
              let url = Bundle.main.url(forResource: "incense_music", withExtension: "caf")
        else { return }
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        guard let p = try? AVAudioPlayer(contentsOf: url) else { return }
        p.numberOfLoops = -1
        p.volume = 0
        p.play()
        p.setVolume(0.85, fadeDuration: 3.0)
        player = p
        // Stop exactly when the incense finishes (fires in background too,
        // since the app stays alive while audio plays).
        stopWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.stop() }
        stopWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + remaining, execute: work)
    }

    func stop(fade: TimeInterval = 2.5) {
        stopWork?.cancel()
        stopWork = nil
        guard let p = player, p.isPlaying else {
            player = nil
            return
        }
        p.setVolume(0, fadeDuration: fade)
        DispatchQueue.main.asyncAfter(deadline: .now() + fade + 0.1) { [weak self] in
            self?.player?.stop()
            self?.player = nil
        }
    }
}
