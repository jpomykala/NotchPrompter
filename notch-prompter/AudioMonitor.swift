//
//  AudioMonitor.swift
//  notch-prompter
//
//  Created by Jakub Pomykała on 07/12/2025.
//


import AVFoundation
import SwiftUI
import Combine


class AudioMonitor: ObservableObject {
    private var audioEngine: AVAudioEngine
    private var inputNode: AVAudioInputNode?
    private var timer: Timer?
    private let smoothingFactor: Float = 0.15
    private var lastPublishTime = Date.timeIntervalSinceReferenceDate
    
    @Published var rmsLevel: Float = 0
    

    init() {
        audioEngine = AVAudioEngine()
        inputNode = audioEngine.inputNode
    }

    func startMonitoring() {
        let format = inputNode!.outputFormat(forBus: 0)
        
        inputNode!.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, time in
            guard let self = self else { return }

            let rms = self.rms(buffer: buffer)
            let smoothedRms = (self.rmsLevel * (1 - self.smoothingFactor)) + (rms * self.smoothingFactor)
            DispatchQueue.main.async {
                self.rmsLevel = smoothedRms
            }
        }

        do {
            try audioEngine.start()
        } catch {
            print("Error starting audio engine: \(error)")
        }
    }

    func stopMonitoring() {
        inputNode?.removeTap(onBus: 0)
        audioEngine.stop()
    }

    private func rms(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0 }
        let frameLength = Int(buffer.frameLength)
        var sum: Float = 0
        for i in 0..<frameLength {
            sum += channelData[i] * channelData[i]
        }
        return sqrt(sum / Float(frameLength))
    }
}
