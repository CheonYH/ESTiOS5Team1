//
//  ImageURLGenerator.swift
//  ESTiOS5Team1
//
//  Created by cheon on 1/6/26.
//

import Foundation

enum IGDBImageSize: String {
    case coverBig = "t_cover_big"
}

func makeIGDBImageURL(imageID: String, id: Int, size: IGDBImageSize = .coverBig) -> URL? {
    URL(string: "https://images.igdb.com/igdb/image/upload/\(size.rawValue)/\(imageID).jpg")
}
