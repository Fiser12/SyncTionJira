//
//  FormJiraRepository.swift
//  SyncTion (macOS)
//
//  Created by Ruben on 17.07.22.
//

/*
This file is part of SyncTion and is licensed under the GNU General Public License version 3.
SyncTion is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

import SwiftUI
import Combine
import SyncTionCore
import PreludePackage

fileprivate extension URL {
    static let jiraAPI = URL(string: "https://jira.atlassian.com/rest/api/")!
    static let jiraProjects: URL = .jiraAPI.appendingPathComponent("2/project")
    static let jiraPages: URL = .jiraAPI.appendingPathComponent("v1/pages")
    static func jiraQueryDatabase(by databaseId: String) -> URL {
        .jiraAPI.appendingPathComponent("v1/databases/\(databaseId)/query")
    }
}

fileprivate extension URLRequest {
    func jiraHeaders(secrets: JiraSecrets) -> URLRequest {
        header(.contentType, value: "application/json")
            .header(.authorization, value: "Bearer \(secrets.secret)")
            .header("Jira-Version", value: "2022-02-22")
    }
}

extension Constants {
    public static let jiraSecretLabel = "JIRA_PRIVATE_SECRET"
}

public final class JiraRepository: FormRepository {
    public static let shared = JiraRepository()
    
    @KeychainWrapper(Constants.jiraSecretLabel) public var jiraSecrets: JiraSecrets?

    func post(form: FormModel) async throws -> Void {
        guard let jiraSecrets else { throw FormError.auth(JiraFormService.shared.id) }
        
        let request = URLRequest(url: .jiraPages)
            .jiraHeaders(secrets: jiraSecrets)
        
        guard request.httpBody != nil else { throw FormError.transformation }

        _ = try await transformAuthError(JiraFormService.shared.id) {

        }
    }
        
    public static var scratchTemplate: FormTemplate {
        let style = FormModel.Style(
            formName: JiraFormService.shared.description,
            icon: .static(JiraFormService.shared.icon),
            color: Color.accentColor.rgba
        )
        
        let firstTemplate = OptionsTemplate(
            header: Header(
                name: String(localized: "Jira Databases"),
                icon: "tray.2",
                tags: [Tag.Jira.ProjectsListField]
            ),
            config: OptionsTemplateConfig(
                mandatory: Editable(true, constant: true),
                singleSelection: Editable(true, constant: true),
                typingSearch: Editable(true, constant: false),
                targetId: ""
            )
        )
        
        return FormTemplate(
            FormHeader(
                id: FormTemplateId(),
                style: style,
                integration: JiraFormService.shared.id
            ),
            inputs: [firstTemplate],
            steps: [
                Step(id: Tag.Jira.ProjectsListField, name: String(localized: "Select database"))
            ]
        )
    }
    
    typealias Project = (id: String, name: String)
    func projects() async throws -> [Project] {
        let response = try await self.loadJiraProjectsDTO()
        return response.map {
            Project(id: $0.id, name: $0.name)
        }
        .filter {
            !$0.name.isEmpty
        }
    }
    
    func loadJiraProjectsDTO() async throws -> [JiraProjectDTO] {
        guard let jiraSecrets else { throw FormError.auth(JiraFormService.shared.id) }

        let request = URLRequest(url: .jiraProjects)
            .jiraHeaders(secrets: jiraSecrets)
            .method(.get)

        return try await transformAuthError(JiraFormService.shared.id) { [unowned self] in
            try await self.request(request, [JiraProjectDTO].self)
        }
    }
}


