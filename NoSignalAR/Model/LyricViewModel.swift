//
//  LyricViewModel.swift
//  NoSignal
//
//  Created by student9 on 2021/12/22.
//

import SwiftUI
import Combine

class LyricViewModel: ObservableObject {
    let lyricParser: LyricParser
    private var cancell: Cancellable = AnyCancellable({})

    @Published var index: Int = 0
    @Published var lyric: String = ""
    
    init(lyric: String) {
        self.lyricParser = LyricParser(lyric)
    }
    
    func setTimer(every: Double, offset: Double = 0.0) {
        if lyricParser.lyrics.count > 1 {
            cancell = Timer.publish(every: every, on: .main, in: .default)
                .autoconnect()
                .sink(receiveValue: { [weak self] (value) in
                    if let lyricViewModel = self {
                        let result =  lyricViewModel.lyricParser.lyricByTime(Player.shared.currentTime().seconds, offset: offset)
                        if lyricViewModel.lyric != result.0 {
                            lyricViewModel.lyric = result.0
                        }
                        if lyricViewModel.index != result.1 {
                            lyricViewModel.index = result.1
                        }
                    }
                })
        }
    }
    
    func stopTimer() {
        cancell.cancel()
    }
}
