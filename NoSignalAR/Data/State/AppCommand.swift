//
//  AppCommand.swift
//  NoSignal
//
//  Created by student9 on 2021/12/18.
//

import Foundation
import CoreData
import Combine
import MediaPlayer
import Kingfisher
import struct CoreGraphics.CGSize

protocol AppCommand {
    func execute(in store: Store)
}

struct InitAcionCommand: AppCommand {
    func execute(in store: Store) {
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime).sink { (Notification) in
            print("end play")
            store.dispatch(.PlayerPlayToendAction)
        }.store(in: &store.cancellableSet)
        store.dispatch(.InitMPRemoteControl)
        store.appState.initRequestingCount += 1
        store.dispatch(.albumSublistRequest())
        
        store.appState.initRequestingCount += 1
        store.dispatch(.artistSublistRequest())
        
        store.appState.initRequestingCount += 1
        store.dispatch(.songLikeListRequest())
        
        store.appState.initRequestingCount += 1
        store.dispatch(.playlistCatalogueRequest)
        
        store.appState.initRequestingCount += 1
        store.dispatch(.recommendPlaylistRequest)
        
        store.appState.initRequestingCount += 1
        store.dispatch(.recommendSongsRequest)
        
        store.appState.initRequestingCount += 1
        store.dispatch(.userPlaylistRequest())
    }
}

struct InitMPRemoteControlCommand: AppCommand {
    func execute(in store: Store) {
        let commandCenter = MPRemoteCommandCenter.shared()
    //耳机线控制无效
    //        commandCenter.playCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
    //            Store.shared.dispatch(.playerPlay)
    //            return .success
    //        }
    //        commandCenter.pauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
    //            Store.shared.dispatch(.playerPause)
    //            return .success
    //        }
        //耳机线控制
        commandCenter.togglePlayPauseCommand.addTarget{ (event) -> MPRemoteCommandHandlerStatus in
            guard let song = store.appState.playing.song else {
                return .noSuchContent
            }
            
            Store.shared.dispatch(.playerTogglePlay(song: song))
            return .success
        }
        commandCenter.nextTrackCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            Store.shared.dispatch(.playerPlayForward)
            return .success
        }
        commandCenter.previousTrackCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            Store.shared.dispatch(.playerPlayBackward)
            return .success
        }
        UIApplication.shared.beginReceivingRemoteControlEvents()

    }
}

struct AlbumDetailRequestCommand: AppCommand {
    let id: Int
    
    func execute(in store: Store) {
        NeteaseCloudMusicApi
            .shared
            .requestPublisher(action: AlbumDetailAction(id: id))
            .sink { completion in
                if case .failure(let error) = completion {
                    store.dispatch(.albumDetailRequestDone(result: .failure(.error(error))))
                }
            } receiveValue: { albumDetailResponse in
                guard albumDetailResponse.isSuccess else {
                    store.dispatch(.albumDetailRequestDone(result: .failure(AppError.albumDetailRequest)))
                    return
                }
                DataManager.shared.updateAlbum(model: albumDetailResponse)
                store.dispatch(.albumDetailRequestDone(result: .success(albumDetailResponse.songs.map({ $0.id }))))
            }.store(in: &store.cancellableSet)
    }
}

struct AlbumSubRequestCommand: AppCommand {
    let id: Int
    let sub: Bool
    
    func execute(in store: Store) {
        NeteaseCloudMusicApi
            .shared
            .requestPublisher(action: AlbumSubAction(parameters: .init(id: id), sub: sub))
            .sink { completion in
                if case .failure(let error) = completion {
                    store.dispatch(.albumSubRequestDone(result: .failure(.error(error))))
                }
            } receiveValue: { albumSubResponse in
                guard albumSubResponse.isSuccess else {
                    store.dispatch(.albumSubRequestDone(result: .failure(AppError.albumSubRequest)))
                    return
                }
                store.dispatch(.albumSubRequestDone(result: .success(sub)))
            }.store(in: &store.cancellableSet)
    }
}

struct AlbumSubRequestDoneCommand: AppCommand {
    func execute(in store: Store) {
        store.dispatch(.albumSublistRequest())
    }
}

struct AlbumSublistRequestCommand: AppCommand {
    let limit: Int
    let offset: Int
    
    func execute(in store: Store) {
        NeteaseCloudMusicApi
            .shared
            .requestPublisher(action: AlbumSublistAction(parameters: .init(limit: limit, offset: limit * offset)))
            .sink { completion in
                if case .failure(let error) = completion {
                    store.dispatch(.albumSublistRequestDone(result: .failure(.error(error))))
                }
            } receiveValue: { albumSublistResponse in
                guard albumSublistResponse.isSuccess else {
                    store.dispatch(.albumSublistRequestDone(result: .failure(AppError.albumSublistRequest)))
                    return
                }
                store.dispatch(.albumSublistRequestDone(result: .success(albumSublistResponse)))
            }.store(in: &store.cancellableSet)
    }
}

struct ArtistAlbumsRequestCommand: AppCommand {
    let id: Int
    let limit: Int
    let offset: Int
    
    func execute(in store: Store) {
        NeteaseCloudMusicApi
            .shared
            .requestPublisher(action: ArtistAlbumsAction(id: id, parameters: .init(limit: limit, offset: offset * limit)))
            .sink { completion in
                if case .failure(let error) = completion {
                    store.dispatch(.albumSublistRequestDone(result: .failure(.error(error))))
                }
            } receiveValue: { artistAlbumResponse in
                guard artistAlbumResponse.isSuccess else {
                    store.dispatch(.albumSublistRequestDone(result: .failure(AppError.artistAlbumsRequest)))
                    return
                }
                DataManager.shared.updateArtistAlbums(id: id, model: artistAlbumResponse)
                store.dispatch(.artistAlbumsRequestDone(result: .success(artistAlbumResponse.hotAlbums.map({ $0.id }))))
            }.store(in: &store.cancellableSet)
    }
}

