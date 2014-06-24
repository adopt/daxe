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
 * The interface for an XML document.
 */
class DaxeDocument {
  int _id_count = 0;
  Map<String, DaxeNode> _idToJN = new Map<String, DaxeNode>();
  DNDocument dndoc;
  Config cfg;
  List<UndoableEdit> edits = new List<UndoableEdit>();
  int undoPosition = -1;
  String filePath;
  String saveURL;
  
  /**
   * Create a new document with the given configuration path.
   */
  Future newDocument(String configPath) {
    Completer completer = new Completer();
    cfg = new Config();
    cfg.load(configPath).then((_) {
      filePath = null;
      dndoc = new DNDocument();
      List<x.Element> roots = cfg.rootElements();
      if (roots.length == 1) {
        DaxeNode root = NodeFactory.create(roots[0]);
        cfg.addNamespaceAttributes(root);
        dndoc.appendChild(root);
        root.updateValidity();
      }
      completer.complete();
    }, onError: (DaxeException ex) {
      completer.completeError(ex);
    });
    return(completer.future);
  }
  
  /**
   * Open the document at filePath with the given configuration path.
   * If a 404 occurs, create a new document with the config instead
   * (so that it can be saved at the given path)
   */
  Future openDocument(String filePath, String configPath) {
    Completer completer = new Completer();
    cfg = new Config();
    cfg.load(configPath).then((_) {
      this.filePath = filePath;
      x.DOMParser dp = new x.DOMParser();
      dp.parseFromURL(filePath).then((x.Document xmldoc) {
        dndoc = NodeFactory.createFromNode(xmldoc, null);
        completer.complete();
      }, onError: (x.DOMException ex) {
        if (ex.errorCode == 404) {
          dndoc = new DNDocument();
          List<x.Element> roots = cfg.rootElements();
          if (roots.length == 1) {
            DaxeNode root = NodeFactory.create(roots[0]);
            cfg.addNamespaceAttributes(root);
            dndoc.appendChild(root);
            root.updateValidity();
          }
          completer.complete();
        } else
          completer.completeError(new DaxeException("Opening $filePath: $ex"));
      });
    }, onError: (DaxeException ex) {
      completer.completeError(new DaxeException("Reading config $configPath: $ex"));
    });
    return(completer.future);
  }
  
  /**
   * Send the document with a POST request to saveURL.
   */
  Future saveOnWebJaxe() {
    assert(saveURL != null);
    Completer completer = new Completer();
    String bound = 'AaB03x';
    h.HttpRequest request = new h.HttpRequest();
    request.onLoad.listen((h.ProgressEvent event) {
      String response = request.responseText;
      if (response.startsWith('ok'))
        completer.complete();
      else {
        String errorMessage;
        if (response.startsWith('erreur\n'))
          errorMessage = response.substring('erreur\n'.length);
        else
          errorMessage = response;
        completer.completeError(new DaxeException(errorMessage));
      }
    });
    request.onError.listen((h.ProgressEvent event) {
      completer.completeError(new DaxeException(request.status.toString()));
    });
    request.open('POST', saveURL);
    request.setRequestHeader('Content-Type', "multipart/form-data; boundary=$bound");
    
    StringBuffer sb = new StringBuffer();
    sb.write("--$bound\r\n");
    sb.write('Content-Disposition: form-data; name="chemin"\r\n');
    sb.write('Content-type: text/plain; charset=UTF-8\r\n');
    sb.write('Content-transfer-encoding: 8bit\r\n\r\n');
    sb.write(filePath);
    sb.write("\r\n--$bound\r\n");
    sb.write('Content-Disposition: form-data; name="contenu"; filename="$filePath"\r\n');
    sb.write('Content-Type: application/octet-stream\r\n\r\n');
    dndoc.xmlEncoding = 'UTF-8'; // the document is forced to use UTF-8
    sb.write(toString());
    sb.write('\r\n--$bound--\r\n\r\n');
    request.send(sb.toString());
    
    /*
    // to use the document encoding (requires the convert library):
    // (need support for ArrayBuffer in IE, does not work in IE9)
    StringBuffer sb = new StringBuffer();
    sb.write("--$bound\r\n");
    sb.write('Content-Disposition: form-data; name="chemin"\r\n');
    sb.write('Content-type: text/plain; charset=UTF-8\r\n');
    sb.write('Content-transfer-encoding: 8bit\r\n\r\n');
    sb.write(filePath);
    sb.write("\r\n--$bound\r\n");
    sb.write('Content-Disposition: form-data; name="contenu"; filename="$filePath"\r\n');
    sb.write('Content-Type: application/octet-stream\r\n\r\n');
    List<int> buffer = UTF8.encode(sb.toString());
    Encoding encoding = Encoding.getByName(dndoc.xmlEncoding);
    if (encoding == null) {
      print('encoding not supported by Dart: ${dndoc.xmlEncoding} - using UTF-8 instead');
      dndoc.xmlEncoding = 'UTF-8';
      encoding = UTF8;
    }
    buffer.addAll(encoding.encode(toString()));
    buffer.addAll(UTF8.encode('\r\n--$bound--\r\n\r\n'));
    request.send(buffer); // what buffer type can I use here ???
    */
    return(completer.future);
  }
  
