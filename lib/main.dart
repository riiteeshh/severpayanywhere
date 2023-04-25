import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:flutter/material.dart';
import 'package:encryptor/encryptor.dart';
import './sharedpref.dart';
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
        BigInt? secrett;
        int? accessnumber = 0;
        String? time;
        String? idd;

        print(message.address);
        print(message.body);

        var securitycode = '1231978'; // security code for ntc
        var sendernumber = message.address;
        var x = sms;
        var y;
        await dbref
            .where('mobilenumber', isEqualTo: sendernumber)
            .get()
            .then((QuerySnapshot dquery) {
          dquery.docs.forEach((clientdd) async {
            if (clientdd.exists) {
              accessnumber = await clientdd['databaseaccessnumber'];
              time = await clientdd['databaseaccesstime'];
              idd = await clientdd.id;
              print(accessnumber);
              print(time);
              print(idd);

              print('here');
              //  if (DateTime.now().compareTo(DateTime.parse(time!)) < 15) {
              if (accessnumber! <= 6) {
                print('reached access');
                if (accessnumber! == 0) {
                  await dbref.doc(idd).update(
                      {'databaseaccesstime': DateTime.now().toString()});
                }
                num inc = accessnumber! + 1;
                //start here
                await dbref.doc(idd).update({'databaseaccessnumber': inc});
                y = x.split(":");

                // var y = x.split(":"); // o/p:[topup, +97798657620198, 50]
                if (y.length == 1) {
                  if (y[0].length > 15) {
                    // print(y.length);

                    var decrypted = await Encryptor.decrypt(
                        await sharedpref.getdata('secretkey'),
                        message.body.toString()); //used 16
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
                              } else if (senderbalancebl >= int.parse(y[2])) {
                                String mobile = y[1];
                                String money = y[2];

                                if (y[1].startsWith('9819') ||
                                    y[1].startsWith('985') ||
                                    y[1].startsWith('986')) {
                                  // num subtractedbl = senderbalancebl - int.parse(y[2]);
                                  // print(sendernamebl);
                                  // print(subtractedbl);
                                  // await dbref
                                  //     .doc(senderidbl)
                                  //     .update({'balance': subtractedbl});
                                  String number =
                                      '*1922*$securitycode*$mobile*$money#';
                                  await FlutterPhoneDirectCaller.callNumber(
                                      number);
                                } else if (y[1].startsWith('980') ||
                                    y[1].startsWith('981') ||
                                    y[1].startsWith('982')) {
                                  num subtractedbl =
                                      senderbalancebl - int.parse(y[2]);
                                  // print(sendernamebl);
                                  // print(subtractedbl);
                                  // await dbref
                                  //     .doc(senderidbl)
                                  //     .update({'balance': subtractedbl});
                                  String number = '*919122*$mobile*$money#';
                                  await FlutterPhoneDirectCaller.callNumber(
                                      number);
                                } else {
                                  String message =
                                      'Sorry! The number provided can\'t be top-uped. Please provide a valid number.'
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
                                }
                              }
                            }
                          });
                        });
                      } else if (y[0] == 'transaction') {
                        print('transaction');
                        await dbref
                            .where('mobilenumber', isEqualTo: y[1])
                            .get()
                            .then((QuerySnapshot querySnapshot) {
                          querySnapshot.docs.forEach((reciever) async {
                            if (reciever.exists) {
                              print('reciever exists');
                              String recieverid = await reciever.id;
                              String recievername = await reciever['name'];
                              num recieverbalance = await reciever['balance'];
                              print(
                                  'reciever details $recieverid,$recievername,$recieverbalance');
                              await dbref
                                  .where('mobilenumber',
                                      isEqualTo: sendernumber)
                                  .get()
                                  .then((QuerySnapshot querySnapshot) {
                                querySnapshot.docs.forEach((sender) async {
                                  if (sender.exists) {
                                    print('sender exist');
                                    String sendername = await sender['name'];
                                    num senderbalance = await sender['balance'];
                                    String senderid = await sender.id;
                                    print(
                                        'sender details $senderid,$senderbalance,$senderid');

                                    if (senderbalance < int.parse(y[2])) {
                                      print('reached no balance');
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
                                    } else if (senderbalance >=
                                        int.parse(y[2])) {
                                      print('reached balalnce available');
                                      //sender balance should be subtracted by y[2]
                                      num subtractedbl =
                                          senderbalance - int.parse(y[2]);
                                      print('subt:$subtractedbl');
                                      //reciever bl added with y[2]
                                      num addedbl =
                                          recieverbalance + int.parse(y[2]);
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
                                      print('reacehed statement sent');
                                      var datasss =
                                          await dbref.doc(senderid).get();
                                      print(datasss['sent']);
                                      List dataaddsent = [];
                                      dataaddsent.addAll(datasss['sent']);
                                      dataaddsent.add(sentdataa);
                                      print(dataaddsent);

                                      await dbref
                                          .doc(senderid)
                                          .update({'sent': dataaddsent});
                                      //ldshad
                                      print('reacehed statement recieved');

                                      var datassr =
                                          await dbref.doc(recieverid).get();
                                      print(datassr['recieved']);
                                      List dataaddrecieved = [];
                                      dataaddrecieved
                                          .addAll(datassr['recieved']);
                                      dataaddrecieved.add(recieveddata);
                                      print(dataaddrecieved);
                                      await dbref.doc(recieverid).update(
                                          {'recieved': dataaddrecieved});
                                      print('reached messaging');

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
                                      List<String> recipents1 = [
                                        y[1].toString()
                                      ];

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
                    String key = await deffie
                        .enc(BigInt.from(15485863), BigInt.from(32452867), prvt)
                        .toString(); //for bigint
                    //String key = await deffie.enc(919, 19, prvt).toString(); //for num
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
              } else if (accessnumber! > 6) {
                //start here
                print('reached here');
                num dataaaa =
                    DateTime.now().second - (DateTime.parse(time!).second);
                print(dataaaa);
                if (DateTime.now().second - (DateTime.parse(time!).second) <
                    15) {
                  await dbref.doc(idd).update({'databaseaccessnumber': 0});
                  print('reset');
                } else {
                  print('blocked');
                }
              }
            }
          });
        });
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

  static Future<BigInt> secretkey(String publickkey, num prvtkey) async {
    num publ = int.parse(publickkey);
    BigInt sec =
        ((BigInt.from(publ)) ^ (BigInt.from(prvtkey))) % BigInt.from(15485863);
    // num sec = pow(publ, prvtkey) % 919; //used 919
    await sharedpref.cleardata();
    await sharedpref.savedata('secretkey', sec.toString());
    print('secretkey$sec');
    return sec;
  }
}