struct ArtistDetailRequestCommand: AppCommand {
    let id: Int
    
    func execute(in store: Store) {
        let artistHotSongsPublisher =  NeteaseCloudMusicApi.shared.requestPublisher(action: ArtistHotSongsAction(id: id))
        let artistIntroductionPublisher = NeteaseCloudMusicApi.shared.requestPublisher(action: ArtistIntroductionAction(parameters: .init(id: id)))
        let artistInfoPublisher = Publishers.CombineLatest(artistHotSongsPublisher, artistIntroductionPublisher)
        artistInfoPublisher
            .sink { completion in
                if case .failure(let error) = completion {
                    store.dispatch(.artistDetailRequestDone(result: .failure(.error(error))))
                }
            } receiveValue: { artistHotSongsResponse, artistIntroductionResponse in
                guard artistHotSongsResponse.isSuccess else {
                    store.dispatch(.artistDetailRequestDone(result: .failure(AppError.artistDetailRequest)))
                    return
                }
                let introduction = artistIntroductionResponse.desc
                DataManager.shared.updateArtist(artistModel: artistHotSongsResponse.artist, introduction: introduction)
                DataManager.shared.updateSongs(model: artistHotSongsResponse)
                DataManager.shared.updateArtistHotSongs(to: id, songsId: artistHotSongsResponse.hotSongs.map({ $0.id }))
                store.dispatch(.artistDetailRequestDone(result: .success(artistHotSongsResponse.hotSongs.map({ $0.id }))))
            }.store(in: &store.cancellableSet)
    }
}

struct ArtistMVsRequestCommand: AppCommand {
    let id: Int
    let limit: Int
    let offset: Int
    let total: Bool
    
    func execute(in store: Store) {
        NeteaseCloudMusicApi
            .shared
            .requestPublisher(action: ArtistMVAction(parameters: .init(artistId: id, limit: limit, offset: offset * limit, total: total)))
            .sink { completion in
                if case .failure(let error) = completion {
                    store.dispatch(.artistMVsRequestDone(result: .failure(.error(error))))
                }
            } receiveValue: { artistMVResponse in
                guard artistMVResponse.isSuccess else {
                    store.dispatch(.artistMVsRequestDone(result: .failure(AppError.artistMVsRequest)))
                    return
                }
                DataManager.shared.updateMV(model: artistMVResponse)
                store.dispatch(.artistMVsRequestDone(result: .success(artistMVResponse)))
            }.store(in: &store.cancellableSet)
    }
}

struct ArtistSubRequestCommand: AppCommand {
    let id: Int
    let sub: Bool
    
    func execute(in store: Store) {
        NeteaseCloudMusicApi
            .shared
            .requestPublisher(action: ArtistSubAction(sub: sub, parameters: .init(artistId: id, artistIds: [id])))
            .sink { completion in
                if case .failure(let error) = completion {
                    store.dispatch(.artistSubRequestDone(result: .failure(.error(error))))
                }
            } receiveValue: { artistSubResponse in
                guard artistSubResponse.isSuccess else {
                    store.dispatch(.artistSubRequestDone(result: .failure(AppError.artistSubRequest)))
                    return
                }
                store.dispatch(.artistSubRequestDone(result: .success(sub)))
            }.store(in: &store.cancellableSet)
    }
}

struct ArtistSubRequestDoneCommand: AppCommand {
    
    func execute(in store: Store) {
        store.dispatch(.artistSublistRequest())
    }
}

struct ArtistSublistRequestCommand: AppCommand {
    let limit: Int
    let offset: Int
    
    init(limit: Int, offset: Int = 0) {
        self.limit = limit
        self.offset = offset
    }
    
    func execute(in store: Store) {
        NeteaseCloudMusicApi.shared.requestPublisher(action: ArtistSublistAction(parameters: .init(limit: limit, offset: offset)))
            .sink { completion in
                if case .failure(let error) = completion {
                    store.dispatch(.artistSublistRequestDone(result: .failure(.error(error))))
                }
            } receiveValue: { artistSublistResponse in
                guard artistSublistResponse.isSuccess else {
                    store.dispatch(.artistSublistRequestDone(result: .failure(AppError.artistSublistRequest)))
                    return
                }
                store.dispatch(.artistSublistRequestDone(result: .success(artistSublistResponse)))
            }.store(in: &store.cancellableSet)
    }
}

struct CloudUploadCommand: AppCommand {
    let token: CloudUploadTokenResponse.Result
    let fileSize: Int
    let md5: String
    let data: Data
    func execute(in store: Store) {
        NeteaseCloudMusicApi.shared.uploadPublisher(action: CloudUploadAction(objectKey: token.objectKey, token: token.token, md5: md5, size: fileSize, data: data))
            .sink { completion in
                if case .failure(let error) = completion {
                    store.dispatch(.artistSublistRequestDone(result: .failure(.error(error))))
                }
            } receiveValue: { response in
                print(response)
                guard response.isSuccess else {
//                    store.dispatch(.artistSublistRequestDone(result: .failure(AppError.artistSublistRequest)))
                    return
                }
//                store.dispatch(.artistSublistRequestDone(result: .success(artistSublistResponse)))
            }.store(in: &store.cancellableSet)
    }
}

struct CloudSongAddRequstCommand: AppCommand {
    let id: Int
    
    func execute(in store: Store) {
        NeteaseCloudMusicApi.shared.requestPublisher(action: CloudSongAddAction(parameters: .init(songid: id)))
            .sink { completion in
                if case .failure(let error) = completion {
                    store.dispatch(.cloudSongAddRequstDone(result: .failure(.error(error))))
                }
            } receiveValue: { response in
                guard response.isSuccess else {
                    store.dispatch(.cloudSongAddRequstDone(result: .failure(AppError.cloudSongAddRequest)))
                    return
                }
                store.dispatch(.cloudSongAddRequstDone(result: .success(response)))
            }.store(in: &store.cancellableSet)
    }
}

