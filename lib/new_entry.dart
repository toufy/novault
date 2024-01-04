import 'dart:convert' as convert;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'vault.dart';

class NewEntry extends StatefulWidget {
  final String username;
  final String masterPassword;
  final Function(Entry entry) addEntry;
  const NewEntry(
      {super.key, required this.username, required this.masterPassword, required this.addEntry});
  @override
  State<NewEntry> createState() => _NewEntryState();
}

class _NewEntryState extends State<NewEntry> {
  bool _loading = false;
  _entryStatus(Entry entry, int responseCode, {String message = ""}) {
    if (responseCode == -1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('network error')));
    } else if (responseCode == 200) {
      setState(() {
        widget.addEntry(entry);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('saving failed: $message')));
    }
  }

  final _servicenameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
          child: Container(
        margin: const EdgeInsets.all(8),
        child: _loading
            ? const Visibility(child: CircularProgressIndicator())
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: _servicenameController,
                    decoration: const InputDecoration(labelText: 'service name'),
                  ),
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
                    margin: const EdgeInsets.all(40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                            onPressed: _loading
                                ? null
                                : () async {
                                    setState(() {
                                      _loading = true;
                                    });
                                    String serviceName = _servicenameController.text;
                                    String userName = _usernameController.text;
                                    String password = _passwordController.text;
                                    if ([serviceName, userName, password]
                                        .every((field) => field.isNotEmpty)) {
                                      Entry entry = Entry(serviceName, userName, password);
                                      Map<String, String> encryptedData =
                                          entry.getEncrypted(widget.masterPassword);
                                      encryptedData.addAll({"uname": widget.username});

                                      try {
                                        final response = await http
                                            .post(
                                              Uri.parse(
                                                  'https://novault.000webhostapp.com/add/index.php'),
                                              headers: <String, String>{
                                                'Content-Type': 'application/json; charset=UTF-8'
                                              },
                                              body: convert.jsonEncode(encryptedData),
                                            )
                                            .timeout(const Duration(seconds: 15));
                                        _entryStatus(entry, response.statusCode,
                                            message: response.body);
                                      } catch (error) {
                                        _entryStatus(entry, -1, message: error.toString());
                                      }
                                    }
                                    setState(() {
                                      _loading = false;
                                    });
                                  },
                            child: const Text('save')),
                      ],
                    ),
                  ),
                ],
              ),
      )),
    );
  }
}
