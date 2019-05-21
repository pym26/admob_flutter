/*
 Copyright (c) 2019 Kevin McGill <kevin@mcgilldevtech.com>
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

import Flutter
import Foundation
import GoogleMobileAds

class AdmobBanner : NSObject, FlutterPlatformView {

    private let channel: FlutterMethodChannel
    private let messeneger: FlutterBinaryMessenger
    private let frame: CGRect
    private let viewId: Int64
    private let args: [String: Any]
    private var adView: GADBannerView?

    init(frame: CGRect, viewId: Int64, args: [String: Any], messeneger: FlutterBinaryMessenger) {
        self.args = args
        self.messeneger = messeneger
        self.frame = frame
        self.viewId = viewId
        channel = FlutterMethodChannel(name: "admob_flutter/banner_\(viewId)", binaryMessenger: messeneger)
    }
    
    func view() -> UIView {
        return getBannerAdView() ?? UIView()
    }

    fileprivate func dispose() {
        adView?.removeFromSuperview()
        adView = nil
        channel.setMethodCallHandler(nil)
    }
    
    fileprivate func getBannerAdView() -> GADBannerView? {
        if adView == nil {
            adView = GADBannerView()
            adView!.rootViewController = UIApplication.shared.keyWindow?.rootViewController
            adView!.delegate = self
            adView!.frame = self.frame.width == 0 ? CGRect(x: 0, y: 0, width: 1, height: 1) : self.frame
            adView!.adUnitID = self.args["adUnitId"] as? String ?? "ca-app-pub-3940256099942544/6300978111"
            adView!.delegate = self
            channel.setMethodCallHandler { [weak self] (flutterMethodCall: FlutterMethodCall, flutterResult: FlutterResult) in
                switch flutterMethodCall.method {
                case "setListener":
//                    self?.adView?.delegate = self
                    break
                case "dispose":
                    self?.dispose()
                    break
                default:
                    flutterResult(FlutterMethodNotImplemented)
                }
            }
            requestAd()
        }
        
        return adView
    }
    
    fileprivate func requestAd() {
        if let ad = getBannerAdView() {
            let request = GADRequest()
//            if debug {
                request.testDevices = [kGADSimulatorID]
//            }
            ad.load(request)
        }
    }
    
    fileprivate func getSize() -> GADAdSize {
        let size = args["adSize"] as? [String: Any]
        let width = size!["width"] as? Int ?? 0
        let height = size!["height"] as? Int ?? 0
        let name = size!["name"] as! String
        
        switch name {
        case "BANNER":
            return kGADAdSizeBanner
        case "LARGE_BANNER":
            return kGADAdSizeLargeBanner
        case "MEDIUM_RECTANGLE":
            return kGADAdSizeMediumRectangle
        case "FULL_BANNER":
            return kGADAdSizeFullBanner
        case "LEADERBOARD":
            return kGADAdSizeLeaderboard
        case "SMART_BANNER":
            // TODO: Do we need Landscape too?
            return kGADAdSizeSmartBannerPortrait
        default:
            return GADAdSize.init(size: CGSize(width: width, height: height), flags: 0)
        }
    }

}

extension AdmobBanner : GADBannerViewDelegate {
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        channel.invokeMethod("loaded", arguments: nil)
    }
    
    func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
         channel.invokeMethod("failedToLoad", arguments: error)
    }
    
    /// Tells the delegate that a full screen view will be presented in response to the user clicking on
    /// an ad. The delegate may want to pause animations and time sensitive interactions.
    func adViewWillPresentScreen(_ bannerView: GADBannerView) {
        channel.invokeMethod("clicked", arguments: nil)
        channel.invokeMethod("opened", arguments: nil)
    }
    
    // TODO: not sure this exists on iOS. channel.invokeMethod("impression", null)
    
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        channel.invokeMethod("leftApplication", arguments: nil)
    }
    
    func adViewDidDismissScreen(_ bannerView: GADBannerView) {
        channel.invokeMethod("closed", arguments: nil)
    }
}