struct CloudUploadCheckRequestCommand: AppCommand {
    let fileURL: URL
    
    func execute(in store: Store) {
        guard let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize, let md5 = try? Data(contentsOf: fileURL).md5().toHexString() else {
            return
        }
        NeteaseCloudMusicApi.shared.requestPublisher(action: CloudUploadCheckAction(parameters: .init(length: fileSize, md5: md5)))
            .sink { completion in
                if case .failure(let error) = completion {
                    store.dispatch(.cloudUploadCheckRequestDone(result: .failure(.error(error))))
                }
            } receiveValue: { response in
                guard response.isSuccess else {
                    store.dispatch(.cloudUploadCheckRequestDone(result: .failure(AppError.cloudUploadCheckRequest)))
                    return
                }
                store.dispatch(.cloudUploadCheckRequestDone(result: .success((response: response, md5: md5))))
            }.store(in: &store.cancellableSet)
    }
}

struct CloudUploadCheckRequestDoneCommand: AppCommand {
    let fileURL: URL
    let md5: String
    
    func execute(in store: Store) {
        store.dispatch(.cloudUploadTokenRequest(fileURL: fileURL, md5: md5))
    }
}

struct CloudUploadInfoRequestCommand: AppCommand {
    let info: CloudUploadInfoAction.CloudUploadInfoParameters
    
    func execute(in store: Store) {
        NeteaseCloudMusicApi.shared.requestPublisher(action: CloudUploadInfoAction(parameters: info))
            .sink { completion in
                if case .failure(let error) = completion {
                    store.dispatch(.cloudUploadInfoRequestDone(result: .failure(.error(error))))
                }
            } receiveValue: { response in
                print(response)
                guard response.isSuccess else {
                    store.dispatch(.cloudUploadInfoRequestDone(result: .failure(AppError.cloudUploadInfoRequest)))
                    return
                }
                store.dispatch(.cloudUploadInfoRequestDone(result: .success(response)))
            }.store(in: &store.cancellableSet)
    }
}

struct CloudUploadInfoRequestDoneCommand: AppCommand {
    let info: CloudUploadInfoAction.Response
    
    func execute(in store: Store) {
        store.dispatch(.cloudSongAddRequst(songId: Int(info.songId)!))
    }
}

struct CloudUploadTokenRequestCommand: AppCommand {
    let fileURL: URL
    let md5: String
    
    func execute(in store: Store) {
        NeteaseCloudMusicApi.shared.requestPublisher(action: CloudUploadTokenAction(parameters: .init(filename: fileURL.fileNameWithoutExtension ?? "", md5: md5)))
            .sink { completion in
                if case .failure(let error) = completion {
                    store.dispatch(.cloudUploadTokenRequestDone(result: .failure(.error(error))))
                }
            } receiveValue: { response in
                guard response.isSuccess else {
                    store.dispatch(.cloudUploadTokenRequestDone(result: .failure(AppError.cloudUploadTokenRequest)))
                    return
                }
                store.dispatch(.cloudUploadTokenRequestDone(result: .success(response.result)))
            }.store(in: &store.cancellableSet)
    }
}

struct CloudUploadTokenDoneCommand: AppCommand {
    let fileURL: URL
    let token: CloudUploadTokenResponse.Result
    let md5: String

    func execute(in store: Store) {
        guard let fileName = fileURL.fileName else { return }
        guard let songName = fileURL.fileNameWithoutExtension else { return }
        guard let size = fileURL.fileSize else { return }
        guard let data = try? Data(contentsOf: fileURL) else { return }
        store.dispatch(.cloudUploadSongRequest(token: token, md5: md5, size: size, data: data))
        store.dispatch(.cloudUploadInfoRequest(.init(filename: fileName, md5: md5, resourceId: token.resourceId, song: songName, songid: store.appState.cloud.songId)))
    }
}

struct CommentRequestCommand: AppCommand {
    let id: Int
    let commentId: Int?
    let content: String?
    let type: CommentType
    let action: CommentAction
    
    func execute(in store: Store) {
        if let content = content, action == .add {
            NeteaseCloudMusicApi.shared.requestPublisher(action: CommentAddAction(parameters: .init(threadId: id, content: content, type: type)))
                .sink { completion in
                    if case .failure(let error) = completion {
                        store.dispatch(.commentDoneRequest(result: .failure(.error(error))))
                    }
                } receiveValue: { commentAddResponse in
                    guard commentAddResponse.isSuccess else {
                        store.dispatch(.commentDoneRequest(result: .failure(AppError.comment)))
                        return
                    }
                    let result = (id: id, type: type, action: action)
                    store.dispatch(.commentDoneRequest(result: .success(result)))
                }.store(in: &store.cancellableSet)
        }
        if let commentId = commentId, action == .delete {
            NeteaseCloudMusicApi.shared.requestPublisher(action: CommentDeleteAction(parameters: .init(threadId: id, commentId: commentId, type: type)))
                .sink { completion in
                    if case .failure(let error) = completion {
                        store.dispatch(.commentDoneRequest(result: .failure(.error(error))))
                    }
                } receiveValue: { commentDeleteResponse in
                    guard commentDeleteResponse.isSuccess else {
                        store.dispatch(.commentDoneRequest(result: .failure(AppError.comment)))
                        return
                    }
                    let result = (id: id, type: type, action: action)
                    store.dispatch(.commentDoneRequest(result: .success(result)))
                }.store(in: &store.cancellableSet)
        }
    }
}

struct CommentRequestDoneCommand: AppCommand {
    let id: Int
    let type: CommentType
    let action: CommentAction
    
