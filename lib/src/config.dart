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

part of daxe;


/**
 * A Jaxe configuration file. Includes many useful methods to use XML schemas.
 */
class Config {
  static final String _typeAffichageParDefaut = "string";
  
  x.Element _cfgroot; // config file root element
  
  String schemaURL; // schema file URL
  
  String _cfgdir; // config folder URL (in which the config file must be)
  
  HashMap<String, x.Element> _elementDisplayCache; // cache for associations nom -> AFFICHAGE_ELEMENT
  HashMap<x.Element, String> _elementsToNamesCache; // cache for associations element reference -> name
  HashMap<x.Element, String> _elementsTitlesCache; // cache for associations element reference -> title
  HashMap<x.Element, Pattern> _insertCache = null; // cache for regular expressions for insertions
  HashMap<x.Element, Pattern> _validPatternCache = null;
  HashMap<x.Element, HashMap<String, List<String>>> _parametersCache = null;
  List<String> _namespaceCache = null; // namespace list
  
  InterfaceSchema _schema; // all the schema management (validity...)
  
  // nodes for the config file main elements
  x.Element _languageNode;
  x.Element _savingNode;
  x.Element _menusNode;
  x.Element _displayNode;
  x.Element _exportsNode;
  List<x.Element> _listeStrings;

  
  // CONSTRUCTORS AND INITIALIZATION
  
  /**
   * Constructor (load must be called afterwards)
   */
  Config() {
  }
  
  /**
   * Load a config file
   *
   * @param cfgFilePath  path to the config file
   */
  Future load(final String cfgFilePath) { // throws DaxeException
    Completer completer = new Completer();
    if (cfgFilePath == null) {
      _cfgroot = null;
      return(new Future.error(new DaxeException("Config.load: null path")));
    }
    
    x.DOMParser dp = new x.DOMParser();
    dp.parseFromURL(cfgFilePath).then((x.Document configdoc) {
      String resource;
      if (configdoc.documentElement.nodeName == "CONFIG_JAXE")
        resource = null;
      else
        resource = _getResource(configdoc.documentElement);
      
      _cfgdir = _getParentURL(cfgFilePath);
      
      _cfgroot = configdoc.documentElement;
      
      // AUTRE_CONFIG: ignored
      
      _buildElementDisplayCache();
      
      _elementsTitlesCache = new HashMap<x.Element, String>();
      
      final String noms = schemaName();
      if (noms == null) {
        final x.Element schema_simple = _findElement(_getLanguage(), "SCHEMA_SIMPLE");
        if (schema_simple == null) {
          completer.completeError(new DaxeException("Error: no XML schema is defined in the config file $cfgFilePath"));
          return;
        }
        _schema = new SimpleSchema(schema_simple, _titlesHash());
        schemaURL = null;
        _buildElementsToNamesCache();
        completer.complete();
        return;
      }
      
      if (_cfgdir != null)
        schemaURL = "${_cfgdir}/$noms";
        else
          schemaURL = noms;
      _schema = new DaxeWXS(_titlesHash());
      (_schema as DaxeWXS).load(schemaURL).then((_) {
        _buildElementsToNamesCache();
        completer.complete();
      }, onError: (WXSException ex) {
        completer.completeError(new DaxeException("Error reading schemaURL: $ex"));
      });
    }, onError: (x.DOMException ex) {
      completer.completeError(new DaxeException("Error reading $cfgFilePath: $ex"));
    });
    return(completer.future);
  }
  
  /**
   * Returns the URL of the parent of the given URL (file or directory),
   * or null if the parent directory cannot be found
   */
  static String _getParentURL(final String u) {
    final int index = u.lastIndexOf("/");
    if (index >= 0) {
      return(u.substring(0, index));
    }
    return(null);
  }
  
  
  // METHODS RELATED TO THE CONFIG FILE
  
  /**
   * Returns the name of the first possible root element, or null if none are defined.
   */
  String nameOfFirstRootElement() {
    final x.Element racine = _findElement(_getLanguage(), "RACINE");
    if (racine == null)
      return(null);
    return(racine.getAttribute("element"));
  }
  
  /**
   * Returns the reference to the first possible root element, or null if none are defined.
   */
  x.Element firstRootElement() {
    final String nom = nameOfFirstRootElement();
    return(_schema.elementReferenceByName(nom));
  }
  
  /**
   * Returns the list of names of the possible root elements
   */
  List<String> listOfRoots() {
    final List<String> liste = new List<String>();
    x.Element racine = _findElement(_getLanguage(), "RACINE");
    while (racine != null) {
      liste.add(racine.getAttribute("element"));
      racine = _nextElement(racine, "RACINE");
    }
    return(liste);
  }
  
  /**
   * Returns the list of references to the possible root elements
   */
  List<x.Element> rootElements() {
    // pour éviter une erreur dans le cas d'un schéma définissant un élément global et un élément local
    // sous le même nom mais avec des types différents, on est obligé d'aller d'abord chercher les références
    // des éléments racines en fonction de l'implémentation du schéma, puis de chercher dedans les éléments
    // avec les noms donnés dans la config.
    final List<x.Element> liste = new List<x.Element>();
    final List<x.Element> racinesPossibles = _schema.rootElements();
    x.Element racine = _findElement(_getLanguage(), "RACINE");
    while (racine != null) {
      final String nom = racine.getAttribute("element");
      for (final x.Element ref in racinesPossibles)
        if (nom == _schema.elementName(ref))
          liste.add(ref);
          racine = _nextElement(racine, "RACINE");
    }
    return(liste);
  }
  
  /**
   * Adds the attributes for the namespaces to the root node
   */
  void addNamespaceAttributes(final DaxeNode root) {
    final List<String> espaces = _namespaceList();
    for (final String espace in espaces) {
      if (espace != "") {
        final String prefixe = namespacePrefix(espace);
        String nomatt;
        if (prefixe != null && prefixe != "")
          nomatt = "xmlns:$prefixe";
        else
          nomatt = "xmlns";
        root.setAttributeNS("http://www.w3.org/2000/xmlns/", nomatt, espace);
      }
    }
    final String schemaLocation = getSchemaLocation();
    final String noNamespaceSchemaLocation = getNoNamespaceSchemaLocation();
    if (schemaLocation != null || noNamespaceSchemaLocation != null) {
      root.setAttributeNS("http://www.w3.org/2000/xmlns/", "xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance");
      if (schemaLocation != null)
        root.setAttributeNS("http://www.w3.org/2001/XMLSchema-instance",
            "xsi:schemaLocation", schemaLocation);
      if (noNamespaceSchemaLocation != null)
        root.setAttributeNS("http://www.w3.org/2001/XMLSchema-instance",
            "xsi:noNamespaceSchemaLocation", noNamespaceSchemaLocation);
    }
  }
  
  /**
   * Returns the name of the schema file as given in the config file
   * (FICHIER_SCHEMA/@nom)
   * Returns null if none is defined
   */
  String schemaName() {
    final x.Element fichierschema = _findElement(_getLanguage(), "FICHIER_SCHEMA");
    if (fichierschema == null)
      return(null);
    String nom = fichierschema.getAttribute("nom");
    if (nom == "")
      nom = null;
    return(nom);
  }
  