  String newId(DaxeNode jn) {
    _id_count++;
    String sid = "a$_id_count";
    _idToJN[sid] = jn;
    return(sid);
  }
  
  DaxeNode getNodeById(String id) {
    if (id == null)
      return(null);
    return(_idToJN[id]);
  }
  
  h.Element html() {
    return(dndoc.html());
  }
  
  DaxeNode getRootElement() {
    for (DaxeNode dn=dndoc.firstChild; dn != null; dn=dn.nextSibling) {
      if (dn.nodeType == DaxeNode.ELEMENT_NODE)
        return(dn);
    }
    return(null);
  }
  
  /**
   * Inserts a new [DaxeNode] at the given [Position].
   * The insert is added to the document history so that it can be undone.
   */
  void insertNode(DaxeNode dn, Position pos) {
    UndoableEdit edit = new UndoableEdit.insertNode(pos, dn);
    doNewEdit(edit);
  }
  
  /**
   * Removes the given [DaxeNode] from the document.
   * The removal is added to the document history so that it can be undone.
   */
  void removeNode(DaxeNode dn) {
    UndoableEdit edit = new UndoableEdit.removeNode(dn);
    doNewEdit(edit);
  }
  
  /**
   * Inserts a String at the given [Position].
   * The insert is added to the document history so that it can be undone.
   */
  void insertString(Position pos, String s) {
    UndoableEdit edit = new UndoableEdit.insertString(pos, s);
    doNewEdit(edit);
  }
  
  /**
   * Removes a String with the given [length] at the given [Position].
   * The removal is added to the document history so that it can be undone.
   */
  void removeString(Position pos, int length) {
    UndoableEdit edit = new UndoableEdit.removeString(pos, length);
    doNewEdit(edit);
  }
  
  /**
   * Removes everything between [start] and [end].
   * The two positions must not cut a node, except for text nodes
   * (all the document elements must be either inside or outside the range).
   * The removal is added to the document history so that it can be undone.
   */
  void removeBetween(Position start, Position end) {
    UndoableEdit edit = removeBetweenEdit(start, end);
    doNewEdit(edit);
  }
  
  /**
   * Returns an edit to Remove everything between [start] and [end].
   * The two positions must not cut a node, except for text nodes
   * (all the document elements must be either inside or outside the range).
   */
  UndoableEdit removeBetweenEdit(Position start, Position end) {
    assert(start < end);
    UndoableEdit edit = new UndoableEdit.compound(Strings.get('undo.remove'));
    if (start.dn == end.dn) {
      DaxeNode dn = start.dn;
      if (dn.nodeType == DaxeNode.TEXT_NODE) {
        edit.addSubEdit(new UndoableEdit.removeString(
            new Position(dn, start.dnOffset),
            end.dnOffset - start.dnOffset));
      } else {
        for (int i = start.dnOffset; i < end.dnOffset; i++) {
          edit.addSubEdit(new UndoableEdit.removeNode(dn.childAtOffset(i)));
        }
      }
    } else {
      // beginning of the selection
      DaxeNode firstNode;
      if (start.dn.nodeType == DaxeNode.ELEMENT_NODE) {
        firstNode = start.dn.childAtOffset(start.dnOffset);
        Position p2 = new Position(start.dn, start.dnOffset + 1);
        if (end >= p2) {
          edit.addSubEdit(new UndoableEdit.removeNode(firstNode));
        }
      } else {
        firstNode = start.dn;
        if (firstNode.offsetLength - start.dnOffset > 0) {
          edit.addSubEdit(new UndoableEdit.removeString(
              new Position(firstNode, start.dnOffset),
              firstNode.offsetLength - start.dnOffset));
        }
      }
      // end of the selection
      // the nodes are removed at the end to avoid text merge problems
      if (end.dn.nodeType == DaxeNode.TEXT_NODE && end.dnOffset > 0) {
        edit.addSubEdit(new UndoableEdit.removeString(
            new Position(end.dn, 0), end.dnOffset));
      }
      // between the first and the end node of the selection
      // text nodes to remove have to be removed before other nodes to avoid being merged
      for (DaxeNode next = firstNode.nextSibling; next != null; next = next.nextSibling) {
        Position p1 = new Position(next.parent, next.parent.offsetOf(next));
        if (p1 < end) {
          if (next.nodeType == DaxeNode.TEXT_NODE &&
              end >= new Position(next.parent, next.parent.offsetOf(next) + 1)) {
            edit.addSubEdit(new UndoableEdit.removeNode(next));
          }
        } else
          break;
      }
      for (DaxeNode next = firstNode.nextSibling; next != null; next = next.nextSibling) {
        Position p1 = new Position(next.parent, next.parent.offsetOf(next));
        if (p1 < end) {
          if (next.nodeType != DaxeNode.TEXT_NODE) {
            edit.addSubEdit(new UndoableEdit.removeNode(next));
          }
        } else
          break;
      }
    }
    return(edit);
  }
  
