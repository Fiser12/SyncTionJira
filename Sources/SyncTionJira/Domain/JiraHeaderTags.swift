//
//  JiraHeaderType.swift
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
    struct Jira {
        private init() { fatalError() }

        static let ProjectsListField = Tag("72986fd4-194a-45ee-9c50-5acc47c32b0c")!
        
    }
}
