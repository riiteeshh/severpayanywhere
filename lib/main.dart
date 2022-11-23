import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:flutter/material.dart';

import 'package:telephony/telephony.dart';

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

  @override
  void initState() {
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) async {
        print(message.address); //+977981******67, sender nubmer
        print(message.body); //sms text
        print(message.date);
        sms = message.body.toString();
        print('data:$sms');
        var securitycode = '123478';
        var sendernumber = message.address;
        var x = sms;
        var y = x.split(":"); // o/p:[topup, 9865762048, 50]
        if (y.length == 3) {
          print(y.length);
          print(x.split(":")); //o/p:9865762048
          String sentmoney = y[2];

          if (y[0] == 'topup') {
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
                      print('topupntc');
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
                      print('topupncell');
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
                  print('reciever exist');
                  String recieverid = await reciever.id;
                  String recievername = await reciever['name'];
                  num recieverbalance = await reciever['balance'];
                  print(recieverid);
                  print(recievername);
                  await dbref
                      .where('mobilenumber', isEqualTo: sendernumber)
                      .get()
                      .then((QuerySnapshot querySnapshot) {
                    querySnapshot.docs.forEach((sender) async {
                      if (sender.exists) {
                        print('sender exist');
                        String sendername = await sender['name'];
                        num senderbalance = await sender['balance'];
                        String senderid = await sender.id;
                        print(senderid);
                        print(sendername);
                        if (senderbalance < int.parse(y[2])) {
                          String message =
                              'Dear $sendername, \nYou have no sufficient balance in your wallet.'
                              'Please recharge.\nThankYou.';
                          List<String> recipents = [sendernumber.toString()];

                          String _result = await sendSMS(
                                  message: message,
                                  recipients: recipents,
                                  sendDirect: true)
                              .catchError((onError) {
                            print(onError);
                          });
                        } else if (senderbalance >= int.parse(y[2])) {
                          print('transaction');
                          //sender balance should be subtracted by y[2]
                          num subtractedbl = senderbalance - int.parse(y[2]);
                          print(sendername);
                          print(subtractedbl);
                          //reciever bl added with y[2]
                          num addedbl = recieverbalance + int.parse(y[2]);
                          print(recievername);
                          print(addedbl);
                          //update sender balance in firestore
                          await dbref
                              .doc(senderid)
                              .update({'balance': subtractedbl});
                          //updated reciever balance in firestore
                          await dbref
                              .doc(recieverid)
                              .update({'balance': addedbl});

                          //send sender the message that y[2] rupees is deducted from sender balance.
                          String message =
                              'Dear $sendername, \nThe transaction of Rs.$sentmoney is successfull !'
                              '\nThankYou.';
                          List<String> recipents = [sendernumber.toString()];

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
      },
      listenInBackground: false,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text("Listen Incoming SMS in Flutter"),
            backgroundColor: Colors.redAccent),
        body: Container(
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
            )));
  }
}
