//
//  DriveController.swift
//  KaraokePlaylist
//
//  Created by Данияр on 09.07.17.
//  Copyright © 2017 Данияр. All rights reserved.
//

import GoogleAPIClientForREST
import GoogleSignIn
import Alamofire
import UIKit

class DriveController: UITableViewController, GIDSignInDelegate, GIDSignInUIDelegate {
    
    
    // If modifying these scopes, delete your previously saved credentials by
    // resetting the iOS simulator or uninstall the app.
    private let scopes = [kGTLRAuthScopeDriveReadonly]
    
    private let service = GTLRDriveService()
    let signInButton = GIDSignInButton()
    let output = UITextView()
    
    var files:[GTLRDrive_File] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure Google Sign-in.
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().scopes = scopes
        GIDSignIn.sharedInstance().signInSilently()
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!,
              withError error: Error!) {
        if let error = error {
            showAlert(title: "Authentication Error", message: error.localizedDescription)
            self.service.authorizer = nil
        } else {
            self.signInButton.isHidden = true
            self.output.isHidden = false
            self.service.authorizer = user.authentication.fetcherAuthorizer()
            let query = GTLRDriveQuery_FilesList.query()
            query.pageSize = 100
//             query.q = "mimeType='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'"
            service.executeQuery(query,
                                 delegate: self,
                                 didFinish: #selector(displayResultWithTicket(ticket:finishedWithObject:error:))
            )
        }
    }
    
    // Process the response and display output
    func displayResultWithTicket(ticket: GTLRServiceTicket,
                                 finishedWithObject result : GTLRDrive_FileList,
                                 error : NSError?) {
        
        if let error = error {
            showAlert(title: "Error", message: error.localizedDescription)
            return
        }
        
        self.files = result.files!
        
        if self.files.isEmpty {
            showAlert(title: "Каталог пуст", message: "Каталог пуст. Файлы не найдены")
        }
        
        tableView.reloadData()
    }
    
    
    // Helper for showing an alert
    func showAlert(title : String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: UIAlertControllerStyle.alert
        )
        let ok = UIAlertAction(
            title: "OK",
            style: UIAlertActionStyle.default,
            handler: nil
        )
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        //        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
        
        // Add a background view to the table view
//        let backgroundImage = UIImage(named: "bg3.png")
//        let imageView = UIImageView(image: backgroundImage)
//        self.tableView.backgroundView = imageView
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    
    // MARK: - Table View
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        
        let file = files[indexPath.row]
        cell.textLabel!.text = file.name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Показано файлов: \(files.count)"
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        
        header.textLabel?.text = "Показано файлов: \(files.count)"
        header.addSubview(signInButton)
        
        // Add a UITextView to display output.
        output.frame = view.bounds
        output.isEditable = false
        output.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        output.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        output.isHidden = true
        header.addSubview(output);
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //
        let file = files[indexPath.row]
        
//        let destination = DownloadRequest.suggestedDownloadDestination(for: .documentDirectory)
        let url = "https://www.googleapis.com/drive/v3/files/\(file.identifier!)?alt=media"
        let accessToken = GIDSignIn.sharedInstance().currentUser.authentication.accessToken
        
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            var documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            
            // the name of the file here I kept is yourFileName with appended extension
            documentsURL.appendPathComponent(file.name!)
            return (documentsURL, [.removePreviousFile])
        }
        
        Alamofire.download(
            url,
            method: .get,
            parameters: nil,
            encoding: JSONEncoding.default,
            headers: ["Authorization":"Bearer \(accessToken!)"],
            to: destination
        ).downloadProgress(closure: { (progress) in
            //progress closure
        }).response(completionHandler: { (DefaultDownloadResponse) in
            _ = self.navigationController?.popViewController(animated: true)
        })
    }

}
