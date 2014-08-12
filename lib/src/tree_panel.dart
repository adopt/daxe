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
  
  TreePanel() {
    expanded = new List<DaxeNode>();
    collapsed = new List<DaxeNode>();
  }
  
  void update() {
    h.DivElement treeDiv = h.document.getElementById('tree');
    treeDiv.children.clear();
    DaxeNode root = doc.getRootElement();
    existing = new List<DaxeNode>();
    if (root != null)
      displayTree(root, treeDiv);
    
    // remove references of deleted nodes
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
  
  void displayTree(DaxeNode dn, h.DivElement parentDiv) {
    existing.add(dn);
    h.DivElement div = new h.DivElement();
    div.classes.add('tree_div');
    bool subElement = false;
    for (DaxeNode child = dn.firstChild; child != null; child=child.nextSibling) {
      if (child is! DNText) {
        subElement = true;
        break;
      }
    }
    h.SpanElement titleSpan = new h.SpanElement();
    titleSpan.classes.add('tree_node_title');
    if (dn.ref != null)
      titleSpan.appendText(doc.cfg.elementTitle(dn.ref));
    else
      titleSpan.appendText(dn.nodeName);
    titleSpan.onClick.listen((h.MouseEvent event) => page.scrollToNode(dn));
    if (!subElement) {
      div.append(titleSpan);
    } else {
      bool bexp = expanded.contains(dn);
      if (!bexp && !collapsed.contains(dn)) {
        bexp = true; // expanded by default
        expanded.add(dn);
      }
      h.SpanElement expandButton = new h.SpanElement();
      expandButton.classes.add('expand_button');
      expandButton.appendText(bexp ? '-' : '+');
      expandButton.onClick.listen((h.MouseEvent event) => expand(dn, div));
      div.append(expandButton);
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
    if (expandButton.text == '+') {
      // expand
      collapsed.remove(dn);
      expanded.add(dn);
      for (DaxeNode child = dn.firstChild; child != null; child=child.nextSibling)
        if (child is! DNText)
          displayTree(child, div);
      expandButton.text = '-';
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
      expandButton.text = '+';
    }
  }
}
