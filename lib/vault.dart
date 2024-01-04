import 'dart:convert' as convert;

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:novault/edit_entry.dart';
import 'package:novault/new_entry.dart';

class Entry {
  Entry(this._serviceName, this._userName, this._password, {this.serviceIv = ""});
  final String serviceIv;
  final String _serviceName;
  final String _userName;
  final String _password;

  String encryptOnce(String masterPassword, encrypt.IV iv, String text) {
    final keyBytes = convert.utf8.encode(masterPassword.padRight(32, '\x00'));
    final key = encrypt.Key(keyBytes);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encryptedText = encrypter.encrypt(text, iv: iv);
    return encryptedText.base64;
  }

  Map<String, String> getEncrypted(String masterPassword, {encrypt.IV? iv}) {
    final keyBytes = convert.utf8.encode(masterPassword.padRight(32, '\x00'));
    final key = encrypt.Key(keyBytes);
    iv ??= encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encryptedServiceName = encrypter.encrypt(_serviceName, iv: iv);
    final encryptedUserName = encrypter.encrypt(_userName, iv: iv);
    final encryptedPassword = encrypter.encrypt(_password, iv: iv);
    return {
      "service_iv": iv.base64,
      "service_name": encryptedServiceName.base64,
      "service_uname": encryptedUserName.base64,
      "service_passwd": encryptedPassword.base64
    };
  }

  Map<String, String> getDecrypted(String masterPassword, encrypt.IV iv) {
    final keyBytes = convert.utf8.encode(masterPassword.padRight(32, '\x00'));
    final key = encrypt.Key(keyBytes);
    final decrypter = encrypt.Encrypter(encrypt.AES(key));
    String decryptedServiceName =
        decrypter.decrypt(encrypt.Encrypted.fromBase64(_serviceName), iv: iv);
    String decryptedUserName = decrypter.decrypt(encrypt.Encrypted.fromBase64(_userName), iv: iv);
    String decryptedPassword = decrypter.decrypt(encrypt.Encrypted.fromBase64(_password), iv: iv);
    return {
      "service_name": decryptedServiceName,
      "service_uname": decryptedUserName,
      "service_passwd": decryptedPassword
    };
  }

  String getServiceName() {
    return _serviceName;
  }

  String getUserName() {
    return _userName;
  }

  String getPassword() {
    return _password;
  }
}

List<Entry> entries = [];

class Vault extends StatefulWidget {
  final String username;
  final String password;
  const Vault({super.key, required this.username, required this.password});
  @override
  State<Vault> createState() => _VaultState();
}

class _VaultState extends State<Vault> {
  bool _loading = false;
  resultMessage(String result) {
    setState(() {
      _loading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
  }

  fetchData() async {
    setState(() {
      _loading = true;
    });
    try {
      final jsonData = {'uname': widget.username};
      final url = Uri.parse(
          'https://novault.000webhostapp.com/get/index.php?data=${Uri.encodeComponent(convert.jsonEncode(jsonData))}');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final responseData = convert.jsonDecode(response.body);
        for (var row in responseData) {
          String encryptedServiceName = row['entry_name'];
          String encryptedServiceUname = row['entry_username'];
          String encryptedServicePasswd = row['entry_password'];
          Entry entry = Entry(encryptedServiceName, encryptedServiceUname, encryptedServicePasswd);
          String ivStr = row['entry_iv'];
          Uint8List ivBytes = convert.base64Decode(ivStr);
          encrypt.IV iv = encrypt.IV(ivBytes);
          Map<String, String> textData = entry.getDecrypted(widget.password, iv);
          String serviceName = textData['service_name'] as String;
          String serviceUname = textData['service_uname'] as String;
          String servicePasswd = textData['service_passwd'] as String;
          Entry decryptedEntry = Entry(serviceName, serviceUname, servicePasswd, serviceIv: ivStr);
          addEntry(decryptedEntry);
        }
        resultMessage("pulled vault entries");
      } else {
        resultMessage("failed to retrieve data: ${response.body}");
      }
    } catch (error) {
      resultMessage("network error");
    }
  }

  @override
  void initState() {
    super.initState();
    entries.clear();
    fetchData();
  }

  void addEntry(Entry entry) {
    setState(() {
      entries.add(entry);
    });
  }

  void updateEntry(Entry entry, int index) {
    setState(() {
      entries[index] = entry;
    });
  }

  void removeEntry(int index) {
    setState(() {
      entries.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => NewEntry(
                  username: widget.username, masterPassword: widget.password, addEntry: addEntry)));
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      appBar: AppBar(),
      body: Center(
        child: _loading
            ? const Visibility(child: CircularProgressIndicator())
            : ListView.builder(
                itemBuilder: (context, index) {
                  return _createEntry(entries[index], index);
                },
                itemCount: entries.length,
              ),
      ),
    );
  }

  confirmDialog(BuildContext context, String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('no'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('yes'),
          ),
        ],
      ),
    );
  }

  _deleteStatus(int index, int responseCode, {String message = ""}) {
    if (responseCode == -1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('network error')));
    } else if (responseCode == 200) {
      setState(() {
        removeEntry(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('deletion failed: $message')));
    }
  }

  Widget _createEntry(Entry entry, int index) {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(entry._serviceName),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: entry._userName));
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('copied "${entry._serviceName}" username')));
                  },
                  child: const Icon(Icons.alternate_email)),
              ElevatedButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: entry._password));
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('copied "${entry._serviceName}" password')));
                  },
                  child: const Icon(Icons.lock)),
              ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => EditEntry(
                              username: widget.username,
                              masterPassword: widget.password,
                              entry: entry,
                              entryIv: entry.serviceIv,
                              entryIndex: index,
                              updateEntry: updateEntry,
                            )));
                  },
                  child: const Icon(Icons.edit)),
              ElevatedButton(
                  onPressed: _loading
                      ? null
                      : () async {
                          setState(() {
                            _loading = true;
                          });
                          bool? confirm = await confirmDialog(
                              context, "delete entry", "delete ${entry._serviceName}?");
                          if (confirm == true) {
                            String ivStr = entry.serviceIv;
                            Uint8List ivBytes = convert.base64Decode(ivStr);
                            encrypt.IV iv = encrypt.IV(ivBytes);
                            String encryptedServiceName =
                                entry.encryptOnce(widget.password, iv, entry._serviceName);
                            try {
                              final response = await http
                                  .post(
                                    Uri.parse('https://novault.000webhostapp.com/delete/index.php'),
                                    headers: <String, String>{
                                      'Content-Type': 'application/json; charset=UTF-8'
                                    },
                                    body: convert.jsonEncode({
                                      'uname': widget.username,
                                      'service_name': encryptedServiceName
                                    }),
                                  )
                                  .timeout(const Duration(seconds: 15));
                              _deleteStatus(index, response.statusCode, message: response.body);
                            } catch (error) {
                              _deleteStatus(index, -1, message: error.toString());
                            }
                          }
                          setState(() {
                            _loading = false;
                          });
                        },
                  child: const Icon(Icons.delete)),
            ],
          )
        ],
      ),
    );
  }
}