    func execute(in store: Store) {
        if type == .song {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                store.dispatch(.commentMusicRequest(rid: id))
            }
        }
    }
}

struct CommentLikeRequestCommand: AppCommand {
    let id: Int
    let cid: Int
    let like: Bool
    let type: CommentType
    
    func execute(in store: Store) {
        NeteaseCloudMusicApi.shared.requestPublisher(action: CommentLikeAction(like: like, parameters: .init(threadId: id, commentId: cid, commentType: type)))
            .sink { completion in
                if case .failure(let error) = completion {
                    store.dispatch(.commentLikeDone(result: .failure(.error(error))))
                }
            } receiveValue: { commentlikeResponse in
                guard commentlikeResponse.isSuccess else {
                    store.dispatch(.commentLikeDone(result: .failure(AppError.commentLikeRequest)))
                    return
                }
                store.dispatch(.commentLikeDone(result: .success(id)))
            }.store(in: &store.cancellableSet)
    }
}

struct CommentMusicRequestCommand: AppCommand {
    let rid: Int
    let limit: Int
    let offset: Int
    let beforeTime: Int
    
    func execute(in store: Store) {
        NeteaseCloudMusicApi.shared.requestPublisher(action: CommentSongAction(rid: rid, parameters: .init(rid: rid, limit: limit, offset: limit * offset, beforeTime: beforeTime)))
            .sink { completion in
                if case .failure(let error) = completion {
                    store.dispatch(.commentMusicRequestDone(result: .failure(.error(error))))
                }
            } receiveValue: { commentSongResponse in
                guard commentSongResponse.isSuccess else {
                    store.dispatch(.commentMusicRequestDone(result: .failure(AppError.commentMusic)))
                    return
                }
                store.dispatch(.commentMusicRequestDone(result: .success(commentSongResponse)))
            }.store(in: &store.cancellableSet)
    }
}

struct LoginRequestCommand: AppCommand {
    let email: String
    let password: String
    
    func execute(in store: Store) {
        NeteaseCloudMusicApi
            .shared
            .requestPublisher(action: LoginAction(parameters: .init(email: email, password: password)))
            .sink { completion in
                if case .failure(let error) = completion {
                    store.dispatch(.loginRequestDone(result: .failure(.error(error))))
                }
            } receiveValue: { loginResponse in
                guard loginResponse.isSuccess else {
                    store.dispatch(.loginRequestDone(result: .failure(AppError.loginRequest)))
                    return
                }
                store.dispatch(.loginRequestDone(result: .success(loginResponse)))
            }.store(in: &store.cancellableSet)
    }
}

struct LoginRequestDoneCommand: AppCommand {
    let user: User
    
    func execute(in store: Store) {
        store.dispatch(.initAction)
    }
}

struct LoginRefreshRequestCommand: AppCommand {
    
    func execute(in store: Store) {
        NeteaseCloudMusicApi
            .shared
            .requestPublisher(action: LoginRefreshAction())
            .sink { completion in
                if case .failure(let error) = completion {
                    store.dispatch(.loginRefreshRequestDone(result: .failure(.error(error))))
                }
            } receiveValue: { loginRefreshResponse in
//                guard loginRefreshResponse.isSuccess else {
//                    store.dispatch(.loginRefreshRequestDone(result: .failure(AppError.loginRefreshRequest)))
//                    return
//                }
                store.dispatch(.loginRefreshRequestDone(result: .success(loginRefreshResponse.isSuccess)))
            }.store(in: &store.cancellableSet)
    }
}

struct LoginRefreshDoneCommand: AppCommand {
    let success: Bool
    
    func execute(in store: Store) {
        #if os(iOS)
        if success {
            store.dispatch(.initAction)
        }else {
            store.dispatch(.logoutRequest)
        }
        #endif
    }
}

struct LogoutRequestCommand: AppCommand {
    func execute(in store: Store) {
        NeteaseCloudMusicApi
            .shared
            .requestPublisher(action: LogoutAction())
            .sink { completion in
                if case .failure(let error) = completion {
                    store.dispatch(.logoutRequestDone(result: .failure(.error(error))))
                }
            } receiveValue: { logoutResponse in
                guard logoutResponse.isSuccess else {
                    store.dispatch(.logoutRequestDone(result: .failure(AppError.logoutRequest)))
                    return
                }
                store.dispatch(.logoutRequestDone(result: .success(logoutResponse.code)))
            }.store(in: &store.cancellableSet)
    }
}

struct MVDetailRequestCommand: AppCommand {
    let id: Int
    
    func execute(in store: Store) {
        NeteaseCloudMusicApi
            .shared
            .requestPublisher(action: LogoutAction())
            .sink { completion in
                if case .failure(let error) = completion {
                    store.dispatch(.mvDetaillRequestDone(result: .failure(.error(error))))
                }
            } receiveValue: { response in
                guard response.isSuccess else {
                    store.dispatch(.mvDetaillRequestDone(result: .failure(AppError.mvDetailRequest)))
                    return
                }
                store.dispatch(.mvDetaillRequestDone(result: .success(id)))
            }.store(in: &store.cancellableSet)
    }
}

struct MVUrlCommand: AppCommand {
    let id: Int
    
    func execute(in store: Store) {
        //        NeteaseCloudMusicApi
        //            .shared
        //            .requestPublisher(action: MVURLAction(parameters: .init(id: Int(mv.id))))
        //            .sink { completion in
        //                if case .failure(let error) = completion {
        //                    Store.shared.dispatch(.error(AppError.neteaseCloudMusic(error: error)))
        //                }
        //            } receiveValue: { mvURLResponse in
        ////                store.dispatch(.mvDetaillRequestDone(result: .success(id)))
        //                mvURL = URL(string: mvURLResponse.data.url)
        //                showPlayer = true
        //            }.store(in: &Store.shared.cancellableSet)
    }
}

