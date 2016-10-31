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


class WXSExtension extends WXSAnnotated implements WithSubElements, Parent {

  // (group|all|choice|sequence)?, (attribute|attributeGroup)*
  WithSubElements _model = null; // WXSGroup | WXSAll | WXSChoice | WXSSequence
  List<WXSThing> _attrDecls; // attrDecls: (attribute|attributeGroup)*
  String _base = null;
  WXSType _wxsBase = null;

  Element _domElement;
  WXSComplexContent _parent;


  WXSExtension(final Element el, final WXSComplexContent parent, final WXSSchema schema) {
    _parseAnnotation(el);
    _attrDecls = new List<WXSThing>();
    for (Node n = el.firstChild; n != null; n=n.nextSibling) {
      if (n is Element) {
        if (n.localName == "group")
          _model = new WXSGroup(n, this, schema);
        else if (n.localName == "all")
          _model = new WXSAll(n, this, schema);
        else if (n.localName == "choice")
          _model = new WXSChoice(n, this, schema);
        else if (n.localName == "sequence")
          _model = new WXSSequence(n, this, schema);
        else if (n.localName == "attribute")
          _attrDecls.add(new WXSAttribute(n, this, schema));
        else if (n.localName == "attributeGroup")
          _attrDecls.add(new WXSAttributeGroup(n, this, schema));
      }
    }
    if (el.hasAttribute("base"))
      _base = el.getAttribute("base");

    _domElement = el;
    this._parent = parent;
  }

  // from WithSubElements
  void resolveReferences(final WXSSchema schema, final WXSThing redefine) {
    if (_model != null)
      _model.resolveReferences(schema, redefine);
    for (WXSThing attrDecl in _attrDecls) {
      if (attrDecl is WXSAttribute)
        attrDecl.resolveReferences(schema);
      else if (attrDecl is WXSAttributeGroup)
        attrDecl.resolveReferences(schema, redefine);
    }
    if (_base != null) {
      final String tns = _domElement.lookupNamespaceURI(DaxeWXS._namePrefix(_base));
      _wxsBase = schema.resolveTypeReference(DaxeWXS._localValue(_base), tns, redefine);
      if (_wxsBase is WXSComplexType)
        (_wxsBase as WXSComplexType).addExtension(this);
    }
  }

  // from WithSubElements
  List<WXSElement> allElements() {
    final List<WXSElement> list = new List<WXSElement>();
    if (_model != null)
      list.addAll(_model.allElements());
    return(list);
  }

  // from WithSubElements
  List<WXSElement> subElements() {
    final List<WXSElement> list = new List<WXSElement>();
    if (_wxsBase is WXSComplexType)
      list.addAll((_wxsBase as WXSComplexType).subElements());
    if (_model != null)
      list.addAll(_model.subElements());
    return(list);
  }

  // from Parent
  List<WXSElement> parentElements() {
    if (_parent != null)
      return(_parent.parentElements());
    else
      return(new List<WXSElement>());
  }

  // from WithSubElements
  String regularExpression() {
    String erBase;
    if (_wxsBase is WXSComplexType)
      erBase = (_wxsBase as WXSComplexType).regularExpression();
    else
      erBase = null;
    String erModele;
    if (_model != null)
      erModele = _model.regularExpression();
    else
      erModele = null;
    if (erBase == null && erModele == null)
      return("");
    else if (erBase != null && erModele == null)
      return(erBase);
    else if (erBase == null && erModele != null)
      return(erModele);
    else
      return("($erBase, $erModele)");
  }

  // from WithSubElements
  bool requiredChild(final WXSElement child) {
    bool bb1 = null;
    if (_wxsBase is WXSComplexType)
      bb1 = (_wxsBase as WXSComplexType).requiredChild(child);
    if (bb1 != null && bb1)
      return(bb1);
    bool bb2 = null;
    if (_model != null)
      bb2 = _model.requiredChild(child);
    if (bb2 != null && bb2)
      return(bb2);
    return(bb1 != null ? bb1 : bb2);
  }

  // from WithSubElements
  bool multipleChildren(final WXSElement child) {
    bool bb1 = null;
    if (_wxsBase is WXSComplexType)
      bb1 = (_wxsBase as WXSComplexType).multipleChildren(child);
    if (bb1 != null && bb1)
      return(bb1);
    bool bb2 = null;
    if (_model != null)
      bb2 = _model.multipleChildren(child);
    return(bb1 != null ? bb1 : bb2);
  }

  List<String> possibleValues() {
    if (_wxsBase != null)
      return(_wxsBase.possibleValues());
    else if (_base != null)
      return(DaxeWXS._booleanValues(_base, _domElement));
    return(null);
  }

  List<String> suggestedValues() {
    if (_wxsBase != null)
      return(_wxsBase.suggestedValues());
    else if (_base != null)
      return(DaxeWXS._booleanValues(_base, _domElement));
    return(null);
  }

  List<WXSAttribute> attributes() {
    final List<WXSAttribute> list = new List<WXSAttribute>();
    for (WXSThing attrDecl in _attrDecls) {
      if (attrDecl is WXSAttribute)
        list.add(attrDecl);
      else if (attrDecl is WXSAttributeGroup)
        list.addAll(attrDecl.attributes());
    }
    if (_wxsBase is WXSComplexType) {
      final List<WXSAttribute> baseList = (_wxsBase as WXSComplexType).attributes();
      final List<WXSAttribute> toAdd = new List<WXSAttribute>();
      for (WXSAttribute attributExt in list) {
        final String extName = attributExt.getName();
        bool found = false;
        for (WXSAttribute attributBase in baseList)
          if (extName == attributBase.getName()) {
            found = true;
            break;
          }
        if (!found)
          toAdd.add(attributExt);
      }
      baseList.addAll(toAdd);
      return(baseList);
    }
    return(list);
  }

  // from WithSubElements
  int validate(final List<WXSElement> subElements, final int start, final bool insertion) {
    int pos = start;
    if (_wxsBase is WXSComplexType) {
      pos = (_wxsBase as WXSComplexType).validate(subElements, start, insertion);
      if (pos == start && !insertion && !(_wxsBase as WXSComplexType).isOptionnal())
        return(start);
    }
    if (_model != null) {
      int pos2 = _model.validate(subElements, pos, insertion);
      if (pos2 == pos && !insertion && !_model.isOptionnal())
        return(start);
      pos = pos2;
    }
    return(pos);
  }

  // from WithSubElements
  bool isOptionnal() {
    if (_wxsBase is WXSComplexType && !(_wxsBase as WXSComplexType).isOptionnal())
      return(false);
    if (_model != null)
      return(_model.isOptionnal());
    return(true);
  }

  bool validValue(final String value) {
    if (_wxsBase != null)
      return(_wxsBase.validValue(value));
    else if (_base != null)
      return(WXSSimpleType.validateTypeValue(DaxeWXS._localValue(_base), value));
    return(false);
  }
}
