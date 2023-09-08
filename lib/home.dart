import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class Home extends StatefulWidget {


  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
 late WebViewController _controller;
  //late final WebViewController _controllerN;

  // String? newUrl='https://savinghm.ae/';
   String? newUrl='https://savinghm.ae/';


  late Size size;
 bool hasInternet = true;
 final Connectivity _connectivity = Connectivity();

 late StreamSubscription<ConnectivityResult> _connectivitySubscription;

 Future<void> checkInternetConnection() async {
   final connectivityResult = await Connectivity().checkConnectivity();
   setState(() {
     hasInternet = connectivityResult != ConnectivityResult.none;
   });
 }

 Future<bool> checkInternet() async{
   bool result = await InternetConnectionChecker().hasConnection;
   if(result == true) {
     return result;
   } else {
     print("net nai");
     return result;
     // print(InternetConnectionChecker().lastTryResults);
   }
 }

  // getUrl()async{
  //   getController();
  //   final prefs=await SharedPreferences.getInstance();
  //   newUrl=prefs.getString('url');
  //
  //
  // }
  getController()async{
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(

        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller =
    WebViewController.fromPlatformCreationParams(params)

      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress)async {

            debugPrint('WebView is loading (progress : $progress%)');

          },
          onPageStarted: (String url)async {
            checkInternetConnection();
            EasyLoading.show(
              status: 'loading...',
              maskType: EasyLoadingMaskType.black,
            );

            debugPrint('Page started loading: $url');
          },
          onPageFinished: (String url) async{
            debugPrint('Page finished loading: $url');
            EasyLoading.dismiss();
            await _controller.platform.enableZoom(false);


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
            if (request.url.startsWith('https://www.youtube.com/')) {
              debugPrint('blocking navigation to ${request.url}');
              return NavigationDecision.prevent;
            }
            debugPrint('allowing navigation to ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'Toaster',
        onMessageReceived: (JavaScriptMessage message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        },
      )
      ..loadRequest(Uri.parse(newUrl!));

    // #docregion platform_features
    if (_controller!.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (_controller!.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    // #enddocregion platform_features
    _controller.enableZoom(false);




  }

 Future<void> _updateConnectionStatus(ConnectivityResult result) async {
   setState(() {
     if(result == ConnectivityResult.none && hasInternet==true){
       hasInternet = false;
     }

     if(hasInternet== false && result != ConnectivityResult.none){
       hasInternet = true;
     }


   });
 }

  @override
  void initState(){

    getController();
    checkInternetConnection();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    //getUrl();
    //WebViewController _controller;
    // TODO: implement initState
    super.initState();

  }



  @override
  Widget build(BuildContext context) {

    size=MediaQuery.of(context).size;
    return WillPopScope(
      onWillPop: () async {
        if (await _controller.canGoBack()) {
          await _controller.goBack();
          return false;
        }
        else{
         return _onBackPressed(context);

        }
      },
      child: Scaffold(
        body: SafeArea(
          child: hasInternet?WebViewWidget(controller: _controller):
          Container(child: Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset("images/wifi.png",height: 100,width: 100,fit: BoxFit.fitWidth,),
              SizedBox(height:15),
              Text("No Internet Connection",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,color: Colors.black54),),
              
            ],
          )),),
        ),
      ),
    );
  }

 Future<bool> _onBackPressed(BuildContext context) {
   return showDialog(
     context: context,
     builder: (context) => AlertDialog(

       title: Text('Exit?',style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold),),
       content: Text('Do you want to exit the app?'),
       actions: [
         TextButton(


           onPressed: () => Navigator.of(context).pop(false), // No
           child: Text('No',style: TextStyle(color: Colors.blueAccent,),),
         ),
         TextButton(
           onPressed: () => Navigator.of(context).pop(true), // Yes
           child: Text('Yes',style: TextStyle(color: Colors.red,),)
         ),
       ],
     ),
   ).then((value) => value ?? false);
 }

}