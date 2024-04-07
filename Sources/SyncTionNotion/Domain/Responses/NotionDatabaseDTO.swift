//
//  NotionDatabaseDTO.swift
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

import SyncTionCore

struct NotionDatabaseDTO: Equatable, Decodable {
    let object: String
    let id: String
    let created_time: String
    let last_edited_time: String
    let title: [NotionTitleDTO]
    let properties: [String: NotionPropertyDTO]
    
    func validTitle() -> String {
        title.map(\.plain_text).joined()
    }
    
    enum CodingKeys: String, CodingKey {
        case object
        case id
        case created_time
        case last_edited_time
        case title
        case properties
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.object = try values.decode(String.self, forKey: .object)
        self.id = try values.decode(String.self, forKey: .id)
        self.created_time = try values.decode(String.self, forKey: .created_time)
        self.last_edited_time = try values.decode(String.self, forKey: .last_edited_time)
        self.title = try values.decode([NotionTitleDTO].self, forKey: .title)
        self.properties = try values.decode([String: NotionPropertyDTO].self, forKey: .properties).filter {
            $0.value.isOperable()
        }
    }
}

struct NotionTitleDTO: Equatable, Decodable {
    let type: String
    let text: NotionTextDTO
    let plain_text: String
    let href: String?
    
    enum CodingKeys: String, CodingKey {
        case type
        case text
        case annotations
        case plain_text
        case href
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        self.type = try values.decode(String.self, forKey: .type)
        self.text = try values.decode(NotionTextDTO.self, forKey: .text)
        self.plain_text = try values.decode(String.self, forKey: .plain_text)
        self.href = try values.decodeIfPresent(String.self, forKey: .href)
    }
}

struct NotionTextDTO: Equatable, Decodable {
    let content: String
    let link: String?
    
    enum CodingKeys: String, CodingKey {
        case content
        case link
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.content = try values.decode(String.self, forKey: .content)
        self.link = try values.decodeIfPresent(String.self, forKey: .link)
    }
}

struct NotionPropertyDTO: Equatable, Codable {
    static let types = [
        "date": Tag.Notion.ColumnType.date,
        "checkbox": Tag.Notion.ColumnType.checkbox,
        "url": Tag.Notion.ColumnType.url,
        "relation": Tag.Notion.ColumnType.relation,
        "select": Tag.Notion.ColumnType.select,
        "multi_select": Tag.Notion.ColumnType.multi_select,
        "number": Tag.Notion.ColumnType.number,
        "rich_text": Tag.Notion.ColumnType.rich_text,
        "title": Tag.Notion.ColumnType.title,
    ]
    
    let id: String
    let type: String
    let select: NotionSelectFieldDTO?
    let multi_select: NotionSelectFieldDTO?
    let relation: NotionRelationFieldDTO?
    
    func isOperable() -> Bool {
        NotionPropertyDTO.types.keys.contains(type)
    }
    
    var headerType: Tag? {
        NotionPropertyDTO.types[type]
    }
}

struct NotionSelectFieldDTO: Equatable, Codable {
    let options: [NotionOptionDTO]
}

struct NotionRelationFieldDTO: Equatable, Codable {
    let database_id: String
    let synced_property_name: String
    let synced_property_id: String
}

struct NotionOptionDTO: Equatable, Codable {
    let id: String
    let name: String
    var color: String = ""
    
    var option: Option {
        Option(optionId: id, description: name)
    }
}

