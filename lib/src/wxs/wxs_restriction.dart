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


class WXSRestriction extends WXSAnnotated implements WithSubElements, Parent {
  
  // simpleType?, (minExclusive|minInclusive|maxExclusive|maxInclusive|totalDigits|fractionDigits|length|minLength|maxLength|enumeration|pattern)*
  // ou: (group|all|choice|sequence)?, (attribute|attributeGroup)*
  WXSSimpleType _simpleType = null;
  List<WXSFacet> _facets;
  WithSubElements _modele = null; // WXSGroup | WXSAll | WXSChoice | WXSSequence
  List<WXSThing> _attrDecls; // attrDecls: (attribute|attributeGroup)*
  String _base = null;
  
  WXSType _wxsBase = null;
  
  Element _domElement;
  WXSComplexContent _parent;
  
  
  WXSRestriction(final Element el, final WXSComplexContent parent, final WXSSchema schema) {
    _parseAnnotation(el);
    _facets = new List<WXSFacet>();
    _attrDecls = new List<WXSThing>();
    for (Node n = el.firstChild; n != null; n=n.nextSibling) {
      if (n is Element) {
        String localName = n.localName;
        if (localName == "simpleType")
          _simpleType = new WXSSimpleType(n as Element, this, schema);
        else if (localName == "minExclusive")
          _facets.add(new WXSFacet(n as Element));
        else if (localName == "minInclusive")
          _facets.add(new WXSFacet(n as Element));
        else if (localName == "maxExclusive")
          _facets.add(new WXSFacet(n as Element));
        else if (localName == "maxInclusive")
          _facets.add(new WXSFacet(n as Element));
        else if (localName == "totalDigits")
          _facets.add(new WXSFacet(n as Element));
        else if (localName == "fractionDigits")
          _facets.add(new WXSFacet(n as Element));
        else if (localName == "length")
          _facets.add(new WXSFacet(n as Element));
        else if (localName == "minLength")
          _facets.add(new WXSFacet(n as Element));
        else if (localName == "maxLength")
          _facets.add(new WXSFacet(n as Element));
        else if (localName == "enumeration")
          _facets.add(new WXSFacet(n as Element));
        else if (localName == "pattern")
          _facets.add(new WXSFacet(n as Element));
        else if (localName == "group")
          _modele = new WXSGroup(n as Element, this, schema);
        else if (localName == "all")
          _modele = new WXSAll(n as Element, this, schema);
        else if (localName == "choice")
          _modele = new WXSChoice(n as Element, this, schema);
        else if (localName == "sequence")
          _modele = new WXSSequence(n as Element, this, schema);
        else if (localName == "attribute")
          _attrDecls.add(new WXSAttribute(n as Element, this, schema));
        else if (localName == "attributeGroup")
          _attrDecls.add(new WXSAttributeGroup(n as Element, this, schema));
      }
    }
    if (el.hasAttribute("base"))
      _base = el.getAttribute("base");
    
    _domElement = el;
    this._parent = parent;
  }
  
  // from WithSubElements
  void resolveReferences(final WXSSchema schema, final WXSThing redefine) {
    if (_simpleType != null)
      _simpleType.resolveReferences(schema, redefine);
    if (_modele != null)
      _modele.resolveReferences(schema, redefine);
    for (WXSThing attrDecl in _attrDecls) {
      if (attrDecl is WXSAttribute)
        attrDecl.resolveReferences(schema);
      else if (attrDecl is WXSAttributeGroup)
        attrDecl.resolveReferences(schema, redefine);
    }
    if (_base != null) {
      final String tns = _domElement.lookupNamespaceURI(DaxeWXS._namePrefix(_base));
      _wxsBase = schema.resolveTypeReference(DaxeWXS._localValue(_base), tns, redefine);
    }
  }
  
  // from WithSubElements
  List<WXSElement> allElements() {
    final List<WXSElement> liste = new List<WXSElement>();
    if (_modele != null)
      liste.addAll(_modele.allElements());
    return(liste);
  }
  
  // from WithSubElements
  List<WXSElement> subElements() {
    final List<WXSElement> liste = new List<WXSElement>();
    if (_modele != null)
      liste.addAll(_modele.subElements());
    return(liste);
  }
  
  // from Parent
  List<WXSElement> parentElements() {
    if (_parent is WXSComplexContent)
      return(_parent.parentElements());
    else
      return(new List<WXSElement>());
  }
  
  // from WithSubElements
  String regularExpression() {
    if (_modele != null)
      return(_modele.regularExpression());
    return(null);
  }
  
  // from WithSubElements
  bool requiredChild(final WXSElement child) {
    // renvoie null si l'enfant n'en est pas un
    if (_modele != null)
      return(_modele.requiredChild(child));
    return(null);
  }
  
  // from WithSubElements
  bool multipleChildren(final WXSElement child) {
    // renvoie null si l'enfant n'en est pas un
    if (_modele != null)
      return(_modele.multipleChildren(child));
    return(null);
  }
  
  List<String> possibleValues() {
    List<String> liste = null;
    for (WXSFacet facet in _facets) {
      if (facet.getFacet() == "enumeration") {
        if (liste == null)
          liste = new List<String>();
        liste.add(facet.getValue());
      }
    }
    return(liste);
  }
  
  List<WXSAttribute> attributes() {
    final List<WXSAttribute> liste = new List<WXSAttribute>();
    for (WXSThing attrDecl in _attrDecls) {
      if (attrDecl is WXSAttribute)
        liste.add(attrDecl);
      else if (attrDecl is WXSAttributeGroup)
        liste.addAll(attrDecl.attributes());
    }
    if (_wxsBase is WXSComplexType) {
      final List<WXSAttribute> listeBase = (_wxsBase as WXSComplexType).attributes();
      final List<WXSAttribute> aRetirer = new List<WXSAttribute>();
      for (WXSAttribute attributRest in liste) {
        final String nomExt = attributRest.getName();
        final bool prohibited = attributRest.getUse() == "prohibited";
        for (WXSAttribute attributBase in listeBase)
          if (nomExt == attributBase.getName()) {
            if (prohibited)
              aRetirer.add(attributBase);
            else
              listeBase[listeBase.indexOf(attributBase)] = attributRest;
            break;
          }
      }
      for (WXSAttribute attribut in aRetirer)
        listeBase.remove(attribut);
          return(listeBase);
    }
    return(liste);
  }
  
  // from WithSubElements
  int validate(final List<WXSElement> subElements, final int start, final bool insertion) {
    if (_modele == null)
      return(start);
    return(_modele.validate(subElements, start, insertion));
  }
  
  // from WithSubElements
  bool isOptionnal() {
    if (_modele != null)
      return(_modele.isOptionnal());
    return(true);
  }
  
  bool validValue(final String value) {
    if (_wxsBase != null) {
      if (!_wxsBase.validValue(value))
        return(false);
    }
    bool enumerationOrPattern = false;
    for (final WXSFacet facet in _facets) {
      if (facet.getFacet() == "enumeration") {
        if (facet.validValue(value))
          return(true);
        enumerationOrPattern = true;
      } else if (facet.getFacet() == "pattern") {
        if (facet.validValue(value))
          return(true);
        enumerationOrPattern = true;
      } else if (!facet.validValue(value))
        return(false);
    }
    if (enumerationOrPattern)
      return(false);
    return(true);
  }
}
