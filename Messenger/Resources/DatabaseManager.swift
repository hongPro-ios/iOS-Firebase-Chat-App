//
//  DatabaseManager.swift
//  Messenger
//
//  Created by JEONGSEOB HONG on 2021/03/04.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager {
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    static func safeEmail(emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
}
// MARK: - Account Management
extension DatabaseManager {
    
    public func checkUserExists(withEmail email: String, completion: @escaping ((Bool) -> Void)) {
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        database.child(safeEmail).observeSingleEvent(of: .value) { snapshot in
            guard snapshot.value as? [String: Any] != nil else {
                completion(false)
                return
                
            }
            completion(true)
        }
    }
    
    /// Inserts new user to database
    public func insertUser(withChatAppUser user: ChatAppUser, completion: @escaping (Bool) -> Void) {
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName
        ]) { error, _ in
            guard error == nil else {
                print("failed to write to database")
                completion(false)
                return
            }
            
            // users data check
            self.database.child("users").observeSingleEvent(of: .value, with: { snapshot in
                if var usersCollection = snapshot.value as? [[String: String]] {
                    // append to user dictionary
                    let newElement =  [
                        "name":  "\(user.firstName) \(user.lastName)",
                        "email":  "\(user.safeEmail)"
                    ]
                    usersCollection.append(newElement)
                    
                    self.database.child("users").setValue(usersCollection, withCompletionBlock: {error, _ in
                        guard error == nil else { completion(false); return }
                        
                        completion(true)
                    })
                }
                else {
                    // create that array
                    let newCollection: [[String: String]] = [
                        [
                            "name":  "\(user.firstName) \(user.lastName)",
                            "email":  "\(user.safeEmail)"
                        ]
                    ]
                    
                    self.database.child("users").setValue(newCollection, withCompletionBlock: {error, _ in
                        guard error == nil else { completion(false); return }
                        
                        completion(true)
                    })
                }
            })
        }
    }
    /*
     .eg...
     uses => [
     [
     "name" :
     "safe_email":
     ],
     [
     "name" :
     "safe_email":
     ],
     ]
     */
    
    public func getAllUsers(completion: @escaping (Result<[[String: String]], Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value as? [[String: String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        })
    }
    
    public enum DatabaseError: Error {
        case failedToFetch
    }
}


struct ChatAppUser {
    let firstName: String
    let lastName: String
    let emailAddress: String
    
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail 
    }
    
    var profilePictureFileName: String {
        // /images/hong-gmail-com_profile_picture.png
        return "\(safeEmail)_profile_picture.png"
    }
}
