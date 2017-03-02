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
 * A Daxe configuration file. Includes many useful methods to use XML schemas.
 */
class Config {
  static final String _defaultDisplayType = "string";
  /// config file root element
  x.Element _cfgroot;
  /// schema file URL
  String schemaURL;
  /// config folder URL (in which the config file must be)
  String _cfgdir;
  /// cache for associations name -> AFFICHAGE_ELEMENT
  HashMap<String, x.Element> _elementDisplayCache;
  /// cache for associations element reference -> name
  HashMap<x.Element, String> _elementsToNamesCache;
  /// cache for associations element reference -> title
  HashMap<x.Element, String> _elementsTitlesCache;
  /// cache for associations menu name -> title
  HashMap<String, String> _menuTitleCache;
  HashMap<x.Element, Pattern> _validPatternCache = null;
  HashMap<x.Element, HashMap<String, List<String>>> _parametersCache = null;
  List<String> _namespaceCache = null; // namespace list
  
  /// all the schema management (validity...)
  InterfaceSchema _schema;
  
  // nodes for the config file main elements
  x.Element _languageNode;
  x.Element _savingNode;
  x.Element _menusNode;
  x.Element _displayNode;
  x.Element _exportsNode;
  List<x.Element> _stringsList;

  
  // CONSTRUCTORS AND INITIALIZATION
  
  /**
   * Constructor (load must be called afterwards)
   */
  Config() {
  }
  
