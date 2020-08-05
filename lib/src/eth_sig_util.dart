@JS() // sets the context, in this case being `window`
library eth_sig_util;

import 'package:js/js.dart';

@JS('ethSigUtil.encryptMessage')
external String sigUtilEncryptMessage(
    String receiverPublicKey, message, String version);

@JS('ethSigUtil.encrypt')
external dynamic sigUtilEncrypt(
    String receiverPublicKey, message, String version);
