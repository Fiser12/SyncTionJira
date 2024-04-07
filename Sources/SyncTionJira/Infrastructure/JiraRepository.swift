//
//  FormJiraRepository.swift
//  SyncTion (macOS)
//
//  Created by Ruben on 17.07.22.
//

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
        guard request.httpBody != nil else { throw FormError.transformation }

        return try await transformAuthError(JiraFormService.shared.id) { [unowned self] in
            try await self.request(request, [JiraProjectDTO].self)
        }
    }
}


struct JiraProjectDTO: Identifiable, Decodable {
    let id: String
    let key: String
    let name: String
    let `self`: URL
    let avatarUrls: [String: URL]
    let projectCategory: JiraProjectCategoryDTO
    
}

struct JiraProjectCategoryDTO: Identifiable, Decodable {
    let id: String
    let `self`: URL
    let name: String
    let description: String
}

/*
 {
     "self": "http://www.example.com/jira/rest/api/2/project/EX",
     "id": "10000",
     "key": "EX",
     "name": "Example",
     "avatarUrls": {
         "48x48": "http://www.example.com/jira/secure/projectavatar?size=large&pid=10000",
         "24x24": "http://www.example.com/jira/secure/projectavatar?size=small&pid=10000",
         "16x16": "http://www.example.com/jira/secure/projectavatar?size=xsmall&pid=10000",
         "32x32": "http://www.example.com/jira/secure/projectavatar?size=medium&pid=10000"
     },
     "projectCategory": {
         "self": "http://www.example.com/jira/rest/api/2/projectCategory/10000",
         "id": "10000",
         "name": "FIRST",
         "description": "First Project Category"
     }
 },
 */
