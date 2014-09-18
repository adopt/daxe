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



/**
 * Class implementing InterfaceSchema for the W3C schemas.
 */
class DaxeWXS implements InterfaceSchema {
  
  WXSSchema _schema;
  /** map: element reference -> WXS element */
  final HashMap<Element, WXSElement> _hElementRefToWXS = new HashMap<Element, WXSElement>();
  /** map: attribute reference -> WXS attribute */
  final HashMap<Element, WXSAttribute> _hAttributeRefToWXS = new HashMap<Element, WXSAttribute>();
  /** map: name -> WXS object */
  final HashMap<String, List<WXSElement>> _hNameToWXS = new HashMap<String, List<WXSElement>>();
  /** map: namespace -> prefix */
  HashMap<String, String> _namespaceToPrefix;
  
  /** list of all WXS elements (not necessarily directly under xs:schema)
  (they can have a name attribute or a ref attribute) */
  final LinkedHashSet<WXSElement> _lAllElements = new LinkedHashSet<WXSElement>();
  Set<WXSSchema> _includedSchemas;
  HashMap<String, String> _hashTitles;
  
  
  DaxeWXS(HashMap<String, String> hashElementTitles) {
    this._hashTitles = hashElementTitles;
    _includedSchemas = new HashSet<WXSSchema>();
    _namespaceToPrefix = new HashMap<String, String>();
  }
  
  Future load(final String schemaURL) {
    Completer completer = new Completer();
    _readDocument(schemaURL).then((Element documentElement) {
      _schema = new WXSSchema(documentElement, schemaURL, this, null);
      _addNamespaces(_schema, null, null);
      _includedSchemas.add(_schema);
      _schema._inclusions().then((_) {
        for (final WXSSchema sch in _includedSchemas)
          _lAllElements.addAll(sch.allElements());
        for (final WXSSchema sch in _includedSchemas)
          sch._resolveReferences(); // WXSAny.resolveReferences() needs this DaxeWXS object, so it is called later
        for (WXSElement element in _lAllElements) {
          _hElementRefToWXS[element.getDOMElement()] = element;
          if (element.getName() != null && element.getRef() == null) {
            List<WXSElement> listeWXS = _hNameToWXS[element.getName()];
            if (listeWXS == null) {
              listeWXS = new List<WXSElement>();
              _hNameToWXS[element.getName()] = listeWXS;
            }
            listeWXS.add(element);
          }
        }
        for (WXSElement element in _lAllElements) {
          final List<WXSAttribute> attributs = element.attributes();
          if (attributs != null) {
            for (WXSAttribute attribut in attributs)
              _hAttributeRefToWXS[attribut.getDOMElement()] = attribut;
          }
        }
        completer.complete();
      });
    }, onError: (WXSException ex) {
      completer.completeError(ex);
    });
    return(completer.future);
  }
  
  // from InterfaceSchema
  bool elementInSchema(final Element elementRef) {
    return(_hElementRefToWXS[elementRef] != null);
  }
  
  // from InterfaceSchema
  Element elementReferenceByName(final String name) {
    final List<WXSElement> listeWXS = _hNameToWXS[name];
    if (listeWXS == null)
      return(null);
    return(listeWXS[0].getDOMElement());
  }
  
  // from InterfaceSchema
  List<Element> elementReferencesByName(final String name) {
    final List<WXSElement> listeWXS = _hNameToWXS[name];
    if (listeWXS == null)
      return(null);
    List<Element> refs = new List<Element>();
    for (WXSElement el in listeWXS)
      refs.add(el.getDOMElement());
    return(refs);
  }
  
