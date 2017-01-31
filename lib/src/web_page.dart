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
 * [newDocument] or [openDocument] should be called first.
 */
class WebPage {
  /// maximum time between the clicks, in milliseconds
  static const int doubleClickTime = 400;
  Cursor _cursor;
  // initial selection positions (different from the effective selection 
  // positions because selections should be well-formed XML)
  Position _selectionStart, _selectionEnd;
  MenuBar mbar;
  MenuItem _undoMenu, _redoMenu;
  Menu _contextualMenu;
  h.Point _ctxMenuPos;
  Toolbar toolbar;
  LeftPanel _left;
  // for double-click impl
  Position _lastClickPosition;
  DateTime _lastClickTime;
  bool _selectionByWords; // double-click+drag
  /// true for a Desktop application
  bool application;
  /// true if [quit] has been called (used by Desktop application only)
  bool _hasQuit;
  /// optional save function, replacing the default
  ActionFunction saveFunction;
  ActionFunction customizeToolbar;
  bool _inited;
  Timer _scrollDocumentTimer;
  
  /**
   * Creates the web page, using the following optional arguments:
   * 
   * * [application] should be true when Daxe is used as a desktop application.
   * * [left] can be used to extend the [LeftPanel] class.
   * * [saveFunction] can be used to customize saving documents.
   * * [customizeToolbar] can be used to customize the toolbar
   * (it is called after page.toolbar is created but before the HTML is generated).
   */
  WebPage({this.application:false, LeftPanel left, ActionFunction this.saveFunction,
      ActionFunction this.customizeToolbar}) {
    _cursor = new Cursor();
    if (left != null)
      _left = left;
    else
      _left = new LeftPanel();
    _lastClickPosition = null;
    _lastClickTime = null;
    _selectionByWords = false;
    _hasQuit = false;
    _inited = false;
  }
  
