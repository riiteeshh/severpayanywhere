import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:flutter/material.dart';
import 'package:encryptor/encryptor.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:servpayanywhere/recharge.dart';
import 'package:telephony/telephony.dart';
import './keyexcg.dart';

// sender should be +977

void main() async {
  await WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String sms = "";
  Telephony telephony = Telephony.instance;

  var dbref = FirebaseFirestore.instance.collection('UserData');

  Future<bool> perm() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.phone,
      //add more permission to request here.
    ].request();
    return true;
  }

  @override
  void initState() {
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) async {
        Map<Permission, PermissionStatus> statuses = await [
          Permission.phone,
          //add more permission to request here.
        ].request();
        sms = message.body.toString();
        num? secrett;

        print(message.address);
        print(message.body);

        var securitycode = '123478'; // security code for ntc
        var sendernumber = message.address;
        var x = sms;
        var y;

        y = x.split(":");

        // var y = x.split(":"); // o/p:[topup, +9779865762048, 50]
        if (y.length == 1) {
          if (y[0].length > 15) {
            // print(y.length);

            var decrypted =
                await Encryptor.decrypt('16', message.body.toString());
            print(decrypted);
            y = decrypted.toString().split(":");
            print('yvalue:$y');
            if (y.length == 3) {
              String sentmoney = y[2];
              print(y);

              if (y[0] == 'topup') {
                print('here');
                await dbref
                    .where('mobilenumber', isEqualTo: sendernumber)
                    .get()
                    .then((QuerySnapshot querySnapshot) {
                  querySnapshot.docs.forEach((senderbl) async {
                    if (senderbl.exists) {
                      String sendernamebl = await senderbl['name'];
                      num senderbalancebl = await senderbl['balance'];
                      String senderidbl = await senderbl.id;

                      if (senderbalancebl < int.parse(y[2])) {
                        String message =
                            'Dear $sendernamebl, \nYou have no sufficient balance in your wallet.'
                            'Please recharge.\nThankYou.';
                        List<String> recipents = [sendernumber.toString()];

                        String _result = await sendSMS(
                                message: message,
                                recipients: recipents,
                                sendDirect: true)
                            .catchError((onError) {
                          print(onError);
                        });
                      } else if (senderbalancebl >= int.parse(y[2])) {
                        String mobile = y[1];
                        String money = y[2];

                        if (y[1].startsWith('984') ||
                            y[1].startsWith('985') ||
                            y[1].startsWith('986')) {
                          // num subtractedbl = senderbalancebl - int.parse(y[2]);
                          // print(sendernamebl);
                          // print(subtractedbl);
                          // await dbref
                          //     .doc(senderidbl)
                          //     .update({'balance': subtractedbl});
                          String number = '*422*$securitycode*$mobile*$money#';
                          await FlutterPhoneDirectCaller.callNumber(number);
                        } else if (y[1].startsWith('980') ||
                            y[1].startsWith('981') ||
                            y[1].startsWith('982')) {
                          num subtractedbl = senderbalancebl - int.parse(y[2]);
                          // print(sendernamebl);
                          // print(subtractedbl);
                          // await dbref
                          //     .doc(senderidbl)
                          //     .update({'balance': subtractedbl});
                          String number = '*17122*$mobile*$money#';
                          await FlutterPhoneDirectCaller.callNumber(number);
                        } else {
                          String message =
                              'Sorry! The number provided can\'t be top-uped. Please provide a valid number.'
                              '\nThankYou.';
                          List<String> recipents = [sendernumber.toString()];
                          String _result = await sendSMS(
                                  message: message,
                                  recipients: recipents,
                                  sendDirect: true)
                              .catchError((onError) {
                            print(onError);
                          });
                        }
                      }
                    }
                  });
                });
              } else if (y[0] == 'transaction') {
                await dbref
                    .where('mobilenumber', isEqualTo: y[1])
                    .get()
                    .then((QuerySnapshot querySnapshot) {
                  querySnapshot.docs.forEach((reciever) async {
                    if (reciever.exists) {
                      String recieverid = await reciever.id;
                      String recievername = await reciever['name'];
                      num recieverbalance = await reciever['balance'];
                      await dbref
                          .where('mobilenumber', isEqualTo: sendernumber)
                          .get()
                          .then((QuerySnapshot querySnapshot) {
                        querySnapshot.docs.forEach((sender) async {
                          if (sender.exists) {
                            String sendername = await sender['name'];
                            num senderbalance = await sender['balance'];
                            String senderid = await sender.id;
                            if (senderbalance < int.parse(y[2])) {
                              String message =
                                  'Dear $sendername, \nYou have no sufficient balance in your wallet.'
                                  'Please recharge.\nThankYou.';
                              List<String> recipents = [
                                sendernumber.toString()
                              ];

                              String _result = await sendSMS(
                                      message: message,
                                      recipients: recipents,
                                      sendDirect: true)
                                  .catchError((onError) {
                                print(onError);
                              });
                            } else if (senderbalance >= int.parse(y[2])) {
                              //sender balance should be subtracted by y[2]
                              num subtractedbl =
                                  senderbalance - int.parse(y[2]);
                              //reciever bl added with y[2]
                              num addedbl = recieverbalance + int.parse(y[2]);
                              //update sender balance in firestore
                              await dbref
                                  .doc(senderid)
                                  .update({'balance': subtractedbl});
                              //updated reciever balance in firestore
                              await dbref
                                  .doc(recieverid)
                                  .update({'balance': addedbl});

                              Map<String, dynamic> sentdataa = {
                                'amount': sentmoney,
                                'date': DateTime.now().toString(),
                                'to': y[1],
                              };
                              Map<String, dynamic> recieveddata = {
                                'amount': sentmoney,
                                'date': DateTime.now().toString(),
                                'from': sendernumber,
                              };

                              // dbref.doc(senderid).update({
                              //   'date': FieldValue.arrayUnion([DateTime.now()])
                              // });

                              // await dbref
                              //     .doc(recieverid)
                              //     .update({'recieved': recieveddata});
                              var datasss = await dbref.doc(senderid).get();
                              print(datasss['sent']);
                              List dataaddsent = [];
                              dataaddsent.addAll(datasss['sent']);
                              dataaddsent.add(sentdataa);
                              print(dataaddsent);

                              await dbref
                                  .doc(senderid)
                                  .update({'sent': dataaddsent});
                              //ldshad

                              var datassr = await dbref.doc(recieverid).get();
                              print(datassr['recieved']);
                              List dataaddrecieved = [];
                              dataaddrecieved.addAll(datassr['recieved']);
                              dataaddrecieved.add(recieveddata);
                              print(dataaddrecieved);
                              await dbref
                                  .doc(recieverid)
                                  .update({'recieved': dataaddrecieved});

                              //send sender the message that y[2] rupees is deducted from sender balance.
                              String message =
                                  'Dear $sendername, \nThe transaction of Rs.$sentmoney was successfull !'
                                  '\nThankYou.';
                              List<String> recipents = [
                                sendernumber.toString()
                              ];

                              String _result = await sendSMS(
                                      message: message,
                                      recipients: recipents,
                                      sendDirect: true)
                                  .catchError((onError) {
                                print(onError);
                              });
                              // send reciever the message that y[2] rupees is addded to reciever balance.
                              String message1 =
                                  'Dear $recievername, \nYou have recieved Rs.$sentmoney in your wallet from $sendernumber.'
                                  '\nThankYou.';
                              List<String> recipents1 = [y[1].toString()];

                              String _result1 = await sendSMS(
                                      message: message1,
                                      recipients: recipents1,
                                      sendDirect: true)
                                  .catchError((onError) {
                                print(onError);
                              });
                            }
                          }
                        });
                      });
                    }
                  });
                });
              }
            }
          }

          if (y[0] == 'getbalance') {
            await dbref
                .where('mobilenumber', isEqualTo: sendernumber)
                .get()
                .then((QuerySnapshot querySnapshot) {
              querySnapshot.docs.forEach((blchecker) async {
                if (blchecker.exists) {
                  String sendername = await blchecker['name'];
                  num senderbalance = await blchecker['balance'];

                  String message =
                      'Dear $sendername, \nYou have Rs.$senderbalance in your wallet.'
                      '\nThankYou.';
                  List<String> recipents = [sendernumber.toString()];

                  await sendSMS(
                          message: message,
                          recipients: recipents,
                          sendDirect: true)
                      .catchError((onError) {
                    print(onError);
                  });
                }
              });
            });
          }
        } else if (y.length == 2) {
          if (y[0] == 'public') {
            String public;
            List<String> str = [];

            List<num> cdunit = [];
            List mid = [];
            num midd;
            int cd;
            num prvt = 6;
            String key = await deffie.enc(17, 4, prvt).toString();
            String publickey = await deffie.chg(key);
            print('reach');
            str = y[1].split('');
            print('str$str');
            for (int i = 0; i < str.length; i++) {
              print('for$i');
              //str[i].codeUnits;
              print('str$str');
              cdunit.addAll(str[i].codeUnits);
              print('cdunit$cdunit');
            }
            print(str);
            for (int i = 0; i < cdunit.length; i++) {
              print(cdunit[i]);
              midd = (cdunit[i] - 68).abs();
              mid.add(midd);
              print(mid);
            }
            public = mid.join("");
            print('publickey$public');
            excgkey(publickey, sendernumber);

            secrett = await deffie.secretkey(public, prvt);
            print('secret:$secrett');
          }
        }
      },
      listenInBackground: false,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => Rechargenumber())),
            icon: Icon(Icons.add),
            label: Text('ADD')),
        appBar: AppBar(
            title: Text("Listen Incoming SMS in Flutter"),
            backgroundColor: Colors.redAccent),
        body: FutureBuilder(
            future: perm(),
            builder: (context, snapshot) {
              if (!snapshot.hasData &&
                  snapshot.connectionState == ConnectionState.waiting)
                return Center(
                  child: CircularProgressIndicator(),
                );
              return Container(
                  padding: EdgeInsets.only(top: 50, left: 20, right: 20),
                  alignment: Alignment.topLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Recieved SMS Text:",
                        style: TextStyle(fontSize: 30),
                      ),
                      Divider(),
                      Text(
                        "SMS Text:" + sms,
                        style: TextStyle(fontSize: 20),
                      )
                    ],
                  ));
            }),
      ),
    );
  }

  void excgkey(String publickey, var sendernumber) async {
    print('called');
    String message = 'public:$publickey';
    List<String> recipents = [sendernumber.toString()];

    await sendSMS(message: message, recipients: recipents, sendDirect: true)
        .catchError((onError) {
      print(onError);
    });
  }

  String getpublickey(String publickeystr) {
    List<String> str = [];
    List cdunit = [];
    List mid = [];
    num midd;
    String publickey;

    str = publickeystr.split("");
    print(str);
    for (int i = 0; i < str.length; i++) {
      cdunit.add(str[i].codeUnits);
      midd = cdunit[i] - 68;
      mid.add(midd);
    }
    publickey = mid.join("");
    print('publickey$publickey');
    return publickey;
  }

  static num secretkey(String publickkey, num prvtkey) {
    num publ = int.parse(publickkey);

    num sec = pow(publ, prvtkey) % 17;
    print('secretkey$sec');
    return sec;
  }
}