  // from InterfaceSchema
  Element elementReference(final Element el, final Element parentRef) {
    if (parentRef == null) {
      // for root elements: local definitions should be avoided
      String name;
      if (el.prefix == null)
        name = el.nodeName;
      else
        name = el.localName;
      final String espace = el.namespaceURI;
      for (final WXSSchema sch in _includedSchemas) {
        for (final WXSElement topel in sch.getTopElements()) {
          if (topel.getRef() == null && !topel.getAbstract() &&
              name == topel.getName() && espace == topel.getNamespace())
            return(topel.getDOMElement());
        }
      }
      print("JaxeWXS: elementReference: no matching root element in the schema for $name");
      return(null);
    }
    final WXSElement wxsParent = _hElementRefToWXS[parentRef];
    if (wxsParent == null) {
      print("DaxeWXS: elementReference: unknown element reference: $parentRef");
      return(null);
    }
    final List<WXSElement> liste = wxsParent.subElements();
    final String name = el.localName;
    final String namespace = el.namespaceURI;
    for (final WXSElement element in liste) {
      if (element.getName() == name && element.getNamespace() == namespace)
        return(element.getDOMElement());
    }
    return(null);
  }
  
  // from InterfaceSchema
  String elementName(final Element elementRef) {
    final WXSElement element = _hElementRefToWXS[elementRef];
    if (element == null) {
      print("DaxeWXS: elementName: unknown element reference: $elementRef");
      return(null);
    }
    return(element.getName());
  }
  
  // from InterfaceSchema
  String elementNamespace(final Element elementRef) {
    final WXSElement element = _hElementRefToWXS[elementRef];
    if (element == null)
      return(null);
    return(element.getNamespace());
  }
  
  // from InterfaceSchema
  String elementPrefix(final Element elementRef) {
    final String namespace = elementNamespace(elementRef);
    if (namespace == null)
      return(null);
    return(_namespaceToPrefix[namespace]);
  }
  
  // from InterfaceSchema
  String elementDocumentation(final Element elementRef) {
    final WXSElement element = _hElementRefToWXS[elementRef];
    if (element == null)
      return(null);
    String doc = element.getDocumentation();
    if (doc != null)
      return(doc);
    if (element._complexType != null)
      return(element._complexType.getDocumentation());
    return(null);
  }
  
  // from InterfaceSchema
  List<String> elementValues(final Element elementRef) {
    final WXSElement element = _hElementRefToWXS[elementRef];
    if (element == null)
      return(null);
    return(element.possibleValues());
  }
  
  // from InterfaceSchema
  List<String> suggestedElementValues(final Element elementRef) {
    final WXSElement element = _hElementRefToWXS[elementRef];
    if (element == null)
      return(null);
    return(element.suggestedValues());
  }
  
  // from InterfaceSchema
  bool elementValueIsValid(final Element elementRef, final String value) {
    final WXSElement element = _hElementRefToWXS[elementRef];
    if (element == null)
      return(false);
    return(element.validValue(value));
  }
  
  // from InterfaceSchema
  List<String> namespaceList() {
    final LinkedHashSet<String> set = new LinkedHashSet<String>();
    if (_schema.getTargetNamespace() != null)
      set.add(_schema.getTargetNamespace());
    for (final String s in _namespaceToPrefix.keys)
      set.add(s);
    return(new List.from(set));
  }
  
  // from InterfaceSchema
  bool hasNamespace(final String namespace) {
    final String targetNamespace = _schema.getTargetNamespace();
    if (namespace == null) {
      if (targetNamespace == null || targetNamespace == "")
        return(true);
      if (_namespaceToPrefix.containsKey(""))
        return(true);
      // case of local elements without a namespace :
      final bool qualified = ("qualified" == _schema.getElementFormDefault());
      if (!qualified)
        return(true);
    } else {
      if (namespace == targetNamespace)
        return(true);
      if (_namespaceToPrefix.containsKey(namespace))
        return(true);
    }
    return(false);
  }
  
  // from InterfaceSchema
  String namespacePrefix(final String ns) {
    return(_namespaceToPrefix[ns]);
  }
  
  // from InterfaceSchema
  String getTargetNamespace() {
    return(_schema.getTargetNamespace());
  }
  
  // from InterfaceSchema
  List<Element> elementsOutsideNamespace(final String namespace) {
    final List<Element> liste = new List<Element>();
    for (final WXSElement el in _lAllElements) {
      if (el.getName() != null && el.getRef() == null && !el.getAbstract()) {
        final String tns = el.getNamespace();
        if (tns != null && tns != namespace)
          liste.add(el.getDOMElement());
      }
    }
    return(liste);
  }
  
