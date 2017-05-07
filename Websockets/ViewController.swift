import UIKit
import SocketRocket

class Message {
    
    required init(title: String, message: String? = nil) {
        self.title = title
        self.message = message
    }
    
    let title : String
    let message: String?
    
    func asDict() -> Dictionary<String, String> {
        return [
            "title": self.title,
            "message": self.message ?? ""
        ]
    }
}

class ViewController: UIViewController, SRWebSocketDelegate, UITableViewDataSource, UITableViewDelegate {
    
    var socket : SRWebSocket?
    var items : Array<Message> = []

    @IBOutlet weak var disconnectedMask: UIView!
    @IBOutlet weak var serverAddress: UITextField!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var nickname: UITextField!
    @IBOutlet weak var connectButton: UIButton!
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var messagesList: UITableView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var messageInput: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "WebSockets testflight"
        self.messagesList.register(UINib(nibName: "ItemCell", bundle: nil), forCellReuseIdentifier: "ItemCell")
//        self.messagesList.estimatedRowHeight = 60
//        self.messagesList.rowHeight = 60
    }
    
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func keyboardDidShow(_ notification : Notification) {
        if let userInfo = notification.userInfo {
            let keyboardSize: CGSize = (userInfo[UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue.size
            self.view.layoutIfNeeded()
            self.bottomConstraint.constant = keyboardSize.height
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func keyboardDidHide(_ notification : Notification) {
        self.view.layoutIfNeeded()
        self.bottomConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        socket?.delegate = nil
        socket?.close()
        self.showDisconnectedView(show: false)
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func onTap(_ sender: Any) {
        nickname.resignFirstResponder()
        messageInput.resignFirstResponder()
    }
    
    @IBAction func onConnectButton(_ sender: Any) {
        self.reconnect();
    }

    @IBAction func sendSocketMessage(_ sender: Any) {
        self.sendMessage(title: messageInput.text!)
        messageInput.text = ""
    }
    
    @IBAction func disconnect(_ sender: Any) {
        socket?.close()
        socket = nil
        self.showDisconnectedView(show: true)
    }
    
    func sendMessage(title: String, message: String? = nil) {
        let message = Message(title: title, message: message)
        do {
            let msgData = try JSONSerialization.data(withJSONObject: message.asDict(), options: [])
            let msgString = String(data: msgData, encoding: .utf8)
            socket?.send(msgString)
        } catch {
            self.addItem(title: "Serialize failed")
        }
    }
    
    func reconnect() {
        socket?.delegate = nil
        socket?.close()
        
        if let address = serverAddress.text?.characters.count ?? 0 > 0 ? serverAddress.text : "192.168.1.162:8080" {
            socket = SRWebSocket(url: URL(string: "ws://\(address)/order"))
            socket?.delegate = self
            self.title = "Connecting..."
            socket?.open()
        } else {
            statusLabel.text = "Invalid address"
        }
    }
    
    func addItem(title: String, message: String? = nil) {
        DispatchQueue.main.async(execute: {
            NSLog("\(title) - \(message ?? "")")
            self.items.append(Message(title: title, message: message))
            let indexPath = IndexPath(row: self.items.count - 1, section: 0)
//            self.messagesList.beginUpdates()
            self.messagesList.insertRows(at: [indexPath], with: .top)
//            self.messagesList.endUpdates()
            self.messagesList.scrollToRow(at: indexPath, at: .bottom, animated: true)
        })
    }
    
    //MARK: - tableview delegate
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : ItemCell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath) as! ItemCell
        cell.loadFromData(items[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let data = items[indexPath.row]
        let content = "\(data.title) - \(data.message ?? "")"
        return content.height(withConstrainedWidth: self.view.frame.width - 32, font: UIFont.systemFont(ofSize: 13)) + 32
    }
    
    //MARK: - websocket delegate
    
    func webSocketDidOpen(_ webSocket: SRWebSocket!) {
        let message = "Connection opened"
        self.addItem(title: "Status", message: message)
        self.title = "Connected"
        disconnectedMask.isHidden = true
        self.sendMessage(title: "handshake", message: nickname.text)
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        let message = "Connection closed with code: \(code) because of: \(reason)"
        self.addItem(title: "Status", message: message)
        self.showDisconnectedView(show: true)
        statusLabel.text = message
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didReceiveMessage message: Any!) {
        if let msg = self.convertToDictionary(text: message as! String) {
            self.addItem(title: msg["title"] as! String, message: msg["message"] as? String)
        }
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didFailWithError error: Error!) {
        let message = "Connection failed because of: \(error.localizedDescription)"
        self.addItem(title: "Status", message: message)
        self.title = "Not connected"
        self.showDisconnectedView(show: true)
        statusLabel.text = message
    }
    
    func showDisconnectedView(show: Bool) {
        disconnectedMask.isHidden = !show
        if(!show) {
            socket = nil
            self.nickname.text = ""
        } else {
            self.title = "WebSockets testflight"
        }
    }
}

