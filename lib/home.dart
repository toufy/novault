import 'dart:convert' as convert;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'vault.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _loading = false;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  _login(int responseCode, {String message = ""}) {
    setState(() {
      _loading = false;
    });
    if (responseCode == -1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('network error')));
    } else if (responseCode == 200) {
      String username = _usernameController.text;
      String password = _passwordController.text;
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => Vault(
                username: username,
                password: password,
              )));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('login failed: $message')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('novault'),
      ),
      body: Center(
          child: Container(
        margin: const EdgeInsets.only(left: 8, right: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'username'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'password'),
            ),
            Container(
              margin: const EdgeInsets.all(50),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _loading
                      ? const Visibility(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: () async {
                            setState(() {
                              _loading = true;
                            });
                            final username = _usernameController.text;
                            final password = _passwordController.text;
                            try {
                              final response = await http
                                  .post(
                                    Uri.parse('https://novault.000webhostapp.com/login/index.php'),
                                    headers: <String, String>{
                                      'Content-Type': 'application/json; charset=UTF-8'
                                    },
                                    body: convert.jsonEncode(
                                        <String, String>{'uname': username, 'upasswd': password}),
                                  )
                                  .timeout(const Duration(seconds: 15));
                              _login(response.statusCode, message: response.body);
                            } catch (error) {
                              _login(-1, message: error.toString());
                            }
                          },
                          child: const Text('login'),
                        ),
                ],
              ),
            ),
            const Spacer(),
            Align(
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("don't have an account?"),
                    TextButton(
                      onPressed: () {
                        Clipboard.setData(
                            const ClipboardData(text: "https://novault.000webhostapp.com/signup"));
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(content: Text("copied url")));
                      },
                      child: const Text("https://novault.000webhostapp.com/signup"),
                    ),
                  ],
                ))
          ],
        ),
      )),
    );
  }
}
