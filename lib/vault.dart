import 'dart:convert' as convert;
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:novault/new_entry.dart';

class Entry {
  Entry(this._serviceName, this._userName, this._password);
  final String _serviceName;
  final String _userName;
  final String _password;

  Map<String, String> getEncrypted(String masterPassword) {
    final keyBytes = convert.utf8.encode(masterPassword.padRight(32, '\x00'));
    final key = encrypt.Key(keyBytes);
    final iv = encrypt.IV.fromLength(16);
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
  @override
  void initState() {
    super.initState();
    entries.clear();
    http
        .get(
          Uri.https('novault.000webhostapp.com', 'get/index.php', {'uname': widget.username}),
        )
        .timeout(const Duration(seconds: 15))
        .then((response) {
      if (response.statusCode == 200) {
        final jsonRsp = convert.jsonDecode(response.body);
        for (var row in jsonRsp) {
          String strIv = row['service_iv'];
          Uint8List ivBytes = convert.base64Decode(strIv);
          encrypt.IV iv = encrypt.IV(ivBytes);
          String encryptedServiceName = row['entry_name'];
          String encryptedServiceUname = row['entry_username'];
          String encryptedServicePasswd = row['entry_password'];
          Entry entry = Entry(encryptedServiceName, encryptedServiceUname, encryptedServicePasswd);
          Map<String, String> textData = entry.getDecrypted(widget.password, iv);
          String serviceName = textData['service_name'] as String;
          String serviceUname = textData['service_uname'] as String;
          String servicePasswd = textData['service_passwd'] as String;
          Entry decryptedEntry = Entry(serviceName, serviceUname, servicePasswd);
          addEntry(decryptedEntry);
        }
      }
    }).catchError((error) {});
  }

  void addEntry(Entry entry) {
    setState(() {
      entries.add(entry);
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
        child: ListView.builder(
          itemBuilder: (context, index) {
            return _createEntry(entries[index]);
          },
          itemCount: entries.length,
        ),
      ),
    );
  }

  Widget _createEntry(Entry entry) {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(entry._serviceName),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(onPressed: () {}, child: const Icon(Icons.alternate_email)),
              ElevatedButton(onPressed: () {}, child: const Icon(Icons.lock)),
              ElevatedButton(onPressed: () {}, child: const Icon(Icons.edit)),
              ElevatedButton(onPressed: () {}, child: const Icon(Icons.delete)),
            ],
          )
        ],
      ),
    );
  }
}
