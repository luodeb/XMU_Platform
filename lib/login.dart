import 'dart:math';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:encrypt/encrypt.dart' as encrypt;
import 'xmu_data.dart';

var loginAPIURL =
    "https://ids.xmu.edu.cn/authserver/login?service=https://xmuxg.xmu.edu.cn/login/cas/xmu";

class Login {
  String converPassword(password, aesKey) {
    List randSTR = "ABCDEFGHJKMNPQRSTWXYZabcdefhijkmnprstwxyz2345678".split('');
    var rng = Random();
    var genrandstr = "";
    for (var i = 0; i < 64; i++) {
      var randint = rng.nextInt(randSTR.length);
      genrandstr += randSTR[randint];
    }

    final key = encrypt.Key.fromUtf8(aesKey);
    final iv = encrypt.IV.fromLength(16);

    final encrypter =
        encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

    final encrypted = encrypter.encrypt(genrandstr + password, iv: iv);
    // final decrypted = encrypter.decrypt(encrypted, iv: iv);
    return encrypted.base64;
  }

  Future<String> parseHTML(opDataString, pwdDefault) async {
    RegExp r = RegExp('<input.*="$pwdDefault".*>');
    var match1 = opDataString.substring(opDataString.indexOf(r));
    var match2 = match1.substring(
        match1.indexOf("value=") + 7, match1.indexOf("/>") - 1);
    return match2;
  }

  Future<Map<String, String>> login() async {
    String cookie;
    String username = MySetting.username;
    String password = MySetting.password;
    final response = await http.get(Uri.parse(loginAPIURL));

    var opDataString = response.body.toString();
    var ltRequ = await Login().parseHTML(opDataString, "lt");
    var saltRequ =
        await Login().parseHTML(opDataString, "pwdDefaultEncryptSalt");
    var passwordRequ = Login().converPassword(password, saltRequ);
    var executionRequ = await Login().parseHTML(opDataString, "execution");

    Map<String, String> jsonBody = {
      "username": username,
      "password": passwordRequ,
      "lt": ltRequ,
      "dllt": "userNamePasswordLogin",
      "execution": executionRequ,
      "_eventId": "submit",
      "rmShown": "1"
    };

    cookie = response.headers["set-cookie"].toString();

    Map<String, String> headers = {
      "cookie": cookie,
      // "referer": "https://ids.xmu.edu.cn/authserver/login?service=https://xmuxg.xmu.edu.cn/login/cas/xmu",
      // "origin": "https://ids.xmu.edu.cn"
    };

    final response1 = await http.post(Uri.parse(loginAPIURL),
        body: jsonBody, headers: headers);

    if (response1.body.indexOf("您提供的用户名或者密码有误") > 0 ||
        response1.body.indexOf("username or password is incorrect") > 0) {
      return {"JSESSIONID": "", "CASTGC": ""};
    }
    var res = response.headers["set-cookie"].toString();
    var res1 = response1.headers["set-cookie"].toString();
    Map<String, String> result = {
      "JSESSIONID":
          res.substring(res.indexOf("JSESSIONID") + 11, res.indexOf(";")),
      "CASTGC": res1.substring(res1.indexOf("CASTGC") + 7, res1.indexOf(";")),
    };
    return result;
  }

}
