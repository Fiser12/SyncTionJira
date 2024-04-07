//
//  NotionPageBodyDTO.swift
//  SyncTion (iOS)
//
//  Created by rgarciah on 19/7/21.
//

/*
This file is part of SyncTion and is licensed under the GNU General Public License version 3.
SyncTion is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

import Foundation
import SyncTionCore
import PreludePackage

struct ParentBody: Encodable {
    let database_id: String
}

struct NotionPageBodyDTO: Encodable {
    let parent: ParentBody
    let properties: [String: ValueBody]
    
    init?(_ form: FormModel) {
        guard
            let databaseInput: OptionsTemplate = form.inputs.first(tag: Tag.Notion.DatabasesField),
            let databaseId = databaseInput.value.selected.first?.optionId
        else {
            logger.error("NotionPageBodyDTO: NotionDatabasesInputTag was not found")
            return nil
        }
        
        parent = ParentBody(database_id: databaseId)
        var values: [(Header, (any AbstractValue)?)] {
            form.inputs.map { value in
                (value.template.header, value.template.value as (any AbstractValue)?)
            }
        }
        let properties: [String: ValueBody] = Dictionary(
            uniqueKeysWithValues: values.filter {
                !$0.0.tags.contains(Tag.Notion.DatabasesField)
            }
                .map { item in
                    let (header, value) = item
                    let key = header.name
                    switch value {
                    case let text as String:
                        if header.tags.contains(Tag.Notion.ColumnType.title) {
                            let valueBody = ValueBody(title: [TitleBody(text: TextBody(content: text))])
                            return (key, valueBody)
                        } else if header.tags.contains(Tag.Notion.ColumnType.number) {
                            return (key, ValueBody(number: Double(text)))
                        } else if header.tags.contains(Tag.Notion.ColumnType.url) && !text.isEmpty {
                            return (key, ValueBody(url: text))
                        } else if header.tags.contains(Tag.Notion.ColumnType.rich_text), !text.isEmpty {
                            let valueBody = ValueBody(richTextbody: [RichTextBody(text: TextBody(content: text)),])
                            return (key, valueBody)
                        }
                    case let range as Range:
                        if let start = range.start {
                            let startString = ISO8601DateFormatter().string(from: start)
                            let endString = range.end != nil ? ISO8601DateFormatter().string(from: range.end!) : nil
                            return (key, ValueBody(date: DateBody(start: startString, end: endString)))
                        }
                    case let options as Options:
                        if let optionId = options.selected.first?.optionId, header.tags.contains(Tag.Notion.ColumnType.select) {
                            return (key, ValueBody(select: SelectBody(id: optionId)))
                        } else if header.tags.contains(Tag.Notion.ColumnType.multi_select) {
                            let valueBody = ValueBody(multiselect: options.selected.map { SelectBody(id: $0.optionId)} )
                            return (key, valueBody)
                        } else if header.tags.contains(Tag.Notion.ColumnType.relation) {
                            let valueBody = ValueBody(relation: options.selected.map { RelationBody(id: $0.optionId)} )
                            return (key, valueBody)
                        }
                    case let value as Bool:
                        return (key, ValueBody(checkbox: value))
                    default:
                        return (key, ValueBody())
                    }
                    
                    return (key, ValueBody())
                })
        self.properties = properties.filter(\.value.isValid)
    }
}

struct ValueBody: Equatable, Encodable {
    let select: SelectBody?
    let multi_select: [SelectBody]?
    let relation: [RelationBody]?
    let rich_text: [RichTextBody]?
    let date: DateBody?
    let url: LinkBody?
    let number: NumberBody?
    let checkbox: CheckboxBody?
    let title: [TitleBody]?
    
    init(
        title: [TitleBody]? = nil,
        select: SelectBody? = nil,
        multiselect: [SelectBody]? = nil,
        relation: [RelationBody]? = nil,
        checkbox: CheckboxBody? = nil,
        number: NumberBody? = nil,
        url: LinkBody? = nil,
        date: DateBody? = nil,
        richTextbody: [RichTextBody]? = nil
    ) {
        self.title = title
        self.select = select
        self.rich_text = richTextbody
        self.date = date
        self.url = url
        self.number = number
        self.checkbox = checkbox
        self.multi_select = multiselect
        self.relation = relation
    }
    
    var isValid: Bool {
        title != nil ||
        select != nil ||
        rich_text != nil ||
        multi_select != nil ||
        number != nil ||
        relation != nil ||
        url != nil ||
        date != nil ||
        checkbox != nil
    }
}

struct SelectBody: Equatable, Encodable {
    let id: String
    let name: String? = nil
}

struct RelationBody: Equatable, Encodable {
    let id: String
}

struct TitleBody: Equatable, Encodable {
    let type: String = "text"
    let text: TextBody
    //    let annotations: AnnotationsBody
    //    let plain_text: String
    //    let href: String
}

struct DateBody: Equatable, Encodable {
    let start: String
    let end: String?
}

struct TextBody: Equatable, Encodable {
    //    let link: String
    let content: String
}

struct AnnotationsBody: Equatable, Encodable {
    let bold: Bool
    let italic: Bool
    let strikethrough: Bool
    let underline: Bool
    let code: Bool
    let color: String
}

typealias RichTextBody = TitleBody
typealias LinkBody = String
typealias CheckboxBody = Bool
typealias NumberBody = Double