  Future newDocument(String configPath) {
    Completer completer = new Completer();
    doc.newDocument(configPath).then( (_) {
      _buildMenus();
      _init();
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
    doc.openDocument(filePath, configPath, removeIndents:removeIndents).then( (_) {
      _buildMenus();
      _init();
      _left.selectTreePanel();
      doc.dndoc.callAfterInsert();
      h.document.title = filePath.split('/').last;
      completer.complete();
    }, onError: (DaxeException ex) {
      h.Element divdoc = h.document.getElementById('doc2');
      String msg = "Error reading the document: $ex";
      divdoc.text = msg;
      completer.completeError(msg);
      if (application)
        quit(async:true, byhand:false);
    });
    return(completer.future);
  }
  
  void _init() {
    h.Element divdoc = h.document.getElementById('doc2');
    divdoc.children.clear();
    if (!_inited) {
      h.document.body.insertBefore(_left.html(), h.document.getElementById('doc1'));
      
      // adjust positions when the toolbar is on more than 1 lines
      // (this cannot be done with CSS)
      adjustPositionsUnderToolbar();
      h.window.onResize.listen((h.Event event) => adjustPositionsUnderToolbar());
    }
    
    // insert document content
    h.Element elhtml = doc.html();
    divdoc.append(elhtml);
    
    Position pos = new Position(doc.dndoc, 0);
    _cursor.moveTo(pos);
    updateAfterPathChange();
    
    if (!_inited) {
      divdoc.onMouseDown.listen((h.MouseEvent event) => _onMouseDown(event));
      divdoc.onMouseMove.listen((h.MouseEvent event) => _onMouseMove(event));
      divdoc.onMouseUp.listen((h.MouseEvent event) => _onMouseUp(event));
      divdoc.onDragEnter.listen((h.MouseEvent event) => _onDragEnter(event));
      divdoc.onDragOver.listen((h.MouseEvent event) => _onDragOver(event));
      divdoc.onDrop.listen((h.MouseEvent event) => _onDrop(event));
      divdoc.onContextMenu.listen((h.MouseEvent event) => _onContextMenu(event));
      h.document.getElementById('doc1').onScroll.listen((h.Event event) => _onScroll(event));
      h.document.onMouseUp.listen((h.MouseEvent event) {
        if (_contextualMenu != null) {
          h.Element div = _contextualMenu.getMenuHTMLNode();
          if (div.scrollHeight > div.clientHeight && event.target == div &&
              event.client.x > div.offsetLeft + div.clientWidth)
            return; // in the scrollbar
          if (event.client != _ctxMenuPos)
            closeContextualMenu();
          event.preventDefault();
        }
      });
      if (doc.saveURL != null) {
        h.window.onBeforeUnload.listen((h.Event e) {
          if (e is h.BeforeUnloadEvent && doc.changed() && !_hasQuit) {
            e.returnValue = Strings.get('save.document_not_saved');
          }
        });
        if (application) {
          h.window.onUnload.listen((h.Event e) {
            if (_hasQuit)
              return null;
            quit(async:false, byhand:false);
          });
        }
      }
      _inited = true;
    }
  }
  
  /**
   * This can be called after a window resize, or after the toolbar
   * has changed.
   */
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
    if (application && doc.saveURL != null) {
      item = new MenuItem(Strings.get('menu.open'), () => open(), shortcut: 'O');
      fileMenu.add(item);
    }
    if (doc.saveURL != null) {
      item = new MenuItem(Strings.get('menu.save'), () => save(), shortcut: 'S');
      fileMenu.add(item);
    }
    item = new MenuItem(Strings.get('menu.source'), () => showSource());
    fileMenu.add(item);
    item = new MenuItem(Strings.get('menu.validation'), () => (new ValidationDialog()).show());
    fileMenu.add(item);
    if (application && doc.saveURL != null) {
      item = new MenuItem(Strings.get('menu.quit'), () => quit(async:true, byhand:true), shortcut: 'Q');
      fileMenu.add(item);
    }
    mbar.insert(fileMenu, 0);
    Menu editMenu = new Menu(Strings.get('menu.edit'));
    _undoMenu = new MenuItem(Strings.get('undo.undo'), () => doc.undo(), shortcut: 'Z');
    _undoMenu.enabled = false;
    editMenu.add(_undoMenu);
    _redoMenu = new MenuItem(Strings.get('undo.redo'), () => doc.redo(), shortcut: 'Y');
    _redoMenu.enabled = false;
    editMenu.add(_redoMenu);
    editMenu.add(new MenuItem.separator());
    MenuItem cutMenu = new MenuItem(Strings.get('menu.cut'), () => cursor.clipboardCut(), shortcut: 'X');
    editMenu.add(cutMenu);
    MenuItem copyMenu = new MenuItem(Strings.get('menu.copy'), () => cursor.clipboardCopy(), shortcut: 'C');
    editMenu.add(copyMenu);
    editMenu.add(new MenuItem.separator());
    editMenu.add(new MenuItem(Strings.get('menu.select_all'), () => selectAll(), shortcut: 'A'));
    MenuItem findMenu = new MenuItem(Strings.get('find.find_replace'), () => (new FindDialog()).show(), shortcut: 'F');
    editMenu.add(findMenu);
    MenuItem findElementMenu = new MenuItem(Strings.get('find.find_element'), () => (new FindElementDialog()).show());
    editMenu.add(findElementMenu);
    mbar.insert(editMenu, 1);
    
    h.Element headers = h.document.getElementById('headers');
    headers.children.clear();
    headers.append(mbar.html());
    
    toolbar = new Toolbar(doc.cfg);
    if (customizeToolbar != null)
      customizeToolbar();
    headers.append(toolbar.html());
    HashMap<String, ActionFunction> shortcuts = new HashMap<String, ActionFunction>();
    for (ToolbarButton button in toolbar.buttons)
      if (button.shortcut != null)
        shortcuts[button.shortcut] = button.action;
    
    for (Menu menu in mbar.menus) {
      _addMenuShortcuts(menu, shortcuts);
    }
    _cursor.setShortcuts(shortcuts);
  }
  
  _addMenuShortcuts(Menu menu, HashMap<String, ActionFunction> shortcuts) {
    for (MenuItem item in menu.items) {
      if (item.shortcut != null && item.action != null)
        shortcuts[item.shortcut] = item.action;
      if (item is Menu)
        _addMenuShortcuts(item, shortcuts);
    }
  }
  
  void _onMouseDown(h.MouseEvent event) {
    if (_contextualMenu != null)
      closeContextualMenu();
    // do not stop event propagation in some cases:
    h.Element target = event.target;
    if (target is h.ImageElement || target is h.ButtonElement ||
        target is h.TextInputElement || target is h.SelectElement ||
        target is h.OptionElement)
      return;
    if (target != null && target.draggable)
      return; // this event might trigger a drag&drop
    h.Element parent = target;
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
      _selectionStart = new Position.clone(_cursor.selectionStart);
      _selectionEnd = Cursor.findPosition(event);
      if (_selectionEnd != null)
        _cursor.setSelection(_selectionStart, _selectionEnd);
    } else {
      _selectionStart = Cursor.findPosition(event);
      if (_selectionStart != null && _lastClickPosition == _selectionStart &&
          _lastClickTime.difference(new DateTime.now()).inMilliseconds.abs() < doubleClickTime &&
          _selectionStart.dn.nodeType != DaxeNode.ELEMENT_NODE) {
        // double click
        if (_selectionStart.dn.parent is! DNAnchor) {
          List<Position> positions = _extendPositionOnWord(_selectionStart);
          _selectionStart = positions[0];
          _selectionEnd = positions[1];
          _cursor.setSelection(_selectionStart, _selectionEnd);
          _selectionByWords = true;
        }
      }
    }
  }
  
