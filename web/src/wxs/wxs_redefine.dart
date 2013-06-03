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



class WXSRedefine implements WXSThing, Parent {
  
  // annotations : inutile ici
  List<WXSThing> _redefinables; // (simpleType|complexType|group|attributeGroup)
  String _schemaLocation = null; // URI
  
  WXSSchema _schemaInclu = null;
  WXSSchema _schema;
  
  
  WXSRedefine(final Element el, final WXSSchema schema) {
    _redefinables = new List<WXSThing>();
    for (Node n = el.firstChild; n != null; n=n.nextSibling) {
      if (n is Element) {
        if (n.localName == "simpleType")
          _redefinables.add(new WXSSimpleType(n as Element, this, schema));
        else if (n.localName == "complexType")
          _redefinables.add(new WXSComplexType(n as Element, this, schema));
        else if (n.localName == "group")
          _redefinables.add(new WXSGroup(n as Element, this, schema));
        else if (n.localName == "attributeGroup")
          _redefinables.add(new WXSAttributeGroup(n as Element, this, schema));
      }
    }
    if (el.hasAttribute("schemaLocation"))
      _schemaLocation = el.getAttribute("schemaLocation");
    
    this._schema = schema;
  }
  
  Future _inclusions(final WXSSchema schema) { // can throw a WXSException
    Completer completer = new Completer();
    schema.newIncludedSchema(_schemaLocation, null, schema).then((WXSSchema schema) {
      _schemaInclu = schema;
      completer.complete();
    }, onError: (WXSException ex) {
      completer.completeError(ex);
    });
    return(completer.future);
  }
  
  List<WXSThing> getRedefinables() {
    return(_redefinables);
  }
  
  // from Parent
  List<WXSElement> parentElements() {
    return(new List<WXSElement>());
  }
  
  String getNamespace() {
    return(_schema.getTargetNamespace());
  }
  
}
