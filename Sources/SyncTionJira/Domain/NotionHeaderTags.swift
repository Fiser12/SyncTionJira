//
//  NotionHeaderType.swift
//  SyncTion (macOS)
//
//  Created by rgarciah on 1/7/21.
//

/*
This file is part of SyncTion and is licensed under the GNU General Public License version 3.
SyncTion is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

import Foundation
import SyncTionCore

extension Tag {
    struct Notion {
        private init() { fatalError() }

        static let DatabasesField = Tag("8b71ef28-38af-46ea-9609-5357b3244ec3")!
        static let DatabaseColumns = Tag("88121221-8ba2-4157-9308-921eb2da50fc")!
        
        struct ColumnType {
            private init() { fatalError() }

            static let date = Tag("976dce8f-3663-4a26-8348-743e7622f694")!
            static let checkbox = Tag("d5f606ab-fbf2-4c24-9870-9dc1c72abcd1")!
            static let url = Tag("c5c65e55-f7f1-4ec5-b8e2-6fe952836bac")!
            static let select = Tag("fb1e4396-0690-46d1-bd85-d0ea391b6460")!
            static let multi_select = Tag("1c7ae02f-5cdf-4dbd-8ce3-6b8f2324a370")!
            static let relation = Tag("7023361e-8665-4ae6-b594-6e46efd8b988")!
            static let number = Tag("5a458009-28fe-4512-ba4b-666a9777e956")!
            static let rich_text = Tag("8616ccdd-a6ca-4686-8858-889edff04e5e")!
            static let title = Tag("5c3dd722-a8d1-475f-8a87-b11e303f59b8")!
            static let content = Tag("0111182f-17e0-434e-80a7-0b7687ffff1c")!
               
            
            static func icon(_ tag: Tag?) -> String {
                switch tag {
                case ColumnType.date:
                    return "calendar"
                case ColumnType.checkbox:
                    return "checkmark.circle"
                case ColumnType.url:
                    return "link"
                case ColumnType.select:
                    return "filemenu.and.selection"
                case ColumnType.relation:
                    return "arrow.up.forward.app"
                case ColumnType.multi_select:
                    return "filemenu.and.selection"
                case ColumnType.number:
                    return "textformat.123"
                case ColumnType.rich_text:
                    return "textformat"
                case ColumnType.title:
                    return "textformat"
                case ColumnType.content:
                    return "doc.richtext.fill"
                default:
                    return "clear"
                }
            }
        }
    }
}
