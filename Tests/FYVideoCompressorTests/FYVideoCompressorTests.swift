import XCTest
@testable import FYVideoCompressor
import AVFoundation

final class FYVideoCompressorTests: XCTestCase {
    static let testVideoURL = URL(string: "http://clips.vorwaerts-gmbh.de/VfE_html5.mp4")! // video size 5.3M
    
    let sampleVideoPath: URL = try! FileManager.tempDirectory(with: "UnitTestSampleVideo").appendingPathComponent("sample.mp4")
    var compressedVideoPath: URL?
    
    var task: URLSessionDataTask?
    
    override func setUpWithError() throws {
        let expectation = XCTestExpectation(description: "video cache downloading remote video")
        var error: Error?
        downloadSampleVideo { result in
            switch result {
            case .failure(let _error):
                print("failed to download sample video: \(_error)")
                error = _error
            case .success(let path):
                print("sample video downloaded at path: \(path)")
                expectation.fulfill()
            }
        }
        if let error = error {
            throw error
        }
        wait(for: [expectation], timeout: 100)
    }
    
    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: sampleVideoPath)
        if let compressedVideoPath = compressedVideoPath {
            try FileManager.default.removeItem(at: compressedVideoPath)
        }
    }
    
    func testAVFileTypeExtension() {
        let mp4Extension = AVFileType("public.mpeg-4")
        XCTAssertEqual(mp4Extension.fileExtension, "mp4")
        
        let movExtension = AVFileType("com.apple.quicktime-movie")
        XCTAssertEqual(movExtension.fileExtension, "mov")
    }
    
    func testGetRandomFramesIndexesCount() {
        let arr = FYVideoCompressor.shared.getFrameIndexesWith(originalFPS: 50, targetFPS: 30, duration: 10)
        XCTAssertEqual(arr.count, 300)
    }
    
    func testCompressVideo() {
        let expectation = XCTestExpectation(description: "compress video")
                        
        FYVideoCompressor.shared.compressVideo(sampleVideoPath, quality: .lowQuality) { result in
            switch result {
            case .success(let video):
                self.compressedVideoPath = video
                expectation.fulfill()
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        wait(for: [expectation], timeout: 30)
        XCTAssertNotNil(compressedVideoPath)
        XCTAssertTrue(self.sampleVideoPath.sizePerMB() > compressedVideoPath!.sizePerMB())
    }
    
    func testTargetVideoSizeWithQuality() {
        let targetSize = FYVideoCompressor.shared.calculateSizeWithQuality(.lowQuality, originalSize: CGSize(width: 1920, height: 1080))
        XCTAssertEqual(targetSize, CGSize(width: 398, height: 224))
    }
    
    func testTargetVideoSizeWithConfig() {
        let scale1 = FYVideoCompressor.shared.calculateSizeWithScale(CGSize(width: -1, height: 224), originalSize: CGSize(width: 1920, height: 1080))
        XCTAssertEqual(scale1, CGSize(width: 398, height: 224))
        
        let scale2 = FYVideoCompressor.shared.calculateSizeWithScale(CGSize(width: 640, height: -1), originalSize: CGSize(width: 1920, height: 1080))
        XCTAssertEqual(scale2, CGSize(width: 640, height: 360))
    }
    
    // MARK: Download sample video
    func downloadSampleVideo(_ completion: @escaping ((Result<URL, Error>) -> Void)) {
        if FileManager.default.fileExists(atPath: self.sampleVideoPath.absoluteString) {
            completion(.success(self.sampleVideoPath))
        } else {
            request(Self.testVideoURL) { result in
                switch result {
                case .success(let data):
                    do {
                        try (data as NSData).write(to: self.sampleVideoPath, options: NSData.WritingOptions.atomic)
                        completion(.success(self.sampleVideoPath))
                    } catch {
                        completion(.failure(error))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    func request(_ url: URL, completion: @escaping ((Result<Data, Error>) -> Void)) {
        if task != nil {
            task?.cancel()
        }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                self.task = nil
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                self.task = nil
                return
            }

            if (200...299).contains(httpResponse.statusCode) {
                if let data = data {
                    DispatchQueue.main.async {
                        self.task = nil
                        completion(.success(data))
                    }
                }
            } else {
                let domain = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                let error = NSError(domain: domain, code: httpResponse.statusCode, userInfo: nil)
                DispatchQueue.main.async {
                    self.task = nil
                    completion(.failure(error))
                }
            }
        }
        task.resume()
        self.task = task
    }
}
