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
  InsertPanel _insertP;
  Cursor _cursor;
  Position selectionStart, selectionEnd;
  MenuBar mbar;
  MenuItem undoMenu, redoMenu;
  Menu contextualMenu;
  Position lastClickPosition;
  DateTime lastClickTime;
  bool selectionByWords; // double-click+drag
  
  WebPage() {
    _insertP = new InsertPanel();
    _cursor = new Cursor();
    lastClickPosition = null;
    lastClickTime = null;
    selectionByWords = false;
  }
  
  void newDocument(String configPath) {
    doc.newDocument(configPath).then( (_) {
      _buildMenus();
      init();
      h.document.title = Strings.get('page.new_document');
    }, onError: (DaxeException ex) {
      h.Element divdoc = h.query("#doc2");
      divdoc.text = "Error creating the new document: $ex";
    });
  }
  
  void openDocument(String filePath, String configPath) {
    doc.openDocument(filePath, configPath).then( (_) {
      _buildMenus();
      init();
      h.document.title = filePath.split('/').last;
    }, onError: (DaxeException ex) {
      h.Element divdoc = h.query("#doc2");
      divdoc.text = "Error reading the document: $ex";
    });
  }
  
  void init() {
    h.Element divdoc = h.query("#doc2");
    divdoc.children.clear();
    h.Element elhtml = doc.html();
    divdoc.append(elhtml);
    
    Position pos = new Position(doc.dndoc, 0);
    _cursor.moveTo(pos);
    updateAfterPathChange();
    
    divdoc.onMouseDown.listen((h.MouseEvent event) => onMouseDown(event));
    divdoc.onMouseMove.listen((h.MouseEvent event) => onMouseMove(event));
    divdoc.onMouseUp.listen((h.MouseEvent event) => onMouseUp(event));
    divdoc.onContextMenu.listen((h.MouseEvent event) => onContextMenu(event));
    h.query("#doc1").onScroll.listen((h.Event event) => onScroll(event));
    h.document.onMouseUp.listen((h.MouseEvent event) {
      if (contextualMenu != null)
        contextualMouseUp(event);
    });
  }
  
  void _buildMenus() {
    mbar = doc.cfg.makeMenus(doc);
    Menu fileMenu = new Menu(Strings.get('menu.file'));
    MenuItem item;
    if (doc.saveURL != null) {
      item = new MenuItem(Strings.get('menu.save'), () => save(), shortcut: 'S');
      fileMenu.add(item);
    }
    //item = new MenuItem(Strings.get('menu.open'), () => openMenu());
    //fileMenu.add(item);
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
    mbar.insert(editMenu, 1);
    h.Element divdoc1 = h.query("#doc1");
    divdoc1.parent.insertBefore(mbar.html(), divdoc1);
    
    HashMap<String, ActionFunction> shortcuts = new HashMap<String, ActionFunction>();
    for (Menu menu in mbar.menus) {
      addShortcuts(menu, shortcuts);
    }
    _cursor.setShortcuts(shortcuts);
  }
  
  addShortcuts(Menu menu, HashMap<String, ActionFunction> shortcuts) {
    for (MenuItem item in menu.items) {
      if (item.shortcut != null && item.action != null)
        shortcuts[item.shortcut] = item.action;
      if (item is Menu)
        addShortcuts(item as Menu, shortcuts);
    }
  }
  
  void onMouseDown(h.MouseEvent event) {
    if (event.target is h.ImageElement ||
        event.target is h.ButtonElement ||
        event.target is h.TextInputElement ||
        event.target is h.SelectElement)
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
    if (event.target is h.ImageElement ||
        event.target is h.ButtonElement ||
        event.target is h.TextInputElement ||
        event.target is h.SelectElement)
      return;
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
    if (doc.cfg == null || _cursor.selectionStart.daxeNode == null)
      return;
    List<x.Element> refs = doc.elementsAllowedUnder(_cursor.selectionStart.daxeNode);
    List<x.Element> validRefs = doc.validElementsInSelection(refs);
    contextualMenu = new Menu(null);
    for (x.Element ref in validRefs) {
      String name = doc.cfg.elementName(ref);
      String title = doc.cfg.menuTitle(name);
      MenuItem item = new MenuItem(title, () => doc.insertNewNode(ref, 'element'));
      contextualMenu.add(item);
    }
    contextualMenu.addSeparator();
    DaxeNode parent;
    if (_cursor.selectionStart.daxeNode is DNText)
      parent = _cursor.selectionStart.daxeNode.parent;
    else
      parent = _cursor.selectionStart.daxeNode;
    String title = doc.cfg.menuTitle(parent.nodeName);
    title = "${Strings.get('contextual.help_about_element')} $title";
    contextualMenu.add(new MenuItem(title, () =>
        (new HelpDialog.Element(parent.ref)).show()));
    h.DivElement div = contextualMenu.html();
    div.style.position = 'fixed';
    div.style.display = 'block';
    div.style.left = "${event.client.x}px";
    div.style.top = "${event.client.y}px";
    h.document.body.append(div);
  }
  
  void contextualMouseUp(h.MouseEvent event) {
    h.DivElement div = contextualMenu.getHTMLNode();
    div.remove();
    contextualMenu = null;
    event.preventDefault();
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
  
  void selectNode(DaxeNode dn) {
    int offset = dn.parent.offsetOf(dn);
    Position p1 = new Position(dn.parent, offset);
    Position p2 = new Position(dn.parent, offset+1);
    _cursor.moveTo(p1); // to scroll
    _cursor.setSelection(p1, p2);
    updateAfterPathChange();
  }
  
  void updateAfterPathChange() {
    updateInsertPanel();
    updateMenus();
    updatePath();
  }
  
  void updateInsertPanel() {
    _insertP.update(_cursor.selectionStart);
  }
  
  void updateMenus() {
    List<x.Element> refs = doc.elementsAllowedUnder(_cursor.selectionStart.dn);
    List<x.Element> validRefs = doc.validElementsInSelection(refs);
    List<Menu> menus = mbar.menus;
    for (Menu m in menus) {
      for (MenuItem item in m.items) {
        if (item.data is x.Element) {
          x.Element ref = item.data;
          if (validRefs.contains(ref))
            item.enable();
          else
            item.disable();
        }
      }
    }
  }
  
  void updatePath() {
    h.Element div_path = h.query("div#path");
    if (_cursor.selectionStart == null)
      div_path.text = "";
    else
      div_path.text = _cursor.selectionStart.xPath();
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
  }
  
  void save() {
    doc.saveOnWebJaxe().then((_) {
      h.window.alert(Strings.get('save.success'));
    }, onError: (DaxeException ex) {
      h.window.alert(Strings.get('save.error') + ': ' + ex.message);
    });
  }
  /*
  void openMenu() {
    
//    FileOpenDialog dlg;
//    dlg = new FileOpenDialog(() {
//      h.File f = dlg.getFile();
//      String configPath = 'config/XPAGES_config.xml'; // for testing
//      String url = h.Url.createObjectUrl(f); // NOT GOOD !
//      // this is not the real URL, but how can we get to it ?
//      // it will require special permissions...
//      openDocument(url, configPath);
//    });
//    dlg.show();
    
    // note: using js.scoped in a packaged app requires the inclusion of
    // packages/js/dart_interop.js in the main html file.
    js.scoped(() {
      var chrome = js.context.chrome;
      //print("chrome = ${chrome.runtime.id}");
      chrome.fileSystem.chooseEntry(js.map({'type': 'openWritableFile'}),
          new js.Callback.once((var fileEntry) {
        // fileEntry.fullPath does not give the real URL, just a temporary path in the (virtual) fileSystem
        // chrome.runtime.getURL(fileEntry.fullPath) return a "chrome-extension://" URL
        // getDisplayPath returns the real path, but it uses ~ shortcuts, making it useless to get the real URL
        // fileEntry.toURL() returns nothing (see https://code.google.com/p/chromium/issues/detail?id=148788 )
        print('fullPath: ' + fileEntry.fullPath);
        print('toURL: ' + fileEntry.toURL());
        
//        var chrome = js.context.chrome;
//        String url = chrome.runtime.getURL(fileEntry.fullPath);
//        print('url:'+url);
        
        
//        var chrome = js.context.chrome;
//        chrome.fileSystem.getDisplayPath(fileEntry, new js.Callback.once((var displayPath) {
//          String configPath = 'config/XPAGES_config.xml'; // for testing
//          print(displayPath);
//        }));
        
      }));
    });
  }
  */
  
  void showSource() {
    //String data = encodeUriComponent(doc.toString());
    // encodeUriComponent adds + instead of whitespace
    //data = data.replaceAll('+', '%20');
    //This data URI does not work with IE9
    //h.WindowBase popup = h.window.open('data:text/xml;charset=UTF-8,$data', 'source');
    
    (new SourceWindow()).show();
  }
}
