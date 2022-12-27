import 'dart:convert';
import 'dart:math';

class deffie {
  static num enc(num p, num q, num prvt) {
    num A;

    A = pow(q, prvt) % p;
    print('publ$A');
    return A;
  }

  static String chg(String key) {
    String changed;
    List intr = [];
    List splitted;
    int C;
    String D;

    splitted = key.split("");
    print(splitted);
    for (int i = 0; i < key.length; i++) {
      C = int.parse(splitted[i]) + 68;
      print(C);
      intr.add(String.fromCharCode(C));
    }
    changed = intr.join("");
    print(changed);
    return changed;
  }

  static String getpublickey(String publickeystr) {
    List<String> str = [];
    List cdunit = [];
    List mid = [];
    num midd;
    String publickey;

    str = publickeystr.split("");
    print(str);
    for (int i = 0; i < str.length; i++) {
      cdunit.add(AsciiEncoder().convert(str[i]));
      midd = cdunit[i] - 68;
      mid.add(midd);
    }
    publickey = mid.join("");
    print('publickey$publickey');
    return publickey;
  }

  static num secretkey(String publickkey, num prvtkey) {
    num publ = int.parse(publickkey);
    print(publ);
    print(prvtkey);

    num sec = pow(publ, prvtkey) % 17;
    print('secretkey$sec');
    return sec;
  }
}
