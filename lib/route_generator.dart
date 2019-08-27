import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'user.dart';
import 'user_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_money_formatter/flutter_money_formatter.dart';

enum snackBarMessages {
  EMPTYEMAILPASS,
  EMPTYFIELDS,
  EMAILPASSMISMATCH,
  PASSREPASSMISMATCH,
  SERVERDOWN,
  USERNOTVERIFIED,
  USEREXISTS,
  CODENOMOREUSES,
  CODEDOESNTEXIST,
  USERNOTEXISTS,
  MAILERDOWN,
  REGISTERSUCCESS,
  INSUFFICIENTFUNDS,
  SUCCESS,
  FAILURE,
}

Future _showSnackBar(BuildContext context, snackBarMessages msg) async {
  String message;
  switch (msg) {
    case snackBarMessages.EMPTYEMAILPASS:
      message = 'Email and password must not be empty!';
      break;
    case snackBarMessages.EMPTYFIELDS:
      message = 'Please fill up all the fields!';
      break;
    case snackBarMessages.EMAILPASSMISMATCH:
      message = 'Wrong email and/or password!';
      break;
    case snackBarMessages.PASSREPASSMISMATCH:
      message = 'Password and re-type password not the same!';
      break;
    case snackBarMessages.SERVERDOWN:
      message = 'Server is down!';
      break;
    case snackBarMessages.USERNOTVERIFIED:
      message = 'Your account has not yet been verified!';
      break;
    case snackBarMessages.USEREXISTS:
      message = 'Account with that email already exists!';
      break;
    case snackBarMessages.USERNOTEXISTS:
      message = 'Account with that email doesn\'t exist!';
      break;
    case snackBarMessages.CODENOMOREUSES:
      message = 'Code has no more uses!';
      break;
    case snackBarMessages.CODEDOESNTEXIST:
      message = 'Code doesn\'t exist!';
      break;
    case snackBarMessages.MAILERDOWN:
      message = 'Our mailer is down!';
      break;
    case snackBarMessages.INSUFFICIENTFUNDS:
      message = 'You have insufficient funds!';
      break;
    case snackBarMessages.SUCCESS:
      message = 'Successfully carried our process!';
      break;
    case snackBarMessages.FAILURE:
      message = 'Process failed!';
      break;
    case snackBarMessages.REGISTERSUCCESS:
      message =
          'Successfully registered. Please verify your account from the email we sent you!';
      break;

    default:
      message = 'Unknown error occured!';
      break;
  }

  Scaffold.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
    ),
  );
}