struct PlayerPlayBackwardCommand: AppCommand {
    
    func execute(in store: Store) {
        let count = store.appState.playing.playinglist.count
        
        if count > 1 {
            var index = store.appState.playing.index
            if index == 0 {
                index = count - 1
            }else {
                index = (index - 1) % count
            }
            store.dispatch(.playerPlayBy(index: index))
        }else if count == 1 {
            store.dispatch(.playerReplay)
        }else {
            return
        }
    }
}

struct PlayerPlayForwardCommand: AppCommand {
    
    func execute(in store: Store) {
        let count = store.appState.playing.playinglist.count
        guard count > 0 else {
            return
        }
        if count > 1 {
            var index = store.appState.playing.index
            index = (index + 1) % count
            store.dispatch(.playerPlayBy(index: index))
        }else if count == 1 {
            store.dispatch(.playerReplay)
        }else {
            return
        }
    }
}

struct NeteaseAppCompand: AppCommand {

    func execute(in store: Store) {
        let playing = store.appState.playing
        guard let song = playing.song else {
            return
        }
        guard playing.songUrl != nil else {
            store.dispatch(.playerPlayRequest(id: song.id))
            return
        }

        Player.shared.play()
    }
}

struct PlayerPlayRequestCommand: AppCommand {
    let id: Int
    
    func execute(in store: Store) {
        if let picUrl =  DataManager.shared.getSong(id: id)?.album?.picUrl {//预先下载播放器专辑图片，避免点击专辑图片动画过渡不自然
            if let url = URL(string: picUrl) {
                let  _ = KingfisherManager.shared.retrieveImage(with: .network(url), options: [.processor(DownsamplingImageProcessor(size: CGSize(width: CoverSize.large.width * 2, height: CoverSize.large.width * 2)))]) { (result) in
                    switch result {
                    case .success(_):
                        break
                    case .failure(_):
                        break
                    }
                }
                let  _ = KingfisherManager.shared.retrieveImage(with: .network(url), options: [.processor(DownsamplingImageProcessor(size: CGSize(width: CoverSize.medium.width * 2, height: CoverSize.medium.width * 2)))]) { (result) in
                    switch result {
                    case .success(_):
                        break
                    case .failure(_):
                        break
                    }
                }
            }
        }
        NeteaseCloudMusicApi
            .shared
            .requestPublisher(action: SongURLAction(parameters: .init(ids: [id])))
            .sink { completion in
                if case .failure(let error) = completion {
                    store.dispatch(.playerPlayRequestDone(result: .failure(.error(error))))
                }
            } receiveValue: { songURLResponse in
                store.dispatch(.playerPlayRequestDone(result: .success(songURLResponse.data.first?.url)))
            }.store(in: &store.cancellableSet)
    }
}

struct PlayerPlayWithUrlCommand: AppCommand {
    let url: String
    
    func execute(in store: Store) {

//        print("execute: \(url)")
//        store.dispatch(.songLyricRequest(id: Int(songId)))
        guard let url = URL(string: url) else {
            return
        }
        Player.shared.playWithURL(url: url)
    }
}

struct PlayerPlayToEndActionCommand: AppCommand {
    
    func execute(in store: Store) {
        switch store.appState.settings.playMode {
        case .playlist:
            store.dispatch(.playerPlayForward)
        case .relplay:
            store.dispatch(.playerReplay)
            break
        }
    }
}

struct PlayerTooglePlayCommand: AppCommand {
    let song: NeteaseSong
    
    func execute(in store: Store) {
        let playing = store.appState.playing
        if song == playing.song {
            if Player.shared.isPlaying {
                store.dispatch(.playerPause)
            } else {
                store.dispatch(.playerPlay)
            }
        } else if let index = playing.playinglist.firstIndex(of: song) {
            store.dispatch(.playerPlayBy(index: index))
        } else {
            store.dispatch(.playinglistInsertAndPlay(songs: [song]))
        }
    }
}

struct PlayinglistInsertCommand: AppCommand {
    let index: Int
    
    func execute(in store: Store) {
        store.dispatch(.playerPlayBy(index: index))
    }
}

struct PlaylistCategoriesRequestCommand: AppCommand {
    func execute(in store: Store) {
        NeteaseCloudMusicApi
            .shared
            .requestPublisher(action: PlaylistCatalogueAction())
            .sink { completion in
                if case .failure(let error) = completion {
                    store.dispatch(.playlistCatalogueRequestsDone(result: .failure(.error(error))))
                }
            } receiveValue: { playlistCatalogueResponse in
                guard playlistCatalogueResponse.isSuccess else {
                    store.dispatch(.playlistCatalogueRequestsDone(result: .failure(AppError.playlistCategoriesRequest)))
                    return
                }
                var playlistCatalogue = [PlaylistCatalogue]()
                
                let keys = playlistCatalogueResponse.categories.keys.sorted(by: { $0 < $1})
                
                keys.forEach { key in
                    let category = PlaylistCatalogue(id: Int(key)!, name: playlistCatalogueResponse.categories[key]!, subs: playlistCatalogueResponse.sub.filter({ Int(key) == $0.category }).map(\.name))
                    playlistCatalogue.append(category)
                }
                
                let all = PlaylistCatalogue(id: playlistCatalogue.count, name: playlistCatalogueResponse.all.name, subs: [])
                playlistCatalogue.append(all)
                
                store.dispatch(.playlistCatalogueRequestsDone(result: .success(playlistCatalogue)))
            }.store(in: &store.cancellableSet)
    }
}

struct PlaylistCreateRequestCommand: AppCommand {
    let name: String
    let privacy: PlaylistCreateAction.Privacy
    
