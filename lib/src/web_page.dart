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
 * Represents a web page (window or tab). A page can only contain a single document.
 */
class WebPage {
  static const int doubleClickTime = 400; // maximum time between the clicks, in milliseconds
  Cursor _cursor;
  Position selectionStart, selectionEnd;
  MenuBar mbar;
  MenuItem undoMenu, redoMenu;
  Menu contextualMenu;
  h.Point ctxMenuPos;
  Toolbar toolbar;
  LeftPanel _left;
  Position lastClickPosition;
  DateTime lastClickTime;
  bool selectionByWords; // double-click+drag
  
  WebPage() {
    _cursor = new Cursor();
    _left = new LeftPanel();
    lastClickPosition = null;
    lastClickTime = null;
    selectionByWords = false;
  }
  
  Future newDocument(String configPath) {
    Completer completer = new Completer();
    doc.newDocument(configPath).then( (_) {
      _buildMenus();
      init();
      _left.selectInsertPanel();
      h.document.title = Strings.get('page.new_document');
      completer.complete();
    }, onError: (DaxeException ex) {
      h.Element divdoc = h.document.getElementById('doc2');
      String msg = "Error creating the new document: $ex";
      divdoc.text = msg;
      completer.completeError(msg);
    });
    return(completer.future);
  }
  
  Future openDocument(String filePath, String configPath, {bool removeIndents: true}) {
    Completer completer = new Completer();
    doc.openDocument(filePath, configPath).then( (_) {
      _buildMenus();
      init();
      _left.selectTreePanel();
      doc.dndoc.callAfterInsert();
      h.document.title = filePath.split('/').last;
      completer.complete();
    }, onError: (DaxeException ex) {
      h.Element divdoc = h.document.getElementById('doc2');
      String msg = "Error reading the document: $ex";
      divdoc.text = msg;
      completer.completeError(msg);
    });
    return(completer.future);
  }
  
  void init() {
    h.Element divdoc = h.document.getElementById('doc2');
    divdoc.children.clear();
    h.document.body.append(_left.html());
    
    // adjust positions when the toolbar is on more than 1 lines
    // (this cannot be done with CSS)
    adjustPositionsUnderToolbar();
    h.window.onResize.listen((h.Event event) => adjustPositionsUnderToolbar());
    
    // insert document content
    h.Element elhtml = doc.html();
    divdoc.append(elhtml);
    
    Position pos = new Position(doc.dndoc, 0);
    _cursor.moveTo(pos);
    updateAfterPathChange();
    
    divdoc.onMouseDown.listen((h.MouseEvent event) => onMouseDown(event));
    divdoc.onMouseMove.listen((h.MouseEvent event) => onMouseMove(event));
    divdoc.onMouseUp.listen((h.MouseEvent event) => onMouseUp(event));
    divdoc.onContextMenu.listen((h.MouseEvent event) => onContextMenu(event));
    h.document.getElementById('doc1').onScroll.listen((h.Event event) => onScroll(event));
    h.document.onMouseUp.listen((h.MouseEvent event) {
      if (contextualMenu != null) {
        if (event.client != ctxMenuPos)
          closeContextualMenu();
        event.preventDefault();
      }
    });
  }
  
  void adjustPositionsUnderToolbar() {
    h.Element headers = h.document.getElementById('headers');
    num y = headers.getBoundingClientRect().bottom;
    String cssTop = (y.round() + 2).toString() + "px";
    h.document.getElementById('left_panel').style.top = cssTop;
    h.document.getElementById('doc1').style.top = cssTop;
  }
  
