//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

// model data structure

struct SpecialColumn {
    struct Topic {
        let name: String
        let url: URL
    }
    
    let name: String
    var topics: [Topic]
}

extension SpecialColumn: CustomStringConvertible {
    var description: String {
        let topicsDescription = topics.reduce("") {
            $0 + "\n" + $1.name
        }
        return "Special column \(name) \(topicsDescription)"

    }
}

enum SerializationError: Error {
    case missing(String)
    case invalid(String, Any)
}

// throwing initializer
extension SpecialColumn {
    init(_ json: [String: Any]) throws {
        
        guard let name = json["name"] as? String else {
            throw SerializationError.missing("name")
        }
        self.name = name
        
        guard let topics = json["topics"] as? Array<[String: Any]> else {
            throw SerializationError.missing("topics")
        }
        var _topics = [Topic]()
        for topic in topics {
            guard let topicName = topic["name"] as? String else {
                throw SerializationError.missing("topic name")
            }
            guard let topicURLString = topic["url"] as? String else {
                throw SerializationError.missing("topic url")
            }
            guard let topicURL = URL(string: topicURLString) else {
                throw SerializationError.invalid("topic url", topicURLString)
            }

            _topics.append(Topic(name: topicName, url: topicURL))
        }
        self.topics = _topics
    }
}

// static type method updating topics
extension SpecialColumn {
    static func updateTopics(completion: @escaping ([SpecialColumn]) -> Void) {
        let url = URL(string: "https://zhuanlan.zhihu.com/api/columns/jiguang-daily")!
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let task = session.dataTask(with: url, completionHandler: { (data, response, error) in
            let json = try? JSONSerialization.jsonObject(with: data!, options: [])
            if let root = json as? [String: Any] {
                let specialColumn = try? SpecialColumn(root)
                completion([specialColumn!])
            }
        })
        task.resume()
    }
}




//------------------------------------------//

class ColumnTableViewController: UITableViewController {
    
//    var specialColumns: [SpecialColumn]? = ["special 1", "special 2", "special 3"].map { special in
//        let topics = ["topic 1", "topic2", "topic 3"].map {
//            SpecialColumn.Topic(name: $0, url: URL(string: "www.google.com")!)
//        }
//        return SpecialColumn(name: special, topics: topics)
//    }

    
    var specialColumns: [SpecialColumn]? {
        didSet {
            tableView.reloadData()
        }
    }
    
    let cell = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: "SpecialColumn")
    
    //how many rows in section
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return specialColumns?[0].topics.count ?? 0
    }
    
    //table view cell preparation
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "SpecialColumn")
        if cell?.detailTextLabel == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "SpecialColumn")
        }
        cell?.textLabel?.text = specialColumns?[indexPath.section].topics[indexPath.row].name
        cell!.detailTextLabel!.text = specialColumns?[indexPath.section].topics[indexPath.row].url.description
        return cell ?? UITableViewCell()
    }
    
    //Initialize special column data
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SpecialColumn")
        SpecialColumn.updateTopics { sc in
            DispatchQueue.main.async {
                print(sc)
                self.specialColumns = sc
            }
        }
    }
}

let columnController = ColumnTableViewController()
PlaygroundPage.current.liveView = columnController

