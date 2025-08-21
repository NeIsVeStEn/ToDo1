//
//  ViewTable.swift
//  ToDo1
//
//  Created by Neis on 17.08.2025.
//

import UIKit

class TodoEditViewController: UIViewController {
    
    var todo: Todo?
    var completionHandler: ((String) -> Void)?
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 18)
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let idLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Флаг для отслеживания изменений
    private var hasUnsavedChanges = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupData()
        setupNavigationBar()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        titleTextView.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        saveIfNeeded()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        titleTextView.delegate = self
        
        view.addSubview(containerView)
        containerView.addSubview(titleTextView)
        containerView.addSubview(dateLabel)
        containerView.addSubview(idLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            titleTextView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 40),
            titleTextView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleTextView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            dateLabel.topAnchor.constraint(equalTo: titleTextView.bottomAnchor, constant: 20),
            dateLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            dateLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            idLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 10),
            idLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            idLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            idLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupNavigationBar() {
        if todo != nil {
            title = "Редактировать"
        } else {
            title = "Новая задача"
        }
        
    }
    
    private func setupData() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        if let todo = todo {
            titleTextView.text = todo.title
            dateLabel.text = "Создано: \(dateFormatter.string(from: Date()))"
            idLabel.text = "ID: \(todo.id), User ID: \(todo.userId)"
        } else {
            dateLabel.text = "Создано: \(dateFormatter.string(from: Date()))"
            idLabel.text = nil
        }
        
    }
    
    private func saveIfNeeded() {
        guard hasUnsavedChanges,
              let text = titleTextView.text,
              !text.isEmpty else {
            return
        }
        completionHandler?(text)
        hasUnsavedChanges = false
    }
    
}
extension TodoEditViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if let text = textView.text, !text.isEmpty {
                    hasUnsavedChanges = true
                } else {
                    hasUnsavedChanges = false
                }
    }
}
