//
//  FormNotionRepository.swift
//  SyncTion (macOS)
//
//  Created by Ruben on 17.07.22.
//

import SwiftUI
import Combine
import SyncTionCore
import PreludePackage

fileprivate extension URL {
    static let notionAPI = URL(string: "https://api.notion.com")!
    static let notionSearch: URL = .notionAPI.appendingPathComponent("v1/search")
    static let notionPages: URL = .notionAPI.appendingPathComponent("v1/pages")
    static func notionQueryDatabase(by databaseId: String) -> URL {
        .notionAPI.appendingPathComponent("v1/databases/\(databaseId)/query")
    }
}

fileprivate extension URLRequest {
    func notionHeaders(secrets: NotionSecrets) -> URLRequest {
        header(.contentType, value: "application/json")
            .header(.authorization, value: "Bearer \(secrets.secret)")
            .header("Notion-Version", value: "2022-02-22")
    }
}

public final class FormNotionRepository: FormRepository {
    public static let shared = FormNotionRepository()
    
    @KeychainWrapper(Constants.notionSecretLabel) public var notionSecrets: NotionSecrets?

    func post(form: FormModel) async throws -> Void {
        guard let notionSecrets else { throw FormError.auth(NotionFormService.shared.id) }
        guard let postPageBody = NotionPageBodyDTO(form) else { throw FormError.transformation }
        
        let request = URLRequest(url: .notionPages)
            .notionHeaders(secrets: notionSecrets)
            .method(.post(postPageBody))
        
        guard request.httpBody != nil else { throw FormError.transformation }

        _ = try await transformAuthError(NotionFormService.shared.id) { [unowned self] in
            try await self.request(request, NotionPostPageResponseDTO.self)
        }
    }
    
    func loadNotionDatabases(databaseId: String) async throws -> [AnyInputTemplate]? {
        let apiDatabase = try await loadNotionDatabaseDTO().results.first {
            $0.id == databaseId
        }
        
        guard let apiDatabase else {
            logger.warning("LoadInputsFromNotionDatabase: request was empty")
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
            formName: NotionFormService.shared.description,
            icon: .static(NotionFormService.shared.icon),
            color: Color.accentColor.rgba
        )
        
        let firstTemplate = OptionsTemplate(
            header: Header(
                name: String(localized: "Notion Databases"),
                icon: "tray.2",
                tags: [Tag.Notion.DatabasesField]
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
                integration: NotionFormService.shared.id
            ),
            inputs: [firstTemplate],
            steps: [
                Step(id: Tag.Notion.DatabasesField, name: String(localized: "Select database")),
                Step(id: Tag.Notion.DatabaseColumns, name: String(localized: "Columns"), isLast: true)
            ]
        )
    }
    
    typealias Database = (id: String, name: String)
    func databases() async throws -> [Database] {
        let response = try await self.loadNotionDatabaseDTO()
        return response.results.map {
            Database(id: $0.id, name: $0.validTitle())
        }
        .filter {
            !$0.name.isEmpty
        }
    }
    
    typealias NotionProperty = (name: String, property: NotionPropertyDTO)
    
    func buildTemplates(_ properties: [NotionProperty]) -> [any InputTemplate] {
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
    
    private func buildTemplate(_ property: NotionProperty) -> any InputTemplate {
        let header = Header(
            name: property.name,
            icon: Tag.Notion.ColumnType.icon(property.property.headerType),
            tags: Set([property.property.headerType, Tag.Notion.DatabaseColumns].compactMap{$0})
        )
        
        let stringTags = [
            Tag.Notion.ColumnType.title,
            Tag.Notion.ColumnType.rich_text,
            Tag.Notion.ColumnType.content,
            Tag.Notion.ColumnType.url,
        ]
        if !header.tags.intersection(stringTags).isEmpty {
            return TextTemplate(header: header)
        } else if header.tags.contains(Tag.Notion.ColumnType.number) {
            return NumberTemplate(header: header)
        } else if header.tags.contains(Tag.Notion.ColumnType.date) {
            return RangeTemplate(header: header)
        } else if header.tags.contains(Tag.Notion.ColumnType.checkbox) {
            return BoolTemplate(header: header)
        } else if header.tags.contains(Tag.Notion.ColumnType.select) {
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
        } else if header.tags.contains(Tag.Notion.ColumnType.multi_select) {
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
            
        } else if header.tags.contains(Tag.Notion.ColumnType.relation) {
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
        
    func loadNotionDatabaseDTO() async throws -> NotionGenericResponseDTO<NotionDatabaseDTO> {
        guard let notionSecrets else { throw FormError.auth(NotionFormService.shared.id) }

        let request = URLRequest(url: .notionSearch)
            .notionHeaders(secrets: notionSecrets)
            .method(.post(NotionFilterBodyDTO()))
        guard request.httpBody != nil else { throw FormError.transformation }

        return try await transformAuthError(NotionFormService.shared.id) { [unowned self] in
            try await self.request(request, NotionGenericResponseDTO<NotionDatabaseDTO>.self)
        }
    }
    
    func searchPages(text: String, databaseId: String) async throws -> [Option] {
        guard let notionSecrets else { throw FormError.auth(NotionFormService.shared.id) }

        let request = URLRequest(url: .notionQueryDatabase(by: databaseId))
            .notionHeaders(secrets: notionSecrets)
            .method(.post(NotionFilterBodyDTO(text)))
        guard request.httpBody != nil else { throw FormError.transformation }

        return try await transformAuthError(NotionFormService.shared.id) { [unowned self] in
            try await self.request(request, NotionGenericResponseDTO<NotionSearchDTO>.self).results
                .map {
                    Option(optionId: $0.id, description: $0.description)
                }
                .sorted { first, second in
                    first.description.levDis(text) < second.description.levDis(text)
                }
        }
    }
}
