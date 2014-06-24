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

part of wxs;



class WXSImport extends WXSAnnotated {
  
  String _namespace = null; // URI
  String _schemaLocation = null; // URI
  
  WXSSchema _schemaInclu = null;
  
  
  WXSImport(final Element el, final WXSSchema schema) {
    if (el.hasAttribute("namespace"))
      _namespace = el.getAttribute("namespace");
    if (el.hasAttribute("schemaLocation"))
      _schemaLocation = el.getAttribute("schemaLocation");
  }
  
  Future _inclusions(final WXSSchema schema) { // can throw a WXSException
    if (_schemaLocation == null)
      return(new Future.value(null));
    Completer completer = new Completer();
    schema.newIncludedSchema(_schemaLocation, _namespace, schema).then((WXSSchema schema) {
      _schemaInclu = schema;
      completer.complete();
    }, onError: (WXSException ex) {
      completer.completeError(ex);
    });
    return(completer.future);
  }
  
}
