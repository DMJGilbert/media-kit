/// This file is a part of media_kit (https://github.com/media-kit/media-kit).
///
/// Copyright © 2021 & onwards, WanJiMi.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'package:synchronized/synchronized.dart';

// --------------------------------------------------

/// {@template hls}
///
/// HLS
/// ---
///
/// Adds [HLS.js](https://github.com/video-dev/hls.js/) to the HTML document using [web.HTMLScriptElement].
///
/// {@endtemplate}
abstract class HLS {
  static Future<void> ensureInitialized({String? hls}) {
    return _lock.synchronized(() async {
      if (_initialized) {
        return;
      }
      final completer = Completer();
      try {
        final script = web.HTMLScriptElement()
          ..async = true
          ..charset = 'utf-8'
          ..type = 'text/javascript'
          ..src = hls ?? kHLSAsset;

        script.onLoad.listen((_) {
          if (!completer.isCompleted) {
            completer.complete();
          }
        });
        script.onError.listen((_) {
          if (!completer.isCompleted) {
            completer.completeError(Exception('Failed to load HLS.js'));
          }
        });

        web.HTMLHeadElement? head = web.document.head;
        if (head == null) {
          head = web.HTMLHeadElement();
          web.document.append(head);
        }
        head.append(script);
      } catch (_) {
        if (!completer.isCompleted) {
          completer.completeError(Exception('Failed to load HLS.js'));
        }
      }
      try {
        await completer.future;
        _initialized = true;
      } catch (exception, stacktrace) {
        print(exception.toString());
        print(stacktrace.toString());
      }
    });
  }

  static const String kHLSAsset =
      'assets/packages/media_kit/assets/web/hls1.7.2.js';
  static const String kHLSCDN =
      'https://cdnjs.cloudflare.com/ajax/libs/hls.js/1.7.2/hls.js';

  static final Lock _lock = Lock();
  static bool _initialized = false;
}

// --------------------------------------------------

@JS('Hls.isSupported')
external bool isHLSSupported();

@JS()
@staticInterop
abstract class XHRSetupCallback {}

extension on XHRSetupCallback {
  // ignore: unused_element
  external void call(web.XMLHttpRequest xhr, String url);
  // todo: is this even important? I am not familiar with this.
}

@JS()
@anonymous
@staticInterop
class HlsOptions {
  external factory HlsOptions({
    XHRSetupCallback? xhrSetup,
  });
}

@JS()
@staticInterop
class Hls {
  external factory Hls(HlsOptions options);
}

extension ExtensionHls on Hls {
  external void loadSource(String src);
  external void attachMedia(web.HTMLVideoElement video);
  external void destroy();
  external void on(String event, JSFunction listener);

  /// Detaches and re-attaches the media element, which clears its error and
  /// resumes loading where playback stopped. Does not resume playback.
  external void recoverMediaError();

  /// Alternate audio renditions listed in the multivariant playlist.
  external HlsTrackList get audioTracks;
}

@JS()
@staticInterop
class HlsTrackList {}

extension ExtensionHlsTrackList on HlsTrackList {
  external int get length;
}

/// Name of the hls.js error event, for [ExtensionHls.on].
@JS('Hls.Events.ERROR')
external String get hlsErrorEvent;

/// Name of the hls.js event fired once a MediaSource is attached to the
/// element, for [ExtensionHls.on].
@JS('Hls.Events.MEDIA_ATTACHED')
external String get hlsMediaAttachedEvent;

/// Name of the hls.js event fired when it creates source buffers for the
/// tracks it found in the stream, for [ExtensionHls.on].
@JS('Hls.Events.BUFFER_CODECS')
external String get hlsBufferCodecsEvent;

/// The data hls.js passes to a buffer codecs listener: one entry per source
/// buffer, absent for a track the stream lacks or hls.js cannot demux.
@JS()
@staticInterop
class HlsBufferCodecsData {}

extension ExtensionHlsBufferCodecsData on HlsBufferCodecsData {
  external JSObject? get audio;
  external JSObject? get audiovideo;
}

/// The data hls.js passes to an error listener.
@JS()
@staticInterop
class HlsErrorData {}

extension ExtensionHlsErrorData on HlsErrorData {
  /// Broad category, e.g. networkError or mediaError.
  external String get type;

  /// Specific cause, e.g. manifestLoadError or fragLoadError.
  external String get details;

  /// hls.js stops after a fatal error; the rest it retries by itself.
  external bool get fatal;

  /// The URL that failed, for playlist and key requests.
  external String? get url;

  /// The fragment that failed, for segment requests.
  external HlsFragment? get frag;

  external HlsErrorResponse? get response;
}

@JS()
@staticInterop
class HlsFragment {}

extension ExtensionHlsFragment on HlsFragment {
  external String get url;
}

@JS()
@staticInterop
class HlsErrorResponse {}

extension ExtensionHlsErrorResponse on HlsErrorResponse {
  /// HTTP status; 0 when the browser refused or could not make the request.
  external int? get code;
}

// --------------------------------------------------
