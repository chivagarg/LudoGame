import Foundation
import AVFoundation

public class SoundManager {
    public static let shared = SoundManager()
    
    // Define constants for sound file names to avoid magic strings
    private struct SoundFiles {
        static let leaveHome = "boing.mp3"
        static let hop = "hop.wav"
        static let hopReverse = "hopReverse.wav"
        static let capture = "capture.wav"
        static let victory = "victory.wav"
        static let dice = "dice.wav"
        static let evilLaugh = "evillaugh.wav"
        static let yeah = "yeah.wav"
        static let coins = "coins.wav"
        static let boost = "boost.wav"
    }
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var coinJanglePlayer: AVAudioPlayer?
    
    private init() {
        // Preload all sound effects using the constants
        preloadSound(named: SoundFiles.leaveHome)
        preloadSound(named: SoundFiles.hop)
        preloadSound(named: SoundFiles.hopReverse)
        preloadSound(named: SoundFiles.capture)
        preloadSound(named: SoundFiles.victory)
        preloadSound(named: SoundFiles.dice)
        preloadSound(named: SoundFiles.evilLaugh)
        preloadSound(named: SoundFiles.yeah)
        preloadSound(named: SoundFiles.coins)
        preloadSound(named: SoundFiles.boost)
    }
    
    private func preloadSound(named filename: String) {
        let fileComponents = filename.components(separatedBy: ".")
        guard fileComponents.count == 2,
              let name = fileComponents.first,
              let ext = fileComponents.last else {
            print("Invalid sound filename format: \(filename)")
            return
        }
        
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            print("Could not find sound file: \(filename)")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            audioPlayers[filename] = player
        } catch {
            print("Could not create audio player for \(filename): \(error)")
        }
    }
    
    public func playSound(_ name: String) {
        guard let player = audioPlayers[name] else {
            print("Sound not found: \(name)")
            return
        }
        
        // Reset the player to the beginning if it's already playing
        if player.isPlaying {
            player.currentTime = 0
        }
        
        player.play()
    }
    
    // MARK: - Specific Sound Functions
    
    public func playDiceRollSound() {
        playSound(SoundFiles.dice)
    }
    
    public func playPawnHopSound() {
        playSound(SoundFiles.hop)
    }

    public func playReverseHopSound() {
        playSound(SoundFiles.hopReverse)
    }
    
    public func playPawnCaptureSound() {
        playSound(SoundFiles.capture)
    }
    
    public func playPawnReachedHomeSound() {
        playSound(SoundFiles.victory)
    }
    
    public func playPawnLeaveHomeSound() {
        playSound(SoundFiles.leaveHome)
    }

    // Custom new sounds
    public func playEvilLaugh() {
        playSound(SoundFiles.evilLaugh)
    }

    public func playYeah() {
        playSound(SoundFiles.yeah)
    }

    // MARK: - Boost sound (capped at 3 seconds)

    public func playBoostSound() {
        guard let player = audioPlayers[SoundFiles.boost] else { return }
        player.currentTime = 0
        player.play()
        // The file may be long — stop playback after 3 seconds.
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak player] in
            player?.stop()
        }
    }

    // MARK: - Coin jangle (looped for coin drain animation)

    public func startCoinJangle() {
        guard let url = Bundle.main.url(forResource: "coins", withExtension: "wav") else { return }
        do {
            coinJanglePlayer = try AVAudioPlayer(contentsOf: url)
            coinJanglePlayer?.numberOfLoops = -1
            coinJanglePlayer?.volume = 0.85
            coinJanglePlayer?.prepareToPlay()
            coinJanglePlayer?.play()
        } catch {}
    }

    public func stopCoinJangle() {
        coinJanglePlayer?.stop()
        coinJanglePlayer = nil
    }
} 
