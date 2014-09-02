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


class WXSComplexType extends WXSAnnotated implements WXSType, WithSubElements, Parent {
  
  // (simpleContent | complexContent | ((group|all|choice|sequence)?, (attribute|attributeGroup)*))
  WXSSimpleContent _simpleContent = null;
  WithSubElements _modele = null; // WXSComplexContent | WXSGroup | WXSAll | WXSChoice | WXSSequence
  List<WXSThing> _attrDecls; // attrDecls: (attribute|attributeGroup)*
  String _name = null;
  bool _mixed = false;
  bool _abstractAtt = false;
  
  Parent _parent; // WXSElement | WXSRedefine
  WXSSchema _schema;
  List<WXSElement> _references;
  List<WXSExtension> _extensions;
  
  
  WXSComplexType(final Element el, final Parent parent, final WXSSchema schema) {
    _parseAnnotation(el);
    _attrDecls = new List<WXSThing>();
    for (Node n = el.firstChild; n != null; n=n.nextSibling) {
      if (n is Element) {
        if (n.localName == "simpleContent")
          _simpleContent = new WXSSimpleContent(n as Element, schema);
        else if (n.localName == "complexContent")
          _modele = new WXSComplexContent(n as Element, this, schema);
        else if (n.localName == "group")
          _modele = new WXSGroup(n as Element, this, schema);
        else if (n.localName == "all")
          _modele = new WXSAll(n as Element, this, schema);
        else if (n.localName == "choice")
          _modele = new WXSChoice(n as Element, this, schema);
        else if (n.localName == "sequence")
          _modele = new WXSSequence(n as Element, this, schema);
        else if (n.localName == "attribute")
          _attrDecls.add(new WXSAttribute(n as Element, this, schema));
        else if (n.localName == "attributeGroup")
          _attrDecls.add(new WXSAttributeGroup(n as Element, this, schema));
      }
    }
    if (el.hasAttribute("name"))
      _name = el.getAttribute("name");
    if (el.hasAttribute("mixed"))
      _mixed = el.getAttribute("mixed") == "true" || el.getAttribute("mixed") == "1";
    if (el.hasAttribute("abstract"))
      _abstractAtt = el.getAttribute("abstract") == "true" || el.getAttribute("abstract") == "1";
    
    this._parent = parent;
    this._schema = schema;
    _references = null;
    _extensions = null;
  }
  
  WXSSimpleContent getSimpleContent() {
    return(_simpleContent);
  }
  
  // from WXSType
  String getName() {
    return(_name);
  }
  
  bool getMixed() {
    return(_mixed);
  }
  
  // from WXSType
  String getNamespace() {
    return(_schema.getTargetNamespace());
  }
  
  // from WXSType
  Parent getParent() {
    return(_parent);
  }
  
  // from WithSubElements and WXSType
  void resolveReferences(final WXSSchema schema, final WXSThing redefine) {
    if (_simpleContent != null)
      _simpleContent.resolveReferences(schema, redefine);
    if (_modele != null)
      _modele.resolveReferences(schema, redefine);
    for (WXSThing attrDecl in _attrDecls) {
      if (attrDecl is WXSAttribute)
        attrDecl.resolveReferences(schema);
      else if (attrDecl is WXSAttributeGroup)
        attrDecl.resolveReferences(schema, redefine);
    }
  }
  
  void addReference(final WXSElement element) {
    if (_references == null)
      _references = new List<WXSElement>();
    _references.add(element);
  }
  
  void addExtension(final WXSExtension ext) {
    if (_extensions == null)
      _extensions = new List<WXSExtension>();
    _extensions.add(ext);
  }
  
  // from WithSubElements
  List<WXSElement> allElements() {
    if (_modele != null)
      return(_modele.allElements());
    return(new List<WXSElement>());
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
    final List<WXSElement> liste = new List<WXSElement>();
    if (_parent is WXSElement) {
      if (!(_parent as WXSElement).getAbstract())
        liste.add(_parent as WXSElement);
      final List<WXSElement> substitutions = (_parent as WXSElement).getSubstitutions();
      if (substitutions != null)
        liste.addAll(substitutions);
    }
    if (_references != null) {
      for (WXSElement el in _references) {
        if (!el.getAbstract())
          liste.add(el);
        final List<WXSElement> substitutions = el.getSubstitutions();
        if (substitutions != null)
          liste.addAll(substitutions);
      }
    }
    if (_extensions != null) {
      for (WXSExtension ext in _extensions)
        liste.addAll(ext.parentElements());
    }
    return(liste);
  }
  
  // from WithSubElements
  String regularExpression() {
    if (_modele != null)
      return(_modele.regularExpression());
    return(null);
  }
  
  // from WithSubElements
  bool requiredChild(final WXSElement child) {
    if (_modele != null)
      return(_modele.requiredChild(child));
    return(null);
  }
  
  // from WithSubElements
  bool multipleChildren(final WXSElement child) {
    if (_modele != null)
      return(_modele.multipleChildren(child));
    return(null);
  }
  
  // from WXSType
  List<String> possibleValues() {
    if (_simpleContent != null)
      return(_simpleContent.possibleValues());
    return(null);
  }
  
  // from WXSType
  List<String> suggestedValues() {
    if (_simpleContent != null)
      return(_simpleContent.suggestedValues());
    return(null);
  }
  
  List<WXSAttribute> attributes() {
    if (_simpleContent != null)
      return(_simpleContent.attributes());
    else if (_modele is WXSComplexContent)
      return((_modele as WXSComplexContent).attributes());
    final List<WXSAttribute> liste = new List<WXSAttribute>();
    for (WXSThing attrDecl in _attrDecls) {
      if (attrDecl is WXSAttribute)
        liste.add(attrDecl);
      else if (attrDecl is WXSAttributeGroup)
        liste.addAll(attrDecl.attributes());
    }
    return(liste);
  }
  
  // from WithSubElements
  int validate(final List<WXSElement> subElements, final int start, final bool insertion) {
    if (_simpleContent != null)
      return(start);
    else if (_modele != null)
      return(_modele.validate(subElements, start, insertion));
    return(start);
  }
  
  // from WithSubElements
  bool isOptionnal() {
    if (_simpleContent != null)
      return(true);
    else if (_modele != null)
      return(_modele.isOptionnal());
    return(true);
  }
  
  // from WXSType
  bool validValue(final String value) {
    if (_simpleContent != null)
      return(_simpleContent.validValue(value));
    // FIXME: we should check whether spaces matter or not here
    return(value.trim() == '' || containsText());
  }
  
  bool containsText() {
    // on teste le type parent quand un type est dérivé
    // par un autre qui ne redonne pas la liste des sous-éléments...
    // cf http://lists.w3.org/Archives/Public/xmlschema-dev/2005Sep/0025.html
    if (_modele is WXSComplexContent) {
      WXSComplexContent cc = _modele as WXSComplexContent;
      WXSType wxsBase = null;
      if (cc._modele is WXSExtension) {
        WXSExtension ext = cc._modele as WXSExtension;
        if (ext._modele == null)
          wxsBase = ext._wxsBase;
      } else {
        WXSRestriction res = cc._modele as WXSRestriction;
        if (res._modele == null)
          wxsBase = res._wxsBase;
      }
      if (wxsBase is WXSComplexType)
        return((wxsBase as WXSComplexType).containsText());
    }
    if (getMixed())
      return(true);
    if (getSimpleContent() != null)
      return(true);
    return(false);
  }

}
