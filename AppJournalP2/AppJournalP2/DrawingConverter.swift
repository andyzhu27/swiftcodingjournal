import UIKit
import CoreML

func renderDrawingToImage(lines: [[CGPoint]], canvasSize: CGSize = CGSize(width: 300, height: 300)) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: canvasSize)
    return renderer.image { ctx in
        ctx.cgContext.setLineWidth(12)
        ctx.cgContext.setStrokeColor(UIColor.black.cgColor)

        for line in lines {
            guard let firstPoint = line.first else { continue }
            ctx.cgContext.move(to: firstPoint)
            for point in line.dropFirst() {
                ctx.cgContext.addLine(to: point)
            }
        }
        ctx.cgContext.strokePath()
    }
}

func imageToCVPixelBuffer(_ image: UIImage, size: CGSize = CGSize(width: 28, height: 28)) -> CVPixelBuffer? {
    UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
    image.draw(in: CGRect(origin: .zero, size: size))
    let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    guard let cgImage = resizedImage?.cgImage else { return nil }

    let attrs = [
        kCVPixelBufferCGImageCompatibilityKey: true,
        kCVPixelBufferCGBitmapContextCompatibilityKey: true
    ] as CFDictionary
    var pixelBuffer: CVPixelBuffer?

    let width = Int(size.width)
    let height = Int(size.height)

    CVPixelBufferCreate(kCFAllocatorDefault, width, height,
                        kCVPixelFormatType_OneComponent8, attrs,
                        &pixelBuffer)

    guard let buffer = pixelBuffer else { return nil }

    CVPixelBufferLockBaseAddress(buffer, .readOnly)
    let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer),
                            width: width,
                            height: height,
                            bitsPerComponent: 8,
                            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                            space: CGColorSpaceCreateDeviceGray(),
                            bitmapInfo: CGImageAlphaInfo.none.rawValue)

    context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
    CVPixelBufferUnlockBaseAddress(buffer, .readOnly)

    return buffer
}