Future _showLoadingDialog(BuildContext context) async {
  showGeneralDialog(
    context: context,
    pageBuilder: (BuildContext buildContext, Animation<double> animation,
        Animation<double> secondaryAnimation) {
      return Material(
        type: MaterialType.transparency,
        child: Center(
          child: Wrap(
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color: Colors.deepPurple,
                ),
                width: 200.0,
                height: 200.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Center(
                      child: SizedBox(
                        height: 50,
                        width: 50,
                        child: CircularProgressIndicator(
                          backgroundColor: Colors.white,
                          strokeWidth: 8.0,
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 25.0),
                      child: Center(
                        child: Text(
                          'Loading...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
    barrierDismissible: false,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Color(0x78808080),
    transitionDuration: Duration(milliseconds: 200),
  );
}

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => LoginPage());
      case '/home':
        return MaterialPageRoute(
          builder: (_) => HomePage(
            token: args.toString(),
          ),
        );
      case '/register':
        return MaterialPageRoute(
          builder: (_) => RegisterPage(),
        );
      case '/transfer':
        return MaterialPageRoute(
          builder: (_) => TransferPage(
            myEmail: args.toString(),
          ),
        );
      case '/redeem':
        return MaterialPageRoute(
          builder: (_) => RedeemPage(
            myEmail: args.toString(),
          ),
        );
      default:
        return MaterialPageRoute(builder: (_) => ErrorPage());
    }
  }
}

class RedeemPage extends StatefulWidget {
  RedeemPage({Key key, this.myEmail}) : super(key: key);

  final String myEmail;

  @override
  _RedeemPageState createState() => _RedeemPageState();
}

class _RedeemPageState extends State<RedeemPage> {
  final codeCtrl = TextEditingController();
  bool _isButtonPressed = false;

  Future _sendRedeemRequest(
      String code, String myEmail, BuildContext context) async {
    final url = 'http://cef1582019.gearhostpreview.com/redeem.php';
    try {
      _isButtonPressed = true;
      _showLoadingDialog(context);
      final response = await http.post(url, body: {
        'code': code,
        'myEmail': myEmail,
      }).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        var resp = jsonDecode(response.body);
        if (resp.isNotEmpty) {
          if (resp['res'] == '4') {
            Navigator.of(context).pop();
            await showDialog(
              context: context,
              builder: (BuildContext context) {
                FlutterMoneyFormatter fmf = FlutterMoneyFormatter(
                  amount: double.parse(resp['codeValue']),
                  settings: MoneyFormatterSettings(
                    symbol: 'USD',
                    thousandSeparator: ',',
                    decimalSeparator: '.',
                    symbolAndNumberSeparator: '',
                    fractionDigits: 2,
                  ),
                );
                String newAmt = fmf.output.symbolOnLeft;
                // return object of type Dialog
                return AlertDialog(
                  title: new Text('Success!'),
                  content: new Text(
                      'Redeem Success! $newAmt has been added to your account!'),
                  actions: <Widget>[
                    // usually buttons at the bottom of the dialog
                    new FlatButton(
                      child: new Text("Close"),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                        _isButtonPressed = false;
                      },
                    ),
                  ],
                );
              },
            );
          } else if (resp['res'] == '3') {
            Navigator.of(context).pop();
            _showSnackBar(context, snackBarMessages.CODENOMOREUSES);
            _isButtonPressed = false;
          } else if (resp['res'] == '2') {
            Navigator.of(context).pop();
            _showSnackBar(context, snackBarMessages.CODEDOESNTEXIST);
            _isButtonPressed = false;
          } else if (resp['res'] == '1') {
            Navigator.of(context).pop();
            _showSnackBar(context, snackBarMessages.FAILURE);
            _isButtonPressed = false;
          } else if (resp['res'] == '0') {
            Navigator.of(context).pop();
            _showSnackBar(context, snackBarMessages.EMPTYFIELDS);
            _isButtonPressed = false;
          } else {
            Navigator.of(context).pop();
            _showSnackBar(context, snackBarMessages.FAILURE);
            _isButtonPressed = false;
          }
        }
      } else {
        Navigator.of(context).pop();
        _showSnackBar(context, snackBarMessages.SERVERDOWN);
        _isButtonPressed = false;
      }
    } on TimeoutException catch (_) {
      Navigator.of(context).pop();
      _showSnackBar(context, snackBarMessages.SERVERDOWN);
      _isButtonPressed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Redeem Code'),
      ),
      body: Builder(
        builder: (context) => SafeArea(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            children: <Widget>[
              SizedBox(height: 120.0),
              TextField(
                controller: codeCtrl,
                decoration: InputDecoration(labelText: 'Code', filled: true),
              ),
              SizedBox(height: 12.0),
              ButtonBar(
                children: <Widget>[
                  RaisedButton(
                    child: Text('Redeem'),
                    onPressed: () {
                      if (!_isButtonPressed) {
                        if (codeCtrl.text.isNotEmpty) {
                          _sendRedeemRequest(
                              codeCtrl.text, widget.myEmail, context);
                        } else {
                          _showSnackBar(context, snackBarMessages.EMPTYFIELDS);
                        }
                      } else {
                        return null;
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TransferPage extends StatefulWidget {
  TransferPage({Key key, this.myEmail}) : super(key: key);

  final String myEmail;

  @override
  _TransferPageState createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  final amtCtrl = TextEditingController();
  final rcptCtrl = TextEditingController();
  bool _isButtonPressed = false;

  Future _sendTransferRequest(String recipientEmail, String myEmail, double amt,
      BuildContext context) async {
    final url = 'http://cef1582019.gearhostpreview.com/transfer.php';
    try {
      _isButtonPressed = true;
      final response = await http.post(url, body: {
        'myEmail': myEmail,
        'recipientEmail': recipientEmail,
        'amount': amt.toString(),
      }).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        var resp = jsonDecode(response.body);
        Navigator.of(context).pop();
        if (resp.isNotEmpty) {
          if (resp['res'] == '4') {
            await showDialog(
              context: context,
              builder: (BuildContext context) {
                FlutterMoneyFormatter fmf = FlutterMoneyFormatter(
                  amount: amt,
                  settings: MoneyFormatterSettings(
                    symbol: 'USD',
                    thousandSeparator: ',',
                    decimalSeparator: '.',
                    symbolAndNumberSeparator: '',
                    fractionDigits: 2,
                  ),
                );
                String newAmt = fmf.output.symbolOnLeft;
                // return object of type Dialog
                return AlertDialog(
                  title: new Text('Success!'),
                  content: new Text(
                      'Transfer Success! $newAmt has been sent to $recipientEmail'),
                  actions: <Widget>[
                    // usually buttons at the bottom of the dialog
                    new FlatButton(
                      child: new Text("Close"),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                        _isButtonPressed = false;
                      },
                    ),
                  ],
                );
              },
            );
          } else if (resp['res'] == '3') {
            _showSnackBar(context, snackBarMessages.USERNOTEXISTS);
            _isButtonPressed = false;
          } else if (resp['res'] == '2') {
            _showSnackBar(context, snackBarMessages.INSUFFICIENTFUNDS);
            _isButtonPressed = false;
          } else if (resp['res'] == '1') {
            _showSnackBar(context, snackBarMessages.FAILURE);
            _isButtonPressed = false;
          } else if (resp['res'] == '0') {
            _showSnackBar(context, snackBarMessages.EMPTYFIELDS);
            _isButtonPressed = false;
          } else {
            _showSnackBar(context, snackBarMessages.FAILURE);
            _isButtonPressed = false;
          }
        }
      } else {
        Navigator.of(context).pop();
        _showSnackBar(context, snackBarMessages.SERVERDOWN);
        _isButtonPressed = false;
      }
    } on TimeoutException catch (_) {
      Navigator.of(context).pop();
      _showSnackBar(context, snackBarMessages.SERVERDOWN);
      _isButtonPressed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transfer'),
      ),
      body: Builder(
        builder: (context) => SafeArea(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            children: <Widget>[
              SizedBox(height: 120.0),
              TextField(
                controller: rcptCtrl,
                decoration:
                    InputDecoration(labelText: 'Recipient', filled: true),
              ),
              SizedBox(
                height: 12.0,
              ),
              TextField(
                controller: amtCtrl,
                decoration: InputDecoration(labelText: 'Amount', filled: true),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 12.0),
              ButtonBar(
                children: <Widget>[
                  RaisedButton(
                    child: Text('Send'),
                    onPressed: () {
                      _showLoadingDialog(context);
                      if (!_isButtonPressed) {
                        if (amtCtrl.text.isNotEmpty &&
                            rcptCtrl.text.isNotEmpty) {
                          var tempAmt = double.parse(amtCtrl.text);
                          _sendTransferRequest(
                              rcptCtrl.text, widget.myEmail, tempAmt, context);
                        } else {
                          _showSnackBar(context, snackBarMessages.EMPTYFIELDS);
                        }
                      } else {
                        return null;
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  LoginPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  bool _isButtonPressed = false;

  var token;

  Future sendLoginRequest(
      String email, String password, BuildContext context) async {
    final url = 'http://cef1582019.gearhostpreview.com/login.php';
    try {
      _isButtonPressed = true;
      final response = await http.post(url, body: {
        'email': email,
        'password': password
      }).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        setState(
          () {
            // debugPrint(response.body);
            token = jsonDecode(response.body);
            Navigator.of(context).pop();
            if (token.isNotEmpty) {
              if (token['res'] == '0') {
                _showSnackBar(context, snackBarMessages.EMAILPASSMISMATCH);
                _isButtonPressed = false;
              } else if (token['res'] == '1') {
                _showSnackBar(context, snackBarMessages.USERNOTVERIFIED);
                _isButtonPressed = false;
              } else {
                Navigator.of(context)
                    .pushReplacementNamed('/home', arguments: token['res']);
              }
            }
          },
        );
      } else {
        _showSnackBar(context, snackBarMessages.SERVERDOWN);
        Navigator.of(context).pop();
        _isButtonPressed = false;
      }
    } on TimeoutException catch (_) {
      _showSnackBar(context, snackBarMessages.SERVERDOWN);
      Navigator.of(context).pop();
      _isButtonPressed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text('Login'),
        ),
      ),
      body: Builder(
        builder: (context) => SafeArea(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            children: <Widget>[
              SizedBox(height: 120.0),
              TextField(
                controller: emailCtrl,
                decoration: InputDecoration(labelText: 'Email', filled: true),
              ),
              SizedBox(height: 12.0),
              TextField(
                controller: passCtrl,
                decoration:
                    InputDecoration(labelText: 'Password', filled: true),
                obscureText: true,
              ),
              ButtonBar(
                children: <Widget>[
                  RaisedButton(
                    child: Text('Login'),
                    onPressed: () {
                      setState(() {
                        if (!_isButtonPressed) {
                          if (emailCtrl.text.isEmpty || passCtrl.text.isEmpty) {
                            _showSnackBar(
                                context, snackBarMessages.EMPTYEMAILPASS);
                          } else {
                            _showLoadingDialog(context);
                            sendLoginRequest(
                                emailCtrl.text, passCtrl.text, context);
                          }
                        } else {
                          return null;
                        }
                      });
                    },
                  ),
                  FlatButton(
                    child: Text('Register'),
                    onPressed: () {
                      Navigator.of(context).pushNamed('/register');
                    },
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key, this.token}) : super(key: key);

  final String token;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  UserBloc _userBloc;
  User currentUser;

  @override
  void initState() {
    super.initState();
    _userBloc = UserBloc(widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bank App'),
      ),
      body: StreamBuilder<User>(
        stream: _userBloc.userStateControllerOutput,
        initialData: User('Loading...', 'Loading...'),
        builder: (context, snapshot) {
          return SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  snapshot.data.email,
                  style: TextStyle(fontSize: 24, color: Colors.grey),
                ),
                SizedBox(height: 12.0),
                Text(
                  snapshot.data.balance,
                  style: TextStyle(fontSize: 26),
                ),
                SizedBox(height: 120.0),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FloatingActionButton(
              heroTag: 'RedeemButton',
              onPressed: () {
                currentUser = _userBloc.userData;
                Navigator.of(context)
                    .pushNamed('/redeem', arguments: currentUser.email);
              },
              tooltip: 'Redeem',
              child: Icon(Icons.redeem),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FloatingActionButton(
              heroTag: 'LogoutButton',
              onPressed: () {
                _userBloc.stopped = true;
                Navigator.of(context).pushReplacementNamed('/');
              },
              tooltip: 'Logout',
              child: Icon(Icons.power_settings_new),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FloatingActionButton(
              heroTag: 'TransferButton',
              onPressed: () {
                currentUser = _userBloc.userData;
                Navigator.of(context)
                    .pushNamed('/transfer', arguments: currentUser.email);
              },
              tooltip: 'Transfer',
              child: Icon(Icons.send),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _userBloc.dispose();
    super.dispose();
  }
}

class RegisterPage extends StatefulWidget {
  RegisterPage({Key key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final rePassCtrl = TextEditingController();

  bool _isButtonPressed = false;
  var res;

  Future sendRegisterRequest(String email, String password, String repass,
      BuildContext context) async {
    final url = 'http://cef1582019.gearhostpreview.com/register.php';

    try {
      _showLoadingDialog(context);
      _isButtonPressed = true;
      final response = await http.post(url, body: {
        'email': email,
        'password': password,
        'repass': repass,
      }).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        setState(() {
          res = jsonDecode(response.body);
          if (res.isNotEmpty) {
            switch (res['res']) {
              case '0':
                Navigator.of(context).pop();
                _showSnackBar(context, snackBarMessages.EMPTYFIELDS);
                _isButtonPressed = false;
                break;
              case '1':
                Navigator.of(context).pop();
                _showSnackBar(context, snackBarMessages.PASSREPASSMISMATCH);
                _isButtonPressed = false;
                break;
              case '2':
                Navigator.of(context).pop();
                _showSnackBar(context, snackBarMessages.USEREXISTS);
                _isButtonPressed = false;
                break;
              case '3':
                Navigator.of(context).pop();
                _showSnackBar(context, snackBarMessages.MAILERDOWN);
                _isButtonPressed = false;
                break;
              case '4':
                Navigator.of(context).pop();
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    // return object of type Dialog
                    return AlertDialog(
                      title: new Text('Success!'),
                      content: new Text(
                          'Registration Success! Please verify your account from the email we sent you.'),
                      actions: <Widget>[
                        // usually buttons at the bottom of the dialog
                        new FlatButton(
                          child: new Text("Close"),
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
                break;
              default:
                _showSnackBar(context, snackBarMessages.SERVERDOWN);
                _isButtonPressed = false;
                break;
            }
          }
        });
      } else {
        _showSnackBar(context, snackBarMessages.SERVERDOWN);
        _isButtonPressed = false;
      }
    } on TimeoutException catch (_) {
      _showSnackBar(context, snackBarMessages.SERVERDOWN);
      _isButtonPressed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text('Register'),
        ),
      ),
      body: Builder(
        builder: (context) => SafeArea(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            children: <Widget>[
              SizedBox(height: 120.0),
              TextField(
                controller: emailCtrl,
                decoration: InputDecoration(labelText: 'Email', filled: true),
              ),
              SizedBox(height: 12.0),
              TextField(
                controller: passCtrl,
                decoration:
                    InputDecoration(labelText: 'Password', filled: true),
                obscureText: true,
              ),
              SizedBox(height: 12.0),
              TextField(
                controller: rePassCtrl,
                decoration: InputDecoration(
                    labelText: 'Re-type Password', filled: true),
                obscureText: true,
              ),
              ButtonBar(
                children: <Widget>[
                  RaisedButton(
                    child: Text('Register'),
                    onPressed: () {
                      setState(() {
                        if (!_isButtonPressed) {
                          if (emailCtrl.text.isNotEmpty &&
                              passCtrl.text.isNotEmpty &&
                              rePassCtrl.text.isNotEmpty) {
                            if (passCtrl.text == rePassCtrl.text) {
                              sendRegisterRequest(emailCtrl.text, passCtrl.text,
                                  rePassCtrl.text, context);
                            } else {
                              _showSnackBar(
                                  context, snackBarMessages.PASSREPASSMISMATCH);
                            }
                          } else {
                            _showSnackBar(
                                context, snackBarMessages.EMPTYFIELDS);
                          }
                        } else {
                          return null;
                        }
                      });
                    },
                  ),
                  FlatButton(
                    child: Text('Back'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SizedBox(
          child: Text('Error'),
          width: double.infinity,
        ),
      ),
    );
  }
}
