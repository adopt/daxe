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
  TreeItem rootItem;
  /** items to collapse next time an item is selected automatically */
  List<TreeItem> itemsToCollapse;
  /** item that was selected automatically with selectNode */
  TreeItem autoSelectedItem;
  
  TreePanel() {
    itemsToCollapse = new List<TreeItem>();
  }
  
  void update() {
    if (rootItem == null && doc.getRootElement() != null) {
      rootItem = new TreeItem(doc.getRootElement(), null);
      _initialExpand();
      h.DivElement treeDiv = h.document.getElementById('tree');
      treeDiv.append(rootItem.div);
    } else {
      if (rootItem == null) {
        if (doc.getRootElement() != null) {
          rootItem = new TreeItem(doc.getRootElement(), null);
          h.DivElement treeDiv = h.document.getElementById('tree');
          treeDiv.append(rootItem.div);
        }
      } else  {
        if (doc.getRootElement() == null) {
          rootItem.div.remove();
          rootItem = null;
        } else if (doc.getRootElement() != rootItem.dn) {
          rootItem.div.remove();
          rootItem = new TreeItem(doc.getRootElement(), null);
          _initialExpand();
          h.DivElement treeDiv = h.document.getElementById('tree');
          treeDiv.append(rootItem.div);
        } else
          rootItem.update();
      }
    }
  }
  
  /**
   * After opening a document, expand only root and the first level under root.
   */
  void _initialExpand() {
    if (!rootItem.canExpand)
      return;
    if (!rootItem.expanded)
      rootItem.toggleExpand();
    if (rootItem.children.length < 10) {
      for (TreeItem item=rootItem.firstChild; item != null; item=item.nextSibling) {
        if (item.canExpand && !item.expanded)
          item.toggleExpand();
      }
    }
  }
  
  /**
   * Selects a node, expanding parents if necessary.
   * Previously automatically expanded parents are collapsed.
   */
  void selectNode(DaxeNode dn) {
    if (autoSelectedItem != null) {
      autoSelectedItem.deselect();
      autoSelectedItem = null;
    }
    for (TreeItem item in itemsToCollapse)
      if (item.expanded)
        item.toggleExpand();
    itemsToCollapse.clear();
    
    if (rootItem == null || dn is DNDocument)
      return;
    if (dn.parent is DNDocument && dn != rootItem.dn)
      return;
    
    var ancestors = new List<DaxeNode>();
    DaxeNode p = dn.parent;
    while (p != null && p is! DNDocument) {
      ancestors.add(p);
      p = p.parent;
    }
    TreeItem item;
    if (ancestors.length > 0) {
      item = null;
      for (DaxeNode p in ancestors.reversed) {
        if (item == null)
          item = rootItem;
        else {
          item = item.getChildForDaxeNode(p);
          if (item == null)
            return;
        }
        if (!item.expanded) {
          item.toggleExpand();
          itemsToCollapse.add(item);
        }
      }
      itemsToCollapse = new List.from(itemsToCollapse.reversed);
      item = item.getChildForDaxeNode(dn);
    } else {
      item = rootItem;
    }
    autoSelectedItem = item;
    item.select();
  }
  
}
