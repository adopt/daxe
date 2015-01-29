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
 * Visible element in the tree panel.
 */
class TreeItem {
  DaxeNode dn;
  TreeItem parent;
  TreeItem firstChild;
  TreeItem nextSibling;
  bool expanded;
  h.DivElement div;
  h.SpanElement titleSpan;
  h.SpanElement expandButton;
  
  TreeItem(this.dn, this.parent) {
    expanded = false;
    createDiv();
    if (dn.parent == doc.dndoc) {
      // expand root automatically
      toggleExpand();
    }
  }
  
  void createChildren() {
    for (DaxeNode child = dn.firstChild; child != null; child=child.nextSibling) {
      if (child is! DNText) {
        appendChild(new TreeItem(child, this));
      }
    }
  }
  
  void removeChildren() {
    if (firstChild != null)
      removeChildrenStartingAt(firstChild);
  }
  
  void removeChildrenStartingAt(TreeItem child) {
    TreeItem item = child;
    while (item != null) {
      if (item.div != null)
        item.div.remove();
      item = item.nextSibling;
    }
    if (firstChild == child)
      firstChild = null;
    else
      child.previousSibling.nextSibling = null;
  }
  
  TreeItem get lastChild {
    if (firstChild == null)
      return null;
    TreeItem item = firstChild;
    while (item.nextSibling != null) {
      item = item.nextSibling;
    }
    return item;
  }
  
  TreeItem get previousSibling {
    if (parent == null)
      return null;
    for (TreeItem item=parent.firstChild; item != null; item=item.nextSibling) {
      if (item.nextSibling == this)
        return item;
    }
    return null;
  }
  
  List<TreeItem> get children {
    List<TreeItem> list = new List<TreeItem>();
    for (TreeItem item=firstChild; item != null; item=item.nextSibling)
      list.add(item);
    return(list);
  }
  
  void appendChild(TreeItem child) {
    TreeItem last = lastChild;
    if (last == null) {
      firstChild = child;
    } else {
      last.nextSibling = child;
    }
    child.nextSibling = null;
    child.parent = this;
    div.append(child.div);
  }
  
  bool get canExpand {
    return hasNonTextChild(dn);
  }
  
  createDiv() {
    div = new h.DivElement();
    div.classes.add('tree_div');
    titleSpan = new h.SpanElement();
    titleSpan.classes.add('tree_node_title');
    titleSpan.setAttribute('tabindex', '-1');
    titleSpan.onKeyDown.listen((h.KeyboardEvent event) {
      int keyCode = event.keyCode;
      if (keyCode == h.KeyCode.DOWN) {
        if (firstChild != null)
          firstChild.focus();
        else if (nextSibling != null)
          nextSibling.focus();
        else if (parent != null) {
          TreeItem item = parent;
          while (item.nextSibling == null && item.parent != null)
            item = item.parent;
          if (item.nextSibling != null)
            item.nextSibling.focus();
        }
      } else if (keyCode == h.KeyCode.UP) {
        if (previousSibling != null) {
          TreeItem item = previousSibling;
          while (item.lastChild != null)
            item = item.lastChild;
          item.focus();
        } else if (parent != null)
          parent.focus();
        else
          h.document.getElementById('tree_tab_button').focus();
      } else if (keyCode == h.KeyCode.ENTER) {
        page.scrollToNode(dn);
      } else if (keyCode == h.KeyCode.RIGHT && canExpand) {
        if (!expanded)
          toggleExpand();
        firstChild.focus();
      } else if (keyCode == h.KeyCode.LEFT && expanded) {
        toggleExpand();
      } else if (keyCode == h.KeyCode.LEFT && parent != null) {
        parent.focus();
      }
    });
    if (dn.ref != null)
      titleSpan.appendText(doc.cfg.elementTitle(dn.ref));
    else
      titleSpan.appendText(dn.nodeName);
    titleSpan.onClick.listen((h.MouseEvent event) => page.scrollToNode(dn));
    if (hasNonTextChild(dn) && dn.parent != doc.dndoc) {
      // (root is always expanded, no need for a button)
      addExpandButton();
    }
    div.append(titleSpan);
  }
  
  void addExpandButton() {
    expandButton = new h.SpanElement();
    expandButton.classes.add('expand_button');
    h.ImageElement img = new h.ImageElement(width:9, height:9);
    if (expanded) {
      expandButton.classes.add('expanded');
      img.src = 'packages/daxe/images/expanded_tree.png';
    } else {
      expandButton.classes.add('collapsed');
      img.src = 'packages/daxe/images/collapsed_tree.png';
    }
    expandButton.append(img);
    expandButton.onClick.listen((h.MouseEvent event) => toggleExpand());
    div.append(expandButton);
  }
  
  void toggleExpand() {
    if (!expanded) {
      // expand
      createChildren();
      if (expandButton != null) {
        expandButton.classes.remove('collapsed');
        expandButton.classes.add('expanded');
        h.ImageElement img = expandButton.firstChild;
        img.src = 'packages/daxe/images/expanded_tree.png';
      }
    } else {
      // collapse
      removeChildren();
      if (expandButton != null) {
        expandButton.classes.remove('expanded');
        expandButton.classes.add('collapsed');
        h.ImageElement img = expandButton.firstChild;
        img.src = 'packages/daxe/images/collapsed_tree.png';
      }
    }
    expanded = !expanded;
  }
  
  void update() {
    if (expandButton == null && hasNonTextChild(dn) && dn.parent != doc.dndoc) {
      addExpandButton();
      expanded = true;
    } else if (expandButton != null && !hasNonTextChild(dn)) {
      removeChildren();
      expanded = false;
      expandButton.remove();
    }
    if (!expanded)
      return;
    TreeItem item = firstChild;
    for (DaxeNode child = dn.firstChild; child != null; child=child.nextSibling) {
      if (child is! DNText) {
        if (item == null) {
          item = new TreeItem(child, this);
          appendChild(item);
        } else if (item.dn != child) {
          removeChildrenStartingAt(item);
          item = new TreeItem(child, this);
          appendChild(item);
        } else {
          item.update();
        }
      }
      if (item != null)
        item = item.nextSibling;
    }
    if (item != null)
      removeChildrenStartingAt(item);
  }
  
  void focus() {
    titleSpan.focus();
  }
  
  static bool hasNonTextChild(DaxeNode dn) {
    for (DaxeNode child = dn.firstChild; child != null; child=child.nextSibling) {
      if (child is! DNText) {
        return(true);
      }
    }
    return(false);
  }
  
}