    func execute(in store: Store) {
        NeteaseCloudMusicApi
            .shared
            .requestPublisher(action: PlaylistCreateAction(parameters: .init(name: name, privacy: privacy)))
            .sink { completion in
                if case .failure(let error) = completion {
                    store.dispatch(.playlistCreateRequestDone(result: .failure(.error(error))))
                }
            } receiveValue: { playlistCreateResponse in
                guard playlistCreateResponse.isSuccess else {
                    store.dispatch(.playlistCreateRequestDone(result: .failure(AppError.playlistCreateRequest)))
                    return
                }
                store.dispatch(.playlistCreateRequestDone(result: .success(playlistCreateResponse.playlist.id)))
            }.store(in: &store.cancellableSet)
    }
}

struct PlaylistCreateRequestDoneCommand: AppCommand {
    
    func execute(in store: Store) {
        store.dispatch(.userPlaylistRequest())
    }
}

struct PlaylistDeleteRequestCommand: AppCommand {
    let pid: Int
    
    func execute(in store: Store) {
        NeteaseCloudMusicApi
            .shared
            .requestPublisher(action: PlaylistDeleteAction(parameters: .init(pid: pid)))
            .sink { completion in
                if case .failure(let error) = completion {
                    store.dispatch(.playlistDeleteRequestDone(result: .failure(.error(error))))
                }
            } receiveValue: { playlistDeleteResponse in
                store.dispatch(.playlistDeleteRequestDone(result: .success(playlistDeleteResponse.id)))
            }.store(in: &store.cancellableSet)
    }
}

struct PlaylistDeleteReuquestDoneCommand: AppCommand {
    
    func execute(in store: Store) {
        store.dispatch(.userPlaylistRequest())
    }
}

struct PlaylistDetailRequestCommand: AppCommand {
    let id: Int
    
    func execute(in store: Store) {
        NeteaseCloudMusicApi
            .shared
            .requestPublisher(action: PlaylistDetailAction(parameters: .init(id: id)))
            .sink { completion in
                if case .failure(let error) = completion {
                    store.dispatch(.playlistDetailRequestDone(result: .failure(.error(error))))
                }
            } receiveValue: { playlistDetailResponse in
                DataManager.shared.update(model: playlistDetailResponse.playlist)
                store.dispatch(.playlistDetailRequestDone(result: .success(playlistDetailResponse.playlist)))
            }.store(in: &store.cancellableSet)
    }
}

struct PlaylistDetailDoneCommand: AppCommand {
    let playlist: PlaylistResponse
    
    func execute(in store: Store) {
        store.dispatch(.playlistDetailSongsRequest(playlist: playlist))
    }
}

struct PlaylistDetailSongsRequestCommand: AppCommand {
    let playlist: PlaylistResponse
    
    func execute(in store: Store) {
        if let ids = playlist.trackIds?.map(\.id) {
            NeteaseCloudMusicApi
                .shared
                .requestPublisher(action: SongDetailAction(parameters: .init(ids: ids)))
                .sink { completion in
                    if case .failure(let error) = completion {
                        store.dispatch(.playlistDetailSongsRequestDone(result: .failure(.error(error))))
                    }
                } receiveValue: { songDetailResponse in
                    guard songDetailResponse.isSuccess else {
                        store.dispatch(.playlistDetailSongsRequestDone(result: .failure(AppError.songsDetailError)))
                        return
                    }
                    DataManager.shared.updateSongs(model: songDetailResponse.songs)
                    DataManager.shared.updatePlaylistSongs(id: playlist.id, songsId: ids)
                    store.dispatch(.playlistDetailSongsRequestDone(result: .success(ids)))
                }.store(in: &store.cancellableSet)
        }
    }
}

struct PlaylistOrderUpdateRequestCommand: AppCommand {
    let ids: [Int]
    
    func execute(in store: Store) {
        NeteaseCloudMusicApi
            .shared
            .requestPublisher(action: PlaylistOrderUpdateAction(parameters: .init(ids: ids)))
            .sink { completion in
                if case .failure(let error) = completion {
                    store.dispatch(.playlistOrderUpdateDone(result: .failure(.error(error))))
                }
            } receiveValue: { playlistOrderUpdateResponse in
                store.dispatch(.playlistOrderUpdateDone(result: .success(playlistOrderUpdateResponse.isSuccess)))
            }.store(in: &store.cancellableSet)
    }
}

struct PlaylistOrderUpdateRequestDoneCommand: AppCommand {
    func execute(in store: Store) {
        store.dispatch(.userPlaylistRequest())
    }
}

struct PlaylisSubscribeRequestCommand: AppCommand {
    let id: Int
    let sub: Bool
    
    func execute(in store: Store) {
        NeteaseCloudMusicApi
            .shared
            .requestPublisher(action: PlaylistSubscribeAction(sub: sub, parameters: .init(id: id)))
            .sink { completion in
                if case .failure(let error) = completion {
                    store.dispatch(.playlistSubscibeRequestDone(result: .failure(.error(error))))
                }
            } receiveValue: { playlistSubscribeResponse in
                if playlistSubscribeResponse.isSuccess {
                    store.dispatch(.playlistSubscibeRequestDone(result: .success(id)))
                }else {
                    store.dispatch(.playlistSubscibeRequestDone(result: .failure(AppError.playlistSubscribeError)))
                }
            }.store(in: &store.cancellableSet)
    }
}

struct PlaylisSubscribeRequestDoneCommand: AppCommand {
    func execute(in store: Store) {
        store.dispatch(.userPlaylistRequest())
    }
}

struct PlaylistTracksRequestCommand: AppCommand {
    let pid: Int
    let ids: [Int]
    let op: Bool
    
