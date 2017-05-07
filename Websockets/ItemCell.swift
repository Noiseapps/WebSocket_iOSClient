import UIKit

class ItemCell: UITableViewCell {

    @IBOutlet weak var label: UILabel!
    
    func loadFromData(_ data : Message) {
        if(data.title == "Status") {
            self.contentView.backgroundColor = UIColor.green.withAlphaComponent(0.25)
        } else {
            self.contentView.backgroundColor = UIColor.blue.withAlphaComponent(0.25)
        }
        let content = "\(data.title) - \(data.message ?? "")"
        label.text = content
    }
    
}
