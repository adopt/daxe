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
 * Manages the application focus.
 */
class FocusManager {
  FocusContainer topContainer;
  Object itemWithFocus;
  FocusContainer containerWithFocus;
  StreamSubscription subscription;
  
  FocusManager(this.topContainer) {
    _newKeySubscription();
  }
  
  unfocus() {
    _cancelKeySubscription();
    if (containerWithFocus != null && itemWithFocus != null)
      containerWithFocus.unfocusItem(itemWithFocus);
    itemWithFocus = null;
    containerWithFocus = null;
  }
  
  setFocus(FocusContainer container, Object item) {
    if (container != null) {
      if (subscription == null) {
        _newKeySubscription();
      }
    } else {
      _cancelKeySubscription();
    }
    if (itemWithFocus != null && itemWithFocus != container)
      containerWithFocus.unfocusItem(itemWithFocus);
    containerWithFocus = container;
    itemWithFocus = item;
    containerWithFocus.focusItem(itemWithFocus);
  }
  
  handleKey(h.KeyboardEvent event) {
    if (h.document.activeElement != null && h.document.activeElement.nodeName == 'BUTTON' ||
        h.document.activeElement.nodeName == 'INPUT')
      return;
    if (containerWithFocus == null)
      return;
    int keyCode = event.keyCode;
    bool shift = event.shiftKey;
    Object newItem = null;
    FocusContainer newContainer = null;
    FocusContainer testContainer = containerWithFocus;
    Object testItem = itemWithFocus;
    while (testContainer != null && newItem == null) {
      if (testItem == null && testContainer.nextFocusKey == keyCode &&
          testContainer.nextFocusShift == shift) {
        newItem = _firstFocusable(testContainer);
        if (newItem != null)
          newContainer = testContainer;
      } else if (testItem != null && testContainer.nextFocusKey == keyCode &&
          testContainer.nextFocusShift == shift) {
        newItem = _nextFocusable(testContainer, testItem);
        if (newItem == null && testContainer.parentFocusContainer == null &&
            keyCode == h.KeyCode.TAB)
          newItem = _firstFocusable(testContainer);
        if (newItem != null)
          newContainer = testContainer;
      } else if (testItem != null && testContainer.previousFocusKey == keyCode &&
          testContainer.previousFocusShift == shift) {
        newItem = _previousFocusable(testContainer, testItem);
        if (newItem == null && testContainer.parentFocusContainer == null &&
            keyCode == h.KeyCode.TAB && shift)
          newItem = _lastFocusable(testContainer);
        if (newItem != null)
          newContainer = testContainer;
      } else if (testItem != null && testContainer.selectKey == keyCode && !shift) {
        testContainer.selectItem(testItem);
        event.preventDefault();
        if (testItem is FocusContainer) {
          List<Object> items = (testItem as FocusContainer).focusableItems;
          if (items.length > 0) {
            newContainer = testItem;
            newItem = items[0];
          }
        }
        break;
      } else if (testItem is FocusContainer && testContainer.selectSubContainerKey == keyCode &&
          testContainer.selectSubContainerShift == shift) {
        testContainer.selectItem(testItem);
        List<Object> items = (testItem as FocusContainer).focusableItems;
        if (items.length > 0) {
          newContainer = testItem;
          newItem = items[0];
        }
      } else if (testContainer.parentFocusContainer != null && testContainer.selectParentContainerKey == keyCode &&
          testContainer.selectParentContainerShift == shift) {
        newContainer = testContainer.parentFocusContainer;
        newItem = testContainer;
      }
      testItem = testContainer;
      testContainer = testContainer.parentFocusContainer;
    }
    if (newItem != null) {
      setFocus(newContainer, newItem);
      event.preventDefault();
    }
  }
  
  _newKeySubscription() {
    subscription = h.document.onKeyDown.listen((h.KeyboardEvent event) => handleKey(event));
  }
  
  _cancelKeySubscription() {
    subscription.cancel();
    subscription = null;
  }
  
  Object _nextFocusable(FocusContainer testContainer, Object testItem) {
    int currentIndex;
    List<Object> items = testContainer.focusableItems;
    if (testItem == null)
      currentIndex = -1;
    else {
      currentIndex = items.indexOf(testItem);
      if (currentIndex == -1) {
        // item cannot be focused
      }
    }
    if (currentIndex + 1 < items.length)
      return items[currentIndex + 1];
    else
      return null;
  }
  
  Object _previousFocusable(FocusContainer testContainer, Object testItem) {
    int currentIndex;
    List<Object> items = testContainer.focusableItems;
    if (testItem == null)
      currentIndex = items.length;
    else {
      currentIndex = items.indexOf(testItem);
      if (currentIndex == -1)
        currentIndex = items.length;
    }
    if (currentIndex - 1 >= 0)
      return items[currentIndex - 1];
    else
      return null;
  }
  
  Object _firstFocusable(FocusContainer testContainer) {
    if (testContainer == null)
      return null;
    List<Object> items = testContainer.focusableItems;
    if (items.length > 0)
      return(items[0]);
    return null;
  }
  
  Object _lastFocusable(FocusContainer testContainer) {
    if (testContainer == null)
      return null;
    List<Object> items = testContainer.focusableItems;
    if (items.length > 0)
      return(items[items.length - 1]);
    return null;
  }
  
}
