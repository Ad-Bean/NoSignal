//
//  Model.swift
//  NoSignal
//
//  Created by student9 on 2021/11/19.
//

import Foundation
import MediaPlayer
import SwiftUI

// 全局共享环境
class Model: ObservableObject {
    static let shared = Model()
    
    var musicPlayer = MPMusicPlayerController.applicationQueuePlayer
    
    // 用于控制 Apple Music 播放
    @Published var isPlaying = false
    @Published var isPlayerViewPresented = false
    @Published var isARShowing = false
    @Published var currentSong : MPMediaItem?
    @Published var playlists = [MPMediaItemCollection]()
    @Published var librarySons = [MPMediaItem]()
    
    // 全局主题
    @Published var themeColor = Color.indigo
    
    // 模块化功能
    @Published var SearchToggle: Bool = true
    @Published var PlaylistToggle: Bool = true
    @Published var LibraryToggle: Bool = true
    @Published var ARToggle: Bool = true
    
// 这种做法不好，维护一个数组虽然写法看上去简洁，但难以维护
//    @Published var views = [
//        TabItem(tag: 1, title: Text("Playlist"), image: Image(systemName: "music.note.list"),view: AnyView(PlaylistView())),
//        TabItem(tag: 2, title: Text("Library"), image: Image(systemName: "music.note"), view: AnyView(LibraryView())),
////        TabItem(tag: 2, title: Text("Search"), image: Image(systemName: "magnifyingglass"), view: AnyView(SearchView()))
//        TabItem(tag: 3, title: Text("User"), image: Image(systemName: "person.fill"), view: AnyView(UserView())),
//    ]
    

}

//struct TabItem: Identifiable {
//    var id = UUID()
//    var tag: Int
//    var title: Text
//    var image: Image
//    var view: AnyView = AnyView(PlaylistView())
//}

