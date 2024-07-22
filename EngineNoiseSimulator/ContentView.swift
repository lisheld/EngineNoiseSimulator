import SwiftUI
import CoreMotion
import AVFoundation

struct ContentView: View {
    @StateObject private var motionManager = MotionManager()
    
    var body: some View {
        VStack {
            Text("Engine Noise Simulator")
                .font(.largeTitle)
                .padding()
            
            Text("Current State: \(motionManager.currentSound)")
                .font(.title2)
                .padding()
        }
        .onAppear {
            motionManager.startAccelerometerUpdates()
        }
        .onDisappear {
            motionManager.stopAccelerometerUpdates()
        }
    }
}

class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    private var audioPlayer: AVAudioPlayer?
    
    @Published var currentSound: String = "Idle"
    
    func startAccelerometerUpdates() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1 // Update interval in seconds
            motionManager.startAccelerometerUpdates(to: OperationQueue.main) { [weak self] (data, error) in
                guard let self = self else { return }
                if let validData = data {
                    self.handleAccelerometerData(validData)
                }
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    self.motionManager.stopAccelerometerUpdates()
                }
            }
        } else {
            print("Accelerometer is not available")
        }
    }
    
    func stopAccelerometerUpdates() {
        motionManager.stopAccelerometerUpdates()
    }
    
    private func handleAccelerometerData(_ data: CMAccelerometerData) {
        let x = data.acceleration.x
        let y = data.acceleration.y
        let z = data.acceleration.z
        
        // Determine the acceleration magnitude
        let accelerationMagnitude = sqrt(x*x + y*y + z*z)
        
        // Determine which sound to play based on acceleration magnitude
        if accelerationMagnitude < 0.1 {
            playSound(named: "engine_idle", displayName: "Idle")
        } else if accelerationMagnitude >= 0.1 && accelerationMagnitude < 0.5 {
            playSound(named: "engine_accelerating", displayName: "Accelerating")
        } else {
            playSound(named: "engine_decelerating", displayName: "Decelerating")
        }
    }
    
    private func playSound(named soundName: String, displayName: String) {
        guard currentSound != displayName else { return } // Do not play the same sound again
        
        if let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.numberOfLoops = -1 // Loop indefinitely
                audioPlayer?.play()
                currentSound = displayName
                DispatchQueue.main.async {
                    self.currentSound = displayName
                }
            } catch {
                print("Error playing sound: \(error.localizedDescription)")
            }
        } else {
            print("Sound file not found: \(soundName)")
        }
    }
}
