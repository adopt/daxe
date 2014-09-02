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



class WXSElement extends WXSAnnotated implements WithSubElements, Parent {
  
  // (simpleType|complexType)?, (unique|key|keyref)*
  WXSSimpleType _simpleType = null;
  WXSComplexType _complexType = null;
  List<WXSThing> _identityConstraints; // (unique|key|keyref)*
  String _name = null;
  String _ref = null;
  String _type = null;
  String _substitutionGroup = null;
  int _minOccurs = 1;
  int _maxOccurs = 1;
  String _defaultAtt = null;
  String _fixed = null;
  bool _abstractAtt = false;
  String _form = null; // (qualified|unqualified)
  
  WXSElement _wxsRef = null;
  WXSElement _wxsSubstitutionGroup = null;
  Element _domElement;
  Parent _parent; // WXSAll | WXSChoice | WXSSequence
  WXSSchema _schema;
  List<WXSThing> _references; // WXSElement | WXSAny
  List<WXSElement> _substitutions;
  List<WXSElement> _correspondant; // cache des éléments correspondant
  List<WXSElement> _sousElements; // cache des sous-éléments
  
  
  WXSElement(final Element el, final Parent parent, final WXSSchema schema) {
    _parseAnnotation(el);
    _identityConstraints = new List<WXSThing>();
    for (Node n = el.firstChild; n != null; n=n.nextSibling) {
      if (n is Element) {
        if (n.localName == "simpleType")
          _simpleType = new WXSSimpleType(n as Element, this, schema);
        else if (n.localName == "complexType")
          _complexType = new WXSComplexType(n as Element, this, schema);
        else if (n.localName == "unique")
          _identityConstraints.add(new WXSUnique(n as Element));
        else if (n.localName == "key")
          _identityConstraints.add(new WXSKey(n as Element));
        else if (n.localName == "keyref")
          _identityConstraints.add(new WXSKeyref(n as Element));
      }
    }
    if (el.hasAttribute("name"))
      _name = el.getAttribute("name");
    if (el.hasAttribute("ref"))
      _ref = el.getAttribute("ref");
    if (el.hasAttribute("type"))
      _type = el.getAttribute("type");
    if (el.hasAttribute("substitutionGroup"))
      _substitutionGroup = el.getAttribute("substitutionGroup");
    try {
      if (el.hasAttribute("minOccurs"))
        _minOccurs = int.parse(el.getAttribute("minOccurs"));
      if (el.hasAttribute("maxOccurs")) {
        if (el.getAttribute("maxOccurs") == "unbounded")
          _maxOccurs = 9007199254740992;
        else
          _maxOccurs = int.parse(el.getAttribute("maxOccurs"));
      }
    } on FormatException {
    }
    if (el.hasAttribute("default"))
      _defaultAtt = el.getAttribute("default");
    if (el.hasAttribute("fixed"))
      _fixed = el.getAttribute("fixed");
    if (el.hasAttribute("abstract"))
      _abstractAtt = el.getAttribute("abstract") == "true" || el.getAttribute("abstract") == "1";
    if (el.hasAttribute("form"))
      _form = el.getAttribute("form");
    
    _domElement = el;
    this._parent = parent;
    this._schema = schema;
    _references = null;
    _substitutions = null;
    _sousElements = null;
    _correspondant = null;
  }
  
  String getName() {
    if (_name == null && _wxsRef != null)
      return(_wxsRef.getName());
    return(_name);
  }
  
  String getRef() {
    return(_ref);
  }
  
  int getMinOccurs() {
    return(_minOccurs);
  }
  
  int getMaxOccurs() {
    return(_maxOccurs);
  }
  
  bool getAbstract() {
    return(_abstractAtt);
  }
  
  
  Element getDOMElement() {
    return(_domElement);
  }
  
  String getNamespace() {
    bool qualified;
    if (_schema.getTopElements().contains(this))
      qualified = true;
    else if (_form != null)
      qualified = _form == "qualified";
    else
      qualified = _schema.getElementFormDefault() == "qualified";
    if (qualified)
      return(_schema.getTargetNamespace());
    else
      return(null);
  }
  
  Parent getParent() {
    return(_parent);
  }
  
