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
  DaxeNode dndoc;
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
    sb.write(toString());
    sb.write('\r\n--$bound--\r\n\r\n');
    request.send(sb.toString());
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
  
  void insertNode(DaxeNode dn, Position pos) {
    UndoableEdit edit = new UndoableEdit.insertNode(pos, dn);
    doNewEdit(edit);
  }
  
  void removeNode(DaxeNode dn) {
    UndoableEdit edit = new UndoableEdit.removeNode(dn);
    doNewEdit(edit);
  }
  
  void insertString(Position pos, String s) {
    UndoableEdit edit = new UndoableEdit.insertString(pos, s);
    doNewEdit(edit);
  }
  
  void removeString(Position pos, int length) {
    UndoableEdit edit = new UndoableEdit.removeString(pos, length);
    doNewEdit(edit);
  }
  
  void removeBetween(Position start, Position end) {
    UndoableEdit edit = new UndoableEdit.compound(Strings.get('undo.remove'));
    assert(start < end);
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
    doNewEdit(edit);
  }
  
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('<?xml version="1.0" encoding="UTF-8"?>\n');
    sb.write(dndoc.toString());
    return(sb.toString());
  }
  
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
  
  void insertNewNode(x.Element ref, String nodeType, [bool checkValidity=false]) {
    Position pos = page.getSelectionStart();
    if (pos == null)
      return;
    if (checkValidity) {
      Position selectionStart = page.getSelectionStart();
      Position selectionEnd = page.getSelectionEnd();
      if (selectionStart.dn != selectionEnd.dn)
        return;
      DaxeNode parent = pos.dn;
      int startOffset = selectionStart.dnOffset;
      int endOffset = selectionEnd.dnOffset;
      if (parent is DNText) {
        startOffset = parent.parent.offsetOf(parent);
        endOffset = startOffset;
        // FIXME: if selectionStart.dnOffset != selectionEnd.dnOffset,
        // we should check that the parent can have text
        parent = parent.parent;
      }
      if (!doc.cfg.insertIsPossible(parent, startOffset, endOffset, ref)) {
        h.window.alert(doc.cfg.elementTitle(ref) + ' ' + Strings.get('insert.not_authorized_here'));
        return;
      }
    }
    DaxeNode seljn = pos.daxeNode;
    DaxeNode dn = NodeFactory.create(ref, nodeType);
    if (nodeType == 'element' && doc.cfg.elementAttributes(ref).length > 0)
      dn.attributeDialog(() => insert2(dn, pos));
    else
      insert2(dn, pos);
  }
  
  void insert2(DaxeNode dn, Position pos) {
    //TODO: use UndoableEdit.compound to include all the operations here (removal/insert/paste)
    String content = null;
    if (page.getSelectionStart() != page.getSelectionEnd()) {
      content = page._cursor.copy();
      Position selectionStart = page.getSelectionStart();
      Position selectionEnd = page.getSelectionEnd();
      page._cursor.deSelect();
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
        undo();
        undo();
      }
    }
  }
  
  void executeFunction(String className, x.Element el) {
    // TODO
  }
  
  List<x.Element> elementsAllowedUnder(DaxeNode dn) {
    List<x.Element> refs;
    if (dn.nodeType == DaxeNode.DOCUMENT_NODE) {
      refs = doc.cfg.rootElements();
    } else if (dn.nodeType == DaxeNode.COMMENT_NODE) {
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
  
  Position findPosition(num x, num y) {
    return(dndoc.findPosition(x, y));
  }
}
