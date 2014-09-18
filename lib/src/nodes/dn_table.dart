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

part of nodes;

/**
 * Table able to contain other elements in its cells.
 * Jaxe display type: 'tabletexte' (text table).
 * 
 * * parameter: `trTag`: the name of row elements
 * * parameter: `tdTag`: the name of cell elements
 * * parameter: `thTag`: the name of header elements
 * * parameter: `colspanAttr`: the name of the colspan attribute
 * * parameter: `rowspanAttr`: the name of the rowspan attribute
 */
class DNTable extends DaxeNode {
  String _trtag, _tdtag, _thtag;
  x.Element _trref, _tdref, _thref;
  String _colspanAttr, _rowspanAttr, _alignAttr;
  bool header;
  
  DNTable.fromRef(x.Element elementRef) : super.fromRef(elementRef) {
    init();
    createNewStructure();
  }
  
  DNTable.fromNode(x.Node node, DaxeNode parent) : super.fromNode(node, parent, createChildren: false) {
    init();
    for (x.Node xtr=node.firstChild; xtr != null; xtr=xtr.nextSibling) {
      if (xtr.nodeType == x.Node.ELEMENT_NODE) {
        DaxeNode tr = new DNTR.fromNode(xtr, this);
        for (x.Node xtd=xtr.firstChild; xtd != null; xtd=xtd.nextSibling) {
          if (xtd.nodeType == x.Node.ELEMENT_NODE) {
            if (xtd.nodeName == _tdtag) {
              DaxeNode td = new DNTD.fromNode(xtd, tr);
              tr.appendChild(td);
            } else if (xtd.nodeName == _thtag) {
              DaxeNode th = new DNTH.fromNode(xtd, tr);
              tr.appendChild(th);
            }
          }
        }
        appendChild(tr);
      }
    }
    if (firstChild != null && firstChild.firstChild is DNTH)
      header = true;
  }
  
  void init() {
    _trtag = doc.cfg.elementParameterValue(ref, 'trTag', 'tr');
    List<x.Element> trRefs = doc.cfg.elementReferences(_trtag);
    _trref = doc.cfg.findSubElement(ref, trRefs);
    _tdtag = doc.cfg.elementParameterValue(ref, 'tdTag', 'td');
    List<x.Element> tdRefs = doc.cfg.elementReferences(_tdtag);
    _tdref = doc.cfg.findSubElement(_trref, tdRefs);
    _thtag = doc.cfg.elementParameterValue(ref, 'thTag', 'th');
    List<x.Element> thRefs = doc.cfg.elementReferences(_thtag);
    _thref = doc.cfg.findSubElement(_trref, thRefs);
    _colspanAttr = doc.cfg.elementParameterValue(ref, 'colspanAttr', null);
    _rowspanAttr = doc.cfg.elementParameterValue(ref, 'rowspanAttr', null);
    _alignAttr = doc.cfg.elementParameterValue(ref, 'alignAttr', null);
    header = false;
  }
  
