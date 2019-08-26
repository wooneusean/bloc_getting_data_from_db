// What a class looks like
//class className {
//  fields;
//  getters/setters
//  constructor
//  methods/functions
//}

class User {
  // fields;
  String _email;
  String _balance;

  // getters/setters
  set setEmail(String newEmail) {
    this._email = newEmail;
  }
  set setBalance(String newBalance) {
    this._balance = newBalance;
  }

  String get email => _email;
  String get balance => _balance;

  // constructor
  User(
    this._email,
    this._balance,
  );

// methods/functions

}
