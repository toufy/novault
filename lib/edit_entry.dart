import 'dart:convert' as convert;
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:novault/vault.dart';

class EditEntry extends StatefulWidget {
  final String username;
  final String masterPassword;
  final Entry entry;
  final String entryIv;
  final int entryIndex;
  final Function(Entry entry, int index) updateEntry;
  const EditEntry(
      {super.key,
      required this.username,
      required this.masterPassword,
      required this.entry,
      required this.entryIv,
      required this.entryIndex,
      required this.updateEntry});
  @override
  State<EditEntry> createState() => _EditEntryState();
}

class _EditEntryState extends State<EditEntry> {
  bool _loading = false;
  _entryStatus(Entry entry, int index, int responseCode, {String message = ""}) {
    if (responseCode == -1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('network error')));
    } else if (responseCode == 200) {
      setState(() {
        widget.updateEntry(entry, index);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('saving failed: $message')));
    }
  }

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.entry.getUserName();
    _passwordController.text = widget.entry.getPassword();
  }

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
                    Text(widget.entry.getServiceName()),
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: "username"),
                    ),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: "password"),
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
                                      Uint8List ivBytes = convert.base64Decode(widget.entryIv);
                                      encrypt.IV iv = encrypt.IV(ivBytes);
                                      String serviceUsername = _usernameController.text;
                                      String servicePassword = _passwordController.text;
                                      if (serviceUsername.isNotEmpty &&
                                          servicePassword.isNotEmpty) {
                                        Entry newEntry = Entry(widget.entry.getServiceName(),
                                            serviceUsername, servicePassword);
                                        String encryptedServiceUsername = widget.entry.encryptOnce(
                                            widget.masterPassword, iv, serviceUsername);
                                        String encryptedServicePassword = widget.entry.encryptOnce(
                                            widget.masterPassword, iv, servicePassword);
                                        String serviceName = widget.entry.getServiceName();
                                        String encryptedServiceName = widget.entry
                                            .encryptOnce(widget.masterPassword, iv, serviceName);
                                        try {
                                          final response = await http
                                              .post(
                                                Uri.parse(
                                                    'https://novault.000webhostapp.com/update/index.php'),
                                                headers: <String, String>{
                                                  'Content-Type': 'application/json; charset=UTF-8'
                                                },
                                                body: convert.jsonEncode({
                                                  'uname': widget.username,
                                                  'service_name': encryptedServiceName,
                                                  'service_uname': encryptedServiceUsername,
                                                  'service_passwd': encryptedServicePassword
                                                }),
                                              )
                                              .timeout(const Duration(seconds: 15));
                                          _entryStatus(
                                              newEntry, widget.entryIndex, response.statusCode,
                                              message: response.body);
                                        } catch (error) {
                                          _entryStatus(newEntry, widget.entryIndex, -1,
                                              message: error.toString());
                                        }
                                      }
                                      setState(() {
                                        _loading = false;
                                      });
                                    },
                              child: const Text("save")),
                        ],
                      ),
                    )
                  ],
                ),
        ),
      ),
    );
  }
}
