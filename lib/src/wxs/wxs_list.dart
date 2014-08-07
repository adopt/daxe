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



class WXSList extends WXSAnnotated {
  
  WXSSimpleType _simpleType = null;
  String _itemType = null;
  
  Element _domElement;
  
  
  WXSList(final Element el, final WXSSchema schema) {
    _parseAnnotation(el);
    for (Node n = el.firstChild; n != null; n=n.nextSibling) {
      if (n is Element && n.localName == "simpleType") {
        _simpleType = new WXSSimpleType(n as Element, null, schema);
        break;
      }
    }
    if (el.hasAttribute("itemType"))
      _itemType = el.getAttribute("itemType");
    
    _domElement = el;
  }
  
  void resolveReferences(final WXSSchema schema, final WXSThing redefine) {
    if (_simpleType != null)
      _simpleType.resolveReferences(schema, redefine);
    if (_itemType != null && _simpleType == null) {
      final String tns = _domElement.lookupNamespaceURI(DaxeWXS._namePrefix(_itemType));
      final WXSType wxsType = schema.resolveTypeReference(DaxeWXS._localValue(_itemType), tns, redefine);
      if (wxsType is WXSSimpleType)
        _simpleType = wxsType;
      else {
        final String espaceSchema = _domElement.namespaceURI;
        if (espaceSchema != tns)
          _itemType = null; // si le type n'a pas été résolu il doit être un type des schémas XML
      }
    }
  }
  
  bool validValue(final String value) {
    if (_simpleType == null && _itemType == null)
      return(false);
    if (value == null)
      return(false);
    final List<String> items = value.trim().split(new RegExp(r"\s+"));
    for (String item in items) {
      if (_simpleType != null) {
        if (!_simpleType.validValue(item))
          return(false);
      } else {
        if (!WXSSimpleType.validateTypeValue(DaxeWXS._localValue(_itemType), item))
          return(false);
      }
    }
    return(true);
  }
}
