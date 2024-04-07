//
//  JiraDatabaseDTO.swift
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

struct JiraDatabaseDTO: Equatable, Decodable {
    let object: String
    let id: String
    let created_time: String
    let last_edited_time: String
    let title: [JiraTitleDTO]
    let properties: [String: JiraPropertyDTO]
    
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
        self.title = try values.decode([JiraTitleDTO].self, forKey: .title)
        self.properties = try values.decode([String: JiraPropertyDTO].self, forKey: .properties).filter {
            $0.value.isOperable()
        }
    }
}

struct JiraTitleDTO: Equatable, Decodable {
    let type: String
    let text: JiraTextDTO
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
        self.text = try values.decode(JiraTextDTO.self, forKey: .text)
        self.plain_text = try values.decode(String.self, forKey: .plain_text)
        self.href = try values.decodeIfPresent(String.self, forKey: .href)
    }
}

struct JiraTextDTO: Equatable, Decodable {
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

struct JiraPropertyDTO: Equatable, Codable {
    static let types = [
        "date": Tag.Jira.ColumnType.date,
        "checkbox": Tag.Jira.ColumnType.checkbox,
        "url": Tag.Jira.ColumnType.url,
        "relation": Tag.Jira.ColumnType.relation,
        "select": Tag.Jira.ColumnType.select,
        "multi_select": Tag.Jira.ColumnType.multi_select,
        "number": Tag.Jira.ColumnType.number,
        "rich_text": Tag.Jira.ColumnType.rich_text,
        "title": Tag.Jira.ColumnType.title,
    ]
    
    let id: String
    let type: String
    let select: JiraSelectFieldDTO?
    let multi_select: JiraSelectFieldDTO?
    let relation: JiraRelationFieldDTO?
    
    func isOperable() -> Bool {
        JiraPropertyDTO.types.keys.contains(type)
    }
    
    var headerType: Tag? {
        JiraPropertyDTO.types[type]
    }
}

struct JiraSelectFieldDTO: Equatable, Codable {
    let options: [JiraOptionDTO]
}

struct JiraRelationFieldDTO: Equatable, Codable {
    let database_id: String
    let synced_property_name: String
    let synced_property_id: String
}

struct JiraOptionDTO: Equatable, Codable {
    let id: String
    let name: String
    var color: String = ""
    
    var option: Option {
        Option(optionId: id, description: name)
    }
}