  // from InterfaceSchema
  List<Element> elementsWithinNamespaces(final Set<String> namespaces) {
    final List<Element> liste = new List<Element>();
    for (final WXSElement el in _lAllElements) {
      if (el.getName() != null && el.getRef() == null && !el.getAbstract()) {
        final String tns = el.getNamespace();
        if (tns != null && namespaces.contains(tns))
          liste.add(el.getDOMElement());
      }
    }
    return(liste);
  }
  
  // from InterfaceSchema
  List<Element> allElements() {
    final List<Element> liste = new List<Element>();
    for (final WXSElement el in _lAllElements) {
      if (el.getName() != null && el.getRef() == null && !el.getAbstract())
        liste.add(el.getDOMElement());
    }
    return(liste);
  }
  
  // from InterfaceSchema
  List<Element> rootElements() {
    final List<Element> liste = new List<Element>();
    for (final WXSSchema sch in _includedSchemas) {
      for (final WXSElement el in sch.getTopElements()) {
        if (el.getName() != null && el.getRef() == null && !el.getAbstract())
          liste.add(el.getDOMElement());
      }
    }
    return(liste);
  }
  
  // from InterfaceSchema
  bool requiredElement(final Element parentRef, final Element childRef) {
    final WXSElement parent = _hElementRefToWXS[parentRef];
    if (parent == null) {
      print("DaxeWXS: requiredElement: unknown element reference: $parentRef");
      return(false);
    }
    final WXSElement child = _hElementRefToWXS[childRef];
    if (child == null) {
      print("DaxeWXS: requiredElement: unknown element reference: $childRef");
      return(false);
    }
    bool bb = parent.requiredChild(child);
    return(bb != null && bb);
  }
  
  // from InterfaceSchema
  bool multipleChildren(final Element parentRef, final Element childRef) {
    final WXSElement parent = _hElementRefToWXS[parentRef];
    if (parent == null) {
      print("DaxeWXS: multipleChildren: unknown element reference: $parentRef");
      return(false);
    }
    final WXSElement child = _hElementRefToWXS[childRef];
    if (child == null) {
      print("DaxeWXS: multipleChildren: unknown element reference: $childRef");
      return(false);
    }
    bool bb = parent.multipleChildren(child);
    return(bb != null && bb);
  }
  
  // from InterfaceSchema
  List<Element> subElements(final Element parentRef) {
    // à faire: cache
    final WXSElement parent = _hElementRefToWXS[parentRef];
    if (parent == null) {
      print("DaxeWXS: subElements: unknown element reference: $parentRef");
      return(null);
    }
    final List<WXSElement> sousElements = parent.subElements();
    final List<Element> liste = new List<Element>();
    for (WXSElement element in sousElements)
      liste.add(element.getDOMElement());
    return(liste);
  }
  
  /**
   * Regular expression for a given parent element.
   * In DaxeWXS, modevisu=true and modevalid=true.
   * [modevisu]  True to get a regular expression to display to the user
   * [modevalid]  For strict validation instead of checking if an insert is possible
   */
  // from InterfaceSchema
  String regularExpression(final Element parentRef, final bool modevisu, final bool modevalid) {
    final WXSElement parent = _hElementRefToWXS[parentRef];
    if (parent == null) {
      print("DaxeWXS: regularExpression: unknown element reference: $parentRef");
      return(null);
    }
    return(parent.elementRegularExpression()); // on utilise toujours modevisu=true et modevalid=true
  }
    
  // from InterfaceSchema
  List<Element> parentElements(final Element elementRef) {
    final WXSElement element = _hElementRefToWXS[elementRef];
    if (element == null) {
      print("DaxeWXS: parentElements: unknown element reference: $elementRef");
      return(null);
    }
    final List<WXSElement> parents = element.parentElements();
    final List<Element> liste = new List<Element>();
    for (WXSElement el in parents)
      liste.add(el.getDOMElement());
    return(liste);
  }
  