  /**
   * Returns an edit to insert all the children of [root] at position [pos].
   * Throws a DaxeException on error.
   */
  UndoableEdit insertChildrenEdit(DaxeNode root, Position pos, {bool checkValidity: true}) {
    if (pos.dn is DNText && pos.dnOffset == 0) // this position might move
      pos = new Position(pos.dn.parent, pos.dn.parent.offsetOf(pos.dn));
    DaxeNode parent = pos.dn;
    int offset = pos.dnOffset;
    if (parent is DNText) {
      offset = parent.parent.offsetOf(parent);
      parent = parent.parent;
    }
    UndoableEdit edit = new UndoableEdit.compound('insertChildren');
    // reverse order to always use pos as the insert position
    for (DaxeNode dn in root.childNodes.reversed) {
      if (checkValidity &&
          (parent is DNComment || parent is DNCData || parent is DNProcessingInstruction) &&
          dn is! DNText) {
        String title;
        if (dn.ref == null)
          title = dn.nodeName;
        else
          title = doc.cfg.elementTitle(dn.ref);
        throw new DaxeException(title + ' ' + Strings.get('insert.not_authorized_here'));
      }
      if (dn is DNText || dn is DNCData) {
        if (checkValidity && parent.nodeType == DaxeNode.DOCUMENT_NODE)
          throw new DaxeException(Strings.get('insert.text_not_allowed'));
        String value = null;
        if (dn is DNText)
          value = dn.nodeValue;
        else if (dn.firstChild != null)
          value = dn.firstChild.nodeValue;
        if (value == null)
          value = '';
        if (checkValidity && value.trim() != '' && !doc.cfg.canContainText(parent.ref)) {
          throw new DaxeException(Strings.get('insert.text_not_allowed'));
        }
        if (dn is DNText)
          edit.addSubEdit(new UndoableEdit.insertString(pos, dn.nodeValue));
        else
          edit.addSubEdit(new UndoableEdit.insertNode(pos, dn));
      } else {
        if (checkValidity) {
          if (parent.nodeType == DaxeNode.DOCUMENT_NODE) {
            if (!doc.cfg.rootElements().contains(dn.ref))
              throw new DaxeException(doc.cfg.elementTitle(dn.ref) + ' ' + Strings.get('insert.not_authorized_here'));
          } else if (dn is! DNComment && dn is! DNProcessingInstruction) {
            if (dn.ref == null || !doc.cfg.isSubElement(parent.ref, dn.ref)) {
              String title;
              if (dn.ref == null)
                title = dn.nodeName;
              else
                title = doc.cfg.elementTitle(dn.ref);
              String parentTitle = doc.cfg.elementTitle(parent.ref);
              throw new DaxeException(title + ' ' + Strings.get('insert.not_authorized_inside') + ' ' + parentTitle);
            }
            if (!doc.cfg.insertIsPossible(parent, offset, offset, dn.ref)) {
              throw new DaxeException(doc.cfg.elementTitle(dn.ref) + ' ' + Strings.get('insert.not_authorized_here'));
            }
          }
        }
        edit.addSubEdit(new UndoableEdit.insertNode(pos, dn));
      }
    }
    return(edit);
  }
  
  String toString() {
    return(dndoc.toString());
  }
  
  /**
   * Returns a new DOM document matching this document.
   */
  x.Document toDOMDoc() {
    x.DOMImplementation domimpl = new x.DOMImplementationImpl();
    x.Document domdoc = domimpl.createDocument(null, null, null);
    dndoc.toDOMNode(domdoc);
    return(domdoc);
  }
  
