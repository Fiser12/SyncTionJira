//
//  JiraFormService.swift
//  SyncTion (macOS)
//
//  Created by Rubén on 25/12/22.
//

/*
This file is part of SyncTion and is licensed under the GNU General Public License version 3.
SyncTion is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

import Combine
import SyncTionCore
import Foundation
import PreludePackage

public final class JiraFormService: FormService {
    public static let shared = JiraFormService()

    public let description = String(localized: "Jira")
    public let icon = "JiraLogo"
    public var id = FormServiceId(hash: UUID(uuidString: "4f6a9d57-b8d0-4635-852a-9a49de2e7ada")!)

    public var scratchTemplate: FormTemplate {
        JiraRepository.scratchTemplate
    }

    public let onChangeEvents: [any TemplateEvent] = [DatabaseFieldHandler.shared, OnChangeRelationFields.shared]
    
    
    func loadInputsFromJiraDatabase(form: FormModel, input: OptionsTemplate) async throws -> FormDomainEvent {
        guard let databaseId = input.value.selected.first?.optionId else {
            throw FormError.event(.skip)
        }
        
        logger.info("LoadInputsFromJiraDatabase: init")
        guard let jiraColumns = try await repository.loadJiraDatabases(databaseId: databaseId) else {
            throw FormError.event(.skip)
        }
        return { form in
            form.inputs = [AnyInputTemplate(input)] + jiraColumns
            form.saveValuesAsDefault()
            
            logger.info("LoadInputsFromJiraDatabase: success")
            guard let firstFocus = jiraColumns.first?.id else { return }
            form.template.firstInputId = firstFocus
        }
    }
    
    private final class DatabaseFieldHandler: TemplateEvent {
        
        typealias Template = OptionsTemplate
        
        static let shared = DatabaseFieldHandler()
        
        func assess(old: OptionsTemplate, input: OptionsTemplate) -> Bool {
            input.header.tags.contains(.Jira.DatabasesField)
        }

        func execute(form: FormModel, old: OptionsTemplate, input: OptionsTemplate) async throws -> FormDomainEvent {
            if old.search != input.search && input.config.typingSearch {
                return try await JiraFormService.shared.filterByText(form: form, input: input)
            }
            if old.value != input.value {
                return try await JiraFormService.shared.loadInputsFromJiraDatabase(form: form, input: input)
            }
            throw FormError.event(.skip)
        }
    }
    
    private final class OnChangeRelationFields: TemplateEvent {
        typealias Template = OptionsTemplate
        
        static let shared = OnChangeRelationFields()

        func assess(old: OptionsTemplate, input: OptionsTemplate) -> Bool {
            input.header.tags.contains(.Jira.ColumnType.relation)
        }

        func execute(form: FormModel, old: OptionsTemplate, input: OptionsTemplate) async throws -> FormDomainEvent {
            guard old.search != input.search && input.config.typingSearch else {
                throw FormError.event(.skip)
            }
            return try await JiraFormService.shared.onChangeRelation(form: form, oldInput: old, input: input)
        }
    }
    
    let repository = JiraRepository.shared

    public func load(form: FormModel) async throws -> FormDomainEvent {
        let input = try await loadDatabasesList(form: form)
        return { [input] form in
            form.inputs[input.id] = AnyInputTemplate(input)
        }
    }
    
    public func send(form: FormModel) async throws -> Void {
        try await repository.post(form: form)
    }
    
    private func loadDatabasesList(form: FormModel) async throws -> OptionsTemplate {
        guard var input: OptionsTemplate = form.inputs.first(tag: .Jira.DatabasesField) else {
            throw FormError.nonLocatedInput(.Jira.DatabasesField)
        }

        let result = try await repository.databases()
        let newOptions = result.map {
            Option(optionId: $0.id, description: $0.name, selected: false)
        }
        
        input.load(options: newOptions, keepSelected: false)
        return input
    }
        
    private func onDatabaseFieldChange(form: FormModel, oldInput: OptionsTemplate, input: OptionsTemplate) async throws -> FormDomainEvent {
        guard input.header.tags.contains(.Jira.DatabasesField) else {
            throw FormError.event(.skip)
        }
        if oldInput.search != input.search, input.config.typingSearch {
            return try await filterByText(form: form, input: input)
        } else if oldInput.value != input.value {
            return try await loadInputsFromJiraDatabase(form: form, input: input)
        }
        throw FormError.event(.skip)
    }
    
    func onChangeRelation(form: FormModel, oldInput: OptionsTemplate, input: OptionsTemplate) async throws -> FormDomainEvent {
        guard input.header.tags.contains(.Jira.ColumnType.relation) else {
            throw FormError.event(.skip)
        }
        guard oldInput.search != input.search, input.config.typingSearch else {
            throw FormError.event(.skip)
        }
        return try await searchPageInJiraDatabaseOnType(form: form, input: input)
    }

        
    private func searchPageInJiraDatabaseOnType(form: FormModel, input: OptionsTemplate) async throws -> FormDomainEvent {
        guard input.header.tags.contains(Tag.Jira.ColumnType.relation), !input.search.isEmpty, let targetId = input.config.targetId else {
            throw FormError.event(.skip)
        }

        try await delay()

        logger.info("SearchPageInJiraDatabaseOnType: init")

        let results = try await repository.searchPages(text: input.search, databaseId: targetId)
        
        var inputCopy = input
        inputCopy.load(options: results, keepSelected: true)
        return { [inputCopy] form in
            form.inputs[input.id] = AnyInputTemplate(inputCopy)
            logger.info("SearchPageInJiraDatabaseOnType: success")
        }
    }
}
