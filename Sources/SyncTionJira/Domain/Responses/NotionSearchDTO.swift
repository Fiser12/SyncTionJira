//
//  NotionSearchDTO.swift
//  SyncTion (macOS)
//
//  Created by Ruben on 18.07.22.
//

/*
This file is part of SyncTion and is licensed under the GNU General Public License version 3.
SyncTion is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

struct NotionSearchDTO: Equatable, Decodable {
    let object: String
    let id: String
    let created_time: String
    let last_edited_time: String
    let icon: IconDTO?
    let properties: [String: PropertyBody]

    var description: String {
        let title = properties
                .filter {
                    $0.value.type == "title"
                }
                .first?
                .value
                .title?
                .map(\.plain_text)
                .joined() ?? ""

        let emoji = icon?.emoji ?? "📄"
        return "\(emoji) \(title)"
    }
}

struct IconDTO: Equatable, Decodable {
    let type: String
    let emoji: String?
    let external: UrlApi?
}

struct UrlApi: Equatable, Decodable {
    let url: String
}

struct PropertyBody: Equatable, Decodable {
    let id: String
    let type: String
    let title: [TitleDTOBody]?
}

struct TitleDTOBody: Equatable, Decodable {
    let plain_text: String
    let type: String
}
