//
//  LyricView.swift
//  NoSignal
//
//  Created by student9 on 2021/12/24.
//

import SwiftUI

struct LyricView: View {
    @ObservedObject private var viewModel: LyricViewModel
    @State private var highlightId: Int = 0
    private let onelineMode: Bool

    init(_ viewModel: LyricViewModel, onelineMode: Bool = false) {
        self.viewModel = viewModel
        self.onelineMode = onelineMode
    }
    
    var body: some View {
        VStack {
            if onelineMode {
                Text(viewModel.lyric)
                    .fontWeight(.bold)
                    .lineLimit(1)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        ForEach(0..<viewModel.lyricParser.lyrics.count, id: \.self) { index in
                            Text(viewModel.lyricParser.lyrics[index])
                                .fontWeight(index == highlightId ? .bold : .none)
                                .foregroundColor(index == highlightId ? .accentColor : .secondary)
                                .multilineTextAlignment(.center)
                                .id(index)
                        }
                    }
                    .onReceive(viewModel.$index, perform: { value in
                        highlightId = value
                        withAnimation(.easeInOut) {
                            proxy.scrollTo(value, anchor: .center)
                        }
                    })
                }
                .padding(.horizontal)
            }
        }
    }
}