  void _buildMenus() {
    mbar = doc.cfg.makeMenus(doc);
    Menu fileMenu = new Menu(Strings.get('menu.file'));
    MenuItem item;
    if (doc.saveURL != null) {
      item = new MenuItem(Strings.get('menu.save'), () => save(), shortcut: 'S');
      fileMenu.add(item);
    }
    item = new MenuItem(Strings.get('menu.source'), () => showSource());
    fileMenu.add(item);
    item = new MenuItem(Strings.get('menu.validation'), () => (new ValidationDialog()).show());
    fileMenu.add(item);
    mbar.insert(fileMenu, 0);
    Menu editMenu = new Menu(Strings.get('menu.edit'));
    undoMenu = new MenuItem(Strings.get('undo.undo'), () => doc.undo(), shortcut: 'Z');
    undoMenu.enabled = false;
    editMenu.add(undoMenu);
    redoMenu = new MenuItem(Strings.get('undo.redo'), () => doc.redo(), shortcut: 'Y');
    redoMenu.enabled = false;
    editMenu.add(redoMenu);
    editMenu.add(new MenuItem(Strings.get('menu.select_all'), () => selectAll(), shortcut: 'A'));
    MenuItem findMenu = new MenuItem(Strings.get('find.find_replace'), () => (new FindDialog()).show(), shortcut: 'F');
    editMenu.add(findMenu);
    mbar.insert(editMenu, 1);
    
    h.Element headers = h.document.getElementById('headers');
    headers.append(mbar.html());
    
    toolbar = new Toolbar(doc.cfg);
    headers.append(toolbar.html());
    HashMap<String, ActionFunction> shortcuts = new HashMap<String, ActionFunction>();
    for (ToolbarButton button in toolbar.buttons)
      if (button.shortcut != null)
        shortcuts[button.shortcut] = button.action;
    
    for (Menu menu in mbar.menus) {
      addMenuShortcuts(menu, shortcuts);
    }
    _cursor.setShortcuts(shortcuts);
  }
  
  addMenuShortcuts(Menu menu, HashMap<String, ActionFunction> shortcuts) {
    for (MenuItem item in menu.items) {
      if (item.shortcut != null && item.action != null)
        shortcuts[item.shortcut] = item.action;
      if (item is Menu)
        addMenuShortcuts(item, shortcuts);
    }
  }
  
  void onMouseDown(h.MouseEvent event) {
    if (contextualMenu != null)
      closeContextualMenu();
    // do not stop event propagation in some cases:
    if (event.target is h.ImageElement ||
        event.target is h.ButtonElement ||
        event.target is h.TextInputElement ||
        event.target is h.SelectElement)
      return;
    h.Element parent = event.target;
    while (parent is h.Element && !parent.classes.contains('dn')) {
      parent = parent.parent;
    }
    if (parent != null && parent.attributes['contenteditable'] == 'true')
      return;
    if (event.button == 1)
      return;
    
    event.preventDefault();
    if (event.button == 2) {
      // this is handled in onContextMenu
      return;
    }
    if (event.shiftKey) {
      selectionStart = new Position.clone(_cursor.selectionStart);
      selectionEnd = Cursor.findPosition(event);
      if (selectionEnd != null)
        _cursor.setSelection(selectionStart, selectionEnd);
    } else {
      selectionStart = Cursor.findPosition(event);
      if (selectionStart != null && lastClickPosition == selectionStart &&
          lastClickTime.difference(new DateTime.now()).inMilliseconds.abs() < doubleClickTime &&
          selectionStart.dn.nodeType != DaxeNode.ELEMENT_NODE) {
        // double click
        List<Position> positions = _extendPositionOnWord(selectionStart);
        selectionStart = positions[0];
        selectionEnd = positions[1];
        _cursor.setSelection(selectionStart, selectionEnd);
        selectionByWords = true;
      }
    }
  }
  
