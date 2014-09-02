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


class WXSAttribute extends WXSAnnotated {
  
  WXSSimpleType _simpleType = null;
  String _name = null;
  String _ref = null;
  String _type = null;
  String _use = null; // (prohibited|optional|required)
  String _defaultAtt = null;
  String _fixed = null;
  String _form = null; // (qualified|unqualified)
  
  WXSAttribute _wxsRef = null;
  Element _domElement;
  Parent _parent; // WXSComplexType | WXSRestriction | WXSExtension | WXSAttributeGroup
  WXSSchema _schema;
  
  
  WXSAttribute(final Element el, final Parent parent, final WXSSchema schema) {
    _parseAnnotation(el);
    for (Node n = el.firstChild; n != null; n=n.nextSibling) {
      if (n is Element && n.localName == "simpleType") {
        _simpleType = new WXSSimpleType(n as Element, null, schema);
        break;
      }
    }
    if (el.hasAttribute("name"))
      _name = el.getAttribute("name");
    if (el.hasAttribute("ref"))
      _ref = el.getAttribute("ref");
    if (el.hasAttribute("type"))
      _type = el.getAttribute("type");
    if (el.hasAttribute("use"))
      _use = el.getAttribute("use");
    if (el.hasAttribute("default"))
      _defaultAtt = el.getAttribute("default");
    if (el.hasAttribute("fixed"))
      _fixed = el.getAttribute("fixed");
    if (el.hasAttribute("form"))
      _form = el.getAttribute("form");
    
    _domElement = el;
    this._parent = parent;
    this._schema = schema;
  }
  
  void resolveReferences(final WXSSchema schema) {
    if (_simpleType != null)
      _simpleType.resolveReferences(schema, null);
    if (_ref != null) {
      final String prefixe = DaxeWXS._namePrefix(_ref);
      String tns;
      if (prefixe == "xml")
        tns = "http://www.w3.org/XML/1998/namespace";
      else
        tns = _domElement.lookupNamespaceURI(prefixe);
      _wxsRef = schema.resolveAttributeReference(DaxeWXS._localValue(_ref), tns);
      if (_wxsRef == null)
        print("WXSAttribute: Référence d'attribut introuvable : $_ref");
    }
    if (_simpleType == null && _type != null) {
      final String tns = _domElement.lookupNamespaceURI(DaxeWXS._namePrefix(_type));
      // pas de résolution pour les types du superschéma, sauf pour le superschéma
      if (tns == null || tns != _domElement.namespaceURI ||
          schema.getTargetNamespace() == null || schema.getTargetNamespace() == _domElement.namespaceURI) {
        final WXSType wxsType = schema.resolveTypeReference(DaxeWXS._localValue(_type), tns, null);
        if (wxsType is WXSSimpleType)
          _simpleType = wxsType;
      }
    }
    if (_simpleType == null && _wxsRef != null)
      _simpleType = _wxsRef._simpleType;
  }
  
  String getName() {
    if (_name == null && _wxsRef != null)
      return(_wxsRef.getName());
    return(_name);
  }
  
  String getUse() {
    return(_use);
  }
  
  String getForm() {
    return(_form);
  }
  
  Element getDOMElement() {
    return(_domElement);
  }
  
  String getNamespace() {
    if (_ref != null) {
      final String prefixe = DaxeWXS._namePrefix(_ref);
      if (prefixe != null) {
        final String ns = _domElement.lookupNamespaceURI(prefixe);
        if (ns != null)
          return(ns);
        if (prefixe == "xml")
          return("http://www.w3.org/XML/1998/namespace");
        return(null);
      }
    }
    bool qualified;
    if (_schema.getTopAttributes().contains(this))
      qualified = true;
    else if (_form != null)
      qualified = (_form == "qualified");
    else
      qualified = (_schema.getAttributeFormDefault() == "qualified");
    if (qualified) {
      final String tn = _schema.getTargetNamespace();
      if (tn == "")
        return(null);
      else
        return(tn);
    } else
      return(null);
  }
  
  WXSAttribute getWXSRef() {
    return(_wxsRef);
  }
  
  List<WXSElement> parentElements() {
    if (_parent != null)
      return(_parent.parentElements());
    return(new List<WXSElement>());
  }
  
  List<String> possibleValues() {
    if (_fixed != null) {
      final List<String> fixedval = new List<String>();
      fixedval.add(_fixed);
      return(fixedval);
    }
    if (_schema.getTargetNamespace() != null && _schema.getTargetNamespace() == _domElement.namespaceURI &&
        DaxeWXS._localValue(_type) == "bool")
      return(DaxeWXS._booleanValues(_type, _domElement)); // cas du superschéma
    if (_simpleType != null)
      return(_simpleType.possibleValues());
    else if (_type != null)
      return(DaxeWXS._booleanValues(_type, _domElement));
    return(null);
  }
  
  List<String> suggestedValues() {
    if (_fixed != null) {
      final List<String> fixedval = new List<String>();
      fixedval.add(_fixed);
      return(fixedval);
    }
    if (_schema.getTargetNamespace() != null && _schema.getTargetNamespace() == _domElement.namespaceURI &&
        DaxeWXS._localValue(_type) == "bool")
      return(DaxeWXS._booleanValues(_type, _domElement)); // cas du superschéma
    if (_simpleType != null)
      return(_simpleType.suggestedValues());
    else if (_type != null)
      return(DaxeWXS._booleanValues(_type, _domElement));
    return(null);
  }
  
  String defaultValue() {
    if (_defaultAtt != null)
      return(_defaultAtt);
    else if (_fixed != null)
      return(_fixed);
    else if (_wxsRef != null)
      return(_wxsRef.defaultValue());
    return(null);
  }
  
  bool validValue(final String value) {
    if (_fixed != null)
      return(_fixed == value);
    if  ((value == null || value == "") && _use == "required")
      return(false);
    if (_simpleType != null)
      return(_simpleType.validValue(value));
    if (_type != null) {
      final String tns = _domElement.lookupNamespaceURI(DaxeWXS._namePrefix(_type));
      if (tns != null && tns == _domElement.namespaceURI)
        return(WXSSimpleType.validateTypeValue(DaxeWXS._localValue(_type), value));
    }
    if (_wxsRef != null)
      return(_wxsRef.validValue(value));
    if (_type == null)
      return(true);
    return(false);
  }
}