  @override
  h.Element html() {
    h.DivElement div = new h.DivElement();
    div.id = "$id";
    div.classes.add('dn');
    div.classes.add('table');
    
    h.FormElement form = new h.FormElement();
    form.classes.add('table_buttons');
    
    h.ButtonElement bTable = new h.ButtonElement();
    bTable.attributes['type'] = 'button';
    bTable.appendText(Strings.get("table.Table"));
    bTable.onClick.listen((h.MouseEvent event) => attributeDialog());
    bTable.style.marginRight = '1em';
    form.append(bTable);
    
    h.ButtonElement bRow = new h.ButtonElement();
    bRow.attributes['type'] = 'button';
    bRow.appendText(Strings.get("table.Row"));
    bRow.onClick.listen((h.MouseEvent event) => rowAttributes());
    bRow.style.marginRight = '0.2em';
    form.append(bRow);
    
    h.ButtonElement bInsertRow = new h.ButtonElement();
    bInsertRow.attributes['type'] = 'button';
    bInsertRow.appendText("+");
    bInsertRow.onClick.listen((h.MouseEvent event) => insertRow());
    bInsertRow.style.marginRight = '0.2em';
    form.append(bInsertRow);
    
    h.ButtonElement bRemoveRow = new h.ButtonElement();
    bRemoveRow.attributes['type'] = 'button';
    bRemoveRow.appendText("-");
    bRemoveRow.onClick.listen((h.MouseEvent event) => removeRow());
    bRemoveRow.style.marginRight = '1em';
    form.append(bRemoveRow);
    
    form.appendText(Strings.get('table.Column'));
    h.ButtonElement bInsertColumn = new h.ButtonElement();
    bInsertColumn.attributes['type'] = 'button';
    bInsertColumn.appendText("+");
    bInsertColumn.onClick.listen((h.MouseEvent event) => insertColumn());
    bInsertColumn.style.marginRight = '0.2em';
    form.append(bInsertColumn);
    
    h.ButtonElement bRemoveColumn = new h.ButtonElement();
    bRemoveColumn.attributes['type'] = 'button';
    bRemoveColumn.appendText("-");
    bRemoveColumn.onClick.listen((h.MouseEvent event) => removeColumn());
    bRemoveColumn.style.marginRight = '1em';
    form.append(bRemoveColumn);
    
    h.ButtonElement bCell = new h.ButtonElement();
    bCell.attributes['type'] = 'button';
    bCell.appendText(Strings.get("table.Cell"));
    bCell.onClick.listen((h.MouseEvent event) => cellAttributes());
    bCell.style.marginRight = '1em';
    form.append(bCell);
    
    h.CheckboxInputElement bheader = new h.CheckboxInputElement();
    bheader.id = "header$id";
    bheader.checked = header;
    bheader.onClick.listen((h.MouseEvent event) => toggleHeader());
    form.append(bheader);
    h.LabelElement headerLabel = new h.LabelElement();
    headerLabel.htmlFor = "header$id";
    headerLabel.appendText(Strings.get('table.header'));
    headerLabel.style.marginRight = '1em';
    form.append(headerLabel);
    
    h.ButtonElement bMergeRight = new h.ButtonElement();
    bMergeRight.attributes['type'] = 'button';
    h.ImageElement img = new h.ImageElement();
    img.src = 'packages/daxe/images/mergeright.png';
    bMergeRight.append(img);
    bMergeRight.onClick.listen((h.MouseEvent event) => mergeRight());
    bMergeRight.style.marginRight = '0.2em';
    bMergeRight.title = Strings.get('table.merge_right');
    form.append(bMergeRight);
    
    h.ButtonElement bSplitX = new h.ButtonElement();
    bSplitX.attributes['type'] = 'button';
    img = new h.ImageElement();
    img.src = 'packages/daxe/images/splitx.png';
    bSplitX.append(img);
    bSplitX.onClick.listen((h.MouseEvent event) => splitX());
    bSplitX.style.marginRight = '0.2em';
    bSplitX.title = Strings.get('table.split_x');
    form.append(bSplitX);
    
    h.ButtonElement bMergeBottom = new h.ButtonElement();
    bMergeBottom.attributes['type'] = 'button';
    img = new h.ImageElement();
    img.src = 'packages/daxe/images/mergebottom.png';
    bMergeBottom.append(img);
    bMergeBottom.onClick.listen((h.MouseEvent event) => mergeBottom());
    bMergeBottom.style.marginRight = '0.2em';
    bMergeBottom.title = Strings.get('table.merge_bottom');
    form.append(bMergeBottom);
    
    h.ButtonElement bSplitY = new h.ButtonElement();
    bSplitY.attributes['type'] = 'button';
    img = new h.ImageElement();
    img.src = 'packages/daxe/images/splity.png';
    bSplitY.append(img);
    bSplitY.onClick.listen((h.MouseEvent event) => splitY());
    bSplitY.style.marginRight = '0.2em';
    bSplitY.title = Strings.get('table.split_y');
    form.append(bSplitY);
    
    div.append(form);
    
    h.TableElement table = new h.TableElement();
    table.classes.add('indent');
    DaxeNode dn = firstChild;
    while (dn != null) {
      table.append(dn.html());
      dn = dn.nextSibling;
    }
    div.append(table);
    return(div);
  }
  
  @override
  Position firstCursorPositionInside() {
    if (firstChild == null || firstChild.firstChild == null) {
      return(null);
    }
    return(new Position(firstChild.firstChild, 0));
  }
  
  @override
  Position lastCursorPositionInside() {
    if (lastChild == null || lastChild.lastChild == null) {
      return(null);
    }
    return(new Position(lastChild.lastChild, lastChild.lastChild.offsetLength));
  }
  
  void createNewStructure() {
    int rows = 2;
    int columns = 2;
    for (int i=0; i<rows; i++) {
      DNTR tr = new DNTR.fromRef(_trref);
      for (int j=0; j<columns; j++) {
        DNTD td = new DNTD.fromRef(_tdref);
        tr.appendChild(td);
      }
      appendChild(tr);
    }
  }
  
