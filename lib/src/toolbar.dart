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

class Toolbar {
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
      x.Element ref = cfg.firstElementWithType('fichier');
      if (ref != null) {
        addInsertButton(cfg, insertBox, ref, iconPath + 'insert_image.png');
      }
      ref = cfg.firstElementWithType('equationmem');
      if (ref != null) {
        addInsertButton(cfg, insertBox, ref, iconPath + 'equation.png');
      }
      ref = cfg.firstElementWithType('symbole2');
      if (ref != null) {
        addInsertButton(cfg, insertBox, ref, iconPath + 'insert_symbol.png');
      }
      ref = cfg.firstElementWithType('tabletexte');
      if (ref != null) {
        addInsertButton(cfg, insertBox, ref, iconPath + 'insert_table.png');
      }
      ref = cfg.firstElementWithType('liste');
      if (ref != null) {
        addInsertButton(cfg, insertBox, ref, iconPath + 'ul.png');
      }
      items.add(insertBox);
      // List buttons
      x.Element ulRef = DNWList.ulRef();
      x.Element olRef = DNWList.olRef();
      if (ulRef != null || olRef != null) {
        ToolbarBox listBox = new ToolbarBox();
        if (ulRef != null) {
          ToolbarButton button = new ToolbarButton(_documentationFor(ulRef), iconPath + 'ul.png',
              null, listButtonUpdate, data:new ToolbarStyleInfo(ulRef, null, null));
          button.action = () {
            if (button.selected)
              DNWList.riseLevel();
            else
              DNWList.addList((button.data as ToolbarStyleInfo).ref);
          };
          listBox.add(button);
        }
        if (olRef != null) {
          ToolbarButton button = new ToolbarButton(_documentationFor(olRef), iconPath + 'ol.png',
              null, listButtonUpdate, data:new ToolbarStyleInfo(olRef, null, null));
          button.action = () {
            if (button.selected)
              DNWList.riseLevel();
            else
              DNWList.addList((button.data as ToolbarStyleInfo).ref);
          };
          listBox.add(button);
        }
        listBox.add(new ToolbarButton(Strings.get('toolbar.rise_list_level'), iconPath + 'list_rise_level.png',
            () => DNWList.riseLevel(), riseListLevelButtonUpdate, data:'rise_list_level'));
        if (doc.cfg.isSubElement(DNWList.findItemRef(ulRef), ulRef) ||
            doc.cfg.isSubElement(DNWList.findItemRef(olRef), olRef))
          listBox.add(new ToolbarButton(Strings.get('toolbar.lower_list_level'), iconPath + 'list_lower_level.png',
              () => DNWList.lowerLevel(), lowerListLevelButtonUpdate, data:'lower_list_level'));
        items.add(listBox);
      }
      // Link/Anchor buttons
      x.Element aRef = DNAnchor.aRef();
      if (aRef != null) {
        ToolbarBox anchorBox = new ToolbarBox();
        ToolbarButton button = new ToolbarButton(Strings.get('toolbar.insert_link'),
            iconPath + 'add_link.png',
            () => DNAnchor.addLink(), insertLinkButtonUpdate,
            data:new ToolbarStyleInfo(aRef, null, null));
        anchorBox.add(button);
        button = new ToolbarButton(Strings.get('toolbar.remove_link'),
            iconPath + 'remove_link.png',
            () => DNAnchor.removeLink(), removeLinkButtonUpdate, 
            data:new ToolbarStyleInfo(aRef, null, null));
        anchorBox.add(button);
        button = new ToolbarButton(Strings.get('toolbar.insert_anchor'),
            iconPath + 'anchor.png',
            () => DNAnchor.addAnchor(), insertButtonUpdate,
            data:new ToolbarStyleInfo(aRef, null, null));
        anchorBox.add(button);
        items.add(anchorBox);
      }
      // Style buttons
      ToolbarBox styleBox = new ToolbarBox();
      List<x.Element> all = cfg.allElementsList();
      for (ref in all) {
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
      if (doc.hiddenp != null) {
        // Align buttons
        String pStyleAtt = doc.cfg.elementParameterValue(doc.hiddenp, 'styleAtt', 'style');
        // check if style attribute is allowed for hidden paragraphs
        List<x.Element> attRefs = doc.cfg.elementAttributes(doc.hiddenp);
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
      ref = DNStyleSpan.styleSpanRef();
      if (ref != null) {
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
    x.Element styleRef = DNStyleSpan.styleSpanRef();
    for (String cssValue in cssValues) {
      String cssValueWithUnit = cssValue;
      if (cssUnit != null)
        cssValueWithUnit += cssUnit;
      String css = "$cssName: $cssValueWithUnit";
      MenuItem menuItem = new MenuItem(cssValue, null,
          data:new ToolbarStyleInfo(styleRef, cssName, cssValueWithUnit));
      menuItem.action = () {
        if (menuItem.checked) {
          Position start = page.getSelectionStart();
          Position end = page.getSelectionEnd();
          if (start == end && start.dn is DNText && start.dn.parent.ref == styleRef &&
              (start.dn.parent as DNStyle).css == css &&
              start.dnOffset == start.dn.offsetLength && start.dn.nextSibling == null) {
            // we are at the end of the style
            // just move the cursor position outside of the style
            DaxeNode styleNode = start.dn.parent;
            page.moveCursorTo(new Position(styleNode.parent, styleNode.parent.offsetOf(styleNode)+1));
            page.updateAfterPathChange();
          } else
            DNStyle.removeStylesFromSelection(styleRef, cssName);
        } else {
          DNStyle.removeAndApplyStyleToSelection(styleRef, cssName, css);
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
            if (info.ref != null)
              list.add(info.ref);
          }
        }
      } else if (item is ToolbarMenu) {
        Menu menu = item.menu;
        for (MenuItem menuItem in menu.items) {
          if (menuItem.data is ToolbarStyleInfo) {
            ToolbarStyleInfo info = menuItem.data;
            if (info.ref != null)
              list.add(info.ref);
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
  
  addInsertButton(Config cfg, ToolbarBox box, x.Element ref, String icon) {
    ToolbarButton button = new ToolbarButton(_documentationFor(ref), icon,
        () => doc.insertNewNode(ref, 'element'), insertButtonUpdate,
        data:new ToolbarStyleInfo(ref, null, null));
    box.add(button);
  }
  
  static void insertButtonUpdate(ToolbarButton button, DaxeNode parent, DaxeNode selectedNode,
                             List<x.Element> validRefs, List<x.Element> ancestorRefs) {
    // element insert
    ToolbarStyleInfo info = button.data;
    x.Element ref = info.ref;
    if (validRefs.contains(ref))
      button.enable();
    else
      button.disable();
  }
  
  addStyleButton(Config cfg, ToolbarBox box, x.Element ref, String icon, [String shortcut=null]) {
    ToolbarButton button = new ToolbarButton(_documentationFor(ref), icon, null, dnStyleButtonUpdate,
        data:new ToolbarStyleInfo(ref, null, null), shortcut:shortcut);
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
    x.Element ref = info.ref;
    if (ancestorRefs.contains(ref)) {
      button.enable();
      button.select();
    } else {
      if (selectedNode != null && ref == selectedNode.ref)
        button.select();
      else
        button.deselect();
      if (validRefs.contains(ref))
        button.enable();
      else
        button.disable();
    }
  }
  
  static void styleSpanButtonUpdate(ToolbarButton button, DaxeNode parent, DaxeNode selectedNode,
                             List<x.Element> validRefs, List<x.Element> ancestorRefs) {
    // DNSpanStyle, span style
    ToolbarStyleInfo info = button.data;
    x.Element ref = info.ref;
    String css = info.css;
    bool foundAncestor = false;
    for (DaxeNode n = parent; n != null; n = n.parent) {
      if (n.ref == ref && (n as DNStyleSpan).css == css) {
        foundAncestor = true;
        break;
      }
    }
    if (foundAncestor) {
      button.enable();
      button.select();
    } else {
      if (selectedNode != null && ref == selectedNode.ref &&
          (selectedNode as DNStyleSpan).css == css) {
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
        null, paragraphButtonUpdate, data:new ToolbarStyleInfo(doc.hiddenp, cssName, cssValue));
    button.action = () {
      if (button.selected) {
        DNHiddenP.removeStyleFromSelection(cssName);
      } else {
        DNHiddenP.applyStyleToSelection(cssName, '$cssName: $cssValue');
      }
    };
    alignBox.add(button);
  }
  
  static void paragraphButtonUpdate(ToolbarButton button, DaxeNode parent, DaxeNode selectedNode,
                             List<x.Element> validRefs, List<x.Element> ancestorRefs) {
    ToolbarStyleInfo info = button.data;
    String css = info.css;
    bool foundAncestor = false;
    for (DaxeNode n = parent; n != null; n = n.parent) {
      if (n.ref == doc.hiddenp && (n as DNHiddenP).css == css) {
        foundAncestor = true;
        break;
      }
    }
    if (foundAncestor) {
      button.enable();
      button.select();
    } else {
      if (selectedNode != null && doc.hiddenp == selectedNode.ref &&
          (selectedNode as DNHiddenP).css == css) {
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
    x.Element ref = info.ref;
    bool foundAncestor = false;
    for (DaxeNode n = parent; n != null; n = n.parent) {
      if (n.ref == DNWList.ulRef() || n.ref == DNWList.olRef()) {
        foundAncestor = (n.ref == ref);
        break;
      }
    }
    if (foundAncestor) {
      button.enable();
      button.select();
    } else {
      button.deselect();
      if (validRefs.contains(ref))
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
    x.Element ref = info.ref;
    if (page.getSelectionStart().dn is DNText && validRefs.contains(ref))
      button.enable();
    else
      button.disable();
  }
  
  static void removeLinkButtonUpdate(ToolbarButton button, DaxeNode parent, DaxeNode selectedNode,
                             List<x.Element> validRefs, List<x.Element> ancestorRefs) {
    if (ancestorRefs.contains(DNAnchor.aRef()))
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
        x.Element ref = info.ref;
        String css = info.css;
        if (ref == doc.hiddenp) {
          // paragraph style
          bool foundAncestor = false;
          for (DaxeNode n = parent; n != null; n = n.parent) {
            if (n.ref == doc.hiddenp && (n as DNHiddenP).css == css) {
              foundAncestor = true;
              break;
            }
          }
          if (foundAncestor) {
            menuItem.enable();
            selectedItem = menuItem;
            menuItem.check();
          } else {
            if (selectedNode != null && doc.hiddenp == selectedNode.ref &&
                (selectedNode as DNHiddenP).css == css) {
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
            if (n.ref == ref && (n as DNStyleSpan).css == css) {
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
                (selectedNode as DNStyleSpan).css == css) {
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
        x.Element ref = info.ref;
        if (ref != null) {
          // element insert
          if (validRefs.contains(ref))
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
  
}
