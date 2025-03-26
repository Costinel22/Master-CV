import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import TrieMap "mo:base/TrieMap";
import Principal "mo:base/Principal";
import Iter "mo:base/Iter";
import Time "mo:base/Time";
import Array "mo:base/Array";

actor Main {

  type User = {
    name : Text;
    email : Text;
    age : Nat;
    accessLevel : AccessLevel;
    timestamp : Int;
    adminStatus : AdminStatus;
  };

  type AccessLevel = {
    #SUPER_ADMIN;
    #ADMIN;
    #USER;
    #GUEST;
  };

  type AdminStatus = {
    #Pending;
    #Approved;
    #Rejected;
    #NotRequested;
  };

  type Status = { #ACTIVE; #INACTIVE };

  public type EditableUser = {
    id : Nat;
    principal : Principal;
    name : Text;
    email : Text;
    age : Nat;
    accessLevel : AccessLevel;
    timestamp : Int;
    adminStatus : AdminStatus;
    status : Status;
  };
  
  type UserResponse = {
    principal: Principal;
    name: Text;
    email: Text;
    age: Nat;
    accessLevel: AccessLevel;
    timestamp: Int;
    adminStatus: AdminStatus;
    status: Status;
  };

  var users = TrieMap.TrieMap<Principal, User>(Principal.equal, Principal.hash);
  stable var usersEntries: [(Principal, User)] = [];
  
  system func preupgrade() {
    usersEntries := Iter.toArray(users.entries());
  };

  system func postupgrade() {
    users := TrieMap.fromEntries(usersEntries.vals(), Principal.equal, Principal.hash);
  };

  public shared(msg) func createUser(args: User): async Text {
    let caller = msg.caller;
    switch (users.get(caller)) {
        case (?existingUser) {
            return "User already exists!";
        };
        case null {
            users.put(caller, args);
            return "Account created successfully for " # args.name # "!";
        };
    };
  };

  public func addUser(principal: Principal, user: User): async Text {
    users.put(principal, user);
    return "User added successfully.";
  };

  public shared func updateUser(userId : Principal, name : Text, email : Text, status : Text) : async Bool {
    switch (users.get(userId)) {
        case (?existingUser) {
            let updatedUser : User = {
                name = name;
                email = email;
                age = existingUser.age;
                accessLevel = existingUser.accessLevel;
                timestamp = Int.abs(Time.now());
                adminStatus = existingUser.adminStatus;
            };
            users.put(userId, updatedUser);
            return true;
        };
        case (null) {
            return false;
        };
    };
  };

  func _convertToEditable(user: User, id: Nat, principal: Principal, status: Status): EditableUser {
    // Create EditableUser from User with additional fields
    return {
        id;
        principal;
        name = user.name;
        email = user.email;
        age = user.age;
        accessLevel = user.accessLevel;
        timestamp = user.timestamp;
        adminStatus = user.adminStatus;
        status;
    };
  };

  public query func getAllUsers() : async [UserResponse] {
    let usersArray : [(Principal, User)] = Iter.toArray(users.entries());
    return Array.map<(Principal, User), UserResponse>(usersArray, func ((principal, user)) {
        {
            principal;
            name = user.name;
            email = user.email;
            age = user.age;
            accessLevel = user.accessLevel;
            timestamp = user.timestamp;
            adminStatus = user.adminStatus;
            status = #ACTIVE; 
        };
    });
  };
}