@JS() // sets the context, in this case being `window`
library meta_mask; // required library declaration

import 'dart:async';
import 'dart:js' as js;
import 'dart:js_util';

import 'package:js/js.dart';

// https://docs.metamask.io/guide/getting-started.html#basic-considerations
// https://docs.metamask.io/guide/ethereum-provider.html !!!
// https://medium.com/metamask/breaking-changes-to-the-metamask-inpage-provider-b4dde069dd0a
class MetaMaskSupport {
  bool hasEthereum;
  bool isMetaMask;

  MetaMaskSupport() {
    hasEthereum = js.context.hasProperty("ethereum");
    isMetaMask = hasEthereum && js.context["ethereum"]["isMetaMask"];
  }

  Future<String> requestAccountAccess() {
    if (isMetaMask) {
      return promiseToFuture(_enable()).then((accounts) => accounts[0]);
    } else {
      return Future.error(Exception("No MetaMask found"));
    }
  }

  // https://eth.wiki/json-rpc/API#json-rpc-methods
  Future<dynamic> send(String method, params) {
    if (isMetaMask) {
      Map payload = Map();
      payload["jsonrpc"] = "2.0";
      payload["method"] = method;
      payload["params"] = params;
      payload["from"] = (js.context["ethereum"]
          as js.JsObject)["selectedAddress"]; // Deprecated

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
    // Issue: https://github.com/MetaMask/metamask-extension/issues/8993
    return send("web3_clientVersion", Map())
        .then((response) => getProperty(response, "result"));
  }

  Future<String> getEncryptionPublicKey() {
    return send(
            "eth_getEncryptionPublicKey",
            jsify([
              (js.context["ethereum"] as js.JsObject)["selectedAddress"]
            ])) // Deprecated
        .then((response) => getProperty(response, "result"));
  }
}

@JS("ethereum.enable") // Will be replaced by send('eth_requestAccounts') in the new API (send -> ethereum.request())
external dynamic _enable();

// https://github.com/logvik/test-dapp/blob/master/src/index.js
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1474.md
@JS("ethereum.send") // Also deprecated, use ethereum.request() instead.
external void _send(payload, callback);
