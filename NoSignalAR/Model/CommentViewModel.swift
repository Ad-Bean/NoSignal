//
//  CommentViewModel.swift
//  NoSignal
//
//  Created by student9 on 2021/12/24.
//

import Foundation

class CommentViewModel: ObservableObject, Identifiable {
    var beReplied = [CommentViewModel]()
    var commentId: Int = 0
    var content: String = ""
    var id: Int = 0 // commentId for Identifiable
    @Published var liked: Bool = false
    var likedCount: Int = 0
    var parentCommentId: Int = 0
    var userId: Int = 0
    var avatarUrl: String = ""
    var nickname: String = ""
    
    init() {
        
    }
    
    init(_ comment: CommentSongResponse.Comment) {
        self.beReplied = comment.beReplied.map{CommentViewModel($0)}
        self.commentId = comment.commentId
        self.content = comment.content
        self.id = comment.commentId
        self.liked = comment.liked
        self.likedCount = comment.likedCount
        self.parentCommentId = comment.parentCommentId
        self.userId = comment.user.userId
        self.avatarUrl = comment.user.avatarUrl
        self.nickname = comment.user.nickname
    }
    
    init(_ comment: CommentSongResponse.Comment.BeReplied) {
        self.commentId = comment.beRepliedCommentId
        self.content = comment.content ?? ""
        self.id = comment.user.userId
        self.avatarUrl = comment.user.avatarUrl
        self.nickname = comment.user.nickname
    }}
