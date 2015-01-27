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
 * Container of focusable items. At least get parentFocusContainer, focusItem, unfocusItem,
 * selectItem and get focusableItems need to be implemented.
 */
abstract class FocusContainer {
  int nextFocusKey = h.KeyCode.TAB;
  bool nextFocusShift = false;
  int previousFocusKey = h.KeyCode.TAB;
  bool previousFocusShift = true;
  int selectKey = h.KeyCode.ENTER;
  int selectSubContainerKey = 0;
  bool selectSubContainerShift = false;
  int get selectParentContainerKey {
    return h.KeyCode.ESC;
  }
  bool selectParentContainerShift = false;
  
  /**
   * Returns the parent FocusContainer, or null.
   */
  FocusContainer get parentFocusContainer {
    return null;
  }
  
  /**
   * Changes the container UI to reflect the fact that this item has the focus.
   */
  focusItem(Object item);
  
  /**
   * Changes the container UI to reflect the fact that this item has lost the focus.
   */
  unfocusItem(Object item);
  
  /**
   * Selects or activates the given item.
   */
  selectItem(Object item);
  
  /**
   * Returns the list of focusable items.
   */
  List<Object> get focusableItems;
}
