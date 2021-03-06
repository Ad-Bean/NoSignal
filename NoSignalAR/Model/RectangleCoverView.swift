//
//  RectangleCoverView.swift
//  NoSignal
//
//  Created by student9 on 2021/12/22.
//

import SwiftUI
import Kingfisher
import struct Kingfisher.DownsamplingImageProcessor

#if canImport(UIKit)
fileprivate let screenScale: CGFloat = UIScreen.main.scale
#endif
#if canImport(AppKit)
fileprivate let screenScale: CGFloat = 1.0
#endif

struct AnyShape: Shape {
    init<S: Shape>(_ wrapped: S) {
        _path = { rect in
            let path = wrapped.path(in: rect)
            return path
        }
    }

    func path(in rect: CGRect) -> Path {
        return _path(rect)
    }

    private let _path: (CGRect) -> Path
}

enum CoverShape: Int, CaseIterable, Codable {
    case circle, rectangle
    var systemName: String {
        switch self {
        case .circle:
            return "circle"
        case .rectangle:
            return "rectangle"
        }
    }
}

enum CoverSize: Int, CaseIterable, Identifiable {
    var id: Int { rawValue }
    case little
    case small
    case medium
    case large
    
    var size: CGSize {
        switch self {
        case .little:   return CGSize(width: 60, height: 60)
        case .small:    return CGSize(width: 110, height: 110)
        case .medium:   return CGSize(width: 130, height: 130)
        case .large:    return CGSize(width: 300, height: 300)
        }
    }
    
    var width: CGFloat { size.width }
    
    var height: CGFloat { size.height }

    var minLength: CGFloat { min(size.width, size.height) }
    
    var cornerRadius: CGFloat { minLength / 4 }
}

struct CoverStyle {
    var size: CoverSize
    var shape: CoverShape
//    var type: NEUBorderStyle = .unevenness
    
    var cornerRadius: CGFloat { size.cornerRadius }
    var borderWidth: CGFloat {
        switch shape {
        case .circle:       return size.minLength / 25
        case .rectangle:    return size.minLength / 15
        }
    }
}

struct RectangleCoverView: View {
    let urlString: String?
    let style: CoverStyle
    
//    func getshape() -> AnyShape {
//        switch style.shape {
//        case .circle: return AnyShape(Circle())
//        case .rectangle: return AnyShape(RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous))
//        }
//    }

    init(_ urlString: String?, style: CoverStyle) {
        self.urlString = urlString
        self.style = style
    }
    
    var body: some View {
//        let shape: AnyShape = getshape()
        if let urlString = urlString {
            KFImage(URL(string: urlString))
                .placeholder({
                        Image("PlaceholderImage")
                            .resizable()
                            .renderingMode(.original)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: style.size.width, height: style.size.height)
                    }
                )
                .setProcessor(DownsamplingImageProcessor(size: CGSize(width: style.size.width * screenScale, height: style.size.height * screenScale)))
              .fade(duration: 0.25)
              .onProgress { receivedSize, totalSize in  }
              .onSuccess { result in  }
              .onFailure { error in }
              .resizable()
              .renderingMode(.original)
              .aspectRatio(contentMode: .fill)
              .clipShape(RoundedRectangle(cornerRadius: 10))
//              .modifier(NEUBorderModifier(shape: shape, borderWidth: style.borderWidth, style: style.type))
              .frame(width: style.size.width, height: style.size.height)
        } else {
            Image("PlaceholderImage")
                .resizable()
                .renderingMode(.original)
                .aspectRatio(contentMode: .fill)
                .frame(width: style.size.width, height: style.size.height)
                .clipShape(RoundedRectangle(cornerRadius: 10))
//                .modifier(NEUBorderModifier(shape: shape, borderWidth: style.borderWidth, style: style.type))
                .frame(width: style.size.width, height: style.size.height)
        }
    }
}

