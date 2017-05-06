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

class ViewController: UIViewController, SRWebSocketDelegate, UITableViewDataSource {
    
    var socket : SRWebSocket?
    var items : Array<Message> = []

    @IBOutlet weak var disconnectedMask: UIView!
    @IBOutlet weak var nickname: UITextField!
    @IBOutlet weak var connectButton: UIButton!
    
    @IBOutlet weak var responseLabel: UITableView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var messageInput: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Initialized"
        self.responseLabel.register(UINib(nibName: "ItemCell", bundle: nil), forCellReuseIdentifier: "ItemCell")
        self.responseLabel.estimatedRowHeight = 90
        self.responseLabel.rowHeight = UITableViewAutomaticDimension
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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        socket?.delegate = nil
        socket?.close()
        self.showDisconnectedView(show: false)
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
    }
    
    @IBAction func disconnect(_ sender: Any) {
        socket?.close()
        socket = nil
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
        
        socket = SRWebSocket(url: URL(string: "ws://192.168.1.162:8080/order"))
        socket?.delegate = self
        
        self.title = "Connecting..."
        socket?.open()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : ItemCell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath) as! ItemCell
        cell.loadFromData(items[indexPath.row])
        return cell
    }
    
    func addItem(title: String, message: String? = nil) {
        NSLog("\(title) - \(message ?? "")")
        items.append(Message(title: title, message: message))
        self.responseLabel.reloadData()
    }
    
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
        self.title = "Disconnected"
        self.showDisconnectedView(show: false)
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
        self.showDisconnectedView(show: false)
    }
    
    func showDisconnectedView(show: Bool) {
        disconnectedMask.isHidden = !show
        if(!show) {
            socket = nil
            self.nickname.text = ""
        }
    }
}

