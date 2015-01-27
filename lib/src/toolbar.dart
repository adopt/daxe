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

class Toolbar implements FocusContainer {
  List<ToolbarItem> items;
  List<x.Element> cacheRefs = null;
  static final String iconPath = 'packages/daxe/images/toolbar/';
  
  Toolbar([Config cfg]) {
    items = new List<ToolbarItem>();
    if (doc.saveURL != null) {
      ToolbarBox documentBox = new ToolbarBox();
      documentBox.add(new ToolbarButton(Strings.get('menu.save'), iconPath + 'document_save.png',
          () => page.save(), null));
      items.add(documentBox);
    }
    ToolbarBox historyBox = new ToolbarBox();
    historyBox.add(new ToolbarButton(Strings.get('undo.undo'), iconPath + 'history_undo.png',
        () => doc.undo(), null, data:"undo", enabled:false));
    historyBox.add(new ToolbarButton(Strings.get('undo.redo'), iconPath + 'history_redo.png',
        () => doc.redo(), null, data:"redo", enabled:false));
    items.add(historyBox);
    ToolbarBox findBox = new ToolbarBox();
    findBox.add(new ToolbarButton(Strings.get('find.find_replace'), iconPath + 'find.png',
        () => (new FindDialog()).show(), null));
    items.add(findBox);
    if (cfg != null) {
      // Buttons to insert new elements
      ToolbarBox insertBox = new ToolbarBox();
      List<x.Element> refs = cfg.elementsWithType('fichier');
      if (refs != null && refs.length > 0) {
        addInsertButton(cfg, insertBox, refs, iconPath + 'insert_image.png');
      }
      refs = cfg.elementsWithType('equationmem');
      if (refs != null && refs.length > 0) {
        addInsertButton(cfg, insertBox, refs, iconPath + 'equation.png');
      }
      refs = cfg.elementsWithType('symbole2');
      if (refs != null && refs.length > 0) {
        addInsertButton(cfg, insertBox, refs, iconPath + 'insert_symbol.png');
      }
      refs = cfg.elementsWithType('tabletexte');
      if (refs != null && refs.length > 0) {
        addInsertButton(cfg, insertBox, refs, iconPath + 'insert_table.png');
      }
      refs = cfg.elementsWithType('liste');
      if (refs != null && refs.length > 0) {
        addInsertButton(cfg, insertBox, refs, iconPath + 'ul.png');
      }
      items.add(insertBox);
      // List buttons
      List<x.Element> ulRefs = DNWList.ulRefs();
      List<x.Element> olRefs = DNWList.olRefs();
      if (ulRefs.length > 0 || olRefs.length > 0) {
        ToolbarBox listBox = new ToolbarBox();
        if (ulRefs.length > 0) {
          ToolbarButton button = new ToolbarButton(_documentationFor(ulRefs[0]), iconPath + 'ul.png',
              null, listButtonUpdate, data:new ToolbarStyleInfo(ulRefs, null, null));
          button.action = () {
            if (button.selected)
              DNWList.riseLevel();
            else
              DNWList.addList((button.data as ToolbarStyleInfo).validRef);
          };
          listBox.add(button);
        }
        if (olRefs.length > 0) {
          ToolbarButton button = new ToolbarButton(_documentationFor(olRefs[0]), iconPath + 'ol.png',
              null, listButtonUpdate, data:new ToolbarStyleInfo(olRefs, null, null));
          button.action = () {
            if (button.selected)
              DNWList.riseLevel();
            else
              DNWList.addList((button.data as ToolbarStyleInfo).validRef);
          };
          listBox.add(button);
        }
        listBox.add(new ToolbarButton(Strings.get('toolbar.rise_list_level'), iconPath + 'list_rise_level.png',
            () => DNWList.riseLevel(), riseListLevelButtonUpdate, data:'rise_list_level'));
        bool possibleListInItem = true; // will be true if it is always possible to have a list in an item of the same type
        for (x.Element ulRef in ulRefs)
          if (doc.cfg.findSubElement(DNWList.findItemRef(ulRef), ulRefs) == null)
            possibleListInItem = false;
        for (x.Element olRef in olRefs)
          if (doc.cfg.findSubElement(DNWList.findItemRef(olRef), olRefs) == null)
            possibleListInItem = false;
        if (possibleListInItem)
          listBox.add(new ToolbarButton(Strings.get('toolbar.lower_list_level'), iconPath + 'list_lower_level.png',
              () => DNWList.lowerLevel(), lowerListLevelButtonUpdate, data:'lower_list_level'));
        items.add(listBox);
      }
      // Link/Anchor buttons
      List<x.Element> aRefs = DNAnchor.aRefs();
      if (aRefs != null && aRefs.length > 0) {
        ToolbarBox anchorBox = new ToolbarBox();
        ToolbarButton button = new ToolbarButton(Strings.get('toolbar.insert_link'),
            iconPath + 'add_link.png',
            null, insertLinkButtonUpdate,
            data:new ToolbarStyleInfo(aRefs, null, null));
        button.action = () => DNAnchor.addLink((button.data as ToolbarStyleInfo).validRef);
        anchorBox.add(button);
        button = new ToolbarButton(Strings.get('toolbar.remove_link'),
            iconPath + 'remove_link.png',
            () => DNAnchor.removeLink(), removeLinkButtonUpdate, 
            data:new ToolbarStyleInfo(aRefs, null, null));
        anchorBox.add(button);
        button = new ToolbarButton(Strings.get('toolbar.insert_anchor'),
            iconPath + 'anchor.png',
            null, insertButtonUpdate,
            data:new ToolbarStyleInfo(aRefs, null, null));
        button.action = () => DNAnchor.addAnchor((button.data as ToolbarStyleInfo).validRef);
        anchorBox.add(button);
        items.add(anchorBox);
      }
      // Style buttons
      ToolbarBox styleBox = new ToolbarBox();
      List<x.Element> all = cfg.allElementsList();
      for (x.Element ref in all) {
        String dtype = cfg.elementDisplayType(ref);
        if (dtype == 'style') {
          String style = cfg.elementParameterValue(ref, 'style', null);
          if (style == 'GRAS') {
            addStyleButton(cfg, styleBox, ref, iconPath + 'style_bold.png', 'B');
          } else if (style == 'ITALIQUE') {
            addStyleButton(cfg, styleBox, ref, iconPath + 'style_italic.png', 'I');
          } else if (style == 'EXPOSANT') {
            addStyleButton(cfg, styleBox, ref, iconPath + 'style_superscript.png');
          } else if (style == 'INDICE') {
            addStyleButton(cfg, styleBox, ref, iconPath + 'style_subscript.png');
          } else if (style == 'BARRE') {
            addStyleButton(cfg, styleBox, ref, iconPath + 'style_strikethrough.png');
          } else if (style == 'SOULIGNE') {
            addStyleButton(cfg, styleBox, ref, iconPath + 'style_underline.png');
          }
        }
      }
      if (styleBox.length > 0) {
        styleBox.add(new ToolbarButton(Strings.get('toolbar.remove_styles'), iconPath + 'remove_styles.png',
            () => DNStyle.removeStylesFromSelection(), null, data:"remove_styles"));
        items.add(styleBox);
      }
      if (doc.hiddenParaRefs != null) {
        // Align buttons
        String pStyleAtt = doc.cfg.elementParameterValue(doc.hiddenParaRefs[0], 'styleAtt', 'style');
        // check if style attribute is allowed for hidden paragraphs
        List<x.Element> attRefs = doc.cfg.elementAttributes(doc.hiddenParaRefs[0]);
        bool found = false;
        for (x.Element attRef in attRefs) {
          if (doc.cfg.attributeName(attRef) == pStyleAtt) {
            found = true;
            break;
          }
        }
        if (found) {
          ToolbarBox alignBox = new ToolbarBox();
          addParagraphCssButton(alignBox, 'text-align', 'left',
              Strings.get('toolbar.align_left'), iconPath + 'align_left.png');
          addParagraphCssButton(alignBox, 'text-align', 'right',
              Strings.get('toolbar.align_right'), iconPath + 'align_right.png');
          addParagraphCssButton(alignBox, 'text-align', 'center',
              Strings.get('toolbar.align_center'), iconPath + 'align_center.png');
          addParagraphCssButton(alignBox, 'text-align', 'justify',
              Strings.get('toolbar.align_justify'), iconPath + 'align_justify.png');
          items.add(alignBox);
        }
      }
      x.Element spanRef = DNStyleSpan.styleSpanRef();
      if (spanRef != null) {
        // Font menu
        List<String> fonts = ['serif', 'sans-serif', 'cursive', 'fantasy', 'monospace'];
        ToolbarMenu tbmenu = _makeStyleToolbarMenu(Strings.get('toolbar.font'), "font-family", fonts);
        items.add(tbmenu);
        /*
        A size menu is a bad idea: larger font sizes are used for titles and it is
        important to be able to extract titles automatically
        
        // Size menu
        List<String> sizes = ['8', '9', '10', '11', '12', '14', '16', '18',
                              '20', '24', '28', '32', '36', '48', '72'];
        tbmenu = _makeStyleToolbarMenu(Strings.get('toolbar.size'), "font-size", sizes, "px");
        items.add(tbmenu);
        */
      }
    }
  }
  
