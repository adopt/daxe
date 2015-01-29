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
  
  TreePanel() {
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
  
}