  /**
   * Returns the hash table by name of the element displays in the config file
   * (element AFFICHAGE_ELEMENT)
   */
  HashMap<String, x.Element> _buildElementDisplayCache() {
    _elementDisplayCache = new HashMap<String, x.Element>();
    if (_cfgroot == null)
      return(_elementDisplayCache);
    x.Element affel = _findElement(_getNodeDisplay(), "AFFICHAGE_ELEMENT");
    while (affel != null) {
      final String nom = affel.getAttribute("element");
      _elementDisplayCache[nom] = affel;
      affel = _nextElement(affel, "AFFICHAGE_ELEMENT");
    }
    return(_elementDisplayCache);
  }
  
  HashMap<x.Element, String> _getElementsToNamesCache() {
    return(_elementsToNamesCache);
  }
  
  x.Element getElementDisplay(String name) {
    return _elementDisplayCache[name];
  }
  
  /**
   * Builds the hash table of associations schema reference -> element name
   */
  void _buildElementsToNamesCache() {
    _elementsToNamesCache = new HashMap<x.Element, String>();
    if (_cfgroot == null)
      return;
    final List<x.Element> elements = _schema.allElements();
    for (final x.Element ref in elements) {
      final String nom = _schema.elementName(ref);
      if (nom != null)
        _elementsToNamesCache[ref] = nom;
    }
  }
  
  /**
   * Return the name of the resource bundle to use.
   *
   * @return the name of the resource bundle, null if not defined.
   */
  String _getResource(final x.Element root) {
    final x.Element bundle = _findElement(root, "FICHIERTITRES");
    if (bundle == null)
      return(null);
    return(bundle.getAttribute("nom"));
  }
  
  /**
   * Returns the list of export references, depending on the output (HTML or XML)
   */
  List<x.Element> exportsList(final String output) {
    if (_cfgroot == null)
      return(null);
    final List<x.Element> liste = new List<x.Element>();
    x.Element export = _findElement(_getExports(), "EXPORT");
    while (export != null) {
      if (output == export.getAttribute("sortie"))
        liste.add(export);
      export = _nextElement(export, "EXPORT");
    }
    return(liste);
  }
  
  /**
   * Returns an export name based on its reference
   */
  String exportName(final x.Element exportRef) {
    return(exportRef.getAttribute("nom"));
  }
  
  /**
   * Returns the output of an export based on its reference
   */
  String exportOutput(final x.Element exportRef) {
    return(exportRef.getAttribute("sortie"));
  }
  
  /**
   * Returns the character encoding to use for new XML documents
   */
  String getEncoding() {
    final x.Element encodage = _findElement(_getSaving(), "ENCODAGE");
    if (encodage == null)
      return(null);
    return(_dom_elementValue(encodage));
  }
  
  String getPublicId() {
    final x.Element doctype = _findElement(_getSaving(), "DOCTYPE");
    if (doctype != null)
      return doctype.getAttribute("publicId");
    
    return(null);
  }
  
  String getSystemId() {
    final x.Element doctype = _findElement(_getSaving(), "DOCTYPE");
    if (doctype != null)
      return doctype.getAttribute("systemId");
    return(null);
  }
  
  String getSchemaLocation() {
    final x.Element sl = _findElement(_getSaving(), "SCHEMALOCATION");
    if (sl != null) {
      final String schemaLocation = sl.getAttribute("schemaLocation");
      if (schemaLocation != "")
        return(schemaLocation);
    }
    return(null);
  }
  
  String getNoNamespaceSchemaLocation() {
    final x.Element sl = _findElement(_getSaving(), "SCHEMALOCATION");
    if (sl != null) {
      final String noNamespaceSchemaLocation = sl.getAttribute("noNamespaceSchemaLocation");
      if (noNamespaceSchemaLocation != "")
        return(noNamespaceSchemaLocation);
    }
    return(null);
  }
  
  /**
   * Returns a prefix to use for the given namespace, or null if none is found
   */
  String namespacePrefix(final String namespace) {
    if (namespace == "http://www.w3.org/XML/1998/namespace")
      return("xml");
    x.Element pe = _findElement(_getSaving(), "PREFIXE_ESPACE");
    while (pe != null) {
      if (namespace == pe.getAttribute("uri"))
        return(pe.getAttribute("prefixe"));
      pe = _nextElement(pe, "PREFIXE_ESPACE");
    }
    return(_schema.namespacePrefix(namespace));
  }
  
  
  // METHODS FOR THE ELEMENT INSERT MENUS
  
  /**
   * Returns a menu matching the menu definition in the config file.
   *
   * @param doc  The Daxe document
   * @param menudef  The MENU element in the config file
   */
  Menu _creationMenu(final DaxeDocument doc, final x.Element menudef) {
    final String nomMenu = menudef.getAttribute("nom");
    String titreM = menuTitle(nomMenu);
    final Menu menu = new Menu(titreM);
    String docMenu = menuDocumentation(nomMenu);
    if (docMenu != null) {
      //docMenu = "<html><body>{docMenu.replaceAll('\n', '<br>')}</body></html>";
      menu.toolTipText = docMenu;
    }
    x.Node menunode = menudef.firstChild;
    while (menunode != null) {
      MenuItem item = null;
      final String nodename = menunode.nodeName;
      String shortcut = null;
      if (menunode is x.Element) {
        final String commande = (menunode as x.Element).getAttribute("raccourci");
        if (commande != null && commande != "") {
          shortcut = commande.toUpperCase()[0];
        }
      }
      if (nodename == "MENU_INSERTION") {
        final x.Element insnoeud = menunode as x.Element;
        final String nom = insnoeud.getAttribute("nom");
        final String titre = menuTitle(nom);
        String typeNoeud = insnoeud.getAttribute("type_noeud");
        if (typeNoeud == "")
          typeNoeud = "element";
        x.Element refElement;
        if (typeNoeud == "element") {
          refElement = elementReference(nom);
          if (refElement == null)
            logError("Erreur: MENU_INSERTION: pas de référence pour '$nom' dans le schéma");
        } else
          refElement = null;
        item = new MenuItem(titre, () => doc.insertNewNode(refElement, typeNoeud), shortcut: shortcut, data: refElement);
        menu.add(item);
        String itemdoc = documentation(refElement);
        if (itemdoc != null) {
          //itemdoc = formatDoc(itemdoc);
          item.toolTipText = itemdoc;
        }
      } else if (nodename == "MENU_FONCTION") {
        final x.Element fonction = menunode as x.Element;
        final String classe = fonction.getAttribute("classe");
        final String nom = fonction.getAttribute("nom");
        final String titre = menuTitle(nom);
        item = new MenuItem(titre, () => doc.executeFunction(classe, fonction), shortcut: shortcut);
        menu.add(item);
        String itemdoc = menuDocumentation(nom);
        if (itemdoc != null) {
          //itemdoc = formatDoc(itemdoc);
          item.toolTipText = itemdoc;
        }
      } else if (nodename == "MENU") {
        item = _creationMenu(doc, menunode as x.Element);
        menu.add(item);
      } else if (nodename == "SEPARATEUR")
        menu.addSeparator();
      
      menunode = menunode.nextSibling;
    }
    return(menu);
  }
  
