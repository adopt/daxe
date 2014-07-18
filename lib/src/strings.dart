/*
  This file is part of Daxe.

  Daxe is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  Daxe is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Daxe.  If not, see <http://www.gnu.org/licenses/>.
*/

/// Provides localized strings.
library Strings;

import 'dart:async';
import 'dart:collection';
import 'dart:html' as h;
import 'package:intl/intl_browser.dart'; // or intl-standalone (see findSystemLocale)


/**
 * Provides localized strings read from properties files.
 * The current language file is read at application loading time.
 */
class Strings {
  
  static String resourcePath = "packages/daxe/LocalStrings";
  static HashMap<String, String> map = null;
  static String systemLocale;
  static const defaultLocale = 'en';
  
  static Future<bool> load() {
    Completer<bool> completer = new Completer<bool>();
    findSystemLocale().then((String sl) {
      // note: this is not always the language chosen by the user
      // see https://code.google.com/p/chromium/issues/detail?id=101138
      if (sl != null)
        systemLocale = sl;
      else
        systemLocale = defaultLocale;
      String language = systemLocale.split('_')[0];
      String fullFilePath = "${resourcePath}_$language.properties";
      
      h.HttpRequest request = new h.HttpRequest();
      request.open("GET", fullFilePath);
      request.onLoad.listen((h.ProgressEvent event) {
        String txt = request.responseText;
        map = new HashMap<String, String>();
        List<String> lines = txt.split("\n");
        for (String line in lines) {
          if (line.startsWith('#'))
            continue;
          int ind = line.indexOf('=');
          if (ind == -1)
            continue;
          String key = line.substring(0, ind).trim();
          String value = line.substring(ind + 1).trim();
          map[key] = value;
        }
        completer.complete(true);
      });
      request.onError.listen((h.ProgressEvent event) {
        completer.completeError("Error when reading the strings in $resourcePath");
      });
      request.send();
    });
    return(completer.future);
  }
  
  static String get(String key) {
    return(map[key]);
  }
  
}
