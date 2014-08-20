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
 * Left panel showing the element tree.
 */
class TreePanel {
  List<DaxeNode> expanded;
  List<DaxeNode> collapsed;
  List<DaxeNode> existing;
  bool firstUpdate;
  
  TreePanel() {
    expanded = new List<DaxeNode>();
    collapsed = new List<DaxeNode>();
    firstUpdate = true;
  }
  
  void update() {
    h.DivElement treeDiv = h.document.getElementById('tree');
    treeDiv.children.clear();
    DaxeNode root = doc.getRootElement();
    if (firstUpdate) {
      firstUpdate = false;
      _initialExpand();
    }
    if (root != null)
      displayTree(root, treeDiv);
    
    _removeDeleted();
  }
  
  bool hasNonTextChild(DaxeNode dn) {
    for (DaxeNode child = dn.firstChild; child != null; child=child.nextSibling) {
      if (child is! DNText) {
        return(true);
      }
    }
    return(false);
  }
  
  /**
   * After opening a document, expand only root or the first level under root.
   */
  void _initialExpand() {
    DaxeNode root = doc.getRootElement();
    if (root != null && hasNonTextChild(root)) {
      expanded.add(root);
      if (root.offsetLength > 10) {
        for (DaxeNode dn = root.firstChild; dn != null; dn=dn.nextSibling) {
          if (dn is! DNText && hasNonTextChild(dn)) {
            _addToListRecursively(collapsed, dn);
          }
        }
      } else {
        for (DaxeNode dn = root.firstChild; dn != null; dn=dn.nextSibling) {
          if (dn is! DNText && hasNonTextChild(dn)) {
            expanded.add(dn);
            for (DaxeNode child = dn.firstChild; child != null; child=child.nextSibling) {
              if (child is! DNText && hasNonTextChild(child)) {
                _addToListRecursively(collapsed, child);
              }
            }
          }
        }
      }
    }
  }
  
  void _addToListRecursively(List<DaxeNode> list, DaxeNode dn) {
    list.add(dn);
    for (DaxeNode child = dn.firstChild; child != null; child=child.nextSibling) {
      if (child is! DNText && hasNonTextChild(child)) {
        _addToListRecursively(list, child);
      }
    }
  }
  
  void displayTree(DaxeNode dn, h.DivElement parentDiv) {
    h.DivElement div = new h.DivElement();
    div.classes.add('tree_div');
    h.SpanElement titleSpan = new h.SpanElement();
    titleSpan.classes.add('tree_node_title');
    if (dn.ref != null)
      titleSpan.appendText(doc.cfg.elementTitle(dn.ref));
    else
      titleSpan.appendText(dn.nodeName);
    titleSpan.onClick.listen((h.MouseEvent event) => page.scrollToNode(dn));
    if (!hasNonTextChild(dn)) {
      div.append(titleSpan);
    } else {
      bool bexp = expanded.contains(dn);
      if (!bexp && !collapsed.contains(dn)) {
        bexp = true; // new node expanded by default
        expanded.add(dn);
      }
      if (dn.parent != doc.dndoc) {
        h.SpanElement expandButton = new h.SpanElement();
        expandButton.classes.add('expand_button');
        h.ImageElement img = new h.ImageElement(width:9, height:9);
        if (bexp) {
          expandButton.classes.add('expanded');
          img.src = 'packages/daxe/images/expanded_tree.png';
        } else {
          expandButton.classes.add('collapsed');
          img.src = 'packages/daxe/images/collapsed_tree.png';
        }
        expandButton.append(img);
        expandButton.onClick.listen((h.MouseEvent event) => expand(dn, div));
        div.append(expandButton);
      }
      div.append(titleSpan);
      if (bexp) {
        for (DaxeNode child = dn.firstChild; child != null; child=child.nextSibling)
          if (child is! DNText)
            displayTree(child, div);
      }
    }
    parentDiv.append(div);
  }
  
  void expand(DaxeNode dn, h.DivElement div) {
    h.SpanElement expandButton = div.firstChild;
    if (expandButton.classes.contains('collapsed')) {
      // expand
      collapsed.remove(dn);
      expanded.add(dn);
      for (DaxeNode child = dn.firstChild; child != null; child=child.nextSibling)
        if (child is! DNText)
          displayTree(child, div);
      expandButton.classes.remove('collapsed');
      expandButton.classes.add('expanded');
      h.ImageElement img = expandButton.firstChild;
      img.src = 'packages/daxe/images/expanded_tree.png';
    } else {
      // collapse
      expanded.remove(dn);
      collapsed.add(dn);
      h.Element hn = expandButton.nextNode.nextNode;
      while (hn != null) {
        h.Element next = hn.nextNode;
        hn.remove();
        hn = next;
      }
      expandButton.classes.remove('expanded');
      expandButton.classes.add('collapsed');
      h.ImageElement img = expandButton.firstChild;
      img.src = 'packages/daxe/images/collapsed_tree.png';
    }
  }
  
  /**
   * Remove references of deleted nodes
   */
  void _removeDeleted() {
    DaxeNode root = doc.getRootElement();
    existing = new List<DaxeNode>();
    if (root != null && hasNonTextChild(root))
      _addToListRecursively(existing, root);
    for (int i=0; i<expanded.length; i++) {
      DaxeNode dn = expanded[i];
      if (!existing.contains(dn)) {
        expanded.remove(dn);
        i--;
      }
    }
    for (int i=0; i<collapsed.length; i++) {
      DaxeNode dn = collapsed[i];
      if (!existing.contains(dn)) {
        collapsed.remove(dn);
        i--;
      }
    }
  }
}
