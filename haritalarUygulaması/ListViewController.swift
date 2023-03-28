//
//  ListViewController.swift
//  haritalarUygulaması
//
//  Created by Burcu Kamilçelebi on 8.03.2023.
//

import UIKit
import CoreData

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    var isimDizisi = [String]()
    var idDizisi = [UUID]()
    var secilenYerIsmi = ""
    var secilenYerId : UUID?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        title = "Places"
        tableView.delegate = self
        tableView.dataSource = self
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(artiButonuTiklandı))
        
        veriAl()
    }
    //kaydettikten sonra kaydedilen yere döndürüyor.
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(veriAl), name: NSNotification.Name("yeniYerOlusturuldu"), object: nil)
    }
    
    @objc func veriAl() {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Yer")
        request.returnsObjectsAsFaults = false
        
        do {
            let sonuclar = try context.fetch(request)
            
            if sonuclar.count > 0 {
                
                isimDizisi.removeAll(keepingCapacity: false)
                idDizisi.removeAll(keepingCapacity: false)
                
                for sonuc in sonuclar as! [NSManagedObject] {
                    
                    if let isim = sonuc.value(forKey: "isim") as? String {
                        isimDizisi.append(isim)
                    }
                    
                    if let id = sonuc.value(forKey: "id") as? UUID {
                        idDizisi.append(id)
                    }
                }
                tableView.reloadData() // tableview'ı yeniliyoruz
            }
            
        } catch {
            print("hata")
        }
    }
    
    
    @objc func artiButonuTiklandı() {
        secilenYerIsmi = ""  // secilen yer ismi boş olmalıki yeni geldiğini anlayalım.
        performSegue(withIdentifier: "toMapsVC", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isimDizisi.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = isimDizisi[indexPath.row]
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        secilenYerIsmi = isimDizisi[indexPath.row]
        secilenYerId = idDizisi[indexPath.row] // secilen yerleri atadık
        performSegue(withIdentifier: "toMapsVC", sender: nil)
    }
    
    //verileri silmek
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Yer")
        //Filtreleme
        let idString = idDizisi[indexPath.row].uuidString // id aldık
        fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
        fetchRequest.returnsObjectsAsFaults = false
        
        do {
            let results = try context.fetch(fetchRequest)
            for result in results as! [NSManagedObject]{
                if let id = result.value(forKey: "id") as? UUID{
                    context.delete(result)
                    isimDizisi.remove(at: indexPath.row)
                    idDizisi.remove(at: indexPath.row)
                    self.tableView.reloadData()
                    
                    do {
                        try context.save()
                    }catch {
                        
                    }
                }
            }
        } catch {
            
        }
                
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // veri aktarımını gerçekleştiriyoruz 
        if segue.identifier == "toMapsVC" {
            let destinationVC = segue.destination as! MapsViewController
            destinationVC.secilenIsim = secilenYerIsmi
            destinationVC.secilenId = secilenYerId
           
        }
    }
}
