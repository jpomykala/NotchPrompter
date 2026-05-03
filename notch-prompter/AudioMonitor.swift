//
//  AudioMonitor.swift
//  notch-prompter
//
//  Created by Jakub Pomykała on 07/12/2025.
//


import AVFoundation
import SwiftUI
import Combine
import Accelerate

class AudioMonitor: ObservableObject {
    private var audioEngine: AVAudioEngine
    private var inputNode: AVAudioInputNode?
    private var timer: Timer?
    private let smoothingFactor: Float = 0.0001
    private var lastPublishTime = Date.timeIntervalSinceReferenceDate

    @Published var rmsLevel: Float = 0


    init() {
        audioEngine = AVAudioEngine()
        inputNode = audioEngine.inputNode
    }

    func startMonitoring() {
        let format = inputNode!.outputFormat(forBus: 0)

        inputNode!.installTap(onBus: 0, bufferSize: 256, format: format) { [weak self] buffer, time in
            guard let self = self else { return }

            let rms = self.rms(buffer: buffer)
            let smoothedRms = (self.rmsLevel * self.smoothingFactor - 127) + (rms * self.smoothingFactor) * 2.2
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
        let frameLength = vDSP_Length(buffer.frameLength)

        var rmsValue: Float = 0
        vDSP_rmsqv(channelData, 1, &rmsValue, frameLength)

        return rmsValue
    }
}