  void _onMouseMove(h.MouseEvent event) {
    if (_selectionStart == null)
      return;
    if (_contextualMenu != null)
      return;
    
    // start scrolling if the cursor is near bottom
    h.DivElement doc1 = h.document.getElementById('doc1');
    h.Rectangle docBox = doc1.getBoundingClientRect();
    int y = event.client.y;
    if (y > docBox.bottom - 5 &&
        doc1.scrollTop < doc1.scrollHeight - doc1.offsetHeight) {
      if (_scrollDocumentTimer == null) {
        _scrollDocumentTimer = new Timer.periodic(new Duration(milliseconds:10),
        (Timer timer) {
          if (_selectionStart != null &&
              doc1.scrollTop < doc1.scrollHeight - doc1.offsetHeight) {
            doc1.scrollTop += 3;
          } else {
            _scrollDocumentTimer.cancel();
            _scrollDocumentTimer = null;
          }
        });
      }
      event.preventDefault();
      return;
    } else if (_scrollDocumentTimer != null) {
      _scrollDocumentTimer.cancel();
      _scrollDocumentTimer = null;
    }
    
    Position newpos = Cursor.findPosition(event);
    if (_selectionByWords) {
      if (_selectionEnd > _selectionStart && newpos <= _selectionStart)
        _selectionStart = _selectionEnd;
      else if (_selectionEnd < _selectionStart && newpos >= _selectionStart)
        _selectionStart = _selectionEnd;
    }
    _selectionEnd = newpos;
    if (_selectionStart != null && _selectionEnd != null) {
      if (_selectionByWords && _selectionEnd.dn.nodeType != DaxeNode.ELEMENT_NODE) {
        List<Position> positions = _extendPositionOnWord(_selectionEnd);
        if (_selectionEnd > _selectionStart)
          _selectionEnd = positions[1];
        else
          _selectionEnd = positions[0];
      }
      _cursor.setSelection(_selectionStart, _selectionEnd, updateUI:false);
    }
    event.preventDefault();
  }
  