  void onMouseMove(h.MouseEvent event) {
    if (selectionStart == null)
      return;
    if (contextualMenu != null)
      return;
    Position newpos = Cursor.findPosition(event);
    if (selectionByWords) {
      if (selectionEnd > selectionStart && newpos <= selectionStart)
        selectionStart = selectionEnd;
      else if (selectionEnd < selectionStart && newpos >= selectionStart)
        selectionStart = selectionEnd;
    }
    selectionEnd = newpos;
    if (selectionStart != null && selectionEnd != null) {
      if (selectionByWords && selectionEnd.dn.nodeType != DaxeNode.ELEMENT_NODE) {
        List<Position> positions = _extendPositionOnWord(selectionEnd);
        if (selectionEnd > selectionStart)
          selectionEnd = positions[1];
        else
          selectionEnd = positions[0];
      }
      _cursor.setSelection(selectionStart, selectionEnd);
    }
    event.preventDefault();
  }
  
  List<Position> _extendPositionOnWord(Position pos) {
    List<Position> positions = new List<Position>();
    String s = pos.dn.nodeValue;
    int i1 = pos.dnOffset;
    int i2 = pos.dnOffset;
    String wstop = ' \n,;:.?!/()[]{}';
    while (i1 > 0 && wstop.indexOf(s[i1-1]) == -1)
      i1--;
    while (i2 < s.length && wstop.indexOf(s[i2]) == -1)
      i2++;
    positions.add(new Position(pos.dn, i1));
    positions.add(new Position(pos.dn, i2));
    return(positions);
  }
  
  void onMouseUp(h.MouseEvent event) {
    /*
     this interferes with selection, why was it there again ?
     if (event.target is h.ImageElement ||
        event.target is h.ButtonElement ||
        event.target is h.TextInputElement ||
        event.target is h.SelectElement)
      return;
    */
    if (!selectionByWords)
      selectionEnd = Cursor.findPosition(event);
    lastClickPosition = null;
    if (selectionStart != null && selectionEnd != null) {
      if (!selectionByWords)
        _cursor.setSelection(selectionStart, selectionEnd);
      if (selectionStart == selectionEnd) {
        lastClickPosition = selectionStart;
        lastClickTime = new DateTime.now();
      }
    }
    selectionStart = null;
    selectionEnd = null;
    selectionByWords = false;
    event.preventDefault();
  }
  
  void onContextMenu(h.MouseEvent event) {
    if (event.shiftKey)
      return;
    Position newpos = Cursor.findPosition(event);
    if (newpos != null) {
      event.preventDefault();
      if (_cursor.selectionStart == null || _cursor.selectionEnd == null ||
          (newpos < _cursor.selectionStart && newpos < _cursor.selectionEnd) ||
          (newpos > _cursor.selectionStart && newpos > _cursor.selectionEnd)) {
        _cursor.setSelection(newpos, newpos);
      }
      if (_cursor.selectionStart != null)
        showContextualMenu(event);
    }
  }
  
  void onScroll(h.Event event) {
    _cursor.updateCaretPosition(false);
  }
  
  void charInsert(Position pos, String s) {
    doc.insertString(pos, s);
  }
  
