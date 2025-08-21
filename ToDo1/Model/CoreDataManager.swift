//
//  CoreDataManager.swift
//  ToDo1
//
//  Created by Neis on 20.08.2025.
//

import CoreData

final class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ToDo1")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func saveContext() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
    
    func saveTodos(_ todos: [Todo]) {
        let context = viewContext
            context.perform {
                self.deleteAllTodos()
                for todo in todos {
                    _ = todo.toEntity(in: context)
                }
        }
    }
    
    func fetchTodos() -> [Todo] {
        let context = viewContext
        let fetchRequest: NSFetchRequest<TodoEntity> = TodoEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            let entities = try context.fetch(fetchRequest)
            return entities.map { Todo(from: $0) }
        } catch {
            print("Error fetching todos: \(error)")
            return []
        }
    }
    
    func createLocalTodo(title: String, userId: Int) -> Todo {
        let context = viewContext
        let newId = generateNegativeId()
        let newTodo = Todo(id: newId, title: title, isCompleted: false, userId: userId)
        
        _ = newTodo.toEntity(in: context)
        saveContext()
        
        return newTodo
    }
    
    func updateTodo(_ todo: Todo) {
        let context = viewContext
        let fetchRequest: NSFetchRequest<TodoEntity> = TodoEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %d", todo.id)
        
        do {
            if let entity = try context.fetch(fetchRequest).first {
                todo.updateEntity(entity)
                try context.save()
            }
        } catch {
            print("Error updating todo: \(error)")
        }
    }
    
    func deleteTodo(id: Int) {
        let context = viewContext
        let fetchRequest: NSFetchRequest<TodoEntity> = TodoEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %d", id)
        
        do {
            if let entity = try context.fetch(fetchRequest).first {
                context.delete(entity)
                try context.save()
            }
        } catch {
            print("Error deleting todo: \(error)")
        }
    }
    
    func deleteAllTodos() {
        let context = viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = TodoEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            print("Error deleting all todos: \(error)")
        }
    }
    
    func mergeTodos(serverTodos: [Todo]) {
        let context = persistentContainer.viewContext
        let localTodos = fetchTodoEntities()
        let serverTodosDict = Dictionary(uniqueKeysWithValues: serverTodos.map { ($0.id, $0) })
        for serverTodo in serverTodos {
            if let localEntity = localTodos.first(where: { $0.id == serverTodo.id }) {
                localEntity.title = serverTodo.title
                localEntity.isCompleted = serverTodo.isCompleted
                localEntity.userId = Int32(serverTodo.userId)
            } else {
                _ = serverTodo.toEntity(in: context)
            }
        }
        for localEntity in localTodos {
            if localEntity.id > 0 && serverTodosDict[Int(localEntity.id)] == nil {
                context.delete(localEntity)
            }
        }
        
        do {
            try context.save()
        } catch {
            print("Ошибка при объединении данных: \(error)")
        }
    }
    
    private func fetchTodoEntities() -> [TodoEntity] {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<TodoEntity> = TodoEntity.fetchRequest()
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Ошибка при получении TodoEntity: \(error)")
            return []
        }
    }
    
    private func generateNegativeId() -> Int {
        let fetchRequest: NSFetchRequest<TodoEntity> = TodoEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id < 0")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        
        do {
            let localTodos = try viewContext.fetch(fetchRequest)
            if let minId = localTodos.map({ Int($0.id) }).min() {
                return minId - 1
            }
        } catch {
            print("Error fetching local todos: \(error)")
        }
        
        return -1 
    }
}