  // from InterfaceSchema
  List<Element> elementAttributes(final Element elementRef) {
    final WXSElement element = _hElementRefToWXS[elementRef];
    if (element == null) {
      print("DaxeWXS: elementAttributes: unknown element reference: $elementRef");
      return(null);
    }
    final List<WXSAttribute> attributes = element.attributes();
    final List<Element> liste = new List<Element>();
    for (WXSAttribute attribute in attributes)
      liste.add(attribute.getDOMElement());
    return(liste);
  }
  
  // from InterfaceSchema
  String attributeName(final Element attributeRef) {
    final WXSAttribute attribute = _hAttributeRefToWXS[attributeRef];
    if (attribute == null) {
      print("DaxeWXS: attributeName: unknown attribute reference: $attributeRef");
      return(null);
    }
    return(attribute.getName());
  }
  
  // from InterfaceSchema
  String attributeNamespace(final Element attributeRef) {
    final WXSAttribute attribute = _hAttributeRefToWXS[attributeRef];
    if (attribute == null) {
      print("DaxeWXS: attributeNamespace: unknown attribute reference: $attributeRef");
      return(null);
    }
    return(attribute.getNamespace());
  }
  
  // from InterfaceSchema
  String attributeDocumentation(final Element attributeRef) {
    final WXSAttribute attribute = _hAttributeRefToWXS[attributeRef];
    if (attribute == null) {
      print("DaxeWXS: attributeDocumentation: unknown attribute reference: $attributeRef");
      return(null);
    }
    return(attribute.getDocumentation());
  }
  
  // from InterfaceSchema
  String attributeNamespaceByName(final String attributeName) {
    if (attributeName == null)
      return(null);
    final String prefix = _namePrefix(attributeName);
    if (prefix == null)
      return(null);
    if (prefix == "xml")
      return("http://www.w3.org/XML/1998/namespace");
    return(_schema.prefixNamespace(prefix));
  }
  
  /**
   * Returns true if an attribute is required, based on its definition.
   * Warning: this is not possible to determine this with only the attribute reference with Relax NG.
   * It is better to use attributeIsRequired.
   */
  bool isRequired(final Element attributeRef) {
    final WXSAttribute attribute = _hAttributeRefToWXS[attributeRef];
    if (attribute == null) {
      print("DaxeWXS: isRequired: unknown attribute reference: $attributeRef");
      return(false);
    }
    return(attribute.getUse() == "required");
  }
  
  // from InterfaceSchema
  bool attributeIsRequired(final Element parentRef, final Element attributeRef) {
    return(isRequired(attributeRef));
  }
  
  // from InterfaceSchema
  List<String> attributeValues(final Element attributeRef) {
    final WXSAttribute attribute = _hAttributeRefToWXS[attributeRef];
    if (attribute == null) {
      print("DaxeWXS: attributeValues: unknown attribute reference: $attributeRef");
      return(null);
    }
    return(attribute.possibleValues());
  }
  
  // from InterfaceSchema
  List<String> suggestedAttributeValues(final Element attributeRef) {
    final WXSAttribute attribute = _hAttributeRefToWXS[attributeRef];
    if (attribute == null) {
      print("DaxeWXS: suggestedAttributeValues: unknown attribute reference: $attributeRef");
      return(null);
    }
    return(attribute.suggestedValues());
  }
  
  // from InterfaceSchema
  String defaultAttributeValue(final Element attributeRef) {
    final WXSAttribute attribute = _hAttributeRefToWXS[attributeRef];
    if (attribute == null) {
      print("DaxeWXS: defaultAttributeValue: unknown attribute reference: $attributeRef");
      return(null);
    }
    return(attribute.defaultValue());
  }
  
  // from InterfaceSchema
  bool attributeIsValid(final Element attributeRef, final String value) {
    // à refaire avec les classes WXS
    final WXSAttribute attribute = _hAttributeRefToWXS[attributeRef];
    if (attribute == null) {
      print("DaxeWXS: attributeIsValid: unknown attribute reference: $attributeRef");
      return(false);
    }
    return(attribute.validValue(value));
  }
  
  // from InterfaceSchema
  Element attributeParent(final Element attributeRef) {
    final WXSAttribute attribute = _hAttributeRefToWXS[attributeRef];
    if (attribute == null) {
      print("DaxeWXS: attributeParent: unknown attribute reference: $attributeRef");
      return(null);
    }
    final List<WXSElement> parents = attribute.parentElements();
    if (parents.length > 0)
      return(parents[0].getDOMElement());
    return(null);
  }
  