  void rowAttributes() {
    DNTR tr = getSelectedRow();
    if (tr == null)
      return;
    tr.attributeDialog();
  }
  
  void insertRow() {
    DNTR selectedRow = getSelectedRow();
    if (selectedRow == null)
      return;
    DaxeNode newRow = new DNTR.fromRef(_trref);
    for (int i=0; i<xLength(); i++) {
      DNTD td = new DNTD.fromRef(_tdref);
      newRow.appendChild(td);
    }
    doc.insertNode(newRow, new Position(this, offsetOf(selectedRow) + 1));
    page.moveCursorTo(newRow.firstCursorPositionInside());
  }
  
  void removeRow() {
    DNTR tr = getSelectedRow();
    if (tr == null)
      return;
    UndoableEdit edit = new UndoableEdit.compound(Strings.get('undo.remove'));
    for (DNTD td in tr.childNodes) {
      if (td.rowspan > 1)
        splitY(td, edit);
    }
    edit.addSubEdit(new UndoableEdit.removeNode(tr));
    doc.doNewEdit(edit);
  }
  
  void insertColumn() {
    DNTD td = getSelectedCell();
    if (td == null)
      return;
    UndoableEdit edit = new UndoableEdit.compound(Strings.get('undo.insert'));
    int x = getCellX(td);
    for (DaxeNode tr in childNodes) {
      DNTD newtd;
      if (firstChild == tr && header)
        newtd = new DNTH.fromRef(_thref);
      else
        newtd = new DNTD.fromRef(_tdref);
      int offset = 0;
      for (DNTD td = tr.firstChild; td != null && x >= getCellX(td); td = td.nextSibling) {
        offset++;
      }
      edit.addSubEdit(new UndoableEdit.insertNode(new Position(tr, offset), newtd));
    }
    doc.doNewEdit(edit);
    page.moveCursorTo(new Position(td.nextSibling, 0));
  }
  
  void removeColumn() {
    DNTD td = getSelectedCell();
    if (td == null)
      return;
    Position futurePos;
    if (td.nextSibling != null)
      futurePos = new Position(td.nextSibling, 0);
    else if (td.previousSibling != null)
      futurePos = new Position(td.previousSibling, 0);
    else
      futurePos = null;
    UndoableEdit edit = new UndoableEdit.compound(Strings.get('undo.remove'));
    int x = getCellX(td);
    int y = 0;
    for (DaxeNode tr in childNodes) {
      DNTD td = getCell(x, y);
      while (td.colspan > 1) {
        splitX(td); // FIXME: should be undoable, but how do we get the reference to the created td ?
        td = getCell(x, y);
      }
      edit.addSubEdit(new UndoableEdit.removeNode(td));
      y++;
    }
    doc.doNewEdit(edit);
    if (futurePos != null)
      page.moveCursorTo(futurePos);
  }
  
  void cellAttributes() {
    DNTD td = getSelectedCell();
    if (td == null)
      return;
    td.attributeDialog();
  }
  
  DNTD getSelectedCell() {
    Position pos = page.getSelectionStart();
    DaxeNode parent = pos.dn;
    while (parent != null && parent is! DNTD)
      parent = parent.parent;
    return(parent);
  }
  
  DNTR getSelectedRow() {
    Position pos = page.getSelectionStart();
    DaxeNode parent = pos.dn;
    while (parent != null && parent is! DNTR)
      parent = parent.parent;
    return(parent);
  }
  
  DNTD getCell(int x, int y) {
    return(grid()[x][y]); // could be optimized with a cache
  }
  
  int getCellX(DNTD td) {
    List<List<DNTD>> g = grid();
    for (int x=0; x<g.length; x++)
      for (int y=0; y<g[0].length; y++)
        if (g[x][y] == td)
          return(x);
    assert(false);
    return(-1);
  }
  
  int getCellY(DNTD td) {
    List<List<DNTD>> g = grid();
    for (int x=0; x<g.length; x++)
      for (int y=0; y<g[0].length; y++)
        if (g[x][y] == td)
          return(y);
    assert(false);
    return(-1);
  }
  
  List<List<DNTD>> grid() {
    int dx = xLength();
    int dy = yLength();
    // to get g[dx][dy]
    List<List<DNTD>> g = new List<List<DNTD>>(dx);
    for (int x=0; x<dx; x++)
      g[x] = new List<DNTD>(dy);
    int y = 0;
    for (DNTR tr in childNodes) {
      int x = 0;
      for (DNTD td in tr.childNodes) {
        while (x < dx && g[x][y] != null)
          x++;
        for (int ix=0; ix < td.colspan; ix++) {
          for (int iy=0; iy < td.rowspan; iy++) {
            g[x+ix][y+iy] = td;
          }
        }
        x += td.colspan;
      }
      y++;
    }
    return(g);
  }
  