  /**
   * Returns a menubar to insert menus.
   *
   * @param doc  The Daxe document
   */
  MenuBar makeMenus(final DaxeDocument doc) {
    final MenuBar mbar = new MenuBar();
    
    final x.Element menus = _getMenus();
    if (menus != null) {
      x.Element menudef = _findElement(menus, "MENU");
      while (menudef != null) {
        final Menu jmenu = _creationMenu(doc, menudef);
        jmenu.parent = mbar;
        mbar.add(jmenu);
        menudef = _nextElement(menudef, "MENU");
      }
    }
    return(mbar);
  }
  
  
  // METHODS RELATED TO THE SCHEMA
  
  InterfaceSchema getSchema() {
    return(_schema);
  }
  
  /**
   * Returns the references for all the elements in the schema
   */
  List<x.Element> allElementsList() {
    final List<x.Element> liste = _schema.allElements();
    return(liste);
  }
  
  bool _elementInSchema(final x.Element elementRef) {
    return(_schema.elementInSchema(elementRef));
  }
  
  /**
   * Returns the name of the element
   */
  String elementName(final x.Element elementRef) {
    return(_elementsToNamesCache[elementRef]);
  }
  
  /**
   * Returns the reference of the first matching element in the schema,
   * based on the element and the reference of its parent
   */
  x.Element getElementRef(final x.Element el, final x.Element parentRef) {
    return(_schema.elementReference(el, parentRef));
  }
  
  /**
   * Returns the reference for the first element with the given name
   */
  x.Element elementReference(final String name) {
    final x.Element el = _schema.elementReferenceByName(localValue(name));
    return(el);
  }
  
  /**
   * Returns the references of the elements with the given name
   */
  List<x.Element> elementReferences(final String name) {
    return(_schema.elementReferencesByName(localValue(name)));
  }
  
  /**
   * Returns the namespace to use for the element,
   * or null the namespace is undefined.
   */
  String elementNamespace(final x.Element elementRef) {
    return(_schema.elementNamespace(elementRef));
  }
  
  /**
   * Returns the prefix to use for a new element with the given reference,
   * or null if no prefix should be used.
   */
  String elementPrefix(final x.Element elementRef) {
    final String espace = elementNamespace(elementRef);
    if (espace == null)
      return(null);
    return(namespacePrefix(espace));
  }
  
  /**
   * Returns the list of possible values for an element.
   * Returns null if there are an infinity of possible values.
   */
  List<String> elementValues(final x.Element elementRef) {
    final List<String> liste = _schema.elementValues(elementRef);
    return(liste);
  }
  
  /**
   * Returns true if the given value is valid for the element
   */
  bool isElementValueValid(final x.Element elementRef, final String value) {
    return(_schema.elementValueIsValid(elementRef, value));
  }
  
  /**
   * Returns the list of all namespaces in the schema
   */
  List<String> _namespaceList() {
    if (_namespaceCache != null)
      return(_namespaceCache);
    final List<String> liste = new List<String>();
    final List<String> espacesSchema = _schema.namespaceList();
    if (espacesSchema != null)
      liste.addAll(espacesSchema);
    _namespaceCache = liste;
    return(liste);
  }
  
  /**
   * Returns a number for the given namespace, starting from 0.
   * A unique number is given for each namespace.
   * Returns -1 if the namespace is not found in the config.
   */
  int namespaceNumber(final String namespace) {
    final List<String> liste = _namespaceList();
    return(liste.indexOf(namespace));
  }
  
  /**
   * Returns true if the namspace is defined in the config
   */
  bool hasNamespace(final String namespace) {
    return(_schema.hasNamespace(namespace));
  }
  
  /**
   * Returns the target namespace for the schema (targetNamespace attribute for WXS)
   */
  String targetNamespace() {
    return(_schema.getTargetNamespace());
  }
  
  /**
   * Returns the references of the elements which are not in the given namespace
   */
  List<x.Element> elementsOutsideNamespace(final String namespace) {
    return(_schema.elementsOutsideNamespace(namespace));
  }
  
  /**
   * Returns the references of the elements which are in the given namespaces
   */
  List<x.Element> elementsWithinNamespaces(final Set<String> namespaces) {
    return(_schema.elementsWithinNamespaces(namespaces));
  }
  
  /**
   * Returns true if the child is required under the parent.
   */
  bool requiredElement(final x.Element parentRef, final x.Element childRef) {
    return(_schema.requiredElement(parentRef, childRef));
  }
  
  /**
   * Returns true if there is a relation parent-child between the 2 elements
   */
  bool isSubElement(final x.Element parentRef, final x.Element childRef) {
    final List<x.Element> children = subElements(parentRef);
    if (children == null)
      return(false);
    return(children.contains(childRef));
  }
  
  /**
   * Returns the first reference in the list that is a child of the parent, or null if none is found.
   */
  x.Element findSubElement(final x.Element parentRef, final List<x.Element> refs) {
    final List<x.Element> children = subElements(parentRef);
    if (children == null)
      return(null);
    for (x.Element ref in refs)
      if (children.contains(ref))
        return(ref);
    return(null);
  }
  
  /**
   * Returns true if the given name matches a possible child for the given parent
   */
  bool isSubElementByName(final x.Element parentRef, String childName) {
    final int inds = childName.indexOf(':');
    if (inds != -1)
      childName = childName.substring(inds+1);
    final List<String> noms = subElementsNames(parentRef);
    return(noms.contains(childName));
  }
  
  /**
   * Returns the references of the given element's children
   */
  List<x.Element> subElements(final x.Element parentRef) {
    return(_schema.subElements(parentRef));
  }
  
  /**
   * Returns the names of the given element's children
   */
  List<String> subElementsNames(final x.Element parentRef) {
    final List<x.Element> listeReferences = subElements(parentRef);
    final List<String> listeNoms = new List<String>();
    for (final x.Element ref in listeReferences) {
      final String nom = _elementsToNamesCache[ref];
      if (!listeNoms.contains(nom))
        listeNoms.add(nom);
    }
    return(listeNoms);
  }
  
  /**
   * Regular expression for a given element
   * @param modevisu  True to get a regular expression to display to the user
   * @param modevalid  For strict validation instead of checking if an insert is possible
   */
  String _regularExpression(final x.Element parentRef, final bool modevisu, final bool modevalid) {
    return(_schema.regularExpression(parentRef, modevisu, modevalid));
  }
  
  /**
   * Regular expression based on the schema for a given parent element
   */
  String regularExpression(final x.Element parentRef) {
    return(_schema.regularExpression(parentRef, true, false));
  }
  
