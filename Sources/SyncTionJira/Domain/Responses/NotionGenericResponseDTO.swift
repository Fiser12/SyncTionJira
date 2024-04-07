import SyncTionCore

/*
This file is part of SyncTion and is licensed under the GNU General Public License version 3.
SyncTion is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

struct NotionGenericResponseDTO<T: Equatable & Decodable>: Equatable, Decodable {
    let object: String
    let results: [T]
    let next_cursor: String?
    let has_more: Bool
    
    enum CodingKeys: String, CodingKey {
        case object
        case results
        case next_cursor
        case has_more
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        guard
            let object = try values.decodeIfPresent(String.self, forKey: .object),
            let results = try values.decodeIfPresent([T].self, forKey: .results),
            let has_more = try values.decodeIfPresent(Bool.self, forKey: .has_more)
        else {
            throw SyncTionError.DecodingError(.NotionJSONDecodingError)
        }
        
        self.object = object
        self.results = results
        next_cursor = try values.decodeIfPresent(String.self, forKey: .next_cursor)
        self.has_more = has_more
    }
    
    init(results: [T]) {
        object = ""
        self.results = results
        next_cursor = ""
        has_more = false
    }
}