  int xLength() {
    int dx = 0;
    for (DNTR tr in childNodes) {
      int n = 0;
      for (DNTD td in tr.childNodes) {
        n += td.colspan;
      }
      dx = max(dx, n);
    }
    return(dx);
  }
  
  int yLength() {
    int dy = 0;
    for (DNTR tr in childNodes) {
      DNTD td = tr.firstChild;
      dy += td.rowspan;
    }
    return(dy);
  }
  
  void toggleHeader() {
    DNTR firstTR = firstChild;
    if (firstTR == null)
      return;
    DaxeNode cell = firstTR.firstChild;
    while (cell != null) {
      DaxeNode nextCell = cell.nextSibling;
      if (header && cell is DNTH) {
        DNTD td = new DNTD.fromRef(_tdref);
        DaxeNode child = cell.firstChild;
        while (child != null) {
          DaxeNode nextChild = child.nextSibling;
          cell.removeChild(child);
          td.appendChild(child);
          child = nextChild;
        }
        for (DaxeAttr attr in cell.attributes)
          td.setAttribute(attr.name, attr.value);
        cell.replaceWith(td);
      } else if (!header && cell is DNTD && cell is! DNTH) {
        DNTH th = new DNTH.fromRef(_thref);
        DaxeNode child = cell.firstChild;
        while (child != null) {
          DaxeNode nextChild = child.nextSibling;
          cell.removeChild(child);
          th.appendChild(child);
          child = nextChild;
        }
        for (DaxeAttr attr in cell.attributes)
          th.setAttribute(attr.name, attr.value);
        cell.replaceWith(th);
      }
      cell = nextCell;
    }
    header = !header;
    firstTR.updateHTML();
  }
  
  void mergeRight([DNTD td]) {
    if (td == null)
      td = getSelectedCell();
    if (td == null)
      return;
    int x = getCellX(td);
    int y = getCellY(td);
    int x2 = x + td.colspan;
    if (x2 >= xLength())
      return;
    DNTD td2 = getCell(x2, y);
    if (td2.parent != td.parent)
      splitY(td2); // TODO: check again, FIXME: make it undoable (pb: get ref to next when it does not exist yet)
    DNTD next = td.nextSibling;
    if (next == null)
      return;
    if (next.rowspan != td.rowspan) {
      //TODO: something ?
      return;
    }
    UndoableEdit edit = new UndoableEdit.compound(Strings.get('table.merge'));
    edit.addSubEdit(
        new UndoableEdit.changeAttribute(td, new DaxeAttr(_colspanAttr, (td.colspan + next.colspan).toString())));
    edit.addSubEdit(new UndoableEdit.removeNode(next));
    doc.doNewEdit(edit);
    page.moveCursorTo(td.firstCursorPositionInside());
    page.updateAfterPathChange();
  }
  
  void mergeBottom([DNTD td]) {
    if (td == null)
      td = getSelectedCell();
    if (td == null)
      return;
    int x = getCellX(td);
    int y = getCellY(td);
    int y2 = y + td.rowspan;
    if (y2 >= yLength())
      return;
    DNTD td2 = getCell(x, y2);
    if (td2.colspan != td.colspan) {
      //TODO: something ?
      return;
    }
    UndoableEdit edit = new UndoableEdit.compound(Strings.get('table.merge'));
    edit.addSubEdit(
        new UndoableEdit.changeAttribute(td, new DaxeAttr(_rowspanAttr, (td.rowspan + td2.rowspan).toString())));
    edit.addSubEdit(new UndoableEdit.removeNode(td2));
    doc.doNewEdit(edit);
    page.moveCursorTo(td.firstCursorPositionInside());
    page.updateAfterPathChange();
  }
  
  void splitX([DNTD td, UndoableEdit parentEdit]) {
    if (td == null)
      td = getSelectedCell();
    if (td == null)
      return;
    if (td.colspan < 2)
      return;
    DNTD newtd;
    if (td is DNTH)
      newtd = new DNTH.fromRef(_thref);
    else
      newtd = new DNTD.fromRef(_tdref);
    DNTR tr = td.parent;
    UndoableEdit edit;
    if (parentEdit != null)
      edit = parentEdit;
    else
      edit = new UndoableEdit.compound(Strings.get('table.split'));
    edit.addSubEdit(
        new UndoableEdit.insertNode(new Position(tr, tr.offsetOf(td) + 1), newtd));
    edit.addSubEdit(
        new UndoableEdit.changeAttribute(td, new DaxeAttr(_colspanAttr, (td.colspan - 1).toString())));
    if (parentEdit == null)
      doc.doNewEdit(edit);
  }
  
