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
  final HashMap<Element, WXSElement> _hRefElementVersWXS = new HashMap<Element, WXSElement>(); // lien références éléments -> éléments WXS
  final HashMap<Element, WXSAttribute> _hRefAttributVersWXS = new HashMap<Element, WXSAttribute>(); // lien références attributs -> attributs WXS
  final HashMap<String, List<WXSElement>> _hNomVersWXS = new HashMap<String, List<WXSElement>>(); // lien noms -> objets WXS
  HashMap<String, String> _espaceVersPrefixe; // associations espaces de noms -> préfixes
  
  // liste de tous les éléments WXS (pas forcément directement sous xs:schema)
  // (ils peuvent avoir un attribut name ou un attribut ref)
  final LinkedHashSet<WXSElement> _lTousElements = new LinkedHashSet<WXSElement>();
  Set<WXSSchema> _schemasInclu;
  HashMap<String, String> _hashTitles;
  
  
  DaxeWXS(HashMap<String, String> hashElementTitles) {
    this._hashTitles = hashElementTitles;
    _schemasInclu = new HashSet<WXSSchema>();
    _espaceVersPrefixe = new HashMap<String, String>();
  }
  
  Future load(final String schemaURL) {
    Completer completer = new Completer();
    _readDocument(schemaURL).then((Element documentElement) {
      _schema = new WXSSchema(documentElement, schemaURL, this, null);
      _addNamespaces(_schema, null, null);
      _schemasInclu.add(_schema);
      _schema._inclusions().then((_) {
        for (final WXSSchema sch in _schemasInclu)
          _lTousElements.addAll(sch.allElements());
        for (final WXSSchema sch in _schemasInclu)
          sch._resolveReferences(); // WXSAny.resolveReferences() a besoin de cet objet DaxeWXS, c'est donc appelé plus tard
        for (WXSElement element in _lTousElements) {
          _hRefElementVersWXS[element.getDOMElement()] = element;
          if (element.getName() != null && element.getRef() == null) {
            List<WXSElement> listeWXS = _hNomVersWXS[element.getName()];
            if (listeWXS == null) {
              listeWXS = new List<WXSElement>();
              _hNomVersWXS[element.getName()] = listeWXS;
            }
            listeWXS.add(element);
          }
        }
        for (WXSElement element in _lTousElements) {
          final List<WXSAttribute> attributs = element.attributes();
          if (attributs != null) {
            for (WXSAttribute attribut in attributs)
              _hRefAttributVersWXS[attribut.getDOMElement()] = attribut;
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
    return(_hRefElementVersWXS[elementRef] != null);
  }
  
  // from InterfaceSchema
  Element elementReferenceByName(final String name) {
    final List<WXSElement> listeWXS = _hNomVersWXS[name];
    if (listeWXS == null)
      return(null);
    return(listeWXS[0].getDOMElement());
  }
  
  // from InterfaceSchema
  Element elementReference(final Element el, final Element parentRef) {
    if (parentRef == null) {
      // pour les éléments racine: il faut éviter les définitions locales
      String nom;
      if (el.prefix == null)
        nom = el.nodeName;
      else
        nom = el.localName;
      final String espace = el.namespaceURI;
      for (final WXSSchema sch in _schemasInclu) {
        for (final WXSElement topel in sch.getTopElements()) {
          if (topel.getRef() == null && !topel.getAbstract() &&
              nom == topel.getName() && espace == topel.getNamespace())
            return(topel.getDOMElement());
        }
      }
      print("JaxeWXS: referenceElement: pas d'élément racine correspondant dans le schéma pour $nom");
      return(null);
    }
    /*
     C'était pour le cas où parentRef n'était pas donné en paramètre, mais ce n'est plus possible:
     parentRef est maintenant obligatoire (le changement a été effectué parce-qu'il n'est plus
     possible d'utiliser "?parentRef" en Dart, et donc on ne peut plus distinguer un null passé explicitement
     d'un paramètre optionnel qui n'est pas passé en paramètre)
     
     else if (parentRef == null) {
      String nom, prefixe;
      prefixe = el.prefix;
      if (prefixe == null)
        nom = el.tagName;
      else
        nom = el.localName;
      final String espace = el.namespaceURI;
      final WXSElement element = _findFirstElement(nom, espace);
      if (element != null)
        return(element.getDOMElement());
      return(null);
    }
    */
    final WXSElement wxsParent = _hRefElementVersWXS[parentRef];
    if (wxsParent == null) {
      print("DaxeWXS: referenceElement: référence élément inconnue: $parentRef");
      return(null);
    }
    final List<WXSElement> liste = wxsParent.subElements();
    final String nom = el.localName;
    final String espace = el.namespaceURI;
    for (final WXSElement element in liste) {
      if (element.getName() == nom && element.getNamespace() == espace)
        return(element.getDOMElement());
    }
    return(null);
  }
  
  // from InterfaceSchema
  String elementName(final Element elementRef) {
    final WXSElement element = _hRefElementVersWXS[elementRef];
    if (element == null) {
      print("DaxeWXS: nomElement: référence élément inconnue: $elementRef");
      return(null);
    }
    return(element.getName());
  }
  
  // from InterfaceSchema
  String elementNamespace(final Element elementRef) {
    final WXSElement element = _hRefElementVersWXS[elementRef];
    if (element == null)
      return(null);
    return(element.getNamespace());
  }
  
  // from InterfaceSchema
  String elementPrefix(final Element elementRef) {
    final String espace = elementNamespace(elementRef);
    if (espace == null)
      return(null);
    return(_espaceVersPrefixe[espace]);
  }
  
  // from InterfaceSchema
  String elementDocumentation(final Element elementRef) {
    final WXSElement element = _hRefElementVersWXS[elementRef];
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
    final WXSElement element = _hRefElementVersWXS[elementRef];
    if (element == null)
      return(null);
    return(element.possibleValues());
  }
  
  // from InterfaceSchema
  bool elementValueIsValid(final Element elementRef, final String value) {
    final WXSElement element = _hRefElementVersWXS[elementRef];
    if (element == null)
      return(false);
    return(element.validValue(value));
  }
  
  // from InterfaceSchema
  List<String> namespaceList() {
    final LinkedHashSet<String> set = new LinkedHashSet<String>();
    if (_schema.getTargetNamespace() != null)
      set.add(_schema.getTargetNamespace());
    for (final String s in _espaceVersPrefixe.keys)
      set.add(s);
    return(new List.from(set));
  }
  
  // from InterfaceSchema
  bool hasNamespace(final String namespace) {
    final String targetNamespace = _schema.getTargetNamespace();
    if (namespace == null) {
      if (targetNamespace == null || targetNamespace == "")
        return(true);
      if (_espaceVersPrefixe.containsKey(""))
        return(true);
      // cas des éléments locaux sans espace de noms :
      final bool qualified = ("qualified" == _schema.getElementFormDefault());
      if (!qualified)
        return(true);
    } else {
      if (namespace == targetNamespace)
        return(true);
      if (_espaceVersPrefixe.containsKey(namespace))
        return(true);
    }
    return(false);
  }
  
  // from InterfaceSchema
  String namespacePrefix(final String ns) {
    return(_espaceVersPrefixe[ns]);
  }
  
  // from InterfaceSchema
  String getTargetNamespace() {
    return(_schema.getTargetNamespace());
  }
  
  // from InterfaceSchema
  List<Element> elementsOutsideNamespace(final String namespace) {
    final List<Element> liste = new List<Element>();
    for (final WXSElement el in _lTousElements) {
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
    for (final WXSElement el in _lTousElements) {
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
    for (final WXSElement el in _lTousElements) {
      if (el.getName() != null && el.getRef() == null && !el.getAbstract())
        liste.add(el.getDOMElement());
    }
    return(liste);
  }
  
  // from InterfaceSchema
  List<Element> rootElements() {
    final List<Element> liste = new List<Element>();
    for (final WXSSchema sch in _schemasInclu) {
      for (final WXSElement el in sch.getTopElements()) {
        if (el.getName() != null && el.getRef() == null && !el.getAbstract())
          liste.add(el.getDOMElement());
      }
    }
    return(liste);
  }
  
  // from InterfaceSchema
  bool requiredElement(final Element parentRef, final Element childRef) {
    final WXSElement parent = _hRefElementVersWXS[parentRef];
    if (parent == null) {
      print("DaxeWXS: requiredElement: unknown element reference: $parentRef");
      return(false);
    }
    final WXSElement enfant = _hRefElementVersWXS[childRef];
    if (enfant == null) {
      print("DaxeWXS: requiredElement: unknown element reference: $childRef");
      return(false);
    }
    bool bb = parent.requiredChild(enfant);
    return(bb != null && bb);
  }
  
  // from InterfaceSchema
  bool multipleChildren(final Element parentRef, final Element childRef) {
    final WXSElement parent = _hRefElementVersWXS[parentRef];
    if (parent == null) {
      print("DaxeWXS: enfantsMultiples: référence élément inconnue: $parentRef");
      return(false);
    }
    final WXSElement enfant = _hRefElementVersWXS[childRef];
    if (enfant == null) {
      print("DaxeWXS: enfantsMultiples: référence élément inconnue: $childRef");
      return(false);
    }
    bool bb = parent.multipleChildren(enfant);
    return(bb != null && bb);
  }
  
  // from InterfaceSchema
  List<Element> subElements(final Element parentRef) {
    // à faire: cache
    final WXSElement parent = _hRefElementVersWXS[parentRef];
    if (parent == null) {
      print("DaxeWXS: listeSousElements: référence élément inconnue: $parentRef");
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
    final WXSElement parent = _hRefElementVersWXS[parentRef];
    if (parent == null) {
      print("DaxeWXS: expressionReguliere: référence élément inconnue: $parentRef");
      return(null);
    }
    return(parent.elementRegularExpression()); // on utilise toujours modevisu=true et modevalid=true
  }
    
  // from InterfaceSchema
  List<Element> parentElements(final Element elementRef) {
    final WXSElement element = _hRefElementVersWXS[elementRef];
    if (element == null) {
      print("DaxeWXS: listeElementsParents: référence élément inconnue: $elementRef");
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
    final WXSElement element = _hRefElementVersWXS[elementRef];
    if (element == null) {
      print("DaxeWXS: listeAttributs: référence élément inconnue: $elementRef");
      return(null);
    }
    final List<WXSAttribute> attributs = element.attributes();
    final List<Element> liste = new List<Element>();
    for (WXSAttribute attribut in attributs)
      liste.add(attribut.getDOMElement());
    return(liste);
  }
  
  // from InterfaceSchema
  String attributeName(final Element attributeRef) {
    final WXSAttribute attribut = _hRefAttributVersWXS[attributeRef];
    if (attribut == null) {
      print("DaxeWXS: nomAttribut: référence attribut inconnue: $attributeRef");
      return(null);
    }
    return(attribut.getName());
  }
  
  // from InterfaceSchema
  String attributeNamespace(final Element attributeRef) {
    final WXSAttribute attribut = _hRefAttributVersWXS[attributeRef];
    if (attribut == null) {
      print("DaxeWXS: espaceAttribut: référence attribut inconnue: $attributeRef");
      return(null);
    }
    return(attribut.getNamespace());
  }
  
  // from InterfaceSchema
  String attributeDocumentation(final Element attributeRef) {
    final WXSAttribute attribut = _hRefAttributVersWXS[attributeRef];
    if (attribut == null) {
      print("DaxeWXS: documentationAttribut: référence attribut inconnue: $attributeRef");
      return(null);
    }
    return(attribut.getDocumentation());
  }
  
  // from InterfaceSchema
  String attributeNamespaceByName(final String attributeName) {
    if (attributeName == null)
      return(null);
    final String prefixe = _namePrefix(attributeName);
    if (prefixe == null)
      return(null);
    if (prefixe == "xml")
      return("http://www.w3.org/XML/1998/namespace");
    return(_schema.prefixNamespace(prefixe));
  }
  
  /**
   * Returns true if an attribute is required, based on its definition.
   * Warning: this is not possible to determine this with only the attribute reference with Relax NG.
   * It is better to use attributeIsRequired.
   */
  bool isRequired(final Element attributeRef) {
    final WXSAttribute attribut = _hRefAttributVersWXS[attributeRef];
    if (attribut == null) {
      print("DaxeWXS: estObligatoire: référence attribut inconnue: $attributeRef");
      return(false);
    }
    return(attribut.getUse() == "required");
  }
  
  // from InterfaceSchema
  bool attributeIsRequired(final Element parentRef, final Element attributeRef) {
    return(isRequired(attributeRef));
  }
  
  // from InterfaceSchema
  List<String> attributeValues(final Element attributeRef) {
    final WXSAttribute attribut = _hRefAttributVersWXS[attributeRef];
    if (attribut == null) {
      print("DaxeWXS: listeValeursAttribut: référence attribut inconnue: $attributeRef");
      return(null);
    }
    return(attribut.possibleValues());
  }
  
  // from InterfaceSchema
  String defaultAttributeValue(final Element attributeRef) {
    final WXSAttribute attribut = _hRefAttributVersWXS[attributeRef];
    if (attribut == null) {
      print("DaxeWXS: valeurParDefaut: référence attribut inconnue: $attributeRef");
      return(null);
    }
    return(attribut.defaultValue());
  }
  
  // from InterfaceSchema
  bool attributeIsValid(final Element attributeRef, final String value) {
    // à refaire avec les classes WXS
    final WXSAttribute attribut = _hRefAttributVersWXS[attributeRef];
    if (attribut == null) {
      print("DaxeWXS: attributValide: référence attribut inconnue: $attributeRef");
      return(false);
    }
    return(attribut.validValue(value));
  }
  
  // from InterfaceSchema
  Element attributeParent(final Element attributeRef) {
    final WXSAttribute attribut = _hRefAttributVersWXS[attributeRef];
    if (attribut == null) {
      print("DaxeWXS: parentAttribut: référence attribut inconnue: $attributeRef");
      return(null);
    }
    final List<WXSElement> parents = attribut.parentElements();
    if (parents.length > 0)
      return(parents[0].getDOMElement());
    return(null);
  }
  
  // from InterfaceSchema
  bool canContainText(final Element elementRef) {
    final WXSElement element = _hRefElementVersWXS[elementRef];
    if (element == null) {
      print("DaxeWXS: contientDuTexte: référence élément inconnue: $elementRef");
      return(false);
    }
    return(element.containsText());
  }
  
  
  /**
   * Tests if an element is valid.
   * If insert is true, just tests the validity of an insert (all sub-elements are optionnal).
   */
  bool validElement(final Element elementRef, final List<Element> subElementRefs, final bool insert) {
    final WXSElement element = _hRefElementVersWXS[elementRef];
    if (element == null) {
      print("DaxeWXS: elementValide: référence élément inconnue: $elementRef");
      return(false);
    }
    final List<WXSElement> sousElements = new List<WXSElement>();
    for (Element ref in subElementRefs) {
      final WXSElement sousElement = _hRefElementVersWXS[ref];
      if (sousElement != null)
        sousElements.add(sousElement); // sinon ref d'une autre config ?
    }
    return(element.validateSubElements(sousElements, insert));
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
    for (WXSSchema schemaInclu in _schemasInclu) {
      if (_normalizePath(schemaInclu.getURL()) == _normalizePath(urls)) {
        _addNamespaces(schemaInclu, parentSchema, importNamespace); // une chance de plus de trouver un préfixe
        return(new Future.value(schemaInclu));
      }
    }
    Completer<WXSSchema> completer = new Completer<WXSSchema>();
    _readDocument(urls).then((Element documentElement) {
      final WXSSchema schemaInclu = new WXSSchema(documentElement, urls, this, parentSchema);
      _addNamespaces(schemaInclu, parentSchema, importNamespace);
      _schemasInclu.add(schemaInclu);
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
  
  // transforme 'a/..' en '' à l'intérieur de chemins
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
    if (importNamespace != null && _espaceVersPrefixe[importNamespace] == null) {
      String prefixe = sch.namespacePrefix(importNamespace);
      if (prefixe != null)
        _espaceVersPrefixe[importNamespace] = prefixe;
      else if (parentSchema != null) {
        prefixe = parentSchema.namespacePrefix(importNamespace);
        if (prefixe != null)
          _espaceVersPrefixe[importNamespace] = prefixe;
      }
    }
    // toujours ajouter targetNamespace ?
    final String targetNamespace = sch.getTargetNamespace();
    if (targetNamespace != null && targetNamespace != "") {
      final String prefixe = sch.namespacePrefix(targetNamespace);
      if (prefixe != null)
        _espaceVersPrefixe[targetNamespace] = prefixe;
    }
  }
  
  WXSElement _findFirstElement(final String name, final String namespace) {
    final List<WXSElement> listeWXS = _hNomVersWXS[name];
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
      for (final WXSElement el in _lTousElements)
        if (el.getName() != null && el.getRef() == null && !el.getAbstract())
          liste.add(el);
    } else if (namespace == "##local") {
      for (final WXSElement el in _lTousElements) {
        if (el.getName() != null && el.getRef() == null && !el.getAbstract()) {
          final String tns = el.getNamespace();
          if (tns == null || tns == targetNamespace)
            liste.add(el);
        }
      }
    } else if (namespace == "##other") {
      for (final WXSElement el in _lTousElements) {
        if (el.getName() != null && el.getRef() == null && !el.getAbstract()) {
          final String tns = el.getNamespace();
          if (tns != null && tns != targetNamespace)
            liste.add(el);
        }
      }
    } else {
      // liste d'espaces de noms séparés par des espaces
      final HashSet<String> espaces = new HashSet.from(namespace.split(new RegExp(r"\s+")));
      if (espaces.contains("##targetNamespace")) {
        espaces.remove("##targetNamespace");
        espaces.add(targetNamespace);
      }
      if (espaces.contains("##local")) {
        espaces.remove("##local");
        espaces.add("");
      }
      for (final WXSElement el in _lTousElements) {
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
    final String espaceSchema = domElement.namespaceURI;
    if (_localValue(type) == "boolean" && espaceSchema == tns) {
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