  ToolbarMenu _makeStyleToolbarMenu(String title, String cssName, List<String> cssValues,
                                    [String cssUnit]) {
    Menu menu = new Menu(title);
    menu.parent = this;
    x.Element styleRef = DNStyleSpan.styleSpanRef();
    for (String cssValue in cssValues) {
      String cssValueWithUnit = cssValue;
      if (cssUnit != null)
        cssValueWithUnit += cssUnit;
      MenuItem menuItem = new MenuItem(cssValue, null,
          data:new ToolbarStyleInfo([styleRef], cssName, cssValueWithUnit));
      menuItem.action = () {
        if (menuItem.checked) {
          Position start = page.getSelectionStart();
          Position end = page.getSelectionEnd();
          if (start == end && start.dn is DNText && start.dn.parent.ref == styleRef &&
              (start.dn.parent as DNStyle).matchesCss(cssName, cssValueWithUnit) &&
              start.dnOffset == start.dn.offsetLength && start.dn.nextSibling == null) {
            // we are at the end of the style
            // just move the cursor position outside of the style
            DaxeNode styleNode = start.dn.parent;
            page.moveCursorTo(new Position(styleNode.parent, styleNode.parent.offsetOf(styleNode)+1));
            page.updateAfterPathChange();
          } else
            DNStyle.removeStylesFromSelection(styleRef, cssName);
        } else {
          DNStyle.removeAndApplyStyleToSelection(styleRef, cssName, cssValueWithUnit);
        }
      };
      menu.add(menuItem);
    }
    ToolbarMenu tbmenu = new ToolbarMenu(menu, styleMenuUpdate);
    return(tbmenu);
  }
  