  void splitY([DNTD td, UndoableEdit parentEdit]) {
    if (td == null)
      td = getSelectedCell();
    if (td == null)
      return;
    if (td.rowspan < 2)
      return;
    int x = getCellX(td);
    int y = getCellY(td);
    int y2 = y + td.rowspan - 1;
    DNTR tr = childAtOffset(y2);
    if (tr == null)
      return;
    int offset = 0;
    for (DNTD td = tr.firstChild; td != null && x > getCellX(td); td = td.nextSibling) {
      offset++;
    }
    DNTD newtd = new DNTD.fromRef(_tdref);
    UndoableEdit edit;
    if (parentEdit != null)
      edit = parentEdit;
    else
      edit = new UndoableEdit.compound(Strings.get('table.split'));
    edit.addSubEdit(
        new UndoableEdit.insertNode(new Position(tr, offset), newtd));
    edit.addSubEdit(
        new UndoableEdit.changeAttribute(td, new DaxeAttr(_rowspanAttr, (td.rowspan - 1).toString())));
    if (parentEdit == null)
      doc.doNewEdit(edit);
  }
  
  @override
  bool newlineAfter() {
    return(true);
  }
  
  @override
  bool newlineInside() {
    return(true);
  }
}


class DNTR extends DaxeNode {
  
  DNTR.fromRef(x.Element elementRef) : super.fromRef(elementRef) {
    userCannotRemove = true;
  }
  
  DNTR.fromNode(x.Node node, DaxeNode parent) : super.fromNode(node, parent, createChildren: false) {
    userCannotRemove = true;
    fixLineBreaks();
  }
  
  @override
  h.Element html() {
    h.TableRowElement tr = new h.TableRowElement();
    tr.attributes['id'] = "$id";
    tr.attributes['class'] = 'dn';
    DaxeNode dn = firstChild;
    while (dn != null) {
      tr.append(dn.html());
      dn = dn.nextSibling;
    }
    return(tr);
  }
  
  @override
  Position firstCursorPositionInside() {
    if (firstChild == null) {
      return(null);
    }
    return(new Position(firstChild, 0));
  }
  
  @override
  Position lastCursorPositionInside() {
    if (lastChild == null) {
      return(null);
    }
    return(new Position(lastChild, lastChild.offsetLength));
  }
  
  @override
  bool newlineAfter() {
    return(true);
  }
}

class DNTD extends DaxeNode {
  
  DNTD.fromRef(x.Element elementRef) : super.fromRef(elementRef) {
    userCannotRemove = true;
  }
  
  DNTD.fromNode(x.Node node, DaxeNode parent) : super.fromNode(node, parent) {
    userCannotRemove = true;
    fixLineBreaks();
  }
  
  @override
  h.Element html() {
    h.TableCellElement td = new h.TableCellElement();
    td.id = "$id";
    td.classes.add('dn');
    if (this is DNTH)
      td.classes.add('header');
    td.attributes['rowspan'] = rowspan.toString();
    td.attributes['colspan'] = colspan.toString();
    td.attributes['align'] = align;
    DaxeNode dn = firstChild;
    while (dn != null) {
      td.append(dn.html());
      dn = dn.nextSibling;
    }
    // without a space at the end, a newline at the end of a cell does not create additional
    // space for the cell
    td.appendText(' ');
    return(td);
  }
  
  int get rowspan {
    DNTable table = parent.parent;
    String v = getAttribute(table._rowspanAttr); 
    if (v == null || v == '')
      return(1);
    else
      return(int.parse(v, onError: (String s) => 1));
  }
  
  int get colspan {
    DNTable table = parent.parent;
    String v = getAttribute(table._colspanAttr); 
    if (v == null || v == '')
      return(1);
    else
      return(int.parse(v, onError: (String s) => 1));
  }
  
  String get align {
    DNTable table = parent.parent;
    String v = getAttribute(table._alignAttr); 
    if (v == null || v == '')
      return('');
    else
      return(v);
  }
  
  // TODO: attributes: prevent edit rowspan/colspan ?
}

class DNTH extends DNTD {
  
  DNTH.fromRef(x.Element elementRef) : super.fromRef(elementRef) {
  }
  
  DNTH.fromNode(x.Node node, DaxeNode parent) : super.fromNode(node, parent) {
    fixLineBreaks();
  }
  
}


