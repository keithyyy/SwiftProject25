//
//  ViewController.swift
//  Project25
//
//  Created by Keith Crooc on 2022-01-29.
//

import UIKit
// need to import our Multipeer framework
import MultipeerConnectivity


// CHALLENGE
// 1. Show an alert when a user has disconnected from our multipeer network. Something like “Paul’s iPhone has disconnected” is enough. ✅

// 2. Try sending text messages across the network. You can create a Data from a string using Data(yourString.utf8), and convert a Data back to a string by using String(decoding: yourData, as: UTF8.self). ✅

// 3. Add a button that shows an alert controller listing the names of all devices currently connected to the session – use the connectedPeers property of your session to find that information.


class ViewController: UICollectionViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, MCSessionDelegate, MCBrowserViewControllerDelegate, MCNearbyServiceAdvertiserDelegate {


    

    var images = [UIImage]()
    
    
//    challenge 2
    var message = ""
    
//    creating instances for our Multipeer Connectivity
    var peerID = MCPeerID(displayName: UIDevice.current.name)
    var mcSession: MCSession?
//    var mcAdvertiserAssistant: MCAdvertiserAssistant?
    var mcAdvertiserAssistant: MCNearbyServiceAdvertiser!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        initialize our MCSession so we're able to make connections
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
//        we'll also need our ViewController to conform to to MCSessionDelegate and MCBrowserViewControllerDelegate protocols
        mcSession?.delegate = self
        
        
        
        
        title = "Selfie Share"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(importPhoto))
        
        
        let message = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(sendText))
        let join = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showConnectionPrompt))
//        button to ask users whether they want to connect to an existing session with others.
        
        
//        challenge 2 - send a text message across network
        navigationItem.leftBarButtonItems = [join, message]
        
        
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageView", for: indexPath)
        
        if let imageView = cell.viewWithTag(1000) as? UIImageView {
            imageView.image = images[indexPath.item]
        }
        
        return cell
    }

    @objc func importPhoto() {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
        
    }
    
//    method to ask users if they want to a join a 'Selfie Share' session
    @objc func showConnectionPrompt() {
        let ac = UIAlertController(title: "Connect to others", message: nil, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Host a session", style: .default, handler: startHosting))
        ac.addAction(UIAlertAction(title: "Join a session", style: .default, handler: joinSession))
        ac.addAction(UIAlertAction(title: "Leave session", style: .default, handler: leaveSession))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }
    
//      CHALLENGE 2
//        text message function
    @objc func sendText() {
        let ac = UIAlertController(title: "Send Message", message: nil, preferredStyle: .alert)
        ac.addTextField()
        
        let sendMessage = UIAlertAction(title: "Send", style: .default) {
            [unowned ac]_ in
            guard let textMessage = ac.textFields![0].text else { return }
            self.message = textMessage
            self.broadcastMessage(message: textMessage)
            
            
        }
        
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(sendMessage)
        present(ac, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }
        dismiss(animated: true)
        
        images.insert(image, at: 0)
        collectionView.reloadData()
        
        guard let mcSession = mcSession else {
            return
        }
        
        if mcSession.connectedPeers.count > 0 {
            
            if let imageData = image.pngData() {
                
                do {
                    try mcSession.send(imageData, toPeers: mcSession.connectedPeers, with: .reliable)
                    
                } catch {
                    let ac = UIAlertController(title: "Send error", message: error.localizedDescription, preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "Dismiss", style: .default))
                    present(ac, animated: true)
                }
            }
        }
    }
    
    func startHosting(action: UIAlertAction) {
        print("creating session...")
        guard let mcSession = mcSession else {
            return
        }
        
        mcAdvertiserAssistant = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: "cnk-project25")
        mcAdvertiserAssistant.delegate = self
        mcAdvertiserAssistant.startAdvertisingPeer()
        

    }
    
    func joinSession(action: UIAlertAction) {
        print("joining session...")
        guard let mcSession = mcSession else {
            return
        }
        
        let mcBrowser = MCBrowserViewController(serviceType: "cnk-project25", session: mcSession)
        mcBrowser.delegate = self
        present(mcBrowser, animated: true)
    }
    
//    challenge 1. Handler for when user taps leave session option, it'll disconnect the current session.
    func leaveSession(action: UIAlertAction) {
        guard let mcSession = mcSession else {
            let ac = UIAlertController(title: "No Session in progress", message: nil, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Dismiss", style: .cancel))
            
            return
        }
        
        mcSession.disconnect()
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            print("Connected: \(peerID.displayName)")
        case .connecting:
            print("Connecting: \(peerID.displayName)")
        case .notConnected:
//            challenge 1 - when user disconnects, show alert
//            here you get an error when things get connected. Need to call on the main thread for this.
            DispatchQueue.main.async {
                [weak self] in
                let disconnectedAC = UIAlertController(title: "User disconnected", message: "\(peerID.displayName) has disconnected", preferredStyle: .alert)
                disconnectedAC.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(disconnectedAC, animated: true)
            }
            

            print("Disconnected: \(peerID.displayName)")
            
            
            
        @unknown default:
            print("Unknown state received: \(peerID.displayName)")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            [weak self] in
            
//            2.  Try sending text messages across the network. You can create a Data from a string using Data(yourString.utf8), and convert a Data back to a string by using String(decoding: yourData, as: UTF8.self).
            let textDataToString = String(decoding: data, as: UTF8.self)
            
            if let image = UIImage(data: data) {
                self?.images.insert(image, at: 0)
                self?.collectionView.reloadData()
            }
            
            if textDataToString != "" {
                let ac = UIAlertController(title: "Message", message: textDataToString, preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "Dismiss", style: .default))
                self?.present(ac, animated: true)
            }
        }
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Invitation Received"
        
        let ac = UIAlertController(title: appName, message: "\(peerID.displayName) wants to connect", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Decline", style: .cancel, handler: { [weak self] _ in invitationHandler(false, self?.mcSession)}))
        ac.addAction(UIAlertAction(title: "Accept", style: .default, handler: { [weak self] _ in invitationHandler(true, self?.mcSession)}))
        
        present(ac, animated: true)
    }
    
    func disconnectedPrompt(peerID: MCPeerID) {
        let ac = UIAlertController(title: "User disconnected", message: "\(peerID.displayName) has disconnected", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        
    }
    
//  2.  Try sending text messages across the network. You can create a Data from a string using Data(yourString.utf8), and convert a Data back to a string by using String(decoding: yourData, as: UTF8.self).
    func broadcastMessage(message: String) {
        guard let mcSession = mcSession else {
            return
        }
        
        let textData = Data(message.utf8)
        
        if mcSession.connectedPeers.count > 0 {
            
            if message != ""  {
                
                do {
                    try mcSession.send(textData, toPeers: mcSession.connectedPeers, with: .reliable)
                    
                } catch {
                    let ac = UIAlertController(title: "Send error", message: error.localizedDescription, preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "Dismiss", style: .default))
                    present(ac, animated: true)
                }
            }
        }

    }
    
    
  

}

