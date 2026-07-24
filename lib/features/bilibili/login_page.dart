import 'dart:async';

import 'package:flutter/material.dart';

import 'login_panel.dart';
import 'session_store.dart';

class BilibiliLoginPage extends StatefulWidget {
  const BilibiliLoginPage({required this.sessionStore, super.key});

  final BilibiliSessionStore sessionStore;

  @override
  State<BilibiliLoginPage> createState() => _BilibiliLoginPageState();
}

class _BilibiliLoginPageState extends State<BilibiliLoginPage> {
  BilibiliQrCode? _qrCode;
  BilibiliQrLoginState? _loginState;
  Timer? _pollTimer;
  String? _error;
  var _checking = false;
  var _polling = false;
  var _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _refreshLoginStatus();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshLoginStatus() async {
    setState(() => _checking = true);
    final loggedIn = await widget.sessionStore.validate();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _loggedIn = loggedIn;
    });
  }

  Future<void> _startLogin() async {
    _pollTimer?.cancel();
    setState(() {
      _error = null;
      _qrCode = null;
      _loginState = null;
    });
    try {
      final code = await widget.sessionStore.createQrCode();
      if (!mounted) return;
      setState(() {
        _qrCode = code;
        _loginState = BilibiliQrLoginState.waitingForScan;
      });
      _pollTimer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => _pollLogin(),
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _pollLogin() async {
    final code = _qrCode;
    if (code == null || _polling) return;
    _polling = true;
    try {
      final result = await widget.sessionStore.pollQrCode(code.key);
      if (!mounted) return;
      setState(() => _loginState = result.state);
      if (!result.isTerminal) return;
      _pollTimer?.cancel();
      if (result.state == BilibiliQrLoginState.succeeded) {
        setState(() {
          _loggedIn = true;
          _qrCode = null;
        });
      }
    } catch (error) {
      _pollTimer?.cancel();
      if (mounted) setState(() => _error = error.toString());
    } finally {
      _polling = false;
    }
  }

  Future<void> _logout() async {
    _pollTimer?.cancel();
    await widget.sessionStore.clear();
    if (!mounted) return;
    setState(() {
      _loggedIn = false;
      _qrCode = null;
      _loginState = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('B站登录')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        BilibiliLoginPanel(
          loggedIn: _loggedIn,
          checking: _checking,
          qrCode: _qrCode,
          state: _loginState,
          error: _error,
          onStart: _startLogin,
          onLogout: _logout,
        ),
      ],
    ),
  );
}
