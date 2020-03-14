@JS() // sets the context, in this case being `window`
library meta_mask; // required library declaration

import 'dart:async';
import 'dart:js' as js;
import 'dart:js_util';

import 'package:js/js.dart';

// https://docs.metamask.io/guide/getting-started.html#basic-considerations
// https://docs.metamask.io/guide/ethereum-provider.html
// https://modulovalue.com/web3js_test_page/#/
class MetaMaskSupport {
  bool hasEthereum;
  bool hasWeb3;
  bool isMetaMask;
  bool isMetaMaskEnabled;

  MetaMaskSupport() {
    hasEthereum = js.context.hasProperty("ethereum");
    hasWeb3 = js.context.hasProperty("web3");
    isMetaMask = hasEthereum && js.context["ethereum"]["isMetaMask"];
    isMetaMaskEnabled = isMetaMask &&
        (js.context["ethereum"]["_metamask"] as js.JsObject)
            .callMethod("isEnabled");
    // 'isEnabled' will be removed: https://medium.com/metamask/breaking-changes-to-the-metamask-inpage-provider-b4dde069dd0a
  }

  Future<String> requestAccountAccess() {
    if (isMetaMask) {
      return promiseToFuture(_enable()).then((accounts) => accounts[0]);
    } else {
      return Future.error(Exception("No MetaMask found"));
    }
  }

  Future<dynamic> send(String method, params) {
    if (isMetaMask) {
      Map payload = Map();
      payload["jsonrpc"] = "2.0";
      payload["method"] = method;
      payload["params"] = params;
      payload["from"] =
          (js.context["web3"]["eth"] as js.JsObject)["defaultAccount"];

      final completer = Completer<dynamic>();
      _send(
          jsify(payload),
          allowInterop((err, response) => () {
                (js.context["console"] as js.JsObject)
                    .callMethod("log", <dynamic>[err, response]);
                if (err == null) {
                  completer.complete(response);
                } else {
                  completer.completeError(err);
                }
              }()));
      return completer.future;
    } else {
      return Future.error(Exception("No MetaMask found"));
    }
  }

  Future<String> clientVersion() {
    return send("web3_clientVersion", Map())
        .then((response) => response.result);
  }

  Future<String> getEncryptionPublicKey() {
    return send(
            "eth_getEncryptionPublicKey",
            jsify(
                [(js.context["web3"]["eth"] as js.JsObject)["defaultAccount"]]))
        .then((response) => response.result);
  }
}

@JS("ethereum.enable") // Will be replaced by send('eth_requestAccounts') in the new API
external dynamic _enable();

// https://github.com/logvik/test-dapp/blob/master/src/index.js
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1474.md
@JS("ethereum.send")
external void _send(payload, callback);
