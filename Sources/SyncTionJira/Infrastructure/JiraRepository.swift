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
    static let jiraAPI = URL(string: "https://api.jira.com")!
    static let jiraSearch: URL = .jiraAPI.appendingPathComponent("v1/search")
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
        guard let postPageBody = JiraPageBodyDTO(form) else { throw FormError.transformation }
        
        let request = URLRequest(url: .jiraPages)
            .jiraHeaders(secrets: jiraSecrets)
            .method(.post(postPageBody))
        
        guard request.httpBody != nil else { throw FormError.transformation }

        _ = try await transformAuthError(JiraFormService.shared.id) { [unowned self] in
            try await self.request(request, JiraPostPageResponseDTO.self)
        }
    }
    
    func loadJiraDatabases(databaseId: String) async throws -> [AnyInputTemplate]? {
        let apiDatabase = try await loadJiraDatabaseDTO().results.first {
            $0.id == databaseId
        }
        
        guard let apiDatabase else {
            logger.warning("LoadInputsFromJiraDatabase: request was empty")
            return nil
        }
        
        let properties = apiDatabase.properties.map {
            (name: $0.key, property: $0.value)
        }
        return self.buildTemplates(properties)
            .compactMap{
                AnyInputTemplate($0)
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
                tags: [Tag.Jira.DatabasesField]
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
                Step(id: Tag.Jira.DatabasesField, name: String(localized: "Select database")),
                Step(id: Tag.Jira.DatabaseColumns, name: String(localized: "Columns"), isLast: true)
            ]
        )
    }
    
    typealias Database = (id: String, name: String)
    func databases() async throws -> [Database] {
        let response = try await self.loadJiraDatabaseDTO()
        return response.results.map {
            Database(id: $0.id, name: $0.validTitle())
        }
        .filter {
            !$0.name.isEmpty
        }
    }
    
    typealias JiraProperty = (name: String, property: JiraPropertyDTO)
    
    func buildTemplates(_ properties: [JiraProperty]) -> [any InputTemplate] {
        let properties = properties
            .sorted {
                $0.property.id < $1.property.id
            }
            .sorted {
                $0.name < $1.name
            }
            .sorted {
                $0.property.type == "title" && $1.property.type != "title"
            }
        return properties.map {
            buildTemplate($0)
        }
    }
    
    private func buildTemplate(_ property: JiraProperty) -> any InputTemplate {
        let header = Header(
            name: property.name,
            icon: Tag.Jira.ColumnType.icon(property.property.headerType),
            tags: Set([property.property.headerType, Tag.Jira.DatabaseColumns].compactMap{$0})
        )
        
        let stringTags = [
            Tag.Jira.ColumnType.title,
            Tag.Jira.ColumnType.rich_text,
            Tag.Jira.ColumnType.content,
            Tag.Jira.ColumnType.url,
        ]
        if !header.tags.intersection(stringTags).isEmpty {
            return TextTemplate(header: header)
        } else if header.tags.contains(Tag.Jira.ColumnType.number) {
            return NumberTemplate(header: header)
        } else if header.tags.contains(Tag.Jira.ColumnType.date) {
            return RangeTemplate(header: header)
        } else if header.tags.contains(Tag.Jira.ColumnType.checkbox) {
            return BoolTemplate(header: header)
        } else if header.tags.contains(Tag.Jira.ColumnType.select) {
            let options = property.property.select?.options
                .map(\.option) ?? []
                .sorted {
                    $0.description < $1.description
                }
            let config = OptionsTemplateConfig(
                singleSelection: Editable(true, constant: true),
                typingSearch: Editable(false, constant: false)
            )
            return OptionsTemplate(
                header: header,
                config: config,
                value: Options(options: options, singleSelection: true)
            )
        } else if header.tags.contains(Tag.Jira.ColumnType.multi_select) {
            let options = property.property.multi_select?.options
                .map(\.option) ?? []
                .sorted {
                    $0.description < $1.description
                }
            let config = OptionsTemplateConfig(
                singleSelection: Editable(false, constant: true),
                typingSearch: Editable(false, constant: false)
            )
            return OptionsTemplate(
                header: header,
                config: config,
                value: Options(options: options, singleSelection: false)
            )
            
        } else if header.tags.contains(Tag.Jira.ColumnType.relation) {
            let targetId = property.property.relation?.database_id ?? "INVALID TARGET ID"
            let config = OptionsTemplateConfig(
                singleSelection: Editable(false, constant: true),
                typingSearch: Editable(true, constant: false),
                targetId: targetId
            )
            return OptionsTemplate(
                header: header,
                config: config
            )
        } else {
            return TextTemplate(header: header)
        }
    }
        
    func loadJiraDatabaseDTO() async throws -> JiraGenericResponseDTO<JiraDatabaseDTO> {
        guard let jiraSecrets else { throw FormError.auth(JiraFormService.shared.id) }

        let request = URLRequest(url: .jiraSearch)
            .jiraHeaders(secrets: jiraSecrets)
            .method(.post(JiraFilterBodyDTO()))
        guard request.httpBody != nil else { throw FormError.transformation }

        return try await transformAuthError(JiraFormService.shared.id) { [unowned self] in
            try await self.request(request, JiraGenericResponseDTO<JiraDatabaseDTO>.self)
        }
    }
    
    func searchPages(text: String, databaseId: String) async throws -> [Option] {
        guard let jiraSecrets else { throw FormError.auth(JiraFormService.shared.id) }

        let request = URLRequest(url: .jiraQueryDatabase(by: databaseId))
            .jiraHeaders(secrets: jiraSecrets)
            .method(.post(JiraFilterBodyDTO(text)))
        guard request.httpBody != nil else { throw FormError.transformation }

        return try await transformAuthError(JiraFormService.shared.id) { [unowned self] in
            try await self.request(request, JiraGenericResponseDTO<JiraSearchDTO>.self).results
                .map {
                    Option(optionId: $0.id, description: $0.description)
                }
                .sorted { first, second in
                    first.description.levDis(text) < second.description.levDis(text)
                }
        }
    }
}

