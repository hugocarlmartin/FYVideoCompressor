# FYVideoCompressor

A high-performance, flexible and easy to use Video compressor library written by Swift. Using hardware-accelerator APIs in AVFoundation. You can add `Bitrate`, `FPS`, and other filters.

[![Version](https://img.shields.io/badge/language-swift%205-f48041.svg?style=flat)](https://developer.apple.com/swift) [![License](https://img.shields.io/badge/license-MIT-lightgrey.svg?style=flat)](https://github.com/T2Je/FYVideoCompressor) ![Platform](https://img.shields.io/cocoapods/p/FYVideoCompressor)



## Usage

### Compress with quality param

```swift
public enum VideoQuality: Equatable {
        /// Scale video size proportionally, not large than 224p and
        /// reduce fps and bit rate if need.
        case lowQuality
        
        /// Scale video size proportionally, not large than 480p and
        /// reduce fps and bit rate if need.
        case mediumQuality
        
        /// Scale video size proportionally, not large than 1080p and
        /// reduce fps and bit rate if need.
        case highQuality
        
        /// reduce fps and bit rate if need.
        /// Scale video size with specified `scale`.
        case custom(fps: Float, bitrate: Int, scale: CGSize)
}
```

Set `VideoQuality` to get different quality of video, beside, you can set custom fps, bitrate and scale:

```swift
FYVideoCompressor.shared.compressVideo(yourVideoPath, quality: .lowQuality) { result in
            switch result {
            case .success(let compressedVideoURL):
            case .failure(let error):
            }
 }
```

### Compress with more customized configuration param

```swif
public struct CompressionConfig {
        // video
        let videoBitrate: Int // bitrate use 1000 for 1kbps.https://en.wikipedia.org/wiki/Bit_rate
        
        let videomaxKeyFrameInterval: Int // A key to access the maximum interval between keyframes. 1 means key frames only, H.264 only
        
        let fps: Float // If video's fps less than this value, this value will be ignored.
        
        // audio
        let audioSampleRate: Int
        
        let audioBitrate: Int
        
        let fileType: AVFileType
        
        /// Scale (resize) the input video
        /// 1. If you need to simply resize your video to a specific size (e.g 320×240), you can use the scale: CGSize(width: 320, height: 240)
        /// 2. If you want to keep the aspect ratio, you need to specify only one component, either width or height, and set the other component to -1
        ///    e.g CGSize(width: 320, height: -1)
        let scale: CGSize?
    }
```

Configure your configuration, then compress your video:

```swift
let config = FYVideoCompressor.CompressionConfig(videoBitrate: 1000_000,
                                                                                        videomaxKeyFrameInterval: 10,
                                                                                        fps: 24,
                                                                                        audioSampleRate: 44100,
                                                                                        audioBitrate: 128_000,
                                                                                        fileType: .mp4,
                                                                                        scale: CGSize(width: 640, height: 480))
FYVideoCompressor.shared.compressVideo(yourVideoPath, config: config) { result in
            switch result {
            case .success(let compressedVideoURL):
            case .failure(let error):
            }
 }
```