  List<Position> _extendPositionOnWord(Position pos) {
    List<Position> positions = new List<Position>();
    String s = pos.dn.nodeValue;
    int i1 = pos.dnOffset;
    int i2 = pos.dnOffset;
    if (s != null) {
      String wstop = ' \n,;:.?!/()[]{}';
      while (i1 > 0 && wstop.indexOf(s[i1-1]) == -1)
        i1--;
      while (i2 < s.length && wstop.indexOf(s[i2]) == -1)
        i2++;
    }
    positions.add(new Position(pos.dn, i1));
    positions.add(new Position(pos.dn, i2));
    return(positions);
  }
  
  void _onMouseUp(h.MouseEvent event) {
    /*
     this interferes with selection, why was it there again ?
     if (event.target is h.ImageElement ||
        event.target is h.ButtonElement ||
        event.target is h.TextInputElement ||
        event.target is h.SelectElement)
      return;
    */
    // case of a selected text: mousedown has been ignored because
    // it might be a drag&drop, so we have to set _selectionStart here
    h.Element target = event.target;
    if (target != null && target.classes.contains('selection') &&
        target.draggable && _selectionStart == null) {
      _selectionStart = Cursor.findPosition(event);
    }
    if (!_selectionByWords)
      _selectionEnd = Cursor.findPosition(event);
    _lastClickPosition = null;
    if (_selectionStart != null && _selectionEnd != null) {
      if (!_selectionByWords)
        _cursor.setSelection(_selectionStart, _selectionEnd);
      if (_selectionStart == _selectionEnd) {
        _lastClickPosition = _selectionStart;
        _lastClickTime = new DateTime.now();
      }
    }
    _selectionStart = null;
    _selectionEnd = null;
    _selectionByWords = false;
    event.preventDefault();
  }
  
  /**
   * Cancels the default dragenter to get drag and drop to work.
   */
  void _onDragEnter(h.MouseEvent event) {
    event.preventDefault();
  }
  
  /**
   * Display the cursor to show where the dragged content will be dropped.
   */
  void _onDragOver(h.MouseEvent event) {
    if (event.target is h.TextInputElement)
      return;
    Position pos = Cursor.findPosition(event);
    if (pos == null)
      return;
    
    // If pos is inside a h.TableCellElement but the event x/y is
    // outside the getHTMLContentsNode() parent td, move the Position outside
    // the node (between rows).
    Position tmpPos = pos;
    if (pos.dn is DNText && (pos.dnOffset == 0 || pos.dnOffset == pos.dn.offsetLength)) {
      // move out of text nodes
      DaxeNode dn = pos.dn;
      if (pos.dnOffset == 0)
        tmpPos = new Position(dn.parent, dn.parent.offsetOf(dn));
      else
        tmpPos = new Position(dn.parent, dn.parent.offsetOf(dn) + 1);
    }
    if (tmpPos.dn.getHTMLNode() is h.TableRowElement &&
        (tmpPos.dnOffset == 0 || tmpPos.dnOffset == tmpPos.dn.offsetLength)) {
      h.Element content = tmpPos.dn.getHTMLContentsNode();
      if (content is h.TableCellElement) {
        h.Rectangle rect = content.getBoundingClientRect();
        if (!rect.containsPoint(event.client)) {
          DaxeNode dn = tmpPos.dn;
          if (tmpPos.dnOffset == 0)
            pos = new Position(dn.parent, dn.parent.offsetOf(dn));
          else
            pos = new Position(dn.parent, dn.parent.offsetOf(dn) + 1);
        }
      }
    }
    
    _cursor.setSelection(pos, pos);
    event.preventDefault();
    if (event.ctrlKey || event.dataTransfer.effectAllowed == 'copy')
      event.dataTransfer.dropEffect = 'copy';
    else
      event.dataTransfer.dropEffect = 'move';
  }
  