  /**
   * Executes a new edit and adds it to the history so that it can be undone.
   */
  void doNewEdit(UndoableEdit edit) {
    edit.doit();
    if (undoPosition < edits.length - 1)
      edits.removeRange(undoPosition + 1, edits.length);
    if (undoPosition < 0 || !edits[undoPosition].addEdit(edit)) {
      edits.add(edit);
      undoPosition++;
    }
    page.updateUndoMenus();
  }
  
  void undo() {
    if (undoPosition < 0)
      return;
    UndoableEdit edit = edits[undoPosition];
    edit.undo();
    undoPosition--;
    page.updateUndoMenus();
    page.updateAfterPathChange();
  }
  
  void redo() {
    if (undoPosition >= edits.length - 1)
      return;
    UndoableEdit edit = edits[undoPosition + 1];
    edit.doit();
    undoPosition++;
    page.updateUndoMenus();
    page.updateAfterPathChange();
  }
  
  bool isUndoPossible() {
    return(undoPosition >= 0);
  }
  
  bool isRedoPossible() {
    return(undoPosition < edits.length - 1);
  }
  
  /**
   * Returns the title for the undo menu.
   */
  String getUndoTitle() {
    String title;
    if (undoPosition >= 0)
      title = edits[undoPosition].title;
    else
      title = null;
    if (title == null)
      return(Strings.get('undo.undo'));
    else
      return("${Strings.get('undo.undo')} $title");
  }
  
  /**
   * Returns the title for the redo menu.
   */
  String getRedoTitle() {
    String title;
    if (undoPosition < edits.length - 1)
      title = edits[undoPosition + 1].title;
    else
      title = null;
    if (title == null)
      return(Strings.get('undo.redo'));
    else
      return("${Strings.get('undo.redo')} $title");
  }
  
  /**
   * Called when the user tries to insert text.
   * [shift]: true if the shift key was used.
   */
  void insertNewString(String s, bool shift) {
    Position selectionStart = page.getSelectionStart();
    Position selectionEnd = page.getSelectionEnd();
    if (((selectionStart.dn is DNItem) ||
        (selectionStart.dn.nextSibling == null && selectionStart.dn.parent is DNItem)) &&
        selectionStart.dnOffset == selectionStart.dn.offsetLength &&
        s == '\n' && !shift) {
      // \n in an item: adding a new list item
      // TODO: try to move this node-specific code elsewhere
      DNItem item;
      if (selectionStart.dn is DNItem)
        item = selectionStart.dn;
      else
        item = selectionStart.dn.parent;
      DNItem newitem = NodeFactory.create(item.ref);
      doc.insertNode(newitem,
          new Position(item.parent, item.parent.offsetOf(item) + 1));
      page.moveCursorTo(new Position(newitem, 0));
      return;
    }
    bool problem = false;
    if (s.trim() != '') {
      DaxeNode parent = selectionStart.dn;
      if (parent.nodeType == DaxeNode.TEXT_NODE)
        parent = parent.parent;
      if (parent.nodeType == DaxeNode.DOCUMENT_NODE)
        problem = true;
      else if (parent.ref != null && !doc.cfg.canContainText(parent.ref))
        problem = true;
    }
    if (problem) {
      h.window.alert(Strings.get('insert.text_not_allowed'));
      return;
    }
    bool remove = false;
    if (selectionStart != selectionEnd) {
      selectionStart = new Position.clone(selectionStart);
      selectionEnd = new Position.clone(selectionEnd);
      page._cursor.deSelect();
      removeBetween(selectionStart, selectionEnd);
      remove = true;
      //selectionStart.dn.parent is now null if all the text inside an element was removed
      if (selectionStart.dn.parent == null)
        selectionStart = page.getSelectionStart();
    }
    doc.insertString(selectionStart, s);
    if (remove) {
      UndoableEdit edit = new UndoableEdit.compound(Strings.get('undo.insert_text'));
      edit.addSubEdit(edits.removeAt(edits.length - 2));
      edit.addSubEdit(edits.removeLast());
      edits.add(edit);
      undoPosition -= 1;
    }
  }
  
  /**
   * Creates and inserts a new Daxe node at the cursor position, displaying the attribute dialog if
   * it can have attributes.
   * The insert is added to the edits history so that it can be undone.
   */
  void insertNewNode(x.Element ref, String nodeType) {
    Position pos = page.getSelectionStart();
    if (pos == null)
      return;
    DaxeNode seljn = pos.daxeNode;
    DaxeNode dn = NodeFactory.create(ref, nodeType);
    if (nodeType == 'element' && getRootElement() == null) {
      cfg.addNamespaceAttributes(dn);
    }
    if (nodeType == 'element' && doc.cfg.elementAttributes(ref).length > 0)
      dn.attributeDialog(() => insert2(dn, pos));
    else
      insert2(dn, pos);
  }
  