  add(ToolbarItem item) {
    items.add(item);
  }
  
  insert(ToolbarItem item, int position) {
    items.insert(position, item);
  }
  
  remove(int position) {
    items.remove(position);
  }
  
  List<ToolbarButton> get buttons {
    List<ToolbarButton> buttons = new List<ToolbarButton>();
    for (ToolbarItem item in items) {
      if (item is ToolbarBox)
        buttons.addAll(item.buttons);
    }
    return(buttons);
  }
  
  /**
   * Returns a list of all element references used in the toolbar.
   */
  List<x.Element> elementRefs() {
    if (cacheRefs != null)
      return(cacheRefs);
    List<x.Element> list = new List<x.Element>();
    for (ToolbarItem item in items) {
      if (item is ToolbarBox) {
        for (ToolbarButton button in item.buttons) {
          if (button.data is ToolbarStyleInfo) {
            ToolbarStyleInfo info = button.data;
            if (info.possibleRefs != null)
              list.addAll(info.possibleRefs);
          }
        }
      } else if (item is ToolbarMenu) {
        Menu menu = item.menu;
        for (MenuItem menuItem in menu.items) {
          if (menuItem.data is ToolbarStyleInfo) {
            ToolbarStyleInfo info = menuItem.data;
            if (info.possibleRefs != null)
              list.addAll(info.possibleRefs);
          }
        }
      }
    }
    cacheRefs = list;
    return(list);
  }
  
  h.Element html() {
    h.DivElement div = new h.DivElement();
    div.classes.add('toolbar');
    for (ToolbarItem item in items) {
      div.append(item.html());
    }
    return(div);
  }
  
  String _documentationFor(x.Element ref) {
    String documentation = doc.cfg.documentation(ref);
    if (documentation == null)
      documentation = doc.cfg.elementTitle(ref);
    return(documentation);
  }
  
  addInsertButton(Config cfg, ToolbarBox box, List<x.Element> refs, String icon) {
    ToolbarButton button = new ToolbarButton(_documentationFor(refs[0]), icon,
        null, insertButtonUpdate,
        data:new ToolbarStyleInfo(refs, null, null));
    button.action = () => doc.insertNewNode((button.data as ToolbarStyleInfo).validRef, 'element');
    box.add(button);
  }
  