  /**
   * Returns true if the toInsert element can be inserted under the parent element
   * on the selection defined by the start and end positions
   */
  bool insertIsPossible(DaxeNode parent, final int startOffset, final int endOffset, final x.Element toInsert) {
    if (parent.nodeType == DaxeNode.DOCUMENT_NODE) {
      for (DaxeNode dn in parent.childNodes) {
        if (dn.nodeType == DaxeNode.ELEMENT_NODE)
          return(false);
      }
      return(true);
    }
    assert(parent.nodeType == DaxeNode.ELEMENT_NODE);
    if (_schema is SimpleSchema)
      return(true); // on suppose que le test de sous-élément a déjà été fait
    if (startOffset < 0) {
      logError("Config.insertionPossible: debutSelection < parent.debut");
      return(false);
    }
    if (_schema is DaxeWXS) {
      final List<x.Element> sousElements = new List<x.Element>();
      bool ajoute = false;
      for (DaxeNode dn = parent.firstChild; dn != null; dn = dn.nextSibling) {
        if (dn.nodeType == DaxeNode.ELEMENT_NODE) {
          int offset = parent.offsetOf(dn);
          if (offset < startOffset || offset >= endOffset) {
            if (!ajoute && offset >= endOffset) {
              sousElements.add(toInsert);
              ajoute = true;
            }
            sousElements.add(dn.ref);
          }
        }
      }
      if (!ajoute)
        sousElements.add(toInsert);
      final bool insertionOK = (_schema as DaxeWXS).validElement(parent.ref, sousElements, true);
      return(insertionOK);
    }
    return(false);
/*
    pb: on ne peut pas tester l'ordre des éléments dans certains cas, par exemple:
    <html>
        <head>
            <xsl:if test='truc'>
                <title>xxx</title>
            </xsl:if>
            <xsl:if test='not(truc)'>
                <title>yyy</title>
            </xsl:if>
        </head>
    </html>
    Ici on autorise deux éléments title sous head alors qu'un seul est normalement autorisé.
    Par contre on peut tester les imbrications (title est autorisé sous head).
*/
  }
  
  /**
   * Returns true if the parent element is valid, considering only its attributes,
   * its first level children, and its node value
   */
  bool elementIsValid(final DaxeNode parent) {
    if (parent is DNComment || parent is DNProcessingInstruction || parent is DNCData)
      return(true);
    
    if (parent.ref == null)
      return(false);
    
    if (!attributesAreValid(parent))
      return(false);
    
    if (parent.firstChild == null && !isElementValueValid(parent.ref, ''))
      return(false);
    else if (parent.childNodes.length == 1 && parent.firstChild is DNText && parent.firstChild.nodeValue != null &&
        !isElementValueValid(parent.ref, parent.firstChild.nodeValue))
      return(false);
    
    if (_schema is SimpleSchema)
      return(true); // on suppose que le test de sous-balise a déjà été fait
    if (_schema is DaxeWXS) {
      final List<x.Element> sousElements = new List<x.Element>();
      bool avectexte = false;
      for (DaxeNode dn = parent.firstChild; dn != null; dn = dn.nextSibling) {
        if (dn.nodeType == DaxeNode.ELEMENT_NODE && dn.ref != null) {
          sousElements.add(dn.ref);
        } else if (dn.nodeType == DaxeNode.TEXT_NODE) {
          if (dn.nodeValue.trim() != "")
            avectexte = true;
        } else if (dn is DNCData) {
          if (dn.firstChild != null && dn.firstChild.nodeValue.trim() != '')
            avectexte = true;
        }
      }
      if (avectexte && !_schema.canContainText(parent.ref))
        return(false);
      final DaxeWXS sch = _schema as DaxeWXS;
      return(sch.validElement(parent.ref, sousElements, false));
    }
    
    final x.Element refParent = parent.ref;
    final StringBuffer cettexp = new StringBuffer();
    if (_validPatternCache == null)
      _validPatternCache = new HashMap<x.Element, Pattern>();
    
    bool avectexte = false;
    DaxeNode child = parent.firstChild;
    while (child != null) {
      if (child is DNCData) {
        if (child.firstChild != null && child.firstChild.nodeValue.trim() != '')
          avectexte = true;
      } else if (child.nodeType == DaxeNode.ELEMENT_NODE && child is! DNComment && child is! DNProcessingInstruction)  {
        cettexp.write(child.localName);
        cettexp.write(",");
      } else if (child.nodeType == DaxeNode.TEXT_NODE) {
        if (child.nodeValue.trim() != '')
          avectexte = true;
      }
      child = child.nextSibling;
    }
    if (avectexte && !_schema.canContainText(refParent))
      return(false);
    RegExp r = _validPatternCache[refParent];
    if (r == null) {
      final String expr = _regularExpression(refParent, false, true);
      if (expr == null || expr == "")
        return(true);
      try {
        r = new RegExp(r"^$expr$");
      } on Exception catch(ex) {
        logError("elementValide(JaxeElement, bool, List<String>) - Malformed Pattern: ^${expr}\$:", ex);
        return(true);
      }
      _validPatternCache[refParent] = r;
    }

    final bool matched = r.hasMatch(cettexp.toString());
    return(matched);
  }
  
  /**
   * Returns true if the element attributes are valid and if there is not missing required attribute.
   */
  bool attributesAreValid(final DaxeNode dn) {
    if (dn.nodeType != DaxeNode.ELEMENT_NODE) {
      logError("Config.attributsValides : ce n'est pas un élément: $dn");
      return(false);
    }
    // vérif des attributs qui sont dans le schéma
    final List<x.Element> lattref = elementAttributes(dn.ref);
    List<String> noms = new List<String>(lattref.length);
    List<String> espaces = new List<String>(noms.length);
    for (int i=0; i<lattref.length; i++) {
      final x.Element attref = lattref[i];
      noms[i] = attributeName(attref);
      espaces[i] = attributeNamespace(attref);
      final String valeur = dn.getAttribute(noms[i]);
      if (valeur == null || valeur == '') {
        if (requiredAttribute(dn.ref, attref))
          return(false);
      } else if (!validAttributeValue(attref, valeur))
        return(false);
    }
    // vérif s'il y a des attributs en plus qui ne sont pas dans le schéma
    final List<DaxeAttr> latt = dn.attributes;
    for (int i=0; i<latt.length; i++) {
      DaxeAttr att = latt[i];
      final String prefixe = att.prefix;
      if (prefixe == "xml" || prefixe == "xmlns")
        continue;
      final String nom = att.localName;
      if (prefixe == null && nom == "xmlns")
        continue;
      final String espace = att.namespaceURI;
      if (espace == "http://www.w3.org/2001/XMLSchema-instance")
        continue;
      bool trouve = false;
      for (int j=0; j<noms.length; j++) {
        if (noms[j] == nom && espaces[j] == espace) {
          trouve = true;
          break;
        }
      }
      if (!trouve)
        return(false);
    }
    return(true);
  }
  
  /**
   * Returns the list of possible parent elements for a given element
   */
  List<x.Element> parentElements(final x.Element elementRef) {
    return(_schema.parentElements(elementRef));
  }
  
  /**
   * Returns the list of names for possible parent elements for a given element
   */
  List<String> parentNames(final x.Element elementRef) {
    final List<x.Element> listeReferences = parentElements(elementRef);
    final List<String> listeNoms = new List<String>();
    for (final x.Element ref in listeReferences) {
      final String nom = _elementsToNamesCache[ref];
      if (!listeNoms.contains(nom))
        listeNoms.add(nom);
    }
    return(listeNoms);
  }
  
  /**
   * Returns true if the given element can contain text
   */
  bool canContainText(final x.Element elementRef) {
    if (elementRef == null)
      return(true);
    return(_schema.canContainText(elementRef));
  }
  
  /**
   * Returns the list of possible attributes for a given element.
   */
  List<x.Element> elementAttributes(final x.Element elementRef) {
    return(_schema.elementAttributes(elementRef));
  }
  