  /**
   * Inserts the [DaxeNode] at the given [Position] following a user action,
   * after the attribute dialog has been validated (if there are attributes).
   * If there is a selection, its contents are moved inside the new element.
   * The whole operation is added to the document history so that it can be undone.
   * This method is called by [insertNewNode].
   */
  void insert2(DaxeNode dn, Position pos) {
    String content = null;
    if (page.getSelectionStart() != page.getSelectionEnd()) {
      content = page._cursor.copy();
      Position selectionStart = page.getSelectionStart();
      Position selectionEnd = page.getSelectionEnd();
      page._cursor.deSelect();
      if (pos.dn is! DNText && pos.dnOffset > 0 &&
          pos.dn.childAtOffset(pos.dnOffset - 1) is DNText) {
        // to prevent a problem if the text to the left of the selection is
        // merged with the text to the right after the removal
        // (pos would be wrong):
        DaxeNode prev = pos.dn.childAtOffset(pos.dnOffset - 1);
        pos = new Position(prev, prev.offsetLength);
      }
      removeBetween(selectionStart, selectionEnd);
      if (pos.dn.parent == null)
        pos = page.getSelectionStart();
    }
    insertNode(dn, pos);
    Position cursorPos = dn.firstCursorPositionInside();
    if (cursorPos != null)
      page.moveCursorTo(cursorPos);
    page.updateAfterPathChange();
    if (content != null) {
      if (!page._cursor.paste(content)) {
        // paste didn't work: undo remove and insert
        undo();
        undo();
        edits.removeRange(edits.length - 2, edits.length);
        page.updateUndoMenus();
      } else {
        // replace the 3 previous edits by a compound
        UndoableEdit edit = new UndoableEdit.compound(Strings.get('undo.insert_element'));
        edit.addSubEdit(edits[edits.length - 3]);
        edit.addSubEdit(edits[edits.length - 2]);
        edit.addSubEdit(edits.last);
        edits.removeRange(edits.length - 3, edits.length);
        edits.add(edit);
        undoPosition -= 2;
        page.updateUndoMenus();
      }
    }
  }
  
  void executeFunction(String functionName, x.Element el) {
    // TODO: pass the parameters in el to the functions
    if (functionName == 'jaxe.FonctionNormal') {
      DNStyle.selectionToNormal();
    } else if (customFunctions[functionName] != null)
      customFunctions[functionName]();
  }
  
  /**
   * Returns the list of element references which can be allowed under a given parent Daxe node.
   * For the document node, returns the list of possible root elements.
   * For a text node, returns the list of elements references allowed under its parent.
   */
  List<x.Element> elementsAllowedUnder(DaxeNode dn) {
    List<x.Element> refs;
    if (dn.nodeType == DaxeNode.DOCUMENT_NODE) {
      refs = doc.cfg.rootElements();
    } else if (dn.ref == null) {
      refs = new List<x.Element>();
    } else {
      DaxeNode parent;
      if (dn.nodeType == DaxeNode.TEXT_NODE)
        parent = dn.parent;
      else
        parent = dn;
      refs = cfg.subElements(parent.ref);
    }
    return(refs);
  }
  
  /**
   * Given a list of element references, returns the elements in this list which can
   * be inserted over the current selection.
   */
  List<x.Element> validElementsInSelection(List<x.Element> allowed) {
    List<x.Element> list = new List<x.Element>();
    Position selectionStart = page.getSelectionStart();
    Position selectionEnd = page.getSelectionEnd();
    DaxeNode startParent = selectionStart.dn;
    int startOffset = selectionStart.dnOffset;
    DaxeNode endParent = selectionEnd.dn;
    int endOffset = selectionEnd.dnOffset;
    if (startParent.nodeType == DaxeNode.TEXT_NODE) {
      startOffset = startParent.parent.offsetOf(startParent);
      startParent = startParent.parent;
    }
    if (endParent.nodeType == DaxeNode.TEXT_NODE) {
      endOffset = endParent.parent.offsetOf(endParent);
      endParent = endParent.parent;
    }
    if (startParent != endParent) // this should not happen
      return(list);
    for (x.Element ref in allowed) {
      if (doc.cfg.insertIsPossible(startParent, startOffset, endOffset, ref))
        list.add(ref);
    }
    return(list);
  }
  
  /**
   * Returns the [Position] matching the given screen coordinates.
   */
  Position findPosition(num x, num y) {
    return(dndoc.findPosition(x, y));
  }
}