  // from InterfaceSchema
  bool canContainText(final Element elementRef) {
    final WXSElement element = _hElementRefToWXS[elementRef];
    if (element == null) {
      print("DaxeWXS: canContainText: unknown element reference: $elementRef");
      return(false);
    }
    return(element.containsText());
  }
  
  
  /**
   * Tests if an element is valid.
   * If insert is true, just tests the validity of an insert (all sub-elements are optionnal).
   */
  bool validElement(final Element elementRef, final List<Element> subElementRefs, final bool insert) {
    final WXSElement element = _hElementRefToWXS[elementRef];
    if (element == null) {
      print("DaxeWXS: validElement: unknown element reference: $elementRef");
      return(false);
    }
    final List<WXSElement> subElements = new List<WXSElement>();
    for (Element ref in subElementRefs) {
      final WXSElement subElement = _hElementRefToWXS[ref];
      if (subElement != null)
        subElements.add(subElement); // else ref from another config ?
    }
    return(element.validateSubElements(subElements, insert));
  }
  
  
  Future<WXSSchema> _newIncludedSchema(final String parentSchemaURL, final String schemaLocation,
                                final String importNamespace, final WXSSchema parentSchema) { //  throws WXSException
    String urls;
    if (schemaLocation.startsWith("http"))
      urls = schemaLocation;
    else
      urls = "${_getParentURL(parentSchemaURL)}/$schemaLocation";
    if (urls == null)
      return(new Future.error(new WXSException("include/import : location not found : $schemaLocation")));
    for (WXSSchema includedSchema in _includedSchemas) {
      if (_normalizePath(includedSchema.getURL()) == _normalizePath(urls)) {
        _addNamespaces(includedSchema, parentSchema, importNamespace); // another chance to find a prefix
        return(new Future.value(includedSchema));
      }
    }
    Completer<WXSSchema> completer = new Completer<WXSSchema>();
    _readDocument(urls).then((Element documentElement) {
      final WXSSchema schemaInclu = new WXSSchema(documentElement, urls, this, parentSchema);
      _addNamespaces(schemaInclu, parentSchema, importNamespace);
      _includedSchemas.add(schemaInclu);
      schemaInclu._inclusions().then((_) {
        completer.complete(schemaInclu);
      }, onError: (WXSException ex) {
        completer.completeError(new WXSException("include/import: $ex"));
      });
    }, onError: (WXSException ex) {
      completer.completeError(new WXSException("include/import: $ex"));
    });
    return(completer.future);
  }
  
  // transforms 'a/..' into '' inside paths
  String _normalizePath(String path) {
    int ind1 = path.indexOf('/');
    if (ind1 == -1)
      return(path);
    String p1 = path.substring(0, ind1);
    int ind2 = path.substring(ind1 + 1).indexOf('/');
    if (ind2 == -1)
      return(path);
    ind2 += ind1 + 1;
    String p2 = path.substring(ind1 + 1, ind2);
    if (p1 != '..' && p2 == '..')
      return(_normalizePath(path.substring(ind2 + 1)));
    else
      return("${path.substring(0, ind1 + 1)}${_normalizePath(path.substring(ind1 + 1))}");
  }
  
  void _addNamespaces(final WXSSchema sch, final WXSSchema parentSchema, final String importNamespace) {
    if (importNamespace != null && _namespaceToPrefix[importNamespace] == null) {
      String prefix = sch.namespacePrefix(importNamespace);
      if (prefix != null)
        _namespaceToPrefix[importNamespace] = prefix;
      else if (parentSchema != null) {
        prefix = parentSchema.namespacePrefix(importNamespace);
        if (prefix != null)
          _namespaceToPrefix[importNamespace] = prefix;
      }
    }
    // always add targetNamespace ?
    final String targetNamespace = sch.getTargetNamespace();
    if (targetNamespace != null && targetNamespace != "") {
      final String prefix = sch.namespacePrefix(targetNamespace);
      if (prefix != null)
        _namespaceToPrefix[targetNamespace] = prefix;
    }
  }
  
