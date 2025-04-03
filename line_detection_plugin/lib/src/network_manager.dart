import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';

/// APP网络管理器
class NetworkManager extends ChangeNotifier {
  static final NetworkManager _instance = NetworkManager._();

  static NetworkManager get instance => _instance;

  Timer? _timer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  int _networkStatus = -1;
  final List<String> _hosts = ['www.baidu.com','223.5.5.5'];
  int get networkStatus => _networkStatus;

  /// 构造函数
  NetworkManager._() {
    /// 监听网络变化
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((ret) {
      checkNetwork();
    });
  }

  /// 销毁
  @override
  void dispose() {
    super.dispose();
    _connectivitySubscription?.cancel();
    _timer?.cancel();
    _timer = null;
  }

  /// 更新状态
  void _setNetworkStatus(int value) {
    if (_networkStatus != value) {
      _networkStatus = value;

      /// 当网络不可用时，自动启动定时器
      if (value != 2) {
        _timer ??= Timer.periodic(const Duration(milliseconds: 3000), (t) {
          checkNetwork();
        });
      } else {
        _timer?.cancel();
        _timer = null;
      }

      /// 通知订阅者
      notifyListeners();
    }
  }

  /// 网络检查
  Future<void> checkNetwork() async {
    var localStatus = await hasLocalNet();
    if (localStatus) {
      var internetStatus = await hasInternet(hosts: _hosts);
      if (internetStatus) {
        _setNetworkStatus(2); // 有网
      } else {
        _setNetworkStatus(1); // 本地有连接，但是没有互联网
      }
    } else {
      _setNetworkStatus(0); // 没有网
    }
  }

  /// 检查本地网络
  Future<bool> hasLocalNet() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.isEmpty ||
        connectivityResult[0] == ConnectivityResult.none) {
      return false;
    }
    return true;
  }

  /// 检测是否能连接互联网
  Future<bool> hasInternet(
      {required List<String> hosts, port = 80, timeout = 3}) async {
    try {
      await InternetChecker(hosts: hosts, port: port, timeout: timeout).run();
      return true;
    } catch (e) {
      return false;
    }
  }
}

class InternetChecker {
  int _errorCount = 0;
  List<String> hosts;
  int port;
  int timeout;

  InternetChecker(
      {required this.hosts, required this.port, required this.timeout});

  Future<Socket> run() {
    _errorCount = 0;
    return _any(hosts.map((host) =>
        Socket.connect(host, port, timeout: Duration(seconds: timeout))));
  }

  Future<T> _any<T>(Iterable<Future<T>> futures) {
    var completer = Completer<T>.sync();
    void onValue(T value) {
      if (!completer.isCompleted) completer.complete(value);
    }

    void onError(Object error, StackTrace stack) {
      _errorCount++;
      if (futures.length == _errorCount) {
        if (!completer.isCompleted) completer.completeError(error, stack);
      }
    }

    for (var future in futures) {
      future.then(onValue, onError: onError);
    }
    return completer.future;
  }
}
