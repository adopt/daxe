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
 * Left panel, with the insert and tree tabs.
 */
class LeftPanel implements FocusContainer {
  int _selected;
  InsertPanel _insertP;
  TreePanel _treeP;
  
  LeftPanel() {
    _selected = 0;
    _insertP = new InsertPanel();
    _treeP = new TreePanel();
  }
  
  h.DivElement html() {
    h.DivElement panelDiv = new h.DivElement();
    panelDiv.id = 'left_panel';
    h.DivElement buttonsDiv = new h.DivElement();
    buttonsDiv.id = 'tab_buttons';
    h.SpanElement insertButton = new h.SpanElement();
    insertButton.id = 'insert_tab_button';
    insertButton.classes.add('tab_button');
    insertButton.classes.add('selected');
    insertButton.setAttribute('tabindex', '-1');
    insertButton.appendText(Strings.get('left.insert'));
    insertButton.onClick.listen((h.MouseEvent event) => page.focusManager.setFocus(this, _insertP));
    buttonsDiv.append(insertButton);
    h.SpanElement treeButton = new h.SpanElement();
    treeButton.id = 'tree_tab_button';
    treeButton.classes.add('tab_button');
    treeButton.setAttribute('tabindex', '-1');
    treeButton.appendText(Strings.get('left.tree'));
    treeButton.onClick.listen((h.MouseEvent event) => page.focusManager.setFocus(this, _treeP));
    buttonsDiv.append(treeButton);
    panelDiv.append(buttonsDiv);
    h.DivElement insertDiv = new h.DivElement();
    insertDiv.id = 'insert';
    panelDiv.append(insertDiv);
    h.DivElement treeDiv = new h.DivElement();
    treeDiv.id = 'tree';
    treeDiv.style.display = 'none';
    panelDiv.append(treeDiv);
    return(panelDiv);
  }
  
  void selectInsertPanel() {
    h.document.getElementById('insert').style.display = 'block';
    h.document.getElementById('tree').style.display = 'none';
    h.document.getElementById('insert_tab_button').classes.add('selected');
    h.document.getElementById('tree_tab_button').classes.remove('selected');
    _selected = 0;
    if (page.getSelectionStart() == null)
      return;
    DaxeNode parent = page.getSelectionStart().dn;
    if (parent is DNText)
      parent = parent.parent;
    List<x.Element> refs = doc.elementsAllowedUnder(parent);
    List<x.Element> validRefs = doc.validElementsInSelection(refs);
    _insertP.update(parent, refs, validRefs);
  }
  
  void selectTreePanel() {
    h.document.getElementById('tree').style.display = 'block';
    h.document.getElementById('insert').style.display = 'none';
    h.document.getElementById('tree_tab_button').classes.add('selected');
    h.document.getElementById('insert_tab_button').classes.remove('selected');
    _selected = 1;
    _treeP.update();
  }
  
  void update(DaxeNode parent, List<x.Element> refs, List<x.Element> validRefs) {
    if (_selected == 0)
      _insertP.update(parent, refs, validRefs);
    else
      _treeP.update();
  }
  
  // FocusManager methods (using default attributes)
  
  int nextFocusKey = h.KeyCode.RIGHT;
  bool nextFocusShift = false;
  int previousFocusKey = h.KeyCode.LEFT;
  bool previousFocusShift = false;
  int selectKey = h.KeyCode.ENTER;
  int selectSubContainerKey = h.KeyCode.DOWN;
  bool selectSubContainerShift = false;
  int selectParentContainerKey = h.KeyCode.ESC;
  bool selectParentContainerShift = false;
  
  FocusContainer get parentFocusContainer {
    return page;
  }
  
  focusItem(Object item) {
    assert(focusableItems.contains(item));
    if (item == _insertP) {
      page._cursor.ta.blur();
      h.document.getElementById('insert_tab_button').focus();
      selectInsertPanel();
    } else if (item == _treeP) {
      page._cursor.ta.blur();
      h.document.getElementById('tree_tab_button').focus();
      selectTreePanel();
    }
  }
  
  unfocusItem(Object item) {
    assert(focusableItems.contains(item));
    if (item == _insertP) {
      h.document.getElementById('insert_tab_button').blur();
    } else if (item == _treeP) {
      h.document.getElementById('tree_tab_button').blur();
    }
  }
  
  selectItem(Object item) {
    assert(focusableItems.contains(item));
    focusItem(item);
  }
  
  List<Object> get focusableItems {
    return [_insertP, _treeP];
  }
}
