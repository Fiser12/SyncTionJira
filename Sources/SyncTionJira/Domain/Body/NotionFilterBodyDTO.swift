//
//  NotionFilterBodyDTO.swift
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

struct NotionFilterBodyDTO: Encodable {
    let filter: Filter

    init(_ text: String) {
        filter = Filter(title: TitleFilter(contains: text), value: nil)
    }

    init() {
        filter = Filter(property: "object", value: "database")
    }
}

struct Filter: Encodable {
    var property: String = "title"
    var title: TitleFilter?
    var value: String?
}

struct TitleFilter: Encodable {
    let contains: String
}