  void _onDrop(h.MouseEvent event) {
    if (event.target is h.TextInputElement)
      return;
    event.preventDefault();
    Position pos = Cursor.findPosition(event);
    String effect = event.dataTransfer.dropEffect;
    if (effect == 'none') {
      // this is the case with Chrome...
      String allowed = event.dataTransfer.effectAllowed;
      if (allowed == 'copy')
        effect = 'copy';
      else if (allowed == 'move')
        effect = 'move';
      else if (event.ctrlKey)
        effect = 'copy';
      else
        effect = 'move';
    }
    String data = event.dataTransfer.getData('text');
    if (data != null && data != '')
      _cursor.drop(pos, data, effect);
  }
  
  /**
   * Cancels the current mouse selection.
   * This is called by Cursor when a character is typed.
   */
  void stopSelection() {
    _lastClickPosition = null;
    _selectionStart = null;
    _selectionEnd = null;
    _selectionByWords = false;
  }
  
  void _onContextMenu(h.MouseEvent event) {
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
  
  void _onScroll(h.Event event) {
    _cursor.updateCaretPosition(false);
  }
  
  @deprecated
  void charInsert(Position pos, String s) {
    doc.insertString(pos, s);
  }
  
  void showContextualMenu(h.MouseEvent event) {
    if (doc.cfg == null || _cursor.selectionStart.dn == null)
      return;
    _ctxMenuPos = event.client;
    DaxeNode parent;
    if (_cursor.selectionStart.dn is DNText)
      parent = _cursor.selectionStart.dn.parent;
    else
      parent = _cursor.selectionStart.dn;
    List<x.Element> refs = doc.elementsAllowedUnder(parent);
    List<x.Element> validRefs = doc.validElementsInSelection(refs);
    _contextualMenu = new Menu(null);
    bool addSeparator = false;
    if (parent.ref != null) {
      String elementTitle = doc.cfg.menuTitle(parent.nodeName);
      String title = "${Strings.get('contextual.select_element')} $elementTitle";
      _contextualMenu.add(new MenuItem(title, () => selectNode(parent)));
      List<x.Element> attRefs = doc.cfg.elementAttributes(parent.ref);
      if (attRefs != null && attRefs.length > 0) {
        title = "${Strings.get('contextual.edit_attributes')} $elementTitle";
        _contextualMenu.add(new MenuItem(title, () =>
            parent.attributeDialog()));
      }
      title = "${Strings.get('contextual.help_about_element')} $elementTitle";
      _contextualMenu.add(new MenuItem(title, () =>
          (new HelpDialog.Element(parent.ref)).show()));
      title = "${Strings.get('contextual.remove')} $elementTitle";
      _contextualMenu.add(new MenuItem(title, () {
        doc.removeNode(parent);
        page.updateAfterPathChange();
      }));
      addSeparator = true;
    }
    if (doc.hiddendiv != null) {
      DaxeNode dndiv = parent;
      while (dndiv != null && dndiv is! DNHiddenDiv)
        dndiv = dndiv.parent;
      if (dndiv != null) {
        if (addSeparator)
          _contextualMenu.addSeparator();
        String elementTitle = doc.cfg.menuTitle(dndiv.nodeName);
        List<x.Element> attRefs = doc.cfg.elementAttributes(dndiv.ref);
        if (attRefs != null && attRefs.length > 0) {
          String title = "${Strings.get('contextual.edit_attributes')} $elementTitle";
          _contextualMenu.add(new MenuItem(title, () =>
              dndiv.attributeDialog()));
        }
        _contextualMenu.add(new MenuItem(Strings.get('div.remove'), () =>
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
        _contextualMenu.addSeparator();
      first = false;
      String name = doc.cfg.elementName(ref);
      String title = doc.cfg.menuTitle(name);
      MenuItem item = new MenuItem(title, () => doc.insertNewNode(ref, 'element'));
      _contextualMenu.add(item);
    }
    h.DivElement div = _contextualMenu.htmlMenu();
    div.style.position = 'fixed';
    div.style.display = 'block';
    int xpos = event.client.x;
    int ypos = event.client.y;
    div.style.left = "${xpos}px";
    div.style.top = "${ypos}px";
    div.style.maxHeight = "${h.window.innerHeight - ypos}px";
    div.style.overflowY = 'auto';
    h.document.body.append(div);
    if (div.scrollHeight > div.clientHeight)
      div.style.paddingRight = "${div.offsetWidth - div.clientWidth}px"; // for the vertical scrollbar
    if (xpos + div.offsetWidth > h.window.innerWidth) {
      xpos = h.window.innerWidth - div.offsetWidth;
      div.style.left = "${xpos}px";
    }
  }
  
  void closeContextualMenu() {
    h.DivElement div = _contextualMenu.getMenuHTMLNode();
    div.remove();
    _contextualMenu = null;
    _ctxMenuPos = null;
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
      if (!_undoMenu.enabled)
        _undoMenu.enable();
    } else {
      if (_undoMenu.enabled)
        _undoMenu.disable();
    }
    if (doc.isRedoPossible()) {
      if (!_redoMenu.enabled)
        _redoMenu.enable();
    } else {
      if (_redoMenu.enabled)
        _redoMenu.disable();
    }
    _undoMenu.title = doc.getUndoTitle();
    _redoMenu.title = doc.getRedoTitle();
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
  
  /**
   * Used by the Daxe desktop application to display a
   * dialog to open another file.
   */
  void open() {
    Uri htmlUri = Uri.parse(h.window.location.toString());
    Uri docUri = Uri.parse(doc.filePath);
    List<String> segments = new List<String>.from(docUri.pathSegments);
    segments.removeLast();
    Uri openDir = docUri.replace(scheme:htmlUri.scheme, host:htmlUri.host,
        port:htmlUri.port, pathSegments:segments);
    FileChooser dlg;
    ActionFunction action = () {
      openDocument(dlg.getSelectedUri().path, doc.configPath);
    };
    dlg = new FileChooser(openDir, action);
    dlg.show();
  }
  
  /**
   * Calls the custom saveFunction from the constructor if defined or saves the document.
   */
  void save() {
    if (saveFunction != null)
      saveFunction();
    else {
      doc.save().then((_) {
        h.window.alert(Strings.get('save.success'));
      }, onError: (DaxeException ex) {
        h.window.alert(Strings.get('save.error') + ': ' + ex.message);
      });
    }
  }
  
  void showSource() {
    //String data = encodeUriComponent(doc.toString());
    // encodeUriComponent adds + instead of whitespace
    //data = data.replaceAll('+', '%20');
    //This data URI does not work with IE9
    //h.WindowBase popup = h.window.open('data:text/xml;charset=UTF-8,$data', 'source');
    
    (new SourceWindow()).show();
  }
  
  /**
   * Tell the Daxe application server to exit and tell user to close the window.
   */
  void quit({bool async, bool byhand}) {
    h.HttpRequest request = new h.HttpRequest();
    Uri saveUri = Uri.parse(doc.saveURL);
    Uri quitUri = saveUri.replace(path:'/quit');
    request.open('GET', quitUri.toString(), async:async);
    request.onLoad.listen((h.ProgressEvent event) {
      // NOTE: alerts might not display during onunload
      if (request.status != 200) {
        h.window.alert(Strings.get('quit.error') + ': ${request.status}');
        return;
      }
      if (request.responseText != 'ok') {
        h.window.alert(Strings.get('quit.error') + ': ${request.responseText}');
        return;
      }
      //h.window.close(); // This does not work in recent browsers
      // A workaround would be to start a new browser process when opening a file,
      // and kill it (nicely) with the server when the user quits.
      if (byhand)
        h.window.alert(Strings.get('quit.byhand'));
      _hasQuit = true;
    });
    request.onError.listen((h.ProgressEvent event) {
      h.window.alert(Strings.get('quit.error'));
    });
    request.send();
  }
}
