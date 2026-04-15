import 'package:flutter/material.dart';
import 'package:flutter_app/Utilities/bottom_navigation.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Import for Android and iOS specific WebView implementations
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FacebookLogin extends StatefulWidget {
  const FacebookLogin({super.key});

  @override
  State<FacebookLogin> createState() => _FacebookLoginState();
}

class _FacebookLoginState extends State<FacebookLogin> {
  late final WebViewController _controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    // Create platform-specific WebView instances
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    // Configure the controller
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('WebView is loading (progress : $progress%)');
          },
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
            });

            if (url.contains('code=')) {
              final uri = Uri.parse(url);
              final code = uri.queryParameters['code'];
              print('response code: ${code}');
              if (code != null) {
                Navigator.pop(context);
                sendCodeToApi(code);
              }
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''
              Page resource error:
              code: ${error.errorCode}
              description: ${error.description}
              errorType: ${error.errorType}
              isForMainFrame: ${error.isForMainFrame}
          ''');
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.facebook.com/v18.0/dialog/oauth'
          '?client_id=3912930388947496'
          '&redirect_uri=${Navigator.push(context, MaterialPageRoute(builder: (context) => Navigation()))}'
          '&scope=email,public_profile'
          '&response_type=code'));

    // If using Android, configure platform specific settings
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facebook Login'),
      ),
      body: Stack(
        children: [
          WebViewWidget(
            controller: _controller,
          ),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Future<void> sendCodeToApi(String code) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.160/Apis/facebookSignIn'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'code': code,
        }),
      );

      print('respone: ${response.body}');
      if (response.statusCode == 200) {
        debugPrint('API call successful');
        debugPrint('Response: ${response.body}');
      } else {
        debugPrint('API call failed with status: ${response.statusCode}');
        debugPrint('Error: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error sending code to API: $e');
    }
  }
}
