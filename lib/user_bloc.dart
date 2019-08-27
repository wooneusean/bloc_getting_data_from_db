import 'dart:async';
import 'dart:convert';
import 'package:bloc_getting_data_from_db/user_event.dart';
import 'user.dart';
import 'package:http/http.dart' as http;

class UserBloc {
  User _userData = User('Loading...', 'Loading...');
  bool stopped = false;
  String _userToken;

  final _userStateController = StreamController<User>();
  final _userEventController = StreamController<UserEvent>();

  StreamSink<User> get _userStateControllerInput => _userStateController.sink;
  Stream<User> get userStateControllerOutput => _userStateController.stream;

  StreamSink<UserEvent> get userEventControllerInput =>
      _userEventController.sink;

  UserBloc(String token) {
    this._userToken = token;
    _mapEventToState(LoadUserEvent());
  }

  Future<User> _getUserData(String token) async {
    final url = 'http://cef1582019.gearhostpreview.com/user.php';
    User _tempUser = new User('null', 'null');
    try {
      final response = await http
          .post(url, body: {'auth': token}).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        var tempResp = jsonDecode(response.body);
        if (tempResp['email'] == null) {
          _tempUser.setEmail = 'Loading...';
          _tempUser.setBalance = 'Loading...';
        } else {
          _tempUser.setEmail = tempResp['email'];
          _tempUser.setBalance = tempResp['balance'];
        }
      }
    } on TimeoutException catch (_) {}
    return _tempUser;
  }

  User get userData => _userData;

  set setToken(String newToken){
    this._userToken = newToken;
  }

  void _mapEventToState(UserEvent event) async{
    _userData = await _getUserData(_userToken);
    _userStateControllerInput.add(_userData);
    Timer.periodic(
      Duration(seconds: 5),
      (timer) async {
        if(!stopped){
          _userData = await _getUserData(_userToken);
          _userStateControllerInput.add(_userData);
        }else{
          timer.cancel();
        }
      },
    );
  }

  void dispose() {
    _userStateController.close();
    _userEventController.close();
  }
}