    func execute(in store: Store) {
        NeteaseCloudMusicApi
            .shared
            .requestPublisher(action: PlaylistTracksAction(parameters: .init(pid: pid, ids: ids, op: op ? .add : .del)))
            .sink { completion in
                if case .failure(let error) = completion {
                    store.dispatch(.playlistTracksRequestDone(result: .failure(.error(error))))
                }
            } receiveValue: { playlistSubscribeResponse in
                if playlistSubscribeResponse.isSuccess {
                    store.dispatch(.playlistTracksRequestDone(result: .success(pid)))
                }else {
                    store.dispatch(.playlistTracksRequestDone(result: .failure(AppError.playlistSubscribeError)))
                }
            }.store(in: &store.cancellableSet)
    }
}

struct PlaylistTracksRequestDoneCommand: AppCommand {
    let id: Int
    
    func execute(in store: Store) {
        store.dispatch(.playlistDetailRequest(id: id))
    }
}

struct RecommendPlaylistRequestCommand: AppCommand {
    func execute(in store: Store) {
        NeteaseCloudMusicApi
            .shared
            .requestPublisher(action: RecommendPlaylistAction())
            .sink { completion in
                if case .failure(let error) = completion {
                    store.dispatch(.recommendPlaylistRequestDone(result: .failure(.error(error))))
                }
            } receiveValue: { recommendPlaylistResponse in
                guard recommendPlaylistResponse.isSuccess else {
                    store.dispatch(.recommendPlaylistRequestDone(result: .failure(AppError.recommendPlaylistRequest)))
                    return
                }
                store.dispatch(.recommendPlaylistRequestDone(result: .success(recommendPlaylistResponse)))
            }.store(in: &store.cancellableSet)
    }
}

struct RecommendSongsRequestCommand: AppCommand {
    func execute(in store: Store) {
        NeteaseCloudMusicApi
            .shared
            .requestPublisher(action: RecommendSongAction())
            .sink { completion in
                if case .failure(let error) = completion {
                    store.dispatch(.recommendSongsRequestDone(result: .failure(.error(error))))
                }
            } receiveValue: { recommendSongsResponse in
                guard recommendSongsResponse.isSuccess else {
                    store.dispatch(.recommendSongsRequestDone(result: .failure(AppError.recommendSongsError)))
                    return
                }
                let ids = recommendSongsResponse.data.dailySongs.map(\.id)
                DataManager.shared.update(model: recommendSongsResponse)
                NeteaseCloudMusicApi
                    .shared
                    .requestPublisher(action: SongDetailAction(parameters: .init(ids: ids)))
                    .sink { completion in
                        if case .failure(let error) = completion {
                            store.dispatch(.recommendSongsRequestDone(result: .failure(.error(error))))
                        }
                    } receiveValue: { songDetailResponse in
                        guard songDetailResponse.isSuccess else {
                            store.dispatch(.recommendSongsRequestDone(result: .failure(AppError.songsDetailError)))
                            return
                        }
                        DataManager.shared.updateSongs(model: songDetailResponse.songs)
                        DataManager.shared.updatePlaylistSongs(id: 0, songsId: ids)
                        store.dispatch(.recommendSongsRequestDone(result: .success(ids)))
                    }.store(in: &store.cancellableSet)
            }.store(in: &store.cancellableSet)
    }
}

struct RecommendSongsRequestDoneCommand: AppCommand {
    let ids: [Int]
    
    func execute(in store: Store) {
    }
}

struct SearchSongDoneCommand: AppCommand {
    let ids: [Int]
    
    func execute(in store: Store) {
        store.dispatch(.songsDetailRequest(ids: ids))
    }
}

struct SongsDetailCommand: AppCommand {
    let ids: [Int]
    
    func execute(in store: Store) {
        NeteaseCloudMusicApi
            .shared
            .requestPublisher(action: SongDetailAction(parameters: .init(ids: ids)))
            .sink { completion in
                if case .failure(let error) = completion {
                    store.dispatch(.songsDetailRequestDone(result: .failure(.error(error))))
                }
            } receiveValue: { songDetailResponse in
                DataManager.shared.batchInsert(type: Song.self, models: songDetailResponse.songs)
                store.dispatch(.songsDetailRequestDone(result: .success(ids)))
            }.store(in: &store.cancellableSet)
    }
}

struct SongLikeRequestCommand: AppCommand {
    let id: Int
    let like: Bool
    
    func execute(in store: Store) {
        NeteaseCloudMusicApi
            .shared
            .requestPublisher(action: SongLikeAction(parameters: .init(trackId: id, like: like)))
            .sink { completion in
                if case .failure(let error) = completion {
                    store.dispatch(.songLikeRequestDone(result: .failure(.error(error))))
                }
            } receiveValue: { songLikeResponse in
                store.dispatch(.songLikeRequestDone(result: .success(songLikeResponse.isSuccess)))
            }.store(in: &store.cancellableSet)
    }
}

struct SongLikeRequestDoneCommand: AppCommand {
    
    func execute(in store: Store) {
        if let uid = store.appState.settings.loginUser?.profile.userId {
            store.dispatch(.songLikeListRequest(uid: uid))
        }
    }
}

struct SongLikeListRequestCommand: AppCommand {
    let uid: Int
    
    func execute(in store: Store) {
        NeteaseCloudMusicApi
            .shared
            .requestPublisher(action: SongLikeListAction(parameters: .init(uid: uid)))
            .sink { completion in
                if case .failure(let error) = completion {
                    store.dispatch(.songLikeListRequestDone(result: .failure(.error(error))))
                }
            } receiveValue: { songLikeListResponse in
                store.dispatch(.songLikeListRequestDone(result: .success(songLikeListResponse.ids)))
            }.store(in: &store.cancellableSet)
    }
}

struct SongLyricRequestCommand: AppCommand {
    let id: Int
    
    func execute(in store: Store) {
        NeteaseCloudMusicApi
            .shared
            .requestPublisher(action: SongLyricAction(parameters: .init(id: id)))
            .sink { completion in
                if case .failure(let error) = completion {
                    store.dispatch(.songLyricRequestDone(result: .failure(.error(error))))
                }
            } receiveValue: { songLyricResponse in
                store.dispatch(.songLyricRequestDone(result: .success(songLyricResponse.lrc.lyric)))
            }
            .store(in: &store.cancellableSet)
    }
}