  void showContextualMenu(h.MouseEvent event) {
    if (doc.cfg == null || _cursor.selectionStart.dn == null)
      return;
    ctxMenuPos = event.client;
    DaxeNode parent;
    if (_cursor.selectionStart.dn is DNText)
      parent = _cursor.selectionStart.dn.parent;
    else
      parent = _cursor.selectionStart.dn;
    List<x.Element> refs = doc.elementsAllowedUnder(parent);
    List<x.Element> validRefs = doc.validElementsInSelection(refs);
    contextualMenu = new Menu(null);
    bool addSeparator = false;
    if (parent.ref != null) {
      String elementTitle = doc.cfg.menuTitle(parent.nodeName);
      String title = "${Strings.get('contextual.select_element')} $elementTitle";
      contextualMenu.add(new MenuItem(title, () => selectNode(parent)));
      List<x.Element> attRefs = doc.cfg.elementAttributes(parent.ref);
      if (attRefs != null && attRefs.length > 0) {
        title = "${Strings.get('contextual.edit_attributes')} $elementTitle";
        contextualMenu.add(new MenuItem(title, () =>
            parent.attributeDialog()));
      }
      title = "${Strings.get('contextual.help_about_element')} $elementTitle";
      contextualMenu.add(new MenuItem(title, () =>
          (new HelpDialog.Element(parent.ref)).show()));
      addSeparator = true;
    }
    if (doc.hiddendiv != null) {
      DaxeNode dndiv = parent;
      while (dndiv != null && dndiv is! DNHiddenDiv)
        dndiv = dndiv.parent;
      if (dndiv != null) {
        if (addSeparator)
          contextualMenu.addSeparator();
        String elementTitle = doc.cfg.menuTitle(dndiv.nodeName);
        List<x.Element> attRefs = doc.cfg.elementAttributes(dndiv.ref);
        if (attRefs != null && attRefs.length > 0) {
          String title = "${Strings.get('contextual.edit_attributes')} $elementTitle";
          contextualMenu.add(new MenuItem(title, () =>
              dndiv.attributeDialog()));
        }
        contextualMenu.add(new MenuItem(Strings.get('div.remove'), () =>
            (dndiv as DNHiddenDiv).removeDiv()));
        addSeparator = true;
      }
    }
    List<x.Element> toolbarRefs;
    if (toolbar != null)
      toolbarRefs = toolbar.elementRefs();
    else
      toolbarRefs = null;
    bool first = true;
    for (x.Element ref in validRefs) {
      if (toolbarRefs != null && toolbarRefs.contains(ref))
        continue;
      if (doc.hiddenParaRefs != null && doc.hiddenParaRefs.contains(ref))
        continue;
      if (first && addSeparator)
        contextualMenu.addSeparator();
      first = false;
      String name = doc.cfg.elementName(ref);
      String title = doc.cfg.menuTitle(name);
      MenuItem item = new MenuItem(title, () => doc.insertNewNode(ref, 'element'));
      contextualMenu.add(item);
    }
    h.DivElement div = contextualMenu.htmlMenu();
    div.style.position = 'fixed';
    div.style.display = 'block';
    int xpos = event.client.x;
    int ypos = event.client.y;
    div.style.left = "${xpos}px";
    div.style.top = "${ypos}px";
    h.document.body.append(div);
    if (xpos + div.clientWidth > h.window.innerWidth) {
      xpos = h.window.innerWidth - div.clientWidth;
      div.style.left = "${xpos}px";
    }
  }
  
  void closeContextualMenu() {
    h.DivElement div = contextualMenu.getMenuHTMLNode();
    div.remove();
    contextualMenu = null;
    ctxMenuPos = null;
  }
  
  
  /**
   * Returns the Daxe node containing the HTML node
   */
  @deprecated
  DaxeNode getDaxeNode(h.Node n) {
    if (n == null)
      return(null);
    h.Element el;
    if (n.nodeType == DaxeNode.TEXT_NODE)
      el = n.parent;
    else if (n.nodeType == DaxeNode.ELEMENT_NODE)
      el = n;
    else
      return(null);
    DaxeNode jn = doc.getNodeById(el.attributes['id']);
    if (jn == null)
      return(getDaxeNode(el.parent));
    return(jn);
  }
  
  Cursor get cursor {
    return(_cursor);
  }
  
  Position getSelectionStart() {
    return(_cursor.selectionStart);
  }
  
  Position getSelectionEnd() {
    return(_cursor.selectionEnd);
  }
  
  void moveCursorTo(Position pos) {
    _cursor.moveTo(pos);
  }
  
  void focusCursor() {
    _cursor.focus();
  }
  
  void scrollToNode(DaxeNode dn) {
    Position startPos = new Position(dn.parent, dn.parent.offsetOf(dn));
    Point pt = startPos.positionOnScreen();
    if (pt == null)
      return;
    h.DivElement doc1 = h.document.getElementById('doc1'); 
    int doctop = doc1.offset.top;
    doc1.scrollTop += pt.y.toInt() - doctop - 10;
  }
  
