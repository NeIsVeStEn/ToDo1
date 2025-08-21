//
//  ViewController.swift
//  ToDo1
//
//  Created by Neis on 14.08.2025.
//

import UIKit

class ViewController: UIViewController {

    private let tableView = UITableView()
    private var todos: [Todo] = []
    private var filteredTodos: [Todo] = []
    private let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupNavigationBar()
        setupSearchController()
        loadData()
    }
    
    private func loadData() {
        let cachedTodos = CoreDataManager.shared.fetchTodos()
        if !cachedTodos.isEmpty {
            self.todos = cachedTodos
            self.tableView.reloadData()
        }
        
        TodoAPIManager.shared.fetchTodos { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                    case .success(let serverTodos):
                        CoreDataManager.shared.mergeTodos(serverTodos: serverTodos)
                        self?.todos = CoreDataManager.shared.fetchTodos()
                        self?.tableView.reloadData()
                    case .failure(let error):
                        print("Ошибка загрузки: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TodoTableViewCell.self, forCellReuseIdentifier: TodoTableViewCell.reuseID)
        view.addSubview(tableView)
        tableView.frame = view.bounds
        tableView.contentInsetAdjustmentBehavior = .automatic
    }
    
    private func setupNavigationBar() {
        navigationItem.title = "Задачи"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        let paragraphStyle = NSMutableParagraphStyle()
        navigationController?.navigationBar.largeTitleTextAttributes = [
            .paragraphStyle: paragraphStyle,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
    
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addNewTodo)
        )
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(refreshData)
        )
    }
    
    @objc private func addNewTodo() {
        showEditScreen(todo: nil)
    }
    
    @objc private func refreshData() {
        loadData()
    }
    
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Поиск задач"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    private var isSearching: Bool {
        return searchController.isActive && !(searchController.searchBar.text?.isEmpty ?? true)
    }
    
    private func deleteTodoLocally(at indexPath: IndexPath) {
        if isSearching {
            let todoToDelete = filteredTodos[indexPath.row]
            if let indexInMain = todos.firstIndex(where: { $0.id == todoToDelete.id }) {
                todos.remove(at: indexInMain)
                CoreDataManager.shared.deleteTodo(id: todoToDelete.id)
            }
            filteredTodos.remove(at: indexPath.row)
        } else {
            let todoToDelete = todos[indexPath.row]
            todos.remove(at: indexPath.row)
            CoreDataManager.shared.deleteTodo(id: todoToDelete.id)
        }
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }
    
    private func toggleTodoCompletion(at indexPath: IndexPath) {
        var todoToUpdate: Todo
        
        if isSearching {
            let todo = filteredTodos[indexPath.row]
            if let indexInMain = todos.firstIndex(where: { $0.id == todo.id }) {
                todos[indexInMain].isCompleted.toggle()
                todoToUpdate = todos[indexInMain]
                filteredTodos[indexPath.row].isCompleted.toggle()
            } else {
                return
            }
        } else {
            todos[indexPath.row].isCompleted.toggle()
            todoToUpdate = todos[indexPath.row]
        }
        CoreDataManager.shared.updateTodo(todoToUpdate)
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    private func showEditScreen(for indexPath: IndexPath? = nil, todo: Todo? = nil) {
        let editVC = TodoEditViewController()
        
        if let indexPath = indexPath {
            // Редактирование существующей задачи
            let currentTodo = isSearching ? filteredTodos[indexPath.row] : todos[indexPath.row]
            editVC.todo = currentTodo
            editVC.completionHandler = { [weak self] updatedTitle in
                var updatedTodo = currentTodo
                updatedTodo.title = updatedTitle
                self?.updateTodoLocally(updatedTodo, at: indexPath)
            }
        } else if let todo = todo {
            // Редактирование переданной задачи
            editVC.todo = todo
            editVC.completionHandler = { [weak self] updatedTitle in
                var updatedTodo = todo
                updatedTodo.title = updatedTitle
                self?.updateTodoLocally(updatedTodo, at: nil)
            }
        } else {
            // Создание новой задачи (только локально)
            editVC.completionHandler = { [weak self] title in
                self?.createNewTodoLocally(title: title)
            }
        }
        navigationController?.pushViewController(editVC, animated: true)
    }
    
    private func createNewTodoLocally(title: String) {
        let newTodo = CoreDataManager.shared.createLocalTodo(title: title, userId: 1)
            todos.insert(newTodo, at: 0)
            tableView.reloadData()
    }
    
    private func updateTodoLocally(_ todo: Todo, at indexPath: IndexPath?) {
        if let indexInMain = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[indexInMain] = todo
        }
        
        if isSearching,
           let indexInFiltered = filteredTodos.firstIndex(where: { $0.id == todo.id }) {
            filteredTodos[indexInFiltered] = todo
        }
        CoreDataManager.shared.updateTodo(todo)
        if let indexPath = indexPath {
            tableView.reloadRows(at: [indexPath], with: .automatic)
        } else {
            tableView.reloadData()
        }
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: TodoTableViewCell.reuseID,
            for: indexPath
        ) as? TodoTableViewCell else {
            fatalError("Ячейка не зарегистрирована")
        }
            
        let todo = isSearching ? filteredTodos[indexPath.row] : todos[indexPath.row]
        cell.configure(with: todo, date: Date())
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ? filteredTodos.count : todos.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        toggleTodoCompletion(at: indexPath)
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            let editAction = UIAction(
                title: "Редактировать",
                image: UIImage(systemName: "pencil")
            ) { [weak self] action in
                self?.showEditScreen(for: indexPath)
            }
            
            let deleteAction = UIAction(
                title: "Удалить",
                image: UIImage(systemName: "trash"),
                attributes: .destructive
            ) { _ in
                self?.deleteTodoLocally(at: indexPath)
            }
            
            return UIMenu(title: "", children: [editAction, deleteAction])
        }
    }
}

extension ViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text?.lowercased() else {
            filteredTodos = []
            tableView.reloadData()
            return
        }
        filteredTodos = todos.filter {
            $0.title.lowercased().contains(searchText)
        }
        tableView.reloadData()
    }
}
