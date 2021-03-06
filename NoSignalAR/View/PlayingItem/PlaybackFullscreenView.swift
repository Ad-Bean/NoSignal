//
//  PlaybackFullscreenView.swift
//  NoSignal
//
//  Created by student9 on 2021/11/19.
//

import SwiftUI

struct PlaybackFullscreenView: View {
    
    var animation: Namespace.ID
    
    enum heartImage: String {
        case fill = "heart.fill"
        case notFill = "heart"
        
        func next() -> heartImage {
            switch self {
            case .fill:
                return .notFill
            case .notFill:
                return .fill
            }
        }
    }
    
    
    @State private var fadeOut = false
    @State private var img = heartImage.notFill
    
    @EnvironmentObject var model: Model
    
    
    var body: some View {
        if let currentSong = model.currentSong {
            let artwork = currentSong.artwork?.image(at: CGSize(width: 800, height: 800)) ??
                UIImage(named: "music_background") ??
                UIImage()
             
            HStack {
                VStack {
                    Spacer(minLength: 0)
                    Image(uiImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding()
                        .scaleEffect(model.isPlaying ? 1.0 : 0.8)
                        .matchedGeometryEffect(id: (currentSong.title ?? "") + "art", in: animation)
                        .shadow(color: Color.black.opacity(model.isPlaying ? 0.2 : 0.0), radius: 30, x: 0, y: 60)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text(currentSong.title ?? "")
                                .font(Font.system(.title2).bold())
                        
                            Text(currentSong.artist ?? "")
                                .font(Font.system(.title3).bold())
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 20)
                        
                        Spacer()
                        
                        HStack {
                            Image(systemName: img.rawValue)
                                .font(.largeTitle)
                                .font(.system(size: 26))
                                .opacity(fadeOut ? 0 : 1)
                                .onTapGesture {
                                    self.fadeOut.toggle()
                                    DispatchQueue.main.asyncAfter(deadline:.now() + 0.05) {
                                        withAnimation {
                                            self.fadeOut.toggle()
                                            self.img = self.img.next()
                                        }
                                    }
                                }
                    
                            
                            NavigationLink(destination: EmptyView(), isActive: $model.isARShowing, label: {EmptyView()})
                            Button(action: {
                                model.isARShowing.toggle()
                            }){
                                Image("concert")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 40, height: 40)
                                    .font(.largeTitle)
                                    .font(.system(size: 30))
                            }
//                            Image("lyrics")
//                                .resizable()
//                                .aspectRatio(contentMode: .fit)
//                                .frame(width: 40, height: 40)
//                                .font(.largeTitle)
//                                .font(.system(size: 30))

                        }
                        .padding(.trailing, 20)
                    }
                    .matchedGeometryEffect(id: (currentSong.title ?? "") + "details", in: animation)
                    .padding(.top, 45)
                    .padding(.bottom, 20)
                    
                    Spacer(minLength: 0)
 
                    PlayingProgressView()
                        .padding(.horizontal)
                    
                    Spacer(minLength: 0)
                    
                    HStack {
                        Image(systemName: "gobackward.15")
                            .font(.largeTitle)
                            .font(.system(size: 40))
                            .onTapGesture {
                                model.musicPlayer.currentPlaybackTime -= 15
                            }
                        
                        PlayPauseButton()
                            .environmentObject(model)
                            .matchedGeometryEffect(id: (currentSong.title ?? "") + "play_button", in: animation)
                            .font(.system(size: 50))
                            .padding()
                            .padding(.horizontal)
                        
                        Image(systemName: "goforward.15")
                            .font(.largeTitle)
                            .font(.system(size: 40))
                            .onTapGesture {
                                model.musicPlayer.currentPlaybackTime += 15
                            }


                    }
                    .foregroundColor(.white)
                    Spacer(minLength: 0)
                }
            }
            .background(
                Rectangle()
                    .foregroundColor(Color(artwork.averageColor ?? .clear))
                    .saturation(0.5)
            )
            .matchedGeometryEffect(id: (currentSong.title ?? "") + "frame", in: animation)
            .edgesIgnoringSafeArea(.all)
            .accentColor(Color(artwork.averageColor ?? .systemPink))
        }
    }
}

extension UIImage {
    var averageColor: UIColor? {
        // guard let == if let
        guard let inputImage = CIImage(image: self) else { return nil }
        
        let extentVector = CIVector(x: inputImage.extent.origin.x,
                                    y: inputImage.extent.origin.y,
                                    z: inputImage.extent.size.width,
                                    w: inputImage.extent.size.height)
        
        guard let filter = CIFilter(name: "CIAreaAverage",
                                     parameters: [kCIInputImageKey: inputImage,
                                                 kCIInputExtentKey:extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull!])
        
        context.render(outputImage,
                       toBitmap: &bitmap,
                       rowBytes: 4,
                       bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                       format: .RGBA8,
                       colorSpace: nil
        )
        
        return UIColor(red: CGFloat(bitmap[0])   * 0.6 / 255,
                       green: CGFloat(bitmap[1]) * 0.6 / 255,
                       blue: CGFloat(bitmap[2])  * 0.6 / 255,
                       alpha: CGFloat(bitmap[3])  / 255)

    }
    
    var originalColor: UIColor? {
        // guard let == if let
        guard let inputImage = CIImage(image: self) else { return nil }
        
        let extentVector = CIVector(x: inputImage.extent.origin.x,
                                    y: inputImage.extent.origin.y,
                                    z: inputImage.extent.size.width,
                                    w: inputImage.extent.size.height)
        
        guard let filter = CIFilter(name: "CIAreaAverage",
                                     parameters: [kCIInputImageKey: inputImage,
                                                 kCIInputExtentKey:extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull!])
        
        context.render(outputImage,
                       toBitmap: &bitmap,
                       rowBytes: 4,
                       bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                       format: .RGBA8,
                       colorSpace: nil
        )
        
        return UIColor(red: CGFloat(bitmap[0])   / 255,
                       green: CGFloat(bitmap[1]) / 255,
                       blue: CGFloat(bitmap[2])  / 255,
                       alpha: CGFloat(bitmap[3]) / 255)
    }
}
