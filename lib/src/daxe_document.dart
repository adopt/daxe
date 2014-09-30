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
  List<x.Element> hiddenParaRefs; /* references for hidden paragraphs */
  x.Element hiddendiv;
  
  /**
   * Create a new document with the given configuration path.
   */
  Future newDocument(String configPath) {
    Completer completer = new Completer();
    cfg = new Config();
    cfg.load(configPath).then((_) {
      hiddenParaRefs = cfg.elementsWithType('hiddenp');
      if (hiddenParaRefs.length == 0)
        hiddenParaRefs = null;
      hiddendiv = cfg.firstElementWithType('hiddendiv');
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
  Future openDocument(String filePath, String configPath, {bool removeIndents: true}) {
    Completer completer = new Completer();
    cfg = new Config();
    cfg.load(configPath).then((_) {
      hiddenParaRefs = cfg.elementsWithType('hiddenp');
      if (hiddenParaRefs.length == 0)
        hiddenParaRefs = null;
      hiddendiv = cfg.firstElementWithType('hiddendiv');
      this.filePath = filePath;
      x.DOMParser dp = new x.DOMParser();
      dp.parseFromURL(filePath).then((x.Document xmldoc) {
        if (removeIndents)
          removeWhitespace(xmldoc.documentElement);
        dndoc = NodeFactory.createFromNode(xmldoc, null);
        if (cfg != null && hiddenParaRefs != null)
          removeWhitespaceForHiddenParagraphs(dndoc);
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
        // text nodes have to be removed first to avoid text merging problems
        for (int i = start.dnOffset; i < end.dnOffset; i++) {
          if (dn.childAtOffset(i) is DNText)
            edit.addSubEdit(new UndoableEdit.removeNode(dn.childAtOffset(i)));
        }
        for (int i = start.dnOffset; i < end.dnOffset; i++) {
          if (dn.childAtOffset(i) is! DNText)
            edit.addSubEdit(new UndoableEdit.removeNode(dn.childAtOffset(i)));
        }
      }
    } else {
      bool removeFirstNode = false;
      // beginning of the selection
      DaxeNode firstNode;
      if (start.dn.nodeType == DaxeNode.ELEMENT_NODE) {
        firstNode = start.dn.childAtOffset(start.dnOffset);
        Position p2 = new Position(start.dn, start.dnOffset + 1);
        if (end >= p2)
          removeFirstNode = true;
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
      if (removeFirstNode)
        edit.addSubEdit(new UndoableEdit.removeNode(firstNode));
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
   * Returns a root DaxeNode with a clone of everything between [start] and [end].
   * The two positions must not cut a node, except for text nodes
   * (all the document elements must be either inside or outside the range).
   */
  DaxeNode cloneBetween(Position start, Position end) {
    assert(start < end);
    DaxeNode parent = start.dn;
    if (parent is DNText)
      parent = parent.parent;
    DaxeNode root = NodeFactory.create(parent.ref);
    if (start.dn == end.dn) {
      DaxeNode dn = start.dn;
      if (dn.nodeType == DaxeNode.TEXT_NODE) {
        root.appendChild(new DNText(dn.nodeValue.substring(start.dnOffset, end.dnOffset)));
      } else {
        for (int i = start.dnOffset; i < end.dnOffset; i++) {
          root.appendChild(new DaxeNode.clone(dn.childAtOffset(i)));
        }
      }
    } else {
      // beginning of the selection
      DaxeNode firstNode;
      if (start.dn.nodeType == DaxeNode.ELEMENT_NODE) {
        firstNode = start.dn.childAtOffset(start.dnOffset);
        Position p2 = new Position(start.dn, start.dnOffset + 1);
        if (end >= p2) {
          root.appendChild(new DaxeNode.clone(firstNode));
        }
      } else {
        firstNode = start.dn;
        if (firstNode.offsetLength - start.dnOffset > 0) {
          root.appendChild(new DNText(
              firstNode.nodeValue.substring(start.dnOffset, firstNode.offsetLength)));
        }
      }
      // between the first and the end node of the selection
      for (DaxeNode next = firstNode.nextSibling; next != null; next = next.nextSibling) {
        Position p1 = new Position(next.parent, next.parent.offsetOf(next));
        if (p1 < end) {
          if (next.nodeType != DaxeNode.TEXT_NODE ||
              (next.nodeType == DaxeNode.TEXT_NODE &&
              end >= new Position(next.parent, next.parent.offsetOf(next) + 1))) {
            root.appendChild(new DaxeNode.clone(next));
          }
        } else
          break;
      }
      // end of the selection
      if (end.dn.nodeType == DaxeNode.TEXT_NODE && end.dnOffset > 0) {
        root.appendChild(new DNText(end.dn.nodeValue.substring(0, end.dnOffset)));
      }
    }
    return(root);
  }
  
  /**
   * Returns a cloned node of root including everything between p1 and p2.
   * The interval p1-p2 may cut nodes.
   * The root attributes are preserved.
   */
  DaxeNode cloneCutBetween(DaxeNode root, Position p1, Position p2) {
    while (p1.dnOffset == p1.dn.offsetLength && p1 < p2) {
      // to avoid cloning an empty element at the beginning
      p1 = new Position(p1.dn.parent, p1.dn.parent.offsetOf(p1.dn) + 1);
    }
    while (p2.dnOffset == 0 && p2 > p1) {
      // to avoid cloning an empty element at the end
      p2 = new Position(p2.dn.parent, p2.dn.parent.offsetOf(p2.dn));
    }
    DaxeNode root2 = new DaxeNode.clone(root);
    // optimization: could this shallow clone be optimized without requiring another method for several DaxeNodes ?
    // (or we could reuse the children later instead of recloning them)
    for (DaxeNode dn = root2.firstChild; dn != null; dn = root2.firstChild)
      root2.removeChild(dn);
    int offset = 0;
    for (DaxeNode dn=root.firstChild; dn != null; dn=dn.nextSibling) {
      Position dnstart = new Position(root, offset);
      Position dnend = new Position(root, offset + 1);
      if (dnstart >= p1 && dnend <= p2) {
        DaxeNode dn2 = new DaxeNode.clone(dn);
        root2.appendChild(dn2);
      } else if (dnend <= p1 || dnstart >= p2) {
        // dn is not included at all in the selection
      } else {
        if (dn is DNText) {
          if (dnstart > p1 && dnend > p2) {
            assert(dn == p2.dn);
            if (0 < p2.dnOffset)
              root2.appendChild(new DNText(dn.nodeValue.substring(0, p2.dnOffset)));
          } else if (dnstart < p1 && dnend < p2) {
            assert(dn == p1.dn);
            if (p1.dnOffset < dn.offsetLength)
              root2.appendChild(new DNText(dn.nodeValue.substring(p1.dnOffset, dn.offsetLength)));
          } else {
            // dnstart <= p1 && dnend >= p2
            int offset1;
            if (p1.dn == dn)
              offset1 = p1.dnOffset;
            else
              offset1 = 0;
            int offset2;
            if (p2.dn == dn)
              offset2 = p2.dnOffset;
            else
              offset2 = dn.offsetLength;
            if (offset1 < offset2)
              root2.appendChild(new DNText(dn.nodeValue.substring(offset1, offset2)));
          }
        } else {
          DaxeNode dn2 = cloneCutBetween(dn, p1, p2);
          root2.appendChild(dn2);
        }
      }
      offset++;
    }
    return(root2);
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
    
    // extract children from the root to avoid text merging under root
    List<DaxeNode> children = new List<DaxeNode>();
    while (root.firstChild != null) {
      children.add(root.firstChild);
      root.removeChild(root.firstChild);
    }
    // inserting non-text nodes first to avoid text merging issues in the target
    Position insertPos = new Position.clone(pos);
    for (DaxeNode dn in children) {
      if (dn is! DNText) {
        if (checkValidity &&
            (parent is DNComment || parent is DNCData || parent is DNProcessingInstruction)) {
          String title;
          if (dn.ref == null)
            title = dn.nodeName;
          else
            title = cfg.elementTitle(dn.ref);
          throw new DaxeException(title + ' ' + Strings.get('insert.not_authorized_here'));
        }
        if (dn is DNCData) {
          if (checkValidity && parent.nodeType == DaxeNode.DOCUMENT_NODE)
            throw new DaxeException(Strings.get('insert.text_not_allowed'));
          String value = null;
          if (dn.firstChild != null)
            value = dn.firstChild.nodeValue;
          if (value == null)
            value = '';
          if (checkValidity && value.trim() != '' && !cfg.canContainText(parent.ref)) {
            throw new DaxeException(Strings.get('insert.text_not_allowed'));
          }
          edit.addSubEdit(new UndoableEdit.insertNode(insertPos, dn));
        } else {
          if (checkValidity) {
            if (parent.nodeType == DaxeNode.DOCUMENT_NODE) {
              if (!cfg.rootElements().contains(dn.ref))
                throw new DaxeException(cfg.elementTitle(dn.ref) + ' ' + Strings.get('insert.not_authorized_here'));
            } else if (dn is! DNComment && dn is! DNProcessingInstruction) {
              if (dn.ref == null || !cfg.isSubElement(parent.ref, dn.ref)) {
                String title;
                if (dn.ref == null)
                  title = dn.nodeName;
                else
                  title = cfg.elementTitle(dn.ref);
                String parentTitle = cfg.elementTitle(parent.ref);
                throw new DaxeException(title + ' ' + Strings.get('insert.not_authorized_inside') + ' ' + parentTitle);
              }
              if (!cfg.insertIsPossible(parent, offset, offset, dn.ref)) {
                throw new DaxeException(cfg.elementTitle(dn.ref) + ' ' + Strings.get('insert.not_authorized_here'));
              }
            }
          }
          edit.addSubEdit(new UndoableEdit.insertNode(insertPos, dn));
        }
        if (insertPos.dn is DNText) // after first insert inside a text node
          insertPos = new Position(parent, offset + 2);
        else
          insertPos = new Position(parent, insertPos.dnOffset + 1);
      }
    }
    // Now copy text nodes.
    // If the first text node merges to the left, it will be taken into
    // account for the insert positions of the following text nodes.
    bool merge = false;
    bool first = true;
    for (DaxeNode dn in children) {
      if (dn is DNText) {
        if (checkValidity && parent.nodeType == DaxeNode.DOCUMENT_NODE)
          throw new DaxeException(Strings.get('insert.text_not_allowed'));
        String value = dn.nodeValue;
        if (value == null)
          value = '';
        if (checkValidity && value.trim() != '' && !cfg.canContainText(parent.ref)) {
          throw new DaxeException(Strings.get('insert.text_not_allowed'));
        }
        int insertOffset = offset + children.indexOf(dn);
        if (pos.dn is DNText)
          insertOffset++;
        if (merge)
          insertOffset--;
        if (children.length == 1)
          insertPos = pos; // case of a single text node
        else
          insertPos = new Position(parent, insertOffset);
        if (first) {
          if (insertOffset > 0 && (pos.dn is DNText ||
              parent.childAtOffset(insertOffset - 1) is DNText))
            merge = true;
          first = false;
        }
        edit.addSubEdit(new UndoableEdit.insertString(insertPos, dn.nodeValue));
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
   * Combine the last nb edits into a single compound edit.
   */
  void combineLastEdits(String title, int nb) {
    UndoableEdit edit = new UndoableEdit.compound(title);
    for (int i=edits.length-nb; i<edits.length; i++)
      edit.addSubEdit(edits[i]);
    edits.removeRange(edits.length - nb, edits.length);
    edits.add(edit);
    undoPosition -= (nb - 1);
  }
  
  /**
   * Called when the user tries to insert text.
   * [shift]: true if the shift key was used.
   */
  void insertNewString(String s, bool shift) {
    Position selectionStart = page.getSelectionStart();
    Position selectionEnd = page.getSelectionEnd();
    if (s == '\n' && !shift) {
      // check for newlines in lists
      if (((selectionStart.dn is DNItem) ||
          (selectionStart.dn.nextSibling == null && selectionStart.dn.parent is DNItem)) &&
          selectionStart.dnOffset == selectionStart.dn.offsetLength) {
        // \n at the end of a DNList item: adding a new list item
        DNList.newlineInItem(selectionStart);
        return;
      } else {
        DaxeNode ancestor = selectionStart.dn;
        while (ancestor is DNText || ancestor is DNHiddenP || ancestor is DNStyle || ancestor is DNStyleSpan)
          ancestor = ancestor.parent;
        if (ancestor is DNWItem) {
          // \n in a DNWList item: adding a new list item
          DNWList.newlineInItem(selectionStart);
          return;
        }
      }
    }
    // Handles automatic insertion of hidden paragraphs
    if (s == '\n' && hiddenParaRefs != null) {
      if (DNHiddenP.handleNewlineOnSelection())
        return;
    }
    // check if text is allowed here
    bool problem = false;
    if (s.trim() != '') {
      DaxeNode parent = selectionStart.dn;
      if (parent.nodeType == DaxeNode.TEXT_NODE)
        parent = parent.parent;
      if (parent.nodeType == DaxeNode.DOCUMENT_NODE)
        problem = true;
      else if (parent.ref != null && !doc.cfg.canContainText(parent.ref)) {
        if (hiddenParaRefs != null) {
          x.Element hiddenp = cfg.findSubElement(parent.ref, hiddenParaRefs);
          if (hiddenp != null && selectionStart == selectionEnd) {
            // we just need to insert a hidden paragraph
            DNHiddenP p = new DNHiddenP.fromRef(hiddenp);
            p.appendChild(new DNText(s));
            insertNode(p, selectionStart);
            page.moveCursorTo(new Position(p, p.offsetLength));
            page.updateAfterPathChange();
            return;
          } else
            problem = true;
        } else
          problem = true;
      }
    }
    if (problem) {
      h.window.alert(Strings.get('insert.text_not_allowed'));
      page.cursor.clearField();
      return;
    }
    bool remove = false;
    if (selectionStart != selectionEnd) {
      selectionStart = new Position.clone(selectionStart);
      selectionEnd = new Position.clone(selectionEnd);
      page.cursor.deSelect();
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
    DaxeNode dn = NodeFactory.create(ref, nodeType);
    if (nodeType == 'element' && getRootElement() == null) {
      cfg.addNamespaceAttributes(dn);
    }
    dn.newNodeCreationUI(() => insert2(dn, pos));
  }
  
  /**
   * Inserts the [DaxeNode] at the given [Position] following a user action,
   * after the attribute dialog has been validated (if there are attributes).
   * If there is a selection, its contents are moved inside the new element.
   * The whole operation is added to the document history so that it can be undone.
   * Returns true if the insert worked.
   * This method is called by [insertNewNode].
   */
  bool insert2(DaxeNode dn, Position pos) {
    DaxeNode content = null;
    if (page.getSelectionStart() != page.getSelectionEnd()) {
      Position selectionStart = page.getSelectionStart();
      Position selectionEnd = page.getSelectionEnd();
      content = cloneBetween(selectionStart, selectionEnd);
      page.cursor.deSelect();
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
    bool inserted = false;
    DaxeNode parent = pos.dn;
    if (parent is DNText)
      parent = parent.parent;
    if (parent is DNHiddenP) {
      DNHiddenP p = parent;
      if (!cfg.isSubElement(p.ref, dn.ref)) {
        // The node must be inserted outside of the paragraph.
        // If there is something in the paragraph to the right of the cursor, it must be
        // moved into a new paragraph after the inserted node.
        UndoableEdit edit = new UndoableEdit.compound(Strings.get('undo.insert_text'));
        Position pend = new Position(p, p.offsetLength);
        pend.moveInsideTextNodeIfPossible();
        if (pos < pend) {
          DaxeNode clone = cloneBetween(pos, pend);
          edit.addSubEdit(removeBetweenEdit(pos, pend));
          DNHiddenP newp = NodeFactory.create(p.ref);
          edit.addSubEdit(new UndoableEdit.insertNode(
              new Position(p.parent, p.parent.offsetOf(p) + 1), newp));
          edit.addSubEdit(insertChildrenEdit(clone, new Position(newp, 0)));
        }
        edit.addSubEdit(new UndoableEdit.insertNode(
            new Position(p.parent, p.parent.offsetOf(p)+1), dn));
        doNewEdit(edit);
        inserted = true;
      }
    } else if (hiddenParaRefs != null && parent.ref != null && !cfg.isSubElement(parent.ref, dn.ref)) {
      x.Element hiddenp = cfg.findSubElement(parent.ref, hiddenParaRefs);
      if (hiddenp != null && cfg.isSubElement(hiddenp, dn.ref)) {
        // a new paragraph must be created
        DNHiddenP p = new DNHiddenP.fromRef(hiddenp);
        p.appendChild(dn);
        insertNode(p, pos);
        inserted = true;
      }
    }
    if (!inserted)
      insertNode(dn, pos);
    Position cursorPos = dn.firstCursorPositionInside();
    if (cursorPos == null)
      cursorPos = new Position(dn.parent, dn.parent.offsetOf(dn) + 1);
    page.moveCursorTo(cursorPos);
    page.updateAfterPathChange();
    if (content != null) {
      try {
        if (cursorPos == null)
          throw new DaxeException(content.toString() + Strings.get('insert.not_authorized_here'));
        if (doc.hiddenParaRefs != null) {
          // add or remove hidden paragraphs where necessary
          DNHiddenP.fixFragment(dn, content);
        }
        doNewEdit(insertChildrenEdit(content, cursorPos, checkValidity:true));
        // replace the 3 previous edits by a compound
        combineLastEdits(Strings.get('undo.insert_element'), 3);
        page.updateUndoMenus();
        return(true);
      } on DaxeException catch (ex) {
        h.window.alert(ex.toString());
        // inserting content didn't work: undo remove and insert
        undo();
        undo();
        edits.removeRange(edits.length - 2, edits.length);
        page.updateUndoMenus();
        return(false);
      }
    }
    return(true);
  }
  
  void executeFunction(String functionName, x.Element el) {
    // TODO: pass the parameters in el to the functions
    if (functionName == 'jaxe.FonctionNormal') {
      DNStyle.removeStylesFromSelection();
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
      if (parent is DNHiddenP && parent.parent.ref != null) {
        LinkedHashSet set = new LinkedHashSet.from(refs);
        set.addAll(cfg.subElements(parent.parent.ref));
        refs = new List.from(set);
      } else if (hiddenParaRefs != null) {
        x.Element hiddenp = cfg.findSubElement(parent.ref, hiddenParaRefs);
        if (hiddenp != null) {
          LinkedHashSet set = new LinkedHashSet.from(refs);
          set.addAll(cfg.subElements(hiddenp));
          refs = new List.from(set);
        }
      }
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
    if (startParent is DNHiddenP && startParent.parent.ref != null) {
      int offset = startParent.parent.offsetOf(startParent) + 1;
      LinkedHashSet set = new LinkedHashSet.from(list);
      for (x.Element ref in allowed) {
        if (!set.contains(ref)) {
          if (doc.cfg.insertIsPossible(startParent.parent, offset, offset, ref))
            set.add(ref);
        }
      }
      list = new List.from(set);
    } else if (hiddenParaRefs != null) {
      x.Element hiddenp = null;
      for (x.Element ref in hiddenParaRefs)
        if (list.contains(ref)) {
          hiddenp = ref;
          break;
        }
      if (hiddenp != null) {
        LinkedHashSet set = new LinkedHashSet.from(list);
        for (x.Element ref in allowed) {
          if (!set.contains(ref)) {
            if (doc.cfg.isSubElement(hiddenp, ref))
              set.add(ref);
          }
        }
        list = new List.from(set);
      }
    }
    return(list);
  }
  
  /**
   * Returns the [Position] matching the given screen coordinates.
   */
  Position findPosition(num x, num y) {
    return(dndoc.findPosition(x, y));
  }
  
  /**
   * Recusively removes needless whitespaces in the element.
   */
  void removeWhitespace(final x.Element el) {
    _removeWhitespace(el, null, false, true);
  }
  
  void _removeWhitespace(final x.Element el, final x.Element refParent, final bool spacePreserveParent,
                      final bool fteParent) {
    bool spacePreserve;
    final String xmlspace = el.getAttribute("xml:space");
    if (xmlspace == "preserve")
      spacePreserve = true;
    else if (xmlspace == "default")
      spacePreserve = false;
    else
      spacePreserve = spacePreserveParent;
    x.Element refElement;
    if (cfg != null) {
      refElement = cfg.getElementRef(el, refParent);
      if (refElement != null && xmlspace == "") {
        final List<x.Element> attributs = cfg.elementAttributes(refElement);
        for (x.Element attref in attributs) {
          if (cfg.attributeName(attref) == "space" &&
              cfg.attributeNamespace(attref) == "http://www.w3.org/XML/1998/namespace") {
            final String defaut = cfg.defaultAttributeValue(attref);
            if (defaut == "preserve")
              spacePreserve = true;
            else if (defaut == "default")
              spacePreserve = false;
            break;
          }
        }
      }
    } else
      refElement = null;
    final bool fte = _isFirstTextElement(el, refElement, refParent, fteParent);
    x.Node next;
    for (x.Node n = el.firstChild; n != null; n = next) {
      next = n.nextSibling;
      if (n.nodeType == x.Node.ELEMENT_NODE)
        _removeWhitespace(n as x.Element, refElement, spacePreserve, fte);
      else if (!spacePreserve && n.nodeType == x.Node.TEXT_NODE) {
        String s = n.nodeValue;
        
        // whitespace is not removed if there is only whitespace in the element
        //if (n.nextSibling == null && n.previousSibling == null && s.trim() == "")
        //  break;
        
        if (fte && n.parentNode.firstChild == n && refParent != null) {
          // remove whitespace at the beginning if the text node is the first child of the element
          int ifin = 0;
          while (ifin < s.length && (s[ifin] == ' ' || s[ifin] == '\t'))
            ifin++;
          if (ifin > 0)
            s = s.substring(ifin);
        }
        
        // remove spaces after newlines
        int idebut = s.indexOf("\n ");
        int idebuttab = s.indexOf("\n\t");
        if (idebuttab != -1 && (idebut == -1 || idebuttab < idebut))
          idebut = idebuttab;
        while (idebut != -1) {
          int ifin = idebut;
          while (ifin + 1 < s.length && (s[ifin + 1] == ' ' || s[ifin + 1] == '\t'))
            ifin++;
          s = s.substring(0, idebut+1) + s.substring(ifin+1);
          idebut = s.indexOf("\n ");
          idebuttab = s.indexOf("\n\t");
          if (idebuttab != -1 && (idebut == -1 || idebuttab < idebut))
            idebut = idebuttab;
        }
        
        // condense spaces everywhere
        idebut = s.indexOf("  ");
        while (idebut != -1) {
          int ifin = idebut;
          while (ifin + 1 < s.length && s[ifin + 1] == ' ')
            ifin++;
          s = s.substring(0, idebut) + s.substring(ifin);
          idebut = s.indexOf("  ");
        }
        
        // update the node
        if (s.length == 0)
          el.removeChild(n);
        else
          n.nodeValue = s;
      }
    }
  }
  
  /**
   * Returns false if whitespaces should not be removed at the start of the element.
   */
  bool _isFirstTextElement(final x.Element el, final x.Element refEl, final x.Element refParent,
                           final bool fteParent) {
    if (refEl == null)
      return true;
    if (refParent == null || !cfg.canContainText(refEl) || !cfg.canContainText(refParent))
      return true;
    x.Node prevNode = el.previousSibling;
    while (prevNode != null) {
      if (prevNode.nodeType == x.Node.TEXT_NODE) {
        final String prevText = prevNode.nodeValue;
        if (!(prevText.endsWith(" ") || prevText.endsWith("\n")))
          return false;
        return true;
      } else if (prevNode.nodeType == x.Node.ELEMENT_NODE) {
        final x.Node lc = prevNode.lastChild;
        if (lc != null && lc.nodeType == x.Node.TEXT_NODE) {
          final String prevText = lc.nodeValue;
          if (!(prevText.endsWith(" ") || prevText.endsWith("\n")))
            return false;
        }
        return true;
      }
      prevNode = prevNode.previousSibling;
    }
    if (prevNode == null)
      return fteParent;
    return true;
  }
  
  /**
   * Replace newlines by spaces where hidden paragraphs can be found and inside them,
   * and remove whitespace before and after blocks where hidden paragraphs can be found.
   */
  void removeWhitespaceForHiddenParagraphs(DaxeNode parent) {
    x.Element paraRef = cfg.findSubElement(parent.ref, hiddenParaRefs);
    bool paraInside = (paraRef != null);
    bool para = parent is DNHiddenP;
    bool style = parent is DNStyle;
    DaxeNode next;
    for (DaxeNode dn=parent.firstChild; dn != null; dn=next) {
      next = dn.nextSibling;
      if (dn is DNText) {
        if (paraInside || para || style) {
          String s = dn.nodeValue;
          s = s.replaceAll('\n', ' ');
          s = s.replaceAll('  ', ' ');
          if (paraInside) {
            // also trim left if there is a block before, and right if there is a block after
            // ("blocks" here are elements that are not allowed inside a paragraph)
            if (dn.previousSibling != null && dn.previousSibling.ref != null && !cfg.isSubElement(paraRef, dn.previousSibling.ref)) {
              s = s.trimLeft();
            }
            if (dn.nextSibling != null && dn.nextSibling.ref != null && !cfg.isSubElement(paraRef, dn.nextSibling.ref)) {
              s = s.trimRight();
            }
          } else if (para) {
            // trim hidden paragraphs
            if (dn.previousSibling == null)
              s = s.trimLeft();
            if (dn.nextSibling == null)
              s = s.trimRight();
          }
          if (s.length == 0)
            parent.removeChild(dn);
          else
            dn.nodeValue = s;
        }
      } else if (dn.firstChild != null)
        removeWhitespaceForHiddenParagraphs(dn);
    }
  }
}
