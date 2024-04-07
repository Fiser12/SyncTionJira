//
//  JiraProjectDTO.swift
//  
//
//  Created by Rubén García Hernando on 7/4/24.
//

/*
This file is part of SyncTion and is licensed under the GNU General Public License version 3.
SyncTion is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

import Foundation

struct JiraProjectDTO: Identifiable, Decodable {
    let id: String
    let key: String
    let name: String
    let `self`: URL
    let avatarUrls: [String: URL]
    let projectTypeKey: String
    let archived: Bool
}
