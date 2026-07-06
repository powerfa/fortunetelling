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
}