struct SongsOrderUpdateRequestCommand: AppCommand {
    let pid: Int
    let ids: [Int]
    
    func execute(in store: Store) {
        NeteaseCloudMusicApi
            .shared
            .requestPublisher(action: SongOrderUpdateAction(parameters: .init(pid: pid, trackIds: ids)))
            .sink { completion in
                if case .failure(let error) = completion {
                    store.dispatch(.songsOrderUpdateRequestDone(result: .failure(.error(error))))
                }
            } receiveValue: { songOrderUpdateResponse in
                guard songOrderUpdateResponse.isSuccess else {
                    store.dispatch(.songsOrderUpdateRequestDone(result: .failure(AppError.songsOrderUpdate)))
                    return
                }
                store.dispatch(.songsOrderUpdateRequestDone(result: .success(pid)))
            }.store(in: &store.cancellableSet)
    }
}

struct SongsOrderUpdateRequestingDoneCommand: AppCommand {
    let id: Int
    
    func execute(in store: Store) {
        store.dispatch(.playlistDetailRequest(id: id))
    }
}

struct SongsURLRequestCommand: AppCommand {
    let ids: [Int]
    
    func execute(in store: Store) {
        //        NeteaseCloudMusicApi.shared.songsURL(ids) { result in
        //            switch result {
        //            case .success(let json):
        //                if let songsURLDict = json["data"] as? [NeteaseCloudMusicApi.ResponseData] {
        //                    if songsURLDict.count > 0 {
        //                        store.dispatch(.songsURLRequestDone(result: .success(songsURLDict.map{$0.toData!.toModel(SongURLJSONModel.self)!})))
        //                    }
        //                }else {
        //                    store.dispatch(.songsURLRequestDone(result: .failure(.songsURLError)))
        //                }
        //            case .failure(let error):
        //                store.dispatch(.songsURLRequestDone(result: .failure(error)))
        //            }
        //        }
    }
}


struct RePlayCommand: AppCommand {
    func execute(in store: Store) {
        Player.shared.seek(seconds: 0)
        Player.shared.play()
    }
}

struct SeeKCommand: AppCommand {
    let time: Double
    
    func execute(in store: Store) {
        Player.shared.seek(seconds: time)
    }
}

struct UpdateMPNowPlayingInfoCommand: AppCommand {
    func execute(in store: Store) {
#if os(iOS)
        func makeInfo() -> [String : Any] {
            var info = [String : Any]()
            info[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
            if let title = store.appState.playing.song?.name {
                info[MPMediaItemPropertyTitle] = title//歌名
            }
            if let album = store.appState.playing.song?.album {
                info[MPMediaItemPropertyAlbumTitle] = album.name//专辑名
                //                     info[MPMediaItemPropertyAlbumArtist] = mainChannels.first?.value.soundMeta?.artist//专辑作者
            }
            
            info[MPMediaItemPropertyArtist] = store.appState.playing.song?.artists.map{($0.name ?? "")}.joined(separator: " ")
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] =  Player.shared.currentItem?.currentTime().seconds
            info[MPMediaItemPropertyPlaybackDuration] = Player.shared.currentItem?.duration.seconds//总时长
            //        info[MPNowPlayingInfoPropertyIsLiveStream] = 1.0
            info[MPNowPlayingInfoPropertyPlaybackRate] = Player.shared.rate//播放速率
            return info
        }
        guard let picUrl = store.appState.playing.song?.album?.coverURLString, let url = URL(string: picUrl) else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = makeInfo()
            return
        }
        
        let _ = KingfisherManager.shared.retrieveImage(with: .network(url), options: [.processor(DownsamplingImageProcessor(size: CGSize(width: CoverSize.medium.width * UIScreen.main.scale, height: CoverSize.medium.width * UIScreen.main.scale)))]) { result in
            switch result {
            case .success(let value):
                var info = makeInfo()
                info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: value.image.size, requestHandler: { (size) -> UIImage in
                    return value.image
                })//显示的图片
                MPNowPlayingInfoCenter.default().nowPlayingInfo = info
            case .failure(let error):
                #if DEBUG
                print(error)
                #endif
                MPNowPlayingInfoCenter.default().nowPlayingInfo = makeInfo()
            }
        }
#endif
        //        #if os(macOS)
        //        MPNowPlayingInfoCenter.default().playbackState = Player.shared.isPlaying ? .playing : .paused
        //        #endif
    }
}

struct UserCloudRequestCommand: AppCommand {
    
    func execute(in store: Store) {
        NeteaseCloudMusicApi
            .shared
            .requestPublisher(action: UserCloudAction(parameters: .init(limit: 30, offset: 0)))
            .sink { completion in
                if case .failure(let error) = completion {
                    store.dispatch(.userPlaylistRequestDone(result: .failure(.error(error))))
                }
            } receiveValue: { userCloudResponse in
                #if false
                print(userCloudResponse.toJSONString ?? "nil")
                #endif
            }.store(in: &store.cancellableSet)
    }
}

struct UserPlayListRequestCommand: AppCommand {
    let uid: Int
    let limit: Int
    let offset: Int
    
    func execute(in store: Store) {
        NeteaseCloudMusicApi
            .shared
            .requestPublisher(action: UserPlaylistAction(parameters: .init(uid: uid, limit: limit, offset: offset)))
            .sink { completion in
                if case .failure(let error) = completion {
                    store.dispatch(.userPlaylistRequestDone(result: .failure(.error(error))))
                }
            } receiveValue: { userPlaylistResponse in
                store.dispatch(.userPlaylistRequestDone(result: .success(userPlaylistResponse.playlist)))
            }.store(in: &store.cancellableSet)
    }
}
