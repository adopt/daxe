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

part of xmldom;

class DOMParser {
  
  Future<Document> parseFromURL(String url, {/*bool useBrowserXMLParser:false,*/ bool disableCache:true}) { // throws DOMException
    Completer<Document> completer = new Completer<Document>();
    // DomParser and responseXml don't work with IE9
    // http://code.google.com/p/dart/issues/detail?id=7937
    // xml-dart does not support XML comments, and its support for namespaces is limited
    h.HttpRequest request = new h.HttpRequest();
    // overrideMimeType doesn't work in IE (even IE10)
    //if (request.supportsOverrideMimeType)
    //  request.overrideMimeType('text/xml');
    if (disableCache) {
      // request.setRequestHeader('Pragma', 'no-cache');
      // request.setRequestHeader('Cache-Control', 'no-cache'); // or: private, max-age=0
      // This doesn't work with IE9
      // see http://stackoverflow.com/q/5235464/438970
      // When the URL does not include a script and might use Apache directly,
      // we have to add a random parameter to the URL to avoid the IE cache.
      if (!url.contains('.php?')) {
        Random rnd = new Random();
        String param = "random_workaround=${rnd.nextDouble()}";
        if (url.contains('?'))
          url = "$url&$param";
        else
          url = "$url?$param";
      }
    }
    request.open('GET', url);
    request.onLoad.listen((h.ProgressEvent event) {
      if (request.status != 200) {
        completer.completeError(new DOMException("Error reading $url",
            errorCode: request.status));
        return;
      }
      Document xdoc;
      /*
      if (useBrowserXMLParser) {
        h.Document hdoc = request.responseXml;
        if (hdoc == null) {
          if (request.responseText != null)
            completer.completeError(new DOMException("Error parsing XML from $url"));
          else
            completer.completeError(new DOMException("Error reading $url"));
          return;
        }
        // https://bugzilla.mozilla.org/show_bug.cgi?id=45566
        // http://stackoverflow.com/q/11563554/438970
        // http://code.google.com/p/dart/issues/detail?id=7938
        //FIXME: $dom_namespaceUri and localName seem to be deprecated, use tagName instead ?
        if (hdoc.documentElement.$dom_namespaceUri == "http://www.mozilla.org/newlayout/xml/parsererror.xml" &&
            hdoc.documentElement.localName == "parsererror") {
          completer.completeError(new DOMException("Error parsing XML from $url"));
          return;
        }
        DOMImplementationImpl dom = new DOMImplementationImpl();
        xdoc = dom.createDocumentFromDH(hdoc);
      } else {
      */
        // warning: at this point responseText can have the wrong character encoding with IE,
        // unless Unicode is used
        if (request.responseText == null) {
          completer.completeError(new DOMException("Error reading $url"));
          return;
        }
        try {
          xdoc = parseFromString(request.responseText);
        } on DOMException catch(ex) {
          completer.completeError(new DOMException("Error reading $url: ${ex.message}"));
          return;
        }
      //}
      completer.complete(xdoc);
    });
    request.onError.listen((h.ProgressEvent event) {
      completer.completeError(new DOMException("Error reading $url"));
    });
    request.send();
    return(completer.future);
  }
  
  /*
  Document parseFromStringWithDartDOM(String s) { // throws DOMException
    h.DomParser parser = new h.DomParser();
    h.Document hdoc = parser.parseFromString(s, "text/xml");
    DOMImplementationImpl dom = new DOMImplementationImpl();
    Document xdoc = dom.createDocumentFromDH(hdoc);
    if (xdoc.getElementsByTagName('parsererror').length > 0)
      throw new DOMException("Error parsing XML from string");
    return(xdoc);
  }
  */
  
  Document parseFromString(String s) { // throws DOMException
    XMLParser parser = new XMLParser();
    try {
      return(parser.parseString(s));
    } on Exception catch(ex) {
      throw new DOMException(ex.toString());
    }
  }
}
