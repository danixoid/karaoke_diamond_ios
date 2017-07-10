//
//  OptionsController.swift
//  KaraokePlaylist
//
//  Created by Данияр on 06.07.17.
//  Copyright © 2017 Данияр. All rights reserved.
//

import UIKit
import SQLite
import FileBrowser

class OptionsController: UITableViewController {
    
    let path = NSSearchPathForDirectoriesInDomains(
        .documentDirectory, .userDomainMask, true
        ).first!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        
        let db = try! Connection("\(self.path)/db.sqlite3")
        let karaoke = Table("karaoke")
        let id = Expression<Int64>("id")
        let comp_id = Expression<String?>("comp_id")
        let artist = Expression<String>("artist")
        let song = Expression<String>("song")
        let quality = Expression<String>("quality")
        
        try! db.run(karaoke.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(comp_id, unique: true)
            t.column(artist)
            t.column(song)
            t.column(quality)
        })
        
        let count = try! db.scalar(karaoke.count)
        
        header.textLabel?.text = "Всего записей: \(count)"
    }

    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            let fileBrowser = FileBrowser()
            present(fileBrowser, animated: true, completion: nil)
            
            fileBrowser.didSelectFile = { (file: FBFile) -> Void in
                self.loadXLSFile(xlsPath: file.filePath.path)
                print(file.filePath.path)
            }
            _ = navigationController?.popViewController(animated: true)
        }
        
        if indexPath.row == 1 {
            clearDB()
        }
        
        if indexPath.row == 2 {
            
            struct defaultsKeys {
                static let pswd = "password"
            }
            let defaults = UserDefaults.standard


            let newWordPrompt = UIAlertController(title: "Администрирование", message: "Введите пароль!", preferredStyle: UIAlertControllerStyle.alert)
            
            newWordPrompt.addTextField(configurationHandler: { (textField: UITextField!) in
                textField.placeholder = "Введите пароль"
            })
            
            newWordPrompt.addTextField(configurationHandler: { (textField: UITextField!) in
                textField.placeholder = "Повторите пароль"
            })

            newWordPrompt.addAction(UIAlertAction(title: "Отмена", style: UIAlertActionStyle.default, handler: nil))
            newWordPrompt.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: {
                alert -> Void in
                
                let passField = newWordPrompt.textFields![0] as UITextField
                let passConrirmField = newWordPrompt.textFields![1] as UITextField
                
                if passField.text == passConrirmField.text {
                    defaults.set(passField.text,forKey: defaultsKeys.pswd)
                } else {
                    self.present(newWordPrompt, animated: true, completion: nil)
                }
                
            }))
            
            self.present(newWordPrompt, animated: true, completion: nil)
        }
        
        if indexPath.row == 3 {
            self.performSegue(withIdentifier: "googledrive", sender: self)
        }
        
        

    }
    
    
    private func loadXLSFile(xlsPath: String) {
        let db = try! Connection("\(self.path)/db.sqlite3")
        let karaoke = Table("karaoke")
        
        let id = Expression<Int64>("id")
        let comp_id = Expression<String?>("comp_id")
        let artist = Expression<String>("artist")
        let song = Expression<String>("song")
        let quality = Expression<String>("quality")
        
        try! db.run(karaoke.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(comp_id, unique: true)
            t.column(artist)
            t.column(song)
            t.column(quality)
        })
        
        
        print("ГЛАВНЫЙ ПУТЬ \(xlsPath)")
        
//        if(xlsPath.hasSuffix("xls"))
        let reader = DHxlsReader.xlsReader(withPath: xlsPath)
        
        if(reader != nil) {
            
            for j in 0...(reader?.numberOfSheets())! {
                
                
                let _numrow = reader?.rowsForSheet(at: j) ?? 0
                print("Строк \(_numrow)")
                
                reader?.startIterator(j)
                var i:UInt16 = 1
                    
                while(i < (reader?.numberOfRows(inSheet: j))!) {
                    let _comp_id = reader?.cell(inWorkSheetIndex: j, row: i, col: 1).str
                    let _song = reader?.cell(inWorkSheetIndex: j, row: i, col: 2).str ?? ""
                    let _artist = reader?.cell(inWorkSheetIndex: j, row: i, col: 3).str ?? ""
                    let _quality = reader?.cell(inWorkSheetIndex: j, row: i, col: 4).str ?? ""
                    print("\(_comp_id ?? "") \(_song) \(_artist) \(_quality)")
                    
                    i = i + 1
                    
                    do {
                        try db.run(karaoke.insert(
                            or: .replace,
                            comp_id <- _comp_id,
                            song <- _song,
                            artist <- _artist,
                            quality <- _quality))
                    } catch {
                        print(error)
                    }
                }
            }
        } else {
            do {
                var data = try String(contentsOfFile: xlsPath, encoding: .utf8)
                data = data.replacingOccurrences(of: "\"", with: "")
                let myStrings = data.components(separatedBy: .newlines)
                
                for line in myStrings {
                    let arr = line.components(separatedBy: ",")
                    let _comp_id = arr[0]
                    let _song = (arr.count > 1) ? arr[1] : "НЕИЗВЕСТНАЯ КОМПОЗИЦИЯ"
                    let _artist = (arr.count > 2) ? arr[2] : "НЕИЗВЕСТНЫЙ ИСПОЛНИТЕЛЬ"
                    let _quality = (arr.count > 3) ? arr[3] : "_"
                    print("\(_comp_id ) \(_song) \(_artist) \(_quality)")
                    do {
                        try db.run(karaoke.insert(
                            or: .replace,
                            comp_id <- _comp_id,
                            song <- _song,
                            artist <- _artist,
                            quality <- _quality))
                    } catch {
                        print(error)
                    }

                }
            } catch {
                print(error)
            }
        }
    }
    
    
    private func clearDB () {
        let db = try! Connection("\(self.path)/db.sqlite3")
        let karaoke = Table("karaoke")
        
        do {
            if try db.run(karaoke.delete()) > 0 {
                print("deleted alice")
            } else {
                print("alice not found")
            }
        } catch {
            print("delete failed: \(error)")
        }
    }

}