  // from WithSubElements
  void resolveReferences(final WXSSchema schema, final WXSThing redefine) {
    if (_simpleType != null)
      _simpleType.resolveReferences(schema, null);
    if (_complexType != null)
      _complexType.resolveReferences(schema, redefine);
    if (_ref != null) {
      final String tns = _domElement.lookupNamespaceURI(DaxeWXS._namePrefix(_ref));
      _wxsRef = schema.resolveElementReference(DaxeWXS._localValue(_ref), tns);
      if (_wxsRef != null)
        _wxsRef.addReference(this);
      else
        print("Element reference not found : $_ref (namespace: $tns)");
    }
    if (_complexType == null && _simpleType == null && _type != null) {
      final String tns = _domElement.lookupNamespaceURI(DaxeWXS._namePrefix(_type));
      final WXSType wxsType = schema.resolveTypeReference(DaxeWXS._localValue(_type), tns, redefine);
      if (wxsType is WXSComplexType) {
        _complexType = wxsType;
        _complexType.addReference(this);
      } else if (wxsType is WXSSimpleType)
        _simpleType = wxsType;
    }
    if (_substitutionGroup != null) {
      final String tns = _domElement.lookupNamespaceURI(DaxeWXS._namePrefix(_substitutionGroup));
      _wxsSubstitutionGroup = schema.resolveElementReference(DaxeWXS._localValue(_substitutionGroup), tns);
      _wxsSubstitutionGroup.addSubstitution(this);
    }
  }
  
  void addReference(final WXSThing thing) {
    if (_references == null)
      _references = new List<WXSThing>();
    _references.add(thing);
  }
  
  void addSubstitution(final WXSElement el) {
    if (_substitutions == null)
      _substitutions = new List<WXSElement>();
    _substitutions.add(el);
  }
  
  List<WXSElement> getSubstitutions() {
    return(_substitutions);
  }
  
  // from WithSubElements
  List<WXSElement> allElements() {
    final List<WXSElement> liste = new List<WXSElement>();
    liste.add(this);
    if (_complexType != null)
      liste.addAll(_complexType.allElements());
    return(liste);
  }
  
  /**
   * Matching non-abstract named elements
   * (this element if it is named, named element if this is a reference, and substitutions).
   */
  List<WXSElement> matchingElements() {
    if (_correspondant != null)
      return(_correspondant);
    _correspondant = new List<WXSElement>();
    if (!_abstractAtt && _name != null)
      _correspondant.add(this);
    if (_wxsRef != null)
      _correspondant.addAll(_wxsRef.matchingElements());
    if (_substitutions != null)
      for (WXSElement substitution in _substitutions)
        _correspondant.addAll(substitution.matchingElements());
          return(_correspondant);
  }
  
  // from WithSubElements
  List<WXSElement> subElements() {
    if (_sousElements != null)
      return(_sousElements);
    final LinkedHashSet<WXSElement> set = new LinkedHashSet<WXSElement>();
    if (_wxsRef != null)
      set.addAll(_wxsRef.subElements());
    else if (_complexType != null)
      set.addAll(_complexType.subElements());
    else if (_simpleType == null && _type == null && _wxsSubstitutionGroup != null)
      set.addAll(_wxsSubstitutionGroup.subElements());
    _sousElements = new List.from(set);
    return(_sousElements);
  }
  
  // from Parent
  List<WXSElement> parentElements() {
    final LinkedHashSet<WXSElement> set = new LinkedHashSet<WXSElement>();
    if (_parent != null)
      set.addAll(_parent.parentElements());
    if (_references != null) {
      for (WXSThing reference in _references) {
        if (reference is WXSElement)
          set.addAll(reference.parentElements());
        else if (reference is WXSAny)
          set.addAll(reference.parentElements());
      }
    }
    if (_wxsSubstitutionGroup != null)
      set.addAll(_wxsSubstitutionGroup.parentElements());
    return(new List.from(set));
  }
  
  /**
   * Regular expression for the user interface (with the element titles: cannot be used for validation)
   */
  String elementRegularExpression() {
    // on suppose que cet élément est nommé
    if (_complexType == null && _simpleType == null && _type == null && _wxsSubstitutionGroup != null)
      return(_wxsSubstitutionGroup.elementRegularExpression());
    if (_complexType == null)
      return(null);
    return(_complexType.regularExpression());
  }
  
  /**
   * Regular expression for this element as a model sub-element.
   * Returns null if there is no non-abstract element matching this element.
   */
  // from WithSubElements
  String regularExpression() {
    final List<WXSElement> liste = matchingElements();
    if (liste.length == 0)
      return(null);
    final StringBuffer sb = new StringBuffer();
    if (liste.length > 1)
      sb.write('(');
      for (int i=0; i<liste.length; i++) {
        final WXSElement el = liste[i];
        sb.write(_schema.elementTitle(el));
        if (i != liste.length - 1)
          sb.write('|');
      }
      if (liste.length > 1)
        sb.write(')');
      if (_minOccurs == 0 && _maxOccurs == 1)
        sb.write('?');
      else if (_minOccurs == 0 && _maxOccurs > 1)
        sb.write('*');
      else if (_minOccurs > 0 && _maxOccurs > 1)
        sb.write('+');
      return(sb.toString());
  }
  
  // from WithSubElements
  bool requiredChild(final WXSElement child) {
    // on suppose que cet élément est nommé
    if (_complexType == null && _simpleType == null && _type == null && _wxsSubstitutionGroup != null)
      return(_wxsSubstitutionGroup.requiredChild(child));
    if (_complexType == null)
      return(null);
    return(_complexType.requiredChild(child));
  }
  
