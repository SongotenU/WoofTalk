//
//  audio_buffer_manager.swift
//  WoofTalk
//
//  Created by vandopha on 11/3/26.
//

import AVFoundation

class AudioBufferManager {
    private let queue = DispatchQueue(label: "audio.buffer.queue")
    private var bufferPool: [AVAudioPCMBuffer] = []
    private let maxPoolSize = 10
    private let bufferFormat: AVAudioFormat
    
    init(format: AVAudioFormat) {
        self.bufferFormat = format
    }
    
    func allocateBuffer(frameCapacity: AVAudioFrameCount) -> AVAudioPCMBuffer {
        queue.sync {
            if let buffer = bufferPool.popLast() {
                buffer.frameLength = 0
                return buffer
            }
        }
        
        return AVAudioPCMBuffer(
            pcmFormat: bufferFormat,
            frameCapacity: frameCapacity
        )!
    }
    
    func recycleBuffer(_ buffer: AVAudioPCMBuffer) {
        queue.sync {
            if bufferPool.count < maxPoolSize {
                bufferPool.append(buffer)
            }
        }
    }
    
    func getCurrentPoolCount() -> Int {
        queue.sync { bufferPool.count }
    }
    
    func clearPool() {
        queue.sync {
            bufferPool.removeAll()
        }
    }
    
    func getPoolStatistics() -> [String: Any] {
        queue.sync {
            return [
                "poolSize": bufferPool.count,
                "maxPoolSize": maxPoolSize,
                "bufferFormat": AudioFormats.getFormatDescription(bufferFormat)
            ]
        }
    }
    
    func isPoolFull() -> Bool {
        queue.sync { bufferPool.count >= maxPoolSize }
    }
    
    func getBufferPoolMemoryUsage() -> Int {
        queue.sync {
            let bytesPerBuffer = MemoryLayout<Float>.size * Int(bufferFormat.sampleRate) * Int(bufferFormat.channelCount ?? 1)
            return bufferPool.count * bytesPerBuffer
        }
    }
}