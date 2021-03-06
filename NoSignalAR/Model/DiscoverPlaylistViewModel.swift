//
//  DiscoverPlaylistViewModel.swift
//  NoSignal
//
//  Created by student9 on 2021/12/22.
//

import Combine

struct PlaylistCatalogue: Identifiable {
    public var id: Int
    public let name: String
    public let subs: [String]
}

extension PlaylistResponse: Identifiable {
    
}

class DiscoverPlaylistViewModel: ObservableObject {
    var cancell = AnyCancellable({})
        
    @Published var requesting = false
    var catalogue: [PlaylistCatalogue]
    @Published var playlists = [PlaylistResponse]()
    
    init(catalogue: [PlaylistCatalogue]) {
        self.catalogue = catalogue
    }
    
    func playlistRequest(cat: String) {
        cancell = NeteaseCloudMusicApi
            .shared
            .requestPublisher(action: PlaylistListAction(parameters: .init(cat: cat, order: .hot, limit: 30, offset: 0 * 30, total: true)))
            .sink { completion in
                if case .failure(let error) = completion {
                    Store.shared.dispatch(.error(.error(error)))
                }
            } receiveValue: {[weak self] playlistListResponse in
                self?.playlists = playlistListResponse.playlists
            }
    }
}
