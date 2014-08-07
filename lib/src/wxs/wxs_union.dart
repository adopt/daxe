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



class WXSUnion extends WXSAnnotated {
  
  // (simpleType)*
  List<WXSSimpleType> _simpleTypes;
  List<String> _memberTypes = null;
  
  Element _domElement;
  List<WXSSimpleType> _wxsMemberTypes;
  
  
  WXSUnion(final Element el, final WXSSchema schema) {
    _parseAnnotation(el);
    _simpleTypes = new List<WXSSimpleType>();
    for (Node n = el.firstChild; n != null; n=n.nextSibling) {
      if (n is Element && n.localName == "simpleType")
        _simpleTypes.add(new WXSSimpleType(n as Element, null, schema));
    }
    if (el.hasAttribute("memberTypes"))
      _memberTypes = (el.getAttribute("memberTypes")).split(new RegExp(r"\s+"));
    
    _domElement = el;
    _wxsMemberTypes = null;
  }
  
  void resolveReferences(final WXSSchema schema, final WXSThing redefine) {
    for (WXSSimpleType simpleType in _simpleTypes)
      simpleType.resolveReferences(schema, redefine);
    if (_memberTypes != null) {
      _wxsMemberTypes = new List<WXSSimpleType>(_memberTypes.length);
      for (int i=0; i<_memberTypes.length; i++) {
        final String type = _memberTypes[i];
        final String tns = _domElement.lookupNamespaceURI(DaxeWXS._namePrefix(type));
        final WXSType wxsType = schema.resolveTypeReference(DaxeWXS._localValue(type), tns, redefine);
        if (wxsType is WXSSimpleType)
          _wxsMemberTypes[i] = wxsType;
        else {
          _wxsMemberTypes[i] = null;
          final String espaceSchema = _domElement.namespaceURI;
          if (espaceSchema != tns)
            _memberTypes[i] = null; // si le type n'a pas été résolu il doit être un type des schémas XML
        }
      }
    }
  }
  
  List<String> possibleValues() {
    final List<String> liste = new List<String>();
    if (_memberTypes != null) {
      for (int i=0; i<_memberTypes.length; i++) {
        if (_wxsMemberTypes[i] != null) {
          final List<String> lv = _wxsMemberTypes[i].possibleValues();
          if (lv == null)
            return(null);
          liste.addAll(lv);
        } else {
          final String type = _memberTypes[i];
          final String tns = _domElement.lookupNamespaceURI(DaxeWXS._namePrefix(type));
          final String espaceSchema = _domElement.namespaceURI;
          if (espaceSchema == tns) {
            final List<String> lv = DaxeWXS._booleanValues(type, _domElement);
            if (lv == null)
              return(null);
            liste.addAll(lv);
          }
        }
      }
    }
    for (WXSSimpleType st in _simpleTypes) {
      final List<String> listest = st.possibleValues();
      if (listest == null)
        return(null);
      liste.addAll(listest);
    }
    if (liste.length == 0)
      return(null);
    return(liste);
  }
  
  bool validValue(final String value) {
    if (_memberTypes != null) {
      for (int i=0; i<_memberTypes.length; i++) {
        if (_wxsMemberTypes[i] != null) {
          if (_wxsMemberTypes[i].validValue(value))
            return(true);
        } else if (_memberTypes[i] != null) {
          if (WXSSimpleType.validateTypeValue(DaxeWXS._localValue(_memberTypes[i]), value))
            return(true);
        }
      }
    }
    for (final WXSSimpleType st in _simpleTypes) {
      if (st.validValue(value))
        return(true);
    }
    return(false);
  }
}