  /**
   * Returns the name of an attribute based on its reference.
   */
  String attributeName(final x.Element attributeRef) {
    return(_schema.attributeName(attributeRef));
  }
  
  /**
   * Returns the qualified name of an attribute based on its reference.
   */
  String attributeQualifiedName(final x.Element parentRef, final x.Element attributeRef) {
    String name = _schema.attributeName(attributeRef);
    String namespace = _schema.attributeNamespace(attributeRef);
    if (namespace != null) {
      String prefix = attributePrefix(parentRef, attributeRef);
      if (prefix != null)
        name = "$prefix:$name";
    }
    return(name);
  }
  
  /**
   * Returns an attribute namespace based on its reference, or null if none is defined.
   */
  String attributeNamespace(final x.Element attributeRef) {
    return(_schema.attributeNamespace(attributeRef));
  }
  
  /**
   * Returns the prefix tu use to create an attribute, given the parent element and the attribute reference,
   * or null if no prefix should be used.
   */
  String attributePrefix(final x.Element parent, final x.Element attributeRef) {
    final String espace = attributeNamespace(attributeRef);
    if (espace == null)
      return(null);
    if (espace == "http://www.w3.org/XML/1998/namespace")
      return("xml");
    if (espace == "http://www.w3.org/2000/xmlns/" && attributeName(attributeRef) != "xmlns")
      return("xmlns");
    // on essaye lookupPrefix avec le parent et avec son document
    // (cas d'un élément en cours de création, pas encore inséré dans le document)
    String prefixe = parent.lookupPrefix(espace);
    if (prefixe == null) {
      if (parent.ownerDocument.documentElement != null) // si l'élément racine existe
        prefixe = parent.ownerDocument.lookupPrefix(espace);
      else
        prefixe = namespacePrefix(espace); // on suppose que la racine sera créée avec ajouterAttributsEspaces
    }
    return(prefixe);
  }
  
  /**
   * Returns an attribute namespace based on its full name (including the prefix).
   */
  String attributeNamespaceByName(final String name) {
    return(_schema.attributeNamespaceByName(name));
  }
  
  /**
   * Returns true if the attribute is required for the parent element.
   */
  bool requiredAttribute(final x.Element parentRef, final x.Element attributeRef) {
    return(_schema.attributeIsRequired(parentRef, attributeRef));
  }
  
  /**
   * Returns the list of possible values for an attribute.
   * Returns null if there are an infinity of possible values.
   */
  List<String> attributeValues(final x.Element attributeRef) {
    final List<String> liste = _schema.attributeValues(attributeRef);
    return(liste);
  }
  
  /**
   * Returns an attribute's default value based on its reference.
   */
  String defaultAttributeValue(final x.Element attributeRef) {
    return(_schema.defaultAttributeValue(attributeRef));
  }
  
  /**
   * Returns true if the given String is a valid value for the attribute.
   */
  bool validAttributeValue(final x.Element attributeRef, final String value) {
    return(_schema.attributeIsValid(attributeRef, value));
  }
  
  /**
   * Returns the local part of an element's name (by removing the prefix).
   */
  static String localValue(final String s) {
    if (s == null)
      return(null);
    final int ind = s.indexOf(':');
    if (ind == -1)
      return(s);
    return(s.substring(ind + 1));
  }
  
  
  // METHODS FOR DISPLAY TYPES
  
  /**
   * Returns a node display type based on the element reference, the node name and the DOM node type.
   */
  String nodeDisplayType(final x.Element elementRef, final String name, final int nodeType) {
    if (nodeType == x.Node.ELEMENT_NODE) {
      final x.Element affel = getElementDisplay(localValue(name));
      if (affel == null)
        return(_typeAffichageParDefaut);
      return(affel.getAttribute("type"));
    } else if (nodeType == x.Node.PROCESSING_INSTRUCTION_NODE) {
      x.Element elplug = _findElement(_getNodeDisplay(), "PLUGIN_INSTRUCTION");
      while (elplug != null) {
        if (name != null && name == elplug.getAttribute("cible"))
          return("plugin");
        elplug = _nextElement(elplug, "PLUGIN_INSTRUCTION");
      }
      return("instruction");
    } else if (nodeType == x.Node.COMMENT_NODE) {
      final x.Element elplug = _findElement(_getNodeDisplay(), "PLUGIN_COMMENTAIRE");
      if (elplug != null)
        return("plugin");
      return("commentaire");
    } else if (nodeType == x.Node.CDATA_SECTION_NODE) {
      final x.Element elplug = _findElement(_getNodeDisplay(), "PLUGIN_CDATA");
      if (elplug != null)
        return("plugin");
      return("cdata");
    } else if (nodeType == x.Node.TEXT_NODE) {
      return("texte");
    }
    return(null);
  }

  /**
   * Returns an element display type based on its reference.
   */
  String elementDisplayType(final x.Element elementRef) {
    final x.Element affel = getElementDisplay(elementName(elementRef));
    if (affel == null)
      return(_typeAffichageParDefaut);
    return(affel.getAttribute("type"));
  }
  
  /**
   * Returns the reference of the first element with the given display type in the config file.
   */
  x.Element firstElementWithType(final String displayType) {
    if (_cfgroot == null)
      return(null);
    x.Element affel = _findElement(_getNodeDisplay(), "AFFICHAGE_ELEMENT");
    while (affel != null) {
      if (displayType == affel.getAttribute("type"))
        return(elementReference(affel.getAttribute("element")));
      affel = _nextElement(affel, "AFFICHAGE_ELEMENT");
    }
    return(null);
  }
  
  /**
   * Returns the references of the elements with the given display type in the config file.
   */
  List<x.Element> elementsWithType(final String displayType) {
    if (_cfgroot == null)
      return(null);
    List<x.Element> list = new List<x.Element>();
    x.Element affel = _findElement(_getNodeDisplay(), "AFFICHAGE_ELEMENT");
    while (affel != null) {
      if (displayType == affel.getAttribute("type"))
        list.addAll(elementReferences(affel.getAttribute("element")));
      affel = _nextElement(affel, "AFFICHAGE_ELEMENT");
    }
    return(list);
  }
  
  /**
   * Returns the value of an element display parameter.
   * @param elementRef element reference
   * @param parameterName parameter name
   * @param defaultValue default value, used if the parameter is not found
   */
  String elementParameterValue(final x.Element elementRef, final String parameterName, final String defaultValue) {
    return nodeParameterValue(elementRef, "element", null, parameterName, defaultValue);
  }

  /**
   * Returns the value of a node display parameter.
   * The node type can be used to find display parameters for comments or PIs.
   */
  String nodeParameterValue(final x.Element elementRef, final String nodeType,
                            final String name, final String parameterName, final String defaultValue) {
    final HashMap<String, List<String>> table = getNodeParameters(elementRef, nodeType, name);
    final List<String> lval = table[parameterName];
    String valeur;
    if (lval != null && lval.length > 0)
      valeur = lval[0];
    else
      valeur = defaultValue;
    return valeur;
  }

  /**
   * Returns a function parameter value.
   * @param fctdef Element for the function menu in the config file
   * @param parameterName parameter name
   * @param defaultValue default value, used if the parameter is not found
   */
  String functionParameterValue(final x.Element fctdef, final String parameterName, final String defaultValue) {
    x.Element parel = _findElement(fctdef, "PARAMETRE");
    while (parel != null) {
      final String nom = parel.getAttribute("nom");
      if (nom == parameterName)
        return(parel.getAttribute("valeur"));
      parel = _nextElement(parel, "PARAMETRE");
    }
    return(defaultValue);
  }