  static void insertButtonUpdate(ToolbarButton button, DaxeNode parent, DaxeNode selectedNode,
                             List<x.Element> validRefs, List<x.Element> ancestorRefs) {
    // element insert
    ToolbarStyleInfo info = button.data;
    List<x.Element> refs = info.possibleRefs;
    if (info.findValidRef(validRefs))
      button.enable();
    else
      button.disable();
  }
  
  addStyleButton(Config cfg, ToolbarBox box, x.Element ref, String icon, [String shortcut=null]) {
    ToolbarButton button = new ToolbarButton(_documentationFor(ref), icon, null, dnStyleButtonUpdate,
        data:new ToolbarStyleInfo([ref], null, null), shortcut:shortcut);
    button.action = () {
      if (button.selected) {
        Position start = page.getSelectionStart();
        Position end = page.getSelectionEnd();
        if (start == end && start.dn is DNText && start.dn.parent.ref == ref &&
            start.dnOffset == start.dn.offsetLength && start.dn.nextSibling == null) {
          // we are at the end of the style
          // just move the cursor position outside of the style
          DaxeNode styleNode = start.dn.parent;
          page.moveCursorTo(new Position(styleNode.parent, styleNode.parent.offsetOf(styleNode)+1));
          page.updateAfterPathChange();
        } else
          DNStyle.removeStylesFromSelection(ref);
      } else {
        DNStyle.applyStyleInsideSelection(ref);
      }
    };
    box.add(button);
  }
  
  static void dnStyleButtonUpdate(ToolbarButton button, DaxeNode parent, DaxeNode selectedNode,
                             List<x.Element> validRefs, List<x.Element> ancestorRefs) {
    // DNStyle, style with no css (as with the b element)
    ToolbarStyleInfo info = button.data;
    List<x.Element> refs = info.possibleRefs;
    bool foundAncestor = false;
    for (x.Element possibleRef in refs) {
      if (ancestorRefs.contains(possibleRef)) {
        foundAncestor = true;
        break;
      }
    }
    if (foundAncestor) {
      button.enable();
      button.select();
    } else {
      if (selectedNode != null && refs.contains(selectedNode.ref))
        button.select();
      else
        button.deselect();
      if (info.findValidRef(validRefs))
        button.enable();
      else
        button.disable();
    }
  }
  
  static void styleSpanButtonUpdate(ToolbarButton button, DaxeNode parent, DaxeNode selectedNode,
                             List<x.Element> validRefs, List<x.Element> ancestorRefs) {
    // DNSpanStyle, span style
    ToolbarStyleInfo info = button.data;
    x.Element ref = info.possibleRefs[0];
    bool foundAncestor = false;
    for (DaxeNode n = parent; n != null; n = n.parent) {
      if (n.ref == ref && (n as DNStyleSpan).matchesCss(info.cssName, info.cssValue)) {
        foundAncestor = true;
        break;
      }
    }
    if (foundAncestor) {
      button.enable();
      button.select();
    } else {
      if (selectedNode != null && ref == selectedNode.ref &&
          (selectedNode as DNStyleSpan).matchesCss(info.cssName, info.cssValue)) {
        button.select();
      } else {
        button.deselect();
      }
      if (validRefs.contains(ref))
        button.enable();
      else
        button.disable();
    }
  }
  
  addParagraphCssButton(ToolbarBox alignBox, String cssName, String cssValue,
                         String title, String icon) {
    ToolbarButton button = new ToolbarButton(title, icon,
        null, paragraphButtonUpdate, data:new ToolbarStyleInfo(doc.hiddenParaRefs, cssName, cssValue));
    button.action = () {
      if (button.selected) {
        DNHiddenP.removeStyleFromSelection(cssName);
      } else {
        DNHiddenP.applyStyleToSelection(cssName, cssValue);
      }
    };
    alignBox.add(button);
  }
  
  static void paragraphButtonUpdate(ToolbarButton button, DaxeNode parent, DaxeNode selectedNode,
                             List<x.Element> validRefs, List<x.Element> ancestorRefs) {
    ToolbarStyleInfo info = button.data;
    bool foundAncestor = false;
    for (DaxeNode n = parent; n != null; n = n.parent) {
      if (doc.hiddenParaRefs.contains(n.ref)) {
        if ((n as DNHiddenP).matchesCss(info.cssName, info.cssValue)) {
          foundAncestor = true;
          break;
        }
      }
    }
    if (foundAncestor) {
      button.enable();
      button.select();
    } else {
      if (selectedNode != null && doc.hiddenParaRefs.contains(selectedNode.ref) &&
          (selectedNode as DNHiddenP).matchesCss(info.cssName, info.cssValue)) {
        button.select();
      } else {
        button.deselect();
      }
      if (DNHiddenP.paragraphsInSelection().length > 0)
        button.enable();
      else
        button.disable();
    }
  }
  
