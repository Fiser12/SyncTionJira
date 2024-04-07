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

    public let onChangeEvents: [any TemplateEvent] = []
    
        
    let repository = JiraRepository.shared

    public func load(form: FormModel) async throws -> FormDomainEvent {
        let input = try await loadProjects(form: form)
        return { [input] form in
            form.inputs[input.id] = AnyInputTemplate(input)
        }
    }
    
    public func send(form: FormModel) async throws -> Void {
        try await repository.post(form: form)
    }
    
    private func loadProjects(form: FormModel) async throws -> OptionsTemplate {
        guard var input: OptionsTemplate = form.inputs.first(tag: .Jira.ProjectsListField) else {
            throw FormError.nonLocatedInput(.Jira.ProjectsListField)
        }

        let result = try await repository.projects()
        let newOptions = result.map {
            Option(optionId: $0.id, description: $0.name, selected: false)
        }
        
        input.load(options: newOptions, keepSelected: false)
        return input
    }
}
