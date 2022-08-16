import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'account.dart';
import 'login.dart';

import 'xmu_data.dart';

bool boolgetResult = true;
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '厦门大学学工平台',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: '厦门大学学工平台'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var testhttp = Login();
  Map<String, String> result = {};

  final CookieManager? cookieManager = CookieManager();

  Future<void> _incrementCounter() async {
    final SharedPreferences prefs = await MySetting.prefs;
    MySetting.username = prefs.getString('username') ?? "";
    MySetting.password = prefs.getString('password') ?? "";
    print(MySetting.password);
  }

  void _getRequests() {
    setState(() {
      print("getRequests");
      boolgetResult = true;
    });
  }

  Future<void> getResult() async {
    // Fluttertoast.showToast(msg: "读取用户名和密码！");
    await _incrementCounter();
    // Fluttertoast.showToast(msg: "正在尝试登陆！");
    result = await testhttp.login();
    setState(() {
      // Fluttertoast.showToast(msg: result.toString()+"666");
      print(result);
      boolgetResult = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _incrementCounter();
  }

  @override
  Widget build(BuildContext context) {
    if (boolgetResult == true) {
      getResult();
    }

    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: '刷新页面',
                onPressed: () {
                  setState(() {
                    boolgetResult = true;
                    print("刷新页面");
                  });
                }),
            IconButton(
              icon: const Icon(Icons.account_box_outlined),
              tooltip: '设置账户',
              onPressed: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MyAccountPage()),
                ).then((value) {
                  if (value) {
                    print("6666666666666");
                    _getRequests();
                  }
                });
              },
            ),
          ],
        ),
        body: genBody());
  }

  Widget genBody() {
    if (MySetting.username.isEmpty) {
      return const Center(child: Text("右上角设置账户信息！"));
    } else {
      if (boolgetResult) {
        return const Center(child: Text("正在尝试登陆！"));
      } else {
        if (result["CASTGC"]!.isEmpty) {
          return const Center(child: Text("密码错误！"));
        } else {
          Fluttertoast.showToast(msg: "登陆成功！");
          // return const Center(child: Text("页面数据！"));
          return WebView(
            initialUrl: "https://ids.xmu.edu.cn/authserver/index.do",
            onWebViewCreated: (controller) async {
              var commonUrl =
                  "https://ids.xmu.edu.cn/authserver/login?service=https://xmuxg.xmu.edu.cn/login/cas/xmu";
              var request = WebViewRequest(
                uri: Uri.parse(commonUrl),
                method: WebViewRequestMethod.get,
              );
              await controller.loadRequest(request);
            },
            initialCookies: [
              WebViewCookie(
                  name: "CASTGC",
                  value: result["CASTGC"]!,
                  domain: "ids.xmu.edu.cn"),
              WebViewCookie(
                  name: "JSESSIONID",
                  value: result["JSESSIONID"]!,
                  domain: "ids.xmu.edu.cn"),
            ],
            javascriptMode: JavascriptMode.unrestricted,
          );
        }
      }
    }
  }
}
