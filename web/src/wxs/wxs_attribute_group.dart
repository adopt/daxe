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


class WXSAttributeGroup extends WXSAnnotated implements Parent {
  
  List<WXSThing> _attrDecls; // _attrDecls: (attribute|attributeGroup)*
  String _name = null;
  String _ref = null;
  
  WXSAttributeGroup _wxsRef = null;
  Element _domElement;
  Parent _parent; // WXSComplexType | WXSRestriction | WXSExtension | WXSAttributeGroup | WXSRedefine
  WXSSchema _schema;
  
  
  WXSAttributeGroup(final Element el, final Parent parent, final WXSSchema schema) {
    _parseAnnotation(el);
    _attrDecls = new List<WXSThing>();
    for (Node n = el.firstChild; n != null; n=n.nextSibling) {
      if (n is Element) {
        if (n.localName == "attribute")
          _attrDecls.add(new WXSAttribute(n as Element, this, schema));
        else if (n.localName == "attributeGroup")
          _attrDecls.add(new WXSAttributeGroup(n as Element, this, schema));
      }
    }
    if (el.hasAttribute("name"))
      _name = el.getAttribute("name");
    if (el.hasAttribute("ref"))
      _ref = el.getAttribute("ref");
    
    _domElement = el;
    this._parent = parent;
    this._schema = schema;
  }
  
  String getNamespace() {
    return(_schema.getTargetNamespace());
  }
  
  Parent getParent() {
    return(_parent);
  }
  
  void resolveReferences(final WXSSchema schema, final WXSThing redefine) {
    for (WXSThing attrDecl in _attrDecls) {
      if (attrDecl is WXSAttribute)
        attrDecl.resolveReferences(schema);
      else if (attrDecl is WXSAttributeGroup)
        attrDecl.resolveReferences(schema, redefine);
    }
    if (_ref != null) {
      final String prefixe = DaxeWXS._namePrefix(_ref);
      String tns;
      if (prefixe == "xml")
        tns = "http://www.w3.org/XML/1998/namespace";
      else
        tns = _domElement.lookupNamespaceURI(prefixe);
      _wxsRef = schema.resolveAttributeGroupReference(DaxeWXS._localValue(_ref), tns, redefine);
    }
  }
  
  String getName() {
    if (_name == null && _wxsRef != null)
      return(_wxsRef.getName());
    return(_name);
  }
  
  // from Parent
  List<WXSElement> parentElements() {
    if (_parent != null)
      return(_parent.parentElements());
    return(new List<WXSElement>());
  }
  
  List<WXSAttribute> attributes() {
    if (_wxsRef != null)
      return(_wxsRef.attributes());
    final List<WXSAttribute> liste = new List<WXSAttribute>();
    for (WXSThing attrDecl in _attrDecls) {
      if (attrDecl is WXSAttribute)
        liste.add(attrDecl);
      else if (attrDecl is WXSAttributeGroup)
        liste.addAll(attrDecl.attributes());
    }
    return(liste);
  }
}
