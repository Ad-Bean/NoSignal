//
//  AppError.swift
//  NoSignal
//
//  Created by student9 on 2021/12/18.
//

import Foundation

enum AppError: Error, Identifiable {
    var id: String { localizedDescription }
    case error(Error)
    case albumDetailRequest
    case albumSubRequest
    case albumSublistRequest
    case artistAlbumsRequest
    case artistDetailRequest
    case artistIntroduction(code: Int, message: String)
    case artistMVsRequest
    case artistSubRequest
    case artistSublistRequest
    case cloudSongAddRequest
    case cloudUploadCheckRequest
    case cloudUploadInfoRequest
    case cloudUploadTokenRequest
    case comment
    case commentLikeRequest
    case commentMusic
    case httpRequest
    case jsonObject(message: String? = nil)
    case like
    case likelist
    case loginRequest
    case loginRefreshRequest
    case logoutRequest
    case lyricError
    case mvDetailRequest
    case neteaseCloudMusic(code: Int, message: String?)
    case playlistCategoriesRequest
    case playlistCreateRequest
    case playlistDeleteError
    case playlistDetailError
    case playlistOrderUpdateError(code: Int, message: String)
    case playlistSubscribeError
    case playlistTracksError(code: Int, message: String)
    case recommendSongsError
    case recommendPlaylistRequest
    case searchError
    case songsDetailError
    case songsOrderUpdate
    case songsURLError
    case userPlaylistError
    case httpRequestError(error: Error)
    case playingError(message: String)
}

extension AppError {
    var localizedDescription: String {
        switch self {
        case .error(let error):  return error.localizedDescription
        case .albumDetailRequest: return "Album detail request failure"
        case .albumSubRequest: return "Album sub or unsub failure"
        case .albumSublistRequest: return "Album sublist failure"
        case .artistAlbumsRequest: return "Artist album request failure"
        case .artistDetailRequest: return "Artist detail request failure"
        case .artistIntroduction(let code, let message): return errorFormat(error: "????????????????????????", code: code, message: message)
        case .artistMVsRequest: return "Artist mvs request failure"
        case .artistSubRequest: return "Artist sub request failure"
        case .artistSublistRequest: return "Artist sublist request failure"
        case .cloudSongAddRequest: return "Cloud song add request failure"
        case .cloudUploadCheckRequest: return "Cloud upload check request failure"
        case .cloudUploadInfoRequest: return "Cloud info request failure"
        case .cloudUploadTokenRequest: return "Cloud upload token request failure"
        case .comment: return "??????????????????"
        case .commentLikeRequest: return "??????????????????"
        case .commentMusic: return "??????????????????"
        case .httpRequest: return "??????????????????"
        case .jsonObject(let message): return "jsonObject error: \(message ?? "")"
        case .like: return "?????????????????????????????????"
        case .likelist: return "?????????????????????????????????"
        case .loginRequest: return "Login request failure"
        case .loginRefreshRequest: return "Login refresh request failure"
        case .logoutRequest: return "Logout request failure"
        case .lyricError: return "??????????????????"
        case .mvDetailRequest: return "MV Detail request failure"
        case .neteaseCloudMusic(let code, let message): return "NeteaseCloudMusic:\ncode:\(code)\nmessage:\(message ?? "")"
        case .playlistCategoriesRequest: return "Playlist categories request failure"
        case .playlistCreateRequest: return "Playlist create request failure"
        case .playlistDeleteError: return "??????????????????"
        case .playlistDetailError: return "????????????????????????"
        case .playlistOrderUpdateError(let code, let message): return errorFormat(error: "??????????????????", code: code, message: message)
        case .playlistSubscribeError: return "??????????????????"
        case .playlistTracksError(let code, let message): return errorFormat(error: "?????????????????????????????????", code: code, message: message)
        case .recommendSongsError: return "??????????????????????????????"
        case .recommendPlaylistRequest: return "??????????????????????????????"
        case .searchError: return "????????????"
        case .songsDetailError: return "????????????????????????"
        case .songsOrderUpdate: return "??????????????????"
        case .songsURLError: return "????????????????????????"
        case .userPlaylistError: return "????????????????????????"
        case .httpRequestError(let error): return error.localizedDescription
        case .playingError(let message): return "??????????????? \(message)"
        }
    }
    private func errorFormat(error: String, code: Int, message: String) -> String {
        return "\(error)\n\(code)\n\(message)"
    }
}
