import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_sms/flutter_sms.dart';

class Rechargenumber extends StatefulWidget {
  const Rechargenumber({super.key});

  @override
  State<Rechargenumber> createState() => _RechargenumberState();
}

class _RechargenumberState extends State<Rechargenumber> {
  final number = TextEditingController();
  final amount = TextEditingController();
  bool wait = false;
  var dbref = FirebaseFirestore.instance.collection('UserData');
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
        ),
        body: Column(
          children: <Widget>[
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.15,
              child: Center(
                  child: Text(
                'Enter the details',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              )),
            ),
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(20),
              child: TextField(
                controller: number,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'MobileNumber/Id',
                  suffixIcon: Icon(
                    Icons.people,
                    color: Colors.red,
                  ),
                  floatingLabelStyle: TextStyle(
                      color: Colors.red,
                      fontSize: 25,
                      fontWeight: FontWeight.bold),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(17),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: (BorderSide(width: 1.0, color: Colors.black)),
                    borderRadius: BorderRadius.all(
                      Radius.circular(17),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: (BorderSide(width: 1.0, color: Colors.red)),
                    borderRadius: BorderRadius.all(
                      Radius.circular(17),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(20),
              child: TextField(
                controller: amount,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  suffixIcon: Icon(
                    Icons.attach_money_outlined,
                    color: Colors.green,
                  ),
                  floatingLabelStyle: TextStyle(
                      color: Colors.red,
                      fontSize: 25,
                      fontWeight: FontWeight.bold),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(17),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: (BorderSide(width: 1.0, color: Colors.black)),
                    borderRadius: BorderRadius.all(
                      Radius.circular(17),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: (BorderSide(width: 1.0, color: Colors.red)),
                    borderRadius: BorderRadius.all(
                      Radius.circular(17),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(top: 20, left: 10),
                  width: MediaQuery.of(context).size.width * 0.4,
                  child: ElevatedButton(
                    onPressed: cancel,
                    child: Text(
                      'Cancel',
                      style: TextStyle(fontSize: 22, color: Colors.red),
                    ),
                    style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                        elevation: 1,
                        shadowColor: Colors.white),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 20, left: 25),
                  width: MediaQuery.of(context).size.width * 0.45,
                  height: MediaQuery.of(context).size.height * 0.075,
                  child: ElevatedButton(
                    onPressed: send,
                    child: wait
                        ? Center(
                            child: CircularProgressIndicator(),
                          )
                        : Text(
                            'Send ',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontFamily: 'DelaGothic'),
                          ),
                    style: ElevatedButton.styleFrom(
                        enableFeedback: false,
                        elevation: 20,
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15))),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void send() async {
    setState(() {
      wait = !wait;
    });
    dbref
        .where('mobilenumber', isEqualTo: '+977' + number.text)
        .get()
        .then((QuerySnapshot querySnapshot) {
      print('object');
      querySnapshot.docs.forEach((data) async {
        if (data.exists) {
          print('reached');
          var mobile = number.text;
          var name = await data['name'];
          num balance = await data['balance'];
          var id = await data.id;
          var sentbl = amount.text;
          num addbl = balance + int.parse(amount.text);

          await dbref.doc(id).update({'balance': addbl});

          // send reciever the message that y[2] rupees is addded to reciever balance.
          String message1 =
              'Dear $name, \nYou have recieved Rs.$sentbl in your wallet from PayAnywhere.'
              '\nThankYou.';
          List<String> recipents1 = [mobile];

          String _result1 = await sendSMS(
                  message: message1, recipients: recipents1, sendDirect: true)
              .catchError((onError) {
            print(onError);
            setState(() {
              wait = !wait;
            });
          });

          Navigator.pop(context);
        }
      });
    });
  }

  void cancel() {
    Navigator.pop(context);
  }
}