  HashMap<String, List<String>> _buildParameterCache(final x.Element base) {
    final HashMap<String, List<String>> hashparams = new HashMap<String, List<String>>();
    x.Element parel = _findElement(base, "PARAMETRE");
    while (parel != null) {
      final String nom = parel.getAttribute("nom");
      final String valeur = parel.getAttribute("valeur");
      List<String> lval = hashparams[nom];
      if (lval == null) {
        lval = new List<String>();
        lval.add(valeur);
        hashparams[nom] = lval;
      } else
        lval.add(valeur);
      parel = _nextElement(parel, "PARAMETRE");
    }
    _parametersCache[base] = hashparams;
    return(hashparams);
  }
  
  /**
   * Returns the table of an element display parameters.
   */
  HashMap<String, List<String>> getElementParameters(final x.Element elementRef) {
    return(getNodeParameters(elementRef, "element", null));
  }
  
  /**
   * Returns the table of a node display parameters.
   * The name can be null if nodeType is "element" and elementRef is not null.
   */
  HashMap<String, List<String>> getNodeParameters(final x.Element elementRef, final String nodeType, final String name) {
    x.Element base;
    if (nodeType == "element")
      base = getElementDisplay(elementName(elementRef));
    else if (nodeType == "instruction") {
      base = null;
      x.Element elplug = _findElement(_getNodeDisplay(), "PLUGIN_INSTRUCTION");
      while (elplug != null) {
        if (name != null && name == elplug.getAttribute("cible")) {
          base = elplug;
          break;
        }
        elplug = _nextElement(elplug, "PLUGIN_INSTRUCTION");
      }
    } else if (nodeType == "commentaire") {
      final x.Element elplug = _findElement(_getNodeDisplay(), "PLUGIN_COMMENTAIRE");
      if (elplug == null) {
        base = null;
      } else {
        base = elplug;
      }
    } else
      base = null;
    if (base == null)
      return(new HashMap<String, List<String>>());
    if (_parametersCache == null)
      _parametersCache = new HashMap<x.Element, HashMap<String, List<String>>>();
    HashMap<String, List<String>> hashparams = _parametersCache[base];
    if (hashparams == null)
      hashparams = _buildParameterCache(base);
    return(hashparams);
  }
  
  /**
   * Returns the list of suggested values for a given element.
   * Returns null if there is no suggestion.
   */
  List<String> elementSuggestedValues(final x.Element elementRef) {
    final Set<String> set = new LinkedHashSet<String>();
    List<String> schemaSuggestions = _schema.suggestedElementValues(elementRef);
    if (schemaSuggestions != null)
      set.addAll(_schema.suggestedElementValues(elementRef));
    final x.Element affel = getElementDisplay(elementName(elementRef));
    if (affel != null) {
      x.Element vs = _findElement(affel, "VALEUR_SUGGEREE");
      while (vs != null) {
        final String v = _dom_elementValue(vs);
        if (v != null)
          set.add(v);
        vs = _nextElement(vs, "VALEUR_SUGGEREE");
      }
    }
    if (set.length == 0)
      return(null);
    else
      return(set.toList());
  }
  
  /**
   * Returns the list of suggested values for an attribute,
   * based on the parent element reference and the attribute reference.
   * Returns null if there is no suggestion.
   */
  List<String> attributeSuggestedValues(final x.Element parentRef, final x.Element attributeRef) {
    final Set<String> set = new LinkedHashSet<String>();
    List<String> schemaSuggestions = _schema.suggestedAttributeValues(attributeRef);
    if (schemaSuggestions != null)
      set.addAll(schemaSuggestions);
    final x.Element affel = getElementDisplay(elementName(parentRef));
    if (affel != null) {
      final String nomAtt = attributeName(attributeRef);
      x.Element aa = _findElement(affel, "AFFICHAGE_ATTRIBUT");
      while (aa != null) {
        if (aa.getAttribute("attribut") == nomAtt) {
          x.Element vs = _findElement(aa, "VALEUR_SUGGEREE");
          while (vs != null) {
            final String v = _dom_elementValue(vs);
            if (v != null)
              set.add(v);
            vs = _nextElement(vs, "VALEUR_SUGGEREE");
          }
        }
        aa = _nextElement(aa, "AFFICHAGE_ATTRIBUT");
      }
    }
    if (set.length == 0)
      return(null);
    else
      return(set.toList());
  }
  
  
  // METHODS FOR THE STRINGS
  
  /**
   * Returns a list of the STRINGS elements in the config file,
   * ordered by preference based on the user language and country.
   */
  List<x.Element> _stringsElements() {
    final Locale defaut = new Locale();
    final List<x.Element> liste = new List<x.Element>();
    
    final List<x.Element> lstrings = _getStrings();
    for (final x.Element strings in lstrings) {
      final String langue = strings.getAttribute("langue");
      if (langue != "") {
        Locale strloc;
        if (strings.getAttribute("pays") == "")
          strloc = new Locale.l(langue);
        else
          strloc = new Locale.lc(langue, strings.getAttribute("pays"));
        if (defaut == strloc && !liste.contains(strings))
          liste.add(strings);
      }
    }
    for (final x.Element strings in lstrings) {
      final String langue = strings.getAttribute("langue");
      if (langue != "") {
        final Locale test = new Locale.lc(defaut.language, defaut.country);
        Locale strloc;
        if (strings.getAttribute("pays") == "")
          strloc = new Locale.l(langue);
        else
          strloc = new Locale.lc(langue, strings.getAttribute("pays"));
        if (test == strloc && !liste.contains(strings))
          liste.add(strings);
      }
    }
    for (final x.Element strings in lstrings) {
      final String langue = strings.getAttribute("langue");
      if (langue != "") {
        final Locale test = new Locale.l(defaut.language);
        if (test == new Locale.l(langue) && !liste.contains(strings))
          liste.add(strings);
      }
    }
    for (final x.Element strings in lstrings) {
      if (!liste.contains(strings))
        liste.add(strings);
    }
    return(liste);
  }
  
  /**
   * Returns the config description (element DESCRIPTION_CONFIG).
   */
  String description() {
    final List<x.Element> lstrings = _stringsElements();
    for (final x.Element strings in lstrings) {
      final x.Element descel = _findElement(strings, "DESCRIPTION_CONFIG");
      if (descel == null || descel.firstChild == null)
        break;
      String desc = _dom_elementValue(descel);
      return(desc);
    }
    return(null);
  }
  
  /**
   * Returns a menu title based on its name
   */
  String menuTitle(final String name) {
    final List<x.Element> lstrings = _stringsElements();
    for (final x.Element strings in lstrings) {
      x.Element sm = _findElementDeep(strings, "STRINGS_MENU");
      while (sm != null) {
        if (name == sm.getAttribute("menu")) {
          final x.Element eltitre = _findElement(sm, "TITRE");
          if (eltitre != null && eltitre.firstChild != null) {
            return(_dom_elementValue(eltitre));
          }
          break;
        }
        sm = _nextElementDeep(strings, sm, "STRINGS_MENU");
      }
    }
    final x.Element refel = elementReference(name);
    if (refel != null)
      return(elementTitle(refel));
    return(name);
  }
  