  void selectNode(DaxeNode dn) {
    int offset = dn.parent.offsetOf(dn);
    Position p1 = new Position(dn.parent, offset);
    Position p2 = new Position(dn.parent, offset+1);
    _cursor.moveTo(p1); // to scroll
    _cursor.setSelection(p1, p2);
    updateAfterPathChange();
  }
  
  void selectAll() {
    _cursor.setSelection(new Position(doc.dndoc, 0), new Position(doc.dndoc, doc.dndoc.offsetLength));
  }
  
  void updateAfterPathChange() {
    if (_cursor.selectionStart == null)
      return;
    DaxeNode parent = _cursor.selectionStart.dn;
    if (parent is DNText)
      parent = parent.parent;
    List<x.Element> refs = doc.elementsAllowedUnder(parent);
    List<x.Element> validRefs = doc.validElementsInSelection(refs);
    _left.update(parent, refs, validRefs);
    updateMenusAndToolbar(parent, validRefs);
    updatePath();
  }
  
  void updateMenusAndToolbar(DaxeNode parent, List<x.Element> validRefs) {
    List<Menu> menus = mbar.menus;
    for (Menu m in menus) {
      _updateMenu(m, validRefs);
    }
    if (toolbar != null)
      toolbar.update(parent, validRefs);
  }
  
  void _updateMenu(Menu m, List<x.Element> validRefs) {
    for (MenuItem item in m.items) {
      if (item is Menu) {
        _updateMenu(item, validRefs);
      } else if (item.data is x.Element) {
        x.Element ref = item.data;
        String elementName = doc.cfg.elementName(ref);
        bool found = false;
        for (x.Element vref in validRefs) {
          if (doc.cfg.elementName(vref) == elementName) {
            found = true;
            if (vref != ref) {
              // this can happen if 2 different elements have the same name
              item.data = vref;
              item.action = () => doc.insertNewNode(vref, 'element');
            }
            break;
          }
        }
        if (found)
          item.enable();
        else
          item.disable();
        
      }
    }
  }
  
  void updatePath() {
    h.Element div_path = h.document.getElementById('path');
    if (_cursor.selectionStart == null)
      div_path.text = "";
    else
      div_path.text = _cursor.selectionStart.xPath(titles:true);
  }
  
  void updateUndoMenus() {
    if (doc.isUndoPossible()) {
      if (!undoMenu.enabled)
        undoMenu.enable();
    } else {
      if (undoMenu.enabled)
        undoMenu.disable();
    }
    if (doc.isRedoPossible()) {
      if (!redoMenu.enabled)
        redoMenu.enable();
    } else {
      if (redoMenu.enabled)
        redoMenu.disable();
    }
    undoMenu.title = doc.getUndoTitle();
    redoMenu.title = doc.getRedoTitle();
    if (toolbar != null) {
      for (ToolbarButton button in toolbar.buttons) {
        if (button.data == "undo") {
          if (doc.isUndoPossible())
            button.enable();
          else
            button.disable();
          button.title = doc.getUndoTitle();
        } else if (button.data == "redo") {
          if (doc.isRedoPossible())
            button.enable();
          else
            button.disable();
          button.title = doc.getRedoTitle();
        }
      }
    }
  }
  
  void save() {
    doc.saveOnWebJaxe().then((_) {
      h.window.alert(Strings.get('save.success'));
    }, onError: (DaxeException ex) {
      h.window.alert(Strings.get('save.error') + ': ' + ex.message);
    });
  }
  
  void showSource() {
    //String data = encodeUriComponent(doc.toString());
    // encodeUriComponent adds + instead of whitespace
    //data = data.replaceAll('+', '%20');
    //This data URI does not work with IE9
    //h.WindowBase popup = h.window.open('data:text/xml;charset=UTF-8,$data', 'source');
    
    (new SourceWindow()).show();
  }
}