  WXSElement _findFirstElement(final String name, final String namespace) {
    final List<WXSElement> listeWXS = _hNameToWXS[name];
    if (listeWXS == null)
      return(null);
    for (WXSElement element in listeWXS) {
      if (namespace == element.getNamespace())
        return(element);
    }
    return(null);
  }
  
  /**
   * Returns the root element of the document with the given URL.
   */
  static Future<Element> _readDocument(final String schemaURL) { // throws WXSException
    Completer<Element> completer = new Completer<Element>();
    DOMParser dp = new DOMParser();
    dp.parseFromURL(schemaURL).then((Document schemadoc) {
      completer.complete(schemadoc.documentElement);
    }, onError: (DOMException ex) {
      print("DaxeWXS: Error reading $schemaURL: $ex");
      completer.completeError(new WXSException("DaxeWXS: reading $schemaURL: $ex"));
    });
    return(completer.future);
  }
  
  /**
   * Returns the URL of the parent directory of the file or directory corresponding to the given URL,
   * or null if the parent directory cannot be determined.
   */
  static String _getParentURL(final String u) {
    final int ind = u.lastIndexOf("/");
    if (ind == -1) {
      return(null);
    } else {
      return(u.substring(0, ind));
    }
  }
  
  List<WXSElement> _anies(final String namespace, final String targetNamespace) {
    final List<WXSElement> liste = new List<WXSElement>();
    if (namespace == null || namespace == "" || namespace == "##any") {
      for (final WXSElement el in _lAllElements)
        if (el.getName() != null && el.getRef() == null && !el.getAbstract())
          liste.add(el);
    } else if (namespace == "##local") {
      for (final WXSElement el in _lAllElements) {
        if (el.getName() != null && el.getRef() == null && !el.getAbstract()) {
          final String tns = el.getNamespace();
          if (tns == null || tns == targetNamespace)
            liste.add(el);
        }
      }
    } else if (namespace == "##other") {
      for (final WXSElement el in _lAllElements) {
        if (el.getName() != null && el.getRef() == null && !el.getAbstract()) {
          final String tns = el.getNamespace();
          if (tns != null && tns != targetNamespace)
            liste.add(el);
        }
      }
    } else {
      // list of namespaces separated by spaces
      final HashSet<String> espaces = new HashSet.from(namespace.split(new RegExp(r"\s+")));
      if (espaces.contains("##targetNamespace")) {
        espaces.remove("##targetNamespace");
        espaces.add(targetNamespace);
      }
      if (espaces.contains("##local")) {
        espaces.remove("##local");
        espaces.add("");
      }
      for (final WXSElement el in _lAllElements) {
        if (el.getName() != null && el.getRef() == null && !el.getAbstract()) {
          final String tns = el.getNamespace();
          if (tns != null && espaces.contains(tns))
            liste.add(el);
        }
      }
    }
    return(liste);
  }
  
  /**
   * Returns the local part of an element's name (by removing the prefix)
   */
  static String _localValue(final String name) {
    if (name == null)
      return(null);
    final int ind = name.indexOf(':');
    if (ind == -1)
      return(name);
    return(name.substring(ind + 1));
  }
  
  /**
   * Returns the name's prefix or null if it does not have one.
   */
  static String _namePrefix(final String name) {
    if (name == null)
      return(null);
    final int indp = name.indexOf(':');
    if (indp == -1)
      return(null);
    else
      return(name.substring(0, indp));
  }
  
  static List<String> _booleanValues(final String type, final Element domElement) {
    final String tns = domElement.lookupNamespaceURI(_namePrefix(type));
    final String schemaNamespace = domElement.namespaceURI;
    if (_localValue(type) == "boolean" && schemaNamespace == tns) {
      final List<String> valbool = ["true", "false", "1", "0"];
      return(valbool);
    }
    return(null);
  }
  
  String _elementTitle(final WXSElement el) {
    if (_hashTitles[el.getName()] != null)
      return(_hashTitles[el.getName()]);
    else
      return(el.getName());
  }
  
}