  static void listButtonUpdate(ToolbarButton button, DaxeNode parent, DaxeNode selectedNode,
                             List<x.Element> validRefs, List<x.Element> ancestorRefs) {
    // toggle list button
    ToolbarStyleInfo info = button.data;
    List<x.Element> refs = info.possibleRefs;
    bool foundAncestor = false;
    for (DaxeNode n = parent; n != null; n = n.parent) {
      if (refs.contains(n.ref)) {
        foundAncestor = true;
        break;
      }
    }
    if (foundAncestor) {
      button.enable();
      button.select();
    } else {
      button.deselect();
      if (info.findValidRef(validRefs))
        button.enable();
      else
        button.disable();
    }
  }
  
  static void riseListLevelButtonUpdate(ToolbarButton button, DaxeNode parent, DaxeNode selectedNode,
                             List<x.Element> validRefs, List<x.Element> ancestorRefs) {
    Position start = page.getSelectionStart();
    DaxeNode dn = start.dn;
    while (dn != null && dn is! DNWItem)
      dn = dn.parent;
    if (dn != null)
      button.enable();
    else
      button.disable();
  }
  
  static void lowerListLevelButtonUpdate(ToolbarButton button, DaxeNode parent, DaxeNode selectedNode,
                             List<x.Element> validRefs, List<x.Element> ancestorRefs) {
    Position start = page.getSelectionStart();
    DaxeNode dn = start.dn;
    while (dn != null && dn is! DNWItem)
      dn = dn.parent;
    if (dn == null || dn.previousSibling == null)
      button.disable();
    else
      button.enable();
  }
  
  static void insertLinkButtonUpdate(ToolbarButton button, DaxeNode parent, DaxeNode selectedNode,
                             List<x.Element> validRefs, List<x.Element> ancestorRefs) {
    ToolbarStyleInfo info = button.data;
    if (page.getSelectionStart().dn is DNText && info.findValidRef(validRefs))
      button.enable();
    else
      button.disable();
  }
  
  static void removeLinkButtonUpdate(ToolbarButton button, DaxeNode parent, DaxeNode selectedNode,
                             List<x.Element> validRefs, List<x.Element> ancestorRefs) {
    ToolbarStyleInfo info = button.data;
    List<x.Element> refs = info.possibleRefs;
    bool foundAncestor = false;
    for (x.Element possibleRef in refs) {
      if (ancestorRefs.contains(possibleRef)) {
        foundAncestor = true;
        break;
      }
    }
    if (foundAncestor)
      button.enable();
    else
      button.disable();
  }
  
  static void styleMenuUpdate(ToolbarMenu tbmenu, DaxeNode parent, DaxeNode selectedNode,
                             List<x.Element> validRefs, List<x.Element> ancestorRefs) {
    Menu menu = tbmenu.menu;
    MenuItem selectedItem = null;
    for (MenuItem menuItem in menu.items) {
      if (menuItem.data is ToolbarStyleInfo) {
        ToolbarStyleInfo info = menuItem.data;
        x.Element ref = info.possibleRefs[0];
        String cssName = info.cssName;
        String cssValue = info.cssValue;
        if (doc.hiddenParaRefs.contains(ref)) {
          // paragraph style
          bool foundAncestor = false;
          for (DaxeNode n = parent; n != null; n = n.parent) {
            if (doc.hiddenParaRefs.contains(n.ref) && (n as DNHiddenP).matchesCss(cssName, cssValue)) {
              foundAncestor = true;
              break;
            }
          }
          if (foundAncestor) {
            menuItem.enable();
            selectedItem = menuItem;
            menuItem.check();
          } else {
            if (selectedNode != null && doc.hiddenParaRefs.contains(selectedNode.ref) &&
                (selectedNode as DNHiddenP).matchesCss(cssName, cssValue)) {
              selectedItem = menuItem;
              menuItem.check();
            } else {
              menuItem.uncheck();
            }
            if (DNHiddenP.paragraphsInSelection().length > 0)
              menuItem.enable();
            else
              menuItem.disable();
          }
        } else if (doc.cfg.elementDisplayType(ref) == 'style') {
          // DNStyle
          if (ancestorRefs.contains(ref)) {
            menuItem.enable();
            selectedItem = menuItem;
          } else {
            if (selectedNode != null && ref == selectedNode.ref)
              selectedItem = menuItem;
            if (validRefs.contains(ref))
              menuItem.enable();
            else
              menuItem.disable();
          }
        } else if (doc.cfg.elementDisplayType(ref) == 'stylespan') {
          // DNSpanStyle
          bool foundAncestor = false;
          for (DaxeNode n = parent; n != null; n = n.parent) {
            if (n.ref == ref && (n as DNStyleSpan).matchesCss(cssName, cssValue)) {
              foundAncestor = true;
              break;
            }
          }
          if (foundAncestor) {
            menuItem.enable();
            selectedItem = menuItem;
            menuItem.check();
          } else {
            if (selectedNode != null && ref == selectedNode.ref &&
                (selectedNode as DNStyleSpan).matchesCss(cssName, cssValue)) {
              selectedItem = menuItem;
              menuItem.check();
            } else {
              menuItem.uncheck();
            }
            if (validRefs.contains(ref))
              menuItem.enable();
            else
              menuItem.disable();
          }
        } else if (ref != null) {
          // element insert
          if (validRefs.contains(ref))
            menuItem.enable();
          else
            menuItem.disable();
        }
      }
    }
    if (selectedItem == null)
      menu.title = tbmenu.title;
    else
      menu.title = selectedItem.title;
  }
  