  /**
   * Returns a menu documentation based on its name.
   */
  String menuDocumentation(final String name) {
    final List<x.Element> lstrings = _stringsElements();
    for (final x.Element strings in lstrings) {
      x.Element sm = _findElementDeep(strings, "STRINGS_MENU");
      while (sm != null) {
        if (name == sm.getAttribute("menu")) {
          final x.Element eldoc = _findElement(sm, "DOCUMENTATION");
          if (eldoc != null && eldoc.firstChild != null) {
            return(_dom_elementValue(eldoc));
          }
          break;
        }
        sm = _nextElementDeep(strings, sm, "STRINGS_MENU");
      }
    }
    return(null);
  }
  
  HashMap<String, String> _titlesHash() {
    HashMap<String, String> h = new HashMap<String, String>();
    final List<x.Element> lstrings = _stringsElements();
    for (final x.Element strings in lstrings) {
      x.Element sel = _findElement(strings, "STRINGS_ELEMENT");
      while (sel != null) {
        String nom = sel.getAttribute("element");
        if (h[nom] == null) {
          String titre = nom;
          final x.Element eltitre = _findElement(sel, "TITRE");
          if (eltitre != null && eltitre.firstChild != null)
            titre = _dom_elementValue(eltitre);
          h[nom] = titre;
        }
        sel = _nextElement(sel, "STRINGS_ELEMENT");
      }
    }
    return(h);
  }
  
  /**
   * Returns an element title based on its reference.
   */
  String elementTitle(final x.Element elementRef) {
    String titre = null;
    titre = _elementsTitlesCache[elementRef];
    if (titre != null)
      return(titre);
    final String nom = elementName(elementRef);
    if (nom == null) {
      logError("Config.elementTitle : no name for $elementRef");
      return(null);
    }
    final List<x.Element> lstrings = _stringsElements();
    for (final x.Element strings in lstrings) {
      if (titre == null) {
        x.Element sel = _findElement(strings, "STRINGS_ELEMENT");
        while (sel != null) {
          if (sel.getAttribute("element") == nom) {
            final x.Element eltitre = _findElement(sel, "TITRE");
            if (eltitre != null && eltitre.firstChild != null) {
              titre = _dom_elementValue(eltitre);
              break;
            }
            break;
          }
          sel = _nextElement(sel, "STRINGS_ELEMENT");
        }
      }
    }
    if (titre == null || titre == "")
      titre = nom;
    _elementsTitlesCache[elementRef] = titre;
    return(titre);
  }
  
  /**
   * Returns an element documentation
   */
  String documentation(final x.Element elementRef) {
    if (elementRef == null)
      return(null);
    final String nom = elementName(elementRef);
    final List<x.Element> lstrings = _stringsElements();
    for (final x.Element strings in lstrings) {
      x.Element sel = _findElement(strings, "STRINGS_ELEMENT");
      while (sel != null) {
        if (nom == sel.getAttribute("element")) {
          final x.Element eldoc = _findElement(sel, "DOCUMENTATION");
          if (eldoc != null && eldoc.firstChild != null)
            return(_dom_elementValue(eldoc));
          break;
        }
        sel = _nextElement(sel, "STRINGS_ELEMENT");
      }
    }
    return(_schema.elementDocumentation(elementRef));
  }
  
  /**
   * Formats the documentation in HTML.
   */
  static String formatDoc(final String documentation) {
    String doc = documentation;
    doc = doc.replaceAll("&", "&amp;");
    doc = doc.replaceAll("<", "&lt;");
    doc = doc.replaceAll(">", "&gt;");
    /*
    if (doc.length > 100) {
      int p = 0;
      for (int i=0; i<doc.length; i++) {
        if (i-p > 90 && doc[i] == ' ') {
          doc = "${doc.substring(0, i)}\n${doc.substring(i+1)}";
          p = i;
        } else if (doc[i] == '\n')
          p = i;
      }
    }
    */
    doc = doc.replaceAll("\n", "<br>");
    return(doc);
  }
  
  /**
   * Returns the title for an element value, based on the element reference and the value.
   */
  String elementValueTitle(final x.Element elementRef, final String value) {
    final String nom = elementName(elementRef);
    final List<x.Element> lstrings = _stringsElements();
    final String langueSyst = (new Locale()).language;
    for (final x.Element strings in lstrings) {
      x.Element sel = _findElement(strings, "STRINGS_ELEMENT");
      while (sel != null) {
        if (sel.getAttribute("element") == nom) {
          x.Element eltitrev = _findElement(sel, "TITRE_VALEUR");
          while (eltitrev != null) {
            if (eltitrev.getAttribute("valeur") == value &&
                eltitrev.firstChild != null)
              return(_dom_elementValue(eltitrev));
            eltitrev = _nextElement(eltitrev, "TITRE_VALEUR");
          }
          break;
        }
        sel = _nextElement(sel, "STRINGS_ELEMENT");
      }
      // la langue est trouvée mais il n'y a pas de TITRE_VALEUR correspondant
      // -> on renvoie la vraie valeur plutôt que de chercher un titre
      // dans d'autres langues.
      final String langue = strings.getAttribute("langue");
      if (langue == langueSyst)
        return(value);
    }
    return(value);
  }
  
  /**
   * Returns an attribute title based on the parent element reference and the attribute reference.
   */
  String attributeTitle(final x.Element parentRef, final x.Element attributeRef) {
    final String nomEl = elementName(parentRef);
    final String nomAtt = attributeName(attributeRef);
    final List<x.Element> lstrings = _stringsElements();
    for (final x.Element strings in lstrings) {
      x.Element sel = _findElement(strings, "STRINGS_ELEMENT");
      while (sel != null) {
        if (sel.getAttribute("element") == nomEl) {
          x.Element sat = _findElement(sel, "STRINGS_ATTRIBUT");
          while (sat != null) {
            if (sat.getAttribute("attribut") == nomAtt) {
              final x.Element eltitre = _findElement(sat, "TITRE");
              if (eltitre != null && eltitre.firstChild != null)
                return(_dom_elementValue(eltitre));
              break;
            }
            sat = _nextElement(sat, "STRINGS_ATTRIBUT");
          }
        }
        sel = _nextElement(sel, "STRINGS_ELEMENT");
      }
    }
    final String prefixe = attributePrefix(parentRef, attributeRef);
    if (prefixe != null)
      return("$prefixe:$nomAtt");
    return(nomAtt);
  }
  
