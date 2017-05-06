import UIKit

class ItemCell: UITableViewCell {

    @IBOutlet weak var label: UILabel!
    
    func loadFromData(_ data : Message) {
        let content = "\(data.title) - \(data.message ?? "")"
        label.text = content
    }
    
}
