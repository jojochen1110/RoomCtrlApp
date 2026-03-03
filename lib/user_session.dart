

class UserSession {
  // 建立一個單例，確保全 App 只有一個 UserSession 實例
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;
  UserSession._internal();

  // 存放帳號密碼 (預設值)
  static String account = "abc";
  static String password = "1234";

  static String getAccount(){
    return account;
  }
  static String getPassword(){
    return password;
  }

  static void changeAccount(String newAccount){
    account = newAccount;
  }
  static void changePassword(String newPassword){
    password = newPassword;
  }
}