  /**
   * Returns the title for an attribute value, based on the parent element reference,
   * the attribute reference and the value.
   */
  String attributeValueTitle(final x.Element parentRef, final x.Element attributeRef, final String value) {
    final String nomEl = elementName(parentRef);
    final String nomAtt = attributeName(attributeRef);
    final List<x.Element> lstrings = _stringsElements();
    final String langueSyst = (new Locale()).language;
    for (final x.Element strings in lstrings) {
      x.Element sel = _findElement(strings, "STRINGS_ELEMENT");
      while (sel != null) {
        if (sel.getAttribute("element") == nomEl) {
          x.Element sat = _findElement(sel, "STRINGS_ATTRIBUT");
          while (sat != null) {
            if (sat.getAttribute("attribut") == nomAtt) {
              x.Element eltitrev = _findElement(sat, "TITRE_VALEUR");
              while (eltitrev != null) {
                if (eltitrev.getAttribute("valeur") == value &&
                    eltitrev.firstChild != null)
                  return(_dom_elementValue(eltitrev));
                eltitrev = _nextElement(eltitrev, "TITRE_VALEUR");
              }
              break;
            }
            sat = _nextElement(sat, "STRINGS_ATTRIBUT");
          }
        }
        sel = _nextElement(sel, "STRINGS_ELEMENT");
      }
      // la langue est trouvée mais il n'y a pas de TITRE_VALEUR correspondant
      // -> on renvoie la vraie valeur d'attribut plutôt que de chercher un titre
      // dans d'autres langues.
      final String langue = strings.getAttribute("langue");
      if (langue == langueSyst)
        return(value);
    }
    return(value);
  }
  
  /**
   * Returns an attribute's documentation based on the parent element reference and
   * the attribute reference.
   */
  String attributeDocumentation(final x.Element parentRef, final x.Element attributeRef) {
    final String nomEl = elementName(parentRef);
    final String nomAtt = attributeName(attributeRef);
    final List<x.Element> lstrings = _stringsElements();
    for (final x.Element strings in lstrings) {
      x.Element sel = _findElement(strings, "STRINGS_ELEMENT");
      while (sel != null) {
        if (sel.getAttribute("element") == nomEl) {
          x.Element sat = _findElement(sel, "STRINGS_ATTRIBUT");
          while (sat != null) {
            if (sat.getAttribute("attribut") == nomAtt) {
              final x.Element eldoc = _findElement(sat, "DOCUMENTATION");
              if (eldoc != null &&eldoc.firstChild != null)
                return(_dom_elementValue(eldoc));
              break;
            }
            sat = _nextElement(sat, "STRINGS_ATTRIBUT");
          }
        }
        sel = _nextElement(sel, "STRINGS_ELEMENT");
      }
    }
    return(_schema.attributeDocumentation(attributeRef));
  }
  
  /**
   * Returns an export's title based on its reference.
   */
  String exportTitle(final x.Element exportRef) {
    final String nom = exportName(exportRef);
    final List<x.Element> lstrings = _stringsElements();
    for (final x.Element strings in lstrings) {
      x.Element export = _findElement(strings, "STRINGS_EXPORT");
      while (export != null) {
        if (nom == export.getAttribute("export")) {
          final x.Element eltitre = _findElement(export, "TITRE");
          if (eltitre != null && eltitre.firstChild != null)
            return(_dom_elementValue(eltitre));
          break;
        }
        export = _nextElement(export, "STRINGS_EXPORT");
      }
    }
    return(nom);
  }
  
  /**
   * Returns an export's documentation based on its reference.
   */
  String exportDocumentation(final x.Element exportRef) {
    final String nom = exportName(exportRef);
    final List<x.Element> lstrings = _stringsElements();
    for (final x.Element strings in lstrings) {
      x.Element export = _findElement(strings, "STRINGS_EXPORT");
      while (export != null) {
        if (nom == export.getAttribute("export")) {
          final x.Element eldoc = _findElement(export, "DOCUMENTATION");
          if (eldoc != null && eldoc.firstChild != null)
            return(_dom_elementValue(eldoc));
          break;
        }
        export = _nextElement(export, "STRINGS_EXPORT");
      }
    }
    return(null);
  }
  
  
  // TOOLS
  
  /**
   * Returns the value of the first child node, removing leading and trailing whites.
   * Returns null if there is not child node.
   */
  static String _dom_elementValue(final x.Node el) {
    final x.Node fc = el.firstChild;
    if (fc == null)
      return(null);
    final String v = fc.nodeValue;
    if (v == null)
      return(null);
    return(v.trim());
  }
  
  x.Element _getLanguage() {
    if (_languageNode == null) {
      _languageNode = _findElement(_cfgroot, "LANGAGE");
    }
    return _languageNode;
  }

  x.Element _getSaving() {
    if (_savingNode == null) {
      _savingNode = _findElement(_cfgroot, "ENREGISTREMENT");
      if (_savingNode == null) {
        _savingNode = _cfgroot.ownerDocument.createElement("ENREGISTREMENT");
      }
    }
    return _savingNode;
  }

  x.Element _getMenus() {
    if (_menusNode == null) {
      _menusNode = _findElement(_cfgroot, "MENUS");
      if (_menusNode == null) {
        _menusNode = _cfgroot.ownerDocument.createElement("MENUS");
      }
    }
    return _menusNode;
  }

  x.Element _getNodeDisplay() {
    if (_displayNode == null) {
      _displayNode = _findElement(_cfgroot, "AFFICHAGE_NOEUDS");
      if (_displayNode == null) {
        _displayNode = _cfgroot.ownerDocument.createElement("AFFICHAGE_NOEUDS");
      }
    }
    return _displayNode;
  }

  x.Element _getExports() {
    if (_exportsNode == null) {
      _exportsNode = _findElement(_cfgroot, "EXPORTS");
      if (_exportsNode == null) {
        _exportsNode = _cfgroot.ownerDocument.createElement("EXPORTS");
      }
    }
    return _exportsNode;
  }

  List<x.Element> _getStrings() {
    if (_listeStrings == null) {
      _listeStrings = new List<x.Element>();
      x.Node child = _cfgroot.firstChild;
      while (child != null) {
        if (child.nodeType == x.Node.ELEMENT_NODE && child.nodeName == "STRINGS") {
          _listeStrings.add(child as x.Element);
        }
        child = child.nextSibling;
      }
    }
    return _listeStrings;
  }

  
  static x.Element _findElement(final x.Node n, final String name) {
    final x.Node child = n.firstChild;
    return _nextNode(child, name);
  }
  
  static x.Element _nextElement(final x.Node n, final String name) {
    final x.Node child = n.nextSibling;
    return _nextNode(child, name);
  }

  static x.Element _nextNode(x.Node child, final String name) {
    if (name == null)
      return null;
    while (child != null) {
      if (child.nodeType == x.Node.ELEMENT_NODE && name == child.nodeName) {
        return child as x.Element;
      }
      child = child.nextSibling;
    }
    return null;
  }

  static x.Element _findElementDeep(final x.Node n, final String name) {
    return _nextElementDeep(n, n, name);
  }
  
  static x.Element _nextElementDeep(final x.Node parent, final x.Node n, final String name) {
    x.Node current = n;
    x.Node next;
    while (current != null) {
      if (current.hasChildNodes()) {
        current = (current.firstChild);
      } else if (current != parent && null != (next = current.nextSibling)) {
        current = next;
      } else {
        next = null;
        while (current != parent) {

          next = current.nextSibling;
          if (next != null)
            break;
          current = current.parentNode;
        }
        current = next;
      }
      if (current != parent && current != null && current.nodeType == x.Node.ELEMENT_NODE
          && current.nodeName == name) {
        return current as x.Element;
      }
    }
    return null;
  }
  
  static void logError(String message, [Exception ex]) {
    if (ex != null)
      print("Config: $message: $ex");
    else
      print("Config: $message");
  }
}

