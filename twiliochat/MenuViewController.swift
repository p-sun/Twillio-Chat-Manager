import UIKit

class MenuViewController: UIViewController {
    static let TWCOpenChannelSegue = "OpenChat"
    static let TWCRefreshControlXOffset: CGFloat = 120
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var usernameLabel: UILabel!
    
    var refreshControl: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let bgImage = UIImageView(image: UIImage(named:"home-bg"))
        bgImage.frame = self.tableView.frame
        tableView.backgroundView = bgImage
        
        usernameLabel.text = MessagingManager.sharedManager().userIdentity
        
        refreshControl = UIRefreshControl()
        tableView.addSubview(refreshControl)
        refreshControl.addTarget(self, action: #selector(MenuViewController.refreshChannels), for: .valueChanged)
        refreshControl.tintColor = UIColor.white
        
        self.refreshControl.frame.origin.x -= MenuViewController.TWCRefreshControlXOffset
        ChannelAccessManager.sharedManager.delegate = self
        reloadChannelList()
    }
    
    // MARK: - Internal methods
    
    func loadingCellForTableView(tableView: UITableView) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "loadingCell")!
    }
    
    func channelCellForTableView(tableView: UITableView, atIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let menuCell = tableView.dequeueReusableCell(withIdentifier: "channelCell", for: indexPath as IndexPath) as! MenuTableCell
        
        if let channel = ChannelAccessManager.sharedManager.channelManager.channel(index: indexPath.row) {
            var friendlyName = channel.friendlyName //(channel as AnyObject).friendlyName
            
            if let name = friendlyName, name.isEmpty {
                friendlyName = name
            }
            menuCell.channelName = friendlyName!
        }
        
        return menuCell
    }
    
    func reloadChannelList() {
        tableView.reloadData()
        refreshControl.endRefreshing()
    }
    
    func refreshChannels() {
        refreshControl.beginRefreshing()
        reloadChannelList()
    }
    
    func deselectSelectedChannel() {
        let selectedRow = tableView.indexPathForSelectedRow
        if let row = selectedRow {
            tableView.deselectRow(at: row, animated: true)
        }
    }
    
    // MARK: - Channel
    
    func createNewChannelDialog() {
        InputDialogController.showWithTitle(title: "New Channel",
                                            message: "Enter a name for this channel",
                                            placeholder: "Name",
                                            presenter: self) { text in
                                                ChannelAccessManager.sharedManager.createChannelWithName(name: text, completion: { _,_ in
                                                    ChannelAccessManager.sharedManager.populateChannels()
                                                })
        }
    }
    
    // MARK: Logout
    
    func promptLogout() {
        let alert = UIAlertController(title: nil, message: "You are about to Logout", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { action in
            self.logOut()
        }
        
        alert.addAction(cancelAction)
        alert.addAction(confirmAction)
        present(alert, animated: true, completion: nil)
    }
    
    func logOut() {
        MessagingManager.sharedManager().logout()
        MessagingManager.sharedManager().presentRootViewController()
    }
    
    // MARK: - Actions
    
    @IBAction func logoutButtonTouched(_ sender: UIButton) {
        promptLogout()
    }
    
    @IBAction func newChannelButtonTouched(_ sender: UIButton) {
        createNewChannelDialog()
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == MenuViewController.TWCOpenChannelSegue {
            let indexPath = sender as! NSIndexPath
            
            guard let channel = ChannelAccessManager.sharedManager.channelManager.channel(index: indexPath.row) else {
                print("Could not find channel @ indexPath.row")
                return
            }
            
            let navigationController = segue.destination as! UINavigationController
            (navigationController.visibleViewController as! MainChatViewController).channel = channel
        }
    }
    
    // MARK: - Style
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

// MARK: - UITableViewDataSource
extension MenuViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = ChannelAccessManager.sharedManager.channelManager.numberOfChannels()
        return count == 0 ? 1 : count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        
        if ChannelAccessManager.sharedManager.channelManager.numberOfChannels() == 0 {
            cell = loadingCellForTableView(tableView: tableView)
        }
        else {
            cell = channelCellForTableView(tableView: tableView, atIndexPath: indexPath as NSIndexPath)
        }
        
        cell.layoutIfNeeded()
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if let channel = ChannelAccessManager.sharedManager.channelManager.channel(index: indexPath.row) {
            return channel != ChannelAccessManager.sharedManager.generalChannel
        }
        return false
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle,
                   forRowAt indexPath: IndexPath) {
        if editingStyle != .delete {
            return
        }
        
        if let channel = ChannelAccessManager.sharedManager.channelManager.channel(index: indexPath.row) {
            channel.destroy { result in
                if (result?.isSuccessful())! {
                    tableView.reloadData()
                } else {
                    AlertDialogController.showAlertWithMessage(message: "You can not delete this channel", title: nil, presenter: self)
                }
            }
        }
    }
}

// MARK: - UITableViewDelegate
extension MenuViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: MenuViewController.TWCOpenChannelSegue, sender: indexPath)
    }
}

// MARK: - TwilioChatClientDelegate
extension MenuViewController : TwilioChatClientDelegate {
    func chatClient(_ client: TwilioChatClient!, channelAdded channel: TCHChannel!) {
        tableView.reloadData()
    }
    
    func chatClient(_ client: TwilioChatClient!, channelChanged channel: TCHChannel!) {
        tableView.reloadData()
    }
    
    func chatClient(_ client: TwilioChatClient!, channelDeleted channel: TCHChannel!) {
        tableView.reloadData()
    }
}