  // from WithSubElements
  bool multipleChildren(final WXSElement child) {
    // on suppose que cet élément est nommé
    if (_complexType == null && _simpleType == null && _type == null && _wxsSubstitutionGroup != null)
      return(_wxsSubstitutionGroup.multipleChildren(child));
    if (_complexType == null)
      return(null);
    return(_complexType.multipleChildren(child));
  }
  
  List<String> possibleValues() {
    if (_fixed != null) {
      final List<String> fixedval = new List<String>();
      fixedval.add(_fixed);
      return(fixedval);
    }
    if (_simpleType != null)
      return(_simpleType.possibleValues());
    else if (_complexType != null)
      return(_complexType.possibleValues());
    else if (_type != null)
      return(DaxeWXS._booleanValues(_type, _domElement));
    else if (_simpleType == null && _wxsSubstitutionGroup != null)
      return(_wxsSubstitutionGroup.possibleValues());
    return(null);
  }
  
  List<String> suggestedValues() {
    if (_fixed != null) {
      final List<String> fixedval = new List<String>();
      fixedval.add(_fixed);
      return(fixedval);
    }
    if (_simpleType != null)
      return(_simpleType.suggestedValues());
    else if (_complexType != null)
      return(_complexType.suggestedValues());
    else if (_type != null)
      return(DaxeWXS._booleanValues(_type, _domElement));
    else if (_simpleType == null && _wxsSubstitutionGroup != null)
      return(_wxsSubstitutionGroup.suggestedValues());
    return(null);
  }
  
  List<WXSAttribute> attributes() {
    if (_wxsRef != null)
      return(_wxsRef.attributes());
    if (_complexType != null)
      return(_complexType.attributes());
    else if (_simpleType == null && _type == null && _wxsSubstitutionGroup != null)
      return(_wxsSubstitutionGroup.attributes());
    return(new List<WXSAttribute>());
  }
  
  bool containsText() {
    if (_type != null) {
      final String tns = _domElement.lookupNamespaceURI(DaxeWXS._namePrefix(_type));
      final String schemaNamespace = _domElement.namespaceURI;
      // si le type fait partie des schémas XML (comme "string" ou "anyURI")
      // on considère que c'est du texte (sauf si le schéma est le schéma des schémas)
      if (schemaNamespace != _schema.getTargetNamespace() && schemaNamespace == tns)
        return(true);
    }
    if (_complexType != null)
      return(_complexType.containsText());
    if (_simpleType != null)
      return(true);
    if (_complexType == null && _type == null && _wxsSubstitutionGroup != null)
      return(_wxsSubstitutionGroup.containsText());
    return(false);
  }
  
  /**
   * Validation of a named element.
   * Returns true if the given list of sub-elements is a valid set of sub-elements.
   * If insert is true, all the sub-elements are optionnal.
   */
  bool validateSubElements(final List<WXSElement> subElements, final bool insert) {
    if (_complexType == null) {
      if (_simpleType == null && _type == null && _wxsSubstitutionGroup != null)
        return(_wxsSubstitutionGroup.validateSubElements(subElements, insert));
      return(subElements.length == 0);
    }
    if (subElements.length == 0) {
      if (insert)
        return(true);
      if (_complexType.isOptionnal())
        return(true);
    }
    final int pos = _complexType.validate(subElements, 0, insert);
    return(pos > 0 && pos == subElements.length);
  }
  
  /**
   * Validation of a sub-element.
   * Returns the position in the list as far as validation is possible
   * (start if no validation is possible, subElements.length if everything is validated).
   */
  // from WithSubElements
  int validate(final List<WXSElement> subElements, final int start, final bool insertion) {
    int nb = 0;
    final List<WXSElement> correspondant = matchingElements();
    for (int i=start; i<subElements.length; i++) {
      if (nb >= _maxOccurs)
        return(i);
      bool trouve = false;
      for (WXSElement el in correspondant)
        if (el == subElements[i])
          trouve = true;
          if (!trouve) {
            if (!insertion && nb < _minOccurs)
              return(start);
            return(i);
          }
          nb++;
    }
    if (!insertion && nb < _minOccurs)
      return(start);
    return(start + nb);
  }
  
  // from WithSubElements
  bool isOptionnal() {
    return(_minOccurs == 0);
  }
  
  bool validValue(final String value) {
    if (_fixed != null)
      return(_fixed == value);
    if (_simpleType != null)
      return(_simpleType.validValue(value));
    if (_complexType != null)
      return(_complexType.validValue(value));
    if (_type != null) {
      final String tns = _domElement.lookupNamespaceURI(DaxeWXS._namePrefix(_type));
      if (tns != null && tns == _domElement.namespaceURI)
        return(WXSSimpleType.validateTypeValue(DaxeWXS._localValue(_type), value));
      return(false);
    } else
      return(true);
  }
}