  /**
   * Load a config file
   *
   * [cfgFilePath]:  path to the config file
   */
  Future load(final String cfgFilePath) { // throws DaxeException
    Completer completer = new Completer();
    if (cfgFilePath == null) {
      _cfgroot = null;
      return(new Future.error(new DaxeException("Config.load: null path")));
    }
    
    x.DOMParser dp = new x.DOMParser();
    dp.parseFromURL(cfgFilePath).then((x.Document configdoc) {
      
      _cfgdir = _getParentURL(cfgFilePath);
      
      _cfgroot = configdoc.documentElement;
      
      _buildElementDisplayCache();
      _buildMenuTitleCache();
      
      _elementsTitlesCache = new HashMap<x.Element, String>();
      
      final String names = schemaName();
      if (names == null) {
        final x.Element simple_schema = _findElement(_getLanguage(), "SIMPLE_SCHEMA");
        if (simple_schema == null) {
          completer.completeError(new DaxeException("Error: no XML schema is defined in the config file $cfgFilePath"));
          return;
        }
        _schema = new SimpleSchema(simple_schema, _titlesHash());
        schemaURL = null;
        _buildElementsToNamesCache();
        completer.complete();
        return;
      }
      
      if (_cfgdir != null)
        schemaURL = "${_cfgdir}/$names";
        else
          schemaURL = names;
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
    final x.Element root = _findElement(_getLanguage(), "ROOT");
    if (root == null)
      return(null);
    return(root.getAttribute("element"));
  }
  
  /**
   * Returns the reference to the first possible root element, or null if none are defined.
   */
  x.Element firstRootElement() {
    final String name = nameOfFirstRootElement();
    return(_schema.elementReferenceByName(name));
  }
  
  /**
   * Returns the list of names of the possible root elements
   */
  List<String> listOfRoots() {
    final List<String> list = new List<String>();
    x.Element root = _findElement(_getLanguage(), "ROOT");
    while (root != null) {
      list.add(root.getAttribute("element"));
      root = _nextElement(root, "ROOT");
    }
    return(list);
  }
  
  /**
   * Returns the list of references to the possible root elements
   */
  List<x.Element> rootElements() {
    // To avoid an error when a schema defines a local element with the same
    // name as a root element but with a different type, we have to first get
    // the references of the possible root elements, and then look among them
    // for the ones with the names given in the config.
    final List<x.Element> list = new List<x.Element>();
    final List<x.Element> possibleRoots = _schema.rootElements();
    x.Element root = _findElement(_getLanguage(), "ROOT");
    while (root != null) {
      final String nom = root.getAttribute("element");
      for (final x.Element ref in possibleRoots)
        if (nom == _schema.elementName(ref))
          list.add(ref);
          root = _nextElement(root, "ROOT");
    }
    return(list);
  }
  
  /**
   * Adds the attributes for the namespaces to the root node
   */
  void addNamespaceAttributes(final DaxeNode root) {
    final List<String> namespaces = namespaceList();
    for (final String namespace in namespaces) {
      if (namespace != "") {
        final String prefix = namespacePrefix(namespace);
        String attname;
        if (prefix != null && prefix != "")
          attname = "xmlns:$prefix";
        else
          attname = "xmlns";
        root.setAttributeNS("http://www.w3.org/2000/xmlns/", attname, namespace);
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
   * (SCHEMA_FILE/@name)
   * Returns null if none is defined
   */
  String schemaName() {
    final x.Element schemaFile = _findElement(_getLanguage(), "SCHEMA_FILE");
    if (schemaFile == null)
      return(null);
    String name = schemaFile.getAttribute("name");
    if (name == "")
      name = null;
    return(name);
  }
  
  /**
   * Returns the hash table by name of the element displays in the config file
   * (element AFFICHAGE_ELEMENT)
   */
  HashMap<String, x.Element> _buildElementDisplayCache() {
    _elementDisplayCache = new HashMap<String, x.Element>();
    if (_cfgroot == null)
      return(_elementDisplayCache);
    x.Element elDisplay = _findElement(_getNodeDisplay(), "ELEMENT_DISPLAY");
    while (elDisplay != null) {
      final String name = elDisplay.getAttribute("element");
      _elementDisplayCache[name] = elDisplay;
      elDisplay = _nextElement(elDisplay, "ELEMENT_DISPLAY");
    }
    return(_elementDisplayCache);
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
      final String name = _schema.elementName(ref);
      if (name != null)
        _elementsToNamesCache[ref] = name;
    }
  }
  
  void _buildMenuTitleCache() {
    _menuTitleCache = new HashMap<String, String>();
    final List<x.Element> lstrings = _stringsElements();
    for (final x.Element strings in lstrings) {
      List<x.Node> menuList = strings.getElementsByTagName("MENU_STRINGS");
      for (x.Node smn in menuList) {
        if (smn is! x.Element)
          continue;
        x.Element sm = smn;
        String name = sm.getAttribute("menu");
        if (_menuTitleCache[name] == null) {
          final x.Element eltitle = _findElement(sm, "TITLE");
          if (eltitle != null) {
            String title = _dom_elementValue(eltitle);
            if (title != null && title != '') {
              _menuTitleCache[name] = title;
            }
          }
        }
      }
    }
  }
  
  /**
   * Returns the list of export references, depending on the output (HTML or XML)
   */
  List<x.Element> exportsList(final String output) {
    if (_cfgroot == null)
      return(null);
    final List<x.Element> list = new List<x.Element>();
    x.Element export = _findElement(_getExports(), "EXPORT");
    while (export != null) {
      if (output == export.getAttribute("output"))
        list.add(export);
      export = _nextElement(export, "EXPORT");
    }
    return(list);
  }
  
  /**
   * Returns an export name based on its reference
   */
  String exportName(final x.Element exportRef) {
    return(exportRef.getAttribute("name"));
  }
  
  /**
   * Returns the output of an export based on its reference
   */
  String exportOutput(final x.Element exportRef) {
    return(exportRef.getAttribute("output"));
  }
  
  /**
   * Returns the character encoding to use for new XML documents
   */
  String getEncoding() {
    final x.Element encoding = _findElement(_getSaving(), "ENCODING");
    if (encoding == null)
      return(null);
    return(_dom_elementValue(encoding));
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
    x.Element pe = _findElement(_getSaving(), "NAMESPACE_PREFIX");
    while (pe != null) {
      if (namespace == pe.getAttribute("uri")) {
        String prefix = pe.getAttribute("prefix");
        if (prefix == '')
          prefix = null;
        return(prefix);
      }
      pe = _nextElement(pe, "NAMESPACE_PREFIX");
    }
    return(_schema.namespacePrefix(namespace));
  }
  
  
  // METHODS FOR THE ELEMENT INSERT MENUS
  
  /**
   * Returns a menu matching the menu definition in the config file.
   *
   * [doc]: the Daxe document;
   * [menudef]: the MENU element in the config file.
   */
  Menu _creationMenu(final DaxeDocument doc, final x.Element menudef) {
    final String menuName = menudef.getAttribute("name");
    final Menu menu = new Menu(menuTitle(menuName));
    String docMenu = menuDocumentation(menuName);
    if (docMenu != null) {
      //docMenu = "<html><body>{docMenu.replaceAll('\n', '<br>')}</body></html>";
      menu.toolTipText = docMenu;
    }
    x.Node menuNode = menudef.firstChild;
    while (menuNode != null) {
      MenuItem item = null;
      final String nodename = menuNode.nodeName;
      String shortcut = null;
      if (menuNode is x.Element) {
        final String commande = menuNode.getAttribute("shortcut");
        if (commande != null && commande != "") {
          shortcut = commande.toUpperCase()[0];
        }
      }
      if (nodename == "INSERT_MENU") {
        final x.Element insNode = menuNode as x.Element;
        final String name = insNode.getAttribute("name");
        final String title = menuTitle(name);
        String nodeType = insNode.getAttribute("node_type");
        if (nodeType == "")
          nodeType = "element";
        x.Element refElement;
        if (nodeType == "element") {
          refElement = elementReference(name);
          if (refElement == null)
            logError("Error: MENU_INSERTION: '$name' is not defined in the schema");
        } else
          refElement = null;
        item = new MenuItem(title, () => doc.insertNewNode(refElement, nodeType),
          shortcut: shortcut, data: refElement);
        menu.add(item);
        String itemdoc = documentation(refElement);
        if (itemdoc != null) {
          //itemdoc = formatDoc(itemdoc);
          item.toolTipText = itemdoc;
        }
      } else if (nodename == "FUNCTION_MENU") {
        final x.Element function = menuNode as x.Element;
        final String className = function.getAttribute("function_name");
        final String name = function.getAttribute("name");
        final String title = menuTitle(name);
        item = new MenuItem(title, () => doc.executeFunction(className, function),
          shortcut: shortcut);
        menu.add(item);
        String itemdoc = menuDocumentation(name);
        if (itemdoc != null) {
          //itemdoc = formatDoc(itemdoc);
          item.toolTipText = itemdoc;
        }
      } else if (nodename == "MENU") {
        item = _creationMenu(doc, menuNode as x.Element);
        menu.add(item);
      } else if (nodename == "SEPARATOR")
        menu.addSeparator();
      
      menuNode = menuNode.nextSibling;
    }
    return(menu);
  }
  
  /**
   * Returns a menubar to insert menus.
   */
  MenuBar makeMenus(final DaxeDocument doc) {
    final MenuBar mbar = new MenuBar();
    
    final x.Element menus = _getMenus();
    if (menus != null) {
      x.Element menudef = _findElement(menus, "MENU");
      while (menudef != null) {
        final Menu jmenu = _creationMenu(doc, menudef);
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
    final List<x.Element> list = _schema.allElements();
    return(list);
  }
  
  /**
   * Returns the local name of the element
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
   * Returns the prefix to use for a new element with the given namespace,
   * or null if no prefix should be used.
   * The new node and a parent node can be specified
   * to check for ancestor namespace prefixes.
   */
  String elementPrefix(final String namespace, final DaxeNode dn,
      final DaxeNode parent) {
    if (namespace == null)
      return(null);
    if (dn != null) {
      // check the new node xmlns attributes first
      if (dn.getAttribute('xmlns') == namespace)
        return(null);
      if (dn.attributes != null) {
        for (DaxeAttr att in dn.attributes) {
          if (att.prefix == 'xmlns' && att.value == namespace)
            return(att.localName);
        }
      }
    }
    DaxeNode p = parent;
    while (p != null) {
      // then look for future ancestors
      if (p.namespaceURI == namespace)
        return(p.prefix);
      if (p.attributes != null) {
        for (DaxeAttr att in p.attributes) {
          if (att.prefix == 'xmlns' && att.value == namespace)
            return(att.localName);
        }
      }
      p = p.parent;
    }
    // otherwise look at the config and schema
    return(namespacePrefix(namespace));
  }
  
  /**
   * Returns the list of possible values for an element.
   * Returns null if there are an infinity of possible values.
   */
  List<String> elementValues(final x.Element elementRef) {
    final List<String> list = _schema.elementValues(elementRef);
    return(list);
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
  List<String> namespaceList() {
    if (_namespaceCache != null)
      return(_namespaceCache);
    final List<String> list = new List<String>();
    final List<String> schemaNamespaces = _schema.namespaceList();
    if (schemaNamespaces != null)
      list.addAll(schemaNamespaces);
    _namespaceCache = list;
    return(list);
  }
  
  /**
   * Returns a number for the given namespace, starting from 0.
   * A unique number is given for each namespace.
   * Returns -1 if the namespace is not found in the config.
   */
  int namespaceNumber(final String namespace) {
    final List<String> list = namespaceList();
    return(list.indexOf(namespace));
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
    final List<String> names = subElementsNames(parentRef);
    return(names.contains(childName));
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
    final List<x.Element> refList = subElements(parentRef);
    final List<String> nameList = new List<String>();
    for (final x.Element ref in refList) {
      final String nom = _elementsToNamesCache[ref];
      if (!nameList.contains(nom))
        nameList.add(nom);
    }
    return(nameList);
  }
  
  /**
   * Regular expression for a given element.
   * 
   * [displayMode]: true to get a regular expression to display to the user;
   * [validationMode]: for strict validation instead of checking if an insert is possible.
   */
  String _regularExpression(final x.Element parentRef, final bool displayMode,
      final bool validationMode) {
    return(_schema.regularExpression(parentRef, displayMode, validationMode));
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
        if (dn.isXMLElement())
          return(false);
      }
      return(true);
    }
    assert(parent.isXMLElement());
    if (_schema is SimpleSchema)
      return(true); // for SimpleSchema we assume the test has already been done
    if (startOffset < 0) {
      logError("Config.insertionPossible: debutSelection < parent.debut");
      return(false);
    }
    if (_schema is DaxeWXS) {
      final List<x.Element> childrenRefs = new List<x.Element>();
      bool add = false;
      for (DaxeNode dn = parent.firstChild; dn != null; dn = dn.nextSibling) {
        if (dn.isXMLElement()) {
          int offset = parent.offsetOf(dn);
          if (offset < startOffset || offset >= endOffset) {
            if (!add && offset >= endOffset) {
              childrenRefs.add(toInsert);
              add = true;
            }
            childrenRefs.add(dn.ref);
          }
        }
      }
      if (!add)
        childrenRefs.add(toInsert);
      final bool insertionOK = (_schema as DaxeWXS).validElement(parent.ref, childrenRefs, true);
      return(insertionOK);
    }
    return(false);
/*
    NOTE: it is not possible to test the order in some cases, for instance:
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
    In this case two title elements are allowed under head even though only
    one is normally allowed. On the other hand, we can test parent/child
    relationships, for instance here we check that title is allowed under head.
*/
  }
  
  /**
   * Throws an exception if the parent element is not valid, considering its attributes,
   * its first level children, its node value, and its parent if there is one.
   */
  void testValidity(final DaxeNode parent) {
    if (parent is DNComment || parent is DNProcessingInstruction || parent is DNCData) {
      // these can only contain text DaxeNodes, and no attribute.
      for (DaxeNode dn in parent.childNodes)
        if (dn.nodeType != DaxeNode.TEXT_NODE)
          throw new DaxeException(Strings.get('config.subelement_in_special_node'));
      if (parent.attributes != null && parent.attributes.length > 0)
        throw new DaxeException(Strings.get('config.attribute_in_special_node'));
      return;
    }
    
    if (parent.ref == null)
      throw new DaxeException(Strings.get('config.element_without_reference'));
    
    if (!attributesAreValid(parent))
      throw new DaxeException(Strings.get('config.invalid_attributes'));
    
    if (parent.parent is DNDocument) {
      for (DaxeNode prev=parent.previousSibling; prev!=null; prev=prev.previousSibling) {
        if (prev.isXMLElement())
          throw new DaxeException(Strings.get('config.more_than_one_root'));
      }
    }
    if (parent.parent != null && parent.parent.ref != null && !isSubElement(parent.parent.ref, parent.ref))
      throw new DaxeException(Strings.get('config.not_allowed_inside_parent'));
    
    bool withText = false;
    for (DaxeNode dn = parent.firstChild; dn != null; dn = dn.nextSibling) {
      if (dn.nodeType == DaxeNode.TEXT_NODE) {
        if (dn.nodeValue.trim() != '')
          withText = true;
      } else if (dn is DNCData) {
        if (dn.firstChild != null && dn.firstChild.nodeValue.trim() != '')
          withText = true;
      }
    }
    if (withText && !_schema.canContainText(parent.ref))
      throw new DaxeException(Strings.get('config.text_not_allowed'));
    
    if (parent.firstChild == null && !isElementValueValid(parent.ref, ''))
      throw new DaxeException(Strings.get('config.invalid_value'));
    else if (parent.childNodes.length == 1 && parent.firstChild is DNText && parent.firstChild.nodeValue != null &&
        !isElementValueValid(parent.ref, parent.firstChild.nodeValue))
      throw new DaxeException(Strings.get('config.invalid_value'));
    
    if (_schema is SimpleSchema)
      return; // sub-element test should have been done already
    
    if (_schema is DaxeWXS) {
      final List<x.Element> childrenRefs = new List<x.Element>();
      for (DaxeNode dn = parent.firstChild; dn != null; dn = dn.nextSibling) {
        if (dn.isXMLElement() && dn.ref != null) {
          childrenRefs.add(dn.ref);
        }
      }
      final DaxeWXS sch = _schema as DaxeWXS;
      if (!sch.validElement(parent.ref, childrenRefs, false))
        throw new DaxeException(Strings.get('config.invalid_children'));
      return;
    }
    
    // not a simple or WXS schema: test with a regular expression
    final x.Element refParent = parent.ref;
    final StringBuffer thisregexp = new StringBuffer();
    if (_validPatternCache == null)
      _validPatternCache = new HashMap<x.Element, Pattern>();
    for (DaxeNode dn = parent.firstChild; dn != null; dn = dn.nextSibling) {
      if (dn.isXMLElement())  {
        thisregexp.write(dn.localName);
        thisregexp.write(",");
      }
    }
    RegExp r = _validPatternCache[refParent];
    if (r == null) {
      final String regexp = _regularExpression(refParent, false, true);
      if (regexp == null || regexp == "")
        return;
      try {
        r = new RegExp(r"^$regexp$");
      } on Exception catch(ex) {
        logError("Config.testValidity() - Malformed Pattern: ^${regexp}\$:", ex);
        return;
      }
      _validPatternCache[refParent] = r;
    }

    final bool matched = r.hasMatch(thisregexp.toString());
    if (!matched)
      throw new DaxeException(Strings.get('config.invalid_children'));
    return;
  }
  
  /**
   * Returns true if the parent element is valid, considering its attributes,
   * its first level children, its node value, and its parent if there is one.
   */
  bool elementIsValid(final DaxeNode parent) {
    try {
      testValidity(parent);
    } on DaxeException {
      return false;
    }
    return true;
  }
  
  /**
   * Returns true if the element attributes are valid and if there is not missing required attribute.
   */
  bool attributesAreValid(final DaxeNode dn) {
    if (dn.nodeType != DaxeNode.ELEMENT_NODE) {
      logError("Config.attributesAreValid : this is not an element: $dn");
      return(false);
    }
    // checking attributes defined in the schema
    final List<x.Element> attrefList = elementAttributes(dn.ref);
    List<String> names = new List<String>(attrefList.length);
    List<String> namespaces = new List<String>(names.length);
    for (int i=0; i<attrefList.length; i++) {
      final x.Element attref = attrefList[i];
      names[i] = attributeName(attref);
      namespaces[i] = attributeNamespace(attref);
      final String value = dn.getAttribute(names[i]);
      if (value == null || value == '') {
        if (requiredAttribute(dn.ref, attref))
          return(false);
      } else if (!validAttributeValue(attref, value))
        return(false);
    }
    // checking attributes that are not in the schema
    final List<DaxeAttr> attList = dn.attributes;
    for (int i=0; i<attList.length; i++) {
      DaxeAttr att = attList[i];
      final String prefix = att.prefix;
      if (prefix == "xml" || prefix == "xmlns")
        continue;
      final String name = att.localName;
      if (prefix == null && name == "xmlns")
        continue;
      final String namespace = att.namespaceURI;
      if (namespace == "http://www.w3.org/2001/XMLSchema-instance")
        continue;
      bool found = false;
      for (int j=0; j<names.length; j++) {
        if (names[j] == name && namespaces[j] == namespace) {
          found = true;
          break;
        }
      }
      if (!found)
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
    final List<x.Element> refList = parentElements(elementRef);
    final List<String> nameList = new List<String>();
    for (final x.Element ref in refList) {
      final String name = _elementsToNamesCache[ref];
      if (!nameList.contains(name))
        nameList.add(name);
    }
    return(nameList);
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
   * Returns the attribute reference for a given element reference and
   * attribute local name and namespace.
   */
  x.Element attributeReference(final x.Element elementRef,
      String attributeLocalName, attributeNamespace) {
    List<x.Element> attRefs = _schema.elementAttributes(elementRef);
    for (x.Element attRef in attRefs) {
      if (_schema.attributeName(attRef) == attributeLocalName &&
          _schema.attributeNamespace(attRef) == attributeNamespace)
        return attRef;
    }
    return null;
  }
  
  /**
   * Returns the name of an attribute based on its reference.
   */
  String attributeName(final x.Element attributeRef) {
    return(_schema.attributeName(attributeRef));
  }
  
  /**
   * Returns the qualified name of an attribute based on a Daxe node,
   * the element reference and the attribute reference.
   */
  String attributeQualifiedName(final DaxeNode dn, final x.Element parentRef,
      final x.Element attributeRef) {
    String name = _schema.attributeName(attributeRef);
    String prefix = attributePrefix(dn, attributeRef);
    if (prefix != null)
      name = "$prefix:$name";
    return(name);
  }
  
  /**
   * Returns an attribute namespace based on its reference, or null if none is defined.
   */
  String attributeNamespace(final x.Element attributeRef) {
    return(_schema.attributeNamespace(attributeRef));
  }
  
  /**
   * Returns the prefix to use to create an attribute, given the parent element and the attribute reference,
   * or null if no prefix should be used.
   */
  String attributePrefix(final DaxeNode dn, final x.Element attributeRef) {
    final String namespace = attributeNamespace(attributeRef);
    if (namespace == null)
      return(null);
    if (namespace == "http://www.w3.org/XML/1998/namespace")
      return("xml");
    // NOTE: there is not going to be an attribute reference for xmlns attributes.
    // look first for a prefix based on the Daxe node,
    // then use the config and schema if necessary
    String prefix = null;
    if (dn != null) {
      DaxeNode p = dn;
      while (p != null && prefix == null) {
        if (p.attributes != null) {
          for (DaxeAttr att in p.attributes) {
            if (att.prefix == 'xmlns' && att.value == namespace)
              return(att.localName);
          }
        }
        p = p.parent;
      }
    }
    return(namespacePrefix(namespace));
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
    final List<String> list = _schema.attributeValues(attributeRef);
    return(list);
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
      final x.Element elDisplay = getElementDisplay(localValue(name));
      if (elDisplay == null)
        return(_defaultDisplayType);
      return(elDisplay.getAttribute("type"));
    } else if (nodeType == x.Node.DOCUMENT_NODE) {
      return("xmldocument");
    } else if (nodeType == x.Node.PROCESSING_INSTRUCTION_NODE) {
      return("xmlpi");
    } else if (nodeType == x.Node.COMMENT_NODE) {
      return("xmlcomment");
    } else if (nodeType == x.Node.CDATA_SECTION_NODE) {
      return("xmlcdata");
    } else if (nodeType == x.Node.TEXT_NODE) {
      return("text");
    }
    return(null);
  }

  /**
   * Returns an element display type based on its reference.
   */
  String elementDisplayType(final x.Element elementRef) {
    final x.Element elDisplay = getElementDisplay(elementName(elementRef));
    if (elDisplay == null)
      return(_defaultDisplayType);
    return(elDisplay.getAttribute("type"));
  }
  
  /**
   * Returns the reference of the first element with the given display type in the config file.
   */
  x.Element firstElementWithType(final String displayType) {
    if (_cfgroot == null)
      return(null);
    x.Element elDisplay = _findElement(_getNodeDisplay(), "ELEMENT_DISPLAY");
    while (elDisplay != null) {
      if (displayType == elDisplay.getAttribute("type"))
        return(elementReference(elDisplay.getAttribute("element")));
      elDisplay = _nextElement(elDisplay, "ELEMENT_DISPLAY");
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
    x.Element elDisplay = _findElement(_getNodeDisplay(), "ELEMENT_DISPLAY");
    while (elDisplay != null) {
      if (displayType == elDisplay.getAttribute("type"))
        list.addAll(elementReferences(elDisplay.getAttribute("element")));
      elDisplay = _nextElement(elDisplay, "ELEMENT_DISPLAY");
    }
    return(list);
  }
  
  /**
   * Returns the value of an element display parameter based on the
   * element reference and the parameter name.
   * The default value is returned if the parameter is not found.
   */
  String elementParameterValue(final x.Element elementRef, final String parameterName,
      final String defaultValue) {
    return nodeParameterValue(elementRef, "element", null, parameterName, defaultValue);
  }

  /**
   * Returns the value of a node display parameter.
   * The node type can be used to find display parameters for comments or PIs.
   */
  String nodeParameterValue(final x.Element elementRef, final String nodeType,
                            final String name, final String parameterName, final String defaultValue) {
    final HashMap<String, List<String>> table = getNodeParameters(elementRef, nodeType, name);
    final List<String> valueList = table[parameterName];
    String value;
    if (valueList != null && valueList.length > 0)
      value = valueList[0];
    else
      value = defaultValue;
    return value;
  }

  /**
   * Returns a function parameter value.
   * [fctdef] is the element for the function menu in the config file.
   * [defaultValue] is returned if the parameter is not found.
   */
  String functionParameterValue(final x.Element fctdef, final String parameterName, final String defaultValue) {
    x.Element parel = _findElement(fctdef, "PARAMETER");
    while (parel != null) {
      final String name = parel.getAttribute("name");
      if (name == parameterName)
        return(parel.getAttribute("value"));
      parel = _nextElement(parel, "PARAMETER");
    }
    return(defaultValue);
  }

  HashMap<String, List<String>> _buildParameterCache(final x.Element base) {
    final HashMap<String, List<String>> hashparams = new HashMap<String, List<String>>();
    x.Element parel = _findElement(base, "PARAMETER");
    while (parel != null) {
      final String name = parel.getAttribute("name");
      final String value = parel.getAttribute("value");
      List<String> lval = hashparams[name];
      if (lval == null) {
        lval = new List<String>();
        lval.add(value);
        hashparams[name] = lval;
      } else
        lval.add(value);
      parel = _nextElement(parel, "PARAMETER");
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
    else
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
    final x.Element elDisplay = getElementDisplay(elementName(elementRef));
    if (elDisplay != null) {
      x.Element sv = _findElement(elDisplay, "SUGGESTED_VALUE");
      while (sv != null) {
        final String v = _dom_elementValue(sv);
        if (v != null)
          set.add(v);
        sv = _nextElement(sv, "SUGGESTED_VALUE");
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
    final x.Element elDisplay = getElementDisplay(elementName(parentRef));
    if (elDisplay != null) {
      final String attName = attributeName(attributeRef);
      x.Element attDisplay = _findElement(elDisplay, "ATTRIBUTE_DISPLAY");
      while (attDisplay != null) {
        if (attDisplay.getAttribute("attribute") == attName) {
          x.Element sv = _findElement(attDisplay, "SUGGESTED_VALUE");
          while (sv != null) {
            final String v = _dom_elementValue(sv);
            if (v != null)
              set.add(v);
            sv = _nextElement(sv, "SUGGESTED_VALUE");
          }
        }
        attDisplay = _nextElement(attDisplay, "ATTRIBUTE_DISPLAY");
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
    final Locale defaultLocale = new Locale();
    final List<x.Element> list = new List<x.Element>();
    
    final List<x.Element> lstrings = _getStrings();
    for (final x.Element strings in lstrings) {
      final String language = strings.getAttribute("language");
      if (language != "") {
        Locale strloc;
        if (strings.getAttribute("country") == "")
          strloc = new Locale.l(language);
        else
          strloc = new Locale.lc(language, strings.getAttribute("country"));
        if (defaultLocale == strloc && !list.contains(strings))
          list.add(strings);
      }
    }
    for (final x.Element strings in lstrings) {
      final String language = strings.getAttribute("language");
      if (language != "") {
        final Locale test = new Locale.lc(defaultLocale.language, defaultLocale.country);
        Locale strloc;
        if (strings.getAttribute("country") == "")
          strloc = new Locale.l(language);
        else
          strloc = new Locale.lc(language, strings.getAttribute("country"));
        if (test == strloc && !list.contains(strings))
          list.add(strings);
      }
    }
    for (final x.Element strings in lstrings) {
      final String language = strings.getAttribute("language");
      if (language != "") {
        final Locale test = new Locale.l(defaultLocale.language);
        if (test == new Locale.l(language) && !list.contains(strings))
          list.add(strings);
      }
    }
    for (final x.Element strings in lstrings) {
      if (!list.contains(strings))
        list.add(strings);
    }
    return(list);
  }
  
  /**
   * Returns the config description (element DESCRIPTION_CONFIG).
   */
  String description() {
    final List<x.Element> lstrings = _stringsElements();
    for (final x.Element strings in lstrings) {
      final x.Element descel = _findElement(strings, "CONFIG_DESCRIPTION");
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
    if (_menuTitleCache[name] != null)
      return _menuTitleCache[name];
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
      x.Element sm = _findElementDeep(strings, "MENU_STRINGS");
      while (sm != null) {
        if (name == sm.getAttribute("menu")) {
          final x.Element eldoc = _findElement(sm, "DOCUMENTATION");
          if (eldoc != null && eldoc.firstChild != null) {
            return(_dom_elementValue(eldoc));
          }
          break;
        }
        sm = _nextElementDeep(strings, sm, "MENU_STRINGS");
      }
    }
    return(null);
  }
  
  HashMap<String, String> _titlesHash() {
    HashMap<String, String> h = new HashMap<String, String>();
    final List<x.Element> lstrings = _stringsElements();
    for (final x.Element strings in lstrings) {
      x.Element sel = _findElement(strings, "ELEMENT_STRINGS");
      while (sel != null) {
        String name = sel.getAttribute("element");
        if (h[name] == null) {
          String titre = name;
          final x.Element eltitre = _findElement(sel, "TITLE");
          if (eltitre != null && eltitre.firstChild != null)
            titre = _dom_elementValue(eltitre);
          h[name] = titre;
        }
        sel = _nextElement(sel, "ELEMENT_STRINGS");
      }
    }
    return(h);
  }
  
  /**
   * Returns an element title based on its reference.
   */
  String elementTitle(final x.Element elementRef) {
    String title = null;
    title = _elementsTitlesCache[elementRef];
    if (title != null)
      return(title);
    final String name = elementName(elementRef);
    if (name == null) {
      logError("Config.elementTitle : no name for $elementRef");
      return(null);
    }
    final List<x.Element> lstrings = _stringsElements();
    for (final x.Element strings in lstrings) {
      if (title == null) {
        x.Element sel = _findElement(strings, "ELEMENT_STRINGS");
        while (sel != null) {
          if (sel.getAttribute("element") == name) {
            final x.Element titleel = _findElement(sel, "TITLE");
            if (titleel != null && titleel.firstChild != null) {
              title = _dom_elementValue(titleel);
              break;
            }
            break;
          }
          sel = _nextElement(sel, "ELEMENT_STRINGS");
        }
      }
    }
    if (title == null || title == "")
      title = name;
    _elementsTitlesCache[elementRef] = title;
    return(title);
  }
  
  /**
   * Returns an element documentation
   */
  String documentation(final x.Element elementRef) {
    if (elementRef == null)
      return(null);
    final String name = elementName(elementRef);
    final List<x.Element> lstrings = _stringsElements();
    for (final x.Element strings in lstrings) {
      x.Element sel = _findElement(strings, "ELEMENT_STRINGS");
      while (sel != null) {
        if (name == sel.getAttribute("element")) {
          final x.Element eldoc = _findElement(sel, "DOCUMENTATION");
          if (eldoc != null && eldoc.firstChild != null)
            return(_dom_elementValue(eldoc));
          break;
        }
        sel = _nextElement(sel, "ELEMENT_STRINGS");
      }
    }
    String schemaDoc = _schema.elementDocumentation(elementRef);
    if (schemaDoc != null)
      schemaDoc = schemaDoc.trim();
    return(schemaDoc);
  }
  
  /**
   * Formats the documentation in HTML.
   */
  static String formatDoc(final String documentation) {
    String doc = documentation.trim();
    doc = doc.replaceAll("&", "&amp;");
    doc = doc.replaceAll("<", "&lt;");
    doc = doc.replaceAll(">", "&gt;");
    /* NOTE: adding newlines could be useful if we used <pre>
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
    final String name = elementName(elementRef);
    final List<x.Element> lstrings = _stringsElements();
    final String osLanguage = (new Locale()).language;
    for (final x.Element strings in lstrings) {
      x.Element sel = _findElement(strings, "ELEMENT_STRINGS");
      while (sel != null) {
        if (sel.getAttribute("element") == name) {
          x.Element tvel = _findElement(sel, "VALUE_TITLE");
          while (tvel != null) {
            if (tvel.getAttribute("value") == value &&
                tvel.firstChild != null)
              return(_dom_elementValue(tvel));
            tvel = _nextElement(tvel, "VALUE_TITLE");
          }
          break;
        }
        sel = _nextElement(sel, "ELEMENT_STRINGS");
      }
      // the language was found but there is no matching TITRE_VALEUR
      // -> we return the real value rather than looking
      // for a title in other languages.
      final String language = strings.getAttribute("language");
      if (language == osLanguage)
        return(value);
    }
    return(value);
  }
  
  /**
   * Returns an attribute title based on an optional Daxe node, the parent element reference
   * and the attribute reference.
   */
  String attributeTitle(final DaxeNode dn, final x.Element parentRef, final x.Element attributeRef) {
    final String elName = elementName(parentRef);
    final String attName = attributeName(attributeRef);
    final List<x.Element> lstrings = _stringsElements();
    for (final x.Element strings in lstrings) {
      x.Element sel = _findElement(strings, "ELEMENT_STRINGS");
      while (sel != null) {
        if (sel.getAttribute("element") == elName) {
          x.Element sat = _findElement(sel, "ATTRIBUTE_STRINGS");
          while (sat != null) {
            if (sat.getAttribute("attribute") == attName) {
              final x.Element eltitre = _findElement(sat, "TITLE");
              if (eltitre != null && eltitre.firstChild != null)
                return(_dom_elementValue(eltitre));
              break;
            }
            sat = _nextElement(sat, "ATTRIBUTE_STRINGS");
          }
        }
        sel = _nextElement(sel, "ELEMENT_STRINGS");
      }
    }
    final String prefix = attributePrefix(dn, attributeRef);
    if (prefix != null)
      return("$prefix:$attName");
    return(attName);
  }
  
  /**
   * Returns the title for an attribute value, based on the parent element reference,
   * the attribute reference and the value.
   */
  String attributeValueTitle(final x.Element parentRef, final x.Element attributeRef, final String value) {
    final String elName = elementName(parentRef);
    final String attName = attributeName(attributeRef);
    final List<x.Element> lstrings = _stringsElements();
    final String osLanguage = (new Locale()).language;
    for (final x.Element strings in lstrings) {
      x.Element sel = _findElement(strings, "ELEMENT_STRINGS");
      while (sel != null) {
        if (sel.getAttribute("element") == elName) {
          x.Element sat = _findElement(sel, "ATTRIBUTE_STRINGS");
          while (sat != null) {
            if (sat.getAttribute("attribute") == attName) {
              x.Element eltitrev = _findElement(sat, "VALUE_TITLE");
              while (eltitrev != null) {
                if (eltitrev.getAttribute("value") == value &&
                    eltitrev.firstChild != null)
                  return(_dom_elementValue(eltitrev));
                eltitrev = _nextElement(eltitrev, "VALUE_TITLE");
              }
              break;
            }
            sat = _nextElement(sat, "ATTRIBUTE_STRINGS");
          }
        }
        sel = _nextElement(sel, "ELEMENT_STRINGS");
      }
      // The language was found but there is no matching TITRE_VALEUR
      // -> we return the real attribute value rather than looking
      // for a title in other languages.
      final String language = strings.getAttribute("language");
      if (language == osLanguage)
        return(value);
    }
    return(value);
  }
  
  /**
   * Returns an attribute's documentation based on the parent element reference and
   * the attribute reference.
   */
  String attributeDocumentation(final x.Element parentRef, final x.Element attributeRef) {
    final String elName = elementName(parentRef);
    final String attName = attributeName(attributeRef);
    final List<x.Element> lstrings = _stringsElements();
    for (final x.Element strings in lstrings) {
      x.Element sel = _findElement(strings, "ELEMENT_STRINGS");
      while (sel != null) {
        if (sel.getAttribute("element") == elName) {
          x.Element sat = _findElement(sel, "ATTRIBUTE_STRINGS");
          while (sat != null) {
            if (sat.getAttribute("attribute") == attName) {
              final x.Element eldoc = _findElement(sat, "DOCUMENTATION");
              if (eldoc != null &&eldoc.firstChild != null)
                return(_dom_elementValue(eldoc));
              break;
            }
            sat = _nextElement(sat, "ATTRIBUTE_STRINGS");
          }
        }
        sel = _nextElement(sel, "ELEMENT_STRINGS");
      }
    }
    String schemaDoc = _schema.attributeDocumentation(attributeRef);
    if (schemaDoc != null)
      schemaDoc = schemaDoc.trim();
    return(schemaDoc);
  }
  
  /**
   * Returns an export's title based on its reference.
   */
  String exportTitle(final x.Element exportRef) {
    final String name = exportName(exportRef);
    final List<x.Element> lstrings = _stringsElements();
    for (final x.Element strings in lstrings) {
      x.Element export = _findElement(strings, "STRINGS_EXPORT");
      while (export != null) {
        if (name == export.getAttribute("export")) {
          final x.Element titleel = _findElement(export, "TITLE");
          if (titleel != null && titleel.firstChild != null)
            return(_dom_elementValue(titleel));
          break;
        }
        export = _nextElement(export, "STRINGS_EXPORT");
      }
    }
    return(name);
  }
  
  /**
   * Returns an export's documentation based on its reference.
   */
  String exportDocumentation(final x.Element exportRef) {
    final String name = exportName(exportRef);
    final List<x.Element> lstrings = _stringsElements();
    for (final x.Element strings in lstrings) {
      x.Element export = _findElement(strings, "STRINGS_EXPORT");
      while (export != null) {
        if (name == export.getAttribute("export")) {
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
      _languageNode = _findElement(_cfgroot, "LANGUAGE");
    }
    return _languageNode;
  }

  x.Element _getSaving() {
    if (_savingNode == null) {
      _savingNode = _findElement(_cfgroot, "SAVING");
      if (_savingNode == null) {
        _savingNode = _cfgroot.ownerDocument.createElement("SAVING");
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
      _displayNode = _findElement(_cfgroot, "ELEMENTS_DISPLAY");
      if (_displayNode == null) {
        _displayNode = _cfgroot.ownerDocument.createElement("ELEMENTS_DISPLAY");
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
    if (_stringsList == null) {
      _stringsList = new List<x.Element>();
      x.Node child = _cfgroot.firstChild;
      while (child != null) {
        if (child.nodeType == x.Node.ELEMENT_NODE && child.nodeName == "STRINGS") {
          _stringsList.add(child as x.Element);
        }
        child = child.nextSibling;
      }
    }
    return _stringsList;
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
