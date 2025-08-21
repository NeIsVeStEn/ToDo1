//
//  ApiManager.swift
//  ToDo1
//
//  Created by Neis on 16.08.2025.
//

import Foundation
import CoreData

struct Todo: Codable {
    let id: Int
    var title: String
    var isCompleted: Bool
    let userId: Int

    enum CodingKeys: String, CodingKey {
        case id
        case title = "todo"
        case isCompleted = "completed"
        case userId
    }
}

extension Todo {
    init(from entity: TodoEntity) {
        self.id = Int(entity.id)
        self.title = entity.title ?? ""
        self.isCompleted = entity.isCompleted
        self.userId = Int(entity.userId)
    }
    
    func toEntity(in context: NSManagedObjectContext) -> TodoEntity {
        let entity = TodoEntity(context: context)
        entity.id = Int32(id)
        entity.title = title
        entity.isCompleted = isCompleted
        entity.userId = Int32(userId)
        entity.createdAt = Date()
        return entity
    }
    
    func updateEntity(_ entity: TodoEntity) {
        entity.title = title
        entity.isCompleted = isCompleted
        entity.userId = Int32(userId)
    }
}

struct TodoResponse: Codable {
    let todos: [Todo]
    let total: Int
    let skip: Int
    let limit: Int
}

final class TodoAPIManager {
    static let shared = TodoAPIManager()
    private let baseURL = URL(string: "https://dummyjson.com/todos")!
    private let urlSession: URLSession
    private let coreDataManager = CoreDataManager.shared
    
    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
    
    
    func fetchTodos(completion: @escaping (Result<[Todo], APIError>) -> Void) {
        let request = URLRequest(url: baseURL)
        urlSession.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(.failure(.networkError(error)))
            return
        }
            guard let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode) else {
                    completion(.failure(.invalidResponse))
                    return
                }
                
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
                
            do {
                let response = try JSONDecoder().decode(TodoResponse.self, from: data)
                CoreDataManager.shared.mergeTodos(serverTodos: response.todos)
                completion(.success(response.todos))
            } catch {
                completion(.failure(.decodingError(error)))
            }
        }.resume()
    }
}

enum APIError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case noData
    case decodingError(Error)
    
    var localizedDescription: String {
        switch self {
        case .invalidURL: return "Неверный URL"
        case .networkError(let error): return "Ошибка сети: \(error.localizedDescription)"
        case .invalidResponse: return "Неверный ответ сервера"
        case .noData: return "Нет данных"
        case .decodingError(let error): return "Ошибка декодирования: \(error.localizedDescription)"
        }
    }
}