  static void insertMenuUpdate(ToolbarMenu tbmenu, DaxeNode parent, DaxeNode selectedNode,
                             List<x.Element> validRefs, List<x.Element> ancestorRefs) {
    Menu menu = tbmenu.menu;
    for (MenuItem menuItem in menu.items) {
      if (menuItem.data is ToolbarStyleInfo) {
        ToolbarStyleInfo info = menuItem.data;
        List<x.Element> refs = info.possibleRefs;
        if (refs != null && refs.length > 0) {
          // element insert
          if (info.findValidRef(validRefs))
            menuItem.enable();
          else
            menuItem.disable();
        }
      }
    }
  }
  
  void update(DaxeNode parent, List<x.Element> validRefs) {
    List<x.Element> ancestorRefs = new List<x.Element>();
    for (DaxeNode n = parent; n != null; n = n.parent)
      ancestorRefs.add(n.ref);
    DaxeNode selectedNode = null;// will be !=null when the selection matches a full element
    Position start = page.getSelectionStart();
    Position end = page.getSelectionEnd();
    if (start.dn is! DNText && start.dn.offsetLength > start.dnOffset) {
      if (end == new Position(start.dn, start.dnOffset + 1))
        selectedNode = start.dn.childAtOffset(start.dnOffset);
    }
    // update buttons
    for (ToolbarButton button in buttons) {
      if (button.update != null)
        button.update(button, parent, selectedNode, validRefs, ancestorRefs);
    }
    // update menus
    for (ToolbarItem tbitem in items) {
      if (tbitem is ToolbarMenu) {
        tbitem.update(tbitem, parent, selectedNode, validRefs, ancestorRefs);
      }
    }
  }
  
  // FocusManager attributes and methods
  
  int nextFocusKey = h.KeyCode.TAB;
  bool nextFocusShift = false;
  int previousFocusKey = h.KeyCode.TAB;
  bool previousFocusShift = true;
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
    for (Object focusItem in focusableItems) {
      if (focusItem == item) {
        if (item is ToolbarButton) {
          //item.select();
          item.getHTMLNode().focus();
        } else if (item is Menu) {
          (item as MenuItem).select();
          (item as Menu).getItemHTMLNode().focus();
        }
      }
    }
  }
  
  unfocusItem(Object item) {
    assert(focusableItems.contains(item));
    for (Object focusItem in focusableItems) {
      if (focusItem == item) {
        if (item is ToolbarButton) {
          item.deselect();
          item.getHTMLNode().blur();
        } else if (item is Menu) {
          (item as MenuItem).deselect();
          (item as Menu).getItemHTMLNode().blur();
        }
      }
    }
  }
  
  selectItem(Object item) {
    assert(focusableItems.contains(item));
    if (item is ToolbarButton) {
      unfocusItem(item);
      item.action();
    } else
      focusItem(item);
  }
  
  List<Object> get focusableItems {
    List<Object> focusItems = new List<Object>();
    for (ToolbarItem item in items) {
      if (item is ToolbarBox) {
        for (ToolbarButton button in item.buttons) {
          if (button.enabled)
            focusItems.add(button);
        }
      } else if (item is ToolbarMenu)
        focusItems.add(item.menu);
    }
    return(focusItems);
  }
}
